// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title DotOne Staking Auto-Compounder
/// @notice Automatically re-stakes rewards from DotOne Chain staking tiers
/// @dev Compatible with DotOne Smart Chain (EVM-compatible L1)
contract StakingAutoCompounder is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─── Structs ────────────────────────────────────────────────────

    struct Position {
        address token;          // Staked ERC-20
        uint256 principal;      // Original stake amount
        uint256 shares;         // Position shares
        uint256 lastCompound;   // Last auto-compound timestamp
        uint256 tierId;         // DotOne tier ID (0, 1, 2)
        bool active;
    }

    // ─── State ──────────────────────────────────────────────────────

    /// @notice DotOne Staking contract address
    address public immutable stakingContract;

    /// @notice User positions
    mapping(address => mapping(uint256 => Position)) public positions;

    /// @notice User position count
    mapping(address => uint256) public positionCount;

    /// @notice Supported tokens
    mapping(address => bool) public supportedTokens;

    /// @notice Auto-compound interval (default: 7 days)
    uint256 public compoundInterval = 7 days;

    // ─── Events ─────────────────────────────────────────────────────

    event Staked(
        address indexed user,
        uint256 indexed positionId,
        address token,
        uint256 amount,
        uint256 tierId
    );

    event Compounded(
        address indexed user,
        uint256 indexed positionId,
        uint256 rewardAmount
    );

    event Unstaked(
        address indexed user,
        uint256 indexed positionId,
        uint256 amount
    );

    event TokenSupported(address indexed token, bool supported);

    // ─── Errors ─────────────────────────────────────────────────────

    error TokenNotSupported();
    error InvalidTier();
    error PositionNotActive();
    error CompoundTooSoon();
    error ZeroAmount();

    // ─── Constructor ────────────────────────────────────────────────

    constructor(address _stakingContract) Ownable(msg.sender) {
        require(_stakingContract != address(0), "invalid staking contract");
        stakingContract = _stakingContract;
    }

    // ─── Admin ──────────────────────────────────────────────────────

    /// @notice Add or remove a supported token
    function setTokenSupport(address token, bool supported) external onlyOwner {
        supportedTokens[token] = supported;
        emit TokenSupported(token, supported);
    }

    /// @notice Update compound interval
    function setCompoundInterval(uint256 interval) external onlyOwner {
        require(interval >= 1 days, "interval too short");
        compoundInterval = interval;
    }

    // ─── Core Functions ─────────────────────────────────────────────

    /// @notice Stake tokens with auto-compound enabled
    /// @param token ERC-20 token address
    /// @param amount Amount to stake
    /// @param tierId DotOne tier ID (0=Low, 1=Medium, 2=High Risk)
    function stake(
        address token,
        uint256 amount,
        uint256 tierId
    ) external nonReentrant returns (uint256 positionId) {
        if (amount == 0) revert ZeroAmount();
        if (!supportedTokens[token]) revert TokenNotSupported();
        if (tierId > 2) revert InvalidTier();

        // Transfer tokens from user
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Approve staking contract
        IERC20(token).approve(stakingContract, amount);

        // Call DotOne staking contract (interface to be defined)
        // In production: IDotOneStaking(stakingContract).stake(token, amount, tierId);

        positionId = positionCount[msg.sender]++;
        positions[msg.sender][positionId] = Position({
            token: token,
            principal: amount,
            shares: amount,
            lastCompound: block.timestamp,
            tierId: tierId,
            active: true
        });

        emit Staked(msg.sender, positionId, token, amount, tierId);
    }

    /// @notice Manually trigger compound for a position
    /// @param positionId Position ID to compound
    function compound(uint256 positionId) external nonReentrant {
        Position storage pos = positions[msg.sender][positionId];

        if (!pos.active) revert PositionNotActive();
        if (block.timestamp < pos.lastCompound + compoundInterval) {
            revert CompoundTooSoon();
        }

        // In production:
        // 1. Claim rewards from DotOne staking
        // 2. Re-stake rewards
        // 3. Update position

        pos.lastCompound = block.timestamp;

        emit Compounded(msg.sender, positionId, pos.shares);
    }

    /// @notice Unstake and withdraw principal + rewards
    function unstake(uint256 positionId) external nonReentrant {
        Position storage pos = positions[msg.sender][positionId];

        if (!pos.active) revert PositionNotActive();

        // In production: unstake from DotOne staking
        // uint256 total = IDotOneStaking(stakingContract).unstake(pos.token, pos.shares);

        uint256 total = pos.shares;

        pos.active = false;
        IERC20(pos.token).safeTransfer(msg.sender, total);

        emit Unstaked(msg.sender, positionId, total);
    }

    // ─── View Functions ─────────────────────────────────────────────

    /// @notice Get user's active positions
    function getActivePositions(address user)
        external
        view
        returns (Position[] memory active)
    {
        uint256 count = positionCount[user];
        uint256 activeCount = 0;

        for (uint256 i = 0; i < count; i++) {
            if (positions[user][i].active) activeCount++;
        }

        active = new Position[](activeCount);
        uint256 j = 0;

        for (uint256 i = 0; i < count; i++) {
            if (positions[user][i].active) {
                active[j++] = positions[user][i];
            }
        }
    }
}
