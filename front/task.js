watchEvents(function(error, event) {
    if (error) {
        console.log(error);
    }
    console.log(event);
    if (event.event === 'acceptClaim') {
        document.getElementById('accept-button').style.display = 'none';
        document.getElementById('decline-button').style.display = 'none';
        document.getElementById('employer-right-button').style.display = 'inline-block';
        document.getElementById('employee-right-button').style.display = 'inline-block';
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
    console.log(secondsToWorkDeadline);
    if (secondsToWorkDeadline <= 0 && secondsToOpenClaim > 0) {
        console.log('aaaa');
        document.getElementById('claim-button').style.display = 'inline-block';
    }
    if (secondsToOpenClaim > 0) {
        document.getElementById('send-money-button').style.display = 'inline-block';
    }
} else if (role === 'employee') {
    if (secondsToWorkDeadline > 0) {
        document.getElementById('project-solution').disabled = false;
        document.getElementById('update-solution-button').style.display = 'inline-block';
    }
    document.getElementById('get-money-button').style.display = 'inline-block';
} else if (role === 'judge') {
  if (getParam('pending')) {
    document.getElementById('accept-button').style.display = 'inline-block';
    document.getElementById('decline-button').style.display = 'inline-block';
  } else {
    document.getElementById('employer-right-button').style.display = 'inline-block';
    document.getElementById('employee-right-button').style.display = 'inline-block';
  }
}
