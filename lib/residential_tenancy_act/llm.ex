defmodule ResidentialTenancyAct.LLM do
  @embeddings_model "amazon.titan-embed-text-v2:0"
  @text_model "apac.amazon.nova-lite-v1:0"
  @aws_region "ap-southeast-2"

  require Logger

  @spec generate_embeddings(String.t(), map()) ::
          {:ok, list(float()), non_neg_integer()} | {:error, any()}
  def generate_embeddings(text, metadata \\ %{}) do
    if is_nil(text) or text == "" do
      Logger.warning("Attempted to generate embeddings for nil or empty text", metadata)
      {:error, :invalid_text}
    else
      request =
        build_embedding_payload(text)
        |> then(&ExAws.Bedrock.invoke_model(@embeddings_model, &1))

      response =
        request
        |> ExAws.request(
          service_override: :bedrock,
          region: @aws_region
        )

      case response do
        {:ok, %{"embedding" => embeddings, "inputTextTokenCount" => token_count}} ->
          Logger.debug(
            "Generated embeddings successfully",
            Map.put(metadata, :token_count, token_count)
          )

          {:ok, embeddings, token_count}

        {:ok, unexpected_response} ->
          Logger.error(
            "Unexpected response format from Bedrock",
            Map.put(metadata, :response, unexpected_response)
          )

          {:error, {:unexpected_response, unexpected_response}}

        {:error, error} ->
          Logger.error("Failed to generate embeddings", Map.put(metadata, :error, error))
          {:error, error}
      end
    end
  end

  def generate_text_response(messages, metadata \\ %{}) do
    request =
      messages
      |> build_response_payload()
      |> ResidentialTenancyAct.LLM.AWSNovaRequest.to_map()
      |> then(&ExAws.Bedrock.invoke_model(@text_model, &1))

    response =
      request
      |> ExAws.Bedrock.request(region: @aws_region)

    case response do
      {:ok,
       %{"output" => %{"message" => %{"content" => [%{"text" => text}]}}, "usage" => usage}} ->
        result = %{
          text: text,
          usage: usage
        }

        Logger.debug("Generated text response successfully", Map.put(metadata, :text, text))
        {:ok, result}

      _ ->
        Logger.error(
          "Unexpected response format from Bedrock",
          Map.put(metadata, :response, response)
        )

        {:error, :unexpected_response_format}
    end
  end

  @spec build_response_payload([ResidentialTenancyAct.LLM.AWSNovaRequest.Message.t()]) ::
          ResidentialTenancyAct.LLM.AWSNovaRequest.t()
  defp build_response_payload(messages) do
    %ResidentialTenancyAct.LLM.AWSNovaRequest{
      messages: messages,
      inferenceConfig: %ResidentialTenancyAct.LLM.AWSNovaRequest.InferenceConfig{
        temperature: 0.9
      }
    }
  end

  @spec build_embedding_payload(String.t()) :: map()
  defp build_embedding_payload(text) do
    %{"inputText" => text}
  end
end
