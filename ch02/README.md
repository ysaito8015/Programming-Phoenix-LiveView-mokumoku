# Chapter 2, Phoenix and Authentication
- build an authentication layer for the Pheonix application
- authentication allows us to:
    - Manage Users
    - Autheicate Requests
    - Manage Sessions
- how Phoenix handles web requests
    - same pattern at play in LiveView code


## CRC: Constructors, Reducers, and Converters
- Enum.reduce/3
- **Plug framework**
- *core* type
    - **String** module deals with strings
    - **Enum** deals with enumerables
- **Constructors** create a term of the core type from convenient inputs
- **Reducers** transform a term of the core type to another term of that type
- **Converters** convert the core type to some other type


```elixir
iex(1)> defmodule Number do
...(1)>   def new(string), do: Integer.parse(string) |> elem(0)
...(1)>   def add(number, addend), do: number + addend
...(1)>   def to_string(number), do: Integer.to_string(number)
...(1)> end
{:module, Number,
 <<70, 79, 82, 49, 0, 0, 6, 236, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 0, 199,
   0, 0, 0, 21, 13, 69, 108, 105, 120, 105, 114, 46, 78, 117, 109, 98, 101, 114,
   8, 95, 95, 105, 110, 102, 111, 95, 95, ...>>, {:to_string, 1}}
```


```elixir
iex(2)> list = [1, 2, 3]
[1, 2, 3]
iex(3)> total = Number.new("0")
0
iex(4)> reducer = &Number.add(&2, &1)
#Function<43.65746770/2 in :erl_eval.expr/5>
iex(5)> converter = &Number.to_string/1
&Number.to_string/1
iex(6)> Enum.reduce(list, total, reducer) |> converter.()
"6"
```


```elixir
iex(7)> [first, second, third] = list
[1, 2, 3]
iex(8)> "0" |> Number.new \
...(8)> |> Number.add(first) \
...(8)> |> Number.add(second) \
...(8)> |> Number.add(third) \
...(8)> |> Number.to_string
"6"
```


### CRC in Phoenix
- Phoenix processes requests with the CRC pattern
- the central type of many Phoenix modules is a *connection* struct defined by the **Plug.Conn** module
- the *connection* represents a web request
    - break down a response into a bunch of smaller reducers that each process a tiny part of the request


```elixir
connection
|> process_part_of_request(...)
|> process_part_of_request(...)
|> render(...)
```


- Phoenix converts the connection to a response with the **render/1** converter


```elixir
iex(4)> connection = %{request_path: "http://mysite.com/"} %{request_path: "http://mysite.com/"}
iex(5)> reducer = fn acc, key, value -> Map.put(acc, key, value) end
#Function<19.126501267/3 in :erl_eval.expr/5>
iex(6)> connection |> reducer.(:status, 200) |> reducer.(:body, :ok)
%{body: :ok, request_path: "http://mysite.com/", status: 200}
```


- each one is a reducer that accepts a **Plug.Conn** as an input, does some work, and returns a transformed **Plug.Conn**


### The **Plug.Conn** Common Data Structure
- Plug is a framework for building web programs
- Each function makes one little change to a connection - the **Plug.Conn** data structure
- empty **Plug.Conn** struct


```elixir
iex(1)> %Plug.Conn{}
%Plug.Conn{
  adapter: {Plug.MissingAdapter, :...},
  assigns: %{},
  body_params: %Plug.Conn.Unfetched{aspect: :body_params},
  cookies: %Plug.Conn.Unfetched{aspect: :cookies},
  halted: false,
  host: "www.example.com",
  method: "GET",
  owner: nil,
  params: %Plug.Conn.Unfetched{aspect: :params},
  path_info: [],
  path_params: %{},
  port: 0,
  private: %{},
  query_params: %Plug.Conn.Unfetched{aspect: :query_params},
  query_string: "",
  remote_ip: nil,
  req_cookies: %Plug.Conn.Unfetched{aspect: :cookies},
  req_headers: [],
  request_path: "",
  resp_body: nil,
  resp_cookies: %{},
  resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}],
  scheme: :http,
  script_name: [],
  secret_key_base: nil,
  state: :unset,
  status: nil
}
```


### Reducers in **Plug**
- Phoenix application's three main concepts
    - Plugs are reducer functions
    - They take a **Plug.Conn** struct as the first argument
    - They return a **Plug.Conn** struct


## Phoenix is One Giant Function
- the main sections of the giant Phoenix pipeline are the endpoint, the router, and the application


```elixir
connection_from_request
|> endpoint
|> router
|> custom_application # Phoenix controller, Phoniex channels, or a live view
```


### The Phoenix Endpoint
- Phoenix is a long chain of reducer functions called plugs,
- *the endpoint is the constructor* at the very beginning of that chain
- **endpoint.ex** has a pipeline of plugs
- every Phoenix request goes through an explicit list of functions called plugs
- the configuration followed by plugs defines the *socket* that will handle the communication for all of your live views
- eventually, requests flow through to the bottom of the pipeline to reach the router at the bottom


- ./lib/pento_web/endpoint.ex

```elixir
#...
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug PentoWeb.Router
```


### The Phoenix Router
- the router
    - a switchboard operator
    - to route the requests to the bits of code that are common pieces of *policy*
    - a policy defines how a given web request should be treated and handled
- the router does its job in three pars
    1. the router specifies chains of common functions to implemnet policy
    2. the router groups together common requests and ties each one to the correct policy
    3. the router maps individual requests onto the modules that do the hard work of buliding appropriate responses


- ./lib/pento_web/router.ex
    - plugs
        - mappings betweeen specific URLs and the code that implements those pages
        - each grouping of plugs provides *policy* for one or more routes


### Pipelines are Policies
- a *pipeline* is a grouping of plugs that applies a set of transformations to a given connection
- the set of transformations applied by a given plug represents a policy
- the **browser** pipeline implements the policy your application needs to process a request from a browser


- ./lib/pento_web/router.ex

```elixir
  pipeline :browser do
    plug :accepts, ["html"] # only accepts HTML requests
    plug :fetch_session     # fetch session
    plug :fetch_live_flash
    plug :put_root_layout, {PentoWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
```


### Scopes
- a scope block groups together common kinds of requests, possibly with a poicy

- ./lib/pento_web/router.ex

```elixir
  scope "/", PentoWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/guess", WrongLive
  end
```

- the **scope** expression means the provided block of routes between the **do** and **end** applies to *all routes*
- the **pipe_through :browser** statement means every matching request in this block will go through all of the plugs in the **:browser** pipeline


### Routes

```elixir
  live "/", PageLive, :index
```


- the individual routes
    - every route starts with a route type, a URL pattern, a module, and options
    - LiveView routes have the type **live**
    - the URL pattern in a route is a pattern matching statement
- the **PageLive** module
    - implements the code that responds to the request
- **:index** live action
    - a metadata about the request


### Plugs and Authentication
- start authentication planning


<img src='https://i.gyazo.com/9780e8502d3a6ca608360a057ac75082.png' width='500'>

- On the left side is the *infrastructure*
    - use a variety of services to store
        - long-term user data in the database,
        - short-term session data into cookies, and 
        - it will provide user interfaces to manage user interactions
- On the right side,
    - the Phoenix router will send appropriate requests through authentication plugs within the router and
    - these plugs will control access to custom live views, channels, and controllers


## Generate The Authentication Layer

-
