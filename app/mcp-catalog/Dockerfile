# Node 22, not 20 like the other apps: @kubernetes/client-node depends on
# undici ^8, which needs Node internals Node 20 doesn't have.
FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY server.js db.js k8s.js ./

ENV PORT=8080
EXPOSE 8080

USER node
CMD ["node", "server.js"]
