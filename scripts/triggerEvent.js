require('dotenv').config();
const { ethers } = require('ethers');
// dotenv config
// Get provider
const provider = new ethers.providers.JsonRpcProvider('https://rpc-mumbai.maticvigil.com/');
// Get wallet
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
// Get mumbai deployed impressionStake contract address
const impressionStakeJSON = require('../deployments/mumbai/ImpressionStake.json');
const impressionJSON = require('../deployments/mumbai/Impression.json');
// Get ImpressionStake contract
const impressionStake = new ethers.Contract(impressionStakeJSON.address, impressionStakeJSON.abi, wallet);
// Get Impression contract
const impression = new ethers.Contract(impressionJSON.address, impressionJSON.abi, wallet);

async function main() {
  // Request message

  const message = 'Hello World';
  //await impression.approve(impressionStake.address, ethers.utils.parseEther('10000'));
  // Request message
  //   let tx = await impressionStake.requestMessage(
  //     '0xB0853B57326e08aA536663D6aC78304c0b3E38Da',
  //     ethers.utils.parseEther('100')
  //   );
  //console.log(tx);
  await impressionStake.setUserCost(ethers.utils.parseEther('10'));
}

main();
