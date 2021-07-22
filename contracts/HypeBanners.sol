////////////////////////////
//    HypeBeastBanners    //
////////////////////////////

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./HypeBeastCoreERC721.sol";

contract HypeBanners is HypeBeastCoreERC721 {
  uint256 public constant maxSupply = 2000;

  constructor()
    ERC721("HypeBanners", "HYPEBANNER")
  {
    setBaseURI("https://api.hypebeasts.io/hypebanners/metadata/");
  }

  struct HypeBanner {
    uint256 dna;
  }

  mapping(uint256 => HypeBanner) hypeBanners;

  event GenerateHypeBanner(
    uint256 tokenId
  );

  event UpdateHypeBanner(
    uint256 indexed id,
    uint256 dna
  );

  function tokenDna(uint256 _tokenId) public view returns (uint256) {
		require(_exists(_tokenId), "Token not yet minted");
		require(hypeBanners[_tokenId].dna != 0, "Token dna not yet generated");

    return hypeBanners[_tokenId].dna;
  }

  function generateHypeBanner(address _address, uint256 _tokenId) external onlyOwner {
    require(_tokenId < maxSupply, "maximum mint count reached");
    require(!_exists(_tokenId), "token already minted");

    _safeMint(_address, _tokenId);

    emit GenerateHypeBanner(_tokenId);
  }

  function fulfillRandomness(uint256 _tokenId, uint256 _randomNumber) external onlyOwner {
    hypeBanners[_tokenId].dna = _randomNumber;
    emit UpdateHypeBanner(_tokenId, _randomNumber);
  }
}
