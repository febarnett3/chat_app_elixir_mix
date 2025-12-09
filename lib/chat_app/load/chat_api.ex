defmodule ChatApp.Load.ChatAPI do
  @moduledoc """
  Adapter between load-testing code and the real ChatApp.User API.
  """

  @type username :: String.t()
  @type room :: String.t()
  @type message :: String.t()
  @type user_pid :: pid()

  # Create a real user GenServer
  def start_user(username) do
    ChatApp.User.start_link(username)
  end

  # Join a real room
  def join(user_pid, room) do
    case ChatApp.User.join(user_pid, room) do
      {:joined, _room_name} -> :ok
      other -> other
    end
  end

  # Send a real message
  def send_message(user_pid, message) do
    ChatApp.User.send_message(user_pid, message)
    :ok
  end

  # Stop user when a fake client dies
  def stop_user(user_pid) do
    ChatApp.User.stop(user_pid)
  end
end
