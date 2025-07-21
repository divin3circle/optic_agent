# Optic Agent - ICPSwap V3 Integration

An Internet Computer canister that automatically manages ICP investments through ICPSwap V3. The canister accepts ICP payments, swaps them to ckUSDC, and provides liquidity to earn fees.

## What This Canister Does

### Accept ICP Payments

By defining a `@update({"payable":true})` func `deposit() : async ()` in Motoko, users can send ICP directly to the canister.

### Query Balances

The `icrc1_balance_of` query on the imported ledger interface lets the agent inspect its own ICP balance (and later ckUSDC after swapping) on-chain.

### Transfer/Swap

With the `icrc1_transfer` method, the canister invokes swaps on ICPSwap's canister by crafting the right `TransferArg`. It wraps half the ICP into ckUSDC and then uses `addLiquidity` on the pool canister.

### Autonomous Logic & Heartbeat

Motoko has built-in `actor { heartbeat }` support, so `runInvestmentCycle()` fires automatically at each interval.

## Key Methods

### Deposit Functions

- `deposit()` - Accept ICP payments
- `depositCkUsdc()` - Accept ckUSDC payments
- `depositCkBtc()` - Accept ckBTC payments

### Balance Functions

- `getBalances()` - Get current token balances
- `getDetailedBalances()` - Get detailed balance info with position values

### Investment Functions

- `runInvestmentCycle()` - Execute swap and liquidity provision
- `collectFees()` - Collect fees from liquidity positions

### Position Management

- `getPositions()` - Get local position data
- `getAllPoolPositions()` - Get all positions from ICPSwap
- `getUnusedBalances()` - Get unused balances in pool

## Architecture

### Canister IDs

- **ICP Ledger**: `ryjl3-tyaaa-aaaaa-aaaba-cai`
- **ckUSDC Ledger**: `xevnm-gaaaa-aaaar-qafnq-cai`
- **ICPSwap Factory**: `4mmnk-kiaaa-aaaag-qbllq-cai`
- **ICP/ckUSDC Pool**: `mohjv-bqaaa-aaaag-qjyia-cai`
- **SwapCalculator**: `phr2m-oyaaa-aaaag-qjuoq-cai`

### Investment Process

1. **Receive ICP** via `deposit()` function
2. **Query balance** using `icrc1_balance_of`
3. **Swap half ICP to ckUSDC** using ICPSwap's `depositAndSwap`
4. **Add liquidity** to ICP/ckUSDC pool with optimal tick range
5. **Track position** and collect fees over time
6. **Repeat** via heartbeat automation

## Usage

```bash
# Deploy
dfx deploy

# Check balances
dfx canister call optic_agent_backend getDetailedBalances

# Run investment cycle manually
dfx canister call optic_agent_backend runInvestmentCycle

# Collect fees
dfx canister call optic_agent_backend collectFees
```

## Token Information

- **ICP**: 8 decimals, fee: 10,000
- **ckUSDC**: 6 decimals, fee: 0
- **Pool Fee**: 0.3% (3000)

---

**Note**: This canister automatically manages ICP investments through ICPSwap V3, providing liquidity and earning fees from trading activity.
