watchEvents(function(error, event) {
    if (error) {
        console.log(error);
    }
    console.log(event);
    if (event.event === 'acceptClaim') {
        document.getElementById('accept-button').style.display = 'none';
        document.getElementById('decline-button').style.display = 'none';
        document.getElementById('employer-right-button').style.display = 'block';
        document.getElementById('employee-right-button').style.display = 'block';
    }
});

var role = getFrom();
var proposalId = getProposalId();

/* string name, address employer,
        address employee, string taskDescription, uint price, string taskSolution,
        uint deadlineWorkDate, uint deadLineClaimDate*/
var proposal = contract.getProposalData(proposalId);
var secondsToWorkDeadline = proposal[6].c[0];
var secondsToOpenClaim = proposal[7].c[0];
console.log(proposal);
document.getElementById('project-name').innerHTML = proposal[0];
document.getElementById('project-description').innerHTML = proposal[3];
document.getElementById('project-solution').value = proposal[5];
document.getElementById('project-price').innerHTML = proposal[4].c[0] + 'wei';
document.getElementById('project-work-deadline').innerHTML = secondsToWorkDeadline / 3600 + ' hours';
document.getElementById('project-open-claim-deadline').innerHTML = secondsToOpenClaim / 3600 + ' hours';

var getMoney = function() {
    if (role === 'employer') {
        contract.getMoneyAsEmployer({from: web3.eth.accounts[0]});
    } else if (role === 'employee') {
        contract.getMoneyAsEmployee({from: web3.eth.accounts[0]});
    } else if (role === 'judge') {
        contract.getMoneyAsJudge({from: web3.eth.accounts[0]});
    }
}

if (role === 'employer') {
    if (secondsToWorkDeadline < 0 && secondsToOpenClaim > 0) {
        document.getElementById('claim-button').style.display = 'block';
    }
    if (secondsToOpenClaim > 0) {
        document.getElementById('send-money-button').style.display = 'block';
    }
} else if (role === 'employee') {
    document.getElementById('project-solution').disabled = false;
    if (secondsToWorkDeadline > 0) {
        document.getElementById('update-solution-button').style.display = 'block';
    }
    document.getElementById('get-money-button').style.display = 'block';
} else if (role === 'judge') {
  if (getParam('pending')) {
    document.getElementById('accept-button').style.display = 'block';
    document.getElementById('decline-button').style.display = 'block';
  } else {
    document.getElementById('employer-right-button').style.display = 'block';
    document.getElementById('employee-right-button').style.display = 'block';
  }
}
