defmodule ChatApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Registry for conversations
      {Registry, keys: :unique, name: ChatApp.Registry},

      # 2. Dynamic supervisor for conversation processes
      {DynamicSupervisor, strategy: :one_for_one, name: ChatApp.ConversationSupervisor},

      # 3. Registry for users
      {Registry, keys: :unique, name: ChatApp.UserRegistry},

      # 4. Dynamic supervisor for user processes
      {DynamicSupervisor, strategy: :one_for_one, name: ChatApp.UserSupervisor}
    ]


    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
