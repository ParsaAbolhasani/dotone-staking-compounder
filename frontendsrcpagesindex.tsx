// frontend/src/pages/index.tsx
import React, { useState } from 'react';
import { useDotOneSDK } from '../hooks/useDotOneSDK';

export default function Home() {
  const { account, connectWallet, getTiers, getUserPositions } = useDotOneSDK();
  const [selectedToken, setSelectedToken] = useState('');
  const [amount, setAmount] = useState('');
  const [tiers, setTiers] = useState([]);

  const handleTokenSelect = async (token: string) => {
    setSelectedToken(token);
    const t = await getTiers(token);
    setTiers(t);
  };

  return (
    <div className="min-h-screen bg-gray-900 text-white p-8">
      <header className="mb-12">
        <h1 className="text-4xl font-bold">DotOne Staking Compounder</h1>
        <p className="text-gray-400 mt-2">
          Stake on DotOne Chain with automatic reward compounding
        </p>
      </header>

      {!account ? (
        <button
          onClick={connectWallet}
          className="bg-blue-600 px-6 py-3 rounded-lg font-semibold"
        >
          Connect Wallet
        </button>
      ) : (
        <div className="grid grid-cols-2 gap-8">
          {/* Stake Panel */}
          <div className="bg-gray-800 p-6 rounded-xl">
            <h2 className="text-xl font-semibold mb-4">New Stake</h2>

            <input
              type="text"
              placeholder="Token Address"
              className="w-full bg-gray-700 p-3 rounded-lg mb-4"
              onChange={(e) => handleTokenSelect(e.target.value)}
            />

            <input
              type="number"
              placeholder="Amount"
              className="w-full bg-gray-700 p-3 rounded-lg mb-4"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />

            <div className="mb-4">
              <label className="block text-sm text-gray-400 mb-2">
                Available Tiers
              </label>
              {tiers.length === 0 ? (
                <p className="text-gray-500 text-sm">
                  Select a supported token to view tiers
                </p>
              ) : (
                tiers.map((tier: any, i: number) => (
                  <div key={i} className="bg-gray-700 p-3 rounded-lg mb-2">
                    <div className="flex justify-between">
                      <span>Tier {i}</span>
                      <span className="text-green-400">
                        {tier.minApy / 100}% - {tier.maxApy / 100}% APY
                      </span>
                    </div>
                    <div className="text-sm text-gray-400">
                      Lock: {tier.lockPeriod / 86400} days
                    </div>
                  </div>
                ))
              )}
            </div>

            <button className="w-full bg-green-600 py-3 rounded-lg font-semibold">
              Stake with Auto-Compound
            </button>
          </div>

          {/* Positions Panel */}
          <div className="bg-gray-800 p-6 rounded-xl">
            <h2 className="text-xl font-semibold mb-4">Your Positions</h2>
            <p className="text-gray-400">
              Connect wallet to view positions
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
