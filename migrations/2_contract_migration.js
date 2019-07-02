const BlockRacer = artifacts.require("BlockRacer");
const EntityAddress = "0xf48D50efc893cA6B41B93De06Fa2D703D523Cb9C";
module.exports = function(deployer) {
  deployer.deploy(BlockRacer, EntityAddress);
};
