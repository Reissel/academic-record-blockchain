require("@nomicfoundation/hardhat-toolbox");

//npx hardhat run scripts/deploy.js --network ganache

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
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
  }
};
