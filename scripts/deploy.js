async function main() {
  // We get the contract to deploy
  const WordToken = await ethers.getContractFactory("WordToken");
  const wordToken = await WordToken.deploy(0);

  console.log("WordToken deployed to:", wordToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
