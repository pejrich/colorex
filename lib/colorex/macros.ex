defmodule Colorex.Macros do
  @moduledoc false

  @doc false
  defmacro cdef({name, _meta, args}, do: block) do
    head =
      Enum.map(args, fn
        {:"::", _, [lhs, _]} -> lhs
        val -> val
      end)

    a =
      Enum.map(args, fn
        {:"::", _, [lhs, _]} -> lhs
        {:\\, _, [lhs, _]} -> lhs
        val -> val
      end)

    b =
      Enum.map(args, fn
        {:"::", _, [lhs, rhs]} -> {rhs, [], [lhs]}
        {:\\, _, [lhs, _]} -> lhs
        val -> val
      end)

    quote do
      def unquote(:"#{name}")(unquote_splicing(head))

      def unquote(:"#{name}")(
            %Colorex.Color{color: color} = unquote(Enum.at(a, 0)),
            unquote_splicing(Enum.drop(a, 1))
          ) do
        res = unquote(:"#{name}")(color, unquote_splicing(Enum.drop(a, 1)))

        case res do
          list when is_list(list) ->
            Enum.map(list, fn color -> %{unquote(Enum.at(a, 0)) | color: color} end)

          %{} = color ->
            %{unquote(Enum.at(a, 0)) | color: color}

          val ->
            val
        end
      end

      def unquote(:"#{name}")(unquote_splicing(a)) do
        unquote(:"_#{name}")(unquote_splicing(b))
      end

      defp unquote(:"_#{name}")(unquote_splicing(a)) do
        unquote(block)
      end
    end
  end
end
