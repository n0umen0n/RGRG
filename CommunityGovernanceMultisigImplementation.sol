// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/ICommunityGovernanceProfiles.sol";
import "./interfaces/ICommunityGovernanceContributions.sol";
import "./interfaces/ICommunityGovernanceMultiSig.sol";
import "./CommunityGovernanceMultiSigStorage.sol";
import "./interfaces/ICommunityToken.sol";

contract CommunityGovernanceMultiSigImplementation is 
    Initializable, 
    OwnableUpgradeable, 
    UUPSUpgradeable,
    CommunityGovernanceMultiSigStorage, 
    ICommunityGovernanceMultiSig 
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
        profilesContract = ICommunityGovernanceProfiles(_profilesContractAddress);
    }

    function setContributionsContract(address _contributionsContractAddress) external onlyOwner {
        contributionsContract = ICommunityGovernanceContributions(_contributionsContractAddress);
    }

    //make sure only profiles contract can trigger
function updateTopRespectedUsers(uint256 _communityId, address[] memory allMembers) external  {
    require(allMembers.length > 0, "Community must have members");
    require(address(contributionsContract) != address(0), "Contributions contract not set");

    uint256[] memory respectScores = new uint256[](allMembers.length);

    for (uint256 i = 0; i < allMembers.length; i++) {
        try contributionsContract.getAverageRespect(allMembers[i], _communityId) returns (uint256 score) {
            respectScores[i] = score;
        } catch {
            respectScores[i] = 0; // Default to 0 if the call fails
        }
    }

    uint256 topCount = allMembers.length < 5 ? allMembers.length : 5;
    address[5] memory topUsers;

    for (uint256 i = 0; i < topCount; i++) {
        uint256 maxIndex = i;
        for (uint256 j = i + 1; j < allMembers.length; j++) {
            if (respectScores[j] > respectScores[maxIndex]) {
                maxIndex = j;
            }
        }
        if (maxIndex != i) {
            (allMembers[i], allMembers[maxIndex]) = (allMembers[maxIndex], allMembers[i]);
            (respectScores[i], respectScores[maxIndex]) = (respectScores[maxIndex], respectScores[i]);
        }
        topUsers[i] = allMembers[i];
    }

    // Fill remaining slots with zero address if less than 5 members
    for (uint256 i = topCount; i < 5; i++) {
        topUsers[i] = address(0);
    }

    // Update the storage with the new top users
    communityMultiSigs[_communityId].topRespectedUsers = topUsers;

    emit TopRespectedUsersUpdated(_communityId, topUsers);
    }

    function createProposal(uint256 _communityId, uint256 _proposalId, ProposalType _type, uint256 _value, address _targetMember) external {
        //require(isTopRespectedUser(msg.sender, communityMultiSigs[_communityId].topRespectedUsers), "Not authorized");
        require(communityMultiSigs[_communityId].proposals[_proposalId].signatureCount == 0, "Proposal ID already exists");
        
        MultiSigProposal storage proposal = communityMultiSigs[_communityId].proposals[_proposalId];
        
        proposal.proposalType = _type;
        proposal.value = _value;
        proposal.targetMember = _targetMember;
        proposal.signatureCount = 1;
        proposal.hasSignedProposal[msg.sender] = true;
        
        emit ProposalCreated(_communityId, _proposalId, _type);
    }

    function signProposal(uint256 _communityId, uint256 _proposalId) external {
        require(isTopRespectedUser(msg.sender, communityMultiSigs[_communityId].topRespectedUsers), "Not authorized");
        
        MultiSigProposal storage proposal = communityMultiSigs[_communityId].proposals[_proposalId];
        require(proposal.signatureCount > 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasSignedProposal[msg.sender], "Already signed");
        
        proposal.hasSignedProposal[msg.sender] = true;
        proposal.signatureCount++;
        
        emit ProposalSigned(_communityId, _proposalId, msg.sender);
        
        if (proposal.signatureCount >= 3) {
            executeProposal(_communityId, _proposalId);
        }
    }

function executeProposal(uint256 _communityId, uint256 _proposalId) internal {
        MultiSigProposal storage proposal = communityMultiSigs[_communityId].proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposal.signatureCount >= 3, "Not enough signatures");
        
        proposal.executed = true;
        
        if (proposal.proposalType == ProposalType.RemoveMember) {
            removeMember(_communityId, proposal.targetMember);
        } else if (proposal.proposalType == ProposalType.SetRespectToDistribute) {
            setRespectToDistribute(_communityId, proposal.value);
        } else if (proposal.proposalType == ProposalType.MintTokens) {
            mintTokens(_communityId, proposal.value);
        }
        
        emit ProposalExecuted(_communityId, _proposalId);
    }


      function removeMember(uint256 _communityId, address _member) internal {
        //uint256 memberCount = profilesContract.getCommunityMemberCount(_communityId);
        //require(memberCount > 1, "Cannot remove the last member");
        
        profilesContract.removeMemberFromCommunity(_communityId, _member);
        emit MemberRemoved(_communityId, _member);
    }

    function setRespectToDistributeByOwner(uint256 _communityId, uint256 _amount) external onlyOwner {
        communityMultiSigs[_communityId].respectToDistribute = _amount;
        //emit RespectToDistributeSet(_communityId, _amount);
    }

    function setRespectToDistribute(uint256 _communityId, uint256 _amount) internal {
        communityMultiSigs[_communityId].respectToDistribute = _amount;
        emit RespectToDistributeChanged(_communityId, _amount);
    }

    function mintTokens(uint256 _communityId, uint256 _amount) internal {
     (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            address tokenAddress
        ) = profilesContract.getCommunityProfile(_communityId);
        
        require(tokenAddress != address(0), "Community token not found");        
        ICommunityToken token = ICommunityToken(tokenAddress);
        token.mint(address(this), _amount);
        emit TokensMinted(_communityId, _amount);
    }

    function getRespectToDistribute(uint256 _communityId) public view returns (uint256) {
        return communityMultiSigs[_communityId].respectToDistribute;
    }


  function isTopRespectedUser(address _user, address[5] memory _topUsers) internal pure returns (bool) {
    for (uint256 i = 0; i < 5; i++) {
        if (_topUsers[i] == _user) {
            return true;
        }
        if (_topUsers[i] == address(0)) {
            break; // Stop checking if we hit a zero address
        }
    }
    return false;
}
    function getTopRespectedUsers(uint256 _communityId) external view returns (address[5] memory) {
        return communityMultiSigs[_communityId].topRespectedUsers;
    }

    function getProposal(uint256 _communityId, uint256 _proposalId) external view returns (
        ProposalType proposalType,
        uint256 value,
        address targetMember,
        uint256 signatureCount,
        bool executed
    ) {
        MultiSigProposal storage proposal = communityMultiSigs[_communityId].proposals[_proposalId];
        return (
            proposal.proposalType,
            proposal.value,
            proposal.targetMember,
            proposal.signatureCount,
            proposal.executed
        );
    }

    function hasSignedProposal(uint256 _communityId, uint256 _proposalId, address _signer) external view returns (bool) {
        return communityMultiSigs[_communityId].proposals[_proposalId].hasSignedProposal[_signer];
    }

    function getMultiSigInfo(uint256 _communityId) external view returns (uint256 respectToDistribute, address[5] memory topRespectedUsers) {
        MultiSigInfo storage multiSigInfo = communityMultiSigs[_communityId];
        return (multiSigInfo.respectToDistribute, multiSigInfo.topRespectedUsers);
    }


}