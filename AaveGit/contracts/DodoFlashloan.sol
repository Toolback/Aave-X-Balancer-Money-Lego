//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./AaveXBAL.sol";

interface IDODO is AaveXBAL {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}

contract Flashloan {

  address _tokenToSupply;
  address _tokenToBorrow;
  address _vaultAddress;
  uint256 _amountToSupply;
  uint256 _amountToBorrow;
  uint256 _amountToRepay;
  uint256 _amountToWithdraw;
  uint256 _amountToSendBack;
  uint8 _interestRateMode;
  bytes32 _poolId;
  IVault.JoinPoolRequest _requestIn;
  IVault.ExitPoolRequest _requestOut;

    function dodoFlashLoan(
        address flashLoanPool, //You will make a flashloan from this DODOV2 pool
        uint256 loanAmount,
        address loanToken,
        address _tokenToSupply,
        address _tokenToBorrow,
        address _vaultAddress,
        uint256 _amountToSupply,
        uint256 _amountToBorrow,
        uint256 _amountToRepay,
        uint256 _amountToWithdraw,
        uint256 _amountToSendBack,
        uint8 _interestRateMode,
        bytes32 _poolId,
        IVault.JoinPoolRequest _requestIn,
        IVault.ExitPoolRequest _requestOut
    ) external {
        // Note: The data can be structured with any variables required by your logic. The following code is just an example
        bytes memory data = abi.encode(flashLoanPool, loanToken, loanAmount, _tokenToSupply, _tokenToBorrow, _amountToRepay, _amountToWithdraw, _amountToSendBack, _vaultAddress, _amountToSupply, _amountToBorrow, _interestRateMode, _poolId, _requestIn, _requestOut);
        address flashLoanBase = IDODO(flashLoanPool)._BASE_TOKEN_();

        if (flashLoanBase == loanToken) {
            IDODO(flashLoanPool).flashLoan(loanAmount, 0, address(this), data);
        } else {
            IDODO(flashLoanPool).flashLoan(0, loanAmount, address(this), data);
        }
    }

    // Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    // Dodo Vending Machine Factory --> 0x79887f65f83bdf15Bcc8736b5e5BcDB48fb8fE13
    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        console.log("Vending Machine Pool Called...");
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    // Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    // Dodo Private Pool Factory --> 0xd24153244066F0afA9415563bFC7Ba248bfB7a51
    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        console.log("Private Pool Called...");
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(
        address sender,
        uint256,
        uint256,
        bytes calldata data
    ) internal {
        (
          address flashLoanPool, 
          address loanToken, 
          uint256 loanAmount,   
          address _tokenToSupply,
          address _tokenToBorrow,
          address _vaultAddress,
          uint256 _amountToSupply,
          uint256 _amountToBorrow,
          uint256 _amountToRepay,
          uint256 _amountToWithdraw,
          uint256 _amountToSendBack,
          uint8 _interestRateMode,
          bytes32 _poolId,
          IVault.JoinPoolRequest _requestIn,
          IVault.ExitPoolRequest _requestOut
        ) = abi
            .decode(data, (address, address, uint256, address , address , uint256 , address , address , address , uint256 , uint256 , uint256 , uint256 , uint256 , uint8 , bytes32 , IVault.JoinPoolRequest , IVault.ExitPoolRequest));

        require(
            sender == address(this) && msg.sender == flashLoanPool,
            "HANDLE_FLASH_NENIED"
        );

        // Note: Realize your own logic using the token from flashLoan pool.
        startBalancerLoop(_tokenToSupply, _tokenToBorrow, _vaultAddress, _amountToSupply, _amountToBorrow, _interestRateMode, _poolId, _requestIn);

        stopBalancerLoop(_tokenToBorrow, _tokenToSupply, _vaultAddress, _amountToRepay, _amountToWithdraw, _amountToSendBack, _interestRateMode, _poolId, _requestOut);

        // Return funds
        IERC20(loanToken).transfer(flashLoanPool, loanAmount);
    }
}
