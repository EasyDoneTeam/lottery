pragma solidity ^0.4.24;

contract IERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event Migrate(address indexed from, address indexed who, uint256 indexed count_tokens);
  event TicketFilled(address indexed owner, uint256 indexed tokenId);

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId) public view returns (address operator);

  function transferFrom(address from, address to, uint256 tokenId) public;

  function mint(address to, uint256 lotteryId, uint256 lotteryDeadline) public returns(uint256 tokenId);
  function fillLotteryTicket(uint256 tokenId, bytes32 encodedDigit1, bytes32 encodedDigit2, bytes32 encodedDigit3, uint8 digit1, uint8 digit2, uint8 digit3, bytes32 secretPhraseHash) public;
  function getLotteryTicketHash(uint256 tokenId) public view returns(bytes32);

  function setLotteryAddress(address lotteryAddress) public;
  function setLotterySellerContract(address _lottery_seller) public;
  function setMigrationAgent(address _agent) external;
  function migrate(uint256 _value) external;
  function finalizeMigration() public;
}