// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {PoolToken} from "./token/PoolToken.sol";

/**
 * @title Staking contract
 * @dev Staking contract that allows users to stake tokens for rewards
 * @author Arnaud
 */

contract Staking is ReentrancyGuard {
    // ERRORS
    error Staking__TransferFailed();
    error Staking__WithdrawFailed();
    error Staking__NeedMoreThanZero();

    // STORAGE
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    // CONSTANTS
    uint256 public constant REWARD_RATE = 100;

    /**
     * @notice Mapping from address to the amount the user has staked
     */
    mapping(address => uint256) public s_balances;

    /**
     * @notice Mapping from address to the amount of rewards the user has earned
     */
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    /**
     * @notice Mapping from address to the amount of rewards the user has earned
     */
    mapping(address => uint256) public s_rewards;

    event Staked(uint256 amount, address indexed onBehalfOf);
    event Unstaked(uint256 amount, address indexed onBehalfOf);

    /**
     * @notice Modifier to update the reward for the account
     * @param _account The account to update the reward for
     */
    modifier updateReward(address _account) {
        // Update the reward for the account
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[_account] = earned(_account);
        s_userRewardPerTokenPaid[_account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) revert Staking__NeedMoreThanZero();
        _;
    }

    constructor(address _stakingToken, address _rewardToken) {
        s_stakingToken = IERC20(_stakingToken);
        s_rewardToken = IERC20(_rewardToken);
    }

    /**
     * @notice Earned function to calculate the amount of rewards the user has earned
     * @param _account The account to calculate the rewards for
     */
    function earned(address _account) public view returns (uint256) {
        uint256 currentBalance = s_balances[_account];
        // How much the user has earned
        uint256 amountPaid = s_userRewardPerTokenPaid[_account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[_account];
        uint256 newReward = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;

        return newReward;
    }

    /**
     * @notice RewardPerToken function to calculate the reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }

        uint256 timeSinceLastUpdate = block.timestamp - s_lastUpdateTime;
        uint256 rewardRate = REWARD_RATE * timeSinceLastUpdate;
        uint256 newRewardPerToken = s_rewardPerTokenStored + (rewardRate * 1e18) / s_totalSupply;

        return newRewardPerToken;
    }

    function stake(uint256 _amount, address onBehalfOf)
        external
        nonReentrant
        updateReward(msg.sender)
        moreThanZero(_amount)
    {
        // Update the total supply
        s_totalSupply += _amount;
        // Update the balance of the user
        s_balances[msg.sender] += _amount;

        // Transfer the tokens to the contract
        if (!s_stakingToken.transferFrom(msg.sender, address(this), _amount)) {
            revert Staking__TransferFailed();
        }

        emit Staked(_amount, onBehalfOf);
    }

    function withdraw(uint256 _amount) external nonReentrant updateReward(msg.sender) moreThanZero(_amount) {
        if (_amount > s_balances[msg.sender]) {
            revert Staking__NeedMoreThanZero();
        }
        // Update the total supply
        s_totalSupply -= _amount;
        // Update the balance of the user
        s_balances[msg.sender] -= _amount;

        // Transfer the tokens to the user
        if (!s_stakingToken.transfer(msg.sender, _amount)) {
            revert Staking__WithdrawFailed();
        }
    }

    function claimReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;

        // Transfer the reward to the user
        if (!s_rewardToken.transfer(msg.sender, reward)) {
            revert Staking__TransferFailed();
        }
    }
}