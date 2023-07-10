const IdentityDirectory = artifacts.require("IdentityDirectory");
module.exports = async function(callback) {
  try {
    let IdentityDirectory = artifacts.require("IdentityDirectory");
    let contract = await IdentityDirectory.deployed();
    let result = await contract.registrarCount();
    console.log(result);
  } catch (error) {
    console.log("error caught")
    console.error(error);
  }
  callback();
};
