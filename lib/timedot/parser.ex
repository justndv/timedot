defmodule Timedot.Helpers do
  @moduledoc """
  Helper functions for the timedot parser.
  """
  import NimbleParsec

  def spaces(min \\ 1) do
    ascii_string([?\s], min: min)
    |> label("#{min} or more spaces")
  end

  def eol() do
    ignore(ascii_char([?\n]))
    |> label("end of line")
  end

  def day() do
    simple_date()
    |> ignore(optional(spaces()))
    |> choice([
      comment(),
      eol()
    ])
    |> concat(
      repeat(
        lookahead_not(simple_date())
        |> lookahead_not(eos())
        |> choice([
          eol(),
          comment(),
          entry()
        ])
      )
      |> tag(:entries)
    )
    |> post_traverse(:list_to_map)
    |> unwrap_and_tag(:day)
  end

  @doc """
  Optional leading zeros, year may be omitted. Example: 2010-01-31, 1/31
  https://hledger.org/hledger.html#simple-dates
  """
  def simple_date() do
    optional(
      integer(4)
      |> ignore(ascii_char([?., ?-, ?/]))
      |> unwrap_and_tag(:year)
    )
    |> concat(
      choice([
        integer(2),
        integer(1)
      ])
      |> ignore(ascii_char([?., ?-, ?/]))
      |> unwrap_and_tag(:month)
    )
    |> concat(
      choice([
        integer(2),
        integer(1)
      ])
      |> unwrap_and_tag(:day)
    )
    |> label("hledger simple date")
  end

  def comment() do
    ignore(ascii_char([?#, ?;]))
    |> ignore(spaces(0))
    |> repeat(
      lookahead_not(ascii_char([?\n]))
      |> lookahead_not(eos())
      |> utf8_char([])
    )
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:comment)
  end

  def account() do
    repeat(
      lookahead_not(spaces(2))
      |> ascii_char([])
    )
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:account)
  end

  def list_to_map(_rest, args, context, _line, _offset) do
    {[args |> Enum.into(%{})], context}
  end

  def entry() do
    ignore(optional(spaces()))
    |> concat(account())
    |> ignore(spaces(2))
    |> label("after account name and before quantity")
    |> concat(quantity())
    |> choice([
      ignore(optional(spaces())) |> concat(comment()),
      ignore(eos()),
      ignore(eol())
    ])
    |> post_traverse(:list_to_map)
    |> unwrap_and_tag(:entry)
  end

  def quantity() do
    choice([
      decimal_hours(),
      dots(),
      with_unit(),
      integral_hours()
    ])
    |> label("quantity")
    |> unwrap_and_tag(:quantity)
  end

  def dots() do
    ascii_char([?.])
    |> replace(1)
    |> repeat(
      choice([
        ascii_char([?.]) |> replace(1),
        ascii_char([?\s]) |> replace(0)
      ])
    )
    |> reduce({Enum, :sum, []})
    |> unwrap_and_tag(:dots)
  end

  def string_to_float(_rest, [float], context, _line, _offset) do
    {[String.to_float(float)], context}
  end

  def decimal_hours() do
    choice([
      ascii_string([?0..?9], min: 1)
      |> string("."),
      string(".") |> replace("0.")
    ])
    |> ascii_string([?0..?9], min: 1)
    |> reduce({List, :to_string, []})
    |> post_traverse(:string_to_float)
    |> unwrap_and_tag(:hours)
  end

  def integral_hours() do
    integer(min: 1)
    |> unwrap_and_tag(:hours)
  end

  def with_unit() do
    integer(min: 1)
    |> choice([
      string("s") |> replace(:seconds),
      string("mo") |> replace(:months),
      string("m") |> replace(:minutes),
      string("h") |> replace(:hours),
      string("d") |> replace(:days),
      string("w") |> replace(:weeks),
      string("y") |> replace(:years)
    ])
    |> post_traverse(:flip_to_tag)
  end

  def flip_to_tag(_rest, [atom, item], context, _line, _offset) do
    {[{atom, item}], context}
  end
end

defmodule Timedot.Parser do
  @moduledoc """
  Timedot parser.
  """
  import NimbleParsec
  import Timedot.Helpers

  # whole file
  defparsec(
    :parse,
    repeat(
      choice([
        eol(),
        day(),
        comment()
      ])
    )
    |> eos()
  )

  # line, only entries
  defparsec(
    :parse_line,
    choice([
      comment(),
      entry()
    ])
    |> eos()
  )
end
