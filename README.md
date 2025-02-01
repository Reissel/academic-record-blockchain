# Academic Record Blockchain

## Overview
This project aims to create a smart contract as blockchain solution to store and retrieve student's information from allowed accounts.

Using this project it's possible to retain student's academic record even when the institution does not operate anymore.

## Prerequisites
- NodeJS v20.18.2

## How to run locally
1. Download [Ganache](https://archive.trufflesuite.com/ganache/).
2. Open Ganache to create a local blockchain.
3. Run `npx hardhat compile` to compile the solidity code.
4. Run `npx hardhat run scripts/deploy.js --network ganache` on a terminal at the root folder of the project to deploy the contract to the blockchain using the first account of the Ganache blockchain.
5. Use the project [academic-registry-web](https://github.com/bifipe/academic-registry-web) to interact with the contract using a frontend application or another tool to interact with the blockchain.