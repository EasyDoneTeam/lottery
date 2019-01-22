pragma solidity ^0.4.24;

import "./interfaces/IProfitWallet.sol";
import "./interfaces/IProfitManager.sol";
import "./owner.sol";

contract ProfitManager is Ownable, IProfitManager
{
    IProfitWallet public profitWallet;
    event PaidDividends(address indexed recepient, address sender);

    constructor () public
    {
        
    }

    function setProfitWalletAddress(address profitWalletAddress) public onlyOwner
    {
        profitWallet = IProfitWallet(profitWalletAddress);
    }

    function getDividends(address recipient) public
    {
        profitWallet.payToShareholder(msg.sender, recipient);
        emit PaidDividends(msg.sender, recipient);
    }
    
    function () public payable {
        revert("Does not Accept ETH directly");
    }
}