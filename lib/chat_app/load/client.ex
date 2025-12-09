defmodule ChatApp.Load.Client do
  use GenServer

  alias ChatApp.Load.ChatAPI

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    username = Keyword.fetch!(opts, :username)
    room = Keyword.fetch!(opts, :room)

    # 1. Start real ChatApp.User process
    {:ok, user_pid} = ChatAPI.start_user(username)

    # 2. Join real room
    :ok = ChatAPI.join(user_pid, room)

    # 3. Start message loop
    schedule_send()

    {:ok,
     %{
       username: username,
       room: room,
       user_pid: user_pid
     }}
  end

  @impl true
  def handle_info(:send_message, state) do
    ChatAPI.send_message(
      state.user_pid,
      random_message()
    )

    schedule_send()
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    ChatAPI.stop_user(state.user_pid)
    :ok
  end

  # ---- Helpers ----

  defp schedule_send do
    delay = :rand.uniform(2000) + 500
    Process.send_after(self(), :send_message, delay)
  end

  defp random_message do
    Enum.random([
      "hello",
      "testing",
      "load test",
      "ping",
      "scaling now",
      "BEAM under pressure",
      "distributed systems!"
    ])
  end
end
