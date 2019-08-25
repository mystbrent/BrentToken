const ERC1820Registry = artifacts.require("ERC1820Registry");

module.exports = function(deployer) {
  deployer.deploy(ERC1820Registry);
};
