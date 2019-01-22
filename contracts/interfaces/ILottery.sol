pragma solidity ^0.4.24;

contract ILottery {
    function startNewLottery() public returns(bool startedSuccessfully);
    function isRewardingAllowed(uint256 lotteryId) public view returns(bool isAllowed);
    function isSubmittingTicketsForRewardAllowed(uint256 lotteryId) public view returns(bool isAllowed);
    function isSellingTicketsAllowed() public view returns(bool isAllowed);
    function isFillingTicketsAllowed(/*uint256 lotteryId*/) public view returns(bool isAllowed);
    function isReturningTicketsForCurrentLotteryAllowed() public view returns(bool isAllowed);
    //function isWithdrawingDividendsAllowed(uint256 lotteryId) public view returns(bool isAllowed);
    function isTokensTransferAllowed() public view returns(bool isAllowed);
    function checkCombination(uint256 lotteryId, bytes32 hash) public view returns(bool isWinning);
    function getWinningCombination(uint256 lotteryId) public view returns(uint8 winningDigit1, uint8 winningDigit2, uint8 winningDigit3);
    function setWinningCombination(uint8 digit1, uint8 digit2, uint8 digit3) public returns (uint8);
    function getCurrentLotteryId() public view returns(uint256);
    function getNextLotteryStart() public view returns(uint256);
}