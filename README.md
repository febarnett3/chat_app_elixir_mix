# ChatApp

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chat_app` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chat_app, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/chat_app>.

ONE-TIME SETUP (you only do this once per computer)

1. Open Erlang distribution ports on BOTH machines

   Run PowerShell as Administrator:

   netsh advfirewall firewall add rule name="EPMD 4369" dir=in action=allow protocol=TCP localport=4369
   netsh advfirewall firewall add rule name="Erlang Dist" dir=in action=allow protocol=TCP localport=42000-42100

2. Add hosts file entries on BOTH machines

   (use the IPv4 addresses from the CURRENT network)

   Example:

   <Surface IPv4> Fiona-Surface
   <PC IPv4> PC-Laptop

You only need to redo this when your network changes.

EVERY TIME YOU DEVELOP (normal workflow)
Start the SERVER (Surface)

Run this from the project folder:

(for just locally)
iex.bat --sname server --cookie chat_cookie -S mix

(for across different devices)
iex --sname server --cookie chat_cookie --erl "-kernel inet_dist_listen_min 42000 inet_dist_listen_max 42100" -S mix

Server node will be:

server@Fiona-Surface (for me lol)

Build the CLI (only when you change CLI code)

Run on each client machine when you change CLI code:

mix escript.build

This regenerates:

chat_app

You do NOT need to rebuild if you didn’t change CLI code.

Start a CLIENT (PC or Surface)
escript chat_app

Connect the client to the server

Inside the chat CLI:
/connect server
/login Alice (or any name)
/join lobby (or any room name)

Send a message
/send Hello everyone!

Leave a room
/leave

Quit the client
/quit

RAW NETWORK TEST (only for debugging)

If something ever breaks:

On Surface:
iex.bat --sname server --cookie chat_cookie --erl "-kernel inet_dist_listen_min 42000 inet_dist_listen_max 42100"

On PC:
iex.bat --sname client --cookie chat_cookie --erl "-kernel inet_dist_listen_min 42000 inet_dist_listen_max 42100"

Then on PC:
Node.connect(:"server@Fiona-Surface")

true = network is perfect
false = firewall, hosts, or network isolation issue

WHAT YOU MUST ALWAYS REMEMBER
Rule Required
Server MUST use --sname Always
Cookies MUST match Always
Firewall ports must be open Once
Hosts file must match current network When network changes
mix escript.build after CLI changes When needed

MINIMAL DAILY COMMAND SET

If everything is already set up, your daily commands are just:

Server:
iex --sname server --cookie chat_cookie --erl "-kernel inet_dist_listen_min 42000 inet_dist_listen_max 42100" -S mix

Client:
escript chat_app

Then:

/connect server
/login Alice
/join lobby
/send hello!

USING TAILSCALE WITH THE LAB/MULTIPLE COMPUTERS

Your Final Distributed Architecture (Correct)

Once Tailscale is enabled:

🖥 Your Laptop (SERVER)

    Runs:
    iex --sname server --cookie chat_cookie -S mix


    This machine:
      Hosts all ChatApp.User
      Hosts all ChatApp.Conversation
      Receives all traffic

🖥 Lab Machine #1 (LOAD)

    Runs:
    iex --sname load1 --cookie chat_cookie -S mix

    Then:
    Node.connect(:"server@TAILSCALE_NAME")
    ChatApp.Load.Spawner.start_clients(1_000, 50, 0)

🖥 Lab Machine #2 (LOAD)
Node.connect(:"server@TAILSCALE_NAME")
ChatApp.Load.Spawner.start_clients(1_000, 50, 100_000)

🖥 Lab Machine #3 (LOAD)
Node.connect(:"server@TAILSCALE_NAME")
ChatApp.Load.Spawner.start_clients(1_000, 50, 200_000)

All users connect to the same server
All names are unique
All rooms are valid
All load is centralized for measurement
