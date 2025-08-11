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

const bridgeAddress = "0xa28A5B88048aCE5c5699a38B5d2b6B82eb729D04";
let bridge;
const bridgeProxyAddress = "0x215E1Bf3dd7ef0A5d5A740E965A3e090ca3B91E4";
let bridgeProxy;
const platformFeeBps = 100;
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    // Deploy real contracts
    if (bridgeAddress) {
        console.log("get Real contracts");
        bridge = await getContractAt("Bridge", bridgeAddress);
    } else {
        console.log("Real contracts deployed start!");
        bridge = await deployContract(Bridge);
        console.log("Real contracts deployed end!");
    }

    console.log(
        `Bridge address: ${bridge.address}`
    );

    bridgeProxy = await getContractAt("Proxy", bridgeProxyAddress);

    console.log(
        `Bridge Proxy address: ${bridgeProxy.address}`
    );

    // Upgrade proxy contracts
    console.log("Proxy contracts upgrade start!");
    await bridgeProxy.upgrade(bridge.address);
    console.log("Proxy contracts upgrade end!");

    console.log("Bridge Proxy address: ", bridgeProxy?.address.toLowerCase());
    console.log("Real Bridge address: ", bridge?.address.toLowerCase());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
