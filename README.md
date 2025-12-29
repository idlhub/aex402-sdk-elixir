# AeX402 Elixir SDK

Elixir SDK for the AeX402 Hybrid AMM on Solana.

## Installation

Add `aex402` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aex402, "~> 0.1.0"},
    {:b58, "~> 1.0"}
  ]
end
```

## Quick Start

```elixir
# Parse a pool account from binary data
{:ok, pool} = AeX402.Accounts.parse_pool(account_data)

# Simulate a swap
{:ok, amount_out} = AeX402.Math.simulate_swap(
  pool.bal0,
  pool.bal1,
  100_000_000,  # amount in
  pool.amp,
  pool.fee_bps
)

# Calculate slippage tolerance
min_out = AeX402.Math.calc_min_output(amount_out, 100)  # 1% slippage

# Build swap instruction data
instruction_data = AeX402.Instructions.swap_t0_t1(%{
  amount_in: 100_000_000,
  min_out: min_out
})

# Derive pool PDA
{:ok, mint0} = AeX402.Accounts.base58_to_pubkey("...")
{:ok, mint1} = AeX402.Accounts.base58_to_pubkey("...")
{:ok, {pool_address, bump}} = AeX402.PDA.derive_pool(mint0, mint1)
```

## Modules

### `AeX402.Constants`

Program constants including:
- Program ID
- Instruction discriminators
- Account discriminators
- Error codes and messages

```elixir
AeX402.Constants.program_id()
# => "3AMM53MsJZy2Jvf7PeHHga3bsGjWV4TSaYz29WUtcdje"

AeX402.Constants.discriminator(:swap)
# => <<0xC8, 0x87, 0x75, 0xE1, 0x91, 0x9E, 0xC6, 0x82>>

AeX402.Constants.error_message(6004)
# => "Slippage exceeded"
```

### `AeX402.Types`

Type definitions for accounts and instruction arguments:
- `pool` - 2-token pool state
- `npool` - N-token pool state (2-8 tokens)
- `farm` - Farming state
- `user_farm` - User's farming position
- `lottery` - Lottery state
- `lottery_entry` - User's lottery entry
- Instruction argument types

### `AeX402.Accounts`

Parse on-chain account data using binary pattern matching:

```elixir
{:ok, pool} = AeX402.Accounts.parse_pool(data)
{:ok, npool} = AeX402.Accounts.parse_npool(data)
{:ok, farm} = AeX402.Accounts.parse_farm(data)
{:ok, user_farm} = AeX402.Accounts.parse_user_farm(data)
{:ok, lottery} = AeX402.Accounts.parse_lottery(data)
```

### `AeX402.Instructions`

Build instruction data for all program handlers:

```elixir
# Pool creation
data = AeX402.Instructions.create_pool(%{amp: 100, bump: 255})

# Swaps
data = AeX402.Instructions.swap_t0_t1(%{amount_in: 1000, min_out: 990})
data = AeX402.Instructions.swap_n(%{from_idx: 0, to_idx: 2, amount_in: 1000, min_out: 990})

# Liquidity
data = AeX402.Instructions.add_liquidity(%{amount0: 1000, amount1: 1000, min_lp: 900})
data = AeX402.Instructions.remove_liquidity(%{lp_amount: 500, min0: 400, min1: 400})

# Admin
data = AeX402.Instructions.set_pause(true)
data = AeX402.Instructions.update_fee(%{fee_bps: 50})

# Farming
data = AeX402.Instructions.stake_lp(%{amount: 1000})
data = AeX402.Instructions.claim_farm()

# Lottery
data = AeX402.Instructions.enter_lottery(%{ticket_count: 5})

# Governance
data = AeX402.Instructions.gov_vote(true)  # vote for
```

### `AeX402.Math`

StableSwap math using Newton's method:

```elixir
# Calculate invariant D
{:ok, d} = AeX402.Math.calc_d(1_000_000_000, 1_000_000_000, 100)

# Simulate swap
{:ok, amount_out} = AeX402.Math.simulate_swap(
  1_000_000_000,  # bal_in
  1_000_000_000,  # bal_out
  100_000_000,    # amount_in
  100,            # amp
  30              # fee_bps
)

# Calculate LP tokens for deposit
{:ok, lp_tokens} = AeX402.Math.calc_lp_tokens(
  100_000_000,    # amt0
  100_000_000,    # amt1
  1_000_000_000,  # bal0
  1_000_000_000,  # bal1
  1_000_000_000,  # lp_supply
  100             # amp
)

# Calculate tokens for LP burn
{:ok, %{amount0: amt0, amount1: amt1}} = AeX402.Math.calc_withdraw(
  100_000_000,    # lp_amount
  1_000_000_000,  # bal0
  1_000_000_000,  # bal1
  1_000_000_000   # lp_supply
)

# N-token pool math
{:ok, d} = AeX402.Math.calc_d_n([1e9, 1e9, 1e9], 100)
{:ok, amount_out} = AeX402.Math.simulate_swap_n(
  [1e9, 1e9, 1e9],  # balances
  0,                 # from_idx
  2,                 # to_idx
  1e8,               # amount_in
  100,               # amp
  30                 # fee_bps
)
```

### `AeX402.PDA`

Derive Program Derived Addresses:

```elixir
{:ok, {pool, bump}} = AeX402.PDA.derive_pool(mint0, mint1)
{:ok, {vault, bump}} = AeX402.PDA.derive_vault(pool, mint)
{:ok, {lp_mint, bump}} = AeX402.PDA.derive_lp_mint(pool)
{:ok, {farm, bump}} = AeX402.PDA.derive_farm(pool)
{:ok, {user_farm, bump}} = AeX402.PDA.derive_user_farm(farm, user)
{:ok, {lottery, bump}} = AeX402.PDA.derive_lottery(pool)
```

## Program Features

### Core AMM
- **Dual Pool Types**: Stable pools (high amp, pegged assets) and volatile pools (amp=1)
- **N-Token Pools**: Support for 2-8 token pools
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

## Constants

```elixir
AeX402.Constants.min_amp()       # => 1
AeX402.Constants.max_amp()       # => 100_000
AeX402.Constants.default_fee_bps() # => 30 (0.3%)
AeX402.Constants.max_tokens()    # => 8
AeX402.Constants.newton_iterations() # => 255
```

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 6000 | paused | Pool is paused |
| 6001 | invalid_amp | Invalid amplification coefficient |
| 6002 | math_overflow | Math overflow |
| 6003 | zero_amount | Zero amount |
| 6004 | slippage_exceeded | Slippage exceeded |
| 6005 | invalid_invariant | Invalid invariant or PDA mismatch |
| 6006 | insufficient_liquidity | Insufficient liquidity |
| ... | ... | See `AeX402.Constants.error_codes()` |

## License

MIT
