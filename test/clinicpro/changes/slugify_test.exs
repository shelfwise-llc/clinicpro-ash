defmodule Clinicpro.Changes.SlugifyTest do
  @moduledoc """
  Tests for the Slugify change module.
  """
  use Clinicpro.DataCase, async: true
  alias Ash.Changeset
  alias Clinicpro.Changes.Slugify

  # Define a simple test resource schema
  defmodule TestResource do
    use Ash.Resource, data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string)
      attribute(:slug, :string)
    end

    actions do
      defaults([:create, :read, :update])
    end
  end

  describe "change/2" do
    test "generates a slug from the source attribute" do
      changeset =
        TestResource
        |> Changeset.new()
        |> Changeset.set_attribute(:name, "Test Resource")
        |> Slugify.change(%{source: :name, target: :slug})

      assert Changeset.get_attribute(changeset, :slug) == "test-resource"
    end

    test "handles nil source values" do
      changeset =
        TestResource
        |> Changeset.new()
        |> Changeset.set_attribute(:name, nil)
        |> Slugify.change(%{source: :name, target: :slug})

      assert Changeset.get_attribute(changeset, :slug) == ""
    end

    test "handles empty source values" do
      changeset =
        TestResource
        |> Changeset.new()
        |> Changeset.set_attribute(:name, "")
        |> Slugify.change(%{source: :name, target: :slug})

      assert Changeset.get_attribute(changeset, :slug) == ""
    end

    test "preserves existing slug if source is not changed" do
      changeset =
        TestResource
        |> Changeset.new()
        |> Changeset.set_attribute(:name, "Test Resource")
        |> Changeset.set_attribute(:slug, "existing-slug")
        |> Slugify.change(%{source: :name, target: :slug, force: false})

      assert Changeset.get_attribute(changeset, :slug) == "existing-slug"
    end

    test "forces slug update when force option is true" do
      changeset =
        TestResource
        |> Changeset.new()
        |> Changeset.set_attribute(:name, "Test Resource")
        |> Changeset.set_attribute(:slug, "existing-slug")
        |> Slugify.change(%{source: :name, target: :slug, force: true})

      assert Changeset.get_attribute(changeset, :slug) == "test-resource"
    end

    test "handles special characters in source" do
      changeset =
        TestResource
        |> Changeset.new()
        |> Changeset.set_attribute(:name, "Test & Resource!")
        |> Slugify.change(%{source: :name, target: :slug})

      assert Changeset.get_attribute(changeset, :slug) == "test-resource"
    end
  end
end
