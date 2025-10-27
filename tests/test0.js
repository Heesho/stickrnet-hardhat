const convert = (amount, decimals) => ethers.utils.parseUnits(amount, decimals);
const divDec = (amount, decimals = 18) => amount / 10 ** decimals;
const divDec6 = (amount, decimals = 6) => amount / 10 ** decimals;
const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { execPath } = require("process");

const AddressZero = "0x0000000000000000000000000000000000000000";

let owner, multisig, treasury, user0, user1, user2, user3;
let usdc, wft;
let tokenFactory, contentFactory, rewarderFactory;
let core, multicall, router;

describe("local: test0", function () {
  before("Initial set up", async function () {
    console.log("Begin Initialization");

    [owner, multisig, treasury, user0, user1, user2, user3] =
      await ethers.getSigners();

    const usdcArtifact = await ethers.getContractFactory("USDC");
    usdc = await usdcArtifact.deploy();
    console.log("- USDC Initialized");

    const tokenFactoryArtifact = await ethers.getContractFactory(
      "TokenFactory"
    );
    tokenFactory = await tokenFactoryArtifact.deploy();
    console.log("- TokenFactory Initialized");

    const contentFactoryArtifact = await ethers.getContractFactory(
      "ContentFactory"
    );
    contentFactory = await contentFactoryArtifact.deploy();
    console.log("- ContentFactory Initialized");

    const rewarderFactoryArtifact = await ethers.getContractFactory(
      "RewarderFactory"
    );
    rewarderFactory = await rewarderFactoryArtifact.deploy();
    console.log("- RewarderFactory Initialized");

    const coreArtifact = await ethers.getContractFactory("Core");
    core = await coreArtifact.deploy(
      usdc.address,
      tokenFactory.address,
      contentFactory.address,
      rewarderFactory.address
    );
    console.log("- Core Initialized");

    const multicallArtifact = await ethers.getContractFactory("Multicall");
    multicall = await multicallArtifact.deploy(core.address);
    console.log("- Multicall Initialized");

    const routerArtifact = await ethers.getContractFactory("Router");
    router = await routerArtifact.deploy(core.address);
    console.log("- Router Initialized");

    const amount = convert("100000", 6);
    await usdc.connect(owner).mint(user0.address, amount);
    await usdc.connect(owner).mint(user1.address, amount);
    await usdc.connect(owner).mint(user2.address, amount);
    await usdc.connect(owner).mint(user3.address, amount);
    console.log("- System set up");

    console.log("Initialization Complete");
    console.log();
  });

  it("User0 creates wft", async function () {
    console.log("******************************************************");

    const wftName = "wft";
    const wftSymbol = "wft";
    const wftUri = "https://wavefront.io/wft";

    await usdc.connect(user0).approve(router.address, convert("1", 6));
    await router
      .connect(user0)
      .createToken(wftName, wftSymbol, wftUri, false, convert("1", 6));
    wft = await ethers.getContractAt("Token", await tokenFactory.lastToken());
    console.log("- wft created");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("User0 buys wft with 10 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("10", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 10 usdc bought wft");
  });

  it("User0 sells 0.001 wft", async function () {
    console.log("******************************************************");
    const amount = convert("0.001", 18);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 0.001 wft sold");
  });

  it("User0 buys wft with 0.01 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("0.01", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 0.01 usdc bought wft");
  });

  it("User0 sells 0.01 wft", async function () {
    console.log("******************************************************");
    const amount = convert("0.01", 18);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 0.01 wft sold");
  });

  it("User0 buys wft with 0.001 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 0);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 0.00001 usdc bought wft");
  });

  it("User0 buys wft with 0.001 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 0.000001 usdc bought wft");
  });

  it("User0 buys wft with 0.001 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 0);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 0.000001 usdc bought wft");
  });

  it("User0 sells 0.000000001 wft", async function () {
    console.log("******************************************************");
    const amount = convert("0.000000001", 18);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 0.000000001 wft sold");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("User0 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("User0 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User0 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("User0 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("10000", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User0 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("User0 heals 100 usdc on wft", async function () {
    console.log("******************************************************");
    const amount = convert("100", 6);
    await usdc.connect(user0).approve(wft.address, amount);
    await wft.connect(user0).heal(amount);
    console.log("- 100 usdc healed on wft");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("User0 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("10000", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User0 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });
});
