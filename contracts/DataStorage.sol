pragma solidity ^0.4.24;
import './ERC721.sol';
import './AccessManager.sol';
import './libraries/SafeMath.sol';

contract DataStorage is ERC721, AccessManager  {
    using SafeMath for uint;
    // Версия лотареи => Уникальный номер билета ERC721 => Содержимое Билета (тип struct)
    mapping(bytes32 => mapping( uint256 => ERC721)) public tokens;

    // Версия лотареи => суммарный выиграш
    mapping(bytes32 => uint) public prize;

    // Версия лотареи => Адресс победителя
    mapping(bytes32 => address) public winners;

    constructor() public {}

    function setLotteryMember(bytes32 _lottery, uint256 idToken, ERC721 token) public isAccessManager(msg.sender) {
        tokens[_lottery][idToken] = token;
    }

    function increasePrize(bytes32 _lottery, uint _value) public isAccessManager(msg.sender) {
        uint current = prize[_lottery];
        uint newPrize = current.add(_value);
        prize[_lottery] = newPrize;
    }

    function setWinner(bytes32 _lottery, address account) public isAccessManager(msg.sender) {
        winners[_lottery] = account;
    }
}
