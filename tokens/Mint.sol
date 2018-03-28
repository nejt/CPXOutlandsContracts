pragma solidity ^0.4.20;

import "./Administered.sol";
import "./OwningContract.sol";

contract tokenContract {
    function mint(address tokenOwner, uint tokens) public returns (bool success);
}

contract Mint is Administered, OwningContract {
    
    // When a token is created.
    event LogMint(address indexed _token, address indexed _owner, uint256 amount);
    
    function Mint () public {}
    
    // this contract can be killed - it stores no data
    function killContract(address _CPX, address _XP, address newOwner) 
    external onlyOwner {
        require(_CPX != address(0) && _XP != address(0) && newOwner != address(0));
        //transfer ownership of stats to provided
        transferOCOwnership(_CPX, newOwner);
        transferOCOwnership(_XP, newOwner);
        //destroy
        selfdestruct(owner);
    }
    
    // Control Admins
    // ------------------------------------------------------------------------
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    //Minting Functions
    function mintToken(address Token, address tokenOwner, uint256 amount)
    external onlyAdmin {
        tokenContract(Token).mint(tokenOwner,amount);   
        //log
        emit LogMint(Token,tokenOwner,amount);
    }
}