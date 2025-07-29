defmodule Clinicpro.TestHelpers do
  @moduledoc """
  Helper functions for testing the ClinicPro application.

  This module provides functions for setting up test data and mocking external API calls
  for Paystack and Virtual Meetings integration tests.
  "

  alias Clinicpro.Repo
  alias Clinicpro.Clinics.Clinic
  alias Clinicpro.AdminBypass.Appointment
  alias Clinicpro.Paystack.Transaction

  @doc \"""
  Creates a test clinic with the given name and configuration.
  """
  def create_test_clinic(name, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          name: name,
          virtual_meeting_config: %{
            adapter: "Clinicpro.VirtualMeetings.SimpleAdapter"
          }
        },
        attrs
      )

    %Clinicpro.Clinics.Clinic{}
    |> struct(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a test appointment for the given clinic.
  """
  def create_test_appointment(clinic_id, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          clinic_id: clinic_id,
          patient_id: Ecto.UUID.generate(),
          doctor_id: Ecto.UUID.generate(),
          appointment_date: Date.utc_today(),
          appointment_time: ~T[10:00:00],
          duration: 30,
          type: "virtual",
          status: "pending_payment",
          amount: 1000,
          reference: "APP-#{Ecto.UUID.generate()}",
          meeting_url: nil,
          meeting_provider: nil
        },
        attrs
      )

    %Clinicpro.AdminBypass.Appointment{}
    |> struct(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a test Paystack transaction for the given clinic.
  """
  def create_test_transaction(clinic_id, attrs \\ %{}) do
    default_attrs =
      Map.merge(
        %{
          clinic_id: clinic_id,
          email: "test@example.com",
          amount: 1000,
          reference: "TEST-#{Ecto.UUID.generate()}",
          description: "Test transaction",
          status: "pending"
        },
        attrs
      )

    %Clinicpro.Paystack.Transaction{}
    |> struct(default_attrs)
    |> Repo.insert()
  end

  @doc """
  Mocks a Paystack payment callback for the given transaction.
  """
  def mock_paystack_callback(transaction) do
    %{
      "event" => "charge.success",
      "data" => %{
        "id" => transaction.id,
        "status" => "success",
        "reference" => transaction.reference,
        "amount" => transaction.amount,
        "paid_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "channel" => "card",
        "currency" => "KES",
        "metadata" => %{},
        "customer" => %{
          "email" => transaction.email
        }
      }
    }
  end

  @doc """
  Mocks a Google API response for creating a meeting.
  """
  def mock_google_api_response do
    %{
      "id" => "google_meeting_#{Ecto.UUID.generate()}",
      "htmlLink" => "https://meet.google.com/#{random_meeting_code()}",
      "conferenceData" => %{
        "conferenceId" => "#{random_meeting_code()}",
        "entryPoints" => [
          %{
            "entryPointType" => "video",
            "uri" => "https://meet.google.com/#{random_meeting_code()}",
            "label" => "meet.google.com/#{random_meeting_code()}"
          }
        ]
      }
    }
  end

  @doc """
  Mocks a Zoom API response for creating a meeting.
  """
  def mock_zoom_api_response do
    %{
      "id" => :rand.uniform(999_999_999),
      "join_url" => "https://zoom.us/j/#{:rand.uniform(999_999_999)}",
      "password" => random_meeting_code(6),
      "host_email" => "host@example.com",
      "topic" => "Test Meeting",
      "start_time" => "#{DateTime.utc_now() |> DateTime.to_iso8601()}",
      "duration" => 30
    }
  end

  @doc """
  Generates a random meeting code.
  """
  def random_meeting_code(length \\ 10) do
    chars = "abcdefghijklmnopqrstuvwxyz0123456789"

    1..length
    |> Enum.map(fn _unused -> String.at(chars, :rand.uniform(String.length(chars)) - 1) end)
    |> Enum.join("")
  end
end
