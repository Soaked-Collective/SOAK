import { HardhatUserConfig } from 'hardhat/types';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-verify';

const {
  mainnetAccount,
  testnetAccount,
  localhostDeployAccount,
  infuraProjectId,
  etherscanApiKey,
  basescanApiKey,
} = require('./.secrets.json');

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    compilers: [
      {
        version: '0.8.20',
        settings: {
          optimizer: { enabled: true, runs: 200 },
        },
      },
    ],
  },
  networks: {
    localhost: {
      url: 'http://localhost:8545',
      accounts: [localhostDeployAccount],
    },
    testnet: {
      url: 'https://ethereum-goerli.publicnode.com',
      chainId: 5,
      accounts: [testnetAccount],
    },
    sepolia: {
      url: 'https://ethereum-sepolia.publicnode.com',
      chainId: 11155111,
      accounts: [testnetAccount],
    },
    base: {
      url: 'https://mainnet.base.org',
      chainId: 8453,
      accounts: [mainnetAccount],
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/' + infuraProjectId,
      accounts: [mainnetAccount],
    },
  },
  etherscan: {
    apiKey: {
      mainnet: etherscanApiKey,
      goerli: etherscanApiKey,
      sepolia: etherscanApiKey,
      base: basescanApiKey,
    },
  },
};

export default config;
