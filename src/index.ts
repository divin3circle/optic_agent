import { AccountIdentifier } from '@dfinity/ledger-icp';
import { call, canisterSelf, canisterCycleBalance, IDL, query, update } from 'azle';
import { LOCAL_CKUSDC_CANISTER_ID, ICP_LEDGER_CANISTER_ID, CKUSDC_LEDGER_CANISTER_ID, ICP_CKUSDC_POOL_CANISTER_ID } from './utils/agent';
import { OpticAccount, ParamAccountIdentifier, ReturnICPBalance, ParamIcrc1BalanceOf, SwapAction, LiquidityAction } from './types';
import { PoolMetadata } from './interfaces/icp_ckusdc_pool';
import { liquidityActions, swapActions } from './state';

const devMode = false;


export default class {
  thresholdCkUSDCBalance: bigint = 100_000_000n;

  async getEstimatedTimeToThreshold(): Promise<number> {
   const averageContributionPerDay = await this.getAverageContributionPerDayLast10Days();
   const daysToThreshold = this.thresholdCkUSDCBalance / averageContributionPerDay;
   return Number(daysToThreshold);
  }

  async getAverageContributionPerDayLast10Days(): Promise<bigint> {
    const ckUSDCBalance = await fetchMyckUSDCBalance();
    const averageContributionPerDay = ckUSDCBalance / 10n;
    return averageContributionPerDay;
  }

  @query([], IDL.Nat)
  getCycleBalance(): bigint {
    return canisterCycleBalance();
  }

  @update([], IDL.Record({
    thresholdCkUSDCBalance: IDL.Nat,
    estimatedTimeToThreshold: IDL.Nat
  }))
  async getThresholdAndEstimatedTimeToThreshold(): Promise<{
    thresholdCkUSDCBalance: bigint,
    estimatedTimeToThreshold: number
  }> {
    return {
      thresholdCkUSDCBalance: this.thresholdCkUSDCBalance,
      estimatedTimeToThreshold: await this.getEstimatedTimeToThreshold()
    }
  }

  @query([], IDL.Vec(LiquidityAction))
  getLiquidityActions(): LiquidityAction[] {
    return Array.from(liquidityActions.values() || []);
  }


  @query([], IDL.Vec(SwapAction))
  getSwapActions(): SwapAction[] {
    return Array.from(swapActions.values() || []);
  }

  @update([], IDL.Opt(OpticAccount))
  async getBalance(): Promise<[OpticAccount] | []> {
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

  @update([], IDL.Opt(IDL.Record({
    fee: IDL.Nat,
    key: IDL.Text,
    sqrtPriceX96: IDL.Nat,
    tick: IDL.Int,
    liquidity: IDL.Nat,
    token0: IDL.Record({
      address: IDL.Text,
      standard: IDL.Text
    }),
    token1: IDL.Record({
      address: IDL.Text,
      standard: IDL.Text
    }),
    maxLiquidityPerTick: IDL.Nat,
    nextPositionId: IDL.Nat
  })))
  async getICPCKUSDCPoolMetadata(): Promise<[PoolMetadata] | []> {
    try {
      const metadata = await fetchPoolMetadata();
      console.log(metadata);
      return [metadata];
    } catch (error) {
      console.error('Error fetching pool metadata:', error);
      return [];
    }
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
  if(devMode){
    return 10_000_000n;
  }
  const myPrincipal = canisterSelf();
  const accountData = {
    owner: myPrincipal,
  }
  const result = await call(CKUSDC_LEDGER_CANISTER_ID, 'icrc1_balance_of', {
    args: [accountData],
    paramIdlTypes: [ParamIcrc1BalanceOf],
    returnIdlType: IDL.Nat
  })
  return result;
}


export async function fetchPoolMetadata(): Promise<PoolMetadata> {
  if(devMode){
    return {
      fee: 1000000000000000000n,
      key: 'test',
      sqrtPriceX96: 1000000000000000000n,
      tick: 0n,
      liquidity: 1000000000000000000n,
      token0: {
        address: 'test',
        standard: 'test'
      },
      token1: {
        address: 'test',
        standard: 'test'
      },
      maxLiquidityPerTick: 1000000000000000000n,
      nextPositionId: 0n,
    }
  }
  const result = await call(ICP_CKUSDC_POOL_CANISTER_ID, 'metadata', {
    args: [],
    paramIdlTypes: [],
    returnIdlType: IDL.Variant({
      ok: IDL.Record({
        fee: IDL.Nat,
        key: IDL.Text,
        sqrtPriceX96: IDL.Nat,
        tick: IDL.Int,
        liquidity: IDL.Nat,
        token0: IDL.Record({
          address: IDL.Text,
          standard: IDL.Text
        }),
        token1: IDL.Record({
          address: IDL.Text,
          standard: IDL.Text
        }),
        maxLiquidityPerTick: IDL.Nat,
        nextPositionId: IDL.Nat
      }),
      err: IDL.Variant({
        CommonError: IDL.Null,
        InternalError: IDL.Text,
        UnsupportedToken: IDL.Text,
        InsufficientFunds: IDL.Null
      })
    })
  });

  if ('ok' in result) {
    console.log(result.ok);
    return result.ok;
  } else {
    throw new Error(`Failed to fetch metadata: ${JSON.stringify(result.err)}`);
  }
}
