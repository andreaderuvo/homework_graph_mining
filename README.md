# Graph Mining Homework

How to execute the homework:

Create your *_konect.jl configuration file to configure your [konect.cc](http://konect.cc/networks/) network. This file is included in konect.jl.

Example:
```
douban_konect.jl
```

Then:

1. Import the packages:
```
julia package.jl
```

2. Download, Decompress, Transform and extract the Largest Connected Component
```
julia konect.jl
```

3. Launch the homework uncommenting the exercise* function of interest
```
julia homework.jl
```

# Parallel Graphs Algorithms

In parallel.jl the calculus of betweenness_centrality is 12x faster using multithreads and parallel computation.

Usage:
```
julia -p 32 -t 8 parallel.jl
```

# Credits

Most of the code in homework.jl is a copy paste of the code written by Pierluigi Crescenzi ([repo](https://github.com/piluc/GraphMining/tree/main/code))
