pragma solidity ^0.4.18;

import "./Ownable.sol";

contract PlayerValidator is Ownable{

    //mapping for the validationSeed - private use - player only
    mapping (address => bytes32) private vSeed;
    //list all players
    address[] private allPlayers;
    
    
    /*contract creation*/
    function PlayerValidator() public {}
    
    
    /* Information Functions 
        Many are admin only because player location is sensitive
    */
    //count of players
    function countOfPlayers() 
    external view returns (uint256 _count){
        _count = allPlayers.length;
    }
    
    //all players addresses
    function allPlayerAddresses() 
    external view returns (address[] _list){
        _list = allPlayers;
    }
    
    function isActive(address _player)
    public view returns (bool _active) {
        _active = vSeed[_player] == bytes32(0) ? false : true;
    }
    
    
    /*External For Player use */
    function createValidationHash(bytes32 _data)
    external view returns (bytes32 _hash){
        require(vSeed[msg.sender] != bytes32(0));
        _hash = keccak256(vSeed[msg.sender],_data);
    }
    
    function Validate(address _player, bytes32 _hash, bytes32 _data)
    external view returns (bool _valid){
        _valid = _hash == keccak256(vSeed[_player],_data);
    }
    
    function resetVSeed(string _text)
    external {
        vSeed[msg.sender] =  keccak256(block.number,msg.sender,_text);
    }
    
    
    /*External By Admin Contract*/
    //once they activate they cannot deactivate
    function Activate(string _text) 
    external {
        require(vSeed[msg.sender] == bytes32(0));
        //add to list
        allPlayers.push(msg.sender);
        //set val Seed
        vSeed[msg.sender] = keccak256(block.number,msg.sender,_text);
    }
}
