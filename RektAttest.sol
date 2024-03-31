// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

contract RektAttest {

    address public gov;

    uint32 public reputationThreshold = 10;

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

    // sets gov when deploying
    constructor(address _gov) {
        gov = _gov;
    }

    // External function to propose a new entry
    function proposeEntry(address _addr, string memory _str) public {
        _proposeEntry(_addr, _str);
    }

    // Internal function to propose a new entry
    function _proposeEntry(address _addr, string memory _str) internal {
        // add proposed entry to list
        Entry memory newEntry = Entry(_addr, _str);
        ProposedEntry memory newProposedEntry = ProposedEntry(newEntry, msg.sender);
        proposedEntries.push(newProposedEntry);

        // add proposal automatically if submission is from reputable address
        if (reputations[msg.sender] > reputationThreshold) {
            _addEntry((proposedEntries.length - 1));
        }
    }

    // External function to confirm a proposed entry by index
    function addEntry(uint index) public {
        require(reputations[msg.sender] > reputationThreshold, "Reputation too low");

        _addEntry(index);
    }

    // Internal function to confirm a proposed entry by index
    function _addEntry(uint index) internal {
        ProposedEntry memory currentProposedEntry = proposedEntries[index];
        
        entries.push(currentProposedEntry._suggestion);
        reputations[currentProposedEntry._proposer] += 1;

        delete proposedEntries[index];
    }

    // allows gov to adjust reputation
    function govAdjustReputation(address _addr, int32 _value) public {
        require(msg.sender == gov, "Only gov can adjust reputation");

        reputations[_addr] += _value;
    }

    // allows gov to delete entry
    function govDeleteEntry(uint index) public {
        require(msg.sender == gov, "Only gov can delete entries");

        delete entries[index];
    }

    // allows gov to set new reputation reputationThreshold
    function govSetThreshold(uint32 thresh) public {
        require(msg.sender == gov, "Only gov can set new threshold");

        reputationThreshold = thresh;
    }
}