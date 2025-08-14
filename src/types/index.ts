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