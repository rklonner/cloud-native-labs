# [Backstage](https://backstage.io)

This is your newly scaffolded Backstage App, Good Luck!

To start the app, run:

```sh
yarn install
yarn start
```

# Backstage application init and build
```bash
nvm install 24
npm install isolated-vm
npm install -g corepack
corepack enable
yarn set version 4.4.1

#Init a backstage app
npx @backstage/create-app@latest
# enter e.g. "my-backstage-app" as name

# Build backstage and load image into kind cluster
./build_and_load.sh
```