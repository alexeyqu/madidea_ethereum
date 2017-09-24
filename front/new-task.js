contract.allEvents().watch(function(error, event) {
    if (error) {
        console.log(error);
    }
    if (event.event === 'ProposalCreated') {
        console.log(event);
        window.location.href = 'task.html?pid=' + event.args.proposalId.c[0];
    }
});

document.getElementById('create-task').onclick = function() {
    console.log('HEEY');
    contract.createProposal(
        document.getElementsByName('projectname')[0].value,
        document.getElementsByName('description')[0].value,
        document.getElementsByName('number-of-judges')[0].value,
        document.getElementsByName('work-deadline')[0].value,
        document.getElementsByName('claim-deadline')[0].value,
        document.getElementsByName('judge-deadline')[0].value,
        document.getElementsByName('judge-decision-deadline')[0].value,
        document.getElementsByName('employee')[0].value,
        {'from' : web3.eth.accounts[0]});
};
