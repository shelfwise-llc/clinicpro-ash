defmodule Clinicpro.MPesa.Disabled do
  @moduledoc """
  This module provides disabled versions of M-Pesa functionality.
  All functions return appropriate error responses indicating that M-Pesa is disabled.
  """
  
  require Logger
  
  @doc """
  Logs an attempt to use a disabled M-Pesa feature and returns an error.
  """
  def disabled_operation(operation_name) do
    Logger.warning("Attempted to use disabled M-Pesa operation: #{operation_name}")
    {:error, :mpesa_disabled}
  end
  
  @doc """
  Disabled version of STK push initiation.
  """
  def initiate_stk_push(_params) do
    disabled_operation("initiate_stk_push")
  end
  
  @doc """
  Disabled version of STK push status query.
  """
  def query_stk_status(_checkout_request_id, _config) do
    disabled_operation("query_stk_status")
  end
  
  @doc """
  Disabled version of transaction creation.
  """
  def create_transaction(_params) do
    disabled_operation("create_transaction")
  end
  
  @doc """
  Disabled version of transaction update.
  """
  def update_transaction(_transaction, _params) do
    disabled_operation("update_transaction")
  end
  
  @doc """
  Disabled version of transaction retrieval.
  """
  def get_transaction(_id) do
    disabled_operation("get_transaction")
  end
  
  @doc """
  Disabled version of transaction listing.
  """
  def list_transactions(_params \\ %{}) do
    disabled_operation("list_transactions")
  end
end
