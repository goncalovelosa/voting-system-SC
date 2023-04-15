/* eslint-disable @typescript-eslint/no-var-requires */
import 'dotenv/config'

import '@nomicfoundation/hardhat-toolbox'
import 'hardhat-contract-sizer'
import '@openzeppelin/hardhat-upgrades'

const alchemyKey = process.env.ALCHEMY_API_KEY

const config = {
  defaultNetwork: 'hardhat',
  solidity: {
    version: '0.8.18',
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
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${alchemyKey}`,
      chainId: 5,
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
