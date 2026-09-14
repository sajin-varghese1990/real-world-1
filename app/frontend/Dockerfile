# Trigger the build-and-promote GitHub Actions workflow (docs/ci-cd.md).
# Retry: multi-arch build fix (linux/amd64,linux/arm64).
FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY server.js db.js cache.js ./
COPY public ./public

ENV PORT=8080
EXPOSE 8080

USER node
CMD ["node", "server.js"]
