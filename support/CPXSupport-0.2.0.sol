pragma solidity 0.4.20;

contract owned {
    address public owner;
    
    function owned() public { owner = msg.sender; }
    
    // This contract only defines a modifier but does not use
    // it - it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // "_;" in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
}

contract priced {
    modifier costs(uint price) {
        //check for value
        //if true continue
        if (msg.value >= price) {
            _;
        }
    }
}