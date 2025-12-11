defmodule ChatApp.CLI do
  def main(_args) do
    # 1. Start CLI as a distributed Erlang node immediately
    node_name = :"cli_#{System.unique_integer([:positive])}"
    {:ok, _} = Node.start(node_name, :shortnames)

    # 2. Ensure cookie matches the server’s cookie
    Node.set_cookie(:chat_cookie)

    # 3. Start listener
    listener_pid = spawn(fn -> message_listener() end)

    # 4. Initial state
    state = %{
      server: nil,
      listener: listener_pid,
      user: nil,
      current_room: nil
    }

    IO.puts("Welcome to ChatApp!")
    loop(state)
  end



  defp loop(state) do
    IO.write("chat> ")
    input =
      IO.gets("")
      |> to_string()
      |> String.trim()

    case handle_command(input, state) do
        {:ok, new_state} -> loop(new_state)
        :quit -> IO.puts("Goodbye!")
      end
  end

  defp message_listener do
    receive do
      {:display, %{from: from, text: text}} ->
        IO.puts("\n[#{from}] #{text}")
        IO.write("chat> ")

      {:display_sent, text} ->
        IO.puts("\n[you] #{text}")

      other ->
        IO.inspect(other, label: "Unknown message in listener")
    end

    message_listener()
  end



  defp handle_command("/quit", _state), do: :quit

  defp handle_command("/connect " <> node_str, state) do
    node_atom = String.to_atom(node_str)

    case Node.connect(node_atom) do
      true ->
        IO.puts("Connected to #{node_atom}")
        {:ok, %{state | server: node_atom}}

      false ->
        IO.puts("Failed to connect to #{node_atom}")
        {:ok, state}
    end
  end


  defp handle_command("/login " <> username, state) do
    if state.server == nil do
      IO.puts("You must connect to a server first (/connect ...)")
      {:ok, state}
    else
      result =
        :rpc.call(
          state.server,
          DynamicSupervisor,
          :start_child,
          [ChatApp.UserSupervisor, {ChatApp.User, username}]
        )

      case result do
        {:ok, user_pid} ->
          # Tell server to send messages to our listener
          :rpc.call(
            state.server,
            ChatApp.User,
            :set_client_pid,
            [user_pid, state.listener]
          )

          IO.puts("Logged in as #{username}")
          {:ok, %{state | user: %{username: username, pid: user_pid}}}

        {:error, {:already_started, pid}} ->
          :rpc.call(
            state.server,
            ChatApp.User,
            :set_client_pid,
            [pid, state.listener]
          )

          IO.puts("Welcome back, #{username}")
          {:ok, %{state | user: %{username: username, pid: pid}}}

        {:badrpc, reason} ->
          IO.puts("RPC error: #{inspect(reason)}")
          {:ok, state}

        other ->
          IO.puts("Unexpected error: #{inspect(other)}")
          {:ok, state}
      end
    end
  end


  defp handle_command("/join " <> room_name, state) do
    cond do
      state.server == nil ->
        IO.puts("You must /connect first.")
        {:ok, state}

      state[:user] == nil ->
        IO.puts("You must /login first.")
        {:ok, state}

      true ->
        # Extract pid from state
        user_pid = state.user.pid

        result =
          :rpc.call(
            state.server,
            ChatApp.User,
            :join,
            [user_pid, room_name]
          )

        case result do
          {:joined, ^room_name} ->
            IO.puts("Joined room #{room_name}")
            {:ok, Map.put(state, :current_room, room_name)}

          :ok ->
            # Your User.join/2 currently returns :ok in your code
            IO.puts("Joined room #{room_name}")
            {:ok, Map.put(state, :current_room, room_name)}

          {:badrpc, reason} ->
            IO.puts("RPC error: #{inspect(reason)}")
            {:ok, state}

          other ->
            IO.puts("Unexpected join result: #{inspect(other)}")
            {:ok, state}
        end
    end
  end

  defp handle_command("/send " <> text, state) do
    cond do
      state.server == nil ->
        IO.puts("You must /connect first.")
        {:ok, state}

      state[:user] == nil ->
        IO.puts("You must /login first.")
        {:ok, state}

      state[:current_room] == nil ->
        IO.puts("You must /join a room first.")
        {:ok, state}

      true ->
        user_pid = state.user.pid

        result =
          :rpc.call(
            state.server,
            ChatApp.User,
            :send_message,
            [user_pid, text]
          )

        case result do
          :ok ->
            {:ok, state}

          {:badrpc, reason} ->
            IO.puts("RPC error: #{inspect(reason)}")
            {:ok, state}

          other ->
            IO.puts("Unexpected send result: #{inspect(other)}")
            {:ok, state}
        end
    end
  end

  defp handle_command("/leave", state) do
    cond do
      state.server == nil ->
        IO.puts("You must /connect first.")
        {:ok, state}

      state.user == nil ->
        IO.puts("You must /login first.")
        {:ok, state}

      state.current_room == nil ->
        IO.puts("You are not in a room.")
        {:ok, state}

      true ->
        user_pid = state.user.pid

        result =
          :rpc.call(
            state.server,
            ChatApp.User,
            :leave,
            [user_pid]
          )

        case result do
          :ok ->
            IO.puts("You left the room.")
            {:ok, %{state | current_room: nil}}

          {:badrpc, reason} ->
            IO.puts("RPC error: #{inspect(reason)}")
            {:ok, state}

          other ->
            IO.puts("Unexpected leave result: #{inspect(other)}")
            {:ok, state}
        end
    end
  end

  defp handle_command("/rooms", state) do
    if state.server == nil do
      IO.puts("You must /connect first.")
      {:ok, state}
    else
      rooms =
        :rpc.call(
          state.server,
          Registry,
          :select,
          [
            ChatApp.Registry,
            [{{:"$1", :_, :_}, [], [:"$1"]}]
          ]
        )

      case rooms do
        {:badrpc, reason} ->
          IO.puts("RPC error: #{inspect(reason)}")
          {:ok, state}

        room_list ->
          IO.puts("Active rooms:")
          Enum.each(room_list, &IO.puts(" - #{&1}"))
          {:ok, state}
      end
    end
  end

  defp handle_command("/who", state) do
    cond do
      state.server == nil ->
        IO.puts("You must /connect first.")
        {:ok, state}

      state.user == nil ->
        IO.puts("You must /login first.")
        {:ok, state}

      state.current_room == nil ->
        IO.puts("You must join a room first.")
        {:ok, state}

      true ->
        room_name = state.current_room

        # Look up room PID on the server
        result =
          :rpc.call(
            state.server,
            Registry,
            :lookup,
            [ChatApp.Registry, room_name]
          )

        case result do
          {:badrpc, reason} ->
            IO.puts("RPC error: #{inspect(reason)}")
            {:ok, state}

          [] ->
            IO.puts("Room does not exist.")
            {:ok, state}

          [{room_pid, _}] ->
            users =
              :rpc.call(
                state.server,
                ChatApp.ConversationManager,
                :list_participants,
                [room_pid]
              )

            usernames =
              Enum.map(users, fn pid ->
                :rpc.call(state.server, ChatApp.User, :get_username, [pid])
              end)


            IO.puts("Users in #{room_name}:")
            Enum.each(usernames, fn name ->
              IO.puts(" - #{name}")
            end)

            {:ok, state}
        end
    end
  end

  defp handle_command("/logout", state) do
    cond do
      state.server == nil ->
        IO.puts("You must /connect first.")
        {:ok, state}

      state.user == nil ->
        IO.puts("You are not logged in.")
        {:ok, state}

      true ->
        user_pid = state.user.pid

        :rpc.call(
          state.server,
          ChatApp.User,
          :stop,
          [user_pid]
        )

        IO.puts("Logged out.")

        {:ok, %{state | user: nil, current_room: nil}}
    end
  end

  defp handle_command(cmd, state) do
    IO.puts("Unknown command: #{cmd}")
    {:ok, state}
  end

end
