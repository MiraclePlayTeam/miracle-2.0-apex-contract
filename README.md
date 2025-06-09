# Miracleplay-Contract

## 1. Miracle Edition Staking

> Miracle Staking is a smart contract platform that allows users to stake their ERC-1155 NFTs in order to earn rewards in a ERC-20 token. The platform also allows for agent rewards and DAO royalties.

## 2. Miracle Token Staking

> Miracle Token Staking is a smart contract platform that allows users to stake their ERC-20 Tokens in order to earn rewards in a ERC-20 token.

## 3. Miracle Tounermant

> Miracle Tournament is a smart contract platform that allows users to participate in tournaments and compete for prizes. The platform uses a single-elimination format, and allows for multiple rounds of play.

## 4. Miracle Token to Token Swap

> EOA (Externally Owned Account)

## 5. ThirdWeb Setup and Contract Deployment

### 1. Install ThirdWeb CLI

```bash
npx thirdweb install
```

### 2. Install Dependencies

```bash
yarn install
# or
npm install
```

### 3. Configure API Key

1. Obtain your API key from the ThirdWeb dashboard
2. Set up your API key as an environment variable:

```bash
echo 'export THIRDWEB_API_KEY="your_api_key_here"' >> ~/.zshrc
source ~/.zshrc
```

### 4. Deploy Contract

```bash
yarn contract ./contract/{folder_name}
```

> 💡 **Important Notes**
>
> - Keep your API key secure and never share it
> - Restart your terminal or run `source ~/.zshrc` after setting environment variables
> - Verify all configurations before deploying your contract
