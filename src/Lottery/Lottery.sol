// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Lottery Contract
 * @author Arnaud
 * @notice You can use this contract for only the lottery
 * @dev Implementing Chainlink VRFv2
 */
contract Lottery {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    /**
     * Getter function
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
