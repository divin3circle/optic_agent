import { IDL } from 'azle';


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