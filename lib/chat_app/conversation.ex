defmodule ChatApp.Conversation do
  use GenServer

  # Public API
  def start_link(name) do
    # TODO: Use a via tuple so this conversation registers itself in the Registry
    # via {:via, Registry, {ChatApp.Registry, name}}
    via_tuple = {:via, Registry, {ChatApp.Registry, name}}
    GenServer.start_link(__MODULE__, name, name: via_tuple)
  end

  def send_message(pid, message) do
    # TODO: call GenServer.cast or call
    # TODO: forward the message to the GenServer using cast
    GenServer.cast(pid, {:send_message, message})
  end

  def join(pid, user_pid) do
    # TODO: forward join request to GenServer
    GenServer.call(pid, {:join, user_pid})
  end

  def leave(pid, user_pid) do
    GenServer.call(pid, {:leave, user_pid})
  end

  # GenServer callbacks
  def init(name) do
    # TODO: return {:ok, initial_state}
    # TODO: Initialize state using the conversation name
    # This state will hold messages and participants later
    # build the state map
    state = %{
      name: name,
      participants: [],
      messages: []
    }

    {:ok, state}

    # TODO (future): monitor participant PIDs to detect crashes or disconnects
  end

  def handle_cast({:send_message, {username, message, sender_pid}}, state) do
    message_map = %{
      from: username,
      text: message,
      timestamp: DateTime.utc_now()
    }

    # AUTO-PRINT TO SERVER TERMINAL
    IO.puts("[#{username}] #{message}")

    new_messages = [message_map | state.messages]

    Enum.each(state.participants, fn pid ->
      if pid != sender_pid do
        send(pid, {:new_message, message_map})
      end
    end)

    {:noreply, %{state | messages: new_messages}}
  end




  def handle_call({:join, user_pid}, _from, state) do
    # Check if already joined
    new_participants =
      if Enum.member?(state.participants, user_pid) do
        state.participants
      else
        [user_pid | state.participants]
      end

    new_state = %{state | participants: new_participants}

    {:reply, :ok, new_state}
  end

  def handle_call({:leave, user_pid}, _from, state) do
    new_participants = List.delete(state.participants, user_pid)
    new_state = %{state | participants: new_participants}

    {:reply, :ok, new_state}
  end

  def handle_call(:participants, _from, state) do
    {:reply, state.participants, state}
  end


end
