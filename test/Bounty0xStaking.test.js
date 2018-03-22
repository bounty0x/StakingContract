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

    it('should deposit', async () => {
        await tokenContract.approve(stakingContract.address, 1000);
        await stakingContract.deposit(1000);
        let balanceDeposited = await stakingContract.balances(owner);
        assert.strictEqual(balanceDeposited.toNumber(), 1000);

        let stakingContractBalance = await tokenContract.balanceOf(stakingContract.address);
        assert.strictEqual(stakingContractBalance.toNumber(), 1000);
    });

    it('should withdraw', async () => {
        await stakingContract.withdraw(100);
        let balanceDeposited = await stakingContract.balances(owner);
        assert.strictEqual(balanceDeposited.toNumber(), 900);

        let stakingContractBalance = await tokenContract.balanceOf(stakingContract.address);
        assert.strictEqual(stakingContractBalance.toNumber(), 900);
    });

    it('should stake', async () => {
        await stakingContract.stake(0, 100);
        let balanceStaked = await stakingContract.stakes(0, owner);
        assert.strictEqual(balanceStaked.toNumber(), 100);

        let balance = await stakingContract.balances(owner);
        assert.strictEqual(balance.toNumber(), 800);
    });

    it('should stake to many', async () => {
        let amounts = [10,10,10,10,10,10,10,10,10,10, 10,10,10,10,10,10,10,10,10,10, 1, 1, 1, 1, 1, 1, 1, 1, 1 ,1];
        let amountToStake = amounts.reduce((a, b) => a + b, 0);
        await stakingContract.stakeToMany([110,10,200,300,400,500,600,700,800,900, 110,111,211,311,411,511,611,711,811,911, 1220,122,222,322,422,522,622,722,822,922], amounts);
        let balanceStaked = await stakingContract.stakes(922, owner);
        assert.strictEqual(balanceStaked.toNumber(), 1);

        let balance = await stakingContract.balances(owner);
        assert.strictEqual(balance.toNumber(), 800-amountToStake);
    });

    it('releaseStake can only be called by owner', async () => {
        const bountyId = 0;
        const address = '0x1Dc4cf41Ce1f397033DeA502528b753b4D028777';
        const amount = 10;
        let initialStaked = await stakingContract.stakes(0, owner);

        await expectThrow(stakingContract.releaseStake(bountyId, owner, address, amount, { from: acct1 }));
        await expectThrow(stakingContract.releaseStake(bountyId, owner, address, amount, { from: acct2 }));
        const { logs } = await stakingContract.releaseStake(bountyId, owner, address, amount, { from: owner });
        assert.strictEqual(logs.length, 1);

        let balanceOfAddress = await stakingContract.balances(address);
        assert.equal(amount, balanceOfAddress.toNumber());

        let tokenBalanceStakedHunter = await stakingContract.stakes(0, owner);
        assert.equal(initialStaked - amount, tokenBalanceStakedHunter.toNumber());
    });

    it('releaseManyStakes can only be called by owner', async () => {
        const submissions = [110,10,200];
        const amounts = [2,3,4];
        const fromArray = [owner, owner, owner];
        const toArray = ['0x1Dc4cf41Ce1f397033DeA502528b753b4D028771', '0x1Dc4cf41Ce1f397033DeA502528b753b4D028772', '0x1Dc4cf41Ce1f397033DeA502528b753b4D028773'];
        let totalAmount = amounts.reduce((a, b) => a + b, 0);

        await expectThrow(stakingContract.releaseManyStakes(submissions, fromArray, toArray, amounts, { from: acct1 }));
        await expectThrow(stakingContract.releaseManyStakes(submissions, fromArray, toArray, amounts, { from: acct2 }));
        const { logs } = await stakingContract.releaseManyStakes(submissions, fromArray, toArray, amounts, { from: owner });
        assert.strictEqual(logs.length, toArray.length);

        for (var i = 0; i < toArray.length; i++) {
            let balanceOfAddress = await stakingContract.balances(toArray[i]);
            assert.equal(amounts[i], balanceOfAddress.toNumber());
        }
    });

});
