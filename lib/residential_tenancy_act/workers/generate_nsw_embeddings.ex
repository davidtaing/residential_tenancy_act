defmodule ResidentialTenancyAct.Workers.GenerateNSWEmbeddings do
  use Oban.Worker, queue: :default

  import Ecto.Query

  alias ResidentialTenancyAct.Acts.NSWRTASections

  @page_size 20

  @impl Oban.Worker
  def perform(_job) do
    first_page =
      get_sections(@page_size)

    process_page(first_page)

    :ok
  end

  @spec get_sections(non_neg_integer(), non_neg_integer()) :: Ash.Page.Offset.t()
  defp get_sections(limit, offset \\ 0) do
    NSWRTASections
    |> Ash.read!(page: [limit: limit, offset: offset])
  end

  @spec process_page(Ash.Page.Offset.t()) :: :ok
  def process_page(page) do
    page.results
    |> Enum.filter(& &1.embeddings_stale)
    |> Enum.map(&update_embeddings(&1))

    case page.more? do
      false ->
        page

      true ->
        next_page = get_sections(@page_size, page.offset + @page_size)
        process_page(next_page)
    end

    :ok
  end

  def update_embeddings(section) do
    embedding_response = ResidentialTenancyAct.LLM.generate_embeddings(section.text)

    payload =
      case embedding_response do
        {:ok, embeddings, token_count} ->
          %{embeddings: embeddings, token_count: token_count}

        {:error, _error} ->
          nil
      end

    if payload do
      from(s in NSWRTASections.table_name(),
        where: s.id == ^section.id,
        update: [
          set: [
            embeddings: ^payload.embeddings,
            token_count: ^payload.token_count,
            embeddings_stale: false
          ]
        ]
      )
      |> ResidentialTenancyAct.Repo.update_all([], prefix: "rtas")
    end
  end
end
