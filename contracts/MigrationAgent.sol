pragma solidity ^0.4.24;

import "./owner.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20NEW.sol";

contract MigrationAgent is Ownable {
    address public sourceToken;
    address public targetToken;
    uint256 tokenSupply;

    IERC20 public tokenContract;
    IERC20NEW public targetContract;

    constructor(address _sourceToken) public {
        sourceToken = _sourceToken;
    }

    function setTargetToken(address _token) public onlyOwner {
        require(targetToken == address(0), "Not set target token");

        tokenContract = IERC20(sourceToken);
        tokenSupply = tokenContract.totalSupply();
        targetToken = _token;
        targetContract = IERC20NEW(_token);
    }

    function migrateFrom(address _from, uint _value) public {
        require(msg.sender == sourceToken, "Not permission");
        require(targetToken != address(0));
        safetyInvariantCheck(_value);
        targetContract.createToken(_from, _value);
    }

    function safetyInvariantCheck(uint _value) private {
        require(targetToken != address(0), "Tokens is out");
    }

    function finalizeMigration() public onlyOwner {
        safetyInvariantCheck(0);
        targetContract.finalizeMigration();
        sourceToken = address(0);
        targetToken = address(0);
        tokenSupply = 0;
    }
}
