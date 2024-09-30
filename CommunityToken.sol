/*
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommunityToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, address communityOwner) 
        ERC20(name, symbol) 
        Ownable(communityOwner)
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommunityToken is ERC20, Ownable {
    address public multiSigContract;
    address public rankingsContract;

    constructor(
        string memory name, 
        string memory symbol, 
        address _multiSigContract,
        address _rankingsContract
    ) ERC20(name, symbol) Ownable(_multiSigContract) {
        //require(_multiSigContract != address(0), "MultiSig address cannot be zero");
        //require(_rankingsContract != address(0), "Rankings address cannot be zero");
        multiSigContract = _multiSigContract;
        rankingsContract = _rankingsContract;
    }

    function mint(address to, uint256 amount) public {
        require(
            msg.sender == owner() || 
            msg.sender == multiSigContract || 
            msg.sender == rankingsContract, 
            "Unauthorized to mint"
        );
        _mint(to, amount);
    }

    function updateMinters(address _multiSigContract, address _rankingsContract) external onlyOwner {
        //require(_multiSigContract != address(0), "New MultiSig address cannot be zero");
        //require(_rankingsContract != address(0), "New Rankings address cannot be zero");
        multiSigContract = _multiSigContract;
        rankingsContract = _rankingsContract;
    }
}