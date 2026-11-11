# Why there is no quintic formula: degrees 2, 3 and 4 have one, degree 5 provably cannot, because the roots' symmetries are too tangled

[Syllabus](../../../SYLLABUS.md) → [Algebra](../README.md) → [For the Curious](../README.md#s10) → Why there is no quintic formula

---

## General Overview

Two equations of degree five: the highest power of the unknown is the fifth. One asks for a number whose fifth power is 2, the other for a number whose fifth power is one more than itself. Both have an answer; only one can be written down.

The first is x^5 - 2 = 0, answered by the fifth root of 2: 1.1486983550 to ten places. The second is x^5 - x - 1 = 0, answered by 1.1673039783, which fifty halvings of an interval around it pin down.

What cannot be done is write that root from whole numbers using plus, minus, times, divide and root-taking. Such an expression is a **radical expression**, and this root has none: Abel proved in 1824 that no radical formula solves every quintic; Ruffini had argued so in 1799.

A **quintic** is a degree-five polynomial equation, and it is where the school formulas stop. The reason is how the five roots may be shuffled without any whole-number equation between them noticing ([Permutations](../08-Groups/03-permutations-and-the-symmetric-group.md)). Taking a root breaks a group of shuffles into layers where order stops mattering. The 120 shuffles of five things refuse to break.

**A radical formula would take the shuffles of an equation's roots apart one order-free layer at a time; the shuffles of five roots stop coming apart at a core of 60, so no radical formula solves every quintic — while the roots are all still there to be found.**

**What kind of fact this is:** a theorem. Its group half is proved here and computed in the code; the bridge from radicals to peelable groups is stated here, proved in Solvable by radicals.

### The picture: two questions about one equation

```mermaid
flowchart TB
    A["x^5 - x - 1 = 0"] --> B["Is there a root?"]
    A --> C["Can plus, minus, times,<br/>divide and roots write it?"]
    B --> D["Yes. Five of them,<br/>one real: 1.1673039783"]
    C --> E["No. Proved impossible:<br/>Ruffini 1799, Abel 1824"]
```

The left road is settled by the fundamental theorem of algebra ([The fundamental theorem of algebra](01-fundamental-theorem-of-algebra.md)); the right one closes.

---

## The formula

Each equation, with what its answer may be written as:

$$x^5 - 2 = 0 \quad\longrightarrow\quad x = \sqrt[5]{2} = 1.1486983550\ldots$$

$$x^5 - x - 1 = 0 \quad\longrightarrow\quad x = 1.1673039783\ldots, \text{ and no radical expression at all}$$

**Read it aloud:** both have a real answer; only the first has one the radical alphabet can spell.

**Abel–Ruffini, stated:** no expression built from a quintic's coefficients — the numbers multiplying its powers — by finitely many pluses, minuses, times, divides and nth roots gives a root of every quintic. Degrees 1 to 4 have one each; degree 5 and up, none.

One measurement carries the proof. Take two shuffles of the roots, $g$ and $h$: undo $h$, undo $g$, do $h$, do $g$, right to left as shuffles compose.

$$[g, h] = g\,h\,g^{-1}h^{-1}$$

where $g^{-1}$ undoes $g$. This is their **commutator**: if the two commute, either order giving the same result, it all cancels and nothing moves. A commutator records how much order mattered.

Collect the commutators of every pair in a group of shuffles and close them under "do one, then the next". Out comes a group inside the original, its **peel**, with what commuted dropped. The standard name for it is the **commutator subgroup**. A group is **solvable** when repeated peeling reaches the do-nothing shuffle.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$, $\sqrt[5]{2}$ | the unknown; the number whose fifth power is 2 | 1.1673039783; 1.1486983550 | another equation, another root |
| $S_n$, so $S_3$, $S_4$, $S_5$ | every shuffle of n roots | $S_5$: 120 shuffles of five | 720 for six roots, still stuck |
| $A_5$ | the 60 even shuffles of five roots: those made by an even number of swaps | the core peeling cannot break | — |
| $g$, $h$, $[g, h]$ | two shuffles, and their commutator | two double swaps, from the code | — |

### When it holds

- **Radicals means that alphabet and no more.** Widen it and the wall moves: other functions write quintic roots, and halving a bracket writes them as decimals.
- **The stock starts at the whole numbers and their ratios.** Hand the recipe the wanted root as a constant and the question empties out.
- **One formula for all quintics fails, not every quintic.** A case is decided by the shuffles that equation's roots admit, not by its degree.

---

## Why it works

### Step 0: existence and spelling are different questions

Every degree-five polynomial has five complex roots (numbers built from the ordinary ones and one new number whose square is -1), counted with repeats ([The fundamental theorem of algebra](01-fundamental-theorem-of-algebra.md)). Existence is settled; naming is not.

### Step 1: every root taken buys one order-free layer

A radical formula is a tower: each nth root taken adds a number to the stock. The shuffles that step introduces commute, being only the choice of which nth root was meant.

So the formula hands over a chain of order-free layers; peeling walks that chain from the other end, and a group that jams was never such a chain. That is the bridge, crossed by Galois in 1832:

**An equation is solvable by radicals exactly when the group of shuffles of its roots is solvable — when peeling reaches the do-nothing shuffle.**

### Step 2: three roots and four roots peel to the end

Peel the 6 shuffles of three things and 3 remain, the even ones; peel again and only the do-nothing shuffle is left: 6 → 3 → 1. Four things run 24 → 12 → 4 → 1. Both chains end, so the bridge permits the formulas Cardano and Ferrari published in 1545.

```mermaid
flowchart LR
    A["3 roots<br/>6 shuffles"] --> B["6 → 3 → 1<br/>the chain ends"]
    C["4 roots<br/>24 shuffles"] --> D["24 → 12 → 4 → 1<br/>the chain ends"]
    E["5 roots<br/>120 shuffles"] --> F["120 → 60 → 60 → 60…<br/>the chain jams"]
    B --> G["cubic formula<br/>exists"]
    D --> H["quartic formula<br/>exists"]
    F --> I["no quintic formula<br/>can exist"]
```

### Step 3: five roots jam at 60

Peel the 120 shuffles of five things and 60 come back: exactly the even ones, $A_5$. Peel those and the same 60 come back, for ever, so the chain reads 120 → 60 → 60 → 60.

Two facts do it, both checked in code. No peel reaches below the even shuffles, since every commutator is even. And the even shuffles are already commutators of even shuffles. A **three-place cycle** — cycling three places, fixing the rest — is the commutator of two double swaps, and three-place cycles build every even shuffle.

<details>
<summary>Detailed proof: the peel of the 60 is the 60 again</summary>

1. **Every commutator is even.** A shuffle and its undo take the same number of swaps, so the four pieces take an even number together. The peel of $S_5$ lies inside $A_5$, and no later peel escapes.
2. **Every three-place cycle is such a commutator.** Exchange places 2 and 3 and also 4 and 5; then places 1 and 2 and also 4 and 5. Both are even, and their commutator sends 1 to 2, 2 to 3, 3 to 1, fixing 4 and 5 — the code prints the pair. Relabelling the places carries it to all 20 three-place cycles.
3. **Three-place cycles build every even shuffle.** Take its swaps two at a time: equal swaps cancel, swaps sharing a place make a three-place cycle, and swaps a-b and c-d sharing none equal a to c, c to d, d to a followed by a to c, c to b, b to a.
4. **So the peel of $A_5$ is $A_5$.** By 2 and 3 it holds all 20 three-place cycles and so all 60; by 1 it holds no more. $S_5$ is not solvable, nor is any larger shuffle group, each holding these 60.

</details>

### Step 4: this quintic carries all 120 shuffles

The bridge asks about one equation's own shuffles: those keeping every whole-number equation between its roots true. For x^5 - x - 1 = 0 that is the full 120, as Conrad's paper below proves. So its roots have no radical expression — and, as it does not factor, not even one at a time. One such equation kills the general formula.

### Step 5: the root is still there, and two roads reach it

At x = 1 the expression x^5 - x - 1 comes out at -1, at x = 2 at 29. A polynomial cannot pass from below zero to above without crossing, so a root lies between. Halve the interval, keep the half still straddling zero, repeat: 50 halvings give 1.1673039783.

Newton's step is the second road: from a guess, follow the curve's own slope to the axis, landing at x - (x^5 - x - 1) / (5x^4 - 1). Eight steps from 1.2 give the same 1.1673039783. Abel's own proof used no groups; Galois's reworking is what generalises.

---

## Worked numbers, by hand

The two quintics, then the chains.

| Step | Arithmetic or check | Value |
| --- | --- | --- |
| the radical quintic, x^5 - 2 | 50 halvings, then 8 Newton steps | **1.1486983550** |
| bracket the other, x^5 - x - 1 | its value at x = 1 and at x = 2 | -1.00 and 29.00 |
| the root inside | 50 halvings, then 8 Newton steps | **1.1673039783** |
| peel three roots, then four | 6 → 3 → 1; 24 → 12 → 4 → 1 | **both reach 1** |
| peel five roots | 120 → 60 → 60 → 60 | **stuck at 60** |

Ten places of a number no radical expression can write, and a chain never reaching bottom.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Reusing the fifth root of 2 in x^5 - x - 1 | -0.1486983550, not 0 | the extra -x moves the root |
| "Degree five, so no radical answer" | x^5 - 2 answered at 1.1486983550 | the general formula fails, not every case |
| Stopping the peel at its first step | 60, read as if it were 1 | the 60 even shuffles peel to themselves |
| "No formula" read as "no root" | the root 1.1673039783, sitting there | existence is a separate theorem |

The code prints all four.

---

## Code, from first principles, and it actually runs

Nothing is imported, and each answer comes twice. The group half builds every commutator and closes it up, peeling the shuffles of three, four and five roots. That first peel is checked again against the even shuffles, counted by pairs standing out of order. The jam is checked by finding all 20 three-place cycles among commutators and rebuilding the 60.

### Python

```python
# Why there is no quintic formula -- the check behind the card.  Nothing is imported.  The
# group half peels the shuffles of 3, 4 and 5 roots by commutators; a shuffle of n places is
# a tuple of destinations, right-hand factor first.  The number half finds the root of
# x^5 - x - 1 and the radical root of x^5 - 2 by halving a bracket and again by Newton's step.
def shuffles(n):                               # every rearrangement of n places
    out = [()]
    for _ in range(n): out = [s + (d,) for s in out for d in range(1, n + 1) if d not in s]
    return out
def comp(a, b): return tuple(a[j - 1] for j in b)       # do b first, then a
def inv(a): return tuple(a.index(i) + 1 for i in range(1, len(a) + 1))
def odd(a): return sum(1 for i in range(len(a))         # pairs out of order
                       for j in range(i + 1, len(a)) if a[i] > a[j]) % 2
def bracket(a, b): return comp(comp(a, b), comp(inv(a), inv(b)))
def close(gens, ident):                        # smallest group holding the gens
    G = set(gens) | {ident}
    while G != (bigger := G | {comp(a, b) for a in G for b in G}): G = bigger
    return sorted(G)
def peel(G, ident): return close([bracket(a, b) for a in G for b in G], ident)
def ladder(n, steps=4):                     # group sizes down the peeling chain
    ident, G, sizes = tuple(range(1, n + 1)), shuffles(n), []
    for _ in range(steps): sizes.append(len(G)); G = peel(G, ident)
    return sizes
def chain(sizes): return " -> ".join(str(v) for v in sizes)
E5, S5 = tuple(range(1, 6)), shuffles(5)       # road two is the even shuffles,
A5, first = [s for s in S5 if not odd(s)], peel(S5, E5)    # road one the commutators
threes = [s for s in A5 if sum(1 for i, d in enumerate(s, 1) if d != i) == 3]
commutators = {bracket(a, b) for a in A5 for b in A5}
built, s3, s4, s5 = close(threes, E5), ladder(3), ladder(4), ladder(5)
lo_pair = next((a, b) for a in A5 for b in A5 if bracket(a, b) == (2, 3, 1, 4, 5))
print(f"shuffles of 3, 4 and 5 roots: {len(shuffles(3))}, {len(shuffles(4))} and {len(S5)}")
print(f"peeled by commutators, 3 roots: {chain(s3)}; 4 roots: {chain(s4)} -- both reach 1")
print(f"peeled by commutators, 5 roots: {chain(s5)} -- stuck at {s5[-1]}")
print(f"the first peel of the 120 is exactly the {len(A5)} even shuffles: {first == A5}")
print(f"all {len(threes)} three-place cycles are commutators of even shuffles: "
      f"{all(t in commutators for t in threes)}; they build all {len(built)}")
print(f"smallest such pair: [2, 3, 1, 4, 5] from {list(lo_pair[0])} and {list(lo_pair[1])}")
def five(x): return x * x * x * x * x
hard, easy = lambda x: five(x) - x - 1, lambda x: five(x) - 2
def halve(h, lo, hi, steps=50):                # both curves rise across 1 to 2
    for _ in range(steps):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if h(mid) < 0 else (lo, mid)
    return (lo + hi) / 2
def newton(h, slope, x, steps=8):
    for _ in range(steps): x = x - h(x) / slope(x)
    return x
eb, hb = halve(easy, 1.0, 2.0), halve(hard, 1.0, 2.0)
en = newton(easy, lambda x: 5 * x * x * x * x, 1.2)
hn = newton(hard, lambda x: 5 * x * x * x * x - 1, 1.2)
print(f"x^5 - 2 at x = 1 and x = 2: {easy(1.0):.2f} and {easy(2.0):.2f}; "
      f"x^5 - x - 1 there: {hard(1.0):.2f} and {hard(2.0):.2f}")
print(f"x^5 - 2, the radical case: 50 halvings give {eb:.10f}, 8 Newton steps {en:.10f}")
print(f"that root's fifth power, by five multiplications: {five(eb):.10f}")
print(f"x^5 - x - 1: 50 halvings give {hb:.10f}, 8 Newton steps from 1.2 {hn:.10f}")
print(f"the four mistakes come out at a residual of {hard(eb):.10f}, a radical answer of "
      f"{eb:.10f}, a peel stuck at {s5[-1]} instead of 1, and a root of {hb:.10f} all the same")
assert first == A5 and len(A5) == 60 and s5 == [120, 60, 60, 60]
assert all(t in commutators for t in threes) and built == A5 and len(threes) == 20
assert s3 == [6, 3, 1, 1] and s4 == [24, 12, 4, 1]
assert abs(hb - hn) < 1e-12 and abs(five(hb) - hb - 1) < 1e-12 and abs(five(eb) - 2) < 1e-12
print("ALL CHECKS PASS")
```

**Ran 2026-09-14 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
shuffles of 3, 4 and 5 roots: 6, 24 and 120
peeled by commutators, 3 roots: 6 -> 3 -> 1 -> 1; 4 roots: 24 -> 12 -> 4 -> 1 -- both reach 1
peeled by commutators, 5 roots: 120 -> 60 -> 60 -> 60 -- stuck at 60
the first peel of the 120 is exactly the 60 even shuffles: True
all 20 three-place cycles are commutators of even shuffles: True; they build all 60
smallest such pair: [2, 3, 1, 4, 5] from [1, 3, 2, 5, 4] and [2, 1, 3, 5, 4]
x^5 - 2 at x = 1 and x = 2: -1.00 and 30.00; x^5 - x - 1 there: -1.00 and 29.00
x^5 - 2, the radical case: 50 halvings give 1.1486983550, 8 Newton steps 1.1486983550
that root's fifth power, by five multiplications: 2.0000000000
x^5 - x - 1: 50 halvings give 1.1673039783, 8 Newton steps from 1.2 1.1673039783
the four mistakes come out at a residual of -0.1486983550, a radical answer of 1.1486983550, a peel stuck at 60 instead of 1, and a root of 1.1673039783 all the same
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Why there is no quintic formula -- the same check as the Python, in Rust.  No crates.  The group
// half peels the shuffles of 3, 4 and 5 roots by commutators; a shuffle of n places is a list of
// destinations, right-hand factor first.  The number half finds the root of x^5 - x - 1 and the
// radical root of x^5 - 2 by halving a bracket and again by Newton's step.
type P = Vec<i32>;
fn shuffles(n: i32) -> Vec<P> {                    // every rearrangement of n places
    let mut out: Vec<P> = vec![vec![]];
    for _ in 0..n { out = out.iter().flat_map(|s| (1..=n).filter(|d| !s.contains(d))
        .map(|d| { let mut t = s.clone(); t.push(d); t }).collect::<Vec<P>>()).collect(); }
    out
}
fn comp(a: &P, b: &P) -> P { b.iter().map(|&j| a[(j - 1) as usize]).collect() }   // b first
fn inv(a: &P) -> P { (1..=a.len() as i32).map(|i| a.iter().position(|&d| d == i).unwrap() as i32 + 1).collect() }
fn odd(a: &P) -> bool {                            // pairs standing out of order
    (0..a.len()).map(|i| (i + 1..a.len()).filter(|&j| a[i] > a[j]).count()).sum::<usize>() % 2 == 1
}
fn bracket(a: &P, b: &P) -> P { comp(&comp(a, b), &comp(&inv(a), &inv(b))) }
fn uniq(mut v: Vec<P>) -> Vec<P> { v.sort(); v.dedup(); v }
fn close(gens: Vec<P>, ident: &P) -> Vec<P> {      // smallest group holding the gens
    let mut g = uniq([gens, vec![ident.clone()]].concat());
    loop {
        let grown: Vec<P> = g.iter().flat_map(|a| g.iter().map(move |b| comp(a, b))).collect();
        let wider = uniq([g.clone(), grown].concat());
        if wider == g { return g; } else { g = wider; }
    }
}
fn peel(g: &[P], ident: &P) -> Vec<P> {
    close(g.iter().flat_map(|a| g.iter().map(move |b| bracket(a, b))).collect(), ident)
}
fn ladder(n: i32) -> Vec<usize> {                  // group sizes down the peeling chain
    let (ident, mut g, mut sizes): (P, Vec<P>, Vec<usize>) = ((1..=n).collect(), uniq(shuffles(n)), vec![]);
    for _ in 0..4 { sizes.push(g.len()); g = peel(&g, &ident); }
    sizes
}
fn chain(s: &[usize]) -> String { s.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" -> ") }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn five(x: f64) -> f64 { x * x * x * x * x }
fn hard(x: f64) -> f64 { five(x) - x - 1.0 }
fn easy(x: f64) -> f64 { five(x) - 2.0 }
fn halve(h: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {    // both curves rise
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if h(mid) < 0.0 { lo = mid; } else { hi = mid; } }
    (lo + hi) / 2.0
}
fn newton(h: &dyn Fn(f64) -> f64, slope: &dyn Fn(f64) -> f64, mut x: f64) -> f64 {
    for _ in 0..8 { x = x - h(x) / slope(x); }
    x
}
fn main() {
    let (e5, s5): (P, Vec<P>) = ((1..=5).collect(), uniq(shuffles(5)));
    let (a5, first): (Vec<P>, Vec<P>) = (s5.iter().filter(|s| !odd(s)).cloned().collect(), peel(&s5, &e5));
    let threes: Vec<P> = a5.iter().filter(|s| s.iter().enumerate()
        .filter(|(i, &d)| d != *i as i32 + 1).count() == 3).cloned().collect();
    let commutators = uniq(a5.iter().flat_map(|a| a5.iter().map(move |b| bracket(a, b))).collect());
    let (built, s3, s4, sizes) = (close(threes.clone(), &e5), ladder(3), ladder(4), ladder(5));
    let pair = a5.iter().flat_map(|a| a5.iter().map(move |b| (a, b)))
        .find(|(a, b)| bracket(a, b) == vec![2, 3, 1, 4, 5]).unwrap();
    let every_three = threes.iter().all(|t| commutators.contains(t));
    println!("shuffles of 3, 4 and 5 roots: {}, {} and {}", shuffles(3).len(), shuffles(4).len(), s5.len());
    println!("peeled by commutators, 3 roots: {}; 4 roots: {} -- both reach 1", chain(&s3), chain(&s4));
    println!("peeled by commutators, 5 roots: {} -- stuck at {}", chain(&sizes), sizes[3]);
    println!("the first peel of the 120 is exactly the {} even shuffles: {}", a5.len(), tf(first == a5));
    println!("all {} three-place cycles are commutators of even shuffles: {}; they build \
all {}", threes.len(), tf(every_three), built.len());
    println!("smallest such pair: [2, 3, 1, 4, 5] from {:?} and {:?}", pair.0, pair.1);
    let (eb, hb) = (halve(&easy, 1.0, 2.0), halve(&hard, 1.0, 2.0));
    let (en, hn) = (newton(&easy, &|x: f64| 5.0 * x * x * x * x, 1.2),
                    newton(&hard, &|x: f64| 5.0 * x * x * x * x - 1.0, 1.2));
    println!("x^5 - 2 at x = 1 and x = 2: {:.2} and {:.2}; x^5 - x - 1 there: {:.2} and {:.2}",
             easy(1.0), easy(2.0), hard(1.0), hard(2.0));
    println!("x^5 - 2, the radical case: 50 halvings give {:.10}, 8 Newton steps {:.10}", eb, en);
    println!("that root's fifth power, by five multiplications: {:.10}", five(eb));
    println!("x^5 - x - 1: 50 halvings give {:.10}, 8 Newton steps from 1.2 {:.10}", hb, hn);
    println!("the four mistakes come out at a residual of {:.10}, a radical answer of {:.10}, \
a peel stuck at {} instead of 1, and a root of {:.10} all the same", hard(eb), eb, sizes[3], hb);
    assert!(first == a5 && a5.len() == 60 && sizes == vec![120, 60, 60, 60]);
    assert!(every_three && built == a5 && threes.len() == 20);
    assert!(s3 == vec![6, 3, 1, 1] && s4 == vec![24, 12, 4, 1]);
    assert!((hb - hn).abs() < 1e-12 && (five(hb) - hb - 1.0).abs() < 1e-12 && (five(eb) - 2.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-14 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
shuffles of 3, 4 and 5 roots: 6, 24 and 120
peeled by commutators, 3 roots: 6 -> 3 -> 1 -> 1; 4 roots: 24 -> 12 -> 4 -> 1 -- both reach 1
peeled by commutators, 5 roots: 120 -> 60 -> 60 -> 60 -- stuck at 60
the first peel of the 120 is exactly the 60 even shuffles: True
all 20 three-place cycles are commutators of even shuffles: True; they build all 60
smallest such pair: [2, 3, 1, 4, 5] from [1, 3, 2, 5, 4] and [2, 1, 3, 5, 4]
x^5 - 2 at x = 1 and x = 2: -1.00 and 30.00; x^5 - x - 1 there: -1.00 and 29.00
x^5 - 2, the radical case: 50 halvings give 1.1486983550, 8 Newton steps 1.1486983550
that root's fifth power, by five multiplications: 2.0000000000
x^5 - x - 1: 50 halvings give 1.1673039783, 8 Newton steps from 1.2 1.1673039783
the four mistakes come out at a residual of -0.1486983550, a radical answer of 1.1486983550, a peel stuck at 60 instead of 1, and a root of 1.1673039783 all the same
ALL CHECKS PASS
```

### Lean

Lean proves the card's theorem for every degree from 5 up, and the group half for any number of roots.

- For each degree from 5 up, some equation with whole-number or ratio coefficients has a complex root no radical expression writes.
- Lean's quintic is x^5 - 4x + 2, not x^5 - x - 1; higher degrees multiply it by a power of x.
- The root itself exists; only its radical spelling fails.
- Step 1's bridge, from radical formulas to peeling, is taken from a proof already in Lean's library.
- The shuffles of n roots peel down to the do-nothing shuffle exactly when n is 4 or less.
- The first peel of the 120 shuffles of five roots is exactly the 60 even shuffles, $A_5$.
- Peeling those 60 gives the same 60 back.
- It also re-checks the card's numbers: -1 and 29, -1 and 30, then 6, 24 and 120 shuffles, 60 of them even.
- It checks the code's pair: two even double swaps whose commutator is the three-place cycle [2, 3, 1, 4, 5].
- It counts the 20 three-place cycles among the shuffles of five roots.

The decimal roots, found by halving and Newton's step, and the printed peel chains are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 231 lines</summary>

```lean
-- Why there is no quintic formula: for every degree from 5 up there is a polynomial with rational coefficients having a complex root that no radical expression writes, because the shuffles of 5 or more roots never peel down to nothing while those of 3 and 4 do.
import Mathlib.FieldTheory.AbelRuffini
import Mathlib.GroupTheory.Solvable
import Mathlib.GroupTheory.SpecificGroups.Alternating.Centralizer
import Mathlib.Basic.Complex.Basic
import Mathlib.GroupTheory.SpecificGroups.Alternating.Simple
import Mathlib.Analysis.Calculus.LocalExtr.Polynomial
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.Eisenstein.Criterion
import Mathlib.RingTheory.Int.Basic
import Mathlib.RingTheory.Polynomial.GaussLemma

open Polynomial Equiv

section QuinticHelper

open Function Polynomial.Gal Ideal

attribute [local instance] splits_ℚ_ℂ

/-- The quintic `X ^ 5 - a X + b`. -/
noncomputable def Φ (R : Type*) [CommRing R] (a b : ℕ) : R[X] :=
  X ^ 5 - C (a : R) * X + C (b : R)

theorem map_Phi {R : Type*} [CommRing R] (a b : ℕ) {S : Type*} [CommRing S] (f : R →+* S) :
    (Φ R a b).map f = Φ S a b := by simp [Φ]

theorem coeff_zero_Phi {R : Type*} [CommRing R] (a b : ℕ) : (Φ R a b).coeff 0 = (b : R) := by
  simp [Φ, coeff_X_pow]

theorem coeff_five_Phi {R : Type*} [CommRing R] (a b : ℕ) : (Φ R a b).coeff 5 = 1 := by
  simp [Φ, -map_natCast]

theorem degree_Phi {R : Type*} [CommRing R] [Nontrivial R] (a b : ℕ) :
    (Φ R a b).degree = ((5 : ℕ) : WithBot ℕ) := by
  suffices degree (X ^ 5 - C (a : R) * X) = ((5 : ℕ) : WithBot ℕ) by
    rwa [Φ, degree_add_eq_left_of_degree_lt]
    convert! (degree_C_le (R := R)).trans_lt (WithBot.coe_lt_coe.mpr (show 0 < 5 by simp))
  rw [degree_sub_eq_left_of_degree_lt] <;> rw [degree_X_pow]
  exact (degree_C_mul_X_le (a : R)).trans_lt (WithBot.coe_lt_coe.mpr (show 1 < 5 by simp))

theorem natDegree_Phi {R : Type*} [CommRing R] [Nontrivial R] (a b : ℕ) :
    (Φ R a b).natDegree = 5 :=
  natDegree_eq_of_degree_eq_some (degree_Phi a b)

theorem monic_Phi {R : Type*} [CommRing R] [Nontrivial R] (a b : ℕ) : (Φ R a b).Monic := by
  show (Φ R a b).leadingCoeff = 1
  rw [Polynomial.leadingCoeff, natDegree_Phi, coeff_five_Phi]

theorem irreducible_Phi (a b : ℕ) (p : ℕ) (hp : p.Prime) (hpa : p ∣ a) (hpb : p ∣ b)
    (hp2b : ¬p ^ 2 ∣ b) : Irreducible (Φ ℚ a b) := by
  rw [← map_Phi a b (Int.castRingHom ℚ), ← IsPrimitive.Int.irreducible_iff_irreducible_map_cast]
  on_goal 1 =>
    apply irreducible_of_eisenstein_criterion
    · rwa [span_singleton_prime (Int.natCast_ne_zero.mpr hp.ne_zero), Int.prime_iff_natAbs_prime]
    · rw [(monic_Phi a b).leadingCoeff, mem_span_singleton]
      exact mod_cast mt Nat.dvd_one.mp hp.ne_one
    · intro n hn
      rw [mem_span_singleton]
      rw [degree_Phi] at hn; norm_cast at hn
      interval_cases n <;>
      simp +decide only [Φ, coeff_X_pow, coeff_C, Int.natCast_dvd_natCast.mpr,
        hpb, ite_true, coeff_C_mul, ite_false, coeff_X_zero, hpa, coeff_add, zero_add, mul_zero,
        coeff_sub, add_zero, zero_sub, dvd_neg, neg_zero, dvd_mul_of_dvd_left]
    · simp only [degree_Phi, ← WithBot.coe_zero]
      decide
    · rw [coeff_zero_Phi, span_singleton_pow, mem_span_singleton]
      exact mt Int.natCast_dvd_natCast.mp hp2b
  all_goals exact Monic.isPrimitive (monic_Phi a b)

attribute [local simp] map_ofNat in
theorem real_roots_Phi_le (a b : ℕ) : Fintype.card ((Φ ℚ a b).rootSet ℝ) ≤ 3 := by
  rw [← map_Phi a b (algebraMap ℤ ℚ), Φ, ← one_mul (X ^ 5), ← C_1]
  apply (card_rootSet_le_derivative _).trans
    (Nat.succ_le_succ ((card_rootSet_le_derivative _).trans (Nat.succ_le_succ _)))
  suffices (Polynomial.rootSet (C (20 : ℚ) * X ^ 3) ℝ).Subsingleton by
    norm_num [Fintype.card_le_one_iff_subsingleton, ← mul_assoc] at *
    exact this
  rw [rootSet_C_mul_X_pow] <;>
  norm_num

theorem real_roots_Phi_ge_aux (a b : ℕ) (hab : b < a) :
    ∃ x y : ℝ, x ≠ y ∧ aeval x (Φ ℚ a b) = 0 ∧ aeval y (Φ ℚ a b) = 0 := by
  let f : ℝ → ℝ := fun x : ℝ => aeval x (Φ ℚ a b)
  have hf : f = fun x : ℝ => x ^ 5 - a * x + b := by simp [f, Φ]
  have hc : ∀ s : Set ℝ, ContinuousOn f s := fun s => (Φ ℚ a b).continuousOn_aeval
  have ha : (1 : ℝ) ≤ a := Nat.one_le_cast.mpr (Nat.one_le_of_lt hab)
  have hle : (0 : ℝ) ≤ 1 := zero_le_one
  have hf0 : 0 ≤ f 0 := by simp [hf]
  by_cases hb : (1 : ℝ) - a + b < 0
  · have hf1 : f 1 < 0 := by simp [hf, hb]
    have hfa : 0 ≤ f a := by
      simp_rw [hf, ← sq]
      refine add_nonneg (sub_nonneg.mpr (pow_right_mono₀ ha ?_)) ?_ <;> norm_num
    obtain ⟨x, ⟨-, hx1⟩, hx2⟩ := intermediate_value_Ico' hle (hc _) (Set.mem_Ioc.mpr ⟨hf1, hf0⟩)
    obtain ⟨y, ⟨hy1, -⟩, hy2⟩ := intermediate_value_Ioc ha (hc _) (Set.mem_Ioc.mpr ⟨hf1, hfa⟩)
    exact ⟨x, y, (hx1.trans hy1).ne, hx2, hy2⟩
  · replace hb : (b : ℝ) = a - 1 := by linarith [show (b : ℝ) + 1 ≤ a from mod_cast hab]
    have hf1 : f 1 = 0 := by simp [hf, hb]
    have hfa :=
      calc
        f (-a) = (a : ℝ) ^ 2 - (a : ℝ) ^ 5 + b := by
          norm_num [hf, ← sq, sub_eq_add_neg, add_comm, Odd.neg_pow (by decide : Odd 5)]
        _ ≤ (a : ℝ) ^ 2 - (a : ℝ) ^ 3 + (a - 1) := by gcongr <;> linarith
        _ = -((a : ℝ) - 1) ^ 2 * (a + 1) := by ring
        _ ≤ 0 := by nlinarith
    have ha' := neg_nonpos.mpr (hle.trans ha)
    obtain ⟨x, ⟨-, hx1⟩, hx2⟩ := intermediate_value_Icc ha' (hc _) (Set.mem_Icc.mpr ⟨hfa, hf0⟩)
    exact ⟨x, 1, (hx1.trans_lt zero_lt_one).ne, hx2, hf1⟩

theorem real_roots_Phi_ge (a b : ℕ) (hab : b < a) : 2 ≤ Fintype.card ((Φ ℚ a b).rootSet ℝ) := by
  have q_ne_zero : Φ ℚ a b ≠ 0 := (monic_Phi a b).ne_zero
  obtain ⟨x, y, hxy, hx, hy⟩ := real_roots_Phi_ge_aux a b hab
  have key : ↑({x, y} : Finset ℝ) ⊆ (Φ ℚ a b).rootSet ℝ := by
    simp [Set.insert_subset, mem_rootSet_of_ne q_ne_zero, hx, hy]
  convert! Fintype.card_le_of_embedding (Set.embeddingOfSubset _ _ key)
  simp only [Finset.coe_sort_coe, Fintype.card_coe, Finset.card_singleton,
    Finset.card_insert_of_notMem (mt Finset.mem_singleton.mp hxy)]

theorem complex_roots_Phi (a b : ℕ) (h : (Φ ℚ a b).Separable) :
    Fintype.card ((Φ ℚ a b).rootSet ℂ) = 5 :=
  (card_rootSet_eq_natDegree h (IsAlgClosed.splits _)).trans (natDegree_Phi a b)

theorem gal_Phi (a b : ℕ) (hab : b < a) (h_irred : Irreducible (Φ ℚ a b)) :
    Bijective (galActionHom (Φ ℚ a b) ℂ) := by
  apply galActionHom_bijective_of_prime_degree' h_irred
  · simp only [natDegree_Phi]; decide
  · rw [complex_roots_Phi a b h_irred.separable, Nat.succ_le_succ_iff]
    exact (real_roots_Phi_le a b).trans (Nat.le_succ 3)
  · simp_rw [complex_roots_Phi a b h_irred.separable, Nat.succ_le_succ_iff]
    exact real_roots_Phi_ge a b hab

theorem not_solvable_by_rad (a b : ℕ) (p : ℕ) (x : ℂ) (hx : aeval x (Φ ℚ a b) = 0) (hab : b < a)
    (hp : p.Prime) (hpa : p ∣ a) (hpb : p ∣ b) (hp2b : ¬p ^ 2 ∣ b) : x ∉ solvableByRad ℚ ℂ := by
  have h_irred := irreducible_Phi a b p hp hpa hpb hp2b
  apply mt (isSolvable_gal_of_irreducible · h_irred hx)
  intro h
  refine Equiv.Perm.not_isSolvable _ (le_of_eq ?_)
    (Group.isSolvable_of_surjective (gal_Phi a b hab h_irred).2)
  rw_mod_cast [Cardinal.mk_fintype, complex_roots_Phi a b h_irred.separable]

theorem not_solvable_by_rad' (x : ℂ) (hx : aeval x (Φ ℚ 4 2) = 0) : x ∉ solvableByRad ℚ ℂ := by
  apply not_solvable_by_rad 4 2 2 x hx <;> decide

/-- A complex root of `X ^ 5 - 4 X + 2` that is not solvable by radicals. -/
theorem exists_root_not_solvable :
    ∃ x : ℂ, aeval x (Φ ℚ 4 2) = 0 ∧ x ∉ solvableByRad ℚ ℂ := by
  obtain ⟨x, hx⟩ := (IsAlgClosed.splits (Φ ℂ 4 2)).exists_eval_eq_zero (by simp [degree_Phi])
  rw [← map_Phi 4 2 (algebraMap ℚ ℂ), eval_map] at hx
  exact ⟨x, hx, not_solvable_by_rad' x hx⟩

end QuinticHelper

#print axioms Φ
#print axioms map_Phi
#print axioms coeff_zero_Phi
#print axioms coeff_five_Phi
#print axioms degree_Phi
#print axioms natDegree_Phi
#print axioms monic_Phi
#print axioms irreducible_Phi
#print axioms real_roots_Phi_le
#print axioms real_roots_Phi_ge_aux
#print axioms real_roots_Phi_ge
#print axioms complex_roots_Phi
#print axioms gal_Phi
#print axioms not_solvable_by_rad
#print axioms not_solvable_by_rad'
#print axioms exists_root_not_solvable


/-- Abel and Ruffini: no radical formula solves every equation of degree 5 or more. For every
degree n from 5 up there is a polynomial with rational coefficients, of exactly that degree, with
a complex root that cannot be written from the rational numbers by plus, minus, times, divide
and nth roots (it lies outside `solvableByRad ℚ ℂ`). The root exists; only its radical spelling
fails. -/
theorem no_radical_formula_solves_every_equation_of_degree_five_or_more (n : ℕ) (hn : 5 ≤ n) :
    ∃ p : ℚ[X], p.natDegree = n ∧ ∃ x : ℂ, aeval x p = 0 ∧ x ∉ solvableByRad ℚ ℂ := by
  obtain ⟨x, hx, hxr⟩ := exists_root_not_solvable
  refine ⟨Φ ℚ 4 2 * X ^ (n - 5), ?_, x, ?_, hxr⟩
  · rw [natDegree_mul (monic_Phi 4 2).ne_zero (pow_ne_zero _ X_ne_zero),
      natDegree_Phi, natDegree_X_pow]
    omega
  · simp [hx]

/-- The group half. The shuffles of n roots peel down to the do-nothing shuffle (the group of all
permutations of n things is solvable) exactly when n is at most 4: the chain ends for 3 and 4
roots, and jams for 5 roots and more. -/
theorem shuffles_of_n_roots_peel_to_nothing_iff_n_le_four (n : ℕ) :
    Group.IsSolvable (Perm (Fin n)) ↔ n ≤ 4 := by
  constructor
  · intro h
    by_contra hn
    refine Equiv.Perm.not_isSolvable (Fin n) ?_ h
    rw [Cardinal.mk_fin]
    exact_mod_cast (by omega : 5 ≤ n)
  · intro hn
    exact Equiv.Perm.isSolvable (by simpa using hn)

/-- The jam at 60. Peeling the 120 shuffles of five roots (taking the subgroup their commutators
generate) gives exactly the 60 even shuffles, and peeling those 60 gives all 60 back again. -/
theorem peel_of_five_shuffles_is_the_even_sixty_and_stays_there :
    commutator (Perm (Fin 5)) = alternatingGroup (Fin 5) ∧
      commutator (alternatingGroup (Fin 5)) = ⊤ := by
  exact ⟨alternatingGroup.commutator_perm_eq (by simp),
    commutator_alternatingGroup_eq_top (by simp)⟩

-- x^5 - x - 1 at x = 1 and x = 2: -1 and 29, so a root lies between.
example : (1 : ℤ) ^ 5 - 1 - 1 = -1 ∧ (2 : ℤ) ^ 5 - 2 - 1 = 29 := by norm_num
-- x^5 - 2 at x = 1 and x = 2: -1 and 30.
example : (1 : ℤ) ^ 5 - 2 = -1 ∧ (2 : ℤ) ^ 5 - 2 = 30 := by norm_num
-- The shuffles of 3, 4 and 5 roots: 6, 24 and 120.
example : Fintype.card (Perm (Fin 3)) = 6 ∧ Fintype.card (Perm (Fin 4)) = 24 ∧
    Fintype.card (Perm (Fin 5)) = 120 := by
  norm_num [Fintype.card_perm, Nat.factorial]
-- The even shuffles of five roots: 60, counted by sign.
example : (Finset.univ.filter fun σ : Perm (Fin 5) => Perm.sign σ = 1).card = 60 := by decide
-- The code's pair: the double swaps [1, 3, 2, 5, 4] and [2, 1, 3, 5, 4] (places 1 to 5 written
-- here as 0 to 4) have as commutator the three-place cycle [2, 3, 1, 4, 5].
example : ∀ i : Fin 5,
    ((swap 1 2 * swap 3 4) * (swap 0 1 * swap 3 4) * (swap 1 2 * swap 3 4)⁻¹ *
      (swap 0 1 * swap 3 4)⁻¹ : Perm (Fin 5)) i = ![1, 2, 0, 3, 4] i := by decide
-- Both double swaps are even.
example : Perm.sign (swap 1 2 * swap 3 4 : Perm (Fin 5)) = 1 ∧
    Perm.sign (swap 0 1 * swap 3 4 : Perm (Fin 5)) = 1 := by decide
-- There are 20 three-place cycles among the shuffles of five roots.
example : (Finset.univ.filter fun σ : Perm (Fin 5) => σ.support.card = 3).card = 20 := by decide

#print axioms no_radical_formula_solves_every_equation_of_degree_five_or_more
#print axioms shuffles_of_n_roots_peel_to_nothing_iff_n_le_four
#print axioms peel_of_five_shuffles_is_the_even_sixty_and_stays_there
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'Φ' depends on axioms: [propext, Classical.choice, Quot.sound]
'map_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'coeff_zero_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'coeff_five_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'degree_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'natDegree_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'monic_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'irreducible_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'real_roots_Phi_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'real_roots_Phi_ge_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'real_roots_Phi_ge' depends on axioms: [propext, Classical.choice, Quot.sound]
'complex_roots_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'gal_Phi' depends on axioms: [propext, Classical.choice, Quot.sound]
'not_solvable_by_rad' depends on axioms: [propext, Classical.choice, Quot.sound]
'not_solvable_by_rad'' depends on axioms: [propext, Classical.choice, Quot.sound]
'exists_root_not_solvable' depends on axioms: [propext, Classical.choice, Quot.sound]
'no_radical_formula_solves_every_equation_of_degree_five_or_more' depends on axioms: [propext, Classical.choice, Quot.sound]
'shuffles_of_n_roots_peel_to_nothing_iff_n_le_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'peel_of_five_shuffles_is_the_even_sixty_and_stays_there' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. An assert halts the program on a wrong number.
> - **Peel with the wrong bracket.** In `bracket`, return `comp(a, b)`: nothing shrinks, the peel of the 120 is 120, first assert halts it.
> - **Take one Newton step, not eight.** Set `steps` to 1 in `newton`: the root prints 1.1692228864 against the halvings' 1.1673039783, fourth assert halts it.
> - **Peel one time fewer.** Set `steps` to 3 in `ladder`: four roots read 24 → 12 → 4 and look as jammed as five.

---

## The usual mistake

> [!warning]
> **Hearing "no formula" as "no answer".** Five roots exist for every quintic, and the real one here is pinned to ten places by 50 halvings. Abel ruled out one way of writing a root, not the root itself — and it is proved impossible, not unsolved.
>
> - **Thinking it kills every quintic.** x^5 - 2 = 0 is a quintic, and its answer is a single fifth root, 1.1486983550.
> - **Reusing one quintic's answer on another.** The fifth root of 2 put into x^5 - x - 1 gives -0.1486983550.
> - **Calling the first peel the end.** 120 down to 60 looks like progress; the next peel gives 60 again, never 1.

---

## Where you meet it in real life

- **Eigenvalues of a 5 by 5 matrix.** Roots of a degree-five polynomial: no radical formula gives them in general, and every library iterates ([Eigenvalues and eigenvectors](../07-Eigenvalues%20and%20Symmetric%20Matrices/02-eigenvalues-and-eigenvectors.md)).
- **Computer algebra.** Asked to solve a quintic, a package returns radicals where the equation allows, else numbers or a name for the roots.
- **Engineering and graphics.** Polynomial roots in control design, ray tracing and orbit work are found by bracketing and iteration. Abel–Ruffini sits with the other proved impossibilities, such as trisecting an angle: knowing a tool cannot do a job redirects the work.

> **Say it back**
> Degrees 2, 3 and 4 have formulas built from plus, minus, times, divide and root-taking; degree 5 has none, and that is proved, not unknown. The reason is the shuffles of the roots: a radical formula would break them into order-free layers, and the 120 shuffles of five break to 60 and stop. The root is still there, 1.1673039783, found twice over.

---

## What this builds on

- [The quadratic formula](../02-Polynomials/03-quadratic-formula.md): the radical formula everyone has met, whose pattern degree 5 breaks.
- [Permutations](../08-Groups/03-permutations-and-the-symmetric-group.md): shuffles, how they compose, and even-or-odd as a property of the shuffle.
- [Normal subgroups and quotient groups](../08-Groups/06-normal-subgroups-and-quotient-groups.md): throwing part of a group away and having a group left, as each peel does.
- [Proof by contradiction](../../01-Foundations/06-Proof/03-proof-by-contradiction.md): the argument's shape — assume the formula, reach a chain that cannot exist.

## Where this goes next

- Solvable by radicals: the bridge proved, and how to test one equation rather than a whole degree.

This card takes that bridge on trust: the one thing left to earn.

---

## Sources

Verified 14 Sep 2026: every link below resolves to the publisher's page.

- Abel, Niels Henrik. "Beweis der Unmöglichkeit, algebraische Gleichungen von höheren Graden als dem vierten allgemein aufzulösen." *Journal für die reine und angewandte Mathematik* 1 (1826), 65-84. [doi:10.1515/crll.1826.1.65](https://doi.org/10.1515/crll.1826.1.65). The 1824 proof as published.
- Conrad, Keith. "The Galois group of x^n - x - 1 over Q." University of Connecticut. [Expository paper](https://kconrad.math.uconn.edu/blurbs/gradnumthy/galoisselmerpoly.pdf). Proves this quintic's roots admit all 120 shuffles, as Step 4 needs.
- Judson, Thomas W. *Abstract Algebra: Theory and Applications*. Stephen F. Austin State University. [University publication page](https://scholarworks.sfasu.edu/ebooks/23/). Solvable groups and the chain of peels.
- O'Connor, J. J., and E. F. Robertson. "Paolo Ruffini." MacTutor History of Mathematics Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Ruffini/). The 1799 argument and its gap.
