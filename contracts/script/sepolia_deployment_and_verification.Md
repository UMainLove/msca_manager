## ETHEREUM SEPOLIA DEPLOYMENT:
```shell
forge script script/DeployMessaging.s.sol --rpc-url NEXT_PUBLIC_ALCHEMY_API_URL --broadcast --verify --etherscan-api-key "NEXT_PUBLIC_ETHERSCAN_API_KEY" -vvvv
[⠊] Compiling...
[⠒] Compiling 1 files with Solc 0.8.22
[⠑] Solc 0.8.22 finished in 6.79s
Compiler run successful!
Traces:
  [1730112] DeployMessaging::run()
    ├─ [0] console::log("******** Deploying MessagingPlugin *********") [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::envUint("PRIVATE_KEY") [staticcall]
    │   └─ ← [Return] <env var value>
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] 0x96c3099a64603291a37940559d9641C05583efB4
    ├─ [0] console::log("******** Deploying MessagingPlugin *********") [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] console::log("Deployer address:", 0x96c3099a64603291a37940559d9641C05583efB4) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::startBroadcast(<pk>)
    │   └─ ← [Return] 
    ├─ [1684464] Create2Deployer::create2()
    │   ├─ [1648611] → new MessagingPlugin@0x79050486765BE9573fDb341b0686576d32d73A9b
    │   │   └─ ← [Return] 8234 bytes of code
    │   └─ ← [Return] 0x79050486765be9573fdb341b0686576d32d73a9b
    ├─ [0] console::log("MessagingPlugin deployed at:", MessagingPlugin: [0x79050486765BE9573fDb341b0686576d32d73A9b]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::stopBroadcast()
    │   └─ ← [Return] 
    └─ ← [Return] 


Script ran successfully.

== Logs ==
  ******** Deploying MessagingPlugin *********
  ******** Deploying MessagingPlugin *********
  Deployer address: 0x96c3099a64603291a37940559d9641C05583efB4
  MessagingPlugin deployed at: 0x79050486765BE9573fDb341b0686576d32d73A9b

## Setting up 1 EVM.
==========================
Simulated On-chain Traces:

  [1684464] Create2Deployer::create2()
    ├─ [1648611] → new MessagingPlugin@0x79050486765BE9573fDb341b0686576d32d73A9b
    │   └─ ← [Return] 8234 bytes of code
    └─ ← [Return] 0x79050486765be9573fdb341b0686576d32d73a9b


==========================

Chain 11155111

Estimated gas price: 5.836937468 gwei

Estimated total gas used for script: 2537588

Estimated amount required: 0.014811742475547184 ETH

==========================

##### sepolia
✅  [Success] Hash: 0x305fc641b0d02c4ff6e93669454acd7afaae96a3b0ffb3012fee9da46af053ba
Block: 7430048
Paid: 0.006203976253777168 ETH (1837168 gas * 3.376923751 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.006203976253777168 ETH (1837168 gas * avg 3.376923751 gwei)
                                                                                     

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (1) contracts
Start verifying contract `0x79050486765BE9573fDb341b0686576d32d73A9b` deployed on sepolia
Compiler version: 0.8.22
Optimizations:    200

Submitted verification for [src/MessagingPlugin.sol:MessagingPlugin] 0x79050486765BE9573fDb341b0686576d32d73A9b.
```

## CONTRACT VERIFIED 📋✅ HERE:
https://sepolia.etherscan.io/address/0x79050486765BE9573fDb341b0686576d32d73A9b#code

