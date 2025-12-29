# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Elixir SDK for the AeX402 Hybrid AMM on Solana. Provides instruction builders, account parsers, and StableSwap math for off-chain simulation.

**Program ID (Devnet):** `3AMM53MsJZy2Jvf7PeHHga3bsGjWV4TSaYz29WUtcdje`

## Build Commands

```bash
# Install dependencies
mix deps.get

# Compile
mix compile

# Run tests
mix test

# Generate docs
mix docs

# Format code
mix format

# Check formatting
mix format --check-formatted
```

## Architecture

```
lib/
├── aex402.ex              # Main module, re-exports submodules
├── aex402/
│   ├── constants.ex       # Program ID, discriminators, error codes
│   ├── types.ex           # Structs for Pool, NPool, Farm, etc.
│   ├── accounts.ex        # Binary parsing of on-chain accounts
│   ├── instructions.ex    # Instruction data builders (55+ handlers)
│   ├── math.ex            # StableSwap math (Newton's method)
│   └── pda.ex             # Program Derived Address derivation
```

## Key Patterns

### Result Tuples
All functions return `{:ok, result}` or `{:error, reason}`:
```elixir
{:ok, d} = AeX402.Math.calc_d(bal0, bal1, amp)
{:error, :failed_to_converge} = AeX402.Math.calc_d(0, 0, 0)
```

### Binary Pattern Matching
Account parsing uses Elixir's binary pattern matching:
```elixir
def parse_pool(<<disc::binary-size(8), authority::binary-size(32), ...>>) do
  # ...
end
```

### Newton's Method Iteration
Math functions use tail-recursive iteration (max 255 iterations):
```elixir
defp calc_d_iterate(s, ann, x, y, d, remaining) when remaining > 0 do
  # Calculate next d
  calc_d_iterate(s, ann, x, y, d_new, remaining - 1)
end
```

## Module Responsibilities

| Module | Purpose |
|--------|---------|
| `Constants` | Program ID, discriminators (8-byte instruction identifiers), error codes |
| `Types` | Elixir structs matching on-chain Borsh layouts |
| `Accounts` | Deserialize binary account data to structs |
| `Instructions` | Serialize instruction args to binary (discriminator + args) |
| `Math` | Off-chain swap simulation, LP calculations, price impact |
| `PDA` | SHA256-based Program Derived Address computation |

## Testing

```bash
# Run all tests
mix test

# Run specific test file
mix test test/math_test.exs

# Run with coverage
mix test --cover
```

## Dependencies

- `b58` - Base58 encoding/decoding for Solana addresses
- `ex_doc` - Documentation generation (dev only)

## Common Tasks

### Simulate a Swap
```elixir
{:ok, amount_out} = AeX402.Math.simulate_swap(bal_in, bal_out, amount_in, amp, fee_bps)
```

### Build Instruction Data
```elixir
data = AeX402.Instructions.swap_t0_t1(%{amount_in: 1000, min_out: 990})
# Returns binary: <<discriminator::64, amount_in::64-little, min_out::64-little>>
```

### Parse Account
```elixir
{:ok, pool} = AeX402.Accounts.parse_pool(account_data)
# Returns %AeX402.Types.Pool{...}
```

## Error Handling

Error codes 6000-6030 map to specific failures:
```elixir
AeX402.Constants.error_message(6004)  # => "Slippage exceeded"
```

## Conventions

- All amounts are in native token units (lamports for SOL, smallest unit for SPL)
- Amplification coefficient (amp) range: 1-100,000
- Fee in basis points (bps): 100 bps = 1%
- Newton's method convergence threshold: 1 unit
