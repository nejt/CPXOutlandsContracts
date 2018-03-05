pragma solidity 0.4.20;

import "./Administered.sol";
import "./CosmicPowerToken.sol";
import "./BaseStats-0.1.0.sol";

contract CPXDistributor is Administered {
    //supporting contract
    BaseStats internal CB;
    //CPX Token contract
    CosmicPowerToken internal CPX;
    
    /* Value Mapping */
    //planes id to the max CPX they can claim per day
    mapping (bytes32 => uint256) private planeValue;
    //players to last time they claimed
    mapping (address => uint256) private lastClaim;
    
    /* Constants */
    //total values set by admins
    //total CPX that can be claimed
    uint256 public totalPerDay = 100 * 1e6;
    //sum of the total current plane value
    uint256 public totalPlaneValue = 100 * 1e6;
    
    /* Constructor */
    
    function () payable public {}
    
    function CPXDistributor() public {}
    
    /* View functions */
    
    //send back the time of the user's last claim
    function getLastClaim() view public returns(uint256) {
        return(lastClaim[msg.sender]);
    }
    
    //claim CPX - value standards of planes and bases are 1e6
    function claimCPX(bytes32 _planeID, uint256 _baseID) public returns(uint){
        uint256 _pV = planeValue[_planeID]; 
        //no 0 value planes allowed
        require(_pV > 0);
        //only the owner can call
        require(msg.sender == CB.ownerOf(_baseID));
        //only call after 180 blocks ~ 1 hour
        require(block.number-lastClaim[msg.sender] >= 180);
        //rank of base and bases on planes is unitary
        //modified to CPX 1e6 standard
        uint256 _rank = CB.rank(_baseID) * 1e6;
        //total base rank
        uint256 totalR = CB.planeTotalRank(_planeID) * 1e6;
        uint256 val = 0;
        //check if over or under
        if(totalR < _pV){
            val = _rank * totalPerDay / totalPlaneValue;
        }
        else {
            uint _rv = _rank * _pV / totalR;
            val = _rv * totalPerDay / totalPlaneValue;
        }
        //set claim date
        lastClaim[msg.sender] = block.number;
        //now give CPX
        //look for local tokens first
        if(CPX.balanceOf(address(this)) > val) {
          CPX.transfer(msg.sender,val);
        }
        else {
          //otherwise mint
          //maxe sure we are under the CPX Cap 
          if(CPX.totalSupply() < 21000000 * 1e6) {
            CPX.mint(msg.sender, val);
          }  
        }
    }
    
    /* Admin Functions */
    
    function setPlaneValue (bytes32 _planeID, uint256 _value)
    public onlyAdmin {
      planeValue[_planeID] = _value;
    }
    
    function adminSetConstants (uint256 _tPerDay, uint256 _tPlaneVal) public onlyAdmin {
        totalPerDay = _tPerDay;
        totalPlaneValue = _tPlaneVal;
    }
    
    function setRefContracts (address _B, address _T) 
    public onlyAdmin {
      CB = BaseStats(_B);
      _T = CosmicPowerToken(_T);
    }
    
}