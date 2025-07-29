defmodule Clinicpro.Repo.Migrations.AddPasswordHashToDoctors do
  use Ecto.Migration

  def change do
    alter table(:doctors) do
      add :password_hash, :string
    end
  end
end
