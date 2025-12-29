defmodule AeX402 do
  @moduledoc """
  Elixir SDK for AeX402 Hybrid AMM on Solana.

  AeX402 is a hybrid AMM supporting both stable pools (AeX402 curve) and
  volatile pools (constant product), with N-token pools (2-8 tokens),
  farming, lottery, TWAP oracle, and advanced DeFi features.

  ## Modules

  - `AeX402.Constants` - Program ID, discriminators, error codes
  - `AeX402.Types` - Type definitions for accounts and instructions
  - `AeX402.Accounts` - Account parsing from binary data
  - `AeX402.Instructions` - Instruction data builders
  - `AeX402.Math` - StableSwap math (calc_d, calc_y, simulate_swap)
  - `AeX402.PDA` - Program Derived Address derivation

  ## Quick Start

      # Parse a pool account
      {:ok, pool} = AeX402.Accounts.parse_pool(account_data)

      # Simulate a swap
      {:ok, amount_out} = AeX402.Math.simulate_swap(
        pool.bal0,
        pool.bal1,
        100_000_000,
        pool.amp,
        pool.fee_bps
      )

      # Build swap instruction
      instruction_data = AeX402.Instructions.swap_t0_t1(%{
        amount_in: 100_000_000,
        min_out: amount_out - (amount_out * 100 / 10000)  # 1% slippage
      })

      # Derive pool PDA
      {:ok, mint0} = AeX402.Accounts.base58_to_pubkey("...")
      {:ok, mint1} = AeX402.Accounts.base58_to_pubkey("...")
      {:ok, {pool_address, bump}} = AeX402.PDA.derive_pool(mint0, mint1)

  ## Features

  ### Core AMM
  - **Dual Pool Types**: Stable pools (high amp, pegged assets) and volatile pools (amp=1)
  - **N-Token Pools**: Support for 2-8 token pools with AeX402 math
  - **TWAP Oracle**: On-chain manipulation-resistant price feed
  - **On-chain Analytics**: 24 hourly + 7 daily OHLCV candles

  ### Security
  - **Circuit Breakers**: Auto-pause on abnormal price deviation
  - **Rate Limiting**: Per-epoch swap volume and count limits
  - **Oracle Integration**: Pyth/Switchboard price validation

  ### Advanced Features
  - **Farming**: LP staking with time-locked rewards
  - **Lottery**: LP-based lottery system
  - **LP Governance**: Pools as DAOs with proposal/vote/execute
  - **Concentrated Liquidity**: Uniswap v3-style tick ranges
  - **Flash Loans**: Atomic borrow-and-repay

  ## Program ID

  The AeX402 program is deployed at:

      #{AeX402.Constants.program_id()}
  """

  @doc """
  Get the program ID as a Base58 string.
  """
  defdelegate program_id, to: AeX402.Constants

  @doc """
  Get the program ID as raw 32 bytes.
  """
  defdelegate program_id_bytes, to: AeX402.Constants

  @doc """
  Parse a Pool account from binary data.
  """
  defdelegate parse_pool(data), to: AeX402.Accounts

  @doc """
  Parse an NPool account from binary data.
  """
  defdelegate parse_npool(data), to: AeX402.Accounts

  @doc """
  Parse a Farm account from binary data.
  """
  defdelegate parse_farm(data), to: AeX402.Accounts

  @doc """
  Parse a UserFarm account from binary data.
  """
  defdelegate parse_user_farm(data), to: AeX402.Accounts

  @doc """
  Simulate a swap and return the output amount.
  """
  defdelegate simulate_swap(bal_in, bal_out, amount_in, amp, fee_bps), to: AeX402.Math

  @doc """
  Calculate invariant D for a 2-token pool.
  """
  defdelegate calc_d(x, y, amp), to: AeX402.Math

  @doc """
  Calculate output amount Y given input X for swap.
  """
  defdelegate calc_y(x_new, d, amp), to: AeX402.Math

  @doc """
  Derive a Pool PDA from the two token mints.
  """
  defdelegate derive_pool(mint0, mint1), to: AeX402.PDA

  @doc """
  Calculate LP tokens for a deposit.
  """
  defdelegate calc_lp_tokens(amt0, amt1, bal0, bal1, lp_supply, amp), to: AeX402.Math

  @doc """
  Calculate tokens received for LP token burn.
  """
  defdelegate calc_withdraw(lp_amount, bal0, bal1, lp_supply), to: AeX402.Math

  @doc """
  Get error message for a specific error code.
  """
  defdelegate error_message(code), to: AeX402.Constants
end
