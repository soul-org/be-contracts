// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Lottery/Lottery.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract LotteryInvariantTest is Test {
    Lottery public lottery;
    VRFCoordinatorV2Mock public vrfCoordinatorMock;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    
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
        vm.deal(charlie, 10 ether);
    }

    function test_invariant_totalDepositsAlwaysWithdrawable() public {
        vm.prank(alice);
        lottery.enterLottery{value: 1 ether}();
        
        vm.prank(bob);
        lottery.enterLottery{value: 2 ether}();
        
        vm.prank(charlie);
        lottery.enterLottery{value: 3 ether}();
        
        uint256 totalDeposits = lottery.getDeposit(alice) + lottery.getDeposit(bob) + lottery.getDeposit(charlie);
        assertEq(totalDeposits, 6 ether, "Total deposits should be 6 ether");
        
        lottery.fundPrize{value: 0.5 ether}();
        
        assertEq(address(lottery).balance, 6.5 ether, "Contract should hold deposits + prize");
        
        vm.warp(block.timestamp + INTERVAL + 1);
        lottery.performUpkeep("");
        
        uint256 requestId = 1;
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(lottery));
        
        uint256 totalDepositsAfterDraw = lottery.getDeposit(alice) + lottery.getDeposit(bob) + lottery.getDeposit(charlie);
        assertEq(totalDepositsAfterDraw, 6 ether, "Total deposits should still be 6 ether after draw");
        
        assertEq(address(lottery).balance, 6 ether, "Contract should still hold all deposits");
        
        address winner = lottery.getRecentWinner();
        
        vm.prank(alice);
        lottery.withdraw();
        
        vm.prank(bob);
        lottery.withdraw();
        
        vm.prank(charlie);
        lottery.withdraw();
        
        assertEq(address(lottery).balance, 0, "Contract should be empty after all withdrawals");
        
        uint256 aliceExpected = alice == winner ? 10.5 ether : 10 ether;
        uint256 bobExpected = bob == winner ? 10.5 ether : 10 ether;
        uint256 charlieExpected = charlie == winner ? 10.5 ether : 10 ether;
        
        assertEq(alice.balance, aliceExpected, "Alice should have her deposit back, plus prize if she won");
        assertEq(bob.balance, bobExpected, "Bob should have his deposit back, plus prize if he won");
        assertEq(charlie.balance, charlieExpected, "Charlie should have his deposit back, plus prize if he won");
        
        assertTrue(alice.balance == 10 ether || alice.balance == 10.5 ether, "Alice should have principal or principal + prize");
        assertTrue(bob.balance == 10 ether || bob.balance == 10.5 ether, "Bob should have principal or principal + prize");
        assertTrue(charlie.balance == 10 ether || charlie.balance == 10.5 ether, "Charlie should have principal or principal + prize");
    }
}
