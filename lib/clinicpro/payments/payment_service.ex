defmodule Clinicpro.Payments.PaymentService do
  @moduledoc """
  SRP-compliant payment processing service.
  Handles Paystack and M-Pesa integration per clinic.
  """

  alias Clinicpro.Payments.Payment
  alias Clinicpro.Repo
  alias Clinicpro.Paystack.HTTP

  @doc "Process Paystack payment"
  def process_paystack_payment(attrs, clinic_id) do
    %Payment{}
    |> Payment.changeset(Map.put(attrs, :clinic_id, clinic_id))
    |> Repo.insert()
    |> case do
      {:ok, payment} -> 
        initiate_paystack_transaction(payment)
      {:error, changeset} -> 
        {:error, changeset}
    end
  end

  @doc "Process M-Pesa payment"
  def process_mpesa_payment(attrs, clinic_id) do
    %Payment{}
    |> Payment.changeset(Map.put(attrs, :clinic_id, clinic_id))
    |> Repo.insert()
    |> case do
      {:ok, payment} -> 
        initiate_mpesa_transaction(payment)
      {:error, changeset} -> 
        {:error, changeset}
    end
  end

  @doc "Get payments for clinic"
  def list_payments(clinic_id) do
    Repo.all(from p in Payment, where: p.clinic_id == ^clinic_id)
  end

  defp initiate_paystack_transaction(payment) do
    case HTTP.initiate_transaction(%{
      amount: payment.amount,
      email: payment.customer_email,
      reference: payment.reference
    }) do
      {:ok, response} -> {:ok, Map.put(payment, :gateway_response, response)}
      {:error, error} -> {:error, error}
    end
  end

  defp initiate_mpesa_transaction(payment) do
    # M-Pesa integration placeholder
    {:ok, payment}
  end
end
