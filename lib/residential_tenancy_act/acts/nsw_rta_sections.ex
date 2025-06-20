defmodule ResidentialTenancyAct.Acts.NSWRTASections do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Acts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.Extension]

  postgres do
    schema "rtas"
    table "nsw_rta_sections"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:create]

    default_accept [:id, :title, :part_id, :division_id, :url]

    read :read do
      primary? true

      pagination do
        required? false
        offset? true
        countable true
      end
    end

    update :update do
      accept [
        :id,
        :title,
        :part_id,
        :division_id,
        :url,
        :text,
        :hash,
        :token_count,
        :embeddings_stale,
        :embeddings
      ]
    end

    read :hashes do
      prepare build(select: [:id, :hash])
    end
  end

  attributes do
    attribute :id, :string do
      allow_nil? false
      primary_key? true
    end

    attribute :title, :string do
      allow_nil? false
    end

    attribute :part_id, :string do
      allow_nil? false
    end

    attribute :division_id, :string do
      allow_nil? false
    end

    attribute :text, :string do
      allow_nil? true
    end

    attribute :embeddings, :vector do
      allow_nil? true
    end

    attribute :url, :string do
      allow_nil? false
    end

    attribute :token_count, :integer do
      allow_nil? true
    end

    attribute :hash, :string do
      allow_nil? true
    end

    attribute :embeddings_stale, :boolean do
      allow_nil? false
      default false
    end
  end

  relationships do
    belongs_to :part, ResidentialTenancyAct.Acts.NSWRTAParts do
      source_attribute :part_id
    end

    belongs_to :division, ResidentialTenancyAct.Acts.NSWRTADivisions do
      source_attribute :division_id
    end
  end

  @doc """
  Generates a SHA-256 hash of the provided text content and returns it as a lowercase hex string.
  This is used to detect changes in section content by comparing hashes rather than full text.
  """
  def hash_content(text) do
    :crypto.hash(:sha256, text)
    |> Base.encode16()
    |> String.downcase()
  end
end
