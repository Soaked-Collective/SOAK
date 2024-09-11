// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Taxable} from "./taxable/Taxable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SoakToken is ERC20, ERC20Burnable, Taxable, Ownable {

    event Taxation(uint8 indexed taxType, uint256 taxAmount); // taxType:  1 = transfer, 2 = buy, 3 = sell

    constructor(address _taxRecipient, address _treasury)
    ERC20("SOAKed Collective", "SOAK")
    Ownable(msg.sender)
    Taxable(500, 500, 200) {
         _mint(_treasury, 35000000000000000000000000000);
         _updateTaxRecipients(_taxRecipient, _taxRecipient, _taxRecipient);
         _setTaxExempt(msg.sender, true);
         _setTaxExempt(_treasury, true);
    }

    // embedd taxation into token tansfer
    function _update(address from, address to, uint256 value) internal virtual override {

        (uint8 taxType, uint256 taxAmount, address taxReceiver) = getTax(from, to, value);

        ERC20._update(from, to, (value - taxAmount));

        // collect tax where applicable
        if (taxAmount > 0) {
            ERC20._update(from, taxReceiver, taxAmount);
            emit Taxation(taxType, taxAmount);
        }
    }

    // tax management
    function updateTaxes(uint256 _buyTax, uint256 _sellTax, uint256 _transferTax) external onlyOwner {
        _updateTaxes(_buyTax, _sellTax, _transferTax);
    }

    function updateTaxRecipients(address _buyTaxRecipient, address _sellTaxRecipient, address _transferTaxRecipient) 
        external onlyOwner {

        _updateTaxRecipients(_buyTaxRecipient, _sellTaxRecipient, _transferTaxRecipient);
    }

    function setTaxExempt(address _address, bool _isTaxExempt) external onlyOwner {
        _setTaxExempt(_address, _isTaxExempt);
    }

    function flagLiqPool(address _address, bool _isLiqPool) external onlyOwner {
        _flagLiqPool(_address, _isLiqPool);
    }

    function withdrawTaxes() external onlyOwner {
        IERC20(address(this)).transfer(
            owner(), 
            IERC20(address(this)).balanceOf(address(this))
        );
    }

}
