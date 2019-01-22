pragma solidity ^0.4.24;

import "./owner.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IProfitWallet.sol";
import "./interfaces/IPrizeFundWallet.sol";
import "./interfaces/ILotterySeller.sol";
import "./interfaces/ILottery.sol";

contract Lottery is Ownable
{
    using SafeMath for uint256;

    struct Combination
    {
        uint8 digit1;
        uint8 digit2;
        uint8 digit3;
        bool generated;
        uint256 dateTimeGenerated;
        bytes32 combinationHash;
    }
    mapping (uint => Combination) public lotteryHistory;
    uint256 public currentLotteryId;

    uint256 private currentLotteryStarted;
    uint256 private currentLotteryTicketSaleEnds;
    uint256 private currentLotteryResultsGeneration;
    uint256 private currentLotteryDividendsUnlocked;
    uint256 private currentLotteryRewardingUnlocked;
    uint256 private nextLotteryStart;

    bool private winningResultsGeneratedForCurrentLottery;
    bool private canReturnTicketsForCurrentLottery;
    bool private canRestartCurrentLottery;
    
    address public oracleAddress;
    IProfitWallet public profitWallet;
    IPrizeFundWallet public prizeFundWallet;
    ILotterySeller public lotterySeller;
    
    constructor () public
    {
        winningResultsGeneratedForCurrentLottery = false;
        canReturnTicketsForCurrentLottery = false;
        canRestartCurrentLottery = false;
        currentLotteryId = 0;
        nextLotteryStart = 0;
    }
    
    function setOracleAddress(address _oracleAddress) public onlyOwner
    {
        oracleAddress = _oracleAddress;
    }

    function setProfitWalletContract(address _profitWalletAddress) public onlyOwner
    {
        profitWallet = IProfitWallet(_profitWalletAddress);
    }

    function setPrizeFundWalletContract(address _prizeFundWallet) public onlyOwner
    {
        prizeFundWallet = IPrizeFundWallet(_prizeFundWallet);
    }

    function setLotterySellerContract(address _lotterySeller) public onlyOwner
    {
        lotterySeller = ILotterySeller(_lotterySeller);
    }

    /*function canNewLotteryStart() public view returns(bool canStart)
    {
        if(now >= nextLotteryStart)
        {
            return true;
        }
        return false;   
    }*/

    function startNewLottery() public returns(bool startedSuccessfully)
    {
        require(msg.sender == oracleAddress || msg.sender == address(this), "Only Oracle or Lottery itself can call this function.");
        
        if (!canRestartCurrentLottery)
        {
            require(now >= nextLotteryStart, "Less than 24 hours passed from last lottery.");
        }
        else
        {
            canRestartCurrentLottery = false;
        }
        
        winningResultsGeneratedForCurrentLottery = false;
        canReturnTicketsForCurrentLottery = false;
        currentLotteryId = currentLotteryId.add(1);
        currentLotteryStarted = now;
        // currentLotteryTicketSaleEnds = currentLotteryStarted.add(47 hours);
        // currentLotteryResultsGeneration = currentLotteryTicketSaleEnds.add(1 hours);
        // currentLotteryDividendsUnlocked = currentLotteryResultsGeneration.add(1 hours);
        // currentLotteryRewardingUnlocked = currentLotteryDividendsUnlocked.add(23 hours);
        // nextLotteryStart = currentLotteryRewardingUnlocked.add(24 hours);
        currentLotteryTicketSaleEnds = currentLotteryStarted.add(3 minutes);
        currentLotteryResultsGeneration = currentLotteryTicketSaleEnds.add(2 minutes);
        currentLotteryDividendsUnlocked = currentLotteryResultsGeneration.add(1 minutes);
        currentLotteryRewardingUnlocked = currentLotteryDividendsUnlocked.add(2 minutes);
        nextLotteryStart = currentLotteryRewardingUnlocked.add(2 minutes);

        lotterySeller.setNewLotteryLot(currentLotteryTicketSaleEnds, currentLotteryStarted, currentLotteryId);

        return true;
    }

    // called if Oracle failed to send the winning digits in functionCallTime
    // moves time of lottery
    // prize fund gets company profit for current lottery
    // players are able to return tickets and get ETH back or continue playing
    function moveLotteryTimeFrame() private
    {
        profitWallet.sendProfitToPrizeFundWallet(currentLotteryId);
        canReturnTicketsForCurrentLottery = true;
        // currentLotteryResultsGeneration = currentLotteryResultsGeneration.add(24 hours);
        // currentLotteryDividendsUnlocked = currentLotteryDividendsUnlocked.add(24 hours);
        // currentLotteryRewardingUnlocked = currentLotteryRewardingUnlocked.add(24 hours);
        // nextLotteryStart = nextLotteryStart.add(24 hours);
        currentLotteryResultsGeneration = currentLotteryResultsGeneration.add(5 minutes);
        currentLotteryDividendsUnlocked = currentLotteryDividendsUnlocked.add(5 minutes);
        currentLotteryRewardingUnlocked = currentLotteryRewardingUnlocked.add(5 minutes);
        nextLotteryStart = nextLotteryStart.add(5 minutes);
    }

    function isRewardingAllowed(uint256 lotteryId) public view returns(bool isAllowed)
    {
        if (lotteryId == currentLotteryId)
        {
            if (now >= currentLotteryRewardingUnlocked)
            {
                return true;
            }
        }
        else if (lotteryId < currentLotteryId)
        {
            return true;
        }
        return false;   
    }

    function isSubmittingTicketsForRewardAllowed(uint256 lotteryId) public view returns(bool)
    {
        if (lotteryId == currentLotteryId)
        {
            uint256 functionCallTime = now;
            if (winningResultsGeneratedForCurrentLottery && functionCallTime >= currentLotteryResultsGeneration && functionCallTime <= currentLotteryRewardingUnlocked)
            {
                return true;
            }
        }
        return false;   
    }

    function isSellingTicketsAllowed() public view returns(bool isAllowed)
    {
        uint256 functionCallTime = now;
        if (functionCallTime >= currentLotteryStarted && functionCallTime <= currentLotteryTicketSaleEnds)
        {
            return true;
        }
        return false;   
    }

    function isFillingTicketsAllowed(/*uint256 lotteryId*/) public view returns(bool isAllowed)
    {
        //if (lotteryId == currentLotteryId)
        //{
            uint256 functionCallTime = now;
            if (functionCallTime >= currentLotteryStarted && functionCallTime <= currentLotteryResultsGeneration)
            {
                return true;
            }
        //}
        return false;   
    }

    function isReturningTicketsForCurrentLotteryAllowed() public view returns(bool isAllowed)
    {
        return canReturnTicketsForCurrentLottery;   
    }

    /*function isWithdrawingDividendsAllowed(uint256 lotteryId) public view returns(bool isAllowed)
    {
        if (lotteryId == currentLotteryId)
        {
            uint256 functionCallTime = now;
            if(functionCallTime >= currentLotteryTicketSaleEnds && functionCallTime <= currentLotteryDividendsUnlocked)
            {
                return false;
            }
        }
        else if (lotteryId > currentLotteryId)
        {
            return false;
        }
        return true;   
    }*/

    function isTokensTransferAllowed() public view returns(bool)
    {
        if (currentLotteryId > 0) {
            uint256 functionCallTime = now;
            if(functionCallTime >= currentLotteryTicketSaleEnds && functionCallTime <= currentLotteryDividendsUnlocked)
            {
                return false;
            }
        }
        return true;   
    }

    function getNextLotteryStart() public view returns(uint256)
    {
        return nextLotteryStart;
    }

    function getPrizeDestributionTime() public view returns(uint256)
    {
        return currentLotteryRewardingUnlocked;
    }

    // compare ticket digits with winning digits
    function checkCombination(uint256 lotteryId, uint8 digit1, uint8 digit2, uint8 digit3) public view returns(bool isWinning)
    {
        Combination winningCombination = lotteryHistory[lotteryId];
        //require(winningCombination.digit1 != 0, "Winning combination hasn't been generated yet.");
        if (digit1 == winningCombination.digit1 && digit2 == winningCombination.digit2 && digit3 == winningCombination.digit3)
        {
            return true;
        }
        return false;
    }

    // get the winning digits
    function getWinningCombination(uint256 lotteryId) public view returns(uint8 winningDigit1, uint8 winningDigit2, uint8 winningDigit3)
    {
        Combination winningCombination = lotteryHistory[lotteryId];
        require(winningCombination.digit1 != 0, "Winning combination hasn't been generated yet for specified lottery.");
        return (winningCombination.digit1, winningCombination.digit2, winningCombination.digit3);
    }

    // get the winning hash
    function getWinningHash(uint256 lotteryId) public view returns(bytes32)
    {
        Combination winningCombination = lotteryHistory[lotteryId];
        require(winningCombination.digit1 != 0, "Winning combination hasn't been generated yet for specified lottery.");
        return winningCombination.combinationHash;
    }

    // called by Oracle, sets the winning digits
    /*bytes32 constant lateStatus = "LATE";
    bytes32 constant earlyStatus = "EARLY";
    bytes32 constant okStatus = "OK";
    bytes32 constant zeroFundsStatus = "ZERO_FUNDS";*/
    uint8 constant lateStatus = 2;
    uint8 constant earlyStatus = 3;
    uint8 constant okStatus = 1;
    uint8 constant zeroFundsStatus = 0;
    function setWinningCombination(uint8 digit1, uint8 digit2, uint8 digit3) public returns (uint8)  
    {
        require(msg.sender == oracleAddress, "Only Oracle can call this function.");

        Combination winningCombination = lotteryHistory[currentLotteryId];
        require(!winningCombination.generated, "Winning combination has already been generated.");

        if  (prizeFundWallet.getBalance() == 0)
        {
            canRestartCurrentLottery = true;
            startNewLottery();
            return zeroFundsStatus;
        }

        uint256 functionCallTime = now;
        if (functionCallTime < currentLotteryResultsGeneration.sub(1 minutes))
        {
            return earlyStatus;
        }
        else if (functionCallTime > currentLotteryResultsGeneration.add(1 minutes))
        {
            moveLotteryTimeFrame();
            return lateStatus;
        }
        else
        {
            lotteryHistory[currentLotteryId] = Combination(digit1, digit2, digit3, true, now, keccak256(abi.encodePacked(digit1, digit2, digit3)));
            //profitWallet.enableDividendWithdrawals(currentLotteryId);
            profitWallet.closeCurrentLap();
            return okStatus;
        }
    }

    function getCurrentLotteryId() public view returns(uint256)
    {
        return currentLotteryId;
    }

    function getLotteryResultsGeneration() public view returns(uint256) 
    {   
        if (now < currentLotteryResultsGeneration) {
            return currentLotteryResultsGeneration;
        } else {
            // uint256 next_start = nextLotteryStart.add(48 hours);
            uint256 next_start = nextLotteryStart.add(5 minutes);
            return next_start;
        }
    }
    
    function getLotteryState() public view returns (uint256)
    {
        if (now < currentLotteryResultsGeneration) {
            return 1;
        } else if ((now >= currentLotteryResultsGeneration || lotteryHistory[currentLotteryId].digit1 != 0) && now < currentLotteryRewardingUnlocked) {
            return 2;
        } else if (now >= currentLotteryRewardingUnlocked) {
            return 3;
        }
    }

    function getLotteryHistory(uint256 _lottery_id) public view returns(uint8 winningDigit1, uint8 winningDigit2, uint8 winningDigit3, uint256 dateTime)
    {
        Combination lotCombination = lotteryHistory[_lottery_id];
        
        return (lotCombination.digit1, lotCombination.digit2, lotCombination.digit3, lotCombination.dateTimeGenerated);
    }
}