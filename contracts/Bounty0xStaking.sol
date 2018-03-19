pragma solidity ^0.4.18;
 
 
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
 
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
 
 
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
 
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }
 
 
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
 
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
 
}
 
 
 
 
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
 
 
 
 
 
 
 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
 
contract Bounty0xStaking is Ownable {
 
    using SafeMath for uint256;
 
    address public Bounty0xToken;
   
    mapping (address => uint) public balances;

    mapping (uint => mapping (address => uint)) public stakedByHunters; // mapping of submission ids to mapping of staked amounts of bounty token by hunters
    mapping (uint => mapping (address => uint)) public stakedBySheriffs; // mapping of submission ids to mapping of staked amounts of bounty token by sheriffs

    
    event Deposit(address depositor, uint amount, uint balance); 
    event Withdraw(address depositor, uint amount, uint balance);
    
    event StakeByHunter(uint submissionId, address hunter, uint amount);
    event StakeBySheriff(uint submissionId, address sheriff, uint amount);
    
    event StakeOfHunterRelease(uint bountyId, address from, address to, uint amount);
    event StakeOfSheriffRelease(uint bountyId, address from, address to, uint amount);
    

    function Bounty0xStaking(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
    }
    
    
    function deposit(uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);

        emit Deposit(msg.sender, _amount, balances[msg.sender]);
    }
    
    
    function stakeAsHunter(uint _submissionId, uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        stakedByHunters[_submissionId][msg.sender] = SafeMath.add(stakedByHunters[_submissionId][msg.sender], _amount);
        
        emit StakeByHunter(_submissionId, msg.sender, _amount);
    }
    
    function stakeAsSheriff(uint _submissionId, uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        stakedBySheriffs[_submissionId][msg.sender] = SafeMath.add(stakedBySheriffs[_submissionId][msg.sender], _amount);
        
        emit StakeBySheriff(_submissionId, msg.sender, _amount);
    }


    function releaseHunterStake(uint _submissionId, address _from, address _to, uint _amount) public onlyOwner {
        require(stakedByHunters[_submissionId][_from] >= _amount);

        stakedByHunters[_submissionId][_from] = SafeMath.sub(stakedByHunters[_submissionId][_from], _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);

        emit StakeOfHunterRelease(_submissionId, _from, _to, _amount);
    }
    
    function releaseSheriffStake(uint _submissionId, address _from, address _to, uint _amount) public onlyOwner {
        require(stakedBySheriffs[_submissionId][_from] >= _amount);

        stakedBySheriffs[_submissionId][_from] = SafeMath.sub(stakedBySheriffs[_submissionId][_from], _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);

        emit StakeOfSheriffRelease(_submissionId, _from, _to, _amount);
    }

    function withdrawDeposit (uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        require(ERC20(Bounty0xToken).transfer(msg.sender, _amount));
        Withdraw(msg.sender, _amount, balances[msg.sender]);
        
    }
    
    // release to burn token hunter
    // release to burn token sheriff

    function stakeToManyAsHunter(uint[] _submissionIds, uint[] _amounts) public {
        uint totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);
       
        for (uint i = 0; i < _submissionIds.length; i++) {
            stakedByHunters[_submissionIds[i]][msg.sender] = SafeMath.add(stakedByHunters[_submissionIds[i]][msg.sender], _amounts[i]);
            
            emit StakeByHunter(_submissionIds[i], msg.sender, _amounts[i]);
        }
    }
    
    function stakeToManyAsSheriff(uint[] _submissionIds, uint[] _amounts) public {
        uint totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);
       
        for (uint i = 0; i < _submissionIds.length; i++) {
            stakedBySheriffs[_submissionIds[i]][msg.sender] = SafeMath.add(stakedBySheriffs[_submissionIds[i]][msg.sender], _amounts[i]);
            
            emit StakeBySheriff(_submissionIds[i], msg.sender, _amounts[i]);
        }
    }
    

    function releaseManyHunterStakes(uint[] _submissionIds, address[] _from, address[] _to, uint[] _amounts) public onlyOwner {
        require(_submissionIds.length == _from.length &&
                _submissionIds.length == _to.length && 
                _submissionIds.length == _amounts.length);
        
        for (uint i = 0; i < _submissionIds.length; i++) {
            require(stakedByHunters[_submissionIds[i]][_from[i]] >= _amounts[i]);
            stakedByHunters[_submissionIds[i]][_from[i]] = SafeMath.sub(stakedByHunters[_submissionIds[i]][_from[i]], _amounts[i]);
            balances[_to[i]] = SafeMath.add(balances[_to[i]], _amounts[i]);
            
            emit StakeOfHunterRelease(_submissionIds[i], _from[i], _to[i], _amounts[i]);
        }
    }
    
    function releaseManySheriffStakes(uint[] _submissionIds, address[] _from, address[] _to, uint[] _amounts) public onlyOwner {
        require(_submissionIds.length == _from.length &&
                _submissionIds.length == _to.length && 
                _submissionIds.length == _amounts.length);
        
        for (uint i = 0; i < _submissionIds.length; i++) {
            require(stakedBySheriffs[_submissionIds[i]][_from[i]] >= _amounts[i]);
            stakedBySheriffs[_submissionIds[i]][_from[i]] = SafeMath.sub(stakedBySheriffs[_submissionIds[i]][_from[i]], _amounts[i]);
            balances[_to[i]] = SafeMath.add(balances[_to[i]], _amounts[i]);
            
            emit StakeOfSheriffRelease(_submissionIds[i], _from[i], _to[i], _amounts[i]);
        }
    }

   
}
