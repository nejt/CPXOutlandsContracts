pragma solidity 0.4.20;

import "./Administered.sol";

//only admins can create planes linked to other networks
//keep it simple - only create and destroy, no other functionality
contract CPXPlanes is Administered{
    struct Plane {
        string id;
        uint8 net;
    }
    //mapping uint to Plane
    mapping (uint => Plane) public planes;
    //index to keep track of the number of planes
    uint _planeIndex;

    //revert all payments
    function () public payable {
        revert();
    }

    function CPXPlanes() public { }
    
    //Logs
    event LogCreate(uint8 indexed _net,string id);
    event LogDestroy(uint8 indexed _net,string id);
    
    //get the current number
    function nPlanes() view public returns (uint) {
        return(_planeIndex);
    }
    
    function createPlane(uint8 _network, string _addr) public onlyAdmin {
        //log
        LogCreate(_network,_addr);
        //add to mapping
        planes[_planeIndex] = Plane(_addr,_network);
        //increment index
        _planeIndex++;
    }
    
    //destroy the planbe by deleting it
    function destroyPlane(uint _i) public onlyAdmin {
        //log
        LogDestroy(planes[_i].net,planes[_i].id);    
        //delete from mapping
        delete planes[_i];
    }
}
