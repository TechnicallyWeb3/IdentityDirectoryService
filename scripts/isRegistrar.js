let IdentityDirectory = artifacts.require("IdentityDirectory");

module.exports = async function(callback) {
  try {
    let instance = await IdentityDirectory.deployed();
    let addressToCheck = process.argv[4]; // Read the address from command-line argument
    let isAddressRegistrar = await instance.isRegistrar(addressToCheck);
    console.log("Is address a registrar:", isAddressRegistrar);
  } catch (error) {
    console.error(error);
  }
  callback();
};
