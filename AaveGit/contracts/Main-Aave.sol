pragma solidity ^0.8.0;
pragma abicoder v2;

// Polygon Mainnet Fork
// replace ALCHEMY_URL in .env file
// run : npx hardhat test

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


contract AaveXBal {

  // Contracts
  IPool public pool;
  IPoolAddressesProvider public constant IPAProvider = IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb); 
  IPoolAddressesProviderRegistry public constant IPAPRegistry = IPoolAddressesProviderRegistry(0x770ef9f4fe897e59daCc474EF11238303F9552b6);
  IWETHGateway public constant WETHGateway = IWETHGateway(0x9BdB5fcc80A49640c7872ac089Cc0e00A98451B6);

  // Aave Tokens
  /// address =  WMATIC-AToken-Polygon
  IAToken public constant aToken = IAToken(0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97); 
  /// address = USDC-StableDebtToken-Polygon
  IStableDebtToken public constant debtToken = IStableDebtToken(0x307ffe186F84a3bc2613D1eA417A5737D69A7007);
  ICreditDelegationToken public constant delegationDebtToken = ICreditDelegationToken(0x307ffe186F84a3bc2613D1eA417A5737D69A7007);

  // ERC20 Tokens
  address public constant matic = 0x0000000000000000000000000000000000001010;
  address public constant wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

  address public msgSender;
  address public contractAddress;

  uint8 InterestModeSelector;

  constructor() {
    contractAddress = address(this);
    pool = IPool(GP());
  }


/*_________________________________________________________/
/                      Write Function                     /
/                    /Main (auto)                        /
/______________________________________________________*/

  function startFarming(
    uint256 _amountToSupply, 
    address _onBehalfOfSupply, 
    uint8 _interestRateMode, 
    address _onBehalfOfBorrow
    ) public payable {
    // Approve Spending && Borrowing
    approveMaxSpend(wMatic, _onBehalfOfSupply);
    approveDelegation(_onBehalfOfSupply, _amountToSupply);

    //Start Farming (Supply wMatic -> Borrow Usdc -> Supply Borrowed Usdc)
    supplyToPool(_amountToSupply, _onBehalfOfSupply);
    uint256 amountToBorrow = _amountToSupply / 3;
    borrowFromPool(amountToBorrow, _interestRateMode, _onBehalfOfBorrow);

    InterestModeSelector = _interestRateMode;
  }

  function undoFarm(address _onBehalfOfRepay, address _to) public {
    repayToPool(type(uint256).max, InterestModeSelector, _onBehalfOfRepay);

    withdrawFromPool(type(uint256).max, _to);
  }


/*_________________________________________________________/
/                      Write Function                     /
/                    /Main (mano)                        /
/______________________________________________________*/

  function supplyToPool(uint256 _amountToSupply, address _onBehalfOfSupply) public payable {
    // Supply _amount of wMatic _onBehalfOfSupply to Aave Pool V3 Protocol
    /// (asset, amount, onBehalfOf, referralCode)
    pool.supply(wMatic, _amountToSupply, _onBehalfOfSupply, 0);    
  }

  function withdrawFromPool(uint256 _amountToWithdraw, address _to) public payable {
    pool.withdraw(wMatin, _amountToWithdraw, _to);
  }

  function borrowFromPool(uint256 _amountToBorrow, uint8 _interestRateMode, address _onBehalfOfBorrow) public payable {
    // Borrow InitialFunds/3 Usdc from Aave Pool
    // (asset, amount, interestRateMode, referralCode, onBehalfOf)
    pool.borrow(usdc, _amountToBorrow, _interestRateMode, 0, _onBehalfOfBorrow);
  }

  function repayToPool(uint256 _amountToRepay, uint8 _interestRateMode, address _onBehalfOfRepay) public payable {
    pool.repay(usdc, _amountToRepay, _interestRateMode, _onBehalfOfRepay);
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
function wrapMatic() public payable {
  IERC20(wMatic).deposit{value: msg.value}();
}

function unWrapWMatic() public payable {
  IERC20(wMatic).withdraw(type(uint256).max);
}

// Approve Spending / Borrowing of funds 
function approveMaxSpend(address _token, address _spender) public {
  IERC20(_token).approve(_spender, type(uint256).max);
}

function approveDelegation(address _delegatee, uint256 _amount) public {
  delegationDebtToken.approveDelegation(_delegatee, _amount);
}

function setReserveAsCollateral(address _user) public {
  IPool(GP()).setUserUseReserveAsCollateral(_user, true);
}

//!\ For testing
function setMsgSender() public returns(address msgSender_) {
  msgSender_ = msg.sender;
}

/*________________________________________________________/
/                      Read Function                     /
/______________________________________________________*/

  // Fetch Pool(s)
  function GP() internal view returns(address pool_) {
    pool_ = IPAProvider.getPool();
  }

  function getListofPools() public view returns(address[] memory) {
      return IPAPRegistry.getAddressesProvidersList();
  }

  // BalanceOf Tokens
  function getERC20Balance(address _token, address _balanceOf) public view returns(uint256 balance_) {
    balance_ = IERC20(_token).balanceOf(_balanceOf);
  }

  function getDebtTokenBalance(address _balanceOf) public view returns(uint256 balance_) {
    balance_ = debtToken.principalBalanceOf(_balanceOf.sender);
  }

  function getERC20Allowance(address _token, address _from, address _to) public view returns(uint256 balance_) {
    balance_ = IERC20(_token).allowance(_from, _to);
  }

  function getBorrowAllowance(address _from, address _to) public view returns(uint256 balance_) {
    balance_ = delegationDebtToken.borrowAllowance(_from, _to);
  }

}
