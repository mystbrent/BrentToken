pragma solidity ^0.5.3;

contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) public returns (bool success) {
        owner = _newOwner;
        return true;
    }
}
