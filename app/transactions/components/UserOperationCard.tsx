"use client";

import { ethers } from "ethers";
import { UserOperation } from "./types";
import { replaceBigIntsWithStrings } from "./types";

interface UserOperationCardProps {
    operation: UserOperation;
}

export function UserOperationCard({ operation: op }: UserOperationCardProps) {
    return (
        <div className="bg-black-50 p-4 rounded-lg shadow-sm mb-4">
            <div className="flex justify-between items-start">
                <div className="space-y-2">
                    <p className="font-mono text-sm break-all">
                        Hash: {op.hash}
                    </p>
                    <p className="text-sm">
                        To: <span className="font-mono">{op.target}</span>
                    </p>
                    <p className="text-sm">
                        Value: {op.value} ETH
                    </p>
                    <p className="text-sm">
                        Time: {new Date(op.timestamp).toLocaleString()}
                    </p>
                </div>
                <span className={`px-2 py-1 rounded text-sm ${op.status === 'completed'
                        ? 'bg-green-100 text-green-800'
                        : op.status === 'failed'
                            ? 'bg-red-100 text-red-800'
                            : 'bg-yellow-100 text-yellow-800'
                    }`}>
                    {op.status.charAt(0).toUpperCase() + op.status.slice(1)}
                </span>
            </div>

            {/* UserOp Receipt Details */}
            {op.userOpReceipt && (
                <div className="mt-4 pt-2 border-t border-gray-200">
                    <p className="text-sm font-medium mb-2">User Operation Details:</p>
                    <div className="space-y-1 text-sm">
                        <p>EntryPoint: <span className="font-mono">{op.userOpReceipt.entryPoint}</span></p>
                        <p>Sender: <span className="font-mono">{op.userOpReceipt.sender}</span></p>
                        <p>Nonce: {op.userOpReceipt.nonce.toString()}</p>
                        {op.userOpReceipt.paymaster && (
                            <p>Paymaster: <span className="font-mono">{op.userOpReceipt.paymaster}</span></p>
                        )}
                        <p>Gas Cost: {ethers.formatEther(op.userOpReceipt.actualGasCost.toString())} ETH</p>
                        <p>Gas Used: {op.userOpReceipt.actualGasUsed.toString()}</p>
                        {op.userOpReceipt.reason && (
                            <p className="text-red-600">Reason: {op.userOpReceipt.reason}</p>
                        )}
                        {op.userOpReceipt.logs.length > 0 && (
                            <div>
                                <p className="font-medium mt-2">Logs:</p>
                                <pre className="text-xs mt-1 bg-gray-50 p-2 rounded">
                                    {op.userOpReceipt.logs.join('\n')}
                                </pre>
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* Transaction Receipt */}
            {op.txReceipt && (
                <div className="mt-2 pt-2 border-t border-gray-200">
                    <p className="text-sm font-medium">Transaction Receipt:</p>
                    <pre className="text-xs mt-1 overflow-x-auto">
                        {JSON.stringify(replaceBigIntsWithStrings(op.txReceipt), null, 2)}
                    </pre>
                </div>
            )}
        </div>
    );
}