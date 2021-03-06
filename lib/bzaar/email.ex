defmodule Bzaar.Email do
  import Bamboo.Email
  import Bamboo.Phoenix
  alias Bzaar.{User, ItemCart}

  @welcome_html """
  <strong>Estamos muito felizes por ter você aqui pertinho de nós</strong><br />
  Com o Bzaar, você poderá fazer milhares de compras e receber em pouco tempo na sua casa!
  Chega de esperar! O produto que você deseja pode estar próximo de você.
  <br />
  Aproveite!
  """
  @welcome_text "Bem vindo/a!"
  @bzaar_email "admin@bzaar.com.br"

  def welcome_email(%User{name: name, email: email}) do
    base_email()
    |> to(email)
    |> subject("#{name}, Seja bem vindo/a!!!")
    |> put_header("Reply-To", @bzaar_email)
    |> html_body(@welcome_html)
  end

  def confirmation_email(token, %User{name: name, email: email}) do
    base_email()
    |> to(email)
    |> subject("Confirmação de e-mail")
    |> put_header("Reply-To", @bzaar_email)
    |> html_body("""
    #{name}, Você acabou de se cadastrar no Bzaar, para ativar a sua conta clique no link abaixo:
    <a href="#{get_url()}/bzaar/auth/verify/?token=#{token}">Clique aqui para ativar sua conta</a><br />
    Caso você não se cadastrou em nossa aplicação você pode nos retornar este e-mail.
    """)
  end

  def notify_new_order(item_cart) do
    store = item_cart.size.product.store
    store_owner = store.user
    base_email()
    |> to(store_owner.email)
    |> subject("#{store_owner.name}, Um cliente solicitou confirmação da venda de um produto!")
    |> put_header("Reply-To", "#{item_cart.user.email}")
    |> html_body("""
      <h1>Produto aguardando sua confirmação!</h1><p />
      <h4>#{item_cart.product_name} - #{item_cart.size_name} - #{item_cart.size_price}</h4><p />
      Verifique se o produto está disponível e se está intacto. <br />
      Se está tudo ok, então confirme a venda!
      """)
  end

  def notify_store_confirmation(item_cart) do
    store = item_cart.size.product.store
    base_email()
    |> to(item_cart.user.email)
    |> subject("#{item_cart.user.name}, A loja #{store.name} CONFIRMOU a venda do produto!")
    |> put_header("Reply-To", "#{store.email}")
    |> html_body("""
      <h1>Produto #{item_cart.product_name} - #{item_cart.size_name} está sendo preparado para o envio!</h1><p />
      É bom ficar atento.
      """)
  end

  def notify_cancel(item_cart) do
    store = item_cart.size.product.store
    base_email()
    |> to(item_cart.user.email)
    |> subject("""
      #{item_cart.user.name}, o produto foi cancelado. Sentimos muito! 
      """)
    |> put_header("Reply-To", "#{store.email}")
    |> html_body("""
      #{item_cart.user.name},
      <h1>A loja #{store.name} CANCELOU a venda do produto!</h1>
      <h1>Produto #{item_cart.product_name} - #{item_cart.size_name} não está mais disponível!</h1><p />
      Qualquer dúvida é possível responder este e-mail diretamente á loja.
      """)
  end

  def notify_in_delivery(item_cart) do
    store = item_cart.size.product.store
    base_email()
    |> to(item_cart.user.email)
    |> subject("""
      Produto já está nas ruas, fique atento para recebe-lo.
      """)
    |> put_header("Reply-To", "#{store.email}")
    |> html_body("""
      <h2>#{item_cart.user.name}</h2>,<br />
      <h2>A loja #{store.name} acabou de enviar o seu produto!</h2><p />
      <h4>Produto #{item_cart.product_name} - #{item_cart.size_name} está à caminho!</h4><p />
      Qualquer dúvida é possível responder este e-mail diretamente á loja.
      """)
  end

  def notify_on_product_available(item_cart) do
    store = item_cart.size.product.store
    base_email()
    |> to(item_cart.user.email)
    |> subject("""
      Produto já está disponível, pode ir até o estabelecimento buscar.
      """)
    |> put_header("Reply-To", "#{store.email}")
    |> html_body("""
      <h2>#{item_cart.user.name}</h2>,<br />
      <h2>A loja #{store.name} acabou de preparar o seu produto!</h2><p />
      <h4>Produto #{item_cart.product_name} - #{item_cart.size_name} já está disponível!</h4><p />
      Qualquer dúvida é possível responder este e-mail diretamente á loja.
      """)
  end

  def notify_new_order(item_cart) do
    store = item_cart.size.product.store
    store_owner = store.user
    base_email()
    |> to(store_owner.email)
    |> subject("#{store_owner.name}, Confirmação da venda de um produto!")
    |> put_header("Reply-To", "#{item_cart.user.email}")
    |> html_body("""
      <h1>O cliente item_cart.user.name confirmou a entrega do produto !</h1><p />
      <h4>#{item_cart.product_name} - #{item_cart.size_name} - #{item_cart.size_price}</h4><p />
      Ficamos felizes por terem feito um bom negócio por meio de nossa plataforma.
      """)
  end

  defp base_email do
    # Here you can set a default from, default headers, etc.
    new_email()
    |> from("admin@bzaar.com.br")
  end

  defp get_url do
    case Application.get_env(:bzaar, BzaarWeb.Endpoint)[:url] do
      [scheme: scheme, host: host, port: 443] ->
        "#{scheme}://#{host}"
      [scheme: scheme, host: host, port: port] ->
        "#{scheme}://#{host}:#{port}"
      [host: host, port: port] ->
        "http://#{host}:#{port}"
      [host: host] -> "http://#{host}"
      [port: port] -> "http://localhost:#{port}"
      _ -> "http://localhost"
    end
  end
end