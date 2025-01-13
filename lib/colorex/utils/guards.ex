defmodule Colorex.Support.Guards do
  @moduledoc false
  @hex_chars Enum.concat([?0..?9, ?a..?f, ?A..?F])
  @hex_strs Enum.map(@hex_chars, &to_string([&1]))
  defguard is_hex_char(char) when char in @hex_chars

  defguard is_hex_str(str)
           when (byte_size(str) == 1 and str in @hex_strs) or
                  (byte_size(str) == 2 and binary_part(str, 0, 1) in @hex_strs and
                     binary_part(str, 1, 1) in @hex_strs)

  defguard is_hex8_int(int) when is_integer(int) and int >= 0 and int <= 255
  defguard is_alpha_float(float) when is_float(float) and float >= 0.0 and float <= 1.0

  defguard is_rgba_tuple(tuple)
           when is_hex8_int(elem(tuple, 0)) and is_hex8_int(elem(tuple, 1)) and
                  is_hex8_int(elem(tuple, 2)) and is_alpha_float(elem(tuple, 3))
end
