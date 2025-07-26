# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Clinicpro.Repo.insert!(%Clinicpro.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Clinicpro.Accounts
alias Clinicpro.Accounts.User
alias Clinicpro.Accounts.Role
alias Clinicpro.Repo
require Logger

Logger.info("Starting seed data creation...")

# Create roles if they don't exist
create_role = fn name, description ->
  case Accounts.get_by_name(name) do
    {:ok, role} ->
      Logger.info("Role '#{name}' already exists")
      role

    {:error, _} ->
      Logger.info("Creating role '#{name}'")
      {:ok, role} = Accounts.create_role(name, description)
      role
  end
end

doctor_role = create_role.("doctor", "Medical professional who diagnoses and treats patients")
patient_role = create_role.("patient", "Person receiving medical care")

# Create users with hardcoded credentials
create_user = fn email, first_name, last_name, role ->
  # Check if user already exists
  case User
       |> Ash.Query.filter(email == email)
       |> Ash.read_one(api: Accounts) do
    {:ok, user} ->
      Logger.info("User '#{email}' already exists")
      user

    {:error, _} ->
      Logger.info("Creating user '#{email}'")

      # Create user
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, %{
          email: email,
          first_name: first_name,
          last_name: last_name,
          phone_number: nil
        })
        |> Ash.create(api: Accounts)

      # Assign role to user
      {:ok, _} = Accounts.assign_role(user.id, role.id)

      # Generate authentication token for development
      {:ok, token} = Accounts.AuthPlaceholder.generate_token_for_user(user.id)
      Logger.info("Generated token for #{email}: #{token.token}")
      Logger.info("User ID: #{token.user.id}, Role: #{token.user.role}")

      user
  end
end

# Create doctor user
doctor = create_user.("doctor@clinicpro.com", "Doctor", "User", doctor_role)

# Create patient user
patient = create_user.("patient@clinicpro.com", "Patient", "User", patient_role)

Logger.info("Seed data creation completed!")
Logger.info("=== HARDCODED CREDENTIALS ===")
Logger.info("Doctor: email=doctor@clinicpro.com, password=doctor123")
Logger.info("Patient: email=patient@clinicpro.com, password=patient123")
Logger.info("")
Logger.info("You can authenticate using:")
Logger.info("Accounts.authenticate_by_email(\"doctor@clinicpro.com\")")
Logger.info("Accounts.authenticate_by_credentials(\"doctor@clinicpro.com\", \"doctor123\")")
Logger.info("")
Logger.info("For token verification use:")
Logger.info("Accounts.verify_token(\"your-token-string\")")
Logger.info("")
Logger.info("NOTE: This is a development-only authentication system.")
Logger.info("      Do not use in production!")

Logger.info("Doctor: email=doctor@clinicpro.com, password=doctor123, role=doctor")
Logger.info("Patient: email=patient@clinicpro.com, password=patient123, role=patient")

Logger.info(
  "Use Accounts.AuthPlaceholder.authenticate_by_email/1 to generate tokens for these users"
)
