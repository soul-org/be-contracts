// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Lottery Contract
 * @author Arnaud
 * @notice You can use this contract for only the lottery
 * @dev Implementing Chainlink VRFv2
 */
contract Lottery {

    // Errors
    error Lottery__NotEnoughEthSent();

    uint256 private immutable i_entranceFee;
    address[] private s_players;

    /**Events */
    event EnteredLottery(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    /**
     * Getter function
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
