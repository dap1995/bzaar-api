defmodule Bzaar.ProductImage do
  use Bzaar.Web, :model

  # https://github.com/elixir-ecto/ecto/issues/840
  @derive {Poison.Encoder, only: [:id, :url, :sequence]}
  schema "product_images" do
    field :url, :string
    field :sequence, :integer
    belongs_to :product, Bzaar.Product

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :sequence])
    |> assoc_constraint(:product)
    |> validate_required([:url, :sequence])
  end

  def changeset_validate_product_id(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :sequence, :product_id])
    |> assoc_constraint(:product)
    |> validate_required([:url, :sequence, :product_id])
  end
end
