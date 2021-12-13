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
- **phx.gen.auth** is an application generator that builds a well-structured authentication layer
- how to use the generator to build an authentication layer
- how the pieces of generated code fit together to handle the responsibilities of authentication
- how LiveView uses the authentication service to identify and operate on the logged in user


### Add the Dependency
- phx_gen_auth (This repository has been archived)
    - https://github.com/aaronrenner/phx_gen_auth
- hexdocs.pm
    - https://hexdocs.pm/phoenix/1.6.4/mix_phx_gen_auth.html


### Run the Generator
- running **mix phx.gen.auth** creates a context and a schema module
    - a context module as an API for a service
    - a schema module as a data structure describing a data base table


```shell
$ mix phx.gen.auth Accounts User users
```

- output

```shell
Compiling 16 files (.ex)
Generated pento app
* creating priv/repo/migrations/20211213204407_create_users_auth_tables.exs
* creating lib/pento/accounts/user_notifier.ex
* creating lib/pento/accounts/user.ex
* creating lib/pento/accounts/user_token.ex
* creating lib/pento_web/controllers/user_auth.ex
* creating test/pento_web/controllers/user_auth_test.exs
* creating lib/pento_web/views/user_confirmation_view.ex
* creating lib/pento_web/templates/user_confirmation/new.html.heex
* creating lib/pento_web/templates/user_confirmation/edit.html.heex
* creating lib/pento_web/controllers/user_confirmation_controller.ex
* creating test/pento_web/controllers/user_confirmation_controller_test.exs
* creating lib/pento_web/templates/layout/_user_menu.html.heex
* creating lib/pento_web/templates/user_registration/new.html.heex
* creating lib/pento_web/controllers/user_registration_controller.ex
* creating test/pento_web/controllers/user_registration_controller_test.exs
* creating lib/pento_web/views/user_registration_view.ex
* creating lib/pento_web/views/user_reset_password_view.ex
* creating lib/pento_web/controllers/user_reset_password_controller.ex
* creating test/pento_web/controllers/user_reset_password_controller_test.exs
* creating lib/pento_web/templates/user_reset_password/edit.html.heex
* creating lib/pento_web/templates/user_reset_password/new.html.heex
* creating lib/pento_web/views/user_session_view.ex
* creating lib/pento_web/controllers/user_session_controller.ex
* creating test/pento_web/controllers/user_session_controller_test.exs
* creating lib/pento_web/templates/user_session/new.html.heex
* creating lib/pento_web/views/user_settings_view.ex
* creating lib/pento_web/templates/user_settings/edit.html.heex
* creating lib/pento_web/controllers/user_settings_controller.ex
* creating test/pento_web/controllers/user_settings_controller_test.exs
* creating lib/pento/accounts.ex
* injecting lib/pento/accounts.ex
* creating test/pento/accounts_test.exs
* injecting test/pento/accounts_test.exs
* creating test/support/fixtures/accounts_fixtures.ex
* injecting test/support/fixtures/accounts_fixtures.ex
* injecting test/support/conn_case.ex
* injecting config/test.exs
* injecting mix.exs
* injecting lib/pento_web/router.ex
* injecting lib/pento_web/router.ex - imports
* injecting lib/pento_web/router.ex - plug
* injecting lib/pento_web/templates/layout/root.html.heex

Please re-fetch your dependencies with the following command:

    $ mix deps.get

Remember to update your repository by running migrations:

    $ mix ecto.migrate

Once you are ready, visit "/users/register"
to create your account and then access to "/dev/mailbox" to
see the account confirmation email.

```

- re-fetch the dependencies and update the repository

```shell
$ mix deps.get
```

- output


```shell
Resolving Hex dependencies...
Dependency resolution completed:
Unchanged:
  castore 0.1.13
  connection 1.1.0
  cowboy 2.9.0
  cowboy_telemetry 0.4.0
  cowlib 2.11.0
  db_connection 2.4.1
  decimal 2.0.0
  ecto 3.7.1
  ecto_sql 3.7.1
  esbuild 0.4.0
  file_system 0.2.10
  floki 0.32.0
  gettext 0.18.2
  html_entities 0.5.2
  jason 1.2.2
  mime 2.0.2
  phoenix 1.6.2
  phoenix_ecto 4.4.0
  phoenix_html 3.1.0
  phoenix_live_dashboard 0.5.3
  phoenix_live_reload 1.3.3
  phoenix_live_view 0.16.4
  phoenix_pubsub 2.0.0
  phoenix_view 1.0.0
  plug 1.12.1
  plug_cowboy 2.5.2
  plug_crypto 1.2.2
  postgrex 0.15.13
  ranch 1.8.0
  swoosh 1.5.2
  telemetry 1.0.0
  telemetry_metrics 0.6.1
  telemetry_poller 1.0.0
New:
  bcrypt_elixir 2.3.0
  comeonin 5.3.2
  elixir_make 0.6.3
* Getting bcrypt_elixir (Hex package)
* Getting comeonin (Hex package)
* Getting elixir_make (Hex package)
```


### Run Migrations
- Elixir separates the concepts of working with database *records* from that of working with database *structure*
    - the generator gave us the "database structure" code in the form of a set of Ecto migrations for creating database tables
- [Programming Ecto](https://pragprog.com/titles/wmecto/programming-ecto/)


```shell
$ mix ecto.migrate
```

- output

```shell
==> comeonin
Compiling 4 files (.ex)
Generated comeonin app
==> elixir_make
Compiling 1 file (.ex)
Generated elixir_make app
==> bcrypt_elixir
mkdir -p /home/ysaito/projects/elixir-mokumoku/Programming-Phoenix-LiveView-mokumoku/ch02/pento/_build/dev/lib/bcrypt_elixir/priv
cc -g -O3 -Wall -Wno-format-truncation -I"/home/ysaito/erlang/24.1.6/erts-12.1.5/include" -Ic_src -fPIC -shared  c_src/bcrypt_nif.c c_src/blo
wfish.c -o /home/ysaito/projects/elixir-mokumoku/Programming-Phoenix-LiveView-mokumoku/ch02/pento/_build/dev/lib/bcrypt_elixir/priv/bcrypt_ni
f.so
Compiling 3 files (.ex)
Generated bcrypt_elixir app
==> pento
Compiling 31 files (.ex)
Generated pento app

22:04:23.725 [info]  == Running 20211213204407 Pento.Repo.Migrations.CreateUsersAuthTables.change/0 forward

22:04:23.728 [info]  execute "CREATE EXTENSION IF NOT EXISTS citext"

22:04:23.751 [info]  create table users

22:04:23.757 [info]  create index users_email_index

22:04:23.758 [info]  create table users_tokens

22:04:23.764 [info]  create index users_tokens_user_id_index

22:04:23.765 [info]  create index users_tokens_context_token_index

22:04:23.767 [info]  == Migrated 20211213204407 in 0.0s
```


### Test the Service

```shell
$ mix test
```


- output


```shell
Compiling 35 files (.ex)
Generated pento app
.........................................................................................................

Finished in 0.4 seconds (0.3s async, 0.1s sync)
105 tests, 0 failures

Randomized with seed 353227
```


## Explore Accounts from IEx
- exploration
    - reading code
    - looking at the public functions in IEx
        - **export** function
- look at the various things that it can *do*
- **Account** context
    - is the layer that we will use to create, read, update, and delete users in the database
    - provides an API through which all of these databaes transactions occur
    - looks up user
    - a *token* in the database to keep the application secure
    - to securely update users email or password


### View Public Functions

```shell
$ iex -S mix
```

- use **exports Accounts**

```elixir
iex(1)> alias Pento.Accounts
Pento.Accounts

iex(2)> exports Accounts
apply_user_email/3                 change_user_email/1                change_user_email/2                
change_user_password/1             change_user_password/2             change_user_registration/1         
change_user_registration/2         confirm_user/1                     delete_session_token/1             
deliver_update_email_instructions/3deliver_user_confirmation_instructions/2deliver_user_reset_password_instructions/2
generate_user_session_token/1      get_user!/1                        get_user_by_email/1                
get_user_by_email_and_password/2   get_user_by_reset_password_token/1 get_user_by_session_token/1        
register_user/1                    reset_user_password/2              update_user_email/2                
update_user_password/3             
```


- functions work with new users
    - **register_user/1**
    - **confirm_user/1**
- functions for managing the user's session
    - **delete_session_token/1**
    - **generate_user_session_token/1**
- functions for looking up users
    - **get_user!/1**
    - **get_user_by_email/1**
    - **get_user_by_email_and_password/2**
    - **get_user_by_reset_password_token/1**
    - **get_user_by_session_token/1**
- functions for changing users
    - **reset_user_password/2**
    - **update_user_password/3**
    - **update_user_email/2**


### Create a Valid User
- create a user


```elixir
iex(3)> params = %{email: "mercutio@grox.io", password: "R0sesBy0therNames"}
%{email: "mercutio@grox.io", password: "R0sesBy0therNames"}

iex(4)> Accounts.register_user(params)
[debug] QUERY OK source="users" db=0.8ms decode=0.6ms queue=1.2ms idle=276.3ms
SELECT TRUE FROM "users" AS u0 WHERE (u0."email" = $1) LIMIT 1 ["mercutio@grox.io"]
[debug] QUERY OK db=2.2ms queue=0.8ms idle=501.8ms
INSERT INTO "users" ("email","hashed_password","inserted_at","updated_at") VALUES ($1,$2,$3,$4) RETURNING "id" ["mercutio@grox.io", "$2b$12$X
2cQ4Z9KnDQZ7/YaybCHOuzR1yQ96FbjrU5/QIt6ulOlfQk5b.ZIG", ~N[2021-12-13 21:50:55], ~N[2021-12-13 21:50:55]]
{:ok,
 #Pento.Accounts.User<
   __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
   confirmed_at: nil,
   email: "mercutio@grox.io",
   id: 1,
   inserted_at: ~N[2021-12-13 21:50:55],
   updated_at: ~N[2021-12-13 21:50:55],
   ...
 >}
```


- the **Account** context created a changeset, and seeing valid data, it inserted an account record into the database
    - the result is an **{:ok, user}** tuple


### Try to Create an Invalid User


```elixir
iex(5)> Accounts.register_user(%{})
{:error,
 #Ecto.Changeset<
   action: :insert,
   changes: %{},
   errors: [
     password: {"can't be blank", [validation: :required]},
     email: {"can't be blank", [validation: :required]}
   ],
   data: #Pento.Accounts.User<>,
   valid?: false
 >}
```

- the result is **{:error, changeset}**
- invalid changesets say why they are invalid with a list of **errors**


## Protect Routes with Plugs
- ./lib/pento_web/controllers/user_auth.ex
    - the authentication service is defined


```shell
$ iex -S mix
```

- output

```elixir
iex(6)> exports PentoWeb.UserAuth
fetch_current_user/2               log_in_user/2                      log_in_user/3                      
log_out_user/1                     redirect_if_user_is_authenticated/2require_authenticated_user/2       
```

- all of these functions are plugs


### Fetch the Current User
- plugs are *reducers* that
    - take a **Plug.Conn** as the first argument and
    - return a transformed **Plug.Conn**
- **assigns** map that we *can* use to store custom application data


- ./lib/pent_web/router.ex


```elixir
  import PentoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PentoWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end
```


- any code that hondles routes tied to the **browser** pipeline will have access to the **current_user** in **conn.assigns.current_user**


- ./lib/pento_web/templates/layout/_user_menu.html.heex
    - this layout's user menu uses the **current_user**
        - stored in the connection's **assigns** and
        - accessed in the template via **@current_user**


```html
<ul>
<%= if @current_user do %>
  <li><%= @current_user.email %></li>
  <li><%= link "Settings", to: Routes.user_settings_path(@conn, :edit) %></li>
  <li><%= link "Log out", to: Routes.user_session_path(@conn, :delete), method: :delete %></li>
<% else %>
  <li><%= link "Register", to: Routes.user_registration_path(@conn, :new) %></li>
  <li><%= link "Log in", to: Routes.user_session_path(@conn, :new) %></li>
<% end %>
</ul>
```


### Authenticate a User
- Phoenix works by chaining together plugs that manipulate a session
- **UserAuth.log_in_user** function also sets up a unique identifier for the LiveView sessions

```elixir
iex(1)> h PentoWeb.UserAuth.log_in_user

                   def log_in_user(conn, user, params \\ %{})                   

Logs the user in.

It renews the session ID and clears the whole session to avoid fixation
attacks. See the renew_session function to customize this behaviour.

It also sets a :live_socket_id key in the session, so LiveView sessions are
identified and automatically disconnected on log out. The line can be safely
removed if you are not using LiveView.

```


- ./lib/pento_web/controllers/user_session_controller.ex
    - **UserAuth.log_in_user** function is used in this file
    - pluck the email and password from the inbound params sent by the login form
    - use the context to check to see whether the user exists and
    - has provided a valid password
        - if not, we render the login page again with an error


```elixir
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end
```


- ./lib/pento_web/controllers/user_auth.ex
    - build a token and grab the redirect path from the session, then
    - renew the **session** for security's sake,
        - adding both the token and a unique identifier to the session
    - create a **remember_me** cookie if the user has selected that option
    - redirect the user


```elixir
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end
```


## Authenticate The Live View
- how to protect authenticated LiveView routes and
- how to identify the authenticated user in a live view
1. put the live route behind authentication
2. update the **mount/3** function to use the token from the session to find the logged un user


### Protect Sensitive Routes
- 
