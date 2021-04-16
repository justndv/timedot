defmodule Timedot.IR do
  @moduledoc """
  Intermediate representation of a timedot file.
  Result of parsing a file and can be serialized again in a consistent manner.
  """

  @type t :: list(line_like())
  @type line_like :: comment() | day()
  @type comment :: {:comment, String.t()}
  @type day ::
          {:comment,
           %{
             optional(:year) => integer(),
             optional(:comment) => String.t(),
             day: integer(),
             month: integer(),
             entries: entries()
           }}
  @type entries ::
          list(
            %{optional(:comment) => String.t(), account: String.t(), quantity: quantity()}
            | {:comment, String.t()}
          )
  @type quantity :: {time_unit(), integer()} | {time_unit(), float()}
  @type time_unit :: :seconds | :minutes | :dots | :hours | :days | :week | :months | :years

  @doc """
  Converts the given IR to a timedot string.
  """
  @spec to_string(Timedot.IR.t()) :: String.t()
  def to_string(ir) do
    (for line_like <- ir do
       case line_like do
         {:comment, comment} ->
           "# #{comment}"

         {:day, [entries: []]} ->
           ""

         {:day, d} ->
           date_line =
             if Map.has_key?(d, :year) do
               year = Integer.to_string(Map.fetch!(d, :year)) |> String.pad_leading(4, "0")
               year <> "-"
             else
               ""
             end

           %{day: day, month: month, entries: entries} = d

           [month, day] =
             Enum.map([month, day], fn v ->
               Integer.to_string(v) |> String.pad_leading(2, "0")
             end)

           optional_comment = Map.get(d, :comment, "")

           optional_comment =
             if String.length(optional_comment) > 0 do
               " # #{optional_comment}"
             else
               optional_comment
             end

           date_line = date_line <> "#{month}-#{day}#{optional_comment}\n"

           date_line <>
             (Enum.map(entries, fn entry ->
                case entry do
                  {:comment, comment} ->
                    "# #{comment}"

                  {:entry, %{account: account, quantity: quantity, comment: comment}} ->
                    "#{account}  #{quantity_to_string(quantity)} # #{comment}"

                  {:entry, %{account: account, quantity: quantity}} ->
                    "#{account}  #{quantity_to_string(quantity)}"
                end
              end)
              |> Enum.join("\n"))
       end
     end
     |> Enum.join("\n")) <>
      "\n"
  end

  @spec quantity_to_string(quantity()) :: String.t()
  defp quantity_to_string({:dots, dots}) do
    String.duplicate(".", dots)
    |> String.to_charlist()
    |> Enum.chunk_every(4)
    |> Enum.join(" ")
  end

  defp quantity_to_string({unit, duration}),
    do: "#{duration}#{unit_to_string(unit)}"

  defp unit_to_string(:seconds), do: "s"
  defp unit_to_string(:minutes), do: "m"
  defp unit_to_string(:hours), do: "h"
  defp unit_to_string(:days), do: "d"
  defp unit_to_string(:weeks), do: "w"
  defp unit_to_string(:months), do: "mo"
  defp unit_to_string(:years), do: "y"
end

defimpl String.Chars, for: Timedot.IR do
  def to_string(ir) do
    Timedot.IR.to_string(ir)
  end
end
