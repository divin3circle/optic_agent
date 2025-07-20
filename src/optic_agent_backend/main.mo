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

  // Local testing mode flag
  let isLocalTesting = false;

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
    if (isLocalTesting) {
      // Return mock data for local testing
      return { 
        icp = 10.5; 
        ckUsdc = 150.25; 
        ckBtc = 0.001; 
        positions = 1000.0 
      };
    };

    let icpNat = await ledgerCanister.icrc1_balance_of(myAccount());
    let icp = Float.fromInt(icpNat) / 100_000_000.0;
    
    // ckUSDC balance
    let ckUsdcNat = await ckUsdcLedger.icrc1_balance_of(myAccount());
    let ckUsdc = Float.fromInt(ckUsdcNat) / 1_000_000.0; 
    
    // ckBTC balance
    let ckBtcNat = await ckBtcLedger.icrc1_balance_of(myAccount());
    let ckBtc = Float.fromInt(ckBtcNat) / 100_000_000.0;
    
    let positionIds = await icpPool.getUserPositionIdsByPrincipal(myAccount());
    
    var totalLiquidity = 0.0;
    for (positionId in positionIds.vals()) {
      switch (await icpPool.getUserPosition(positionId)) {
        case (?position) {
          totalLiquidity += Float.fromInt(position.liquidity);
        };
        case (null) {
          // Position not found, skip
        };
      };
    };
    
    return { icp; ckUsdc; ckBtc; positions = totalLiquidity };
  };

  public shared func runInvestmentCycle() : async InvestmentEvent {
    if (isLocalTesting) {
      // Return mock investment event for local testing
      return {
        swappedIcp = 5.0;
        receivedCkUsdc = 75.0;
        providedIcp = 5.0;
        providedCkUsdc = 75.0;
        mintedLp = 500.0;
        timestamp = Time.now();
      };
    };

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
          case (#Ok swapResult) { 
            // Now we have ckUSDC, let's add liquidity
            // First deposit ICP for liquidity
            switch (await icpPool.deposit(ICP_TOKEN, half, 10000)) { // ICP fee is 10000
              case (#Ok _) {
                // Then deposit the received ckUSDC for liquidity
                switch (await icpPool.deposit(CKUSDC_TOKEN, swapResult, 0)) { // ckUSDC fee is 0
                  case (#Ok _) {
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
                      recipient = myAccount();
                      deadline = getCurrentTime() + 300; // 5 minutes
                    };
                    
                    switch (await icpPool.mint(mintArgs)) {
                      case (#Ok mintResult) {
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
                      case (#Err e) { 
                        throw Error.reject("Failed to add liquidity: " # debug_show(e));
                      };
                    };
                  };
                  case (#Err e) {
                    throw Error.reject("Failed to deposit ckUSDC to pool: " # e);
                  };
                };
              };
              case (#Err e) {
                throw Error.reject("Failed to deposit ICP to pool: " # e);
              };
            };
          };
          case (#Err e) {
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
    
    let positionIds = await icpPool.getUserPositionIdsByPrincipal(myAccount());
    
    for (positionId in positionIds.vals()) {
      let collectArgs : Pool.CollectArgs = {
        tokenId = positionId;
        recipient = myAccount();
        amount0Max = 2_147_483_647; // Max Nat32 value as approximation
        amount1Max = 2_147_483_647; // Max Nat32 value as approximation
      };
      
      switch (await icpPool.collect(collectArgs)) {
        case (#Ok result) {
          totalAmount0 += result.amount0;
          totalAmount1 += result.amount1;
        };
        case (#Err _) {
          // Continue with other positions even if one fails
        };
      };
    };
    
    { amount0 = totalAmount0; amount1 = totalAmount1 }
  };

  public shared func getPositions() : async [Position] {
    positions
  };

  public shared func getAllPoolPositions() : async [Pool.Position] {
    let positionIds = await icpPool.getUserPositionIdsByPrincipal(myAccount());
    
    var allPositions : [Pool.Position] = [];
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
    
    allPositions
  };

  public shared func getUnusedBalances() : async { amount0 : Nat; amount1 : Nat } {
    await icpPool.getUserUnusedBalance(myAccount())
  };

  public shared func getDetailedBalances() : async { 
    icp : { amount : Nat; display : Float }; 
    ckUsdc : { amount : Nat; display : Float }; 
    ckBtc : { amount : Nat; display : Float }; 
    positions : Float 
  } {
    if (isLocalTesting) {
      // Return mock data for local testing
      return {
        icp = { amount = 1_050_000_000; display = 10.5 }; // 10.5 ICP
        ckUsdc = { amount = 150_250_000; display = 150.25 }; // 150.25 USDC
        ckBtc = { amount = 100_000; display = 0.001 }; // 0.001 BTC
        positions = 1000.0
      };
    };

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
    
    let positionIds = await icpPool.getUserPositionIdsByPrincipal(myAccount());
    
    var totalLiquidity = 0.0;
    for (positionId in positionIds.vals()) {
      switch (await icpPool.getUserPosition(positionId)) {
        case (?position) {
          totalLiquidity += Float.fromInt(position.liquidity);
        };
        case (null) {
          // Position not found, skip
        };
      };
    };
    
    { icp; ckUsdc; ckBtc; positions = totalLiquidity }
  };

  // func calculateOptimalLiquidity(amount0 : Nat, amount1 : Nat, tickLower : Int, tickUpper : Int) : async { amount0 : Nat; amount1 : Nat } {
  //   let liquidity = 1000000;
  //   switch (await swapCalculator.getPositionTokenAmount(liquidity, tickLower, tickUpper, 0, amount0, amount1)) {
  //     case (#Ok result) {
  //       { amount0 = result.amount0; amount1 = result.amount1 }
  //     };
  //     case (#Err _) {
  //       { amount0 = amount0 / 2; amount1 = amount1 / 2 }
  //     };
  //   }
  // };

  public shared func init() : async () {
    
  };

  system func heartbeat() : async () {
    // This can be called periodically to run investment cycles
    ignore await runInvestmentCycle();
  };
};