// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PoolToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("PoolToken", "PLT") {
        _mint(msg.sender, initialSupply);
    }
}