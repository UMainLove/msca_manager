import { alchemy, sepolia } from "@account-kit/infra";
import { LocalAccountSigner } from "@aa-sdk/core";
import { encodePacked, type Address, createPublicClient, http, keccak256, encodeAbiParameters } from "viem";
import { MessagingPlugin } from "../plugins/generated/plugin";
import { MultiOwnerPlugin, installPlugin, createModularAccountAlchemyClient } from "@account-kit/smart-contracts";
import * as dotenv from "dotenv";
dotenv.config({ path: '.env.local' });


// Import the environment variables
const PRIV_KEY = process.env.NEXT_PUBLIC_METAMASK_PRIVATE_KEY!;
const ALCHEMY_API_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY!;
const GAS_ID = process.env.NEXT_PUBLIC_PAYMASTER_POLICY_ID!;

//Create another account to test 'MessagingPlugin'
const PRIV_KEY2 = process.env.NEXT_PUBLIC_METAMASK_PRIVATE_KEY2!;
/**
* @description Installs Plugins on the modular smart contract account through the generated plugin client. (in this case, MessagingPlugin)
*/

console.log("\nInitializing smart account client...");
                const alchemyAccountClient = await createModularAccountAlchemyClient({
                        transport: alchemy({ apiKey: `${ALCHEMY_API_KEY}` }),
                        chain: sepolia,
                        signer: LocalAccountSigner.privateKeyToAccountSigner(`0x${PRIV_KEY2}`),
                        policyId: GAS_ID
                });

                // Create dependencies
                const messagingPluginAddress = MessagingPlugin.meta.addresses[sepolia.id];
                const multiOwnerPluginAddress = MultiOwnerPlugin.meta.addresses[sepolia.id];
                
                if (!messagingPluginAddress || !multiOwnerPluginAddress) {
                        throw new Error(`Plugin addresses not found for Sepolia:
                MessagingPlugin: ${messagingPluginAddress}
                MultiOwnerPlugin: ${multiOwnerPluginAddress}`);
                }

console.log("Plugin Addresses:", {
        messagingPlugin: messagingPluginAddress,
        multiOwnerPlugin: multiOwnerPluginAddress
});

                const dependencies = [
                        // Runtime validation (RUNTIME_VALIDATION_OWNER_OR_SELF)
                        encodePacked(
                                ["address", "uint8"],
                                [multiOwnerPluginAddress as Address, 0x0]
                        ),
                        // UserOp validation (USER_OP_VALIDATION_OWNER)
                        encodePacked(
                                ["address", "uint8"],
                                [multiOwnerPluginAddress as Address, 0x1]
                        ),
                ];

// Create public client to read manifestHash
const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(`https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`)
});

// Get the manifest hash from contract
const plugin = MessagingPlugin.getContract(publicClient, messagingPluginAddress);
const manifest = await plugin.read.pluginManifest();
// Generate manifest hash
const manifestHash = keccak256(encodeAbiParameters([{
        type: 'tuple',
        components: [
                { type: 'bytes4[]', name: 'interfaceIds' },
                { type: 'bytes4[]', name: 'dependencyInterfaceIds' },
                { type: 'bytes4[]', name: 'executionFunctions' },
                { type: 'bytes4[]', name: 'permittedExecutionSelectors' },
                { type: 'bool', name: 'permitAnyExternalAddress' },
                { type: 'bool', name: 'canSpendNativeToken' },
                {
                        type: 'tuple[]',
                        name: 'permittedExternalCalls',
                        components: [
                                { type: 'address', name: 'externalAddress' },
                                { type: 'bool', name: 'permitAnySelector' },
                                { type: 'bytes4[]', name: 'selectors' }
                        ]
                },
                {
                        type: 'tuple[]',
                        name: 'userOpValidationFunctions',
                        components: [
                                { type: 'bytes4', name: 'executionSelector' },
                                {
                                        type: 'tuple',
                                        name: 'associatedFunction',
                                        components: [
                                                { type: 'uint8', name: 'functionType' },
                                                { type: 'uint8', name: 'functionId' },
                                                { type: 'uint256', name: 'dependencyIndex' }
                                        ]
                                }
                        ]
                },
                {
                        type: 'tuple[]',
                        name: 'runtimeValidationFunctions',
                        components: [
                                { type: 'bytes4', name: 'executionSelector' },
                                {
                                        type: 'tuple',
                                        name: 'associatedFunction',
                                        components: [
                                                { type: 'uint8', name: 'functionType' },
                                                { type: 'uint8', name: 'functionId' },
                                                { type: 'uint256', name: 'dependencyIndex' }
                                        ]
                                }
                        ]
                },
                {
                        type: 'tuple[]',
                        name: 'preUserOpValidationHooks',
                        components: [
                                { type: 'bytes4', name: 'executionSelector' },
                                {
                                        type: 'tuple',
                                        name: 'associatedFunction',
                                        components: [
                                                { type: 'uint8', name: 'functionType' },
                                                { type: 'uint8', name: 'functionId' },
                                                { type: 'uint256', name: 'dependencyIndex' }
                                        ]
                                }
                        ]
                },
                {
                        type: 'tuple[]',
                        name: 'preRuntimeValidationHooks',
                        components: [
                                { type: 'bytes4', name: 'executionSelector' },
                                {
                                        type: 'tuple',
                                        name: 'associatedFunction',
                                        components: [
                                                { type: 'uint8', name: 'functionType' },
                                                { type: 'uint8', name: 'functionId' },
                                                { type: 'uint256', name: 'dependencyIndex' }
                                        ]
                                }
                        ]
                },
                {
                        type: 'tuple[]',
                        name: 'executionHooks',
                        components: [
                                { type: 'bytes4', name: 'executionSelector' },
                                {
                                        type: 'tuple',
                                        name: 'preExecHook',
                                        components: [
                                                { type: 'uint8', name: 'functionType' },
                                                { type: 'uint8', name: 'functionId' },
                                                { type: 'uint256', name: 'dependencyIndex' }
                                        ]
                                },
                                {
                                        type: 'tuple',
                                        name: 'postExecHook',
                                        components: [
                                                { type: 'uint8', name: 'functionType' },
                                                { type: 'uint8', name: 'functionId' },
                                                { type: 'uint256', name: 'dependencyIndex' }
                                        ]
                                }
                        ]
                }
        ]
}], [manifest]));


                const accountAddress = await alchemyAccountClient.getAddress();
                
console.log("\nStarting MessagingPlugin installation");
console.log("Account Address:", accountAddress);
console.log("Manifest Hash:", manifestHash);
                
                try {
console.log("\nSubmitting installation...");
                const { hash } = await installPlugin(alchemyAccountClient, {
                        pluginAddress: messagingPluginAddress,
                        manifestHash,
                        pluginInitData: "0x", // No init data needed
                        dependencies
                });

console.log("Installation operation submitted:", hash);
console.log("\nWaiting for user operation...");

                const txHash = await alchemyAccountClient.waitForUserOperationTransaction({
                        hash
                });

console.log("Transaction hash:", txHash);
console.log("\nWaiting for receipt...");

                const receipt = await alchemyAccountClient.waitForTransactionReceipt({
                        hash: txHash
                });

console.log("\n--- Installation completed successfully ---");
console.log("Receipt:", receipt);

                } catch (error: any) {
                        console.error("\nInstallation failed!");

                        // Try to extract useful error information
                        if (error.cause?.data?.revertData) {
                                console.error("Revert data:", error.cause.data.revertData);
                        }

                        if (error.metaMessages) {
                                console.error("\nRequest details:");
                                error.metaMessages.forEach((msg: string) => console.error(msg));
                        }

                        console.error("\nFull error:", error);
                        process.exit(1);
                }
