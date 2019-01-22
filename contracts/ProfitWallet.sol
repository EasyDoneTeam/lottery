pragma solidity ^0.4.24;

import "./owner.sol";
import "./interfaces/IERC20.sol";


contract ProfitWallet is Ownable
{
    address public lottery_seller; // only he can send tokens to this contract
    IERC20  public token_contract; // our main tokens
    address public token_contract_address; // erc20 contract address
    address public profit_manager; // contract can send tokens only to him
    address public prize_fund_wallet; // lottery prize wallet address
    address public lottery; // lottery contact address

    uint public current_lap; // num of current lap
    uint private for_distribute; // profit for distribute

    mapping (uint => uint) private lottery_laps; // lapnum=>lap_balance

    struct ShareHolder{
        address shareholder;
        uint proportion;
        uint profit_balance;
    }
    ShareHolder[] private shareholders;

    mapping (address => uint) private index_shareholders;

    constructor () public
    {
        for_distribute = 0; // initial available profit for distribution
        current_lap = 0; // current lap's num
        shareholders.push(ShareHolder(0,0,0)); // initial array
    }

    function setERC20TokenAddress(address tokenAddress) public onlyOwner
    {
        token_contract = IERC20(tokenAddress);
        token_contract_address = tokenAddress;
    }

    function setPrizeFundWalletAddress(address _prizeFundWallet) public onlyOwner
    {
        prize_fund_wallet = _prizeFundWallet;
    }

    function setLotterySellerAddress(address _lotterySeller) public onlyOwner
    {
        lottery_seller = _lotterySeller;
    }

    function setLotteryAddress(address _lottery) public onlyOwner
    {
        lottery = _lottery;
    }

    function setProfitManagerAddress(address _profitManager) public onlyOwner
    {
        profit_manager = _profitManager;
    }

    // update shareholders
    function updateShareHolder(address _holder, uint _proportion) public onlyERC20
    {
        // set new shareholder
        if (index_shareholders[_holder] == 0){
            uint new_index = shareholders.push(ShareHolder(_holder, _proportion, 0));
            index_shareholders[_holder] = new_index-1;
        }
        // update exists shareholder
        else{
            uint _index = index_shareholders[_holder];
            shareholders[_index].proportion = _proportion;
        }
    }

    //receive profit for current lap from lottery contract
    function receiveProfit(uint _lap) payable public onlyLotterySeller
    {
        require(_lap>0, "Lap is required");
        require(msg.value > 0, "Amount of money must be bigger than 0");
        current_lap = _lap;
        for_distribute += msg.value;
        lottery_laps[_lap] += msg.value;
    }

    //calculate profit for shareholders
    function distributeProfit() private
    {
        for(uint i=0; i<shareholders.length; i++){
            require(for_distribute>0, "Profit for distributing is 0");
            ShareHolder storage _item = shareholders[i];
            // shareholder, proportion, profit_balance
            uint val = (_item.proportion * for_distribute)/1e18;
            _item.profit_balance += val;
            for_distribute -= val;
        }
    }

    //close current lap and distribute profit. external callable
    function closeCurrentLap() public onlyLottery
    {
        if (for_distribute > 0){
            distributeProfit();
            for_distribute = 0;
        }
    }

    // send shareholder's profit to him
    function payToShareholder(address _shareholder, address recepient) public onlyProfitManager
    {
        // check incoming params
        require(_shareholder != address(0), "Address of shareholder is required");

        // check lap's data for exist
        uint _index = index_shareholders[_shareholder];
        require(_index>0, "ShareHolder is not registered");

        uint available_balance = shareholders[_index].profit_balance;
        require(available_balance>0, "This ShareHolder has not available money on his balance");
        shareholders[_index].profit_balance = 0;

        // return profit to holder
        recepient.transfer(available_balance);
    }

    function sendProfitToPrizeFundWallet(uint256 lotteryId) public
    {
        require(msg.sender == lottery, "Only Lottery Contract can call this function.");
        
        //send all profit for lottery with ID == lotteryId to prize_fund_wallet
        //uint256 lapBalance = lottery_laps[lotteryId].lapBalance;
        //lottery_laps[lotteryId].profitLost = true;
        //lottery_laps[lotteryId].profitUsed = lapBalance;
        //lottery_laps[lotteryId].lapBalance = 0;
        
        //prize_fund_wallet.transfer(lapBalance);
    }

    function getShareholderUnpaidDividends() public view returns (uint256)
    {
        // check lap's data for exist
        uint _index = index_shareholders[msg.sender];
        require(_index > 0, "ShareHolder is not registered");

        return shareholders[_index].profit_balance;
    }

   function getShareholderPortion(address _address) public view onlyOwner returns (uint256)
    {
        // check lap's data for exist
        uint _index = index_shareholders[_address];
        require(_index > 0, "ShareHolder is not registered");

        return shareholders[_index].proportion;
    }
    
    function getShareholderIndex(address _address) public view onlyOwner returns (uint256)
    {
        uint _index = index_shareholders[_address];
        return _index;
    }
    
    function getShareholder(address _address) public view  onlyOwner returns (address, uint, uint)
    {
        uint _index = index_shareholders[_address];

        return (shareholders[_index].shareholder, shareholders[_index].proportion, shareholders[_index].profit_balance);
    }
    
    function getForDistribute() public view  onlyOwner returns (uint256)
    {
       return for_distribute;
    }

    modifier onlyProfitManager()
    {
        require(msg.sender == profit_manager, "Only Profit Manager Contract can take ETH from here!");
        _;
    }

    modifier onlyERC20()
    {
        require(msg.sender == token_contract_address, "Only ERC20 Contract can update shareholder's balance!");
        _;
    }

    modifier onlyLotterySeller()
    {
        require(msg.sender == lottery_seller, "Only Lottery Seller Contract can put ETH here!");
        _;
    }

    modifier onlyLottery()
    {
        require(msg.sender == lottery, "Only Lottery Contract can close current lap of lottery");
        _;
    }

    function () public payable {
        revert("Does not Accept EHT directly");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
