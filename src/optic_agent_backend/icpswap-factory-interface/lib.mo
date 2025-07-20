module {
  public type Account = {
    owner : Principal;
    subaccount : ?[Nat8];
  };

  public type PoolInfo = {
    poolId : Text;
    token0 : Text;
    token1 : Text;
    fee : Nat;
    tickSpacing : Int;
    liquidity : Nat;
    sqrtPriceX96 : Nat;
    tick : Int;
    token0Price : Float;
    token1Price : Float;
    volumeUSD : Float;
    volumeToken0 : Float;
    volumeToken1 : Float;
    feesUSD : Float;
    feesToken0 : Float;
    feesToken1 : Float;
    tvlUSD : Float;
    tvlToken0 : Float;
    tvlToken1 : Float;
  };

  public type Pool = {
    poolId : Text;
    pool : Principal;
  };

  public type Self = actor {
    getPools : shared query () -> async [Pool];
    getPool : shared query (Text) -> async ?PoolInfo;
    getPoolByTokens : shared query (Text, Text, Nat) -> async ?PoolInfo;
  };
}; 