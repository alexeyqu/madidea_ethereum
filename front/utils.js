var abi = "constant":false,"inputs":[{"name":"_proposalId","type":"uint256"},{"name":"_message","type":"string"},{"name":"_deadlineVoting","type":"uint256"}],"name":"openClaim","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[],"name":"acceptClaim","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[{"name":"claimId","type":"uint256"}],"name":"getMoneyAsJudge","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"}],"name":"getMoneyAsEmployee","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"}],"name":"acceptProposal","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"claimId","type":"uint256"}],"name":"finalizeClaim","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_taskDescription","type":"string"},{"name":"_numJudges","type":"uint8"},{"name":"daysToDeadline","type":"uint256"},{"name":"daysToClaimDeadline","type":"uint256"},{"name":"daysToVoteDeadline","type":"uint256"},{"name":"_employee","type":"address"}],"name":"createProposal","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[{"name":"claimId","type":"uint256"},{"name":"judgeId","type":"uint256"}],"name":"deleteJudge","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"kickUpClaims","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"claimId","type":"uint256"}],"name":"payJudgementFee","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[{"name":"claimId","type":"uint256"},{"name":"isEmployerInFavor","type":"bool"}],"name":"decideClaim","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"}],"name":"getMoneyAsEmployer","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"getNewClaim","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"},{"name":"_taskSolution","type":"string"}],"name":"updateSolution","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_id","type":"bytes32"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"proposalId","type":"uint256"}],"name":"ProposalCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"claimId","type":"uint256"}],"name":"ClaimOpened","type":"event"}]

var Web3 = require('web3');
var web3 = new Web3();
var contract = web3.eth.contract(abi).at('0x440ab529708ce0aF5bb3a4d77cfd270BEED701C5');

function getParam(url, param) {
    if (!url) url = window.location.search;
    var regex = new RegExp("[?&]" + param + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return results[2];
}

function getFrom(url) {
    getParam(url, "from");
}

function getProjectId(url) {
    getParam(url, "pid");
}


