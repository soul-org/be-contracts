// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {IRouterClient} from "@chainlink/contracts-ccip/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/v0.8/interfaces/LinkTokenInterface.sol";

contract MockLinkToken is LinkTokenInterface {
    function allowance(address owner, address spender) external view override returns (uint256 remaining) {
        return 100;
    }

    function approve(address spender, uint256 value) external override returns (bool success) {
        return true;
    }

    function balanceOf(address owner) external view override returns (uint256 balance) {
        return 10;
    }

    function decimals() external view override returns (uint8 decimalPlaces) {
        return 18;
    }

    function decreaseApproval(address spender, uint256 addedValue) external override returns (bool success) {
        return true;
    }

    function increaseApproval(address spender, uint256 subtractedValue) external override {}

    function name() external view override returns (string memory tokenName) {
        return "LINK";
    }

    function symbol() external view override returns (string memory tokenSymbol) {
        return "LINK";
    }

    function totalSupply() external view override returns (uint256 totalTokensIssued) {
        return 10 ** 18;
    }

    function transfer(address to, uint256 value) external override returns (bool success) {
        return true;
    }

    function transferAndCall(address to, uint256 value, bytes calldata data) external override returns (bool success) {
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool success) {
        return true;
    }
}
