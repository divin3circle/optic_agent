# Optic Agent - ICPSwap V3 Integration

An Internet Computer canister that automatically manages ICP investments through ICPSwap V3, including token swaps, liquidity provision, and position management.

## 🎉 **Status: Fully Functional**

✅ **ICPSwap V3 Integration Complete**  
✅ **Real Token Amount Calculation Working**  
✅ **Pool Metadata Integration Working**  
✅ **Position Management Working**  
✅ **Balance Tracking Working**

## Features

### ✅ **Multi-Token Support**

- **ICP**: Native Internet Computer token
- **ckUSDC**: ICRC1 USDC token on IC
- **ckBTC**: ICRC1 Bitcoin token on IC (future support)

### ✅ **Automated Investment Cycle**

1. **Receive ICP deposits** from users
2. **Swap half ICP to ckUSDC** using ICPSwap V3
3. **Add liquidity** to ICP/ckUSDC pool
4. **Track positions** and collect fees
5. **Report balances** for dashboard display

### ✅ **ICPSwap V3 Integration**

- Uses ICPSwap V3's `depositAndSwap` method for ICRC1 tokens
- Proper two-step liquidity provision process
- Position management via NFT-based positions
- Fee collection and balance tracking
- **Real token amount calculation** using SwapCalculator

### ✅ **Position Management**

- NFT-based liquidity positions (not fungible LP tokens)
- Unique position IDs for each liquidity position
- Fee collection from positions
- Position transfer and management
- **Accurate token amount calculation** for position values

## Architecture

### **Canister Structure**

```
OpticAgent
├── Token Ledgers (ICP, ckUSDC, ckBTC)
├── ICPSwap V3 Integration
│   ├── SwapFactory
│   ├── SwapPool (ICP/ckUSDC)
│   └── SwapCalculator
└── Position Management
```

### **Key Components**

#### **Token Ledgers**

- **ICP Ledger**: `ryjl3-tyaaa-aaaaa-aaaba-cai`
- **ckUSDC Ledger**: `xevnm-gaaaa-aaaar-qafnq-cai`
- **ckBTC Ledger**: `mxzaz-hqaaa-aaaar-qaada-cai`

#### **ICPSwap V3 Canisters**

- **SwapFactory**: `4mmnk-kiaaa-aaaag-qbllq-cai`
- **ICP/ckUSDC Pool**: `mohjv-bqaaa-aaaag-qjyia-cai`
- **SwapCalculator**: `phr2m-oyaaa-aaaag-qjuoq-cai`

## API Reference

### **Deposit Functions**

#### `deposit()`

Receive ICP deposits from users.

```motoko
public shared({ caller = _ }) func deposit() : async ()
```

#### `depositCkUsdc()`

Receive ckUSDC deposits from users.

```motoko
public shared({ caller = _ }) func depositCkUsdc() : async ()
```

#### `depositCkBtc()`

Receive ckBTC deposits from users.

```motoko
public shared({ caller = _ }) func depositCkBtc() : async ()
```

### **Balance Functions**

#### `getBalances()`

Get current balances of all tokens and liquidity positions.

```motoko
public shared func getBalances() : async Balances
```

Returns:

```motoko
type Balances = {
  icp : Float;
  ckUsdc : Float;
  ckBtc : Float;
  positions : Float;
}
```

#### `getDetailedBalances()` ✅ **WORKING**

Get detailed balance information with raw amounts and display values. **Now calculates real token amounts in positions using ICPSwap's SwapCalculator.**

```motoko
public shared func getDetailedBalances() : async {
  icp : { amount : Nat; display : Float };
  ckUsdc : { amount : Nat; display : Float };
  ckBtc : { amount : Nat; display : Float };
  positions : Float;
}
```

**Features:**

- ✅ Real token amount calculation (not just liquidity numbers)
- ✅ Proper decimal conversion (8 for ICP, 6 for ckUSDC)
- ✅ USD value approximation for position reporting
- ✅ Graceful error handling with fallback values

#### `testMetadata()` ✅ **WORKING**

Test function to verify pool metadata integration.

```motoko
public shared func testMetadata() : async Pool.MetadataResult
```

Returns pool metadata including:

- Current tick: -27994
- sqrtPriceX96: 19545085355429929225629290197
- Liquidity: 4918348185919
- Token information and pool configuration

### **Investment Functions**

#### `runInvestmentCycle()`

Execute the main investment cycle: swap ICP to ckUSDC and add liquidity.

```motoko
public shared func runInvestmentCycle() : async InvestmentEvent
```

Returns:

```motoko
type InvestmentEvent = {
  swappedIcp : Float;
  receivedCkUsdc : Float;
  providedIcp : Float;
  providedCkUsdc : Float;
  mintedLp : Float;
  timestamp : Int;
}
```

**Process:**

1. **Swap**: Use `depositAndSwap` to convert ICP to ckUSDC
2. **Deposit**: Deposit both tokens to the pool
3. **Mint**: Create liquidity position with optimal tick range
4. **Track**: Store new position and return event data

### **Position Management**

#### `getPositions()`

Get local position tracking data.

```motoko
public shared func getPositions() : async [Position]
```

#### `getAllPoolPositions()`

Get all positions from ICPSwap pool.

```motoko
public shared func getAllPoolPositions() : async [Pool.Position]
```

#### `collectFees()`

Collect fees from all liquidity positions.

```motoko
public shared func collectFees() : async { amount0 : Nat; amount1 : Nat }
```

#### `getUnusedBalances()`

Get unused token balances in the pool.

```motoko
public shared func getUnusedBalances() : async { amount0 : Nat; amount1 : Nat }
```

### **System Functions**

#### `init()`

Initialize the canister.

```motoko
public shared func init() : async ()
```

#### `heartbeat()`

System function called periodically to run investment cycles.

```motoko
system func heartbeat() : async ()
```

## Implementation Details

### **ICPSwap V3 Integration** ✅ **COMPLETE**

#### **Token Standards**

- **ICP**: Native IC token (handled automatically by ICPSwap)
- **ckUSDC**: ICRC1 token (requires `depositAndSwap` method)
- **ckBTC**: ICRC1 token (future implementation)

#### **Liquidity Provision Process**

1. **Quote**: Get current exchange rate
2. **Deposit & Swap**: Use `depositAndSwap` for ICRC1 tokens
3. **Deposit Tokens**: Add both tokens to pool for liquidity
4. **Mint Position**: Create concentrated liquidity position
5. **Track Position**: Store position ID and metadata

#### **Real Token Amount Calculation** ✅ **IMPLEMENTED**

The canister now properly calculates actual token amounts in positions using ICPSwap's documentation workflow:

1. **Get Pool Metadata**: Retrieve current tick, sqrtPriceX96, and liquidity
2. **Get Position Data**: Retrieve position tickLower, tickUpper, and liquidity
3. **Calculate Token Amounts**: Use SwapCalculator.getTokenAmountByLiquidity
4. **Convert to Display Values**: Apply proper decimal conversion

```motoko
// Example workflow implementation
let poolMetadata = await icpPool.metadata();
let positionData = await icpPool.getUserPosition(positionId);
let tokenAmounts = await swapCalculator.getTokenAmountByLiquidity(
  position.liquidity,
  position.tickLower,
  position.tickUpper,
  poolMetadata.tick,
  poolMetadata.sqrtPriceX96,
  poolMetadata.liquidity
);
```

#### **Tick Range Calculation**

```motoko
func calculateTickRange(price : Float, volatility : ?Float) : async (Int, Int)
```

- Uses ICPSwap's built-in `priceToTick` method
- Calculates optimal range based on current price
- Supports dynamic volatility adjustment
- Ensures valid tick spacing for 0.3% fee tier

### **Interface Integration** ✅ **FIXED**

#### **Correct Candid Interface**

The canister now uses the exact interface from ICPSwap's `.did` file:

- ✅ **Metadata**: Returns `{ #ok : PoolMetadata; #err : Error }`
- ✅ **Position IDs**: Returns `{ #ok : [Nat]; #err : Error }`
- ✅ **Variant Tags**: Uses lowercase tags (`#ok`, `#err`) to match Candid
- ✅ **Parameter Types**: Uses `Principal` instead of `Account` for user methods

#### **Error Handling**

- Comprehensive error handling for each step
- Graceful failure recovery
- Detailed error messages for debugging
- Transaction rollback on failures
- **Fallback to liquidity values** if token calculation fails

### **Security Features**

- Proper principal validation
- Slippage protection (1% default)
- Deadline enforcement (5 minutes)
- Fee validation for each token

## Usage Examples

### **Basic Investment Cycle**

```bash
# Deploy the canister
dfx deploy

# Test metadata integration
dfx canister call optic_agent_backend testMetadata

# Run investment cycle
dfx canister call optic_agent_backend runInvestmentCycle

# Check detailed balances (with real token amounts)
dfx canister call optic_agent_backend getDetailedBalances

# Collect fees
dfx canister call optic_agent_backend collectFees
```

### **Monitor Positions**

```bash
# Get all positions
dfx canister call optic_agent_backend getAllPoolPositions

# Get unused balances
dfx canister call optic_agent_backend getUnusedBalances
```

### **Example Output**

```bash
# getDetailedBalances output
{
  icp = { display = 0; amount = 0 };
  ckBtc = { display = 0; amount = 0 };
  ckUsdc = { display = 0; amount = 0 };
  positions = 0
}

# testMetadata output
{
  ok = {
    fee = 3000;
    key = "ryjl3-tyaaa-aaaaa-aaaba-cai_xevnm-gaaaa-aaaar-qafnq-cai_3000";
    sqrtPriceX96 = 19545085355429929225629290197;
    tick = -27994;
    liquidity = 4918348185919;
    token0 = { address = "ryjl3-tyaaa-aaaaa-aaaba-cai"; standard = "ICRC2" };
    token1 = { address = "xevnm-gaaaa-aaaar-qafnq-cai"; standard = "ICRC2" };
    maxLiquidityPerTick = 11505743598341114571880798222544994;
    nextPositionId = 2751
  }
}
```

## Development

### **Prerequisites**

- DFX SDK
- Internet Computer network access
- Motoko development environment

### **Build & Deploy**

```bash
# Build the canister
dfx build optic_agent_backend

# Deploy to local network
dfx deploy

# Deploy to mainnet
dfx deploy --network ic
```

### **Testing**

```bash
# Run tests
dfx test

# Check canister status
dfx canister status optic_agent_backend
```

## Token Information

### **Decimals**

- **ICP**: 8 decimals (100,000,000 = 1 ICP)
- **ckUSDC**: 6 decimals (1,000,000 = 1 USDC)
- **ckBTC**: 8 decimals (100,000,000 = 1 BTC)

### **Fees**

- **ICP**: 10,000 (0.0001 ICP)
- **ckUSDC**: 0 (no fee)
- **ckBTC**: 10 (0.0000001 BTC)

### **Pool Configuration**

- **Fee Tier**: 0.3% (3000)
- **Tick Spacing**: 60
- **Concentrated Liquidity**: Yes

## Future Enhancements

### **Planned Features**

- [ ] ckBTC integration for multi-token pools
- [ ] Dynamic fee optimization
- [ ] Advanced position management
- [ ] Automated rebalancing
- [ ] Performance analytics
- [ ] Multi-pool support

### **Potential Improvements**

- [ ] Gas optimization
- [ ] Batch operations
- [ ] Advanced slippage protection
- [ ] Real-time price feeds
- [ ] Risk management features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support:

- Create an issue on GitHub
- Check the ICPSwap documentation
- Review the Internet Computer documentation

---

**Note**: This canister is designed for educational and development purposes. Always test thoroughly before using with real funds.

**Status**: ✅ **Fully functional with complete ICPSwap V3 integration and real token amount calculation.**
