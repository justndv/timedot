defmodule Timedot do
  @moduledoc """
  Documentation for `Timedot`.
  """

  @type t :: %__MODULE__{items: list(Timedot.Item.t()), ir: Timedot.IR.t()}
  defstruct [:items, :ir]

  @doc """
  Parse a timedot string.

  If year is missing from an entry, the current year will be used instead.
  See `parse_line/2` to parse just a single entry line.
  """
  @spec parse(String.t()) :: {:ok, Timedot.t()} | {:error, String.t()}
  def parse(string) do
    case Timedot.Parser.parse(string) do
      {:ok, ir, _, _, _, _} ->
        {:ok, %Timedot{items: from_ir(ir, Date.utc_today().year), ir: ir}}

      {:error, msg, _, _, _, _} ->
        {:error, msg}
    end
  end

  @spec parse(String.t(), integer()) :: {:ok, Timedot.t()} | {:error, String.t()}
  def parse(string, year) do
    case Timedot.Parser.parse(string) do
      {:ok, ir, _, _, _, _} ->
        {:ok, %Timedot{items: from_ir(ir, year), ir: ir}}

      {:error, msg, _, _, _, _} ->
        {:error, msg}
    end
  end

  @doc """
  Parse a timedot line without an explicit date.
  """
  @spec parse_line(String.t(), :calendar.date()) ::
          {:ok, Timedot.Item.t() | nil} | {:error, String.t()}
  def parse_line(string, {year, month, day}) do
    case Timedot.Parser.parse_line(string) do
      {:ok, [item], _, _, _, _} ->
        case item do
          {:comment, _} -> {:ok, nil}
          {:entry, entry} -> {:ok, ir_to_item(entry, {year, month, day})}
        end

      {:error, msg, _, _, _, _} ->
        {:error, msg}
    end
  end

  @doc """
  Converts IR to Timedot, stripping comments and normalizing quantities.
  If a time item has no associated year in the IR, supplemental_year is used.
  """
  @spec from_ir(ir :: Timedot.IR.t(), supplemental_year :: integer()) :: list(Timedot.Item.t())
  def from_ir(ir, supplemental_year) do
    for line_like <- ir do
      case line_like do
        {:comment, _} ->
          nil

        {:day, data} ->
          %{day: day, month: month, year: year, entries: entries} =
            Map.put_new(data, :year, supplemental_year)

          for item <- entries do
            case item do
              {:comment, _} -> nil
              {:entry, entry} -> ir_to_item(entry, {year, month, day})
            end
          end
      end
    end
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  @spec ir_to_item(any(), :calendar.date()) :: Timedot.Item.t()
  defp ir_to_item(%{account: account, quantity: quantity}, date) do
    quantity =
      case quantity do
        {:seconds, duration} -> duration
        {:minutes, duration} -> duration * 60
        {:dots, duration} -> duration * 60 * 15
        {:hours, duration} -> round(duration * 60 * 60)
        {:days, duration} -> duration * 60 * 60 * 24
        {:weeks, duration} -> duration * 60 * 60 * 24 * 7
        {:months, duration} -> duration * 60 * 60 * 24 * 30
        {:years, duration} -> duration * 60 * 60 * 24 * 365
      end

    %Timedot.Item{date: date, account: account, quantity: {quantity, :seconds}}
  end

  @doc """
  Convert to string.
  """
  @spec to_string(Timedot.t()) :: String.t()
  def to_string(%__MODULE__{items: items, ir: _ir}) do
    Enum.group_by(items, fn %{date: date = {_, _, _}} -> date end, fn item -> item end)
    |> Map.to_list()
    |> Enum.map(fn {date, items} ->
      {year, month, day} = date
      year = Integer.to_string(year) |> String.pad_leading(4, "0")

      [month, day] =
        Enum.map([month, day], fn v -> Integer.to_string(v) |> String.pad_leading(2, "0") end)

      "#{year}-#{month}-#{day}\n" <>
        (Enum.map(items, fn %{account: account, quantity: {quantity, :seconds}} ->
           "#{account}  #{quantity}s"
         end)
         |> Enum.join("\n")) <> "\n"
    end)
    |> Enum.join("\n")
  end
end

defimpl String.Chars, for: Timedot do
  def to_string(timedot) do
    Timedot.to_string(timedot)
  end
end
