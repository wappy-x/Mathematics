<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Computability and complexity

# 24 · Computability and complexity

Define computation precisely, prove that some problems cannot be solved at all and others cannot be solved fast under standard assumptions, and read P versus NP as a precise statement with a clear account of what is proved around it. Follow randomised, quantum and interactive models well enough to say what each one buys, and read category-theoretic language when it appears.

7 shelves · **57 of 57 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

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

1. [Finite automata: fixed memory reads once and decides accept or reject](01-Models%20of%20Computation/01-finite-automata-and-regular-languages.md)
2. [Guessing machines: allowed every move at once, and no more powerful](01-Models%20of%20Computation/02-nondeterminism-and-the-subset-construction.md)
3. [Regular expressions: patterns and machines describe the same string sets](01-Models%20of%20Computation/03-regular-expressions-and-pattern-matching.md)
4. [Pumping and Myhill-Nerode: proving fixed memory is not enough](01-Models%20of%20Computation/04-pumping-lemma-and-myhill-nerode.md)
5. [Grammars and a stack: machines that handle nesting](01-Models%20of%20Computation/05-context-free-grammars-and-pushdown-automata.md)
6. [The language ladder: more memory buys strictly more patterns](01-Models%20of%20Computation/06-chomsky-hierarchy-and-the-language-ladder.md)
7. [Turing machines: a tape, a head and a table of rules](01-Models%20of%20Computation/07-turing-machines.md)
8. [Church-Turing thesis: every reasonable machine computes the same things](01-Models%20of%20Computation/08-church-turing-thesis.md)
9. [Universal machines: one runs them all, and cannot predict them](01-Models%20of%20Computation/09-universal-machines-and-the-halting-problem.md)
10. [Rice's theorem: no interesting property of a program is decidable](01-Models%20of%20Computation/10-rices-theorem-and-reductions.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Computability and Logic · 8 cards

*decidable against semidecidable, incompleteness, undecidable equations, shortest-program information, and machine-checked proof*

1. [Decidable and semidecidable: always an answer, or only when the answer is yes](02-Computability%20and%20Logic/01-decidable-and-semidecidable-sets.md)
2. [Busy beaver: a function that outgrows everything computable](02-Computability%20and%20Logic/02-the-busy-beaver-function.md)
3. [Godel's theorems: arithmetic cannot settle everything true about itself](02-Computability%20and%20Logic/03-godels-incompleteness-in-outline.md)
4. [Hilbert's tenth problem: no test for whole-number solutions](02-Computability%20and%20Logic/04-hilberts-tenth-problem.md)
5. [Kolmogorov complexity: the length of the shortest program that prints it](02-Computability%20and%20Logic/05-kolmogorov-complexity.md)
6. [Incompressibility: almost every file is its own shortest description](02-Computability%20and%20Logic/06-incompressibility-and-randomness.md)
7. [Lambda calculus: computing with nothing but functions](02-Computability%20and%20Logic/07-lambda-calculus-in-outline.md)
8. [Proof assistants: a machine checks every step of a proof](02-Computability%20and%20Logic/08-proof-assistants-and-formal-verification.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Time Complexity · 9 cards

*cost classes, P and NP, reductions and completeness, Cook-Levin, the classes above NP, and strict hierarchies*

1. [Time and space classes: cost measured against how the input grows](03-Time%20Complexity/01-time-and-space-classes.md)
2. [P and NP: solving quickly against checking quickly](03-Time%20Complexity/02-p-and-np.md)
3. [Reductions: convert one problem into another to compare difficulty](03-Time%20Complexity/03-polynomial-reductions-and-np-completeness.md)
4. [Cook-Levin: satisfiability is the first universally hardest problem](03-Time%20Complexity/04-cook-levin-theorem.md)
5. [Karp's list: a small kit of reductions that reaches everything](03-Time%20Complexity/05-karps-problems-and-hardness-recipes.md)
6. [Pseudo-polynomial time: fast only while the numbers stay small](03-Time%20Complexity/06-pseudo-polynomial-time-and-numbers-in-the-input.md)
7. [SAT solvers: hard in theory, often easy on the instance in hand](03-Time%20Complexity/07-sat-solvers-and-hard-problems-in-practice.md)
8. [Above NP: alternating there-exists and for-all, and memory instead of time](03-Time%20Complexity/08-conp-pspace-and-the-polynomial-hierarchy.md)
9. [Hierarchy and Ladner: more time really helps, and middle ground must exist](03-Time%20Complexity/09-time-hierarchy-and-ladners-theorem.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Beyond Worst Case · 8 cards

*approximation with guarantees, coin flips, a second parameter, average-case hardness, lower bounds, and the barriers around P versus NP*

1. [Approximation: a guaranteed near-answer, and limits on the guarantee](04-Beyond%20Worst%20Case/01-approximation-and-hardness-of-approximation.md)
2. [Relaxation and rounding: solve a fractional version, then round it back](04-Beyond%20Worst%20Case/02-relaxation-and-rounding.md)
3. [BPP: coin flips that buy speed at a controlled error rate](04-Beyond%20Worst%20Case/03-randomised-complexity-and-bpp.md)
4. [Pseudorandomness: fake coins that a fast test cannot tell from real ones](04-Beyond%20Worst%20Case/04-derandomisation-and-pseudorandomness.md)
5. [Parameterised complexity: hard in general, easy while one number stays small](04-Beyond%20Worst%20Case/05-parameterised-complexity.md)
6. [Average-case hardness: hard on the inputs you actually draw](04-Beyond%20Worst%20Case/06-average-case-and-cryptographic-hardness.md)
7. [Circuit lower bounds: counting gates to prove nothing can be fast](04-Beyond%20Worst%20Case/07-circuit-complexity-and-lower-bounds.md)
8. [P versus NP: the precise statement, and the barriers that block proof](04-Beyond%20Worst%20Case/08-p-versus-np-what-is-known.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Algebraic, Interactive and Quantum · 7 cards

*gates and depth, counting rather than deciding, permanent against determinant, proof by conversation or spot check, and quantum circuits*

1. [Boolean circuits: cost measured in gates and in depth](05-Algebraic%2C%20Interactive%20and%20Quantum/01-boolean-circuits-and-formulas.md)
2. [Counting: how many solutions, not merely whether one exists](05-Algebraic%2C%20Interactive%20and%20Quantum/02-counting-solutions-and-sharp-p.md)
3. [Permanent against determinant: two near-identical formulas, wildly different cost](05-Algebraic%2C%20Interactive%20and%20Quantum/03-algebraic-complexity-permanent-versus-determinant.md)
4. [Interactive proofs: convincing a sceptic by conversation, or by spot checks](05-Algebraic%2C%20Interactive%20and%20Quantum/04-interactive-proofs-ip-pspace-and-the-pcp-theorem.md)
5. [Qubits: a unit vector of amplitudes, read once and collapsed](05-Algebraic%2C%20Interactive%20and%20Quantum/05-qubits-superposition-and-measurement.md)
6. [BQP: what a quantum circuit does and does not speed up](05-Algebraic%2C%20Interactive%20and%20Quantum/06-quantum-computation-and-bqp.md)
7. [Shor and Grover: period finding breaks RSA, search gains a square root](05-Algebraic%2C%20Interactive%20and%20Quantum/07-shors-and-grovers-algorithms.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Data, Learning and Fine-Grained Complexity · 6 cards

*one-pass summaries, random projection, bits across a gap, how many examples are enough, regret, and hardness inside P*

1. [Streaming: one pass, tiny memory, an answer with error bars](06-Data%2C%20Learning%20and%20Fine-Grained%20Complexity/01-streaming-and-sketching.md)
2. [Random projection: squash the data, keep the distances](06-Data%2C%20Learning%20and%20Fine-Grained%20Complexity/02-dimension-reduction-and-random-projection.md)
3. [Communication complexity: how many bits must cross the gap](06-Data%2C%20Learning%20and%20Fine-Grained%20Complexity/03-communication-complexity-in-outline.md)
4. [Learning with a guarantee: how many examples are enough](06-Data%2C%20Learning%20and%20Fine-Grained%20Complexity/04-pac-learning-and-vc-dimension.md)
5. [Regret: judged against the best single choice in hindsight](06-Data%2C%20Learning%20and%20Fine-Grained%20Complexity/05-online-learning-and-regret.md)
6. [Fine-grained complexity: why quadratic is probably the floor](06-Data%2C%20Learning%20and%20Fine-Grained%20Complexity/06-fine-grained-complexity-and-seth.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Category Theory in Outline · 9 cards

*categories and functors, naturality, universal properties, adjunctions, monoids and monads, folds, and side-by-side composition*

1. [Categories and functors: objects, arrows, and maps that respect them](07-Category%20Theory%20in%20Outline/01-categories-and-functors.md)
2. [Commutative diagrams: every route agrees, and every arrow can be reversed](07-Category%20Theory%20in%20Outline/02-commutative-diagrams-and-duality.md)
3. [Natural transformations and Yoneda: an object is known by its arrows](07-Category%20Theory%20in%20Outline/03-natural-transformations-and-yoneda.md)
4. [Universal properties: defined by the one arrow that always exists](07-Category%20Theory%20in%20Outline/04-universal-properties-limits-and-colimits.md)
5. [Pullbacks and pushouts: matching pairs, and gluing along a shared part](07-Category%20Theory%20in%20Outline/05-pullbacks-pushouts-and-gluing.md)
6. [Adjunctions: two functors whose arrows correspond exactly](07-Category%20Theory%20in%20Outline/06-adjunctions.md)
7. [Monoids and monads: combining values, and sequencing steps that can fail](07-Category%20Theory%20in%20Outline/07-monoids-and-monads-for-programmers.md)
8. [F-algebras: one step of a recursive structure, then folded away](07-Category%20Theory%20in%20Outline/08-f-algebras-and-folds.md)
9. [Monoidal categories: things side by side, drawn as parallel wires](07-Category%20Theory%20in%20Outline/09-monoidal-categories-and-string-diagrams.md)

[↑ Back to the shelves](#top)

---

[← 23 · Differential geometry and Lie groups](../23-Differential%20geometry%20and%20Lie%20groups/README.md) · [All wings](../../SYLLABUS.md) · [25 · Frontier →](../25-Frontier/README.md)
