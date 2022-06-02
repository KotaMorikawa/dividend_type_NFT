// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Token is ERC721Enumerable, Ownable {
    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 60;
    uint256 public maxMintAmount = 20;
    uint256 private depositAmount;
    bool public paused = false;
    bool public withdrawDividendFlag = false;
    string public baseURI;

    event Mint(uint256 _mintAmount);
    event Withdraw();
    event Deposit();
    event Pause();

    constructor(string memory initBaseURI) ERC721("TOKEN", "TKN") {
        setBaseURI(initBaseURI);
    }

    //main contract function
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

    //inherit function
    function tokenURI(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenID),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _baseURI();
    }

    //only owner
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
        emit Pause();
    }

    function withdrawBalance() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        emit Withdraw();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
        uint256 dividend = (depositAmount * balanceOf(msg.sender)) / maxSupply;
        (bool os, ) = payable(msg.sender).call{value: dividend}("");
        require(os);
    }
}
