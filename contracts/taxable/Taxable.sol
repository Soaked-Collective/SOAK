// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Taxable {

    // Optional Tax Recipients
    address public sellTaxRecipient;
    address public buyTaxRecipient;
    address public transferTaxRecipient;

    // Taxes - Percentage value that supports up to two decimals,
    // e.g. 1 = 0.01% | 100 = 1% | 1000 = 10%
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public transferTax;

    mapping(address=>bool) public isTaxExempt;
    mapping(address=>bool) public isLiqPool;

    event TaxUpdate(uint256 newBuyTax, uint256 newSellTax, uint256 newTransferTax);
    event TaxRecipientUpdate(address newBuyTaxRecipient, address newSellTaxRecipient, address newTransferTaxRecipient);

    error TaxCannotExceed10Percent();

    constructor (uint256 _buyTax, uint256 _sellTax, uint256 _transferTax) {

        if(_buyTax > 1000 || _sellTax > 1000 || _transferTax > 1000) {
            revert TaxCannotExceed10Percent();
        }

        // init tax recipients with Zero address, aka contract itself receives taxes
        buyTaxRecipient = address(0);
        sellTaxRecipient = address(0);
        transferTaxRecipient = address(0);

        // set initial tax values
        buyTax = _buyTax;
        sellTax = _sellTax;
        transferTax = _transferTax;

        // make address 0 tax exempt (mint and burn should not be taxed)
        _setTaxExempt(address(0), true);
    }

    /**
     * Get tax amount and tax receiver for the specified transfer
     * Returns:
     * - uint8 taxType : 0 = none, 1 = transfer, 2 = buy, 3 = sell
     * - uint256 taxAmount
     * - address taxReceiver
     */
    function getTax(address sender, address recipient, uint256 amount) public view returns (uint8, uint256, address) {

        if (isTaxExempt[sender] || isTaxExempt[recipient]) {
            return (0, 0, address(0));
        }

        // if sender is a LiqPool, we assume a token purchase from a DEX
        if(isLiqPool[sender]) {
            return (2, ((amount * buyTax)/10000), buyTaxRecipient == address(0) ? address(this) : buyTaxRecipient);
        }
        // if recipient is a LiqPool, we assume a token sell to a DEX
        if(isLiqPool[recipient]) {
            return (3, ((amount * sellTax)/10000), sellTaxRecipient == address(0) ? address(this) : sellTaxRecipient);
        }

        return (1, ((amount * transferTax)/10000), transferTaxRecipient == address(0) ? address(this) : transferTaxRecipient);
    }

    function _updateTaxes(uint256 _buyTax, uint256 _sellTax, uint256 _transferTax) internal {

        if(_buyTax > 1000 || _sellTax > 1000 || _transferTax > 1000) {
            revert TaxCannotExceed10Percent();
        }

        buyTax = _buyTax;
        sellTax = _sellTax;
        transferTax = _transferTax;

        emit TaxUpdate(_buyTax, _sellTax, _transferTax);
    }

    function _updateTaxRecipients(address _buyTaxRecipient, address _sellTaxRecipient, address _transferTaxRecipient) internal {

        buyTaxRecipient = _buyTaxRecipient;
        sellTaxRecipient = _sellTaxRecipient;
        transferTaxRecipient = _transferTaxRecipient;

        emit TaxRecipientUpdate(_buyTaxRecipient, _sellTaxRecipient, _transferTaxRecipient);
    }

    function _setTaxExempt(address _address, bool _isTaxExempt) internal {
        isTaxExempt[_address] = _isTaxExempt;
    }

    function _flagLiqPool(address _address, bool _isLiqPool) internal {
        isLiqPool[_address] = _isLiqPool;
    }

}
