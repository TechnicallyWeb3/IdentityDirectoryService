const IdentityDirectory = artifacts.require("IdentityDirectory");

module.exports = function (deployer) {
    deployer.deploy(IdentityDirectory, {
        gas: 3000000,
        value: 0 // Specify the desired value in wei
      });
      
};
