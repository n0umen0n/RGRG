// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CommunityStateManagerStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract CommunityStateManager is Initializable, OwnableUpgradeable, UUPSUpgradeable, CommunityStateManagerStorage {


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    event SubmissionToContributionTransition(string idWeek);
    event RankingtoSubmission(string communityId);


    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setProfilesContract(address _profilesContractAddress) external onlyOwner {
        profilesContract = ICommunityGovernanceProfiles(_profilesContractAddress);
    }

    function setRankingsContract(address _rankingsContractAddress) external onlyOwner {
        rankingsContract = ICommunityGovernanceRankings(_rankingsContractAddress);
    }

    function setContributionsContract(address _contributionsContractAddress) external onlyOwner {
        contributionsContract = ICommunityGovernanceContributions(_contributionsContractAddress);
    }

    function setMultiSigContract(address _multiSigContractAddress) external onlyOwner {
        multiSigContract = ICommunityGovernanceMultiSig(_multiSigContractAddress);
    }

    function changeState(uint256 _communityId) public {
        (,,,address creator,,ICommunityGovernanceProfiles.CommunityState currentState,uint256 eventCount,) = profilesContract.getCommunityProfile(_communityId);
        require(creator != address(0), "Community does not exist");
        //require(msg.sender == creator || msg.sender == owner(), "Not authorized to change state");

        uint256 nextStateTransitionTime = profilesContract.getNextStateTransitionTime(_communityId);
        require(block.timestamp >= nextStateTransitionTime, "State transition time not reached");

        if (currentState == ICommunityGovernanceProfiles.CommunityState.ContributionSubmission) {
            profilesContract.setCommunityState(_communityId, ICommunityGovernanceProfiles.CommunityState.ContributionRanking);
            address[] memory contributors = contributionsContract.getWeeklyContributors(_communityId, eventCount);
            require(contributors.length > 0, "No contributors for this week");
            contributionsContract.createGroupsForCurrentWeek(_communityId);
            
            // 1 day
            profilesContract.setStateTransitionTime(_communityId, block.timestamp + 1 seconds);
            
            string memory idWeek = string(abi.encodePacked(Strings.toString(_communityId), " - ", Strings.toString(eventCount)));
            emit SubmissionToContributionTransition(idWeek);

             } 
        else {
            profilesContract.setCommunityState(_communityId, ICommunityGovernanceProfiles.CommunityState.ContributionSubmission);
            profilesContract.incrementCommunityEventCount(_communityId);
            rankingsContract.determineConsensusForAllGroups(_communityId, eventCount);
            contributionsContract.updateAllUsersRespectData(_communityId);
            // Fix: Extract only the address array from getCommunityMembers
            (address[] memory members,) = profilesContract.getCommunityMembers(_communityId);
            multiSigContract.updateTopRespectedUsers(_communityId, members);        
            
            // Set next state transition time to 6 days from now
            profilesContract.setStateTransitionTime(_communityId, block.timestamp + 1 seconds);
            
            
            string memory idWeek = string(abi.encodePacked(Strings.toString(_communityId)));
            emit RankingtoSubmission(idWeek);
            
            }

/*
            emit CommunityStateChanged(_communityId, currentState == ICommunityGovernanceProfiles.CommunityState.ContributionSubmission ? 
            ICommunityGovernanceProfiles.CommunityState.ContributionRanking : 
            ICommunityGovernanceProfiles.CommunityState.ContributionSubmission);
*/

    }
}