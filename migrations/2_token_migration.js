const BeastToken = artifacts.require("HypeBeasts");
const BannerToken = artifacts.require("HypeBanners");

module.exports = function (deployer) {
  deployer.deploy(BeastToken);
  deployer.deploy(BannerToken);
};
