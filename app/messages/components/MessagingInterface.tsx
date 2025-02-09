// app/messages/components/MessagingInterface.tsx
"use client";

import { useState, useEffect } from "react";
import { initializeSmartAccountClient } from "@/modular-account/src/ModularAccount";
import { createPublicClient, http, Address, type Hash } from "viem";
import { sepolia } from "viem/chains";
import { SendUserOperationResult } from "@alchemy/aa-core";
import { MessagingPlugin, MessagingPluginExecutionFunctionAbi, messagingPluginActions } from "@/modular-account/plugins/generated/plugin";
import { MessageOperation, ExtendedTransactionReceipt } from "./types";
import { delay, retryOperation, saveMessageOperations, loadMessageOperations, cacheChat, getCachedChat } from "../utils";

interface Message {
    content: string;
    timestamp: number;
    isSent: boolean;
}

interface ChatHistory {
    [address: string]: Message[];
}

export default function MessagingInterface() {
    const [recipientAddress, setRecipientAddress] = useState("");
    const [message, setMessage] = useState("");
    const [chatHistory, setChatHistory] = useState<ChatHistory>({});
    const [selectedChat, setSelectedChat] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [operations, setOperations] = useState<MessageOperation[]>([]);
    const [smartAccountAddress, setSmartAccountAddress] = useState<string |null>(null);

    // Load initial operations
    useEffect(() => {
        const loadInitialData = async () => {
            const smartAccountClient = await initializeSmartAccountClient();
            const address = await smartAccountClient.account.address;
            setSmartAccountAddress(address);

            const savedOps = loadMessageOperations(address);
            setOperations(savedOps);
        };

        loadInitialData();
    }, []);

    const handleOperationSubmitted = (operation: MessageOperation) => {
        if (!smartAccountAddress) return;

        setOperations(prev => {
            const newOps = [operation, ...prev];
            saveMessageOperations(smartAccountAddress, newOps);
            return newOps;
        });
    };

    const handleOperationUpdated = (hash: Hash, updates: Partial<MessageOperation>) => {
        if (!smartAccountAddress) return;

        setOperations(prev => {
            const newOps = prev.map(op =>
                op.hash === hash ? { ...op, ...updates } : op
            );
            saveMessageOperations(smartAccountAddress, newOps);
            return newOps;
        });
    };

    // Load chat history for a specific address
    const loadChatHistory = async (address: string) => {
        if (!address.startsWith('0x') || !smartAccountAddress) return;

        try {
            setLoading(true);
            setError(null);

            // Check cache first
            const cachedMessages = getCachedChat(smartAccountAddress, address);
            if (cachedMessages) {
                setChatHistory(prev => ({
                    ...prev,
                    [address]: cachedMessages.map(content => ({
                        content,
                        timestamp: Date.now(),
                        isSent: true
                    }))
                }));
                setSelectedChat(address);
                return;
            }

            // If no cache, load from blockchain
            const publicClient = createPublicClient({
                chain: sepolia,
                transport: http(),
            });

            const contract = MessagingPlugin.getContract(
                publicClient,
                MessagingPlugin.meta.addresses[sepolia.id]!
            );

            const formattedAddress = address as Address;

            try {
                // Look for PluginInstalled events
                const pluginEvents = await publicClient.getLogs({
                    address: formattedAddress,
                    event: {
                        type: 'event',
                        name: 'PluginInstalled',
                        inputs: [
                            { type: 'address', name: 'plugin', indexed: true },
                            { type: 'bytes32', name: 'manifestHash', indexed: false },
                            { type: 'bytes[]', name: 'dependencies', indexed: false }
                        ]
                    },
                    fromBlock: 'earliest'
                });

                // Check if our messaging plugin was installed
                const hasPlugin = pluginEvents.some(event =>
                    event.args.plugin?.toLowerCase() === MessagingPlugin.meta.addresses[sepolia.id]?.toLowerCase()
                );

                if (!hasPlugin) {
                    throw new Error("Recipient does not have the messaging plugin installed");
                }

                console.log("Found plugin installation for recipient:", formattedAddress);

            } catch (err) {
                console.error("Error checking recipient plugin events:", err);
                throw new Error("Failed to verify recipient's plugin status");
            }

            const messages = await contract.read.getChat([formattedAddress]);

            // Update cache
            cacheChat(smartAccountAddress, address, [...messages]);

            // Update state
            setChatHistory(prev => ({
                ...prev,
                [address]: messages.map((msg: string) => ({
                    content: msg,
                    timestamp: Date.now(),
                    isSent: true
                }))
            }));

            setSelectedChat(address);

        } catch (err) {
            console.error("Error loading chat:", err);
            setError("Failed to load chat history");
        } finally {
            setLoading(false);
        }
    };

    const sendMessage = async () => {
        if (!recipientAddress || !message || !smartAccountAddress) return;

        setLoading(true);
        setError(null);

        let storedHash: Hash | undefined;
        let transactionHash: string | undefined;

        try {
            const smartAccountClient = await initializeSmartAccountClient();
            const formattedAddress = recipientAddress as Address;

            // Check not sending to self
            if (formattedAddress.toLowerCase() === smartAccountAddress.toLowerCase()) {
                throw new Error("Cannot send messages to yourself");
            }

            // Extend the client with messaging plugin actions
            const messagingClient = smartAccountClient.extend(messagingPluginActions);

            // Create message operation using the generated plugin actions
            const result = await messagingClient.sendMessage({
                args: [formattedAddress, message],
                overrides: {
                    dummySignature: "0xfffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c",
                    callGasLimit: { multiplier: 1.5 },
                    preVerificationGas: { multiplier: 1.5 },
                    verificationGasLimit: { multiplier: 1.5 }
                }
            });
            storedHash = await result.hash as Hash;

            console.log("UserOperation:", result.hash )

            // Create new operation record
            const newOp: MessageOperation = await {
                hash: storedHash,
                target: formattedAddress,
                value: "0",
                timestamp: Date.now(),
                status: 'pending',
                content: message,
                recipientAddress: formattedAddress,
                request: {
                    sender: smartAccountAddress,
                    nonce: result.request.nonce,
                    initCode: "0x",
                    callData: result.request.callData,
                    paymasterAndData: 'paymaster' in result.request
                        ? `${result.request.paymaster || "0x"}${(result.request.paymasterData || "0x").slice(2)}`
                        : (result.request as any).paymasterAndData || "0x",
                    signature: result.request.signature
                }
            };

            handleOperationSubmitted(newOp);

            // Wait for transaction with retries
            const txHash = await retryOperation(
                () => smartAccountClient.waitForUserOperationTransaction(result),
                3,
                (error, attempt) => console.log(`Attempt ${attempt} failed:`, error)
            );
            transactionHash = txHash;

            await delay(0);

            // Get receipts with retries
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

            const receipt = await retryOperation(
                () => smartAccountClient.waitForTransactionReceipt({
                    hash: txHash,
                }),
                3
            );

            // Handle the receipt
            handleOperationUpdated(storedHash, {
                status: userOpReceipt?.success ? 'completed' : 'failed',
                userOpReceipt,
                txReceipt: receipt as unknown as ExtendedTransactionReceipt,
                failureReason: userOpReceipt?.reason
            });

            if (userOpReceipt?.success) {
                // Update chat history
                const newMessage = {
                    content: message,
                    timestamp: Date.now(),
                    isSent: true
                };

                setChatHistory(prev => ({
                    ...prev,
                    [recipientAddress]: [...(prev[recipientAddress] || []), newMessage]
                }));

                setMessage("");

                // Reload chat after delay
                setTimeout(() => {
                    loadChatHistory(recipientAddress);
                }, 2000);
            }

        } catch (error: any) {
            console.error("Error sending message:", error);
            let errorMessage = "Failed to send message";

            // Handle rate limit error case
            if (error.message?.includes('429') && transactionHash && storedHash) {
                handleOperationUpdated(storedHash, {
                    status: 'completed',
                    txReceipt: {
                        transactionHash,
                        confirmations: 1,
                        byzantium: true,
                    } as unknown as ExtendedTransactionReceipt
                });
                return;
            }

            if (error.data?.revertData) {
                const revertData = error.data.revertData;
                console.log("Revert data:", revertData);

                if (revertData.includes("0xfa06f06e")) {
                    errorMessage = "Operation validation failed. This might be a permissions issue.";
                } else {
                    errorMessage = `Operation reverted: ${revertData}`;
                }
            } else if (error.message) {
                errorMessage = await error.message;
            }

            setError(errorMessage);

            if (storedHash) {
                handleOperationUpdated(storedHash, {
                    status: 'failed',
                    failureReason: errorMessage
                });
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="flex flex-col space-y-4">
            <div className="flex space-x-2">
                <input
                    type="text"
                    value={recipientAddress}
                    onChange={(e) => setRecipientAddress(e.target.value)}
                    placeholder="Recipient Address (0x...)"
                    className="flex-1 p-2 border rounded text-black"
                />
                <button
                    onClick={() => recipientAddress && loadChatHistory(recipientAddress)}
                    className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
                    disabled={loading || !recipientAddress.startsWith('0x')}
                >
                    Load Chat
                </button>
            </div>

            {/* Chat Display */}
            <div className="border rounded p-4 min-h-[300px] bg-gray-50 text-black">
                {selectedChat && chatHistory[selectedChat] ? (
                    <div className="space-y-2">
                        {chatHistory[selectedChat].map((msg, index) => (
                            <div
                                key={index}
                                className={`p-2 rounded max-w-[80%] ${msg.isSent
                                        ? "bg-blue-500 text-black ml-auto"
                                        : "bg-gray-300"
                                    }`}
                            >
                                <div className="break-words">{msg.content}</div>
                                <div className="text-xs opacity-75">
                                    {new Date(msg.timestamp).toLocaleTimeString()}
                                </div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="text-center text-gray-500">
                        No messages to display
                    </div>
                )}
            </div>

            <div className="flex space-x-2">
                <input
                    type="text"
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    placeholder="Type your message...[Max 300 chars]"
                    className="flex-1 p-2 border rounded text-black"
                    maxLength={300}
                />
                <button
                    onClick={sendMessage}
                    disabled={loading || !recipientAddress || !message}
                    className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:bg-gray-400"
                >
                    {loading ? "Sending..." : "Send"}
                </button>
            </div>

            {error && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative">
                    <strong className="font-bold">Error: </strong>
                    <span className="block sm:inline">{error}</span>
                </div>
            )}

            {/* Recent Operations */}
            {operations.length > 0 && (
                <div className="mt-4">
                    <h3 className="text-lg font-semibold mb-2">Recent Message Operations</h3>
                    <div className="space-y-2">
                        {operations.map((op) => (
                            <div
                                key={op.hash}
                                className={`p-3 rounded border ${op.status === 'pending' ? 'bg-yellow-50 border-yellow-200' :
                                        op.status === 'completed' ? 'bg-green-50 border-green-200' :
                                            'bg-red-50 border-red-200'
                                    }`}
                            >
                                <div className="flex justify-between items-start">
                                    <div>
                                        <p className="font-medium text-black">To: {op.recipientAddress}</p>
                                        <p className="text-sm text-gray-600">{op.content}</p>
                                    </div>
                                    <span className={`text-sm ${op.status === 'pending' ? 'text-yellow-600' :
                                            op.status === 'completed' ? 'text-green-600' :
                                                'text-red-600'
                                        }`}>
                                        {op.status}
                                    </span>
                                </div>
                                {op.failureReason && (
                                    <p className="text-sm text-red-600 mt-1">{op.failureReason}</p>
                                )}
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
}