const chai = require("chai");
const web3 = require("web3-utils");
const BN = web3.BN;
const { expect } = chai;
const { solidity } = require("ethereum-waffle");

chai.use(solidity);

module.exports = {
  expect,
};
