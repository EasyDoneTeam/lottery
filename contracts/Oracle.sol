pragma solidity ^0.4.24;

interface ILottery {
    function setWinningCombination( uint8 digit1,
        uint8 digit2,
        uint8 digit3,
        uint8 digit4) public returns (bytes32 status);
}

contract Oracle {

    ILottery public lottery;
    address public lotteryAddress;

    constructor (address _lotteryAddress) {
        lotteryAddress = _lotteryAddress;
        lottery = ILottery(_lotteryAddress);
    }

    function getLotteryAddress() public view returns(address lottery) {
        return lotteryAddress;
    }

    function setLotteryAddress (address _lottery) public {
        lottery = ILottery(_lottery);
        lotteryAddress = _lottery;
    }

    function setWinningCombinationForLottery(uint8 n1, uint8 n2, uint8 n3) public {
        lottery.setWinningCombination(n1, n2, n3, 0);
    }
}