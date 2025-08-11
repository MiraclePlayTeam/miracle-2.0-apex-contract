const { ethers } = require("hardhat");
const { keccak256 } = require("web3-utils");

const { MPT, MPN, Proxy, Bridge } = require("../helpers/contractArtifacts");
const { deployContract, getContractAt } = require("../helpers/utils");
const { BYTES_ZERO } = require("../helpers/constants");

const CONTRACT_POLYGON_BRIDGE_PROXY = "0xaE5Ff29139E0a0Dcd0dCF4738d44694327c6325f";
const CONTRACT_POLYGON_MPT = "0xa4f63404b58C3efD9Db6D53352BD386fFa174e5A";
const CONTRACT_POLYGON_MPN = "0x43ada72443E81ec1be693822a487cE9063ED9D62";
const CONTRACT_POLYGON_MLGE = "0x8854D28105c2095CAb1d3d73da7de94c65B3FD3C";
const CONTRACT_BASE_MPV = "0xcEB0f9304F165d4DfedCE829e3A983759F4AeA98";
const CONTRACT_BASE_BPT = "0xDB8583078BFDac7d6B9CA922B79ad2cCE3D50bFb";

const OWNER_ADDRESS = "0x82FCb7bdAa578Da16d10074e07784bA318Be702c";

const minterRoleByBytes32 = keccak256("MINTER_ROLE");
const minterAndBurnerRoleByBytes32 = keccak256("MINTER_AND_BURNER_ROLE");

let mptTokenProxy;
let mpnTokenProxy;
let mlgeTokenProxy;
let mpvTokenProxy;
let bptTokenProxy;
let bridgeProxy;
const platformFeeBps = 100;

// 1. MPN, MPT, MLGE Token에 대해서 민터, 버너 권한을 브릿지 프록시가 보유하고 있는지 확인한다.

// 2. 브릿지 컨트랙트의 민터 권한을 어드민 계정이 보유하고 있는지 확인한다.
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    mptTokenProxy = await getContractAt("TokenERC20", CONTRACT_POLYGON_MPT);
    mpnTokenProxy = await getContractAt("DropERC1155", CONTRACT_POLYGON_MPN);
    mlgeTokenProxy = await getContractAt("TokenERC20", CONTRACT_POLYGON_MLGE);
    mpvTokenProxy = await getContractAt("TokenERC20", CONTRACT_BASE_MPV);
    bptTokenProxy = await getContractAt("TokenERC20", CONTRACT_BASE_BPT);

    bridgeProxy = await getContractAt("Bridge", CONTRACT_POLYGON_BRIDGE_PROXY);

    const hasRoleAboutMpt = await mptTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    const hasRoleAboutMpn = await mpnTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    const hasRoleAboutMlge = await mlgeTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    const hasRoleAboutmpv = await mpvTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    const hasRoleAboutbpt = await bptTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    const hasRoleAboutBridge = await bridgeProxy.hasRole(minterAndBurnerRoleByBytes32, OWNER_ADDRESS);
    console.log("🚀 hasRoleAboutBridge:", hasRoleAboutBridge);
    console.log("🚀 hasRoleAboutMlge:", hasRoleAboutMlge);
    console.log("🚀 hasRoleAboutMpn:", hasRoleAboutMpn);
    console.log("🚀 hasRoleAboutMpt:", hasRoleAboutMpt);
    console.log("🚀 hasRoleAboutmpv:", hasRoleAboutmpv);
    console.log("🚀 hasRoleAboutbpt:", hasRoleAboutbpt);

    // if (!hasRoleAboutBridge) {
    //     console.log("🚀 bridgeProxy has not role about minter and burner");
    //     const hash = await bridgeProxy.grantRole(minterAndBurnerRoleByBytes32, OWNER_ADDRESS);
    //     console.log("🚀 ~ file: check-status-polygon.js:70 ~ main ~ hash:", hash);
    // }

    // if (!hasRoleAboutMlge) {
    //     console.log("🚀 mlgeTokenProxy has not role about minter");
    //     await mlgeTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    // }

    // if (!hasRoleAboutMpt) {
    //     console.log("🚀 mptTokenProxy has not role about minter");
    //     await mptTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    // }

    // if (!hasRoleAboutMpn) {
    //     console.log("🚀 mpnTokenProxy has not role about minter");
    //     await mpnTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE_PROXY);
    // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
