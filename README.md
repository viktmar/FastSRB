
# FastSRB

FastSRB (Fast Symbolic Regression Benchmark) is a symbolic regression benchmarking library.
For detailed information, please refer to [this publication]().
It allows for faster and more pragmatically precise benchmarking.

The idea is that a curated list of acceptable expression is defined for each expression.
Those are functionally identical and remain concise.
As argued in [the publication](), relaxing the requirement for exact recovery to a list of acceptable expressions is a more realistic performance measure for symbolic regression algorithms.
Furthermore, this benchmark addresses the inefficiency of continuing expression search after an expression is discovered.

The core is a [yaml file]() that contains ground-truth expressions, and for each of them, information of how to sample data, and miscellaneous additional metadata.
Moreover, this package provides convenience functions to implement a callback mechanism for early termination, as soon as a found expression matches one in the list of acceptable expression.
An example of how to use this benchmark is shown for the symbolic regression package [TiSR]().

Currently, 120 equations the Feynman symbolic regression database are implemented, whose sampling ranges and constant values are adopted from the [SRSD benchmark]().
More information on the SRSD benchmark can be found in the accompanying [publication]().

PRs for new acceptable expression of existing problems, new benchmark problems, and additional metadata are welcome.

## Callback for early termination

## Contribute new acceptable expression




