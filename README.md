# FPGA_SNN_STDP
This project targets FPGA acceleration of a Spike-Timing-Dependent Plasticity (STDP) learning algorithm for Spiking Neural Networks (SNN). Specifically, the network is composed of Leaky Integrate-and-Fire neurons implementing the Pair-based STDP learning rule. Additionaly, lateral inhibition is added to the design.

For assessing the learning performance, the recognition of digits is targeted, employing the dataset provided by the MNIST database (http://yann.lecun.com/exdb/mnist/). In order to improve inference and learning rates, a preprocessing layer in the form of a receptive field is added to the network. 

The basic network configuration counts with a 784-neuron input layer, a 20-neuron hidden layer and a 10-neuron output layer. The inferred digit is conveyed throught the Winner-Takes-All (WTA) mechanism: for each image, the first output neuron to fire represents the selected digit.
