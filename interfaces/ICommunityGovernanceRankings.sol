// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICommunityGovernanceRankings {

    // Events
    /*
    event RankingSubmitted(uint256 indexed communityId, uint256 weekNumber, uint256 groupId, address indexed submitter);
    event ConsensusReached(uint256 indexed communityId, uint256 weekNumber, uint256 groupId, uint256[] consensusRanking);
    event RespectIssued(uint256 indexed communityId, uint256 weekNumber, uint256 groupId, address indexed recipient, uint256 amount);
    event DebugLog(string message, uint256 value);
    event RespectIssueFailed(uint256 indexed communityId, uint256 weekNumber, uint256 groupId, address indexed recipient, uint256 amount, string reason);
    event TokensClaimed(uint256 indexed communityId, address indexed user, uint256 amount);
*/
    event ConsensusReached(string compositeId, string[] finalRanking);
    event RankingSubmitted(string eventId, string[] ranking);


    // Functions
    //function createCommunityToken(uint256 communityId) external;
    //function submitRanking(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, uint256[] memory _ranking) external;
    //function determineConsensus(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) external;
     function determineConsensusForAllGroups(uint256 _communityId, uint256 _weekNumber) external;
    //function getConsensusRanking(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) external view returns (uint256[] memory rankedScores, uint256[] memory transientScores, uint256 timestamp);
    //function getRanking(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, address _user) external view returns (uint256[] memory);
    //function getTransientScores(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) external view returns (address[] memory, uint256[] memory);
    //function claimTokens(uint256 _communityId) external;
    //function getClaimableTokens(uint256 _communityId, address _user) external view returns (uint256 amount, bool claimed);
}