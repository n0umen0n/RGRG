// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CommunityGovernanceRankingsStorage.sol";
import "./interfaces/ICommunityGovernanceRankings.sol";
import "./interfaces/ICommunityGovernanceProfiles.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";
import "./interfaces/ICommunityGovernanceMultiSig.sol";
import "./interfaces/ICommunityToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract CommunityGovernanceRankingsImpUUPS is 
    Initializable, 
    OwnableUpgradeable, 
    ERC1155Upgradeable,
    UUPSUpgradeable,
    CommunityGovernanceRankingsStorage, 
    ICommunityGovernanceRankings 
{    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __ERC1155_init("");
        __UUPSUpgradeable_init();
        respectValues = [21, 13, 8, 5, 3, 2];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setContracts(address _contributionsContractAddress,address _profilesContractAddress, address _multisigContractAddress ) external onlyOwner {
        contributionsContract = ICommunityGovernanceContributions(_contributionsContractAddress);
        profilesContract = ICommunityGovernanceProfiles(_profilesContractAddress); 
        multisigContract = ICommunityGovernanceMultiSig(_multisigContractAddress); 
    }

    function createCommunityToken(uint256 communityId) external  onlyOwner {
        require(!communityExists[communityId], "Community token already exists");
        communityExists[communityId] = true;
    }
/*
    function submitRanking(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, uint256[] memory _ranking) public  {
        (, , , , , ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek, ) = profilesContract.getCommunityProfile(_communityId);
        require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in ranking phase");
        require(_weekNumber == currentWeek, "Can only submit rankings for the current week");

        ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
        require(_groupId < groups.length, "Invalid group ID");
        ICommunityGovernanceContributions.Group memory group = groups[_groupId];
        require(_ranking.length == group.members.length, "Ranking must include all group members");
        require(isPartOfGroup(group, msg.sender), "Sender not part of the group");
        require(rankings[_communityId][_weekNumber][_groupId][msg.sender].rankedScores.length == 0, "Ranking already submitted");

        rankings[_communityId][_weekNumber][_groupId][msg.sender] = Ranking(_ranking);
        emit RankingSubmitted(_communityId, _weekNumber, _groupId, msg.sender);
    }
   */

function submitRanking(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, uint256[] memory _ranking) public {
    (, , , , , ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek, ) = profilesContract.getCommunityProfile(_communityId);
    require(state == ICommunityGovernanceProfiles.CommunityState.ContributionRanking, "Not in ranking phase");
    //require(_weekNumber == currentWeek, "Can only submit rankings for the current week");

    ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
    //require(_groupId < groups.length, "Invalid group ID");
    ICommunityGovernanceContributions.Group memory group = groups[_groupId];
    require(_ranking.length == group.members.length, "Ranking must include all group members");
    require(isPartOfGroup(group, msg.sender), "Sender not part of the group");
    //require(rankings[_communityId][_weekNumber][_groupId][msg.sender].rankedScores.length == 0, "Ranking already submitted");

    rankings[_communityId][_weekNumber][_groupId][msg.sender] = Ranking(_ranking);

    string[] memory rankingStrings = new string[](_ranking.length);
    for (uint256 i = 0; i < _ranking.length; i++) {
        rankingStrings[i] = Strings.toString(rankings[_communityId][_weekNumber][_groupId][msg.sender].rankedScores[i]);
    }

    // Create the eventId string
    string memory eventId = string(abi.encodePacked(
        Strings.toString(_communityId),
        " - ",
        Strings.toString(_weekNumber),
        " - ",
        Strings.toHexString(uint160(msg.sender), 20),
        " - R"
    ));

    // Emit the modified event
    emit RankingSubmitted(eventId, rankingStrings);
}

/*
    function determineConsensus(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) public  {

        //(, , , , , ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek, ) = profilesContract.getCommunityProfile(_communityId);


        ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
        require(_groupId < groups.length, "Invalid group ID");
        ICommunityGovernanceContributions.Group memory group = groups[_groupId];
        require(group.members.length > 0, "Group does not exist");
        
        //bool allSubmitted = allMembersSubmitted(_communityId, _weekNumber, _groupId, group);
        //require(allSubmitted, "Not all members have submitted rankings");

        uint256 groupSize = group.members.length;
        uint256[] memory transientScores = new uint256[](groupSize);

        for (uint256 i = 0; i < groupSize; i++) {
            transientScores[i] = calculateTransientScore(_communityId, _weekNumber, _groupId, i, group);
            //emit DebugLog("Transient score for member", transientScores[i]);
        }

        uint256[] memory consensusRanking = sortByScore(transientScores);
        consensusRankings[_communityId][_weekNumber][_groupId] = ConsensusRanking(consensusRanking, transientScores, block.timestamp);
        
       // emit ConsensusReached(_communityId, _weekNumber, _groupId, consensusRanking);

        issueRespectTokens(_communityId, _weekNumber, _groupId, group);

    }
*/
/*
function determineConsensus(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) public {
    ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
    //require(_groupId < groups.length, "Invalid group ID");
    ICommunityGovernanceContributions.Group memory group = groups[_groupId];
    //require(group.members.length > 0, "Group does not exist");

    uint256 groupSize = group.members.length;
    uint256[] memory transientScores = new uint256[](groupSize);

    for (uint256 i = 0; i < groupSize; i++) {
        transientScores[i] = calculateTransientScore(_communityId, _weekNumber, _groupId, i, group);
    }

    uint256[] memory consensusRanking = sortByScore(transientScores);
    consensusRankings[_communityId][_weekNumber][_groupId] = ConsensusRanking(consensusRanking, transientScores, block.timestamp);
    
    // Create the composite ID string
    string memory compositeId = string(abi.encodePacked(
        Strings.toString(_communityId),
        " - ",
        Strings.toString(_weekNumber),
        " - ",
        Strings.toString(_groupId)
    ));

    // Convert consensusRanking to an array of strings
    string[] memory rankingStrings = new string[](consensusRanking.length);
    for (uint256 i = 0; i < consensusRanking.length; i++) {
        rankingStrings[i] = Strings.toString(consensusRanking[i]);
    }

    // Emit the modified ConsensusReached event
    emit ConsensusReached(compositeId, rankingStrings);

    issueRespectTokens(_communityId, _weekNumber, _groupId, group);
}
*/
/*
    function determineConsensus(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) public  {

        //(, , , , , ICommunityGovernanceProfiles.CommunityState state, uint256 currentWeek, ) = profilesContract.getCommunityProfile(_communityId);

        ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
        require(_groupId < groups.length, "Invalid group ID");
        ICommunityGovernanceContributions.Group memory group = groups[_groupId];
        require(group.members.length > 0, "Group does not exist");
        
        //bool allSubmitted = allMembersSubmitted(_communityId, _weekNumber, _groupId, group);
        //require(allSubmitted, "Not all members have submitted rankings");

        uint256 groupSize = group.members.length;
        uint256[] memory transientScores = new uint256[](groupSize);

        for (uint256 i = 0; i < groupSize; i++) {
            transientScores[i] = calculateTransientScore(_communityId, _weekNumber, _groupId, i, group);
            //emit DebugLog("Transient score for member", transientScores[i]);
        }

        uint256[] memory consensusRanking = sortByScore(transientScores);
        consensusRankings[_communityId][_weekNumber][_groupId] = ConsensusRanking(consensusRanking, transientScores, block.timestamp);
        //emit ConsensusReached(_communityId, _weekNumber, _groupId, consensusRanking);

        issueRespectTokens(_communityId, _weekNumber, _groupId, group);

    }
*/

function determineConsensus(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) public {
    
    ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
    ICommunityGovernanceContributions.Group memory group = groups[_groupId];
    //require(_groupId < groups.length, "Group ID is out of bounds");

    uint256 groupSize = group.members.length;
    uint256[] memory transientScores = new uint256[](groupSize);

    for (uint256 i = 0; i < groupSize; i++) {
        transientScores[i] = calculateTransientScore(_communityId, _weekNumber, _groupId, i, group);
    }

    uint256[] memory consensusRanking = sortByScore(transientScores);
    ConsensusRanking memory newConsensusRanking = ConsensusRanking(consensusRanking, transientScores, block.timestamp);
    consensusRankings[_communityId][_weekNumber][_groupId] = newConsensusRanking;
    
    // Create the composite ID string
    string memory compositeId = string(abi.encodePacked(
        Strings.toString(_communityId),
        "-",
        Strings.toString(_weekNumber),
        "-",
        Strings.toString(_groupId)
    ));

    // Convert rankedScores to an array of ranking number strings
string[] memory rankingNumberStrings = new string[](consensusRanking.length);
for (uint256 i = 0; i < consensusRanking.length; i++) {
    rankingNumberStrings[i] = Strings.toString(consensusRanking[i]);
}



    // Emit the modified ConsensusReached event
    emit ConsensusReached(compositeId, rankingNumberStrings);

    issueRespectTokens(_communityId, _weekNumber, _groupId, group);
    
}



    function fib(uint8 n) internal pure returns (uint256) {
        if (n <= 1) return n;
        uint256 a = 0;
        uint256 b = 1;
        for (uint8 i = 2; i <= n; i++) {
            uint256 c = a + b;
            a = b;
            b = c;
        }
        return b;
    }

    function distributeRespect(uint256 totalRespect, uint256[][] memory groupRankings) internal pure returns (uint256[] memory) {
        uint256 totalParticipants = 0;
        for (uint256 i = 0; i < groupRankings.length; i++) {
            totalParticipants += groupRankings[i].length;
        }
        
        uint256[] memory distribution = new uint256[](totalParticipants);
        uint256 totalWeight = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < groupRankings.length; i++) {
            for (uint256 j = 0; j < groupRankings[i].length; j++) {
                uint256 weight = fib(uint8(6 - j)); // 6 is used as the starting point, adjust if needed
                totalWeight += weight;
                distribution[currentIndex] = weight;
                currentIndex++;
            }
        }

        for (uint256 i = 0; i < distribution.length; i++) {
            distribution[i] = (distribution[i] * totalRespect) / totalWeight;
        }

        return distribution;
    }

    function determineConsensusForAllGroups(uint256 _communityId, uint256 _weekNumber) external override {
        
        (uint256 totalRespectToDistribute, ) = multisigContract.getMultiSigInfo(_communityId);
        ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
        
        uint256[][] memory allGroupRankings = new uint256[][](groups.length);
        
        for (uint256 i = 0; i < groups.length; i++) {
            determineConsensus(_communityId, _weekNumber, i);
            ConsensusRanking storage consensusRanking = consensusRankings[_communityId][_weekNumber][i];
            allGroupRankings[i] = consensusRanking.rankedScores;
        }
        
        uint256[] memory distribution = distributeRespect(totalRespectToDistribute, allGroupRankings);
        
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < groups.length; i++) {
            for (uint256 j = 0; j < groups[i].members.length; j++) {
                address member = groups[i].members[j];
                uint256 respectAmount = distribution[currentIndex];
                
                // Update claimable tokens
                //userClaimableTokens[_communityId][member].amount += respectAmount;
                if (respectAmount > 0) {
                (, , , , , , , address tokenAddress) = profilesContract.getCommunityProfile(_communityId);
                ICommunityToken communityToken = ICommunityToken(tokenAddress);

                communityToken.mint(member, respectAmount);
                }
                // Update respect data in contributions contract
                //contributionsContract.updateRespectData(_communityId, member, _weekNumber, respectAmount);
                
                //_mint(recipient, _communityId, respectAmount, "");

                ////emit RespectIssued(_communityId, _weekNumber, i, member, respectAmount);
                currentIndex++;
            }
        }


    }

/*
function determineConsensusForAllGroups(uint256 _communityId, uint256 _weekNumber) external override {
    // Retrieve total respect to distribute and the groups for the given week
    (uint256 totalRespectToDistribute, ) = multisigContract.getMultiSigInfo(_communityId);
    ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);

    uint256[][] memory allGroupRankings = new uint256[][](groups.length);

    // Determine consensus for each group and collect their rankings
    for (uint256 i = 0; i < groups.length; i++) {
        determineConsensus(_communityId, _weekNumber, i);
        ConsensusRanking storage consensusRanking = consensusRankings[_communityId][_weekNumber][i];
        allGroupRankings[i] = consensusRanking.rankedScores;
    }

    // Distribute respect based on all group rankings
    uint256[] memory distribution = distributeRespect(totalRespectToDistribute, allGroupRankings);

    // Initialize currentIndex to track the distribution array
    uint256 currentIndex = 0;

    // Loop through each group and their members to mint respect tokens
    for (uint256 i = 0; i < groups.length && currentIndex < distribution.length; i++) {
        for (uint256 j = 0; j < groups[i].members.length && currentIndex < distribution.length; j++) {
            address member = groups[i].members[j];
            uint256 respectAmount = distribution[currentIndex];

            if (respectAmount > 0) {
                // Retrieve the community token address
                (, , , , , , , address tokenAddress) = profilesContract.getCommunityProfile(_communityId);
                ICommunityToken communityToken = ICommunityToken(tokenAddress);

                // Mint respect tokens to the member
                communityToken.mint(member, respectAmount);
            }

            // Increment the currentIndex to move to the next distribution amount
            currentIndex++;
        }
    }

    // Optional: Update all users' respect data in the contributions contract
    // contributionsContract.updateAllUsersRespectData(_communityId);
}
*/
    function calculateTransientScore(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, uint256 memberIndex, ICommunityGovernanceContributions.Group memory group) private view returns (uint256) {
        uint256[] memory memberRankings = new uint256[](group.members.length);
        for (uint256 i = 0; i < group.members.length; i++) {
            memberRankings[i] = rankings[_communityId][_weekNumber][_groupId][group.members[i]].rankedScores[memberIndex];
        }

        uint256 meanRanking = calculateMean(memberRankings);
        uint256 variance = calculateVariance(memberRankings);
        uint256 maxVariance = calculateMaxVariance(group.members.length);

        uint256 consensusTerm;
        if (maxVariance == 0) {
            consensusTerm = SCALE;
        } else {
            consensusTerm = SCALE - ((variance * SCALE) / maxVariance);
        }

        return (meanRanking * consensusTerm) / SCALE;
    }

    function calculateMean(uint256[] memory values) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            sum += values[i];
        }
        return (sum * SCALE) / values.length;
    }

    function calculateVariance(uint256[] memory values) private pure returns (uint256) {
        uint256 mean = calculateMean(values);
        uint256 sumSquaredDiff = 0;
        for (uint256 i = 0; i < values.length; i++) {
            int256 diff = int256(values[i] * SCALE) - int256(mean);
            sumSquaredDiff += uint256(diff * diff) / SCALE;
        }
        return sumSquaredDiff / values.length;
    }

    function calculateMaxVariance(uint256 groupSize) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 x = 1; x < groupSize; x++) {
            sum += x * SCALE / 2;
        }
        return (groupSize * sum) / (groupSize - 1);
    }

    function sortByScore(uint256[] memory _scores) private pure returns (uint256[] memory) {
        uint256[] memory indices = new uint256[](_scores.length);
        for (uint256 i = 0; i < indices.length; i++) {
            indices[i] = i;
        }

        for (uint256 i = 0; i < _scores.length - 1; i++) {
            for (uint256 j = i + 1; j < _scores.length; j++) {
                if (_scores[indices[i]] < _scores[indices[j]]) {
                    (indices[i], indices[j]) = (indices[j], indices[i]);
                }
            }
        }

        uint256[] memory finalRanking = new uint256[](_scores.length);
        for (uint256 i = 0; i < finalRanking.length; i++) {
            finalRanking[indices[i]] = _scores.length - i;
        }

        return finalRanking;
    }

    function isPartOfGroup(ICommunityGovernanceContributions.Group memory group, address _member) private pure returns (bool) {
        for (uint256 i = 0; i < group.members.length; i++) {
            if (group.members[i] == _member) return true;
        }
        return false;
    }
/*
    function allMembersSubmitted(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, ICommunityGovernanceContributions.Group memory group) private view returns (bool) {
        for (uint256 i = 0; i < group.members.length; i++) {
            if (rankings[_communityId][_weekNumber][_groupId][group.members[i]].rankedScores.length == 0) {
                return false;
            }
        }
        return true;
    }
*/
    function issueRespectTokens(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, ICommunityGovernanceContributions.Group memory group) private {
        uint256[] memory ranking = consensusRankings[_communityId][_weekNumber][_groupId].rankedScores;
        uint256 membersCount = group.members.length;

        //require(ranking.length == membersCount, "Ranking length mismatch");

        for (uint256 i = 0; i < membersCount && i < respectValues.length; i++) {
           //require(ranking[i] > 0 && ranking[i] <= membersCount, "Invalid ranking");
            address recipient = group.members[ranking[i] - 1];
            uint256 respectAmount = respectValues[i];

            //require(recipient != address(0), "Invalid recipient address");

            // Directly mint tokens instead of calling an external function
            //_mint(recipient, _communityId, respectAmount, "");
            contributionsContract.updateRespectData(_communityId, recipient, _weekNumber, respectAmount);
            ////emit RespectIssued(_communityId, _weekNumber, _groupId, recipient, respectAmount);
        }
    }
/*
    // Getter functions
    function getConsensusRanking(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) public view  returns (uint256[] memory rankedScores, uint256[] memory transientScores, uint256 timestamp) {
        ConsensusRanking storage consensusRanking = consensusRankings[_communityId][_weekNumber][_groupId];
        return (consensusRanking.rankedScores, consensusRanking.transientScores, consensusRanking.timestamp);
    }
*/
/*
    function getRanking(uint256 _communityId, uint256 _weekNumber, uint256 _groupId, address _user) public view  returns (uint256[] memory) {
        return rankings[_communityId][_weekNumber][_groupId][_user].rankedScores;
    }
*/
/*
    function getTransientScores(uint256 _communityId, uint256 _weekNumber, uint256 _groupId) public view  returns (address[] memory, uint256[] memory) {
        ICommunityGovernanceContributions.Group[] memory groups = contributionsContract.getGroupsForWeek(_communityId, _weekNumber);
        require(_groupId < groups.length, "Invalid group ID");
        ICommunityGovernanceContributions.Group memory group = groups[_groupId];
        uint256 groupSize = group.members.length;
        address[] memory members = new address[](groupSize);
        uint256[] memory scores = new uint256[](groupSize);

        for (uint256 i = 0; i < groupSize; i++) {
            members[i] = group.members[i];
            scores[i] = calculateTransientScore(_communityId, _weekNumber, _groupId, i, group);
        }

        return (members, scores);
    }

/*
    function claimTokens(uint256 _communityId) external  {
        ClaimableTokens storage claimable = userClaimableTokens[_communityId][msg.sender];
        require(claimable.amount > 0, "No tokens to claim");
        require(!claimable.claimed, "Tokens already claimed");

        // Here you would typically transfer the tokens to the user
        // For this example, we'll just mark them as claimed
        claimable.claimed = true;

        //emit TokensClaimed(_communityId, msg.sender, claimable.amount);
    }

    function getClaimableTokens(uint256 _communityId, address _user) external view  returns (uint256 amount, bool claimed) {
        ClaimableTokens storage claimable = userClaimableTokens[_communityId][_user];
        return (claimable.amount, claimable.claimed);
    }
 */
}