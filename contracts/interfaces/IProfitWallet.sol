pragma solidity ^0.4.24;

contract IProfitWallet
{
    function init(address _profit_manager_address, address _token_address, address _prize_fund_wallet_address, address _lottery_address) public;

    //receive profit with lap's num from lottery contract
    function receiveProfit(uint _lap) payable public;

    // return total balance of company's profit
    function getBalance() public view returns (uint256);

    // send shareholder's profit to him
    function payToShareholder(address _shareholder, address recepient) public;

    // send profit to prize fund wallet when lottery fails
    function sendProfitToPrizeFundWallet(uint256 lotteryId) public;

    // update shareholder's proportion
    function updateShareHolder(address _holder, uint _proportion) public;

    // close lap and distribute profit by shareholders
    function closeCurrentLap() public;

    function getShareholderUnpaidDividends() public view returns (uint256);
}
