import { IDL, Principal } from 'azle';


export const ReturnICPBalance = IDL.Record({
    e8s: IDL.Nat64,
})


export const ParamAccountIdentifier = IDL.Record({
    account: IDL.Vec(IDL.Nat8),
})


export const ParamIcrc1BalanceOf = IDL.Record({
    owner: IDL.Principal,
})


export const OpticAccount = IDL.Record({
    icpBalance: IDL.Nat64,
    ckUSDCBalance: IDL.Nat64,
})

export type OpticAccount = {
    icpBalance: bigint;
    ckUSDCBalance: bigint;
}

export const Withdrawals = IDL.Record({
    amount0: IDL.Nat64,
    amount1: IDL.Nat64,
    to: IDL.Principal,
    timestamp: IDL.Nat64,
})

export type Withdrawals = {
    amount0: bigint;
    amount1: bigint;
    to: Principal;
    timestamp: bigint;
}

export const CollectedFees = IDL.Record({
    amount0: IDL.Nat64,
    amount1: IDL.Nat64,
    timestamp: IDL.Nat64,
})

export type CollectedFees = {
    amount0: bigint;
    amount1: bigint;
    timestamp: bigint;
}

export const SwapAction = IDL.Record({
    amount0: IDL.Nat64,
    amount1: IDL.Nat64,
    timestamp: IDL.Nat64,
    fee: IDL.Nat64,
    txHash: IDL.Text,
})

export type SwapAction = {
    amount0: bigint;
    amount1: bigint;
    timestamp: bigint;
    fee: bigint;
    txHash: string;
}

export const LiquidityAction = IDL.Record({
    amount0: IDL.Nat64,
    amount1: IDL.Nat64,
    timestamp: IDL.Nat64,
    positionId: IDL.Nat64,
    poolId: IDL.Text,
})

export type LiquidityAction = {
    amount0: bigint;
    amount1: bigint;
    timestamp: bigint;
    positionId: bigint;
    poolId: string;
}