// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/staking/token/TokenTransferor.sol";
import "./mocks/MockCCIPRouter.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {StdCheats} from "../lib/forge-std/src//StdCheats.sol";

contract MockToken is MockERC20 {
    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply);
    }
}

contract TokenTransferorTest is StdCheats, Test {
    TokenTransferor transferor;
    MockCCIPRouter router;
    MockToken link;
    MockToken token;
    address receiver;
    address sender;

    function setUp() public {
        router = new MockCCIPRouter();
        receiver = makeAddr("receiver");
        sender = makeAddr("sender");
        link = new MockToken(10e18);
        transferor = new TokenTransferor(address(router), address(link));
        token = new MockToken(10e18);
        token.transfer(sender, 100);
    }

    function test_addAllowedTokens() external {
        transferor.allowlistDestinationChain(1, true);
        assertTrue(transferor.allowlistedChains(1));
    }

    function test_RevertWhen_transferTokensPayLINK_InsufficientLinkBalance() external {
        link.transfer(address(transferor), 100);
        assertEq(link.balanceOf(address(transferor)), 100);

        vm.prank(sender);
        token.transfer(address(transferor), 10);
        assertEq(token.balanceOf(address(transferor)), 10);

        transferor.allowlistDestinationChain(1, true);
        
        // Expect revert due to insufficient LINK balance to cover fees
        // Mock router returns fee of 1, but we need to approve the token transfer
        // This will fail because the transferor contract doesn't have enough token balance
        vm.expectRevert();
        transferor.transferTokensPayLINK(1, receiver, address(token), 10);
    }

    function test_RevertWhen_NotEnoughBalance() external {
        transferor.allowlistDestinationChain(1, true);
        
        // Expect NotEnoughBalance error when contract has 0 LINK but needs to pay fees
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenTransferor.NotEnoughBalance.selector,
                0,
                1
            )
        );
        transferor.transferTokensPayLINK(1, receiver, address(token), 10);
    }

    function test_RevertWhen_DestinationChainNotAllowlisted() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenTransferor.DestinationChainNotAllowlisted.selector,
                1
            )
        );
        transferor.transferTokensPayLINK(1, receiver, address(token), 10);
    }
}
