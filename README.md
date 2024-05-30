# be-contracts

SOUL solidity contracts backend repository

## avalanche fuji deployment

| Contract | Address | Chainlink Subscription ID |
|-|-|-|
| AnalyticsAPICaller | 0x7854F35413AF8e42b1633eB4244CD7d0528663E5 | [2639](https://functions.chain.link/sepolia/2639) |


forge script script/DeployLottery.s.sol:DeployLottery --chain-id $CHAIN_ID --rpc-url $RPC_URL \
    --etherscan-api-key $VERIFY_API_KEY --verifier-url $VERIFY_URL \
    --broadcast --verify -vvvv