import * as dotenv from "dotenv";
dotenv.config({ path: '.env.local' });
import { UserOperation } from "./components/types";
import { ethers } from "ethers";

const STORAGE_KEY = 'userOperations';

export const delay = (attempt: number) => new Promise(resolve =>
    setTimeout(resolve, Math.min(1000 * Math.pow(2, attempt), 10000))
);

interface InternalTransaction {
    hash: string;
    blockNumber: string;
    timeStamp: string;
    from: string;
    to: string;
    value: string;
    contractAddress: string;
    input: string;
    type: string;
    isError: string;
    errCode: string;
}

export async function retryOperation<T>(
    operation: () => Promise<T>,
    maxAttempts: number = 3,
    onError?: (error: unknown, attempt: number) => void
): Promise<T> {
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
        try {
            return await operation();
        } catch (error) {
            onError?.(error, attempt + 1);

            const isRateLimit = error instanceof Error &&
                (error.message?.includes('429') || error.message?.includes('rate limit'));

            if (isRateLimit || attempt < maxAttempts - 1) {
                await delay(attempt);
                continue;
            }
            throw error;
        }
    }
    throw new Error("Max retry attempts reached");
}

export function saveOperations(address: string, operations: UserOperation[]): void {
    try {
        const key = `${STORAGE_KEY}-${address}`;
        localStorage.setItem(key, JSON.stringify(operations));
    } catch (error) {
        console.error('Error saving operations:', error);
    }
}

export function loadOperations(address: string): UserOperation[] {
    try {
        const key = `${STORAGE_KEY}-${address}`;
        const saved = localStorage.getItem(key);
        return saved ? JSON.parse(saved) : [];
    } catch (error) {
        console.error('Error loading operations:', error);
        return [];
    }
}

export async function fetchInternalTransactions(address: string) {
    const apiKey = process.env.NEXT_PUBLIC_ETHERSCAN_API_KEY;
    const baseUrl = 'https://api-sepolia.etherscan.io/api';

    const url = `${baseUrl}?module=account&action=txlistinternal&address=${address}&startblock=0&endblock=99999999&sort=desc&apikey=${apiKey}`;

    try {
        const response = await fetch(url);
        const data = await response.json();

        if (data.status === '1' && data.result) {
            return data.result.map((tx: InternalTransaction) => ({
                hash: tx.hash,
                timestamp: parseInt(tx.timeStamp) * 1000, // Convert to milliseconds
                from: tx.from,
                to: tx.to,
                value: ethers.formatEther(tx.value),
                status: tx.isError === '0' ? 'completed' : 'failed'
            }));
        }
        return [];
    } catch (error) {
        console.error('Error fetching internal transactions:', error);
        return [];
    }
}