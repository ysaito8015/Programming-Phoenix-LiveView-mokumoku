#---
# Excerpted from "Programming Phoenix LiveView",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/liveview for more book information.
#---
defmodule PentoWeb.UserLiveAuth do
  import Phoenix.LiveView
  alias Pento.Accounts

  def mount(params, %{"user_token" => user_token} = _session, socket) do
    socket = assign(socket, :current_user, Accounts.get_user_by_session_token(user_token))
    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end
