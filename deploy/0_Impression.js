const { access } = require('fs');
const { ethers } = require('hardhat');

const { GasLogger } = require('../utils/helper');
const gasLogger = new GasLogger();

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer, treasury } = await getNamedAccounts();
  const chainId = await getChainId();
  console.log('ChainID: ', chainId);

  // DEPLOYMENTS////////////////////////////////////////////////////////
  console.log(`Deploying Impression... from ${deployer}`);

  let impression = await deploy('Impression', {
    from: deployer,
    args: [ethers.utils.parseEther('100000000'), deployer],
  });
  console.log(`Impression at  ${impression.address}`);
  gasLogger.addDeployment(impression);
};

module.exports.tags = ['Impression'];
