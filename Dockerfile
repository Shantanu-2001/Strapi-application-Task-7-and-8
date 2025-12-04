FROM node:20-bullseye

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

COPY .env .env

RUN npm run build

EXPOSE 1337

CMD ["npm", "run", "develop"]

