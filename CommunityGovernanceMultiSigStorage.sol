// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICommunityGovernanceProfiles.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";

contract CommunityGovernanceMultiSigStorage {
    ICommunityGovernanceProfiles public profilesContract;
    ICommunityGovernanceContributions public contributionsContract;

     struct MultiSigInfo {
        mapping(uint256 => MultiSigProposal) proposals;
        address[5] topRespectedUsers;
        uint256 respectToDistribute;  // Add this line
    }

    struct MultiSigProposal {
        ProposalType proposalType;
        uint256 value;
        address targetMember;
        uint256 signatureCount;
        mapping(address => bool) hasSignedProposal;
        bool executed;
    }

    enum ProposalType { RemoveMember, SetRespectToDistribute, MintTokens }

    mapping(uint256 => MultiSigInfo) internal communityMultiSigs;
    
    event ProposalCreated(uint256 indexed communityId, uint256 indexed proposalId, ProposalType proposalType);

}