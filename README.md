# Aave X Balancer Money Lego on Polygon 
# Polygon Mainnet Fork Used For Testing
(Work in progress)


# Supply Function : 

## startAaveLoop
- Supply Token to Aave V3 Pool
- Borrow Token at corresponding collat from Aave Pool

## startBalancerLoop
- startAaveLoop()
- Supply Borrowed Usdc to Balancer Pool Mai/Usdc 


# Whithdraw Function: 

## stopAaveLoop
- Repay Borrowed Token Amount From Aave Pool
- Withdraw Initial Token Funds from Aave Pool

## stopBalancerLoop
- Withdraw Borrowed Token From Balancer Pool
- stopAaveLoop()

# Todo List : 
- [~] => Allow swaps to pay for collateral wear
- [~] => Activate the E-Mode of Aave according to the token and the collateral of the user
- [] => calculate the max loop possible according to the collateral and the potential e-mode
- [~] => add a loop with a flashloan leverage
- []
- []
- [] => optimize testing and transaction costs


```shell
npm install
npx hardhat test (fork Polygon mainnet)
```

Replace .env file data for testing on your machine

