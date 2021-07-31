const BlockToken = artifacts.require("MonsterBlocks");
// const BannerToken = artifacts.require("HypeBanners");

module.exports = function (deployer) {
  let blockBaseProbabilities = [
    80, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40
  ];
  let eyesProbabilities = [1000];
  let mouthProbabilities = [250, 250, 200, 175, 125];
  let headProbabilities = [1000];
  let hatProbabilities = [300, 200, 200, 150, 100, 50];
  let clothingProbabilities = [300, 200, 200, 150, 100, 50];


  deployer.deploy(
    BlockToken,
    bodyProbabilities,
    eyesProbabilities,
    mouthProbabilities,
    headProbabilities,
    hatProbabilities,
    clothingProbabilities
  );
  // deployer.deploy(BannerToken);
};
