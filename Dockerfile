############################
# Stage 1 – Dependencies
############################
FROM node:20-alpine AS build
WORKDIR /app

# 1️⃣ Copy dependency manifests first (takes advantage of layer caching)
COPY package*.json ./
RUN npm ci      # 2️⃣ Install NPM deps

# 3️⃣ Copy the rest of the source
COPY . .

############################
# Stage 2 – Runtime image
############################
FROM node:20-alpine
WORKDIR /app

# 4️⃣ Copy the built workspace from Stage 1
COPY --from=build /app /app

# 5️⃣ Add a tiny entrypoint that:
#    • runs the migration with TLS disabled (useful when your RDS cert is self‑signed)
#    • then hands control to whatever CMD was supplied
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

# 6️⃣ Expose the Medusa port
EXPOSE 9000

# 7️⃣ Default command (what docker-entrypoint.sh will ultimately exec)
CMD ["npm", "run", "dev"]
