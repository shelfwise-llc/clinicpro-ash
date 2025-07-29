defmodule Clinicpro.PaystackLegacy.Subaccount do
  @moduledoc """
  Legacy Subaccount module for Paystack integration.
  
  This module provides legacy Paystack Subaccount functions for backward compatibility.
  It delegates to the new Paystack Subaccount implementation.
  """

  require Logger
  alias Clinicpro.Paystack.Subaccount, as: NewSubaccount

  @doc """
  Gets a subaccount by ID and clinic.
  Delegates to the new implementation if available.
  """
  def get_by_id_and_clinic(id, clinic_id) do
    if function_exported?(NewSubaccount, :get_by_id_and_clinic, 2) do
      NewSubaccount.get_by_id_and_clinic(id, clinic_id)
    else
      Logger.warning("NewSubaccount.get_by_id_and_clinic/2 not implemented, returning error")
      {:error, :not_found}
    end
  end

  @doc """
  Gets the active subaccount for a clinic.
  Delegates to the new implementation if available.
  """
  def getactive(clinic_id) do
    if function_exported?(NewSubaccount, :getactive, 1) do
      NewSubaccount.getactive(clinic_id)
    else
      Logger.warning("NewSubaccount.getactive/1 not implemented, returning error")
      {:error, :not_found}
    end
  end

  @doc """
  Updates a subaccount.
  Delegates to the new implementation if available.
  """
  def update(subaccount, attrs) do
    if function_exported?(NewSubaccount, :update, 2) do
      NewSubaccount.update(subaccount, attrs)
    else
      Logger.warning("NewSubaccount.update/2 not implemented, returning error")
      {:error, :not_implemented}
    end
  end
end
