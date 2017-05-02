defmodule Bzaar.StoreTest do
  use Bzaar.ModelCase

  alias Bzaar.Store

  @valid_attrs %{active: true, description: "some content", email: "some content", logo: "some content", name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Store.changeset(%Store{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Store.changeset(%Store{}, @invalid_attrs)
    refute changeset.valid?
  end
end
