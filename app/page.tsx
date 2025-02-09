"use client";
import { initializeSmartAccountClient } from "@/modular-account/src/ModularAccount";
import {
  useAuthModal,
  useLogout,
  useSignerStatus,
  useUser,
} from "@account-kit/react";
import { ethers } from "ethers";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

const MESSAGING_PLUGIN_ADDRESS = "0x79050486765BE9573fDb341b0686576d32d73A9b";
const ALCHEMY_API_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;

export default function Home() {
  const user = useUser();
  const { openAuthModal } = useAuthModal();
  const signerStatus = useSignerStatus();
  const { logout } = useLogout();
  const router = useRouter();

  // Add state to check if messaging plugin is installed
  const [hasMessagingPlugin, setHasMessagingPlugin] = useState(true);

  // Check if messaging plugin is installed
  useEffect(() => {
    async function checkPlugin() {
      if (user) {
        const smartAccountClient = await initializeSmartAccountClient();
        const address = await smartAccountClient.account.address;
        const provider = new ethers.JsonRpcProvider(
          `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`
        );

        const CONTRACT_ABI = [
          "function getInstalledPlugins() external view returns (address[])"
        ];
        // Use contract call to check installed plugins
        const contract = new ethers.Contract(address, CONTRACT_ABI, provider);
        try {
          const plugins = await contract.getInstalledPlugins();
          setHasMessagingPlugin(plugins.includes(MESSAGING_PLUGIN_ADDRESS));
        } catch (error) {
          console.error("Error checking plugins:", error);
          setHasMessagingPlugin(false);
        }
      }
    }
    checkPlugin();
  }, [user]);

  return (
    <main className="flex min-h-screen flex-col items-center p-24 gap-4 justify-center text-center">
      {signerStatus.isInitializing ? (
        <>Loading...</>
      ) : user ? (
        <div className="flex flex-col gap-2 p-2">
          <p className="text-xl font-bold">Success!</p>
          Logged with {user.email ?? "MetaMask"}.


          <div className="mt-4 flex flex-col gap-2">
            <button
              className="btn btn-primary"
              onClick={() => router.push("/dashboard")}
            >
              Go to Dashboard
            </button>
            <button
              className="btn btn-secondary"
              onClick={() => router.push("/transactions")}
            >
              User Operations
            </button>
            <button
              className="btn btn-secondary"
              onClick={() => router.push("/messages")}
              disabled={!hasMessagingPlugin}
            >
              Messages {!hasMessagingPlugin && "(Install Plugin First)"}
            </button>
            <button className="btn btn-primary mt-6" onClick={() => logout()}>
              Log out
            </button>
          </div>
        </div>
      ) : (
        <button className="btn btn-primary" onClick={openAuthModal}>
          Login
        </button>
      )}
    </main>
  );
}
