defmodule BlogAppWeb.PostController do
  use BlogAppWeb, :controller

  alias BlogApp.Posts
  alias BlogApp.Posts.Post

  @spam_error "Spam detected!"

  def index(conn, _params) do
    posts = Posts.list_posts()
    render(conn, :index, posts: posts)
  end

  def new(conn, _params) do
    changeset = Posts.change_post(%Post{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    case Posts.create_post(post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Posts.get_post!(id)
    changeset = Posts.change_comment(%BlogApp.Comments.Comment{})
    render(conn, :show, post: post, changeset: changeset)
  end

  def edit(conn, %{"id" => id}) do
    post = Posts.get_post!(id)
    changeset = Posts.change_post(post)
    render(conn, :edit, post: post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Posts.get_post!(id)

    case Posts.update_post(post, post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Posts.get_post!(id)
    {:ok, _post} = Posts.delete_post(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: ~p"/posts")
  end

  def add_comment(conn, %{"post_id" => post_id, "comment" => comment_params}) do
    post = Posts.get_post!(post_id)

    case Posts.create_comment(post, comment_params) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "Comment added successfully.")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        # Track spam attempts
        if changeset.errors[:content] == {@spam_error, []} do
          track_spam_attempt(conn, post_id, comment_params)
        end

        render(conn, :show, post: post, changeset: changeset)
    end
  end

  defp track_spam_attempt(conn, post_id, comment_params) do
    # Get user IP
    ip =
      conn.remote_ip
      |> Tuple.to_list()
      |> Enum.join(".")

    # Prepare metadata
    metadata = %{
      content: comment_params["content"],
      post_id: post_id,
      user_ip: ip,
      path: conn.request_path,
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      timestamp: DateTime.utc_now()
    }

    # Send custom error to AppSignal
    Appsignal.send_error(
      :spam_attempt,
      "Spam comment detected",
      "Content: #{comment_params["content"]}",
      [
        namespace: "spam_detection",
        metadata: metadata,
        tags: ["spam", "user_content"]
      ]
    )

    # Also increment a counter metric
    Appsignal.increment_counter("spam_attempts", 1, metadata)
  end
end
