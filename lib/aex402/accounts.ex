defmodule AeX402.Accounts do
  @moduledoc """
  Account parsing for AeX402 AMM program.

  Uses Elixir binary pattern matching to parse on-chain account data
  into structured types. All parsers validate the account discriminator
  before parsing.
  """

  alias AeX402.Constants
  alias AeX402.Types

  @pubkey_size 32
  @candle_size 12
  @bloom_size 128
  @max_tokens 8

  # ============================================================================
  # Pool Parsing (1024 bytes)
  # ============================================================================

  @doc """
  Parse a 2-token Pool account from binary data.

  Returns `{:ok, pool}` if parsing succeeds, `{:error, reason}` otherwise.

  ## Example

      {:ok, pool} = AeX402.Accounts.parse_pool(account_data)
      pool.bal0  # Token 0 balance
  """
  @spec parse_pool(binary()) :: {:ok, Types.pool()} | {:error, atom()}
  def parse_pool(data) when byte_size(data) < 900 do
    {:error, :insufficient_data}
  end

  def parse_pool(<<
        disc::binary-size(8),
        authority::binary-size(32),
        mint0::binary-size(32),
        mint1::binary-size(32),
        vault0::binary-size(32),
        vault1::binary-size(32),
        lp_mint::binary-size(32),
        amp::little-unsigned-64,
        init_amp::little-unsigned-64,
        target_amp::little-unsigned-64,
        ramp_start::little-signed-64,
        ramp_stop::little-signed-64,
        fee_bps::little-unsigned-64,
        admin_fee_pct::little-unsigned-64,
        bal0::little-unsigned-64,
        bal1::little-unsigned-64,
        lp_supply::little-unsigned-64,
        admin_fee0::little-unsigned-64,
        admin_fee1::little-unsigned-64,
        vol0::little-unsigned-64,
        vol1::little-unsigned-64,
        paused::8,
        bump::8,
        vault0_bump::8,
        vault1_bump::8,
        lp_mint_bump::8,
        _pad::binary-size(3),
        pending_auth::binary-size(32),
        auth_time::little-signed-64,
        pending_amp::little-unsigned-64,
        amp_time::little-signed-64,
        trade_count::little-unsigned-64,
        trade_sum::little-unsigned-64,
        max_price::little-unsigned-32,
        min_price::little-unsigned-32,
        hour_slot::little-unsigned-32,
        day_slot::little-unsigned-32,
        hour_idx::8,
        day_idx::8,
        _pad2::binary-size(6),
        bloom::binary-size(128),
        rest::binary
      >>) do
    expected_disc = Constants.account_discriminator(:pool)

    if disc != expected_disc do
      {:error, :invalid_discriminator}
    else
      # Parse 24 hourly candles (24 * 12 = 288 bytes)
      {hourly_candles, rest} = parse_candles(rest, 24)

      # Parse 7 daily candles (7 * 12 = 84 bytes)
      {daily_candles, _rest} = parse_candles(rest, 7)

      pool = %{
        discriminator: disc,
        authority: authority,
        mint0: mint0,
        mint1: mint1,
        vault0: vault0,
        vault1: vault1,
        lp_mint: lp_mint,
        amp: amp,
        init_amp: init_amp,
        target_amp: target_amp,
        ramp_start: ramp_start,
        ramp_stop: ramp_stop,
        fee_bps: fee_bps,
        admin_fee_pct: admin_fee_pct,
        bal0: bal0,
        bal1: bal1,
        lp_supply: lp_supply,
        admin_fee0: admin_fee0,
        admin_fee1: admin_fee1,
        vol0: vol0,
        vol1: vol1,
        paused: paused != 0,
        bump: bump,
        vault0_bump: vault0_bump,
        vault1_bump: vault1_bump,
        lp_mint_bump: lp_mint_bump,
        pending_auth: pending_auth,
        auth_time: auth_time,
        pending_amp: pending_amp,
        amp_time: amp_time,
        trade_count: trade_count,
        trade_sum: trade_sum,
        max_price: max_price,
        min_price: min_price,
        hour_slot: hour_slot,
        day_slot: day_slot,
        hour_idx: hour_idx,
        day_idx: day_idx,
        bloom: bloom,
        hourly_candles: hourly_candles,
        daily_candles: daily_candles
      }

      {:ok, pool}
    end
  end

  def parse_pool(_), do: {:error, :invalid_format}

  # ============================================================================
  # NPool Parsing (2048 bytes)
  # ============================================================================

  @doc """
  Parse an N-token Pool account from binary data.

  Returns `{:ok, npool}` if parsing succeeds, `{:error, reason}` otherwise.
  """
  @spec parse_npool(binary()) :: {:ok, Types.npool()} | {:error, atom()}
  def parse_npool(data) when byte_size(data) < 800 do
    {:error, :insufficient_data}
  end

  def parse_npool(<<
        disc::binary-size(8),
        authority::binary-size(32),
        n_tokens::8,
        paused::8,
        bump::8,
        _pad::binary-size(5),
        amp::little-unsigned-64,
        fee_bps::little-unsigned-64,
        admin_fee_pct::little-unsigned-64,
        lp_supply::little-unsigned-64,
        rest::binary
      >>) do
    expected_disc = Constants.account_discriminator(:npool)

    if disc != expected_disc do
      {:error, :invalid_discriminator}
    else
      # Parse 8 mints (8 * 32 = 256 bytes)
      {mints, rest} = parse_pubkeys(rest, @max_tokens)

      # Parse 8 vaults (8 * 32 = 256 bytes)
      {vaults, rest} = parse_pubkeys(rest, @max_tokens)

      # Parse LP mint
      <<lp_mint::binary-size(32), rest::binary>> = rest

      # Parse 8 balances (8 * 8 = 64 bytes)
      {balances, rest} = parse_u64s(rest, @max_tokens)

      # Parse 8 admin fees (8 * 8 = 64 bytes)
      {admin_fees, rest} = parse_u64s(rest, @max_tokens)

      # Parse analytics fields
      <<
        total_volume::little-unsigned-64,
        trade_count::little-unsigned-64,
        last_trade_slot::little-unsigned-64,
        _rest::binary
      >> = rest

      npool = %{
        discriminator: disc,
        authority: authority,
        n_tokens: n_tokens,
        paused: paused != 0,
        bump: bump,
        amp: amp,
        fee_bps: fee_bps,
        admin_fee_pct: admin_fee_pct,
        lp_supply: lp_supply,
        mints: mints,
        vaults: vaults,
        lp_mint: lp_mint,
        balances: balances,
        admin_fees: admin_fees,
        total_volume: total_volume,
        trade_count: trade_count,
        last_trade_slot: last_trade_slot
      }

      {:ok, npool}
    end
  end

  def parse_npool(_), do: {:error, :invalid_format}

  # ============================================================================
  # Farm Parsing
  # ============================================================================

  @doc """
  Parse a Farm account from binary data.

  Returns `{:ok, farm}` if parsing succeeds, `{:error, reason}` otherwise.
  """
  @spec parse_farm(binary()) :: {:ok, Types.farm()} | {:error, atom()}
  def parse_farm(data) when byte_size(data) < 120 do
    {:error, :insufficient_data}
  end

  def parse_farm(<<
        disc::binary-size(8),
        pool::binary-size(32),
        reward_mint::binary-size(32),
        reward_rate::little-unsigned-64,
        start_time::little-signed-64,
        end_time::little-signed-64,
        total_staked::little-unsigned-64,
        acc_reward::little-unsigned-64,
        last_update::little-signed-64,
        _rest::binary
      >>) do
    expected_disc = Constants.account_discriminator(:farm)

    if disc != expected_disc do
      {:error, :invalid_discriminator}
    else
      farm = %{
        discriminator: disc,
        pool: pool,
        reward_mint: reward_mint,
        reward_rate: reward_rate,
        start_time: start_time,
        end_time: end_time,
        total_staked: total_staked,
        acc_reward: acc_reward,
        last_update: last_update
      }

      {:ok, farm}
    end
  end

  def parse_farm(_), do: {:error, :invalid_format}

  # ============================================================================
  # UserFarm Parsing
  # ============================================================================

  @doc """
  Parse a UserFarm account from binary data.

  Returns `{:ok, user_farm}` if parsing succeeds, `{:error, reason}` otherwise.
  """
  @spec parse_user_farm(binary()) :: {:ok, Types.user_farm()} | {:error, atom()}
  def parse_user_farm(data) when byte_size(data) < 96 do
    {:error, :insufficient_data}
  end

  def parse_user_farm(<<
        disc::binary-size(8),
        owner::binary-size(32),
        farm::binary-size(32),
        staked::little-unsigned-64,
        reward_debt::little-unsigned-64,
        lock_end::little-signed-64,
        _rest::binary
      >>) do
    expected_disc = Constants.account_discriminator(:ufarm)

    if disc != expected_disc do
      {:error, :invalid_discriminator}
    else
      user_farm = %{
        discriminator: disc,
        owner: owner,
        farm: farm,
        staked: staked,
        reward_debt: reward_debt,
        lock_end: lock_end
      }

      {:ok, user_farm}
    end
  end

  def parse_user_farm(_), do: {:error, :invalid_format}

  # ============================================================================
  # Lottery Parsing
  # ============================================================================

  @doc """
  Parse a Lottery account from binary data.

  Returns `{:ok, lottery}` if parsing succeeds, `{:error, reason}` otherwise.
  """
  @spec parse_lottery(binary()) :: {:ok, Types.lottery()} | {:error, atom()}
  def parse_lottery(data) when byte_size(data) < 152 do
    {:error, :insufficient_data}
  end

  def parse_lottery(<<
        disc::binary-size(8),
        pool::binary-size(32),
        authority::binary-size(32),
        lottery_vault::binary-size(32),
        ticket_price::little-unsigned-64,
        total_tickets::little-unsigned-64,
        prize_pool::little-unsigned-64,
        end_time::little-signed-64,
        winning_ticket::little-unsigned-64,
        drawn::8,
        claimed::8,
        _pad::binary-size(6),
        _rest::binary
      >>) do
    expected_disc = Constants.account_discriminator(:lottery)

    if disc != expected_disc do
      {:error, :invalid_discriminator}
    else
      lottery = %{
        discriminator: disc,
        pool: pool,
        authority: authority,
        lottery_vault: lottery_vault,
        ticket_price: ticket_price,
        total_tickets: total_tickets,
        prize_pool: prize_pool,
        end_time: end_time,
        winning_ticket: winning_ticket,
        drawn: drawn != 0,
        claimed: claimed != 0
      }

      {:ok, lottery}
    end
  end

  def parse_lottery(_), do: {:error, :invalid_format}

  # ============================================================================
  # LotteryEntry Parsing
  # ============================================================================

  @doc """
  Parse a LotteryEntry account from binary data.

  Returns `{:ok, lottery_entry}` if parsing succeeds, `{:error, reason}` otherwise.
  """
  @spec parse_lottery_entry(binary()) :: {:ok, Types.lottery_entry()} | {:error, atom()}
  def parse_lottery_entry(data) when byte_size(data) < 88 do
    {:error, :insufficient_data}
  end

  def parse_lottery_entry(<<
        disc::binary-size(8),
        owner::binary-size(32),
        lottery::binary-size(32),
        ticket_start::little-unsigned-64,
        ticket_count::little-unsigned-64,
        _rest::binary
      >>) do
    expected_disc = Constants.account_discriminator(:lotentry)

    if disc != expected_disc do
      {:error, :invalid_discriminator}
    else
      entry = %{
        discriminator: disc,
        owner: owner,
        lottery: lottery,
        ticket_start: ticket_start,
        ticket_count: ticket_count
      }

      {:ok, entry}
    end
  end

  def parse_lottery_entry(_), do: {:error, :invalid_format}

  # ============================================================================
  # Helper Functions
  # ============================================================================

  @doc """
  Parse a single candle from binary data.
  """
  @spec parse_candle(binary()) :: {Types.candle(), binary()}
  def parse_candle(<<
        open::little-unsigned-32,
        high_d::little-unsigned-16,
        low_d::little-unsigned-16,
        close_d::little-signed-16,
        volume::little-unsigned-16,
        rest::binary
      >>) do
    candle = %{
      open: open,
      high_d: high_d,
      low_d: low_d,
      close_d: close_d,
      volume: volume
    }

    {candle, rest}
  end

  @doc """
  Parse multiple candles from binary data.
  """
  @spec parse_candles(binary(), non_neg_integer()) :: {[Types.candle()], binary()}
  def parse_candles(data, count), do: parse_candles(data, count, [])

  defp parse_candles(data, 0, acc), do: {Enum.reverse(acc), data}

  defp parse_candles(data, count, acc) do
    {candle, rest} = parse_candle(data)
    parse_candles(rest, count - 1, [candle | acc])
  end

  @doc """
  Parse multiple pubkeys (32-byte binaries) from binary data.
  """
  @spec parse_pubkeys(binary(), non_neg_integer()) :: {[binary()], binary()}
  def parse_pubkeys(data, count), do: parse_pubkeys(data, count, [])

  defp parse_pubkeys(data, 0, acc), do: {Enum.reverse(acc), data}

  defp parse_pubkeys(<<pubkey::binary-size(32), rest::binary>>, count, acc) do
    parse_pubkeys(rest, count - 1, [pubkey | acc])
  end

  @doc """
  Parse multiple u64 values from binary data.
  """
  @spec parse_u64s(binary(), non_neg_integer()) :: {[non_neg_integer()], binary()}
  def parse_u64s(data, count), do: parse_u64s(data, count, [])

  defp parse_u64s(data, 0, acc), do: {Enum.reverse(acc), data}

  defp parse_u64s(<<value::little-unsigned-64, rest::binary>>, count, acc) do
    parse_u64s(rest, count - 1, [value | acc])
  end

  # ============================================================================
  # Utility Functions
  # ============================================================================

  @doc """
  Encode a pubkey to Base58 string.
  """
  @spec pubkey_to_base58(binary()) :: String.t()
  def pubkey_to_base58(pubkey) when byte_size(pubkey) == 32 do
    B58.encode58(pubkey)
  end

  @doc """
  Decode a Base58 pubkey to binary.
  """
  @spec base58_to_pubkey(String.t()) :: {:ok, binary()} | {:error, term()}
  def base58_to_pubkey(base58) do
    case B58.decode58(base58) do
      {:ok, bytes} when byte_size(bytes) == 32 -> {:ok, bytes}
      {:ok, _} -> {:error, :invalid_length}
      error -> error
    end
  end

  @doc """
  Check if binary data matches a specific account discriminator.
  """
  @spec has_discriminator?(binary(), atom()) :: boolean()
  def has_discriminator?(<<disc::binary-size(8), _rest::binary>>, account_type) do
    disc == Constants.account_discriminator(account_type)
  end

  def has_discriminator?(_, _), do: false
end
