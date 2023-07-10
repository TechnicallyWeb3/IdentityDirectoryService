const IdentityDirectory = artifacts.require("IdentityDirectory");

module.exports = function (deployer) {
  deployer.deploy(IdentityDirectory);
};
