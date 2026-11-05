// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Lottery/Lottery.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract LotteryUpkeepTest is Test {
    Lottery public lottery;
    VRFCoordinatorV2Mock public vrfCoordinatorMock;

    uint256 constant ENTRANCE_FEE = 0.01 ether;
    uint256 constant INTERVAL = 30;
    bytes32 constant GAS_LANE = bytes32(uint256(0x1));
    uint64 constant SUBSCRIPTION_ID = 1;
    uint32 constant CALLBACK_GAS_LIMIT = 500000;

    function setUp() public {
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        vrfCoordinatorMock.createSubscription();

        lottery = new Lottery(
            ENTRANCE_FEE,
            INTERVAL,
            address(vrfCoordinatorMock),
            GAS_LANE,
            SUBSCRIPTION_ID,
            CALLBACK_GAS_LIMIT
        );
    }

    function test_checkUpkeepSelector() public pure {
        bytes4 lotterySelector = bytes4(keccak256("checkUpkeep(bytes)"));
        bytes4 interfaceSelector = AutomationCompatibleInterface.checkUpkeep.selector;
        assertEq(lotterySelector, interfaceSelector, "checkUpkeep selector mismatch");
    }

    function test_performUpkeepSelector() public pure {
        bytes4 lotterySelector = bytes4(keccak256("performUpkeep(bytes)"));
        bytes4 interfaceSelector = AutomationCompatibleInterface.performUpkeep.selector;
        assertEq(lotterySelector, interfaceSelector, "performUpkeep selector mismatch");
    }
}
