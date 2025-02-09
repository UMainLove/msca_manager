import type { PluginConfig } from "@account-kit/plugingen";
import { parseAbiParameters } from "viem";
import { sepolia } from 'viem/chains';
import { MessagingPluginAbi } from "./abi.js";
import { MultiOwnerPluginGenConfig } from "@account-kit/smart-contracts/plugin-defs";

export const MessagingPluginGenConfig: PluginConfig = {
    name: "MessagingPlugin",
    abi: MessagingPluginAbi,
    addresses: {
        [sepolia.id]: "0x79050486765BE9573fDb341b0686576d32d73A9b",
    },
    installConfig: {
        initAbiParams: parseAbiParameters("bytes"), // MessagingPlugin auto-initializes on install
        dependencies: [
            {
                // For runtime validation - RUNTIME_VALIDATION_OWNER_OR_SELF
                plugin: MultiOwnerPluginGenConfig,
                functionId: "0x0", // RUNTIME_VALIDATION_OWNER_OR_SELF
            },
            {
                // For userOp validation - USER_OP_VALIDATION_OWNER
                plugin: MultiOwnerPluginGenConfig,
                functionId: "0x1", // USER_OP_VALIDATION_OWNER
            }
        ]
    },
};