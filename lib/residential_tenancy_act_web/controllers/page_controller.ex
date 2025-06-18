defmodule ResidentialTenancyActWeb.PageController do
  use ResidentialTenancyActWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
