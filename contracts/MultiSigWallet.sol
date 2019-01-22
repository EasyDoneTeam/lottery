pragma solidity ^0.4.24;

contract MultiSigWallet  {
    struct Transaction {
        address destination;
        uint value;
        bool executed;
    }

    event Confirmation(address owner, uint256 operation);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Transfer(uint indexed transactionId);

    uint constant public MAX_OWNER_COUNT = 5;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public transactionCount = 1;
    uint public required = 2;
    address tokenContract;

    constructor() public {
        isOwner[0x9d12f4d20efd2135ab5b50a26456dccfb6e15a3f] = true;
        isOwner[0xa9806f5cefa0ffde5e75b51d16a9eed0908f7463] = true;
        isOwner[0x20d54aa08e2d9fe33ac35eff1c85665341cfe9a0] = true;
        isOwner[0x33e0547fc6d1a1077226f0bf931c7e07ca91ac6e] = true;

        owners.push(0x9d12f4d20efd2135ab5b50a26456dccfb6e15a3f);
        owners.push(0xa9806f5cefa0ffde5e75b51d16a9eed0908f7463);
        owners.push(0x20d54aa08e2d9fe33ac35eff1c85665341cfe9a0);
        owners.push(0x33e0547fc6d1a1077226f0bf931c7e07ca91ac6e);
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "-------- owner exists -------");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0, "-------- transaction exists -------");
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner], "-------- not confirmed -------");
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0, "You can set address");
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, " ---- Transaction is already done -----");
        _;
    }

    function addOwner(address newOwner) public ownerExists(msg.sender) {
        require(owners.length < MAX_OWNER_COUNT, " ---- Limit exceeded -----");
        require(!isOwner[newOwner], "-------- This owner is already exists -------");
        owners.push(newOwner);
        isOwner[newOwner] = true;
    }

    function submitTransaction(address destination, uint value) public returns (uint transactionId) {
        transactionId = addTransaction(destination, value);
        confirmTransaction(transactionId);
    }

    function addTransaction(address destination, uint value) internal notNull(destination) returns (uint transactionId) {
        transactionId = ++transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            executed: false
            });
        emit Submission(transactionId);
        return transactionCount;
    }

    function confirmTransaction(uint transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {

        confirmations[transactionId][msg.sender] = true;
        executeTransaction(transactionId);
        emit Confirmation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId) public ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            transactions[transactionId].executed = true;
            emit Execution(transactionId);
        }
    }

    function revokeConfirmation(uint transactionId) public ownerExists(msg.sender) {
        transactions[transactionId].executed = false;
        emit ExecutionFailure(transactionId);
    }

    function isConfirmed(uint transactionId) public constant returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
        if (count >= required) {
            return true;
        } else {
            return false;
        }
    }

    function transfer(uint transactionId) public  {
        require(transactions[transactionId].executed, "Transaction is not allowed");
        require(transactions[transactionId].value != 0, "Can't equal 0");
        //require(crowdsaleContract.isCrowdsaleClosed(), "the transfer is not allow");
        if (isConfirmed(transactionId)) {
            transactions[transactionId].destination.transfer(transactions[transactionId].value);
            emit Transfer(transactionId);
        }
    }

    function() payable public {

    }
}
