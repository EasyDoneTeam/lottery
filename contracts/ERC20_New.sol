pragma solidity ^0.4.24;

import "./owner.sol";
import "./interfaces/IMigrationAgent.sol";
import "./interfaces/IProfitWallet.sol";
import "./interfaces/ILottery.sol";

contract ERC20_New is Ownable {
    string public name;
    string public symbol;
    uint public decimals = 18;
    uint public totalSupply;
    uint public totalMigrated;

    address public crowdsale;
    address public profitWallet;
    address public owner;
    address public migrationAgent;
    address public lottery;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    constructor (string tokenName, string tokenSymbol) public {
        totalSupply = 100000e18;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
        uint256 dev_amount = 15000e18;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balanceOf[tokenOwner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        if (msg.sender != crowdsale) {
            bool isAllowed = ILottery(lottery).isTokensTransferAllowed();
            require(isAllowed == true, "Tokens transfer closed, as dividends calculating.");
        }
        require(_value <= balanceOf[_from], "Not enough funds!!!");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        if (_from != crowdsale) {
            IProfitWallet(profitWallet).updateShareHolder(_from, getPortion(balanceOf[_from]));
        }    

        IProfitWallet(profitWallet).updateShareHolder(_to, getPortion(balanceOf[_to]));

        emit Transfer(_from, _to, _value);
    }

    function setPortion(address _to) public onlyOwner {
        IProfitWallet(profitWallet).updateShareHolder(_to, getPortion(balanceOf[_to]));
    }

    function getPortion(uint256 _amount) public view returns (uint256){
        return _amount*1e18 / totalSupply;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Not enough funds!!!");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    function setCrowdsale(address _crowdsale) external{
        require(crowdsale == 0, "Crowdsale is specified already!!!");
        require(msg.sender == owner, "Only Owner can set Crowdsale");
        crowdsale = _crowdsale;
        balanceOf[msg.sender] -= 40000e18;
        balanceOf[crowdsale] = 40000e18;
    }

    function setProfitWallet(address _profitWallet) external onlyOwner {
        profitWallet = _profitWallet;
    }   

    function setLottery(address _lottery) external onlyOwner {
        lottery = _lottery;
    }  

    function getProportion(address _owner) public view returns (uint256 proportion){
        return balanceOf[_owner] * 100e18 / totalSupply;
    }

    function () public payable {
        revert("This contact should not accept ETH");
    }

    function setMigrationAgent(address _agent) external {
        require(migrationAgent == 0, "Migration agent is specified already!!!");
        require(msg.sender == owner, "Only Owner can setup Migration agent!!!");
        migrationAgent = _agent;
    }

    function migrate(uint256 _value) external {
        require(migrationAgent != 0, "Migration agent is not specified!!!");
        require(_value != 0, "Value should be > 0!!!");
        require(_value <= balanceOf[msg.sender], "Not enough funds!!!");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        totalMigrated += _value;
        IMigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        emit Migrate(msg.sender, migrationAgent, _value);
    }

    function createToken(address _target, uint256 _amount) public{
        require(msg.sender == migrationAgent, "Only Migration agent can do it!!!");
        balanceOf[_target] += _amount;
        totalSupply += _amount;
        emit Transfer(migrationAgent, _target, _amount);
    }

    function finalizeMigration() public{
        require(msg.sender == migrationAgent, "Only Migration agent can do it!!!");
        migrationAgent = 0;
    }

}
