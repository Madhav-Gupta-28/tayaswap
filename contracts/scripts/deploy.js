const hre = require("hardhat");



const { CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS } = require("../constants");

async function main() {
  const cryptoDevTokenAddress = CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS;
 
  const exchangeContract = await ethers.deployContract("TayaSwap",[cryptoDevTokenAddress]);

  await exchangeContract.waitForDeployment();

  // print the address of the deployed contract
  console.log("Exchange Contract Address:", exchangeContract.target);
}

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });