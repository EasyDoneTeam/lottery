pragma solidity ^0.4.24;

contract IProfitManager {
    event PaidDividends(address indexed recepient, address sender);
    
    function setProfitWalletAddress(address profitWalletAddress) public;
    function getDividends(address recipient) public;
}