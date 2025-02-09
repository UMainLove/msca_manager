// app/messages/utils.ts
import * as dotenv from "dotenv";
dotenv.config({ path: '.env.local' });
import { MessageOperation, replaceBigIntsWithStrings } from "./components/types";

const MESSAGE_STORAGE_KEY = 'messageOperations';
const CHAT_STORAGE_KEY = 'chatHistory';

// Basic delay utility
/*export const delay = (attempt: number) => new Promise(resolve =>
    setTimeout(resolve, Math.min(1000 * Math.pow(2, attempt), 10000))
);*/
export const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Generic retry operation with exponential backoff
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

// Save message operations for a specific account
export function saveMessageOperations(address: string, operations: any[]): void {
    try {
        const key = `${MESSAGE_STORAGE_KEY}-${address}`;
        const serializedOps = replaceBigIntsWithStrings(operations);
        localStorage.setItem(key, JSON.stringify(serializedOps));
    } catch (error) {
        console.error('Error saving message operations:', error);
    }
}

// Load message operations for a specific account
export function loadMessageOperations(address: string): any[] {
    try {
        const key = `${MESSAGE_STORAGE_KEY}-${address}`;
        const saved = localStorage.getItem(key);
        return saved ? JSON.parse(saved) : [];
    } catch (error) {
        console.error('Error loading message operations:', error);
        return [];
    }
}

// Interface for local chat cache
interface ChatHistoryCache {
    messages: string[];
    lastUpdated: number;
    version: number;
}

// Cache chat history locally with versioning and TTL
export function cacheChat(senderAddress: string, recipientAddress: string, messages: string[]): void {
    try {
        const key = `${CHAT_STORAGE_KEY}-${senderAddress}-${recipientAddress}`;
        const cache: ChatHistoryCache = {
            messages,
            lastUpdated: Date.now(),
            version: 1 // For future cache structure updates
        };
        localStorage.setItem(key, JSON.stringify(cache));
    } catch (error) {
        console.error('Error caching chat history:', error);
    }
}

// Get cached chat with TTL check
export function getCachedChat(senderAddress: string, recipientAddress: string, maxAge: number = 30000): string[] | null {
    try {
        const key = `${CHAT_STORAGE_KEY}-${senderAddress}-${recipientAddress}`;
        const cached = localStorage.getItem(key);

        if (!cached) return null;

        const cache: ChatHistoryCache = JSON.parse(cached);
        const age = Date.now() - cache.lastUpdated;

        // Return null if cache is too old
        if (age > maxAge) {
            localStorage.removeItem(key);
            return null;
        }

        return cache.messages;
    } catch (error) {
        console.error('Error retrieving cached chat:', error);
        return null;
    }
}

// Utility to combine operations and chat history
export function mergeChatOperations(
    operations: MessageOperation[],
    chatHistory: string[],
    recipientAddress: string
): MessageOperation[] {
    const chatOps = chatHistory.map((message, index) => ({
        hash: `chat-${index}` as any, // This is just for local reference
        target: recipientAddress as any,
        value: "0",
        timestamp: Date.now() - (chatHistory.length - index) * 1000, // Approximate timestamps
        status: 'completed' as const,
        content: message,
        recipientAddress
    }));

    // Merge and deduplicate based on content and timestamp
    const merged = [...operations, ...chatOps];
    const seen = new Set();

    return merged.filter(op => {
        const key = `${op.content}-${op.timestamp}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    }).sort((a, b) => b.timestamp - a.timestamp);
}

// Get all unique chat participants from operations
export function getChatParticipants(operations: MessageOperation[]): string[] {
    const participants = new Set<string>();
    operations.forEach(op => {
        participants.add(op.recipientAddress);
    });
    return Array.from(participants);
}