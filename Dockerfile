FROM hexpm/elixir:1.14.5-erlang-25.3.2-debian-bullseye-20230522 as build

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git nodejs npm \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create app directory and copy the Elixir project into it
WORKDIR /app

# Copy the entire application
COPY . .

# Install mix dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Compile the project for production
RUN mix compile

# Build assets using Mix tasks
RUN mix assets.deploy

# Build the release
RUN mix release

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM debian:bullseye-20230522-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# Set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=build --chown=nobody:root /app/_build/prod/rel/clinicpro ./

# Copy the server startup script
COPY --from=build --chown=nobody:root /app/rel/overlays/bin/server ./bin/
RUN chmod +x /app/bin/server

USER nobody

# Command to start the application
CMD ["/app/bin/server"]
