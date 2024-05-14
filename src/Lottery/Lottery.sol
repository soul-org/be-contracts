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
    // Errors
    error Lottery__NotEnoughEthSent();

    // Constants variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Immutable variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_lotteryDuration;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_startTime;

    /**
     * Events
     */
    event EnteredLottery(address indexed player);

    constructor(
        uint256 _entranceFee,
        uint256 _lotteryDuration,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_lotteryDuration = _lotteryDuration;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_startTime = block.timestamp;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) revert Lottery__NotEnoughEthSent();

        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    function pickWinner() external {
        if (block.timestamp - s_startTime < i_lotteryDuration) revert();

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {}

    /**
     * Getter function
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
