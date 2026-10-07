<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Computability and complexity

# 24 · Computability and complexity

Define computation precisely, prove that some problems cannot be solved at all and others cannot be solved fast under standard assumptions, and read P versus NP as a precise statement with a clear account of what is proved around it. Follow randomised, quantum and interactive models well enough to say what each one buys, and read category-theoretic language when it appears.

7 shelves · **0 of 57 cards ready to read** · all planned, not written yet

| Shelf | Cards |
| --- | ---: |
| [01 · Models of Computation](#s01) | 10 |
| [02 · Computability and Logic](#s02) | 8 |
| [03 · Time Complexity](#s03) | 9 |
| [04 · Beyond Worst Case](#s04) | 8 |
| [05 · Algebraic, Interactive and Quantum](#s05) | 7 |
| [06 · Data, Learning and Fine-Grained Complexity](#s06) | 6 |
| [07 · Category Theory in Outline](#s07) | 9 |

<a name="s01"></a>

## 01 · Models of Computation · 10 cards

*machines with fixed memory, with a stack and with a tape; what computation means; the first impossibility results*

1. Finite automata: fixed memory reads once and decides accept or reject
2. Guessing machines: allowed every move at once, and no more powerful
3. Regular expressions: patterns and machines describe the same string sets
4. Pumping and Myhill-Nerode: proving fixed memory is not enough
5. Grammars and a stack: machines that handle nesting
6. The language ladder: more memory buys strictly more patterns
7. Turing machines: a tape, a head and a table of rules
8. Church-Turing thesis: every reasonable machine computes the same things
9. Universal machines: one runs them all, and cannot predict them
10. Rice's theorem: no interesting property of a program is decidable

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Computability and Logic · 8 cards

*decidable against semidecidable, incompleteness, undecidable equations, shortest-program information, and machine-checked proof*

1. Decidable and semidecidable: always an answer, or only when the answer is yes
2. Busy beaver: a function that outgrows everything computable
3. Godel's theorems: arithmetic cannot settle everything true about itself
4. Hilbert's tenth problem: no test for whole-number solutions
5. Kolmogorov complexity: the length of the shortest program that prints it
6. Incompressibility: almost every file is its own shortest description
7. Lambda calculus: computing with nothing but functions
8. Proof assistants: a machine checks every step of a proof

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Time Complexity · 9 cards

*cost classes, P and NP, reductions and completeness, Cook-Levin, the classes above NP, and strict hierarchies*

1. Time and space classes: cost measured against how the input grows
2. P and NP: solving quickly against checking quickly
3. Reductions: convert one problem into another to compare difficulty
4. Cook-Levin: satisfiability is the first universally hardest problem
5. Karp's list: a small kit of reductions that reaches everything
6. Pseudo-polynomial time: fast only while the numbers stay small
7. SAT solvers: hard in theory, often easy on the instance in hand
8. Above NP: alternating there-exists and for-all, and memory instead of time
9. Hierarchy and Ladner: more time really helps, and middle ground must exist

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Beyond Worst Case · 8 cards

*approximation with guarantees, coin flips, a second parameter, average-case hardness, lower bounds, and the barriers around P versus NP*

1. Approximation: a guaranteed near-answer, and limits on the guarantee
2. Relaxation and rounding: solve a fractional version, then round it back
3. BPP: coin flips that buy speed at a controlled error rate
4. Pseudorandomness: fake coins that a fast test cannot tell from real ones
5. Parameterised complexity: hard in general, easy while one number stays small
6. Average-case hardness: hard on the inputs you actually draw
7. Circuit lower bounds: counting gates to prove nothing can be fast
8. P versus NP: the precise statement, and the barriers that block proof

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Algebraic, Interactive and Quantum · 7 cards

*gates and depth, counting rather than deciding, permanent against determinant, proof by conversation or spot check, and quantum circuits*

1. Boolean circuits: cost measured in gates and in depth
2. Counting: how many solutions, not merely whether one exists
3. Permanent against determinant: two near-identical formulas, wildly different cost
4. Interactive proofs: convincing a sceptic by conversation, or by spot checks
5. Qubits: a unit vector of amplitudes, read once and collapsed
6. BQP: what a quantum circuit does and does not speed up
7. Shor and Grover: period finding breaks RSA, search gains a square root

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Data, Learning and Fine-Grained Complexity · 6 cards

*one-pass summaries, random projection, bits across a gap, how many examples are enough, regret, and hardness inside P*

1. Streaming: one pass, tiny memory, an answer with error bars
2. Random projection: squash the data, keep the distances
3. Communication complexity: how many bits must cross the gap
4. Learning with a guarantee: how many examples are enough
5. Regret: judged against the best single choice in hindsight
6. Fine-grained complexity: why quadratic is probably the floor

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Category Theory in Outline · 9 cards

*categories and functors, naturality, universal properties, adjunctions, monoids and monads, folds, and side-by-side composition*

1. Categories and functors: objects, arrows, and maps that respect them
2. Commutative diagrams: every route agrees, and every arrow can be reversed
3. Natural transformations and Yoneda: an object is known by its arrows
4. Universal properties: defined by the one arrow that always exists
5. Pullbacks and pushouts: matching pairs, and gluing along a shared part
6. Adjunctions: two functors whose arrows correspond exactly
7. Monoids and monads: combining values, and sequencing steps that can fail
8. F-algebras: one step of a recursive structure, then folded away
9. Monoidal categories: things side by side, drawn as parallel wires

[↑ Back to the shelves](#top)

---

[← 23 · Differential geometry and Lie groups](../23-Differential%20geometry%20and%20Lie%20groups/README.md) · [All wings](../../SYLLABUS.md) · [25 · Frontier →](../25-Frontier/README.md)
