defmodule ResidentialTenancyAct.Acts.RTASections do
  @moduledoc """
  Provides functionality for searching RTA sections using vector similarity.

  This module handles similarity searches across different jurisdictions' Residential Tenancy Act sections
  using vector embeddings for semantic matching.
  """

  import Ecto.Query
  alias ResidentialTenancyAct.Acts.NSWRTASections

  @threshold 0.3

  @type jurisdiction :: :nsw | :vic | :qld | :sa | :wa | :tas | :act | :nt
  @type embeddings :: [float()]
  @type section :: %{
          id: String.t(),
          title: String.t(),
          url: String.t(),
          text: String.t(),
          match: float()
        }

  @spec similarity_search(jurisdiction(), embeddings()) :: [section()]
  def similarity_search(:nsw, embeddings) do
    from(section in NSWRTASections,
      select: %{
        id: section.id,
        title: section.title,
        url: section.url,
        text: section.text,
        match: fragment("1 - (embeddings <=> ?::vector)", ^embeddings)
      },
      where: fragment("1 - (embeddings <=> ?::vector) > ?", ^embeddings, ^@threshold),
      order_by: fragment("embeddings <=> ?::vector", ^embeddings),
      limit: 5
    )
    |> ResidentialTenancyAct.Repo.all(prefix: "rtas")
  end

  def similarity_search(_, _embeddings) do
    raise "Not implemented"
  end
end
