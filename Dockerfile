FROM elixir:1.18.2-otp-27

# Install debian packages
RUN apt-get update
RUN apt-get install --yes build-essential inotify-tools

# Install Phoenix packages
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install hex phx_new

WORKDIR /app

COPY . .

RUN chmod +x run.sh

EXPOSE 4000

CMD ["./run.sh"]