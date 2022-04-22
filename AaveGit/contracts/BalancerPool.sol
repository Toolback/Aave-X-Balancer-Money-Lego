pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";
// import "@balancer-labs/v2-vault/contracts/interfaces/IBasePool.sol";

contract BalancerPool {
    IVault internal immutable Vault;
    
    // IBasePool public Pool;

    constructor() {
        Vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    }

    // struct JoinPoolRequest {
    //     IAsset[] assets;
    //     uint256[] maxAmountsIn;
    //     bytes userData;
    //     bool fromInternalBalance;
    // }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request
    ) public payable {
        Vault.joinPool(poolId, sender, recipient, request);
    }

    function GPT(bytes32 _poolId) public view returns (
        IERC20[] memory tokens, 
        uint256[] memory balances,
        uint256 lastChangeBlock){
        Vault.getPoolTokens(_poolId);
    }

    // function getPoolId(address _pool) external view returns (bytes32) {
    //     Pool = IBasePool(_pool);
    //     return Pool.getPoolId();
    // }

    // struct ExitPoolRequest {
    //     IAsset[] assets;
    //     uint256[] minAmountsOut;
    //     bytes userData;
    //     bool toInternalBalance;
    // }

    // function toBytes(string memory source) public pure returns (bytes32 result) {
    // bytes memory tempEmptyStringTest = bytes(source);
    // if (tempEmptyStringTest.length == 0) {
    //     return 0x0;
    // }

    // assembly {
    //     result := mload(add(source, 32))
    // }
    // }

    function setRelayerApproval(address sender, address relayer, bool approved) public {
        Vault.setRelayerApproval(sender, relayer, approved);
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        IVault.ExitPoolRequest memory request
    ) public {
        Vault.exitPool(poolId, sender, recipient, request);
    }
}
