# Chapter 3 Generators: Contexts and Schemas
- The next two chapters will build a product catalog into our application.
- use the Phoenix generators to build the bulk
- when run the generator
    - some of the code we generate will be backend database code, and
    - some will be frontend code.
- this chapter focus on the backend code.
- The Phoenix generators will separate backend code into two layers
    - the schema layer
        - describes the Elixir entities that map to our individual database tables
    - the API layer,
        - called a context,
        - provides the interface through which we will interact with the schema


## Get to Know the Phoenix Live Generator
- The Phoenix Live generator is a utility that generates code supporting full CRUD functionality
    - this includes
        - the backend schema and context code, as well as
        - the frontend code including
            - routes,
            - LiveView, and 
            - templates


## Run the Phoenix Live Generator
- use the Phoenix Live generator to create a feature for managing produccts
- *resource*
    - is a collection of like entities
    - **Product** will be our resource
- Runnning the generator will give us all of the code needed to support the CRUD interactions for this resource


<img src='https://i.gyazo.com/c614cb31be92e0c3873b4c4b7f8630bc.png' width='500'>


### Learn How To Use hte Generator
- need to specify both a context and a schema
- need to tell Phoenix which fields to support for the resource's corresponding database table


```shell
$ mix phx.gen.live
...
** (Mix) Invalid arguments

mix phx.gen.html, phx.gen.json, phx.gen.live, and phx.gen.context
expect a context module name, followed by singular and plural names
of the generated resource, ending with any number of attributes.
For example:

    mix phx.gen.html Accounts User users name:string
    mix phx.gen.json Accounts User users name:string
    mix phx.gen.live Accounts User users name:string
    mix phx.gen.context Accounts User users name:string

The context serves as the API boundary for the given resource.
Multiple resources may belong to a context and a resource may be
split over distinct contexts (such as Accounts.User and Payments.User).

```

- 3rd example
    - `$ mix phx.gen.live Accounts User users name:string`
        - generate **Accounts** context and **User** schema
        - generator will take these arguments
            - to generate an **Accounts** context and a **User** schema
        - `Accounts`
            - *context*
        - `User`
            - the name of the *resource* and *schema*
        - `users name:string`
            - the attributes
            - the names and types of the fields our schema will support


### Generate a Resource
- it will genrate
    - a **Catalog** context with
    - a schema for **Product**, corresponding to
    - a **products** database table
        - a product will have
            - **name**,
            - **description**,
            - **unit_price**, and
            - **SKU** fields
- `$ mix phx.gen.live Catalog Product products name:string description:string unit_price:float sku:integer:unique`


```
* creating lib/pento_web/live/product_live/show.ex
* creating lib/pento_web/live/product_live/index.ex
* creating lib/pento_web/live/product_live/form_component.ex
* creating lib/pento_web/live/product_live/form_component.html.leex
* creating lib/pento_web/live/product_live/index.html.leex
* creating lib/pento_web/live/product_live/show.html.leex
* creating test/pento_web/live/product_live_test.exs
* creating lib/pento/catalog/product.ex
* creating priv/repo/migrations/20220101221741_create_products.exs
* injecting lib/pento/catalog.ex
* injecting test/pento/catalog_test.exs

Add the live routes to your browser scope in lib/pento_web/router.ex:

    live "/products", ProductLive.Index, :index
    live "/products/new", ProductLive.Index, :new
    live "/products/:id/edit", ProductLive.Index, :edit

    live "/products/:id", ProductLive.Show, :show
    live "/products/:id/show/edit", ProductLive.Show, :edit


Remember to update your repository by running migrations:

    $ mix ecto.migrate
```


#### edit router
- `./lib/pento_web/router.ex`


```elixir
72  scope "/", PentoWeb do
73    pipe_through [:browser, :require_authenticated_user]
74    # Generated product routes start here:
75    live "/products", ProductLive.Index, :index
76    live "/products/new", ProductLive.Index, :new
77    live "/products/:id/edit", ProductLive.Index, :edit
78
79    live "/products/:id", ProductLive.Show, :show
80    live "/products/:id/show/edit", ProductLive.Show, :edit
```

- **live** macro
    - instructs Phoenix that this request will start a live view
- **ProductLive.Index** argument
    - is the module that implements the live view
- **:new** argument
    - is the *live action*
    - Phoenix will put the **:new** live action into the socket when it starts the live view


## Understand The Generated Core
- separate the concerns for each resource into two layers
    - the *boundary* and
    - the *core*
- The **Catalog** context
    - represents the boundary layer,
    - it is the API through which external input can make its way into the application
- The **Product** schema
    - represents the application's core
    - the generated migrations are also part of the core
- the *core*
    - is responsible for managing and interacting with the database
    - to create and maintain database tables, and
    - prepare database transactions and queries


### Context vs. Boundary
- A *Phoenix Context* is a module in your PHoenix application that provides an API for a service or resource.
    is responsible for managing uncertainly, external interfaces, and process machinery
- The context implements the *boundary layer* of your application.


### The Product Migratino
- migration file
- `./priv/repo/migrations/2022xxxxx_create_product.exs`


```elixir
defmodule Pento.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :description, :string
      add :unit_price, :float
      add :sku, :integer

      timestamps()
    end

    create unique_index(:products, [:sku])
  end
end
```


- Migration files allow us to build key changes to the database int code.
- `$ mix ecto.migrate`


```
00:02:24.636 [info]  == Running 20220101221741 Pento.Repo.Migrations.CreateProducts.change/0 forward
00:02:24.636 [info]  create table products
00:02:24.639 [info]  create index products_sku_index
00:02:24.640 [info]  == Migrated 20220101221741 in 0.0s
```


### The Product Schema
- On the database side is the **products** table
- On the Elixir side,
    - the **Product** schema knows how to translate between
        - the **products** database table and
        - **Pento.Catalog.Product** Elixir struct.


- `./lib/pento/catalog/product.ex`


```elixir
defmodule Pento.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :name, :string
    field :sku, :integer
    field :unit_price, :float

    timestamps()
  end
```

- **use** macro
    - injects code from the specified module into the current module
- **schema/1** function
    - creates an Elixir struct that weaves in fields from a database table


### examining the public API

```elixir
iex(1)> alias Pento.Catalog.Product
Pento.Catalog.Product
iex(2)> exports Product
__changeset__/0     __schema__/1        __schema__/2        __struct__/0        
__struct__/1        changeset/2         
```


#### **Product.__struct__**

```elixir
iex(3)> Product.__struct__
%Pento.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:built, "products">,
  description: nil,
  id: nil,
  inserted_at: nil,
  name: nil,
  sku: nil,
  unit_price: nil,
  updated_at: nil
}
```

- use **__struct__/1** to create a new **Product** struct


```elixir
iex(4)> Product.__struct__(name: "Exploding Ninja Cows")
%Pento.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:built, "products">,
  description: nil,
  id: nil,
  inserted_at: nil,
  name: "Exploding Ninja Cows",
  sku: nil,
  unit_price: nil,
  updated_at: nil
}
```


### Changesets
- Rules for data integrity together form change *policies* that need to be implemented in code.
- Shemas are not limited to a simngle change policy.
- In Ecto, *chnagesets* allow us to implement any number of change *policies*.
    - **import Ecto.Changeset**
    - **import** function
        - allows us to use the imported module's functions without using the fully qualified name.


- `./lib/pento/catalog/product.ex`


```elixir
15  def changeset(product, attrs) do
16    product
17    |> cast(attrs, [:name, :description, :unit_price, :sku])
18    |> validate_required([:name, :description, :unit_price, :sku])
19    |> unique_constraint(:sku)
20  end
```

- This changeset implements the change policy for new records and updates alike.
- The **Ecto.Changeset.cast/4** function
    - filters the user data we pass into **params**
    - allows the **:name**, **:description**, **:unit_price**, and **:sky** fields.
- the **cast/4** function
    - also takes input data,
        - usually as maps with atom keys and string values, and
    - transforms them into the right types.
- The result of our **changeset** function is a changeset struct.


### Test Drive the Schema
- the **Product** schema


```elixir
iex(1)> alias Pento.Catalog.Product
Pento.Catalog.Product
iex(3)> product = %Product{}
%Pento.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:built, "products">,
  description: nil,
  id: nil,
  inserted_at: nil,
  name: nil,
  sku: nil,
  unit_price: nil,
  updated_at: nil
}
```

- establish a map of valid Product attributes

```elixir
iex(4)> attrs = %{
...(4)>   name: "Pentominoes",
...(4)>   sku: 123456,
...(4)>   unit_price: 5.00,
...(4)>   description: "A super fun game!"
...(4)> }
%{
  description: "A super fun game!",
  name: "Pentominoes",
  sku: 123456,
  unit_price: 5.0
}
```

- execute the **Product.changeset/2** function to create a valid Product changeset

```elixir
iex(6)> Product.changeset(product, attrs)
#Ecto.Changeset<
  action: nil,
  changes: %{
    description: "A super fun game!",
    name: "Pentominoes",
    sku: 123456,
    unit_price: 5.0
  },
  errors: [],
  data: #Pento.Catalog.Product<>,
  valid?: true
>
```

- the **Pento.Repo.insert/2** function
    - insert this valid changeset into the database


```elixir
iex(7)> alias Pento.Repo
Pento.Repo
iex(8)> Product.changeset(product, attrs) |> Repo.insert()
[debug] QUERY OK db=1.6ms decode=1.2ms queue=0.6ms idle=1416.9ms
INSERT INTO "products" ("description","name","sku","unit_price","inserted_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6) RETURNING "id" ["A sup
er fun game!", "Pentominoes", 123456, 5.0, ~N[2022-01-01 23:54:35], ~N[2022-01-01 23:54:35]]
{:ok,
 %Pento.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
   description: "A super fun game!",
   id: 4,
   inserted_at: ~N[2022-01-01 23:54:35],
   name: "Pentominoes",
   sku: 123456,
   unit_price: 5.0,
   updated_at: ~N[2022-01-01 23:54:35]
 }}
```

#### Not a Valid Data

```elixir
iex(9)> invalid_attrs = %{name: "Not a valid game"}
%{name: "Not a valid game"}
iex(10)> Product.changeset(product, invalid_attrs)
#Ecto.Changeset<
  action: nil,
  changes: %{name: "Not a valid game"},
  errors: [
    description: {"can't be blank", [validation: :required]},
    unit_price: {"can't be blank", [validation: :required]},
    sku: {"can't be blank", [validation: :required]}
  ],
  data: #Pento.Catalog.Product<>,
  valid?: false
>
```

- **:errors**, **"valid?** keys


#### Add Validation to Product's Price

- `./lib/pento/catalog/product.ex`


```elixir
22  def changeset(product, attrs) do
23    product
24    |> cast(attrs, [:name, :description, :unit_price, :sku])
25    |> validate_required([:name, :description, :unit_price, :sku])
26    |> unique_constraint(:sku)
27    |> validate_number(:unit_price, greater_than: 0.0)
28  end
```

```elixir
iex(11)> recompile()
Compiling 1 file (.ex)
:ok
iex(12)> invalid_price_attrs = %{
...(12)>   name: "Pentominoes",
...(12)>   sku: 123456,
...(12)>   unit_price: 0.00,
...(12)>   description: "A super fun game!"}
%{
  description: "A super fun game!",
  name: "Pentominoes",
  sku: 123456,
  unit_price: 0.0
}
iex(13)> Product.changeset(product, invalid_price_attrs)
#Ecto.Changeset<
  action: nil,
  changes: %{
    description: "A super fun game!",
    name: "Pentominoes",
    sku: 123456,
    unit_price: 0.0
  },
  errors: [
    unit_price: {"must be greater than %{number}",
     [validation: :number, kind: :greater_than, number: 0.0]}
  ],
  data: #Pento.Catalog.Product<>,
  valid?: false
>
```

## Understand The Generated Boundary
- the Phoenix context.
- Contexts represent the boundary for an application.
- The boundary code isn't just an API layer
- these responsibilities
    - *Access External Services*
        - The context allows a single point of access for external services.
    - *Abstruct Away Tedious Details*
        - The context abstrcts away tedious, inconvenient concepts.
    - *Handle uncertainty*
        - The context handles uncertainty, often by using result tuples.
    - *Present a single, common API*
        - The context provides a single access point for a family of services.


### Access External Services
- External services will always be accessed from the context.
- Database is an external service
- the **Catalog** context provides the service of *database access*.
- Ecto code can be divided into core and boundary concerns.
- Ecto implements the **Repo** module to do executing
    - database requests and
    - any such code
        - that calls on the **Repo** module belongs in the context module.

- `./lib/pento/catalog.ex`


```elixir
11  def list_products do
12    Repo.all(Product)
13  end
14
15  def get_product!(id) do
16    Repo.get!(Product, id)
16  end
#...
31  def delete_product(%Product{} = product) do
32    Repo.delete(product)
33  end
```

- These functions perfoem some of the classic *CRUD* operations.
- The last expression in each of these CRUD funcitons is some function call to **Repo**.
- Any function call to **Repo** can fail
- `Repo.function_name_with!`
    - it can throw an exception.
    - if you can't do anything about an error, you should use the ! form.
- `Repo.function_name`
    - it will return a *result tuple*.
    - `{:ok, _}`, `{:error, _}`


### Abstract Away Tedious Details
- Phoenix contexts provide an API through which it can abstract away Ecto transaction.
- Changeset are part of the Ecto library
- to use Ecto directory to insert a new record into the database
    - alias the **Product** module
    - build an empty **Product** struct
    - build the changeset with some atttributes
    - only *then* can we insert our new record into the database.
- The **Catalog** context's API wraps calls to query


#### Using Catalog API to Insert a New Record

- `./lib/pento/catalog.ex`


```elixir
19  def create_product(attrs \\ %{}) do
20    %Product{}
21    |> Product.changeset(attrs)
22    |> Repo.insert()
23  end
```


```elixir
iex(1)> alias Pento.Catalog
Pento.Catalog
iex(2)> attrs = %{
...(2)>   name: "Candy Smush",
...(2)>   sku: 50982761,
...(2)>   unit_price: 3.00,
...(2)>   description: "A candy-themed puzzle game"
...(2)> }
%{
  description: "A candy-themed puzzle game",
  name: "Candy Smush",
  sku: 50982761,
  unit_price: 3.0
}
iex(3)> Catalog.create_product(attrs)
[debug] QUERY OK db=1.4ms decode=0.6ms queue=0.5ms idle=1055.8ms
INSERT INTO "products" ("description","name","sku","unit_price","inserted_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6) RETURNING "id" ["A can
dy-themed puzzle game", "Candy Smush", 50982761, 3.0, ~N[2022-01-02 10:03:12], ~N[2022-01-02 10:03:12]]
{:ok,
 %Pento.Catalog.Product{
   __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
   description: "A candy-themed puzzle game",
   id: 5,
   inserted_at: ~N[2022-01-02 10:03:12],
   name: "Candy Smush",
   sku: 50982761,
   unit_price: 3.0,
   updated_at: ~N[2022-01-02 10:03:12]
 }}
```


### Present a Single, Common API
- to funnel all code for related tasks through a common, unified API.
- insted of calling the schema directly from external services, it will be wraped by **Product.changeset/2**.


- `./lib/pento/catalog.ex`


```elixir
35  def change_product(%Product{} = product, attrs \\ %{}) do
36    Product.changeset(product, attrs)
37  end
```

- the clients won't have to call functions in the schema layer directly.
- all external access go through a single, common API.


### Handle Uncertainty
- context
    - to translate univerified user input into data that's safe and consistent with the rules of our database.


- `./lib/pento/catalog.ex`


```elixir
19  def create_product(attrs \\ %{}) do
20    %Product{}
21    |> Product.changeset(attrs)
22    |> Repo.insert()
23  end
24
25  def update_product(%Product{} = product, attrs) do
26    product
27    |> Product.changeset(attrs)
28    |> Repo.update()
29  end
```

- If the changeset is not valid,
    - the database transaction executed via the call to **Repo.insert/1** or **Repo.update/1** will ignore it, and
    - return the changeset with errors.
- If the chnageset is valid,
    - the database will process the request.


### Use The Context to Seed The Database
- create some seed data to populate the database and we'll use our context to do it.


- `./priv/repo/seeds.exs`


```elixir
alias Pento.Catalog

products = [
  %{
    name: "Chess",
    description: "The classic strategy game",
    sku: 5_678_910,
    unit_price: 10.00
  },
  %{
    name: "Tic-Tac-Toe",
    description: "The game of Xs and Os",
    sku: 11_121_314, unit_price: 3.00
  },
  %{
    name: "Table Tennis",
    description: "Bat the ball back and forth. Don't miss!",
    sku: 15_222_324,
    unit_price: 12.00
  }
]

Enum.each(products, fn product ->
  Catalog.create_product(product)
end)
```

- `$ mix run priv/repo/seeds.exs`



## Boundary, Core, or Script?
