import { LedgerCanister, AccountIdentifier } from '@dfinity/ledger-icp';
import { call, canisterSelf, IDL, Principal, query, update } from 'azle';
import  { LOCAL_CKUSDC_CANISTER_ID, ICP_LEDGER_CANISTER_ID } from './utils/agent';

const ReturnICPBalance = IDL.Record({
    e8s: IDL.Nat64,
})

const ParamAccountIdentifier = IDL.Record({
    account: IDL.Vec(IDL.Nat8),
})

const ParamIcrc1BalanceOf = IDL.Record({
    owner: IDL.Principal,
})

const OpticAccount = IDL.Record({
    icpBalance: IDL.Nat64,
    ckUSDCBalance: IDL.Nat64,
})

type OpticAccount = {
    icpBalance: bigint;
    ckUSDCBalance: bigint;
}

export default class {
    @update([], IDL.Opt(OpticAccount))
    async getBalance(): Promise<[OpticAccount] | []>  {
       try {
        const icpBalance = await fetchMyICPBalance();
        const ckUSDCBalance = await fetchMyckUSDCBalance();
        const account = {
            icpBalance, 
            ckUSDCBalance
        }
        return [account];
       } catch (error) {
        console.error(error);
        throw error;
       }
    }

    @query([], IDL.Text)
    getSelfAccountIdentifier(): string {
        const myAccountIdentifier = AccountIdentifier.fromPrincipal({
            principal: canisterSelf(),
        });
        return myAccountIdentifier.toHex();
    }

    @query([], IDL.Text)
    getSelfPrincipal(): string {
        return canisterSelf().toString();
    }
}

async function fetchMyICPBalance(): Promise<bigint> {
    const myAccountIdentifier = AccountIdentifier.fromPrincipal({
        principal: canisterSelf(),
    });
    
    const accountData = {
        account: myAccountIdentifier.toUint8Array()
    };
    // account_balance: (record {account:vec nat8}) → (record {e8s:nat64}) query
   const result = await call(ICP_LEDGER_CANISTER_ID, 'account_balance', {
    args: [accountData],
    paramIdlTypes: [ParamAccountIdentifier],
    returnIdlType: ReturnICPBalance
   })

   return result.e8s;
}  

async function fetchMyckUSDCBalance(): Promise<bigint> {
    //icrc1_balance_of: (record {owner:principal; subaccount:opt vec nat8}) → (nat) query 
    const myPrincipal = canisterSelf();
    const accountData = {
        owner: myPrincipal,
    }
    const result = await call(LOCAL_CKUSDC_CANISTER_ID, 'icrc1_balance_of', {
        args: [accountData],
        paramIdlTypes: [ParamIcrc1BalanceOf],
        returnIdlType: IDL.Nat
    })
    return result;
}
