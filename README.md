# FastSRB

**FastSRB** (Fast Symbolic Regression Benchmark) is a symbolic regression (SR) benchmarking library designed to improve the efficiency and pragmatism of ground-truth rediscovery benchmarks.
For detailed information, please refer to [this publication]().
Unlike traditional benchmarks that prioritize recovering a single "correct" expression form or rely soley on SymPy, FastSRB redefines success by introducing a curated list of acceptable expressions for each benchmark expression.
Those are functionally identical yet concise variants.
It also tackles the computational inefficiency of fixed-budget searches by allowing to implement a callback mechanism for early termination, halting the search once an acceptable expression is found.

The library is in Julia and provides benchmark problems, convenience functions for data sampling, and candidate expression processing.
Currently, FastSRB includes 120 expressions from the Feynman symbolic regression database, with sampling ranges and constant values adapted from the [SRSD benchmark](https://github.com/omron-sinicx/srsd-benchmark).
More details on the SRSD benchmark can be found in its accompanying [publication](https://openreview.net/forum?id=qrUdrXsiXX).
Contributions such as more acceptable expressions for existing problems, new benchmark problems, or metadata are encouraged via pull requests.

## Core Components

At the heart of FastSRB is a [YAML file](src/expressions.yaml) containing:
- **Ground-truth expressions**: The reference expressions for each benchmark problem.
- **Sampling instructions**: Guidelines for generating test data (e.g., variable ranges, constants).
- **Metadata**: Additional details about each expression, such as units.

This YAML file serves as the foundation for benchmarking, enabling users to evaluate SR algorithms against a well-defined yet flexible set of criteria.

## Key Features

- **Curated Acceptable Expressions**: Each benchmark expression comes with a list of functionally identical variants, relaxing the strict requirement of exact recovery.
  As argued in [the publication](), this approach aligns with SR’s goal of achieving high fit quality and maintaining expression simplicity, making it a more realistic measure of algorithm performance.
- **Julia Package**: Offers convenience functions for sampling data, evaluating candidate expressions, and implementing the callback mechanism.

## Callback for Early Termination

The callback mechanism is a standout feature of FastSRB, enhancing efficiency in SR benchmarking.
FastSRB does not provide a ready-made callback for all libraries, as implementations differ.
However, many convenience functions and an [example for the TiSR](example/TiSR.jl) are provided, which streamline the development of a callback for other SR packages.

During the search process, the callback should be invoked periodically, e.g., every 15 seconds.
It should evaluate candidate expressions that meet initial criteria (e.g., low loss on test data).
These candidates are then simplified, canonicalized, and have their parameters rounded to a set number of significant digits.
If a match is found, the search terminates immediately, marking the benchmark as successful.

## Contributing New Acceptable Expressions

To increase FastSRB's efficiency, contributions of new acceptable expressions for existing benchmark problems are welcomed.
These should be:
- **Functionally identical** to the ground-truth expression.
- **Concise**: not contain more than 20% more operations or operands than the reference expression, i.e., the original one simplified by SymPy (first expression in the "accept" list).

## Funding

This work was funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) within the Priority Programme SPP 2331: "Machine Learning in Chemical Engineering" - project no. 466528284 - HE 6077/14-1 and RI 2482/10-1
