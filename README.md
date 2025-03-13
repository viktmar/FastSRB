# FastSRB

**FastSRB** (Fast Symbolic Regression Benchmark) is a symbolic regression (SR) benchmarking library designed to improve the efficiency and pragmatism of ground-truth rediscovery benchmarks.
For detailed information, please refer to [this publication]().
Unlike traditional benchmarks that prioritize recovering a single "correct" equation form, FastSRB redefines success by introducing a curated list of acceptable expressions for each benchmark equation.
Those are functionally identical yet concise variants.
It also tackles the computational inefficiency of fixed-budget searches by implementing a callback mechanism for early termination, halting the search once an acceptable expression is found.

The library is implemented as a Julia package, providing convenience functions to streamline SR workflows, including data sampling, candidate equation processing, and integration with SR tools like [TiSR]().
Currently, FastSRB includes 120 equations sourced from the Feynman symbolic regression database, with sampling ranges and constant values adapted from the [SRSD benchmark]().
More details on the SRSD benchmark can be found in its accompanying [publication]().
The library is extensible, and contributions such as new acceptable expressions, benchmark problems, or metadata are encouraged via pull requests.

## Core Components

At the heart of FastSRB is a [YAML file]() containing:
- **Ground-truth expressions**: The reference equations for each benchmark problem.
- **Sampling instructions**: Guidelines for generating test data (e.g., variable ranges, constants).
- **Metadata**: Additional details about each equation, such as units.

This YAML file serves as the foundation for benchmarking, enabling users to evaluate SR algorithms against a well-defined yet flexible set of criteria.

## Key Features

- **Curated Acceptable Expressions**: Each benchmark equation comes with a list of functionally identical variants, relaxing the strict requirement of exact recovery. As argued in [the publication](), this approach aligns with SR’s dual goals of achieving high fit quality and maintaining expression simplicity, making it a more realistic measure of algorithm performance.
- **Julia Package**: Offers convenience functions for sampling data, evaluating candidate equations, and implementing the callback mechanism.
- **Extensibility**: Designed to grow with community input, allowing users to add new expressions, problems, or metadata.

## Callback for Early Termination

The callback mechanism is a standout feature of FastSRB, enhancing efficiency in SR benchmarking.
FastSRB does not provide a ready-made callback for all libraries, as implementations differ.
However, many convenience functions and an example for the TiSR package are provided, which streamline the development of a callback for your SR package.

During the search process, the callback should be invoked periodically, e.g., after each iteration or at set time intervals.
It should evaluate candidate equations that meet initial criteria (e.g., low loss on test data).
These candidates are then simplified, canonicalized, and have their parameters rounded to a set number of significant digits.
If a match is found, the search terminates immediately, marking the benchmark as successful.

An example implementation is provided, showcasing how the callback function as used for with [TiSR]().

## Contributing New Acceptable Expressions

To increase FastSRB's efficiency, contributions of new acceptable expressions for existing benchmark problems are welcomed.
These should be:
- **Functionally identical** to the ground-truth equation.
- **Concise**, adhering to SR’s emphasis on simplicity.

Contributors can submit pull requests, including new variants, additional benchmark problems, or enhanced metadata.
This collaborative approach ensures FastSRB remains a versatile and up-to-date resource for the SR community.

