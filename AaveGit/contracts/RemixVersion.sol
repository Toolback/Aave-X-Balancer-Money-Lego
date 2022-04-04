// VERSION :
// https://remix.ethereum.org/  

pragma solidity ^0.8.10;

import 'https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPool.sol';
import 'https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPoolAddressesProvider.sol';
import 'https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPoolAddressesProviderRegistry.sol';


import 'https://github.com/aave/aave-v3-periphery/blob/master/contracts/misc/interfaces/IWETH.sol';
import 'https://github.com/aave/aave-v3-periphery/blob/master/contracts/misc/interfaces/IWETHGateway.sol';
import 'https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IAToken.sol';
import 'https://github.com/aave/aave-v3-core/blob/master/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

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

// Polygon Mumbai Testnet
contract AaveMoOn {
    // Contracts
    IPoolAddressesProvider public immutable IPAProvider;
    IPoolAddressesProviderRegistry public immutable IPAPRegistry;
    IWETHGateway public immutable WETHGateway;
    IERC20Faucet immutable IERC20F;
    // ERC20 / Wrapped / AToken
    IWETH public immutable WETH;
    IAToken public immutable aWMatic;
    IERC20 public immutable wMaticStableDebt;
    IAToken public immutable aToken;
    address public immutable wMatic;
    address public immutable usdc;

    // TX Price Amount
    uint256 AMOUNT_1 = 1 * 1e18;
    uint256 AMOUNT_USDC = 3 * 1e18;
    uint256 AMOUNT_500 = 500 * 1e18;



    constructor() {
        IPAProvider = IPoolAddressesProvider(0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6); 
        IPAPRegistry = IPoolAddressesProviderRegistry(0xE0987FC9EDfcdcA3CB9618510AaF1D565f4960A6);
        WETHGateway = IWETHGateway(0x2a58E9bbb5434FdA7FF78051a4B82cb0EF669C17);
        IERC20F = IERC20Faucet(0xc1eB89DA925cc2Ae8B36818d26E12DDF8F8601b0);

        WETH = IWETH(0xb685400156cF3CBE8725958DeAA61436727A30c3); // Used in WETHGateway to wrap ERC20, address ?
        aToken = IAToken(0x8017B7FC5473d05e67E617072fB237D24Add550b);
        wMatic = address(0xb685400156cF3CBE8725958DeAA61436727A30c3); 
        wMaticStableDebt = IERC20(0xEC59F2FB4EF0C46278857Bf2eC5764485974D17B);  
        usdc = address(0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2);
        aWMatic = IAToken(0x89a6AE840b3F8f489418933A220315eeA36d11fF);

        bool useAsCollateral = true;


    }

    //\\ PoolAddressProviderRegistry : fetch All Deployed Pools Address 
    function getListofPools() public view returns(address[] memory) {
        return IPAPRegistry.getAddressesProvidersList();
    }

    //\\ PoolAddressProvider: Fetch current selected Pool Address
    function GP() public view returns(address) {
        return IPAProvider.getPool();
    }

    //\\ ERC20/ Faucet ? Mint testnet WToken 
    function mintToken() public payable {
        IERC20F.mint(wMatic, AMOUNT_500);
    }
    /// [~] Faucet Address => wMatic + Amount = TX pass but nothing more (no token increment)
    /// [V] Success: wMatic address => msg.sender + Amount = wMatic increment 



    
    // function getWethAddress() public view {
    //     WETHGateway.getWETHAddress();
    // }
    /// Doesn't work ? not implemented in source contract ?


    //\\ WETHGateway for wrapping native ERC20, using deprecated 'deposit' function instead of 'supply' from pool 
    function dGateDeposit() public payable {
        WETHGateway.depositETH{value: msg.value}(GP(), msg.sender, 0);
    }
    /// [V] Success : Wrap and deposit successfully native Matic on selected Pool (still need to check user's balance/allowance on selected pool to be sure)


    //\\  WETHGateway BorrowETH (only native ?) 
    function dGateBorrow() public {
        WETHGateway.borrowETH(GP(), AMOUNT_1, 1, 0);
    }
    // [X] TX reverted 


    //\\ WETHGateWay Withdraw Initial native ERC20 supplyied from pool
    function dGateWithdraw() public {
        WETHGateway.withdrawETH(GP(), type(uint256).max, msg.sender);
    }
    /// [X] TX reverted


    //\\ ERC20 : Wrap nativeMatic from source contract 
    function wrapMatic() public payable {
        WETH.deposit{value: msg.value}();
    }
    /// [X] TX reverted 


    //\\ ERC 20 : Unwrap wrappedMatic from source contract    
    function unwrapMatic() public payable  {
        WETH.withdraw(type(uint).max);
    }
    /// [X] TX reverted 


    //\\ Pool : Trying to borrow Usdc from Aave v3 Pool 
    function TryBorrowPool() public {
        TryApprove();
        IPool(GP()).borrow(usdc, AMOUNT_USDC, 1, 0, msg.sender);
    }
    /// [X] TX reverted (Wrong Token/Pool Address ? Reserve not set as collat ? Not allowed to dispose of funds ?) 

    //\\ Pool : Trying to supply Matic to Aave v3 Pool 
    function TrySupplyPool() public {
        TryApprove();
        IPool(GP()).supply(wMatic, AMOUNT_1, msg.sender, 0);
    }
    /// [X] TX reverted (Approval Needed ? Wrong ERC20 Address ?)

    //\\ AToken : Fetch user aToken Balance
    function TryATokenData() public view returns(uint256){
        IAToken ATokenData = IAToken(IPool(GP()).getReserveData(wMatic).aTokenAddress);
        return ATokenData.balanceOf(msg.sender);
    }
    ///[V] Success


    //\\ ERC20 : Approve Spender on behalf of msg.sender for x amount 
    function TryApprove() public payable {
        IERC20(wMatic).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        IERC20(wMatic).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 
        IERC20(address(aWMatic)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        IERC20(address(aWMatic)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 
        IERC20(usdc).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        IERC20(usdc).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

        IERC20(address(aToken)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        IERC20(address(aToken)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

        IERC20(address(wMaticStableDebt)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        IERC20(address(wMaticStableDebt)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

        // IERC20(address(IERC20F)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        // IERC20(address(IERC20F)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

    }
    ///[V] Success


    //\\ Pool : Set User selected Reserve as collateral for borrowing 
    function TrySetReserveasCollat() public {
        IPool pool = IPool(GP());

        pool.setUserUseReserveAsCollateral(wMatic, true);
    }
    /// [X] TX reverted 


    /* //\\ Supply Funds
        - Supply ERC20 Matic to Aave V3 Polygon Pool
        - Borrow 200% collat USDC from pool
        - Supply borrowed USDC from Aave to Balancer Pool 
    */    
    function letsDoItFrens() public payable {
        IPool pool = IPool(GP());

        // IERC20(wMatic).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
        TryApprove();

        pool.supply(wMatic, AMOUNT_1, msg.sender, 0); // address(WETH) [1]


        pool.setUserUseReserveAsCollateral(wMatic, true); // V1 ? 

        
        // pool.borrow(usdc, AMOUNT_USDC, 1, 0, msg.sender);

        // Deposit borrowed USDC to Pool Balancer MAI/USDC/DAI/USDT

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
}
