pragma solidity ^0.4.24;


contract ILotterySeller{
    event ticketsSold(address buyer, uint ticketsSold);
    event newLotNumberSetup(uint lotNumber);

    function setNewLotteryLot(uint _deadline, uint _start, uint _lotteryLotNumber) public;
    function setPrice (uint _price) public;
    function buyTickets() public payable;
}