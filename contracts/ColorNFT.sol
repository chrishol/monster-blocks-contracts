///////////////////////////////////////////////////////////
//     _____      _            _   _ ______ _______      //
//    / ____|    | |          | \ | |  ____|__   __|     //
//   | |     ___ | | ___  _ __|  \| | |__     | |        //
//   | |    / _ \| |/ _ \| '__| . ` |  __|    | |        //
//   | |___| (_) | | (_) | |  | |\  | |       | |        //
//    \_____\___/|_|\___/|_|  |_| \_|_|       |_|        //
//                                                       //
///////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ColorNFTs is ERC721Pausable, Ownable, ReentrancyGuard, VRFConsumerBase {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIds;

  IUniswapV2Router02 public uniswapRouter;

  bytes32 internal keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
  uint256 internal LinkFee = 2 * 10**18; // 2 LINK (mainnet)
  address private VRFCoordinator = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
  address private LinkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  uint256 public constant NFTMintPrice = 50000000000000000; // 0.08 ETH
  uint256 public constant NFTReRollPrice = 50000000000000000; // 0.035 ETH
  uint256 public constant maxSupply = 200;
  uint256 public constant maxMintLimit = 10;

  constructor() public
    ERC721("Color NFTs", "COLORNFT")
    VRFConsumerBase(VRFCoordinator, LinkToken)
  {
    uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    art.baseColor = ["03045eff","023e8aff","0077b6ff","0096c7ff","00b4d8ff","48cae4ff","90e0efff","ade8f4ff","caf0f8ff"];
  }

  struct Item {
    bytes12 name;
  }

  struct Art {
    string[] baseColor;
  }

  Art art;

  struct ColorNFT {
    uint256 dna;
  }

  struct VRFRequest {
    uint256 id;
  }

  mapping(uint256 => ColorNFT) colorNFTs;
  mapping(bytes32 => VRFRequest) VRFRequests;

  event GenerateColorNFT(
    uint256 tokenId
  );

  event UpdateColorNFT(
    uint256 indexed id,
    uint256 dna
  );

  function generateColorNFT(uint256 _quantity, uint256 _deadline) external payable nonReentrant whenNotPaused {
    require(_tokenIds.current() < maxSupply, "maximum mint count reached");
    require(_tokenIds.current() + _quantity <= maxSupply, "mint quantity exceeds max supply");
    require(_quantity > 0 && _quantity <= maxMintLimit, "mint quantity must be between 1-10");
    require(NFTMintPrice * _quantity <= msg.value, "eth value sent is not sufficient");

    uint256 amountOut = LinkFee * _quantity;

    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = LinkToken;

    uniswapRouter.swapETHForExactTokens{value: msg.value}(amountOut, path, address(this), _deadline);

    for (uint256 i = 0; i < _quantity; i++) {
      getRandomNumber(uint256(blockhash(block.number - i)));
    }
  }

  function getRandomNumber(uint256 _userProvidedSeed) internal {
    require(LINK.balanceOf(address(this)) >= LinkFee, "Not enough LINK - fill contract");
    bytes32 requestId = requestRandomness(keyHash, LinkFee, _userProvidedSeed);

    _tokenIds.increment();

    VRFRequests[requestId] = VRFRequest({
      id: _tokenIds.current()
    });

    _safeMint(msg.sender, _tokenIds.current());

    emit GenerateColorNFT(_tokenIds.current());
  }

  function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
    colorNFTs[VRFRequests[_requestId].id].dna = _randomNumber;
    emit UpdateColorNFT(VRFRequests[_requestId].id, _randomNumber);
  }

  function reRollColor(uint256 _tokenId, uint256 _deadline) public payable {
    require(NFTReRollPrice * _quantity <= msg.value, "eth value sent is not sufficient");
    require(msg.sender == ownerOf(_tokenId), "Not NFT owner");

    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = LinkToken;

    uniswapRouter.swapETHForExactTokens{value: msg.value}(LinkFee, path, address(this), _deadline);

    getRandomNumber(uint256(blockhash(block.number)));
  }


  function pauseSale() public onlyOwner {
    _pause();
  }

  function unpauseSale() public onlyOwner {
    _unpause();
  }

  function setLinkFee(uint256 _LinkFee) public onlyOwner {
    LinkFee = _LinkFee;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    _setBaseURI(_baseURI);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = baseURI();

    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
      : '';
  }

  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}('');
    require(success, "Withdrawal failed");
  }

  receive() external payable {}
}
