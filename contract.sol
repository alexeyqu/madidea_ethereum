pragma solidity ^0.4.17;
contract Project {

    function Project() public {
        claimList.push(Claim({
            proposalId: 0,
            message: "",
            salary: 0,
            deadlineClaimVoting: 0,
            finalDecision: JudgeDecision.UNDECIDED,
            noDecision: false,
            judgeWinnersCount: 0
        }));
        openClaimIds.push(0);
    }

    uint8 constant MIN_JUDGES = 7;
    uint totalEmployeeWins = 0;
    uint totalEmployerWins = 0;
    uint totalClaims = 0;
    uint seed = 0;
    
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

    function getProposalData(uint proposalId) constant public returns(string name, address employer,
        address employee, string taskDescription, uint price, string taskSolution,
        uint deadlineWorkDate, uint deadLineClaimDate)
    {
        Proposal storage proposal = taskList[proposalId];
        return (
            proposal.name,
            proposal.employer,
            proposal.employee,
            proposal.taskDescription,
            proposal.price,
            proposal.taskSolution,
            proposal.deadlineWorkDate - now,
            proposal.deadlineClaimDate - now
        );
    }
    
    Proposal[] taskList;
    
    // mapping( address => uint8 ) judgeRating;
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
    
    struct IdOptional {
        uint id;
        bool exists;
    }

    struct Claim {
        uint proposalId;
        string message;
        uint salary;
        uint deadlineClaimVoting; // how do we manage that?
        mapping( address => IdOptional ) judgeMapping;
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
        if( claimIdToOpenClaimId[claimId] != 0 ) {
            return;
        }
		finalizeClaim(claimId);
        openClaimIds.push(claimId);
        claimIdToOpenClaimId[claimId] = openClaimIds.length - 1;
    }
    
    event openClaimResult(bool success, uint claimId);

    function openClaim(uint _proposalId, 
        string _message) public payable
    {
        Proposal memory proposal = taskList[_proposalId];

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
            deadlineClaimVoting: now + proposal.daysForIndividualVote * 1 days,
            finalDecision: JudgeDecision.UNDECIDED,
            noDecision: false,
            judgeWinnersCount: 0
        });
        taskList[_proposalId].state = ProposalState.IN_COURT;

        claimList.push(newClaim);
        uint claimId = claimList.length - 1;

        openClaimResult(true, claimId);
    }
    
    //==========================================================================
    // JUDGE METHODS
    //==========================================================================
    
    function kickUpClaims() private {
        for (uint i = 0; i < claimList.length; i++) {
            bool kickedUp = false;
            uint deleteOffset = 0;
            Proposal storage proposal = taskList[claimList[i].proposalId];
            if (proposal.numJudges != claimJudges[i].length) {
                kickedUp = true;
            }
            for (uint j = 0; j - deleteOffset < claimJudges[i].length; j++) {
                ProposalJudge storage judge = claimJudges[i][j - deleteOffset];
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
        seed++;
        uint randomOpenClaimIdOfId = uint(seed) % (openClaimIds.length - 1) + 1;
		uint claimId = openClaimIds[randomOpenClaimIdOfId];
        judgePendingClaimId[msg.sender] = claimId;
        getNewClaimResult(true, claimList[claimId].proposalId);
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
        judgePendingClaimId[msg.sender] = 0;

        Claim storage claim = claimList[claimId];
		finalizeClaim(claimId);
        Proposal storage proposal = taskList[claim.proposalId];

        claimJudges[claimId].push(ProposalJudge({
            id: msg.sender,
            pendingClaimId: claimId,
            decision: JudgeDecision.UNDECIDED,
            deadlineJudgeVoting: now + proposal.daysForIndividualVote
        }));

        if (claimJudges[claimId].length == proposal.numJudges) {
            dropOpenClaimId(claimIdToOpenClaimId[claimId]);
        } else {
            claimList[claimId].judgeMapping[msg.sender].id = claimJudges[claimId].length-1;
            claimList[claimId].judgeMapping[msg.sender].exists = true;
        }

        acceptClaimResult(true);
    }

    
    function updateJudgesList(uint claimId) private {
		finalizeClaim(claimId);
        uint8 currentIndex = 0;
        for (uint i = 0; i < claimJudges[claimId].length; i++) {
            if (claimJudges[claimId][i].decision != JudgeDecision.UNDECIDED &&
                claimJudges[claimId][i].deadlineJudgeVoting < now &&
                currentIndex != i) 
            {
                claimJudges[claimId][currentIndex] = claimJudges[claimId][i];
                currentIndex++;
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
        for (uint8 i = 0; i < claimJudges[claimId].length; i++) {
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

    function decideClaim(uint proposalId, bool isEmployerInFavor) public {
        uint claimId;
        for (uint i = 1; i < claimList.length; i++) {
            if (claimList[i].proposalId == proposalId) {
                claimId = i;
                break;
            }
        }
        Claim storage claim = claimList[claimId];
		finalizeClaim(claimId);
		
        if(!claim.judgeMapping[msg.sender].exists) {
            decideClaimResult(false);
            return;
        }

        uint judgeId = claim.judgeMapping[msg.sender].id;
        ProposalJudge storage judge = claimJudges[claimId][judgeId];

        if( !(now < claim.deadlineClaimVoting &&
            taskList[claim.proposalId].state == ProposalState.IN_COURT &&
            judge.decision == JudgeDecision.UNDECIDED) )
        {
            decideClaimResult(false);
            return;
        }

        claim.judgeMapping[msg.sender].exists = false; // not to decide twice

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

        for (uint i = 1; i < claimList.length; i++) {
            if( claimList[i].proposalId == proposalId ) {
                found = true;
                claimId = i;
            }
        }

        if( !found ) {
            decideClaimResult(false);
            return;
        }

		finalizeClaim(claimId);
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
    
    function getJudgeId(uint claimId) private constant returns(bool found, uint judgeId) {
        Claim storage claim = claimList[claimId];

        found = false;
        for (uint i = 0; i < claimJudges[claimId].length; i++) {
            if( claimJudges[claimId].length > i ) {
                if( claimJudges[claimId][i].id == msg.sender ) {
                    judgeId = i;
                    found = true;
                    return;
                }
            }
        }
    }
    
    function deleteJudge(uint claimId, uint judgeId) private {
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
		finalizeClaim(claimId);

        bool found;
        uint judgeId;
        (found, judgeId) = getJudgeId(claimId);

        if(!found) {
            getMoneyAsJudgeResult(false);
            return; 
        }

        ProposalJudge storage judge = claimJudges[claimId][judgeId];

        if( !((claim.finalDecision != JudgeDecision.UNDECIDED && claim.finalDecision == judge.decision) ||
            (claim.noDecision && judge.decision != JudgeDecision.UNDECIDED)) ) // noDecision means that vote deadline expired
        {
            getMoneyAsJudgeResult(false);
            return;
        }

	    claimJudges[claimId][judgeId].id.transfer(claim.salary / claim.judgeWinnersCount);      

        deleteJudge(claimId, judgeId);

        getMoneyAsJudgeResult(true);
    }

    /* Getters */

    function getProposalForEmployee(address _employee, uint idx) constant public returns (uint proposalId, string name) {
        for (uint i = 0; i < taskList.length; i++) {
            Proposal storage proposal = taskList[i];
            if( proposal.employee == _employee ) {
                if (idx == 0) {
                    return (i, proposal.name);
                }
                idx--;
            }
        }
    }

    function getProposalsLengthForEmployee(address _employee) constant public returns (uint length) {
        length = 0;
        for (uint i = 0; i < taskList.length; i++) {
            Proposal storage proposal = taskList[i];
            if( proposal.employee == _employee ) {
                length++;
            }
        }
    }

    function getProposalForEmployer(address _employer, uint idx) constant public returns (uint proposalId, string name) {
        for (uint i = 0; i < taskList.length; i++) {
            Proposal storage proposal = taskList[i];
            if( proposal.employer == _employer ) {
                if (idx == 0) {
                    return (i, proposal.name);
                }
                idx--;
            }
        }
    }

    function getProposalsLengthForEmployer(address _employer) constant public returns (uint length) {
        length = 0;
        for (uint i = 0; i < taskList.length; i++) {
            Proposal storage proposal = taskList[i];
            if( proposal.employer == _employer ) {
                length++;
            }
        }
    }

    function getProposalsLengthForJudge(address _judge) constant public returns (uint length) {
        length = 0;
        for (uint i = 1; i < claimList.length; i++) {
            uint proposalId = claimList[i].proposalId;
            for (uint j = 0; j < claimJudges[i].length; j++) {
                if( claimJudges[i][j].id == _judge ) {
                    length++;
                }
            }
        }
    }

    function getProposalForJudge(address _judge, uint idx) constant public returns (uint proposalId, string name) {
        for (uint i = 1; i < claimList.length; i++) {
            proposalId = claimList[i].proposalId;
            string storage proposalName = taskList[proposalId].name;

            for (uint j = 0; j < claimJudges[i].length; j++) {
                if( claimJudges[i][j].id == _judge ) {
                    if (idx == 0) {
                        return (proposalId, proposalName);
                    } else {
                        idx--;
                    }
                }
            }
        }
    }
}