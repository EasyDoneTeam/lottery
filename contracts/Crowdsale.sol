pragma solidity ^0.4.24;

import "./owner.sol";
import "./interfaces/IERC20.sol";
import './libraries/SafeMath.sol';
import './interfaces/ICrowdsale.sol';

contract Crowdsale is Ownable, ICrowdsale
{
    using SafeMath for uint256;

    address public multisigContractAddress;
    IERC20 public tokenContract;

    uint256 public deadline;
    uint256 public bonusDeadline;
    uint256 public priceMultiplier;
    uint256 public bonusPriceDivider;
    uint256 public bonusPercentage;
    uint256 public investorCount;
    uint256 public tokensSold;
    //uint256 public leftSold;

    bool private fundingGoalReached = false;
    bool private crowdsaleClosed = false;

    event GoalReached(address recipient);
    event FundTransfer(address backer, uint amount);
    
    event BeforeDeadlineBonus(address investor);
    event EarlyInvestorBonus(address investor);
    event AdditionalBonus(address investor);

    constructor (address _multisigContractAddress, address _tokenAddress) public
    {
        multisigContractAddress = _multisigContractAddress;
        setERC20TokenAddress(_tokenAddress);

        deadline = now + 10080 minutes;
        bonusDeadline = now + 2880 minutes;
        priceMultiplier = 4;
        bonusPriceDivider = 225;
        bonusPercentage = 20;
        investorCount = 0;
        tokensSold = 0;
        //leftSold = 40000e18;
    }

    function setERC20TokenAddress(address tokenAddress) private
    {
        tokenContract = IERC20(tokenAddress);
    }

    function estimateTokens(uint weiAmount) public view returns(uint tokenEstimation)
    {
        uint tokens;

        if (now <= bonusDeadline)
        {
            tokens = (weiAmount * 1000) / bonusPriceDivider;
        }
        else
        {
            tokens = weiAmount * priceMultiplier;
        }

        if (investorCount <= 4)
        {
            tokens += (tokens / 100) * bonusPercentage;
        }

        uint256 additionalBonus = tokens / 100000000000000000000;
        if(additionalBonus > 0)
        {
            tokens = tokens.add(additionalBonus * 1000000000000000000);
        }

        return tokens;
    }

    function() payable public
    {
        require(!crowdsaleClosed, "Crowdsale is closed already.");

        uint amount = msg.value;
        require(amount != 0, "You have to send some ETH to Crowdsale.");

        uint tokensForTransfer;
        if (now <= bonusDeadline)
        {
            tokensForTransfer = (amount * 1000) / bonusPriceDivider;
            emit BeforeDeadlineBonus(msg.sender);
        }
        else
        {
            tokensForTransfer = amount * priceMultiplier;
        }

        if (investorCount <= 4)
        {
            tokensForTransfer += (tokensForTransfer / 100) * bonusPercentage;
            emit EarlyInvestorBonus(msg.sender);
        }

        uint256 additionalBonus = tokensForTransfer / 100000000000000000000;
        if(additionalBonus > 0)
        {
            tokensForTransfer = tokensForTransfer.add(additionalBonus * 1000000000000000000);
            emit AdditionalBonus(msg.sender);
        }

        uint256 currentCrowdsaleBalance = tokenContract.balanceOf(this);

        //if(tokensForTransfer > leftSold)
        if (tokensForTransfer > currentCrowdsaleBalance)
        {
            //uint availablePercentage = (leftSold * 100) / tokensForTransfer;
            uint availablePercentage = (currentCrowdsaleBalance * 100) / tokensForTransfer;
            uint returnAmount = (amount * (100 - availablePercentage)) / 100;
            amount = amount.sub(returnAmount);

            //tokensForTransfer = leftSold;
            tokensForTransfer = currentCrowdsaleBalance;
            msg.sender.transfer(returnAmount);
        }

        multisigContractAddress.transfer(amount);
        tokenContract.transfer(msg.sender, tokensForTransfer);
        tokensSold = tokensSold.add(tokensForTransfer);
        //leftSold = leftSold.sub(tokensForTransfer);
        emit FundTransfer(msg.sender, amount);

        investorCount = investorCount.add(1);
    }

    modifier afterDeadline()
    {
        if (now >= deadline)
            _;
    }

    modifier beforeDeadline()
    {
        if (now < deadline)
            _;
    }

    function checkGoalReached() public afterDeadline
    {
        //if(leftSold == 0)
        if (tokenContract.balanceOf(this) == 0)
        {
            fundingGoalReached = true;
            emit GoalReached(multisigContractAddress);
        }
        crowdsaleClosed = true;
    }

    function isCrowdsaleClosed() public view returns(bool)
    {
        return crowdsaleClosed;
    }

    function getInvestorCount() public view returns(uint256)
    {
        return investorCount;
    }

    function getTokensSold() public view returns(uint256)
    {
        return tokensSold;
    }
}