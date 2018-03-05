pragma solidity ^0.4.18;

import "./Administered.sol";
import "./CosmicCollection.sol";
import "./BaseStats.sol";

//V0.1.0
contract BaseAdmin is PaysBank, Administered {
        //actual base upgrade mapping to cost
    mapping (uint256 => uint256) public upgradeCost;
    //constants for pricing
    uint[5] public rankCost = [1/10 * 1 ether, 2/10 * 1 ether, 4/10 * 1 ether, 8/10 * 1 ether, 16/10 * 1 ether];

    
    //fallback
    function () public payable {}
    
    function setRankCost(uint[5] _cost)
    external onlyAdmin {
        rankCost = _cost;
    }
    
    function setUpgradeCost(uint256 _id, uint256 _cost)
    external onlyAdmin {
        upgradeCost[_id] = _cost;
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
    
    //basic functionality
    function upgradeRank(uint256 _baseID) 
    public payable {
        //must exist
        require(CB.ownerOf(_baseID) != 0);
        //rank must be less than max rank of 5
        require(baseRank[_baseID] < 5);
        uint _cost = rankCost[baseRank[_baseID]]; 
        //meet cost
        require(msg.value >= _cost);
        //upgrade rank
        baseRank[_baseID]++;
        //get plane
        bytes32 _planeID = deedPlane[_baseID];
        //increase rank on plane
        planeTotalRank[_planeID]++;
    }

}