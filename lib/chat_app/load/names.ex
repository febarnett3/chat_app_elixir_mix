defmodule ChatApp.Load.Names do
  def username(i) do
    suffix =
      i
      |> Integer.to_string()
      |> String.pad_leading(7, "0")

    "user_" <> suffix
  end

  def username(i, offset) do
    username(i + offset)
  end

  def room(i, offset \\ 0) do
    "room_" <> Integer.to_string(i + offset)
  end
end
