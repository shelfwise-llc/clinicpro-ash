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
COPY mix.exs mix.lock ./
COPY config config
COPY priv priv

# Install mix dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy assets
COPY assets assets
COPY lib lib
COPY test test

# Build assets
WORKDIR /app/assets
RUN npm install
RUN npm run deploy

# Compile and build the release
WORKDIR /app
RUN mix compile
RUN mix phx.digest

# Compile the project for production
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# Build the release
RUN mix release

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM debian:bullseye-slim as app

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/clinicpro ./

# Set the environment variables
ENV HOME=/app
ENV PORT=4000

CMD ["/app/bin/server"]
