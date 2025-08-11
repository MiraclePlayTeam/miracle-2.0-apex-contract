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

const CONTRACT_AVALANCHE_BRIDGE_PROXY = "0x215e1bf3dd7ef0a5d5a740e965a3e090ca3b91e4";
const CONTRACT_AVALANCHE_MPT = "0x422812fC000E831b5ff13C181d85F34dd71380b3";
const CONTRACT_AVALANCHE_MPN = "0x82c540a705DCa6Fb88D11FB0496F3C2d5B269A2a";
const CONTRACT_AVALANCHE_MLGE = "0xEb1B1F7cb7D09DCb383898b381554Dbe24670da4";
// const CONTRACT_AVALANCHE_MPT = "0x5321c14a124d33da74a4701dcfbcb13e7c1fa707";
// const CONTRACT_AVALANCHE_MPN = "0x3a70d013255b411337344d3acb1d63e05df565cf";
// const CONTRACT_AVALANCHE_MLGE = "0x8df8d90c0e0f6bacc18bab3fde026374051e8635";

const OWNER_ADDRESS = "0x82FCb7bdAa578Da16d10074e07784bA318Be702c";

const minterRoleByBytes32 = keccak256("MINTER_ROLE");
const minterAndBurnerRoleByBytes32 = keccak256("MINTER_AND_BURNER_ROLE");

let mptToken;
let mpnToken;
let mlgeToken;
let mptTokenProxy;
let mpnTokenProxy;
let mlgeTokenProxy;
let bridge;
let bridgeProxy;
const platformFeeBps = 100;

// 1. MPN, MPT, MLGE Token에 대해서 민터, 버너 권한을 브릿지 프록시가 보유하고 있는지 확인한다.

// 2. 브릿지 컨트랙트의 민터 권한을 어드민 계정이 보유하고 있는지 확인한다.
async function main() {
    const signers = await ethers.getSigners();
    [owner, ..._] = signers;

    mptTokenProxy = await getContractAt("TokenERC20", CONTRACT_AVALANCHE_MPT);
    mpnTokenProxy = await getContractAt("DropERC1155", CONTRACT_AVALANCHE_MPN);
    mlgeTokenProxy = await getContractAt("TokenERC20", CONTRACT_AVALANCHE_MLGE);

    bridgeProxy = await getContractAt("Bridge", CONTRACT_AVALANCHE_BRIDGE_PROXY);

    // const hasRoleAboutMpt = await mptTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_AVALANCHE_BRIDGE_PROXY);
    // const hasRoleAboutMpn = await mpnTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_AVALANCHE_BRIDGE_PROXY);
    // const hasRoleAboutMlge = await mlgeTokenProxy.hasRole(minterRoleByBytes32, CONTRACT_AVALANCHE_BRIDGE_PROXY);
    // const hasRoleAboutBridge = await bridgeProxy.hasRole(minterAndBurnerRoleByBytes32, OWNER_ADDRESS);

    // console.log("🚀 hasRoleAboutBridge:", hasRoleAboutBridge);
    // console.log("🚀 hasRoleAboutMlge:", hasRoleAboutMlge);
    // console.log("🚀 hasRoleAboutMpn:", hasRoleAboutMpn);
    // console.log("🚀 hasRoleAboutMpt:", hasRoleAboutMpt);

    // const sendData = {
    //     fromChain : 0,
    //     token : '0x422812fc000e831b5ff13c181d85f34dd71380b3',
    //     receiver : '0x359fa8c52f6902efba225822954a3dc1c3088b1b',
    //     amount : '1000000000000000000',
    //     feeAmount : '1',
    //     metadata : '0x0000000000000000000000000000000000000000000000000000000000000000'
    // }
const sendData = {
  fromChain: 0,
  token: '0x82c540a705dca6fb88d11fb0496f3c2d5b269a2a',
  tokenId: '1',
  receiver: '0xd7b3fd159960f02a35f010fc8be5366484ff7964',
  amount: '2',
  metadata: '0x0000000000000000000000000000000000000000000000000000000000000000',
  allowlistProof: {
    proof: [],
    quantityLimitPerWallet: 1,
    pricePerToken: 0,
    currency: '0x0000000000000000000000000000000000000000'
  },
  currency: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
  pricePerToken: 0,
  data: '0x'
}

/*
uint256 startTimestamp:             1703585778,
uint256 maxClaimableSupply:         115792089237316195423570985008687907853269984665640564039457584007913129639935,
uint256 supplyClaimed:              0,
uint256 quantityLimitPerWallet:     0,
bytes32 merkleRoot:                 0x387f88744086572632bb4508c0c2a6eb8437899cfd6f58b5c5cf034e9bc02de8,
uint256 pricePerToken:              0,
address currency:                   0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
string metadata:                    ipfs://QmZxhDsqbBY7zQprRLkWoxh6tJF495gZQD3bREzcArDf6F/0
1703585778,
115792089237316195423570985008687907853269984665640564039457584007913129639935,
0,
0,
0x387f88744086572632bb4508c0c2a6eb8437899cfd6f58b5c5cf034e9bc02de8,
0,
0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
ipfs://QmZxhDsqbBY7zQprRLkWoxh6tJF495gZQD3bREzcArDf6F/0


if (_quantity == 0 || (_quantity + supplyClaimedByWallet > claimLimit)) {
  revert("!Qty");
}

여기서 _quantity 는 2로 보내고 있고 
supplyClaimedByWallet 값은 0x215E1Bf3dd7ef0A5d5A740E965A3e090ca3B91E4 이 지갑에서 0값 입니다.
claimLimit값은 claimCondition[_tokenId].conditions[_conditionId].quantityLimitPerWallet 으로 세팅되고 있는데 
claimCondition[1].conditions[0].quantityLimitPerWallet == 0 이라서
해당값을 수정해 주셔야 할것 같습니다.
*/

    const data = bridgeProxy.interface.encodeFunctionData("sendERC1155ToUser", [sendData]);
    console.log(data)

    // 58f5efa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000422812fc000e831b5ff13c181d85f34dd71380b3000000000000000000000000359fa8c52f6902efba225822954a3dc1c3088b1b0000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000
    // 0xf9028e1e854ad350b8b9830493e094215e1bf3dd7ef0a5d5a740e965a3e090ca3b91e480b902245300ff5e0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000082c540a705dca6fb88d11fb0496f3c2d5b269a2a0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d7b3fd159960f02a35f010fc8be5366484ff796400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014000000000000000000000000082c540a705dca6fb88d11fb0496f3c2d5b269a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000082c540a705dca6fb88d11fb0496f3c2d5b269a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000830150f8a025bb590abfc2d28de6a63d13dacba13ae6bf325d79a4d636cb3037b6572511a0a033767ef04f80f0be11c87c05822c9cde8573f95559b68ec9e820ca59bec56f22

    const gas = await ethers.provider.estimateGas({
        from: OWNER_ADDRESS,
        to: CONTRACT_AVALANCHE_BRIDGE_PROXY,
        data: data,
        value: 0,
    });
    console.log(gas)

    // const signedTx = "0xf9028e18850ad20e15e6830493e094215e1bf3dd7ef0a5d5a740e965a3e090ca3b91e480b902245300ff5e0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000082c540a705dca6fb88d11fb0496f3c2d5b269a2a0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d7b3fd159960f02a35f010fc8be5366484ff796400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014000000000000000000000000082c540a705dca6fb88d11fb0496f3c2d5b269a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000082c540a705dca6fb88d11fb0496f3c2d5b269a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000830150f8a06e33f6ece4b96ba7513fa4f5490a0f91b54d70cd821f5e6e9c31cb0d3ba484b2a02f131892ab2c4bd649e1b2c735d10393c6bd7715cf959c6e78099f35f2d2ce99"

    // // 서명된 트랜잭션 전송
    // const txResponse = await ethers.provider.sendTransaction(signedTx);
    // console.log(`Transaction hash: ${txResponse.hash}`);

    // // 트랜잭션 영수증 확인
    // const receipt = await txResponse.wait();
    // console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
    

    // const d = await bridgeProxy.sendERC20ToUser(sendData);
    // console.log(d)

    // if (!hasRoleAboutMlge) {
    //     console.log("🚀 mlgeTokenProxy has not role about minter");
    //     await mlgeTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_AVALANCHE_BRIDGE_PROXY);
    // }
    // if (!hasRoleAboutMpt) {
    //     console.log("🚀 mptTokenProxy has not role about minter");
    //     await mptTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_AVALANCHE_BRIDGE_PROXY);
    // }
    // if (!hasRoleAboutMpn) {
    //     console.log("🚀 mpnTokenProxy has not role about minter");
    //     await mpnTokenProxy.grantRole(minterRoleByBytes32, CONTRACT_AVALANCHE_BRIDGE_PROXY);
    // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
