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

let mptToken;
let mpnToken;
let mlgeToken;
let mptTokenProxy;
let mpnTokenProxy;
let mlgeTokenProxy;
let bridge;
let bridgeProxy;
const platformFeeBps = 100;
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    // Deploy real contracts
    console.log("Real contracts deployed start!");
    mptToken = await deployContract(MPT);
    mlgeToken = await deployContract(MPT);
    mpnToken = await deployContract(MPN);
    bridge = await deployContract(Bridge);
    console.log("Real contracts deployed end!");

    console.log(
        `MPT Token address: ${mptToken.address} / MLGE Token address: ${mlgeToken.address} / MPN Token address: ${mpnToken.address} / Bridge address: ${bridge.address}`
    );

    // Deploy proxy contracts
    console.log("Proxy contracts deployed start!");
    const mptTokenProxyContract = await deployContract(Proxy, owner.address);
    const mlgeTokenProxyContract = await deployContract(Proxy, owner.address);
    const mpnTokenProxyContract = await deployContract(Proxy, owner.address);
    const bridgeProxyContract = await deployContract(Proxy, owner.address);
    console.log("Proxy contracts deployed end!");

    console.log(
        `MPT Token Proxy address: ${mptTokenProxyContract.address} / MLGE Token Proxy address: ${mlgeTokenProxyContract.address} / MPN Token Proxy address: ${mpnTokenProxyContract.address} / Bridge Proxy address: ${bridgeProxyContract.address} `
    );

    // Upgrade proxy contracts
    console.log("Proxy contracts upgrade start!");
    await mptTokenProxyContract.upgrade(mptToken.address);
    await mlgeTokenProxyContract.upgrade(mlgeToken.address);
    await mpnTokenProxyContract.upgrade(mpnToken.address);
    await bridgeProxyContract.upgrade(bridge.address);
    console.log("Proxy contracts upgrade end!");

    // Initialize proxy contracts
    mptTokenProxy = await getContractAt("TokenERC20", mptTokenProxyContract.address);
    mlgeTokenProxy = await getContractAt("TokenERC20", mlgeTokenProxyContract.address);
    mpnTokenProxy = await getContractAt("DropERC1155", mpnTokenProxyContract.address);
    bridgeProxy = await getContractAt("Bridge", bridgeProxyContract.address);
    console.log("Proxy contracts initialize start!");
    await bridgeProxy.initialize("Bridge", owner.address, ChainType.Polygon, owner.address, owner.address);
    await mptTokenProxy.initialize(
        bridgeProxy.address,
        "Test MPT Token",
        "TESTMPT",
        "https://test.com",
        [],
        owner.address,
        owner.address,
        platformFeeBps
    );
    await mlgeTokenProxy.initialize(
        bridgeProxy.address,
        "Test MLGE Token",
        "TESTMLGE",
        "https://test.com",
        [],
        owner.address,
        owner.address,
        platformFeeBps
    );

    await mpnTokenProxy.initialize(
        bridgeProxy.address,
        "TEST MPN NFT",
        "TESTMPN",
        "https://test.com",
        [],
        owner.address,
        owner.address,
        platformFeeBps,
        platformFeeBps,
        owner.address
    );
    console.log("Proxy contracts initialize end!");

    console.log("MPT Token Proxy address: ", mptTokenProxy?.address.toLowerCase());
    console.log("MLGE Token Proxy address: ", mlgeTokenProxy.address.toLowerCase());
    console.log("MPN Token Proxy address: ", mpnTokenProxy.address.toLowerCase());
    console.log("Bridge Proxy address: ", bridgeProxy?.address.toLowerCase());

    console.log("Real MPT Token address: ", mptToken?.address.toLowerCase());
    console.log("Real MLGE Token address: ", mlgeToken?.address.toLowerCase());
    console.log("Real MPN Token address: ", mpnToken?.address.toLowerCase());
    console.log("Real Bridge address: ", bridge?.address.toLowerCase());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
