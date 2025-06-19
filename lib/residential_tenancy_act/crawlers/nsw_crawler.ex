defmodule ResidentialTenancyAct.Crawlers.NSWCrawler do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url, do: "https://classic.austlii.edu.au/au/legis/nsw/consol_act/rta2010207/"

  @impl Crawly.Spider
  def init() do
    [start_urls: ["https://classic.austlii.edu.au/au/legis/nsw/consol_act/rta2010207/"]]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    url = response.request_url

    IO.inspect("Crawler: Processing URL " <> url)

    parsed_item =
      case url do
        "https://classic.austlii.edu.au/au/legis/nsw/consol_act/rta2010207/" ->
          parse_table_of_contents(response.body)

        _ ->
          parse_section(response.body)
      end

    parsed_item
  end

  def parse_table_of_contents(body) do
    parts = parse_parts(body)

    parts
    |> Enum.map(&Map.delete(&1, :content))
    |> Ash.bulk_create!(
      ResidentialTenancyAct.Acts.NSWRTAPart,
      :create,
      upsert?: true,
      upsert_fields: :replace_all
    )

    divisions =
      parts
      |> Enum.map(&get_divisions/1)
      |> List.flatten()

    divisions
    |> Enum.map(&Map.delete(&1, :content))
    |> Ash.bulk_create!(
      ResidentialTenancyAct.Acts.NSWRTADivisions,
      :create,
      upsert?: true,
      upsert_fields: :replace_all
    )

    sections =
      divisions
      |> Enum.map(& parse_division/1)
      |> Enum.filter(& &1)
      |> List.flatten()

    sections
    |> Ash.bulk_create!(
      ResidentialTenancyAct.Acts.NSWRTASections,
      :create,
      upsert?: true,
      upsert_fields: :replace_all
    )

    section_urls =
      sections
      |> Enum.map(&%Crawly.Request{url: &1.url})

    %Crawly.ParsedItem{
      items: [],
      requests: section_urls
    }
  end

  def parse_parts(html) do
    {:ok, document} = Floki.parse_document(html)

    parts =
      document
      |> Floki.find("pre")
      |> Floki.raw_html()
      |> String.split("<a name=\"p")
      |> Enum.drop(1)
      |> Enum.map(&("<a name=\"p" <> &1))
      |> Enum.map(&parse_part(&1))

    parts
  end

  defp parse_part(html) do
    {:ok, fragment} = Floki.parse_fragment(html)

    fragment
    |> Floki.find("b")
    |> Enum.map(&Floki.text/1)
    |> Enum.filter(&String.starts_with?(&1, "PART"))
    |> Enum.map(
      &%{
        title: extract_part_title(&1),
        id: extract_part_id(&1),
        content: html
      }
    )
    |> hd()
  end

  def get_divisions(%{id: part_id, content: html}) do
    html
    |> String.split("<b>Division")
    |> Enum.drop(1)
    |> Enum.map(&("<b>Division " <> &1))
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn item ->
      get_division_details(item, part_id)
      |> Map.put(:content, item)
    end)
  end

  def get_division_details(html, part_id) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find("b")
    |> Enum.map(fn item ->
      [division | division_title_fragments] =
        Floki.text(item)
        |> String.split("-")
        |> Enum.map(&String.trim(&1))

      division_title = division_title_fragments |> Enum.join(" - ")

      division_key =
        division
        |> String.replace("Division ", "")
        |> String.trim()

      %{
        id: format_division_id(division_key, part_id),
        title: division_title,
        part_id: part_id,
        division_id: division_key
      }
    end)
    |> hd()
  end

  def parse_division(%{id: division_id, part_id: part_id, content: html}) do
    html
    |> String.split("<a name=\"s")
    |> Enum.drop(1)
    |> Enum.map(fn html_content ->
      fragment =
        html_content
        |> then(&("<a name=\"s" <> &1))
        |> String.split("\n")
        |> Enum.at(0)
        |> String.trim()
        |> Floki.parse_fragment!()

      [section_id, section_title] =
        fragment
        |> Floki.text()
        |> String.split(".")
        |> Enum.map(&String.trim/1)

      url =
        fragment
        |> Floki.find("a")
        |> Enum.map(&Floki.attribute(&1, "name"))
        |> List.flatten()
        |> hd()
        |> then(&(base_url() <> &1 <> ".html"))

      %{
        id: section_id,
        title: section_title,
        division_id: division_id,
        part_id: part_id,
        url: url
      }
    end)
  end

  defp format_division_id(id, part_id) do
    "P#{part_id}_D#{id}"
  end

  defp extract_part_title(full_title) do
    full_title
    |> String.split("-")
    |> Enum.drop(1)
    |> Enum.map(&String.trim/1)
    |> hd()
  end

  defp extract_part_id(full_title) do
    full_title
    |> String.split("-")
    |> hd()
    |> String.trim()
    |> String.replace("PART ", "")
  end

  def parse_section(body) do
    section_prefix = "RESIDENTIAL TENANCIES ACT 2010 - SECT"

    # Split by <hr> and get the second part (index 1)
    parts = String.split(body, "<HR>")

    raw_content =
      Enum.at(parts, 1)

    # Parse the fragment safely
    fragment =
      case Floki.parse_fragment(raw_content) do
        {:ok, parsed} ->
          parsed

        {:error, reason} ->
          IO.puts("Warning: Failed to parse HTML fragment: #{inspect(reason)}")
          # Return empty list as fallback
          []
      end

    content =
      fragment
      |> Floki.text()
      |> String.trim()

    # Safely extract section ID
    section_id =
      fragment
      |> Floki.find("h3")
      |> Enum.map(&Floki.text(&1))
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&String.starts_with?(&1, section_prefix))
      |> case do
        [] ->
          IO.puts("Warning: Could not find section ID in h3 tags")
          "unknown"

        [id | _] ->
          id
          |> String.replace(section_prefix, "")
          |> String.trim()
      end

    # Only try to update if we have a valid section ID
    if section_id != "unknown" do
      try do
        ResidentialTenancyAct.Acts.NSWRTASections
        |> Ash.get!(section_id)
        |> Ash.Changeset.for_update(:update, %{text: content})
        |> Ash.update!()
      rescue
        e ->
          IO.puts("Warning: Failed to update section #{section_id}: #{inspect(e)}")
      end
    end

    %Crawly.ParsedItem{
      items: [],
      requests: []
    }
  end
end
