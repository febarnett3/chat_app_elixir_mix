defmodule ChatApp.User do
    use GenServer

    # Public API

    def start_link(username) do
        via = {:via, Registry, {ChatApp.UserRegistry, username}}
        GenServer.start_link(__MODULE__, username, name: via)
    end

    def set_client_pid(user_pid, client_pid) do
        GenServer.call(user_pid, {:set_client, client_pid})
    end


    def join(user_pid, room_name) do
        # TODO
        GenServer.call(user_pid, {:join, room_name})
    end

    def leave(user_pid) do
        GenServer.call(user_pid, :leave)
    end


    def send_message(user_pid, text) do
        GenServer.cast(user_pid, {:send_message, text})
    end

    def stop(user_pid) do
        GenServer.stop(user_pid, :normal)
    end

    def get_username(user_pid) do
        GenServer.call(user_pid, :get_username)
    end



    # GenServer Callbacks

    def init(username) do
        state = %{
            username: username,
            current_room: nil,
            inbox: []
        }

        {:ok, state}
    end


    def handle_call({:join, room_name}, _from, state) do
        {:ok, room_pid} = ChatApp.ConversationManager.get_or_start_conversation(room_name)
        ChatApp.Conversation.join(room_pid, self())
        new_state = %{state | current_room: room_pid}
        {:reply, {:joined, room_name}, new_state}
    end

    def handle_call(:leave, _from, state) do
    if state.current_room do
        ChatApp.Conversation.leave(state.current_room, self())
    end

    new_state = %{state | current_room: nil}

    {:reply, :ok, new_state}
    end


    def handle_call({:set_client, client_pid}, _from, state) do
        new_state = Map.put(state, :client, client_pid)
        {:reply, :ok, new_state}
    end

    def handle_call(:get_username, _from, state) do
        {:reply, state.username, state}
    end


    def handle_cast({:send_message, text}, state) do
        if state.current_room do
            ChatApp.Conversation.send_message(
            state.current_room,
            {state.username, text, self()}
            )

            # print confirmation to the sender
            if state[:client] do
            send(state.client, {:display_sent, text})
            end
        end

        {:noreply, state}
    end

    def handle_info({:new_message, message_map}, state) do
    # Store the message locally on the server
    new_inbox = [message_map | state.inbox]
    new_state = %{state | inbox: new_inbox}

    # Forward to CLI if connected
    if state[:client] do
        send(state.client, {:display, message_map})
    end

    {:noreply, new_state}
    end


    def handle_info(msg, state) do
        {:noreply, state}
    end


end
