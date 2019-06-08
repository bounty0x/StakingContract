pragma solidity ^0.4.21;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/lifecycle/Pausable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';


contract BntyControllerInterface {
    function destroyTokensInBntyTokenContract(address _owner, uint _amount) public returns (bool);
}




contract Bounty0xStaking is Ownable, Pausable {

    using SafeMath for uint256;

    address public Bounty0xToken;
    uint public lockTime;
    uint public unlockTime;

    mapping (address => uint) public balances;
    mapping (uint => mapping (address => uint)) public stakes; // mapping of submission ids to mapping of addresses that staked an amount of bounty token
    mapping (address => uint) public huntersLockTime;
    mapping (address => uint) public huntersLockAmount;
    
    
    event Deposit(address indexed depositor, uint amount, uint balance);
    event Withdraw(address indexed depositor, uint amount, uint balance);
    event Stake(uint indexed submissionId, address indexed hunter, uint amount, uint balance);
    event StakeReleased(uint indexed submissionId, address indexed from, address indexed to, uint amount);
    event Lock(address indexed hunter, uint amount, uint endDateTime);
    event Unlock(address indexed hunter, uint amount);


    constructor(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
        lockTime = 30 days;
        unlockTime = 1 days;
    }
    

    function deposit(uint _amount) external whenNotPaused {
        require(_amount != 0);
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);

        emit Deposit(msg.sender, _amount, balances[msg.sender]);
    }
    
    function withdraw(uint _amount) external whenNotPaused {
        require(_amount != 0);
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        require(ERC20(Bounty0xToken).transfer(msg.sender, _amount));

        emit Withdraw(msg.sender, _amount, balances[msg.sender]);
    }
    
    
    function lock(uint _amount) external whenNotPaused {
        require(_amount != 0);
        require(balances[msg.sender] >= _amount);
        
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        huntersLockAmount[msg.sender] = SafeMath.add(huntersLockAmount[msg.sender], _amount);
        huntersLockTime[msg.sender] = now;
        
        emit Lock(msg.sender, huntersLockAmount[msg.sender], huntersLockTime[msg.sender]);
    }
    
    function depositAndLock(uint _amount) external whenNotPaused {
        require(_amount != 0);
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        
        huntersLockAmount[msg.sender] = SafeMath.add(huntersLockAmount[msg.sender], _amount);
        huntersLockTime[msg.sender] = now;
        
        emit Lock(msg.sender, huntersLockAmount[msg.sender], huntersLockTime[msg.sender]);
    }
    
    function unlock() external whenNotPaused {
        require(secondsUntilUnlock(msg.sender) == 0);
        uint amountLocked = huntersLockAmount[msg.sender];
        
        huntersLockAmount[msg.sender] = SafeMath.sub(huntersLockAmount[msg.sender], amountLocked);
        huntersLockTime[msg.sender] = 0;
        balances[msg.sender] = SafeMath.add(balances[msg.sender], amountLocked);
        
        emit Unlock(msg.sender, amountLocked);
    }
    
    function unlockAndWithdraw() external whenNotPaused {
        require(secondsUntilUnlock(msg.sender) == 0);
        uint amountLocked = huntersLockAmount[msg.sender];
        
        huntersLockAmount[msg.sender] = SafeMath.sub(huntersLockAmount[msg.sender], amountLocked);
        huntersLockTime[msg.sender] = 0;
        require(ERC20(Bounty0xToken).transfer(msg.sender, amountLocked));
        
        emit Unlock(msg.sender, amountLocked);
        emit Withdraw(msg.sender, amountLocked, balances[msg.sender]);
    }
        
    
    function secondsUntilUnlock(address _hunter) public view whenNotPaused returns (uint) {
        if (SafeMath.add(huntersLockTime[_hunter], lockTime) <= now) {
            uint timeLocked = SafeMath.sub(now, huntersLockTime[_hunter]);
            uint residual = SafeMath.add(timeLocked, unlockTime) % SafeMath.add(lockTime, unlockTime);
            if (residual <= unlockTime) {
                return 0;
            } else {
                uint timeLeft = SafeMath.sub(lockTime, SafeMath.sub(residual, unlockTime));
                return timeLeft;
            }
        } else {
            timeLocked = SafeMath.sub(now, huntersLockTime[_hunter]);
            timeLeft = SafeMath.sub(lockTime, timeLocked);
            return timeLeft;
        }
    }
    

    function stake(uint _submissionId, uint _amount) external whenNotPaused {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        stakes[_submissionId][msg.sender] = SafeMath.add(stakes[_submissionId][msg.sender], _amount);

        emit Stake(_submissionId, msg.sender, _amount, balances[msg.sender]);
    }

    function stakeToMany(uint[] _submissionIds, uint[] _amounts) external whenNotPaused {
        uint totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);

        for (uint i = 0; i < _submissionIds.length; i++) {
            stakes[_submissionIds[i]][msg.sender] = SafeMath.add(stakes[_submissionIds[i]][msg.sender], _amounts[i]);

            emit Stake(_submissionIds[i], msg.sender, _amounts[i], balances[msg.sender]);
        }
    }


    function releaseStake(uint _submissionId, address _from, address _to) external onlyOwner {
        require(stakes[_submissionId][_from] != 0);

        balances[_to] = SafeMath.add(balances[_to], stakes[_submissionId][_from]);
        emit StakeReleased(_submissionId, _from, _to, stakes[_submissionId][_from]);
        
        stakes[_submissionId][_from] = 0;
    }

    function releaseManyStakes(uint[] _submissionIds, address[] _from, address[] _to) external onlyOwner {
        require(_submissionIds.length == _from.length &&
                _submissionIds.length == _to.length);

        for (uint i = 0; i < _submissionIds.length; i++) {
            require(_from[i] != address(0));
            require(_to[i] != address(0));
            require(stakes[_submissionIds[i]][_from[i]] != 0);
            
            balances[_to[i]] = SafeMath.add(balances[_to[i]], stakes[_submissionIds[i]][_from[i]]);
            emit StakeReleased(_submissionIds[i], _from[i], _to[i], stakes[_submissionIds[i]][_from[i]]);
            
            stakes[_submissionIds[i]][_from[i]] = 0;
        }
    }
    

    function changeLockTime(uint _periodInSeconds) external onlyOwner {
        require(_periodInSeconds != 0);
        lockTime = _periodInSeconds;
    }
    
    function changeUnlockTime(uint _periodInSeconds) external onlyOwner {
        require(_periodInSeconds != 0);
        unlockTime = _periodInSeconds;
    }
    
    
    // Burnable mechanism

    address public bntyController;

    event Burn(uint indexed submissionId, address indexed from, uint amount);

    function changeBntyController(address _bntyController) external onlyOwner {
        bntyController = _bntyController;
    }


    function burnStake(uint _submissionId, address _from) external onlyOwner {
        require(stakes[_submissionId][_from] > 0);

        uint amountToBurn = stakes[_submissionId][_from];
        stakes[_submissionId][_from] = 0;

        require(BntyControllerInterface(bntyController).destroyTokensInBntyTokenContract(this, amountToBurn));
        emit Burn(_submissionId, _from, amountToBurn);
    }


    // in case of emergency
    function emergentWithdraw() external onlyOwner {
        require(ERC20(Bounty0xToken).transfer(msg.sender, address(this).balance));
    }
    
}
