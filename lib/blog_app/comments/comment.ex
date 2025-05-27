defmodule BlogApp.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlogApp.Posts.Post

  schema "comments" do
    field :content, :string
    belongs_to :post, Post

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end

  @doc """
  Associates a comment changeset with a post.
  """
  def set_post(changeset, post) do
    Ecto.Changeset.put_assoc(changeset, :post, post)
  end
end
