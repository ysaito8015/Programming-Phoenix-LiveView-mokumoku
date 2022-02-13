# Chapter 5, Forms and Chnagesets
- HTML provides forms to represent complex data
- in single-page apps, form interactions go beyond one-time submissions with a single response
- Phoenix forms *are* representations of chnagesets in the user interface
- how to compose LiveView code specifically, and Phoniex code generally, to manage change


## Model Change with Cangesets
- the role of forms and chnagesets in the application

- Ecto changesets
- Changesets are policies for chnaging data and they play these roles
    - Changesets *cast unstructured user data* into a known, structured form
        - most commonly, an Ecto database shcema, ensuring data *safety*
    - Changesets *capture differences* between safe, consistent data and proposed change, allowing *efficiency*
    - Changesets *validate data* using known consistent rules, ensuring data *consistency*
    - Changesets provide a *contract* for communication error states and vlid states, ensuring a *common interface for change*

- **Product.chnageset/2** function


```elixir
def changeset(product, attrs) do
  product
  |> cast(attrs, [:name, :description, :unit_price, :sku]
  |> validate_required([:name, :description, :unite_price, :sku])
  |> unique_constraint(:sku)
end
```


- **changeset/2** function captures differences betwwen the structured **product** and the unstructured **attrs**
- **cast/4**, the changeset tirims the attributes to a known field list and converts to the correct types, ensuring dafety by guaranteeing
- **validate/2** and **unique_constraint/2** functions validate the inbound data, ensuring consistency
- the results is a data structure with known states and error message formats, ensuring interface compatibility
- this chapter
    - how versatile changesets can be when it comes to modeling chnages to data , with or without a database
    - build a custom, chemaless chnageset for data that *isn't* backed by a database table
    - use that changeset in a form within a live view


## Model Change with Schemaless Changesets
- schenarios in which we want to present the user with the ability to input data that *isn't* persisted
- chnagesets
    - those scenarios require presenting some interface to the user for
        - collecting input,
        - validating that input, and
        - managing the results of that validation
    - this is what changesets and forms did in the **ProductLive** views
- how to use schemaless changesets to model data that isn't saved in the database


### Build Schemaless Changesets from Structs
- use changesets with basic Elixir structs or maps
    - don't need to use Ecto schemas to generate those structs
    - but, the code needs to provide the type information Ecto would normally handle


#### **Ecto.Changeset.cast/4**
- the first argument
    - tuple containing the struct and a map of the struct's attribute types


##### define the Player struct and declear it

```elixir
iex(1)> defmodule Player do
...(1)>   defstruct [:username, :age]
...(1)> end
{:module, Player,
 <<70, 79, 82, 49, 0, 0, 7, 28, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 0, 195,
   0, 0, 0, 19, 13, 69, 108, 105, 120, 105, 114, 46, 80, 108, 97, 121, 101, 114,
   8, 95, 95, 105, 110, 102, 111, 95, 95, ...>>,
 %Player{age: nil, username: nil}}
iex(2)> player = %Player{}
%Player{age: nil, username: nil}
```

##### view the help

```elixir
iex(3)> h Ecto.Changeset.cast/4

                 def cast(data, params, permitted, opts \\ [])                  

  @spec cast(
          Ecto.Schema.t() | t() | {data(), types()},
          %{required(binary()) => term()}
          | %{required(atom()) => term()}
          | :invalid,
          [atom()],
          Keyword.t()
        ) :: t()

Applies the given params as changes for the given data according to the given
set of permitted keys. Returns a changeset.

The given data may be either a changeset, a schema struct or a {data, types}
tuple. The second argument is a map of params that are cast according to the
type information from data. params is a map with string keys or a map with atom
keys containing potentially invalid data.

During casting, all permitted parameters whose values match the specified type
information will have their key name converted to an atom and stored together
with the value as a change in the :changes field of the changeset. All
parameters that are not explicitly permitted are ignored.

If casting of all fields is successful, the changeset is returned as valid.

Note that cast/4 validates the types in the params, but not in the given data.

## Options

  • :empty_values - a list of values to be considered as empty when
    casting. Defaults to the changeset value, which defaults to [""]

## Examples

    iex> changeset = cast(post, params, [:title])
    iex> if changeset.valid? do
    ...>   Repo.update!(changeset)
    ...> end

Passing a changeset as the first argument:

    iex> changeset = cast(post, %{title: "Hello"}, [:title])
    iex> new_changeset = cast(changeset, %{title: "Foo", body: "World"}, [:body])
    iex> new_changeset.params
    %{"title" => "Hello", "body" => "World"}

Or creating a changeset from a simple map with types:

    iex> data = %{title: "hello"}
    iex> types = %{title: :string}
    iex> changeset = cast({data, types}, %{title: "world"}, [:title]) 
    iex> apply_changes(changeset)
    %{title: "world"}

## Composing casts

cast/4 also accepts a changeset as its first argument. In such cases, all the
effects caused by the call to cast/4 (additional errors and changes) are simply
added to the ones already present in the argument changeset. Parameters are
merged (not deep-merged) and the ones passed to cast/4 take precedence over the
ones already in the changeset.


```


- the key
    - "The given data may be either a chnageset, a schema struct or a {data, types}"
        - a chnageset or a schema struct, both of which embed data and type information
        - *or*
        - a two tuple that explicity that contains the data as the first element and provides type information as the second



##### Create a changeset

- create a changeset from a struct and a map which has types of struct fields
    - then cast changeset with attributes and keys of map of types

```elixir
iex(5)> types = %{username: :string, age: :integer}
%{age: :integer, username: :string}
iex(6)> attrs = %{username: "player1", age: 20}
%{age: 20, username: "player1"}
iex(7)> changeset = {player, types} \
...(7)>   |> Ecto.Changeset.cast(attrs, Map.keys(types))
#Ecto.Changeset<
  action: nil,
  changes: %{age: 20, username: "player1"},
  errors: [],
  data: #Player<>,
  valid?: true
>
```


##### write validations


```elixir
iex(8)> changeset = {player, types} \                               
...(8)>   |> Ecto.Changeset.cast(attrs, Map.keys(types)) \          
...(8)>   |> Ecto.Changeset.validate_number(:age, greater_than: 16) 
#Ecto.Changeset<
  action: nil,
  changes: %{age: 20, username: "player1"},
  errors: [],
  data: #Player<>,
  valid?: true
>
```


##### check with not valid data

```elixir
iex(10)> attrs = %{username: "player2", age: 15}                    
%{age: 15, username: "player2"}
iex(11)> changeset = {player, types} \                              
...(11)>   |> Ecto.Changeset.cast(attrs, Map.keys(types)) \         
...(11)>   |> Ecto.Changeset.validate_number(:age, greater_than: 16)
#Ecto.Changeset<
  action: nil,
  changes: %{age: 15, username: "player2"},
  errors: [
    age: {"must be greater than %{number}",
     [validation: :number, kind: :greater_than, number: 16]}
  ],
  data: #Player<>,
  valid?: false
>
```


## Use Schemaless Changesets in LiveView
- an scenario that provides a promo code to a email
    - a form for the promo recipients' email
    - but we won't be storing this email in our database
- use a chemaless changeset to cast and validate the form input
- we need ...
    - a new **/promo** live view with a form backed by a schemaless changeset
    - the form will collect a name and email for a recipient
- core module
    - **Promo.Recipient**
        - model the data for a promo recipient
        - has a converter to produce the changeset that works with the live view's form
- context module
    - **Promo**
        - provide an iterface for interacting with **Promo.Recipient** changesets
    - the context is the boundary layer between the predictable core and the outside world
    - it will be respoinsible for
        - receiving the uncertain form input from the user and
        - translating it into predictable changesets
    - also interact with potentially unreliable external services
- live view
    - **PromoLive**
        - will manage the user interface
        - we will provide users with a form through which they can input the promo recipients's name and email
        - will manage the state of the page in response to invalid inputs or valid form submissions


### The Promo Boundary and Core
##### the core of the promo feature
- ./lib/pento/promo/recipient.ex


```elixir
defmodule Pento.Promo.Recipient do
  defstruct [:first_name, :email]
end
```


##### define types of the struct fields


```elixir
defmodule Pento.Promo.Recipient do
  defstruct [:first_name, :email]
  @types %{first_name: :string, email: :string}
end
```

##### alias the module and import **Ecto.Changeset**

```elixir
defmodule Pento.Promo.Recipient do
  defstruct [:first_name, :email]
  @types %{first_name: :string, email: :string}

  alias Pento.Promo.Recipient

  import Ecto.Changeset
end
```

##### define the **changeset/2** function

```elixir
defmodule Pento.Promo.Recipient do
  defstruct [:first_name, :email]
  @types %{first_name: :string, email: :string}

  alias Pento.Promo.Recipient

  import Ecto.Changeset

  def changeset(%{Recipient{} = user, attrs) do
    {user, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:first_name, :email])
    |> validate_format(:email, ~r/@/)
  end
end
```

##### Create recipient changesets


```elixir
iex(1)> alias Pento.Promo.Recipient
Pento.Promo.Recipient
iex(2)> r = %Recipient{}
%Pento.Promo.Recipient{email: nil, first_name: nil}
iex(3)> Recipient.changeset(r, %{email: "joe@email.com", first_name: "Joe"})
#Ecto.Changeset<
  action: nil,
  changes: %{email: "joe@email.com", first_name: "Joe"},
  errors: [],
  data: #Pento.Promo.Recipient<>,
  valid?: true
>
iex(4)> Recipient.changeset(r, %{email: "joe@email.com", first_name: 1234}) 
#Ecto.Changeset<
  action: nil,
  changes: %{email: "joe@email.com"},
  errors: [first_name: {"is invalid", [type: :string, validation: :cast]}],
  data: #Pento.Promo.Recipient<>,
  valid?: false
>
iex(5)> Recipient.changeset(r, %{email: "joe's email", first_name: "Joe"})  
#Ecto.Changeset<
  action: nil,
  changes: %{email: "joe's email", first_name: "Joe"},
  errors: [email: {"has invalid format", [validation: :format]}],
  data: #Pento.Promo.Recipient<>,
  valid?: false
>
```


#### Build the **Promo** context
- **Promo** context that will present the interface for interacting with the changeset
- ./lib/pento/promo.ex
    - the context function should create and validate a changeset
    - if the changeset is in fact valid,
        - we can pipe it to some helper function or service that handles the details of sending promotional emails
    - if the changeset is not valid,
        - we can return an error tuple


```elixir
defmodule Pento.Promo do
  alias Pento.Promo.Pecipient

  def change_recipient(%Recipient{] = recipient, attrs \\ %{}) do
    Recipient.changeset(recipient, attrs)
  end

  def send_promo(recipient, attrs) do
    # send email to promo recipient
  end
end
```


### The Promo Live View
- ./lib/pento_web/live/promo_live.ex
    - simple **mount/3** function


```elixir
defmodule PentoWeb.PromoLive do
  use PentoWeb, :live_view
  alias Pento.Promo
  alias Pento.Promo.Recipient

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
```

##### Create a template file
- ./lib/pento_web/live/promo_live/html.leex


```elixir
<h2>Send Your Promo Code to a Friend</h2>
<h4>
  Enter your friend's email below and we'll send them a
  promo code for 10% off their first game purchase!
</h4>
```


##### Add a route
- ./lib/pento_web/router.ex


```elixir
scope "/", PentoWeb do
  pipe_through [:browser, :require_authenticated_user]
  live "/promo", PromoLive
```


##### Refine **mount/3** function
- ./lib/pento_web/live/promo_live.ex
    - reducer functions
        - **assign_recipient/1**
        - **assign_changeset/1**


```elixir
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign_recipient()
      |> assign_changeset()}
  end

  def assign_recipient(socket) do
    socket
    |> assign(:recipient, %Recipient{})
  end

  def assign_changeset(%{assigns: %{recipient: recipient}} = socket) do
    socket
    |> assign(:changeset, Promo.change_recipient(recipient))
  end
```


##### use the schemaless changeset in the form
- ./lib/pento_web/live/promo_live.html.leex
    - LiveView bindings
        - **phx-change**
            - the LiveView will
                - send a **"validate"** event each time the form changes, and
                -  include the form params in the event metadata
            - -> implement a **handle_event/3** function for this event that builds a new changeset from the params and adds it to the socket
        - **phx-submit**
            - the "**save**" event fires when the user submits the form
            - -> implement a **handle_event/3** function that uses the context function, **Promo.send_promo/2**, to respond to this event
- **error_tag/2** view helper function
    - displays the form's errors for a given field on a changeset, when the chnageset's action is **:validate**


```elixir
<%= f = form_for @changeset, "#",
  id: "promo-form",
  phx_change: "validate",
  phx_submit: "save" %>

  <%= label f, :first_name %>
  <%= text_input f, :first_name %>
  <%= error_tag f, :first_name %>

  <%= label f, :email %>
  <%= text_input f, :email %>
  <%= error_tag f, :email %>

  <%= submit "Send Promo"%>
</form>
```


##### Implement a **handle_event/3** function
- ./lib/pento_web/live/promo_live.ex
    - the **Promo.chnage_recipient/2** context function
        - creates a new changeset using
            - the recipient from state and
            - the params from the form change event
    - **Map.put(:action, :validate)**
        - to add the **validate** action to the changeset,
            - a signal that instructs Phoenix to display errors
        - not all invalid changesets should show errors on the page
        - if the changeset's action is empty, then no errors are set on the form object
    - **assigns/2** function
        - adds the new changeset to the socket, triggering **render/1** and displaying any errors

```elixir
def handle_event(
    "validate",
    %{"recipient" => recipient_params},
    %{assigns: %{recipient: recipient}} = socket) do

  changeset =
    recipient
    |> Promo.change_recipient(recipient_params)
    |> Map.put(:action, :validate)

    {:noreply,
      socket
      |> assign(:changeset, chnageset)}
end
```

<img src='https://i.gyazo.com/2a95fc34a0d38db18c421c6fd2a45ff2.png' width='500'>


##### Flow
- the live view
    - calls on the context to create a changeset,
    - renders it in a form,
    - validates it on form change, and then
    - re-renders the template after each form event


## LiveView Form Bindings
- LiveView uses annotations called bindings to tie live views to events using platform JavaScript
- **phx-submit**
    - submitting a form
- **phx-change**
    - form validations
- LiveView also offers bindings to control how often, and under what circumstances, LiveView JavaScript emits form events


### Submit and Disable a Form
- by default, binding **phx-submit** events causes three things to occur on the client
    - the form's inputs are set to "readonly"
    - the submit button is disabled
    - the "**phx-submit-loading**" CSS class is applied to the form
