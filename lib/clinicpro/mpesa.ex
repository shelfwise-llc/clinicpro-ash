defmodule Clinicpro.MPesa do
  @moduledoc """
  The MPesa context.

  This module serves as the main interface for all M-Pesa operations.
  It provides functions for managing configurations, transactions, and
  interacting with the M-Pesa API.
  """

  import Ecto.Query

  alias Clinicpro.Repo
  alias Clinicpro.MPesa.{Config, Transaction}

  @doc """
  Returns a config changeset.
  """
  def change_config(%Config{} = config, attrs \\ %{}) do
    Config.changeset(config, attrs)
  end

  @doc """
  Creates a new M-Pesa configuration.
  """
  def create_config(attrs) do
    %Config{}
    |> Config.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an M-Pesa configuration.
  """
  def update_config(%Config{} = config, attrs) do
    config
    |> Config.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an M-Pesa configuration.
  """
  def delete_config(%Config{} = config) do
    Repo.delete(config)
  end

  @doc """
  Gets an M-Pesa configuration by ID.
  """
  def get_config!(id) do
    Repo.get!(Config, id)
  end

  @doc """
  Gets an M-Pesa configuration by clinic ID.
  """
  def get_config_by_clinic(clinic_id) do
    Repo.get_by(Config, clinic_id: clinic_id)
  end

  @doc """
  Gets an M-Pesa transaction by ID.
  """
  def get_transaction!(id) do
    Repo.get!(Transaction, id)
  end

  @doc """
  Initiates an STK Push request.

  ## Parameters

  - params: Map containing:
    - phone: Phone number to send STK Push to
    - amount: Amount to charge
    - reference: Transaction reference
    - description: Transaction description
    - clinic_id: ID of the clinic

  ## Returns

  - {:ok, transaction} on success
  - {:error, reason} on failure
  """
  def initiate_stk_push(params) do
    # Create a pending transaction
    with {:ok, transaction} <- Transaction.create_pending(Map.put(params, "type", "stk_push")),
         {:ok, config} <- get_active_config(params.clinic_id),
         {:ok, response} <- do_stk_push(config, transaction) do

      # Update transaction with response data
      transaction_attrs = %{
        checkout_request_id: response["CheckoutRequestID"],
        merchant_request_id: response["MerchantRequestID"],
        raw_request: params,
        raw_response: response
      }

      Transaction.update(transaction, transaction_attrs)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Registers C2B URLs with M-Pesa.

  ## Parameters

  - config: The M-Pesa configuration to use

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def register_c2b_urls(config) do
    # This is a placeholder. In a real implementation, this would
    # make an API call to register the C2B URLs with M-Pesa.
    # For now, we'll just simulate a successful response.

    {:ok, %{
      "ResponseCode" => "0",
      "ResponseDescription" => "Success"
    }}
  end

  # Private functions

  defp get_active_config(clinic_id) do
    case Repo.get_by(Config, clinic_id: clinic_id, active: true) do
      nil -> {:error, :no_active_config}
      config -> {:ok, config}
    end
  end

  defp do_stk_push(config, transaction) do
    # This is a placeholder. In a real implementation, this would
    # make an API call to the M-Pesa STK Push endpoint.
    # For now, we'll just simulate a successful response.

    {:ok, %{
      "MerchantRequestID" => "#{System.unique_integer([:positive])}",
      "CheckoutRequestID" => "ws_CO_#{System.unique_integer([:positive])}",
      "ResponseCode" => "0",
      "ResponseDescription" => "Success. Request accepted for processing",
      "CustomerMessage" => "Success. Request accepted for processing"
    }}
  end
end
