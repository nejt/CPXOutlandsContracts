pragma solidity 0.4.20;

import './Ownable.sol';
import './PullPayment.sol';

contract PullToBank is Ownable, PullPayment {
    //sets up bank and distributor
    address internal bank;

    function PullToBank() public {}
    
    function setBankContract(address _bank) 
    external onlyOwner {
        bank = _bank;
    }
    //withdraw
    // The owner can only withdraw what has not been assigned to plane owners as PullPayments.
    function withdrawToBank()
    external onlyOwner {
        //withdraw bank account
        uint256 payment = payments[bank];
        require(payment != 0);
        require(this.balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[bank] = 0;

        assert(bank.send(payment));
        // The contract's balance MUST stay backing the outstanding withdrawals. Only the surplus not needed for any backing can be withdrawn by the owner.
        uint256 surplus = this.balance.sub(totalPayments);
        if (surplus > 0) {
            bank.transfer(surplus);
        }
    }
}

contract PaysBank is Ownable{
    //sets up bank and distributor
    address internal bank;

    event LogWithdraw (address bank, uint256 amount);

    function PaysBank() public {}
    
    function setBankContract(address _bank) 
    public onlyOwner {
        bank = _bank;
    }
    //withdraw
    function withdraw() 
    public onlyOwner {
        //bank contract has to be set
        require(bank != address(0));
        LogWithdraw(bank,this.balance);
        bank.transfer(this.balance);
    }
}

contract Distributes is PaysBank {
    //sets up distributor
    address internal distributor;
    //constant 
    uint8 internal distributePercent = 75;
    
    function Distributes() public {}
    
    function setDisributePercent(uint8 _P)
    public onlyOwner {
        distributePercent = _P;
    }

    function setBankContract(address _bank, address _distributor) 
    public onlyOwner {
        bank = _bank;
        distributor = _distributor;
    }
    //withdraw to bank and distributor
    function withdraw() 
    public onlyOwner {
        uint d = this.balance * distributePercent / 100;
        //check if 0
        if(d != 0) distributor.transfer(d);
        //transfer remainder
        bank.transfer(this.balance);
    }
}

