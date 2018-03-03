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

    it('should depositAsHunter', async () => {
        await tokenContract.approve(stakingContract.address, 1000);
        await stakingContract.depositAsHunter(1000);
        let balanceDeposited = await stakingContract.huntersDeposits(owner);
        assert.strictEqual(balanceDeposited.toNumber(), 1000);

        let stakingContractBalance = await tokenContract.balanceOf(stakingContract.address);
        assert.strictEqual(stakingContractBalance.toNumber(), 1000);
    });

    it('should depositAsSheriff', async () => {
        await tokenContract.approve(stakingContract.address, 1000);
        await stakingContract.depositAsSheriff(1000);
        let balanceDeposited = await stakingContract.sheriffsDeposits(owner);
        assert.strictEqual(balanceDeposited.toNumber(), 1000);

        let stakingContractBalance = await tokenContract.balanceOf(stakingContract.address);
        assert.strictEqual(stakingContractBalance.toNumber(), 2000);
    });

    it('should stakeAsHunter', async () => {
        await stakingContract.stakeAsHunter(0, 100);
        let balanceStaked = await stakingContract.stakedByHunters(0, owner);
        assert.strictEqual(balanceStaked.toNumber(), 100);

        let hunterDeposit = await stakingContract.huntersDeposits(owner);
        assert.strictEqual(hunterDeposit.toNumber(), 900);
    });

    it('should stakeAsSheriff', async () => {
        await stakingContract.stakeAsSheriff(0, 100);
        let balanceStaked = await stakingContract.stakedBySheriffs(0, owner);
        assert.strictEqual(balanceStaked.toNumber(), 100);

        let sheriffDeposit = await stakingContract.sheriffsDeposits(owner);
        assert.strictEqual(sheriffDeposit.toNumber(), 900);
    });

    it('releaseHunterStake can only be called by owner', async () => {
        const bountyId = 0;
        const address = '0x1Dc4cf41Ce1f397033DeA502528b753b4D028777';
        const amount = 10;
        let initialStaked = await stakingContract.stakedByHunters(0, owner);

        await expectThrow(stakingContract.releaseHunterStake(bountyId, owner, address, amount, { from: acct1 }));
        await expectThrow(stakingContract.releaseHunterStake(bountyId, owner, address, amount, { from: acct2 }));
        const { logs } = await stakingContract.releaseHunterStake(bountyId, owner, address, amount, { from: owner });
        assert.strictEqual(logs.length, 1);

        let balanceOfAddress = await tokenContract.balanceOf(address);
        assert.equal(amount, balanceOfAddress.toNumber());

        let tokenBalanceStakedHunter = await stakingContract.stakedByHunters(0, owner);
        assert.equal(initialStaked - amount, tokenBalanceStakedHunter.toNumber());
    });

    it('releaseSheriffStake can only be called by owner', async () => {
        const bountyId = 0;
        const address = '0x1Dc4cf41Ce1f397033DeA502528b753b4D028771';
        const amount = 10;
        let initialStaked = await stakingContract.stakedBySheriffs(0, owner);

        await expectThrow(stakingContract.releaseSheriffStake(bountyId, owner, address, amount, { from: acct1 }));
        await expectThrow(stakingContract.releaseSheriffStake(bountyId, owner, address, amount, { from: acct2 }));
        const { logs } = await stakingContract.releaseSheriffStake(bountyId, owner, address, amount, { from: owner });
        assert.strictEqual(logs.length, 1);

        let balanceOfAddress = await tokenContract.balanceOf(address);
        assert.equal(amount, balanceOfAddress.toNumber());

        let tokenBalanceStakedHunter = await stakingContract.stakedBySheriffs(0, owner);
        assert.equal(initialStaked - amount, tokenBalanceStakedHunter.toNumber());
    });

});
