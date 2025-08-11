const { expect } = require("../helpers/setup");
const { ethers } = require("hardhat");
const { deployContract, getContractAt } = require("../helpers/utils");
const contractArtifacts = require("../helpers/contractArtifacts");
const { keccak256 } = require("web3-utils");

describe("MPT 20 Basic Mint & Burn Test", () => {
    let mptTokenProxy;
    const minterRoleByBytes32 = keccak256("MINTER_ROLE");

    before(async () => {
        const signers = await ethers.getSigners();
        [deployer, newMinter, admin, primarySaleRecipient, platformFeeRecipient, user, ..._] = signers;
        const platformFeeBps = 100;
        const mptToken = await deployContract(contractArtifacts.MPT);
        const proxy = await deployContract(contractArtifacts.Proxy, deployer.address);
        await proxy.upgrade(mptToken.address);

        mptTokenProxy = await getContractAt("TokenERC20", proxy.address);

        await mptTokenProxy.initialize(
            admin.address,
            "MPT Token",
            "MPT",
            "https://google.com",
            [],
            primarySaleRecipient.address,
            platformFeeRecipient.address,
            platformFeeBps
        );
    });

    it("mint with mpt token", async () => {
        const userBalance = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalance).equal(0);

        const name = await mptTokenProxy.connect(user).name();
        expect(name).equal("MPT Token");

        await expect(mptTokenProxy.mintTo(user.address, 500)).revertedWith("not minter.");

        await mptTokenProxy.connect(admin).mintTo(user.address, 500);

        const userBalanceAfterMint500 = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalanceAfterMint500).equal(500);
    });

    it("burn with mpt token", async () => {
        const userBalance = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalance).equal(500);

        await expect(mptTokenProxy.connect(deployer).burnFrom(user.address, 500)).revertedWith(
            "ERC20: insufficient allowance"
        );

        await mptTokenProxy.connect(user).approve(deployer.address, 500);

        await mptTokenProxy.connect(deployer).burnFrom(user.address, 500);

        const userBalanceAfterBurn500 = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalanceAfterBurn500).equal(0);
    });

    it("mint with mpt token by new minter", async () => {
        const userBalance = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalance).equal(0);

        const name = await mptTokenProxy.connect(user).name();
        expect(name).equal("MPT Token");

        await expect(mptTokenProxy.connect(newMinter).mintTo(user.address, 500)).revertedWith("not minter.");

        await mptTokenProxy.connect(admin).grantRole(minterRoleByBytes32, newMinter.address);

        await mptTokenProxy.connect(newMinter).mintTo(user.address, 500);

        const userBalanceAfterMint500 = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalanceAfterMint500).equal(500);
    });
});
