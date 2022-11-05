import { deployments, ethers } from 'hardhat';
import { Impression } from '../typechain/Impression';
import { ImpressionStake } from '../typechain/ImpressionStake';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const chai = require('chai');
const expect = chai.expect;
chai.use(require('chai-as-promised'));

// TODO: SHould take in a string message, hash the message
// TODO: Signer will sign the message hash and produce a signature
// TODO: Nonce is not required for this test

describe('ImpressionStake contract', function () {
  let impressionStake: ImpressionStake;
  let impression: Impression;
  let owner: SignerWithAddress;
  let treasury: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, treasury, addr2, addr3, ...addrs] = await ethers.getSigners();
    await deployments.fixture(['Impression', 'ImpressionStake']);
    impressionStake = (await ethers.getContract('ImpressionStake')) as ImpressionStake;
    impression = (await ethers.getContract('Impression')) as Impression;
    impression.transfer(addr2.address, ethers.utils.parseEther('100000000'));
  });

  describe('Main Functions', function () {
    it('Should request message and tokens transferred', async function () {
      // Create a string message
      const message = 'Hello World Bitches';
      // Set user cost for owner
      await impressionStake.connect(owner).setUserCost(ethers.utils.parseEther('100'));
      // approve impressionStake to transfer impression tokens
      await impression.connect(addr2).approve(impressionStake.address, ethers.utils.parseEther('10000'));
      // Request message
      await impressionStake.connect(addr2).requestMessage(owner.address, ethers.utils.parseEther('100'));
      // Expect balance to equal 10000
      expect(await impression.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther('99999900'));
      // Hash the message
      const msgHash = ethers.utils.solidityKeccak256(['string'], [message]);
      // Sign the message hash
      const signature = await owner.signMessage(ethers.utils.arrayify(msgHash));
    });

    it('Should claim tokens only after a signature is provided', async function () {
      // Create a string message
      const message = 'Hello World Bitches';

      let eventFilter = impressionStake.filters.MessageRequestCreated();
      // Set user cost for owner
      await impressionStake.connect(owner).setUserCost(ethers.utils.parseEther('100'));
      // approve impressionStake to transfer impression tokens
      await impression.connect(addr2).approve(impressionStake.address, ethers.utils.parseEther('10000'));
      // Request message
      await impressionStake.connect(addr2).requestMessage(owner.address, ethers.utils.parseEther('100'));

      let events = await impressionStake.queryFilter(eventFilter);
      let requestId = events[0].args.requestId;
      // Log requestId
      console.log('Sample requestId: ', requestId);
      let textMessageHash = ethers.utils.solidityKeccak256(['string'], [message]);
      // Hash the message
      let msgHash = ethers.utils.solidityKeccak256(
        ['uint256', 'address', 'bytes'],
        [requestId, owner.address, textMessageHash]
      );
      // Sign the message hash
      const signature = await owner.signMessage(ethers.utils.arrayify(msgHash));
      // Claim tokens
      await impressionStake.connect(owner).claimMessage(requestId, signature, textMessageHash);
      // Expect owner balance to increase by 100
      expect(await impression.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('100'));
    });
  });
});
