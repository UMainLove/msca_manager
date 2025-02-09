"use client";

import { useState, useEffect } from "react";
import { useUser, useSignerStatus, useLogout } from "@account-kit/react";
import { useRouter } from "next/navigation";
import { Address, Hash } from "viem";
import { UserOperation } from "./components/types";
import { SendEthForm } from "./components/SendEthForm";
import { UserOperationsList } from "./components/UserOperationsList";
import { NavigationButtons } from "./components/NavigationButtons";
import { fetchInternalTransactions } from "./utils";

const STORAGE_KEY = 'userOperations';

function replaceBigIntsWithStrings(obj: any): any {
    if (obj === null || obj === undefined) {
        return obj;
    }

    if (typeof obj === 'bigint') {
        return obj.toString();
    }

    if (Array.isArray(obj)) {
        return obj.map(replaceBigIntsWithStrings);
    }

    if (typeof obj === 'object') {
        const result: { [key: string]: any } = {};
        for (const key in obj) {
            result[key] = replaceBigIntsWithStrings(obj[key]);
        }
        return result;
    }

    return obj;
}

export default function TransactionsPage() {
    const user = useUser();
    const { isInitializing } = useSignerStatus();
    const { logout } = useLogout();
    const router = useRouter();

    const [userOps, setUserOps] = useState<UserOperation[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [historicalOps, setHistoricalOps] = useState<UserOperation[]>([]);
    const [isLoadingHistory, setIsLoadingHistory] = useState(false);
    const [historyError, setHistoryError] = useState<string | null>(null);

    // Load saved operations on mount
    useEffect(() => {
        if (user?.address) {
            const key = `${STORAGE_KEY}-${user.address}`;
            const savedOps = localStorage.getItem(key);
            if (savedOps) {
                try {
                    const parsedOps = JSON.parse(savedOps);
                    setUserOps(parsedOps);
                } catch (error) {
                    console.error('Error loading saved operations:', error);
                }
            }
            setIsLoading(false);
        }
    }, [user?.address]);

    // Save operations when they change
    useEffect(() => {
        if (user?.address && !isLoading) {
            const key = `${STORAGE_KEY}-${user.address}`;
            const safeUserOps = replaceBigIntsWithStrings(userOps);
            localStorage.setItem(key, JSON.stringify(safeUserOps));
        }
    }, [userOps, user?.address, isLoading]);

    // Protect route - redirect if not authenticated
    useEffect(() => {
        if (!user && !isInitializing) {
            router.push("/");
        }
    }, [user, isInitializing, router]);

    // Handler for new operations
    const handleNewOperation = (operation: UserOperation) => {
        setUserOps(prev => [operation, ...prev]);
    };

    // Handler for operation updates
    const handleOperationUpdate = (hash: Hash, updates: Partial<UserOperation>) => {
        setUserOps(prev => prev.map(op =>
            op.hash === hash
                ? { ...op, ...updates }
                : op
        ));
    };

    // Update the useEffect that loads historical operations
    useEffect(() => {
        async function loadHistoricalOperations() {
            if (user?.address) {
                setIsLoadingHistory(true);
                setHistoryError(null);
                try {
                    const msca = "0x87624F0e8d1837232D6c26f184d581DcB6791349";
                    const transactions = await fetchInternalTransactions(msca);

                    const historicalOperations = transactions.map((tx:{ hash: string; to: string; value: any; timestamp: any; status: string;}) => ({
                        hash: tx.hash as Hash,
                        target: tx.to as Address,
                        value: tx.value,
                        timestamp: tx.timestamp,
                        status: tx.status as 'completed' | 'failed',
                    }));

                    setHistoricalOps(historicalOperations);
                } catch (error) {
                    setHistoryError('Failed to load transaction history');
                    console.error(error);
                } finally {
                    setIsLoadingHistory(false);
                }
            }
        }

        loadHistoricalOperations();
    }, [user?.address]);

    if (isInitializing || isLoading) {
        return (
            <div className="flex min-h-screen items-center justify-center">
                <p>Loading...</p>
            </div>
        );
    }

    // Combine current and historical operations, removing duplicates by hash
    const allOperations = [...userOps, ...historicalOps]
        .reduce((unique: UserOperation[], op) => {
            const exists = unique.find(u => u.hash === op.hash);
            if (!exists) {
                unique.push(op);
            }
            return unique;
        }, [])
        .sort((a, b) => b.timestamp - a.timestamp);
    
    if (!user) {
        return null;
    }

    return (
        <main className="flex min-h-screen flex-col items-center p-6">
            <div className="max-w-4xl w-full space-y-8">
                <SendEthForm
                    onOperationSubmitted={handleNewOperation}
                    onOperationUpdated={handleOperationUpdate}
                />
                {historyError && (
                    <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative" role="alert">
                        <strong className="font-bold">Error: </strong>
                        <span className="block sm:inline">{historyError}</span>
                    </div>
                )}
                <UserOperationsList
                    operations={allOperations}
                />
                <NavigationButtons onLogout={logout} />
            </div>
        </main>
    );
}