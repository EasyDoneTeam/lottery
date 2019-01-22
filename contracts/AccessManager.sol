pragma solidity ^0.4.24;

contract AccessManager {

    mapping (address => bool) public accessManager;

    constructor(address dev1, address dev2, address dev3, address dev4){
        accessManager[dev1] = true;
        accessManager[dev2] = true;
        accessManager[dev3] = true;
        accessManager[dev4] = true;
    }

    modifier isAccessManager(address manager) {
        require(accessManager[manager], 'Not permission');
        _;
    }

    function transferOwnership(address newManager) public isAccessManager(msg.sender) {
        accessManager[newManager] = true;
    }
}