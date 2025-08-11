const { ethers } = require("hardhat");

const { Proxy, Bridge } = require("../helpers/contractArtifacts");
const { deployContract, getContractAt } = require("../helpers/utils");

const ChainType = {
    Polygon: 0,
    Avalanche: 1,
    Base: 2,
};
const ErcType = {
    ERC20: 0,
    ERC1155: 1,
};

let bridge;
let bridgeProxy;
let minter = "0x82FCb7bdAa578Da16d10074e07784bA318Be702c";
const platformFeeBps = 100;
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    // Deploy real contracts
    console.log("Real contracts deployed start!", owner.address);
    bridge = await deployContract(Bridge); // 0x8d14E9a4690e71CAD1fe3c74E68b58cD4c352398
    console.log("Real contracts deployed end!");

    console.log(
        `Bridge address: ${bridge.address}`
    );

    // Deploy proxy contracts
    console.log("Proxy contracts deployed start!");
    const bridgeProxyContract = await deployContract(Proxy, owner.address); // 0xaE5Ff29139E0a0Dcd0dCF4738d44694327c6325f
    console.log("Proxy contracts deployed end!");

    console.log(
        `Bridge Proxy address: ${bridgeProxyContract.address} `
    );

    // Upgrade proxy contracts
    console.log("Proxy contracts upgrade start!");
    await bridgeProxyContract.upgrade(bridge.address);
    console.log("Proxy contracts upgrade end!");

    // Initialize proxy contracts
    bridgeProxy = await getContractAt("Bridge", bridgeProxyContract.address);
    console.log("Proxy contracts initialize start!");
    await bridgeProxy.initialize("Bridge", owner.address, ChainType.Base, owner.address, minter);
    console.log("Proxy contracts initialize end!");

    console.log("Bridge Proxy address: ", bridgeProxy?.address.toLowerCase());
    console.log("Real Bridge address: ", bridge?.address.toLowerCase());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
