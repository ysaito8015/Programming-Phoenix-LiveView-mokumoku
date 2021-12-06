# Programming Phoenix LiveView の読書メモ
- 出版社ページ
    - https://pragprog.com/titles/liveview/programming-phoenix-liveview/
- コード
    - https://media.pragprog.com/titles/liveview/code/liveview-code.zip
- errata
    - https://devtalk.com/books/programming-phoenix-liveview/errata

# 目次
- Introduction
1. Get To Know LiveView
## Part I. Code Generation
2. Phoenix and Authentication
    - `phx.gen.auth`
        - authentication layer generator
        - doesn't use LiveView
        - to learn how Phoenix requests work
        - use the generated code to authenticate a live view
3. Generators: OCntexts and Schemas
    - `phx.gen.live`
        - creates live views with all of the code
        - to generate the product CRUD feature-set
    - **core** layer
        - contains code that is certain and behaves predictably
    - **boundary** layer
        - also called context layer
        - represents code that has uncertainty
            - e.g., database interfaces
        - to manage products through an API
4. Generators: Live Views and Templates
    - `phx.gen.live`
        - web side of this generator
            - web modules
            - templates
            - helpers
## Part II. LiveView Composition
5. Forms and Changesets
    - form tags
    - Ecto.changeset
6. Stateless Components
    - stateless components
        - work like partial views
    - LiveView present state across multiple stages
7. Stateful Components
    - to capture events that change the state of our views
## Part III. Extend LiveView
- this part provides...
    - use communication
        - between a parent live view and child components, and
        - between a live view and other areas of the Phoenix app
    - build a modular admin dashboard
    - how to track and display sysytem-wide information in a live view
8. Build an Interactive Dashboard
    - leverage the functions and patterns that LiveViews provides for the event management lifecycle
    - how components communicate with the live view to which they belong
9. Build a Distributed Dashboard
    - reflect the state of the entire application
    - distributed real-time behavior will be supported by Phoenix PubSub
10. Test Your Live Views
    - write some tests for the features
    - examine the testing tools that LiveView provides
## Part IV. Graphics and Custom Code Organization
11. Build The Game Core
    - beginning with a layer of functions called the *core*
    - review the reducer mathod
12. Render Graphics With SVG
    - a basic presentation layer
    - use SVG to represent the game board
13. Establish Boundaries and APIs
- Bibliography


# Alternative Resources として紹介されているもの
- [Learn Functioonal Programming with Elixir](https://pragprog.com/titles/cdc-elixir/learn-functional-programming-with-elixir/)
    - new to functional programming
- [Programming Elixir](https://pragprog.com/titles/elixir16/programming-elixir-1-6/)
- [Elixir Course on grox.io](https://grox.io/language/elixir/course)
- [Programming Phoenix](https://pragprog.com/titles/phoenix14/programming-phoenix-1-4/)
    - not single-page apps
- [Designing Elixir Systems with OTP](https://pragprog.com/titles/jgotp/designing-elixir-systems-with-otp/)
    - organizing Elixir software
    - advanced book
- [Elixir School](https://elixirschool.com/blog/phoenix-live-view/)
- [LiveView Course on grox.io](https://grox.io/language/liveview/course)
