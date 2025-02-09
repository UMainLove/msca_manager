"use client";

import { useState } from "react";
import { ethers } from "ethers";
import { parseEther } from "viem";
import type { SendUserOperationResult } from "@alchemy/aa-core";
import { Hash, Address } from "viem";
import { initializeSmartAccountClient } from "@/modular-account/src/ModularAccount";
import { UserOperation } from "./types";
import { delay, retryOperation } from "../utils";
import { ExtendedTransactionReceipt } from "./types";

interface SendEthFormProps {
    onOperationSubmitted: (operation: UserOperation) => void;
    onOperationUpdated: (hash: Hash, updates: Partial<UserOperation>) => void;
}

export function SendEthForm({ onOperationSubmitted, onOperationUpdated }: SendEthFormProps) {
    const [recipient, setRecipient] = useState("");
    const [amount, setAmount] = useState("");
    const [isSending, setIsSending] = useState(false);
    const [sendError, setSendError] = useState<string | null>(null);

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSending(true);
        setSendError(null);

        let storedHash: Hash | undefined;
        let transactionHash: string | undefined;

        try {
            const smartAccountClient = await initializeSmartAccountClient();
            if (!smartAccountClient) {
                throw new Error("Failed to initialize smart account client");
            }

            if (!recipient.startsWith('0x') || !ethers.isAddress(recipient)) {
                throw new Error("Invalid recipient address");
            }

            const amountToSend = parseEther(amount);
            const formattedAddress = recipient as `0x${string}`;

            const result: SendUserOperationResult =
                await smartAccountClient.sendUserOperation({
                    uo: {
                        target: formattedAddress,
                        data: "0x",
                        value: amountToSend,
                    },
                });
            storedHash = result.hash as Hash;

            // Create and submit new operation
            const newOp: UserOperation = {
                hash: storedHash,
                target: formattedAddress as Address,
                value: amount,
                timestamp: Date.now(),
                status: 'pending',
                request: result.request
            };
            onOperationSubmitted(newOp);

            // Wait for transaction
            const txHash = await retryOperation(
                () => smartAccountClient.waitForUserOperationTransaction(result),
                3,
                (error, attempt) => console.log(`Attempt ${attempt} failed:`, error)
            );
            transactionHash = txHash;

            await delay(0);

            // Get receipts
            const userOpReceipt = await retryOperation(
                () => smartAccountClient.getUserOperationReceipt(storedHash as Hash),
                3,
                (error, attempt) => {
                    if (error instanceof Error && error.message.includes('429')) {
                        console.log('Rate limit hit, backing off...');
                    }
                }
            );

            await delay(0);

            const txReceipt = await retryOperation(
                () => smartAccountClient.waitForTransactionReceipt({
                    hash: txHash,
                }),
                3
            );

            // Update operation status
            onOperationUpdated(storedHash, {
                status: 'completed',
                userOpReceipt,
                txReceipt: txReceipt as unknown as ExtendedTransactionReceipt,
                failureReason: userOpReceipt?.reason
            });

            // Reset form
            setRecipient("");
            setAmount("");

        } catch (error) {
            if (error instanceof Error &&
                error.message.includes('429') &&
                transactionHash &&
                storedHash) {
                onOperationUpdated(storedHash, {
                    status: 'completed',
                    txReceipt: {
                        transactionHash
                    } as unknown as ExtendedTransactionReceipt
                });
            } else {
                console.error("Error sending ETH:", error);
                const errorMessage = error instanceof Error ? error.message : "Failed to send ETH";
                setSendError(errorMessage);

                if (storedHash) {
                    onOperationUpdated(storedHash, {
                        status: 'failed',
                        failureReason: errorMessage
                    });
                }
            }
        } finally {
            setIsSending(false);
        }
    };

    return (
        <section className="bg-black-100 p-6 rounded-lg">
            <h2 className="text-xl font-bold mb-4">Send SepoliaETH</h2>
            <form onSubmit={handleSend} className="space-y-4">
                <div>
                    <label className="block text-sm font-medium mb-1">
                        Recipient Address
                    </label>
                    <input
                        type="text"
                        value={recipient}
                        onChange={(e) => setRecipient(e.target.value)}
                        className="w-full p-2 border rounded text-black py-2 px-4"
                        placeholder="0x..."
                        required
                    />
                </div>
                <div>
                    <label className="block text-sm font-medium mb-1">
                        Amount (ETH)
                    </label>
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        className="w-full p-2 border rounded text-black py-2 px-4"
                        placeholder="0.0"
                        step="0.0001"
                        min="0"
                        required
                    />
                </div>
                {sendError && (
                    <p className="text-red-600 text-sm">{sendError}</p>
                )}
                <button
                    type="submit"
                    disabled={isSending}
                    className="w-full bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700 disabled:opacity-50"
                >
                    {isSending ? "Sending..." : "Send ETH"}
                </button>
            </form>
        </section>
    );
}