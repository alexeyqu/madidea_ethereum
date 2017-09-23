pragma solidity ^0.4.0;
contract Project {
    uint8 constant MIN_JUDGES = 7;
    
    enum ProposalState { 
        PROPOSED,
        ACCEPTED,
        FINISHED,
        IN_COURT,
        CLOSED
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
    }
    
    mapping( address => uint8 ) judgeRating;
    
    enum JudgeDecision {
        UNDECIDED,
        EMPLOYER,
        EMPLOYEE
    }
    
    struct Judge {
        address id;
        JudgeDecision decision;
    }
    
    struct Claim {
        Proposal proposal;
        
        string message;
        uint judgeSalary;
        uint deadlineVotingDate;
        Judge[] judges;
    }
    
     
}
