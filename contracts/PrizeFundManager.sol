pragma solidity ^0.4.24;
import "./owner.sol";

interface IERC721 {
    function getLotteryTicketHash(uint256 tokenId) public view returns(bytes32);
    function getTokenData(uint256 _tokenId) public view returns (
        address owner,
        uint8 encodedDigit1,
        uint8 encodedDigit2,
        uint8 encodedDigit3,
        bytes32 secretPhraseHash,
        uint lotteryDeadline);
}

interface ILottety {
    function getWinningHash(uint256 lotteryId) public view returns(bytes32);

    function getCurrentLotteryId() public view returns (uint256 _idLottery);
    function isSubmittingTicketsForRewardAllowed(uint256 lotteryId) public view returns(bool);
}

interface IWallet {
    function getBalance() public view returns (uint256);
    function getLotteryBalance(uint256 lotteryId) public returns(uint256);

    // Попросить дописать функцию
    function sendPrizeWinner(address winner, uint256 value);

}

contract PrizeFundManager is Ownable {
    event AddRequest (uint256 _tokenId);
    event PrizeSent (uint256 _tokenId, address sender, uint256 _prize);
    event PrizeNotSent (uint256 _tokenId, address sender);

    struct TicketInfo {
        uint256 tokenId;
        uint256 lotteryId;
        address ownerTicket;
        bytes32 secretPhraseHash;
        bool isGotPrize;
    }

    ILottety public lottery;
    IERC721 public erc721;
    IWallet public wallet;

    // lottery id => address winners
    mapping(uint256 => address[]) private winners;
    // lottery id => id tokens
    mapping(uint256 => uint256[]) private winnnerTickets;
    // lottery id => prize
    mapping (uint256 => uint256) public amountPrize;
    // Количесвство средст в лотерее
    mapping (uint256 => uint256) public jackpotAmount;

    TicketInfo[] private tickets;
    uint256 currentLotteryId;
    uint256 nextId;
    uint256 jackpot;

    constructor () public {
        nextId = 0;
        jackpot = 0;
    }

    function setLotteryAddress(address _lottery) public onlyOwner {
        lottery = ILottety(_lottery);
    }

    function setPriceFundWallet(address _wallet) public onlyOwner {
        wallet = IWallet(_wallet);
    }

    function setERC721(address _erc721) public onlyOwner {
        erc721 = IERC721(_erc721);
    }

    function checkTicket(bytes32 _ticketHash, address _owner, uint256 lotteryDeadline) private {
        require(_owner == msg.sender, "You can not add request!");
        require((lotteryDeadline + 24 hours) < now, "You can not add request!");
        bytes32 lotteryHash = lottery.getWinningHash(currentLotteryId);
        require(lotteryHash == _ticketHash, "You can not add request!");
    }


    // function setRequest(uint256 _tokenId) public {
    function setRequest(uint256 _tokenId, bytes32 _secretHash) public {
        bool has_request =false;
        for (var i = 0; i < tickets.length; i++) {
            if(tickets[i].tokenId == _tokenId) {
                has_request = true;
            }
        }
        require(has_request == false, "You have already add request!");
        var (_owner, encodedDigit1, encodedDigit2, encodedDigit3, secretPhraseHash, lotteryDeadline) = erc721.getTokenData(_tokenId);
        require(_secretHash == secretPhraseHash, "Secret phrase doesn't match.");
        bytes32 ticketHash = erc721.getLotteryTicketHash(_tokenId);
        currentLotteryId = lottery.getCurrentLotteryId();
        bytes32 lotteryHash = lottery.getWinningHash(currentLotteryId);

        //checkTicket(ticketHash, _owner, lotteryDeadline);
        require(_owner == msg.sender, "You can not add request!");
        //require(lottery.isSubmittingTicketsForRewardAllowed(currentLotteryId) == true, "You can not add request!");
        require(lotteryHash == ticketHash, "You can not add request!");

        winners[currentLotteryId].push(msg.sender);
        winnnerTickets[currentLotteryId].push(_tokenId);

        tickets.push(TicketInfo(_tokenId, currentLotteryId, _owner, secretPhraseHash, false));

        emit AddRequest(_tokenId);
    }

    function getPrize(uint256 _ticketID) public {
        bool prize_sent = false;
        uint256 prize_value = 0;
        for (var i = 0; i < tickets.length; i++) {
            if (tickets[i].ownerTicket == msg.sender) {
                if (tickets[i].isGotPrize == false && tickets[i].tokenId == _ticketID) {
                    prize_value = amountPrize[tickets[i].lotteryId];
                    wallet.sendPrizeWinner(tickets[i].ownerTicket, prize_value);
                    tickets[i].isGotPrize = true;
                    prize_sent = true;
                    break;
                }
            }
        }
        if (prize_sent) {
            emit PrizeSent(_ticketID, msg.sender, prize_value);
        } else {
            emit PrizeNotSent(_ticketID, msg.sender);
        }
    }

    // Проверка билета на возможность получения выиграша
    //  false false - 1) false - заявка не подана 2) false - выиграш не получен
    function checkRequest(address _owner, uint256 _ticket, uint256 _lottery) public view returns (bool isRequest, bool isGet) {
        for(var i = 0; i < tickets.length; i++) {
            if(tickets[i].tokenId == _ticket && tickets[i].lotteryId == _lottery) {
                //require(_owner == msg.sender, "You don't have permission");
                return (true, tickets[i].isGotPrize);
            }
        }
        return (false, false);
    }

    // Возвращение информации о джекпоте.
    function getDataJackpot (uint256 _lottery) public view returns (uint256 _jackpotAmount, uint256 prize, address[] addressWinners) {
        return (jackpotAmount[_lottery], amountPrize[_lottery], winners[_lottery]);
    }

    // Возвращение победителей по id лотереи
    function getWinners(uint256 _lottery) public view returns (address[] _winners) {
        return winners[_lottery];
    }

    // Возвращение выиграшных билетов по id лотереи
    function getWinnerTickets(uint256 _lottery) public view returns (uint256 [] _idTickets) {
        return winnnerTickets[_lottery];
    }

    function calculatePrize(uint256 _lotteryId)  public {
        uint256 totalPrize = wallet.getLotteryBalance(_lotteryId);
        uint countWinners = winners[_lotteryId].length;
        if (countWinners == 0) {
            jackpot += totalPrize;
            jackpotAmount[_lotteryId] = jackpot;
            amountPrize[_lotteryId] = 0;
        } else {
            jackpotAmount[_lotteryId] = totalPrize + jackpot;
            amountPrize[_lotteryId] = (totalPrize + jackpot) / countWinners;
            jackpot = 0;
        }
    }

    function getJackpot() public view returns (uint256) {
        return jackpot;
    }

    function() payable {
        revert();
    }
}