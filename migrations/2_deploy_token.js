const Token = artifacts.require("Token");

module.exports = function(deployer) {
  deployer.deploy(Token, "BrentCoin", "BC", 0, 2, [], [], []);
};
