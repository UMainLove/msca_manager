# MSCA Manager (Alpha Version)

See [accountkit.alchemy.com](https://accountkit.alchemy.com/) for the most up to date documentation!

- [quick start guide](https://accountkit.alchemy.com/react/quickstart) to Account Kit
- [demo](https://demo.alchemy.com/)


This is a [Next.js](https://nextjs.org/) template bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).

To learn more about Next.js, take a look at the following resources:
- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

##

### Getting Started
First, download the template:

```bash
npx create-next-app@latest account-kit-app -e https://github.com/UMainLove/msca_manager.git
```


#### Get your Alchemy api key, Gas Sponsorship key (Paymaster Policy ID), ReOwn Project ID (Ex WalletConnect) and Metamask private key

- Create a new embedded accounts configuration for an alchemy app in your [dashboard](https://dashboard.alchemy.com/accounts)
- Create a new Gas Plicy configuration for an alchemy app in your [dashboard](https://dashboard.alchemy.com/gas-manager)
- Create a new ReOwn Project configuration to use you Blockchain APIs in your [dashboard](https://cloud.reown.com/app/)

##
See [https://docs.reown.com/appkit/next/core/installation] for more informations related to AppKit.
##

- Replace the Alchemy api key in the ```~/config.ts``` file
- Replace the Gas Sponsorship key (Paymaster Policy ID) in the ```~/config.ts``` file
- Replace the ReOwn Project ID (Ex WalletConnect) in the ```~/config.ts``` file

- Replace the Metamask private key in the ```~/modular-account/src/ModularAccount.ts``` file
- Replace the Alchemy api key in the ```~/modular-account/src/ModularAccount.ts``` file
- Replace the Gas Sponsorship key (Paymaster Policy ID) in the ```~/modular-account/src/ModularAccount.ts``` file


#### Run the app
```bash
npm run dev
``` 
Follow this [quick start guide](https://accountkit.alchemy.com/) for more details!
#### DISCLAMER:
This is a basic dApp tested only on Ethereum Sepolia testnet and NOT READY FOR PRODUCTION USE. Please be aware that you SHOULD NOT send any real money from your mainnet wallet.


#### Deploy the Smart Account Client
```bash
npm run create:client
``` 
You'll se on your Next app UI that the "Account Status" indicator has changed to "Connected" ✅

Try sending some SepoliaEth directly from your Metamask wallet to your "Smart Account Address #1" 


#### Install the MessagingPlugin to your Smart Account Client
```bash
npm run install-plugin
``` 
You'll see on your Next app UI that in the "Installed Modules" section appears the "MessagingPlugin" module. [Messages](http://localhost:3000/messages) button is now available.

Try to send a message to my Smart Account address "0x87624F0e8d1837232D6c26f184d581DcB6791349" 
#### NOTE:
Chat History is not loading yet. You can try to send a message and check the [Events](https://sepolia.etherscan.io/address/0x79050486765be9573fdb341b0686576d32d73a9b#events) tab on SepoliaEth Etherscan to see the message being sent.

## Let's connect to collaborate with me and/or get more informations about this project

Your feedback and contributions are welcome! 🤝

Feel free to reach me on [LinkedIn](https://www.linkedin.com/in/michele-galante-91b663294)!