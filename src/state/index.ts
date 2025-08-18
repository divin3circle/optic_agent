import { StableBTreeMap } from "azle";

import { CollectedFees, Withdrawals, SwapAction, LiquidityAction } from "../types";

export const withdrawals = new StableBTreeMap<string, Withdrawals>(0)

export const collectedFees = new StableBTreeMap<string, CollectedFees>(0)

export const swapActions = new StableBTreeMap<string, SwapAction>(0)

export const liquidityActions = new StableBTreeMap<string, LiquidityAction>(0)