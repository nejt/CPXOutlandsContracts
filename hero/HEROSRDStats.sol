pragma solidity ^0.4.18;

import "./Administered.sol";

contract Token {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
}

contract HeroSRDStats is Administered{
    /*  Events 
        Almost everything is handled by events - DAPP monitors web3 for changes
    */
    event UpdatedSkills (uint256 indexed id, uint8[2][] skills);
    event UpdatedFeats (uint256 indexed id, uint16[] feats);
    event UpdatedClassAbilities (uint256 indexed id, uint8[] classAbilities);
    
    
     /* Handle updates to stats
    Log functions only for reference by Web3 DAPP
    */
    
    function setSkills(uint256 _hero, uint8[2][] skills)
    internal {
        emit UpdatedSkills(_hero, skills);
    }
    
    function setFeats(uint256 _hero, uint16[] feats)
    internal onlyOwner {
        emit UpdatedFeats(_hero, feats);
    }
    
    function setClassAbilities(uint256 _hero, uint8[] classAbilities)
    internal onlyOwner {
        emit UpdatedClassAbilities(_hero, classAbilities);
    }
    
    /* Update Hero Stats - skills, feats, and class abilities
    - For use by DAPP - lookup through Logs
    */
    
    function setHeroStats (address _token, uint256 _hero, uint8[2][] skills, uint16[] feats, uint8[] classAbilities)
    public {
        //require ownership
        require(msg.sender == Token(_token).ownerOf(_hero));
        //check what to update
        //if skills have a length, update
        if(skills.length > 0) setSkills(_hero, skills);
        //if feats have a length update
        if(feats.length > 0) setFeats(_hero, feats);
        //if classAbilities have a length update
        if(classAbilities.length > 0) setClassAbilities(_hero, classAbilities);
    }
}
