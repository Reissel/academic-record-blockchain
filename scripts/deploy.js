const hre = require("hardhat");

async function main() {

  const Hello = await hre.ethers.getContractFactory("Hello");
  const hello = await Hello.deploy();

  await hello.waitForDeployment();
  
  console.log(
    `Deployed to ${hello.target}!`
  );
}


// npx hardhat run scripts/deploy.js --network ganache
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});