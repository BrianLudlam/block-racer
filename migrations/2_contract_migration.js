const BlockRacer = artifacts.require("BlockRacer");
const EntityAddress = "0x725e882ED026B5F90ACCe6E02Ee1f27FBCbe1928";
module.exports = function(deployer) {
  deployer.deploy(BlockRacer, EntityAddress);
};
