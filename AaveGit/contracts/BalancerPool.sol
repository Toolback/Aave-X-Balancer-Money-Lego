pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";
// import "@balancer-labs/v2-vault/contracts/interfaces/IBasePool.sol";
// import "@balancer-labs/v2-vault/contracts/interfaces/IFlashLoanRecipient.sol";

contract BalancerPool is IFlashLoanRecipient  {
    IVault public flashVault = "0x0297e37f1873d2dab4487aa67cd56b58e2f27875";

    function joinPool(
        address vaultAddress,
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request
    ) public payable {

        IVault(vaultAddress)
        .joinPool(poolId, sender, recipient, request);
    }

    function exitPool(
        address _vaultAddress,
        bytes32 poolId,
        address sender,
        address payable recipient,
        IVault.ExitPoolRequest memory request
    ) public {
        IVault(_vaultAddress)
        .exitPool(poolId, sender, recipient, request);
    }

    function swapTokens(
        address _vaultAddress,
        IVault.SingleSwap memory singleSwap,
        IVault.FundManagement memory funds,
        uint256 limit,
        uint256 deadline) public{
        IVault(_vaultAddress)
            .swap(singleSwap,
                funds,
                limit,
                deadline);
    }

    // function makeFlashLoan(
    //     IERC20[] memory tokens,
    //     uint256[] memory amounts,
    //     bytes memory userData
    // ) external {
    //   flashVault
    //   .flashLoan(this, tokens, amounts, userData);
    // }

    // function receiveFlashLoan(
    //     IERC20[] memory tokens,
    //     uint256[] memory amounts,
    //     uint256[] memory feeAmounts,
    //     bytes memory userData
    // ) external override {
    //     require(msg.sender == flashVault);
        
    // }


    function GetPoolTokens(bytes32 _poolId, address _vaultAddress) public view returns (
        IERC20[] memory tokens, 
        uint256[] memory balances,
        uint256 lastChangeBlock){
        IVault(_vaultAddress)
        .getPoolTokens(_poolId);
    }
}
