const hardhat = require("hardhat");
const ethers = hardhat.ethers;
const Web3 = require("web3");
const web3Utils = require("web3-utils");
// const INFURA_NODE = process.env.INFURA_NODE || "https://polygon-mainnet.infura.io/v3/2bfcc1d84c1648648e92560dfb4a0b6b"
// hardhat.Web3 = Web3;


const deployContract = async (artifact, ...args) => {
  try {
    const contract = await (await artifact).deploy(...args);
    let instance = await contract.deployed();
    return instance;
  } catch (e) {
    console.log("deployContract error: ", e);
  }
};

const getContractAt = async (artifact, contractAddress) => {
  return await hre.ethers.getContractAt(artifact, contractAddress);
};

const getBlockNumber = async () => {
  return await ethers.provider.getBlockNumber();
};


const soliditySha3 = async (...args) => {
  return web3Utils.soliditySha3(...args);
};

module.exports = {
  deployContract,
  getContractAt,
  soliditySha3,
  getBlockNumber,
  deployContract,
};
