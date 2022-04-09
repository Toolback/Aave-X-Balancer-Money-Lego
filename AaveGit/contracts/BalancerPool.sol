pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";

contract Balancer {
    IVault internal immutable Vault;

    constructor() {
        Vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) public payable {
        Vault.joinPool(poolId, sender, recipient, request);
    }

    function GPT(bytes32 _poolId) public view {
        Vault.getPoolTokens(_poolId);
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) public {
        Vault.exitPool(poolId, sender, recipient, request);
    }
}
