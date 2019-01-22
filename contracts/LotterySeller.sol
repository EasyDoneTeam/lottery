pragma solidity ^0.4.24;

import "./owner.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IPrizeFundWallet.sol";
import "./interfaces/IProfitWallet.sol";

contract LotterySeller is Ownable
{
    IProfitWallet public profitWallet;
    IPrizeFundWallet public prizeFundWallet;
    //ILottery public lotteryAddress;
    address public lotteryAddress;
    IERC721 public ticketContract;

    uint public deadline;
    uint public start;
    uint public price;
    uint public lotteryLotNumber;

    mapping(uint => bool) public lotHistory;

    event ticketsSold(address buyer, uint ticketsSold);
    event newLotNumberSetup(uint lotNumber);

    constructor () public
    {
        start = now;
    }

    function setNewLotteryLot(uint _deadline, uint _start, uint _lotteryLotNumber) public {
        require(msg.sender == lotteryAddress, "Only Lottery can set New Lot");
        require(!lotHistory[_lotteryLotNumber], "You can not set number twice");
        deadline = _deadline;
        start = _start;
        lotteryLotNumber = _lotteryLotNumber;
        lotHistory[_lotteryLotNumber] = true;
        emit newLotNumberSetup(lotteryLotNumber);
    }

    function setPrice (uint _price) public onlyOwner{
        price = _price;
    }

    function setTicketAddress(address _ticketContractAddress) public onlyOwner
    {
        ticketContract = IERC721(_ticketContractAddress);
    }

    function setProfitWallet(address _profitWalletAddress) public onlyOwner
    {
        profitWallet = IProfitWallet(_profitWalletAddress);
    }

    function setPrizeFundWallet(address _prizeFundWalletAddress) public onlyOwner
    {
        prizeFundWallet = IPrizeFundWallet(_prizeFundWalletAddress);
    }

    function setLottery(address _lotteryAddress) public onlyOwner
    {
        //lotteryAddress = ILottery(_lotteryAddress);
        lotteryAddress = _lotteryAddress;
    }

    function buyTickets() public payable afterStart beforeDeadline
    {
        uint amount = msg.value;
        uint profitAmount;
        uint prizeAmount;
        uint ticketsToSale;

        ticketsToSale = amount / price;
        profitAmount = amount / 100 * 10;
        prizeAmount = amount / 100 * 90;

        profitWallet.receiveProfit.value(profitAmount)(lotteryLotNumber);
        prizeFundWallet.putFundsToPrizeWallet.value(prizeAmount)(lotteryLotNumber);

        for (uint i = 0; i < ticketsToSale; i++) {
            ticketContract.mint(msg.sender, lotteryLotNumber, deadline);
        }

        emit ticketsSold(msg.sender, ticketsToSale);
    }

    modifier afterStart()
    {
        require(now > start, "The sale for the current lottery lot is not opened");
        _;
    }

    modifier beforeDeadline()
    {
        require(now < deadline, "The sale for the current lottery lot is already closed");
        _;
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    } 

    function getPrice() public view returns (uint256) {
        return price;
    }

    function getSaleDeadline() public view returns (uint256) {
        return deadline;
    }

    function getSaleStart() public view returns (uint256) {
        return start;
    }
    
}
