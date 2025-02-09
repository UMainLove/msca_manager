import { initializeSmartAccountClient } from "./ModularAccount";
import { parseEther } from "viem";
import type { SendUserOperationResult } from "@alchemy/aa-core";

// eslint-disable-next-line max-len
const ADDR = "0x96c3099a64603291a37940559d9641C05583efB4"; // replace with the adress you want to send SepoliaETH to
const ADDR2 = "0x7ed28ed143Ca625Bcf315587a30a15aceeA5E9d5";

/**
 * @description Sends ETH to a specified address (could be an EOA or MSCA). The gas fees are sponsored by the Alchemy Gas Manager.
 * This is the manual way to send ETH to an address. It's already implemented in the UI, but you can use this function to test it.
 */

export async function sendUserOperation() {
    const smartAccountClient = await initializeSmartAccountClient();
    if (!smartAccountClient) {
        throw new Error("Failed to initialize smart account client");
    }
    const amountToSend: bigint = parseEther("0.0001");

    try {
    const result: SendUserOperationResult =
        await smartAccountClient.sendUserOperation({
            uo: {
                target: ADDR2,
                data: "0x",
                value: amountToSend,
            },
        });

    console.log("User operation result: ", result);

    console.log(
        "\nWaiting for the user operation to be included in a mined transaction..."
    );

    const txHash = await smartAccountClient.waitForUserOperationTransaction(
        result
    );

    console.log("\nTransaction hash: ", txHash);

    const userOpReceipt = await smartAccountClient.getUserOperationReceipt(
        result.hash as `0x${string}`
    );

    console.log("\nUser operation receipt: ", userOpReceipt);

    const txReceipt = await smartAccountClient.waitForTransactionReceipt({
        hash: txHash,
    });

    return txReceipt;

} catch (error) {
    console.error("Error in transaction: ", error);
    throw error;
}
}

if (require.main === module) {
    sendUserOperation()
        .then((txReceipt) => {
            console.log("\nTransaction receipt: ", txReceipt);
        })
        .catch((err) => {
            console.error("Error: ", err);
        })
        .finally(() => {
            console.log("\n--- DONE ---");
        });
}