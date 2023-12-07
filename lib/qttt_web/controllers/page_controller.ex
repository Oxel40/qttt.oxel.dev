defmodule QtttWeb.PageController do
  use QtttWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: {QtttWeb.Layouts, :blank})
  end
end
