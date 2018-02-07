pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20.sol';


contract Bounty0xStaking is Ownable {

    using SafeMath for uint256;

    address Bounty0xToken;

    mapping (uint => mapping (address => uint)) public staked; // mapping of bounty ids to mapping of staked amounts of bounty token by hunters

    event StakeRecieved(uint bountyId, address hunter, uint amount);
    event StakeReleased(uint bountyId, address from, address to, uint amount);


    function Bounty0xStaking(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
    }

    function stake(uint _bountyId, uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        staked[_bountyId][msg.sender] = SafeMath.add(staked[_bountyId][msg.sender], _amount);

        StakeRecieved(_bountyId, msg.sender, _amount);
    }

    function releaseStake(uint _bountyId, address _from, address _to, uint _amount) public onlyOwner {
        require(staked[_bountyId][_from] >= _amount);

        staked[_bountyId][_from] = SafeMath.sub(staked[_bountyId][_from], _amount);
        require(ERC20(Bounty0xToken).transfer(_to, _amount));

        StakeReleased(_bountyId, _from, _to, _amount);
    }

}
