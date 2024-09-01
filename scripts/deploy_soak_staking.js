const { soakTokenAddress, soakFeeRecipient } = require('../.secrets.json');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('Deploying contracts with the account:', deployer.address);
  const Contract = await ethers.getContractFactory('SoakStaking');
  const contract = await Contract.deploy(
    soakTokenAddress,
    soakFeeRecipient,
    soakTokenAddress,
    true
  );
  console.log('Staking Contract address:', contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
