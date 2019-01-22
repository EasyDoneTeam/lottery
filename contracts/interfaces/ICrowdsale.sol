pragma solidity ^0.4.24;

contract ICrowdsale {
    function isCrowdsaleClosed() public view returns(bool);
    function getInvestorCount() public view returns(uint256);
    function getTokensSold() public view returns(uint256);
    function estimateTokens(uint weiAmount) public view returns(uint tokenEstimation);

    event GoalReached(address recipient);
    event FundTransfer(address backer, uint amount);
    
    event BeforeDeadlineBonus(address investor);
    event EarlyInvestorBonus(address investor);
    event AdditionalBonus(address investor);
}