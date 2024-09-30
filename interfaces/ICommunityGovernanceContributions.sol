// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICommunityGovernanceContributions {

    

    struct Contribution {
        string name;
        string description;
        string[] links;
    }
        struct Group {
        address[] members;
    }

    event ContributionSubmitted(string contributionId, Contribution[] contributions);    //event GroupsCreated(uint256 indexed communityId, uint256 weekNumber, uint256 groupCount);
    event RespectUpdated(address indexed user,uint256 totalRespect,uint256 averageRespect);
    event NewGroupsCreated(string eventId, string[] contributionStrings, string[] rankingStrings, string[] memberAddresses);
    event WeeklyGroupsCreated(
    string communityAndWeekId,
    string[] roomIds,
    string[] roomIdentifiers,
    string weekNumber
    );
    function createGroupsForCurrentWeek(uint256 _communityId) external;
    function getGroupsForWeek(uint256 _communityId, uint256 _weekNumber) external view returns (Group[] memory);
    function getWeeklyContributors(uint256 _communityId, uint256 _week) external view returns (address[] memory);
    function updateRespectData(uint256 _communityId, address _user, uint256 _weekNumber, uint256 _respect) external;
    function getAverageRespect(address _user, uint256 _communityId) external view returns (uint256);
    function getCurrentWeek(uint256 _communityId) external view returns (uint256);
    function updateAllUsersRespectData(uint256 _communityId) external;
}