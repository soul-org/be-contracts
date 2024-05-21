// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployPoolToken} from "../script/DeployPoolToken.s.sol";
import {PoolToken} from "../src/staking/token/PoolToken.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {StdCheats} from "../lib/forge-std/src//StdCheats.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract PoolTokenTest is StdCheats, Test {
    uint256 BOB_STARTING_AMOUNT = 100 ether;

    PoolToken public poolToken;
    DeployPoolToken public deployer;
    address public deployerAddress;
    address bob;
    address alice;

    function setUp() public {
        deployer = new DeployPoolToken();
        poolToken = deployer.run();

        bob = makeAddr("bob");
        alice = makeAddr("alice");

        deployerAddress = vm.addr(deployer.deployerKey());
        vm.prank(deployerAddress);
        poolToken.transfer(bob, BOB_STARTING_AMOUNT);
    }

    function testInitialSupply() public view {
        assertEq(poolToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(poolToken)).mint(address(this), 1);
    }

    function testAllowances() public {
        uint256 initialAllowance = 1000;

        // Alice approves Bob to spend tokens on her behalf
        vm.prank(bob);
        poolToken.approve(alice, initialAllowance);
        uint256 transferAmount = 500;

        vm.prank(alice);
        poolToken.transferFrom(bob, alice, transferAmount);
        assertEq(poolToken.balanceOf(alice), transferAmount);
        assertEq(poolToken.balanceOf(bob), BOB_STARTING_AMOUNT - transferAmount);
    }
}
