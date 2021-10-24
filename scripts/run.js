const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('PixiCats');
  const gameContract = await gameContractFactory.deploy(
    ['Bawler Cat', 'Mr. Meowington', 'Yogi Cat'], // Names
    [
      'https://i.imgur.com/U3r98Ym.jpg',
      'https://i.imgur.com/o7kkFES.jpg',
      'https://i.imgur.com/cnRyNcm.jpg',
    ], // Images
    [100, 300, 400], // HP values
    [200, 100, 100], // Attack damage values
    'Evil Dog', // Boss name
    'https://i.imgur.com/GpGSo8x.jpg', // Boss image
    10000, // Boss hp
    100 // Boss attack damage
  );
  await gameContract.deployed();
  console.log('Contract deployed to:', gameContract.address);

  let txn;
  txn = await gameContract.mintCharacterNFT(0);
  await txn.wait();
  console.log('Minted NFT #1');

  txn = await gameContract.attackBoss();
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();

  txn = await gameContract.mintCharacterNFT(1);
  await txn.wait();
  console.log('Minted NFT #2');

  txn = await gameContract.mintCharacterNFT(1);
  await txn.wait();
  console.log('Minted NFT #3');

  txn = await gameContract.mintCharacterNFT(2);
  await txn.wait();
  console.log('Minted NFT #4');

  console.log('Done deploying and minting!');

  // Get NFT's URI value
  let returnedTokenUri = await gameContract.tokenURI(1);
  // console.log('Token URI: ', returnedTokenUri);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
