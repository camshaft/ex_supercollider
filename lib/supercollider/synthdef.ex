defmodule SuperCollider.Synthdef do
  defstruct [:version, :defs]

  defmodule Def do
    defstruct [:name, :consts, :params, :param_names, :ugens, :variants]
  end

  defmodule UGen do
    defstruct [:name, :rate, :ins, :outs, :s_index]
  end

  defmodule UGenOutput do
    defstruct [:index1, :index2]
  end

  defmodule Constant do
    defstruct [:value]
  end

  def decode(binary) do
    {:ok, decode!(binary)}
  rescue
    e ->
      {:error, e}
  end

  def decode!(binary) do
    __MODULE__.Decoder.decode(binary)
  end

  def encode(value, opts \\ %{}) do
    encode(value, opts)
  rescue
    e ->
      {:error, e}
  end

  def encode!(value, opts \\ %{}) do
    encode_to_iodata(value, opts)
    |> :erlang.iolist_to_binary()
  end

  def encode_to_iodata(value, opts \\ %{}) do
    encode_to_iodata!(value, opts)
  rescue
    e ->
      {:error, e}
  end

  def encode_to_iodata!(value, opts \\ %{}) do
    __MODULE__.Encoder.encode(value, opts)
  end
end
