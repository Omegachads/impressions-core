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
  let impressionStake = await deploy('ImpressionStake', {
    from: deployer,
    args: [deployer, deployer, impression.address],
  });
  console.log(`ImpressionStake at  ${impression.address}`);
  gasLogger.addDeployment(impressionStake);
};

module.exports.tags = ['ImpressionStake'];
