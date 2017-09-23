pragma solidity ^0.4.0;
contract Project {
    uint8 constant MIN_JUDGES = 7;
    
    enum ProposalState { 
        PROPOSED,
        ACCEPTED,
        FINISHED,
        IN_COURT,
        PAY_EMPLOYER,
        PAY_EMPLOYEE
    }
    
    struct Proposal {
        address employer;
        address employee;
        string taskDescription;
        uint price;
        
        ProposalState state;
        string taskSolution;
        uint8 numJudges;
        uint deadlineWorkDate; // = now + deltaWork
        uint deadlineClaimDate; // = deadlineWorkDate + claimDelta
        uint minRating;
        uint claimId;
    }
    
    Proposal[] taskList;
    
    mapping( address => uint8 ) judgeRating; // do we need it?
    
    enum JudgeDecision {
        UNDECIDED,
        EMPLOYER,
        EMPLOYEE
    }
    
    struct ProposalJudge {
        address id;
        JudgeDecision decision;
        uint deadlineJudgeVoting;
    }
    
    struct Claim {
        uint proposalId;
        string message;
        uint salary;
        uint deadlineClaimVoting; // how do we manage that?
        mapping( address => uint ) judgeMapping;
        ProposalJudge[] judges;
    }

    Claim[] claimList;
    
    //==========================================================================
    // PROPOSAL METHODS
    //==========================================================================
    
    function createProposal(string _taskDescription, 
        uint _price, 
        uint8 _numJudges, 
        uint daysToDeadline, 
        uint daysToClaimDeadline) public returns (uint proposalId) {
            Proposal newProposal;
            newProposal.employer = msg.sender;
            newProposal.taskDescription = _taskDescription;
            newProposal.price = _price;
            newProposal.state = ProposalState.PROPOSED;
            newProposal.numJudges = _numJudges;
            newProposal.deadlineWorkDate = now + daysToDeadline;
            newProposal.deadlineClaimDate = now + daysToClaimDeadline;
            
            taskList.push(newProposal);
            return taskList.length - 1;
        }
        
    function acceptProposal(uint proposalId) public {
        if( now < taskList[proposalId].deadlineWorkDate ) {
            taskList[proposalId].employee = msg.sender;
            taskList[proposalId].state = ProposalState.ACCEPTED;
        }
    }
    
    function finishTask(uint proposalId, string _taskSolution) public {
        if( msg.sender == taskList[proposalId].employee &&
            now < taskList[proposalId].deadlineWorkDate ) 
        {
            taskList[proposalId].taskSolution = _taskSolution;
            taskList[proposalId].state = ProposalState.FINISHED;
        }
    }
    
   /* function selectJudges(uint numJudges) public returns (ProposalJudge[] judges) {
        // some stuff going on here
        
        return judges;
    }*/
    
    function openClaim(uint _proposalId, 
        string _message,
        uint _salary, 
        uint _deadlineVoting) public returns (uint claimId) {
        if( msg.sender == taskList[_proposalId].employer &&
            now < taskList[_proposalId].deadlineClaimDate &&
            taskList[_proposalId].state == ProposalState.FINISHED ) 
        {
            Claim newClaim;
            newClaim.proposalId = _proposalId;
            taskList[_proposalId].state = ProposalState.IN_COURT;
            newClaim.salary = _salary;
            newClaim.deadlineClaimVoting = now + _deadlineVoting;
           // newClaim.judges = selectJudges(taskList[proposalId].numJudges);
            
            claimList.push(newClaim);
            
            return claimList.length - 1;
        }
    }
    
    //==========================================================================
    // JUDGE METHODS
    //==========================================================================
    
    function getNewClaim() public {
        // msg.sender == judge
    }
    
    function finalizeClaim(uint claimId) public {
        // decide final claim decision
    }
        
    function decideClaim(uint claimId, bool isEmployerInFavor) public {
        uint judgeId = claimList[claimId].judgeMapping[msg.sender];
        if ( now < claimList[claimId].deadlineClaimVoting &&
            taskList[claimList[claimId].proposalId].state == ProposalState.IN_COURT &&
            judgeId != 0  && 
            claimList[claimId].judges[judgeId].decision == JudgeDecision.UNDECIDED ) 
        {
            if( isEmployerInFavor ) {
                claimList[claimId].judges[judgeId].decision = JudgeDecision.EMPLOYER;
            } else {
                claimList[claimId].judges[judgeId].decision = JudgeDecision.EMPLOYEE;
            }
        }
    }
    
    //==========================================================================
    // MONEY RETRIEVAL
    //==========================================================================
    
    function getMoneyAsEmployer(uint proposalId) public {
        if( ( taskList[proposalId].state == ProposalState.PAY_EMPLOYER || // claim issued and decided in favor of employer
              taskList[proposalId].state == ProposalState.PROPOSED ) && // or recall money just at the start
            msg.sender == taskList[proposalId].employer) {
            // send money back
            
            delete taskList[proposalId];
        }
    }
    
    function getMoneyAsEmployee(uint proposalId) public {
        if( ( taskList[proposalId].state == ProposalState.PAY_EMPLOYEE || // claim resolved in favor of employee
              ( taskList[proposalId].state == ProposalState.FINISHED && // task finished and no claim was issued
                now >= taskList[proposalId].deadlineClaimDate ) ) &&
            msg.sender == taskList[proposalId].employee) {
            // send money
            
            delete taskList[proposalId];
        }
    }
    
    function getMoneyAsJudge(uint claimId) public {
        uint proposalId = claimList[claimId].proposalId;
        if( ( taskList[proposalId].state == ProposalState.PAY_EMPLOYEE || // there was a claim and it was decided
            taskList[proposalId].state == ProposalState.PAY_EMPLOYER ) &&
            msg.sender == taskList[proposalId].employee ) {
            // send money from claim salary
            
            delete taskList[proposalId];
        }
    }
}
