const { expect } = require("chai");
var assert = require('chai').assert
const { ethers } = require("hardhat");

const wMaticAbi = require("../contracts/abis/WMATIC.json");

// Uniswap 

// const {Pool} = require("@uniswap/v3-sdk")
// const { Token } = require('@uniswap/sdk-core')
// const { IUniswapV3PoolABI } =  require('@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json')

// require( "hardhat/console.sol");

require('chai')
  .use(require('chai-as-promised'))
  .should()

// Test Balance For Testing
let userAddress;
let contractAddress;
let Signer;
let signer;
// Contract Instance
let aaveXBal;
let bptContract;
let GP;
let wMaticContract;

let balancerPoolAddress = "0x06df3b2bbb68adc8b0e302443692037ed9f91b42"

// Tokens Address
let wMatic = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270';
let usdc = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';

// TX Price Amount
let AMOUNT_USDC = ethers.BigNumber.from("500000000");
let AMOUNT_USDC5 = ethers.BigNumber.from("5");
let AMOUNT_USDCOUT = ethers.BigNumber.from("400000000");
// let USDCAMOUNTTEST = BigNumberish('5');
// console.log("BIGNUMBERISH", USDCAMOUNTTEST)
let AMOUNT_400 = ethers.utils.parseEther('400');
let AMOUNT_500 = ethers.utils.parseEther('500');
let AMOUNT_700 = ethers.utils.parseEther('700');
let AMOUNT_WMATICOUT = ethers.utils.parseEther('300')

let AMOUNT_1000 = ethers.utils.parseEther('1000');

// const uniswapPoolAddress = ""



// Let's play =D 
describe("Testing Aave X Balancer Contracts", async () => {

  before(async () => {
    Signer = await ethers.getSigner();

    // console.log(Signer.address, "Signer details")
    signer = await ethers.provider.getSigner(Signer.address);

    // console.log("signer details" ,signer, "END signer");

    // Deploy Contract
    const AaveXBal = await ethers.getContractFactory("AaveXBal", Signer);
    aaveXBal = await AaveXBal.deploy();
    await aaveXBal.deployed();
    // console.log(aaveXBal, "aaveXBAL : details")

    // Balancer Pool
    bptContract = new ethers.Contract(balancerPoolAddress, wMaticAbi, Signer);
    await bptContract.deployed()

    wMaticContract = new ethers.Contract(wMatic, wMaticAbi, Signer)
    await wMaticContract.deployed();

    // Set User and Contract address for input testing
    await aaveXBal.setUserAddress();

    const user = await aaveXBal.userAddress();
    userAddress = user;

    const contract = await aaveXBal.contractAddress();
    contractAddress = contract;

    GP = await aaveXBal.GP();


  })

  describe("Wrapping Matic for testing", async () => {

    it("Should Wrap 500 Matic for User and Contract Balance", async () => {
      const wMaticUserBalanceBefore = await aaveXBal.getERC20Balance(wMatic, userAddress);
      // console.log("wMatic User Balance :", ethers.utils.formatUnits(wMaticUserBalanceBefore, 18));

      await aaveXBal.wrapMatic(wMatic, { value: AMOUNT_1000 });

      const wMaticUserBalanceAfter = await aaveXBal.getERC20Balance(wMatic, userAddress);
      console.log("wMatic User Balance After TX :", ethers.utils.formatUnits(wMaticUserBalanceAfter, 18));

      assert.isAbove(wMaticUserBalanceAfter, wMaticUserBalanceBefore, "User Should be Funded with 1000 wMatic")
    })

    it("Should transfer Initial Amout to Contract", async () => {
      const wMaticContractBalanceBefore = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      console.log("wMatic Contract Balance Before TX :", ethers.utils.formatUnits(wMaticContractBalanceBefore, 18));

      await wMaticContract.transferFrom(userAddress, contractAddress, AMOUNT_1000)

      const wMaticContractBalanceAfter = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      console.log("wMatic Contract Balance After TX :", ethers.utils.formatUnits(wMaticContractBalanceAfter, 18));

      assert.isAbove(wMaticContractBalanceAfter, wMaticContractBalanceBefore, "User Should be Funded with 1000 wMatic")

    })
  })


  describe("Start Supply and Borrowing to Aave Pool", async () => {
    it("Should start Farming", async () => {

      const usdcBalanceBefore = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("Contract Balance USDC Before Repay :", usdcBalanceBefore);

      const interestRateMode = 1;

      await aaveXBal.startAaveLoop(wMatic, usdc, AMOUNT_1000, AMOUNT_USDC, interestRateMode);

      const wMaticContractBalanceAfter = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      console.log("wMatic Contract Balance After TX :", ethers.utils.formatUnits(wMaticContractBalanceAfter, 18));

      const usdcContractBalanceAfter = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("USDC Contract Balance After TX :", ethers.utils.formatUnits(usdcContractBalanceAfter, 6));

      assert.isAbove(usdcContractBalanceAfter, usdcContractBalanceBefore, "Usdc Borrowed Amount Should have Increase" )
    })
  })

  describe("Quit Supplying / Borrowing Loop", async => {

    it("Should Swap wMatic for USDC", async () => {
      const usdcBalanceBefore = await aaveXBal.getERC20Balance(usdc, userAddress);
      console.log("User Balance USDC Before swapping :", usdcBalanceBefore)

      // TODO : Uniswap wMatic => USDC for collat wear 

      const usdcBalanceAfter = await aaveXBal.getERC20Balance(usdc, userAddress);
      console.log("User Balance USDC After swapping :", usdcBalanceAfter)

      // assert.isAbove(usdcBalanceAfter, usdcBalanceBefore, "USDC Balance should have increase");
    })

    it("Should Undo Farm", async () => {
      const userContractBalance = await aaveXBal.userBalance(userAddress, wMatic);
      console.log("User's contract balance Before Repay : ", userContractBalance);

      const usdcBalanceBefore = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("Contract Balance USDC Before Repay :", usdcBalanceBefore);

      const wMaticUserBalanceBefore = await aaveXBal.getERC20Balance(wMatic, userAddress);
      console.log("wMatic User Balance Before Stop :", ethers.utils.formatUnits(wMaticUserBalanceBefore, 18));

      // Aave Var
      const interestRateMode = 1;

      await aaveXBal.stopAaveLoop(usdc, wMatic, AMOUNT_USDCOUT, AMOUNT_WMATICOUT, AMOUNT_WMATICOUT, interestRateMode);

      const userContractBalanceAfter = await aaveXBal.userBalance(userAddress, wMatic);
      console.log("User's contract balance After Repay : ", userContractBalanceAfter);

      const usdcBalanceAfter = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("Contract Balance USDC After Repay :", usdcBalanceAfter);

      const wMaticUserBalanceAfter = await aaveXBal.getERC20Balance(wMatic, userAddress);
      console.log("wMatic User Balance After Stop :", ethers.utils.formatUnits(wMaticUserBalanceAfter, 18));

      assert.isBelow(usdcBalanceAfter, usdcBalanceBefore, "Should have decrease");
      assert.isAbove(wMaticUserBalanceAfter, wMaticUserBalanceBefore, "User Should have been repaid")
    })
  })
})
