############################
# Stage 1 – Build stage
############################
FROM node:20-alpine AS build
WORKDIR /app

# 1️⃣ Copy only dependency manifests
COPY package*.json ./

# 2️⃣ Clean and reproducible install
RUN npm ci

# 3️⃣ Copy the rest of the app source
COPY . .

# 4️⃣ Optional build (safe for Vite or Medusa builds)
# Prevent crash if build script doesn't exist
RUN npm run build || true


############################
# Stage 2 – Runtime stage
############################
FROM node:20-alpine
WORKDIR /app

# 5️⃣ Copy app from build stage
COPY --from=build /app /app

# 6️⃣ Set environment variables
ENV NODE_ENV=production


# 7️⃣ Entrypoint: run Medusa DB migration first
RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -e' \
    'echo "🔄  Running Medusa DB migration…"' \
    'NODE_TLS_REJECT_UNAUTHORIZED=0 npx medusa db:migrate' \
    'echo "✅  Migration complete — launching app"' \
    'exec "$@"' \
  > /usr/local/bin/docker-entrypoint.sh && \
  chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

# 8️⃣ Expose Medusa backend port
EXPOSE 9000

# 9️⃣ Start Medusa app (dev or prod)
CMD ["npm", "run", "start"]
