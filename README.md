



```julia
name = "newton_gravity"

data, eq_string = sample_dataset(
    name,
    n_points = 1000
)

df = DataFrame(data, :auto)
CSV.write(name * s, df)
```


