import expectThrow from './helpers/expectThrow';

const SimpleToken = artifacts.require("SimpleToken");
const Bounty0xStaking = artifacts.require("Bounty0xStaking");


contract('Bounty0xStaking', ([ owner, acct1, acct2, acct3, acct4, acct5 ]) => {
    let tokenContract;
    let tokenAddress;
    let stakingContract;

    before('get the deployed test token and Bounty0xStaking', async () => {
        tokenContract = await SimpleToken.deployed();
        tokenAddress = tokenContract.address;
        stakingContract = await Bounty0xStaking.deployed();
    });

    it('contracts should be deployed', async () => {
        assert.strictEqual(typeof tokenContract.address, 'string');
        assert.strictEqual(typeof stakingContract.address, 'string');
    });

    it('should stake', async () => {
        await tokenContract.approve(stakingContract.address, 1000);
        await stakingContract.stake(0, 1000);
        let balanceStaked = await stakingContract.staked(0, owner);
        assert.strictEqual(balanceStaked.toNumber(), 1000);

        let stakingContractBalance = await tokenContract.balanceOf(stakingContract.address);
        assert.strictEqual(stakingContractBalance.toNumber(), 1000);
    });

    it('releaseStake can only be called by owner', async () => {
        const bountyId = 0;
        const address = '0x1Dc4cf41Ce1f397033DeA502528b753b4D028777';
        const amount = 100;
        let initialStaked = await stakingContract.staked(0, owner);

        await expectThrow(stakingContract.releaseStake(bountyId, owner, address, amount, { from: acct1 }));
        await expectThrow(stakingContract.releaseStake(bountyId, owner, address, amount, { from: acct2 }));
        const { logs } = await stakingContract.releaseStake(bountyId, owner, address, amount, { from: owner });
        assert.strictEqual(logs.length, 1);

        let balanceOfAddress = await tokenContract.balanceOf(address);
        assert.equal(amount, balanceOfAddress.toNumber());

        let tokenBalanceStakedHunter = await stakingContract.staked(0, owner);
        assert.equal(initialStaked - amount, tokenBalanceStakedHunter.toNumber());
    });

});
