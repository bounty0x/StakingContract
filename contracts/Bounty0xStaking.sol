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
   
    mapping (address => uint) public Deposits;

    mapping (uint => mapping (address => uint)) public stakedByHunters; // mapping of submission ids to mapping of staked amounts of bounty token by hunters
    mapping (uint => mapping (address => uint)) public stakedBySheriffs; // mapping of submission ids to mapping of staked amounts of bounty token by sheriffs
 
   
    event DepositByHunter(address depositor, uint amount, uint balance);
    event DepositBySheriff(address depositor, uint amount, uint balance);
   
    event StakeByHunter(uint submissionId, address hunter, uint amount);
    event StakeBySheriff(uint submissionId, address sheriff, uint amount);
   
    event StakeOfHunterRelease(uint bountyId, address from, address to, uint amount);
    event StakeOfSheriffRelease(uint bountyId, address from, address to, uint amount);
   
 
    function Bounty0xStaking(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
    }
   
   
    function depositAsHunter(uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        Deposits[msg.sender] = SafeMath.add(Deposits[msg.sender], _amount);
 
        DepositByHunter(msg.sender, _amount, Deposits[msg.sender]);
    }
   
    function depositAsSheriff(uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        Deposits[msg.sender] = SafeMath.add(Deposits[msg.sender], _amount);
 
        DepositBySheriff(msg.sender, _amount, Deposits[msg.sender]);
    }
   
   
    function stakeAsHunter(uint _submissionId, uint _amount) public {
        require(Deposits[msg.sender] >= _amount);
        Deposits[msg.sender] = SafeMath.sub(Deposits[msg.sender], _amount);
        stakedByHunters[_submissionId][msg.sender] = SafeMath.add(stakedByHunters[_submissionId][msg.sender], _amount);
       
        StakeByHunter(_submissionId, msg.sender, _amount);
    }
   
    function stakeAsSheriff(uint _submissionId, uint _amount) public {
        require(Deposits[msg.sender] >= _amount);
        Deposits[msg.sender] = SafeMath.sub(Deposits[msg.sender], _amount);
        stakedBySheriffs[_submissionId][msg.sender] = SafeMath.add(stakedBySheriffs[_submissionId][msg.sender], _amount);
       
        StakeBySheriff(_submissionId, msg.sender, _amount);
    }
 
 
    function releaseHunterStake(uint _submissionId, address _from, address _to, uint _amount) public onlyOwner {
        require(stakedByHunters[_submissionId][_from] >= _amount);
 
        stakedByHunters[_submissionId][_from] = SafeMath.sub(stakedByHunters[_submissionId][_from], _amount);
        Deposits[_to] = SafeMath.add(Deposits[_to], _amount);
 
        StakeOfHunterRelease(_submissionId, _from, _to, _amount);
    }
   
    function releaseSheriffStake(uint _submissionId, address _from, address _to, uint _amount) public onlyOwner {
        require(stakedBySheriffs[_submissionId][_from] >= _amount);
 
        stakedBySheriffs[_submissionId][_from] = SafeMath.sub(stakedBySheriffs[_submissionId][_from], _amount);
        Deposits[_to] = SafeMath.add(Deposits[_to], _amount);
 
        StakeOfSheriffRelease(_submissionId, _from, _to, _amount);
    }
 
    // withdraw function for both hunter and sheriff
    
    function withdrawDeposit (uint _amount) public {
        require(Deposits[msg.sender] >= _amount);
        Deposits[msg.sender] = SafeMath.sub(Deposits[msg.sender], _amount);
        require(ERC20(Bounty0xToken).transfer(msg.sender, _amount));
        
    }

    // release to burn token hunter
    // release to burn token sheriff
 
    // batch function stakeAsHunter for hunter
    // batch function stakeAsSheriff for sheriff
 
    // batch function for releaseHunterStake for owner
    // batch function for releaseSheriffStake for owner
   
}
