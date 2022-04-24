// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Polygon Mainnet Fork
// replace ALCHEMY_URL in .env file
// run : npx hardhat test

///////////////////////////////////////////////////////////////
// TODO : DelegateCall for 

// Aave Contracts Interfaces
import '@aave/core-v3/contracts/interfaces/IPool.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProviderRegistry.sol';
import '@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol';

// Tokens Interfaces
import '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import '@aave/periphery-v3/contracts/misc/interfaces/IWETH.sol';
import '@aave/core-v3/contracts/interfaces/IAToken.sol';
import '@aave/core-v3/contracts/interfaces/IStableDebtToken.sol';
import '@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol';

// Balancer Protocol
import './BalancerPool.sol';
import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";


import "hardhat/console.sol";


contract AaveXBal is BalancerPool {

  // Contracts
  IPool internal pool;
  IPoolAddressesProvider internal constant IPAProvider = IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb); 
  IPoolAddressesProviderRegistry internal constant IPAPRegistry = IPoolAddressesProviderRegistry(0x770ef9f4fe897e59daCc474EF11238303F9552b6);
  IWETHGateway internal constant WETHGateway = IWETHGateway(0x9BdB5fcc80A49640c7872ac089Cc0e00A98451B6);

  // Aave Tokens
  /// address =  WMATIC-AToken-Polygon
  IAToken public constant aToken = IAToken(0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97); 
  /// address = USDC-StableDebtToken-Polygon
  IStableDebtToken public constant debtToken = IStableDebtToken(0x307ffe186F84a3bc2613D1eA417A5737D69A7007);
  ICreditDelegationToken internal constant delegationDebtToken = ICreditDelegationToken(0x307ffe186F84a3bc2613D1eA417A5737D69A7007);

  // ERC20 Tokens
  address public constant matic = 0x0000000000000000000000000000000000001010;
  address public constant wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;


  // uint8 InterestModeSelector;

  address public contractAddress;
  address public userAddress;

  constructor() {
    pool = IPool(GP());

    contractAddress = address(this);
  }


/*_________________________________________________________/
/                      Write Function                     /
/                    /Main (auto)                        /
/______________________________________________________*/

  function startFarming(
    address _DebtToken, // Stable or Variable Debt Token Borrowed 
    address _tokenToSupply, // Initial Pool Supply Funding 
    uint256 _amountToSupply, // Initial Amount to Supply
    address _tokenToBorrow,
    uint256 _amountToBorrow, // Amount to Borrow cf Health Factor
    uint8 _interestRateMode, // 1 = Stable 2 = Variable
    IVault.JoinPoolRequest memory _request 
    ) public payable {

    // /!\ User Must Approve Contract to Spend Relevant Supply Amount of Token From Token Source Contract Before TX
    // /!\ Same For Delegate Borrowing to contract ? (from Debt Token Source Contract)
   
    transferFromToken(_tokenToSupply, msg.sender, address(this), _amountToSupply);
    
    approveMaxSpend(_tokenToSupply, GP());
    //Start Farming (Supply (wMatic) -> Borrow (Usdc) -> Supply Borrowed (Usdc) to Balancer Pool)
    // Supply initial Token To Aave Pool -> Set Collateral for borrowing
    supplyToPool(_tokenToSupply, _amountToSupply, address(this));

    // Borrow Usdc from Aave Pool cf. Health Factor 
    borrowFromPool(_tokenToBorrow, _amountToBorrow, _interestRateMode, address(this));

    joinPool(_poolId, address(this), address(this), _request);


  }
  // address PAYABLE _sender ? \\
  function undoFarm(
    address _tokenToRepay, 
    uint8 _interestRateMode, 
    address _tokenToWithdraw,
    IVault.JoinPoolRequest memory _request 
    ) public {

    exitPool(_poolId, address(this), address(this), _request);

    approveMaxSpend(_tokenToRepay, GP());
 
    // Repay Borrowed Token Aave V3 Pool + Fees from loan;
    repayToPool(_tokenToRepay, type(uint256).max, _interestRateMode, address(this));

    // Withdraw Initial Token + Benefits
    withdrawFromPool(_tokenToWithdraw, type(uint256).max, address(this));

    transferFromToken(_tokenToWithdraw, address(this), msg.sender, msg.value);
  }


/*_________________________________________________________/
/                      Write Function                     /
/                    /Main (mano)                        /
/______________________________________________________*/

  function supplyToPool(address _tokenToSupply, uint256 _amountToSupply, address _onBehalfOfSupply) public payable {
    // Supply _amount of wMatic _onBehalfOfSupply to Aave Pool V3 Protocol
    /// (asset, amount, onBehalfOf, referralCode)
    pool.supply(_tokenToSupply, _amountToSupply, _onBehalfOfSupply, 0);    
  }

  function withdrawFromPool(address _tokenToWithdraw, uint256 _amountToWithdraw, address _to) public payable {
    pool.withdraw(_tokenToWithdraw, _amountToWithdraw, _to);
  }

  function borrowFromPool(address _tokenToBorrow, uint256 _amountToBorrow, uint8 _interestRateMode, address _onBehalfOfBorrow) public payable {
    // Borrow InitialFunds/3 Usdc from Aave Pool
    // (asset, amount, interestRateMode, referralCode, onBehalfOf)
    pool.borrow(_tokenToBorrow, _amountToBorrow, _interestRateMode, 0, _onBehalfOfBorrow);
  }

  function repayToPool(address _tokenToRepay, uint256 _amountToRepay, uint8 _interestRateMode, address _onBehalfOfRepay) public payable {
    pool.repay(_tokenToRepay, _amountToRepay, _interestRateMode, _onBehalfOfRepay);
  }

  //\\ WETHGateway for wrapping native ERC20, using deprecated 'deposit' function instead of 'supply' from pool 
  function dGateDeposit(address _user) public payable{
    WETHGateway.depositETH{value: msg.value}(GP(), _user, 0);
  }

  //\\  WETHGateway BorrowETH (only native ?) 
  function dGateBorrow(uint256 _amount) public {
    WETHGateway.borrowETH(GP(), _amount, 2, 0);
  }

  //\\ WETHGateWay Withdraw Initial native ERC20 supplyied from pool
  function dGateWithdraw(address _user) public {
    WETHGateway.withdrawETH(GP(), type(uint256).max, _user);
  }

/*_________________________________________________________/
/                      Write Function                     /
/                    /Utils                              /
/______________________________________________________*/


function transferFromToken(address _token, address _from, address _to, uint256 _amount) public payable {
  IERC20(_token).transferFrom(_from, _to, _amount);
}

// Wrap / Unwrap Matic
function wrapMatic(address _wTokenAddress) public payable {
  IWETH(_wTokenAddress).deposit{value: msg.value}();
}

function unWrapWMatic(address _wTokenAddress) public payable {
  IWETH(_wTokenAddress).withdraw(msg.value);
}

// Approve Spending / Borrowing of funds 
function approveMaxSpend(address _token, address _spender) public {
  IERC20(_token).approve(_spender, type(uint256).max);
}

// // TX Must Be Sent from Debt Source Contract (msg.sender conflict ?) 
// function approveDelegation(address _DebtToken, address _delegatee, uint256 _amount) public {
//   ICreditDelegationToken(_DebtToken).approveDelegation(_delegatee, _amount);
// }

function setReserveAsCollateral(address _user) public {
  IPool(GP()).setUserUseReserveAsCollateral(_user, true);
}

function setUserAddress() public {
  userAddress = msg.sender;
}

/*________________________________________________________/
/                      Read Function                     /
/______________________________________________________*/

  // Fetch Pool(s)
  function GP() public view returns(address pool_) {
    pool_ = IPAProvider.getPool();
  }

  function getListofPools() public view returns(address[] memory) {
      return IPAPRegistry.getAddressesProvidersList();
  }

  // BalanceOf Tokens
  function getERC20Balance(address _token, address _balanceOf) public view returns(uint256 balance_) {
    balance_ = IERC20(_token).balanceOf(_balanceOf);
  }

  function getDebtTokenBalance(address _debtToken, address _balanceOf) public view returns(uint256 balance_) {
    balance_ = IStableDebtToken(_debtToken).principalBalanceOf(_balanceOf);
  }

  function getERC20Allowance(address _token, address _owner, address _spender) public view returns(uint256 balance_) {
    balance_ = IERC20(_token).allowance(_owner, _spender);
  }

  function getBorrowAllowance(address _debtToken, address _from, address _to) public view returns(uint256 balance_) {
    balance_ = ICreditDelegationToken(_debtToken).borrowAllowance(_from, _to);
  }

  function getUserAccountData(address user) 
      external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    ) {
    return IPool(GP()).getUserAccountData(user); 
  }


}
