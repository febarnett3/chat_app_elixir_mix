defmodule ChatApp.ConversationManager do
  def get_or_start_conversation(name) do
    result = Registry.lookup(ChatApp.Registry, name)

    case result do
      [] ->
        case DynamicSupervisor.start_child(
               ChatApp.ConversationSupervisor,
               {ChatApp.Conversation, name}
             ) do
          {:ok, pid} ->
            {:ok, pid}

          {:error, reason} ->
            {:error, reason}
        end

      [{pid, _value}] ->
        {:ok, pid}
    end
  end

  def list_participants(room_pid) do
    GenServer.call(room_pid, :participants)
  end

end
