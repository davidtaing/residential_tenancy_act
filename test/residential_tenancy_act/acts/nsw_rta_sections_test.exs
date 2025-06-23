defmodule ResidentialTenancyAct.Acts.NSWRTASectionsTest do
  use ExUnit.Case, async: true

  alias ResidentialTenancyAct.Acts.NSWRTASections

  describe "hash_content/1" do
    test "generates SHA-256 hash for simple text" do
      text = "Hello, World!"
      hash = NSWRTASections.hash_content(text)

      # SHA-256 hash of "Hello, World!" in lowercase hex
      expected_hash = "dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f"

      assert hash == expected_hash
      assert String.length(hash) == 64
      assert hash =~ ~r/^[a-f0-9]+$/
    end

    test "generates consistent hash for same input" do
      text = "Residential Tenancy Act 2010"
      hash1 = NSWRTASections.hash_content(text)
      hash2 = NSWRTASections.hash_content(text)

      assert hash1 == hash2
    end

    test "generates different hashes for different inputs" do
      text1 = "Section 1"
      text2 = "Section 2"

      hash1 = NSWRTASections.hash_content(text1)
      hash2 = NSWRTASections.hash_content(text2)

      assert hash1 != hash2
    end

    test "handles empty string" do
      hash = NSWRTASections.hash_content("")

      # SHA-256 hash of empty string in lowercase hex
      expected_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

      assert hash == expected_hash
    end

    test "handles large text content" do
      large_text = String.duplicate("This is a large section of legal text. ", 100)
      hash = NSWRTASections.hash_content(large_text)

      assert String.length(hash) == 64
      assert hash =~ ~r/^[a-f0-9]+$/
    end

    test "handles special characters and unicode" do
      text = "Section 123: Rights & Obligations © 2024"
      hash = NSWRTASections.hash_content(text)

      assert String.length(hash) == 64
      assert hash =~ ~r/^[a-f0-9]+$/
    end

    test "returns lowercase hex string" do
      text = "Test Content"
      hash = NSWRTASections.hash_content(text)

      assert hash == String.downcase(hash)
      assert hash =~ ~r/^[a-f0-9]+$/
    end
  end
end
