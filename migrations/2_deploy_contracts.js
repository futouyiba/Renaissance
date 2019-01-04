var vault = artifacts.require("CappedVault");
var cardIntegration = artifacts.require("CardIntegration");
var cardProto = artifacts.require("CardProto");
var rare = artifacts.require("RarePack");
var governable = artifacts.require("Governable");

module.exports = async function (deployer) {
//     await deployer.deploy(vault);
// //     console.log("deployed vault is:\n");
// //     console.log(vault.address);
// //     await deployer.deploy(cardProto);
// //     await deployer.deploy(governable);
//     await deployer.deploy(cardIntegration);
//     await deployer.deploy(rare, cardIntegration.address, vault.address);
    deployer.deploy(cardIntegration).then(()=>deployer.deploy(vault))
    .then(()=>{deployer.deploy(rare, cardIntegration.address, vault.address)});
//     deployer.deploy(rare, cardIntegration.address, vault.address);
;};
