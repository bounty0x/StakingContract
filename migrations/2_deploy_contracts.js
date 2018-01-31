const SimpleToken = artifacts.require("SimpleToken");
const Bounty0xStaking = artifacts.require("Bounty0xStaking");

module.exports = async function(deployer) {
    deployer.then(async () => {
        await deployer.deploy(SimpleToken);
        let tokenContract = await SimpleToken.deployed();
        await deployer.deploy(Bounty0xStaking, tokenContract.address);
    });
};
