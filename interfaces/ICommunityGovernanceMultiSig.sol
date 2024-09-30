// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICommunityGovernanceMultiSig {
    
    event MemberRemoved(uint256 indexed communityId, address indexed member);
    event RespectToDistributeChanged(uint256 indexed communityId, uint256 newAmount);
    event TokensMinted(uint256 indexed communityId, uint256 amount);
    event TopRespectedUsersUpdated(uint256 indexed communityId, address[5] topUsers);
    function updateTopRespectedUsers(uint256 _communityId, address[] memory allMembers) external;
    function getMultiSigInfo(uint256 _communityId) external view returns (uint256 respectToDistribute, address[5] memory topRespectedUsers);
    event ProposalSigned(uint256 indexed communityId, uint256 indexed proposalId, address signer);
    event ProposalExecuted(uint256 indexed communityId, uint256 indexed proposalId);
}