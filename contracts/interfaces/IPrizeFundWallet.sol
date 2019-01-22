pragma solidity ^0.4.24;

contract IPrizeFundWallet {
    function putFundsToPrizeWallet(uint256 lotteryId) payable public;
    function sendFundsToPrizeFundManager() public;
    function getBalance() public view returns (uint256);
    function init(address _lottery_seller_address, address _profitWalletAddress, address _prizeFundManagerAddress) public;
    function getLotteryBalance(uint256 lotteryId) public view returns(uint256);
}