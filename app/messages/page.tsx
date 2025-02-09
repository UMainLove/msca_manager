"use client";

import { useEffect, useState } from "react";
import { useUser, useSignerStatus, useLogout } from "@account-kit/react";
import { useRouter } from "next/navigation";
import { initializeSmartAccountClient } from "@/modular-account/src/ModularAccount";
import { ethers } from "ethers";
import MessagingInterface from "./components/MessagingInterface";
import { NavigationButtons } from "./components/NavigationButtons";

const ALCHEMY_API_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;
const MESSAGING_PLUGIN_ADDRESS = "0x79050486765BE9573fDb341b0686576d32d73A9b";
const STORAGE_KEY = 'messagingPlugin';

export default function MessagesPage() {
    const user = useUser();
    const { isInitializing } = useSignerStatus();
    const { logout } = useLogout();
    const router = useRouter();
    const [hasPlugin, setHasPlugin] = useState<boolean | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // Protect route - redirect if not authenticated
    useEffect(() => {
        if (!user && !isInitializing) {
            router.push("/");
        }
    }, [user, isInitializing, router]);

    // Check plugin installation
    useEffect(() => {
        async function checkPlugin() {
            if (user) {
                try {
                    setIsLoading(true);
                    setError(null);

                    // Try to load from cache first
                    const cachedStatus = localStorage.getItem(`${STORAGE_KEY}-${user.address}`);
                    if (cachedStatus) {
                        setHasPlugin(JSON.parse(cachedStatus));
                    }

                    // Check current status
                    const smartAccountClient = await initializeSmartAccountClient();
                    const address = await smartAccountClient.account.address;
                    const provider = new ethers.JsonRpcProvider(
                        `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`
                    );

                    const CONTRACT_ABI = [
                        "function getInstalledPlugins() external view returns (address[])"
                    ];

                    const contract = new ethers.Contract(
                        address,
                        CONTRACT_ABI,
                        provider
                    );

                    const plugins = await contract.getInstalledPlugins();
                    const pluginStatus = plugins.includes(MESSAGING_PLUGIN_ADDRESS);

                    // Update cache and state
                    localStorage.setItem(`${STORAGE_KEY}-${user.address}`, JSON.stringify(pluginStatus));
                    setHasPlugin(pluginStatus);

                } catch (error) {
                    console.error("Error checking plugins:", error);
                    setError("Failed to check plugin status");
                    setHasPlugin(false);
                } finally {
                    setIsLoading(false);
                }
            }
        }
        checkPlugin();
    }, [user]);

    // Loading state
    if (isInitializing || isLoading) {
        return (
            <div className="flex min-h-screen items-center justify-center">
                <p>Loading...</p>
            </div>
        );
    }

    // Error state
    if (error) {
        return (
            <div className="flex min-h-screen flex-col items-center p-6">
                <div className="max-w-4xl w-full space-y-8 text-center">
                    <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative" role="alert">
                        <strong className="font-bold">Error: </strong>
                        <span className="block sm:inline">{error}</span>
                    </div>
                    <NavigationButtons onLogout={logout} />
                </div>
            </div>
        );
    }

    // Plugin not installed state
    if (!hasPlugin) {
        return (
            <div className="flex min-h-screen flex-col items-center p-6">
                <div className="max-w-4xl w-full space-y-8 text-center">
                    <h1 className="text-2xl font-bold">Messaging Not Available</h1>
                    <p>Please install the Messaging Plugin to access this feature.</p>
                    <NavigationButtons onLogout={logout} />
                </div>
            </div>
        );
    }

    // No user state
    if (!user) {
        return null;
    }

    // Main content
    return (
        <main className="flex min-h-screen flex-col items-center p-6">
            <div className="max-w-4xl w-full space-y-8">
                <h1 className="text-2xl font-bold text-center">Messages</h1>
                <MessagingInterface />
                <NavigationButtons onLogout={logout} />
            </div>
        </main>
    );
}