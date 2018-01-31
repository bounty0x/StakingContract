pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20.sol';


contract Bounty0xStaking is Ownable {

    using SafeMath for uint256;

    address Bounty0xToken;

    mapping (address => uint) public staked; 

    event StakeRecieved(address user, uint amount, uint balance);
    event StakeReleased(address _from, address _to, uint amount, uint balance);
    

    function Bounty0xStaking(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
    }
    

    function stake(uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        staked[msg.sender] = SafeMath.add(staked[msg.sender], _amount);

        StakeRecieved(msg.sender, _amount, staked[msg.sender]);
    }

    function releaseStake(address _from, address _to, uint _amount) public onlyOwner {
        require(staked[_from] >= _amount);
        
        staked[_from] = SafeMath.sub(staked[_from], _amount);
        require(ERC20(Bounty0xToken).transfer(_to, _amount));
        
        StakeReleased(_to, _from, _amount, staked[_from]);
    }

}

