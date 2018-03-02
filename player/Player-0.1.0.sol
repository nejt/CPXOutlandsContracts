pragma solidity 0.4.20;

import "./Administered.sol";

contract CPXPlayer is administered {
    //core player data
    struct Player {
        uint[3] xp;
        bytes8 faction;
        bytes8[] knownUnits;
    }
    //mapping to hold all players
    mapping (address => Player) internal players;
    
    //creator function
    function CPXPlayer() public {}
    
    //get knownUnits
    function getKnownUnit(address _player, uint8 _i) view public returns(bytes8 unitid) {
        //only player or admin
        require(msg.sender == _player || admins[msg.sender]);
        unitid = players[_player].knownUnits[_i];
    }
    
    //get information
    function getPlayerData(address _player) view public returns(uint[3] stats, bytes8 faction, bytes8[] knownUnits) {
        //initialize to 0
        stats = [uint(0),0,0];
        //let them know the faction
        faction = players[_player].faction;
        
        //if they are the player or an admin - let them know the stats
        if(msg.sender == _player || admins[msg.sender]){
            stats = players[_player].xp;
            knownUnits = players[_player].knownUnits;
        }
    }
    
    //set the faction, the only one the player can set
    function setFaction (bytes8 _faction) public {
        //require that the faction isn't set
        require(players[msg.sender].faction == 0);
        //otherwise - set the faction
        players[msg.sender].faction = _faction;
    }
    
    //admins can give xp
    function adminGiveXP (address _player, uint8 _i, uint _xp) public onlyAdmin {
        // increase the xp of the stat by the given xp
        players[_player].xp[_i] += _xp;
    }
    
    //admin gives a unit template to player
    function adminAddKnownUnit (address _player, bytes8 _unitid) public onlyAdmin {
        players[_player].knownUnits.push(_unitid);
    }
    }
