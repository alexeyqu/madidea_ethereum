var getAllProposals = function(getProposalsLength, getProposal, address) {
    var length = getProposalsLength(address);
    for (var i = 0; i < length; ++i) {
        var proposal = getProposal(address, i);
        console.log(proposal);
        document.getElementById('task-list').innerHTML += '<div class="button-form proposal" onclick="window.location.href = \'task.html?pid='
        + proposal[0] + '&from=' + getFrom() + '\'">'
            + proposal[1] + '</div><br><br>'
        
    }
};

var role = getFrom();
if (role === 'employer') {
    getAllProposals(contract.getProposalsLengthForEmployer, contract.getProposalForEmployer, web3.eth.accounts[0]);
} else if (role === 'employee') {
    getAllProposals(contract.getProposalsLengthForEmployee, contract.getProposalForEmployee, web3.eth.accounts[0]);
} else if (role === 'judge') {
    getAllProposals(contract.getProposalsLengthForJudge, contract.getProposalForJudge, web3.eth.accounts[0]);
}

