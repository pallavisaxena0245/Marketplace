// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract RealEstate is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Rentoblock", "ROB") {}

    /// @notice Mint a new property NFT
    function mint(string memory tokenURI) public returns (uint256) {
        uint256 currentId = _tokenIds.current();
        _mint(msg.sender, currentId);
        _setTokenURI(currentId, tokenURI);

        _tokenIds.increment();
        return currentId;
    }

    /// @notice Get total supply of minted NFTs
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}
