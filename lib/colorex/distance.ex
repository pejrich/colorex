defmodule Colorex.Distance do
  @moduledoc false
  @doc """
  A module that implements the CIEDE2000 color distance algorithm.
  (http://www2.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf)
  """

  alias Colorex.Support.Math

  @deg_6_in_rad Math.deg_to_rad(6)
  @deg_25_in_rad Math.deg_to_rad(25)
  @deg_30_in_rad Math.deg_to_rad(30)
  @deg_63_in_rad Math.deg_to_rad(63)
  @deg_275_in_rad Math.deg_to_rad(275)
  @pow_25_7 :math.pow(25, 7)

  def distance(a, b, opts \\ [fast: false]) do
    if Keyword.get(opts, :fast, false) do
      fast_distance(a, b, opts)
    else
      lab_distance(a, b, opts)
    end
  end

  @lab_max 117
  @fast_max 742
  def fast_distance(a, a, _), do: 0.0

  def fast_distance(c1, c2, opts) do
    norm = Keyword.get(opts, :norm, false)
    c1 = Colorex.rgb(c1)
    c2 = Colorex.rgb(c2)
    rmean = (c1.red + c2.red) / 2
    r = c1.red - c2.red
    g = c1.green - c2.green
    b = c1.blue - c2.blue

    :math.sqrt(
      (((512 + rmean) * r * r) |> ceil() |> Bitwise.bsr(8)) + 4 * g * g +
        (((767 - rmean) * b * b) |> ceil() |> Bitwise.bsr(8))
    )
    |> Kernel./((norm && @fast_max) || 1)
  end

  def lab_distance(a, a, _), do: 0.0

  def lab_distance(color, other_color, opts) do
    norm = Keyword.get(opts, :norm, false)
    color = Colorex.lab(color)
    other_color = Colorex.lab(other_color)

    # 2)
    c_star_1 = calc_c_star_i(color.a, color.b)
    c_star_2 = calc_c_star_i(other_color.a, other_color.b)
    # 3)
    c_star_dash = calc_c_star_dash(c_star_1, c_star_2)
    # 4)
    g = calc_g(c_star_dash)
    # 5)
    a_apo_1 = calc_a_apo(g, color.a)
    a_apo_2 = calc_a_apo(g, other_color.a)
    # 6)
    c_apo_1 = calc_c_apo(a_apo_1, color.b)
    c_apo_2 = calc_c_apo(a_apo_2, other_color.b)
    # 7)
    h_apo_1 = calc_h_apo(a_apo_1, color.b)
    h_apo_2 = calc_h_apo(a_apo_2, other_color.b)
    # 8)
    delta_l_apo = other_color.l - color.l
    # 9)
    delta_c_apo = c_star_2 - c_star_1
    # 10)
    delta_h_apo = calc_delta_h_apo(c_apo_1, c_apo_2, h_apo_1, h_apo_2)
    # 11)
    delta_cap_h_apo = calc_delta_cap_h_apo(c_apo_1, c_apo_2, delta_h_apo)
    # 12)
    l_apo_dash = calc_cl_apo_dash(color.l, other_color.l)
    # 13)
    c_apo_dash = calc_cl_apo_dash(c_apo_1, c_apo_2)
    # 14)
    h_apo_dash = calc_h_apo_dash(c_apo_1, c_apo_2, h_apo_1, h_apo_2)
    # 15)
    t = calc_t(h_apo_dash)
    # 16)
    delta_theta = calc_delta_theta(h_apo_dash)
    # 17)
    rc = calc_rc(c_apo_dash)
    # 18)
    sl = calc_sl(l_apo_dash)
    # 19)
    sc = calc_sc(c_apo_dash)
    # 20)
    sh = calc_sh(c_apo_dash, t)
    # 21)
    rt = calc_rt(delta_theta, rc)

    # 22)

    calc_delta_e00(
      delta_l_apo,
      delta_c_apo,
      delta_cap_h_apo,
      rt,
      sl,
      sc,
      sh,
      opts[:weights]
    )
    |> Kernel./((norm && @lab_max) || 1)
  end

  defp calc_c_star_i(a, b) do
    :math.sqrt(:math.pow(a, 2) + :math.pow(b, 2))
  end

  defp calc_c_star_dash(c_star_1, c_star_2) do
    (c_star_1 + c_star_2) / 2
  end

  defp calc_g(c_star_dash) do
    c_star_dash_pow_7 = :math.pow(c_star_dash, 7)
    0.5 * (1 - :math.sqrt(c_star_dash_pow_7 / (c_star_dash_pow_7 + @pow_25_7)))
  end

  defp calc_a_apo(g, a) do
    (1 + g) * a
  end

  defp calc_c_apo(a_apo, b) do
    :math.sqrt(:math.pow(a_apo, 2) + :math.pow(b, 2))
  end

  defp calc_h_apo(a_apo, b) do
    if a_apo == 0 && b == 0 do
      0
    else
      b
      |> :math.atan2(a_apo)
      |> Math.rad_to_deg()
    end
  end

  defp calc_delta_h_apo(c_apo_1, c_apo_2, h_apo_1, h_apo_2) do
    if c_apo_1 == 0 && c_apo_2 == 0 do
      0
    else
      diff = h_apo_2 - h_apo_1

      cond do
        abs(diff) <= 180 -> diff
        diff > 180 -> diff - 360
        diff < -180 -> diff + 360
      end
    end
  end

  defp calc_delta_cap_h_apo(c_apo_1, c_apo_2, delta_h_apo) do
    2 * :math.sqrt(c_apo_1 * c_apo_2) *
      :math.sin(Math.deg_to_rad(delta_h_apo) / 2)
  end

  defp calc_cl_apo_dash(v1, v2) do
    (v1 + v2) / 2
  end

  defp calc_h_apo_dash(c_apo_1, c_apo_2, h_apo_1, h_apo_2) do
    sum = h_apo_1 + h_apo_2

    if c_apo_1 == 0 && c_apo_2 == 0 do
      sum
    else
      abs_diff = abs(h_apo_1 - h_apo_2)

      cond do
        abs_diff <= 180 -> sum / 2
        sum < 360 -> (sum + 360) / 2
        sum >= 360 -> (sum - 360) / 2
      end
    end
  end

  defp calc_t(h_apo_dash) do
    h_apo_dash_rad = Math.deg_to_rad(h_apo_dash)

    1 - 0.17 * :math.cos(h_apo_dash_rad - @deg_30_in_rad) +
      0.24 * :math.cos(2 * h_apo_dash_rad) +
      0.32 * :math.cos(3 * h_apo_dash_rad + @deg_6_in_rad) -
      0.2 * :math.cos(4 * h_apo_dash_rad - @deg_63_in_rad)
  end

  defp calc_delta_theta(h_apo_dash) do
    @deg_30_in_rad *
      :math.exp(
        -:math.pow(
          (Math.deg_to_rad(h_apo_dash) - @deg_275_in_rad) / @deg_25_in_rad,
          2
        )
      )
  end

  defp calc_rc(c_apo_dash) do
    c_apo_dash_pow_7 = :math.pow(c_apo_dash, 7)
    2 * :math.sqrt(c_apo_dash_pow_7 / (c_apo_dash_pow_7 + @pow_25_7))
  end

  defp calc_sl(l_apo_dash) do
    v = :math.pow(l_apo_dash - 50, 2)
    1 + 0.015 * v / :math.sqrt(20 + v)
  end

  defp calc_sc(c_apo_dash) do
    1 + 0.045 * c_apo_dash
  end

  defp calc_sh(c_apo_dash, t) do
    1 + 0.015 * c_apo_dash * t
  end

  defp calc_rt(delta_theta, rc) do
    -:math.sin(2 * delta_theta) * rc
  end

  defp calc_delta_e00(
         delta_l_apo,
         delta_c_apo,
         delta_h_apo,
         rt,
         sl,
         sc,
         sh,
         weights
       ) do
    # The weights kL, kC, and kH are usually unity
    {kl, kc, kh} = weights || {1, 1, 1}

    d_l_apo_sl_div = delta_l_apo / (kl * sl)
    d_c_apo_sc_div = delta_c_apo / (kc * sc)
    d_h_apo_sh_div = delta_h_apo / (kh * sh)

    :math.sqrt(
      :math.pow(d_l_apo_sl_div, 2) +
        :math.pow(d_c_apo_sc_div, 2) +
        :math.pow(d_h_apo_sh_div, 2) +
        rt * d_c_apo_sc_div * d_h_apo_sh_div
    )
  end
end
