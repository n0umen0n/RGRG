// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ICommunityGovernanceProfiles.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";


contract CommunityGovernanceContributionsStorage is Initializable {
    ICommunityGovernanceProfiles public profilesContract;
/*
    struct Contribution {
        string name;
        string description;
        string[] links;
    }

    struct WeeklyContributions {
        uint256 weekNumber;
        Contribution[] contributions;
        uint256 respectReceived;
    }

    struct UserContributions {
        uint256 communityId;
        mapping(uint256 => WeeklyContributions) weeklyContributions;
        uint256[] contributedWeeks;
        uint256 totalRespect;
        uint256 averageRespect;
        uint256[] last12WeeksRespect;
    }

    struct Group {
        address[] members;
    }
*/
    struct WeeklyContributions {
        uint256 weekNumber;
        ICommunityGovernanceContributions.Contribution[] contributions;
        uint256 respectReceived;
    }

    struct UserContributions {
        uint256 communityId;
        mapping(uint256 => WeeklyContributions) weeklyContributions;
        uint256[] contributedWeeks;
        uint256 totalRespect;
        uint256 averageRespect;
        uint256[] last12WeeksRespect;
    }


    mapping(address => mapping(uint256 => UserContributions)) internal userContributions;
    mapping(uint256 => mapping(uint256 => address[])) internal weeklyContributors;
    mapping(uint256 => mapping(uint256 => ICommunityGovernanceContributions.Group[])) internal weeklyGroups;
    uint8[] internal lastRoomSizes;

    uint256 internal constant SCALING_FACTOR = 1000;
}