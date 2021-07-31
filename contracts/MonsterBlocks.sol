// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MonsterBlockCoreERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MonsterBlocks is MonsterBlockCoreERC721, VRFConsumerBase {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  Counters.Counter private _originalTokenIds;

  IUniswapV2Router02 public uniswapRouter;

  // TODO: Update for Mainnet
  bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
  uint256 internal LinkFee = 0.1 * 10**18; // 0.1 LINK (Rinkeby)
  address private VRFCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
  address private LinkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

  // TODO: Update for Mainnet
  uint256 public constant NFTMintPrice = 7000000000000000; // 0.007 ETH - TODO
  uint256 public constant maxSupply = 50; // TODO
  uint256 public constant maxMintLimit = 10;

  uint256 public constant numberOfTraits = 6;
  uint256 internal constant traitWeighting = 1000;

  // N.B. Traits are zero-indexed, but tokens are 1-indexed
  uint8[numberOfTraits][maxSupply] public mintedTraits; // TODO: Make internal

  uint16[][numberOfTraits] internal traitProbabilities;
  string[numberOfTraits] internal traitCategories;
  string[][numberOfTraits] internal traitNames;

  constructor(
    uint16[] memory blockBaseProbabilities,
    uint16[] memory blockMiddleProbabilities,
    uint16[] memory blockTopProbabilities,
    uint16[] memory flourishBaseProbabilities,
    uint16[] memory flourishMiddleProbabilities,
    uint16[] memory flourishTopProbabilities
  )
    ERC721("MonsterBlocks", "MONSTERBLOCK")
    VRFConsumerBase(VRFCoordinator, LinkToken)
  {
    // TODO: Update for Mainnet
    uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    _pause(); // Start in paused sale state

    traitProbabilities[0] = blockBaseProbabilities;
    traitCategories[0] = "Base Block";

    traitProbabilities[1] = blockMiddleProbabilities;
    traitCategories[1] = "Middle Block";

    traitProbabilities[2] = blockTopProbabilities;
    traitCategories[2] = "Top Block";

    traitProbabilities[3] = flourishBaseProbabilities;
    traitCategories[3] = "Base Flourish";

    traitProbabilities[4] = flourishMiddleProbabilities;
    traitCategories[4] = "Middle Flourish";

    traitProbabilities[5] = flourishTopProbabilities;
    traitCategories[5] = "Top Flourish";

    traitNames[0] = [
      "Squeamish Behemoth - Red","Squeamish Behemoth - Stone","Squeamish Behemoth - Turquoise",
      "Lethargic Giraffe - Orange","Lethargic Giraffe - Green","Pensive Serpent - Green",
      "Pensive Serpent - Blue","Beleagured Troll - Green","Beleagured Troll - Orange",
      "Contemplative Grizzly - Gold","Contemplative Grizzly - Stone","Burdened Hobgoblin",
      "Turquoise Militarized Rodent","Amber Militarized Rodent","Concrete Militarized Rodent",
      "Shielded Goblin","Welcoming Demon","Blue Paralyzed Bull","Brown Paralyzed Bull",
      "Yellow Weaponized Hare","Green Weaponized Hare","Obedient Reptile",
      "Red Phillip","Stone Phillip"
    ];
    traitNames[1] = [
      "Grisly Harpy - Red","Grisly Harpy - Green","Grisly Harpy - Stone",
      "Frantic Coyote - Yellow","Frantic Coyote - Blue","Petrified Owl - Stone",
      "Petrified Owl - Amber","Burrowing Reptile","Space Walrus - Purple",
      "Space Walrus - Stone","Jolly Martian","Irate Swine - Cement",
      "Irate Swine - Red","Plague Rat","Wooden Crate",
      "Red Euphoric Pond Scum","Green Euphoric Pond Scum","Red Pipsqueak",
      "Blue Pipsqueak","Worried Tiki","Sedated Ogre",
      "Medicated Druid","Yellow Ecstatic Shrew","Green Ecstatic Shrew",
      "Green Prancing Lurker","Stone Prancing Lurker","Forlorn Shaman",
      "Marbled Moth","Piggish Vicar","Red Paltry Soothsayer","Green Paltry Soothsayer",
      "Red Moon Hound","Yellow Moon Hound","Unsightly Vermin","Anonymous Eyeball"
    ];
    traitNames[2] = [
      "Grisly Harpy - Red","Grisly Harpy - Green","Grisly Harpy - Stone",
      "Frantic Coyote - Yellow","Frantic Coyote - Blue","Petrified Owl - Stone",
      "Petrified Owl - Amber","Burrowing Reptile","Space Walrus - Purple",
      "Space Walrus - Stone","Jolly Martian","Irate Swine - Cement",
      "Irate Swine - Red","Plague Rat","Wooden Crate","Red Euphoric Pond Scum",
      "Green Euphoric Pond Scum","Red Pipsqueak","Blue Pipsqueak","Worried Tiki",
      "Sedated Ogre","Medicated Druid","Yellow Ecstatic Shrew",
      "Green Ecstatic Shrew","Green Prancing Lurker","Stone Prancing Lurker",
      "Forlorn Shaman","Marbled Moth","Piggish Vicar","Red Paltry Soothsayer",
      "Green Paltry Soothsayer","Red Moon Hound","Yellow Moon Hound",
      "Unsightly Vermin","Anonymous Eyeball"
    ];
    traitNames[3] = [
      "Stern Fists - Stone","Stern Fists - Blue","Stern Fists - Orange",
      "Depressive Lizard - Green","Depressive Lizard - Stone","Vengeful Dagger",
      "Precious Little Antlers","Prominent Rooster","Gilded Wings",
      "Cretinous Gargoyle"
    ];
    traitNames[4] = [
      "Stern Fists - Stone","Stern Fists - Blue","Stern Fists - Orange",
      "Depressive Lizard - Green","Depressive Lizard - Stone","Vengeful Dagger",
      "Precious Little Antlers","Prominent Rooster","Gilded Wings","Cretinous Gargoyle"
    ];
    traitNames[5] = [
      "Stern Fists - Stone","Stern Fists - Blue","Stern Fists - Orange",
      "Depressive Lizard - Green","Depressive Lizard - Stone","Vengeful Dagger",
      "Precious Little Antlers","Prominent Rooster","Gilded Wings","Cretinous Gargoyle"
    ];
  }

  mapping(uint256 => uint256) public monsterBlocksDna; // TODO: Make internal
  mapping(bytes32 => uint256) public vrfRequestIds; // TODO: Make internal
  mapping(uint256 => uint256) public mintedTraitIndex; // TODO: Make internal
  mapping(uint256 => uint256[]) public stacks; // TODO: Make internal

  event GenerateMonsterBlock(
    uint256 tokenId
  );

  event UpdateMonsterBlock(
    uint256 indexed id,
    uint256 dna
  );

  event StackMonsterBlock(
    uint256 tokenId1,
    uint256 tokenId2,
    uint256 resultTokenId
  );

  function traitMetadata(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "Not minted");
    require(stacks[_tokenId].length > 1 || monsterBlocksDna[_tokenId] != 0, "No DNA yet");

    string memory resultString = '{';
    for (uint8 i = 0; i < stacks[_tokenId].length; i++) {
      for (uint8 j = 0; j < numberOfTraits; j++) {
        if (i > 0 || j > 0) {
          resultString = strConcat(resultString, ', ');
        }
        resultString = strConcat(resultString, '"');
        resultString = strConcat(resultString, traitCategories[j]);
        resultString = strConcat(resultString, '": "');
        resultString = strConcat(resultString, traitNames[j][mintedTraits[mintedTraitIndex[_tokenId]][j]]);
        resultString = strConcat(resultString, '"');
      }
    }
    resultString = strConcat(resultString, ', ');
    resultString = strConcat(resultString, stackMetadata(_tokenId));
    resultString = strConcat(resultString, ', "Stack Height": "');
    resultString = strConcat(resultString, Strings.toString(stacks[_tokenId].length));
    return strConcat(resultString, '"}');
  }

  function stackMetadata(uint256 _tokenId) internal view returns (string memory) {
    string memory resultString = '';
    for (uint8 i = 0; i < stacks[_tokenId].length; i++) {
      if (i > 0) {
        resultString = strConcat(resultString, ', ');
      }
      resultString = strConcat(resultString, '"');
      resultString = strConcat(resultString, 'Token ');
      resultString = strConcat(resultString, Strings.toString(i));
      resultString = strConcat(resultString, '": "');
      resultString = strConcat(resultString, Strings.toString(stacks[_tokenId][i] + 1));
      resultString = strConcat(resultString, '"');
    }
    return resultString;
  }

  function generateMonsterBlock(uint256 _quantity, uint256 _deadline) external payable whenNotPaused {
    require(_originalTokenIds.current() < maxSupply, "Maximum minted");
    require(_originalTokenIds.current() + _quantity <= maxSupply, "Not enough left");
    require(_quantity < maxMintLimit + 1, "Max mint is 10");
    require(NFTMintPrice * _quantity <= msg.value, "Not enough ETH");

    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = LinkToken;
    uniswapRouter.swapETHForExactTokens{value: msg.value} (LinkFee * _quantity, path, address(this), _deadline);

    for (uint256 i = 0; i < _quantity; i++) {
      _tokenIds.increment();

      require(LINK.balanceOf(address(this)) >= LinkFee, "Not enough LINK");
      bytes32 requestId = requestRandomness(keyHash, LinkFee, uint256(blockhash(block.number - i)));

      vrfRequestIds[requestId] = _tokenIds.current();

      _safeMint(msg.sender, _tokenIds.current());

      stacks[_tokenIds.current()] = [_tokenIds.current()];
      mintedTraitIndex[_tokenIds.current()] = _originalTokenIds.current();
      _originalTokenIds.increment();

      emit GenerateMonsterBlock(_tokenIds.current());
    }
  }

  function engageStackinator(uint256 _tokenId1, uint256 _tokenId2) external {
    require(ownerOf(_tokenId1) == msg.sender, "Do not own token 1");
    require(ownerOf(_tokenId2) == msg.sender, "Do not own token 2");
    require(_tokenId1 != _tokenId2, "Tokens are the same");

    _tokenIds.increment();

    _burn(_tokenId1);
    _burn(_tokenId2);

    _safeMint(msg.sender, _tokenIds.current());

    for (uint8 i = 0; i < stacks[_tokenId1].length; i++) {
      stacks[_tokenIds.current()].push(stacks[_tokenId1][i]);
    }
    for (uint8 i = 0; i < stacks[_tokenId2].length; i++) {
      stacks[_tokenIds.current()].push(stacks[_tokenId2][i]);
    }

    emit StackMonsterBlock(_tokenId1, _tokenId2, _tokenIds.current());
  }

  function setLinkFee(uint256 _LinkFee) public onlyOwner {
    LinkFee = _LinkFee;
  }

  function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
    monsterBlocksDna[vrfRequestIds[_requestId]] = _randomNumber;

    for (uint256 i = 0; i < numberOfTraits; i++) {
      uint256 currentWeight = traitWeighting;
      uint256 dnaModuloWeight = (uint256(keccak256(abi.encode(_randomNumber, i))) % currentWeight) + 1;

      for (uint8 j = 0; j < traitProbabilities[i].length; j++) {
        currentWeight -= traitProbabilities[i][j];
        if (dnaModuloWeight > currentWeight) {
          mintedTraits[vrfRequestIds[_requestId] - 1][i] = j;
          break;
        }
      }
    }

    emit UpdateMonsterBlock(vrfRequestIds[_requestId], _randomNumber);
  }
}
