const hre = require("hardhat");

async function main() {

  const AcademicRegistry = await hre.ethers.getContractFactory("AcademicRegistry");
  const academicRegistry = await AcademicRegistry.deploy();

  await academicRegistry.waitForDeployment();
  
  console.log(
    `Deployed to ${academicRegistry.target}`
  );
}


// npx hardhat run scripts/deploy.js --network ganache
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});