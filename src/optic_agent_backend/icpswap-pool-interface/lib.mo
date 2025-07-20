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
    #Ok : { amountIn : Nat; amountOut : Nat };
    #Err : SwapError;
  };

  public type SwapError = {
    #InsufficientLiquidity;
    #InsufficientFunds;
    #SlippageExceeded;
    #InvalidAmount;
    #InvalidToken;
    #InvalidFee;
    #DeadlineExceeded;
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
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
    #Ok : { tokenId : Nat; liquidity : Nat; amount0 : Nat; amount1 : Nat };
    #Err : MintError;
  };

  public type MintError = {
    #InsufficientFunds;
    #InvalidRatio;
    #SlippageExceeded;
    #InvalidTickRange;
    #InvalidToken;
    #InvalidFee;
    #DeadlineExceeded;
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };

  public type CollectArgs = {
    tokenId : Nat;
    recipient : Account;
    amount0Max : Nat;
    amount1Max : Nat;
  };

  public type CollectResult = {
    #Ok : { amount0 : Nat; amount1 : Nat };
    #Err : CollectError;
  };

  public type CollectError = {
    #TokenNotFound;
    #InsufficientFunds;
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
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

    public type Self = actor {
    swap : shared SwapArgs -> async SwapResult;
    mint : shared MintArgs -> async MintResult;
    collect : shared CollectArgs -> async CollectResult;
    deposit : shared (Text, Nat, Nat) -> async { #Ok : Nat; #Err : Text };
    depositAndSwap : shared DepositAndSwapArgs -> async { #Ok : Nat; #Err : Text };
    getUserPositionIdsByPrincipal : shared query Account -> async [Nat];
    getUserPosition : shared query Nat -> async ?Position;
    getUserUnusedBalance : shared query Account -> async { amount0 : Nat; amount1 : Nat };
    metadata : shared query () -> async { sqrtPriceX96 : Nat; tick : Int; liquidity : Nat };
  };
}; 