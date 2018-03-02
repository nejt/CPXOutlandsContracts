pragma solidity 0.4.20;

contract MultiSigWallet {
    mapping(address => uint8) private _owners;

    uint public threshold;
    uint private _transactionIdx;

    struct Transaction {
      address from;
      address to;
      uint amount;
      uint blockn;
      uint8 signatureCount;
      bool cancelled;
      mapping (address => uint8) signatures;
    }

    mapping (uint => Transaction) private _transactions;

    modifier validOwner() {
        require(_owners[msg.sender] == 1);
        _;
    }

    event LogDepositFunds(address from, uint amount);
    event LogTransactionCreated(address from, address to, uint amount, uint transactionId);
    event LogTransactionCompleted(address from, address to, uint amount, uint transactionId);
    event LogTransactionSigned(address by, uint transactionId);

    function MultiSigWallet(uint _threshold, address[] owners)
        public {
            //minimum 
            threshold = 2;
            require(_threshold > 1 && owners.length < 10);
            //set threshhold and owners 
            threshold = _threshold;
            //loop through owners
            for(uint i = 0; i < owners.length; i++) {
                _owners[owners[i]] = 1;
            }
    }

    function ()
        public
        payable {
        LogDepositFunds(msg.sender, msg.value);
    }
    
    function getTxStatus(uint id) validOwner view public 
        returns(address from, address to, uint amount, uint blockn, bool cancelled, uint8 signatureCount)
    {
        Transaction memory T = _transactions[id];
        return (T.from,T.to,T.amount,T.blockn,T.cancelled,T.signatureCount);
    } 

    function withdraw(uint amount)
        public 
        returns (uint)
        {
        return(transferTo(msg.sender, amount));
    }

    function transferTo(address to, uint amount)
        validOwner
        public 
        returns (uint)
        {
        require(address(this).balance >= amount);
        uint transactionId = _transactionIdx++;

        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.blockn = block.number;
        transaction.cancelled = false;
        transaction.signatureCount = 0;

        _transactions[transactionId] = transaction;

        LogTransactionCreated(msg.sender, to, amount, transactionId);
        //return id
        return(transactionId);
    }

    function signTransaction(uint transactionId)
      validOwner
      public {

      Transaction storage transaction = _transactions[transactionId];

      // Transaction must exist
      require(0x0 != transaction.from);
      //cannot be cancelled
      require(!transaction.cancelled);
      // Creator cannot sign the transaction
      require(msg.sender != transaction.from);
      // Cannot sign a transaction more than once
      require(transaction.signatures[msg.sender] != 1);

      transaction.signatures[msg.sender] = 1;
      transaction.signatureCount++;

      LogTransactionSigned(msg.sender, transactionId);

      if (transaction.signatureCount >= threshold) {
        require(address(this).balance >= transaction.amount);
        transaction.to.transfer(transaction.amount);
        LogTransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
      }
    }
    
    function cancelTransaction(uint transactionId)
      validOwner
      public {
          //cannot cancel something completed
        require(_transactions[transactionId].signatureCount < threshold);  
        _transactions[transactionId].cancelled = true;
      }

    function walletBalance()
      constant
      public
      returns (uint) {
      return address(this).balance;
    }
}

contract MultiSigMaker {
    address private owner;
    address [] public owners;
    uint public threshold;  
    
    event LogNewContract(address mutiSig);
    
    function MultiSigMaker() public {
        owner = msg.sender;
    }
    
    function setOwners(uint n, address[] _owners) public { 
        require(_owners.length <= 10 && n < _owners.length && n != 0);

        owners = _owners;
        threshold = n;
    }
    
    function makeNewMultiSig() public returns(address _c) {
        MultiSigWallet SMS = new MultiSigWallet(threshold, owners);
        _c = address(SMS);
        LogNewContract(SMS);
        //cleares state
        owners.length = 0;
    }
    
    function killContract() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}
