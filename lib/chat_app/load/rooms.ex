defmodule ChatApp.Load.Rooms do
  @moduledoc """
  Assigns users to rooms in a simple round-robin way.
  """

  @doc """
  Given user index `i` and `num_rooms`, returns a room name like "room_1".

  Example:
    room_for(1, 10)  -> "room_1"
    room_for(10, 10) -> "room_10"
    room_for(11, 10) -> "room_1" (wraps around)
  """
  @spec room_for(pos_integer(), pos_integer()) :: String.t()
  def room_for(i, num_rooms) when num_rooms > 0 do
    idx = rem(i - 1, num_rooms) + 1
    "room_#{idx}"
  end
end
