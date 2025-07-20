defmodule Clinicpro.Clinics.ClinicTest do
  @moduledoc """
  Tests for the Clinic resource in the Clinics context.
  """
  use Clinicpro.DataCase, async: true
  alias Clinicpro.Clinics
  alias Clinicpro.Clinics.Clinic
  alias Clinicpro.Accounts
  alias Clinicpro.Accounts.User

  setup do
    # Create a user that will be the owner of the clinic
    {:ok, user} = Accounts.register(%{
      email: "owner@example.com",
      first_name: "Clinic",
      last_name: "Owner",
      phone_number: "+1234567890"
    })

    %{user: user}
  end

  describe "clinic registration" do
    test "can register a clinic with valid attributes", %{user: user} do
      attrs = %{
        name: "Test Clinic",
        slug: "test-clinic",
        address: "123 Test Street",
        city: "Test City",
        country: "Test Country",
        phone_number: "+1234567890",
        email: "clinic@example.com",
        owner_id: user.id
      }

      assert {:ok, %Clinic{} = clinic} = Clinics.register(attrs)
      assert clinic.name == "Test Clinic"
      assert clinic.slug == "test-clinic"
      assert clinic.address == "123 Test Street"
      assert clinic.city == "Test City"
      assert clinic.country == "Test Country"
      assert clinic.phone_number == "+1234567890"
      assert clinic.email == "clinic@example.com"
      assert clinic.owner_id == user.id
    end

    test "cannot register a clinic with invalid attributes", %{user: user} do
      # Missing required fields
      attrs = %{
        name: "Test Clinic",
        owner_id: user.id
      }

      assert {:error, changeset} = Clinics.register(attrs)
      assert "can't be blank" in errors_on(changeset).slug
    end

    test "cannot register a clinic with duplicate slug", %{user: user} do
      attrs = %{
        name: "Test Clinic",
        slug: "test-clinic",
        address: "123 Test Street",
        city: "Test City",
        country: "Test Country",
        phone_number: "+1234567890",
        email: "clinic@example.com",
        owner_id: user.id
      }

      assert {:ok, %Clinic{}} = Clinics.register(attrs)
      
      # Try to register another clinic with the same slug
      attrs2 = Map.put(attrs, :name, "Another Clinic")
      
      assert {:error, changeset} = Clinics.register(attrs2)
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "clinic staff management" do
    setup %{user: owner} do
      # Create a clinic
      {:ok, clinic} = Clinics.register(%{
        name: "Test Clinic",
        slug: "test-clinic",
        address: "123 Test Street",
        city: "Test City",
        country: "Test Country",
        phone_number: "+1234567890",
        email: "clinic@example.com",
        owner_id: owner.id
      })

      # Create another user to be added as staff
      {:ok, staff_user} = Accounts.register(%{
        email: "staff@example.com",
        first_name: "Staff",
        last_name: "Member",
        phone_number: "+0987654321"
      })

      %{clinic: clinic, owner: owner, staff_user: staff_user}
    end

    test "can add staff to a clinic", %{clinic: clinic, staff_user: staff_user} do
      attrs = %{
        clinic_id: clinic.id,
        user_id: staff_user.id,
        role: "doctor"
      }

      assert {:ok, clinic_staff} = Clinics.add_staff(attrs)
      assert clinic_staff.clinic_id == clinic.id
      assert clinic_staff.user_id == staff_user.id
      assert clinic_staff.role == "doctor"
    end

    test "can list staff for a clinic", %{clinic: clinic, owner: owner, staff_user: staff_user} do
      # Add staff member
      Clinics.add_staff(%{
        clinic_id: clinic.id,
        user_id: staff_user.id,
        role: "doctor"
      })

      # List staff
      staff_list = Clinics.list_staff(clinic.id)
      
      # Should include both the owner and the staff member
      assert length(staff_list) == 2
      
      # Verify staff roles
      staff_roles = Enum.map(staff_list, & &1.role)
      assert "owner" in staff_roles
      assert "doctor" in staff_roles
      
      # Verify user IDs
      staff_user_ids = Enum.map(staff_list, & &1.user_id)
      assert owner.id in staff_user_ids
      assert staff_user.id in staff_user_ids
    end
  end
end
