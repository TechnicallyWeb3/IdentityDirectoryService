const IdentityDirectory = artifacts.require("IdentityDirectory");

module.exports = function (deployer) {
  deployer.deploy(IdentityDirectory, {
    gas: 6721975,
    value: 20000000000 // Specify the desired value in wei
  });
};
