# Chapter 1, Get To Know LiveView
- 

## Single-Page Apps are Distributed System


### Distributed Systems are Complex
- MV(T)C モデルの図


### SPAs are Hard


## LiveView Makes SPAs Easy
- LiveView will *receive events,* live link clicks, key presses, or page submits
- Based on those events, you'll *change your staete*
- After you change your state, LiveView will rerender *only the portions of the page that are affected by the changed state*.
- Agter rendaring, LiveView again waits for events, and we go back to the top


### LiveView, Elixir, and OTP
- LiveView relies heavily on the use of Phoenix cannels
    - the details of channel-based communication


## Program LiveView Like a Professional


## INstall Elixir, Postgres, PHoenix, and LiveView
- Elixir >= 1.10
- Erlang >= 21
- Phoenix 1.5


## Create a Phoenix Project

```shell
$ mix phx.new pento --live
```


### Create The Database and Run The Server

```shell
$ cd ./pento
$ mix deps.get
# Phoenix v1.6.2 では webpack をつかっていない
$ cd asset && npm install && node node_modules/webpack/bin/webpack.js -- mode development
$ mix ecto.create
$ mix phx.server
```


### View Mix Dependencies

- ./mix.exs
    - LiveView dependencies are...
        - for system monitoring
            - phoenix_live_view
            - phoenix_live_dashboard
        - for test
            - floki


```
#...
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.16.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"}
    ]
  end
#...
```


## The LiveView Lifecycle
- LiveView lifecycle
    - how LiveView manages the state of the single-page app in a data structure called a **socket**
    - how LiveView
        - starts up,
        - renders the page for the user and
        - responds to events
- **Phoenix.LiveView.Socker** structs
