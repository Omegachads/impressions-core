import { deployments, ethers } from 'hardhat';
import { Impression } from '../typechain/Impression';
import { ImpressionStake } from '../typechain/ImpressionStake';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const chai = require('chai');
const expect = chai.expect;
chai.use(require('chai-as-promised'));

// TODO: SHould take in a string message, hash the message
// TODO: Signer will sign the message hash and produce a signature
// TODO: Nonce is not required
const signWhitelist = (user: any, signing_key: any) => {
  const signingKey = new ethers.utils.SigningKey(signing_key);
  const nonce = ethers.utils.randomBytes(32);
  const msgHash = ethers.utils.solidityKeccak256(['address', 'bytes'], [user, nonce]);
  const digest = signingKey.signDigest(msgHash);
  const signature = ethers.utils.joinSignature(digest);
  return { signature: signature, nonce: ethers.utils.hexlify(nonce) };
};

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
  });

  describe('Request Message', function () {
    it('Should request message and tokens transferred', async function () {
      const amount = ethers.utils.parseEther('100');
      await impression.approve(impressionStake.address, amount);
      // Get signature
      let { signature, nonce } = signWhitelist(address, SIGNER_KEY);
      // await impressionStake.requestMessage(amount, '0x0000000000000000000000000000000000000000');
      // expect(await impression.balanceOf(impressionStake.address)).to.equal(amount);
    });
  });
});
