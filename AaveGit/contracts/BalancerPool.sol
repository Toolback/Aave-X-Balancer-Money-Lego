pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";
// import "@balancer-labs/v2-vault/contracts/interfaces/IBasePool.sol";

contract BalancerPool {

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


    function GetPoolTokens(bytes32 _poolId, address _vaultAddress) public view returns (
        IERC20[] memory tokens, 
        uint256[] memory balances,
        uint256 lastChangeBlock){
        IVault(_vaultAddress)
        .getPoolTokens(_poolId);
    }
}
