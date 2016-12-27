alias SuperCollider.Synthdef

defprotocol Synthdef.Encoder do
  def encode(value, opts)
end

defmodule Synthdef.Encoder.Utils do
  def encode_int8(value), do: <<value :: size(8)>>
  def encode_int16(value), do: <<value :: size(16)>>
  def encode_int32(value), do: <<value :: size(32)>>

  def encode_list16(list, fun) when is_function(fun) do
    [
      encode_int16(length(list)),
      Enum.map(list, fun)
    ]
  end
  def encode_list16(list, opts) do
    encode_list16(list, &Synthdef.Encoder.encode(&1, opts))
  end

  def encode_list32(list, fun) when is_function(fun) do
    [
      encode_int32(length(list)),
      Enum.map(list, fun)
    ]
  end
  def encode_list32(list, opts) do
    encode_list32(list, &Synthdef.Encoder.encode(&1, opts))
  end
end
alias Synthdef.Encoder.Utils

defimpl Synthdef.Encoder, for: BitString do
  def encode(bin, _) do
    [<<byte_size(bin) :: size(8)>>, bin]
  end
end

defimpl Synthdef.Encoder, for: Float do
  def encode(float, _) do
    <<float :: float-size(32)>>
  end
end

defimpl Synthdef.Encoder, for: Synthdef do
  def encode(%{version: version, defs: defs}, opts) do
    ["SCgf",
     <<version :: size(32), length(defs) :: size(16)>>,
     Enum.map(defs, &@protocol.encode(&1, opts))]
  end
end

defimpl Synthdef.Encoder, for: Synthdef.Def do
  def encode(%{name: name,
               consts: consts,
               params: params,
               param_names: pnames,
               ugens: ugens,
               variants: variants}, opts) do
    [
      @protocol.encode(name, opts),
      Utils.encode_list32(consts, opts),
      Utils.encode_list32(params, opts),
      Utils.encode_list32(pnames, fn({name, index}) ->
        [@protocol.encode(name, opts),
         Utils.encode_int32(index)]
      end),
      Utils.encode_list32(ugens, opts),
      Utils.encode_list16(variants, fn({name, params}) ->
        [@protocol.encode(name, opts),
         Enum.map(params, &@protocol.encode(&1, opts))]
      end),
    ]
  end
end

defimpl Synthdef.Encoder, for: Synthdef.UGen do
  def encode(%{name: name,
               rate: rate,
               ins: ins,
               outs: outs,
               s_index: s_index}, opts) do
    [
      @protocol.encode(name, opts),
      Utils.encode_int8(rate),
      Utils.encode_int32(length(ins)),
      Utils.encode_int32(length(outs)),
      Utils.encode_int16(s_index),
      Enum.map(ins, &@protocol.encode(&1, opts)),
      Enum.map(outs, &Utils.encode_int8/1),
    ]
  end
end

defimpl Synthdef.Encoder, for: Synthdef.Constant do
  def encode(%{value: value}, _opts) do
    <<4294967295 :: size(32), value :: size(32)>>
  end
end

defimpl Synthdef.Encoder, for: Synthdef.UGenOutput do
  def encode(%{index1: index1, index2: index2}, _opts) do
    <<index1 :: size(32), index2 :: size(32)>>
  end
end
