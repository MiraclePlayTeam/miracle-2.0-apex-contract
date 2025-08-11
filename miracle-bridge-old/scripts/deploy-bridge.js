const { ethers } = require("hardhat");

const { Bridge } = require("../helpers/contractArtifacts");
const { deployContract, getContractAt } = require("../helpers/utils");

// hh run scripts/deploy-bridge.js --network base
let bridge;
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    bridge = await deployContract(Bridge);
    console.log("Real contracts deployed end!");
    console.log(`Bridge address: ${bridge.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

