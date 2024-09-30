// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICommunityGovernanceProfiles.sol";
import "./interfaces/ICommunityGovernanceRankings.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";
import "./interfaces/ICommunityGovernanceMultiSig.sol";

contract CommunityGovernanceProfilesStorage {
    struct UserProfile {
        string username;
        string description;
        string profilePicUrl;
        mapping(uint256 => CommunityData) communityData;
    }

    struct CommunityData {
        uint256 communityId;
        bool isApproved;
        address[] approvers;
    }

    struct Community {
        string name;
        string description;
        string imageUrl;
        address creator;
        uint256 memberCount;
        address[] members;
        ICommunityGovernanceProfiles.CommunityState state;
        uint256 eventCount;
        uint256 nextStateTransitionTime;
        address tokenContractAddress;
        uint256 respectToDistribute;
    }

    mapping(address => UserProfile) internal users;
    mapping(uint256 => Community) internal communities;
    uint256 internal nextCommunityId;
    address public stateManagerAddress;

    // New storage variables for contract references

    ICommunityGovernanceMultiSig internal multiSigContract;
    ICommunityGovernanceRankings internal rankingsContract;
    ICommunityGovernanceContributions internal contributionsContract;

}