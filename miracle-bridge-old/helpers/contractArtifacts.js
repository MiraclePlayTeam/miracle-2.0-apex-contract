const MPT = ethers.getContractFactory("TokenERC20");
const MPN = ethers.getContractFactory("DropERC1155");
const Proxy = ethers.getContractFactory("Proxy");
const Bridge = ethers.getContractFactory("Bridge");
const TimelockController = ethers.getContractFactory("TimelockController");
const TimelockMultiSig = ethers.getContractFactory("TimelockMultiSig");
module.exports = {
    MPT,
    MPN,
    Proxy,
    Bridge,
    TimelockController,
    TimelockMultiSig,
};
