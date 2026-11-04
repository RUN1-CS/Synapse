# Build Flutter web, serve with nginx (which also proxies /api and /socket.io to the backend).
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
RUN flutter create . --platforms=web --project-name chat_app
COPY pubspec.yaml ./
RUN rm -rf lib test
COPY lib ./lib
RUN flutter pub get && flutter build web --release

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
