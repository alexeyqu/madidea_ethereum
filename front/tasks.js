var getAllProposals = function(getProposalsLength, getProposal, address) {
    var length = getProposalsLength(address);
    for (var i = 0; i < length; ++i) {
        var proposal = getProposal(address, i);
        console.log(proposal);
        document.getElementById('task-list').innerHTML += '<div class="button-form proposal">'
            + proposal[1] + '</div>'
        var proposals = document.getElementsByClassName('proposal');
        proposals[proposals.length - 1].onclick = function() {
            window.location.href = 'task.html?pid=' + proposal[0] + '&from=' + getFrom();
        }
    }
};

var role = getFrom();
if (role === 'employer') {
    getAllProposals(contract.getProposalsLengthForEmployer, contract.getProposalForEmployer, web3.eth.accounts[0]);
} else if (role === 'employee') {
    var length = contract.getProposalsLengthForEmployee(web3.eth.accounts[0]);
} else if (role === 'judge') {
    var length = contract.getProposalsLengthForJudge(web3.eth.accounts[0]);
}

