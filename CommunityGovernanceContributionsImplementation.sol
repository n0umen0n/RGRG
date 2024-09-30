// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./CommunityGovernanceContributionsStorage.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";
import "./interfaces/ICommunityGovernanceProfiles.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CommunityGovernanceContributionsImplementation is 
    Initializable, 
    OwnableUpgradeable, 
    UUPSUpgradeable,
    CommunityGovernanceContributionsStorage, 
    ICommunityGovernanceContributions 
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function setProfilesContract(address _profilesContractAddress) external onlyOwner {
        //require(_profilesContractAddress != address(0), "Invalid profiles contract address");
        profilesContract = ICommunityGovernanceProfiles(_profilesContractAddress);
    }

    function submitContributions(uint256 _communityId, Contribution[] memory _contributions) public  {
        //(string memory username, , ) = profilesContract.getUserProfile(msg.sender);
        //require(bytes(username).length > 0, "Profile must exist to submit contributions");

        (uint256 communityId, bool isApproved, ) = profilesContract.getUserCommunityData(msg.sender, _communityId);
        require(communityId != 0 && isApproved, "User not approved");
        //require(_contributions.length > 0, "Must submit at least one contribution");

        (, , , , , ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek ,) = profilesContract.getCommunityProfile(_communityId);
        require(state == ICommunityGovernanceProfiles.CommunityState.ContributionSubmission, "Community is not in contribution submission state");

    // Check if the user is already in the weeklyContributors array
    bool isAlreadyContributor = false;
    for (uint256 i = 0; i < weeklyContributors[_communityId][currentWeek].length; i++) {
        if (weeklyContributors[_communityId][currentWeek][i] == msg.sender) {
            isAlreadyContributor = true;
            break;
        }
    }

    // Only add to weeklyContributors if not already present
    if (!isAlreadyContributor) {
        weeklyContributors[_communityId][currentWeek].push(msg.sender);
    }

        UserContributions storage userContrib = userContributions[msg.sender][_communityId];
        if (userContrib.communityId == 0) userContrib.communityId = _communityId;

        WeeklyContributions storage weeklyContrib = userContrib.weeklyContributions[currentWeek];
        weeklyContrib.weekNumber = currentWeek;
        delete weeklyContrib.contributions;

        for (uint256 i = 0; i < _contributions.length; i++) {
            weeklyContrib.contributions.push(_contributions[i]);
        }
/*
        if (userContrib.contributedWeeks.length == 0 || userContrib.contributedWeeks[userContrib.contributedWeeks.length - 1] != currentWeek) {
            userContrib.contributedWeeks.push(currentWeek);
        }
*/
        emit ContributionSubmitted(
        string(abi.encodePacked(Strings.toString(_communityId), "-", Strings.toString(currentWeek), "-", Strings.toHexString(uint160(msg.sender), 20), "-C")),
        _contributions
            );
    }

function createGroupsForCurrentWeek(uint256 _communityId) external override {
    (, , , , , ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);

    require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in ranking");

    address[] memory participants = weeklyContributors[_communityId][currentWeek];
    require(participants.length > 0, "No contributors");

    shuffle(participants);
    uint8[] memory roomSizes = determineRoomSizes(participants.length);

    // New arrays for the modified WeeklyGroupsCreated event
    string[] memory roomIds = new string[](roomSizes.length);
    string[] memory roomIdentifiers = new string[](roomSizes.length);

    uint256 participantIndex = 0;
    for (uint256 i = 0; i < roomSizes.length; i++) {
        address[] memory groupMembers = new address[](roomSizes[i]);
        string[] memory contributionStrings = new string[](roomSizes[i]);
        string[] memory rankingStrings = new string[](roomSizes[i]);
        string[] memory memberAddressStrings = new string[](roomSizes[i]);

        for (uint256 j = 0; j < roomSizes[i] && participantIndex < participants.length; j++) {
            groupMembers[j] = participants[participantIndex];
            
            string memory baseString = string(abi.encodePacked(
                Strings.toString(_communityId),
                "-",
                Strings.toString(currentWeek),
                "-",
                Strings.toHexString(uint160(participants[participantIndex]), 20)
            ));
            
            contributionStrings[j] = string(abi.encodePacked(baseString, "-C"));
            rankingStrings[j] = string(abi.encodePacked(baseString, "-R"));
            memberAddressStrings[j] = Strings.toHexString(uint160(participants[participantIndex]), 20);
            
            participantIndex++;
        }
        weeklyGroups[_communityId][currentWeek].push(Group(groupMembers));
        
        // Emit NewGroupsCreated for each group
        emit NewGroupsCreated(
            string(abi.encodePacked(Strings.toString(_communityId), "-", Strings.toString(currentWeek), "-", Strings.toString(i + 1))),
            contributionStrings,
            rankingStrings,
            memberAddressStrings
        );

        // Populate new arrays for the modified WeeklyGroupsCreated event
        roomIds[i] = Strings.toString(i + 1);
        roomIdentifiers[i] = string(abi.encodePacked(
            Strings.toString(_communityId),
            "-",
            Strings.toString(currentWeek),
            "-",
            Strings.toString(i + 1)
        ));
    }

    lastRoomSizes = roomSizes;

    // Modified WeeklyGroupsCreated event emission
    emit WeeklyGroupsCreated(
        string(abi.encodePacked(Strings.toString(_communityId), "-", Strings.toString(currentWeek))),
        roomIds,
        roomIdentifiers,
        Strings.toString(currentWeek)
    );
}


/*
function createGroupsForCurrentWeek(uint256 _communityId) external override {
    (, , , , , ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);

    require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in ranking");
    //require(weeklyGroups[_communityId][currentWeek].length == 0, "Groups already created for this week");

    address[] memory participants = weeklyContributors[_communityId][currentWeek];
    require(participants.length > 0, "No contributors");

    shuffle(participants);
    uint8[] memory roomSizes = determineRoomSizes(participants.length);

    string[] memory contributionStrings = new string[](participants.length);
    string[] memory rankingStrings = new string[](participants.length);
    string[] memory memberAddressStrings = new string[](participants.length);
    
    // New arrays for the modified WeeklyGroupsCreated event
    string[] memory roomIds = new string[](roomSizes.length);
    string[] memory roomIdentifiers = new string[](roomSizes.length);

    uint256 participantIndex = 0;
    for (uint256 i = 0; i < roomSizes.length; i++) {
        address[] memory groupMembers = new address[](roomSizes[i]);
        for (uint256 j = 0; j < roomSizes[i] && participantIndex < participants.length; j++) {
            groupMembers[j] = participants[participantIndex];
            
            string memory baseString = string(abi.encodePacked(
                Strings.toString(_communityId),
                "-",
                Strings.toString(currentWeek),
                "-",
                Strings.toString(i + 1),
                "-",
                Strings.toHexString(uint160(participants[participantIndex]), 20)
            ));
            
            contributionStrings[participantIndex] = string(abi.encodePacked(baseString, "-C"));
            rankingStrings[participantIndex] = string(abi.encodePacked(baseString, "-R"));
            memberAddressStrings[participantIndex] = Strings.toHexString(uint160(participants[participantIndex]), 20);
            
            participantIndex++;
        }
        weeklyGroups[_communityId][currentWeek].push(Group(groupMembers));
        
        // Populate new arrays for the modified WeeklyGroupsCreated event
        roomIds[i] = Strings.toString(i + 1);
        roomIdentifiers[i] = string(abi.encodePacked(
            Strings.toString(_communityId),
            "-",
            Strings.toString(currentWeek),
            "-",
            Strings.toString(i + 1)
        ));
    }

    lastRoomSizes = roomSizes;

    emit NewGroupsCreated(
        fid(_communityId, currentWeek),
        contributionStrings,
        rankingStrings,
        memberAddressStrings
    );

    // Modified WeeklyGroupsCreated event emission
    emit WeeklyGroupsCreated(
        string(abi.encodePacked(Strings.toString(_communityId), "-", Strings.toString(currentWeek))),
        roomIds,
        roomIdentifiers,
        Strings.toString(currentWeek)
    );
}
*/

/*
    function createGroupsForCurrentWeek(uint256 _communityId) external override {
        (, , , , , ICommunityGovernanceProfiles.CommunityState state,uint256 currentWeek ,) = profilesContract.getCommunityProfile(_communityId);

        require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in contribution ranking state");
        require(weeklyGroups[_communityId][currentWeek].length == 0, "Groups already created for this week");

        address[] memory participants = weeklyContributors[_communityId][currentWeek];
        require(participants.length > 0, "No contributors for the current week");

        shuffle(participants);
        uint8[] memory roomSizes = determineRoomSizes(participants.length);

        uint256 participantIndex = 0;
        for (uint256 i = 0; i < roomSizes.length; i++) {
            address[] memory groupMembers = new address[](roomSizes[i]);
            for (uint256 j = 0; j < roomSizes[i] && participantIndex < participants.length; j++) {
                groupMembers[j] = participants[participantIndex++];
            }
            weeklyGroups[_communityId][currentWeek].push(Group(groupMembers));
        }

        lastRoomSizes = roomSizes;
        //emit GroupsCreated(_communityId, currentWeek, weeklyGroups[_communityId][currentWeek].length);
    }
*/
/*
function createGroupsForCurrentWeek(uint256 _communityId) external override {
    (,,,,,ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);

    require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in contribution ranking state");
    //require(weeklyGroups[_communityId][currentWeek].length == 0, "Groups already created for this week");

    address[] memory participants = weeklyContributors[_communityId][currentWeek];
    require(participants.length > 1, "No contributors for the current week");

    shuffle(participants);
    uint8[] memory roomSizes = determineRoomSizes(participants.length);

    uint256 participantIndex = 0;
    uint256 totalParticipants = 0;
    for (uint256 i = 0; i < roomSizes.length; i++) {
        totalParticipants += roomSizes[i];
    }

    string[] memory contributionStrings = new string[](totalParticipants);
    string[] memory rankingStrings = new string[](totalParticipants);
    string[] memory memberAddressStrings = new string[](totalParticipants);

    uint256 stringIndex = 0;
    for (uint256 i = 0; i < roomSizes.length; i++) {
        address[] memory groupMembers = new address[](roomSizes[i]);
        for (uint256 j = 0; j < roomSizes[i] && participantIndex < participants.length; j++) {
            groupMembers[j] = participants[participantIndex];
            
            string memory baseString = string(abi.encodePacked(
                Strings.toString(_communityId),
                " - ",
                Strings.toString(currentWeek),
                " - ",
                Strings.toString(i + 1),
                " - ",
                Strings.toHexString(uint160(participants[participantIndex]), 20)
            ));
            
            contributionStrings[stringIndex] = string(abi.encodePacked(baseString, " - Contribution"));
            rankingStrings[stringIndex] = string(abi.encodePacked(baseString, " - Ranking"));
            memberAddressStrings[stringIndex] = Strings.toHexString(uint160(participants[participantIndex]), 20);
            
            stringIndex++;
            participantIndex++;
        }
        weeklyGroups[_communityId][currentWeek].push(Group(groupMembers));
    }

    lastRoomSizes = roomSizes;

    emit NewGroupsCreated(
        formatEventId(_communityId, currentWeek),
        contributionStrings,
        rankingStrings,
        memberAddressStrings
    );

    string[] memory roomIds = new string[](roomSizes.length);

    // New emit event
    emit WeeklyGroupsCreated(
    string(abi.encodePacked(Strings.toString(_communityId), " - ", Strings.toString(currentWeek))),
    roomIds,
    Strings.toString(currentWeek)
);


}
*/
/*
function createGroupsForCurrentWeek(uint256 _communityId) external override {
    (,,,,,ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);
    require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in contribution ranking state");

    address[] memory participants = weeklyContributors[_communityId][currentWeek];
    require(participants.length > 1, "No contributors for the current week");

    shuffle(participants);
    uint8[] memory roomSizes = determineRoomSizes(participants.length);

    string[] memory contributionStrings = new string[](participants.length);
    string[] memory rankingStrings = new string[](participants.length);
    string[] memory memberAddressStrings = new string[](participants.length);
    
    // New arrays for the modified WeeklyGroupsCreated event
    string[] memory roomIds = new string[](roomSizes.length);
    string[] memory roomIdentifiers = new string[](roomSizes.length);

    uint256 participantIndex = 0;
    for (uint256 i = 0; i < roomSizes.length; i++) {
        address[] memory groupMembers = new address[](roomSizes[i]);
        for (uint256 j = 0; j < roomSizes[i] && participantIndex < participants.length; j++) {
            groupMembers[j] = participants[participantIndex];
            
            string memory baseString = string(abi.encodePacked(
                Strings.toString(_communityId),
                "-",
                Strings.toString(currentWeek),
                "-",
                Strings.toString(i + 1),
                "-",
                Strings.toHexString(uint160(participants[participantIndex]), 20)
            ));
            
            contributionStrings[participantIndex] = string(abi.encodePacked(baseString, "-Contribution"));
            rankingStrings[participantIndex] = string(abi.encodePacked(baseString, "-Ranking"));
            memberAddressStrings[participantIndex] = Strings.toHexString(uint160(participants[participantIndex]), 20);
            
            participantIndex++;
        }
        weeklyGroups[_communityId][currentWeek].push(Group(groupMembers));
        
        // Populate new arrays for the modified WeeklyGroupsCreated event
        roomIds[i] = Strings.toString(i + 1);
        roomIdentifiers[i] = string(abi.encodePacked(
            Strings.toString(_communityId),
            "-",
            Strings.toString(currentWeek),
            "-",
            Strings.toString(i + 1)
        ));
    }

    lastRoomSizes = roomSizes;

    emit NewGroupsCreated(
        formatEventId(_communityId, currentWeek),
        contributionStrings,
        rankingStrings,
        memberAddressStrings
    );

    // Modified WeeklyGroupsCreated event emission
    emit WeeklyGroupsCreated(
        string(abi.encodePacked(Strings.toString(_communityId), "-", Strings.toString(currentWeek))),
        roomIds,
        roomIdentifiers,
        Strings.toString(currentWeek)
    );
}
*/
/*
function createGroupsForCurrentWeek(uint256 _communityId) external override {
    (,,,,,ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);

    require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in contribution ranking state");
    require(weeklyGroups[_communityId][currentWeek].length == 0, "Groups already created for this week");

    address[] memory participants = weeklyContributors[_communityId][currentWeek];
    require(participants.length > 0, "No contributors for the current week");

    shuffle(participants);
    uint8[] memory roomSizes = determineRoomSizes(participants.length);

    uint256 participantIndex = 0;
    uint256 totalParticipants = 0;
    for (uint256 i = 0; i < roomSizes.length; i++) {
        totalParticipants += roomSizes[i];
    }

    string[] memory contributionStrings = new string[](totalParticipants);
    string[] memory rankingStrings = new string[](totalParticipants);
    string[] memory memberAddressStrings = new string[](totalParticipants);
    string[] memory roomIds = new string[](roomSizes.length);

    uint256 stringIndex = 0;
    for (uint256 i = 0; i < roomSizes.length; i++) {
        address[] memory groupMembers = new address[](roomSizes[i]);
        for (uint256 j = 0; j < roomSizes[i] && participantIndex < participants.length; j++) {
            groupMembers[j] = participants[participantIndex];
            
            string memory baseString = string(abi.encodePacked(
                Strings.toString(_communityId),
                " - ",
                Strings.toString(currentWeek),
                " - ",
                Strings.toString(i + 1),
                " - ",
                Strings.toHexString(uint160(participants[participantIndex]), 20)
            ));
            
            contributionStrings[stringIndex] = string(abi.encodePacked(baseString, " - Contribution"));
            rankingStrings[stringIndex] = string(abi.encodePacked(baseString, " - Ranking"));
            memberAddressStrings[stringIndex] = Strings.toHexString(uint160(participants[participantIndex]), 20);
            
            stringIndex++;
            participantIndex++;
        }
        weeklyGroups[_communityId][currentWeek].push(Group(groupMembers));
        roomIds[i] = Strings.toString(i + 1);
    }

    lastRoomSizes = roomSizes;

    emit NewGroupsCreated(
        formatEventId(_communityId, currentWeek),
        contributionStrings,
        rankingStrings,
        memberAddressStrings
    );

}
*/
function fid (uint256 _communityId, uint256 _currentWeek) private view returns (string memory) {
    return string(abi.encodePacked(
        Strings.toString(_communityId),
        " - ",
        Strings.toString(_currentWeek),
        " - ",
        Strings.toString(weeklyGroups[_communityId][_currentWeek].length)
    ));
}

    function getGroupsForWeek(uint256 _communityId, uint256 _weekNumber) public view override returns (Group[] memory) {
        return weeklyGroups[_communityId][_weekNumber];
    }
/*
// Helper function to convert address array to string
function addressesToString(address[] memory addresses) internal pure returns (string memory) {
    bytes memory addressBytes;
    for (uint i = 0; i < addresses.length; i++) {
        if (i > 0) {
            addressBytes = abi.encodePacked(addressBytes, ",");
        }
        addressBytes = abi.encodePacked(addressBytes, Strings.toHexString(uint160(addresses[i]), 20));
    }
    return string(addressBytes);
}

   */ 
/*
    function getContributions(address _user, uint256 _communityId, uint256 _weekNumber) public view returns (string[] memory names, string[] memory descriptions, string[][] memory links) {
        require(userContributions[_user][_communityId].communityId != 0, "No contributions found for this user in this community");
        Contribution[] memory contributions = userContributions[_user][_communityId].weeklyContributions[_weekNumber].contributions;
        names = new string[](contributions.length);
        descriptions = new string[](contributions.length);
        links = new string[][](contributions.length);
        for (uint i = 0; i < contributions.length; i++) {
            names[i] = contributions[i].name;
            descriptions[i] = contributions[i].description;
            links[i] = contributions[i].links;
        }
    }
*/
/*
    function getUserContributedWeeks(address _user, uint256 _communityId) public view returns (uint256[] memory) {
        require(userContributions[_user][_communityId].communityId != 0, "No contributions found for this user in this community");
        return userContributions[_user][_communityId].contributedWeeks;
    }
*/
    function getLastRoomSizes() public view returns (uint8[] memory) {
        return lastRoomSizes;
    }

    function getWeeklyContributors(uint256 _communityId, uint256 _week) public view override returns (address[] memory) {
        return weeklyContributors[_communityId][_week];
    }
   
/*
    function updateRespectData(uint256 _communityId, address _user, uint256 _weekNumber, uint256 _respect) external override {
        UserContributions storage userContrib = userContributions[_user][_communityId];
        WeeklyContributions storage weeklyContrib = userContrib.weeklyContributions[_weekNumber];

        uint256 scaledRespect = _respect * SCALING_FACTOR;
        weeklyContrib.respectReceived = scaledRespect;
        userContrib.totalRespect += scaledRespect;

        // Update last 12 weeks respect
        if (userContrib.last12WeeksRespect.length < 12) {
            userContrib.last12WeeksRespect.push(scaledRespect);
        } else {
            for (uint256 i = 0; i < 11; i++) {
                userContrib.last12WeeksRespect[i] = userContrib.last12WeeksRespect[i + 1];
            }
            userContrib.last12WeeksRespect[11] = scaledRespect;
        }

        // Calculate and update average respect
        uint256 totalRespect = 0;
        for (uint256 i = 0; i < userContrib.last12WeeksRespect.length; i++) {
            totalRespect += userContrib.last12WeeksRespect[i];
        }
        userContrib.averageRespect = totalRespect / 12; // Always divide by 12, even if 12 weeks haven't passed

        emit RespectUpdated(_user, _communityId, _weekNumber, scaledRespect, userContrib.averageRespect);
    }
*/
function updateRespectData(uint256 _communityId, address _user, uint256 _weekNumber, uint256 _respect) external override {
    _updateRespectData(_communityId, _user, _weekNumber, _respect);
}

function _updateRespectData(uint256 _communityId, address _user, uint256 _weekNumber, uint256 _respect) internal {
    UserContributions storage userContrib = userContributions[_user][_communityId];
    WeeklyContributions storage weeklyContrib = userContrib.weeklyContributions[_weekNumber];

    uint256 scaledRespect = _respect * SCALING_FACTOR;
    weeklyContrib.respectReceived = scaledRespect;
    userContrib.totalRespect += scaledRespect;

    // Always update last 12 weeks respect
    if (userContrib.last12WeeksRespect.length < 12) {
        userContrib.last12WeeksRespect.push(scaledRespect);
    } else {
        for (uint256 i = 0; i < 11; i++) {
            userContrib.last12WeeksRespect[i] = userContrib.last12WeeksRespect[i + 1];
        }
        userContrib.last12WeeksRespect[11] = scaledRespect;
    }

    updateAverageRespect(_communityId, _user);

    emit RespectUpdated(_user, userContrib.totalRespect, userContrib.averageRespect);
}

    function updateAverageRespect(uint256 _communityId, address _user) internal {
        UserContributions storage userContrib = userContributions[_user][_communityId];
        uint256 totalRespect = 0;
        uint256 weeksCount = userContrib.last12WeeksRespect.length;

        for (uint256 i = 0; i < weeksCount; i++) {
            totalRespect += userContrib.last12WeeksRespect[i];
        }

        // Always divide by 12, even if 12 weeks haven't passed
        userContrib.averageRespect = totalRespect / 12;
    }
/*
  function updateAllUsersRespectData(uint256 _communityId) external {
        (, , , , , , uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);
        (address[] memory allUsers, ) = profilesContract.getCommunityMembers(_communityId);

        for (uint256 i = 0; i < allUsers.length; i++) {
            address user = allUsers[i];
            UserContributions storage userContrib = userContributions[user][_communityId];

            // Ensure the user has a contribution record for this community
            if (userContrib.communityId == 0) {
                userContrib.communityId = _communityId;
            }

            // Check if the user has contributed this week
            if (userContrib.weeklyContributions[currentWeek - 1].respectReceived == 0) {
                // User didn't participate, add 0 to their last12WeeksRespect
                if (userContrib.last12WeeksRespect.length < 12) {
                    userContrib.last12WeeksRespect.push(0);
                } else {
                    for (uint256 j = 0; j < 11; j++) {
                        userContrib.last12WeeksRespect[j] = userContrib.last12WeeksRespect[j + 1];
                    }
                    userContrib.last12WeeksRespect[11] = 0;
                }

                updateAverageRespect(_communityId, user);
            }
        }
    }
*/
function updateAllUsersRespectData(uint256 _communityId) external {
    (, , , , , , uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);
    (address[] memory allUsers, ) = profilesContract.getCommunityMembers(_communityId);

    // Get the list of contributors for the current week
    address[] memory contributors = weeklyContributors[_communityId][currentWeek - 1];

    for (uint256 i = 0; i < allUsers.length; i++) {
        address user = allUsers[i];
        bool izContributor = false;
        for (uint256 j = 0; j < contributors.length; j++) {
            if (user == contributors[j]) {
                izContributor = true;
                break;
            }
        }
        
        if (!izContributor) {
            // Update non-contributors with 0 respect
            _updateRespectData(_communityId, user, currentWeek - 1, 0);
        }
        // Note: Contributors are updated in the determineConsensusForAllGroups function
    }
}

/*
function updateAllUsersRespectData(uint256 _communityId) external {
    (, , , , , , uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);
    (address[] memory allUsers, ) = profilesContract.getCommunityMembers(_communityId);

    for (uint256 i = 0; i < allUsers.length; i++) {
        address user = allUsers[i];
        UserContributions storage userContrib = userContributions[user][_communityId];

        // Ensure the user has a contribution record for this community
        if (userContrib.communityId == 0) {
            userContrib.communityId = _communityId;
        }

        // Check if we need to add a new entry (only if the array is empty or the last entry isn't for the current week)
        if (userContrib.last12WeeksRespect.length == 0 || userContrib.last12WeeksRespect.length < currentWeek - 1) {
            uint256 respectReceived = userContrib.weeklyContributions[currentWeek - 1].respectReceived;
            
            if (userContrib.last12WeeksRespect.length < 12) {
                userContrib.last12WeeksRespect.push(respectReceived);
            } else {
                for (uint256 j = 0; j < 11; j++) {
                    userContrib.last12WeeksRespect[j] = userContrib.last12WeeksRespect[j + 1];
                }
                userContrib.last12WeeksRespect[11] = respectReceived;
            }

            updateAverageRespect(_communityId, user);
        }
    }
}
*/
    function getAverageRespect(address _user, uint256 _communityId) public view override returns (uint256) {
        return userContributions[_user][_communityId].averageRespect;
    }

    function getUserRespectData(address _user, uint256 _communityId) public view  returns (uint256 totalRespect, uint256 averageRespect, uint256[] memory last12WeeksRespect) {
        UserContributions storage userContrib = userContributions[_user][_communityId];
        totalRespect = userContrib.totalRespect;
        averageRespect = userContrib.averageRespect;
        last12WeeksRespect = userContrib.last12WeeksRespect;
    }

    function getCurrentWeek(uint256 _communityId) public view override returns (uint256) {
        (, , , , , , uint256 currentWeek,) = profilesContract.getCommunityProfile(_communityId);
        return currentWeek;
    }
/*
    function isContributor(uint256 _communityId, uint256 _week, address _user) internal view returns (bool) {
        address[] memory contributors = weeklyContributors[_communityId][_week];
        for (uint i = 0; i < contributors.length; i++) {
            if (contributors[i] == _user) return true;
        }
        return false;
    }
*/
    function shuffle(address[] memory array) internal view {
        for (uint256 i = array.length - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i))) % (i + 1);
            (array[i], array[j]) = (array[j], array[i]);
        }
    }

    function determineRoomSizes(uint256 numParticipants) internal pure returns (uint8[] memory) {
        return numParticipants <= 20 ? hardcodedRoomSizes(numParticipants) : genericRoomSizes(numParticipants);
    }

    function hardcodedRoomSizes(uint256 numParticipants) internal pure returns (uint8[] memory) {
        uint8[] memory sizes;
        if (numParticipants == 1) sizes = new uint8[](1);
        else if (numParticipants == 2) sizes = new uint8[](1);
        else if (numParticipants == 3) sizes = new uint8[](1);
        else if (numParticipants == 4) sizes = new uint8[](1);
        else if (numParticipants == 5) sizes = new uint8[](1);
        else if (numParticipants == 6) sizes = new uint8[](1);
        else if (numParticipants == 7) sizes = new uint8[](2);
        else if (numParticipants == 8) sizes = new uint8[](2);
        else if (numParticipants == 9) sizes = new uint8[](2);
        else if (numParticipants == 10) sizes = new uint8[](2);
        else if (numParticipants == 11) sizes = new uint8[](2);
        else if (numParticipants == 12) sizes = new uint8[](2);
        else if (numParticipants == 13) sizes = new uint8[](3);
        else if (numParticipants == 14) sizes = new uint8[](3);
        else if (numParticipants == 15) sizes = new uint8[](3);
        else if (numParticipants == 16) sizes = new uint8[](3);
        else if (numParticipants == 17) sizes = new uint8[](3);
        // ... (continued from previous artifact)

    else if (numParticipants == 18) sizes = new uint8[](3);
    else if (numParticipants == 19) sizes = new uint8[](4);
    else if (numParticipants == 20) sizes = new uint8[](4);

    if (numParticipants == 1) sizes[0] = 1;
    else if (numParticipants == 2) sizes[0] = 2;
    else if (numParticipants == 3) sizes[0] = 3;
    else if (numParticipants == 4) sizes[0] = 4;
    else if (numParticipants == 5) sizes[0] = 5;
    else if (numParticipants == 6) sizes[0] = 6;
    else if (numParticipants == 7) { sizes[0] = 3; sizes[1] = 4; }
    else if (numParticipants == 8) { sizes[0] = 4; sizes[1] = 4; }
    else if (numParticipants == 9) { sizes[0] = 5; sizes[1] = 4; }
    else if (numParticipants == 10) { sizes[0] = 5; sizes[1] = 5; }
    else if (numParticipants == 11) { sizes[0] = 5; sizes[1] = 6; }
    else if (numParticipants == 12) { sizes[0] = 6; sizes[1] = 6; }
    else if (numParticipants == 13) { sizes[0] = 5; sizes[1] = 4; sizes[2] = 4; }
    else if (numParticipants == 14) { sizes[0] = 5; sizes[1] = 5; sizes[2] = 4; }
    else if (numParticipants == 15) { sizes[0] = 5; sizes[1] = 5; sizes[2] = 5; }
    else if (numParticipants == 16) { sizes[0] = 6; sizes[1] = 5; sizes[2] = 5; }
    else if (numParticipants == 17) { sizes[0] = 6; sizes[1] = 6; sizes[2] = 5; }
    else if (numParticipants == 18) { sizes[0] = 6; sizes[1] = 6; sizes[2] = 6; }
    else if (numParticipants == 19) { sizes[0] = 5; sizes[1] = 5; sizes[2] = 5; sizes[3] = 4; }
    else if (numParticipants == 20) { sizes[0] = 5; sizes[1] = 5; sizes[2] = 5; sizes[3] = 5; }

    return sizes;
}

function genericRoomSizes(uint256 numParticipants) internal pure returns (uint8[] memory) {
    uint8[] memory sizes = new uint8[]((numParticipants + 5) / 6);  // Max possible rooms
    uint256 roomCount = 0;
    uint8 countOfFives = 0;

    while (numParticipants > 0) {
        if (numParticipants % 6 != 0 && countOfFives < 5) {
            sizes[roomCount++] = 5;
            numParticipants -= 5;
            countOfFives++;
        } else {
            sizes[roomCount++] = 6;
            numParticipants -= 6;
            if (countOfFives == 5) countOfFives = 0;
        }
    }

    // Trim the array to the actual number of rooms
    assembly {
        mstore(sizes, roomCount)
    }
    return sizes;
}


}