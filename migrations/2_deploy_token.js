const Token = artifacts.require("Token");

module.exports = function(deployer) {
  deployer.deploy(Token, "X Token", "XT", 0, 2, [], [], []);
};
