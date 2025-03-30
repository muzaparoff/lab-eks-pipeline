FROM node:18-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . . 
ARG APP_VERSION
# During build, we could inject the version (for instance, replace a placeholder in code or simply use it in logs)
RUN echo "Building frontend version $APP_VERSION"
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
# Set an environment variable for runtime (if frontend reads it)
ENV REACT_APP_VERSION=$APP_VERSION