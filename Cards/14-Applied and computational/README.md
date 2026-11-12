<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Applied and computational

# 14 · Applied and computational

Analyse an algorithm's cost and choose a data structure, use randomness and approximation on purpose, measure information in bits and code it for storage and for a noisy channel, follow modern cryptography from the one-time pad to lattices, formulate an operations-research model and read a solver's answer, do the mathematics behind machine learning, and analyse a network as a matrix. Theory that belongs elsewhere is named and linked rather than half-taught: algorithms and duality for optimisation in wing 15, method derivations and error bounds in wing 16, complexity classes in wing 24.

8 shelves · **34 of 71 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it. A title without a link is planned and not written yet.

| Shelf | Cards | Ready to read |
| --- | ---: | ---: |
| [01 · Algorithms and Growth](#s01) | 9 | 0 of 9 · planned |
| [02 · Randomised and Approximate Algorithms](#s02) | 8 | 0 of 8 · planned |
| [03 · Information Theory](#s03) | 10 | 0 of 10 · planned |
| [04 · Cryptography](#s04) | 10 | 0 of 10 · planned |
| [05 · Operations Research](#s05) | 10 | 10 of 10 |
| [06 · Machine Learning Mathematics](#s06) | 9 | 9 of 9 |
| [07 · Network Science and Spectral Graphs](#s07) | 8 | 8 of 8 |
| [08 · Scientific Computing Practice](#s08) | 7 | 7 of 7 |

<a name="s01"></a>

## 01 · Algorithms and Growth · 9 cards · planned

*How cost grows, which case you are quoting, and the workhorse patterns: divide and conquer, sorting, structures, tables, greed*

1. Big-O: the growth rate of a cost, not its stopwatch reading
2. Which case are you quoting? Worst, average and amortised cost
3. Polynomial or exponential: the line between doable and hopeless
4. Recurrences: the cost of a method that calls itself, read off in one line
5. Sorting and searching: merge sort, quicksort, binary search and the n log n floor
6. Data structures: what each one makes cheap, and what it makes dear
7. Dynamic programming: solve each small piece once and write the answer down
8. Greedy: take the best next step, and the argument that it is safe
9. Graph algorithms as code: the structures that make wing 04's theorems run fast

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Randomised and Approximate Algorithms · 8 cards · planned

*Randomness as a design tool: expectation, tail bounds, sketches, guaranteed ratios, and sampling used as computation*

1. Randomised algorithms: coin flips inside the method, and the expected cost
2. Tail bounds: why a random method almost never embarrasses you
3. Fair choices from a list you cannot hold: Fisher-Yates and reservoir sampling
4. Hashing for size: Bloom filters and sketches that trade certainty for memory
5. Monte Carlo integration: random points beat a grid once the dimension climbs
6. Approximation: a guaranteed ratio when the exact answer is out of reach
7. Local search: hill climbing, restarts, annealing and genetic moves
8. MCMC as a tool: Metropolis-Hastings when you cannot sample directly

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Information Theory · 10 cards · planned

*Measuring information in bits, compressing it, and pushing it through a channel that makes mistakes*

1. Entropy: the average number of yes-or-no questions an outcome costs
2. Conditional entropy and mutual information: how much one signal tells you about another
3. KL divergence: the bits you waste by coding for the wrong distribution
4. Typical sequences: long messages all look alike, and that is where the limit comes from
5. Huffman coding: the shortest prefix-free code, built from the bottom up
6. Arithmetic and Lempel-Ziv coding: beating Huffman on fractions and on repetition
7. Channel capacity: the fastest error-free rate a noisy link will allow
8. Hamming and Reed-Solomon: codes that repair what the channel broke
9. LDPC, turbo and polar codes: how modern links get within a whisker of capacity
10. Rate and distortion: how many bits for a picture you can live with

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Cryptography · 10 cards · planned

*What each primitive promises, what breaks it, and the arithmetic underneath: pads, block ciphers, hashes, RSA, curves, lattices, proofs*

1. The one-time pad: perfect secrecy, and the price that makes it impractical
2. AES: a block cipher as a keyed shuffle, and the modes that use it safely
3. Hashes and MACs: a fingerprint for data, and a tag only a key could make
4. RSA in full: key generation, padding, and why factoring is the whole game
5. Diffie-Hellman and ElGamal: agreeing a secret in public, then encrypting with it
6. Elliptic curves: the same protocols with 256-bit keys instead of 3,072
7. Digital signatures: hash then sign, and what a forgery would have to mean
8. The TLS handshake: every primitive in one short conversation
9. Lattices: hard problems a quantum computer does not break, and the new standards
10. Zero-knowledge: convincing someone you know a secret without showing it

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Operations Research · 10 cards

*Writing a decision as a model a solver can answer, then reading the answer: programs, schedules, stock, queues, decisions, games*

1. [Linear programs: a plan written as variables, one target and straight-line limits](05-Operations%20Research/01-modelling-with-linear-programs.md)
2. [Shadow prices: what one more oven hour is worth, straight off the solver](05-Operations%20Research/02-shadow-prices-and-sensitivity.md)
3. [Integer programs: yes-or-no decisions, and the search tree that settles them](05-Operations%20Research/03-integer-programming-and-branch-and-bound.md)
4. [Scheduling: the critical path, the float, and rules that beat a gut feeling](05-Operations%20Research/04-scheduling-and-the-critical-path.md)
5. [The assignment problem: pairing people to jobs at least total cost](05-Operations%20Research/05-assignment-and-the-hungarian-algorithm.md)
6. [Stock: the order size that balances holding against ordering, and the one-shot order](05-Operations%20Research/06-inventory-models-eoq-and-newsvendor.md)
7. [Queues: Little's law, M/M/1, and why ninety percent busy feels broken](05-Operations%20Research/07-queueing-theory-and-littles-law.md)
8. [Deciding under uncertainty: expected utility, and what a perfect forecast is worth](05-Operations%20Research/08-decision-theory-and-the-value-of-information.md)
9. [Nash equilibrium: nobody gains by moving alone, in pure or mixed strategies](05-Operations%20Research/09-game-theory-and-nash-equilibrium.md)
10. [Auctions: why a second-price rule makes honesty the best policy](05-Operations%20Research/10-auctions-and-mechanism-design.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Machine Learning Mathematics · 9 cards

*The mathematics under the libraries: a loss to minimise, a gradient to follow, and the linear algebra behind the rest*

1. [Loss and empirical risk: writing "learning" as a sum you can minimise](06-Machine%20Learning%20Mathematics/01-loss-functions-and-empirical-risk.md)
2. [Gradient descent: walk downhill, and take a noisy step when the data is large](06-Machine%20Learning%20Mathematics/02-gradient-descent-and-stochastic-gradient.md)
3. [The perceptron and its stack: weights, a bias, a squashing function, layers](06-Machine%20Learning%20Mathematics/03-perceptron-and-neural-networks.md)
4. [Backpropagation: the chain rule run backwards through a network](06-Machine%20Learning%20Mathematics/04-backpropagation.md)
5. [Softmax and cross-entropy: scores into probabilities, then scored in bits](06-Machine%20Learning%20Mathematics/05-softmax-and-cross-entropy-for-classification.md)
6. [k-means: groups defined by their own centres, found by taking turns](06-Machine%20Learning%20Mathematics/06-k-means-and-clustering.md)
7. [Principal components: the few directions that carry most of the variation](06-Machine%20Learning%20Mathematics/07-principal-components-and-dimension-reduction.md)
8. [EM: guess the hidden labels, refit, repeat until nothing moves](06-Machine%20Learning%20Mathematics/08-em-algorithm.md)
9. [Support vector machines: the widest safe margin, and the kernel trick](06-Machine%20Learning%20Mathematics/09-kernels-and-support-vector-machines.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Network Science and Spectral Graphs · 8 cards

*Networks as matrices: who matters, where the groups are, and how fast news, a virus or a random walker spreads*

1. [Centrality: degree, betweenness and PageRank as rival ideas of "important"](07-Network%20Science%20and%20Spectral%20Graphs/01-centrality-and-pagerank.md)
2. [PageRank by power iteration: multiply, normalise, repeat, and why damping is needed](07-Network%20Science%20and%20Spectral%20Graphs/02-power-iteration-and-the-damping-factor.md)
3. [The graph Laplacian: eigenvalues that count the pieces and cut the network in two](07-Network%20Science%20and%20Spectral%20Graphs/03-graph-laplacian-and-spectral-clustering.md)
4. [Small worlds and hubs: three models, and the real networks they imitate](07-Network%20Science%20and%20Spectral%20Graphs/04-small-world-and-scale-free-models.md)
5. [Epidemics on a network: the threshold, and why the hubs decide the outcome](07-Network%20Science%20and%20Spectral%20Graphs/05-epidemics-on-networks.md)
6. [Communities: modularity, and the algorithms that chase it](07-Network%20Science%20and%20Spectral%20Graphs/06-community-detection.md)
7. [Expanders: sparse networks that are hard to cut and quick to mix](07-Network%20Science%20and%20Spectral%20Graphs/07-expanders-and-mixing.md)
8. [Random walks as circuits: hitting times, resistance and commute times](07-Network%20Science%20and%20Spectral%20Graphs/08-random-walks-and-electrical-networks.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Scientific Computing Practice · 7 cards

*How the library keeps its numbers honest: floating point, seeds, cost, tolerances, two independent roads, and asserts that can fail*

1. [Floating point: why 0.1 plus 0.2 is not 0.3, and what the machine does promise](08-Scientific%20Computing%20Practice/01-floating-point-in-practice.md)
2. [Cancellation: subtracting near-equal numbers, and the rewrite that saves the digits](08-Scientific%20Computing%20Practice/02-catastrophic-cancellation-and-safe-formulas.md)
3. [Seeds: a random result that anyone can reproduce, line for line](08-Scientific%20Computing%20Practice/03-reproducible-simulation-and-seeds.md)
4. [Cost in practice: count the operations, then let arrays do them at once](08-Scientific%20Computing%20Practice/04-computational-cost-and-vectorisation.md)
5. [Tolerances: never test two computed numbers for equality](08-Scientific%20Computing%20Practice/05-tolerances-and-comparing-computed-numbers.md)
6. [Two roads and a mutation: a test that would notice if the answer were wrong](08-Scientific%20Computing%20Practice/06-testing-numerical-code-two-roads-and-mutations.md)
7. [The check script: asserts that can fail, run on every card](08-Scientific%20Computing%20Practice/07-writing-a-check-script.md)

[↑ Back to the shelves](#top)

---

[← 13 · Engineering mathematics](../13-Engineering%20mathematics/README.md) · [All wings](../../SYLLABUS.md) · [15 · Optimization →](../15-Optimization/README.md)
