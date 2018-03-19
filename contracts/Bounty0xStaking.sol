pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20.sol';


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

    event StakeOfHunterRelease(uint submissionId, address from, address to, uint amount);
    event StakeOfSheriffRelease(uint submissionId, address from, address to, uint amount);


    function Bounty0xStaking(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
    }


    function deposit(uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);

        emit Deposit(msg.sender, _amount, balances[msg.sender]);
    }

    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        require(ERC20(Bounty0xToken).transfer(msg.sender, _amount));

        emit Withdraw(msg.sender, _amount, balances[msg.sender]);
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
