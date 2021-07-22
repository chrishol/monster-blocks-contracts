//////////////////////
//    HypeBeasts    //
//////////////////////

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./HypeBeastCoreERC721.sol";
import "./HypeBanners.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract HypeBeasts is HypeBeastCoreERC721, ReentrancyGuard, VRFConsumerBase {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  IUniswapV2Router02 public uniswapRouter;
  address payable public bannerContractAddress;

  bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
  uint256 internal LinkFee = 0.1 * 10**18; // 0.1 LINK (Rinkeby)
  address private VRFCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
  address private LinkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

  uint256 public constant NFTMintPrice = 80000000000000000; // 0.08 ETH
  uint256 public constant maxSupply = 2000;
  uint256 public constant maxMintLimit = 10;

  constructor()
    ERC721("HypeBeasts", "HYPEBEAST")
    VRFConsumerBase(VRFCoordinator, LinkToken)
  {
    uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // uint256 startIndex = 0;
    // allTraits.push(Trait("03045eff", 100));
    // allTraits.push(Trait("03045eff", 100));
    // allTraits.push(Trait("023e8aff", 100));
    // allTraits.push(Trait("0077b6ff", 100));
    // allTraits.push(Trait("0096c7ff", 100));
    // allTraits.push(Trait("00b4d8ff", 100));
    // allTraits.push(Trait("48cae4ff", 100));
    // allTraits.push(Trait("90e0efff", 100));
    // allTraits.push(Trait("ade8f4ff", 100));
    // allTraits.push(Trait("caf0f8ff", 100));
    // allTraitCategories.push(TraitCategory("Base Color", startIndex, allTraits.length));
    // startIndex = allTraits.length;
    //
    // allTraits.push(Trait("Kylie Lips", 600));
    // allTraits.push(Trait("Gold Grill", 100));
    // allTraits.push(Trait("Rainbow Teeth", 100));
    // allTraits.push(Trait("Blunt", 100));
    // allTraits.push(Trait("Drool", 100));
    // allTraitCategories.push(TraitCategory("Mouth", startIndex, allTraits.length));
    // startIndex = allTraits.length;
    //
    // allTraits.push(Trait("Green", 700));
    // allTraits.push(Trait("Striped", 100));
    // allTraits.push(Trait("Dots", 100));
    // allTraits.push(Trait("Blue", 100));
    // allTraitCategories.push(TraitCategory("Fur", startIndex, allTraits.length));
    // startIndex = allTraits.length;
    //
    // allTraits.push(Trait("Scowl", 700));
    // allTraits.push(Trait("Open", 100));
    // allTraits.push(Trait("Closed", 100));
    // allTraits.push(Trait("Wink", 100));
    // allTraitCategories.push(TraitCategory("Eyes", startIndex, allTraits.length));
    // startIndex = allTraits.length;
    //
    // allTraits.push(Trait("Bald", 700));
    // allTraits.push(Trait("Curly", 100));
    // allTraits.push(Trait("Straight", 100));
    // allTraits.push(Trait("Spiked", 100));
    // allTraitCategories.push(TraitCategory("Hair", startIndex, allTraits.length));
    // startIndex = allTraits.length;
  }

  mapping(uint256 => uint256) hypeBeastsDna;
  mapping(bytes32 => uint256) vrfRequestIds;

  event GenerateHypeBeast(
    uint256 tokenId
  );

  event UpdateHypeBeast(
    uint256 indexed id,
    uint256 dna
  );

  function tokenDna(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), "Token not yet minted");
    require(hypeBeastsDna[_tokenId] != 0, "Token dna not yet generated");

    return hypeBeastsDna[_tokenId];
  }

  function traitMetadata(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "Token not yet minted");
    require(hypeBeastsDna[_tokenId] != 0, "Token dna not yet generated");

    uint256 traitCategoryCount = allTraits.length;
    uint256[] memory expandedDnaNumbers = expandDna(hypeBeastsDna[_tokenId], traitCategoryCount);

    return generateTraitMetadata(traitCategoryCount, expandedDnaNumbers);
  }

  function generateHypeBeast(uint256 _quantity, uint256 _deadline) external payable nonReentrant whenNotPaused {
    require(_tokenIds.current() < maxSupply, "maximum mint count reached");
    require(_tokenIds.current() + _quantity <= maxSupply, "mint quantity exceeds max supply");
    require(_quantity > 0 && _quantity <= maxMintLimit, "mint quantity must be between 1-10");
    require(NFTMintPrice * _quantity <= msg.value, "eth value sent is not sufficient");

    uint256 amountOut = LinkFee * _quantity;
    swapEthForLink(amountOut, _deadline);

    for (uint256 i = 0; i < _quantity; i++) {
      _tokenIds.increment();

      require(LINK.balanceOf(address(this)) >= LinkFee, "Not enough LINK to call Chainlink VRF");
      bytes32 requestId = requestRandomness(keyHash, LinkFee, uint256(blockhash(block.number - i)));

      vrfRequestIds[requestId] = _tokenIds.current();

      _safeMint(msg.sender, _tokenIds.current());
      HypeBanners(bannerContractAddress).generateHypeBanner(msg.sender, _tokenIds.current());

      emit GenerateHypeBeast(_tokenIds.current());
    }
  }

  function swapEthForLink(uint256 _amountOut, uint256 _deadline) internal {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = LinkToken;

    uniswapRouter.swapETHForExactTokens{value: msg.value} (_amountOut, path, address(this), _deadline);
  }

  function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
    hypeBeastsDna[vrfRequestIds[_requestId]] = _randomNumber;

    HypeBanners(bannerContractAddress).fulfillRandomness(vrfRequestIds[_requestId], _randomNumber);

    emit UpdateHypeBeast(vrfRequestIds[_requestId], _randomNumber);
  }

  function expandDna(uint256 _dna, uint256 _n) internal pure returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](_n);
    for (uint256 i = 0; i < _n; i++) {
      expandedValues[i] = uint256(keccak256(abi.encode(_dna, i)));
    }
    return expandedValues;
  }

  function setBannerContractAddress(address payable _address) public onlyOwner {
    bannerContractAddress = _address;
  }

  function transferBannerOwnership(address _newOwner) public virtual onlyOwner {
    HypeBanners(bannerContractAddress).transferOwnership(_newOwner);
  }

  function setLinkFee(uint256 _LinkFee) public onlyOwner {
    LinkFee = _LinkFee;
  }
}
