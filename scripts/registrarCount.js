const IdentityDirectory = artifacts.require("IdentityDirectory");
console.log("Hello World!")
module.exports = async function(callback) {
  try {
    console.log("trying")
    const instance = await IdentityDirectory.deployed();
    const registrarCount = await instance.registrarCount();
    console.log("Registrar Count:", registrarCount);
  } catch (error) {
    console.log("error caught")
    console.error(error);
  }
  callback();
};
