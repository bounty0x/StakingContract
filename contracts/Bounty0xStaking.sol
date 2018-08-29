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
    uint public lockAmount;


    mapping (address => uint) public balances;
    mapping (uint => mapping (address => uint)) public stakes; // mapping of submission ids to mapping of addresses that staked an amount of bounty token
    mapping (address => uint) public huntersLockDateTime;
    mapping (address => uint) public huntersLockAmount;
    
    
    event Deposit(address indexed depositor, uint amount, uint balance);
    event Withdraw(address indexed depositor, uint amount, uint balance);
    event Stake(uint indexed submissionId, address indexed hunter, uint amount, uint balance);
    event StakeReleased(uint indexed submissionId, address indexed from, address indexed to, uint amount);
    event Lock(address indexed hunter, uint amount, uint endDateTime);
    event Unlock(address indexed hunter, uint amount);


    constructor(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
        lockTime = 2 weeks;
        lockAmount = SafeMath.mul(1000, (10 ** 18));
    }
    

    function deposit(uint _amount) external whenNotPaused {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);

        emit Deposit(msg.sender, _amount, balances[msg.sender]);
    }
    
    function withdraw(uint _amount) external whenNotPaused {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        require(ERC20(Bounty0xToken).transfer(msg.sender, _amount));

        emit Withdraw(msg.sender, _amount, balances[msg.sender]);
    }
    
    function lock() external whenNotPaused {
        require(!isValidHunter(msg.sender));
        require(balances[msg.sender] >= lockAmount);
        
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], lockAmount);
        huntersLockAmount[msg.sender] = SafeMath.add(huntersLockAmount[msg.sender], lockAmount);
        huntersLockDateTime[msg.sender] = SafeMath.add(now, lockTime);
        
        emit Lock(msg.sender, lockAmount, huntersLockDateTime[msg.sender]);
    }
    
    function unlock() external whenNotPaused {
        require(!isValidHunter(msg.sender));
        uint amountLocked = huntersLockAmount[msg.sender];
        require(amountLocked != 0);
        
        huntersLockAmount[msg.sender] = SafeMath.sub(huntersLockAmount[msg.sender], amountLocked);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], amountLocked);
        
        emit Unlock(msg.sender, lockAmount);
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


    function releaseStake(uint _submissionId, address _from, address _to, uint _amount) external onlyOwner {
        require(stakes[_submissionId][_from] >= _amount);

        stakes[_submissionId][_from] = SafeMath.sub(stakes[_submissionId][_from], _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);

        emit StakeReleased(_submissionId, _from, _to, _amount);
    }

    function releaseManyStakes(uint[] _submissionIds, address[] _from, address[] _to, uint[] _amounts) external onlyOwner {
        require(_submissionIds.length == _from.length &&
                _submissionIds.length == _to.length &&
                _submissionIds.length == _amounts.length);

        for (uint i = 0; i < _submissionIds.length; i++) {
            require(stakes[_submissionIds[i]][_from[i]] >= _amounts[i]);
            stakes[_submissionIds[i]][_from[i]] = SafeMath.sub(stakes[_submissionIds[i]][_from[i]], _amounts[i]);
            balances[_to[i]] = SafeMath.add(balances[_to[i]], _amounts[i]);

            emit StakeReleased(_submissionIds[i], _from[i], _to[i], _amounts[i]);
        }
    }

    function changeLockTime(uint _periodInSeconds) external onlyOwner {
        lockTime = _periodInSeconds;
    }
    
    function changeLockAmount(uint _bntyAmount) external onlyOwner {
        lockAmount = SafeMath.mul(_bntyAmount, (10 ** 18));
    }


    function isValidHunter(address _user) view public returns (bool) {
        return huntersLockDateTime[_user] >= now;
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

}
