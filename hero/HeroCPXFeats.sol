pragma solidity ^0.4.18;

import "./Administered.sol";
import "./PaysBank.sol";

contract CommitReveal {
    bytes32[] public hash;
    function hashIndex () public view returns (uint256 i);
}

contract HeroCPXFeats is Administered, PaysBank {

    //holds feats allowed
    mapping (address => mapping(uint16 => uint8)) internal availableFeats;
    //to get feats - they must commit
    mapping (address => uint256) public playerFeatCommit;
    
    /* Costs */
    uint256 public costToDrawFeats = 1 finney;

    //max element index
    uint8 maxE = 54;
    
    function () payable public {}
    constructor() public {
        //Links - 0 bank, 1 CommitReveal
        CLinks = [
            0x16e39D98A3f25B39eBdA681ECaE94418E1d20De2,
            0x50FFe2d12b6e4441ac68CbA6373f8f8D2400f2F9
            ];
    }
    
    
    /* Events */
    event FeatsGiven (address indexed player, uint16[] feats);
    

    /* Admin functions 
        Granting upgrades and available feats
    */
    //grant an array of feats to an owner
    function grantAvailableFeats(address player, uint16[] feats) 
    public onlyAdmin {
        for(uint8 i = 0; i< feats.length; i++) availableFeats[player][feats[i]]++;
        
        emit FeatsGiven(player, feats);
    }
    
    //remove a set of feats from a player
    function reduceFeats (address player, uint16[] feats) 
    public onlyAdmin {
        for(uint8 i = 0; i< feats.length; i++) availableFeats[player][feats[i]]--;
    }
    
    //set constants
    function setConstants(uint[2] c) 
    public onlyAdmin {
        if(c[0] != 0) costToDrawFeats = c[0];
        if(c[1] != 0) maxE = uint8(c[1]);
    }
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    
    /* Views */
    function countOfFeatsAvailable(address player, uint16 feat) 
    public view returns(uint8 count){
        count = availableFeats[player][feat];
    }
    
    /* Public functions */
    
    /*Feats
        Player commit
    */ 
    function commitToDrawFeats()
    public payable {
        //there is a cost
        require(msg.value >= costToDrawFeats);
        //set commit
        playerFeatCommit[msg.sender] = CommitReveal(CLinks[1]).hashIndex();
    }
    
    //draw feats - only if commit is less than the Commit Reveal
    function drawFeats()
    public returns (uint16[] given){
        //shows that they have committed
        require(playerFeatCommit[msg.sender] != 0);
        //make sure that they use a hash that they could not predict
        require(playerFeatCommit[msg.sender] < CommitReveal(CLinks[1]).hashIndex());
        //remove commit
        playerFeatCommit[msg.sender] = 0;
        //do the draw
        //calculate hash
        bytes32 hash = keccak256(address(this), CommitReveal(CLinks[1]).hash(playerFeatCommit[msg.sender]), msg.sender);
        given = new uint16[](15);
        uint16 s;

        for(uint8 i = 0; i < 15; i++){
            //all feats are skill * 100 + element - approaches are always 0-5
            s = uint8(hash[2*i]) % 12;
            //for approach feats it is 10 * skill + approach
            given[i] = (100*s) + (uint8(hash[(2*i)+1]) % maxE);
            //now grant feat
            availableFeats[msg.sender][given[i]]++;
        }
        
        emit FeatsGiven(msg.sender, given);
    }
}
