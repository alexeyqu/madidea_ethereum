pragma solidity ^0.4.17;
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
        string name;

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
        uint daysForIndividualVote;
        uint minRating;
        uint claimId;

        bool paid;
    }
    
    Proposal[] taskList;
    
    // mapping( address => uint8 ) judgeRating;
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
        JudgeDecision finalDecision;
        uint judgeWinnersCount;
        bool noDecision;
    }

    Claim[] claimList;
    mapping(uint => ProposalJudge[]) claimJudges;
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
    
    event createProposalResult(bool success, uint proposalId);

    function createProposal(
        string _name,
        string _taskDescription, 
        uint8 _numJudges, 
        uint daysToDeadline, 
        uint daysToClaimDeadline,
        uint daysToVoteDeadline,
        uint _daysForIndividualVote,
        address _employee) public payable
        {
            Proposal memory newProposal = Proposal({
                name: _name,
                employer: msg.sender,
                employee: _employee,
                taskDescription: _taskDescription,
                price: msg.value,
                state: ProposalState.IN_WORK,
                taskSolution: "",
                numJudges: _numJudges,
                deadlineWorkDate: now + daysToDeadline * 1 days,
                deadlineClaimDate: now + daysToClaimDeadline * 1 days,
                deadlineVoteDate: now + daysToVoteDeadline * 1 days,
                daysForIndividualVote: _daysForIndividualVote,
                minRating: 0,
                claimId: 0,
                paid: false
            });
            
            taskList.push(newProposal);
            createProposalResult(true, taskList.length - 1);
        }
    
    event updateSolutionResult(bool success);

    function updateSolution(uint proposalId, string _taskSolution) public {
        if( taskList[proposalId].employee == msg.sender && now < taskList[proposalId].deadlineWorkDate ) {
            taskList[proposalId].taskSolution = _taskSolution;
            updateSolutionResult(true);
        } else {
            updateSolutionResult(false);
        }
    }
    
    event acceptProposalResult(
        bool success
    );

    function acceptProposal(uint proposalId) public {
        Proposal storage proposal = taskList[proposalId];
        if( msg.sender == proposal.employer && proposal.state == ProposalState.IN_WORK ) {
            proposal.state = ProposalState.PAY_EMPLOYEE;    
            acceptProposalResult(true);
        } else {
            acceptProposalResult(false);
        }
    }
    
    function addClaimInOpenList(uint claimId) private {
        openClaimIds.push(claimList.length - 1);
        claimIdToOpenClaimId[claimId] = openClaimIds.length - 1;
    }
    
    event openClaimResult(bool success, uint claimId);

    function openClaim(uint _proposalId, 
        string _message,
        uint _deadlineVoting) public payable
    {
        Proposal memory proposal = taskList[_proposalId];

        if( !(msg.sender == proposal.employer && now < proposal.deadlineClaimDate &&
            now > proposal.deadlineWorkDate && proposal.state == ProposalState.IN_WORK) )
        {
            openClaimResult(false, 0);
            return;
        }


        if( !(msg.sender == proposal.employer && now < proposal.deadlineClaimDate &&
            now > proposal.deadlineWorkDate && proposal.state == ProposalState.IN_WORK) )
        {
            openClaimResult(false, 0);
            return;
        }

        Claim memory newClaim = Claim({
            proposalId: _proposalId,
            message: _message,
            salary: msg.value,
            deadlineClaimVoting: now + _deadlineVoting,
            finalDecision: JudgeDecision.UNDECIDED,
            noDecision: false,
            judgeWinnersCount: 0
        });
        taskList[_proposalId].state = ProposalState.IN_COURT;

        claimList.push(newClaim);
        uint claimId = claimList.length - 1;
        addClaimInOpenList(claimId);

        openClaimResult(true, claimId);
    }
    
    //==========================================================================
    // JUDGE METHODS
    //==========================================================================
    
    event payJudgementFeeResult(bool success);

    function payJudgementFee(uint claimId) public payable {
        if( judgePayment[msg.sender] ) {
            payJudgementFeeResult(false);
            return;
        }
        
        uint amount = 1 * calculateFeeMultiplier(); // todo: calculate wisely

        if( msg.value != amount ) {
            payJudgementFeeResult(false);
            return;
        }

     	claimList[claimId].salary += msg.value;

        judgePayment[msg.sender] = true;
    }
    
    function kickUpClaims() private {
        for (uint i = 0; i < claimList.length; i++) {
            Claim storage claim = claimList[i];
            bool kickedUp = false;
            uint deleteOffset = 0;
            for (uint j = 0; j - deleteOffset < claimJudges[i].length; j++) {
                ProposalJudge storage judge = claimJudges[i][j - deleteOffset]; // claim.judges[j - deleteOffset];
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

    event getNewClaimResult(bool success, uint clainId);

    function getNewClaim() public {
        kickUpClaims();
        uint randomOpenClaimIdOfId = 0; // todo - fix this shit
        uint claimId = openClaimIds[randomOpenClaimIdOfId];
        judgePendingClaimId[msg.sender] = claimId;
        getNewClaimResult(true, claimId);
    }


    event acceptClaimResult(bool success);

    function acceptClaim() public payable {
        uint amount = 1 * calculateFeeMultiplier(); // todo: calculate wisely
        if(msg.value != amount) {
            acceptClaimResult(false);
            return;
        }

        uint claimId = judgePendingClaimId[msg.sender];
        if(claimId == 0) {
            acceptClaimResult(false);
            return;
        }

        judgePayment[msg.sender] = false;
        Claim storage claim = claimList[claimId];
        claimJudges[claimId].push(ProposalJudge({
            id: msg.sender,
            pendingClaimId: claimId,
            decision: JudgeDecision.UNDECIDED,
            deadlineJudgeVoting: now + 5 days // todo - take from proposal
        }));
        Proposal storage proposal = taskList[claim.proposalId];
        if (claimJudges[claimId].length == proposal.numJudges) {
            dropOpenClaimId(claimIdToOpenClaimId[claimId]);
        }

        acceptClaimResult(true);
    }

    
    function updateJudgesList(uint claimId) private {
        Claim storage claim = claimList[claimId];
        uint8 currentIndex = 0;
        for (uint i = 0; i < claimJudges[claimId].length; i++) {
            if (claimJudges[claimId][i].decision != JudgeDecision.UNDECIDED &&
                claimJudges[claimId][i].deadlineJudgeVoting < now &&
                currentIndex != i) 
            {
                claimJudges[claimId][currentIndex] = claimJudges[claimId][i];
            }
        }
        claimJudges[claimId].length = currentIndex;
    }
    
    function calculateFeeMultiplier() private constant returns(uint) {
        return 1; // todo - calculate actually
    }
    
    function finalizeClaim(uint claimId) private {
        // todo - call it everywhere!
        Claim storage claim = claimList[claimId];
        Proposal storage proposal = taskList[claim.proposalId];
        uint8 voteForEmployee = 0;
        uint8 voteForEmployer = 0;
        bool hasUnvoted = false;
        for (uint8 i = 0; i < claimJudges[claimId].length; i++){
            ProposalJudge storage judge = claimJudges[claimId][i];
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
                    claim.judgeWinnersCount = voteForEmployee;
                } else {
                    proposal.state = ProposalState.PAY_EMPLOYER;
                    claim.finalDecision = JudgeDecision.EMPLOYER;
                    totalEmployerWins++;
                    claim.judgeWinnersCount = voteForEmployer;
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

    event decideClaimResult(bool success);

    function decideClaim(uint claimId, bool isEmployerInFavor) public {
        Claim storage claim = claimList[claimId];
        uint judgeId = claim.judgeMapping[msg.sender];
        ProposalJudge storage judge = claimJudges[claimId][judgeId];

        if( !(now < claim.deadlineClaimVoting &&
            taskList[claim.proposalId].state == ProposalState.IN_COURT &&
            judgeId != 0  && 
            judge.decision == JudgeDecision.UNDECIDED) )
        {
            decideClaimResult(false);
            return;
        }

        if (isEmployerInFavor) {
            judge.decision = JudgeDecision.EMPLOYER;
        } else {
            judge.decision = JudgeDecision.EMPLOYEE;
        }

        decideClaimResult(true);
    }

    function decideClaimByProposal(uint proposalId, bool isEmployerInFavor) public {
        uint claimId = 0;
        bool found = false;

        for (uint i = 0; i < claimList.length; i++) {
            if( claimList[i].proposalId == proposalId ) {
                found = true;
                claimId = i;
            }
        }

        if( !found ) {
            decideClaimResult(false);
            return;
        }

        decideClaim(claimId, isEmployerInFavor);
    }
    
    //==========================================================================
    // MONEY RETRIEVAL
    //==========================================================================
    
    event getMoneyAsEmployerResult(bool success);

    function getMoneyAsEmployer(uint proposalId) public {
        Proposal storage proposal = taskList[proposalId];

        if(!(proposal.state == ProposalState.PAY_EMPLOYER && msg.sender == proposal.employer && proposal.paid == false)) {
            getMoneyAsEmployerResult(false);
            return;
        }

        msg.sender.transfer(proposal.price);
        taskList[proposalId].paid = true;
        // delete taskList[proposalId];

        getMoneyAsEmployerResult(true);
    }
    
    event getMoneyAsEmployeeResult(bool success);

    function getMoneyAsEmployee(uint proposalId) public {
        Proposal storage proposal = taskList[proposalId];

        if(!(proposal.state == ProposalState.PAY_EMPLOYEE && msg.sender == proposal.employee && proposal.paid == false)) {
            getMoneyAsEmployeeResult(false);
            return;
        }

        msg.sender.transfer(proposal.price);
        taskList[proposalId].paid = true;
        // delete taskList[proposalId];

        getMoneyAsEmployeeResult(true);
    }
    
    function getJudgeId(uint claimId) private constant returns(uint judgeId) {
        Claim storage claim = claimList[claimId];
        for (uint i = 0; i < claimJudges[claimId].length; i++) {
            if (claimJudges[claimId][i].id == msg.sender) {
                judgeId = i;
                return;
            }
        }
        require(false); // not a judge
    }
    
    function deleteJudge(uint claimId, uint judgeId) private {
        Claim storage claim = claimList[claimId];
        delete claimJudges[claimId][judgeId];
        for (uint i = judgeId; i < claimJudges[claimId].length - 1; i++) {
            claimJudges[claimId][i] = claimJudges[claimId][i + 1];
        }
        claimJudges[claimId].length--;
    }
    
    function deleteClaim(uint claimId) private {
        delete claimList[claimId];
        for (uint i = claimId; i < claimList.length - 1; i++) {
            claimList[i] = claimList[i + 1];
        }
        claimList.length--;
    }
    
    event getMoneyAsJudgeResult(bool success);

    function getMoneyAsJudge(uint claimId) public {
        Claim storage claim = claimList[claimId];
        uint judgeId = getJudgeId(claimId);
        ProposalJudge storage judge = claimJudges[claimId][judgeId];

        if( !(judgeId != 0 &&
            (claim.finalDecision != JudgeDecision.UNDECIDED &&
            claim.finalDecision == judge.decision) ||
            (claim.noDecision && judge.decision != JudgeDecision.UNDECIDED)) ) // noDecision means that vote deadline expired
        {
            getMoneyAsJudgeResult(false);
            return;
        }

	    claimJudges[claimId][judgeId].id.transfer(claim.salary / claim.judgeWinnersCount);      

        deleteJudge(claimId, judgeId);
        for (uint i = 0; i < claimJudges[claimId].length; i++) {
            ProposalJudge storage anotherJudge = claimJudges[claimId][i];
            if (anotherJudge.deadlineJudgeVoting < now) {
                deleteJudge(claimId, i);
            }
        }
        if (claimJudges[claimId].length == 0) {
            deleteClaim(claimId);
        }

        getMoneyAsJudgeResult(true);
    }

    /* Getters */

    event getAllProposalsForEmployeeResult(bool success, uint proposalId, string proposalName);

    function getAllProposalsForEmployee(address _employee) public {
        for (uint i = 0; i < taskList.length; i++) {
            Proposal storage proposal = taskList[i];
            if( proposal.employee == _employee ) {
                getAllProposalsForEmployeeResult(true, i, proposal.name);
            }
        }
    }

    event getAllProposalsForEmployerResult(bool success, uint proposalId, string proposalName);

    function getAllProposalsForEmployer(address _employer) public {
        for (uint i = 0; i < taskList.length; i++) {
            Proposal storage proposal = taskList[i];
            if( proposal.employer == _employer ) {
                getAllProposalsForEmployerResult(true, i, proposal.name);
            }
        }
    }

    event getAllProposalsForJudgeResult(bool success, uint proposalId, string proposalName);

    function getAllProposalsForJudge(address _judge) public {
        for (uint i = 0; i < claimList.length; i++) {
            uint proposalId = claimList[i].proposalId;
            string storage proposalName = taskList[proposalId].name;

            for (uint j = 0; j < claimJudges[i].length; j++) {
                if( claimJudges[i][j].id == _judge ) {
                    getAllProposalsForJudgeResult(true, proposalId, proposalName);
                }
            }
        }
    }
}

