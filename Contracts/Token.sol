// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract CreateToken is ERC20 {
    address public tokenowner;
  
    constructor() ERC20("SaiKiranToken", "SKT") {
        tokenowner = msg.sender;
        _mint(tokenowner, 90000 * (10**decimals()));
    }

    modifier onlyowner() {
        require(msg.sender == tokenowner, "Only Owner can allow this operation");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyowner {
        _mint(_to, _amount);
    }

   
}
