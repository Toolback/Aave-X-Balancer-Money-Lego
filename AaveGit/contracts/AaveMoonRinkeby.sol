// pragma solidity ^0.8.10;


// import '@aave/core-v3/contracts/interfaces/IPool.sol';
// import '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
// import '@aave/core-v3/contracts/interfaces/IPoolAddressesProviderRegistry.sol';


// import '@aave/periphery-v3/contracts/misc/interfaces/IWETH.sol';
// import '@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol';
// import '@aave/core-v3/contracts/interfaces/IAToken.sol';
// import '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

// // import 'https://github.com/balancer-labs/balancer-v2-monorepo/blob/weighted-deployment/contracts/vault/interfaces/IVault.sol';

// interface IERC20Faucet {
//     /**
//      * @dev Proxy function to mint Testnet tokens to msg.sender
//      * @param _token The address of the token
//      * @param _amount The amount to mint
//      * @return The amount minted
//      **/
//     function mint(address _token, uint256 _amount) external returns (uint256);
// }
// // Polygon MainNET Fork
// contract AaveMoOn {
//     // Contracts
//     IPoolAddressesProvider public immutable IPAProvider;
//     IPoolAddressesProviderRegistry public immutable IPAPRegistry;
//     IWETHGateway public immutable WETHGateway;
//     IERC20Faucet internal immutable ERC20Faucet;

//     // Aave Tokens
//     IAToken public immutable aWEth;
//     IAToken public immutable wETHStableDebt;

//     IAToken public immutable aUsdc;
//     IAToken public immutable UsdcStableDebt;

//     bool useAsCollateral = true;

//     // ERC20 Tokens
//     address public immutable wEth;
//     // address public immutable matic;

//     address public immutable usdc;


//     // TX Price Amount
//     uint256 AMOUNT_1 = 1 * 1e18;
//     uint256 AMOUNT_USDC = 3 * 1e18;
//     uint256 AMOUNT_500 = 500 * 1e18;





//     constructor() {
//         // Contracts
//         IPAProvider = IPoolAddressesProvider(0xBA6378f1c1D046e9EB0F538560BA7558546edF3C); 
//         IPAPRegistry = IPoolAddressesProviderRegistry(0xF2038a65f68a94d1CFD0166f087A795341e2eac8);
//         WETHGateway = IWETHGateway(0xD1DECc6502cc690Bc85fAf618Da487d886E54Abe);
//         ERC20Faucet = IERC20Faucet(0x88138CA1e9E485A1E688b030F85Bb79d63f156BA);

//         // Aave Tokens
//         wETHStableDebt = IAToken(0x7666ca6911bEcBA7d38Fa2da8278b82297EC7e6F);  
//         aWEth = IAToken(0x608D11E704baFb68CfEB154bF7Fd641120e33aD4);

//         aUsdc = IAToken(0x50b283C17b0Fc2a36c550A57B1a133459F4391B3);
//         UsdcStableDebt = IAToken(0xee3D33c0C779cAD53CAa496aa5a97D026D1218Ca);


//         // ERC20 Tokens
//         usdc = address(0xb18d016cDD2d9439A19f15633005A6b2cd6Aa774);
//         // matic = address(0x0000000000000000000000000000000000001010);
//         wEther = address(0xd74047010D77c5901df5b0f9ca518aED56C85e8D);



//     }

//     //\\ PoolAddressProviderRegistry : fetch All Deployed Pools Address 
//     function getListofPools() public view returns(address[] memory) {
//         return IPAPRegistry.getAddressesProvidersList();
//     }

//     //\\ PoolAddressProvider: Fetch current selected Pool Address
//     function GP() public view returns(address) {
//         return IPAProvider.getPool();
//     }

//     // //\\ ERC20/ Faucet ? Mint testnet WToken 
//     // function mintToken() public payable {
//     //     IERC20F.mint(wMatic, AMOUNT_500);
//     // }
//     // /// [~] Faucet Address => wMatic + Amount = TX pass but nothing more (no token increment)
//     // /// [V] Success: wMatic address => msg.sender + Amount = wMatic increment 



    
//     // function getWethAddress() public view {
//     //     WETHGateway.getWETHAddress();
//     // }
//     /// Doesn't work ? not implemented in source contract ?


//     //\\ WETHGateway for wrapping native ERC20, using deprecated 'deposit' function instead of 'supply' from pool 
//     function dGateDeposit() public payable returns(bool){
//         WETHGateway.depositETH{value: AMOUNT_1}(GP(), msg.sender, 0);
//         // IPool(GP()).setUserUseReserveAsCollateral(wEther, true);
//         return true;
//     }
//     /// [V] Success : Wrap and deposit successfully native Matic on selected Pool (still need to check user's balance/allowance on selected pool to be sure)


//     //\\  WETHGateway BorrowETH (only native ?) 
//     function dGateBorrow() public {
//         WETHGateway.borrowETH(GP(), AMOUNT_1, 1, 0);
//     }
//     // [X] TX reverted 


//     //\\ WETHGateWay Withdraw Initial native ERC20 supplyied from pool
//     function dGateWithdraw() public {
//         WETHGateway.withdrawETH(GP(), type(uint256).max, msg.sender);
//     }
//     /// [X] TX reverted


//     // //\\ ERC20 : Wrap nativeMatic from source contract 
//     // function wrapMatic() public payable {
//     //     WETH.deposit{value: msg.value}();
//     // }
//     // /// [X] TX reverted 


//     // //\\ ERC 20 : Unwrap wrappedMatic from source contract    
//     // function unwrapMatic() public payable  {
//     //     WETH.withdraw(type(uint).max);
//     // }
//     // /// [X] TX reverted 


//     //\\ Pool : Trying to borrow Usdc from Aave v3 Pool 
//     function TryBorrowPool() public {
//         TryApprove();
//         IPool(GP()).borrow(usdc, AMOUNT_USDC, 1, 0, msg.sender);
//     }
//     /// [X] TX reverted (Wrong Token/Pool Address ? Reserve not set as collat ? Not allowed to dispose of funds ?) 

//     //\\ Pool : Trying to supply Matic to Aave v3 Pool 
//     function TrySupplyPool() public {
//         TryApprove();
//         IPool(GP()).supply(matic, AMOUNT_1, msg.sender, 0);
//     }
//     /// [X] TX reverted (Approval Needed ? Wrong ERC20 Address ?)

//     //\\ AToken : Fetch user aToken Balance
//     function TryATokenData() public view returns(uint256){
//         IAToken ATokenData = IAToken(IPool(GP()).getReserveData(matic).aTokenAddress);
//         return ATokenData.balanceOf(msg.sender);
//     }
//     ///[V] Success


//     //\\ ERC20 : Approve Spender on behalf of msg.sender for x amount 
//     function TryApprove() public payable {
//         // IERC20(matic).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         // IERC20(matic).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(usdc).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(usdc).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

//         IERC20(address(UsdcStableDebt)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(address(UsdcStableDebt)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(address(aUsdc)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(address(aUsdc)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

//         IERC20(address(aWMatic)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(address(aWMatic)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(address(wMaticStableDebt)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(address(wMaticStableDebt)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

//         // IERC20(address(IERC20F)).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         // IERC20(address(IERC20F)).approve(address(WETHGateway), AMOUNT_1); // Approve Pool to handle funds 

//     }
//     ///[V] Success


//     //\\ Pool : Set User selected Reserve as collateral for borrowing 
//     function TrySetReserveasCollat() public {
//         IPool pool = IPool(GP());

//         pool.setUserUseReserveAsCollateral(matic, true);
//     }
//     /// [X] TX reverted 


//     /* //\\ Supply Funds
//         - Supply ERC20 Matic to Aave V3 Polygon Pool
//         - Borrow 200% collat USDC from pool
//         - Supply borrowed USDC from Aave to Balancer Pool 
//     */    
//     function letsDoItFrens() public payable returns(bool){
//         IPool pool = IPool(GP());

//         // IERC20(wMatic).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         // TryApprove();

//         pool.supply(matic, AMOUNT_1, msg.sender, 0); // address(WETH) [1]


//         // pool.setUserUseReserveAsCollateral(wMatic, true); // V1 ? 

//         return true;

        
//         // pool.borrow(usdc, AMOUNT_USDC, 1, 0, msg.sender);

//         // Deposit borrowed USDC to Pool Balancer MAI/USDC/DAI/USDT

//     }
//     /// [X] Reverted 

//     function approveSupply() public payable returns(bool){
//         IPool pool = IPool(GP());
//         IERC20(wMatic).approve(GP(), AMOUNT_1); // Approve Pool to handle funds 
//         IERC20(matic).approve(GP(), AMOUNT_1); // Approve Pool to handle funds
//         return true; 
//     }

        


//     /* //\\ Withdraw Funds w/ Benefits
//         - Withdraw Borrowed USDC off Balancer Pools
//         - Repay borrowed USDC from Aave, free AToken
//         - Withdraw initials funds, payback AToken 
//     */  
//     function canWeUndo() public {
//         IPool pool = IPool(GP());


//         // Withdraw lended USDC from Balancer Pool;

//         pool.repay(usdc, type(uint).max, 1, msg.sender); // repay borrowed USDC -> free matic collateral

//         pool.withdraw(matic, type(uint).max, msg.sender);

//         // unwrapMatic();
//     }
//     /// [X] Reverted
// }