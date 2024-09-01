import { ethers } from 'hardhat';
import { expect } from 'chai';

import { ContractFactory, parseEther } from 'ethers';

import { SoakToken } from '../../typechain-types';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';

// WIP: Tests shouldn't use the mint function as the token is not mintable.
describe('Taxable Token', () => {
  let token: SoakToken;
  let accounts: HardhatEthersSigner[];
  let owner: HardhatEthersSigner;
  let user1: HardhatEthersSigner;
  let user2: HardhatEthersSigner;
  let liqPool: HardhatEthersSigner;

  before(async () => {
    accounts = await ethers.getSigners();
    owner = accounts[0];
    user1 = accounts[1];
    user2 = accounts[2];
    liqPool = accounts[3];

    // deploy token
    const tokenFactory: ContractFactory = await ethers.getContractFactory(
      'SoakToken',
      owner
    );
    token = (await tokenFactory.deploy(accounts[4], accounts[5])) as SoakToken;
    await token.waitForDeployment();

    // set taxes
    await token.connect(owner).updateTaxes(50, 500, 5); // buy = 0.5%, sell = 5%, transfer 0.05%
    await token.connect(owner).flagLiqPool(liqPool.address, true);
    // mint to liq pool
    await token.connect(owner).mint(liqPool.address, parseEther('10'));
  });

  describe('Tax System', async () => {
    it('mint should be tax exempt', async () => {
      const balanceBefore = await token.balanceOf(owner.address);

      await token.connect(owner).mint(owner.address, parseEther('100'));

      const balanceAfter = await token.balanceOf(owner.address);
      expect(balanceAfter).to.eq(balanceBefore + parseEther('100'));
    });

    it('transfer tax applied correctly', async () => {
      const balanceSenderBefore = await token.balanceOf(owner.address);
      const balanceReceiverBefore = await token.balanceOf(user1.address);
      const balanceTaxPoolBefore = await token.balanceOf(
        await token.getAddress()
      );

      await token.connect(owner).transfer(user1.address, parseEther('1'));

      const balanceSenderAfter = await token.balanceOf(owner.address);
      const balanceReceiverAfter = await token.balanceOf(user1.address);
      const balanceTaxPoolAfter = await token.balanceOf(
        await token.getAddress()
      );

      expect(balanceSenderAfter).to.eq(balanceSenderBefore - parseEther('1'));
      expect(balanceReceiverAfter).to.eq(
        balanceReceiverBefore + parseEther('0.9995')
      );
      expect(balanceTaxPoolAfter).to.eq(
        balanceTaxPoolBefore + parseEther('0.0005')
      );
    });

    it('buy tax applied correctly', async () => {
      const balanceSenderBefore = await token.balanceOf(liqPool.address);
      const balanceReceiverBefore = await token.balanceOf(user1.address);
      const balanceTaxPoolBefore = await token.balanceOf(
        await token.getAddress()
      );

      await token.connect(liqPool).transfer(user1.address, parseEther('1'));

      const balanceSenderAfter = await token.balanceOf(liqPool.address);
      const balanceReceiverAfter = await token.balanceOf(user1.address);
      const balanceTaxPoolAfter = await token.balanceOf(
        await token.getAddress()
      );

      expect(balanceSenderAfter).to.eq(balanceSenderBefore - parseEther('1'));
      expect(balanceReceiverAfter).to.eq(
        balanceReceiverBefore + parseEther('0.995')
      );
      expect(balanceTaxPoolAfter).to.eq(
        balanceTaxPoolBefore + parseEther('0.005')
      );
    });

    it('sell tax applied correctly', async () => {
      const balanceSenderBefore = await token.balanceOf(owner.address);
      const balanceReceiverBefore = await token.balanceOf(liqPool.address);
      const balanceTaxPoolBefore = await token.balanceOf(
        await token.getAddress()
      );

      await token.connect(owner).transfer(liqPool.address, parseEther('1'));

      const balanceSenderAfter = await token.balanceOf(owner.address);
      const balanceReceiverAfter = await token.balanceOf(liqPool.address);
      const balanceTaxPoolAfter = await token.balanceOf(
        await token.getAddress()
      );

      expect(balanceSenderAfter).to.eq(balanceSenderBefore - parseEther('1'));
      expect(balanceReceiverAfter).to.eq(
        balanceReceiverBefore + parseEther('0.95')
      );
      expect(balanceTaxPoolAfter).to.eq(
        balanceTaxPoolBefore + parseEther('0.05')
      );
    });

    it('tax exemption works correctly', async () => {
      await token.connect(owner).setTaxExempt(user2.address, true);
      const balanceSenderBefore = await token.balanceOf(owner.address);
      const balanceReceiverBefore = await token.balanceOf(user2.address);
      const balanceTaxPoolBefore = await token.balanceOf(
        await token.getAddress()
      );

      await token.connect(owner).transfer(user2.address, parseEther('1'));

      const balanceSenderAfter = await token.balanceOf(owner.address);
      const balanceReceiverAfter = await token.balanceOf(user2.address);
      const balanceTaxPoolAfter = await token.balanceOf(
        await token.getAddress()
      );

      expect(balanceSenderAfter).to.eq(balanceSenderBefore - parseEther('1'));
      expect(balanceReceiverAfter).to.eq(
        balanceReceiverBefore + parseEther('1')
      );
      expect(balanceTaxPoolAfter).to.eq(balanceTaxPoolBefore);
    });
  });
});
