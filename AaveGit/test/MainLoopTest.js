const { expect } = require("chai");
var assert = require('chai').assert
const { ethers } = require("hardhat");

const wMaticAbi = require("../contracts/abis/WMATIC.json");

const { StablePoolEncoder } = require("@balancer-labs/balancer-js");


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
let usdcContract;
let wMaticContract;


let balancerPoolAddress = "0x06df3b2bbb68adc8b0e302443692037ed9f91b42"
let balancerPoolId = "0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000012"
let vaultAddress = "0xBA12222222228d8Ba445958a75a0704d566BF2C8"
let bptToken = "0x06df3b2bbb68adc8b0e302443692037ed9f91b42"

// Tokens Address
let wMatic = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270';
let usdc = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
let dai = '0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063';
let mai = '0xa3Fa99A148fA48D14Ed51d610c367C61876997F1';
let usdt = '0xc2132D05D31c914a87C6611C10748AEb04B58e8F';

// TX Price Amount
let AMOUNT_USDC = ethers.BigNumber.from("500000000");
let AMOUNT_USDC5 = ethers.BigNumber.from("5");
let AMOUNT_USDCOUTAAVE = ethers.BigNumber.from("400000000");
let AMOUNT_USDCOUTBALANCER = ethers.BigNumber.from("100000000");

// let USDCAMOUNTTEST = BigNumberish('5');
// console.log("BIGNUMBERISH", USDCAMOUNTTEST)
let AMOUNT_200 = ethers.utils.parseEther('200');
let AMOUNT_500 = ethers.utils.parseEther('500');
let AMOUNT_700 = ethers.utils.parseEther('700');
let AMOUNT_WMATICOUT = ethers.utils.parseEther('300')
let AMOUNT_WMATICOUT2 = ethers.utils.parseEther('2')

let AMOUNT_1000 = ethers.utils.parseEther('1000');

let AMOUNT_BPT_APPROVE = ethers.utils.parseEther('100')
let AMOUNT_BPT_OUT = ethers.utils.parseEther('100')

let interestRateMode = 1;

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

    usdcContract = new ethers.Contract(usdc, wMaticAbi, Signer);
    await usdcContract.deployed();

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

      assert.isAbove(wMaticContractBalanceAfter, wMaticContractBalanceBefore, "Contract Should be Funded with 1000 wMatic")

    })
  })


  describe("Start Supply and Borrowing to Aave Pool", async () => {
    it("Should start Aave Pool Farming", async () => {

      const usdcBalanceBefore = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("Contract Balance USDC Before Repay :", usdcBalanceBefore);

      await aaveXBal.startAaveLoop(wMatic, usdc, AMOUNT_1000, AMOUNT_USDC, interestRateMode);

      const wMaticContractBalanceAfter = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      console.log("wMatic Contract Balance After TX :", ethers.utils.formatUnits(wMaticContractBalanceAfter, 18));

      const usdcContractBalanceAfter = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("USDC Contract Balance After TX :", ethers.utils.formatUnits(usdcContractBalanceAfter, 6));

      assert.isAbove(usdcContractBalanceAfter, usdcBalanceBefore, "Usdc Borrowed Amount Should have Increase")
    })
  })

  describe("Quit Supplying / Borrowing of Aave Loop", async => {

    it("Should Undo Aave Pool Farm", async () => {
      const userContractBalance = await aaveXBal.userBalance(userAddress, wMatic);
      console.log("User's contract balance Before Repay : ", userContractBalance);

      const usdcBalanceBefore = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("Contract Balance USDC Before Repay :", usdcBalanceBefore);

      const wMaticUserBalanceBefore = await aaveXBal.getERC20Balance(wMatic, userAddress);
      console.log("wMatic User Balance Before Stop :", ethers.utils.formatUnits(wMaticUserBalanceBefore, 18));

      await aaveXBal.stopAaveLoop(usdc, wMatic, AMOUNT_USDCOUTAAVE, AMOUNT_WMATICOUT, AMOUNT_WMATICOUT, interestRateMode);

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

  describe("It Should Start Aave X Balancer Loop", async () => {
    it("Should transfer Initial Amout to Contract to start Balancer Loop", async () => {
      const wMaticUserBalanceBefore = await aaveXBal.getERC20Balance(wMatic, userAddress);
      console.log("wMatic User Balance Before Balancer Loop TX :", ethers.utils.formatUnits(wMaticUserBalanceBefore, 18));

      const wMaticContractBalanceBefore = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      console.log("wMatic Contract Balance Before Balancer Loop TX :", ethers.utils.formatUnits(wMaticContractBalanceBefore, 18));

      await wMaticContract.transferFrom(userAddress, contractAddress, AMOUNT_200)

      const wMaticContractBalanceAfter = await aaveXBal.getERC20Balance(wMatic, userAddress);
      console.log("wMatic Contract Balance After TX :", ethers.utils.formatUnits(wMaticContractBalanceAfter, 18));

      assert.isAbove(wMaticContractBalanceAfter, wMaticContractBalanceBefore, "Contract Should be Funded with 1000 wMatic")

    })

    it("Should Start Balancer Farming", async () => {
      const tokens = [usdc, dai, mai, usdt]
      const amountsIn = [AMOUNT_USDC, 0, 0, 0];
      const minimumBPT = 0;
      const encodedData = StablePoolEncoder.joinExactTokensInForBPTOut(amountsIn, minimumBPT);

      const request = { assets: tokens, maxAmountsIn: amountsIn, userData: encodedData, fromInternalBalance: false };
      
      await aaveXBal.approveMaxSpend(usdc, "0xBA12222222228d8Ba445958a75a0704d566BF2C8")

      await aaveXBal.startBalancerLoop(wMatic, usdc, vaultAddress, AMOUNT_200, AMOUNT_USDC, interestRateMode, balancerPoolId, request);

      const userBptBalanceAfter = await aaveXBal.getERC20Balance(bptToken, contractAddress);
      // console.log("User BPT Balance After Borrowing:", ethers.utils.formatUnits(userBptBalanceAfter, 18));
      console.log("BPT Balance After Depositing usdc in Balancer Pool;", ethers.utils.formatUnits(userBptBalanceAfter, 18));

      const wMaticContractBalanceAfter = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      console.log("wMatic Contract Balance After TX :", ethers.utils.formatUnits(wMaticContractBalanceAfter, 18));

      const wMaticUserBalanceAfter = await aaveXBal.getERC20Balance(wMatic, userAddress);
      console.log("wMatic User Balance After TX :", ethers.utils.formatUnits(wMaticUserBalanceAfter, 18));

      const usdcBalanceAfter = await aaveXBal.getERC20Balance(usdc, userAddress);
      console.log("User Balance USDC After Borrowing :", ethers.utils.formatUnits(usdcBalanceAfter, 6))

      const usdccontractBalanceAfter = await aaveXBal.getERC20Balance(usdc, contractAddress);
      console.log("contract Balance USDC After Borrowing :", ethers.utils.formatUnits(usdccontractBalanceAfter, 6))
    })

    
    // it("Should Swap wMatic for USDC to repay collateral wear", async () => {
    //   const usdcBalanceBefore = await aaveXBal.getERC20Balance(usdc, userAddress);
    //   console.log("User Balance USDC Before swapping :", usdcBalanceBefore)

    //   // TODO : Uniswap wMatic => USDC for collat wear 

    //   const usdcBalanceAfter = await aaveXBal.getERC20Balance(usdc, userAddress);
    //   console.log("User Balance USDC After swapping :", usdcBalanceAfter)

    //   // assert.isAbove(usdcBalanceAfter, usdcBalanceBefore, "USDC Balance should have increase");
    // })

    it("Should Quit Balancer Loop", async () => {

      const userBptBalanceBefore = await aaveXBal.getERC20Balance(bptToken, userAddress);
      console.log("userBptBalanceBefore:", userBptBalanceBefore)

      const tokens = [usdc, dai, mai, usdt]
      const amountsOut = [0, 0, 0, 0];
      const bptAmountsIn = AMOUNT_BPT_OUT;
      const tokenIndex = 0;
      const encodedData = StablePoolEncoder.exitExactBPTInForOneTokenOut(bptAmountsIn, tokenIndex);

      const request = { assets: tokens, minAmountsOut: amountsOut, userData: encodedData, toInternalBalance: false };
      await aaveXBal.stopBalancerLoop(usdc, wMatic, vaultAddress, AMOUNT_USDCOUTBALANCER, AMOUNT_WMATICOUT2, AMOUNT_WMATICOUT2, interestRateMode, balancerPoolId, request);
      
      const userBptBalanceAfter = await aaveXBal.getERC20Balance(bptToken, userAddress);
      console.log("User BPT Balance After Borrowing:", ethers.utils.formatUnits(userBptBalanceAfter, 18));
    })
  })
})
