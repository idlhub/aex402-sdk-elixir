defmodule AeX402.Constants do
  @moduledoc """
  Constants for the AeX402 AMM program.

  Includes program ID, instruction discriminators, account discriminators,
  error codes, and various protocol constants.
  """

  # ============================================================================
  # Program ID
  # ============================================================================

  @doc "AeX402 Program ID (Base58 encoded)"
  def program_id, do: "3AMM53MsJZy2Jvf7PeHHga3bsGjWV4TSaYz29WUtcdje"

  @doc "AeX402 Program ID as raw 32 bytes"
  def program_id_bytes do
    {:ok, bytes} = B58.decode58(program_id())
    bytes
  end

  # ============================================================================
  # Token Programs
  # ============================================================================

  @doc "SPL Token Program ID"
  def token_program_id, do: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"

  @doc "Token-2022 Program ID"
  def token_2022_program_id, do: "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"

  # ============================================================================
  # Pool Constants
  # ============================================================================

  @doc "Minimum amplification coefficient"
  def min_amp, do: 1

  @doc "Maximum amplification coefficient"
  def max_amp, do: 100_000

  @doc "Default swap fee in basis points (30 = 0.3%)"
  def default_fee_bps, do: 30

  @doc "Admin fee percentage (50 = 50% of swap fees go to admin)"
  def admin_fee_pct, do: 50

  @doc "Minimum swap amount"
  def min_swap, do: 100_000

  @doc "Minimum deposit amount"
  def min_deposit, do: 100_000_000

  @doc "Maximum Newton's method iterations"
  def newton_iterations, do: 255

  @doc "Minimum ramp duration in seconds (1 day)"
  def ramp_min_duration, do: 86_400

  @doc "Commit delay for timelocked operations (1 hour)"
  def commit_delay, do: 3_600

  @doc "Migration fee in basis points (1337 = 0.1337%)"
  def migration_fee_bps, do: 1337

  @doc "Maximum tokens in N-token pool"
  def max_tokens, do: 8

  # ============================================================================
  # Analytics Constants
  # ============================================================================

  @doc "Bloom filter size in bytes"
  def bloom_size, do: 128

  @doc "Number of hourly OHLCV candles stored"
  def ohlcv_24h, do: 24

  @doc "Number of daily OHLCV candles stored"
  def ohlcv_7d, do: 7

  @doc "Slots per hour (~400ms slots)"
  def slots_per_hour, do: 9_000

  @doc "Slots per day"
  def slots_per_day, do: 216_000

  # ============================================================================
  # Account Sizes
  # ============================================================================

  @doc "Pool account size in bytes"
  def pool_size, do: 1024

  @doc "NPool account size in bytes"
  def npool_size, do: 2048

  # ============================================================================
  # Instruction Discriminators (8 bytes, little-endian)
  # ============================================================================

  @doc """
  Instruction discriminators as 8-byte binaries.

  Each discriminator uniquely identifies an instruction handler in the program.
  Values are stored in little-endian format.
  """
  def discriminators do
    %{
      # Pool creation
      createpool: <<0xF9, 0xE3, 0xA7, 0xC8, 0xD1, 0xE4, 0xB9, 0xF2>>,
      createpn: <<0x1B, 0x7C, 0xC5, 0xE5, 0xBC, 0x33, 0x9C, 0x27>>,
      initt0v: <<0x9F, 0x4A, 0x3E, 0x0F, 0x0D, 0x3B, 0x8C, 0x5E>>,
      initt1v: <<0x8A, 0x5E, 0x2D, 0x3B, 0x1C, 0x9F, 0x4E, 0x7A>>,
      initlpm: <<0xF2, 0xE7, 0xB8, 0xC5, 0xA3, 0xE9, 0xD1, 0xF4>>,

      # Swaps
      swap: <<0xC8, 0x87, 0x75, 0xE1, 0x91, 0x9E, 0xC6, 0x82>>,
      swapt0t1: <<0x2A, 0x4E, 0xF1, 0xE0, 0xB7, 0xF2, 0x2A, 0x64>>,
      swapt1t0: <<0xC8, 0xC4, 0x75, 0xAC, 0x1B, 0x13, 0x0E, 0x3A>>,
      swapn: <<0xF8, 0xE5, 0xD9, 0xB2, 0xC7, 0xE3, 0xA8, 0xF1>>,
      migt0t1: <<0xD5, 0xE9, 0xB7, 0xC3, 0xA8, 0xF1, 0xE4, 0xD2>>,
      migt1t0: <<0xB8, 0x3D, 0x39, 0x26, 0x94, 0x77, 0x88, 0x18>>,

      # Liquidity
      addliq: <<0xA9, 0xE5, 0xD1, 0xB3, 0xF8, 0xC4, 0xE7, 0xA2>>,
      addliq1: <<0xE6, 0x12, 0x2E, 0x3C, 0x4E, 0x8B, 0xC9, 0x51>>,
      addliqn: <<0xF6, 0xE4, 0xE9, 0xB1, 0xA8, 0xC2, 0xF7, 0xE3>>,
      remliq: <<0x02, 0xF9, 0xC5, 0x75, 0x2C, 0xBC, 0x54, 0x2E>>,
      remliqn: <<0xB4, 0xB1, 0xE9, 0xD7, 0xC5, 0xA2, 0xE8, 0xB3>>,

      # Admin
      setpause: <<0xC9, 0x6E, 0x0D, 0x7E, 0x2B, 0x76, 0x75, 0xE0>>,
      updfee: <<0x4A, 0x1F, 0x9D, 0x7C, 0x5B, 0x2E, 0x3A, 0x8F>>,
      wdrawfee: <<0xF8, 0xE7, 0xB1, 0xC8, 0xA2, 0xD3, 0xE5, 0xF9>>,
      commitamp: <<0xC4, 0xE2, 0xB8, 0xA5, 0xF7, 0xE3, 0xD9, 0xC1>>,
      rampamp: <<0x6A, 0x8E, 0x2D, 0x7B, 0x3F, 0x5E, 0x1C, 0x9A>>,
      stopramp: <<0x53, 0x10, 0xA2, 0x15, 0xBB, 0x27, 0x94, 0x3C>>,
      initauth: <<0xF4, 0xF8, 0xE1, 0xB3, 0xC9, 0xA7, 0xE2, 0xF5>>,
      complauth: <<0xF5, 0xE1, 0xE9, 0xB7, 0xA4, 0xD2, 0xE8, 0xF6>>,
      cancelauth: <<0xF6, 0xE8, 0xB2, 0xD5, 0xC1, 0xA9, 0xE3, 0xF7>>,

      # Farming
      createfarm: <<0x5C, 0x5D, 0x1A, 0x2F, 0x8E, 0x0C, 0x7B, 0x6D>>,
      stakelp: <<0xF7, 0xE2, 0xB9, 0xB3, 0xA7, 0xE1, 0xD4, 0xF8>>,
      unstakelp: <<0xBC, 0xF8, 0x34, 0x4E, 0x65, 0xBF, 0x66, 0x41>>,
      claimfarm: <<0x9B, 0xEC, 0xD6, 0xE0, 0xB7, 0x62, 0x75, 0x07>>,
      locklp: <<0xEC, 0x8C, 0x02, 0x5F, 0x01, 0x83, 0xFB, 0xFE>>,
      claimulp: <<0x1E, 0x8B, 0xE8, 0x5C, 0xF4, 0x93, 0x85, 0xCA>>,

      # Lottery
      createlot: <<0x3C, 0x79, 0x72, 0x65, 0x74, 0x74, 0x6F, 0x6C>>,
      enterlot: <<0xFC, 0x48, 0xEF, 0x4E, 0x3A, 0x38, 0x95, 0xE7>>,
      drawlot: <<0x11, 0xBC, 0x7C, 0x4D, 0x5A, 0x22, 0x61, 0x13>>,
      claimlot: <<0xF4, 0x3C, 0x9F, 0x15, 0x3F, 0x5E, 0x7B, 0x7E>>,

      # Registry
      initreg: <<0x18, 0x07, 0x60, 0xF5, 0xD4, 0xC3, 0xB2, 0xA1>>,
      regpool: <<0x29, 0x18, 0x07, 0xF6, 0xE5, 0xD4, 0xC3, 0xB2>>,
      unregpool: <<0x30, 0x29, 0x18, 0x07, 0xF6, 0xE5, 0xD4, 0xC3>>,

      # Oracle
      gettwap: <<0x01, 0x74, 0x65, 0x67, 0x61, 0x70, 0x77, 0x74>>,

      # Circuit Breaker
      setcb: <<0x01, 0xCB, 0x01, 0xCB, 0x01, 0xCB, 0x01, 0xCB>>,
      resetcb: <<0x02, 0xCB, 0x02, 0xCB, 0x02, 0xCB, 0x02, 0xCB>>,

      # Rate Limiting
      setrl: <<0x6C, 0x72, 0x01, 0x6C, 0x72, 0x01, 0x6C, 0x72>>,

      # Oracle Config
      setoracle: <<0x04, 0x03, 0x02, 0x01, 0x6C, 0x63, 0x72, 0x6F>>,

      # Governance
      govprop: <<0x00, 0x70, 0x6F, 0x72, 0x70, 0x76, 0x6F, 0x67>>,
      govvote: <<0x00, 0x65, 0x74, 0x6F, 0x76, 0x76, 0x6F, 0x67>>,
      govexec: <<0x63, 0x65, 0x78, 0x65, 0x76, 0x6F, 0x67, 0x00>>,
      govcncl: <<0x6C, 0x63, 0x6E, 0x63, 0x76, 0x6F, 0x67, 0x00>>,

      # Orderbook
      initbook: <<0x6B, 0x6F, 0x6F, 0x62, 0x74, 0x69, 0x6E, 0x69>>,
      placeord: <<0x64, 0x72, 0x6F, 0x65, 0x63, 0x61, 0x6C, 0x70>>,
      cancelord: <<0x72, 0x6F, 0x6C, 0x65, 0x63, 0x6E, 0x61, 0x63>>,
      fillord: <<0x65, 0x64, 0x72, 0x6F, 0x6C, 0x6C, 0x69, 0x66>>,

      # Concentrated Liquidity
      initclpl: <<0x01, 0x01, 0x6C, 0x6F, 0x6F, 0x70, 0x6C, 0x63>>,
      clmint: <<0x01, 0x01, 0x74, 0x6E, 0x69, 0x6D, 0x6C, 0x63>>,
      clburn: <<0x01, 0x01, 0x6E, 0x72, 0x75, 0x62, 0x6C, 0x63>>,
      clcollect: <<0x63, 0x65, 0x6C, 0x6C, 0x6F, 0x63, 0x6C, 0x63>>,
      clswap: <<0x01, 0x01, 0x70, 0x61, 0x77, 0x73, 0x6C, 0x63>>,

      # Flash Loans
      flashloan: <<0x61, 0x6F, 0x6C, 0x68, 0x73, 0x61, 0x6C, 0x66>>,
      flashrepy: <<0x70, 0x65, 0x72, 0x68, 0x73, 0x61, 0x6C, 0x66>>,

      # Multi-hop
      multihop: <<0x70, 0x6F, 0x68, 0x69, 0x74, 0x6C, 0x75, 0x6D>>,

      # ML Brain
      initml: <<0x72, 0x62, 0x6C, 0x6D, 0x74, 0x69, 0x6E, 0x69>>,
      cfgml: <<0x61, 0x72, 0x62, 0x6C, 0x6D, 0x67, 0x66, 0x63>>,
      trainml: <<0x00, 0x6C, 0x6D, 0x6E, 0x69, 0x61, 0x72, 0x74>>,
      applyml: <<0x00, 0x6C, 0x6D, 0x79, 0x6C, 0x70, 0x70, 0x61>>,
      logml: <<0x61, 0x74, 0x73, 0x6C, 0x6D, 0x67, 0x6F, 0x6C>>,

      # Transfer Hook
      th_exec: <<0x69, 0x25, 0x65, 0xC5, 0x4B, 0xFB, 0x66, 0x1A>>,
      th_init: <<0x2B, 0x22, 0x0D, 0x31, 0xA7, 0x58, 0xEB, 0xEB>>
    }
  end

  @doc "Get discriminator for a specific instruction"
  def discriminator(instruction) when is_atom(instruction) do
    Map.get(discriminators(), instruction)
  end

  # ============================================================================
  # Account Discriminators (8-byte ASCII strings)
  # ============================================================================

  @doc """
  Account type discriminators.

  Each account type has a unique 8-byte ASCII discriminator at offset 0.
  """
  def account_discriminators do
    %{
      pool: "POOLSWAP",
      npool: "NPOOLSWA",
      farm: "FARMSWAP",
      ufarm: "UFARMSWA",
      lottery: "LOTTERY!",
      lotentry: "LOTENTRY",
      registry: "REGISTRY",
      mlbrain: "MLBRAIN!",
      clpool: "CLPOOL!!",
      clpos: "CLPOSIT!",
      book: "ORDERBOK",
      aifee: "AIFEE!!!",
      thmeta: "THMETA!!",
      govprop: "GOVPROP!",
      govvote: "GOVVOTE!"
    }
  end

  @doc "Get account discriminator for a specific account type"
  def account_discriminator(account_type) when is_atom(account_type) do
    Map.get(account_discriminators(), account_type)
  end

  # ============================================================================
  # Error Codes
  # ============================================================================

  @doc """
  Error codes returned by the program.

  Base error code starts at 6000.
  """
  def error_codes do
    %{
      paused: 6000,
      invalid_amp: 6001,
      math_overflow: 6002,
      zero_amount: 6003,
      slippage_exceeded: 6004,
      invalid_invariant: 6005,
      insufficient_liquidity: 6006,
      vault_mismatch: 6007,
      expired: 6008,
      already_initialized: 6009,
      unauthorized: 6010,
      ramp_constraint: 6011,
      locked: 6012,
      farming_error: 6013,
      invalid_owner: 6014,
      invalid_discriminator: 6015,
      cpi_failed: 6016,
      full: 6017,
      circuit_breaker: 6018,
      oracle_error: 6019,
      rate_limit: 6020,
      governance_error: 6021,
      order_error: 6022,
      tick_error: 6023,
      range_error: 6024,
      flash_error: 6025,
      cooldown: 6026,
      mev_protection: 6027,
      stale_data: 6028,
      bias_error: 6029,
      duration_error: 6030
    }
  end

  @doc "Get error code value for a specific error"
  def error_code(error) when is_atom(error) do
    Map.get(error_codes(), error)
  end

  @doc "Error messages for each error code"
  def error_messages do
    %{
      6000 => "Pool is paused",
      6001 => "Invalid amplification coefficient",
      6002 => "Math overflow",
      6003 => "Zero amount",
      6004 => "Slippage exceeded",
      6005 => "Invalid invariant or PDA mismatch",
      6006 => "Insufficient liquidity",
      6007 => "Vault mismatch",
      6008 => "Expired or ended",
      6009 => "Already initialized",
      6010 => "Unauthorized",
      6011 => "Ramp constraint violated",
      6012 => "Tokens are locked",
      6013 => "Farming error",
      6014 => "Invalid account owner",
      6015 => "Invalid account discriminator",
      6016 => "CPI call failed",
      6017 => "Orderbook/registry is full",
      6018 => "Circuit breaker triggered",
      6019 => "Oracle price validation failed",
      6020 => "Rate limit exceeded",
      6021 => "Governance error",
      6022 => "Orderbook error",
      6023 => "Invalid tick",
      6024 => "Invalid price range",
      6025 => "Flash loan error",
      6026 => "Cooldown period not elapsed",
      6027 => "MEV protection triggered",
      6028 => "Stale data",
      6029 => "ML bias error",
      6030 => "Invalid duration"
    }
  end

  @doc "Get error message for a specific error code"
  def error_message(code) when is_integer(code) do
    Map.get(error_messages(), code, "Unknown error")
  end

  # ============================================================================
  # TWAP Windows
  # ============================================================================

  @doc "TWAP window values"
  def twap_windows do
    %{
      hour_1: 0,
      hour_4: 1,
      hour_24: 2,
      day_7: 3
    }
  end

  # ============================================================================
  # Circuit Breaker Constants
  # ============================================================================

  @doc "Price deviation that triggers circuit breaker (10%)"
  def cb_price_dev_bps, do: 1000

  @doc "Volume multiplier that triggers circuit breaker"
  def cb_volume_mult, do: 10

  @doc "Circuit breaker cooldown in slots (~1 hour)"
  def cb_cooldown_slots, do: 9_000

  @doc "Circuit breaker auto-resume in slots (~6 hours)"
  def cb_auto_resume_slots, do: 54_000

  # ============================================================================
  # Rate Limiting Constants
  # ============================================================================

  @doc "Slots per rate limiting epoch (~5 minutes)"
  def rl_slots_per_epoch, do: 750

  # ============================================================================
  # Governance Constants
  # ============================================================================

  @doc "Governance voting period in slots (~3 days)"
  def gov_vote_slots, do: 518_400

  @doc "Governance timelock in slots (~1 day)"
  def gov_timelock_slots, do: 172_800

  @doc "Governance quorum in basis points (10%)"
  def gov_quorum_bps, do: 1_000

  @doc "Governance threshold in basis points (50%)"
  def gov_threshold_bps, do: 5_000

  # ============================================================================
  # ML Brain Constants
  # ============================================================================

  @doc "ML discount factor (gamma)"
  def ml_gamma, do: 0.9

  @doc "ML learning rate (alpha)"
  def ml_alpha, do: 0.1

  @doc "ML exploration rate (epsilon)"
  def ml_epsilon, do: 0.1

  @doc "Number of ML states"
  def ml_num_states, do: 27

  @doc "Number of ML actions"
  def ml_num_actions, do: 9
end
