defmodule ResidentialTenancyActWeb.MarkdownHelper do
  @moduledoc """
  Helper module for rendering markdown content in the chat interface.
  """

  @max_input_size 50_000  # 50KB limit to prevent resource exhaustion

  @doc """
  Converts markdown text to HTML with custom styling for the chat interface.
  Includes security measures to prevent XSS and other attacks.
  """
  def render_markdown(text) when is_binary(text) do
    cond do
      byte_size(text) > @max_input_size ->
        Phoenix.HTML.raw("<p class=\"text-red-600\">Message too large to render safely.</p>")

      true ->
        text
        |> Earmark.as_html!(%Earmark.Options{
          smartypants: false,
          gfm: true,
          breaks: true
        })
        |> sanitize_html()
        |> add_custom_styling()
        |> Phoenix.HTML.raw()
    end
  end

  def render_markdown(_), do: ""

  defp sanitize_html(html) do
    # Use html_sanitize_ex for robust sanitization
    HtmlSanitizeEx.basic_html(html)
  end

  defp add_custom_styling(html) do
    html
    |> String.replace("<p>", "<p class=\"mb-3 leading-relaxed\">")
    |> String.replace("<h1>", "<h1 class=\"text-xl font-bold mb-4 mt-6 text-emerald-900\">")
    |> String.replace("<h2>", "<h2 class=\"text-lg font-semibold mb-3 mt-5 text-emerald-900\">")
    |> String.replace("<h3>", "<h3 class=\"text-base font-semibold mb-2 mt-4 text-emerald-900\">")
    |> String.replace("<h4>", "<h4 class=\"text-sm font-semibold mb-2 mt-3 text-emerald-900\">")
    |> String.replace("<h5>", "<h5 class=\"text-sm font-semibold mb-2 mt-3 text-emerald-900\">")
    |> String.replace("<h6>", "<h6 class=\"text-sm font-semibold mb-2 mt-3 text-emerald-900\">")
    |> String.replace("<ul>", "<ul class=\"list-disc list-inside mb-3 space-y-1\">")
    |> String.replace("<ol>", "<ol class=\"list-decimal list-inside mb-3 space-y-1\">")
    |> String.replace("<li>", "<li class=\"text-sm\">")
    |> String.replace("<strong>", "<strong class=\"font-semibold text-emerald-900\">")
    |> String.replace("<em>", "<em class=\"italic\">")
    |> String.replace("<code>", "<code class=\"bg-emerald-100 text-emerald-800 px-1 py-0.5 rounded text-xs font-mono\">")
    |> String.replace("<pre>", "<pre class=\"bg-emerald-50 border border-emerald-200 rounded-md p-3 mb-3 overflow-x-auto\">")
    |> String.replace("<pre class=\"", "<pre class=\"bg-emerald-50 border border-emerald-200 rounded-md p-3 mb-3 overflow-x-auto ")
    |> String.replace("<blockquote>", "<blockquote class=\"border-l-4 border-emerald-300 pl-4 py-2 mb-3 bg-emerald-50 italic\">")
    |> String.replace("<hr>", "<hr class=\"border-emerald-300 my-4\">")
    |> String.replace("<a ", "<a class=\"text-emerald-700 underline hover:text-emerald-900\" ")
    |> String.replace("<table>", "<table class=\"border-collapse border border-emerald-300 mb-3 w-full\">")
    |> String.replace("<th>", "<th class=\"border border-emerald-300 px-3 py-2 bg-emerald-100 text-left font-semibold\">")
    |> String.replace("<td>", "<td class=\"border border-emerald-300 px-3 py-2\">")
  end
end
