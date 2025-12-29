defmodule AeX402.Math do
  @moduledoc """
  StableSwap math for off-chain simulation.

  All calculations use Elixir's native arbitrary precision integers.
  Newton's method is used for iterative calculations (max 255 iterations).

  The AeX402 curve uses the formula:
    A * n^n * sum(x_i) + D = A * D * n^n + D^(n+1) / (n^n * prod(x_i))

  Where:
    - A is the amplification coefficient
    - n is the number of tokens (2 for basic pools)
    - x_i are the token balances
    - D is the invariant
  """

  alias AeX402.Constants

  @newton_iterations Constants.newton_iterations()
  @fee_denominator 10_000

  # ============================================================================
  # Invariant D Calculation
  # ============================================================================

  @doc """
  Calculate invariant D for a 2-token pool using Newton's method.

  The invariant D represents the "virtual balance" of the pool when
  token prices are equal (1:1).

  ## Arguments
    - x: Balance of token 0
    - y: Balance of token 1
    - amp: Amplification coefficient

  ## Returns
    - `{:ok, d}` on success
    - `{:error, :failed_to_converge}` if Newton's method doesn't converge

  ## Example

      {:ok, d} = AeX402.Math.calc_d(1_000_000_000, 1_000_000_000, 100)
  """
  @spec calc_d(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, :failed_to_converge}
  def calc_d(x, y, amp) do
    # Guard against division by zero
    if x == 0 or y == 0 do
      {:ok, 0}
    else
      s = x + y

      if s == 0 do
        {:ok, 0}
      else
        ann = amp * 4  # A * n^n where n=2

        # Guard against zero amp
        if ann == 0 do
          {:error, :zero_amp}
        else
          calc_d_iterate(s, ann, x, y, s, @newton_iterations)
        end
      end
    end
  end

  defp calc_d_iterate(_s, _ann, _x, _y, _d, 0), do: {:error, :failed_to_converge}

  defp calc_d_iterate(s, ann, x, y, d, remaining) do
    # d_p = d^3 / (4 * x * y)
    d_p = div(d * d, x * 2)
    d_p = div(d_p * d, y * 2)

    # d_new = (ann * s + d_p * 2) * d / ((ann - 1) * d + 3 * d_p)
    num = (ann * s + d_p * 2) * d
    denom = (ann - 1) * d + d_p * 3

    # Guard against division by zero
    if denom == 0 do
      {:error, :zero_denom}
    else
      d_new = div(num, denom)

      # Check convergence (within 1 unit)
      if abs(d_new - d) <= 1 do
        {:ok, d_new}
      else
        calc_d_iterate(s, ann, x, y, d_new, remaining - 1)
      end
    end
  end

  # ============================================================================
  # Output Amount Y Calculation
  # ============================================================================

  @doc """
  Calculate output amount y given input x for swap.

  Uses Newton's method to find the new balance of the output token
  that maintains the invariant D.

  ## Arguments
    - x_new: New balance of input token after swap
    - d: Pool invariant
    - amp: Amplification coefficient

  ## Returns
    - `{:ok, y}` on success
    - `{:error, :failed_to_converge}` if Newton's method doesn't converge

  ## Example

      {:ok, d} = AeX402.Math.calc_d(1_000_000_000, 1_000_000_000, 100)
      {:ok, y} = AeX402.Math.calc_y(1_100_000_000, d, 100)
  """
  @spec calc_y(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, :failed_to_converge}
  def calc_y(x_new, d, amp) do
    # Guard against division by zero
    if x_new == 0 do
      {:error, :zero_input}
    else
      ann = amp * 4

      # Guard against zero amp
      if ann == 0 do
        {:error, :zero_amp}
      else
        # c = d^3 / (4 * x_new * ann)
        c = div(d * d, x_new * 2)
        c = div(c * d, ann * 2)

        # b = x_new + d / ann
        b = x_new + div(d, ann)

        calc_y_iterate(c, b, d, d, @newton_iterations)
      end
    end
  end

  defp calc_y_iterate(_c, _b, _d, _y, 0), do: {:error, :failed_to_converge}

  defp calc_y_iterate(c, b, d, y, remaining) do
    # y_new = (y^2 + c) / (2y + b - d)
    num = y * y + c
    denom = 2 * y + b - d

    # Guard against division by zero
    if denom == 0 do
      {:error, :zero_denom}
    else
      y_new = div(num, denom)

      # Check convergence (within 1 unit)
      if abs(y_new - y) <= 1 do
        {:ok, y_new}
      else
        calc_y_iterate(c, b, d, y_new, remaining - 1)
      end
    end
  end

  # ============================================================================
  # Swap Simulation
  # ============================================================================

  @doc """
  Simulate a swap and return the output amount.

  ## Arguments
    - bal_in: Current balance of input token
    - bal_out: Current balance of output token
    - amount_in: Amount to swap
    - amp: Amplification coefficient
    - fee_bps: Fee in basis points (e.g., 30 = 0.3%)

  ## Returns
    - `{:ok, amount_out}` on success
    - `{:error, reason}` on failure

  ## Example

      {:ok, amount_out} = AeX402.Math.simulate_swap(
        1_000_000_000,
        1_000_000_000,
        100_000_000,
        100,
        30
      )
  """
  @spec simulate_swap(
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, non_neg_integer()} | {:error, atom()}
  def simulate_swap(bal_in, bal_out, amount_in, amp, fee_bps) do
    with {:ok, d} <- calc_d(bal_in, bal_out, amp),
         new_bal_in = bal_in + amount_in,
         {:ok, new_bal_out} <- calc_y(new_bal_in, d, amp) do
      amount_out = bal_out - new_bal_out

      # Apply fee
      fee = div(amount_out * fee_bps, @fee_denominator)
      amount_out = amount_out - fee

      {:ok, amount_out}
    end
  end

  @doc """
  Simulate a swap and return both output amount and price impact.

  ## Returns
    - `{:ok, %{amount_out: amount, fee: fee, price_impact: impact}}` on success
    - `{:error, reason}` on failure
  """
  @spec simulate_swap_with_impact(
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, map()} | {:error, atom()}
  def simulate_swap_with_impact(bal_in, bal_out, amount_in, amp, fee_bps) do
    with {:ok, d} <- calc_d(bal_in, bal_out, amp),
         new_bal_in = bal_in + amount_in,
         {:ok, new_bal_out} <- calc_y(new_bal_in, d, amp) do
      gross_amount_out = bal_out - new_bal_out

      # Calculate fee
      fee = div(gross_amount_out * fee_bps, @fee_denominator)
      amount_out = gross_amount_out - fee

      # Calculate price impact
      # Expected output at spot price (no slippage)
      expected_out = div(amount_in * bal_out, bal_in)

      price_impact =
        if expected_out > 0 do
          (expected_out - amount_out) / expected_out
        else
          0.0
        end

      {:ok,
       %{
         amount_out: amount_out,
         fee: fee,
         price_impact: price_impact
       }}
    end
  end

  # ============================================================================
  # LP Token Calculations
  # ============================================================================

  @doc """
  Calculate LP tokens for a deposit to a 2-token pool.

  For initial deposits, LP tokens = sqrt(amount0 * amount1).
  For subsequent deposits, LP tokens = lp_supply * (d1 - d0) / d0.

  ## Arguments
    - amt0: Amount of token 0 to deposit
    - amt1: Amount of token 1 to deposit
    - bal0: Current balance of token 0 in pool
    - bal1: Current balance of token 1 in pool
    - lp_supply: Current LP token supply
    - amp: Amplification coefficient

  ## Returns
    - `{:ok, lp_tokens}` on success
    - `{:error, reason}` on failure

  ## Example

      {:ok, lp_tokens} = AeX402.Math.calc_lp_tokens(
        100_000_000,
        100_000_000,
        1_000_000_000,
        1_000_000_000,
        1_000_000_000,
        100
      )
  """
  @spec calc_lp_tokens(
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, non_neg_integer()} | {:error, atom()}
  def calc_lp_tokens(amt0, amt1, _bal0, _bal1, lp_supply, _amp) when lp_supply == 0 do
    # Initial deposit: LP = sqrt(amt0 * amt1)
    product = amt0 * amt1
    {:ok, isqrt(product)}
  end

  def calc_lp_tokens(amt0, amt1, bal0, bal1, lp_supply, amp) do
    with {:ok, d0} <- calc_d(bal0, bal1, amp),
         {:ok, d1} <- calc_d(bal0 + amt0, bal1 + amt1, amp) do
      if d0 == 0 do
        {:error, :zero_invariant}
      else
        # LP tokens = lp_supply * (d1 - d0) / d0
        lp_tokens = div(lp_supply * (d1 - d0), d0)
        {:ok, lp_tokens}
      end
    end
  end

  @doc """
  Calculate tokens received for LP token burn.

  ## Arguments
    - lp_amount: Amount of LP tokens to burn
    - bal0: Current balance of token 0
    - bal1: Current balance of token 1
    - lp_supply: Current LP token supply

  ## Returns
    - `{:ok, %{amount0: amount0, amount1: amount1}}` on success
    - `{:error, :zero_supply}` if LP supply is zero

  ## Example

      {:ok, %{amount0: amt0, amount1: amt1}} = AeX402.Math.calc_withdraw(
        100_000_000,
        1_000_000_000,
        1_000_000_000,
        1_000_000_000
      )
  """
  @spec calc_withdraw(non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, %{amount0: non_neg_integer(), amount1: non_neg_integer()}} | {:error, atom()}
  def calc_withdraw(_lp_amount, _bal0, _bal1, lp_supply) when lp_supply == 0 do
    {:error, :zero_supply}
  end

  def calc_withdraw(lp_amount, bal0, bal1, lp_supply) do
    amount0 = div(bal0 * lp_amount, lp_supply)
    amount1 = div(bal1 * lp_amount, lp_supply)

    {:ok, %{amount0: amount0, amount1: amount1}}
  end

  # ============================================================================
  # Amp Ramping
  # ============================================================================

  @doc """
  Calculate current amplification coefficient during ramping.

  Amp changes linearly over time from init_amp to target_amp.

  ## Arguments
    - amp: Initial amplification (at ramp start)
    - target_amp: Target amplification
    - ramp_start: Unix timestamp when ramping started
    - ramp_end: Unix timestamp when ramping ends
    - now: Current Unix timestamp

  ## Returns
  The current effective amplification coefficient.

  ## Example

      current_amp = AeX402.Math.get_current_amp(100, 200, 1000, 2000, 1500)
      # => 150 (halfway through ramp)
  """
  @spec get_current_amp(
          non_neg_integer(),
          non_neg_integer(),
          integer(),
          integer(),
          integer()
        ) :: non_neg_integer()
  def get_current_amp(amp, target_amp, ramp_start, ramp_end, now) do
    cond do
      now >= ramp_end or ramp_end == ramp_start ->
        target_amp

      now <= ramp_start ->
        amp

      target_amp > amp ->
        diff = target_amp - amp
        elapsed = now - ramp_start
        duration = ramp_end - ramp_start
        amp + div(diff * elapsed, duration)

      true ->
        diff = amp - target_amp
        elapsed = now - ramp_start
        duration = ramp_end - ramp_start
        amp - div(diff * elapsed, duration)
    end
  end

  # ============================================================================
  # Price Calculations
  # ============================================================================

  @doc """
  Calculate the spot price (token1/token0).

  Uses the derivative of the invariant curve at current balances.

  ## Returns
  Price as a float (token1 per token0).
  """
  @spec calc_spot_price(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, float()} | {:error, atom()}
  def calc_spot_price(bal0, bal1, amp) do
    # Approximate spot price using small swap
    small_amount = max(div(bal0, 10_000), 1)

    with {:ok, d} <- calc_d(bal0, bal1, amp),
         {:ok, new_bal1} <- calc_y(bal0 + small_amount, d, amp) do
      out = bal1 - new_bal1
      price = out / small_amount
      {:ok, price}
    end
  end

  @doc """
  Calculate price impact for a swap.

  ## Returns
  Price impact as a float (0.01 = 1% impact).
  """
  @spec calc_price_impact(
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, float()} | {:error, atom()}
  def calc_price_impact(bal_in, bal_out, amount_in, amp, fee_bps) do
    with {:ok, amount_out} <- simulate_swap(bal_in, bal_out, amount_in, amp, fee_bps) do
      # Spot rate
      spot_rate = bal_out / bal_in

      # Effective rate
      effective_rate = amount_out / amount_in

      # Price impact
      impact = 1.0 - effective_rate / spot_rate
      {:ok, impact}
    end
  end

  @doc """
  Calculate minimum output with slippage tolerance.

  ## Arguments
    - expected_output: Expected output amount
    - slippage_bps: Slippage tolerance in basis points (e.g., 100 = 1%)

  ## Returns
  Minimum acceptable output amount.

  ## Example

      min_out = AeX402.Math.calc_min_output(1_000_000, 100)
      # => 990_000 (1% slippage)
  """
  @spec calc_min_output(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def calc_min_output(expected_output, slippage_bps) do
    div(expected_output * (@fee_denominator - slippage_bps), @fee_denominator)
  end

  # ============================================================================
  # Virtual Price
  # ============================================================================

  @doc """
  Calculate virtual price (LP token value relative to underlying tokens).

  Virtual price = D / LP_supply, scaled by 1e18.

  A virtual price > 1e18 indicates the pool has earned fees.

  ## Returns
    - `{:ok, virtual_price}` scaled by 1e18
    - `{:error, reason}` on failure
  """
  @spec calc_virtual_price(
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, non_neg_integer()} | {:error, atom()}
  def calc_virtual_price(_bal0, _bal1, lp_supply, _amp) when lp_supply == 0 do
    {:error, :zero_supply}
  end

  def calc_virtual_price(bal0, bal1, lp_supply, amp) do
    with {:ok, d} <- calc_d(bal0, bal1, amp) do
      precision = 1_000_000_000_000_000_000  # 1e18
      virtual_price = div(d * precision, lp_supply)
      {:ok, virtual_price}
    end
  end

  # ============================================================================
  # Pool Balance Checks
  # ============================================================================

  @doc """
  Check if a swap would cause excessive pool imbalance.

  ## Arguments
    - bal0: Current balance of token 0
    - bal1: Current balance of token 1
    - max_imbalance_ratio: Maximum allowed ratio (default 10)

  ## Returns
  `true` if pool is balanced, `false` if imbalanced.
  """
  @spec check_imbalance(non_neg_integer(), non_neg_integer(), number()) :: boolean()
  def check_imbalance(bal0, bal1, max_imbalance_ratio \\ 10.0) do
    if bal0 == 0 or bal1 == 0 do
      false
    else
      ratio =
        if bal0 > bal1 do
          bal0 / bal1
        else
          bal1 / bal0
        end

      ratio <= max_imbalance_ratio
    end
  end

  # ============================================================================
  # N-Pool Math
  # ============================================================================

  @doc """
  Calculate invariant D for an N-token pool.

  Uses the same Newton's method approach but generalized for N tokens.

  ## Arguments
    - balances: List of token balances
    - amp: Amplification coefficient

  ## Returns
    - `{:ok, d}` on success
    - `{:error, :failed_to_converge}` if Newton's method doesn't converge
  """
  @spec calc_d_n([non_neg_integer()], non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, :failed_to_converge}
  def calc_d_n(balances, amp) do
    n = length(balances)
    s = Enum.sum(balances)

    if s == 0 do
      {:ok, 0}
    else
      # A * n^n
      ann = amp * :math.pow(n, n) |> trunc()

      calc_d_n_iterate(balances, n, s, ann, s, @newton_iterations)
    end
  end

  defp calc_d_n_iterate(_balances, _n, _s, _ann, d, 0), do: {:error, :failed_to_converge}

  defp calc_d_n_iterate(balances, n, s, ann, d, remaining) do
    # d_p = d^(n+1) / (n^n * prod(balances))
    d_p =
      Enum.reduce(balances, d, fn bal, acc ->
        div(acc * d, bal * n)
      end)

    # d_new = (ann * s + d_p * n) * d / ((ann - 1) * d + (n + 1) * d_p)
    num = (ann * s + d_p * n) * d
    denom = (ann - 1) * d + (n + 1) * d_p
    d_new = div(num, denom)

    if abs(d_new - d) <= 1 do
      {:ok, d_new}
    else
      calc_d_n_iterate(balances, n, s, ann, d_new, remaining - 1)
    end
  end

  @doc """
  Calculate output amount for N-token pool swap.

  ## Arguments
    - balances: List of current token balances
    - from_idx: Index of input token
    - to_idx: Index of output token
    - amount_in: Amount to swap
    - amp: Amplification coefficient
    - fee_bps: Fee in basis points

  ## Returns
    - `{:ok, amount_out}` on success
    - `{:error, reason}` on failure
  """
  @spec simulate_swap_n(
          [non_neg_integer()],
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, non_neg_integer()} | {:error, atom()}
  def simulate_swap_n(balances, from_idx, to_idx, amount_in, amp, fee_bps) do
    with {:ok, d} <- calc_d_n(balances, amp) do
      n = length(balances)
      ann = amp * :math.pow(n, n) |> trunc()

      # Update input balance
      new_balances = List.update_at(balances, from_idx, &(&1 + amount_in))

      # Calculate new output balance using Newton's method
      case calc_y_n(new_balances, to_idx, d, ann, n) do
        {:ok, new_bal_out} ->
          current_bal_out = Enum.at(balances, to_idx)
          amount_out = current_bal_out - new_bal_out

          # Apply fee
          fee = div(amount_out * fee_bps, @fee_denominator)
          amount_out = amount_out - fee

          {:ok, amount_out}

        error ->
          error
      end
    end
  end

  defp calc_y_n(balances, out_idx, d, ann, n) do
    # Sum of all balances except output token
    s_prime =
      balances
      |> Enum.with_index()
      |> Enum.reject(fn {_, idx} -> idx == out_idx end)
      |> Enum.map(fn {bal, _} -> bal end)
      |> Enum.sum()

    # Product term
    c =
      Enum.reduce(Enum.with_index(balances), d, fn {bal, idx}, acc ->
        if idx == out_idx do
          acc
        else
          div(acc * d, bal * n)
        end
      end)

    c = div(c * d, ann * n)

    b = s_prime + div(d, ann)

    calc_y_iterate(c, b, d, d, @newton_iterations)
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  @doc """
  Integer square root using Newton's method.
  """
  @spec isqrt(non_neg_integer()) :: non_neg_integer()
  def isqrt(0), do: 0
  def isqrt(n) when n <= 3, do: 1

  def isqrt(n) do
    x = n
    y = div(x + 1, 2)
    isqrt_iterate(n, x, y)
  end

  defp isqrt_iterate(_n, x, y) when y >= x, do: x

  defp isqrt_iterate(n, _x, y) do
    new_y = div(y + div(n, y), 2)
    isqrt_iterate(n, y, new_y)
  end
end
