pragma solidity ^0.4.24;

import "./owner.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721NEW.sol";

contract MigrationAgent721 is Ownable {
    address source_ticket;
    address target_ticket;

    IERC721 public sourceContract;
    IERC721NEW public targetContract;

    constructor(address _source) public {
        source_ticket = _source;
    }

    function setTargetToken(address _new_ticket) public onlyOwner {
        require(target_ticket == 0, "Target contract initialized already");
        sourceContract = IERC721(source_ticket);
        targetContract = IERC721NEW(_new_ticket);
    }

    function safetyInvariantCheck(uint _value) private {
        require(target_ticket != 0, "Tokens is out");
    }

    function migrateToken(address _client, bytes32[] _digs, bytes32 _secret, uint _lap, uint _deadline, bytes32 _combinationHash, uint _ticket) public {
        require(msg.sender == source_ticket, "Only original contract can calls this method");
        targetContract.receiveMigratedData(_client, _digs, _secret, _lap, _deadline, _combinationHash, _ticket);
    }

    function finalizeMigration() public onlyOwner {
        safetyInvariantCheck(0);
        targetContract.finalizeMigration();
        source_ticket = 0;
        target_ticket = 0;
    }
}
