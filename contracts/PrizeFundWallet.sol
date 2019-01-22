pragma solidity ^0.4.24;

import "./owner.sol";
import "./interfaces/IPrizeFundWallet.sol";

contract PrizeFundWallet is Ownable, IPrizeFundWallet
{
    address public lotteryAddress;
    address public profitWalletAddress;
    address public prizeFundManagerAddress;

    mapping (uint256 => uint256) private lotteryBalances;

    constructor () public
    {
        
    }

    function init(address _lottery_seller_address, address _profitWalletAddress, address _prizeFundManagerAddress) public onlyOwner
    {
        lotteryAddress = _lottery_seller_address;
        profitWalletAddress = _profitWalletAddress;
        prizeFundManagerAddress = _prizeFundManagerAddress;
    }

    function putFundsToPrizeWallet(uint256 lotteryId) payable public
    {
        require(msg.sender == lotteryAddress || msg.sender == profitWalletAddress, "Only Lottery Seller Contract or Company Profit Contract can put ETH here!");
        lotteryBalances[lotteryId] = lotteryBalances[lotteryId] + msg.value;
    }

    function getLotteryBalance(uint256 lotteryId) public view returns(uint256)
    {
        return lotteryBalances[lotteryId];
    }

    function sendFundsToPrizeFundManager() public
    {
        require(msg.sender == prizeFundManagerAddress, "Only Prize Fund Manager Contract can take ETH from here!");
        prizeFundManagerAddress.transfer(address(this).balance);
    }

    function sendPrizeWinner(address winner, uint256 value) {
        require(msg.sender == prizeFundManagerAddress, "Only Prize Fund Manager Contract can take ETH from here!");
        winner.transfer(value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function () public payable {
        revert("Does not Accept EHT directly");
    }
}