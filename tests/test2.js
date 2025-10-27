const convert = (amount, decimals) => ethers.utils.parseUnits(amount, decimals);
const divDec = (amount, decimals = 18) => amount / 10 ** decimals;
const divDec6 = (amount, decimals = 6) => amount / 10 ** decimals;
const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { execPath } = require("process");

const AddressZero = "0x0000000000000000000000000000000000000000";

let owner, multisig, treasury, user0, user1, user2, user3;
let usdc, usdt, wft0, wft1, wft2, wft3;
let tokenFactory, contentFactory, rewarderFactory;
let core, multicall, router;

describe("local: test2", function () {
  before("Initial set up", async function () {
    console.log("Begin Initialization");

    [owner, multisig, treasury, user0, user1, user2, user3] =
      await ethers.getSigners();

    const usdcArtifact = await ethers.getContractFactory("USDC");
    usdc = await usdcArtifact.deploy();
    usdt = await usdcArtifact.deploy();
    console.log("- USDC Initialized");
    console.log("- USDT Initialized");

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

  it("User0 creates wft0", async function () {
    console.log("******************************************************");

    const wftName = "wft0";
    const wftSymbol = "wft0";
    const wftUri = "https://wavefront.io/wft0";

    await usdc.connect(user0).approve(router.address, convert("1", 6));
    await router
      .connect(user0)
      .createToken(wftName, wftSymbol, wftUri, false, convert("1", 6));
    wft0 = await ethers.getContractAt("Token", await tokenFactory.lastToken());
    console.log("- wft0 created");
  });

  it("User1 creates wft1", async function () {
    console.log("******************************************************");

    const wftName = "wft1";
    const wftSymbol = "wft1";
    const wftUri = "https://wavefront.io/wft1";

    const amount = convert("1000", 6);
    await usdc.connect(user1).approve(router.address, amount);
    await router
      .connect(user1)
      .createToken(wftName, wftSymbol, wftUri, false, amount);
    wft1 = await ethers.getContractAt("Token", await tokenFactory.lastToken());
    console.log("- wft1 created");
  });

  it("User2 creates wft2", async function () {
    console.log("******************************************************");

    const wftName = "wft2";
    const wftSymbol = "wft2";
    const wftUri = "https://wavefront.io/wft2";

    let amount = convert("1", 6);
    await usdc.connect(user2).approve(router.address, amount);
    await router
      .connect(user2)
      .createToken(wftName, wftSymbol, wftUri, false, amount);
    wft2 = await ethers.getContractAt("Token", await tokenFactory.lastToken());
    console.log("- wft2 created");
  });

  it("User3 creates wft3", async function () {
    console.log("******************************************************");

    const wftName = "wft3";
    const wftSymbol = "wft3";
    const wftUri = "https://wavefront.io/wft3";

    let amount = convert("100000", 6);
    await usdc.connect(user3).approve(router.address, amount);
    await router
      .connect(user3)
      .createToken(wftName, wftSymbol, wftUri, false, amount);
    wft3 = await ethers.getContractAt("Token", await tokenFactory.lastToken());
    console.log("- wft3 created");
  });

  it("core coverage", async function () {
    console.log("******************************************************");
    console.log("quote: ", await core.quote());
    console.log("tokenFactory: ", await core.tokenFactory());
    console.log("contentFactory: ", await core.contentFactory());
    console.log("rewarderFactory: ", await core.rewarderFactory());
    console.log("treasury: ", await core.treasury());
    console.log("index: ", await core.index());
    console.log("index_Token[0]: ", await core.index_Token(0));
    console.log("index_Token[1]: ", await core.index_Token(1));
    console.log("index_Token[2]: ", await core.index_Token(2));
    console.log("index_Token[3]: ", await core.index_Token(3));
    console.log("token_Index[wft0]: ", await core.token_Index(wft0.address));
    console.log("token_Index[wft1]: ", await core.token_Index(wft1.address));
    console.log("token_Index[wft2]: ", await core.token_Index(wft2.address));
    console.log("token_Index[wft3]: ", await core.token_Index(wft3.address));

    await core.connect(owner).setTreasury(AddressZero);
    await core.connect(owner).setTreasury(treasury.address);
    await expect(core.connect(user0).setTreasury(treasury.address)).to.be
      .reverted;

    await core.connect(owner).setTokenFactory(AddressZero);
    await core.connect(owner).setTokenFactory(tokenFactory.address);
    await expect(core.connect(user0).setTokenFactory(AddressZero)).to.be
      .reverted;

    await core.connect(owner).setContentFactory(AddressZero);
    await core.connect(owner).setContentFactory(contentFactory.address);
    await expect(core.connect(user0).setContentFactory(AddressZero)).to.be
      .reverted;

    await core.connect(owner).setRewarderFactory(AddressZero);
    await core.connect(owner).setRewarderFactory(rewarderFactory.address);
    await expect(core.connect(user0).setRewarderFactory(AddressZero)).to.be
      .reverted;
  });

  it("Rewarder coverage", async function () {
    console.log("******************************************************");
    console.log("- content reward added");
    await usdc.connect(owner).mint(owner.address, convert("10", 6));
    await usdc.connect(owner).approve(router.address, convert("2", 6));
    await router
      .connect(owner)
      .notifyContentRewardAmount(wft0.address, usdc.address, convert("2", 6));
    console.log("- content reward notified");
    await usdc.connect(owner).approve(router.address, convert("1", 6));
    await expect(
      router
        .connect(owner)
        .notifyContentRewardAmount(wft0.address, usdc.address, convert("1", 6))
    ).to.be.revertedWith("Rewarder__RewardSmallerThanLeft");
    await usdc.connect(owner).approve(router.address, convert("0.1", 6));
    await expect(
      router
        .connect(owner)
        .notifyContentRewardAmount(
          wft0.address,
          usdc.address,
          convert("0.1", 6)
        )
    ).to.be.revertedWith("Rewarder__RewardSmallerThanLeft");
  });
});
