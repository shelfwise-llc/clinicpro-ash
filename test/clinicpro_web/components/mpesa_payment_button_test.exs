defmodule ClinicproWeb.MPesaPaymentButtonTest do
  use ClinicproWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Clinicpro.Invoices
  alias Clinicpro.MPesa.Transaction

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "MPesaPaymentButton component with multi-tenant support" do
    setup do
      # Create test clinics
      {:ok, clinic1} = Clinicpro.Clinics.create_clinic(%{
        name: "Test Clinic 1",
        code: "TC1",
        address: "123 Test St",
        phone: "254700000001",
        email: "clinic1@test.com"
      })

      {:ok, clinic2} = Clinicpro.Clinics.create_clinic(%{
        name: "Test Clinic 2",
        code: "TC2",
        address: "456 Test Ave",
        phone: "254700000002",
        email: "clinic2@test.com"
      })

      # Create test patients for each clinic
      {:ok, patient1} = Clinicpro.Patients.create_patient(%{
        first_name: "John",
        last_name: "Doe",
        phone_number: "254711111111",
        email: "john@example.com",
        clinic_id: clinic1.id
      })

      {:ok, patient2} = Clinicpro.Patients.create_patient(%{
        first_name: "Jane",
        last_name: "Smith",
        phone_number: "254722222222",
        email: "jane@example.com",
        clinic_id: clinic2.id
      })

      # Create test invoices for each clinic
      {:ok, invoice1} = Invoices.create_invoice(%{
        patient_id: patient1.id,
        clinic_id: clinic1.id,
        reference_number: "INV-#{clinic1.code}-001",
        date: DateTime.utc_now(),
        due_date: DateTime.utc_now() |> DateTime.add(7, :day),
        status: "pending",
        payment_status: "pending",
        subtotal: Decimal.new("1000.00"),
        total: Decimal.new("1000.00"),
        items: [
          %{
            description: "Consultation Fee",
            quantity: 1,
            unit_price: Decimal.new("1000.00")
          }
        ]
      })

      {:ok, invoice2} = Invoices.create_invoice(%{
        patient_id: patient2.id,
        clinic_id: clinic2.id,
        reference_number: "INV-#{clinic2.code}-001",
        date: DateTime.utc_now(),
        due_date: DateTime.utc_now() |> DateTime.add(7, :day),
        status: "pending",
        payment_status: "pending",
        subtotal: Decimal.new("1500.00"),
        total: Decimal.new("1500.00"),
        items: [
          %{
            description: "Consultation Fee",
            quantity: 1,
            unit_price: Decimal.new("1500.00")
          }
        ]
      })

      # Mock the M-Pesa STK Push module
      Mox.stub(Clinicpro.MPesa.STKPushMock, :request, fn phone_number, amount, reference, clinic_id ->
        # Return different responses based on clinic_id to test multi-tenant behavior
        case clinic_id do
          ^clinic1.id ->
            {:ok, %{
              "MerchantRequestID" => "123456-#{clinic1.id}",
              "CheckoutRequestID" => "wx123-#{clinic1.id}",
              "ResponseCode" => "0",
              "ResponseDescription" => "Success. Request accepted for processing",
              "CustomerMessage" => "Success. Request accepted for processing"
            }}

          ^clinic2.id ->
            {:ok, %{
              "MerchantRequestID" => "789012-#{clinic2.id}",
              "CheckoutRequestID" => "wx456-#{clinic2.id}",
              "ResponseCode" => "0",
              "ResponseDescription" => "Success. Request accepted for processing",
              "CustomerMessage" => "Success. Request accepted for processing"
            }}

          _ ->
            {:error, "Invalid clinic ID"}
        end
      end)

      # Mock the payment status check
      Mox.stub(Clinicpro.Invoices.PaymentProcessorMock, :check_payment_status, fn invoice ->
        case invoice.id do
          _ -> {:ok, :pending}
        end
      end)

      # Return the test data
      %{
        clinic1: clinic1,
        clinic2: clinic2,
        patient1: patient1,
        patient2: patient2,
        invoice1: invoice1,
        invoice2: invoice2
      }
    end

    test "renders payment button for unpaid invoice", %{conn: conn, invoice1: invoice1} do
      # Create a test LiveView that uses the MPesaPaymentButton component
      {:ok, view, html} = live_isolated(conn, ClinicproWeb.TestLiveView, session: %{
        "invoice" => invoice1,
        "current_user" => %{id: "user-123"}
      })

      # Assert that the component renders correctly
      assert html =~ "Pay with M-Pesa"
      assert html =~ "Enter your phone number"
      assert html =~ "Pay KES #{Decimal.to_string(invoice1.total)}"
    end

    test "validates phone number format", %{conn: conn, invoice1: invoice1} do
      # Create a test LiveView that uses the MPesaPaymentButton component
      {:ok, view, _html} = live_isolated(conn, ClinicproWeb.TestLiveView, session: %{
        "invoice" => invoice1,
        "current_user" => %{id: "user-123"}
      })

      # Try to submit with invalid phone number
      view
      |> element("#mpesa-payment-form")
      |> render_submit(%{phone_number: "12345"})

      # Assert that validation error is shown
      assert render(view) =~ "Please enter a valid Kenyan phone number"

      # Try with valid phone number format but submit button should still be disabled
      view
      |> element("#mpesa-payment-form")
      |> render_change(%{phone_number: "254711222333"})

      # Assert that validation passes
      refute render(view) =~ "Please enter a valid Kenyan phone number"
    end

    test "initiates payment with correct clinic isolation", %{conn: conn, invoice1: invoice1, clinic1: clinic1} do
      # Create a test LiveView that uses the MPesaPaymentButton component
      {:ok, view, _html} = live_isolated(conn, ClinicproWeb.TestLiveView, session: %{
        "invoice" => invoice1,
        "current_user" => %{id: "user-123"}
      })

      # Fill in valid phone number and submit
      view
      |> element("#mpesa-payment-form")
      |> render_submit(%{phone_number: "254711222333"})

      # Assert that payment initiation message is shown
      assert render(view) =~ "Payment initiated"
      assert render(view) =~ "Please check your phone to complete the payment"

      # Verify that a transaction was created with the correct clinic_id
      :timer.sleep(100) # Give time for async operations
      transactions = Transaction.list_by_invoice_id(invoice1.id)
      assert length(transactions) == 1
      transaction = hd(transactions)
      assert transaction.clinic_id == clinic1.id
      assert transaction.status == "pending"
    end

    test "handles payment status check", %{conn: conn, invoice1: invoice1} do
      # Create a transaction for the invoice
      {:ok, transaction} = Transaction.create(%{
        clinic_id: invoice1.clinic_id,
        invoice_id: invoice1.id,
        patient_id: invoice1.patient_id,
        amount: invoice1.total,
        phone_number: "254711222333",
        status: "pending",
        merchant_request_id: "test-merchant-id",
        checkout_request_id: "test-checkout-id",
        reference: invoice1.reference_number
      })

      # Create a test LiveView that uses the MPesaPaymentButton component
      {:ok, view, _html} = live_isolated(conn, ClinicproWeb.TestLiveView, session: %{
        "invoice" => invoice1,
        "current_user" => %{id: "user-123"}
      })

      # Trigger payment status check
      view
      |> element("[phx-click=\"check_payment_status\"]")
      |> render_click()

      # Assert that pending status message is shown
      assert render(view) =~ "Payment is being processed"

      # Update transaction to completed
      {:ok, _updated} = Transaction.update(transaction, %{
        status: "completed",
        transaction_id: "MPESA123456"
      })

      # Override the mock to return completed status
      Mox.stub(Clinicpro.Invoices.PaymentProcessorMock, :check_payment_status, fn invoice ->
        case invoice.id do
          ^invoice1.id -> {:ok, :completed}
          _ -> {:ok, :pending}
        end
      end)

      # Trigger payment status check again
      view
      |> element("[phx-click=\"check_payment_status\"]")
      |> render_click()

      # Assert that completed status message is shown
      assert render(view) =~ "Payment completed successfully"
    end

    test "handles payment failure", %{conn: conn, invoice1: invoice1} do
      # Create a transaction for the invoice
      {:ok, transaction} = Transaction.create(%{
        clinic_id: invoice1.clinic_id,
        invoice_id: invoice1.id,
        patient_id: invoice1.patient_id,
        amount: invoice1.total,
        phone_number: "254711222333",
        status: "pending",
        merchant_request_id: "test-merchant-id",
        checkout_request_id: "test-checkout-id",
        reference: invoice1.reference_number
      })

      # Create a test LiveView that uses the MPesaPaymentButton component
      {:ok, view, _html} = live_isolated(conn, ClinicproWeb.TestLiveView, session: %{
        "invoice" => invoice1,
        "current_user" => %{id: "user-123"}
      })

      # Update transaction to failed
      {:ok, _updated} = Transaction.update(transaction, %{
        status: "failed",
        result_code: "1032",
        result_description: "Request cancelled by user"
      })

      # Override the mock to return failed status
      Mox.stub(Clinicpro.Invoices.PaymentProcessorMock, :check_payment_status, fn invoice ->
        case invoice.id do
          ^invoice1.id -> {:ok, :failed}
          _ -> {:ok, :pending}
        end
      end)

      # Trigger payment status check
      view
      |> element("[phx-click=\"check_payment_status\"]")
      |> render_click()

      # Assert that failure message is shown
      assert render(view) =~ "Payment failed"
      assert render(view) =~ "Request cancelled by user"

      # Assert that retry button is shown
      assert render(view) =~ "Try Again"
    end
  end
end

# Test LiveView for component testing
defmodule ClinicproWeb.TestLiveView do
  use ClinicproWeb, :live_view

  def mount(_params, %{"invoice" => invoice, "current_user" => current_user}, socket) do
    {:ok, assign(socket, invoice: invoice, current_user: current_user)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={ClinicproWeb.MPesaPaymentButton}
        id="mpesa-payment-button"
        invoice={@invoice}
        current_user={@current_user}
      />
    </div>
    """
  end
end
