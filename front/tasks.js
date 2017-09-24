contract.allEvents().watch(function(error, event) {
    if (error) {
        console.log(error);
    }
    if (event.event === 'ProposalCreated') {
        document.getElementById('task-list').innerHTML += '<div class="description-line proposal" data-id="' + event.proposalId.c[0] + '">'
            + event.proposalName + '</div>' 
        var proposals = document.getElementByClassName('proposal');
        proposal[proposal.length - 1].onclick = function() {
            window.location.href = 'task.html?pid=' + proposal[proposal.length - 1].dataset.id + '&from=' + getFrom();
        }
    }
}

var role = getFrom();
if (role === 'employer') {
    contract.getAllProposalsForEmployer(web3.eth.accounts[0]);
else if (role === 'employee') {
    contract.getAllProposalsForEmployee(web3.eth.accounts[0]);
else if (role === 'judge') {
    contract.getAllProposalsForJudge(web3.eth.accounts[0]);
}


document.getElementsByClassName('proposal');
