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
        - is implemented with the base **index** template and **index** live view
        - is responsible for rendering the products table in the background
    - the modal dialog
        - Modal dialog funciton: LiveHelpers.live_modal
        - to provide a window container
        - prevents interaction with the layers underneath and 
        - contains the form component
        - is comprised of HTML markup with supporting CSS, and a small modal *component*.
        - **Components** are like little live views that run in the process of their parent live view.
    - the form component 
        - Component: FormComponent
        - holds data in its own sockets,
        - renders itself, and
        - processes messages that potentially change its state.


### Call the Modal Component
- The code flow is kicked off in the very same Product Index template.
- three concepts
    - the conditional statement
        - predicated on the value of the **@live_action** assignment.
        - the change management workflow
            - when a user clicks the "edit" link
                - the **ProductLive.Index** live view will invoke the **handle_params/3** callback with a **live_action** of **:edit** populated in the socket assigns.
            - the template will then re-render with this **@live_action** assignment set to **:edit**
            - the template *will* call the **live_modal/3*8 funciton.
    - **live_modal/3** function
        - waps up two concepts.
            1. a CSS concept
                - a *modal dialog*
                    - the generated CSS applied to the modal component will disallow interaction with the window underneath.
            2. the component itself
                - This component handles details for a modal window, including an event to close the window.
- The Phoenix Live generator
    - builds the **live_modal/3** function and
    - places it in the **./lib/pento_web/live/live_helpers.ex** file
    - its sole responsibility is to build a modal window in a **div**
- **PentoWeb.ModalComponent**
    - to apply some markup and styling that
        - presents a window in the foreground, and 
        - handles the events to close that window


- `./lib/pento_web/lib/libe_helpers.ex`


```elixir
25  def live_modal(socket, component, opts) do
26    path = Keyword.fetch!(opts, :return_to)
27    modal_opts = [
28      id: :modal,
29      return_to: path,
30      component: component,
31      opts: opts
32    ]
33    live_component(socket, PentoWeb.ModalComponent, modal_opts)
34  end
```


### Render The Modal Component
- A _component_ is part of a live view that handles its own markup.
- a basic sense of the responsibilities of the modal component
- `./lib/pento_web/live/modal_component.ex`


```elixir
defmodule PentoWeb.ModalComponent do
  use PentoWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="phx-modal"
      phx-capture-click="close"
      phx-window-keydown="close"
      phx-key="escape"
      phx-target="#<%= @id %>"
      phx-page-loading>

      <div class="phx-modal-content">
        <%= live_patch raw("&times;"),
              to: @return_to, class: "phx-modal-close" %>
        <%= live_component @socket, @component, @opts %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
```

- the **assigns** argument
    - the keyword list that was given as a third argument to the **PentoWeb.LiveHelpers.live_modal/3** function


- `./lib/pento_web/live/live_helpers.ex`


```elixir
defmodule PentoWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [
      id: :modal,
      return_to: path,
      component: component,
      opts: opts
    ]
    live_component(socket, PentoWeb.ModalComponent, modal_opts)
  end
end
```

- **phx-** hook
    - to pick up important events that are all ways to close the form.
- **phx-capture-click**, **phx-window-keydown**
    - will receive events when the user clicks on certain buttons or presses cetain keys.
- **live_patch/2** call
    - to build a "close" link with the **:return_to** path.
- no **mount/1** function


### Mount the Modal Component
- a component has a lifecycle of its own
- **update/2** function that LiveView uses to update a component
- the default **mount/1** function just passes the socket through, unchanged
- the default **update/2** function takes the assigns
- this generated modal component doesn't need to keep any extra data in the socket
    - aside from the assings we pass in via the call to **live_component/3**
    - we can allow it to pick up the default **mount/1** and **update/2** functions from the behaviour.

<img src="https://i.gyazo.com/8fb555b3bbe65b57a3ab37aec69ca9be.png" width="600">

1. The **live_modal** function in the **ProductLive.Index** template calls a **LiveHelpers.live_component/3** function
2. The **LiveHelpers.live_component/3** function calls on the **ModalComponent**
3. The **ModalComponent.live_component/3** renders a template that presents a pop-up to the user


### Handle Model Component Events
- types of components
    1. statefull
    2. stateless
- only components that can implement a **handle_event/3** function can actually handle events
- only _stateful_ components can implement **handle_event/3**
    - Adding an **id** to a component make it stateful


#### :id key in the live_helpers.ex

```elixir
  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [
      id: :modal,
      return_to: path,
      component: component,
      opts: opts
    ]
    live_component(socket, PentoWeb.ModalComponent, modal_opts)
  end
```


#### How it is taught to handle events
- three ingredients to event management in LiveView
    1. Add a LiveView DOM Element binding, or LiveView binding
        - to given HTML element
        - bindings that send events over the WebSocket to the live view when a specified client interaction
    2. Specify a target for that LiveView event
        - by adding a **phx-target** attribute to the DOM element
    3. implement a **handle_event/3** callback
        - that matches the name of the event in the targeted live view or component

#### a handle_event/3 function for the "close" event


```elixir
  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
```

- this generated event handler takes in arguments of the event name, ignored metadata, and the socket.
- it _transforms_ the socket by navigating back to the path we specified in **live_modal/3** with a call to **push_path/2**.


### Live Navigation with **push_path/2**
- The **push_patch/2** function works just like the **live_patch/2** function with one exception.
    - use **live_patch/2** in HTML markup running in the browser client.
    - use **push_patch/2** in event handlers running on the server.
- The **push_patch/2**
    - adds private data to the socket that LiveView's server-side code and
    - JavaScript will use to navigate between pages and manage the URL _all within the current LiveView_.
- On the server side,
    - the dame change management lifecycle will kick off.
    - LiveView will call **handle_params/3**, but not **mount/3**


<img src="https://i.gyazo.com/fb5427d5969746eb1e3e2034f43a4ff2.png" width="600">


1. click the "close" button, the browser navigates back to **/products**.
2. **/products** route will point us at **ProductLive.Index** with a **live_action** of **:index**.
3. **ProductLive.Index** change in state will cause another render of the index template.
4. This time around, the template code's **if** condition that checks for the **:edit** live action will evaluate to **false**


## LiveView Layers: The Form Component
- The content we put _inside_ our modal window may have its own state, markup, and events
- the form component
    - be able to compose components into layers
    - allows us to collect the fields for a product a user wants to create or update.
    - will also have events related to submitting and validating the form.
    - in three steps
        1. rendering the template,
        2. setting up the socket, and
        3. processing events


### Render the Form Component
- tracing how the form component is rendered from within the modal component.

- ./lib/pento_web/live/product_live/index.html.leex

```elixir
<%= if @live_action in [:new, :edit] do %>
  <%= live_modal @socket, PentoWeb.ProductLive.FormComponent,
    id: @product.id || :new,
    title: @page_title,
    action: @live_action,
    product: @product,
    return_to: Routes.product_index_path(@socket, :index)%>
<% end %>
```

- there is an **:id** key, along with a **:component** key that specifies the **FormComponent**
    - that will be rendered inside the modal
- These attributes are passed into the modal component via **PentoWeb.LiveHelpers.live_modal/3**'s call to **live_component/3**.

- ./lib/pento_web/live/live_helpers.ex


```elixir
  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [
      id: :modal,
      return_to: path,
      component: component,
      opts: opts
    ]
    live_component(socket, PentoWeb.ModalComponent, modal_opts)
  end
```

- modal_opts
    - the keyword list of options is made available to the modal component's **render/1** function as part of the assigns.
    - the modal component's template has access to a **@component** assignment set equal to the name of the form component module.
-


#### calling live_component/3
- `<%= live_component @socket, @component, @opts %>`
- in the modal component's markup
- this will mount and render the **FormComponent** and provide the additional options present in the **@opts** assignment.
    - the **@opts** assignment includes a key of **:id**
        - so the form component _is_ stateful.
- passed keys with a product, a title, the live action, and a path to **live_modal/3** function in the Product Index template
    - All those options, alog with our **:id**, are in **@opts**
        - can refer to them in the form component as part of the component's assigns


- ./lib/pento_web/live/product_live/index.html.leex

```elixir
<%= if @live_action in [:new, :edit] do %>
  <%= live_modal @socket, PentoWeb.ProductLive.FormComponent,
    id: @product.id || :new,
    title: @page_title,
    action: @live_action,
    product: @product,
    return_to: Routes.product_index_path(@socket, :index)%>
<% end %>
```


### Establish From Component State
- what happens _when_ it is rendered.
1. The first time Phoenix renders the form component, it will call **mount/1** once.
    - this is where we can perform any initial set-up for our form component's state.
2. the **update/2** callback will be used to keep the component up-to-date
    - whenever the parent live view or the component itself changes.
    - The default **mount/1** function from the call to **use PentoWeb, :live_component** will suffice.
- The **update/2** function takes in two arguments, the map of assigns and the socket
    - both of wich we provided when we called **live_component/3**
- `<%= live_component @socket, @component, @opts %>`
    - a refresher of the **update/2** function calling **live_component/3** in the LEEX template
    - these three options are passed into the specified component's **update/2** callback as the **assigns** argument, and
        - the socket is passed in as the second argument.
        1. **@socket**:
            - The socket shared by the parent live view, in this case **ProductLive.Index**
        2. **@component**:
            - the name of the component to be rendered and
        3. **@opts**:
            - the keyword list of options.


#### update/2 function
- ./lib/pento_web/live/product_live/form_component.ex


```elixir
  @impl true
  def update(%{product: product} = assigns, socket) do
    changeset = Catalog.change_product(product)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end
```

- how this **update/2** function uses the data in **assigns** to support the "product eidt form"
- _form_ links _changeset_
- The generated code uses the **Catalog.chnage_product/1** function to build a chnageset for the product that is stored in assigns.
- use handlers to wait for events,
    - and then change the assigns in the socket in response to those events.


### Handle Form Component Events
- how the form component receives and handles events
- the form component remplate and see how it sends events to the LiveView component.


#### Send Form Component Events
- The form template is really just a standard Phoenix form.
- The main function in the template is the **form_for** function.
- use the chnageset that was put in assigns via the **update/2** callback


- ./lib/pento_web/live/product_live/form_component.html.leex


```elixir
<%= f = form_for @changeset, "#",
  id: "product-form",
  phx_target: @myself,
  phx_change: "validate",
  phx_submit: "save" %>

  <%= label f, :name %>
  <%= text_input f, :name %>
  <%= error_tag f, :name %>

  <%= label f, :description %>
  <%= text_input f, :description %>
  <%= error_tag f, :description %>

  <%= label f, :unit_price %>
  <%= number_input f, :unit_price, step: "any" %>
  <%= error_tag f, :unit_price %>

  <%= label f, :sku %>
  <%= number_input f, :sku %>
  <%= error_tag f, :sku %>

  <%= submit "Save", phx_disable_with: "Saving..." %>
</form>
```

- **form_for** function with no target URL, and **id**, and three **phx-** attributes.
- **phx-** attributes
    - _**phx-change**_
        - Send the **"validate"** event to the live component each time the form changes
    - _**phx-submit**_
        - Send the **"save"** event to the live component when the user submits the form
    - _**phx-target**_
        - Specify a component to receive these events.
- a series of form fields, and a submit button
    - these tie back to the **@chnageset** through the form variable, **f**.
- They will do two things.
    - Upon rendering,
        - they establish the value for each field.
    - Upon submit,
        - they send their values to the live view.
- the error tags
    - these will come into play when a field is not valid based on the errors in the changeset.


#### Receive Form Component Evnets
- The **phx-change** event fires whenever the form chnages.
- The **phx-submit** event fires when the user submits the form.


##### "save" event

```elixir
  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end
```

1. The first argument is the event name.
2. For the first time, we use the metadata sent along with the event, and we use it to pick off the form contents.
3. The last argument to the event handler is the **socket**.
- When the user presses **submit**,
    - the form component calls **save_product/3**
    - which attempts either a product update or product create with the help of the **Catalog** context.
- If the attempt is successful,
    - the component updates the flash messages and redirects to the Product Index view.


#### Live Navigation with **push_redirect/2**
- The **push_redirect/2** function, and its client-slide counterpart **live_redirect/2**,
    - transform the socket.
- When the client receives this socket data,
    - it will redirect to a live view, and
    - will always trigger the **mount/3** function.
- It's also the only mechanism you can use to redirect to a _different_ LiveView than the current one.


##### push_redirect/2 calling at the form component

```elixir
socket
|> push_redirect(to: socket.assigns.return_to)}
```

- calling **live_modal/3** from the Index template
    - it was invoked with a set of options including a **:return_to** key set to a value of **/products**
- that option was passed through the modal component,
    - into the form compnent as part of the form component's socket assigns.
- We want to ensure that **mount/3** re-runs now so that it can reload the product list from the database


## Your Turn
- the major pieces of the LiveView framework
    - the route,
    - the live view module,
    - the optional view template, and
    - the helpers, component modules and component templates that support the parent view.
- The entry point of the LiveView lifecycle is the route.
    - The route matches a URL onto a LiveView module and sets a live action.
- The live view
    - puts data in the socket using **mount/3** and **handle_params/3**, and then
    - renders that data in a template with the same name as the live view.
- The mount/render and chnage management workflows
    - make it easy to reason about state management and
    - help you find a home for _all_ of your CRUD code across just _two_ live view.
- A **LiveComponent**
    - compartmentalizes state, HTML markup, and event processing for a small part of a live view.
    - The generators built two different components,
        - one to handle a modal window and
        - one to process a form


### Give It a Try
- three problems
    1. Trace through the **ProductLive.Show** live view
    2. Change the Index Live View
    3. Generate Your Own LiveView


#### Trace Through a Live View
- the **Index** page's implementation of the link to the product show page


#### Change the Index Live View
- the **index.html.leex** live view


#### Generate You Own LiveView
