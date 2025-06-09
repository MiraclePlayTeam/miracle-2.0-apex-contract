# Miracleplay-Contract

## 1. Miracle Edition Staking

> Miracle Staking is a smart contract platform that allows users to stake their ERC-1155 NFTs in order to earn rewards in a ERC-20 token. The platform also allows for agent rewards and DAO royalties.

## 2. Miracle Token Staking

> Miracle Token Staking is a smart contract platform that allows users to stake their ERC-20 Tokens in order to earn rewards in a ERC-20 token.

## 3. Miracle Tounermant

> Miracle Tournament is a smart contract platform that allows users to participate in tournaments and compete for prizes. The platform uses a single-elimination format, and allows for multiple rounds of play.

## 4. Miracle Token to Token Swap

## ThirdWeb 설정 및 컨트랙트 배포

### 1. ThirdWeb CLI 설치

```bash
npx thirdweb install
```

### 2. yarn 또는 npm install

```bash
yarn install or npm install
```

### 3. API 키 등록

1. ThirdWeb 대시보드에서 API 키를 발급받습니다.
2. 터미널에서 다음 명령어를 실행하여 API 키를 환경변수로 등록합니다:

```bash
echo 'export THIRDWEB_API_KEY="your_api_key_here"' >> ~/.zshrc
source ~/.zshrc
```

### 4. 컨트랙트 배포

```bash
yarn contract ./contract/{폴더명}
```

> 💡 **참고사항**
>
> - API 키는 반드시 안전하게 보관하세요.
> - 환경변수 등록 후에는 터미널을 재시작하거나 `source ~/.zshrc` 명령어를 실행해야 합니다.
> - 컨트랙트 배포 전에 모든 설정이 올바르게 되어있는지 확인하세요.
