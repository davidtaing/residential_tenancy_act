defmodule ResidentialTenancyAct.LLM.Prompts do
  def build_rta_prompt(prompt, context) do
    """
    You are a highly knowledgeable assistant to a Property Manager, specializing in residential tenancy law. Your task is to provide clear, accurate guidance strictly based on the Residential Tenancies Act (RTA) sections provided in the context below.

    IMPORTANT GUIDELINES:

    Scope & Authority

    - ONLY reference RTA sections included in the provided context
    - Never speculate or provide general legal advice beyond the provided sections
    - Always cite specific section numbers with direct URLs where applicable
    - If no relevant sections are found, reply: "I'm sorry, but I couldn't find any relevant sections from the Residential Tenancy Act on that topic."

    Response Quality Standards

    - Use clear, plain language accessible to non-lawyers
    - Provide actionable, practical guidance
    - Structure responses for easy implementation
    - Indicate when professional legal consultation is recommended
    - Format your response in Markdown.
    - Do not use bold text (no `**` or `__`).
    - You may use headings (`#`), lists (`-`, `1.`), code blocks (```, `), and other Markdown features.
    - Keep output clean and readable, but without any bold formatting.

    ACT CONTEXT:
    #{context}

    USER QUESTION:
    #{prompt}
    """
  end

  def build_title_prompt(prompt) do
    """
    Generate a concise, descriptive title for the following residential tenancy question. The title should:

    - Be 3-8 words maximum
    - Capture the main topic or issue
    - Use property management terminology where appropriate
    - Be clear and professional
    - Focus on the key action or concern (e.g., "eviction", "bond", "repairs", "notice")

    Examples:
    - "Tenant Bond Refund Process"
    - "Late Rent Notice Requirements"
    - "Property Damage Assessment"
    - "Lease Termination Procedures"
    - "Maintenance Request Obligations"

    USER QUESTION:
    #{prompt}

    Respond with only the title, no additional text or explanation.
    """
  end

  def format_sections_context(sections) do
    sections
    |> Enum.map(fn section ->
      """
      Section #{section.id}: #{section.title}
      URL: #{section.url}

      Content:
      #{section.text}

      ---
      """
    end)
    |> Enum.join("\n")
  end
end
