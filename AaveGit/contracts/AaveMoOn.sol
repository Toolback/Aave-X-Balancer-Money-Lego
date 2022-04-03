pragma solidity ^0.8.10;
pragma abicoder v2;


import '@aave/core-v3/contracts/interfaces/IPool.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProviderRegistry.sol';


import '@aave/periphery-v3/contracts/misc/interfaces/IWETH.sol';
import '@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol';
import '@aave/core-v3/contracts/interfaces/IAToken.sol';
import '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

// import 'https://github.com/balancer-labs/balancer-v2-monorepo/blob/weighted-deployment/contracts/vault/interfaces/IVault.sol';

interface IERC20Faucet {
    /**
     * @dev Proxy function to mint Testnet tokens to msg.sender
     * @param _token The address of the token
     * @param _amount The amount to mint
     * @return The amount minted
     **/
    function mint(address _token, uint256 _amount) external returns (uint256);
}
// Polygon MainNET Fork
contract AaveMoOn {
    //Uniswap 
    ISwapRouter public immutable swapRouter;

    // Contracts
    IPoolAddressesProvider public immutable IPAProvider;
    IPoolAddressesProviderRegistry public immutable IPAPRegistry;
    IWETHGateway public immutable WETHGateway;

    // Aave Tokens
    IAToken public immutable aWMatic;
    IAToken public immutable wMaticStableDebt;

    IAToken public immutable aUsdc;
    IAToken public immutable UsdcStableDebt;

    bool useAsCollateral = true;

    // ERC20 Tokens
    IERC20 public immutable wMatic = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IERC20 public immutable matic = IERC20(0x0000000000000000000000000000000000001010);

    address public immutable usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    //Uniswap 
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant WETH9 = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    // Fee Swap
    uint24 public constant poolFee = 3000;



    // TX Price Amount
    uint256 AMOUNT_1 = 1 * 1e18;
    uint256 AMOUNT_USDC = 3 * 1e18;
    uint256 AMOUNT_500 = 500 * 1e18;




    constructor() {
        //Uniswap
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Wrong Polygon address ?
        // Contracts
        IPAProvider = IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb); 
        IPAPRegistry = IPoolAddressesProviderRegistry((0x770ef9f4fe897e59daCc474EF11238303F9552b6));
        WETHGateway = IWETHGateway(0x9BdB5fcc80A49640c7872ac089Cc0e00A98451B6);

        // Aave Tokens
        wMaticStableDebt = IAToken(0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E);  
        aWMatic = IAToken(0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97);

        aUsdc = IAToken(0x625E7708f30cA75bfd92586e17077590C60eb4cD);
        UsdcStableDebt = IAToken(0x307ffe186F84a3bc2613D1eA417A5737D69A7007);





    }

    //\\ PoolAddressProviderRegistry : fetch All Deployed Pools Address 
    function getListofPools() public view returns(address[] memory) {
        return IPAPRegistry.getAddressesProvidersList();
    }

    //\\ PoolAddressProvider: Fetch current selected Pool Address
    function GP() public view returns(address) {
        return IPAProvider.getPool();
    }

    function wMaticBalance() public view returns(uint256 balance_) {
        balance_ =  wMatic.balanceOf(msg.sender);
    }

    function maticBalance() public view returns(uint256 balance_) {
        balance_ =  matic.balanceOf(msg.sender);
    }
    
    // function getWethAddress() public view returns(address) {
    //     return WETHGateway.getWETHAddress();
    // }

    // Not Found ? 


    //\\ WETHGateway for wrapping native ERC20, using deprecated 'deposit' function instead of 'supply' from pool 
    function dGateDeposit() public payable returns(uint256 dGateDeposit_) {
        WETHGateway.depositETH{value: msg.value}(GP(), msg.sender, 0);
        dGateDeposit_ = TryATokenData();
        // IPool(GP()).setUserUseReserveAsCollateral(wMatic, true);
    }
    /// [V] Success : Wrap and deposit successfully native Matic on selected Pool (still need to check user's balance/allowance on selected pool to be sure)


    //\\  WETHGateway BorrowETH (only native ?) 
    function dGateBorrow(uint256 _amount) public {
        WETHGateway.borrowETH(GP(), _amount, 1, 0);
    }
    // [X] TX reverted 


    //\\ WETHGateWay Withdraw Initial native ERC20 supplyied from pool
    function dGateWithdraw() public {
        WETHGateway.withdrawETH(GP(), type(uint256).max, msg.sender);
    }
    /// [X] TX reverted


    //\\ ERC20 : Wrap nativeMatic from source contract 
    function wrapMatic() public payable returns(uint256) {
        wMatic.deposit{value: msg.value}();
        return wMatic.balanceOf(msg.sender);
    }
    /// [X] TX reverted 


    //\\ ERC 20 : Unwrap wrappedMatic from source contract    
    function unwrapMatic() public payable  {
        wMatic.withdraw(type(uint).max);
    }
    /// [X] TX reverted 


    //\\ Pool : Trying to borrow Usdc from Aave v3 Pool 
    function TryBorrowPool(uint256 _amount) public {
        TryApprove(_amount);
        IPool(GP()).borrow(usdc, _amount, 1, 0, msg.sender);
    }
    /// [X] TX reverted (Wrong Token/Pool Address ? Reserve not set as collat ? Not allowed to dispose of funds ?) 

    //\\ Pool : Trying to supply Matic to Aave v3 Pool 
    function TrySupplyPool(uint256 _amount) public {
        TryApprove(_amount);
        IPool(GP()).supply(address(wMatic), _amount, msg.sender, 0);
    }
    /// [X] TX reverted (Approval Needed ? Wrong ERC20 Address ?)

    //\\ AToken : Fetch user aToken Balance
    function TryATokenData() public view returns(uint256){
        IAToken ATokenData = IAToken(IPool(GP()).getReserveData(address(wMatic)).aTokenAddress);
        return ATokenData.balanceOf(msg.sender);
    }
    ///[V] Success


    //\\ ERC20 : Approve Spender on behalf of msg.sender for x amount 
    function TryApprove(uint256 _amount) public payable returns(bool){
        IERC20(address(wMatic)).approve(GP(), _amount); // Approve Pool to handle funds 
        IERC20(address(wMatic)).approve(address(WETHGateway), _amount); // Approve Pool to handle funds 
        IERC20(usdc).approve(GP(), _amount); // Approve Pool to handle funds 
        IERC20(usdc).approve(address(WETHGateway), _amount); // Approve Pool to handle funds 

        // IERC20(address(UsdcStableDebt)).approve(GP(), _amount); // Approve Pool to handle funds 
        // IERC20(address(UsdcStableDebt)).approve(address(WETHGateway), _amount); // Approve Pool to handle funds 
        IERC20(address(aUsdc)).approve(GP(), _amount); // Approve Pool to handle funds 
        IERC20(address(aUsdc)).approve(address(WETHGateway), _amount); // Approve Pool to handle funds 

        IERC20(address(aWMatic)).approve(GP(), _amount); // Approve Pool to handle funds 
        IERC20(address(aWMatic)).approve(address(WETHGateway), _amount); // Approve Pool to handle funds 
        // IERC20(address(wMaticStableDebt)).approve(GP(), _amount); // Approve Pool to handle funds 
        // IERC20(address(wMaticStableDebt)).approve(address(WETHGateway), _amount); // Approve Pool to handle funds 

        return true;

        // IERC20(address(IERC20F)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        // IERC20(address(IERC20F)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 
 
    }
    ///[V] Success


    //\\ Pool : Set User selected Reserve as collateral for borrowing 
    function TrySetReserveasCollat() public {
        IPool pool = IPool(GP());

        pool.setUserUseReserveAsCollateral(address(wMatic), true);
    }
    /// [X] TX reverted 


    /* //\\ Supply Funds
        - Supply ERC20 Matic to Aave V3 Polygon Pool
        - Borrow 200% collat USDC from pool
        - Supply borrowed USDC from Aave to Balancer Pool 
    */    
    function letsDoItFrens(uint256 _amount) public payable returns(bool){
        IPool pool = IPool(GP());

        // IERC20(wMatic).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        // TryApprove();

        pool.supply(address(wMatic), _amount, msg.sender, 0); // address(WETH) [1]


        // pool.setUserUseReserveAsCollateral(wMatic, true); // V1 ? 

        return true;

        
        // pool.borrow(usdc, AMOUNT_USDC, 1, 0, msg.sender);

        // Deposit borrowed USDC to Pool Balancer MAI/USDC/DAI/USDT

    }
    /// [X] Reverted 

    function approveWMatic(uint256 _amount) public payable returns(uint256){
        wMatic.approve(GP(), _amount); // Approve Pool to handle funds 
        wMatic.approve(address(WETHGateway), _amount); // Approve Pool to handle funds

        return wMatic.allowance(msg.sender, GP());
         
    }

    function approveMatic(uint256 _amount) public payable returns(uint256){
        matic.approve(GP(), _amount); // Approve Pool to handle funds 
        matic.approve(address(WETHGateway), _amount); // Approve Pool to handle funds
        return matic.allowance(msg.sender, GP());
    }


        


    /* //\\ Withdraw Funds w/ Benefits
        - Withdraw Borrowed USDC off Balancer Pools
        - Repay borrowed USDC from Aave, free AToken
        - Withdraw initials funds, payback AToken 
    */  
    function canWeUndo() public {
        IPool pool = IPool(GP());


        // Withdraw lended USDC from Balancer Pool;

        pool.repay(usdc, type(uint).max, 1, msg.sender); // repay borrowed USDC -> free matic collateral

        pool.withdraw(address(wMatic), type(uint).max, msg.sender);

        // unwrapMatic();
    }
    /// [X] Reverted

    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract
        TransferHelper.safeApprove(address(matic), address(this), amountIn);


        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(address(matic), msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(address(matic), address(swapRouter), amountIn);
        TransferHelper.safeApprove(address(matic), address(this), amountIn);
        TransferHelper.safeApprove(address(wMatic), address(swapRouter), amountIn);
        TransferHelper.safeApprove(address(wMatic), address(this), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(matic),
                tokenOut: address(wMatic),
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
