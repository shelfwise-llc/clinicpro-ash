defmodule Clinicpro.Medications do
  @moduledoc """
  The Medications context.
  Handles medication management with Typesense integration for search functionality.
  Supports multi-tenant architecture with clinic-specific medication collections.
  """

  alias Clinicpro.Medications.TypesenseConfig
  # # alias Clinicpro.Repo
  alias Ecto.UUID

  @doc """
  Searches for medications in the clinic's collection.
  Returns a list of matching medications.
  """
  def search(clinic_id, query, options \\ %{}) do
    case TypesenseConfig.search_medications(clinic_id, query, options) do
      {:ok, results} ->
        {:ok, Enum.map(results, fn hit -> hit["document"] end)}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Adds a medication to the clinic's collection.
  """
  def add_medication(clinic_id, attrs) do
    # Generate a UUID if not provided
    medication = Map.put_new(attrs, "id", UUID.generate())

    case TypesenseConfig.index_medication(clinic_id, medication) do
      {:ok, result} -> {:ok, result}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Bulk imports medications for a clinic.
  Useful for initial setup or data migration.
  """
  def bulk_import(clinic_id, medications) do
    # Ensure each medication has an ID
    medications =
      Enum.map(medications, fn med ->
        Map.put_new(med, "id", UUID.generate())
      end)

    # Create the collection if it doesn't exist
    TypesenseConfig.create_collection_if_not_exists(clinic_id)

    # Get the collection name
    collection_name = TypesenseConfig.collection_name(clinic_id)

    # Import the medications
    TypesenseConfig.client()
    |> Typesense.import_documents(collection_name, medications)
  end

  @doc """
  Returns a list of common medication forms for UI dropdowns.
  """
  def medication_forms do
    [
      "Tablet",
      "Capsule",
      "Liquid",
      "Injection",
      "Cream",
      "Ointment",
      "Gel",
      "Patch",
      "Inhaler",
      "Spray",
      "Drops",
      "Suppository"
    ]
  end

  @doc """
  Returns a list of common medication frequencies for UI dropdowns.
  """
  def medication_frequencies do
    [
      "Once daily",
      "Twice daily",
      "Three times daily",
      "Four times daily",
      "Every 4 hours",
      "Every 6 hours",
      "Every 8 hours",
      "Every 12 hours",
      "As needed",
      "Before meals",
      "After meals",
      "At bedtime"
    ]
  end

  @doc """
  Returns a list of common medication durations for UI dropdowns.
  """
  def medication_durations do
    [
      "3 days",
      "5 days",
      "7 days",
      "10 days",
      "14 days",
      "21 days",
      "28 days",
      "30 days",
      "60 days",
      "90 days",
      "6 months",
      "Indefinitely"
    ]
  end

  @doc """
  Returns a list of common medication categories for UI dropdowns.
  """
  def medication_categories do
    [
      "Analgesic",
      "Antibiotic",
      "Antidepressant",
      "Antifungal",
      "Antihistamine",
      "Antihypertensive",
      "Anti-inflammatory",
      "Antimalarial",
      "Antipsychotic",
      "Antiviral",
      "Bronchodilator",
      "Decongestant",
      "Diuretic",
      "Hormone",
      "Sedative",
      "Steroid",
      "Supplement",
      "Vaccine"
    ]
  end
end
