pragma solidity ^0.4.0;
contract Project {
    uint8 constant MIN_JUDGES = 7;
    uint totalEmployeeWins = 0;
    uint totalEmployerWins = 0;
    uint totalClaims = 0;
    
    enum ProposalState { 
        IN_WORK,
        IN_COURT,
        PAY_EMPLOYEE,
        PAY_EMPLOYER
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
        uint deadlineVoteDate; // = deadLineClaimDate + voteDelta
        uint minRating;
        uint claimId;
    }
    
    Proposal[] taskList;
    
    mapping( address => uint8 ) judgeRating;
    mapping(address => bool) judgePayment;
    mapping(address => uint) judgePendingClaimId;
    
    enum JudgeDecision {
        UNDECIDED,
        EMPLOYER,
        EMPLOYEE
    }

    
    struct ProposalJudge {
        address id;
        uint pendingClaimId;
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
        JudgeDecision finalDecision;
        bool noDecision;
    }

    Claim[] claimList;
    uint[] openClaimIds;
    mapping(uint => uint) claimIdToOpenClaimId;
    
    function dropOpenClaimId(uint index) private {
        if (index >= openClaimIds.length) return;

        for (uint i = index; i < openClaimIds.length - 1; i++) {
            openClaimIds[i] = openClaimIds[i + 1];
        }
        delete openClaimIds[openClaimIds.length - 1];
        openClaimIds.length--;
    }
    
    //==========================================================================
    // PROPOSAL METHODS
    //==========================================================================
    
    function createProposal(string _taskDescription, 
        uint _price, 
        uint8 _numJudges, 
        uint daysToDeadline, 
        uint daysToClaimDeadline,
        uint daysToVoteDeadline,
        address _employee) public returns (uint proposalId)
        {
            Proposal newProposal;
            newProposal.employer = msg.sender;
            newProposal.employee = _employee;
            newProposal.taskDescription = _taskDescription;
            newProposal.price = _price;
            newProposal.state = ProposalState.IN_WORK;
            newProposal.numJudges = _numJudges;
            newProposal.deadlineWorkDate = now + daysToDeadline * 1 days;
            newProposal.deadlineClaimDate = now + daysToClaimDeadline * 1 days;
            newProposal.deadlineVoteDate = now + daysToVoteDeadline * 1 days;
            
            taskList.push(newProposal);
            return taskList.length - 1;
        }
    
    function updateSolution(uint proposalId, string _taskSolution) public {
        if( msg.sender == taskList[proposalId].employee &&
            now < taskList[proposalId].deadlineWorkDate ) 
        {
            taskList[proposalId].taskSolution = _taskSolution;
        }
    }
    
    function acceptProposal(uint proposalId) public {
        Proposal storage proposal = taskList[proposalId];
        if (msg.sender == proposal.employer &&
            proposal.state == ProposalState.IN_WORK) 
        {
            proposal.state = ProposalState.PAY_EMPLOYEE;    
        } 
    }
    
    function addClaimInOpenList(uint claimId) private {
        openClaimIds.push(claimList.length - 1);
        claimIdToOpenClaimId[claimId] = openClaimIds.length - 1;
    }
    
    function openClaim(uint _proposalId, 
        string _message,
        uint _salary, 
        uint _deadlineVoting) public returns (uint claimId) 
    {
        Proposal storage proposal = taskList[_proposalId];
        if (msg.sender == proposal.employer &&
            now < proposal.deadlineClaimDate &&
            now > proposal.deadlineWorkDate &&
            proposal.state == ProposalState.IN_WORK) 
        {
            Claim memory newClaim = Claim({
                proposalId: _proposalId,
                message: _message,
                judges: new ProposalJudge[](1),
                salary: _salary,
                deadlineClaimVoting: now + _deadlineVoting,
                finalDecision: JudgeDecision.UNDECIDED,
                noDecision: false
            });
            taskList[_proposalId].state = ProposalState.IN_COURT;

            claimList.push(newClaim);
            claimId = claimList.length - 1;
            addClaimInOpenList(claimId);
        }
    }
    
    //==========================================================================
    // JUDGE METHODS
    //==========================================================================
    
    function payJudgementFee() public {
        if (judgePayment[msg.sender]) {
            return;
        }
        // todo - take money
        judgePayment[msg.sender] = true;
    }
    
    function kickUpClaims() public {
        for (uint i = 0; i < claimList.length; i++) {
            Claim storage claim = claimList[i];
            bool kickedUp = false;
            uint deleteOffset = 0;
            for (uint j = 0; j - deleteOffset < claim.judges.length; j++) {
                ProposalJudge storage judge = claim.judges[j - deleteOffset];
                if (judge.deadlineJudgeVoting < now) {
                    deleteJudge(i, j - deleteOffset);
                    kickedUp = true;
                    deleteOffset++;
                }
            }
            if (kickedUp) {
                addClaimInOpenList(i);
            }
        }
    }
    
    function getNewClaim() public returns(uint) {
        kickUpClaims();
        uint randomOpenClaimIdOfId = 0; // todo - fix this shit
        uint claimId = openClaimIds[randomOpenClaimIdOfId];
        judgePendingClaimId[msg.sender] = claimId;
        return claimId;
    }
    function acceptClaim() public {
        // todo - take money with multiplier
        uint claimId = judgePendingClaimId[msg.sender];
        if (claimId == 0) {
            return;
        }
        judgePayment[msg.sender] = false;
        Claim storage claim = claimList[claimId];
        claim.judges.push(ProposalJudge({
            id: msg.sender,
            pendingClaimId: claimId,
            decision: JudgeDecision.UNDECIDED,
            deadlineJudgeVoting: now + 5 days // todo - take from proposal
        }));
        Proposal storage proposal = taskList[claim.proposalId];
        if (claim.judges.length == proposal.numJudges) {
            dropOpenClaimId(claimIdToOpenClaimId[claimId]);
        }
    }

    
    function updateJudgesList(uint claimId) private {
        Claim storage claim = claimList[claimId];
        uint8 currentIndex = 0;
        for (uint i = 0; i < claim.judges.length; i++) {
            if (claim.judges[i].decision != JudgeDecision.UNDECIDED &&
                claim.judges[i].deadlineJudgeVoting < now &&
                currentIndex != i) 
            {
                claim.judges[currentIndex] = claim.judges[i];
            }
        }
        claim.judges.length = currentIndex;
    }
    
    function calculateFeeMultiplier() constant returns(uint) {
        return 1; // todo - calculate actually
    }
    
    function finalizeClaim(uint claimId) public {
        // todo - call it everywhere!
        Claim storage claim = claimList[claimId];
        Proposal storage proposal = taskList[claim.proposalId];
        uint8 voteForEmployee = 0;
        uint8 voteForEmployer = 0;
        bool hasUnvoted = false;
        for (uint8 i = 0; i < claim.judges.length; i++){
            ProposalJudge storage judge = claim.judges[i];
            if (judge.decision == JudgeDecision.UNDECIDED) {
                hasUnvoted = true;
            } else if (judge.decision == JudgeDecision.EMPLOYER) {
                voteForEmployer++;
            } else {
                voteForEmployee++;
            }
            }
        if (claimId != 0 &&
            proposal.state == ProposalState.IN_COURT) 
            
        {
            if (!hasUnvoted) {
                if (voteForEmployee > voteForEmployer) {
                    proposal.state = ProposalState.PAY_EMPLOYEE;
                    claim.finalDecision = JudgeDecision.EMPLOYEE;
                    totalEmployeeWins++;
                } else {
                    proposal.state = ProposalState.PAY_EMPLOYER;
                    claim.finalDecision = JudgeDecision.EMPLOYER;
                    totalEmployerWins++;
                }
                totalClaims++;
            } else {
                if (claim.deadlineClaimVoting < now) {
                    proposal.state = ProposalState.PAY_EMPLOYEE;
                    claim.noDecision = true;
                    totalClaims++;
                }
            }
        }
    }
        
    function decideClaim(uint claimId, bool isEmployerInFavor) public {
        Claim storage claim = claimList[claimId];
        uint judgeId = claim.judgeMapping[msg.sender];
        ProposalJudge storage judge = claim.judges[judgeId];
        if (now < claim.deadlineClaimVoting &&
            taskList[claim.proposalId].state == ProposalState.IN_COURT &&
            judgeId != 0  && 
            judge.decision == JudgeDecision.UNDECIDED ) 
        {
            if (isEmployerInFavor) {
                judge.decision = JudgeDecision.EMPLOYER;
            } else {
                judge.decision = JudgeDecision.EMPLOYEE;
            }
        }
    }
    
    //==========================================================================
    // MONEY RETRIEVAL
    //==========================================================================
    
    function getMoneyAsEmployer(uint proposalId) public {
        Proposal storage proposal = taskList[proposalId];
        if (proposal.state == ProposalState.PAY_EMPLOYER &&
            msg.sender == proposal.employer) {
            // todo - send money back
            delete taskList[proposalId];
        }
    }
    
    function getMoneyAsEmployee(uint proposalId) public {
        Proposal storage proposal = taskList[proposalId];
        if (proposal.state == ProposalState.PAY_EMPLOYEE &&
            msg.sender == proposal.employee) {
            // todo - send money
            delete taskList[proposalId];
        }
    }
    
    function getJudgeId(uint claimId) private constant returns(uint judgeId) {
        Claim storage claim = claimList[claimId];
        for (uint i = 0; i < claim.judges.length; i++) {
            if (claim.judges[i].id == msg.sender) {
                judgeId = i;
                return;
            }
        }
    }
    
    function deleteJudge(uint claimId, uint judgeId) {
        Claim storage claim = claimList[claimId];
        delete claim.judges[judgeId];
        for (uint i = judgeId; i < claim.judges.length - 1; i++) {
            claim.judges[i] = claim.judges[i + 1];
        }
        claim.judges.length--;
    }
    
    function deleteClaim(uint claimId) {
        delete claimList[claimId];
        for (uint i = claimId; i < claimList.length - 1; i++) {
            claimList[i] = claimList[i + 1];
        }
        claimList.length--;
    }
    
    function getMoneyAsJudge(uint claimId) public {
        Claim storage claim = claimList[claimId];
        uint judgeId = getJudgeId(claimId);
        ProposalJudge storage judge = claim.judges[judgeId];
        if (judgeId != 0 &&
            (claim.finalDecision != JudgeDecision.UNDECIDED &&
            claim.finalDecision == judge.decision) ||
            (claim.noDecision && judge.decision != JudgeDecision.UNDECIDED)) 
        {
            deleteJudge(claimId, judgeId);
            for (uint i = 0; i < claim.judges.length; i++) {
                ProposalJudge storage anotherJudge = claim.judges[i];
                if (anotherJudge.deadlineJudgeVoting < now) {
                    deleteJudge(claimId, i);
                }
            }
            if (claim.judges.length == 0) {
                deleteClaim(claimId);
            }
            // todo - send money from claim salary
        }
    }
}
