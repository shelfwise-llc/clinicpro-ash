defmodule Clinicpro.Changes.Slugify do
  @moduledoc """
  A change module for generating slugs from a source attribute.

  This follows clean code principles by isolating the slug generation logic
  into a separate, reusable module with a single responsibility.

  ## Usage

  ```elixir
  change Clinicpro.Changes.Slugify, %{source: :name, target: :slug}
  ```

  ## Options

  * `:source` - The attribute to generate the slug from (required)
  * `:target` - The attribute to store the slug in (default: `:slug`)
  * `:force` - Whether to force update the slug even if it already exists (default: `false`)
  """
  use Ash.Resource.Change
  alias Clinicpro.Utils.Slug

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def change(changeset, opts, _context) do
    source = Map.get(opts, :source)
    target = Map.get(opts, :target, :slug)
    force = Map.get(opts, :force, false)
    
    # If we already have a target value and force is false, don't change anything
    if !force && Ash.Changeset.get_attribute(changeset, target) do
      changeset
    else
      # Get the source value and generate a slug
      source_value = Ash.Changeset.get_attribute(changeset, source)
      slug = Slug.generate(source_value)
      
      # Set the target attribute to the generated slug
      Ash.Changeset.set_attribute(changeset, target, slug)
    end
  end
end
