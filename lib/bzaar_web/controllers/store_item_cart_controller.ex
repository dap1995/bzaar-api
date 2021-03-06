defmodule BzaarWeb.StoreItemCartController do
  use Bzaar.Web, :controller

  alias Bzaar.{ItemCart, Store, User, Product, Size}

  plug :validate_nested_resource when action in [:update]

  @in_bag 0
  @buy_requested 1
  @sale_confirmed 2
  @waiting_delivery 3
  @delivered 4
  @canceled 5
  @in_loco 6

  def validate_nested_resource(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    %{"item_cart" => new_item, "id" => item_id} = conn.params
    new_status = new_item["status"]
    item_cart = get_item_by_id_and_user(item_id, user.id)
    validate_update_action(conn, item_cart, new_status)
  end

  defp validate_update_action(conn, item_cart, new_status) do
    case {item_cart, new_status} do
      {nil, _} -> conn
        |> put_status(403)
        |> render(BzaarWeb.ErrorView, "error.json", error: "User doesn't have this resource associated")
        |> halt # Used to prevend Plug.Conn.AlreadySentError
      {%ItemCart{status: status}, new_status}
        when (status + 1) == new_status # When newStatus is the next sequence number
          or (status == @buy_requested and new_status == @canceled) # or newStatus is to cancel a confirmed status
          or (status == @buy_requested and new_status == @in_loco) # or newStatus is to confirm a sale without delivery
         -> conn
      _ -> conn
        |> put_status(403)
        |> render(BzaarWeb.ErrorView, "error.json", error: "It's not possible, sorry")
        |> halt # Used to prevend Plug.Conn.AlreadySentError
    end
  end

  defp get_item_by_id_and_user(item_id, user_id) do
    Repo.one(
      from i in ItemCart,
      join: z in Size, on: z.id == i.size_id,
      join: p in Product, on: p.id == z.product_id,
      join: s in Store, on: s.id == p.store_id,
      join: u in User, on: u.id == s.user_id,
     where: i.id == ^item_id and u.id == ^user_id
    )
  end

  def index(conn, %{"store_id" => store_id}) do
    user = Guardian.Plug.current_resource(conn)
    item_cart = Repo.all(from i in ItemCart,
      join: z in Size, on: z.id == i.size_id,
      join: p in Product, on: p.id == z.product_id,
      join: s in Store, on: s.id == p.store_id,
      preload: [
        :user,
        :address,
        :size, {:size, [:product, {:product, [:images]}]}
      ],
      where: p.store_id == ^store_id
    )
    render(conn, "index_product.json", store_item_cart: item_cart)
  end

  @doc """
  Preload Product and Size based on `size_id`. 
  """
  defp load_size(%{"size_id" => size_id}) do
    Repo.one(
      from s in Size,
      where: s.id == ^size_id,
      preload: [:product, {:product, [:images]}]
    )
  end

  defp get_size_fields(size) do
    [%{url: url}| tail] = size.product.images
    %{
      "size_name" => size.name,
      "product_name" => size.product.name,
      "size_price" => size.price,
      "product_image" => url
    }
  end

  def show(conn, %{"id" => id}) do
    item_cart = ItemCart
      |> from()
      |> preload([:address, :size, {:size, [:product, {:product, [:images]}]}])
      |> Repo.get!(id)
    render(conn, BzaarWeb.StoreItemCartView, "show.json", store_item_cart: item_cart)
  end

  def update(conn, %{"id" => id, "item_cart" => item_cart_params}) do
    item_cart = Repo.one!(from i in ItemCart,
      preload: [
        :user, :address, :size, {:size, [
          :product, {:product, [
            :images, :store, {:store, [
              :user
            ]}
          ]}
        ]}
      ],
      where: i.id == ^id
    )
    changeset = ItemCart.store_changeset(item_cart, item_cart_params)

    case Repo.update(changeset) do
      {:ok, item_cart} ->
        notification = case item_cart.status do
          @sale_confirmed -> Bzaar.Email.notify_store_confirmation(item_cart)
          @waiting_delivery -> Bzaar.Email.notify_in_delivery(item_cart)
          @canceled -> Bzaar.Email.notify_cancel(item_cart)
          @in_loco -> Bzaar.Email.notify_on_product_available(item_cart)
        end
        notification |> Bzaar.Mailer.deliver_later
        render(conn, "show.json", store_item_cart: item_cart)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BzaarWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
