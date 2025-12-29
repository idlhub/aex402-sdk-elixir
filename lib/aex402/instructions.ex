defmodule AeX402.Instructions do
  @moduledoc """
  Instruction builders for AeX402 AMM program.

  Each function builds the binary instruction data for a specific handler.
  The data is prefixed with an 8-byte discriminator followed by the
  instruction-specific arguments.

  These instruction data binaries are meant to be used with Solana transaction
  builders to create complete transaction instructions.
  """

  alias AeX402.Constants
  alias AeX402.Types

  # ============================================================================
  # Pool Creation Instructions
  # ============================================================================

  @doc """
  Build instruction data for creating a 2-token pool.

  ## Arguments
    - amp: Amplification coefficient (1 to 100,000)
    - bump: PDA bump seed

  ## Returns
  Binary instruction data (17 bytes)
  """
  @spec create_pool(Types.create_pool_args()) :: binary()
  def create_pool(%{amp: amp, bump: bump}) do
    Constants.discriminator(:createpool) <>
      <<amp::little-unsigned-64, bump::8>>
  end

  @doc """
  Build instruction data for creating an N-token pool.

  ## Arguments
    - amp: Amplification coefficient
    - n_tokens: Number of tokens (2-8)
    - bump: PDA bump seed

  ## Returns
  Binary instruction data (18 bytes)
  """
  @spec create_npool(Types.create_npool_args()) :: binary()
  def create_npool(%{amp: amp, n_tokens: n_tokens, bump: bump}) do
    Constants.discriminator(:createpn) <>
      <<amp::little-unsigned-64, n_tokens::8, bump::8>>
  end

  @doc """
  Build instruction data for initializing token 0 vault.

  Returns just the discriminator (8 bytes).
  """
  @spec init_t0_vault() :: binary()
  def init_t0_vault do
    Constants.discriminator(:initt0v)
  end

  @doc """
  Build instruction data for initializing token 1 vault.

  Returns just the discriminator (8 bytes).
  """
  @spec init_t1_vault() :: binary()
  def init_t1_vault do
    Constants.discriminator(:initt1v)
  end

  @doc """
  Build instruction data for initializing LP mint.

  Returns just the discriminator (8 bytes).
  """
  @spec init_lp_mint() :: binary()
  def init_lp_mint do
    Constants.discriminator(:initlpm)
  end

  # ============================================================================
  # Swap Instructions
  # ============================================================================

  @doc """
  Build instruction data for a generic swap.

  ## Arguments
    - from: Source token index
    - to: Destination token index
    - amount_in: Amount to swap
    - min_out: Minimum output amount
    - deadline: Transaction deadline (Unix timestamp)

  ## Returns
  Binary instruction data (34 bytes)
  """
  @spec swap(Types.swap_args()) :: binary()
  def swap(%{from: from, to: to, amount_in: amount_in, min_out: min_out, deadline: deadline}) do
    Constants.discriminator(:swap) <>
      <<
        from::8,
        to::8,
        amount_in::little-unsigned-64,
        min_out::little-unsigned-64,
        deadline::little-signed-64
      >>
  end

  @doc """
  Build instruction data for token 0 to token 1 swap.

  ## Arguments
    - amount_in: Amount to swap
    - min_out: Minimum output amount

  ## Returns
  Binary instruction data (24 bytes)
  """
  @spec swap_t0_t1(Types.swap_simple_args()) :: binary()
  def swap_t0_t1(%{amount_in: amount_in, min_out: min_out}) do
    Constants.discriminator(:swapt0t1) <>
      <<amount_in::little-unsigned-64, min_out::little-unsigned-64>>
  end

  @doc """
  Build instruction data for token 1 to token 0 swap.

  ## Arguments
    - amount_in: Amount to swap
    - min_out: Minimum output amount

  ## Returns
  Binary instruction data (24 bytes)
  """
  @spec swap_t1_t0(Types.swap_simple_args()) :: binary()
  def swap_t1_t0(%{amount_in: amount_in, min_out: min_out}) do
    Constants.discriminator(:swapt1t0) <>
      <<amount_in::little-unsigned-64, min_out::little-unsigned-64>>
  end

  @doc """
  Build instruction data for N-pool swap.

  ## Arguments
    - from_idx: Source token index
    - to_idx: Destination token index
    - amount_in: Amount to swap
    - min_out: Minimum output amount

  ## Returns
  Binary instruction data (26 bytes)
  """
  @spec swap_n(Types.swap_n_args()) :: binary()
  def swap_n(%{from_idx: from_idx, to_idx: to_idx, amount_in: amount_in, min_out: min_out}) do
    Constants.discriminator(:swapn) <>
      <<
        from_idx::8,
        to_idx::8,
        amount_in::little-unsigned-64,
        min_out::little-unsigned-64
      >>
  end

  @doc """
  Build instruction data for migration swap (t0 to t1).

  Uses fixed 0.1337% fee for token migration.
  """
  @spec migration_swap_t0_t1(Types.swap_simple_args()) :: binary()
  def migration_swap_t0_t1(%{amount_in: amount_in, min_out: min_out}) do
    Constants.discriminator(:migt0t1) <>
      <<amount_in::little-unsigned-64, min_out::little-unsigned-64>>
  end

  @doc """
  Build instruction data for migration swap (t1 to t0).

  Uses fixed 0.1337% fee for token migration.
  """
  @spec migration_swap_t1_t0(Types.swap_simple_args()) :: binary()
  def migration_swap_t1_t0(%{amount_in: amount_in, min_out: min_out}) do
    Constants.discriminator(:migt1t0) <>
      <<amount_in::little-unsigned-64, min_out::little-unsigned-64>>
  end

  # ============================================================================
  # Liquidity Instructions
  # ============================================================================

  @doc """
  Build instruction data for adding liquidity to a 2-token pool.

  ## Arguments
    - amount0: Amount of token 0
    - amount1: Amount of token 1
    - min_lp: Minimum LP tokens to receive

  ## Returns
  Binary instruction data (32 bytes)
  """
  @spec add_liquidity(Types.add_liq_args()) :: binary()
  def add_liquidity(%{amount0: amount0, amount1: amount1, min_lp: min_lp}) do
    Constants.discriminator(:addliq) <>
      <<
        amount0::little-unsigned-64,
        amount1::little-unsigned-64,
        min_lp::little-unsigned-64
      >>
  end

  @doc """
  Build instruction data for single-sided liquidity add.

  ## Arguments
    - amount_in: Amount of single token
    - min_lp: Minimum LP tokens to receive

  ## Returns
  Binary instruction data (24 bytes)
  """
  @spec add_liquidity_single(Types.add_liq1_args()) :: binary()
  def add_liquidity_single(%{amount_in: amount_in, min_lp: min_lp}) do
    Constants.discriminator(:addliq1) <>
      <<amount_in::little-unsigned-64, min_lp::little-unsigned-64>>
  end

  @doc """
  Build instruction data for adding liquidity to N-token pool.

  ## Arguments
    - amounts: List of amounts for each token (up to 8)
    - min_lp: Minimum LP tokens to receive

  ## Returns
  Binary instruction data
  """
  @spec add_liquidity_n([non_neg_integer()], non_neg_integer()) :: binary()
  def add_liquidity_n(amounts, min_lp) when length(amounts) <= 8 do
    amounts_binary =
      amounts
      |> Enum.map(fn amt -> <<amt::little-unsigned-64>> end)
      |> Enum.join()

    Constants.discriminator(:addliqn) <> amounts_binary <> <<min_lp::little-unsigned-64>>
  end

  @doc """
  Build instruction data for removing liquidity from a 2-token pool.

  ## Arguments
    - lp_amount: Amount of LP tokens to burn
    - min0: Minimum amount of token 0 to receive
    - min1: Minimum amount of token 1 to receive

  ## Returns
  Binary instruction data (32 bytes)
  """
  @spec remove_liquidity(Types.rem_liq_args()) :: binary()
  def remove_liquidity(%{lp_amount: lp_amount, min0: min0, min1: min1}) do
    Constants.discriminator(:remliq) <>
      <<
        lp_amount::little-unsigned-64,
        min0::little-unsigned-64,
        min1::little-unsigned-64
      >>
  end

  @doc """
  Build instruction data for removing liquidity from N-token pool.

  ## Arguments
    - lp_amount: Amount of LP tokens to burn
    - mins: List of minimum amounts for each token

  ## Returns
  Binary instruction data
  """
  @spec remove_liquidity_n(non_neg_integer(), [non_neg_integer()]) :: binary()
  def remove_liquidity_n(lp_amount, mins) when length(mins) <= 8 do
    mins_binary =
      mins
      |> Enum.map(fn min -> <<min::little-unsigned-64>> end)
      |> Enum.join()

    Constants.discriminator(:remliqn) <> <<lp_amount::little-unsigned-64>> <> mins_binary
  end

  # ============================================================================
  # Admin Instructions
  # ============================================================================

  @doc """
  Build instruction data for pausing/unpausing a pool.

  ## Arguments
    - paused: true to pause, false to unpause

  ## Returns
  Binary instruction data (9 bytes)
  """
  @spec set_pause(boolean()) :: binary()
  def set_pause(paused) do
    pause_byte = if paused, do: 1, else: 0
    Constants.discriminator(:setpause) <> <<pause_byte::8>>
  end

  @doc """
  Build instruction data for updating the swap fee.

  ## Arguments
    - fee_bps: New fee in basis points

  ## Returns
  Binary instruction data (16 bytes)
  """
  @spec update_fee(Types.update_fee_args()) :: binary()
  def update_fee(%{fee_bps: fee_bps}) do
    Constants.discriminator(:updfee) <> <<fee_bps::little-unsigned-64>>
  end

  @doc """
  Build instruction data for withdrawing admin fees.

  Returns just the discriminator (8 bytes).
  """
  @spec withdraw_fee() :: binary()
  def withdraw_fee do
    Constants.discriminator(:wdrawfee)
  end

  @doc """
  Build instruction data for committing an amp change (timelock).

  ## Arguments
    - target_amp: Target amplification coefficient

  ## Returns
  Binary instruction data (16 bytes)
  """
  @spec commit_amp(Types.commit_amp_args()) :: binary()
  def commit_amp(%{target_amp: target_amp}) do
    Constants.discriminator(:commitamp) <> <<target_amp::little-unsigned-64>>
  end

  @doc """
  Build instruction data for starting amp ramping.

  ## Arguments
    - target_amp: Target amplification coefficient
    - duration: Duration in seconds

  ## Returns
  Binary instruction data (24 bytes)
  """
  @spec ramp_amp(Types.ramp_amp_args()) :: binary()
  def ramp_amp(%{target_amp: target_amp, duration: duration}) do
    Constants.discriminator(:rampamp) <>
      <<target_amp::little-unsigned-64, duration::little-signed-64>>
  end

  @doc """
  Build instruction data for stopping amp ramping.

  Returns just the discriminator (8 bytes).
  """
  @spec stop_ramp() :: binary()
  def stop_ramp do
    Constants.discriminator(:stopramp)
  end

  @doc """
  Build instruction data for initiating authority transfer.

  Returns just the discriminator (8 bytes).
  """
  @spec init_auth_transfer() :: binary()
  def init_auth_transfer do
    Constants.discriminator(:initauth)
  end

  @doc """
  Build instruction data for completing authority transfer.

  Returns just the discriminator (8 bytes).
  """
  @spec complete_auth_transfer() :: binary()
  def complete_auth_transfer do
    Constants.discriminator(:complauth)
  end

  @doc """
  Build instruction data for cancelling authority transfer.

  Returns just the discriminator (8 bytes).
  """
  @spec cancel_auth_transfer() :: binary()
  def cancel_auth_transfer do
    Constants.discriminator(:cancelauth)
  end

  # ============================================================================
  # Farming Instructions
  # ============================================================================

  @doc """
  Build instruction data for creating a farming period.

  ## Arguments
    - reward_rate: Reward tokens per second
    - start_time: Start timestamp
    - end_time: End timestamp

  ## Returns
  Binary instruction data (32 bytes)
  """
  @spec create_farm(Types.create_farm_args()) :: binary()
  def create_farm(%{reward_rate: reward_rate, start_time: start_time, end_time: end_time}) do
    Constants.discriminator(:createfarm) <>
      <<
        reward_rate::little-unsigned-64,
        start_time::little-signed-64,
        end_time::little-signed-64
      >>
  end

  @doc """
  Build instruction data for staking LP tokens.

  ## Arguments
    - amount: Amount of LP tokens to stake

  ## Returns
  Binary instruction data (16 bytes)
  """
  @spec stake_lp(Types.stake_args()) :: binary()
  def stake_lp(%{amount: amount}) do
    Constants.discriminator(:stakelp) <> <<amount::little-unsigned-64>>
  end

  @doc """
  Build instruction data for unstaking LP tokens.

  ## Arguments
    - amount: Amount of LP tokens to unstake

  ## Returns
  Binary instruction data (16 bytes)
  """
  @spec unstake_lp(Types.stake_args()) :: binary()
  def unstake_lp(%{amount: amount}) do
    Constants.discriminator(:unstakelp) <> <<amount::little-unsigned-64>>
  end

  @doc """
  Build instruction data for claiming farming rewards.

  Returns just the discriminator (8 bytes).
  """
  @spec claim_farm() :: binary()
  def claim_farm do
    Constants.discriminator(:claimfarm)
  end

  @doc """
  Build instruction data for locking LP tokens.

  ## Arguments
    - amount: Amount of LP tokens to lock
    - duration: Lock duration in seconds

  ## Returns
  Binary instruction data (24 bytes)
  """
  @spec lock_lp(Types.lock_lp_args()) :: binary()
  def lock_lp(%{amount: amount, duration: duration}) do
    Constants.discriminator(:locklp) <>
      <<amount::little-unsigned-64, duration::little-signed-64>>
  end

  @doc """
  Build instruction data for claiming unlocked LP tokens.

  Returns just the discriminator (8 bytes).
  """
  @spec claim_unlocked_lp() :: binary()
  def claim_unlocked_lp do
    Constants.discriminator(:claimulp)
  end

  # ============================================================================
  # Lottery Instructions
  # ============================================================================

  @doc """
  Build instruction data for creating a lottery.

  ## Arguments
    - ticket_price: LP tokens required per ticket
    - end_time: Lottery end timestamp

  ## Returns
  Binary instruction data (24 bytes)
  """
  @spec create_lottery(Types.create_lottery_args()) :: binary()
  def create_lottery(%{ticket_price: ticket_price, end_time: end_time}) do
    Constants.discriminator(:createlot) <>
      <<ticket_price::little-unsigned-64, end_time::little-signed-64>>
  end

  @doc """
  Build instruction data for entering a lottery.

  ## Arguments
    - ticket_count: Number of tickets to purchase

  ## Returns
  Binary instruction data (16 bytes)
  """
  @spec enter_lottery(Types.enter_lottery_args()) :: binary()
  def enter_lottery(%{ticket_count: ticket_count}) do
    Constants.discriminator(:enterlot) <> <<ticket_count::little-unsigned-64>>
  end

  @doc """
  Build instruction data for drawing a lottery winner.

  ## Arguments
    - random_seed: Random seed for winner selection

  ## Returns
  Binary instruction data (16 bytes)
  """
  @spec draw_lottery(Types.draw_lottery_args()) :: binary()
  def draw_lottery(%{random_seed: random_seed}) do
    Constants.discriminator(:drawlot) <> <<random_seed::little-unsigned-64>>
  end

  @doc """
  Build instruction data for claiming lottery prize.

  Returns just the discriminator (8 bytes).
  """
  @spec claim_lottery() :: binary()
  def claim_lottery do
    Constants.discriminator(:claimlot)
  end

  # ============================================================================
  # Oracle Instructions
  # ============================================================================

  @doc """
  Build instruction data for getting TWAP price.

  ## Arguments
    - window: TWAP window (0=1h, 1=4h, 2=24h, 3=7d)

  ## Returns
  Binary instruction data (9 bytes)
  """
  @spec get_twap(non_neg_integer()) :: binary()
  def get_twap(window) when window in 0..3 do
    Constants.discriminator(:gettwap) <> <<window::8>>
  end

  # ============================================================================
  # Circuit Breaker Instructions
  # ============================================================================

  @doc """
  Build instruction data for setting circuit breaker parameters.

  ## Arguments
    - price_dev_bps: Price deviation threshold in basis points
    - volume_mult: Volume multiplier threshold

  ## Returns
  Binary instruction data
  """
  @spec set_circuit_breaker(non_neg_integer(), non_neg_integer()) :: binary()
  def set_circuit_breaker(price_dev_bps, volume_mult) do
    Constants.discriminator(:setcb) <>
      <<price_dev_bps::little-unsigned-64, volume_mult::little-unsigned-64>>
  end

  @doc """
  Build instruction data for resetting circuit breaker.

  Returns just the discriminator (8 bytes).
  """
  @spec reset_circuit_breaker() :: binary()
  def reset_circuit_breaker do
    Constants.discriminator(:resetcb)
  end

  # ============================================================================
  # Rate Limiting Instructions
  # ============================================================================

  @doc """
  Build instruction data for setting rate limits.

  ## Arguments
    - max_volume: Maximum volume per epoch (0 = unlimited)
    - max_swaps: Maximum swaps per epoch (0 = unlimited)

  ## Returns
  Binary instruction data
  """
  @spec set_rate_limit(non_neg_integer(), non_neg_integer()) :: binary()
  def set_rate_limit(max_volume, max_swaps) do
    Constants.discriminator(:setrl) <>
      <<max_volume::little-unsigned-64, max_swaps::little-unsigned-32>>
  end

  # ============================================================================
  # Governance Instructions
  # ============================================================================

  @doc """
  Build instruction data for creating a governance proposal.

  ## Arguments
    - prop_type: Proposal type (1=fee, 2=amp, 3=admin_fee, 4=pause, 5=authority)
    - value: New value for the parameter
    - description: Short description (max 64 bytes)

  ## Returns
  Binary instruction data
  """
  @spec gov_propose(non_neg_integer(), non_neg_integer(), String.t()) :: binary()
  def gov_propose(prop_type, value, description) do
    desc_bytes =
      description
      |> String.slice(0, 64)
      |> String.pad_trailing(64, <<0>>)

    Constants.discriminator(:govprop) <>
      <<prop_type::8, value::little-unsigned-64>> <>
      desc_bytes
  end

  @doc """
  Build instruction data for voting on a proposal.

  ## Arguments
    - vote_for: true to vote for, false to vote against

  ## Returns
  Binary instruction data (9 bytes)
  """
  @spec gov_vote(boolean()) :: binary()
  def gov_vote(vote_for) do
    vote_byte = if vote_for, do: 1, else: 0
    Constants.discriminator(:govvote) <> <<vote_byte::8>>
  end

  @doc """
  Build instruction data for executing a passed proposal.

  Returns just the discriminator (8 bytes).
  """
  @spec gov_execute() :: binary()
  def gov_execute do
    Constants.discriminator(:govexec)
  end

  @doc """
  Build instruction data for cancelling a proposal.

  Returns just the discriminator (8 bytes).
  """
  @spec gov_cancel() :: binary()
  def gov_cancel do
    Constants.discriminator(:govcncl)
  end
end
