defmodule ChatApp.Load.Spawner do
  alias ChatApp.Load.{Names, Client}

  def start_clients(num_clients, num_rooms, offset \\ 0) do
    for i <- 1..num_clients do
      username = Names.username(i, offset)
      room     = Names.room(rem(i - 1, num_rooms) + 1, offset)

      Task.start(fn ->
        Client.start_link(username: username, room: room)
      end)
    end

    IO.puts("Spawned #{num_clients} clients across #{num_rooms} rooms with offset #{offset}.")
    :ok
  end
end
