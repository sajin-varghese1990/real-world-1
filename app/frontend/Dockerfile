# Trigger the build-and-promote GitHub Actions workflow (docs/ci-cd.md).
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
