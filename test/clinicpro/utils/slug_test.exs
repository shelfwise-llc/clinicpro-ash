defmodule Clinicpro.Utils.SlugTest do
  @moduledoc """
  Tests for the Slug utility module.
  """
  use ExUnit.Case, async: true
  alias Clinicpro.Utils.Slug

  describe "generate/1" do
    test "converts a string to a valid slug" do
      assert Slug.generate("Test String") == "test-string"
    end

    test "handles special characters" do
      assert Slug.generate("Test & String!") == "test-string"
    end

    test "handles multiple spaces" do
      assert Slug.generate("Test   String") == "test-string"
    end

    test "handles leading and trailing spaces" do
      assert Slug.generate("  Test String  ") == "test-string"
    end

    test "handles nil values" do
      assert Slug.generate(nil) == ""
    end

    test "handles empty strings" do
      assert Slug.generate("") == ""
    end

    test "handles non-Latin characters" do
      assert Slug.generate("Café Ñoño") == "cafe-nono"
    end

    test "handles numbers" do
      assert Slug.generate("Test 123") == "test-123"
    end

    test "handles underscores and dashes" do
      assert Slug.generate("test_string-here") == "test-string-here"
    end
  end
end
