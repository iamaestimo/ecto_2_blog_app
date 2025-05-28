defmodule BlogApp.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlogApp.Posts.Post

  @spam_phrases ["this is a spam comment", "buy now", "make money fast"]

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
    |> validate_no_spam()
  end

  defp validate_no_spam(changeset) do
    content = get_field(changeset, :content) || ""

    if Enum.any?(@spam_phrases, &String.contains?(String.downcase(content), &1)) do
      changeset
      |> add_error(:content, "Spam detected!")
    else
      changeset
    end
  end

  @doc """
  Associates a comment changeset with a post.
  """
  def set_post(changeset, post) do
    Ecto.Changeset.put_assoc(changeset, :post, post)
  end
end
