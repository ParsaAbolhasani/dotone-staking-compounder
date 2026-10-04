// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IDotOneStaking
/// @notice Interface for DotOne Chain's native staking contract
/// @dev Based on @dotone/sdk specifications
interface IDotOneStaking {
    // ─── Structs ────────────────────────────────────────────────────

    struct Tier {
        uint256 minApy;          // Minimum APY in basis points (800 = 8%)
        uint256 maxApy;          // Maximum APY in basis points
        uint256 lockPeriod;      // Lock period in seconds
        uint256 minInvestment;   // Minimum investment amount
        uint256 performanceFee;  // Performance fee in basis points
        uint256 managementFee;   // Management fee in basis points
        bool active;
    }

    struct StakeInfo {
        address token;
        uint256 amount;
        uint256 tierId;
        uint256 startTime;
        uint256 unlockTime;
        bool active;
    }

    // ─── Events ─────────────────────────────────────────────────────

    event Staked(address indexed user, address indexed token, uint256 amount, uint256 tierId);
    event Unstaked(address indexed user, address indexed token, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, address indexed token, uint256 reward);

    // ─── Functions ──────────────────────────────────────────────────

    /// @notice Stake tokens into DotOne staking
    /// @dev Tier is auto-selected based on amount
    function stake(address token, uint256 amount) external returns (uint256 stakeId);

    /// @notice Unstake tokens and claim rewards
    function unstake(uint256 stakeId) external returns (uint256 totalAmount);

    /// @notice Claim accumulated rewards without unstaking
    function claimRewards(uint256 stakeId) external returns (uint256 reward);

    /// @notice Get tier configuration for a token
    function getTiers(address token) external view returns (Tier[] memory);

    /// @notice Get user's stake info
    function getStakeInfo(uint256 stakeId) external view returns (StakeInfo memory);

    /// @notice Calculate pending rewards for a stake
    function pendingRewards(uint256 stakeId) external view returns (uint256);
}
