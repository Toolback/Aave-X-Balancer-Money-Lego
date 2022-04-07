pragma solidity ^0.7.0;

import 'https://github.com/balancer-labs/balancer-v2-monorepo/blob/weighted-deployment/contracts/vault/interfaces/IVault.sol';

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
        Vault.joinPool();
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
        Vault.exitPool();
    }
}
