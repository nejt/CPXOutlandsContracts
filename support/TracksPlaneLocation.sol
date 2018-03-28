pragma solidity ^0.4.18;

contract TracksPlaneLocation {
    /* Handle Locations */
    
    // Mapping from Plane to Item 
    mapping (uint256 => uint256[]) internal planeItems;
    
    // Mapping from deed ID to plane
    mapping (uint256 => uint256) internal itemPlane;
    
    function TracksPlaneLocation() public {}
    
    
    /* Information Functions */
    function planeOf(uint256 _itemID)
    external view returns (uint256 _planeID) {
      _planeID = itemPlane[_itemID];
    }
    
    function countOfItemsByPlane(uint256 _planeID)
    external view returns (uint256 _n) {
        _n = planeItems[_planeID].length;
    }
    
    function itemsOnPlane(uint256 _planeID)
    external view returns (uint256[] _items) {
        _items = planeItems[_planeID];
    }
    
    function itemAtIndex (uint256 _planeID, uint256 _i)
    external view returns (uint256 _item) {
        _item = planeItems[_planeID][_i];
    }
    
    
    /* working functions  */
    
    function addItemToPlane(uint256 _planeID, uint256 _itemID)
    internal {
        planeItems[_planeID].push(_itemID);
        itemPlane[_itemID] = _planeID;
    }
    
    function removeFromPlane(uint256 _planeID, uint256 _i, uint256 _itemID)
    internal {
        require(planeItems[_planeID][_i] == _itemID);
        //set last to index
        uint256 length = planeItems[_planeID].length;
        planeItems[_planeID][_i] = planeItems[_planeID][length-1];
        //now delete last
        planeItems[_planeID].length--;
    }
    
    function moveItem(uint256 _itemID, uint256 _to, uint256 _from, uint256 _fromI) 
    internal {
        //first remove 
        removeFromPlane(_from, _fromI, _itemID);
        //now add to new plane
        addItemToPlane(_to, _itemID);
    }
}