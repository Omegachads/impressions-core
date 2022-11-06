const { access } = require('fs');
const { ethers } = require('hardhat');

const { GasLogger } = require('../utils/helper');
const gasLogger = new GasLogger();

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  console.log('ChainID: ', chainId);

  // DEPLOYMENTS////////////////////////////////////////////////////////
  console.log(`Deploying ImpressionStake... from ${deployer}`);
  // Get impression contract from previous deployment
  const impression = await ethers.getContract('Impression');
  let charityFund = '0x43F7D84e346584621AeD8eCE27C7ccd1659665E6';
  let signerAddress = '0xF25f9E09344DCeC110addF1603b6c9e650883af5';
  let impressionStake = await deploy('ImpressionStake', {
    from: deployer,
    args: [deployer, charityFund, signerAddress, impression.address],
  });
  console.log(`ImpressionStake at  ${impression.address}`);
  gasLogger.addDeployment(impressionStake);
};

module.exports.tags = ['ImpressionStake'];
