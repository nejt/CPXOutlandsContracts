pragma solidity ^0.4.18;

import "./Base-0.2.0.sol";
import "./Unit-0.2.0.sol";
import "./Distributes.sol";
import "./Administered.sol";

contract BaseUpgrades is PaysBank, Administered {
    //connection to bases
    CPXBases CB; 
    //actual base upgrade mapping to cost
    mapping (uint256 => uint256) public upgradeCost;
    
    //rank
    mapping (uint256 => uint8) public rank;
    //BaseUpgrades array
    mapping (uint256 => uint256[]) private upgrades;

    //constants for pricing
    uint[5] public rankCost = [1/10 * 1 ether, 2/10 * 1 ether, 4/10 * 1 ether, 8/10 * 1 ether, 16/10 * 1 ether];
    
    //fallback
    function () public payable {}
    //creation
    function BaseUpgrades() public {}
    
    /* admin functions */
    
    //contract admin has to set base contract
    function setBaseContract(address _c)
    external onlyAdmin {
        CB = CPXBases(_c);
    }
    
    function setRankCost(uint[5] _cost)
    external onlyAdmin {
        rankCost = _cost;
    }
    
    function setUpgradeCost(uint256 _id, uint256 _cost)
    external onlyAdmin {
        upgradeCost[_id] = _cost;
    }
    
    /* player functions */
    
    //base owner and admins can see upgrades
    function getBaseUpgrades(uint256 _id)
    view public returns(uint256[]) {
        require(msg.sender == CB.ownerOf(_id) || admins[msg.sender]);
        //if pass then give list
        return(upgrades[_id]);
    }
    
    //basic functionality
    function upgradeRank(uint256 _id) 
    public payable {
        //must exist
        require(CB.ownerOf(_id) != 0);
        //rank must be less than max rank of 5
        require(rank[_id] < 5);
        uint _cost = rankCost[rank[_id]]; 
        //meet cost
        require(msg.value >= _cost);
        //upgrade rank
        rank[_id]++;
    }
    
    function buyBaseUpgrade(uint256 _baseID, uint256 _upgradeID)
    public payable {
        //must exist
        require(CB.ownerOf(_baseID) != 0 && upgradeCost[_upgradeID] != 0);
        uint _cost = upgradeCost[_upgradeID]; 
        //meet cost
        require(msg.value >= _cost);
        //push upgrades
        upgrades[_baseID].push(_upgradeID);
    }
}

contract BaseMaker is PaysBank, Administered {
    //connection to bases
    CPXBases CB; 

    //constants for pricing
    uint256 public creationCost = 1/10 * 1 ether;
    
    //fallback
    function () public payable {}
    //creation
    function BaseMaker() public {}
    
    /* admin functions */
    
    //contract admin has to set base contract
    function setBaseContract(address _c)
    external onlyAdmin {
        CB = CPXBases(_c);
    }
    
    function setCreationCost(uint256 _cost)
    external onlyAdmin {
        creationCost = _cost;
    }
    
    /* player functions */
    function createBase(uint256 _uintID) 
    public payable {}
}