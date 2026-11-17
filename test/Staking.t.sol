// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/staking/Staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract StakingTest is Test {
    Staking public staking;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    
    uint256 constant INITIAL_BALANCE = 1000 ether;
    
    function setUp() public {
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken = new MockERC20("Reward Token", "RWD");
        
        staking = new Staking(address(stakingToken), address(rewardToken));
        
        stakingToken.mint(alice, INITIAL_BALANCE);
        stakingToken.mint(bob, INITIAL_BALANCE);
        
        vm.prank(alice);
        stakingToken.approve(address(staking), type(uint256).max);
        
        vm.prank(bob);
        stakingToken.approve(address(staking), type(uint256).max);
    }
    
    function test_selfStake() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        staking.stake(stakeAmount, alice);
        
        assertEq(staking.s_balances(alice), stakeAmount);
        assertEq(stakingToken.balanceOf(alice), INITIAL_BALANCE - stakeAmount);
    }
    
    function test_revertStakeOnBehalfOfOther() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        vm.expectRevert(Staking.Staking__UnauthorizedBeneficiary.selector);
        staking.stake(stakeAmount, bob);
    }
    
    function test_stakingCreditsCorrectBeneficiary() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        staking.stake(stakeAmount, alice);
        
        assertEq(staking.s_balances(alice), stakeAmount);
        assertEq(staking.s_balances(bob), 0);
    }
    
    function test_revertWhenStakingAndRewardTokenAreSame() public {
        vm.expectRevert(Staking.Staking__RewardTokenIsStakingToken.selector);
        new Staking(address(stakingToken), address(stakingToken));
    }
    
    function test_claimDoesNotReduceOtherUsersStake() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        staking.stake(stakeAmount, alice);
        
        vm.prank(bob);
        staking.stake(stakeAmount, bob);
        
        rewardToken.mint(address(staking), 1000 ether);
        
        vm.warp(block.timestamp + 365 days);
        
        uint256 bobBalanceBefore = staking.s_balances(bob);
        
        vm.prank(alice);
        staking.claimReward();
        
        assertEq(staking.s_balances(bob), bobBalanceBefore, "Bob's stake should not be reduced by Alice's claim");
    }
    
    function test_authorizedCallerCanStakeOnBehalfOf() public {
        address lottery = address(0x3);
        uint256 stakeAmount = 100 ether;
        
        stakingToken.mint(lottery, INITIAL_BALANCE);
        vm.prank(lottery);
        stakingToken.approve(address(staking), type(uint256).max);
        
        staking.setAuthorizedCaller(lottery);
        
        vm.prank(lottery);
        staking.stake(stakeAmount, alice);
        
        assertEq(staking.s_balances(alice), stakeAmount);
        assertEq(stakingToken.balanceOf(alice), INITIAL_BALANCE);
    }
    
    function test_unauthorizedCallerCannotStakeOnBehalfOf() public {
        address lottery = address(0x3);
        uint256 stakeAmount = 100 ether;
        
        stakingToken.mint(lottery, INITIAL_BALANCE);
        vm.prank(lottery);
        stakingToken.approve(address(staking), type(uint256).max);
        
        vm.prank(lottery);
        vm.expectRevert(Staking.Staking__UnauthorizedBeneficiary.selector);
        staking.stake(stakeAmount, alice);
    }
}
