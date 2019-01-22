module.exports = {
  networks: {
    testrpc: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
      gasPrice: 100000000000,
      gas: 6009618,
    },
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
      gasPrice: 1000000000,
      gas: 4500000,
    }
  }
}