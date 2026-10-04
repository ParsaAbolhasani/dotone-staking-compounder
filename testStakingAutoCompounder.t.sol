// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {StakingAutoCompounder} from "../contracts/StakingAutoCompounder.sol";
import {IDotOneStaking} from "../contracts/interfaces/IDotOneStaking.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ─── Mock Contracts ─────────────────────────────────────────────────

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract MockDotOneStaking is IDotOneStaking {
    mapping(uint256 => StakeInfo) public stakes;
    mapping(uint256 => uint256) public rewards;
    uint256 public nextStakeId = 1;

    function stake(address token, uint256 amount) external returns (uint256) {
        uint256 id = nextStakeId++;
        stakes[id] = StakeInfo({
            token: token,
            amount: amount,
            tierId: 0,
            startTime: block.timestamp,
            unlockTime: block.timestamp + 90 days,
            active: true
        });
        return id;
    }

    function unstake(uint256 stakeId) external returns (uint256) {
        StakeInfo storage s = stakes[stakeId];
        s.active = false;
        return s.amount + rewards[stakeId];
    }

    function claimRewards(uint256 stakeId) external returns (uint256) {
        uint256 reward = rewards[stakeId];
        rewards[stakeId] = 0;
        return reward;
    }

    function getTiers(address) external pure returns (Tier[] memory tiers) {
        tiers = new Tier[](3);
        tiers[0] = Tier(800, 1800, 90 days, 1000e18, 1500, 100, true);
        tiers[1] = Tier(2000, 3500, 180 days, 10000e18, 2000, 150, true);
        tiers[2] = Tier(3500, 5000, 365 days, 50000e18, 3000, 200, true);
    }

    function getStakeInfo(uint256 stakeId) external view returns (StakeInfo memory) {
        return stakes[stakeId];
    }

    function pendingRewards(uint256 stakeId) external view returns (uint256) {
        return rewards[stakeId];
    }

    function setReward(uint256 stakeId, uint256 amount) external {
        rewards[stakeId] = amount;
    }
}

// ─── Tests ──────────────────────────────────────────────────────────

contract StakingAutoCompounderTest is Test {
    StakingAutoCompounder public compounder;
    MockDotOneStaking public dotOneStaking;
    MockToken public token;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        dotOneStaking = new MockDotOneStaking();
        compounder = new StakingAutoCompounder(address(dotOneStaking));
        token = new MockToken();

        compounder.setTokenSupport(address(token), true);

        token.mint(alice, 1_000_000e18);
        token.mint(bob, 1_000_000e18);
    }

    // ─── Stake Tests ────────────────────────────────────────────────

    function test_Stake_Success() public {
        vm.startPrank(alice);
        token.approve(address(compounder), 10_000e18);
        uint256 positionId = compounder.stake(address(token), 10_000e18);
        vm.stopPrank();

        assertEq(positionId, 0);
        assertEq(compounder.positionCount(alice), 1);
        assertEq(compounder.totalValueLocked(), 10_000e18);
    }

    function test_Stake_RevertsOnZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(StakingAutoCompounder.ZeroAmount.selector);
        compounder.stake(address(token), 0);
    }

    function test_Stake_RevertsOnUnsupportedToken() public {
        MockToken otherToken = new MockToken();
        vm.prank(alice);
        vm.expectRevert(StakingAutoCompounder.TokenNotSupported.selector);
        compounder.stake(address(otherToken), 1000e18);
    }

    // ─── Compound Tests ─────────────────────────────────────────────

    function test_Compound_AfterInterval() public {
        // Stake
        vm.startPrank(alice);
        token.approve(address(compounder), 10_000e18);
        compounder.stake(address(token), 10_000e18);
        vm.stopPrank();

        // Set reward
        dotOneStaking.setReward(1, 500e18);

        // Warp past interval
        vm.warp(block.timestamp + 8 days);

        // Compound
        vm.prank(alice);
        compounder.compound(0);

        // Check principal increased
        (, , uint256 principal, , , ) = compounder.positions(alice, 0);
        assertEq(principal, 10_500e18);
    }

    function test_Compound_RevertsTooSoon() public {
        vm.startPrank(alice);
        token.approve(address(compounder), 10_000e18);
        compounder.stake(address(token), 10_000e18);

        vm.expectRevert(StakingAutoCompounder.CompoundTooSoon.selector);
        compounder.compound(0);
        vm.stopPrank();
    }

    // ─── Unstake Tests ──────────────────────────────────────────────

    function test_Unstake_Success() public {
        vm.startPrank(alice);
        token.approve(address(compounder), 10_000e18);
        compounder.stake(address(token), 10_000e18);

        uint256 balanceBefore = token.balanceOf(alice);
        compounder.unstake(0);
        uint256 balanceAfter = token.balanceOf(alice);

        vm.stopPrank();

        assertEq(balanceAfter - balanceBefore, 10_000e18);
        assertEq(compounder.totalValueLocked(), 0);
    }

    function test_Unstake_RevertsIfNotOwner() public {
        vm.startPrank(alice);
        token.approve(address(compounder), 10_000e18);
        compounder.stake(address(token), 10_000e18);
        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert(StakingAutoCompounder.NotPositionOwner.selector);
        compounder.unstake(0);
    }

    // ─── View Tests ─────────────────────────────────────────────────

    function test_GetActivePositions() public {
        vm.startPrank(alice);
        token.approve(address(compounder), 20_000e18);
        compounder.stake(address(token), 10_000e18);
        compounder.stake(address(token), 10_000e18);
        vm.stopPrank();

        StakingAutoCompounder.Position[] memory active = compounder.getActivePositions(alice);
        assertEq(active.length, 2);
    }

    function test_CanCompound() public {
        vm.startPrank(alice);
        token.approve(address(compounder), 10_000e18);
        compounder.stake(address(token), 10_000e18);
        vm.stopPrank();

        assertFalse(compounder.canCompound(0, alice));

        vm.warp(block.timestamp + 8 days);
        assertTrue(compounder.canCompound(0, alice));
    }
}
