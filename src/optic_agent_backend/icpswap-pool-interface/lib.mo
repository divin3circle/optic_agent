module {
  public type Account = {
    owner : Principal;
    subaccount : ?[Nat8];
  };

  public type SwapArgs = {
    tokenIn : Text;
    tokenOut : Text;
    fee : Nat;
    recipient : Account;
    deadline : Nat64;
    amountIn : Nat;
    amountOutMinimum : Nat;
    sqrtPriceLimitX96 : ?Nat;
  };

  public type DepositAndSwapArgs = {
    amountIn : Text;
    zeroForOne : Bool;
    amountOutMinimum : Text;
    tokenInFee : Nat;
    tokenOutFee : Nat;
  };

  public type SwapResult = {
    #ok : { amountIn : Nat; amountOut : Nat };
    #err : SwapError;
  };

  public type SwapError = {
    #insufficientLiquidity;
    #insufficientFunds;
    #slippageExceeded;
    #invalidAmount;
    #invalidToken;
    #invalidFee;
    #deadlineExceeded;
    #temporarilyUnavailable;
    #genericError : { error_code : Nat; message : Text };
  };

  public type MintArgs = {
    token0 : Text;
    token1 : Text;
    fee : Nat;
    tickLower : Int;
    tickUpper : Int;
    amount0Desired : Nat;
    amount1Desired : Nat;
    amount0Min : Nat;
    amount1Min : Nat;
    recipient : Account;
    deadline : Nat64;
  };

  public type MintResult = {
    #ok : { tokenId : Nat; liquidity : Nat; amount0 : Nat; amount1 : Nat };
    #err : MintError;
  };

  public type MintError = {
    #insufficientFunds;
    #invalidRatio;
    #slippageExceeded;
    #invalidTickRange;
    #invalidToken;
    #invalidFee;
    #deadlineExceeded;
    #temporarilyUnavailable;
    #genericError : { error_code : Nat; message : Text };
  };

  public type CollectArgs = {
    tokenId : Nat;
    recipient : Account;
    amount0Max : Nat;
    amount1Max : Nat;
  };

  public type CollectResult = {
    #ok : { amount0 : Nat; amount1 : Nat };
    #err : CollectError;
  };

  public type CollectError = {
    #tokenNotFound;
    #insufficientFunds;
    #temporarilyUnavailable;
    #genericError : { error_code : Nat; message : Text };
  };



  public type Position = {
    tokenId : Nat;
    liquidity : Nat;
    feeGrowthInside0LastX128 : Nat;
    feeGrowthInside1LastX128 : Nat;
    tokensOwed0 : Nat;
    tokensOwed1 : Nat;
    tickLower : Int;
    tickUpper : Int;
  };

  public type Token = {
    address : Text;
    standard : Text;
  };

  public type PoolMetadata = {
    fee : Nat;
    key : Text;
    liquidity : Nat;
    maxLiquidityPerTick : Nat;
    nextPositionId : Nat;
    sqrtPriceX96 : Nat;
    tick : Int;
    token0 : Token;
    token1 : Token;
  };

  public type Error = {
    #commonError;
    #insufficientFunds;
    #internalError : Text;
    #unsupportedToken : Text;
  };

  public type MetadataResult = {
    #ok : PoolMetadata;
    #err : Error;
  };

  public type PositionIdsResult = {
    #ok : [Nat];
    #err : Error;
  };

    public type Self = actor {
    swap : shared SwapArgs -> async SwapResult;
    mint : shared MintArgs -> async MintResult;
    collect : shared CollectArgs -> async CollectResult;
    deposit : shared (Text, Nat, Nat) -> async { #ok : Nat; #err : Text };
    depositAndSwap : shared DepositAndSwapArgs -> async { #ok : Nat; #err : Text };
    getUserPositionIdsByPrincipal : shared query Principal -> async PositionIdsResult;
    getUserPosition : shared query Nat -> async ?Position;
    getUserUnusedBalance : shared query Principal -> async { amount0 : Nat; amount1 : Nat };
    metadata : shared query () -> async MetadataResult;
  };
}; 