const { ethers } = require("hardhat");
const { utils, BigNumber } = require("ethers");
const hre = require("hardhat");
const AddressZero = "0x0000000000000000000000000000000000000000";

/*===================================================================*/
/*===========================  SETTINGS  ============================*/

const TREASURY_ADDRESS = "0x7a8C895E7826F66e1094532cB435Da725dc3868f"; // Treasury Address
const SN1 = "0x8F8C00F7CAcBa66d1c7f3141cD95DfE56c7B4253"; // SN1 Address
const SN2 = ""; // SN2 Address
const SN3 = ""; // SN3 Address

/*===========================  END SETTINGS  ========================*/
/*===================================================================*/

// Constants
const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay));
const convert = (amount, decimals) => ethers.utils.parseUnits(amount, decimals);

// Contract Variables
let usdc;
let tokenFactory, contentFactory, rewarderFactory;
let core, multicall, router;
let token, content, rewarder;

/*===================================================================*/
/*===========================  CONTRACT DATA  =======================*/

async function getContracts() {
  usdc = await ethers.getContractAt(
    "contracts/mocks/USDC.sol:USDC",
    "0x0113A749d4c3cb85ea0Bf3062b41C63acA669d2f"
  );

  tokenFactory = await ethers.getContractAt(
    "contracts/TokenFactory.sol:TokenFactory",
    "0xC23E316705Feef0922F0651488264db90133ED38"
  );
  contentFactory = await ethers.getContractAt(
    "contracts/ContentFactory.sol:ContentFactory",
    "0x30F8e847fCf1bC750A1fDCE7bd329FEc4c8277F9"
  );
  rewarderFactory = await ethers.getContractAt(
    "contracts/RewarderFactory.sol:RewarderFactory",
    "0x2169a51D582D7D94F19Ad1EC8dCd4271E91D1fA0"
  );

  core = await ethers.getContractAt(
    "contracts/Core.sol:Core",
    "0x255F278Ad8Dff1C1FDCfeD97825522Df305D8B32"
  );
  multicall = await ethers.getContractAt(
    "contracts/Multicall.sol:Multicall",
    "0x0a0C653F3FB69906dFC77b845a24c285071d3144"
  );
  router = await ethers.getContractAt(
    "contracts/Router.sol:Router",
    "0x44CB84344243cC29bF63C417E4A00B124dB7dc8F"
  );

  token = await ethers.getContractAt("contracts/TokenFactory.sol:Token", SN1);
  content = await ethers.getContractAt(
    "contracts/ContentFactory.sol:Content",
    await token.content()
  );
  rewarder = await ethers.getContractAt(
    "contracts/RewarderFactory.sol:Rewarder",
    await token.rewarder()
  );

  console.log("Contracts Retrieved");
}

/*===========================  END CONTRACT DATA  ===================*/
/*===================================================================*/

async function deployUsdc() {
  console.log("Starting USDC Deployment");
  const usdcArtifact = await ethers.getContractFactory("USDC");
  const usdcContract = await usdcArtifact.deploy({
    gasPrice: ethers.gasPrice,
  });
  usdc = await usdcContract.deployed();
  await sleep(5000);
  console.log("USDC Deployed at:", usdc.address);
}

async function verifyUsdc() {
  console.log("Starting USDC Verification");
  await hre.run("verify:verify", {
    address: usdc.address,
    contract: "contracts/mocks/USDC.sol:USDC",
  });
  console.log("USDC Verified");
}

async function deployTokenFactory() {
  console.log("Starting TokenFactory Deployment");
  const tokenFactoryArtifact = await ethers.getContractFactory("TokenFactory");
  const tokenFactoryContract = await tokenFactoryArtifact.deploy({
    gasPrice: ethers.gasPrice,
  });
  tokenFactory = await tokenFactoryContract.deployed();
  await sleep(5000);
  console.log("TokenFactory Deployed at:", tokenFactory.address);
}

async function verifyTokenFactory() {
  console.log("Starting TokenFactory Verification");
  await hre.run("verify:verify", {
    address: tokenFactory.address,
    contract: "contracts/TokenFactory.sol:TokenFactory",
  });
  console.log("TokenFactory Verified");
}

async function deployContentFactory() {
  console.log("Starting ContentFactory Deployment");
  const contentFactoryArtifact = await ethers.getContractFactory(
    "ContentFactory"
  );
  const contentFactoryContract = await contentFactoryArtifact.deploy({
    gasPrice: ethers.gasPrice,
  });
  contentFactory = await contentFactoryContract.deployed();
  await sleep(5000);
  console.log("ContentFactory Deployed at:", contentFactory.address);
}

async function verifyContentFactory() {
  console.log("Starting ContentFactory Verification");
  await hre.run("verify:verify", {
    address: contentFactory.address,
    contract: "contracts/ContentFactory.sol:ContentFactory",
  });
  console.log("ContentFactory Verified");
}

async function deployRewarderFactory() {
  console.log("Starting RewarderFactory Deployment");
  const rewarderFactoryArtifact = await ethers.getContractFactory(
    "RewarderFactory"
  );
  const rewarderFactoryContract = await rewarderFactoryArtifact.deploy({
    gasPrice: ethers.gasPrice,
  });
  rewarderFactory = await rewarderFactoryContract.deployed();
  await sleep(5000);
  console.log("RewarderFactory Deployed at:", rewarderFactory.address);
}

async function verifyRewarderFactory() {
  console.log("Starting RewarderFactory Verification");
  await hre.run("verify:verify", {
    address: rewarderFactory.address,
    contract: "contracts/RewarderFactory.sol:RewarderFactory",
  });
  console.log("RewarderFactory Verified");
}

async function deployCore() {
  console.log("Starting Core Deployment");
  const coreArtifact = await ethers.getContractFactory("Core");
  const coreContract = await coreArtifact.deploy(
    usdc.address,
    tokenFactory.address,
    contentFactory.address,
    rewarderFactory.address,
    {
      gasPrice: ethers.gasPrice,
    }
  );
  core = await coreContract.deployed();
  await sleep(5000);
  console.log("Core Deployed at:", core.address);
}

async function verifyCore() {
  console.log("Starting Core Verification");
  await hre.run("verify:verify", {
    address: core.address,
    contract: "contracts/Core.sol:Core",
    constructorArguments: [
      usdc.address,
      tokenFactory.address,
      contentFactory.address,
      rewarderFactory.address,
    ],
  });
  console.log("Core Verified");
}

async function deployMulticall() {
  console.log("Starting Multicall Deployment");
  const multicallArtifact = await ethers.getContractFactory("Multicall");
  const multicallContract = await multicallArtifact.deploy(core.address, {
    gasPrice: ethers.gasPrice,
  });
  multicall = await multicallContract.deployed();
  await sleep(5000);
  console.log("Multicall Deployed at:", multicall.address);
}

async function verifyMulticall() {
  console.log("Starting Multicall Verification");
  await hre.run("verify:verify", {
    address: multicall.address,
    contract: "contracts/Multicall.sol:Multicall",
    constructorArguments: [core.address],
  });
  console.log("Multicall Verified");
}

async function deployRouter() {
  console.log("Starting Router Deployment");
  const routerArtifact = await ethers.getContractFactory("Router");
  const routerContract = await routerArtifact.deploy(core.address, {
    gasPrice: ethers.gasPrice,
  });
  router = await routerContract.deployed();
  await sleep(5000);
  console.log("Router Deployed at:", router.address);
}

async function verifyRouter() {
  console.log("Starting Router Verification");
  await hre.run("verify:verify", {
    address: router.address,
    contract: "contracts/Router.sol:Router",
    constructorArguments: [core.address],
  });
  console.log("Router Verified");
}

async function printDeployment() {
  console.log("**************************************************************");
  console.log("USDC: ", usdc.address);
  console.log("TokenFactory: ", tokenFactory.address);
  console.log("ContentFactory: ", contentFactory.address);
  console.log("RewarderFactory: ", rewarderFactory.address);
  console.log("Core: ", core.address);
  console.log("Multicall: ", multicall.address);
  console.log("Router: ", router.address);
  console.log("**************************************************************");
}

async function verifyToken(wallet) {
  console.log("Starting Token Verification");
  await hre.run("verify:verify", {
    address: token.address,
    contract: "contracts/TokenFactory.sol:Token",
    constructorArguments: [
      await token.name(),
      await token.symbol(),
      await content.uri(),
      core.address,
      usdc.address,
      await core.INITIAL_SUPPLY(),
      await core.RESERVE_VIRT_QUOTE_RAW(),
      contentFactory.address,
      rewarderFactory.address,
      wallet.address,
      await core.CONTENT_MIN_INIT_PRICE(),
      false,
    ],
  });
  console.log("Token Verified");
}

async function verifyContent() {
  console.log("Starting Content Verification");
  await hre.run("verify:verify", {
    address: content.address,
    contract: "contracts/ContentFactory.sol:Content",
    constructorArguments: [
      await token.name(),
      await token.symbol(),
      await content.uri(),
      token.address,
      usdc.address,
      rewarderFactory.address,
      await core.CONTENT_MIN_INIT_PRICE(),
      false,
    ],
  });
  console.log("Content Verified");
}

async function verifyRewarder() {
  console.log("Starting Rewarder Verification");
  await hre.run("verify:verify", {
    address: rewarder.address,
    contract: "contracts/RewarderFactory.sol:Rewarder",
    constructorArguments: [content.address],
  });
  console.log("Rewarder Verified");
}

async function main() {
  const [wallet] = await ethers.getSigners();
  console.log("Using wallet: ", wallet.address);

  await getContracts();

  //===================================================================
  // Deploy System
  //===================================================================

  // console.log("Starting System Deployment");
  // await deployUsdc();
  // await deployTokenFactory();
  // await deployContentFactory();
  // await deployRewarderFactory();
  // await deployCore();
  // await deployMulticall();
  // await deployRouter();
  // await printDeployment();

  /*********** UPDATE getContracts() with new addresses *************/

  //===================================================================
  // Verify System
  //===================================================================

  // console.log("Starting System Verification");
  // await verifyUsdc();
  // await sleep(5000);
  // await verifyTokenFactory();
  // await sleep(5000);
  // await verifyContentFactory();
  // await sleep(5000);
  // await verifyRewarderFactory();
  // await sleep(5000);
  // await verifyCore();
  // await sleep(5000);
  // await verifyMulticall();
  // await sleep(5000);
  // await verifyRouter();

  // console.log("Verify Token");
  // await verifyToken(wallet);
  // await sleep(5000);
  // await verifyContent();
  // await sleep(5000);
  // await verifyRewarder();

  //===================================================================
  // Transactions
  //===================================================================

  console.log("Starting Transactions");

  // console.log("Mint USDC");
  // const mintTx = await usdc.mint(wallet.address, convert("10000", 6));
  // await mintTx.wait();
  // console.log("USDC Balance: ", await usdc.balanceOf(wallet.address));

  // console.log("Deploy Token");
  // const createAmount = convert("1", 6);
  // const approveTx = await usdc
  //   .connect(wallet)
  //   .approve(router.address, createAmount, { gasPrice: ethers.gasPrice });
  // await approveTx.wait();
  // const createTokenTx = await router.createToken(
  //   "Pepe",
  //   "PEPE",
  //   "https://memedepot.com/cdn-cgi/imagedelivery/naCPMwxXX46-hrE49eZovw/02069990-70b9-4b84-407e-0f2f249edb00/public",
  //   false,
  //   createAmount,
  //   {
  //     gasPrice: ethers.gasPrice,
  //   }
  // );
  // await createTokenTx.wait();
  // console.log("Token Deployed at:", await core.index_Token(1));

  // console.log("Buy Token");
  // const buyAmount = convert("1000", 6);
  // const approveTx = await usdc
  //   .connect(wallet)
  //   .approve(router.address, buyAmount, { gasPrice: ethers.gasPrice });
  // await approveTx.wait();
  // await sleep(5000);
  // const buyTx = await router
  //   .connect(wallet)
  //   .buy(token.address, AddressZero, buyAmount, 0, 0, {
  //     gasPrice: ethers.gasPrice,
  //   });
  // await buyTx.wait();
  // await sleep(5000);
  // console.log(
  //   "Token bought: ",
  //   ethers.utils.formatUnits(await token.balanceOf(wallet.address), 18)
  // );

  // console.log("Sell Token");
  // const sellAmount = convert("1000", 18);
  // const approveTx = await token
  //   .connect(wallet)
  //   .approve(router.address, sellAmount, { gasPrice: ethers.gasPrice });
  // await approveTx.wait();
  // await sleep(5000);
  // const sellTx = await router
  //   .connect(wallet)
  //   .sell(token.address, AddressZero, sellAmount, 0, 0, {
  //     gasPrice: ethers.gasPrice,
  //   });
  // await sellTx.wait();
  // await sleep(5000);
  // console.log(
  //   "Token sold: ",
  //   ethers.utils.formatUnits(await token.balanceOf(wallet.address), 18)
  // );

  // console.log("Borrow Credit");
  // const borrowAmount = convert("1", 6);
  // const borrowTx = await token
  //   .connect(wallet)
  //   .borrow(wallet.address, borrowAmount, {
  //     gasPrice: ethers.gasPrice,
  //   });
  // await borrowTx.wait();
  // await sleep(5000);
  // console.log("Token borrowed: ", await token.account_DebtRaw(wallet.address));

  // console.log("Repay Debt");
  // const repayAmount = convert("0.5", 6);
  // const approveTx = await usdc
  //   .connect(wallet)
  //   .approve(token.address, repayAmount, { gasPrice: ethers.gasPrice });
  // await approveTx.wait();
  // await sleep(5000);
  // const repayTx = await token
  //   .connect(wallet)
  //   .repay(wallet.address, repayAmount, {
  //     gasPrice: ethers.gasPrice,
  //   });
  // await repayTx.wait();
  // await sleep(5000);
  // console.log("Token debt: ", await token.account_DebtRaw(wallet.address));

  // console.log("Heal Token");
  // const healAmount = convert("1000", 6);
  // const approveTx = await usdc
  //   .connect(wallet)
  //   .approve(token.address, healAmount, { gasPrice: ethers.gasPrice });
  // await approveTx.wait();
  // await sleep(5000);
  // const healTx = await token.connect(wallet).heal(healAmount, {
  //   gasPrice: ethers.gasPrice,
  // });
  // await healTx.wait();
  // await sleep(5000);
  // console.log("Token price: ", await token.getMarketPrice());

  // console.log("Burn Token");
  // const burnAmount = convert("1000", 18);
  // const burnTx = await token.connect(wallet).burn(burnAmount, {
  //   gasPrice: ethers.gasPrice,
  // });
  // await burnTx.wait();
  // await sleep(5000);
  // console.log("Token price: ", await token.getMarketPrice());

  // console.log("Create Content");
  // const contentTx = await router
  //   .connect(wallet)
  //   .createContent(
  //     token.address,
  //     "https://memedepot.com/cdn-cgi/imagedelivery/naCPMwxXX46-hrE49eZovw/e3ad8257-5543-453a-10ce-6e928130d800/public",
  //     {
  //       gasPrice: ethers.gasPrice,
  //     }
  //   );
  // await contentTx.wait();
  // await sleep(5000);
  // console.log("Content created: ", await content.tokenURI(1));

  // console.log("Curate Content");
  // let res = await multicall.getContentData(token.address, 1);
  // console.log(res);
  // const approveTx = await usdc
  //   .connect(wallet)
  //   .approve(router.address, res.price, {
  //     gasPrice: ethers.gasPrice,
  //   });
  // await approveTx.wait();
  // await sleep(5000);
  // const collectTx = await router
  //   .connect(wallet)
  //   .collectContent(
  //     token.address,
  //     AddressZero,
  //     1,
  //     res.epochId,
  //     1871590734,
  //     res.price,
  //     {
  //       gasPrice: ethers.gasPrice,
  //     }
  //   );
  // await collectTx.wait();
  // await sleep(5000);
  // console.log("Content Price: ", await content.getPrice(1));

  // console.log("Transfer Token");
  // const targetAddress = "0x19858F6c29eA886853dc97D1a68ABf8d4Cb07712";
  // const transferAmount = convert("1000", 18);
  // const transferTx = await token
  //   .connect(wallet)
  //   .transfer(targetAddress, transferAmount, {
  //     gasPrice: ethers.gasPrice,
  //   });
  // await transferTx.wait();
  // await sleep(5000);
  // console.log("Token transferred: ", await token.balanceOf(targetAddress));

  // console.log("Claim Reward");
  // const claimTx = await router.connect(wallet).getContentReward(token.address, {
  //   gasPrice: ethers.gasPrice,
  // });
  // await claimTx.wait();
  // await sleep(5000);
  // console.log("Reward claimed: ");

  // console.log("Update uri");
  // const updateUriTx = await content
  //   .connect(wallet)
  //   .setUri(
  //     "https://memedepot.com/cdn-cgi/imagedelivery/naCPMwxXX46-hrE49eZovw/a6763307-44b2-4579-275a-50f27f2de700/public",
  //     {
  //       gasPrice: ethers.gasPrice,
  //     }
  //   );
  // await updateUriTx.wait();
  // await sleep(5000);
  // console.log("Uri updated: ", await content.uri());

  // console.log("Token Data");
  // const res = await multicall.getTokenData(token.address, AddressZero);
  // console.log(res);

  // console.log("Content Data");
  // const res = await multicall.getContentData(token.address, 1);
  // console.log(res);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
