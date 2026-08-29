# Build stage: compile the server to a native AOT executable.
FROM dart:stable AS build
WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Runtime stage: minimal image with just the compiled binary + Dart's runtime deps.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8090
CMD ["/app/bin/server"]
