pragma solidity ^0.4.18;

import "./CosmicCollection.sol";
import "./PaysBank.sol";

contract AdminContract {
    mapping (address => bool) public admins;
}

contract ChallengeCPX is PaysBank {
    struct Challenge {
        address benefactor;
        uint256 createdOn;
        uint256 plane;
        uint8 DC;
        uint8[] skills;
        uint8[] elements;
        bytes32 key;
        bool finalized;
    }
    
    //Contain all challenges
    mapping (uint256 => Challenge) internal challenges;
    uint256[] internal openChallenges;
    //track the number of challenges on a plane
    mapping (uint256 => uint8) public countOfChallengesOnAPlane;
    //Track IDs
    uint256 internal challengeID;
    
    
    /* Costs */
    uint256 public createChallengeCost = 2 * 1 finney;
    
    constructor() public {
        //Links - 0 Bank, 1 Colectable
        CLinks = [0x16e39D98A3f25B39eBdA681ECaE94418E1d20De2,0x572403E42F7d787f3EA38eeCCCe7699c02e95f55];
    }
    
    /* Views */
    
    function getAllOpenChallenges ()
    public view returns(uint256[] all) {
        all = openChallenges;
    }
    
    function isOpen (uint256 id) 
    public view returns(bool open) {
        open = challenges[id].key == bytes32(0);
    }
    
    function getBenefactor (uint256 id)
    public view returns(address benefactor) {
        benefactor = challenges[id].benefactor;
    }
    
    function getPlane (uint256 id)
    public view returns(uint256 plane) {
        plane = challenges[id].plane;
    }
    
    function getDC (uint256 id)
    public view returns(uint8 DC) {
        DC = challenges[id].DC;
    }
    
    function getSkills (uint256 id)
    public view returns(uint8[] skills) {
        skills = challenges[id].skills;
    }
    
    function getChallengeData (uint256 id) 
    public view returns(uint256 plane, uint256 createdOn, bool finalized, uint8 DC, uint8[] skills, uint8[] elements, bytes32 key) {
        plane = challenges[id].plane;
        createdOn = challenges[id].createdOn;
        finalized = challenges[id].finalized;
        DC = challenges[id].DC;
        skills = challenges[id].skills;
        elements = challenges[id].elements;
        key = challenges[id].key;
    }
    
    function getResolveData (uint256 id) 
    public view returns(bool finalized, uint8 DC, uint8[] skills, uint8[] elements, bytes32 key) {
        finalized = challenges[id].finalized;
        DC = challenges[id].DC;
        skills = challenges[id].skills;
        elements = challenges[id].elements;
        key = challenges[id].key;
    }
    
    /*Admin */
    function setConstants (uint256 cost) 
    public {
        require(AdminContract(owner).admins(msg.sender));
        if(cost != 0) createChallengeCost = cost;
    }
    
    
    /* Functions to be called by admin contract */
    //Links - 0 Bank, 1 Collectable
    
    //Skill[2] - primary and total number, plane id - must be the owner, difficulty - only if admin 
    function createChallenge (uint8[2] skills, uint256 plane, uint8 DC) 
    public payable {
        //validate skill and plane
        require(skills[0] < 12 && skills[1] < 22 && CosmicCollectionTokens(CLinks[1]).typeOf(plane) == 0);
        //max of 5 challenges
        require(countOfChallengesOnAPlane[plane]+1 < 6);
        
        //set benefactor
        address benefactor = msg.sender;
        
        // check if admin - set benefactor to bank
        // else require payment
        if(AdminContract(owner).admins(msg.sender)) benefactor = CLinks[0];
        else {
            //cost = cost * number of skills 
            require(msg.value >= skills[1] * createChallengeCost);
            require(msg.sender == CosmicCollectionTokens(CLinks[1]).ownerOf(plane));
            //set DC
            bytes32 hash = keccak256(address(this),blockhash(block.number-1),msg.sender);
            //take the lowest of 2
            uint8 low = uint8(hash[3])%30 < uint8(hash[7])%30 ? uint8(hash[3])%30 : uint8(hash[7])%30;
            DC = 4 + low + uint8(hash[9]) % 30 + uint8(hash[21]) % 30 + uint8(hash[27]) % 30;
        }
        
        //increase count on plane 
        countOfChallengesOnAPlane[plane]++;
        
        //set data
        challenges[challengeID].createdOn = now;
        challenges[challengeID].benefactor = benefactor;
        challenges[challengeID].DC = DC;
        challenges[challengeID].skills = skills;
        challenges[challengeID].plane = plane;
        //push to open
        openChallenges.push(challengeID);
        //increase id
        challengeID++;
    }

    //sets the key for the challenge and locks it
    //no more commits 
    function setKey(uint256 id, uint8[] skills, uint8[] elements, string _key)
    public {
        //require admin 
        //Created by player - they get benefit, but set by admin for control of skills and elements
        require(AdminContract(owner).admins(msg.sender));
        
        //check number of skills
        require(skills.length == challenges[id].skills[1]);
        
        //create key
        bytes32 key = keccak256(address(this),now,id,_key);
        //set skills, elements, rewards, key
        challenges[id].skills = skills;
        challenges[id].elements = elements;
        challenges[id].key = key;
    }
    
    //finalize the challenge - no more resolution - declares winner
    //id of challenge, and index to remove
    function finalizeChallenge(uint256 id, uint256 i)
    public onlyOwner {
        //cannot be finalized
        require(!challenges[id].finalized);
        challenges[id].finalized = true;
        //reduce count on plane
        countOfChallengesOnAPlane[challenges[id].plane]--;
        //get length
        uint256 l = openChallenges.length;
        //move last to index
        openChallenges[i] = openChallenges[l-1];
        //delete last
        openChallenges.length--;
    }
}
