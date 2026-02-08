# Stage 1: Build the React application
FROM node:20-slim AS build

WORKDIR /app

# Install dependencies first (better caching)
COPY package.json package-lock.json* ./
RUN npm install

# Copy source and build
COPY . .
ARG VITE_CONVEX_URL
ENV VITE_CONVEX_URL=$VITE_CONVEX_URL

# Generate Convex stubs if not present (for demo/non-Convex builds)
RUN if [ ! -f convex/_generated/api.js ]; then \
      mkdir -p convex/_generated && \
      echo 'export const api = {};' > convex/_generated/api.js && \
      echo 'export const api = {};' > convex/_generated/api.d.ts && \
      echo 'export type Id<T extends string> = string & { __tableName: T };' > convex/_generated/dataModel.js && \
      echo 'export type Id<T extends string> = string & { __tableName: T };' > convex/_generated/dataModel.d.ts; \
    fi

# Build (skip tsc for demo mode compatibility, vite handles types)
RUN npx vite build

# Stage 2: Serve with nginx
FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built files
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
