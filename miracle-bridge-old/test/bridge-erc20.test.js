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
describe("MPT 20 Basic Mint & Burn Test", () => {
    let mptTokenProxy;
    let bridgeProxy;
    const minterRoleByBytes32 = keccak256("MINTER_ROLE");

    before(async () => {
        const signers = await ethers.getSigners();
        [deployer, newMinter, admin, primarySaleRecipient, platformFeeRecipient, user, ..._] = signers;
        const platformFeeBps = 100;
        const mptToken = await deployContract(contractArtifacts.MPT);
        const bridge = await deployContract(contractArtifacts.Bridge);
        const proxy = await deployContract(contractArtifacts.Proxy, deployer.address);
        const bridgeProxyContract = await deployContract(contractArtifacts.Proxy, deployer.address);

        await proxy.upgrade(mptToken.address);
        await bridgeProxyContract.upgrade(bridge.address);

        mptTokenProxy = await getContractAt("TokenERC20", proxy.address);
        bridgeProxy = await getContractAt("Bridge", bridgeProxyContract.address);

        await bridgeProxy.initialize(
            "Bridge",
            admin.address,
            ChainType.Avalanche,
            primarySaleRecipient.address,
            newMinter.address
        );

        await mptTokenProxy.initialize(
            bridgeProxy.address,
            "MPT Token",
            "MPT",
            "https://google.com",
            [],
            primarySaleRecipient.address,
            platformFeeRecipient.address,
            platformFeeBps
        );
    });

    it("exchange with mpt token", async () => {
        const userBalance = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalance).equal(0);

        const name = await mptTokenProxy.connect(user).name();
        expect(name).equal("MPT Token");

        await bridgeProxy.connect(newMinter).sendERC20ToUser({
            fromChain: ChainType.Polygon,
            token: mptTokenProxy.address,
            receiver: user.address,
            amount: 500,
            metadata: BYTES_ZERO,
        });

        const userBalanceAfterMint500 = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalanceAfterMint500).equal(500);

        await mptTokenProxy.connect(user).approve(bridgeProxy.address, 500);
        await bridgeProxy.connect(user).exchange({
            toChain: ChainType.Avalanche,
            token: mptTokenProxy.address,
            tokenId: 0,
            amount: 500,
            ercType: ErcType.ERC20,
            metadata: BYTES_ZERO,
        });

        const userBalanceAfterExchange = await mptTokenProxy.connect(user).balanceOf(user.address);
        expect(userBalanceAfterExchange).equal(0);
    });
});
