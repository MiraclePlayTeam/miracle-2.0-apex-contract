const { ethers } = require("hardhat");
const { keccak256 } = require("web3-utils");

const { MPT, MPN, Proxy, Bridge } = require("../helpers/contractArtifacts");
const { deployContract, getContractAt } = require("../helpers/utils");
const { BYTES_ZERO } = require("../helpers/constants");

const ChainType = {
    Polygon: 0,
    Avalanche: 1,
    Base: 2,
};

const ErcType = {
    ERC20: 0,
    ERC1155: 1,
};

const CONTRACT_OPBNB_BRIDGE_PROXY = "0x8d14E9a4690e71CAD1fe3c74E68b58cD4c352398";
const CONTRACT_OPBNB_MPT = "0xf0E2f2a84C898989C66FCa1d5BCe869E9BC85ddf";
const CONTRACT_OPBNB_MPN = "0xfc35B3255ea1523daF4B6834Ef20B4ebC4346012";
const CONTRACT_OPBNB_MLGE = "0x0597b72dD532A78A11C16606CD7525D1277bBC7f";
const CONTRACT_OPBNB_MPV = "0x2a2eA57FABAe758Bde10C9294d674B8830b2F21b";
const CONTRACT_OPBNB_BPT = "0xFCc3839BB0D1A1cbe90eA967526E91B71376E3Ab";

const OWNER_ADDRESS = "0x82FCb7bdAa578Da16d10074e07784bA318Be702c";

const minterRoleByBytes32 = keccak256("MINTER_ROLE");
const minterAndBurnerRoleByBytes32 = keccak256("MINTER_AND_BURNER_ROLE");

let mptToken;
let mpnToken;
let mlgeToken;
let mptTokenProxy;
let mpnTokenProxy;
let mlgeTokenProxy;
let mpvTokenProxy;
let bptTokenProxy;
let bridge;
let bridgeProxy;
const platformFeeBps = 100;

// 1. MPN, MPT, MLGE Token에 대해서 민터, 버너 권한을 브릿지 프록시가 보유하고 있는지 확인한다.

// 2. 브릿지 컨트랙트의 민터 권한을 어드민 계정이 보유하고 있는지 확인한다.
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    mptTokenProxy = await getContractAt("TokenERC20", CONTRACT_OPBNB_MPT);
    mpnTokenProxy = await getContractAt("DropERC1155", CONTRACT_OPBNB_MPN);
    mlgeTokenProxy = await getContractAt("TokenERC20", CONTRACT_OPBNB_MLGE);
    mpvTokenProxy = await getContractAt("TokenERC20", CONTRACT_OPBNB_MPV);
    bptTokenProxy = await getContractAt("TokenERC20", CONTRACT_OPBNB_BPT);

    bridgeProxy = await getContractAt("Bridge", CONTRACT_OPBNB_BRIDGE_PROXY);

    const hasRoleAboutMpt = await mptTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_OPBNB_BRIDGE_PROXY);
    const hasRoleAboutMpn = await mpnTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_OPBNB_BRIDGE_PROXY);
    const hasRoleAboutMlge = await mlgeTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_OPBNB_BRIDGE_PROXY);
    const hasRoleAboutMpv = await mpvTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_OPBNB_BRIDGE_PROXY);
    const hasRoleAboutBpt = await bptTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_OPBNB_BRIDGE_PROXY);
    const hasRoleAboutBridge = await bridgeProxy.hasRole(minterAndBurnerRoleByBytes32, OWNER_ADDRESS);
    console.log("🚀 hasRoleAboutBridge:", hasRoleAboutBridge);
    console.log("🚀 hasRoleAboutMlge:", hasRoleAboutMlge);
    console.log("🚀 hasRoleAboutMpn:", hasRoleAboutMpn);
    console.log("🚀 hasRoleAboutMpt:", hasRoleAboutMpt);
    console.log("🚀 hasRoleAboutMpv:", hasRoleAboutMpv);
    console.log("🚀 hasRoleAboutBpt:", hasRoleAboutBpt);


    // if (!hasRoleAboutBridge) {
    //     console.log("🚀 bridgeProxy has not role about minter and burner");
    //     const hash = await bridgeProxy.grantRole(minterAndBurnerRoleByBytes32, OWNER_ADDRESS);
    //     console.log("🚀 ~ file: check-status-polygon.js:70 ~ main ~ hash:", hash);
    // }

    // if (!hasRoleAboutMlge) {
    //     console.log("🚀 mlgeTokenProxy has not role about minter");
    //     await mlgeTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
    // }

    // if (!hasRoleAboutMpt) {
    //     console.log("🚀 mptTokenProxy has not role about minter");
    //     await mptTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
    // }

    // if (!hasRoleAboutMpn) {
    //     console.log("🚀 mpnTokenProxy has not role about minter");
    //     await mpnTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
    // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
