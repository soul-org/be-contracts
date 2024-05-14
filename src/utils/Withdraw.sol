// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/v0.8/shared/access/OwnerIsCreator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Withdraw is OwnerIsCreator {
    using SafeERC20 for IERC20;

    error FailedToWithdrawEth(address owner, address target, uint256 value);

    function withdraw(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    function withdrawToken(
        address beneficiary,
        address token
    ) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(beneficiary, amount);
    }
}