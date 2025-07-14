// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external returns (bool);
}

contract MiracleGovernance is PermissionsEnumerable {
  bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

  IERC20 public immutable Token;

  enum VoteType {
    AGAINST,
    FOR,
    ABSTAIN
  }

  struct Proposal {
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    address creator;
    bool isActive;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    address[] participants;
    bool isPassed;
  }

  mapping(uint256 => Proposal) public proposals;
  mapping(uint256 => mapping(address => uint256)) public userVotes;

  event ProposalCreated(
    uint256 indexed proposalId,
    address creator,
    uint256 startTime,
    uint256 endTime
  );
  event Voted(uint256 indexed proposalId, address voter, VoteType voteType, uint256 amount);
  event ProposalCancelled(uint256 indexed proposalId, address canceller);
  event ProposalForceCancelled(uint256 indexed proposalId, address admin);
  event ProposalEnded(uint256 indexed proposalId, address admin);

  constructor(address _token) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(FACTORY_ROLE, msg.sender);
    Token = IERC20(_token);
  }

  modifier onlyActiveProposal(uint256 _proposalId) {
    require(proposals[_proposalId].isActive, "Proposal not active");
    require(
      block.timestamp >= proposals[_proposalId].startTime &&
        block.timestamp <= proposals[_proposalId].endTime,
      "Not in proposal duration"
    );
    _;
  }

  // Write Functions

  function createProposal(
    uint256 _proposalId,
    uint256 _startTime,
    uint256 _endTime,
    address _creator
  ) external onlyRole(FACTORY_ROLE) {
    require(_startTime >= block.timestamp, "Invalid start time");
    require(_endTime > _startTime, "Invalid end time");
    require(_proposalId > 0, "Invalid proposal ID");
    require(proposals[_proposalId].id == 0, "Proposal ID already exists");

    proposals[_proposalId] = Proposal({
      id: _proposalId,
      startTime: _startTime,
      endTime: _endTime,
      creator: _creator,
      isActive: true,
      forVotes: 0,
      againstVotes: 0,
      abstainVotes: 0,
      participants: new address[](0),
      isPassed: false
    });

    emit ProposalCreated(_proposalId, _creator, _startTime, _endTime);
  }

  function vote(
    uint256 _proposalId,
    VoteType _voteType,
    uint256 _amount,
    address _voter
  ) external onlyActiveProposal(_proposalId) {
    require(_amount > 0, "Amount must be > 0");

    uint256 allowance = Token.allowance(_voter, address(this));
    require(allowance >= _amount, "Insufficient allowance");
    uint256 balance = Token.balanceOf(_voter);
    require(balance >= _amount, "Insufficient token balance");

    bool burnSuccess = Token.burnFrom(_voter, _amount);
    require(burnSuccess, "Token burn failed");

    Proposal storage proposal = proposals[_proposalId];
    if (_voteType == VoteType.FOR) {
      proposal.forVotes += _amount;
    } else if (_voteType == VoteType.AGAINST) {
      proposal.againstVotes += _amount;
    } else {
      proposal.abstainVotes += _amount;
    }

    if (userVotes[_proposalId][_voter] == 0) {
      proposal.participants.push(_voter);
    }
    userVotes[_proposalId][_voter] += _amount;

    emit Voted(_proposalId, _voter, _voteType, _amount);
  }

  function cancelVote(
    uint256 _proposalId,
    address _voter
  ) external onlyActiveProposal(_proposalId) {
    require(userVotes[_proposalId][_voter] > 0, "No votes to cancel");

    userVotes[_proposalId][_voter] = 0;
    emit ProposalCancelled(_proposalId, _voter);
  }

  function cancelProposal(
    uint256 _proposalId,
    address _canceller
  ) external onlyActiveProposal(_proposalId) {
    require(proposals[_proposalId].isActive, "Proposal not active");
    require(proposals[_proposalId].creator == _canceller, "Not proposal creator");
    proposals[_proposalId].isActive = false;
    emit ProposalCancelled(_proposalId, _canceller);
  }

  function forceCancelProposal(uint256 _proposalId) external onlyRole(FACTORY_ROLE) {
    require(proposals[_proposalId].isActive, "Proposal not active");

    proposals[_proposalId].isActive = false;
    emit ProposalForceCancelled(_proposalId, msg.sender);
  }

  function endProposal(uint256 _proposalId) external onlyRole(FACTORY_ROLE) {
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.isActive, "Proposal not active");
    require(block.timestamp > proposal.endTime, "Proposal not ended");

    proposal.isActive = false;
    emit ProposalEnded(_proposalId, msg.sender);
  }

  // Read Functions

  function getProposalInfo(uint256 _proposalId) external view returns (GeneralInfo memory) {
    Proposal memory proposal = proposals[_proposalId];
    require(proposal.id != 0, "Proposal does not exist");
    GeneralInfo memory info;
    info.id = proposal.id;
    info.startTime = proposal.startTime;
    info.endTime = proposal.endTime;
    info.creator = proposal.creator;
    info.isActive = proposal.isActive;
    return info;
  }

  function getVoteCounts(
    uint256 _proposalId
  ) external view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
    Proposal memory proposal = proposals[_proposalId];
    return (proposal.forVotes, proposal.againstVotes, proposal.abstainVotes);
  }

  struct GeneralInfo {
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    address creator;
    bool isActive;
  }

  function getParticipants(uint256 _proposalId) external view returns (address[] memory) {
    Proposal memory proposal = proposals[_proposalId];
    require(proposal.id != 0, "Proposal does not exist");
    return proposal.participants;
  }
}
