/* eslint-disable @typescript-eslint/no-var-requires */
import 'dotenv/config'

import '@nomicfoundation/hardhat-toolbox'
import 'hardhat-contract-sizer'
import '@openzeppelin/hardhat-upgrades'

const infuraKey = process.env.INFURA_API_KEY

const config = {
  defaultNetwork: 'hardhat',
  solidity: {
    version: '0.8.16',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    ganache: {
      url: 'http://localhost:8545',
      gasPrice: 20000000000,
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${infuraKey}`,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${infuraKey}`,
      chainId: 5,
    },
    matic: {
      url: `https://polygon-mainnet.infura.io/v3/${infuraKey}`,
      chainId: 137,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    showTimeSpent: true,
    currency: 'EUR',
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
}

export default config
