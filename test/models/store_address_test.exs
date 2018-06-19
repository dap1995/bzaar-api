defmodule Bzaar.StoreAddressTest do
  use Bzaar.ModelCase

  alias Bzaar.StoreAddress

  @valid_attrs %{cep: 42, city: "some content", complement: "some content", latitude: "120.5", longitude: "120.5", name: "some content", number: 42, street: "some content", uf: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = StoreAddress.changeset(%StoreAddress{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = StoreAddress.changeset(%StoreAddress{}, @invalid_attrs)
    refute changeset.valid?
  end
end