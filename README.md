# FastSRB

**FastSRB** (Fast Symbolic Regression Benchmark) is a symbolic regression (SR) benchmarking library designed to improve the efficiency and pragmatism of ground-truth rediscovery benchmarks.
For detailed information, please refer to [this publication]().
Unlike other benchmarks that prioritize recovering a single "correct" expression form or rely soley on SymPy, FastSRB redefines success by introducing a curated list of acceptable expressions for each benchmark expression.
Those are functionally identical yet concise variants.
It also tackles the computational inefficiency of fixed-budget searches by allowing to implement a callback mechanism for early termination, halting the search once an acceptable expression is found.

The library is in Julia and provides benchmark problems, convenience functions for data sampling, and candidate expression processing.
Currently, FastSRB includes 120 expressions from the Feynman symbolic regression database, with sampling ranges and constant values adopted from the [SRSD benchmark](https://github.com/omron-sinicx/srsd-benchmark).
More details on the SRSD benchmark can be found in its accompanying [publication](https://openreview.net/forum?id=qrUdrXsiXX).
Contributions such as more acceptable expressions for existing problems, new benchmark problems, or metadata are encouraged via pull requests.

## Core Components

At the heart of FastSRB is a [YAML file](src/expressions.yaml) containing:
- **Ground-truth expressions**: The reference expressions for each benchmark problem.
- **Sampling instructions**: Guidelines for generating test data (e.g., variable ranges, constants).
- **Metadata**: Additional details about each expression, such as units.

This YAML file serves as the foundation for benchmarking, enabling users to evaluate SR algorithms against a well-defined yet flexible set of criteria.

## Callback for Early Termination

FastSRB does not provide a ready-made callback for all libraries, as implementations differ.
However, many convenience functions and an [example for the TiSR](example/TiSR.jl) are provided, which streamline the development of a callback for other SR packages.

During the search process, the callback should be invoked periodically, e.g., every 15 seconds.
It should evaluate candidate expressions that meet initial criteria (e.g., low loss on test data).
These candidates are then simplified, canonicalized, and have their parameters rounded to a set number of significant digits, i.e., five.
If a match is found, the search terminates with success.

## Contributing New Acceptable Expressions

To increase FastSRB's efficiency, contributions of new acceptable expressions for existing benchmark problems are welcomed.
These should be:
- **Functionally identical** to the ground-truth expression.
- **Concise**: not contain more than 20% more operators or operands than the reference expression using binary operators, i.e., the original one simplified by SymPy (first expression in the "accept" list).

## Funding

This work was funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) within the Priority Programme SPP 2331: "Machine Learning in Chemical Engineering" - project no. 466528284 - HE 6077/14-1 and RI 2482/10-1
