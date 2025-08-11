import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";
import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/types";
dotenv.config({ path: __dirname + "/.env" });

const OWNER_KEY = process.env.OWNER_KEY || "Test account's private key here";
const OWNER_KEY1 = process.env.OWNER_KEY1 || "Test account's private key here";
const OWNER_KEY2 = process.env.OWNER_KEY2 || "Test account's private key here";
const OWNER_KEY3 = process.env.OWNER_KEY3 || "Test account's private key here";
const TEST_OWNER_KEY = process.env.TEST_OWNER_KEY || "Test account's private key here";
// const TEST_OWNER_KEY = process.env.TEST_OWNER_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";

const REPORT_GAS = process.env.REPORT_GAS || false;

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.20",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        hardhat: {
            chainId: 31337,
            allowUnlimitedContractSize: true,
            gas: 20000000,
            gasPrice: 250000000000,
            accounts: [
                { privateKey: OWNER_KEY1, balance: "1000000000000000000000000000" },
                { privateKey: OWNER_KEY2, balance: "1000000000000000000000000000" },
                { privateKey: OWNER_KEY3, balance: "1000000000000000000000000000" },
            ],
        },
        // get avalanche c-chain
        avalanche: {
            // url: "https://avalanche-mainnet.infura.io/v3/bf289c9e6ebe42fb92f99d23d76ecdd0", // 아발란체 체인의 RPC 엔드포인트
            url: "https://api.avax.network/ext/bc/C/rpc", // 아발란체 체인의 RPC 엔드포인트
            chainId: 43114, // 아발란체 체인 ID
            // gasPrice: 280000000000,
            // gas: 200000000,
            accounts: [OWNER_KEY],
        },
        opbnb: {
            url: "https://opbnb-mainnet-rpc.bnbchain.org", // 아발란체 체인의 RPC 엔드포인트
            chainId: 204, // 아발란체 체인 ID
            accounts: [OWNER_KEY],
        },
        fuji: {
            url: "https://avalanche-fuji.infura.io/v3/bf289c9e6ebe42fb92f99d23d76ecdd0", // 아발란체 테스트넷의 RPC 엔드포인트
            chainId: 43113, // 아발란체 테스트넷 체인 ID
            gas: 20000000,
            gasPrice: 250000000000,
            accounts: [TEST_OWNER_KEY],
        },
        polygon: {
            url: "https://polygon-mainnet.infura.io/v3/bf289c9e6ebe42fb92f99d23d76ecdd0", // Polygon Mainnet의 RPC 엔드포인트
            chainId: 137, // Polygon Mainnet 체인 ID
            // gas: 20000000,
            // gasPrice: 70000000000,
            accounts: [OWNER_KEY],
        },
        base: {
            url: "https://mainnet.base.org", // Polygon Mainnet의 RPC 엔드포인트
            chainId: 8453, // Base Mainnet 체인 ID
            // gas: 20000000,
            // gasPrice: 70000000000,
            accounts: [OWNER_KEY],
        },
        arbi: {
            url: "https://arb1.arbitrum.io/rpc", // Polygon Mainnet의 RPC 엔드포인트
            chainId: 42161, // Base Mainnet 체인 ID
            // gas: 20000000,
            // gasPrice: 70000000000,
            accounts: [OWNER_KEY],
        },
        mumbai: {
            url: "https://polygon-mumbai.infura.io/v3/bf289c9e6ebe42fb92f99d23d76ecdd0", // Polygon Mumbai의 RPC 엔드포인트
            chainId: 80001, // Polygon Mumbai 체인 ID
            gas: 20000000,
            gasPrice: 25000000000,
            accounts: [TEST_OWNER_KEY],
        },
    },
    gasReporter: {
        enabled: REPORT_GAS ? true : false,
    },
};

export default config;
