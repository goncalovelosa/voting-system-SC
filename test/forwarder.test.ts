// Import the necessary packages
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Forwarder } from '../typechain/contracts/forwarder/ForwarderV2.sol/Forwarder'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { IForwarder } from '../typechain/contracts/interfaces/IForwarder'
import { ForwardRequest, signForwardRequest } from '../fixtures/forwarder'

// Define the test suite
describe('Forwarder', function () {
  let forwarder: IForwarder
  let chainId: number
  let trustedSigner: SignerWithAddress
  let operator: SignerWithAddress
  let recipient: SignerWithAddress

  before(async function () {
    // Create some test wallets
    ;[trustedSigner, operator, recipient] = await ethers.getSigners()

    // Get the chain ID
    chainId = (await ethers.provider.getNetwork()).chainId

    // Deploy the Forwarder contract
    const Forwarder = await ethers.getContractFactory('Forwarder')
    forwarder = (await Forwarder.connect(trustedSigner).deploy()) as Forwarder
    await forwarder.deployed()
  })

  describe('forward', function () {
    beforeEach(async function () {
      // Add the operator
      await forwarder.connect(trustedSigner).addOperator(operator.address)

      await forwarder.getNonce(trustedSigner.address)
    })

    it('should forward a transaction', async function () {
      // Set up the request
      const request = {
        from: trustedSigner.address,
        to: recipient.address,
        value: ethers.utils.parseEther('0'),
        data: '0x',
        nonce: await forwarder.getNonce(trustedSigner.address),
      }

      // Sign the request
      const signature = signForwardRequest(chainId, forwarder.address, request, trustedSigner)

      // Forward the request
      const tx = await forwarder.connect(operator).forward(request, signature)

      // Verify the result
      expect(tx)
        .to.emit(forwarder, 'Forwarded')
        .withArgs(trustedSigner.address, recipient.address, request.value, request.data, request.nonce.add(1))
    })

    it('should fail if the sender is not authorized', async function () {
      // Set up the request
      const request: ForwardRequest = {
        from: trustedSigner.address,
        to: recipient.address,
        value: ethers.utils.parseEther('1'),
        data: '0x',
        nonce: await forwarder.connect(trustedSigner).getNonce(trustedSigner.address),
      }

      // Sign the request
      const signature = signForwardRequest(chainId, forwarder.address, request, trustedSigner)

      // Try to forward the request from an unauthorized sender
      await expect(forwarder.connect(recipient).forward(request, signature)).to.be.revertedWith(
        'Forwarder: sender unauthorized',
      )
    })

    it('should fail if the signature is invalid', async function () {
      // Set up the request
      const request: ForwardRequest = {
        from: trustedSigner.address,
        to: recipient.address,
        value: ethers.utils.parseEther('1'),
        data: '0x',
        nonce: await forwarder.connect(trustedSigner).getNonce(trustedSigner.address),
      }

      // Sign the request with the wrong private key
      const signature = signForwardRequest(chainId, forwarder.address, request, operator)

      // Try to forward the request with the wrong signature
      await expect(forwarder.connect(operator).forward(request, signature)).to.be.revertedWith(
        'Forwarder: invalid signature',
      )
    })
  })
})
