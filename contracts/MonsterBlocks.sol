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
  Counters.Counter private _ownerMintedTokenIds;

  IUniswapV2Router02 public uniswapRouter;

  // TODO: Update for Mainnet
  bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
  uint256 internal LinkFee = 0.1 * 10**18; // 0.1 LINK (Rinkeby) TODO for Mainnet
  address private VRFCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
  address private LinkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

  // TODO: Update for Mainnet
  uint256 public constant NFTMintPrice = 1000000000000000; // 0.001 ETH - TODO
  uint256 public constant maxSupply = 7000; // TODO
  uint256 public constant maxOwnerMintedSupply = 50; // TODO
  uint256 public constant maxMintLimit = 10;

  uint256 public constant numberOfTraits = 6;
  uint256 internal constant traitWeighting = 1000;

  uint16[][numberOfTraits] internal traitProbabilities;
  string[numberOfTraits] internal traitCategories;
  string[][numberOfTraits] internal traitNames;

  mapping(uint256 => uint256) public monsterBlocksDna; // TODO: Make internal
  mapping(bytes32 => uint256[]) public vrfRequestIds; // TODO: Make internal
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

  function traitMetadata(uint256 _tokenId) external view returns (string memory) {
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
        resultString = strConcat(resultString, traitNames[j][getMintedTrait(stacks[_tokenId][i], j)]);
        resultString = strConcat(resultString, '"');
      }
    }

    resultString = strConcat(resultString, stackMetadata(_tokenId));

    resultString = strConcat(resultString, ', "Tower Height": "');
    resultString = strConcat(resultString, Strings.toString(stacks[_tokenId].length));
    resultString = strConcat(resultString, '"');

    return strConcat(resultString, '}');
  }

  function ownerMintMonsterBlocks(uint256 _quantity) external onlyOwner {
    require(_ownerMintedTokenIds.current() < maxOwnerMintedSupply, "Maximum minted");
    require(_ownerMintedTokenIds.current() + _quantity <= maxOwnerMintedSupply, "Not enough left");
    require(_quantity < maxMintLimit + 1, "Max mint is 10");

    for (uint8 i = 0; i < _quantity; i++) {
      _ownerMintedTokenIds.increment();
    }

    mintMonsterBlock(_quantity);
  }

  function generateMonsterBlock(uint256 _quantity, uint256 _deadline) external payable whenNotPaused {
    require(_originalTokenIds.current() < maxSupply, "Maximum minted");
    require(_originalTokenIds.current() + _quantity <= maxSupply, "Not enough left");
    require(_quantity < maxMintLimit + 1, "Max mint is 10");
    require(NFTMintPrice * _quantity <= msg.value, "Not enough ETH");

    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = LinkToken;
    uniswapRouter.swapETHForExactTokens{value: msg.value} (LinkFee, path, address(this), _deadline);

    mintMonsterBlock(_quantity);
  }

  function engageStackinator(uint256 _bottomToken, uint256 _topToken) external {
    require(_exists(_bottomToken), "Bottom token does not exist");
    require(_exists(_topToken), "Top token does not exist");
    require(_isApprovedOrOwner(msg.sender, _bottomToken), "Not approved for bottom token");
    require(_isApprovedOrOwner(msg.sender, _topToken), "Not approved for top token");
    require(_bottomToken != _topToken, "Tokens are the same");

    _tokenIds.increment();

    _burn(_bottomToken);
    _burn(_topToken);

    _safeMint(msg.sender, _tokenIds.current());

    for (uint8 i = 0; i < stacks[_bottomToken].length; i++) {
      stacks[_tokenIds.current()].push(stacks[_bottomToken][i]);
    }
    for (uint8 i = 0; i < stacks[_topToken].length; i++) {
      stacks[_tokenIds.current()].push(stacks[_topToken][i]);
    }

    emit StackMonsterBlock(_tokenId1, _topToken, _tokenIds.current());
  }

  function setLinkFee(uint256 _LinkFee) external onlyOwner {
    LinkFee = _LinkFee;
  }

  function mintMonsterBlock(uint256 _quantity) internal {
    require(LINK.balanceOf(address(this)) >= LinkFee, "Not enough LINK");
    bytes32 requestId = requestRandomness(keyHash, LinkFee);

    for (uint8 i = 0; i < _quantity; i++) {
      _tokenIds.increment();

      vrfRequestIds[requestId].push(_tokenIds.current());

      _safeMint(msg.sender, _tokenIds.current());

      stacks[_tokenIds.current()] = [_tokenIds.current()];
      _originalTokenIds.increment();

      emit GenerateMonsterBlock(_tokenIds.current());
    }
  }

  function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
    for (uint8 i = 0; i < vrfRequestIds[_requestId].length; i++) {
      uint256 blockDna;
      if (i == 0) {
        blockDna = _randomNumber;
      } else {
        blockDna = uint256(keccak256(abi.encode(_randomNumber, numberOfTraits * i)));
      }
      monsterBlocksDna[vrfRequestIds[_requestId][i]] = blockDna;

      emit UpdateMonsterBlock(vrfRequestIds[_requestId][i], blockDna);
    }
  }

  function getMintedTrait(uint256 _tokenId, uint8 _traitIndex) internal view returns (uint256) {
    uint256 currentWeight = traitWeighting;
    uint256 dnaModuloWeight = (uint256(keccak256(abi.encode(monsterBlocksDna[_tokenId], _traitIndex + 1))) % currentWeight) + 1;

    for (uint8 j = 0; j < traitProbabilities[_traitIndex].length; j++) {
      currentWeight -= traitProbabilities[_traitIndex][j];
      if (dnaModuloWeight > currentWeight) {
        return j;
      }
    }

    return 0;
  }

  function stackMetadata(uint256 _tokenId) internal view returns (string memory) {
    string memory resultString = '';

    if (stacks[_tokenId].length < 2) {
      return resultString;
    }

    for (uint8 i = 0; i < stacks[_tokenId].length; i++) {
      resultString = strConcat(resultString, ', "Token ');
      resultString = strConcat(resultString, Strings.toString(i + 1));
      resultString = strConcat(resultString, '": "');
      resultString = strConcat(resultString, Strings.toString(stacks[_tokenId][i]));
      resultString = strConcat(resultString, '"');
    }

    return resultString;
  }
}
