// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Lottery/Lottery.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    VRFCoordinatorV2Mock public vrfCoordinatorMock;

    address public alice = address(0x1);
    address public bob = address(0x2);
    
    uint256 constant ENTRANCE_FEE = 0.01 ether;
    uint256 constant INTERVAL = 30;
    bytes32 constant GAS_LANE = bytes32(uint256(0x1));
    uint64 constant SUBSCRIPTION_ID = 1;
    uint32 constant CALLBACK_GAS_LIMIT = 500000;

    function setUp() public {
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        vrfCoordinatorMock.createSubscription();
        vrfCoordinatorMock.fundSubscription(SUBSCRIPTION_ID, 1000 ether);

        lottery = new Lottery(
            ENTRANCE_FEE,
            INTERVAL,
            address(vrfCoordinatorMock),
            GAS_LANE,
            SUBSCRIPTION_ID,
            CALLBACK_GAS_LIMIT
        );

        vrfCoordinatorMock.addConsumer(SUBSCRIPTION_ID, address(lottery));
        
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_twoPlayersDepositPrincipalPreservedAfterDraw() public {
        vm.prank(alice);
        lottery.enterLottery{value: 1 ether}();
        
        vm.prank(bob);
        lottery.enterLottery{value: 1 ether}();
        
        lottery.fundPrize{value: 0.1 ether}();
        
        assertEq(lottery.getDeposit(alice), 1 ether);
        assertEq(lottery.getDeposit(bob), 1 ether);
        assertEq(lottery.getPrizeBalance(), 0.1 ether);
        
        vm.warp(block.timestamp + INTERVAL + 1);
        
        lottery.performUpkeep("");
        
        uint256 requestId = 1;
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 42;
        
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(lottery));
        
        assertEq(lottery.getDeposit(alice), 1 ether, "Alice's deposit should remain");
        assertEq(lottery.getDeposit(bob), 1 ether, "Bob's deposit should remain");
        assertEq(lottery.getPrizeBalance(), 0, "Prize should be paid out");
        assertEq(address(lottery).balance, 2 ether, "Contract should still hold both deposits");
    }

    function test_withdrawAfterDraw() public {
        vm.prank(alice);
        lottery.enterLottery{value: 1 ether}();
        
        vm.prank(bob);
        lottery.enterLottery{value: 1 ether}();
        
        lottery.fundPrize{value: 0.1 ether}();
        
        vm.warp(block.timestamp + INTERVAL + 1);
        lottery.performUpkeep("");
        
        uint256 requestId = 1;
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(lottery));
        
        uint256 aliceBalanceBefore = alice.balance;
        
        vm.prank(alice);
        lottery.withdraw();
        
        assertEq(alice.balance, aliceBalanceBefore + 1 ether, "Alice should get her deposit back");
        assertEq(lottery.getDeposit(alice), 0, "Alice's deposit should be zeroed");
    }

    function test_fundPrizeRevertsOnZero() public {
        vm.expectRevert(Lottery.Lottery__ZeroAmount.selector);
        lottery.fundPrize{value: 0}();
    }
}
