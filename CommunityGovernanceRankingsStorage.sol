// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICommunityGovernanceProfiles.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";
import "./interfaces/ICommunityGovernanceMultiSig.sol";


contract CommunityGovernanceRankingsStorage {
    uint256 constant SCALE = 1e18;

    struct Ranking {
        uint256[] rankedScores;
    }

    struct ConsensusRanking {
        uint256[] rankedScores;
        uint256[] transientScores;
        uint256 timestamp;
    }

    struct ClaimableTokens {
        uint256 amount;
        bool claimed;
    }

    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(address => Ranking)))) internal rankings;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => ConsensusRanking))) internal consensusRankings;
    mapping(uint256 => bool) public communityExists;
    mapping(uint256 => mapping(address => ClaimableTokens)) public userClaimableTokens;

    uint256[] internal respectValues;

    ICommunityGovernanceContributions public contributionsContract;
    ICommunityGovernanceProfiles public profilesContract;
    ICommunityGovernanceMultiSig public multisigContract;

}