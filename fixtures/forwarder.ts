import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { Forwarder } from '../typechain/contracts/forwarder/ForwarderV2.sol/Forwarder'
import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

// Define the ForwardRequest interface
interface ForwardRequest {
  from: string
  to: string
  value: BigNumber
  data: string
  nonce: BigNumber
}

// Define the BatchForwardRequest interface
interface BatchForwardRequest {
  request: ForwardRequest
  signature: string
}

//Deploy the Forwarder contract
async function deployForwarder(owner: SignerWithAddress) {
  const forwarderFactory = await ethers.getContractFactory('Forwarder')
  const forwarder = (await forwarderFactory.connect(owner).deploy()) as Forwarder
  await forwarder.deployed()
  return forwarder
}

// Define the signForwardRequest function
async function signForwardRequest(
  chainId: number,
  verifyingContract: string,
  request: ForwardRequest,
  signer: SignerWithAddress,
  name = 'Forwarder',
  version = '0.1',
): Promise<string> {
  const { from, to, value, data, nonce } = request

  return await signer._signTypedData(
    {
      name,
      version,
      chainId,
      verifyingContract,
    },
    {
      ForwardRequest: [
        {
          name: 'from',
          type: 'address',
        },
        {
          name: 'to',
          type: 'address',
        },
        {
          name: 'value',
          type: 'uint256',
        },
        {
          name: 'data',
          type: 'bytes',
        },
        {
          name: 'nonce',
          type: 'uint256',
        },
      ],
    },
    {
      from,
      to,
      value,
      data: ethers.utils.keccak256(data),
      nonce,
    },
  )
}

export { deployForwarder, signForwardRequest, ForwardRequest, BatchForwardRequest }
