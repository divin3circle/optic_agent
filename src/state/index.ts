import { StableBTreeMap } from "azle";

import { CollectedFees, Withdrawals } from "../types";

export const withdrawals = new StableBTreeMap<string, Withdrawals>(0)

export const collectedFees = new StableBTreeMap<string, CollectedFees>(0)