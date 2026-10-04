// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IDotOneStaking} from "./interfaces/IDotOneStaking.sol";

/// @title StakingAutoCompounder
/// @notice Auto-compounds DotOne Chain staking rewards
/// @dev Works with DotOne's auto-tier-selection staking system
contract StakingAutoCompounder is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─── Structs ────────────────────────────────────────────────────

    struct Position {
        uint256 dotOneStakeId;    // ID from DotOne staking contract
        address token;            // Staked ERC-20
        uint256 principal;        // Original stake amount
        uint256 accumulatedRewards; // Rewards not yet compounded
        uint256 lastCompound;     // Last auto-compound timestamp
        bool active;
    }

    // ─── Constants ──────────────────────────────────────────────────

    uint256 public constant MIN_COMPOUND_INTERVAL = 1 days;
    uint256 public constant MAX_COMPOUND_INTERVAL = 30 days;

    // ─── State ──────────────────────────────────────────────────────

    /// @notice DotOne Staking contract address
    IDotOneStaking public immutable dotOneStaking;

    /// @notice User positions
    mapping(address => mapping(uint256 => Position)) public positions;

    /// @notice User position count
    mapping(address => uint256) public positionCount;

    /// @notice Supported tokens (verified via SDK)
    mapping(address => bool) public supportedTokens;

    /// @notice Auto-compound interval (default: 7 days)
    uint256 public compoundInterval = 7 days;

    /// @notice Total value locked (for analytics)
    uint256 public totalValueLocked;

    // ─── Events ─────────────────────────────────────────────────────

    event Staked(
        address indexed user,
        uint256 indexed positionId,
        address token,
        uint256 amount,
        uint256 dotOneStakeId
    );

    event Compounded(
        address indexed user,
        uint256 indexed positionId,
        uint256 rewardAmount,
        uint256 newPrincipal
    );

    event Unstaked(
        address indexed user,
        uint256 indexed positionId,
        uint256 totalAmount
    );

    event TokenSupportUpdated(address indexed token, bool supported);
    event CompoundIntervalUpdated(uint256 oldInterval, uint256 newInterval);

    // ─── Errors ─────────────────────────────────────────────────────

    error TokenNotSupported();
    error PositionNotActive();
    error CompoundTooSoon();
    error ZeroAmount();
    error InvalidInterval();
    error NotPositionOwner();

    // ─── Modifiers ──────────────────────────────────────────────────

    modifier onlyPositionOwner(uint256 positionId) {
        if (positions[msg.sender][positionId].dotOneStakeId == 0) {
            revert NotPositionOwner();
        }
        _;
    }

    // ─── Constructor ────────────────────────────────────────────────

    constructor(address _dotOneStaking) Ownable(msg.sender) {
        require(_dotOneStaking != address(0), "invalid staking contract");
        dotOneStaking = IDotOneStaking(_dotOneStaking);
    }

    // ─── Admin Functions ────────────────────────────────────────────

    /// @notice Add or remove a supported token
    function setTokenSupport(address token, bool supported) external onlyOwner {
        supportedTokens[token] = supported;
        emit TokenSupportUpdated(token, supported);
    }

    /// @notice Update auto-compound interval
    function setCompoundInterval(uint256 interval) external onlyOwner {
        if (interval < MIN_COMPOUND_INTERVAL || interval > MAX_COMPOUND_INTERVAL) {
            revert InvalidInterval();
        }
        uint256 old = compoundInterval;
        compoundInterval = interval;
        emit CompoundIntervalUpdated(old, interval);
    }

    // ─── Core Functions ─────────────────────────────────────────────

    /// @notice Stake tokens with auto-compound enabled
    /// @param token ERC-20 token address
    /// @param amount Amount to stake
    function stake(
        address token,
        uint256 amount
    ) external nonReentrant returns (uint256 positionId) {
        if (amount == 0) revert ZeroAmount();
        if (!supportedTokens[token]) revert TokenNotSupported();

        // Transfer tokens from user
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Approve DotOne staking contract
        IERC20(token).forceApprove(address(dotOneStaking), amount);

        // Stake on DotOne (tier auto-selected)
        uint256 dotOneStakeId = dotOneStaking.stake(token, amount);

        // Create position
        positionId = positionCount[msg.sender]++;
        positions[msg.sender][positionId] = Position({
            dotOneStakeId: dotOneStakeId,
            token: token,
            principal: amount,
            accumulatedRewards: 0,
            lastCompound: block.timestamp,
            active: true
        });

        totalValueLocked += amount;

        emit Staked(msg.sender, positionId, token, amount, dotOneStakeId);
    }

    /// @notice Manually trigger compound for a position
    /// @param positionId Position ID to compound
    function compound(uint256 positionId) external nonReentrant onlyPositionOwner(positionId) {
        Position storage pos = positions[msg.sender][positionId];

        if (!pos.active) revert PositionNotActive();
        if (block.timestamp < pos.lastCompound + compoundInterval) {
            revert CompoundTooSoon();
        }

        // Claim rewards from DotOne
        uint256 reward = dotOneStaking.claimRewards(pos.dotOneStakeId);

        if (reward > 0) {
            // Approve and re-stake rewards
            IERC20(pos.token).forceApprove(address(dotOneStaking), reward);
            dotOneStaking.stake(pos.token, reward);

            pos.principal += reward;
            totalValueLocked += reward;
        }

        pos.lastCompound = block.timestamp;

        emit Compounded(msg.sender, positionId, reward, pos.principal);
    }

    /// @notice Unstake and withdraw principal + rewards
    /// @param positionId Position ID to unstake
    function unstake(uint256 positionId) external nonReentrant onlyPositionOwner(positionId) {
        Position storage pos = positions[msg.sender][positionId];

        if (!pos.active) revert PositionNotActive();

        // Unstake from DotOne
        uint256 total = dotOneStaking.unstake(pos.dotOneStakeId);

        pos.active = false;
        totalValueLocked -= pos.principal;

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

    /// @notice Get pending rewards for a position
    function getPendingRewards(uint256 positionId, address user)
        external
        view
        returns (uint256)
    {
        Position storage pos = positions[user][positionId];
        if (!pos.active) return 0;
        return dotOneStaking.pendingRewards(pos.dotOneStakeId);
    }

    /// @notice Check if position can be compounded
    function canCompound(uint256 positionId, address user)
        external
        view
        returns (bool)
    {
        Position storage pos = positions[user][positionId];
        return pos.active && block.timestamp >= pos.lastCompound + compoundInterval;
    }

    /// @notice Get tier info for a token
    function getTiers(address token)
        external
        view
        returns (IDotOneStaking.Tier[] memory)
    {
        return dotOneStaking.getTiers(token);
    }
}
