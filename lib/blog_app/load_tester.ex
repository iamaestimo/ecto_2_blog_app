# lib/blog_app/load_tester.ex
defmodule BlogApp.LoadTester do
  @moduledoc """
  A module for generating test load on the BlogApp to establish baseline metrics.
  Note: Use in a development or staging environments only.
  """
  require Logger
  alias BlogApp.Posts
  alias BlogApp.Repo

  @doc """
  Runs a load test for post creation and retrieval operations.
  Options:
    * :duration - Duration of the test in seconds (default: 60)
    * :concurrency - Number of concurrent processes (default: 10)
    * :post_count - Number of posts to create before running read tests (default: 100)
  """
  def run_test(opts \\ []) do
    duration = Keyword.get(opts, :duration, 60)
    concurrency = Keyword.get(opts, :concurrency, 10)
    post_count = Keyword.get(opts, :post_count, 100)

    Logger.info("Starting load test with concurrency: #{concurrency}, duration: #{duration}s")

    # Ensure we have enough test data
    seed_test_data(post_count)

    # Start concurrent processes
    tasks = for _ <- 1..concurrency do
      Task.async(fn ->
        run_test_process(duration)
      end)
    end

    # Wait for all tasks to complete
    results = Task.await_many(tasks, duration * 1000 + 5000)

    # Aggregate and report results
    total_reads = Enum.sum(Enum.map(results, fn {:ok, stats} -> stats.reads end))
    total_writes = Enum.sum(Enum.map(results, fn {:ok, stats} -> stats.writes end))
    total_operations = total_reads + total_writes

    Logger.info("""
    Load test completed:
      Duration: #{duration}s
      Concurrency: #{concurrency}
      Total operations: #{total_operations}
      Reads: #{total_reads}
      Writes: #{total_writes}
      Operations/second: #{total_operations / duration}
    """)

    {:ok, %{
      duration: duration,
      concurrency: concurrency,
      total_operations: total_operations,
      reads: total_reads,
      writes: total_writes,
      ops_per_second: total_operations / duration
    }}
  end

  defp run_test_process(duration) do
    end_time = System.monotonic_time(:second) + duration
    stats = %{reads: 0, writes: 0}

    run_operations(end_time, stats)
  end

  defp run_operations(end_time, stats) do
    if System.monotonic_time(:second) < end_time do
      # Randomly choose between read and write operations
      # 80% reads, 20% writes to simulate typical web app traffic
      updated_stats = if :rand.uniform(100) <= 80 do
        # Perform a read operation
        post_count = Repo.aggregate(BlogApp.Posts.Post, :count)
        if post_count > 0 do
          random_id = :rand.uniform(post_count)
          # We'll occasionally get id not found errors, which is fine for testing
          try do
            Posts.get_post!(random_id)
            %{stats | reads: stats.reads + 1}
          catch
            _, _ -> stats
          end
        else
          stats
        end
      else
        # Perform a write operation
        {:ok, _post} = Posts.create_post(%{
          title: "Load Test Post #{System.unique_integer([:positive])}",
          body: "This is a test post generated during load testing. #{String.duplicate("Content ", :rand.uniform(50))}"
        })
        %{stats | writes: stats.writes + 1}
      end

      # Add some randomness to avoid synchronized load
      Process.sleep(:rand.uniform(50))
      run_operations(end_time, updated_stats)
    else
      {:ok, stats}
    end
  end

  defp seed_test_data(count) do
    existing_count = Repo.aggregate(BlogApp.Posts.Post, :count)

    if existing_count < count do
      Logger.info("Seeding #{count - existing_count} test posts...")

      for i <- (existing_count + 1)..count do
        {:ok, _} = Posts.create_post(%{
          title: "Test Post #{i}",
          body: "This is test post content for post #{i}. #{String.duplicate("Lorem ipsum ", :rand.uniform(100))}"
        })
      end

      Logger.info("Finished seeding test data.")
    end
  end
end
