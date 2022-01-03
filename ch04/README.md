# Chapter 4, Generators: Live Views and Templates
- an examination of the frontend code.
- how LiveView works to support the CRUD functionality for the **Product** resource
- some of the best ways to organize LiveView code
- to build custom LiveView functionality on top of thid strong foundation.
- a plan
    1. start with the routes and use them to understand the views
    2. take inventory of the files that the generator created.
    3. walk through the main details of a live view
        - along the way,
            - live navigation
            - live actions
            - how LiveView builds and handles routes.
            - how LiveView's lifecycle manages the presentation and state of a given view
    4. LiveView components
        - how to organize LiveView code properly.


## Application Inventory
- The routes in `./lib/pento_web/router.ex` are an API.


### Route the Live Views
- The router tells us all of the things a user can *do* with products.
- how Phoenix routes requests to a live view
- how LiveView operates on those requests.

- `./lib/pento_web/router.ex`


```elixir
75    live "/products", ProductLive.Index, :index
76    live "/products/new", ProductLive.Index, :new
77    live "/products/:id/edit", ProductLive.Index, :edit
78
79    live "/products/:id", ProductLive.Show, :show
80    live "/products/:id/show/edit", ProductLive.Show, :edit
```

- This list of routes descrives all of the ways a user can interact with products in the application.
- The **live/4** macro
    - is implemented by the **Phoenix.LiveView.Router** module.
    - generates a route that ties a URL pattern to a gien LiveView module.
    - arguments
        - the first
            - is the URL pattern.
            - This pattern defines what the URL looks like.
            - *named parameters*
                - e.g.
                    - URL **products/7** matchs the pattern **"/products/:id"**,
                    - prepare this map of params to be made available to the corresponding live view:
                        - `%{"id" => "7"}`
        - the second
            - is the LiveView module implementing the code.
                - e.g. **ProductLive.Index** module
        - the third
            - is the *live action*.
            - allows a given live view to manage multiple page states.
- the **ProductLive.Index** view implements three different live actions **:index**, **:new**, and **:edit**
    - This means that *one* live view, **ProductLive.Index**,
        - will handle the **:index**, **:new**, and **:edit** portions of the **Product** CRUD feature-set.
- the **ProductLive.Show** live view implements two different actions: **:show** and **:edit**.

- `./lib/pento_web/router.ex`


```elixir
10  use PentoWeb, :router
```

- The **use** macro injects the **PentoWeb.router/0** function into the current module.

- `./lib/pento_web.ex`


```elixir
70  def router do
71    quote do
72      use Phoenix.Router
73
74      import Plug.Conn
75      import Phoenix.Controller
76      import Phoenix.LiveView.Router
77    end
78  end
```


### Explore The Generated Files
- the files that the Phoenix Live generator created.


```
* creating lib/pento_web/live/product_live/show.ex
* creating lib/pento_web/live/product_live/show.html.heex
* creating lib/pento_web/live/product_live/index.ex
* creating lib/pento_web/live/product_live/index.html.heex
* creating lib/pento_web/live/product_live/form_component.ex
* creating lib/pento_web/live/product_live/form_component.html.heex
* creating lib/pento_web/live/model_component.ex
* creating lib/pento_web/live/live_helpers.ex
* injecting lib/pento_web.ex
* creating test/pento_web/live/product_live_test.exs
```

- the **show.ex** file implemnets the LiveView module for a single product.
    - it uses the **how.html.heex** template to render the HTML markup
- the **form_component.ex** and **form_component.html.heex** both implement a *LiveView component*.
- LiveView's two key workflows.
    - the mount and render workflow
    - the change management workflow


## Mount and Render the Product Index
- The mount/render workflow describes the process in which a live view sets its initial state and renders it.
- **mount/3** function
    - to put data into the socket struct 

- `./lib/pentp_web/live/product_live/index.ex`


```elixir
16  def mount(_params, _session, socket) do
17    {:ok, assign(socket,:products, list_products())}
18  end
#...
51  defp list_products do
52    Catalog.list_products()
53  end
```

- the socket struct's map of **:assigns** is updated with a key of **:products**,
    - pointing a value of all of the products returned from the **list_products/0** helper function.
- add an additional key of **:greeting** to the socket assigns.


```elixir
16  def mount(_params, _session, socket) do
17    {:ok,
18      socket
19      |> assign(:greeting, "Welcome to Pento!")
20      |> assign(:products, list_products())}
21  end
```

- the **Phoenix.Socket.assign/3** function
    - adda a key/value pair to the socket struct's map of **:assigns**.
        - **:assigns** map is where the socket struct holds state.
- Any key/value pairs placed in the socket's **:assigns** can be accessed in the live view's template.
    - e.g., access the value of the **:greeting** key in the template like this: **@greeting**


- `./lib/pento_web/live/product_live/index.html.heex`


```elixir
1 <h1>Listing Product</h1>
2 <h1><%= @greeting %></h1>
```


### Understand LiveView Behaviours
- *behaviours*
    - The behaviour runs a specified application and calls your code according to a contract.
    - The LiveView contract defines several callbacks.
- the **mount/3** function
    - to set up data in the socket
- the **render/1** function
    - to return data to the client
- the **handle_x** function
    - to change the socket
- the **terminate/2** function
    - to shut down the live view
- the *behaviour* calls **mount/3** and then **render/1**.


### Route to the Product Index

1. The entry point of the mount/render lifecycle is the route.
    - the router will match the URL pattern to the code that
        - will execute the request, and extract any parameters.
    - Next, the live view will start up.
        - the live view is actually an OTP **GenServer**.
2. the **mount/3** function is called.
    - to *set up* the initial data in the live vew.
3. Next the live view will do the initial *render*.
    - the **render/1** function is called, if its defined.
        - if not, LiveView will render a template based on the name of the live view file.


<img src='https://i.gyazo.com/d9457113a3a887cee6f41df1cf6fd43f.png' width='400'>

- When the LiveView process starts up, the socket is initialized or *constructed*.
- the **mount/3** function further *reduces* over that socket to make any state changes.
- the **render/1** function *converts* that socket state into markup.
- "construct, reduce, convert"


### Establish Product Index State

- each path takes us first to the **mount/3** function


- `./lib/pento_web/live/product_live/index.ex`


```elixir
16  def mount(_params, _session, socket) do
17    {:ok, assign(socket,:products, list_products())}
18  end
#...
51  defp list_products do
52    Catalog.list_products()
53  end
```

- a live view revolves around its state.
- The **mount/3** function sets up the initial state
- The **Catalog.list_products/0** function is used to get a list of products.


- socket


```elixir
%{
  #...
  assigns: %{
    live_action: :index,
    products: %{[ "list of products" ]},
    #...
  }
}
```


### Render Product Index State
- how these HEEX templates function in a LiveView application.
- HEEX
    - it is designed to minimize the amount of data sent down to the clint over the WebSocket connection.
    - part of the job of the templates
        - is to track state changes in the live view **socket** and
        - *only* update portions of the template impacted by these state changes.
- LiveView makes hte data stored within **socket.assigns** available for computations in HEEx templates.
- When that data changes, the HEEx template is re-evaluated.


#### Render Products

```elixir
12 <table>
13   <thead>
14     <tr>
15       <th>Name</th>
16       <th>Description</th>
17       <th>Unit price</th>
18       <th>Sku</th>
19 
20       <th></th>
21     </tr>
22   </thead>
23   <tbody id="product">
24     <%= for product <- @products do %>
25       <tr id="product-<%= product.id %>">
26         <td><%= product.name %></td>
27         <td><%= product.description %></td>
28         <td><%= product.unit_price %></td>
29         <td><%= product.sku %></td>
```

- iterating over the products in **socket.assigns.products**, available in the template as the **@products** assignment


## Handle Change for the Product Edit
- the change management workflow
- In this way, a single live view can easily handle multiple pieces of CRUD functionality.


### Route to the Product Edit
- **/products/:id/edit** route
- the route definition
    - `live "/products/:id/edit", ProductLive.Index, :edit`
        - with a live action of **:edit**
- LiveView adds a key of **:live_action** to the live view's socket assigns,
    - setting it to the value of the provided action.
- hook into a slightly different LiveView lifecycle 
- the **handle_params/3** function
    - is called when access and use the live action from socket assigns
    - is called right after the **mount/3** function


<img src='https://i.gyazo.com/0ce17687618129d93678c6c25b80adc3.png' widht='400'>

- direct access to
    - **products/:id/edit**


### Live Nabigation with **live_patch/2**
- `./live/pento_web/live/product_live/index.html.heex`


```elixir
33          <span>
34            <%= live_patch "Edit",
35                  to: Routes.product_index_path(@socket, :edit, product)%>
36          </span>
```

- This markup generates an HTML link that the user can click to be taken to the Product Edit view.


```html
<span>
    <a data-phx-link="patch" data-phx-link-state="push" href="/products/1/edit">Edit</a>
</span>
```

- Ths is a special kind of link called a "live patch", returned by the call to the **live_patch/2**.
- A live patch link will "patch" the current live view.
- clicking the link *will* change the URL in the browser bar, courtesy of a JavaScript feature called *push state navigation*.
    - but it *won't* send a web request to reload the page.
    - clicking this link will kick off LiveView's chnage management workflow.
- direct access to `/products/:id/edit`
    - first calls the **mount/3** function
    - then **handle_params/3** function
    - finally **render/1** funciton
        - the lifecycle triggered by the **live_patch** request skips the call to **mount/3**.
- when clicking the edit link
    - the **ProductLive.Index** live view will call **handle_params/3**
    - The **handle_params/3** function
        - is responsible for using these data points to update the socket
- how the **handle_params/3** function works to set the "edit product" state.


### Establish Product Edit State
- The change management workflow begins when the user enacts a change by clicking the **edit** link
    - Phoenix then calls **handle_params/3** with a live action of **:edit** and the params of **%{id: 1}**.
- **apply_action/3** function


- `./lib/pento_web/live/product_live/index.ex`


```elixir
27  defp apply_action(socket, :edit, %{"id" => id}) do
28    socket
29    |> assign(:page_title, "Edit Product")
30    |> assign(:product, Catalog.get_product!(id))
31  end
```

- setting a **:page_title** of ""Edit Profile".
- pattern matching is being used to extract the **:id** from **params**.
- The product ID is fed to **Catalog.get_product!/1** to extract the full product from the database.
- the product is added to **socket.assigns** under a key of **:product**.
- Since the socket has changed,
    - LiveView pushes only the changed state to the client, which then renders those changes.
- The **handle_params/3** function
    - *changes* socket state in accordance with the presence of a live action and certain params.
    - *reduces* over that socket to change its state, when the live view's socket is initialized.
- the socket state is *transformed* via the rendering of the template.
- With the **handle_params/3** callback, LiveView provides an interface for managing change.


### Render Product Edit State
- the **ProductLive.Index**


```elixir
 3 <%= if @live_action in [:new, :edit] do %>
 4   <%= live_modal @socket, PentoWeb.ProductLive.FormComponent,
 5     id: @product.id || :new,
 6     title: @page_title,
 7     action: @live_action,
 8     product: @product,
 9     return_to: Routes.product_index_path(@socket, :index)%>
10 <% end %>
```

- the conditional logic that's based on the **@live_action** assignment.


## LiveView Layers: The Modal Component
- LiveView components
    - how the are used to organize live views
    - what role they play in LiveView change management
- how the generated component code is organized int olayers the compartmentalize presentation and state.


<img src="https://i.gyazo.com/5a3c2108ad6b4671e920d80a7a14ded4.png" width="400">

- The Product Edit page will have three distinct layers.
    - the *background*
        - Live view: index.heml.heex
    - the modal dialog
        - Modal dialog funciton: LiveHelpers.live_modal
    - the form component 
        - Component: FormComponent
