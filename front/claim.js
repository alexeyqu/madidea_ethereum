var proposalId = getProposalId()

var openClaim = function() {
    contract.openClaim(proposalId, document.getElementsByName('message')[0].value,
        {from: web3.eth.accounts[0], value: document.getElementsByName('price')[0].value});
    window.location.href = 'task.html?from=employer&pid=' + proposalId;
}
