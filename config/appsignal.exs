import Config

config :appsignal, :config,
  otp_app: :blog_app,
  name: "ecto_2_blog_app",
  push_api_key: System.get_env("APPSIGNAL_PUSH_API_KEY"),
  env: Mix.env
