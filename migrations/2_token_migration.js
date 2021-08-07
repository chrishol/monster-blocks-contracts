const Splitter = artifacts.require("PaymentSplitter");
const BlockToken = artifacts.require("MonsterBlocks");

module.exports = function (deployer) {
  deployer.deploy(Splitter,
    ['0x50EF16A9167661DC2500DDde8f83937C1ba4CD5f', '0x5e2eBd311Ed77dC6638c9f1998B8546C068067E5', '0xB09a43785E7dDAe6EBe9d8Bb6F7B908D2dc5fa11', '0x92a2BCa6dDBBA7a0518E54f8cFe5C3e252132848', '0x868B0BF922dec3B049c724FA9f61a719C8a3dB1c'],
    [20, 30, 15, 15, 10]
  ).then(function() {
    return deployer.deploy(BlockToken, Splitter.address, '0x5e2eBd311Ed77dC6638c9f1998B8546C068067E5');
  });
};
