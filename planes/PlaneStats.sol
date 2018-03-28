pragma solidity ^0.4.18;

import "./Ownable.sol";

/*  @dev Contract handles the core stats for a private plane
*/
contract PlaneStats is Ownable{
    /* Personal Plane Data */

    //basic plane privacy open state
    struct PersonalPlane {
        bytes32 name;
        bool pvt;
        bool isClosed;
    }
    //mapping to handle token to data structure 
    mapping (uint256 => PersonalPlane) public personalPlanes;
    // Needed to make all planes discoverable. 
    uint256[] private personalIds;
    
    
    /* Network Plane Data */

    //basic plane privacy open state
    struct NetworkPlane {
        uint16 netid;
        string paddress;
    }
    //mapping to handle token to data structure 
    mapping (uint256 => NetworkPlane) public networkPlanes;
    // Needed to make all planes discoverable. 
    uint256[] private networkPlaneIds;

    /*cooldown for all */
    //plane id to cooldown
    mapping (uint256 => uint256) public cooldown;
    

    /* Contract Creation */

    function PlaneStats () public {}


    /* View Functions */
    function countOfPersonalPlanes() 
    public view returns(uint256) {
        return(personalIds.length);
    }
    
    function allPlaneIDs() 
    public view returns(uint256[] personal, uint256[] network){
        return(personalIds,networkPlaneIds);
    }
    

    /* Owner Functions */
    
    //Creation of plane
    function createPersonalPlane (uint256 _deedID, bytes32 _name)
    external onlyOwner {
        //store deedIds
        personalIds.push(_deedID);
        //create plane - name, not private, not closed, no cooldown wait
        personalPlanes[_deedID] = PersonalPlane(_name,false,false);
    }
    
    //Creation of plane
    function createNetworkPlane (uint256 _deedID, uint16 _netid, string _address)
    external onlyOwner {
        //store deedIds
        networkPlaneIds.push(_deedID);
        //create plane - network id and address
        networkPlanes[_deedID] = NetworkPlane(_netid,_address);
    }
    
    
    /* Individual plane data 
        Set by Maker contract - this contract is purely data
    */
    
    //set cooldown - based on user choices
    function setCooldown (uint256 _deedID, uint256 _cool)
    external onlyOwner {
      cooldown[_deedID] = _cool;
    }
    
    //set private - based on user choices
    function setPrivacy (uint256 _deedID, bool _pvt)
    external onlyOwner {
      personalPlanes[_deedID].pvt = _pvt;
    }
    
    //set closed - based on user choices
    function setClosed (uint256 _deedID, bool _isClosed)
    external onlyOwner {
      personalPlanes[_deedID].isClosed = _isClosed;
    }
    
}