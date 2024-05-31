# be-contracts

SOUL solidity contracts backend repository

## avalanche fuji deployment

| Contract | Address | Chainlink Subscription ID |
|-|-|-|
| AnalyticsAPICaller | 0x7854F35413AF8e42b1633eB4244CD7d0528663E5 | [2639](https://functions.chain.link/sepolia/2639) |
Lottery  | 0x31bCbbf289a3461eb822CCacA529C0971f00fAE7  | [2819](https://vrf.chain.link/fuji/2819) |
HelperConfig |0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141 | [2819](https://vrf.chain.link/fuji/2819) |
Staking | 0x84AF19eb54957E6D1113d5A12B7c30A52aE338a8    |   |
PoolToken   | 0x00e19877758b5E00712EACC02D0f92C532a6C453    |   |

forge script script/DeployLottery.s.sol:DeployLottery --chain-id $CHAIN_ID --rpc-url $RPC_URL \
    --etherscan-api-key $VERIFY_API_KEY --verifier-url $VERIFY_URL \
    --broadcast --verify -vvvv