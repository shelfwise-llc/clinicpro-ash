defmodule Clinicpro.Mocks do
  @moduledoc """
  Mock definitions for testing.

  This module defines Mox mocks for Ash resources to allow controller tests
  to run without requiring real Ash resource compilation.
  """

  # Define mocks for Ash APIs
  Mox.defmock(Clinicpro.MockAsh.AppointmentsMock, for: Clinicpro.MockAsh.AppointmentsBehaviour)
  Mox.defmock(Clinicpro.MockAsh.PatientsMock, for: Clinicpro.MockAsh.PatientsBehaviour)
  Mox.defmock(Clinicpro.MockAsh.ClinicsMock, for: Clinicpro.MockAsh.ClinicsBehaviour)

  # Define mocks for PaymentProcessor
  Mox.defmock(Clinicpro.Invoices.PaymentProcessorMock,
    for: Clinicpro.Invoices.PaymentProcessorBehaviour
  )
end

defmodule Clinicpro.MockAsh.AppointmentsBehaviour do
  @moduledoc """
  Behaviour for mocking Appointments API.
  """
  @callback get_appointment(String.t()) :: map()
  @callback list_appointments(String.t()) :: [map()]
  @callback create_appointment(map()) :: {:ok, map()} | {:error, any()}
  @callback update_appointment(map(), map()) :: {:ok, map()} | {:error, any()}
  @callback update_appointment(String.t(), map()) :: {:ok, map()} | {:error, any()}
  @callback delete_appointment(String.t()) :: {:ok, map()} | {:error, any()}
  @callback get_appointment!(String.t()) :: map() | no_return()
end

defmodule Clinicpro.MockAsh.PatientsBehaviour do
  @moduledoc """
  Behaviour for mocking Patients API.
  """
  @callback get_patient(String.t()) :: map()
  @callback list_patients() :: [map()]
  @callback create_patient(map()) :: {:ok, map()} | {:error, any()}
  @callback update_patient(String.t(), map()) :: {:ok, map()} | {:error, any()}
end

defmodule Clinicpro.MockAsh.ClinicsBehaviour do
  @moduledoc """
  Behaviour for mocking Clinics API.
  """
  @callback get_clinic(String.t()) :: map()
  @callback list_clinics() :: [map()]
  @callback create_clinic(map()) :: {:ok, map()} | {:error, any()}
  @callback update_clinic(String.t(), map()) :: {:ok, map()} | {:error, any()}
end

# M-Pesa STKPushMock removed - using Paystack instead

defmodule Clinicpro.Invoices.PaymentProcessorMock do
  @moduledoc """
  Mock implementation of the PaymentProcessor module for testing.
  """

  @behaviour Clinicpro.Invoices.PaymentProcessorBehaviour

  @doc """
  Mock implementation of the check_payment_status function.
  This function is mocked in tests to return different statuses.
  """
  @impl true
  def check_payment_status(invoice) do
    # Default implementation that will be overridden by Mox in tests
    {:ok, :pending}
  end

  @doc """
  Mock implementation of the process_payment function.
  """
  @impl true
  def process_payment(invoice, phone_number, opts \\ []) do
    # Default implementation that will be overridden by Mox in tests
    {:ok,
     %{
       id: "mock-transaction-id",
       clinic_id: invoice.clinic_id,
       invoice_id: invoice.id,
       patient_id: invoice.patient_id,
       amount: invoice.total,
       phone_number: phone_number,
       status: "pending",
       reference: invoice.reference_number
     }}
  end

  @doc """
  Mock implementation of the mark_invoice_as_paid function.
  """
  @impl true
  def mark_invoice_as_paid(invoice, transaction_id, opts \\ []) do
    # Default implementation that will be overridden by Mox in tests
    {:ok, %{invoice | payment_status: "paid", payment_reference: transaction_id}}
  end

  @doc """
  Mock implementation of the handle_completed_payment function.
  """
  @impl true
  def handle_completed_payment(transaction, opts \\ []) do
    # Default implementation that will be overridden by Mox in tests
    {:ok,
     %{
       id: transaction.invoice_id,
       payment_status: "paid",
       payment_reference: transaction.transaction_id
     }}
  end

  @doc """
  Mock implementation of the handle_failed_payment function.
  """
  @impl true
  def handle_failed_payment(transaction, opts \\ []) do
    # Default implementation that will be overridden by Mox in tests
    {:ok, transaction}
  end
end
