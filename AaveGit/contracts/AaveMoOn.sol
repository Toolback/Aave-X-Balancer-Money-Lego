pragma solidity ^0.8.10;
pragma abicoder v2;


import '@aave/core-v3/contracts/interfaces/IPool.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProviderRegistry.sol';


import '@aave/periphery-v3/contracts/misc/interfaces/IWETH.sol';
import '@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol';
import '@aave/core-v3/contracts/interfaces/IAToken.sol';
import '@aave/core-v3/contracts/interfaces/IStableDebtToken.sol';
import '@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol';
import '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';



// Polygon MainNET Fork
contract AaveMoOn {
    //Uniswap 
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Wrong Polygon address ?

    // Contracts
    IPoolAddressesProvider public constant IPAProvider = IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb); 
    IPoolAddressesProviderRegistry public constant IPAPRegistry = IPoolAddressesProviderRegistry(0x770ef9f4fe897e59daCc474EF11238303F9552b6);
    IWETHGateway public constant WETHGateway = IWETHGateway(0x9BdB5fcc80A49640c7872ac089Cc0e00A98451B6);

    // Aave Tokens
    //wMatic
    IAToken public constant aToken = IAToken(0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97); 
    // usdc Stable Debt Token
    IStableDebtToken public constant debtToken = IStableDebtToken(0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E);
    ICreditDelegationToken public constant delegationDebtToken = ICreditDelegationToken(0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E);

    bool useAsCollateral = true;

    // ERC20 Tokens
    address public constant wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant matic = 0x0000000000000000000000000000000000001010;

    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    //Uniswap 
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant WETH9 = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    // Fee Swap
    uint24 public constant poolFee = 3000;



    // TX Price Amount
    uint256 AMOUNT_1 = 1 * 1e18;
    uint256 AMOUNT_USDC = 3 * 1e18;
    uint256 AMOUNT_500 = 500 * 1e18;

    uint256 public contractBalance;

    constructor() {

        // Allow Contract allowance (?)
        approveMaxSpend(usdc, address(this));
        // approveMaxSpend(matic, address(this));
        approveMaxSpend(wMatic, address(this));
        approveMaxSpend(address(aToken), address(this)); 

        // Approve Aave V3 Pool allowance
        approveMaxSpend(usdc, GP());
        // approveMaxSpend(matic, GP());
        approveMaxSpend(wMatic, GP());
        // approveMaxSpend(address(debtToken), GP());
        approveMaxSpend(address(aToken), GP()); 

        // Approve Aave V3 wEthGateway allowance
        approveMaxSpend(usdc, address(WETHGateway));
        // approveMaxSpend(matic, GP());
        approveMaxSpend(wMatic, address(WETHGateway));
        // approveMaxSpend(address(debtToken), GP());
        approveMaxSpend(address(aToken), address(WETHGateway)); 

        // Approve Uniswap allowance
        
        // approveMaxSpend(usdc, GP());
        // approveMaxSpend(matic, address(swapRouter));
        approveMaxSpend(wMatic, address(swapRouter));
        approveMaxSpend(address(aToken), address(swapRouter)); 


        approveDelegation(500e18);
    }

/*________________________________________________________/
/                      Read Function                     /
/______________________________________________________*/

    //\\ PoolAddressProviderRegistry : fetch All Deployed Pools Address 
    function getListofPools() public view returns(address[] memory) {
        return IPAPRegistry.getAddressesProvidersList();
    }

    //\\ PoolAddressProvider: Fetch current selected Pool Address
    function GP() public view returns(address) {
        return IPAProvider.getPool();
    }

    function wMaticAllowanceAave() public view returns(uint256 allowance_) {
        allowance_ = IERC20(wMatic).allowance(msg.sender, GP());
    }

    //\\ AToken : Fetch user aToken Balance
    function ATokenData() public view returns(uint256){
        IAToken ATokenDataBalance = IAToken(IPool(GP()).getReserveData(wMatic).aTokenAddress);
        return ATokenDataBalance.balanceOf(msg.sender);
    }
    ///[V] Success

    function wMaticBalance() public view returns(uint256 balance_) {
        balance_ =  IERC20(wMatic).balanceOf(msg.sender);
    }

    function maticBalance() public view returns(uint256 balance_) {
        balance_ =  IERC20(matic).balanceOf(msg.sender);
    }

    function usdcBalance() public view returns(uint256 balance_) {
        balance_ =  IERC20(usdc).balanceOf(msg.sender);
    }

    function aTokenBalance() public view returns(uint256 balance_) {
        balance_ =  aToken.balanceOf(msg.sender);
    }

    function debtTokenBalance() public view returns(uint256 balance_) {
        balance_ =  debtToken.principalBalanceOf(msg.sender);
    }

    function borrowAllowanceBalance() public view returns(uint256 balance_) {
        balance_ = delegationDebtToken.borrowAllowance(msg.sender, address(this));
    }
    
    // function getWethAddress() public view returns(address) {
    //     return WETHGateway.getWETHAddress();
    // }

    // Not Found ? 

/*_________________________________________________________/
/                      Write Function                     /
/                    /Utils                              /
/______________________________________________________*/



    function approveMaxSpend(address token, address spender) internal {
        IERC20(token).approve(spender, type(uint256).max);
    }

    function approveDelegation(uint256 amount) public {
        delegationDebtToken.approveDelegation(address(this), amount);
        // delegationDebtToken.approveDelegation(GP(), amount);
        delegationDebtToken.approveDelegation(msg.sender, amount);

    }

    //\\ Pool : Set User selected Reserve as collateral for borrowing 
    function setReserveAsCollateral() public returns(bool) {
        IPool(GP()).setUserUseReserveAsCollateral(wMatic, true);
        return true;
    }
    /// [X] TX reverted 

    function transferWMaticToContract(uint256 amount) public payable returns(uint256 balance_) {
        IWETH(wMatic).transferFrom(msg.sender, address(this), amount);
        balance_ = IERC20(wMatic).balanceOf(address(this));
    }

    //\\ ERC20 : Wrap nativeMatic from source contract 
    function wrapMatic() public payable returns(uint256 balance_) {
        IERC20(wMatic).deposit{value: msg.value}();
        balance_ = wMaticBalance();
    }
    /// [X] TX reverted 


    //\\ ERC 20 : Unwrap wrappedMatic from source contract    
    function unwrapMatic() public payable returns(uint256 balance_) {
        IERC20(wMatic).withdraw(type(uint).max);
        balance_ = maticBalance();
    }
    /// [X] TX reverted 



/*_________________________________________________________/
/                      Write Function                     /
/                    /Main                               /
/______________________________________________________*/

    //\\ WETHGateway for wrapping native ERC20, using deprecated 'deposit' function instead of 'supply' from pool 
    function dGateDeposit() public payable returns(uint256 dGateDeposit_) {
        WETHGateway.depositETH{value: msg.value}(GP(), msg.sender, 0);
        dGateDeposit_ = ATokenData();
        // IPool(GP()).setUserUseReserveAsCollateral(wMatic, true);
    }
    /// [V] Success : Wrap and deposit successfully native Matic on selected Pool 
    ///(still need to check user's balance/allowance on selected pool to be sure)


    //\\  WETHGateway BorrowETH (only native ?) 
    function dGateBorrow(uint256 _amount) public {
        WETHGateway.borrowETH(GP(), _amount, 2, 0);
    }
    // [X] TX reverted 


    //\\ WETHGateWay Withdraw Initial native ERC20 supplyied from pool
    function dGateWithdraw() public {

        WETHGateway.withdrawETH(GP(), type(uint256).max, msg.sender);
    }
    /// [X] TX reverted


    //\\ Pool : Trying to borrow Usdc from Aave v3 Pool 
    function borrowUsdcFromPool(uint256 _amount) public {
        // Allow Contract spending (?)
        // approveMaxSpend(usdc, address(this));
        // // approveMaxSpend(matic, address(this));
        // approveMaxSpend(wMatic, address(this));
        // approveMaxSpend(address(aToken), address(this)); 

        // // Approve Aave V3 Pool allowance
        // approveMaxSpend(usdc, GP());
        // // approveMaxSpend(matic, GP());
        // approveMaxSpend(wMatic, GP());
        // // approveMaxSpend(address(debtToken), GP());
        // approveMaxSpend(address(aToken), GP()); 


        // Allow Contract Credit Delegation
        approveDelegation(_amount);

        // USDC borrowing from contract to pool 
        IPool(GP()).borrow(usdc, _amount, 1, 0, msg.sender);
    }
    /// [X] TX reverted (Wrong Token/Pool Address ? Reserve not set as collat ? Not allowed to dispose of funds ?) 

    //\\ Pool : Trying to supply Matic to Aave v3 Pool 
    function supplyWMaticToPool(uint256 _amount) public { 
        IPool(GP()).supply(wMatic, _amount, msg.sender, 0);
    }
    /// [X] TX reverted (Approval Needed ? Wrong ERC20 Address ?)





    /* //\\ Supply Funds
        - Supply ERC20 Matic to Aave V3 Polygon Pool
        - Borrow 200% collat USDC from pool
        - Supply borrowed USDC from Aave to Balancer Pool 
    */    
    function letsDoItFrens(uint256 _amount) public payable returns(uint256 tokenData_){
        IPool pool = IPool(GP());
        approveMaxSpend(wMatic, address(this));
        approveMaxSpend(wMatic, msg.sender);
        approveMaxSpend(wMatic, GP());

        approveMaxSpend(address(aToken), address(this));
        approveMaxSpend(address(aToken), msg.sender);
        approveMaxSpend(address(aToken), GP());

        approveDelegation(500e18);

        // transferWMaticToContract(_amount);


        
        // TransferHelper.safeTransferFrom(wMatic, msg.sender, address(this), _amount);


        pool.supply(wMatic, _amount, msg.sender, 0);

        // setReserveAsCollateral(wMatic);
        
        // pool.borrow(usdc, AMOUNT_USDC, 1, 0, msg.sender);

        // Deposit borrowed USDC to Pool Balancer MAI/USDC/DAI/USDT

        tokenData_ = ATokenData();

    }
    /// [X] Reverted 
        


    /* //\\ Withdraw Funds w/ Benefits
        - Withdraw Borrowed USDC off Balancer Pools
        - Repay borrowed USDC from Aave, free AToken
        - Withdraw initials funds, payback AToken 
    */  
    function canWeUndo() public {
        IPool pool = IPool(GP());


        // Withdraw lended USDC from Balancer Pool;

        pool.repay(usdc, type(uint).max, 1, msg.sender); // repay borrowed USDC -> free matic collateral

        pool.withdraw(wMatic, type(uint).max, msg.sender);

        // unwrapMatic();
    }
    /// [X] Reverted


    //\\ Uniswap 

    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // TransferHelper.safeApprove(matic, address(swapRouter), amountIn);
        // TransferHelper.safeApprove(matic, address(this), amountIn);
        TransferHelper.safeApprove(matic, address(this), amountIn);

        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(matic, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(matic, address(swapRouter), amountIn);
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: matic,
                tokenOut: wMatic,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }


}
