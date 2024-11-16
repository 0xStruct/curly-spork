# ZKZK.trade

Trade off-chain assets (domains, blogs, websites, etc) directly between users


## Code - frontend

it is in the [frontend subfolder](/frontend).

please use nodejs version 18.

```
yarn install
yarn start
```

```
yarn hardhat node
```

```
yarn hardhat compile
yarn hardhat run scripts/deploy.js
```


## Code - vlayer proof

it is in the [vlayer-proof subfolder](/vlayer-proof).

```
anvil
```

```
vlayer serve
```

```
forge build

bun run prove:dev
```