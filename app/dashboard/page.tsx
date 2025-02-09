"use client";

import { useEffect, useState } from "react";
import { useUser, useSignerStatus, useLogout } from "@account-kit/react";
import { useRouter } from "next/navigation";
import { ethers } from "ethers";
import { AccountDetails } from "./components/AccountDetails";
import { getKnownPluginInfo, type KnownPlugin } from "../../modular-account/src/plugins";
import { NavigationButtons } from "./components/NavigationButtons";
import dynamic from "next/dynamic";

// Import ModularAccount dynamically to avoid top-level await issues
const ModularAccount = dynamic(
    () => import("../../modular-account/src/ModularAccount").then(mod => ({
        default: () => {
            mod.initializeSmartAccountClient(); // This ensures the client is initialized
            return null;
        }
    })),
    { ssr: true }
);

const MSCA_ABI = [
    "function getInstalledPlugins() external view returns (address[])",
    "function getOwners() external view returns (address[])",
    "function getPluginInfo(address) external view returns (string, string, string, string)",
    "function "
];

const PLUGIN_ABI = [
    "function name() external view returns (string)",
    "function version() external view returns (string)"
];

interface Plugin {
    address: string;
    name: string;
    version?: string;
    description?: string;
}

async function getPluginInfo(pluginAddress: string, provider: ethers.Provider): Promise<Plugin> {

    // First check if it's a known plugin
    const KnownPlugin = getKnownPluginInfo(pluginAddress);

    if (KnownPlugin) {
        return {
            address: pluginAddress,
            ...KnownPlugin
        };
    }
    try {
        const contract = new ethers.Contract(pluginAddress, PLUGIN_ABI, provider);

        // Try to get both name and version
        const [name, version] = await Promise.all([
            contract.name().catch(() => {
                return "Unknown Plugin";
            }),
            contract.version().catch(() => {
                return undefined;
            }),
            contract.description().catch(() => {
                return undefined;
            })
        ]);

        return {
            address: pluginAddress,
            name,
            version,
            description: "No description available"
        };
    } catch (error) {
        console.error('Error fetching plugin metadata:', error);
        return {
            address: pluginAddress,
            name: "Unknown Plugin",
            description: "No description available"
        };
    }
}


export default function Dashboard() {
    const user = useUser();
    const { isInitializing, isConnected } = useSignerStatus();
    const { logout } = useLogout();
    const router = useRouter();


    const [modules, setModules] = useState<Plugin[]>([]);
    const [balance, setBalance] = useState<string>("0");
    const [factoryAddress] = useState<string>("0x000000e92d78d90000007f0082006fda09bd5f11");
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [mscaAddress, setMscaAddress] = useState<string>("");

    useEffect(() => {
        if (!user) {
            router.push("/");
            return;
        }

        const fetchAccountData = async () => {
            try {
                setIsLoading(true);
                setError(null);

                // Import the smartAccountClient from ModularAccount
                const { smartAccountClientPromise } = await import("../../modular-account/src/ModularAccount");
                const smartAccountClient = await smartAccountClientPromise;

                if (!smartAccountClient) {
                    throw new Error("Failed to initialize smart account client");
                }

                // Get the account address
                const accountAddress = await smartAccountClient.account.address;
                setMscaAddress(accountAddress);

                const provider = new ethers.JsonRpcProvider(
                    `https://eth-sepolia.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_API_KEY}`
                );

                // Get modules
                const contract = new ethers.Contract(
                    accountAddress,
                    MSCA_ABI,
                    provider
                );

                // Get balance using the smart account client
                const accountBalance = await smartAccountClient.getBalance({
                    address: accountAddress,
                });
                setBalance(ethers.formatEther(accountBalance));

                const pluginsList = await contract.getInstalledPlugins();
                const pluginsWithInfo = await Promise.all(
                    pluginsList.map((address: string) => getPluginInfo(address, provider))
                );
                setModules(pluginsWithInfo);

            } catch (error) {
                console.error("Error fetching account data:", error);
                setError(error instanceof Error ? error.message : "Failed to fetch account data");
            } finally {
                setIsLoading(false);
            }
        };

        setTimeout(() => {
            fetchAccountData();
        }, 100);

    }, [user, router, isConnected, mscaAddress]);


    return (
        <main className="flex min-h-screen flex-col items-center p-6">
            <ModularAccount />
            <div className="max-w-4xl w-full">
                <header className="mb-8 text-center">
                    <h1 className="text-2xl font-bold mb-4">Account Dashboard</h1>
                    {isInitializing || isLoading ? (
                        <div className="flex justify-center">Loading...</div>
                    ) : (
                        <>
                            <div className="space-y-4">
                                <AccountDetails
                                    userAddress={user?.address}
                                    configUserAddress={undefined}
                                    mscaAddress={mscaAddress}
                                    factoryAddress={factoryAddress}
                                    balance={balance}
                                    isLoadingAccount={false}
                                    error={error}
                                />
                            </div>
                            {!isInitializing && !isLoading && (
                                <section className="mb-8">
                                    <h2 className="text-xl font-semibold mb-4 text-center">Installed Modules</h2>
                                    {modules.length > 0 ? (
                                        <ul className="space-y-4">
                                            {modules.map((module, index) => (
                                                <li
                                                    key={index}
                                                    className="bg-black-50 p-4 rounded-lg shadow-sm"
                                                >
                                                    <div className="flex flex-col gap-1">
                                                        <span className="font-semibold text-lg">
                                                            {module.name}
                                                        </span>
                                                        {module.version && (
                                                            <span className="text-sm text-gray-600">
                                                                Version: {module.version}
                                                            </span>
                                                        )}
                                                        <p className="text-sm text-gray-700">
                                                            {module.description}
                                                        </p>
                                                        <span className="text-sm font-mono text-gray-500 break-all">
                                                            Address: {module.address}
                                                        </span>
                                                    </div>
                                                </li>
                                            ))}
                                        </ul>
                                    ) : (
                                        <p className="text-center">No modules installed.</p>
                                    )}
                                </section>
                            )}</>
                    )}
                </header>
                <NavigationButtons onLogout={logout} />
            </div>
        </main>
    );
}