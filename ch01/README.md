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
    - examining how LiveView represents state via this struct

### Holds State in LiveView Sockets
- **sockets**
    - LiveView manages state in these structs
    - **Phonenix.LiveView.Socket** create these structs
    - the data that constitutes the live view's state
    - have all of the data that Phoenix needs to manage a LiveView connection
    - the data contained tin ths structs are mostly private
- **assigns: %{}**
    - keep all of a gien live ivew's custom data describing the state of the SPA
- summary
    - live view keeps data describing state in a **socket**
    - establish and update thet state by interacting with the socket struct's **:assigns** key


- run IEx on the pento directory


```
$ iex -S mix
```


```elixir
# request help socket
iex(1)> h Phoenix.LiveView.Socket

                            Phoenix.LiveView.Socket                             

The LiveView socket for Phoenix Endpoints.

This is typically mounted directly in your endpoint.

    socket "/live", Phoenix.LiveView.Socket


# make a new socket
iex(2)> Phoenix.LiveView.Socket.__struct__
#Phoenix.LiveView.Socket<
  assigns: %{__changed__: %{}},
  endpoint: nil,
  id: nil,
  parent_pid: nil,
  root_pid: nil,
  router: nil,
  transport_pid: nil,
  view: nil,
  ...
>
```


### Render the Live View
- understand how the LiveView lifecycle starts
1. Router
    - **live route**
        - special type of route
        - maps an incoming web request to a specified live view
            - so that a request to that endpoint will start up the live view process
    - define the route and map it to a fiven LiveView module
    - **live/3** function
        - the router calls the **mount/3** function on the module that is specified in live/3 function
2. Index.mount
    - **mount/3**
        - that live view process will initialize the live view's state by setting up the socket in this function
3. Index.render
    - the live view will **render** that state for the client

<img src='https://i.gyazo.com/1ddd0f33c9c4cf6bfa57e86535d63f73.png' width='500'>


#### 1. Router definition
- ./lib/pento_web/router.ex

```elixir
#...
  scope "/", PentoWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end
#...
```


- LiveView route defined with the **live/3** function
    - this will map the fiben incoming we request to the provided Live View module
    - 3rd option called a *live action*
    - **PentoWeb.PageLive**
        - the LiveView module that will handle requests to **/**
1. when your Phoenix app receives a request to the **/** route
2. the **PageLive** live view will start up, and
3. LiveView will invoke that module's **mount/3** function
    - **mount/3** function is responsible for establishing the initial state for the live view by populating the socket assigns


#### 2. Deficinition of mount/3 function
- ./lib/pento_web/live/page_live.ex


```elixir
#...
  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: %{})}
  end
#...
```


- **assign/2** helper function
    - adds key/value pairs to a given socket assigns
- **socket**
    - has the data reta representing the state of the live view
    - **:assigns** key, referred to as the "socket assigns", holds custom data
- this code is setting up the socket assigns with a search **query** string adn an empty **results** map
- **mount/3** function
    - return value
        - tuple
            - `{:ok, socket}`, or `{:error, socket}`


##### current data in the socket

```
%Socket{
  assigns: %{
    query: "",
    results: %{}
  }
}
```


#### 3. render function
- after the initial **mount*8 funishes, LiveView passes the value of the **socket.assigns** key to a **render** function
- if there is no **render** function,
    - LiveView looks for a template to render based on the name of the view


##### See template file
- ./lib/pento_web/live/page_live.html.leex

```
<input
  type="text"
  name="q"
  value="<%= @query %>"
  placeholder="Live dependency search"
  list="results"
  autocomplete="off"/>
```

- **<%= @wuery %>** expression
    - LiveView populates this code with the value of **socket.assigns.query**
        - which is setted in **mount**


#### After the initial web page is rendered
- LiveView establishes a persistent WebScoket connection and awaits events over thet connection


### Run the LiveView Loop
- When Phoenix processes a LiveView request, two things happen.
    1. Phoenix processes a plain HTTP request
        - the router invokes the LiveView module
        - the LiveView module calls the **mount/3** function and then **render/1**
        - the first pass renders a static, SEO-friendly page
    2. opens a persistent connection between the client and the server using WebSockets
- After Phoenix opens the WebSocket connection
    - the LiveView program calls **mount/3** and **render/1** *again*
    - the LiveView lifecycle starts up the *LiveView loop*
        - the live view can now receive events, change the state, and render the state again
- <img src='https://i.gyazo.com/bf3046cc2ede2a7dbf591187d56ef903.png' width='500'>
- During the LiveView loop
    - we have to implement our own event handler functions, and teach them how to change state
    - once our handlers have changed the state,
        - LiveView triggers a new render based on those changes
    - LiveView returns to the top of the loop to process more events


## Build a Simple Live View
- simple game
- three things
    1. build a route
    2. render a page
    3. handle the events


### Define the Route
- **live routes**
    - are defined in the Phoenix application's router
- ./lib/pento_web/router.ex
    - add "/guess" routing
- LiveView routes are defined with a call to the **live** macro and point to a long-running live view
    - the initial HTTP request and response will flow through this route

```elixir
#...
  scope "/", PentoWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/guess", WrongLive
  end
#...
```


### Render the LiveView
- ./lib/pent_web/live/wront_live.ex
    - `defmodule PentoWeb.WrongLive do end`
    - `use PentoWeb, :live_view`
    - define `mount/3` with three parameters
        - `_session`
            - request
        - `_params`
            - input parameters
        - `socket`
            - struct
            - the socket is nothing more than a representation of the state for a LiveView
        - **assign/3** function puts custom data into the **socket.assigns** map
            - **assigns.score** = 0
            - **assigns.message** = "Guess a number."


```elixir
defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket,
        score: 0,
        message: "Guess a number."
      )
    }
  end
end
```

#### current socket data

```
%{
  assigns: %{
    score: 0,
    message: "Guess a number."
  }
}
```


#### Build markup
- ./lib/pento_web/live/wrong_live.ex
    - `~L""" ... """` bracket HTML code
        - `~L` is sigil
        - this means there's a functio ncalled **sigil_L**
            - the processing of template replacements
    - *LEEx*
        - a language which process the expression between `<%=` and `%>`
        - `@message` and `@score` expressions are keys from the **socket.assings** map


```elixir
#...
  def render(assigns) do
    ~L"""
    <h1>Your score: <%= @score %></h1>
    <h2>
      <%= @message %>
    </h2>
    <h2>
      <%= for n <- 1..10 do %>
        <a href="#" phx-click="guess" phx-balue-number="<%= n %>"><%= n %></a>
      <% end %>
    </h2>
    """
  end
#...
```


<img src='https://i.gyazo.com/75ddf09baed06b856099f35573b83287.png' width='500'>

- Error message on hte console
    - it wasn't ready to handle
- When the event came in, LiveView called the function **handle_event("guess", some-map_data, socket)**


```
[error] GenServer #PID<0.716.0> terminating
** (UndefinedFunctionError) function PentoWeb.WrongLive.handle_event/3 is undefined or private
    (pento 0.1.0) PentoWeb.WrongLive.handle_event("guess", %{}, #Phoenix.LiveView.Socket<assigns: %{__changed__: %{}, flash: %{}, live_action
: nil, message: "Guess a number.", score: 0}, endpoint: PentoWeb.Endpoint, id: "phx-Fr8Q5j1O-H3-mgKH", parent_pid: nil, root_pid: #PID<0.716.
0>, router: PentoWeb.Router, transport_pid: #PID<0.713.0>, view: PentoWeb.WrongLive, ...>)
```


### Handle Events
- maching the inbound data
- the inbound data will trigger the function **handle_event/3** function
    - arguments
        1. **phx-click**
            - the message name
        2. **%{}** a map
            - with the metadata related to the event
        3. **socket**
            - state of the LiveView

#### Implement the handle_event/3 function

```elixir
def handle_event("guess", %{"number" => guess} = data, socket) do
  IO.inspect data
  message = "Your guess: #{guess}, Wrong. Guess again."
  score = socket.assigns.score - 1

  {
    :noreply,
    assign(
      socket,
      message: message,
      score: score
    )
  }
end
```

- using a pattern matching
    - it matches only function calls
        - where the first argument is "guess", and
            - (set in the **phx-click** at the template file)
        - the second is a map with a key of "number"
            - (set in the **phx-value** at the template file)
- to change the LiveView's state based on the inbound event
    - to transform the data within **socket.assigns**
        - score - 1
        - new message
        - new data in the **socket.assigns** map
- return value
    - taple **{:noreply, socket}**
- this update to **socket.assigns** triggers the LiveView to re-render by sending some changes down to the client


## LiveView Transfers Data Efficiently
- how LiveView transfers data to the client over the WebSocket connection
- LiveView re-renders the page by sending UI changes down to the client in response to state changes


### examine the network traffic in the browser
- get into habit of inspecting the network traffic when developing the LiveView


### Examine Network Traffic
- Inspection WebSockets on Firefox
    - https://developer.mozilla.org/en-US/docs/Tools/Network_Monitor/Inspecting_web_sockets
- browser to LiveView
    - <img src='https://i.gyazo.com/1b369846e7cf8909794a6924fd90a332.png' width='500'>


```JSON
[
  "4","5", "lv:phx-Fr-BqBPeeqRaAgBF",
  "event", {"type":"click","event":"guess",
    "value":{"number":"8"}
  }
]
```

- this data is information about the mouse click, including whether certain keys were pressed


- LiveView to browser
    - <img src='https://i.gyazo.com/2fb52a876fc8e6a403c094e54b8363ab.png' width='500'>


```JSON
[
  "4","5","lv:phx-Fr-Cq5mqXrRjhwJE", "phx_reply",
  {
    "response":{
      "diff":{
        "0":"-1",
        "1":"Your guess: 7. Wrong. Guess again."
      }
    },
    "status":"ok"
  }
]
```


- the data that LiveView has sent over the WebSocket connection in response to some state change
    - including the score and message it was set in the **handle_event/3** function
- "diff" part
    - it represents the changes in the view *since the last time it was renderd*


### Send Network Diffs
- how LiveView actually detects the changes to send down to hte client
- update **render** function


```elixir
  def render(assigns) do
    ~L"""
    <h1>Your score: <%= @score %></h1>
    <h2>
      <%= @message %>
      It's <%= time() %>
    </h2>
    <h2>
      <%= for n <- 1..10 do %>
        <a href="#" phx-click="guess" phx-value-number="<%= n %>"><%= n %></a>
      <% end %>
    </h2>
    """
  end

  def time() do
    DateTime.utc_now |> to_string
  end
```


- <img src='https://i.gyazo.com/92d5d86af2a28eb7bc8873e28d17b439.png' width='500'>
- <img src='https://i.gyazo.com/5f4e71175c8611c2c7fd495a17666145.png' width='500'>
    - the time is *exactly the same*
    - we didin't give LiveView any way to determine that the value should change and re-rendered
- When you want to track changes, make sure to use socket assigns values such as **@score** in your template
- LiveView keeps track of the data in socket assigns and any changes to that data instruct LiveView to send a diff down to the client


### LiveView's Efficiency is SEO Friendly
- after refresh the page
    - Phoenix sends the main page and the assets just as it normally would for any HTTP request/response


## Your Turn
- LiveView is a livrary for building highly interactive single-page web flows called live views
- A live view:
    - Has internal state
    - Has a render function to render that state
    - Receives events which change state
    - Calls the render function when state changes 
    - Only sends changed data to the browser
    - Needs no custom JavaScript
- When we build live views, we focus on managing and rendering our view's state
    - called a socket
- manage our live view's state
    - by assigning an initial value in the **mount/3** function and
    - by updating that value using several handler functions
- After a handler function is invoked, LiveView renders the changed state with the **render/1** function


### Give It a Try
- task list
    - assign a rundom number to the **socket** when the game is created, one the user will need to guess
    - Check for that number in the **handle_event** for **guess**
    - Award points for a right guess
    - Show a winning message when the user wins
    - Show a restart message and button when the user wins


### Next Time
- next chapter, beginning with the authentication layer
    - using a code generator
- explore how Phoenix requests work, and how to use the generated authentication service to authenticate users
