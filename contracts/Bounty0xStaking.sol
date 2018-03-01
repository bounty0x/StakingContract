pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20.sol';


contract Bounty0xStaking is Ownable {

    using SafeMath for uint256;

    address public Bounty0xToken;
    
    mapping (address => uint) public huntersDeposits;
    mapping (address => uint) public sheriffsDeposits;

    mapping (uint => mapping (address => uint)) public stakedByHunters; // mapping of bounty ids to mapping of staked amounts of bounty token by hunters
    mapping (uint => mapping (address => uint)) public stakedBySheriffs; // mapping of bounty ids to mapping of staked amounts of bounty token by sheriffs

    
    event DepositByHunter(address depositor, uint amount, uint balance); 
    event DepositBySheriff(address depositor, uint amount, uint balance);
    
    event StakeByHunter(uint bountyId, address hunter, uint amount);
    event StakeBySheriff(uint bountyId, address sheriff, uint amount);
    
    event StakeOfHunterRelease(uint bountyId, address from, address to, uint amount);
    event StakeOfSheriffRelease(uint bountyId, address from, address to, uint amount);
    

    function Bounty0xStaking(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
    }
    
    
    function depositAsHunter(uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        huntersDeposits[msg.sender] = SafeMath.add(huntersDeposits[msg.sender], _amount);

        DepositByHunter(msg.sender, _amount, huntersDeposits[msg.sender]);
    }
    
    function depositAsSheriff(uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        sheriffsDeposits[msg.sender] = SafeMath.add(sheriffsDeposits[msg.sender], _amount);

        DepositBySheriff(msg.sender, _amount, sheriffsDeposits[msg.sender]);
    }
    
    
    function stakeAsHunter(uint _bountyId, uint _amount) public {
        require(huntersDeposits[msg.sender] >= _amount);
        huntersDeposits[msg.sender] = SafeMath.sub(huntersDeposits[msg.sender], _amount);
        stakedByHunters[_bountyId][msg.sender] = SafeMath.add(stakedByHunters[_bountyId][msg.sender], _amount);
        
        StakeByHunter(_bountyId, msg.sender, _amount);
    }
    
    function stakeAsSheriff(uint _bountyId, uint _amount) public {
        require(sheriffsDeposits[msg.sender] >= _amount);
        sheriffsDeposits[msg.sender] = SafeMath.sub(sheriffsDeposits[msg.sender], _amount);
        stakedBySheriffs[_bountyId][msg.sender] = SafeMath.add(stakedBySheriffs[_bountyId][msg.sender], _amount);
        
        StakeBySheriff(_bountyId, msg.sender, _amount);
    }


    function releaseHunterStake(uint _bountyId, address _from, address _to, uint _amount) public onlyOwner {
        require(stakedByHunters[_bountyId][_from] >= _amount);

        stakedByHunters[_bountyId][_from] = SafeMath.sub(stakedByHunters[_bountyId][_from], _amount);
        require(ERC20(Bounty0xToken).transfer(_to, _amount));

        StakeOfHunterRelease(_bountyId, _from, _to, _amount);
    }
    
    function releaseSheriffStake(uint _bountyId, address _from, address _to, uint _amount) public onlyOwner {
        require(stakedBySheriffs[_bountyId][_from] >= _amount);

        stakedBySheriffs[_bountyId][_from] = SafeMath.sub(stakedBySheriffs[_bountyId][_from], _amount);
        require(ERC20(Bounty0xToken).transfer(_to, _amount));

        StakeOfSheriffRelease(_bountyId, _from, _to, _amount);
    }

}

