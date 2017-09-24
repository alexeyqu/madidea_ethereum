
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

var contractAddress = "0xeDFC9c2F4Cfa7495c1A95CfE1cB856F5980D5e18";

var contract = web3.eth.contract(ABI).at(contractAddress);
console.log(contract.say());