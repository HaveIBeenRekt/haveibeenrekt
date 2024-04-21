// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

contract RektAttest {

    address public gov;
    uint32 public reputationThreshold;
    uint256 public rewardDivisor;

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

    event EntryProposed(address indexed _address, string indexed _description, address indexed _proposer);
    event EntryConfirmed(address indexed _address, string indexed _description, address indexed _proposer, uint _newReputation, address _confirmer);
    event EntryRemoved(address indexed _address, string indexed _description);

    // working "database" of entries
    Entry[] public entries;

    // public proposer reputations
    mapping(address => uint32) public reputations;

    // current proposed entries
    ProposedEntry[] public proposedEntries;

    // sets gov and reputation threshold when deploying
    constructor(address _gov, uint32 _thresh) {
        gov = _gov;
        reputationThreshold = _thresh;
        reputations[_gov] = _thresh;
        rewardDivisor = 1000;
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

        emit EntryProposed(_addr, _description, msg.sender);

        // add proposal automatically if submission is from reputable address
        if (reputations[msg.sender] >= reputationThreshold) {
            _confirmEntry((proposedEntries.length - 1));
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
    // Transfers ETH rewards to proposer
    function _confirmEntry(uint _index) internal {
        ProposedEntry memory currentProposedEntry = proposedEntries[_index];
        
        entries.push(currentProposedEntry._suggestion);
        reputations[currentProposedEntry._proposer] += 1;

        emit EntryConfirmed(currentProposedEntry._suggestion._address, currentProposedEntry._suggestion._description, currentProposedEntry._proposer, reputations[currentProposedEntry._proposer], msg.sender);

        address payable rewardRecipient = payable(currentProposedEntry._proposer);

        rewardRecipient.transfer((address(this).balance / rewardDivisor));

        delete proposedEntries[_index];
    }

    // allows gov to adjust reputation
    function govAdjustReputation(address _addr, uint32 _value) public {
        require(msg.sender == gov, "Only gov can adjust reputation");

        reputations[_addr] += _value;
    }

    // allows gov to delete entry
    function govDeleteEntry(uint _index) public {
        require(msg.sender == gov, "Only gov can delete entries");
        
        emit EntryRemoved(entries[_index]._address, entries[_index]._description);

        delete entries[_index];
    }

    // allows gov to set new reputation threshold
    function govSetThreshold(uint32 _thresh) public {
        require(msg.sender == gov, "Only gov can set new threshold");

        reputationThreshold = _thresh;
    }

    // reads entries, based on beginning index and maximum number to return
    function readEntries(uint _beginIndex, uint _maxNum) external view returns (Entry[] memory) {
        Entry[] memory workingEntries = new Entry[](_maxNum);

        for (uint256 i = _beginIndex; i < (_maxNum + _beginIndex); i++) {
            if (i == entries.length) {
                break;
            }
            workingEntries[i] = entries[i];
        }
        
        return workingEntries;
    }

    // allows gov to set new reward divisor value
    function govSetDivisor(uint256 _divisor) public {
        require(msg.sender == gov, "Only gov can set new divisor");
        require(_divisor > 9, "Reward divisor must be at least 10");

        rewardDivisor = _divisor;
    }

}