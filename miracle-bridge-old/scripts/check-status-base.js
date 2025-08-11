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

const CONTRACT_BASE_BRIDGE_PROXY = "0xaE5Ff29139E0a0Dcd0dCF4738d44694327c6325f";
const CONTRACT_BASE_MPT = "0xF2d3d488626a117984fda70F8106abC0049018D3";
const CONTRACT_BASE_MPN = "0x9fcA3B2e70718cdaE99EAB0f508EC129af83d059";
const CONTRACT_BASE_MLGE = "0xFd240BaD711B909B164439F5F9c8A85dBc467f24";
const CONTRACT_BASE_MPV = "0xa142379081963D5c6eF4feFeAfB5580a397bF25A";
const CONTRACT_BASE_BPT = "0xfaa10caefb1dd0fef76c857697f980932f96bbc9";

const CONTRACT_POLYGON_BRIDGE_PROXY = "0xd57a69f8c3ab0c4f15c0b331877134e61e20a147";
const CONTRACT_POLYGON_MPT = "0x87d6F8eDECcbCcA766D2880D19b2C3777D322C22";
const CONTRACT_POLYGON_MPN = "0x3Df3eaeEfc30d77891aaBDCE18Bd15cc59B0D466";
const CONTRACT_POLYGON_MLGE = "0x79940436c6a70bad4eCb6A41F4EBFd4735B767aF";

const CONTRACT_AVALANCHE_BRIDGE_PROXY = "0x215e1bf3dd7ef0a5d5a740e965a3e090ca3b91e4";
const CONTRACT_AVALANCHE_MPT = "0x5321c14a124d33da74a4701dcfbcb13e7c1fa707";
const CONTRACT_AVALANCHE_MPN = "0x3a70d013255b411337344d3acb1d63e05df565cf";
const CONTRACT_AVALANCHE_MLGE = "0x8df8d90c0e0f6bacc18bab3fde026374051e8635";

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

    mptTokenProxy = await getContractAt("TokenERC20", CONTRACT_BASE_MPT);
    mpnTokenProxy = await getContractAt("DropERC1155", CONTRACT_BASE_MPN);
    mlgeTokenProxy = await getContractAt("TokenERC20", CONTRACT_BASE_MLGE);
    mpvTokenProxy = await getContractAt("TokenERC20", CONTRACT_BASE_MPV);
    bptTokenProxy = await getContractAt("TokenERC20", CONTRACT_BASE_BPT);

    bridgeProxy = await getContractAt("Bridge", CONTRACT_BASE_BRIDGE_PROXY);

    const hasRoleAboutMpt = await mptTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
    const hasRoleAboutMpn = await mpnTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
    const hasRoleAboutMlge = await mlgeTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
    const hasRoleAboutMpv = await mpvTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
    const hasRoleAboutBpt = await bptTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_BASE_BRIDGE_PROXY);
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
