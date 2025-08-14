import { Principal } from "azle"

/**
 * MAINNET LEDGER CANISTER ID
 */
export const CKUSDC_LEDGER_CANISTER_ID = "xevnm-gaaaa-aaaar-qafnq-cai"
export const ICP_LEDGER_CANISTER_ID = "ryjl3-tyaaa-aaaaa-aaaba-cai"

/**
 * LOCAL CKUSDC CANISTER ID
 */
export const LOCAL_CKUSDC_CANISTER_ID = "u6s2n-gx777-77774-qaaba-cai"

/**
 * POOLS CANISTER ID
 */
export const ICP_CKUSDC_POOL_CANISTER_ID = "mohjv-bqaaa-aaaag-qjyia-cai"

/**
 * FUNCTIONS
 */
export function generateWithdrawalId(amount0: bigint, amount1: bigint, to: Principal): string {
    return `${amount0}-${amount1}-${to.toString()}`
}

