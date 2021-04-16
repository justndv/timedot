defmodule Timedot.Item do
  @moduledoc """
  Single time entry in a timedot log, including the date.

  The quantity is always given in seconds.
  """

  @type t :: %__MODULE__{
          date: :calendar.date(),
          account: String.t(),
          quantity: {non_neg_integer(), :seconds}
        }
  defstruct [:date, :account, :quantity]
end
