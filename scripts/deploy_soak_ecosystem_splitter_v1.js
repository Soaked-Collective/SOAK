const { tokenAddress, devAddress } = require('../.secrets.json');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    'Deploying Soak Ecosystem Splitter V1 contract with the account:',
    deployer.address
  );
  console.log('Account balance:', (await deployer.getBalance()).toString());
  const ContractFactory = await ethers.getContractFactory(
    'SoakverseEcosystemSplitterV1'
  );
  const contract = await ContractFactory.deploy(
    '0x1b2fdb1626285b94782af2fda8e270e95cebc3b4',
    '0x647C7a60c88A7C71a2A4D5a1BB3403b6FFe5EF69',
    '0xD395C62D50c11B19C44b4B0b7C09faB67795A5CD',
    '0x2C6Dc31063c65CACfD0D1EAd7c192074B5C278ba',
    '0xf5da615989dadbd552e3479d79e8e7f34eca9832',
    '0x2ae33aa09adbe84de47d8b5c08df3d1dfae17f02'
  );
  console.log('Contract address:', contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
