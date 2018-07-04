pragma solidity ^0.4.21;




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





// File: minimetoken/contracts/TokenController.sol

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}




contract BntyTokenInterface {
  function destroyTokens(address _owner, uint _amount) public returns (bool);
  function changeController(address newController) public;
}




contract BntyController is Ownable, TokenController {
    
    address public stakingContract;
    address public Bounty0xToken;
    
    modifier onlyStakingContract() {
        require(msg.sender == stakingContract);
        _;
    }
    
    
    constructor(address _stakingContract, address _Bounty0xToken) public {
        stakingContract = _stakingContract;
        Bounty0xToken = _Bounty0xToken;
    }
    
    
    function changeStakingContract(address _stakingContract) onlyOwner public {
        stakingContract = _stakingContract;
    }

    function destroyTokensInBntyTokenContract(address _owner, uint _amount) onlyStakingContract public returns (bool) {
        require(BntyTokenInterface(Bounty0xToken).destroyTokens(_owner, _amount));
        return true;
    }
    
    function changeControllerInBntyTokenContract(address newController) onlyOwner public {
        BntyTokenInterface(Bounty0xToken).changeController(newController);
    }


    function proxyPayment(address _owner) public payable returns (bool) {
        return false;
    }

    function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
        return true;
    }
    
    function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
        return true;
    }
    
}
