defmodule Bench do
  def run(fun) when is_function(fun, 0) do
    Benchee.run(%{func: fun}, warmup: 1, memory_time: 1, reduction_time: 1)
  end

  def run(atom) when is_atom(atom) do
    atom.__info__(:functions)
    |> Enum.filter(&(elem(&1, 1) == 0))
    |> Enum.reduce(%{}, fn {fun, i}, acc ->
      Map.put(acc, to_string(fun), Function.capture(atom, fun, i))
    end)
    |> Benchee.run(warmup: 1, memory_time: 1, reduction_time: 1)
  end

  def run([_ | _] = list) do
    Enum.with_index(list)
    |> Enum.reduce(%{}, fn {fun, i}, acc ->
      Map.put(acc, "fun#{i}", fun)
    end)
    |> Benchee.run(warmup: 1, memory_time: 1, reduction_time: 1)
  end
end

defmodule Debug do
  def module(mod, app \\ "slator", env \\ "dev") when is_atom(mod) do
    disassemble("_build/#{env}/lib/#{app}/ebin/#{mod}.beam")
  end

  def module_str(mod, app \\ "slator", env \\ "dev") when is_atom(mod) do
    disassemble_str("_build/#{env}/lib/#{app}/ebin/#{mod}.beam")
  end

  def disassemble_str(beam_file) when is_binary(beam_file) do
    beam_file = String.to_charlist(beam_file)

    {:ok, {_, [{:abstract_code, {_, ac}}]}} =
      :beam_lib.chunks(
        beam_file,
        [:abstract_code]
      )

    :erl_prettypr.format(:erl_syntax.form_list(ac))
  end

  def disassemble({_, _, bin, _}) do
    {:ok, {_, [{:abstract_code, {_, ac}}]}} =
      :beam_lib.chunks(
        bin,
        [:abstract_code]
      )

    pp = :erl_prettypr.format(:erl_syntax.form_list(ac))
    :io.fwrite(~c"~s~n", [pp])
  end

  def disassemble(beam_file) when is_binary(beam_file) do
    :io.fwrite(~c"~s~n", [disassemble_str(beam_file)])
  end

  def trace_new_procs do
    :dbg.tracer()
    :dbg.p(:new, [:p])
  end
end

defmodule Clipboard do
  @spec copy(iodata) :: iodata
  def copy(value) do
    copy(:os.type(), value)
    value
  end

  @spec copy!(iodata) :: iodata | no_return
  def copy!(value) do
    case copy(:os.type(), value) do
      :ok ->
        value

      {:error, reason} ->
        raise reason
    end
  end

  defp copy({:unix, :darwin}, value) do
    command = Application.get_env(:clipboard, :macos)[:copy] || {"pbcopy", []}
    execute(command, value)
  end

  defp copy({:unix, _os_name}, value) do
    command = Application.get_env(:clipboard, :unix)[:copy] || {"xclip", []}
    execute(command, value)
  end

  defp copy({:win32, _os_name}, value) do
    command = Application.get_env(:clipboard, :windows)[:copy] || {"clip", []}
    execute(command, value)
  end

  defp copy({_unsupported_family, _unsupported_name}, _value) do
    {:error, "Unsupported operating system"}
  end

  def paste do
    case paste(:os.type()) do
      {:error, _reason} ->
        nil

      output ->
        output
    end
  end

  def paste! do
    case paste(:os.type()) do
      {:error, reason} ->
        raise reason

      output ->
        output
    end
  end

  defp paste({:unix, :darwin}) do
    command = Application.get_env(:clipboard, :macos)[:paste] || {"pbpaste", []}
    execute(command)
  end

  defp paste({:unix, _os_name}) do
    command = Application.get_env(:clipboard, :unix)[:paste] || {"xclip", ["-o"]}
    execute(command)
  end

  defp paste(_unsupported_os) do
    {:error, "Unsupported operating system"}
  end

  # Ports

  defp execute(nil), do: {:error, "Unsupported operating system"}

  defp execute({executable, args}) when is_binary(executable) and is_list(args) do
    case System.find_executable(executable) do
      nil ->
        {:error, "Cannot find #{executable}"}

      _ ->
        case System.cmd(executable, args) do
          {output, 0} ->
            output

          {error, _} ->
            {:error, error}
        end
    end
  end

  defp execute(nil, _), do: {:error, "Unsupported operating system"}

  defp execute({executable, args}, value) when is_binary(executable) and is_list(args) do
    case System.find_executable(executable) do
      nil ->
        {:error, "Cannot find #{executable}"}

      path ->
        port = Port.open({:spawn_executable, path}, [:binary, args: args])

        case value do
          value when is_binary(value) ->
            send(port, {self(), {:command, value}})

          value ->
            send(port, {self(), {:command, format(value)}})
        end

        send(port, {self(), :close})
        :ok
    end
  end

  defp format(value) do
    doc =
      Inspect.Algebra.to_doc(value, %Inspect.Opts{limit: :infinity, printable_limit: :infinity})

    Inspect.Algebra.format(doc, :infinity)
  end
end
