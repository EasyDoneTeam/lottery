pragma solidity ^0.4.24;
import './AccessManager.sol';
import './StateStorage.sol';

contract Dispatcher is AccessManager {

    address public dataStorage;
    address public promotionToken;
    address public ticketToken;

    constructor(address _promotionToken, address _ticketToken, address _dataStorage) public {
        dataStorage = _dataStorage;
        promotionToken = _promotionToken;
        ticketToken = _ticketToken;
    }


    function setAddressDataStorage(address _newAddress) public isAccessManager(msg.sender) {
        dataStorage = _newAddress;
    }

    function setAddressPromotionToken(address _newAddress) public isAccessManager(msg.sender) {
        promotionToken = _newAddress;
    }

    function setAddressTicketToken(address _newAddress) public isAccessManager(msg.sender) {
        ticketToken = _newAddress;
    }

}
