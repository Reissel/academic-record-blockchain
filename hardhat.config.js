require("@nomicfoundation/hardhat-toolbox");

require("hardhat-contract-sizer");

//npx hardhat run scripts/deploy.js --network ganache

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1
      }
  },
  paths: {
    artifacts: "./src/artifacts",
  },
  networks: {
    hardhat: {
      chainId: 1337,
      },
    ganache: {
      url: "http://127.0.0.1:7545",
      }
    },
  }
}
