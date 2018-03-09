pragma solidity ^0.4.18;

import "./Administered.sol";

contract PlayerStats is Administered{
    //requires admin contract - as lookup to allow functionality
    address PAC;
    
    /* Activity and core stats*/
    struct Player {
        bool active;
        uint8 utype;
    }
    //map player address to the struct
    mapping (address => Player) public CPXPlayers;
    //list all players
    address[] private allPlayers;
    
    
    /* Handle Locations */
    // Mapping from Plane to Player 
    mapping (uint256 => address[]) private planePlayer;
    
    // Mapping from player to plane
    mapping (address => uint256) private playerPlane;


    /*contract creation*/
    function PlayerStats() public {}
    
    
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
        _active = CPXPlayers[_player].active;
    }
    
    //get the plane of the player
    function planeOf(address _player)
    external view returns (uint256 _planeID) {
        require(CPXPlayers[_player].active);
        require(msg.sender == _player || admins[msg.sender]);
      _planeID = playerPlane[_player];
    }
    //number of players on a plane
    function countOfDeedsByPlane(uint256 _planeID)
    external view returns (uint256 _count) {
        _count = planePlayer[_planeID].length;
    }
    //list of players on a plane
    function playersOnPlane(uint256 _planeID)
    external view onlyAdmin returns (address[] _list) {
        _list = planePlayer[_planeID];
    }
    //list of players at index
    function playerAtIndex(uint256 _planeID, uint256 _i)
    external view onlyAdmin returns (address _player) {
        _player = planePlayer[_planeID][_i];
    }
    
    
    /*Admin Functions*/
    function setRefContract (address _A)
    external onlyOwner {
        PAC = _A;
        //allow it to read sensitive state
        admins[_A] = true;
    }
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    
    /* working functions  */
    
    function addPlayerToPlane(uint256 _planeID, address _player)
    internal {
        planePlayer[_planeID].push(_player);
        playerPlane[_player] = _planeID;
    }
    
    function removeFromPlane(uint256 _planeID, uint256 _i, address _player)
    internal {
        require(planePlayer[_planeID][_i] == _player);
        //set last to index
        uint256 length = planePlayer[_planeID].length;
        planePlayer[_planeID][_i] = planePlayer[_planeID][length-1];
        //now delete last
        planePlayer[_planeID].length--;
    }
    
    /*External By Admin Contract*/
    //once they activate they cannot deactivate
    function setActive(address _player) 
    external {
        require(msg.sender == PAC);
        //add to list
        allPlayers.push(_player);
        //make active
        CPXPlayers[_player].active = true;
    }
    
    function setType(address _player, uint8 _t) 
    external {
        require(msg.sender == PAC);
        //make active
        CPXPlayers[_player].utype = _t;
    }

    function movePlayer(uint256 _planeID, address _player)
    external {
        require(msg.sender == PAC);
        addPlayerToPlane(_planeID,_player);
    }
    //overload to allow movement from a plane to another
    function movePlayer(uint256 _to, address _player, uint256 _from, uint256 _i)
    external {
        require(msg.sender == PAC);
        //remove from old plane - push to new
        removeFromPlane(_from,_i,_player);
        //add to new
        addPlayerToPlane(_to,_player);
    }
}
