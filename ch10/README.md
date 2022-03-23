# Chapter 10 Test Your Live Views
- the CRC pattern lends itself nicely to robust unit testing
- the **LiveViewTest** module offers a set of convenience functions to exercise live views without fancy Javascript testig frameworks.
    - use this module directly in the **ExUnit** tests
- Tests exist to instill confidence, and unstable tests erode that confidence.
- [Testing Elixir](https://pragprog.com/titles/lmelixir/testing-elixir/)


## What Makes CRC Code Testable?
- three things
    1. Set up preconditions
    2. Provide a stimulus
    3. Compare an actual response to expectations
- write three test, of two specific types
    - one of the tests will be a _unit test_
        - to verify the behavior of the independent functions
    - two _integration tests_ which will let up verify the  interaction between components
        - one of that to test interactions _within_ a live view process, and
        - anothe to verify interactions _between processes_
- _won't_ be testing JavaScript
- The integration tests will interact with LiveView machinery to examine the impact of page loads and events.
    - e.g., simulating a button click and checking the impact on the re-rendered live view template.
    - Integration tests have the benefit of catching _integration problems_
    - Integration tests can be britte.
        - e.g., if the user interface changes the button into a link, then the test must be updated also.
        - this type of test is costly in terms of long-term maintenance.
- Sometimes it pays to
    - isolate specific functions with complex behavior (like reducer functions) and
    - write pure function tests for them.
    - Such tests are calls _unit tests_
        - they test one specific unit of functionality.
- a testing strategy that addresses both integrated and isolated tests.


### Isolation vs. Integration
#### Unit tests
- Pure unit tests call one function at a time, and then
    - check expectations with one or more assertions.
- Isolated unit test graph
    - https://i.gyazo.com/d29cdf7016ed91871289fc30fab3e1b2.png
- Unit tests encourrage _depth_.
    - programmers can write test more of them and cover more scenarios.
- Unit tests also allow _loose coupling_
    - because they don't need relay on specific interaction.
- Unit tests link to the property based testing
    - uses generated data to verify code and makes it even easier to create unit tests.
- Property-Based testing
    - [Property-Based Testing with PropEr, Erlang, and Elixir](https://pragprog.com/titles/fhproper/property-based-testing-with-proper-erlang-and-elixir/)


#### Integration Tests
- Integration tests check the _interaction between application elements_
- Integration test graph
    - https://i.gyazo.com/1859516ac6ef53031e615148844c1851.png
- The cost is tighter coupling


#### Three Examples
- Unit tests
- Integrtion tests
    1. will use **LiveViewTest** features to interact with LiveView
    2. will use **LiveViewTest** along with plain message passing to simulate PubSub messages


### Start with Unit Tests
- start with single-purpose, decoupled functions.
    - e.g., the CRC pipelines
        - can choose to test each contructor, reducer, and converter individually _as functions_
- By exercising individual complex functions in unit tests with many different inputs,
    - you can exhaustively cover corner cases that may be prone to failure.
- Then, you can write a smaller number of integration tests to comnfirm that the complex interactions of the system work.
- **SurveyResultsLive** component
    - the component's ability to obtain and filter survey results.
        - write advanced unit tests composed of reducer pipelines, then, move on to the integration tests.


## Unit Test Test Survery Results State
- unit tests that cover the **SurveyResultsLive** component's ability to manage survery results data in state.
    - the **assign_products_with_average_rationgs/2** reducer function,
        - which needs to handle both
            - an empty survery results dataset and
            - one with existing product ratings.


### survery_results_live_test.exs

#### write test fixtures

```elixir
def module PentoWeb.SurveyREsultsLiveTest do
  use Pento.DataCase
  alias PentoWeb.SurveyResultsLive

  alias Pento.{Accounts, Survey, Catalog}

  # module attributes to create test data
  @create_product_attrs %{
                           description: "test description",
                           name: "Test Game",
                           sky: 42,
                           unit_price: 120.5
                         }
  @create_user_attrs %{
                        email: "test@test.com",
                        password: "passwordpassword"
                      }
  @create_user2_attrs %{
                        email: "another-person@email.com",
                        password: "passwordpassword"
                      }
  @create_demographic_attrs %{
                               gender: "female",
                               year_of_birth: DateTime.utc_now.year - 15
                             }
  @create_demographic2_attrs %{
                               gender: "male",
                               year_of_birth: DateTime.utc_now.year - 30
                             }

  # Fixture functions to create test data
  defp product_fixture do
    {:ok, product} = Catalog.create_product(@create_product_attrs)
    product
  end

  defp user_fixture(attrs \\ @create_user_attrs) do
    {:ok, user} = Accounts.register_user(attrs)
    user
  end

  defp demographic_fixture(user, attrs \\ @create_demographic_attrs) do
    attrs =
      attrs
      |> Map.merge(%{user_id: user.id})
    {:ok, demographic} = Survey.create_demographic(attrs)
    demographic
  end

  defp rating_gixture(stars, user, product) do
    {:ok, rating} = Survey.create_rating(%{
                    stars: stars,
                    user_id: user.id,
                    product_id: product.id
                  })
    rating
  end

  # Helper functions to return the newly created records
  defp create_product(_) do
    product = product_fixture()
    %{product: product}
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_rating(stars, user, product) do
    rating = rating_fixture(stars, user, product)
    %{rating: rating}
  end

  defp create_demographic(user) do
    demographic = demographic_fixture(user)
    %{demographic: demographic}
  end

  defp create_socket(_) do
    %{socket: %Phoenix.LiveView.Socket{}}
  end
end
```

- Test fixtures create test data, and ours use module attributes to create **User**, **Demographic**, and **Rating** records
- Then, following a few helpers that call on our fixtures and return the newly created records.


#### write setup/1 function


```elixir
  describe "Socket state" do
    setup [:create_user, :create_product, :create_socket]

    setup %{user: user} do
      create_demographic(user)
      user2 = user_fixture(@create_user2_attrs)
      demographic_fixture(user2, @create_demographic2_attrs)
      [user2: user2]
    end
  end
```

- the **setup/1** funcion with ther list of helpers that will create a user, product, and socket struct.
- The **describe** function
    - groups together a block of tests
    - before each one of the block of tests, ExUnit will run the setup callbacks.
- Thick of both **setup** functions in the code before as **reducer**.
    - Both take an accumulator, called the context, which holds a bit of state.
- **setup** function with list
    - probides a list of atoms.
    - Each one is the name of a named setup function.
        - the named setup functions each create bits of data to add to the context.
            - e.g., the **create_socket** named setup function
                - returning an empty LiveView socket to add to the context.
                - By returning **%{socket: 
    - A setup function returns a map of data to merge into the context.
- **setup** function with map
    - is a reducer that further transforms the context.
