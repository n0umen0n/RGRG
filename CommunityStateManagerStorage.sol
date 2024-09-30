// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICommunityGovernanceProfiles.sol";
import "./interfaces/ICommunityGovernanceRankings.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";
import "./interfaces/ICommunityGovernanceMultiSig.sol";

contract CommunityStateManagerStorage {
    ICommunityGovernanceProfiles public profilesContract;
    ICommunityGovernanceRankings public rankingsContract;
    ICommunityGovernanceContributions public contributionsContract;
    ICommunityGovernanceMultiSig public multiSigContract;

    event CommunityStateChanged(uint256 indexed communityId, ICommunityGovernanceProfiles.CommunityState newState);
    //event SubmissionToContributionTransition(string indexed idWeek);

}