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
