const { expect } = require("chai");
var assert = require('chai').assert
const { ethers } = require("hardhat");

const wMaticAbi = require("../contracts/abis/WMATIC.json");



require('chai')
.use(require('chai-as-promised'))
.should()

// Test Balance For Testing
let userAddress;
let contractAddress;
let signer;

// Contract Instance
let aaveXBal;
let wMaticContract;

// Tokens Address
let wMatic = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270';
let aToken = '0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97';
let matic = '0x0000000000000000000000000000000000001010';
let usdc = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
let stabDebtUsdc = '0x307ffe186F84a3bc2613D1eA417A5737D69A7007';

// TX Price Amount
let AMOUNT_1 = ethers.utils.parseEther('1');
let AMOUNT_2 = ethers.utils.parseEther('2');
let AMOUNT_USDC = ethers.utils.parseEther('3');
let AMOUNT_500 = ethers.utils.parseEther('500');
let AMOUNT_1000 = ethers.utils.parseEther('1000');

// Let's play =D 
describe("Testing Aave X Balancer Contracts", async() => {

  before(async() => {

    // /!\ TODO : Test HardHat Signer connect w/ contract instance
    const Signer = await ethers.getSigner();

    console.log(Signer.address, "log Signer")
    signer = await ethers.provider.getSigner(Signer.address);


    // Deploy Contract
    const AaveXBal = await ethers.getContractFactory("AaveXBal", signer);
    aaveXBal = await AaveXBal.deploy();
    await aaveXBal.deployed();

    wMaticContract = await ethers.getContractAt(wMaticAbi, "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", signer);
    await wMaticContract.deployed();

    // Set User and Contract address for input testing
    await aaveXBal.setMsgSender();

    const user = await aaveXBal.msgSender();
    userAddress = user;
    console.log("// ADDRESS ??", signer._address, userAddress);

    const contract = await aaveXBal.contractAddress();
    contractAddress = contract;
  })

  describe("Wrapping Matic for testing", async() => {

    it("Should Wrap 500 Matic for User and Contract Balance", async() => {
      const wMaticUserBalanceBefore = await aaveXBal.getERC20Balance(wMatic, userAddress);
      // console.log("wMatic User Balance :", ethers.utils.formatUnits(wMaticUserBalanceBefore, 18));

      const wMaticContractBalanceBefore = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      // console.log("wMatic Contract Balance :", ethers.utils.formatUnits(wMaticContractBalanceBefore, 18));

      await aaveXBal.wrapMatic({value: AMOUNT_1000});
      await aaveXBal.transferFromToken(wMatic, contractAddress, userAddress, AMOUNT_500);

      const wMaticUserBalanceAfter = await aaveXBal.getERC20Balance(wMatic, userAddress);
      // console.log("wMatic User Balance After TX :", ethers.utils.formatUnits(wMaticUserBalanceAfter, 18));

      const wMaticContractBalanceAfter = await aaveXBal.getERC20Balance(wMatic, contractAddress);
      // console.log("wMatic Contract Balance After TX :", ethers.utils.formatUnits(wMaticContractBalanceAfter, 18));

      assert.isAbove(wMaticContractBalanceAfter, wMaticContractBalanceBefore, "Contract Should be Funded with 500 wMatic");
      assert.isAbove(wMaticUserBalanceAfter, wMaticUserBalanceBefore, "User Should be Funded with 500 wMatic")
    })

  })


  describe("Start on User Behalf Farming", async() => {

    it("User Should Approve Pool MaxSpend", async() => {
      const GP = await aaveXBal.GP();

      const poolwMaticAllowanceBefore = await aaveXBal.getERC20Allowance(wMatic, userAddress, GP);
      console.log("Contract wMatic Allowance of User Funds :", poolwMaticAllowanceBefore);

      await wMaticContract.approve(GP, AMOUNT_500);
  
      const poolwMaticAllowanceAfter = await aaveXBal.getERC20Allowance(wMatic, userAddress, GP);
      console.log("Contract wMatic Allowance of User Funds :", poolwMaticAllowanceAfter);

      assert.isAbove(poolwMaticAllowanceAfter, poolwMaticAllowanceBefore, "Contract wMatic allowance of User Funds should have increase");
    })

    it("User Should deposit 500 wMatic to Pool", async() => {
      const useraTokenBalanceBefore = await aaveXBal.getERC20Balance(aToken, userAddress);

      await aaveXBal.supplyToPool(AMOUNT_500, userAddress);

      const useraTokenBalanceAfter = await aaveXBal.getERC20Balance(aToken, userAddress);

      assert.isAbove(useraTokenBalanceAfter, useraTokenBalanceBefore, "aToken User's Balance should have increase");
    })

    // it("User Should Approve Contract Credit Delegation", async() => {

    // })
  })
});
