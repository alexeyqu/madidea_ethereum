var abi = [{"constant":false,"inputs":[{"name":"_proposalId","type":"uint256"},{"name":"_message","type":"string"},{"name":"_deadlineVoting","type":"uint256"}],"name":"openClaim","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[],"name":"acceptClaim","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[{"name":"claimId","type":"uint256"}],"name":"getMoneyAsJudge","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"}],"name":"getMoneyAsEmployee","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_employee","type":"address"}],"name":"getAllProposalsForEmployee","outputs":[],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_employer","type":"address"}],"name":"getAllProposalsForEmployer","outputs":[],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"}],"name":"acceptProposal","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"},{"name":"isEmployerInFavor","type":"bool"}],"name":"decideClaimByProposal","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_name","type":"string"},{"name":"_taskDescription","type":"string"},{"name":"_numJudges","type":"uint8"},{"name":"daysToDeadline","type":"uint256"},{"name":"daysToClaimDeadline","type":"uint256"},{"name":"daysToVoteDeadline","type":"uint256"},{"name":"_daysForIndividualVote","type":"uint256"},{"name":"_employee","type":"address"}],"name":"createProposal","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[{"name":"_judge","type":"address"}],"name":"getAllProposalsForJudge","outputs":[],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"claimId","type":"uint256"},{"name":"isEmployerInFavor","type":"bool"}],"name":"decideClaim","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"}],"name":"getMoneyAsEmployer","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"getNewClaim","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"proposalId","type":"uint256"},{"name":"_taskSolution","type":"string"}],"name":"updateSolution","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"},{"indexed":false,"name":"proposalId","type":"uint256"}],"name":"createProposalResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"}],"name":"updateSolutionResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"}],"name":"acceptProposalResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"},{"indexed":false,"name":"claimId","type":"uint256"}],"name":"openClaimResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"},{"indexed":false,"name":"clainId","type":"uint256"}],"name":"getNewClaimResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"}],"name":"acceptClaimResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"}],"name":"decideClaimResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"}],"name":"getMoneyAsEmployerResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"}],"name":"getMoneyAsEmployeeResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"}],"name":"getMoneyAsJudgeResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"},{"indexed":false,"name":"proposalId","type":"uint256"},{"indexed":false,"name":"proposalName","type":"string"}],"name":"getAllProposalsForEmployeeResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"},{"indexed":false,"name":"proposalId","type":"uint256"},{"indexed":false,"name":"proposalName","type":"string"}],"name":"getAllProposalsForEmployerResult","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"success","type":"bool"},{"indexed":false,"name":"proposalId","type":"uint256"},{"indexed":false,"name":"proposalName","type":"string"}],"name":"getAllProposalsForJudgeResult","type":"event"}];
var Web3 = require('web3');
var web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider('http://127.0.0.1:8545'));
var contract = web3.eth.contract(abi).at('0xBb01DA2F6B60593EdDF2f20D7f1375D21fFD067c');

function getFrom(url) {
    if (!url) url = window.location.search;
    var regex = new RegExp("[?&]" + "from" + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return results[2];
}

function watchEvents(callback) {
    var latest = web3.eth.getBlock('latest').number;
    contract.allEvents().watch(function (error, event) {
        if (event.blockNumber > latest) {
            callback(error, event);
        }
    });
}
