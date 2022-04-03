require("hardhat");
var assert = require('chai').assert
const { expect } = require("chai");

// const {IERC20} = require("@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol")

require('chai')
.use(require('chai-as-promised'))
.should()

let POLYGON_WHALE = "0xe5D4fB304A37926e04831B22Fc6aFe931557c883"

// TX Price Amount
let AMOUNT_1 = ethers.utils.parseEther('1');
let AMOUNT_2 = ethers.utils.parseEther('2');
let AMOUNT_USDC = ethers.utils.parseEther('3');
let AMOUNT_500 = ethers.utils.parseEther('500');

// TOFIX
// let account
// function getAccount(){
//   const accounts = await ethers.getSigners()
//   account = await accounts[0].getAddress()

// }
// let signer1 = ethers.provider.getSigner(account);

// Function which allows to convert any address to the signer which can sign transactions in a test
const impersonateAddress = async (address) => {
  const hre = require('hardhat');
  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [address],
  });
  const signer = await ethers.provider.getSigner(address);
  signer.address = signer._address;
  return signer;
};
// Function to increase time in mainnet fork
async function increaseTime(value) {
  if (!ethers.BigNumber.isBigNumber(value)) {
    value = ethers.BigNumber.from(value);
  }
  await ethers.provider.send('evm_increaseTime', [value.toNumber()]);
  await ethers.provider.send('evm_mine');
}
// Construction to get any contract as an object by its interface and address in blockchain
// It is necessary to note that you must add an interface to your project


describe('AaveMoOn Test Contract', () => {
  let aaveMoOn;
  // let maticAddress = "0x0000000000000000000000000000000000001010"

    before(async () => {
      // Load Contract
      const AaveMoOn = await ethers.getContractFactory("AaveMoOn");
      aaveMoOn = await AaveMoOn.deploy();
      await aaveMoOn.deployed();
      impersonateAddress(POLYGON_WHALE);

      // MATIC = await ethers.getContractAt('IERC20', maticAddress);



    });
    describe("GP", async () => {
      it("Should Retrieve Pool", async () => {
        const GP = await aaveMoOn.GP();
        console.log("Pool address ISSSS! :", GP)
        expect(GP).to.include('0x');
      });
    });

    describe("UniSwap ExactInput matic/wMatic", async () => {
      it("Swap from Uniswap", async () => {
        const maticBalance = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalance, 18))

        const wMaticBalance = await aaveMoOn.wMaticBalance();
        console.log("wMatic funds available :", ethers.utils.formatUnits(wMaticBalance, 18));

        const swapExactInputSingle = await aaveMoOn.swapExactInputSingle(AMOUNT_1);

        const maticBalanceAfter = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalanceAfter, 18))

        const wMaticBalanceAfter = await aaveMoOn.wMaticBalance();
        console.log("wMatic funds available :", ethers.utils.formatUnits(wMaticBalanceAfter, 18));


        assert.isAbove(wMaticBalanceAfter, wMaticBalance, "Balance should increase");
      });
    });

    describe("Wrap Matic from wMatic Contract", async () => {
      it("Try to wrap from Matic Contract", async () => {

        const maticBalance = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalance, 18))

        const wrapMatic = await aaveMoOn.wrapMatic({value: AMOUNT_1});

        const maticBalanceAfter = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalanceAfter, 18))
        
        assert.isBelow(maticBalanceAfter, maticBalance, "Balance should Decrease");
      });
    });


    // describe("wMatic Balance has to be funded", async () => {
    //   it("Fetch wMatic Balance from contract", async () => {
    //     const wMaticBalance = await aaveMoOn.wMaticBalance();
    //     console.log("wMatic funds available :", ethers.utils.formatUnits(wMaticBalance, 18))
    //     assert.isAtLeast(wMaticBalance, 1, "greater or equal to 1");
    //   });
    // });

    // describe("Matic Funds", async () => {
    //   it("Fetch Matic Balance from contract", async () => {
    //     const maticBalance = await aaveMoOn.maticBalance();
    //     console.log("Matic funds available :", ethers.utils.formatUnits(maticBalance, 18))
    //     assert.isAtLeast(maticBalance, 1, "greater or equal to 1");
    //   });
    // });


    describe("Approve wMatic allowance", async () => {
      it("allow 1 token to Pool / WETHGateway", async () => {
        const approveWMatic = await aaveMoOn.approveWMatic(AMOUNT_1);
        // assert.equal(approveSupply, true);
        assert.isAtLeast(approveWMatic, 1, "greater or equal to 1");

      });
    });

    describe("Approve Matic allowance", async () => {
      it("allow 1 token to Pool / WETHGateway", async () => {
        const approveMatic = await aaveMoOn.approveMatic(AMOUNT_1);
        // assert.equal(approveSupply, true);
        assert.isAtLeast(approveMatic, 1, "greater or equal to 1");

      });
    });

    describe("WETHGateWay Deposit", async () => {
      it("Should Deposit Native Matic to Aave V3 WETHGateway", async () => {
        const maticBalance = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalance, 18))

        const dGateDeposit = await aaveMoOn.dGateDeposit({value: AMOUNT_1});

        const maticBalanceAfter = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalanceAfter, 18))
        assert.isBelow(maticBalanceAfter, maticBalance, "Balance Should Decrease");

      });
    });

    describe("Supply from Pool Contract", async () => {
      it("Should Deposit WMatic to V3 Pool Contract", async () => {
        // await aaveMoOn.approveSupply(AMOUNT_1);

        const maticBalance = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalance, 18))

        const wMaticBalance = await aaveMoOn.wMaticBalance();
        console.log("wMatic funds available :", ethers.utils.formatUnits(wMaticBalance, 18));

        const letsDoItFrens = await aaveMoOn.letsDoItFrens(AMOUNT_1);

        const maticBalanceAfter = await aaveMoOn.maticBalance();
        console.log("Matic funds available :", ethers.utils.formatUnits(maticBalanceAfter, 18))

        const wMaticBalanceAfter = await aaveMoOn.wMaticBalance();
        console.log("wMatic funds available :", ethers.utils.formatUnits(wMaticBalanceAfter, 18));

        // assert.equal(letsDoItFrens, true);
        assert.isTrue(letsDoItFrens, 'Supply succeed');

      });
    });
});
