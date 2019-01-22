pragma solidity ^0.4.24;

import "./interfaces/ILottery.sol";
import "./interfaces/IERC721NEW.sol";
import "./libraries/SafeMath.sol";
import "./owner.sol";

contract ERC721NEW is IERC721NEW, Ownable
{

  using SafeMath for uint256;

  struct lotteryTicket
  {
    address tokenOwner;
    bytes32 encodedDigit1;
    bytes32 encodedDigit2;
    bytes32 encodedDigit3;
    bytes32 secretPhraseHash;
    bytes32 combinationHash;
    uint lotteryDeadline;
  }
  mapping (uint256 => uint256[]) private lotteryTickets;
  mapping (uint256 => mapping(address => uint256[])) private lotteryUsersTickets;

  string public tokenName;
  string public tokenSymbol;
  uint256 public totalSupply;
  address public lotteryContract;
  uint256 public tokenIdCounter;

  mapping (uint256 => lotteryTicket) private tokens;
  mapping (uint256 => address) private tokenApprovals;
  mapping (address => uint256) private ownedTokensCount;

  ILottery private lottery;
  address public migrationAgent;
  bool private is_migrated; // is the contract migrated.
  mapping (address => uint) private migrated_clients;
  uint private totalMigrated;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event Migrate(address indexed from, address indexed who, uint256 indexed count_tokens);
  event TicketFilled(address indexed owner, uint256 indexed tokenId);

  constructor(string _tokenName, string _tokenSymbol, address lotteryAddress) public
  {
    tokenName = _tokenName;
    tokenSymbol = _tokenSymbol;
    totalSupply = 0;
    tokenIdCounter = 0;
    setLotteryAddress(lotteryAddress);
    is_migrated = false;
    totalMigrated = 0;
  }

  function setLotteryAddress(address lotteryAddress) public onlyOwner
  {
      lottery = ILottery(lotteryAddress);
  }

  function setLotterySellerContract(address _lottery_seller) public
  {
    require(lotteryContract == 0, "Lottery Contract has already been specified.");
    require(msg.sender == owner, "Lottery Contract can be set only by contract Owner.");
    lotteryContract = _lottery_seller;
  }

  function balanceOf(address owner) public view returns (uint256)
  {
    require(owner != address(0), "Invalid address.");
    return ownedTokensCount[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address)
  {
    address owner = tokens[tokenId].tokenOwner;
    require(owner != address(0), "Invalid address.");
    return owner;
  }

  function approve(address to, uint256 tokenId) public
  {
    address owner = ownerOf(tokenId);
    require(to != owner, "Invalid address.");
    require(msg.sender == owner, "Function can be called only from account-owner of the specified token.");

    tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address)
  {
    require(exists(tokenId), "Specified token doesn't exist.");
    return tokenApprovals[tokenId];
  }

  function transferFrom(address from, address to, uint256 tokenId) public
  {
    require(isApprovedOrOwner(msg.sender, tokenId), "Calling address is not an owner and not allowed to transfer the specified token.");
    require(ownerOf(tokenId) == from, "Specified from address is not the owner of the specified token.");
    require(to != address(0), "Invalid address.");

    clearApproval(from, tokenId);
    removeTokenFrom(from, tokenId);

    addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  function exists(uint256 tokenId) internal view returns (bool)
  {
    address owner = tokens[tokenId].tokenOwner;
    return owner != address(0);
  }

  function isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool)
  {
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender);
  }

  function mint(address to, uint256 lotteryId, uint256 lotteryDeadline) public returns(uint256 tokenId)
  {
    require(msg.sender == lotteryContract, "Only Lottery contract can mint the lottery tickets.");
    require(to != address(0), "Invalid address.");

    uint256 createdTokenId = tokenIdCounter;

    addTokenTo(to, createdTokenId);
    tokens[createdTokenId].lotteryDeadline = lotteryDeadline;
    lotteryTickets[lotteryId].push(createdTokenId);
    lotteryUsersTickets[lotteryId][to].push(createdTokenId);
    emit Transfer(address(0), to, createdTokenId);

    totalSupply = totalSupply.add(1);
    tokenIdCounter = tokenIdCounter.add(1);

    return createdTokenId;
  }

  //function fillLotteryTicket(uint256 tokenId, uint8 digit1, uint8 digit2, uint8 digit3) public
  function fillLotteryTicket(uint256 tokenId, bytes32 encodedDigit1, bytes32 encodedDigit2, bytes32 encodedDigit3, uint8 digit1, uint8 digit2, uint8 digit3, bytes32 secretPhraseHash) public
  {
    require(exists(tokenId), "Specified token doesn't exist.");
    require(msg.sender == tokens[tokenId].tokenOwner, "Only ticket owner can fill a lottery ticket.");
    //require(now < tokens[tokenId].lotteryDeadline, "Too late for filling a ticket.");
    require(lottery.isFillingTicketsAllowed(), "Too late for filling a ticket.");

    //require(digit1 >= 1 && digit1 <= 99, "Digit 1 is not between 1 and 99.");
    //require(digit2 >= 1 && digit2 <= 99, "Digit 2 is not between 1 and 99.");
    //require(digit3 >= 1 && digit3 <= 99, "Digit 3 is not between 1 and 99.");
    //require(digit1 == digit2 || digit1 == digit3 || digit2 == digit3, "All digits should be unique.");
    //tokens[tokenId].hash = keccak256(abi.encodePacked(digit1, digit2, digit3));

    tokens[tokenId].encodedDigit1 = encodedDigit1;
    tokens[tokenId].encodedDigit2 = encodedDigit2;
    tokens[tokenId].encodedDigit3 = encodedDigit3;
    tokens[tokenId].secretPhraseHash = secretPhraseHash;
    tokens[tokenId].combinationHash = keccak256(abi.encodePacked(digit1, digit2, digit3));

    emit TicketFilled(msg.sender, tokenId);
  }

  function getLotteryTicketHash(uint256 tokenId) public view returns(bytes32) 
  {
     return tokens[tokenId].combinationHash;
  }

  function burn(uint256 tokenId) internal
  {
    address owner = ownerOf(tokenId);
    clearApproval(owner, tokenId);
    removeTokenFrom(owner, tokenId);

    totalSupply = totalSupply.sub(1);
    emit Transfer(owner, address(0), tokenId);
  }

  function addTokenTo(address to, uint256 tokenId) internal
  {
    require(tokens[tokenId].tokenOwner == address(0), "Invalid address.");

    tokens[tokenId].tokenOwner = to;
    ownedTokensCount[to] = ownedTokensCount[to].add(1);
  }

  function removeTokenFrom(address from, uint256 tokenId) internal
  {
    ownedTokensCount[from] = ownedTokensCount[from].sub(1);
    tokens[tokenId].tokenOwner = address(0);
  }

  function clearApproval(address owner, uint256 tokenId) private
  {
    if (tokenApprovals[tokenId] != address(0))
    {
      tokenApprovals[tokenId] = address(0);
    }
  }

  function getTokenData(uint256 _token_id) public view returns (address tokenOwner, bytes32 encodedDigit1, bytes32 encodedDigit2, bytes32 encodedDigit3, bytes32 secretPhraseHash,
  uint lotteryDeadline) {
      return (tokens[_token_id].tokenOwner, tokens[_token_id].encodedDigit1, tokens[_token_id].encodedDigit2, tokens[_token_id].encodedDigit3,
      tokens[_token_id].secretPhraseHash, tokens[_token_id].lotteryDeadline);
  }

  function getLotteryTickets(uint256 _lottery_id) public view returns(uint256[]) {
     return lotteryTickets[_lottery_id];
  }

  function getUsersTickets(uint256 _lottery_id) public view returns(uint256[]) {
        return lotteryUsersTickets[_lottery_id][msg.sender];
  }

  function TEST_GET_TICKET_ENCODED_DIGITS_AND_SECRET(uint256 lotteryId, uint256 tokenId) public view returns (bytes32 encodedDigit1, bytes32 encodedDigit2, bytes32 encodedDigit3, bytes32 secretPhraseHash)
  {
    uint256[] array = lotteryTickets[lotteryId];
    for (uint i = 0; i < array.length; i++)
    {
        if(array[i] == tokenId)
        {
            return (tokens[tokenId].encodedDigit1, tokens[tokenId].encodedDigit2, tokens[tokenId].encodedDigit3, tokens[tokenId].secretPhraseHash);
        }
    }
  }

  // migration part
  function receiveMigratedData(address _client, bytes32[] _digs, bytes32 _secret, uint _lap, uint _deadline, bytes32 _combinationHash, uint _ticket) external {
    require(msg.sender == migrationAgent, "Only Migration agent can calls this method");

    //lotteryTicket memory new_ticket = lotteryTicket(_client, _digs[0], _digs[1], _digs[2], _secret, _deadline);
    tokens[_ticket] = lotteryTicket(_client, _digs[0], _digs[1], _digs[2], _secret, _combinationHash, _deadline);

    lotteryTickets[_lap].push(_ticket);
    lotteryUsersTickets[_lap][_client].push(_ticket);
    totalSupply += 1;
  }

  function setMigrationAgent(address _agent) external {
        require(migrationAgent == 0, "Migration agent is specified already!!!");
        require(msg.sender == owner, "Only Owner can setup Migration agent!!!");
        require(is_migrated == false, 'Contract was migrated already');
        migrationAgent = _agent;
  }


  function finalizeMigration() public{
        require(msg.sender == migrationAgent, "Only Migration agent can do it!!!");
        migrationAgent = 0;
        is_migrated = true;
  }
}