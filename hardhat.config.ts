import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";
import "hardhat-deploy";
import "@typechain/hardhat";

require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
//   const accounts = await hre.ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// task("newwallet", "Generate New Wallet", async (taskArgs, hre) => {
//   const wallet = hre.ethers.Wallet.createRandom();
//   console.log("PK: ", wallet._signingKey().privateKey);
//   console.log("Address: ", wallet.address);
// });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      saveDeployments: true,
      accounts: ["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"],
    },
    hardhat: {
      chainId: 1337,
      // forking: {
      //   url: "https://rpc.vvs.finance",
      //   blockNumber: 1876666
      // },
      saveDeployments: true,
      // mining: {
      //   auto: true,
      // },
    },
    cronos_testnet: {
      url: `https://cronos-testnet-3.crypto.org:8545/`,
      chainId: 338,
      accounts: [process.env.PRIVATE_KEY],
      gas: 21000000,
      gasPrice: 5000000000000,
    },
    cronos_mainnet: {
      url: `https://rpc.vvs.finance`,
      chainId: 25,
      accounts: [process.env.PRIVATE_KEY],
      gas: 2100000,
      gasPrice: 5000000000000,
    },
    // mainnet: {
    //   url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
    //   chainId: 1,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    // rinkeby: {
    //   url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
    //   chainId: 4,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    // matic: {
    //   url: "https://polygon-rpc.com/",
    //   chainId: 137,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    // mumbai: {
    //   url: "https://rpc-mumbai.matic.today",
    //   chainId: 80001,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.11",
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
     
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
    treasury: {
      default: 1, // here this will by default take the first account as deployer
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
    deploy: "./deploy",
  },
  mocha: {
    timeout: 2000000000,
  },
  typechain:{
    outDir:"typechain",
    target:"ethers-v5",
  }
};
