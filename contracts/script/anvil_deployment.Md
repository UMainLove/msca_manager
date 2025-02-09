## FORGE DEPLOYMENT:
```shell
forge script DeployMessaging.s.sol     --rpc-url http://127.0.0.1:8545     --broadcast
[⠊] Compiling...
[⠰] Compiling 1 files with Solc 0.8.22
[⠔] Solc 0.8.22 finished in 6.57s
Compiler run successful!
Script ran successfully.

== Logs ==
  Deploying MessagingPlugin...
  MessagingPlugin deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3

## Setting up 1 EVM.

==========================

Chain 31337

Estimated gas price: 2.000000001 gwei

Estimated total gas used for script: 2383756

Estimated amount required: 0.004767512002383756 ETH

==========================

##### anvil-hardhat
✅  [Success] Hash: 0x2408bc67f8975b4b155454a5ae892e4993688d99a934d437abb6f0941c205b6c
Contract Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Block: 1
Paid: 0.001833659001833659 ETH (1833659 gas * 1.000000001 gwei)

✅ Sequence #1 on anvil-hardhat | Total Paid: 0.001833659001833659 ETH (1833659 gas * avg 1.000000001 gwei)
                                                                                     

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /PATH/TO/PROJECT/account-kit-app/contracts/broadcast/DeployMessaging.s.sol/31337/run-latest.json

Sensitive values saved to: /PATH/TO/PROJECT/account-kit-app/contracts/cache/DeployMessaging.s.sol/31337/run-latest.json


```


## ANVIL CONSOLE:
```shell
eth_getTransactionCount
eth_getBalance
eth_getCode
.
.
.
eth_feeHistory
eth_sendRawTransaction
eth_getTransactionReceipt
eth_getTransactionReceipt

    Transaction: 0x2408bc67f8975b4b155454a5ae892e4993688d99a934d437abb6f0941c205b6c
    Contract created: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    Gas used: 1833659

    Block Number: 1
    Block Hash: 0x7bbda41d40c092b6f20624d6140d57d88fddd656805e4e9863b5480d33af45c6
    Block Time: "Sun, 5 Jan 2025 23:00:02 +0000"

eth_blockNumber
eth_getBlockByNumber
eth_getTransactionReceipt
.
.
.
```