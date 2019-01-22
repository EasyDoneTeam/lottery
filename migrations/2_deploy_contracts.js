const Crowdsale = artifacts.require("Crowdsale");
const ERC20 = artifacts.require("ERC20");
const ERC20_New = artifacts.require("ERC20_New");
const MigrationAgent = artifacts.require("MigrationAgent");
const MultiSigWallet = artifacts.require("MultiSigWallet");
const PrizeFundWallet = artifacts.require("PrizeFundWallet");
const PrizeFundManager = artifacts.require("PrizeFundManager");
const ProfitManager = artifacts.require("ProfitManager");
const ProfitWallet = artifacts.require("ProfitWallet");
const ERC721 = artifacts.require("ERC721");
const Lottery = artifacts.require("Lottery");
const LotterySeller = artifacts.require("LotterySeller");
const MigrationAgent721 = artifacts.require("MigrationAgent721");

module.exports = async deployer => {
  return deployer.deploy(ERC20, "ERC20", "ERC20",
    "0x16a064d87e5fc3d2014ba9dcf4d8f9f22d7833d6",
    "0xb4318a0c980b073ff8f50754cc878c3876ea162b",
    "0x20d54aa08e2d9fe33ac35eff1c85665341cfe9a0",
    "0x5c5aca5c09b321ccd944401b45ebcb613b17fa4c"
  )
    .then((ERC20Instance) => {
      console.log('1 ERC20: ', ERC20.address);
      return deployer.deploy(MultiSigWallet).then(() => {
        console.log('2 MultiSigWallet: ', MultiSigWallet.address);
        return deployer.deploy(MigrationAgent, ERC20.address).then((MigrationAgentInstance) => {
          console.log('3 MigrationAgent: ', MigrationAgent.address);
          return deployer.deploy(Crowdsale, MultiSigWallet.address, ERC20.address).then(() => {
            console.log('4 Crowdsale: ', Crowdsale.address);
            return deployer.deploy(ERC721, "ERC721", "ERC721").then((ERC721Instance) => {
              console.log('5 ERC721: ', ERC721.address);
              return deployer.deploy(LotterySeller).then((LotterySellerInstance) => {
                console.log('6 LotterySeller: ', LotterySeller.address);
                return deployer.deploy(PrizeFundWallet).then((PrizeFundWalletInstance) => {
                  console.log('7 PrizeFundWallet: ', PrizeFundWallet.address);
                  return deployer.deploy(PrizeFundManager).then((PrizeFundManagerInstance) => {
                    console.log('8 PrizeFundManager: ', PrizeFundManager.address);
                    return deployer.deploy(ProfitManager).then((ProfitManagerInstance) => {
                      console.log('9 ProfitManager: ', ProfitManager.address);
                      return deployer.deploy(Lottery).then((LotteryInstance) => {
                        console.log('10 Lottery: ', Lottery.address);
                        return deployer.deploy(ProfitWallet).then((ProfitWalletInstance) => {
                          console.log('11 ProfitWallet: ', ProfitWallet.address);
                          return deployer.deploy(MigrationAgent721, ERC721.address).then((MigrationAgent721Instance) => {
                            console.log('12 MigrationAgent721: ', MigrationAgent721.address);
                            return deployer.deploy(ERC20_New, 
                                                  "ERC20", 
                                                  "ERC20",)
                                                  .then((ERC20_NewInstance) => {
                              console.log('13 ERC20_New: ', ERC20_New.address);
                              
                              MigrationAgentInstance.setTargetToken(ERC20_New.address);

                              ERC20Instance.setLottery(Lottery.address);
                              ERC20Instance.setCrowdsale(Crowdsale.address);
                              ERC20Instance.setProfitWallet(ProfitWallet.address);
                              
                              ERC721Instance.setLotteryAddress(Lottery.address);
                              ERC721Instance.setLotterySellerContract(LotterySeller.address);
                              //ERC721Instance.setMigrationAgent(MigrationAgent721.address);
                              LotterySellerInstance.setTicketAddress(ERC721.address);
                              LotterySellerInstance.setProfitWallet(ProfitWallet.address);
                              LotterySellerInstance.setPrizeFundWallet(PrizeFundWallet.address);
                              LotterySellerInstance.setLottery(Lottery.address);
                              LotterySellerInstance.setPrice(50000000000000000);
                              PrizeFundWalletInstance.init(LotterySeller.address, ProfitWallet.address, PrizeFundManager.address);
                              PrizeFundManagerInstance.setLotteryAddress(Lottery.address);
                              PrizeFundManagerInstance.setPriceFundWallet(PrizeFundWallet.address);
                              PrizeFundManagerInstance.setERC721(ERC721.address);
                              ProfitManagerInstance.setProfitWalletAddress(ProfitWallet.address);
                              //LotteryInstance.setOracleAddress("0x");
                              LotteryInstance.setProfitWalletContract(ProfitWallet.address);
                              LotteryInstance.setPrizeFundWalletContract(PrizeFundWallet.address);
                              LotteryInstance.setLotterySellerContract(LotterySeller.address);
                              ProfitWalletInstance.setERC20TokenAddress(ERC20.address);
                              ProfitWalletInstance.setPrizeFundWalletAddress(PrizeFundWallet.address);
                              ProfitWalletInstance.setLotterySellerAddress(LotterySeller.address);
                              ProfitWalletInstance.setLotteryAddress(Lottery.address);
                              ProfitWalletInstance.setProfitManagerAddress(ProfitManager.address);

                              ERC20Instance.setPortion("0x16a064d87e5fc3d2014ba9dcf4d8f9f22d7833d6");
                              ERC20Instance.setPortion("0xb4318a0c980b073ff8f50754cc878c3876ea162b");
                              ERC20Instance.setPortion("0x20d54aa08e2d9fe33ac35eff1c85665341cfe9a0");
                              ERC20Instance.setPortion("0x5c5aca5c09b321ccd944401b45ebcb613b17fa4c");

                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
};