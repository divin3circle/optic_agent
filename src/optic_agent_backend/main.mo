import Ledger "icp-ledger-interface";
import CkUsdcLedger "ckusdc-ledger-interface";
import CkBtcLedger "ckbtc-ledger-interface";
import Pool "icpswap-pool-interface";
import Factory "icpswap-factory-interface";
import Calculator "icpswap-calculator-interface";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Nat "mo:base/Nat";


actor OpticAgent {
  type Balances = { icp : Float; ckUsdc : Float; ckBtc : Float; positions : Float };

  type InvestmentEvent = {
    swappedIcp : Float; 
    receivedCkUsdc : Float; 
    providedIcp : Float;
    providedCkUsdc : Float; 
    mintedLp : Float; 
    timestamp : Int;
  };

  type Position = {
    tokenId : Nat;
    liquidity : Nat;
    feesEarned0 : Nat;
    feesEarned1 : Nat;
  };

  // Canister IDs - 
  let ledgerCanister : Ledger.Self = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
  let ckUsdcLedger : CkUsdcLedger.Self = actor("xevnm-gaaaa-aaaar-qafnq-cai");
  let ckBtcLedger : CkBtcLedger.Self = actor("mxzaz-hqaaa-aaaar-qaada-cai");
  let swapFactory : Factory.Self = actor("4mmnk-kiaaa-aaaag-qbllq-cai");
  let icpPool : Pool.Self = actor("mohjv-bqaaa-aaaag-qjyia-cai");
  let swapCalculator : Calculator.Self = actor("phr2m-oyaaa-aaaag-qjuoq-cai");
  
  // Token addresses 
  let ICP_TOKEN = "ryjl3-tyaaa-aaaaa-aaaba-cai";
  let CKUSDC_TOKEN = "xevnm-gaaaa-aaaar-qafnq-cai";
  
  // Token decimals
  let ICP_DECIMALS = 8.0;
  let CKUSDC_DECIMALS = 6.0;
  
  // Pool fee tier (0.3% = 3000)
  let POOL_FEE = 3000;
  
  // Store our positions
  var positions : [Position] = [];

  public shared({ caller = _ }) func deposit() : async () {
    // This function can receive ICP from any user
    // The ICP will be automatically credited to this canister's account
  };

  public shared({ caller = _ }) func depositCkUsdc() : async () {
    // This function can receive ckUSDC from any user
    // The ckUSDC will be automatically credited to this canister's account
  };

  public shared({ caller = _ }) func depositCkBtc() : async () {
    // This function can receive ckBTC from any user
    // The ckBTC will be automatically credited to this canister's account
  };

  func myAccount() : Ledger.Account {
    { owner = Principal.fromActor(OpticAgent); subaccount = null }
  };

  func myPoolAccount() : Pool.Account {
    { owner = Principal.fromActor(OpticAgent); subaccount = null }
  };

  func getCurrentTime() : Nat64 {
    Nat64.fromNat(Int.abs(Time.now()));
  };


  func calculateTickRange(price : Float, volatility : ?Float) : async (Int, Int) {
    let tickSpacing = 60; // For 0.3% fee tier
    
    let currentTick = await swapCalculator.priceToTick(price, ICP_DECIMALS, CKUSDC_DECIMALS, POOL_FEE);
    
    let baseRange = 600; // ~6% price range
    let dynamicRange = switch (volatility) {
      case (?vol) { 
        let volPrice = price * (1.0 + vol);
        let volTick = await swapCalculator.priceToTick(volPrice, ICP_DECIMALS, CKUSDC_DECIMALS, POOL_FEE);
        Int.abs(volTick - currentTick)
      };
      case (null) { baseRange };
    };
    
    let range = (dynamicRange / tickSpacing) * tickSpacing;
    
    let tickLower = Int.max(-887272, currentTick - range);
    let tickUpper = Int.min(887272, currentTick + range); 
    
    if (tickLower >= tickUpper) {
      (currentTick - 300, currentTick + 300)
    } else {
      (tickLower, tickUpper)
    }
  };

  public shared func getBalances() : async Balances {
    let icpNat = await ledgerCanister.icrc1_balance_of(myAccount());
    let icp = Float.fromInt(icpNat) / 100_000_000.0;
    
    // ckUSDC balance
    let ckUsdcNat = await ckUsdcLedger.icrc1_balance_of(myAccount());
    let ckUsdc = Float.fromInt(ckUsdcNat) / 1_000_000.0; 
    
    // ckBTC balance
    let ckBtcNat = await ckBtcLedger.icrc1_balance_of(myAccount());
    let ckBtc = Float.fromInt(ckBtcNat) / 100_000_000.0;
    
    // Get pool metadata (following ICPSwap documentation workflow)
    let poolMetadataResult = await icpPool.metadata();
    
    let positionIdsResult = await icpPool.getUserPositionIdsByPrincipal(Principal.fromActor(OpticAgent));
    
    var totalPositionValue = 0.0;
    switch (positionIdsResult) {
      case (#ok positionIds) {
        for (positionId in positionIds.vals()) {
          switch (await icpPool.getUserPosition(positionId)) {
            case (?position) {
              // Use SwapCalculator to get actual token amounts (following ICPSwap documentation)
              switch (poolMetadataResult) {
                case (#ok poolMetadata) {
                  switch (await swapCalculator.getTokenAmountByLiquidity(
                    position.liquidity, 
                    position.tickLower, 
                    position.tickUpper, 
                    poolMetadata.tick, 
                    poolMetadata.sqrtPriceX96, 
                    poolMetadata.liquidity
                  )) {
                    case (#ok tokenAmounts) {
                      // Convert token amounts to display values
                      let amount0Display = Float.fromInt(tokenAmounts.amount0) / 100_000_000.0; // ICP decimals
                      let amount1Display = Float.fromInt(tokenAmounts.amount1) / 1_000_000.0;   // ckUSDC decimals
                      
                      // Use ckUSDC value as the position value
                      totalPositionValue += amount0Display * 5; // Approximate ICP value in USD
                      totalPositionValue += amount1Display;
                    };
                    case (#err _) {
                      // If calculation fails, fall back to liquidity value
                      totalPositionValue += Float.fromInt(position.liquidity) / 1e18;
                    };
                  };
                };
                case (#err _) {
                  // If metadata fails, fall back to liquidity value
                  totalPositionValue += Float.fromInt(position.liquidity) / 1e18;
                };
              };
            };
            case (null) {
              // Position not found, skip
            };
          };
        };
      };
      case (#err _) {
        // If getting position IDs fails, return 0 for positions
      };
    };
    
    return { icp; ckUsdc; ckBtc; positions = totalPositionValue };
  };

  public shared func runInvestmentCycle() : async InvestmentEvent {
    let icpNat = await ledgerCanister.icrc1_balance_of(myAccount());
    let half = icpNat / 2;
    
    let poolInfo = await swapFactory.getPoolByTokens(ICP_TOKEN, CKUSDC_TOKEN, POOL_FEE);
    
    switch (poolInfo) {
      case (?info) {
        let minOut = Int.abs(Float.toInt(info.token1Price * Float.fromInt(half) * 0.99));
        
        // Use depositAndSwap for ICRC1 tokens (one-step process)
        let depositAndSwapArgs : Pool.DepositAndSwapArgs = {
          amountIn = Nat.toText(half);
          zeroForOne = false; // ICP to ckUSDC direction
          amountOutMinimum = Nat.toText(minOut);
          tokenInFee = 10000; // ICP fee
          tokenOutFee = 0; // ckUSDC fee
        };
        
        switch (await icpPool.depositAndSwap(depositAndSwapArgs)) {
          case (#ok swapResult) { 
            // Now we have ckUSDC, let's add liquidity
            // First deposit ICP for liquidity
            switch (await icpPool.deposit(ICP_TOKEN, half, 10000)) { // ICP fee is 10000
              case (#ok _) {
                // Then deposit the received ckUSDC for liquidity
                switch (await icpPool.deposit(CKUSDC_TOKEN, swapResult, 0)) { // ckUSDC fee is 0
                  case (#ok _) {
                    let (tickLower, tickUpper) = await calculateTickRange(info.token1Price, null);
                    
                    let mintArgs : Pool.MintArgs = {
                      token0 = ICP_TOKEN;
                      token1 = CKUSDC_TOKEN;
                      fee = POOL_FEE;
                      tickLower = tickLower;
                      tickUpper = tickUpper;
                      amount0Desired = half;
                      amount1Desired = swapResult;
                      amount0Min = half * 99 / 100; // 1% slippage
                      amount1Min = swapResult * 99 / 100; // 1% slippage
                      recipient = myPoolAccount();
                      deadline = getCurrentTime() + 300; // 5 minutes
                    };
                    
                    switch (await icpPool.mint(mintArgs)) {
                      case (#ok mintResult) {
                        let newPosition : Position = {
                          tokenId = mintResult.tokenId;
                          liquidity = mintResult.liquidity;
                          feesEarned0 = 0;
                          feesEarned1 = 0;
                        };
                        positions := Array.append(positions, [newPosition]);
                        
                        return {
                          swappedIcp = Float.fromInt(half) / 100_000_000.0;
                          receivedCkUsdc = Float.fromInt(swapResult) / 1_000_000.0;
                          providedIcp = Float.fromInt(mintResult.amount0) / 100_000_000.0;
                          providedCkUsdc = Float.fromInt(mintResult.amount1) / 1_000_000.0;
                          mintedLp = Float.fromInt(mintResult.liquidity) / 1e18;
                          timestamp = Time.now();
                        };
                      };
                      case (#err e) { 
                        throw Error.reject("Failed to add liquidity: " # debug_show(e));
                      };
                    };
                  };
                  case (#err e) {
                    throw Error.reject("Failed to deposit ckUSDC to pool: " # e);
                  };
                };
              };
              case (#err e) {
                throw Error.reject("Failed to deposit ICP to pool: " # e);
              };
            };
          };
          case (#err e) {
            throw Error.reject("Failed to deposit and swap: " # e);
          };
        };
      };
      case (null) {
        throw Error.reject("Pool not found for ICP/ckUSDC pair");
      };
    };
  };

  public shared func collectFees() : async { amount0 : Nat; amount1 : Nat } {
    var totalAmount0 = 0;
    var totalAmount1 = 0;
    
    let positionIdsResult = await icpPool.getUserPositionIdsByPrincipal(Principal.fromActor(OpticAgent));
    
    switch (positionIdsResult) {
      case (#ok positionIds) {
        for (positionId in positionIds.vals()) {
          let collectArgs : Pool.CollectArgs = {
            tokenId = positionId;
            recipient = myPoolAccount();
            amount0Max = 2_147_483_647; // Max Nat32 value as approximation
            amount1Max = 2_147_483_647; // Max Nat32 value as approximation
          };
          
          switch (await icpPool.collect(collectArgs)) {
            case (#ok result) {
              totalAmount0 += result.amount0;
              totalAmount1 += result.amount1;
            };
            case (#err _) {
              // Continue with other positions even if one fails
            };
          };
        };
      };
      case (#err _) {
        // If getting position IDs fails, return 0
      };
    };
    
    { amount0 = totalAmount0; amount1 = totalAmount1 }
  };

  public shared func getPositions() : async [Position] {
    positions
  };

  public shared func getAllPoolPositions() : async [Pool.Position] {
    let positionIdsResult = await icpPool.getUserPositionIdsByPrincipal(Principal.fromActor(OpticAgent));
    
    var allPositions : [Pool.Position] = [];
    switch (positionIdsResult) {
      case (#ok positionIds) {
        for (positionId in positionIds.vals()) {
          switch (await icpPool.getUserPosition(positionId)) {
            case (?position) {
              allPositions := Array.append(allPositions, [position]);
            };
            case (null) {
              // Position not found, skip
            };
          };
        };
      };
      case (#err _) {
        // If getting position IDs fails, return empty array
      };
    };
    
    allPositions
  };

  public shared func getUnusedBalances() : async { amount0 : Nat; amount1 : Nat } {
    await icpPool.getUserUnusedBalance(Principal.fromActor(OpticAgent))
  };

  public shared func testMetadata() : async Pool.MetadataResult {
    await icpPool.metadata()
  };

  public shared func testMetadataRaw() : async Text {
    // This will help us see what the actual response structure is
    try {
      let result = await icpPool.metadata();
      "Success: metadata call completed"
    } catch (error) {
      "Error: metadata call failed"
    }
  };

  public shared func getDetailedBalances() : async { 
    icp : { amount : Nat; display : Float }; 
    ckUsdc : { amount : Nat; display : Float }; 
    ckBtc : { amount : Nat; display : Float }; 
    positions : Float 
  } {
    let icpNat = await ledgerCanister.icrc1_balance_of(myAccount());
    let ckUsdcNat = await ckUsdcLedger.icrc1_balance_of(myAccount());
    
    let icp = { 
      amount = icpNat; 
      display = Float.fromInt(icpNat) / 100_000_000.0 
    };
    let ckUsdc = { 
      amount = ckUsdcNat; 
      display = Float.fromInt(ckUsdcNat) / 1_000_000.0 
    };
    
    // ckBTC balance
    let ckBtcNat = await ckBtcLedger.icrc1_balance_of(myAccount());
    let ckBtc = { 
      amount = ckBtcNat; 
      display = Float.fromInt(ckBtcNat) / 100_000_000.0 
    };
    
    // Get pool metadata (following ICPSwap documentation workflow)
    let poolMetadataResult = await icpPool.metadata();
    
    let positionIdsResult = await icpPool.getUserPositionIdsByPrincipal(Principal.fromActor(OpticAgent));
    
    var totalPositionValue = 0.0;
    switch (positionIdsResult) {
      case (#ok positionIds) {
        for (positionId in positionIds.vals()) {
          switch (await icpPool.getUserPosition(positionId)) {
            case (?position) {
              // Use SwapCalculator to get actual token amounts (following ICPSwap documentation)
              switch (poolMetadataResult) {
                case (#ok poolMetadata) {
                  switch (await swapCalculator.getTokenAmountByLiquidity(
                    position.liquidity, 
                    position.tickLower, 
                    position.tickUpper, 
                    poolMetadata.tick, 
                    poolMetadata.sqrtPriceX96, 
                    poolMetadata.liquidity
                  )) {
                    case (#ok tokenAmounts) {
                      // Convert token amounts to display values
                      let amount0Display = Float.fromInt(tokenAmounts.amount0) / 100_000_000.0; // ICP decimals
                      let amount1Display = Float.fromInt(tokenAmounts.amount1) / 1_000_000.0;   // ckUSDC decimals
                      
                      // Use ckUSDC value as the position value
                      totalPositionValue += amount0Display * 5; // Approximate ICP value in USD
                      totalPositionValue += amount1Display;
                    };
                    case (#err _) {
                      // If calculation fails, fall back to liquidity value
                      totalPositionValue += Float.fromInt(position.liquidity) / 1e18;
                    };
                  };
                };
                case (#err _) {
                  // If metadata fails, fall back to liquidity value
                  totalPositionValue += Float.fromInt(position.liquidity) / 1e18;
                };
              };
            };
            case (null) {
              // Position not found, skip
            };
          };
        };
      };
      case (#err _) {
        // If getting position IDs fails, return 0
      };
    };
    
    { icp; ckUsdc; ckBtc; positions = totalPositionValue }
  };


  public shared func init() : async () {
    
  };

  system func heartbeat() : async () {
    // This can be called periodically to run investment cycles
    ignore await runInvestmentCycle();
  };
};