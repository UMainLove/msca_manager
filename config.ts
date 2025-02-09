import {
  AlchemyAccountsUIConfig,
  cookieStorage,
  createConfig,
} from "@account-kit/react";
import { SupportedAccountTypes } from "@account-kit/core";
import { SmartAccountClientOptsSchema } from "@aa-sdk/core";
import { alchemy, sepolia } from "@account-kit/infra";
import { QueryClient } from "@tanstack/react-query";
import { z } from "zod";

const ALCHEMY_API_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY || "";
const WALLETCONNECT_PROJECT_ID = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "";
const GAS_ID = process.env.NEXT_PUBLIC_PAYMASTER_POLICY_ID || "";

const uiConfig: AlchemyAccountsUIConfig = {
  illustrationStyle: "outline",
  auth: {
    sections: [
      [
        {
          type: "external_wallets",
          walletConnect: { projectId: WALLETCONNECT_PROJECT_ID },
        },
      ],
    ],
    addPasskeyOnSignup: false,
  },
  
};

export const config = createConfig(
  {
    transport: alchemy({ apiKey: ALCHEMY_API_KEY }),
    chain: sepolia,
    ssr: true, // more about ssr: https://accountkit.alchemy.com/react/ssr
    storage: cookieStorage, // more about persisting state with cookies: https://accountkit.alchemy.com/react/ssr#persisting-the-account-state
    enablePopupOauth: true, // must be set to "true" if you plan on using popup rather than redirect in the social login flow
    policyId: GAS_ID,
  },
  uiConfig
);

export const accountType: SupportedAccountTypes = "MultiOwnerModularAccount";


export const queryClient = new QueryClient();

// Account client options
type SmartAccountClientOptions = z.infer<typeof SmartAccountClientOptsSchema>;
export const accountClientOptions: Partial<SmartAccountClientOptions> = {
  txMaxRetries: 20,
} as const;
