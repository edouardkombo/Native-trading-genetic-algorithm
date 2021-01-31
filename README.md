# Native Trading  Genetic Algorithm - MQ4/MQ5
It is a self-learning trading robot based upon neural network, and directly built inside Metatrader via C++

The purpose of this repo is to create a trading expert advisor able to learn itself from market and make decisions, without any pre-configured settings or indicators.

The robot can take decisions simultaneously like:
- When to open/close/sell/buy
- Which lots to allocate

And deploy a full strategy like hedging over instrument and hedging over correlated instrument.


# Future improvements

-MQ4 version

-Success ratio

-Add GaussianNoise at each input layer to reduce overfitting and increas performance on test data

-I detected some output neuron witout activation we need to add dropout to force neurons activaction and reduce overfitting

-Add normalization at each layer output

-Add and deploy activations at each output layer

-Try optimization with Simulation Annelaning

-Implement Neuro Evolution Augmented Topologies (NEAT) to self optimized network arquitecture











