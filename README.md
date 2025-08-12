# Optic Agent 

A Typescript Agent for the Optic Platform.

## Workflow

It's assumed, at least for now that only ckUSDC tokens are sent to these canister. After receiving enough ckUSDC based on the set thresh-hold, the agent will run two operations. A swap action to swap half of the available ckUSDC value to either ICP or ckBTC, followed by a add liquidity action to provide liquidity to the relevant pool. These actions are provided by ICPSwap [here](https://github.com/ICPSwap-Labs/docs).

All swap, add liquidity actions are recorded into the canister's satble memory for auditing and performance analysis. This is true also for all the error messages encountered during swap or add liquidity actions.

This canister also provides a function to check the available fees earned by the pool on it's investment on the said pool. 

## Functions

✅`getBalance` returns the ckUSDC and ICP balances of the canister in decimals
🔂`swap` swaps portion of treasury ckUSDC to ICP
🔂`balance` gets the amount of ckUSDC to swap to ICP to get a balanced USD value ratio
🔂`getICPUSDValue` gets current ICP value in USD
🔂`addLiquidity` adds liquidity to the ICP/ckUSDC pool
🔂`get


## Local SetUp

1. ICP Ledger & NNS Local Setup

Follow the guide [here](https://internetcomputer.org/docs/defi/token-ledgers/setup/icp_ledger_setup) to set up nns(plus the ICP ledger) locally. 

2. ckUSDC Setup

Follow the guide [here](https://internetcomputer.org/docs/defi/token-ledgers/setup/icrc1_ledger_setup) to setup the ckUSDC ledger locally. 
Alternatively clone, and deploy [this](https://github.com/divin3circle/local_ckUSDC_ledger) ready configured demo ckUSDC canister. 
`NOTE: Remember to edit the init_args in the dfx.json file`

