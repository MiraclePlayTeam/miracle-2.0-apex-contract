import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";
import { HardhatUserConfig } from "hardhat/config";

const sourcePath = process.env.SOURCE_PATH || "./contract";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      }
    }
  },
  paths: {
    sources: sourcePath,
    artifacts: "./artifacts",
    cache: "./cache",
    tests: "./test"
  }
};

export default config;
