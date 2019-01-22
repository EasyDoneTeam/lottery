pragma solidity ^0.4.24;

contract IMigrationAgent721 {
    function finalizeMigration() external;
    function migrateToken(address _client, bytes32[] _digs, bytes32 _secret, uint _lap, uint _deadline, uint _ticket) public;
}