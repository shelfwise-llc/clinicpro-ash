defmodule Clinicpro.Medications.TypesenseConfig do
  @moduledoc """
  Configuration for Typesense medication search with multi-tenant support.
  Each clinic can have its own Typesense collection for medications.
  """
  import Ecto.Query
  # # alias Clinicpro.Repo
  alias Clinicpro.Clinics.Clinic

  @doc """
  Returns the Typesense client for the application.
  """
  def client do
    config = Application.get_env(:clinicpro, :typesense) || %{}

    Typesense.configure(
      host: config[:host] || "localhost",
      port: config[:port] || 8108,
      protocol: config[:protocol] || "http",
      api_key: config[:api_key] || "xyz"
    )

    Typesense.client()
  end

  @doc """
  Returns the collection name for a specific clinic.
  This ensures multi-tenant isolation of medication data.
  """
  def collection_name(_clinic_id) when is_binary(_clinic_id) do
    "medications_#{_clinic_id}"
  end

  @doc """
  Creates the medication collection for a specific clinic if it doesn't exist.
  """
  def create_collection_if_not_exists(_clinic_id) when is_binary(_clinic_id) do
    collection_name = collection_name(_clinic_id)

    # Check if collection exists
    case Typesense.collections(client()) do
      {:ok, collections} ->
        if Enum.any?(collections, fn c -> c["name"] == collection_name end) do
          {:ok, :already_exists}
        else
          create_collection(collection_name)
        end

      {:error, _unused} ->
        create_collection(collection_name)
    end
  end

  defp create_collection(collection_name) do
    schema = %{
      "name" => collection_name,
      "fields" => [
        %{
          "name" => "id",
          "type" => "string",
          "facet" => false
        },
        %{
          "name" => "name",
          "type" => "string",
          "facet" => false
        },
        %{
          "name" => "code",
          "type" => "string",
          "facet" => true
        },
        %{
          "name" => "form",
          "type" => "string",
          "facet" => true
        },
        %{
          "name" => "strength",
          "type" => "string",
          "facet" => true
        },
        %{
          "name" => "controlled_substance",
          "type" => "bool",
          "facet" => true
        },
        %{
          "name" => "category",
          "type" => "string",
          "facet" => true
        }
      ],
      "default_sorting_field" => "name"
    }

    Typesense.create_collection(client(), schema)
  end

  @doc """
  Indexes a medication in the clinic's Typesense collection.
  """
  def index_medication(_clinic_id, medication) do
    collection_name = collection_name(_clinic_id)

    # Ensure collection exists
    create_collection_if_not_exists(_clinic_id)

    # Index the medication
    Typesense.create_document(client(), collection_name, medication)
  end

  @doc """
  Searches for medications in the clinic's Typesense collection.
  """
  def search_medications(_clinic_id, query, options \\ %{}) do
    collection_name = collection_name(_clinic_id)

    # Default search parameters
    search_params =
      Map.merge(
        %{
          "q" => query,
          "query_by" => "name,code",
          "sort_by" => "name:asc",
          "_per_page" => 10
        },
        options
      )

    case Typesense.search(client(), collection_name, search_params) do
      {:ok, results} -> {:ok, results["hits"] || []}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Initializes Typesense collections for all clinics.
  This should be called during application startup.
  """
  def initialize_for_all_clinics do
    # Get all clinic IDs
    clinic_ids = Repo.all(from(c in Clinic, select: c.id))

    # Create collections for each clinic
    Enum.each(clinic_ids, fn _clinic_id ->
      create_collection_if_not_exists(_clinic_id)
    end)
  end
end
