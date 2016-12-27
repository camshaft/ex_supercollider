defmodule SuperCollider.Synthdef.Decoder do
  alias SuperCollider.Synthdef

  def decode("SCgf" <> <<version :: size(32)>> <> defs) do
    {defs, ""} = get_list_16(defs, &get_def/1)
    %Synthdef{
      version: version,
      defs: defs
    }
  end

  defp get_def(bin) do
    {name, bin} = get_string(bin)
    {consts, bin} = get_list_32(bin, &get_float/1)
    {params, bin} = get_list_32(bin, &get_float/1)
    {pnames, bin} = get_list_32(bin, &get_param_name/1)
    {ugens, bin} = get_list_32(bin, &get_ugen/1)
    num_params = length(params)
    {variants, bin} = get_list_16(bin, fn(bin) ->
      {name, bin} = get_string(bin)
      {params, bin} = get_list_parts(bin, num_params, &get_float/1)
      {{name, params}, bin}
    end)
    {%Synthdef.Def{
      name: name,
      consts: consts,
      params: params,
      param_names: pnames,
      ugens: ugens,
      variants: variants
    }, bin}
  end

  defp get_int8(<<value :: size(8), rest :: binary>>) do
    {value, rest}
  end

  defp get_int16(<<value :: size(16), rest :: binary>>) do
    {value, rest}
  end

  defp get_int32(<<value :: size(32), rest :: binary>>) do
    {value, rest}
  end

  defp get_float(<<value :: float-size(32), rest :: binary>>) do
    {value, rest}
  end

  defp get_string(<<size :: size(8), value :: binary-size(size), rest :: binary>>) do
    {value, rest}
  end

  defp get_param_name(bin) do
    {name, bin} = get_string(bin)
    {index, bin} = get_int32(bin)
    {{name, index}, bin}
  end

  defp get_ugen(bin) do
    {name, bin} = get_string(bin)
    {rate, bin} = get_int8(bin)
    {num_ins, bin} = get_int32(bin)
    {num_outs, bin} = get_int32(bin)
    {s_index, bin} = get_int16(bin)
    {in_specs, bin} = get_list_parts(bin, num_ins, &get_input_spec/1)
    {out_specs, bin} = get_list_parts(bin, num_outs, &get_int8/1)
    {%Synthdef.UGen{
      name: name,
      rate: rate,
      ins: in_specs,
      outs: out_specs,
      s_index: s_index
    }, bin}
  end

  def get_input_spec(<<4294967295 :: size(32), value :: size(32), rest :: binary>>) do
    {%Synthdef.Constant{value: value}, rest}
  end
  def get_input_spec(<<index1 :: size(32), index2 :: size(32), rest :: binary>>) do
    {%Synthdef.UGenOutput{index1: index1, index2: index2}, rest}
  end

  defp get_list_16(<<count :: size(16), rest :: binary>>, fun) do
    get_list_parts(rest, count, fun)
  end
  defp get_list_32(<<count :: size(32), rest :: binary>>, fun) do
    get_list_parts(rest, count, fun)
  end

  defp get_list_parts(bin, count, fun) do
    count
    |> repeatedly()
    |> Enum.map_reduce(bin, fn(_, acc) ->
      fun.(acc)
    end)
  end

  defp repeatedly(0), do: []
  defp repeatedly(count), do: 1..count
end
