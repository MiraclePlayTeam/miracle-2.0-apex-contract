const { mine } = require("@nomicfoundation/hardhat-network-helpers");

const hardhat = require("hardhat");
const ethers = hardhat.ethers;
const Web3 = require("web3");
const web3Utils = require("web3-utils");

const Proxy = ethers.getContractFactory("Proxy");
const Bridge = ethers.getContractFactory("Bridge");
const TimelockController = ethers.getContractFactory("TimelockController");
const TimelockMultiSig = ethers.getContractFactory("TimelockMultiSig");

const funcs = ["isOperation", "isOperationPending", "isOperationReady", "isOperationDone", "getTimestamp"];


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
  
  

// 실행 명령어: npx hardhat run scripts/deploy-proxy-as-tms.js [--network "YOUR_NETWORK"]
// salt는 트랜잭션 index로 설정되어 있습니다. [salt 세팅]에서 변경 가능합니다.
// 기본적으로 TimelockMultiSig _owners는 하드햇 accounts로 되어 있습니다.

// multi-sig에서 트랜잭션에 몇명의 커밋이 필요한지
const REQUIED = 2;
// timelock에서 최소 딜레이가 몇초인지
const MIN_DELAY = 2;

async function main() {
    const signers = await ethers.getSigners();
    const [admin] = signers;
    const owners = [signers[0].address, signers[1].address, signers[2].address];

    // Bridge 배포
    const bridge = await deployContract(Bridge);
    console.log("Bridge deployed at", bridge.address);

    let proxyAddress;
    {
        // Proxy 배포
        const proxy = await deployContract(Proxy, admin.address);
        proxyAddress = proxy.address
        console.log("Proxy deployed at", proxy.address);
    }
    const proxy = await getContractAt("Proxy", proxyAddress);

    // TimelockController 배포 트랜잭션 생성자 파라미터
    const PROPOSERS = [];
    const EXECUTORS = owners;
    const TIMELOCK_ADMIN = admin.address;

    // TimelockController 배포
    const timelock = await deployContract(TimelockController, MIN_DELAY, PROPOSERS, EXECUTORS, TIMELOCK_ADMIN);
    console.log("TimelockController deployed at", timelock.address);
    
    // TimelockMultiSig 배포
    const tms = await deployContract(TimelockMultiSig, owners, REQUIED, timelock.address);
    console.log("TimelockMultiSig deployed at", tms.address);

    // Proxy의 admin을 TimelockMultiSig로 설정
    const proxySetAdmin = await proxy.setAdmin(tms.address);
    const proxySetAdminReceipt = await proxySetAdmin.wait();
    console.log(`proxy setAdmin(TimelockMultiSig):`, proxySetAdminReceipt.transactionHash);

    // Proxy upgrade calldata 생성
    const ABI = ["function upgrade(address)"];
    const iface = new ethers.utils.Interface(ABI);
    const cdata = iface.encodeFunctionData("upgrade", [bridge.address]);
    console.log("cdata", cdata)

    // cdata 이 데이터가 실제 실행하고 싶은 tx 입니다.

    // Proxy 컨트랙트 upgrade 트랜잭션 submit
    const tmsContractSubmit = await tms.submitTransaction(proxy.address, ethers.constants.Zero, cdata);
    const tmsContractSubmitReceipt = await tmsContractSubmit.wait();
    console.log("submit tx:", tmsContractSubmitReceipt.transactionHash);

    // 트랜잭션 인덱스
    const index = (await tms.getTransactionCount()) - 1;
    console.log("submit tx index:", index);

    // 트랜잭션 confirm

    {
        const tms0 = tms.connect(signers[0]);
        const tx = await tms0.confirmTransaction(index);
        const rec = await tx.wait();
        console.log("confirm:", rec.transactionHash);
    }
    {
        const tms1 = tms.connect(signers[1]);
        const tx = await tms1.confirmTransaction(index);
        const rec = await tx.wait();
        console.log("confirm:", rec.transactionHash);
    }


    // TimelockMultiSig 컨트랙트를 TimelockController 컨트랙트에 PROPOSER로 등록
    const PROPOSER_ROLE = await timelock.PROPOSER_ROLE();
    const timelockGrant = await timelock.grantRole(PROPOSER_ROLE, tms.address);
    await timelockGrant.wait();

    // salt 세팅
    const SALT = index;

    // TimelockMultiSig 컨트랙트 executeTransaction 실행
    const tmsContractExec = await tms.executeTransaction(index, SALT);
    const tmsContractExecReceipt = await tmsContractExec.wait();
    console.log("execute:", tmsContractExecReceipt.transactionHash);

    // timestamp 확인 (1)
    console.log();
    await ethers.provider.getBlock().then(({ timestamp }) => console.log("prev timestamp:", timestamp));

    // mine
    console.log("waiting...");
    await mine(2000);

    // timestamp 확인 (2)
    await ethers.provider.getBlock().then(({ timestamp }) => console.log("curr timestamp:", timestamp));

    // 체인으로부터 트랜잭션 데이터 받아와서 calldata 및 id 새로 생성
    const [to, value, data, executed, numConfirmations] = await tms.getTransaction(index);
    const ABI_tms = ["function executeScheduledTransaction(address,uint256,bytes)"];
    const iface_tms = new ethers.utils.Interface(ABI_tms);
    const cdata_tms = iface_tms.encodeFunctionData("executeScheduledTransaction", [to, value, data]);
    const id = await timelock.hashOperation(
        tms.address,
        0,
        cdata_tms,
        ethers.constants.HashZero,
        ethers.constants.HashZero
    );
    console.log();

    // timelock execute 전 상태 확인
    console.log("[before timelock.execute]");
    for (const f of funcs) console.log(f, await timelock[f](id));
    console.log();

    // timelock execute
    const execTx = await timelock.execute(
        tms.address,
        0,
        cdata_tms,
        ethers.constants.HashZero,
        ethers.utils.hexZeroPad(ethers.utils.hexlify(SALT), 32)
    );
    const execTxReceipt = await execTx.wait();
    console.log("timelock execute:", execTxReceipt.transactionHash);
    console.log();

    // timelock execute 후 상태 확인
    console.log("[after timelock.execute]");
    for (const f of funcs) console.log(f, await timelock[f](id));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
