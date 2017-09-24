
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

var contractAddress = "0xeDFC9c2F4Cfa7495c1A95CfE1cB856F5980D5e18";

var userAddress = '0x004ec07d2329997267Ec62b4166639513386F32E'; // to be taken from form

var contract = web3.eth.contract(ABI).at(contractAddress);

contract.say(function(error, result) {
    console.log(error, result);
});
contract.change.sendTransaction("allo", {'from': userAddress}, function(error, result) {
    console.log(error, result);
});