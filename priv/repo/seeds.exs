# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     BlogApp.Repo.insert!(%BlogApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Create posts and comments for the BlogApp

alias BlogApp.Repo
alias BlogApp.Posts.Post
alias BlogApp.Comments.Comment
alias BlogApp.Posts

# Clear existing data (optional, but often useful for seeds)
Repo.delete_all(Comment)
Repo.delete_all(Post)

# Create 100 Posts
posts =
  Enum.map(1..100, fn i ->
    {:ok, post} =
      Posts.create_post(%{
        title: "Post Title #{i}",
        body: "This is the body for post number #{i}. It contains some interesting content."
      })

    post
  end)

IO.puts("Successfully created #{length(posts)} posts.")

# Add comments to a subset of posts
# Let's add comments to the first 5 posts for this example
posts_to_comment_on = Enum.take(posts, 5)

Enum.each(posts_to_comment_on, fn post ->
  num_comments = Enum.random(10..20) # Random number of comments between 10 and 20

  Enum.each(1..num_comments, fn j ->
    Posts.create_comment(post, %{
      content: "This is comment ##{j} on #{post.title}. What a great post!"
    })
  end)
  IO.puts("Added #{num_comments} comments to Post ID: #{post.id} - \"#{post.title}\"")
end)

IO.puts("Database seeding completed.")
