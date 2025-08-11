# 타임락&멀티시그 지갑으로 프록시 컨트랙트 오너 변경 및 컨트랙트 업그레이드 시나리오

테스트 오너
["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]

- 컨트랙트 2개(타임락, 멀티시그) 배포

- 타임락
proposers: 제안은 멀티시그월렛만 가능하도록 설정
executors: 실행은 오너들 지갑주소들 모두 가능
admin: 초기에 있어야 멀티시그 배포후 등록할수 있음 설정완료후 제거

- 멀티시그
OWNERS: 오너들 3개 지갑 사용
REQUIRED: 3개중 2개 이상

TimelockMultiSig.sol 을 컴파일 하면 TimelockController 컨트랙트와 TimelockMultiSig를 배포할수 있습니다.

1. 타임락(TimelockController) 배포: 0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692
mindelay: 60 * 60 * 24 * 2 (48h) 지금은 60 정도로 짧게 사용
proposers: [] 비워둠
executors: 오너들
admin: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

2. 멀티시그(TimelockMultiSig) 배포: 0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D
_OWNERS: [오너들]
_REQUIRED: 2
_TIMELOCK: 타임락 컨트랙트

3. 타임락에 proposers에 멀티시그 컨트랙트 등록  grantRole 호출
 - proposers에 멀티시그 컨트랙트 하나만 등록함

4. 타임락에 admin을 멀티시그 지갑으로 변경. 
 4.1. grantRole:admin 으로 멀티시그 지갑지정 호출,
 4.2. renounceRole: admin권한에서 생성시에 지정했던 admin 제거 호출

5. 프록시 어드민을 멀티시그 지갑 컨트랙트(0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D)로 변경 setAdmin 호출
 ! 프록시 어드민 타임락 & 멀티시그 지갑으로 교체 완료


# 타임락 & 멀티시그를 사용한 컨트랙트 업그레이드 진행

6. 멀티시그에서 submitTransaction 으로 프록시 컨트랙트 업그레이드 서밋
 6.1. 프록시 컨트랙트: 0x5e17b14ADd6c386305A32928F985b29bbA34Eff5
 6.2. 프록시 컨트랙트 의 업그레이드 함수 calldata 추출. 로직 컨트랙트 addr(더미): 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c
    0x0900f01000000000000000000000000014723a09acff6d2a60dcdf7aa4aff308fddc160c
 6.3. 멀티시그에서 submitTransaction 으로 프록시 컨트랙트 업그레이드 서밋

7. 멀티시그에서 오너들이 confirmTransaction 실행 (2개 이상의 지갑에서 진행)
 7.1 submit한 순서대로 txindex가 생성됨, 0번 txindex를 confirm

8. 멀티시그에서 오너중 한명이 executeTransaction 실행
 8.1 0번 txindex와 임의의 salt를 지정함(아무 숫자나 상관없으나 동일한 executeScheduledTransaction calldata 일 경우 동일한 숫자를 사용할 수 없음)

9. 타임락에서 시간이 지난후 execute 실행
 9.1. 멀티시그의 executeScheduledTransaction calldata 추출 6.2. 에서 진행한 데이터로 진행, 
  _to: 프록시 컨트랙트
  _value: 0
  _data: 6.2.에서 추출한 데이터 사용
 => 0x4f69907e0000000000000000000000005e17b14add6c386305a32928f985b29bba34eff50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000240900f01000000000000000000000000014723a09acff6d2a60dcdf7aa4aff308fddc160c00000000000000000000000000000000000000000000000000000000

 9.2. predecessor는 byte32(0)으로 순서상관없이 진행되도록하고 salt는 8.1 에서 지정한 salt를 사용한다. (TimelockMultiSig 에 있는 getSalt함수를 쓰면 uint256 => bytes32으로 보여준다.)
  target: 0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D(멀티시그)
  value: 0 
  payload: 9.1. 에서 구한값 
  predecessor: 0x0000000000000000000000000000000000000000000000000000000000000000
  salt: 0x0000000000000000000000000000000000000000000000000000000000000000

프록시 로직 컨트랙트 변경 확인


