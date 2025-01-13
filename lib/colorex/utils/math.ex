defmodule Colorex.Support.Math do
  @moduledoc false

  @spec nth_root(number, integer, float) :: float
  def nth_root(value, n, precision \\ 1.0e-5) do
    f = fn prev -> ((n - 1) * prev + value / :math.pow(prev, n - 1)) / n end
    fixed_point(f, value, precision, f.(value))
  end

  defp fixed_point(_, guess, tolerance, next)
       when abs(guess - next) < tolerance,
       do: next

  defp fixed_point(f, _, tolerance, next) do
    fixed_point(f, next, tolerance, f.(next))
  end

  @spec rad_to_deg(float) :: float
  def rad_to_deg(value) do
    pi = :math.pi()

    value =
      if value < 0 do
        value + 2 * pi
      else
        value
      end

    value * (180 / pi)
  end

  @spec deg_to_rad(float) :: float
  def deg_to_rad(value) do
    value * (:math.pi() / 180)
  end

  def rem(dividend, divisor) when is_float(dividend) and is_integer(divisor) do
    int_dividend = abs(floor(dividend))
    rest = Kernel.rem(int_dividend, divisor)
    decimal_rest = dividend - int_dividend
    rest + decimal_rest
  end
end
