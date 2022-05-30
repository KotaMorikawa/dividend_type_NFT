// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Token is ERC721Enumerable, Ownable {
    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 60;
    uint256 public maxMintAmount = 20;
    uint256 private depositAmount;
    bool public paused = false;
    bool public withdrawDividendFlag = false;

    event Mint(uint256 _mintAmount);
    event Withdraw();
    event Deposit();
    event Pause();

    constructor() ERC721("TOKEN", "TKN") {}

    function mintToken(uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        require(!paused, "Not publish!");
        require(_mintAmount > 0, "under minmun mint amount!");
        require(
            _mintAmount <= maxMintAmount,
            "Over max mint amount per person!"
        );
        require(supply + _mintAmount <= maxSupply, "Over total mint amount!");
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Insufficient charge!");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        emit Mint(_mintAmount);
    }

    //only owner
    function pause(bool _state) external onlyOwner {
        paused = _state;
        emit Pause();
    }

    function withdrawBalance() external payable onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
        emit Withdraw();
    }

    //deposit dividend for withdrawing
    function depositDividend() external payable onlyOwner {
        require(msg.value > 0, "Not enought deposit amount");
        withdrawDividendState(true);
        _depositAmount(msg.value);
        emit Deposit();
    }

    function _depositAmount(uint256 _amount) internal {
        depositAmount = _amount;
    }

    function withdrawDividendState(bool _state) public onlyOwner {
        withdrawDividendFlag = _state;
    }

    //withdraw dividend function
    function withdrawDividend() external {
        require(withdrawDividendFlag, "Can't withdraw dividend yet");
        require(balanceOf(msg.sender) > 0, "You have no token yet");
        _dividend();
    }

    function _dividend() public payable {
        // uint256 domi = (balanceOf(msg.sender) * 100) / maxSupply;
        // console.log(domi);
        uint256 dividend = (depositAmount * balanceOf(msg.sender)) / maxSupply;
        Address.sendValue(payable(msg.sender), dividend);
    }
}
