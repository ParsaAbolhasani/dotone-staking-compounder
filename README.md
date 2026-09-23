<!-- ═══════════════════════════════════════════════════════════════════ -->
<!--              DOTONE STAKING AUTO-COMPOUNDER — README               -->
<!-- ═══════════════════════════════════════════════════════════════════ -->

<div align="center">

# 🔷 DotOne Staking Auto-Compounder

### A production-grade dApp for DotOne Smart Chain that automates staking reward compounding

**Auto-Compound · Multi-Tier Support · EVM-Compatible · PoSA-Native**

<br />

[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?logo=solidity&logoColor=white)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000?logo=foundry&logoColor=white)](https://book.getfoundry.sh/)
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=nextdotjs&logoColor=white)](https://nextjs.org/)
[![Chain](https://img.shields.io/badge/Chain-DotOne%20(505)-0A66C2)](https://dotscan.one)
[![PoSA](https://img.shields.io/badge/Consensus-PoSA-4B5563)](https://docs.dotone.network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-24%20passing-brightgreen)](test/)
[![Coverage](https://img.shields.io/badge/coverage-96%25-brightgreen)](test/)

<br />

[Overview](#-overview) ·
[Why DotOne](#-why-dotone) ·
[Architecture](#-architecture) ·
[Staking Tiers](#-staking-tiers) ·
[Quick Start](#-quick-start) ·
[Testing](#-testing) ·
[Deployment](#-deployment) ·
[Roadmap](#-roadmap) ·
[Security](#-security)

</div>

---

## 📖 Overview

**DotOne Staking Auto-Compounder** is a production-ready decentralized application
built natively for **DotOne Smart Chain** — a high-performance, EVM-compatible
Layer 1 secured by **Proof of Staked Authority (PoSA)** consensus.

The protocol solves a concrete UX problem in DotOne's native staking system:
users must **manually claim and re-stake** their rewards to maximize compounding
returns. This dApp **automates that process end-to-end**, turning a tedious
multi-step workflow into a single, gas-efficient transaction.

### The Problem

On DotOne's native staking, rewards accrue continuously but sit idle unless
the user manually:

1. Connects their wallet
2. Calls `claimRewards()`
3. Waits for the transaction to confirm
4. Calls `stake()` again with the claimed amount

This is not only tedious — it also means users **lose compounding time** every
cycle. Over a 12-month horizon, manual compounding can cost users **5–15%** of
their total yield compared to automatic compounding.

### The Solution

`StakingAutoCompounder` wraps DotOne's staking contract with an intelligent
auto-compound layer:

- **One-time approval** — users approve the compounder once
- **Position tracking** — every stake is stored as an on-chain `Position`
- **Auto-compound** — rewards are claimed and re-staked atomically
- **Tier-aware** — works with DotOne's automatic tier-selection logic
- **Frontend dashboard** — full Next.js UI with wallet connect, live positions, and analytics

---

## 🎯 Why DotOne

DotOne Smart Chain is uniquely positioned for this kind of DeFi primitive:

| Feature | Value | Why It Matters |
|---------|-------|----------------|
| **Consensus** | PoSA (Proof of Staked Authority) | Fast finality, low energy, enterprise-grade |
| **Chain ID** | 505 | Stable, production-ready |
| **Native Token** | DOTO | 18 decimals, EVM-native |
| **Block Gas Limit** | 70,000,000 | Supports complex multi-step transactions |
| **EVM Compatibility** | Full | Reuse of Solidity, Foundry, OpenZeppelin |
| **Explorer** | dotscan.one | Full contract verification support |
| **SDK** | `@dotone/sdk` | Typed access to tiers, positions, and rewards |
| **RPC** | `https://rpc.dotone.network` | Public endpoint, no API key required |

DotOne's **auto-tier selection** — where the tier is chosen by the protocol
based on stake amount, not by the user — is a deliberate design decision that
removes cognitive load. This project **embraces** that design rather than
fighting it.

---

## 🏗️ Architecture


### Contract Layout

| Contract | Responsibility |
|----------|----------------|
| `StakingAutoCompounder.sol` | Core wrapper — stake, compound, unstake, position tracking |
| `IDotOneStaking.sol` | Interface to DotOne's native staking contract |
| `MockDotOneStaking.sol` | Test mock simulating tier auto-selection |
| `MockToken.sol` | Test ERC-20 with public mint |

### Frontend Layout

| File | Responsibility |
|------|----------------|
| `config/dotone.ts` | Chain definition, tier config, contract addresses |
| `hooks/useDotOneSDK.ts` | Wallet connect, SDK calls, contract interactions |
| `pages/index.tsx` | Main dashboard — stake panel + positions panel |

---

## 🏆 Staking Tiers

DotOne's staking system uses **automatic tier selection** — the tier is
determined by the protocol based on the stake amount, not chosen by the user.
This design removes friction and prevents users from selecting a tier that
mismatches their risk profile.

| Tier | Name | APY Range | Lock Period | Min Investment | Performance Fee | Management Fee |
|------|------|-----------|-------------|----------------|-----------------|----------------|
| **0** | Low Risk | 8% – 18% | 90 days | 1,000 tokens | 15% | 1% |
| **1** | Medium Risk | 20% – 35% | 180 days | 10,000 tokens | 20% | 1.5% |
| **2** | High Risk | 35% – 50% | 365 days | 50,000 tokens | 30% | 2% |

### Auto-Selection Logic


The `StakingAutoCompounder` **never overrides** this logic. It reads tier
metadata via `IDotOneStaking.getTiers()` for display purposes only, and
delegates all tier decisions to DotOne's native contract.

### Auto-Compound Interval

| Parameter | Default | Min | Max |
|-----------|---------|-----|-----|
| `compoundInterval` | 7 days | 1 day | 30 days |

The interval is configurable by the contract owner. Users can manually trigger
`compound()` any time the interval has elapsed.

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Foundry | latest | Smart contract build & test |
| Node.js | ≥ 18 | Frontend & tooling |
| Git | ≥ 2.30 | Version control |
| MetaMask | latest | Wallet connection |

### Installation

bash
# 1. Clone repository
git clone https://github.com/<your-username>/dotone-staking-compounder.git
cd dotone-staking-compounder

# 2. Install Foundry dependencies
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts

# 3. Install frontend dependencies
cd frontend && npm install && cd ..

# 4. Copy environment template
cp .env.example .env

Environment Configuration

# ─── RPC Endpoints ──────────────────────────────────────────────────
DOTONE_RPC_URL=https://rpc.dotone.network
DOTONE_TESTNET_RPC_URL=https://rpc-testnet.dotone.network

# ─── Deployment ─────────────────────────────────────────────────────
PRIVATE_KEY=0xYOUR_PRIVATE_KEY

# ─── Contract Addresses (fill after deployment) ─────────────────────
DOTONE_STAKING_ADDRESS=0x...
COMPOUNDER_ADDRESS=0x...

# ─── Explorer ───────────────────────────────────────────────────────
DOTSCAN_API_KEY=YOUR_API_KEY

Build
# Compile contracts
forge build

# Compile frontend
cd frontend && npm run build && cd ..

Run Tests
# All tests with verbosity
forge test -vvv

# Specific test contract
forge test --match-contract StakingAutoCompounderTest -vvv

# Coverage report
forge coverage --report summary

Run Locally

# Terminal 1 — start local chain
anvil --chain-id 505

# Terminal 2 — deploy contracts
forge script script/Deploy.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast

# Terminal 3 — start frontend
cd frontend && npm run dev

Open http://localhost:3000 in your browser.

🧪 Testing
The test suite covers every code path, including boundary conditions,
attack vectors, and gas benchmarks.

Test Structure
test/
└── StakingAutoCompounder.t.sol    # 24 tests covering all functions

Test Categories
Category	Tests	Description
Stake	3	Success, zero amount, unsupported token
Compound	2	Success after interval, revert too soon
Unstake	2	Success, revert if not owner
Views	2	Active positions, can-compound check
Admin	2	Token support, interval update
Edge Cases	5	Multiple positions, ownership, reentrancy
Fuzz	4	Payout math, share accounting
Gas	4	Deposit, withdraw, compound benchmarks

Running Tests
# Full suite
forge test

# Verbose output
forge test -vvv

# Specific function
forge test --match-test test_Stake_Success

# Fuzz with 10,000 iterations
forge test --fuzz-runs 10000

# Gas report
forge test --gas-report

# Coverage
forge coverage --report lcov

Expected Output
Ran 24 tests for test/StakingAutoCompounder.t.sol:StakingAutoCompounderTest
[PASS] test_Stake_Success
[PASS] test_Stake_RevertsOnZeroAmount
[PASS] test_Stake_RevertsOnUnsupportedToken
[PASS] test_Compound_AfterInterval
[PASS] test_Compound_RevertsTooSoon
[PASS] test_Unstake_Success
[PASS] test_Unstake_RevertsIfNotOwner
[PASS] test_GetActivePositions
[PASS] test_CanCompound
[PASS] test_SetTokenSupport
[PASS] test_SetCompoundInterval
[PASS] test_SetCompoundInterval_RevertsOnInvalid
[PASS] test_MultiplePositions
[PASS] test_PositionOwnership
... (10 more)

Suite result: ok. 24 passed; 0 failed; 0 skipped

Coverage
File	Statements	Branches	Functions	Lines
StakingAutoCompounder.sol	100%	96%	100%	100%
IDotOneStaking.sol	N/A	N/A	N/A	N/A

📦 Deployment
Step 1: Deploy to DotOne Testnet
forge script script/Deploy.s.sol \
  --rpc-url $DOTONE_TESTNET_RPC_URL \
  --broadcast \
  --verify

  Step 2: Verify on DotScan
  forge verify-contract \
  --chain 505 \
  --compiler-version 0.8.24 \
  $COMPOUNDER_ADDRESS \
  contracts/StakingAutoCompounder.sol:StakingAutoCompounder \
  --constructor-args $(cast abi-encode "constructor(address)" $DOTONE_STAKING_ADDRESS)

  Step 3: Configure Supported Tokens
  cast send $COMPOUNDER_ADDRESS \
  "setTokenSupport(address,bool)" \
  $TOKEN_ADDRESS \
  true \
  --private-key $PRIVATE_KEY \
  --rpc-url $DOTONE_RPC_URL

  Step 4: Update Frontend Config
Edit frontend/src/config/dotone.ts:
export const CONTRACTS = {
  stakingAutoCompounder: '0x...', // ← Deployed address
  dotOneStaking: '0x...',         // ← DotOne native staking
} as const;

Step 5: Deploy Frontend
cd frontend
npm run build
npm run start

Or deploy to Vercel:
vercel --prod

🗺️ Roadmap
v0.1.0 — Core (Current)
☑ StakingAutoCompounder.sol with stake/compound/unstake
☑ Position tracking per user
☑ Auto-compound interval (1–30 days)
☑ Token support whitelist
☑ 24 passing tests, 96% coverage
☑ Next.js frontend with wagmi
☑ DotOne Chain config (Chain ID 505)
v0.2.0 — Automation
□ Chainlink Automation integration for trustless compounding
□ Gelato Network support as alternative keeper
□ Gasless compounding via ERC-2771 meta-transactions
□ Batch compound for multiple positions
v0.3.0 — Analytics
□ Historical APY tracking per position
□ Realized vs. unrealized yield breakdown
□ Tier migration suggestions
□ Export to CSV/JSON
v0.4.0 — Social
□ Leaderboard of top compounders
□ Referral system with fee sharing
□ Achievement NFTs for milestones
□ Telegram/Discord bot notifications
v1.0.0 — Production
□ External security audit
□ Multi-sig treasury for fees
□ Mainnet launch on DotOne
□ Integration with DotOne's official dashboard

🔐 Security
Audit Status
⚠️ This code is unaudited. Do not deploy to DotOne mainnet with real
funds without a professional security review.

Mitigations in Place
Risk	Mitigation
Reentrancy	ReentrancyGuard on stake(), compound(), unstake()
Unauthorized access	onlyPositionOwner modifier on compound/unstake
Zero-amount attacks	ZeroAmount revert on all entry points
Unsupported tokens	Whitelist check via supportedTokens mapping
Compound spam	compoundInterval enforcement (min 1 day)
Interval abuse	MIN_COMPOUND_INTERVAL and MAX_COMPOUND_INTERVAL bounds
Position hijacking	Positions keyed by (user, positionId), not globally
Approve race condition	forceApprove instead of approve

Known Limitations
Keeper dependency — auto-compound requires off-chain trigger. Chainlink
Automation integration is planned for v0.2.0.

No emergency pause — a Pausable mechanism should be added before mainnet.

Owner centralization — setTokenSupport and setCompoundInterval are
onlyOwner. A timelock or multi-sig is recommended.

Tier metadata is display-only — the compounder does not verify tier APYs
on-chain; it trusts DotOne's native contract.

Reporting a Vulnerability
Please report security issues to security@yourdomain.com rather than
opening a public issue. We aim to respond within 48 hours

🛠️ Tech Stack
<div align="center">
Layer	Technology
Smart Contracts	Solidity 0.8.24
Framework	Foundry (forge, cast, anvil)
Libraries	OpenZeppelin Contracts
Chain	DotOne Smart Chain (Chain ID: 505)
Consensus	PoSA (Proof of Staked Authority)
SDK	@dotone/sdk
Frontend	Next.js 14, React 18
Web3	wagmi, viem
Styling	Tailwind CSS
Testing	Forge-std
CI/CD	GitHub Actions
</div>

📂 Project Structure
dotone-staking-compounder/
│
├── contracts/
│   ├── StakingAutoCompounder.sol       # 🔷 Core compounder
│   └── interfaces/
│       └── IDotOneStaking.sol          # 🔌 DotOne staking interface
│
├── test/
│   └── StakingAutoCompounder.t.sol     # 🧪 24 tests
│
├── script/
│   └── Deploy.s.sol                    # 🚀 Deployment script
│
├── frontend/
│   ├── src/
│   │   ├── config/
│   │   │   └── dotone.ts               # ⚙️ Chain + tier config
│   │   ├── hooks/
│   │   │   └── useDotOneSDK.ts         # 🪝 SDK integration
│   │   └── pages/
│   │       └── index.tsx               # 🖥️ Main dashboard
│   ├── package.json
│   └── tsconfig.json
│
├── foundry.toml                        # Foundry config
├── remappings.txt                      # Import remappings
├── .env.example                        # Environment template
├── .gitignore
├── LICENSE                             # MIT
└── README.md                           # ← You are here

🎬 Demo
What I'll Show at the DotOne Event
Live staking on DotOne Chain — deposit tokens, watch position appear

Auto-compound execution — trigger compound, see principal increase

Tier auto-selection — demonstrate how DotOne picks the tier

Position tracking — full dashboard with active positions

Gas benchmarks — show Foundry gas reports

Demo Screenshots
Screenshots will be added after testnet deployment.

🤝 Contributing
Contributions are welcome! Please follow these steps:

Fork the repository

Create a feature branch (git checkout -b feature/amazing-feature)

Commit your changes (git commit -m 'feat: add amazing feature')

Push to the branch (git push origin feature/amazing-feature)

Open a Pull Request

Commit Convention
feat: new feature

fix: bug fix

docs: documentation

test: test additions

refactor: code refactoring

chore: maintenance

Code Style
Solidity 0.8.24, forge fmt before commit

TypeScript strict mode, ESLint + Prettier

NatSpec comments for all public functions

100% test coverage for new code

📚 References
DotOne Chain
DotOne Website

DotScan Explorer
DotOne Documentation
@dotone/sdk on npm
Development Tools
Foundry Book
OpenZeppelin Contracts
wagmi Documentation
viem Documentation
Next.js Documentation

📝 License
This project is licensed under the MIT License — see the LICENSE
file for details.

👤 Author
<div align="center">
Parsa Abolhasani Rad
Senior Blockchain Engineer

https://www.linkedin.com/in/parsa-abolhasani-rad-/
https://github.com/ParsaAbolhasani

</div>


<div align="center">
⭐ If this project helps you, please give it a star!
Built with ❤️ for the DotOne Chain ecosystem


⬆ Back to Top

</div> ```
