defmodule ResidentialTenancyAct.LLM.AWSNovaRequest do
  @moduledoc """
  Represents a complete request to AWS Bedrock Nova model API.

  This struct encapsulates the full request schema including system messages,
  conversation messages, inference configuration, and tool configuration.
  """

  # System message content
  defmodule SystemContent do
    @moduledoc "Represents system message content"
    @derive Jason.Encoder
    defstruct [:text]
    @type t :: %__MODULE__{text: String.t()}
  end

  # Text content for messages
  defmodule TextContent do
    @moduledoc "Represents text content in a message"
    @derive Jason.Encoder
    defstruct [:text]
    @type t :: %__MODULE__{text: String.t()}
  end

  # Image content for messages
  defmodule ImageContent do
    @moduledoc "Represents image content in a message"
    @derive Jason.Encoder
    defstruct [:format, :source]

    @type format :: :jpeg | :png | :gif | :webp
    @type source ::
            %{bytes: binary()} | %{s3Location: %{uri: String.t(), bucketOwner: String.t() | nil}}

    @type t :: %__MODULE__{
            format: format(),
            source: source()
          }
  end

  # Video content for messages
  defmodule VideoContent do
    @moduledoc "Represents video content in a message"
    @derive Jason.Encoder
    defstruct [:format, :source]

    @type format :: :mkv | :mov | :mp4 | :webm | :three_gp | :flv | :mpeg | :mpg | :wmv
    @type source ::
            %{bytes: binary()} | %{s3Location: %{uri: String.t(), bucketOwner: String.t() | nil}}

    @type t :: %__MODULE__{
            format: format(),
            source: source()
          }
  end

  # Message content can be text, image, or video
  @type content :: TextContent.t() | ImageContent.t() | VideoContent.t()

  # Individual message in the conversation
  defmodule Message do
    @moduledoc "Represents a message in the conversation"
    @derive Jason.Encoder
    defstruct [:role, :content]

    @type role :: :user | :assistant
    @type t :: %__MODULE__{
            role: role(),
            content: [ResidentialTenancyAct.LLM.AWSNovaRequest.content()]
          }
  end

  # Inference configuration
  defmodule InferenceConfig do
    @moduledoc "Represents inference configuration parameters"
    @derive Jason.Encoder
    defstruct [:maxTokens, :temperature, :topP, :topK, :stopSequences]

    @type t :: %__MODULE__{
            maxTokens: pos_integer() | nil,
            temperature: float() | nil,
            topP: float() | nil,
            topK: non_neg_integer() | nil,
            stopSequences: [String.t()] | nil
          }
  end

  # Tool input schema
  defmodule ToolInputSchema do
    @moduledoc "Represents the input schema for a tool"
    @derive Jason.Encoder
    defstruct [:json]

    @type t :: %__MODULE__{
            json: %{
              type: String.t(),
              properties: map(),
              required: [String.t()]
            }
          }
  end

  # Tool specification
  defmodule ToolSpec do
    @moduledoc "Represents a tool specification"
    @derive Jason.Encoder
    defstruct [:name, :description, :inputSchema]

    @type t :: %__MODULE__{
            name: String.t(),
            description: String.t(),
            inputSchema: ToolInputSchema.t()
          }
  end

  # Tool configuration
  defmodule ToolConfig do
    @moduledoc "Represents tool configuration"
    @derive Jason.Encoder
    defstruct [:tools, :toolChoice]

    @type t :: %__MODULE__{
            tools: [ToolSpec.t()] | nil,
            toolChoice: %{auto: %{}} | nil
          }
  end

  # Main request struct
  @derive Jason.Encoder
  defstruct [:system, :messages, :inferenceConfig, :toolConfig]

  @type t :: %__MODULE__{
          system: [SystemContent.t()] | nil,
          messages: [Message.t()],
          inferenceConfig: InferenceConfig.t() | nil,
          toolConfig: ToolConfig.t() | nil
        }

  @doc """
  Converts the request struct to the map format expected by AWS Bedrock Nova API.
  """
  @spec to_map(t()) :: %{String.t() => any()}
  def to_map(%__MODULE__{} = request) do
    %{}
    |> maybe_add_system(request.system)
    |> Map.put("messages", Enum.map(request.messages, &message_to_map/1))
    |> maybe_add_inference_config(request.inferenceConfig)
    |> maybe_add_tool_config(request.toolConfig)
  end

  # Helper functions for conversion
  defp maybe_add_system(map, nil), do: map

  defp maybe_add_system(map, system) do
    Map.put(map, "system", Enum.map(system, &system_content_to_map/1))
  end

  defp maybe_add_inference_config(map, nil), do: map

  defp maybe_add_inference_config(map, config) do
    Map.put(map, "inferenceConfig", inference_config_to_map(config))
  end

  defp maybe_add_tool_config(map, nil), do: map

  defp maybe_add_tool_config(map, config) do
    Map.put(map, "toolConfig", tool_config_to_map(config))
  end

  defp system_content_to_map(%SystemContent{} = content) do
    %{"text" => content.text}
  end

  defp message_to_map(%Message{} = message) do
    %{
      "role" => Atom.to_string(message.role),
      "content" => Enum.map(message.content, &content_to_map/1)
    }
  end

  defp content_to_map(%TextContent{} = content) do
    %{"text" => content.text}
  end

  defp content_to_map(%ImageContent{} = content) do
    %{
      "image" => %{
        "format" => Atom.to_string(content.format),
        "source" => content.source
      }
    }
  end

  defp content_to_map(%VideoContent{} = content) do
    %{
      "video" => %{
        "format" => Atom.to_string(content.format),
        "source" => content.source
      }
    }
  end

  defp inference_config_to_map(%InferenceConfig{} = config) do
    %{}
    |> maybe_put("maxTokens", config.maxTokens)
    |> maybe_put("temperature", config.temperature)
    |> maybe_put("topP", config.topP)
    |> maybe_put("topK", config.topK)
    |> maybe_put("stopSequences", config.stopSequences)
  end

  defp tool_config_to_map(%ToolConfig{} = config) do
    %{}
    |> maybe_put("tools", config.tools && Enum.map(config.tools, &tool_spec_to_map/1))
    |> maybe_put("toolChoice", config.toolChoice)
  end

  defp tool_spec_to_map(%ToolSpec{} = spec) do
    %{
      "toolSpec" => %{
        "name" => spec.name,
        "description" => spec.description,
        "inputSchema" => tool_input_schema_to_map(spec.inputSchema)
      }
    }
  end

  defp tool_input_schema_to_map(%ToolInputSchema{} = schema) do
    %{"json" => schema.json}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
