// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";

/**
 * @title Lottery Contract
 * @author Arnaud
 * @notice You can use this contract for only the lottery
 * @dev Implementing Chainlink VRFv2
 */
contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Lottery__NotEnoughEthSent();
    error Lottery__TransferFailed();
    error Lottery__NotOpen();
    error Lottery__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);
    error Lottery__ZeroAmount();

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
    mapping(address => uint256) private s_deposits;
    uint256 private s_prizeBalance;

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
        s_deposits[msg.sender] += msg.value;
        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    function fundPrize() external payable {
        if (msg.value == 0) revert Lottery__ZeroAmount();
        s_prizeBalance += msg.value;
    }

    function withdraw() external {
        if (s_lotteryeState != LotteryState.OPEN) revert Lottery__NotOpen();
        uint256 amount = s_deposits[msg.sender];
        s_deposits[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert Lottery__TransferFailed();
    }

    function checkUpkeep(bytes calldata /*checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData*/ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = LotteryState.OPEN == s_lotteryeState;
        bool hasBalance = s_prizeBalance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = LotteryState.OPEN == s_lotteryeState;
        bool hasBalance = s_prizeBalance > 0;
        bool hasPlayers = s_players.length > 0;
        bool upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        
        if (!upkeepNeeded) {
            revert Lottery__UpKeepNotNeeded(s_prizeBalance, s_players.length, uint256(s_lotteryeState));
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
        
        uint256 prize = s_prizeBalance;
        s_prizeBalance = 0;
        
        s_lotteryeState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        
        (bool success,) = winner.call{value: prize}("");
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

    function getDeposit(address player) external view returns (uint256) {
        return s_deposits[player];
    }

    function getPrizeBalance() external view returns (uint256) {
        return s_prizeBalance;
    }
}