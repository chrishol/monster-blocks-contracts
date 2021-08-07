const BlockToken = artifacts.require("MonsterBlocks");
// const BannerToken = artifacts.require("HypeBanners");

module.exports = function (deployer) {
  deployer.deploy(
    BlockToken
  );
  // deployer.deploy(BannerToken);
};
