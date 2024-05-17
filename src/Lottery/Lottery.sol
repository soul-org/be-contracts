// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Lottery Contract
 * @author Arnaud
 * @notice You can use this contract for only the lottery
 * @dev Implementing Chainlink VRFv2
 */
contract Lottery is VRFConsumerBaseV2 {
    error Lottery__NotEnoughEthSent();
    error Lottery__TransferFailed();
    error Lottery__NotOpen();
    error Lottery__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);

    enum LotteryState {
        OPEN,
        CALCULATING
    }

    // PRIVATE CONSTANT

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // PRIVATE IMMUTABLE
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;


    // PRIVATE STORAGE //

    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    LotteryState private s_lotteryeState;

    /**
     * Events
     */
    event EnteredLottery(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedLotteryWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lotteryeState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterLottery() external payable {
        if (msg.value < i_entranceFee) revert Lottery__NotEnoughEthSent();
        if (s_lotteryeState != LotteryState.OPEN) revert Lottery__NotOpen();
        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    function checkUpKeep(bytes memory /*checkData */ )
        public
        view
        returns (bool upKeepNeed, bytes memory /* perfomData*/ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = LotteryState.OPEN == s_lotteryeState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeed = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upKeepNeed, "0x0");
    }

    function performUpKeep(bytes calldata /* performData */ ) external {
        (bool upKeepNeed,) = checkUpKeep("");
        if (!upKeepNeed) {
            revert Lottery__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_lotteryeState));
        }
        s_lotteryeState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] memory randomWord) internal override {
        uint256 indexOfWinner = randomWord[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_lotteryeState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) revert Lottery__TransferFailed();
        emit PickedWinner(winner);
    }

    /**
     * Getter function
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryeState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPLayer() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}