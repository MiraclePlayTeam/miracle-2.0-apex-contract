const { ethers } = require("hardhat");

const { MPT, MPN, Proxy, Bridge } = require("../helpers/contractArtifacts");
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

const bridgeAddress = "0x625d3fd726cC86f1463b50376Dec62359d61a1F0";
let bridge;
const bridgeProxyAddress = "0xD57A69F8c3Ab0c4f15C0b331877134E61E20a147";
let bridgeProxy;
const platformFeeBps = 100;
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    // Deploy real contracts
    console.log("Real contracts deployed start!");
    if (bridgeAddress) {
        bridge = await getContractAt("Bridge", bridgeAddress);
    } else {
        bridge = await deployContract(Bridge);
    }
    console.log("Real contracts deployed end!");

    console.log(
        `Bridge address: ${bridge.address}`
    );

    bridgeProxy = await getContractAt("Proxy", bridgeProxyAddress);

    console.log(
        `Bridge Proxy address: ${bridgeProxy.address} `
    );

    // Upgrade proxy contracts
    console.log("Proxy contracts upgrade start!");
    await bridgeProxy.upgrade(bridge.address);
    console.log("Proxy contracts upgrade end!");

    // Initialize proxy contracts
    console.log("Bridge Proxy address: ", bridgeProxy?.address.toLowerCase());
    console.log("Real Bridge address: ", bridge?.address.toLowerCase());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
