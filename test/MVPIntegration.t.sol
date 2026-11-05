// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Lottery/Lottery.sol";
import "../src/staking/Staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MVPIntegrationTest is Test {
    Lottery public lottery;
    Staking public staking;
    VRFCoordinatorV2Mock public vrfCoordinatorMock;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;

    address public user = address(0x1);
    
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
        
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken = new MockERC20("Reward Token", "RWD");
        staking = new Staking(address(stakingToken), address(rewardToken));
        
        staking.setAuthorizedCaller(address(lottery));
        
        vm.deal(user, 10 ether);
    }

    function test_lotteryCanStakeForUser() public {
        uint256 stakeAmount = 100 ether;
        
        stakingToken.mint(address(lottery), stakeAmount);
        
        vm.prank(address(lottery));
        stakingToken.approve(address(staking), stakeAmount);
        
        vm.prank(address(lottery));
        staking.stake(stakeAmount, user);
        
        assertEq(staking.s_balances(user), stakeAmount);
    }

    function test_thirdPartyCannotStakeForUser() public {
        uint256 stakeAmount = 100 ether;
        address thirdParty = address(0x99);
        
        stakingToken.mint(thirdParty, stakeAmount);
        
        vm.prank(thirdParty);
        stakingToken.approve(address(staking), stakeAmount);
        
        vm.prank(thirdParty);
        vm.expectRevert(Staking.Staking__UnauthorizedBeneficiary.selector);
        staking.stake(stakeAmount, user);
    }

    function test_mvpPath_depositPrincipalStaysWithdrawable_drawPaysOnlyPrize() public {
        vm.prank(user);
        lottery.enterLottery{value: 1 ether}();
        
        assertEq(lottery.getDeposit(user), 1 ether, "User deposit should be tracked");
        
        lottery.fundPrize{value: 0.1 ether}();
        
        assertEq(lottery.getPrizeBalance(), 0.1 ether, "Prize should be funded");
        
        vm.warp(block.timestamp + INTERVAL + 1);
        lottery.performUpkeep("");
        
        uint256 requestId = 1;
        vrfCoordinatorMock.fulfillRandomWords(requestId, address(lottery));
        
        assertEq(lottery.getDeposit(user), 1 ether, "User deposit should remain after draw");
        assertEq(lottery.getPrizeBalance(), 0, "Prize should be paid out");
        
        uint256 userBalanceBefore = user.balance;
        
        vm.prank(user);
        lottery.withdraw();
        
        assertEq(user.balance, userBalanceBefore + 1 ether, "User should be able to withdraw principal");
    }
}
