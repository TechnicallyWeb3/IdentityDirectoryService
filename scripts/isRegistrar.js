const IdentityDirectory = artifacts.require("IdentityDirectory");
console.log("Hello World!")
module.exports = async function(callback) {
  try {
    console.log("trying")
    const instance = await IdentityDirectory.deployed();
    console.log(instance)
    const addressToCheck = "0x7b9a421575f72D17331CA7433aeA46eC5d5B2739";
    const isAddressRegistrar = await instance.isRegistrar(addressToCheck);
    console.log(addressToCheck)
    console.log("Is address a registrar:", isAddressRegistrar);
  } catch (error) {
    console.log("error caught")
    console.error(error);
  }
  callback();
};
