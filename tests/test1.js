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

describe("local: test1", function () {
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

    const amount = convert("10000000", 6);
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

    const amount = convert("100", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .createToken(wftName, wftSymbol, wftUri, false, amount);
    wft = await ethers.getContractAt("Token", await tokenFactory.lastToken());
    console.log("- wft created");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user1.address);
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

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user3.address);
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

  it("User0 buys wft with 10 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("10", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 10 usdc bought wft");
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

  it("User0 buys wft with 10 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("10", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 10 usdc bought wft");
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

  it("User0 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
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

  it("User1 buys wft with 10 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("10", 6);
    await usdc.connect(user1).approve(router.address, amount);
    await router
      .connect(user1)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 10 usdc bought wft");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user1.address);
    console.log(res);
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user2.address);
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

  it("User1 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user1.address);
    await wft.connect(user1).approve(router.address, amount);
    await router
      .connect(user1)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("User2 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user2.address);
    await wft.connect(user2).approve(router.address, amount);
    await expect(
      router
        .connect(user2)
        .sell(wft.address, AddressZero, amount, 0, 2000000000)
    ).to.be.revertedWith("Token__MinTradeSize");
    console.log("- all wft sold");
  });

  it("Quote Buy In", async function () {
    console.log("******************************************************");
    const amount = convert("10000000", 6);
    await multicall.buyQuoteIn(wft.address, 0, 9800);
    let res = await multicall
      .connect(owner)
      .buyQuoteIn(wft.address, amount, 9800);

    console.log("USDC in", divDec6(amount));
    console.log("Slippage Tolerance", "2%");
    console.log();
    console.log("WFT0 out", divDec(res.tokenAmtOut));
    console.log("slippage", divDec(res.slippage));
    console.log("min WFT0 out", divDec(res.minTokenAmtOut));
    console.log("auto min WFT0 out", divDec(res.autoMinTokenAmtOut));
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

  it("Quote Sell In", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await multicall.sellTokenIn(wft.address, 0, 9800);
    let res = await multicall.sellTokenIn(wft.address, amount, 9700);
    console.log("WFT in", divDec(amount));
    console.log("Slippage Tolerance", "3%");
    console.log();
    console.log("USDC out", divDec6(res.quoteRawOut));
    console.log("slippage", divDec(res.slippage));
    console.log("min USDC out", divDec6(res.minQuoteRawOut));
    console.log("min USDC out", divDec6(res.autoMinQuoteRawOut));
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
  });

  it("Quote buy out", async function () {
    console.log("******************************************************");
    const amount = convert("10", 18);
    let res = await multicall
      .connect(owner)
      .buyTokenOut(wft.address, amount, 9700);
    console.log("WFT out", divDec(amount));
    console.log("Slippage Tolerance", "3%");
    console.log();
    console.log("USDC in", divDec6(res.quoteRawIn));
    console.log("slippage", divDec(res.slippage));
    console.log("min Token out", divDec(res.minTokenAmtOut));
    console.log("min Token out", divDec(res.autoMinTokenAmtOut));
  });

  it("Quote sell out", async function () {
    console.log("******************************************************");
    const amount = convert("10", 6);
    let res = await multicall
      .connect(owner)
      .sellQuoteOut(wft.address, amount, 9950);
    console.log("USDC out", divDec6(amount));
    console.log("Slippage Tolerance", "0.5%");
    console.log();
    console.log("WFT in", divDec(res.tokenAmtIn));
    console.log("slippage", divDec(res.slippage));
    console.log("min USDC out", divDec6(res.minQuoteRawOut));
    console.log("min USDC out", divDec6(res.autoMinQuoteRawOut));
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user2.address);
    console.log(res);
  });

  it("User0 borrows against wft0", async function () {
    console.log("******************************************************");
    console.log("Contract USDC balance: ", await usdc.balanceOf(wft.address));
    console.log("User0 Credit: ", await wft.getAccountCredit(user0.address));
    await wft
      .connect(user0)
      .borrow(user0.address, await wft.getAccountCredit(user0.address));
  });

  it("User0 tries to transfer and tries to sell", async function () {
    console.log("******************************************************");
    const transferrable = await wft.getAccountTransferrable(user0.address);
    console.log("User0 transferrable wft: ", divDec(transferrable));
    const amount = convert("1", 18);
    await expect(
      wft.connect(user0).transfer(user1.address, amount)
    ).to.be.revertedWith("Token__CollateralLocked");
    await wft.connect(user0).transfer(user1.address, transferrable);
    console.log(
      "User0 transferrable wft: ",
      divDec(await wft.getAccountTransferrable(user0.address))
    );
    console.log("- wft transferred");
  });

  it("User0 tries to sell wft0", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).approve(router.address, amount);
    await expect(
      router
        .connect(user0)
        .sell(wft.address, AddressZero, amount, 0, 2000000000)
    ).to.be.revertedWith("Token__CollateralLocked");
  });

  it("User0 repays some usdc for wft0", async function () {
    console.log("******************************************************");
    const amount = convert("1", 6);
    await usdc.connect(user0).approve(wft.address, amount);
    await wft.connect(user0).repay(user0.address, amount);
    console.log("- 1 usdc repaid for wft");
  });

  it("User0 tries to transfer and tries to sell", async function () {
    console.log("******************************************************");
    const transferrable = await wft.getAccountTransferrable(user0.address);
    console.log("User0 transferrable wft: ", divDec(transferrable));
    const amount = await wft.balanceOf(user0.address);
    await expect(
      wft.connect(user0).transfer(user1.address, amount)
    ).to.be.revertedWith("Token__CollateralLocked");
    await wft.connect(user0).transfer(user1.address, transferrable);
    console.log(
      "User0 transferrable wft: ",
      divDec(await wft.getAccountTransferrable(user0.address))
    );
    console.log("- wft transferred");
  });

  it("User0 repays all usdc", async function () {
    console.log("******************************************************");
    console.log(
      "User0 transferrable wft: ",
      divDec(await wft.getAccountTransferrable(user0.address))
    );
    await usdc
      .connect(user0)
      .approve(wft.address, await wft.account_DebtRaw(user0.address));
    await wft
      .connect(user0)
      .repay(user0.address, await wft.account_DebtRaw(user0.address));
    console.log(
      "User0 transferrable wft: ",
      divDec(await wft.getAccountTransferrable(user0.address))
    );
    console.log("- all usdc repaid for wft");
  });

  it("User0 transfers wft0", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).transfer(user1.address, amount);
    console.log("- wft transferred");
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user3.address);
    console.log(res);
  });

  it("User1 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user1.address);
    await wft.connect(user1).approve(router.address, amount);
    await router
      .connect(user1)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
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

  it("User1 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user1).approve(router.address, amount);
    await router
      .connect(user1)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User2 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user2).approve(router.address, amount);
    await router
      .connect(user2)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User3 buys wft with 10000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("10000000", 6);
    await usdc.connect(user3).approve(router.address, amount);
    await router
      .connect(user3)
      .buy(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- 1,000,0000 usdc bought wft");
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user3.address);
    console.log(res);
  });

  it("User0 heals with 1 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user0).approve(wft.address, amount);
    await wft.connect(user0).heal(amount);
    console.log("- 1000 usdc healed for wft");
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
  });

  it("User3 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user3.address);
    await wft.connect(user3).approve(router.address, amount);
    await router
      .connect(user3)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("User0 heals with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user0).approve(wft.address, amount);
    await wft.connect(user0).heal(amount);
    console.log("- 1000 usdc healed for wft");
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user3.address);
    console.log(res);
  });

  it("User0 burns all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).approve(wft.address, amount);
    await wft.connect(user0).burn(amount);
    console.log("- all wft burned");
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
  });

  it("Set core treasury to treasury", async function () {
    console.log("******************************************************");
    await expect(core.connect(user0).setTreasury(treasury.address)).to.be
      .reverted;
    await core.connect(owner).setTreasury(treasury.address);
    await core.connect(owner).setTreasury(AddressZero);
    await core.connect(owner).setTreasury(treasury.address);
    console.log("- core treasury set to treasury");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, treasury.address);
    console.log(res);
  });

  it("User0 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .buy(wft.address, user1.address, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User1 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user1).approve(router.address, amount);
    await router
      .connect(user1)
      .buy(wft.address, user2.address, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User2 buys wft with 1000 usdc", async function () {
    console.log("******************************************************");
    const amount = convert("1000", 6);
    await usdc.connect(user2).approve(router.address, amount);
    await router
      .connect(user2)
      .buy(wft.address, user2.address, amount, 0, 2000000000);
    console.log("- 1000 usdc bought wft");
  });

  it("User0 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user0.address);
    await wft.connect(user0).approve(router.address, amount);
    await router
      .connect(user0)
      .sell(wft.address, user1.address, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("User1 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user1.address);
    await wft.connect(user1).approve(router.address, amount);
    await router
      .connect(user1)
      .sell(wft.address, user2.address, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("User2 sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(user2.address);
    await wft.connect(user2).approve(router.address, amount);
    await router
      .connect(user2)
      .sell(wft.address, user2.address, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, treasury.address);
    console.log(res);
  });

  it("Treasury sells all wft", async function () {
    console.log("******************************************************");
    const amount = await wft.balanceOf(treasury.address);
    await wft.connect(treasury).approve(router.address, amount);
    await router
      .connect(treasury)
      .sell(wft.address, AddressZero, amount, 0, 2000000000);
    console.log("- all wft sold");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, treasury.address);
    console.log(res);
  });

  it("Invariants wft0", async function () {
    console.log("******************************************************");
    const reserveRealQuote = await wft.wadToRaw(
      await wft.reserveRealQuoteWad()
    );
    const reserveVirtQuote = await wft.wadToRaw(
      await wft.reserveVirtQuoteWad()
    );
    const reserveToken = await wft.reserveTokenAmt();
    const totalSupply = await wft.totalSupply();
    const maxSupply = await wft.maxSupply();
    const maxReserve = reserveToken.add(totalSupply);
    const usdcBalance = await usdc.balanceOf(wft.address);
    const usdcRemaining = (await wft.reserveRealQuoteWad())
      .add(await wft.reserveVirtQuoteWad())
      .mul(reserveToken)
      .div(maxReserve);

    console.log("USDC Balance: ", divDec6(usdcBalance));
    console.log("Reserve USDC: ", divDec6(reserveRealQuote));
    expect(usdcBalance).to.be.at.least(reserveRealQuote);

    console.log("Max WFT Reserve: ", divDec(maxReserve));
    console.log("Max WFT Supply: ", divDec(maxSupply));
    expect(maxReserve).to.be.at.least(maxSupply);

    console.log("Remaining USDC: ", usdcRemaining);
    console.log("Initial USDC: ", await wft.reserveVirtQuoteWad());
    expect(usdcRemaining).to.be.at.least(await wft.reserveVirtQuoteWad());
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, AddressZero);
    console.log(res);
  });

  it("User0 creates content", async function () {
    console.log("******************************************************");
    const uri = "https://wavefront.io/content1";
    await router.connect(user0).createContent(wft.address, uri);
    console.log("- content created");
  });

  it("User1 curates content", async function () {
    console.log("******************************************************");
    const res = await multicall.getContentData(wft.address, 1);
    console.log(res);
    const amount = res.nextPrice;
    await usdc.connect(user1).approve(router.address, amount);
    await router.connect(user1).curateContent(wft.address, 1);
    console.log("- content curated");
  });

  it("User1 curates content", async function () {
    console.log("******************************************************");
    const res = await multicall.getContentData(wft.address, 1);
    console.log(res);
    const amount = res.nextPrice;
    await usdc.connect(user1).approve(router.address, amount);
    await router.connect(user1).curateContent(wft.address, 1);
    console.log("- content curated");
  });

  it("User2 curates content", async function () {
    console.log("******************************************************");
    const res = await multicall.getContentData(wft.address, 1);
    console.log(res);
    const amount = res.nextPrice;
    await usdc.connect(user2).approve(router.address, amount);
    await router.connect(user2).curateContent(wft.address, 1);
    console.log("- content curated");
  });

  it("User0 curates content", async function () {
    console.log("******************************************************");
    const res = await multicall.getContentData(wft.address, 1);
    console.log(res);
    const amount = res.nextPrice;
    await usdc.connect(user0).approve(router.address, amount);
    await router.connect(user0).curateContent(wft.address, 1);
    console.log("- content curated");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("User1 curates content", async function () {
    console.log("******************************************************");
    const res = await multicall.getContentData(wft.address, 1);
    console.log(res);
    const amount = res.nextPrice;
    await usdc.connect(user1).approve(router.address, amount);
    await router.connect(user1).curateContent(wft.address, 1);
    console.log("- content curated");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user1.address);
    console.log(res);
  });

  it("User0 gets content reward", async function () {
    console.log("******************************************************");
    await router.connect(user0).getContentReward(wft.address);
    console.log("- content reward got");
  });

  it("User1 gets content reward", async function () {
    console.log("******************************************************");
    await router.connect(user1).getContentReward(wft.address);
    console.log("- content reward got");
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user0.address);
    console.log(res);
  });

  it("Token Data", async function () {
    console.log("******************************************************");
    let res = await multicall.getTokenData(wft.address, user1.address);
    console.log(res);
  });
});
