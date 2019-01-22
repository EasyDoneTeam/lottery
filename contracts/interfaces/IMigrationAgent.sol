pragma solidity ^0.4.24;

contract IMigrationAgent {
    function finalizeMigration() external;
    function migrateFrom(address _from, uint256 _value) public;
}