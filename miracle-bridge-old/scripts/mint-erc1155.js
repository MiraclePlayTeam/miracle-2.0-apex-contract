const { ethers } = require("hardhat");
const { keccak256 } = require("web3-utils");

const { MPT, MPN, Proxy, Bridge } = require("../helpers/contractArtifacts");
const { deployContract, getContractAt } = require("../helpers/utils");
const ChainType = {
    Polygon: 0,
    Avalanche: 1,
};
const ErcType = {
    ERC20: 0,
    ERC1155: 1,
};
const { BYTES_ZERO } = require("../helpers/constants");
const CONTRACT_POLYGON_MPN = "0xa27c9915a1a1fea899f514d69fcf5b98b693d181";
const CONTRACT_AVALANCHE_MPN = "0x3a70d013255b411337344d3acb1d63e05df565cf";
const CONTRACT_AVALANCHE_BRIDGE = "0xa917761Bb88a04f828D60bB9Cc00A44dbBfF4D62";
const CONTRACT_POLYGON_BRIDGE = "0xd57a69f8c3ab0c4f15c0b331877134e61e20a147";
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

    mpnTokenProxy = await getContractAt("DropERC1155", CONTRACT_POLYGON_MPN);

    const block = await ethers.provider.getBlock("latest");

    const conditions = [
        {
            startTimestamp: block.timestamp,
            maxClaimableSupply: 1000,
            supplyClaimed: 100,
            quantityLimitPerWallet: 10,
            merkleRoot: BYTES_ZERO,
            pricePerToken: 0,
            currency: CONTRACT_POLYGON_MPN,
            metadata: "0x",
        },
    ];
    const resetClaimEligibility = true;
    await mpnTokenProxy.setClaimConditions(1, conditions, resetClaimEligibility);
    // const tx = await mpnTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_POLYGON_BRIDGE);
    // const tx = await mpnTokenProxy
    //     .connect(owner)
    //     .claim(
    //         owner.address,
    //         1,
    //         1,
    //         CONTRACT_AVALANCHE_MPN,
    //         0,
    //         { proof: [], quantityLimitPerWallet: 1, pricePerToken: 0, currency: CONTRACT_AVALANCHE_MPN },
    //         "0x"
    //     );
    // console.log("🚀 ~ file: mint-erc1155.js:63 ~ main ~ tx:", tx);

    // const userBalanceAfterMint = await mpnTokenProxy.balanceOf(owner.address, 1);
    // console.log("🚀 ~ file: mint-erc1155.js:67 ~ main ~ userBalanceAfterMint:", userBalanceAfterMint);

    // const balance = await mpnTokenProxy.balanceOf(owner.address);
    // console.log("🚀 ~ file: mint-erc20.js:39 ~ main ~ name:", balance);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
