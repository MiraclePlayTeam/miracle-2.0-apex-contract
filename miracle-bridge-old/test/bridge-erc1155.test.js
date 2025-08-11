const { expect } = require("../helpers/setup");
const { ethers } = require("hardhat");
const { deployContract, getContractAt } = require("../helpers/utils");
const contractArtifacts = require("../helpers/contractArtifacts");
const { keccak256 } = require("web3-utils");
const { BYTES_ZERO } = require("../helpers/constants");
const ChainType = {
    Polygon: 0,
    Avalanche: 1,
};
const ErcType = {
    ERC20: 0,
    ERC1155: 1,
};
describe("MPN 1155 Basic Mint & Burn Test", () => {
    let mpnTokenProxy;
    let bridgeProxy;
    let mpnToken;
    const minterRoleByBytes32 = keccak256("MINTER_ROLE");

    before(async () => {
        const signers = await ethers.getSigners();
        [deployer, newMinter, admin, primarySaleRecipient, platformFeeRecipient, user, ..._] = signers;
        const platformFeeBps = 100;
        const royaltyBps = 100;
        mpnToken = await deployContract(contractArtifacts.MPN);
        const bridge = await deployContract(contractArtifacts.Bridge);
        const proxy = await deployContract(contractArtifacts.Proxy, deployer.address);
        const bridgeProxyContract = await deployContract(contractArtifacts.Proxy, deployer.address);

        await proxy.upgrade(mpnToken.address);
        await bridgeProxyContract.upgrade(bridge.address);

        mpnTokenProxy = await getContractAt("DropERC1155", proxy.address);
        bridgeProxy = await getContractAt("Bridge", bridgeProxyContract.address);

        await bridgeProxy.initialize(
            "Bridge",
            admin.address,
            ChainType.Avalanche,
            primarySaleRecipient.address,
            newMinter.address
        );

        await mpnTokenProxy.initialize(
            admin.address,
            "Miracleplay NFT",
            "MPN",
            "https://google.com",
            [],
            primarySaleRecipient.address,
            primarySaleRecipient.address,
            royaltyBps,
            platformFeeBps,
            platformFeeRecipient.address
        );
        // get block timestamp for minting
        const block = await ethers.provider.getBlock("latest");
        const conditions = [
            {
                startTimestamp: block.timestamp,
                maxClaimableSupply: 1000,
                supplyClaimed: 100,
                quantityLimitPerWallet: 10,
                merkleRoot: BYTES_ZERO,
                pricePerToken: 0,
                currency: mpnToken.address,
                metadata: "0x",
            },
        ];
        const resetClaimEligibility = true;
        await mpnTokenProxy.connect(admin).setClaimConditions(1, conditions, resetClaimEligibility);
    });

    it("exchange with mpt token", async () => {
        const name = await mpnTokenProxy.connect(user).name();
        expect(name).equal("Miracleplay NFT");

        await bridgeProxy.connect(newMinter).sendERC1155ToUser({
            fromChain: ChainType.Polygon,
            token: mpnTokenProxy.address,
            tokenId: 1,
            receiver: user.address,
            amount: 1,
            metadata: BYTES_ZERO,
            allowlistProof: {
                proof: [],
                quantityLimitPerWallet: 1,
                pricePerToken: 0,
                currency: mpnToken.address,
            },
            currency: mpnToken.address,
            pricePerToken: 0,
            data: "0x",
        });

        const userBalanceAfterMint500 = await mpnTokenProxy.connect(user).balanceOf(user.address, 1);
        expect(userBalanceAfterMint500).equal(1);
    });
});
