const { expect } = require("../helpers/setup");
const { ethers } = require("hardhat");
const { deployContract, getContractAt } = require("../helpers/utils");
const contractArtifacts = require("../helpers/contractArtifacts");
const { keccak256 } = require("web3-utils");
const { ZERO_ADDRESS, BYTES_ZERO } = require("../helpers/constants");

describe("MPN Basic Mint & Burn Test", () => {
    let mpnTokenProxy;
    let mptToken;
    const tokenId = "1";
    const minterRoleByBytes32 = keccak256("MINTER_ROLE");

    before(async () => {
        const signers = await ethers.getSigners();
        [deployer, newMinter, admin, saleRecipient, royaltyRecipient, platformFeeRecipient, user, ..._] = signers;
        const royaltyBps = 100;
        const platformFeeBps = 100;
        mptToken = await deployContract(contractArtifacts.MPT);
        const mpnToken = await deployContract(contractArtifacts.MPN);
        const proxy = await deployContract(contractArtifacts.Proxy, deployer.address);
        await proxy.upgrade(mpnToken.address);

        mpnTokenProxy = await getContractAt("DropERC1155", proxy.address);

        await mpnTokenProxy.initialize(
            admin.address,
            "Miracleplay NFT",
            "MPN",
            "https://google.com",
            [],
            saleRecipient.address,
            royaltyRecipient.address,
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
                currency: mptToken.address,
                metadata: "0x",
            },
        ];
        const resetClaimEligibility = true;
        await mpnTokenProxy.connect(admin).setClaimConditions(1, conditions, resetClaimEligibility);
    });

    it("mint with mpn token", async () => {
        const userBalance = await mpnTokenProxy.connect(user).balanceOf(user.address, 1);
        expect(userBalance).equal(0);

        await mpnTokenProxy
            .connect(user)
            .claim(
                user.address,
                1,
                1,
                mptToken.address,
                0,
                { proof: [], quantityLimitPerWallet: 1, pricePerToken: 0, currency: mptToken.address },
                "0x"
            );

        const userBalanceAfterMint = await mpnTokenProxy.balanceOf(user.address, 1);
        expect(userBalanceAfterMint).equal(1);
    });

    it("burn with mpn token", async () => {
        const userBalance = await mpnTokenProxy.balanceOf(user.address, 1);
        expect(userBalance).equal(1);

        await expect(mpnTokenProxy.connect(admin).burnBatch(user.address, [1], [1])).revertedWith(
            "ERC1155: caller is not owner nor approved."
        );

        await mpnTokenProxy.connect(user).setApprovalForAll(admin.address, true);

        await mpnTokenProxy.connect(admin).burnBatch(user.address, [1], [1]);

        const userBalanceAfterBurn = await mpnTokenProxy.balanceOf(user.address, 1);
        expect(userBalanceAfterBurn).equal(0);
    });
});
