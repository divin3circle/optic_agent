module {
  public type Self = actor {
    priceToTick : shared query (Float, Float, Float, Nat) -> async Int;
    getPrice : shared query (Nat, Nat, Nat) -> async Float;
    getSqrtRatioAtTick : shared query (Int) -> async { #Ok : Nat; #Err : Text };
    getPositionTokenAmount : shared query (Nat, Int, Int, Int, Nat, Nat) -> async { #Ok : { amount0 : Nat; amount1 : Nat }; #Err : Text };
    getTokenAmountByLiquidity : shared query (Nat, Int, Int, Int, Nat, Nat) -> async { #Ok : { amount0 : Nat; amount1 : Nat }; #Err : Text };
    getSqrtPriceX96 : shared query (Float, Float, Float) -> async Int;
    sortToken : shared query (Text, Text) -> async (Text, Text);
  };
}; 