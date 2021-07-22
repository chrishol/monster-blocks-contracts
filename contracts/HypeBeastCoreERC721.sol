/////////////////////////
//    HypeBeastCore    //
/////////////////////////

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract HypeBeastCoreERC721 is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
  using SafeMath for uint256;

  string public baseURI;
  TraitCategory[] public allTraitCategories;
  Trait[] public allTraits;

  struct TraitCategory {
    string name;
    uint256 startIndex;
    uint256 length;
  }

  struct Trait {
    string name;
    uint weight;
  }

  function strConcat(string memory _a, string memory _b) internal pure returns(string memory) {
    return string(abi.encodePacked(bytes(_a), bytes(_b)));
  }

  function traitCategoryWeight(uint256 _startIndex, uint256 _length) internal view returns (uint256) {
    uint256 totalWeight = 0;
    for (uint i = _startIndex; i < _length; i++) {
      totalWeight += allTraits[i].weight;
    }
    return totalWeight;
  }

  function generateTraitMetadata(uint256 _traitCategoryCount, uint256[] memory _expandedDnaNumbers) internal view returns (string memory) {
    string memory resultString = "{";
    for (uint i = 0; i < _traitCategoryCount; i++) {
      TraitCategory memory category = allTraitCategories[i];
      if (i > 0) {
        resultString = strConcat(resultString, ", ");
      }
      resultString = strConcat(resultString, "\'");
      resultString = strConcat(resultString, category.name);
      resultString = strConcat(resultString, "\': \'");
      resultString = strConcat(resultString, traitValue(category.startIndex, category.length, _expandedDnaNumbers[i]));
      resultString = strConcat(resultString, "\'");
    }
    resultString = strConcat(resultString, "}");
    return resultString;
  }

  function traitValue(uint256 _startIndex, uint256 _length, uint256 _expandedDna) internal view returns (string memory) {
    uint256 currentWeight = traitCategoryWeight(_startIndex, _length);
    uint256 dnaModuloWeight = _expandedDna.mod(currentWeight).add(1);

    for (uint i = _startIndex; i < _length; i++) {
      currentWeight -= allTraits[i].weight;
      if (dnaModuloWeight > currentWeight) {
        return allTraits[i].name;
      }
    }

    return "Not found";
  }

  function pauseSale() public onlyOwner {
    _pause();
  }

  function unpauseSale() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(_tokenId, _tokenURI);
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call { value: address(this).balance }('');
    require(success, "Withdrawal failed");
  }

  receive() external payable {}
}
