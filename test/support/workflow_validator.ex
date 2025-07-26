defmodule Clinicpro.WorkflowValidator do
  @moduledoc """
  Provides validation functions for workflow state transitions.
  This module can be used in both tests and the actual controller.
  """

  @doc """
  Validates that the current step can transition to the next step.
  Returns :ok if valid, {:error, reason} if invalid.
  """
  def validate_transition(workflow_state, next_step) do
    case {workflow_state.workflow_type, workflow_state.current_step, next_step} do
      # Doctor flow transitions
      {:doctor_flow, :list_appointments, :access_appointment} ->
        :ok

      {:doctor_flow, :access_appointment, :fill_medical_details} ->
        :ok

      {:doctor_flow, :fill_medical_details, :record_diagnosis} ->
        :ok

      {:doctor_flow, :record_diagnosis, :complete_appointment} ->
        :ok

      {:doctor_flow, :complete_appointment, :completed} ->
        :ok

      # Completed workflows cannot be modified
      {_unused, :completed, _unused} ->
        {:error, "Workflow is already completed and cannot be modified"}

      # Invalid transition
      {workflow_type, current, next} ->
        {:error, "Invalid transition from #{current} to #{next} in #{workflow_type} workflow"}
    end
  end

  @doc """
  Validates that the required data is present for the current step.
  Returns :ok if valid, {:error, reason} if invalid.
  """
  def validate_step_data(workflow_state) do
    case {workflow_state.workflow_type, workflow_state.current_step} do
      # Fill medical details requires appointment_id
      {:doctor_flow, :fill_medical_details} ->
        if Map.has_key?(workflow_state, :appointment_id) do
          :ok
        else
          {:error, "Missing appointment_id for fill_medical_details step"}
        end

      # Record diagnosis requires appointment_id and medical_details
      {:doctor_flow, :record_diagnosis} ->
        cond do
          not Map.has_key?(workflow_state, :appointment_id) ->
            {:error, "Missing appointment_id for record_diagnosis step"}

          not Map.has_key?(workflow_state, :medical_details) ->
            {:error, "Missing medical_details for record_diagnosis step"}

          true ->
            :ok
        end

      # Complete appointment requires appointment_id, medical_details, and diagnosis
      {:doctor_flow, :complete_appointment} ->
        cond do
          not Map.has_key?(workflow_state, :appointment_id) ->
            {:error, "Missing appointment_id for complete_appointment step"}

          not Map.has_key?(workflow_state, :medical_details) ->
            {:error, "Missing medical_details for complete_appointment step"}

          not Map.has_key?(workflow_state, :diagnosis) ->
            {:error, "Missing diagnosis for complete_appointment step"}

          true ->
            :ok
        end

      # Other steps don't require specific data
      _unused ->
        :ok
    end
  end

  @doc """
  Validates medical details input.
  Returns :ok if valid, {:error, reason} if invalid.
  """
  def validate_medical_details(medical_details) do
    required_fields = ["height", "weight", "blood_pressure", "temperature"]

    missing_fields =
      Enum.filter(required_fields, fn field ->
        not Map.has_key?(medical_details, field)
      end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required medical details: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  @doc """
  Validates diagnosis input.
  Returns :ok if valid, {:error, reason} if invalid.
  """
  def validate_diagnosis(diagnosis) do
    required_fields = ["diagnosis", "treatment"]

    missing_fields =
      Enum.filter(required_fields, fn field ->
        not Map.has_key?(diagnosis, field)
      end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required diagnosis fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end
end
