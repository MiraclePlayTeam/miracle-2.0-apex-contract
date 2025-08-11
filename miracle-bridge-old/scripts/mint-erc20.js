const { ethers } = require("hardhat");
const { keccak256 } = require("web3-utils");

const { MPT, MPN, Proxy, Bridge } = require("../helpers/contractArtifacts");
const { deployContract, getContractAt } = require("../helpers/utils");
const { BYTES_ZERO } = require("../helpers/constants");
const ChainType = {
    Polygon: 0,
    Avalanche: 1,
};
const ErcType = {
    ERC20: 0,
    ERC1155: 1,
};

const CONTRACT_POLYGON_BRIDGE_PROXY = "0xd57a69f8c3ab0c4f15c0b331877134e61e20a147";
const CONTRACT_POLYGON_MPT = "0xcccc3b02c5fce5619f4cede90ec1f936c07aa456";
const CONTRACT_POLYGON_MPN = "0xa27c9915a1a1fea899f514d69fcf5b98b693d181";
const CONTRACT_POLYGON_MLGE = "0x8b0f9e76bdfe74f0741f8acc526097c49a1da303";

const CONTRACT_AVALANCHE_MPT = "0x5321c14a124d33da74a4701dcfbcb13e7c1fa707";
const CONTRACT_AVALANCHE_BRIDGE_PROXY = "0x215e1bf3dd7ef0a5d5a740e965a3e090ca3b91e4";
const minterRoleByBytes32 = keccak256("MINTER_ROLE");

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

    mptTokenProxy = await getContractAt("TokenERC20", CONTRACT_AVALANCHE_MPT);

    // get 1 ether value using hardhat's ethers utils
    const value = ethers.utils.parseEther("1000000");
    // const hash = await mptTokenProxy.mintTo(owner.address, value);

    const balance = await mptTokenProxy.balanceOf(owner.address);
    // console.log("🚀 ~ file: mint-erc20.js:39 ~ main ~ name:", balance);

    bridgeProxy = await getContractAt("Bridge", CONTRACT_AVALANCHE_BRIDGE_PROXY);

    const version = await bridgeProxy.name();
    console.log("🚀 ~ file: mint-erc20.js:50 ~ main ~ version:", version);

    // await mptTokenProxy.grantRole(minterRoleByBytes32, bridgeProxy.address);

    const res = await bridgeProxy.connect(owner).sendERC20ToUser({
        fromChain: ChainType.Polygon,
        token: mptTokenProxy.address,
        receiver: owner.address,
        amount: 1000000,
        feeAmount: 250,
        metadata: BYTES_ZERO,
    });
    console.log("🚀res:", res);

    // mptTokenProxy.approve(bridgeProxy.address, value);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
