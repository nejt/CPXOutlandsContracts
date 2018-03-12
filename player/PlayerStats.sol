pragma solidity ^0.4.18;

import "./Administered.sol";

contract PlayerStats is Administered{
    //requires admin contract - as lookup to allow functionality
    address PAC;
    
    /* Activity and core stats*/
    struct Player {
        uint256 createdOn;
        uint8 cClass;
        uint256 nKO;
        uint256 cooldown;
    }
    //map player address to the struct - for public view
    mapping (address => Player) public CPXPlayers;
    //mapping for the validationSeed - private use - player only
    mapping (address => bytes32) private vSeed;
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
        _active = CPXPlayers[_player].createdOn > 0 ? true : false;
    }
    
    //get the plane of the player
    function planeOf(address _player)
    external view returns (uint256 _planeID) {
        require(CPXPlayers[_player].createdOn > 0 );
        require(msg.sender == _player || admins[msg.sender]);
      _planeID = playerPlane[_player];
    }
    //number of players on a plane
    function countOfPlayersByPlane(uint256 _planeID)
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
    //easy cooldown reference
    function getCooldown(address _player)
    external view returns (uint256 _cool) {
        _cool = CPXPlayers[_player].cooldown;
    }
    //easy nKO ref
    function getKO(address _player)
    external view returns (uint256 _nKO) {
        _nKO = CPXPlayers[_player].nKO;
    }
    //easy Class ref
    function getClass(address _player)
    external view returns (uint8 _class) {
        _class = CPXPlayers[_player].cClass;
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
    
    
    /*External For PLayer use */
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
    function Activate(address _player, string _text) 
    external {
        require(msg.sender == PAC);
        //add to list
        allPlayers.push(_player);
        //create player
        CPXPlayers[_player] = Player(now,0,0,0);
        //set val Seed
        vSeed[_player] = keccak256(block.number,_player,_text);
    }
    
    //increase KO
    function KO(address _player, uint256 _nullP, uint256 _i) 
    external {
        require(msg.sender == PAC);
        //increase KOP
        CPXPlayers[_player].nKO++;
        //set cooldown - time 1 Hour per KO
        uint256 _cool = now + (CPXPlayers[_player].nKO * 1 hours);
        CPXPlayers[_player].cooldown = _cool;
        //move player to null plane
        removeFromPlane(playerPlane[_player], _i, _player);
        addPlayerToPlane(_nullP, _player);
    }
    
    //set cooldown
    function setCooldown(address _player, uint256 _cool) 
    external {
        require(msg.sender == PAC);
        //make active
        CPXPlayers[_player].cooldown = _cool;
    }
    
    function setClass(address _player, uint8 _c) 
    external {
        require(msg.sender == PAC);
        //make active
        CPXPlayers[_player].cClass = _c;
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
