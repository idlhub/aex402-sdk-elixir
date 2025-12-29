defmodule AeX402.Types do
  @moduledoc """
  Type definitions for AeX402 AMM accounts and instruction arguments.

  All types map directly to the C structs in aex402.c.
  Binary sizes and field orders match the on-chain data layout.
  """

  # ============================================================================
  # Candle (12 bytes, delta-encoded OHLCV)
  # ============================================================================

  @typedoc """
  OHLCV candle with delta encoding for compactness.

  - open: Base price (scaled 1e6)
  - high_d: Delta from open (high = open + high_d)
  - low_d: Delta from open (low = open - low_d)
  - close_d: Signed delta from open (close = open + close_d)
  - volume: Volume in 1e9 units
  """
  @type candle :: %{
          open: non_neg_integer(),
          high_d: non_neg_integer(),
          low_d: non_neg_integer(),
          close_d: integer(),
          volume: non_neg_integer()
        }

  @typedoc "Decoded candle with actual OHLCV values"
  @type candle_decoded :: %{
          open: number(),
          high: number(),
          low: number(),
          close: number(),
          volume: number()
        }

  @doc "Decode a delta-encoded candle to actual values"
  @spec decode_candle(candle()) :: candle_decoded()
  def decode_candle(%{open: open, high_d: high_d, low_d: low_d, close_d: close_d, volume: volume}) do
    %{
      open: open,
      high: open + high_d,
      low: open - low_d,
      close: open + close_d,
      volume: volume
    }
  end

  # ============================================================================
  # Pool (2-token) - 1024 bytes
  # ============================================================================

  @typedoc """
  2-token AeX402 pool with on-chain OHLCV analytics.

  Size: 1024 bytes
  """
  @type pool :: %{
          discriminator: binary(),
          authority: binary(),
          mint0: binary(),
          mint1: binary(),
          vault0: binary(),
          vault1: binary(),
          lp_mint: binary(),
          amp: non_neg_integer(),
          init_amp: non_neg_integer(),
          target_amp: non_neg_integer(),
          ramp_start: integer(),
          ramp_stop: integer(),
          fee_bps: non_neg_integer(),
          admin_fee_pct: non_neg_integer(),
          bal0: non_neg_integer(),
          bal1: non_neg_integer(),
          lp_supply: non_neg_integer(),
          admin_fee0: non_neg_integer(),
          admin_fee1: non_neg_integer(),
          vol0: non_neg_integer(),
          vol1: non_neg_integer(),
          paused: boolean(),
          bump: non_neg_integer(),
          vault0_bump: non_neg_integer(),
          vault1_bump: non_neg_integer(),
          lp_mint_bump: non_neg_integer(),
          pending_auth: binary(),
          auth_time: integer(),
          pending_amp: non_neg_integer(),
          amp_time: integer(),
          trade_count: non_neg_integer(),
          trade_sum: non_neg_integer(),
          max_price: non_neg_integer(),
          min_price: non_neg_integer(),
          hour_slot: non_neg_integer(),
          day_slot: non_neg_integer(),
          hour_idx: non_neg_integer(),
          day_idx: non_neg_integer(),
          bloom: binary(),
          hourly_candles: [candle()],
          daily_candles: [candle()]
        }

  # ============================================================================
  # NPool (N-token, 2-8 tokens) - 2048 bytes
  # ============================================================================

  @typedoc """
  N-token pool supporting 2-8 tokens.

  Size: 2048 bytes
  """
  @type npool :: %{
          discriminator: binary(),
          authority: binary(),
          n_tokens: non_neg_integer(),
          paused: boolean(),
          bump: non_neg_integer(),
          amp: non_neg_integer(),
          fee_bps: non_neg_integer(),
          admin_fee_pct: non_neg_integer(),
          lp_supply: non_neg_integer(),
          mints: [binary()],
          vaults: [binary()],
          lp_mint: binary(),
          balances: [non_neg_integer()],
          admin_fees: [non_neg_integer()],
          total_volume: non_neg_integer(),
          trade_count: non_neg_integer(),
          last_trade_slot: non_neg_integer()
        }

  # ============================================================================
  # Lottery
  # ============================================================================

  @typedoc """
  Lottery state for LP-based lottery system.
  """
  @type lottery :: %{
          discriminator: binary(),
          pool: binary(),
          authority: binary(),
          lottery_vault: binary(),
          ticket_price: non_neg_integer(),
          total_tickets: non_neg_integer(),
          prize_pool: non_neg_integer(),
          end_time: integer(),
          winning_ticket: non_neg_integer(),
          drawn: boolean(),
          claimed: boolean()
        }

  # ============================================================================
  # LotteryEntry
  # ============================================================================

  @typedoc """
  User's lottery entry with ticket range.
  """
  @type lottery_entry :: %{
          discriminator: binary(),
          owner: binary(),
          lottery: binary(),
          ticket_start: non_neg_integer(),
          ticket_count: non_neg_integer()
        }

  # ============================================================================
  # Farm
  # ============================================================================

  @typedoc """
  Farming state with time-based rewards.
  """
  @type farm :: %{
          discriminator: binary(),
          pool: binary(),
          reward_mint: binary(),
          reward_rate: non_neg_integer(),
          start_time: integer(),
          end_time: integer(),
          total_staked: non_neg_integer(),
          acc_reward: non_neg_integer(),
          last_update: integer()
        }

  # ============================================================================
  # UserFarm
  # ============================================================================

  @typedoc """
  User's farming position with staked amount and rewards.
  """
  @type user_farm :: %{
          discriminator: binary(),
          owner: binary(),
          farm: binary(),
          staked: non_neg_integer(),
          reward_debt: non_neg_integer(),
          lock_end: integer()
        }

  # ============================================================================
  # Registry
  # ============================================================================

  @typedoc """
  Pool registry for on-chain enumeration.
  """
  @type registry :: %{
          discriminator: binary(),
          authority: binary(),
          pending_auth: binary(),
          auth_time: integer(),
          count: non_neg_integer(),
          pools: [binary()]
        }

  # ============================================================================
  # TWAP Result
  # ============================================================================

  @typedoc """
  Time-weighted average price result from the oracle.
  """
  @type twap_result :: %{
          price: non_neg_integer(),
          samples: non_neg_integer(),
          confidence: non_neg_integer()
        }

  @doc "Decode TWAP result from encoded u64"
  @spec decode_twap_result(non_neg_integer()) :: twap_result()
  def decode_twap_result(encoded) do
    price = encoded &&& 0xFFFFFFFF
    samples = (encoded >>> 32) &&& 0xFFFF
    confidence = (encoded >>> 48) &&& 0xFFFF

    %{
      price: price,
      samples: samples,
      confidence: confidence
    }
  end

  @doc "Get TWAP price as a float (scaled from 1e6)"
  @spec twap_price_as_float(twap_result()) :: float()
  def twap_price_as_float(%{price: price}), do: price / 1_000_000

  @doc "Get TWAP confidence as percentage"
  @spec twap_confidence_percent(twap_result()) :: float()
  def twap_confidence_percent(%{confidence: confidence}), do: confidence / 100

  # ============================================================================
  # Instruction Arguments
  # ============================================================================

  @typedoc "Arguments for createpool instruction"
  @type create_pool_args :: %{
          amp: non_neg_integer(),
          bump: non_neg_integer()
        }

  @typedoc "Arguments for createpn (N-pool) instruction"
  @type create_npool_args :: %{
          amp: non_neg_integer(),
          n_tokens: non_neg_integer(),
          bump: non_neg_integer()
        }

  @typedoc "Arguments for generic swap instruction"
  @type swap_args :: %{
          from: non_neg_integer(),
          to: non_neg_integer(),
          amount_in: non_neg_integer(),
          min_out: non_neg_integer(),
          deadline: integer()
        }

  @typedoc "Arguments for simple swap (t0t1 or t1t0) instruction"
  @type swap_simple_args :: %{
          amount_in: non_neg_integer(),
          min_out: non_neg_integer()
        }

  @typedoc "Arguments for N-pool swap instruction"
  @type swap_n_args :: %{
          from_idx: non_neg_integer(),
          to_idx: non_neg_integer(),
          amount_in: non_neg_integer(),
          min_out: non_neg_integer()
        }

  @typedoc "Arguments for add liquidity instruction"
  @type add_liq_args :: %{
          amount0: non_neg_integer(),
          amount1: non_neg_integer(),
          min_lp: non_neg_integer()
        }

  @typedoc "Arguments for single-sided add liquidity instruction"
  @type add_liq1_args :: %{
          amount_in: non_neg_integer(),
          min_lp: non_neg_integer()
        }

  @typedoc "Arguments for remove liquidity instruction"
  @type rem_liq_args :: %{
          lp_amount: non_neg_integer(),
          min0: non_neg_integer(),
          min1: non_neg_integer()
        }

  @typedoc "Arguments for update fee instruction"
  @type update_fee_args :: %{
          fee_bps: non_neg_integer()
        }

  @typedoc "Arguments for commit amp instruction"
  @type commit_amp_args :: %{
          target_amp: non_neg_integer()
        }

  @typedoc "Arguments for ramp amp instruction"
  @type ramp_amp_args :: %{
          target_amp: non_neg_integer(),
          duration: integer()
        }

  @typedoc "Arguments for create farm instruction"
  @type create_farm_args :: %{
          reward_rate: non_neg_integer(),
          start_time: integer(),
          end_time: integer()
        }

  @typedoc "Arguments for stake/unstake instruction"
  @type stake_args :: %{
          amount: non_neg_integer()
        }

  @typedoc "Arguments for lock LP instruction"
  @type lock_lp_args :: %{
          amount: non_neg_integer(),
          duration: integer()
        }

  @typedoc "Arguments for enter lottery instruction"
  @type enter_lottery_args :: %{
          ticket_count: non_neg_integer()
        }

  @typedoc "Arguments for draw lottery instruction"
  @type draw_lottery_args :: %{
          random_seed: non_neg_integer()
        }

  @typedoc "Arguments for create lottery instruction"
  @type create_lottery_args :: %{
          ticket_price: non_neg_integer(),
          end_time: integer()
        }
end
