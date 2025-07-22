# M-Pesa Integration Test Scenarios

This document outlines manual test scenarios for verifying the M-Pesa integration in ClinicPro, focusing on the multi-tenant architecture where each clinic has its own M-Pesa configuration and isolated transactions.

## Prerequisites

1. Set up at least two test clinics in the system
2. Configure M-Pesa credentials for each clinic:
   - Different consumer keys and secrets
   - Different shortcodes
   - Different passkeys
   - Appropriate callback URLs

## Test Scenarios

### 1. Configuration Management

#### 1.1 Create Configuration for Multiple Clinics

**Steps:**
1. Create M-Pesa configuration for Clinic A
   ```elixir
   Clinicpro.MPesa.create_config(%{
     clinic_id: clinic_a_id,
     consumer_key: "test_key_a",
     consumer_secret: "test_secret_a",
     passkey: "test_passkey_a",
     shortcode: "123456",
     environment: "sandbox"
   })
   ```

2. Create M-Pesa configuration for Clinic B
   ```elixir
   Clinicpro.MPesa.create_config(%{
     clinic_id: clinic_b_id,
     consumer_key: "test_key_b",
     consumer_secret: "test_secret_b",
     passkey: "test_passkey_b",
     shortcode: "654321",
     environment: "sandbox"
   })
   ```

**Expected Results:**
- Both configurations should be created successfully
- Each configuration should be associated with its respective clinic

#### 1.2 Retrieve Clinic-Specific Configuration

**Steps:**
1. Retrieve configuration for Clinic A
   ```elixir
   {:ok, config_a} = Clinicpro.MPesa.Config.get_for_clinic(clinic_a_id)
   ```

2. Retrieve configuration for Clinic B
   ```elixir
   {:ok, config_b} = Clinicpro.MPesa.Config.get_for_clinic(clinic_b_id)
   ```

**Expected Results:**
- Each clinic should have its own distinct configuration
- Clinic A's configuration should not be accessible to Clinic B and vice versa

### 2. STK Push Transactions

#### 2.1 Initiate STK Push for Multiple Clinics

**Steps:**
1. Initiate STK Push for Clinic A
   ```elixir
   {:ok, transaction_a} = Clinicpro.MPesa.initiate_stk_push(
     clinic_a_id,
     "254712345678",
     100,
     "CLINIC-A-REF",
     "Clinic A Payment"
   )
   ```

2. Initiate STK Push for Clinic B
   ```elixir
   {:ok, transaction_b} = Clinicpro.MPesa.initiate_stk_push(
     clinic_b_id,
     "254712345678",
     200,
     "CLINIC-B-REF",
     "Clinic B Payment"
   )
   ```

**Expected Results:**
- Both transactions should be created successfully
- Each transaction should have unique checkout request IDs and merchant request IDs
- Each transaction should be associated with its respective clinic

#### 2.2 Process STK Push Callbacks

**Steps:**
1. Simulate STK Push callback for Clinic A
   ```elixir
   payload_a = %{
     "Body" => %{
       "stkCallback" => %{
         "MerchantRequestID" => transaction_a.merchant_request_id,
         "CheckoutRequestID" => transaction_a.checkout_request_id,
         "ResultCode" => 0,
         "ResultDesc" => "The service request is processed successfully.",
         "CallbackMetadata" => %{
           "Item" => [
             %{"Name" => "Amount", "Value" => 100},
             %{"Name" => "MpesaReceiptNumber", "Value" => "RECEIPT-A"},
             %{"Name" => "TransactionDate", "Value" => 20250722100436},
             %{"Name" => "PhoneNumber", "Value" => 254712345678}
           ]
         }
       }
     }
   }
   
   Clinicpro.MPesa.process_stk_callback(payload_a)
   ```

2. Simulate STK Push callback for Clinic B
   ```elixir
   payload_b = %{
     "Body" => %{
       "stkCallback" => %{
         "MerchantRequestID" => transaction_b.merchant_request_id,
         "CheckoutRequestID" => transaction_b.checkout_request_id,
         "ResultCode" => 0,
         "ResultDesc" => "The service request is processed successfully.",
         "CallbackMetadata" => %{
           "Item" => [
             %{"Name" => "Amount", "Value" => 200},
             %{"Name" => "MpesaReceiptNumber", "Value" => "RECEIPT-B"},
             %{"Name" => "TransactionDate", "Value" => 20250722100436},
             %{"Name" => "PhoneNumber", "Value" => 254712345678}
           ]
         }
       }
     }
   }
   
   Clinicpro.MPesa.process_stk_callback(payload_b)
   ```

**Expected Results:**
- Both callbacks should be processed successfully
- Each transaction should be updated with its respective receipt number
- Each transaction's status should be updated to "completed"

### 3. C2B URL Registration

#### 3.1 Register C2B URLs for Multiple Clinics

**Steps:**
1. Register C2B URLs for Clinic A
   ```elixir
   Clinicpro.MPesa.register_c2b_urls(clinic_a_id)
   ```

2. Register C2B URLs for Clinic B
   ```elixir
   Clinicpro.MPesa.register_c2b_urls(clinic_b_id)
   ```

**Expected Results:**
- URLs should be registered successfully for both clinics
- Each clinic should have its own validation and confirmation URLs

#### 3.2 Process C2B Callbacks

**Steps:**
1. Simulate C2B callback for Clinic A
   ```elixir
   payload_a = %{
     "TransactionType" => "Pay Bill",
     "TransID" => "C2B-A",
     "TransTime" => "20250722100436",
     "TransAmount" => "100.00",
     "BusinessShortCode" => "123456",
     "BillRefNumber" => "CLINIC-A-REF",
     "InvoiceNumber" => "",
     "OrgAccountBalance" => "",
     "ThirdPartyTransID" => "",
     "MSISDN" => "254712345678",
     "FirstName" => "John",
     "MiddleName" => "",
     "LastName" => "Doe"
   }
   
   Clinicpro.MPesa.process_c2b_callback(payload_a)
   ```

2. Simulate C2B callback for Clinic B
   ```elixir
   payload_b = %{
     "TransactionType" => "Pay Bill",
     "TransID" => "C2B-B",
     "TransTime" => "20250722100436",
     "TransAmount" => "200.00",
     "BusinessShortCode" => "654321",
     "BillRefNumber" => "CLINIC-B-REF",
     "InvoiceNumber" => "",
     "OrgAccountBalance" => "",
     "ThirdPartyTransID" => "",
     "MSISDN" => "254712345678",
     "FirstName" => "Jane",
     "MiddleName" => "",
     "LastName" => "Doe"
   }
   
   Clinicpro.MPesa.process_c2b_callback(payload_b)
   ```

**Expected Results:**
- Both callbacks should be processed successfully
- Each transaction should be associated with its respective clinic based on the shortcode
- Each transaction should have the correct amount and reference

### 4. Transaction Management

#### 4.1 List Transactions for Multiple Clinics

**Steps:**
1. List transactions for Clinic A
   ```elixir
   transactions_a = Clinicpro.MPesa.list_transactions(clinic_a_id)
   ```

2. List transactions for Clinic B
   ```elixir
   transactions_b = Clinicpro.MPesa.list_transactions(clinic_b_id)
   ```

**Expected Results:**
- Each clinic should only see its own transactions
- Clinic A should see transactions with references "CLINIC-A-REF"
- Clinic B should see transactions with references "CLINIC-B-REF"

#### 4.2 Get Transaction Statistics for Multiple Clinics

**Steps:**
1. Get statistics for Clinic A
   ```elixir
   stats_a = Clinicpro.MPesa.Transaction.get_stats_for_clinic(clinic_a_id)
   ```

2. Get statistics for Clinic B
   ```elixir
   stats_b = Clinicpro.MPesa.Transaction.get_stats_for_clinic(clinic_b_id)
   ```

**Expected Results:**
- Each clinic should have its own statistics
- Clinic A's statistics should reflect its transactions (amount: 100)
- Clinic B's statistics should reflect its transactions (amount: 200)

### 5. Edge Cases

#### 5.1 Handle Missing Configuration

**Steps:**
1. Attempt to initiate STK Push for a clinic without configuration
   ```elixir
   Clinicpro.MPesa.initiate_stk_push(
     non_existent_clinic_id,
     "254712345678",
     100,
     "TEST-REF",
     "Test Payment"
   )
   ```

**Expected Results:**
- Should return `{:error, :mpesa_config_not_found}`

#### 5.2 Handle Invalid Transaction Data

**Steps:**
1. Attempt to create a transaction with invalid data
   ```elixir
   Clinicpro.MPesa.initiate_stk_push(
     clinic_a_id,
     "invalid_phone",
     -100,
     "",
     "Invalid Payment"
   )
   ```

**Expected Results:**
- Should return `{:error, :invalid_transaction_data}`

#### 5.3 Handle Failed API Calls

**Steps:**
1. Simulate a failed API call (e.g., by temporarily setting an invalid consumer key)
   ```elixir
   # Temporarily update config with invalid credentials
   Clinicpro.MPesa.create_config(%{
     clinic_id: clinic_a_id,
     consumer_key: "invalid_key",
     consumer_secret: "invalid_secret",
     passkey: "invalid_passkey",
     shortcode: "123456",
     environment: "sandbox"
   })
   
   # Attempt STK Push
   Clinicpro.MPesa.initiate_stk_push(
     clinic_a_id,
     "254712345678",
     100,
     "TEST-REF",
     "Test Payment"
   )
   ```

**Expected Results:**
- Should handle the API failure gracefully
- Should return an appropriate error message

## Conclusion

These test scenarios verify that the M-Pesa integration correctly implements the multi-tenant architecture requirements, ensuring that:

1. Each clinic has its own M-Pesa configuration
2. Transactions are properly isolated by clinic
3. Callbacks are correctly processed and associated with the right clinic
4. Edge cases are handled appropriately

After completing these tests, restore any test data to its original state.
