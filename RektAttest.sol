// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

contract RektAttest {

    address public gov;

    uint32 public reputationThreshold;

    // Entry struct used to represent records in database of addresses
    struct Entry {
        address _address;
        string _description;
    }

    // Proposed Entry struct used to make a suggestion for new entry to database
    struct ProposedEntry {
        Entry _suggestion;
        address _proposer;
    }

    // working "database" of entries
    Entry[] public entries;

    // public proposer reputations
    mapping(address => int32) public reputations;

    // current proposed entries
    ProposedEntry[] public proposedEntries;

    // sets gov and reputation threshold when deploying
    constructor(address _gov, uint32 _thresh) {
        gov = _gov;
        reputationThreshold = _thresh;
        reputations[_gov] = _thresh;
    }

    // External function to propose a new entry
    function proposeEntry(address _addr, string memory _description) public {
        _proposeEntry(_addr, _description);
    }

    // External function to propose many new entries
    function proposeMany(address[] calldata _addrs, string[] calldata _descriptions) public {
        require(_addrs.length == _descriptions.length, "Address and description arrays must be same length");

        for (uint256 i = 0; i < _addrs.length; i++) {
            _proposeEntry(_addrs[i], _descriptions[i]);
        }
    }

    // Internal function to propose a new entry
    function _proposeEntry(address _addr, string memory _description) internal {
        // add proposed entry to list
        Entry memory newEntry = Entry(_addr, _description);
        ProposedEntry memory newProposedEntry = ProposedEntry(newEntry, msg.sender);
        proposedEntries.push(newProposedEntry);

        // add proposal automatically if submission is from reputable address
        if (reputations[msg.sender] >= reputationThreshold) {
            _addEntry((proposedEntries.length - 1));
        }
    }

    // External function to confirm a proposed entry by index
    function confirmEntry(uint _index) public {
        require(reputations[msg.sender] >= reputationThreshold, "Reputation too low");

        _confirmEntry(_index);
    }

    // External function to confirm many proposed entries by index
    function confirmMany(uint[] calldata _indices) public {
        require(reputations[msg.sender] >= reputationThreshold, "Reputation too low");

        for (uint256 i = 0; i < _indices.length; i++) {
            _confirmEntry(_indices[i]);
        }
    }

    // Internal function to confirm a proposed entry by index
    function _confirmEntry(uint _index) internal {
        ProposedEntry memory currentProposedEntry = proposedEntries[_index];
        
        entries.push(currentProposedEntry._suggestion);
        reputations[currentProposedEntry._proposer] += 1;

        delete proposedEntries[_index];
    }

    // allows gov to adjust reputation
    function govAdjustReputation(address _addr, int32 _value) public {
        require(msg.sender == gov, "Only gov can adjust reputation");

        reputations[_addr] += _value;
    }

    // allows gov to delete entry
    function govDeleteEntry(uint _index) public {
        require(msg.sender == gov, "Only gov can delete entries");

        delete entries[_index];
    }

    // allows gov to set new reputation threshold
    function govSetThreshold(uint32 _thresh) public {
        require(msg.sender == gov, "Only gov can set new threshold");

        reputationThreshold = _thresh;
    }
}