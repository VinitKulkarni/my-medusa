############################
# Stage 1 – Dependencies
############################
FROM node:20-alpine AS build
WORKDIR /app

# 1️⃣ Copy dependency manifests first (takes advantage of layer caching)
COPY package*.json ./

# 2️⃣ Install NPM deps
RUN npm install

# 3️⃣ Copy source code (but no .env yet—kept out of the build stage)
COPY . .

############################
# Stage 2 – Runtime image
############################
FROM node:20-alpine

WORKDIR /app

# 4️⃣ Copy the built workspace from Stage 1
COPY --from=build /app /app

# 6️⃣ Expose the Medusa port
EXPOSE 9000

# 7️⃣ Default command
CMD ["npm", "run", "dev"]
