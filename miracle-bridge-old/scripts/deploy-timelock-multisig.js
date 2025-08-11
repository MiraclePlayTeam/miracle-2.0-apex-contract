const { mine } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const { Proxy, Bridge, TimelockController, TimelockMultiSig } = require("../helpers/contractArtifacts");
const { deployContract, getContractAt } = require("../helpers/utils");

const funcs = ["isOperation", "isOperationPending", "isOperationReady", "isOperationDone", "getTimestamp"];

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
    console.log("admin:", admin);
    console.log("owners:", signers);
    const owners = [signers[0].address, signers[1].address, signers[2].address];

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

/*
3. 타임락에 proposers에 멀티시그 컨트랙트 등록  grantRole 호출
 - proposers에 멀티시그 컨트랙트 하나만 등록함
*/
    // TimelockMultiSig 컨트랙트를 TimelockController 컨트랙트에 PROPOSER로 등록
    const PROPOSER_ROLE = await timelock.PROPOSER_ROLE();
    const timelockGrant = await timelock.grantRole(PROPOSER_ROLE, tms.address);
    await timelockGrant.wait();

/*
4. 타임락에 admin을 멀티시그 지갑으로 변경. 
*/
const TIMELOCK_ADMIN_ROLE = await timelock.TIMELOCK_ADMIN_ROLE();
    {
        const hasRoleAdmin1 = await timelock.hasRole(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN);
        const hasRoleAdmin2 = await timelock.hasRole(TIMELOCK_ADMIN_ROLE, tms.address);
        const hasRoleProposer = await timelock.hasRole(PROPOSER_ROLE, tms.address);

        console.log("before TimelockController hasRole(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN):", hasRoleAdmin1);
        console.log("before TimelockController hasRole(TIMELOCK_ADMIN_ROLE, tms):", hasRoleAdmin2);
        console.log("before TimelockController hasRole(PROPOSER_ROLE, tms):", hasRoleProposer);
    }
    // 4.1. grantRole:admin 으로 멀티시그 지갑지정 호출,
    const MultisigGrantAdmin = await timelock.grantRole(TIMELOCK_ADMIN_ROLE, tms.address);
    await MultisigGrantAdmin.wait();

    // 4.2. renounceRole: admin권한에서 생성시에 지정했던 admin 제거 호출
    const renounceAdmin = await timelock.renounceRole(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN);
    await renounceAdmin.wait();

    // 4.3. timelock의 admin이 멀티시그 지갑인지 확인
    {
        const hasRoleAdmin1 = await timelock.hasRole(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN);
        const hasRoleAdmin2 = await timelock.hasRole(TIMELOCK_ADMIN_ROLE, tms.address);
        const hasRoleProposer = await timelock.hasRole(PROPOSER_ROLE, tms.address);
    
        console.log("after TimelockController hasRole(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN):", hasRoleAdmin1);
        console.log("after TimelockController hasRole(TIMELOCK_ADMIN_ROLE, tms):", hasRoleAdmin2);
        console.log("after TimelockController hasRole(PROPOSER_ROLE, tms):", hasRoleProposer);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
