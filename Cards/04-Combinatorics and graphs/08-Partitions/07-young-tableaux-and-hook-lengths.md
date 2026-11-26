# Young tableaux and the hook length formula: fill a partition's diagram with 1 to n rising along rows and down columns, and n! over the product of hook lengths counts the ways

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Partitions](../README.md#s08) → Young tableaux and the hook length formula

---

## General Overview

A board of five votes on a motion: three yes, two no. The chair reads the ballots aloud one at a time. In how many reading orders is "yes" never behind?

Record an order in a grid of boxes. Write each ballot's place in the reading in the top row if it says yes, in the bottom row if no. The rows hold three boxes and two, both starting at the left edge: the Ferrers diagram of the partition 3 + 2 ([Integer partitions](01-integer-partitions.md)), drawn with boxes.

Rows rise to the right: ballots are read in order. "Yes never behind" adds a second rule: the first no comes after the first yes, the second no after the second yes. So each bottom number is bigger than the one above it: columns rise downward too.

A box grid filled with 1 to n, rows rising to the right and columns downward, is a **standard Young tableau** (plural tableaux), after Alfred Young. The shape 3 + 2 has five, so five orders work. For a 10–10 vote, listing means checking 184,756 orders; 16,796 pass.

**Give every box a hook — the box, the boxes to its right and the boxes below it — and the number of standard tableaux on n boxes is n! divided by the product of all the hook lengths.**

**What kind of fact this is:** a theorem, proved on this card in Why it works. Allowing repeated entries later on this card defines a weight sum — the Schur polynomial — whose symmetry is proved in Step 4.

### The picture: the five fillings of 3 + 2

| Top row (yes) | Bottom row (no) | Reading order |
| --- | --- | --- |
| 1 2 3 | 4 5 | Y Y Y N N |
| 1 2 4 | 3 5 | Y Y N Y N |
| 1 2 5 | 3 4 | Y Y N N Y |
| 1 3 4 | 2 5 | Y N Y Y N |
| 1 3 5 | 2 4 | Y N Y N Y |

Y N N Y Y is one of five that fail: 3 would sit under 4, and no would lead 2 to 1.

---

## The formula

The shape is written $`\lambda`$ (lambda): its row lengths, longest first, here $`(3, 2)`$, with $`n`$ boxes in all. The box in row $`i`$ and column $`j`$ is $`(i, j)`$. Its **hook length** $`h(i, j)`$ counts the box, the boxes to its right and the boxes below it.

| | column 1 | column 2 | column 3 |
| --- | --- | --- | --- |
| row 1 | 4 | 3 | 1 |
| row 2 | 2 | 1 | |

Box $`(1, 1)`$ has itself, two boxes to its right and one below: 4. The count of standard tableaux is $`f^{\lambda}`$:

```math
f^{\lambda} = \frac{n!}{\prod_{(i,j) \in \lambda} h(i,j)}
```

**Read it aloud:** divide n factorial by the product of the hook lengths of all n boxes.

The tall $`\prod`$ means multiply over every box. Here $`5! = 120`$ ([Factorials](../01-Counting%20Principles/03-factorial.md)), the hooks multiply to 24, and $`120 / 24 = 5`$.

**Allowing repeats.** A **semistandard tableau** $`T`$ uses entries 1 to $`m`$, rows never falling and columns rising strictly. Give each entry $`v`$ a variable $`x_v`$; the tableau's **weight** $`x^T`$ multiplies one $`x_v`$ per entry. The **Schur polynomial** adds the weights:

```math
s_{\lambda}(x_1, \ldots, x_m) = \sum_{T} x^{T}
```

**Read it aloud:** add the weights of every semistandard tableau of shape lambda with entries 1 to m.

Shape $`(2, 1)`$ with entries 1 and 2 has two: top row 1 1 over 2, and top row 1 2 over 2. So $`s_{(2,1)}(x_1, x_2) = x_1^2 x_2 + x_1 x_2^2`$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`\lambda`$, $`n`$ | the shape, row lengths longest first; its box count | $`(3, 2)`$; 5 | far more fillings |
| $`(i, j)`$ | the box in row $`i`$, column $`j`$ | $`(1, 1)`$, top left | — |
| $`h(i, j)`$ | hook length: the box, the boxes right of it and below it | 4, 3, 1 and 2, 1 | fewer fillings |
| $`\prod`$, $`\sum`$ | multiply, or add, over every box or tableau | 24; two weights | — |
| $`f^{\lambda}`$ | number of standard tableaux | 5 | — |
| $`c = (r, s)`$, $`P(c)`$, $`\lambda - c`$ | a corner box (hook length 1) in row $`r`$, column $`s`$; the chance the hook walk stops there; the shape without $`c`$ | $`(1, 3)`$; 2/5; $`(2, 2)`$ | — |
| $`T`$, $`m`$, $`x_v`$, $`x^T`$ | a semistandard tableau; its largest allowed entry; a variable per entry; the weight | 1 1 over 2; 2; $`x_1`$; $`x_1^2 x_2`$ | more tableaux |
| $`s_{\lambda}`$ | Schur polynomial: the sum of the weights | $`x_1^2 x_2 + x_1 x_2^2`$ | — |

### When it holds

- **Columns rise as well as rows.** Without the column rule the count is 10, not 5.
- **Rows start at the left and never lengthen going down.** On 2 boxes over 3 the formula gives 120/36, not a whole number.
- **Each of 1 to n is used once.** With repeats from 1 to 3, $`(2, 1)`$ has 8 semistandard tableaux, not 2.
- **Semistandard rows are weak.** Make them strict and $`(2, 1)`$ keeps one tableau, $`x_1 x_2^2`$: the symmetry of Step 4 is lost.

---

## Why it works

### Step 0: the largest number sits in a corner

A **corner** is a box with nothing right of it and nothing below. The number $`n`$ must sit in one, since a box right of it or below it would need a bigger number.

Remove $`n`$ and a standard tableau of a smaller shape remains. So for $`n \ge 1`$, $`f^{\lambda}`$ is the sum of $`f^{\lambda - c}`$ over the corners $`c`$, where $`\lambda - c`$ is the shape without that box. For $`(3, 2)`$ the 5 sits at $`(1, 3)`$, leaving $`(2, 2)`$ with 2 fillings, or at $`(2, 2)`$, leaving $`(3, 1)`$ with 3: $`2 + 3 = 5`$.

So the formula holds for every shape if its right side obeys the same corner rule (induction on $`n`$). Divided through, that rule says some fractions add to 1: chances, as Greene, Nijenhuis and Wilf saw.

### Step 1: the fractions

Removing corner $`c`$ shortens by one just the hooks of the boxes left of $`c`$ in its row and above $`c`$ in its column. So the formula for $`\lambda - c`$, divided by the formula for $`\lambda`$, is

```math
P(c) = \frac{1}{n} \prod_{\text{boxes left of } c \text{ or above } c} \frac{h}{h - 1}
```

**Read it aloud:** one over n, times hook over hook minus one, for each box left of the corner or above it.

Corner $`(1, 3)`$ has hooks 4 and 3 to its left: $`(1/5)(4/3)(3/2) = 2/5`$. Corner $`(2, 2)`$ has hook 3 above and 2 to its left: $`(1/5)(3/2)(2/1) = 3/5`$. They add to 1, matching 2 and 3 of the 5 fillings.

### Step 2: the hook walk

1. Pick one of the $`n`$ boxes, each equally likely.
2. Jump to another box of its hook, each equally likely.
3. Repeat until the walk reaches a corner.

Jumps go right or down, so the walk stops; its stopping chances add to 1.

### Step 3: the walk stops at each corner with Step 1's fraction

Write the corner as $`c = (r, s)`$, and group the walks to $`c`$ by the rows and columns they visit; the top row and left column give the start.

A group's total chance is a product. Each visited row other than $`r`$ gives one over (hook minus one) at the box where that row meets column $`s`$. Each visited column other than $`s`$ gives the same where it meets row $`r`$.

Each row above $`c`$ and each column left of $`c`$ is either visited or skipped. Summing over all groups, times $`1/n`$ for the start, gives $`1 + 1/(h-1) = h/(h-1)`$ per box above or left of $`c`$: Step 1's fraction. The fractions are stopping chances, they add to 1, and the formula obeys the corner rule.

<details>
<summary>Detailed proof: the chance of one set of rows and columns</summary>

Start at $`(i, j) \ne c`$, with $`i \le r`$ and $`j \le s`$ (at $`c`$ the walk stops with chance 1). The first jump goes down to the next visited row or right to the next visited column, each with chance $`1/(h(i, j) - 1)`$. By induction the rest of the walk has the full product with one factor missing: row $`i`$'s, or column $`j`$'s. So the chance is the full product times

$`\displaystyle \frac{(h(i, s) - 1) + (h(r, j) - 1)}{h(i, j) - 1}`$

and this ratio is 1. Since $`c`$ is a corner, column $`s`$ ends at row $`r`$ and row $`r`$ ends at column $`s`$. So $`h(i, s) - 1`$ counts row $`i`$ right of column $`s`$ plus the $`r - i`$ boxes below. Likewise $`h(r, j) - 1`$ counts the $`s - j`$ boxes right of it plus column $`j`$ below row $`r`$.

Together, those count every box right of or below $`(i, j)`$. In row $`r`$ or column $`s`$ one term is zero, and the count still holds.

</details>

### Step 4: Schur polynomials are symmetric

Swap $`x_1`$ and $`x_2`$ in $`x_1^2 x_2 + x_1 x_2^2`$ and the same polynomial returns. A swap of tableaux due to Bender and Knuth shows why.

A 1 with a 2 directly below it forms a locked pair; every other 1 and 2 is free. In each row, swap the number of free 1s with the number of free 2s. The result is still semistandard, and doing it twice gives back the start, so weights pair off with $`x_1`$ and $`x_2`$ traded.

In top row 1 1 over 2, the second 1 is free and becomes a 2: top row 1 2 over 2.

The swap works for any neighbouring values, and such swaps reach every reordering, so $`s_{\lambda}`$ never changes when its variables are reordered. The code checks all six reorderings of $`s_{(2,1)}(x_1, x_2, x_3)`$.

A weight of $`x_1 x_2 \cdots x_n`$ uses each of 1 to $`n`$ once, so that coefficient is $`f^{\lambda}`$: 2 for $`(2, 1)`$, 5 for $`(3, 2)`$.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| hooks, row 1 | box + right + below | 4, 3, 1 |
| hooks, row 2 | box + right | 2, 1 |
| hook product | 4 × 3 × 1 × 2 × 1 | 24 |
| orders of five ballots | 5! | 120 |
| standard tableaux | 120 / 24 | **5** |
| corner rule | 2 fillings of (2, 2) + 3 of (3, 1) | 5 |
| reflection | C(5,2) − C(5,1) = 10 − 5 | 5 |
| a 10–10 vote | hooks 11 down to 2, then 10 down to 1 | **16,796** |

Five reading orders keep yes level or ahead. Reflection with the mirror shifted one step lower ([The reflection principle](../06-Lattice%20Paths%20and%20Catalan%20Numbers/02-reflection-principle-and-ballot-problem.md), [Catalan numbers](../06-Lattice%20Paths%20and%20Catalan%20Numbers/03-catalan-numbers.md)) gives 184,756 − 167,960 = 16,796 for a 10–10 vote.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Columns ignored | 10, not 5 | Orders where no leads are counted |
| Hook counts the box and those below | 120 / 4 = 30 | The arm to the right is part of the hook |
| Semistandard rows made strict | 1 tableau, $`x_1 x_2^2`$ | Its swap partner is gone: not symmetric |

---

## Code, from first principles, and it actually runs

Four independent roads reach 5: listing every filling, the hook formula, reflection and the corner rule. The hook walk is followed exactly along every path.

### Python

```python
# Young tableaux and hook lengths -- the check behind the card.  Five ballots, three yes and two
# no, fill the shape (3, 2).  Its standard tableaux are counted by listing fillings, by the hook
# formula, by the hook walk and by reflection; Schur polynomials come from semistandard tableaux.
from fractions import Fraction
from itertools import permutations, product
def fact(n): return n * fact(n - 1) if n > 1 else 1
def prod(xs): return xs[0] * prod(xs[1:]) if xs else 1
def choose(n, k): return fact(n) // (fact(k) * fact(n - k))
def cells(lam): return [(i, j) for i in range(len(lam)) for j in range(lam[i])]
def hook_cells(lam, c):                  # the cells right of c, then the cells below c
    return [(c[0], j) for j in range(c[1] + 1, lam[c[0]])] + [(i, c[1]) for i in range(c[0] + 1, len(lam)) if lam[i] > c[1]]
def hooks(lam): return [1 + len(hook_cells(lam, c)) for c in cells(lam)]
def by_hooks(lam): return fact(sum(lam)) // prod(hooks(lam))         # road one: the hook formula
def ok(T, lam, strict):                  # rows rise (strictly or weakly), columns rise strictly
    return all((j == 0 or T[i, j] > T[i, j - 1] or (not strict and T[i, j] == T[i, j - 1]))
               and (i == 0 or T[i, j] > T[i - 1, j]) for i, j in cells(lam))
def fillings(lam, vals, strict): return [T for p in vals if ok(T := dict(zip(cells(lam), p)), lam, strict)]
def standard(lam): return fillings(lam, permutations(range(1, sum(lam) + 1)), True)   # road two: try all
def schur(lam, m, strict=False):         # semistandard tableaux, entries 1..m, as monomial -> count
    es = [tuple(list(T.values()).count(v) for v in range(1, m + 1)) for T in fillings(lam, product(range(1, m + 1), repeat=sum(lam)), strict)]
    return {e: es.count(e) for e in es}
def walk(lam, c):                        # road three: exact chances of where a hook walk stops
    out, step = ({} if hook_cells(lam, c) else {c: Fraction(1)}), hook_cells(lam, c)
    for d in step:
        for k, p in walk(lam, d).items(): out[k] = out.get(k, 0) + p / len(step)
    return out
def shapes(n, top): return [()] if n == 0 else [(a,) + r for a in range(min(n, top), 0, -1) for r in shapes(n - a, a)]
show = lambda T, lam: "[" + "/".join(" ".join(str(T[i, j]) for j in range(lam[i])) for i in range(len(lam))) + "]"
poly = lambda P: " + ".join((f"{P[e]} " if P[e] > 1 else "") + " ".join(f"x{v + 1}" + (f"^{k}" if k > 1 else "")
                            for v, k in enumerate(e) if k) for e in sorted(P, reverse=True))
lam, n, H = (3, 2), 5, hooks((3, 2)); syt, ssyt = standard(lam), fillings((2, 1), product(range(1, 3), repeat=3), False)
ends = {c: sum(walk(lam, s).get(c, 0) for s in cells(lam)) / n for c in [(0, 2), (1, 1)]}
small = {c: (lam[0] - (c[0] == 0), lam[1] - (c[0] == 1)) for c in ends}; a, b = (len(standard(small[c])) for c in ends)
listed, hooked = [len(standard(mu)) for mu in shapes(n, n)], [by_hooks(mu) for mu in shapes(n, n)]
s21, s21x3, s32x5, s21s = schur((2, 1), 2), schur((2, 1), 3), schur(lam, 5), schur((2, 1), 2, True)
symmetric = all(s21x3[tuple(e[q] for q in sig)] == s21x3[e] for e in s21x3 for sig in permutations(range(3)))
print(f"shape {lam}, n = {n}; hook lengths by row: {H[:3]} {H[3:]}")
print(f"hook formula: {n}!/({'*'.join(map(str, H))}) = {fact(n)}/{prod(H)} = {by_hooks(lam)}")
print(f"standard tableaux by listing all {fact(n)} fillings: {len(syt)}\n  " + "  ".join(show(T, lam) for T in syt))
print("as ballot orders (row 1 = yes, row 2 = no): " + " ".join("".join("YN"[v in (T[1, 0], T[1, 1])] for v in range(1, 6)) for T in syt))
print(f"reflection count: C(5,2) - C(5,1) = {choose(5, 2)} - {choose(5, 1)} = {choose(5, 2) - choose(5, 1)}; "
      f"corner recurrence, by listing: f(2, 2) + f(3, 1) = {a} + {b} = {a + b}")
for c, p in ends.items():
    print(f"hook walk ends at corner ({c[0] + 1},{c[1] + 1}) with chance {p} = f{small[c]}/f{lam} = {Fraction(by_hooks(small[c]), by_hooks(lam))}")
print(f"all shapes of 5, listed: {listed}; by hooks: {hooked}; squares add to {sum(f * f for f in listed)} = 5!")
print(f"rows lengthening downward, 2 over 3: {sum(p[0] < p[1] and p[2] < p[3] < p[4] and p[0] < p[2] and p[1] < p[3] for p in permutations(range(1, 6)))} "
      f"fillings by listing, but hooks give {fact(n)}/{(h23 := prod(hooks((2, 3))))} = {Fraction(fact(n), h23)}")
print(f"shape (10, 10): hook rows {(H10 := hooks((10, 10)))[0]}..{H10[9]} and {H10[10]}..{H10[19]}; hooks give {by_hooks((10, 10))}; "
      f"reflection C(20,10) - C(20,9) = {choose(20, 10)} - {choose(20, 9)} = {choose(20, 10) - choose(20, 9)}")
print(f"semistandard (2, 1), entries 1..2: {' '.join(show(T, (2, 1)) for T in ssyt)}; s(2,1)(x1,x2) = {poly(s21)}")
print(f"s(2,1)(x1,x2,x3): {sum(s21x3.values())} tableaux, symmetric under every swap of variables: {'yes' if symmetric else 'no'}; x1 x2 x3 coefficient {s21x3[1, 1, 1]} = f(2, 1)")
print(f"s(3,2) in 5 variables: x1 x2 x3 x4 x5 coefficient {s32x5[1, 1, 1, 1, 1]} = f(3, 2)")
print(f"mistake 1, columns ignored: {sum(1 for p in permutations(range(1, 6)) if p[0] < p[1] < p[2] and p[3] < p[4])}, not 5")
print(f"mistake 2, hooks counting only cells below: {fact(n)}/{prod(legs := [sum(lam[i] > j for i in range(r, 2)) for r, j in cells(lam)])} = {fact(n) // prod(legs)}, not 5")
print(f"mistake 3, rows strictly rising in a semistandard tableau: {sum(s21s.values())} tableau, {poly(s21s)}, not symmetric")
assert len(syt) == by_hooks(lam) == choose(5, 2) - choose(5, 1) == a + b and H == [4, 3, 1, 2, 1]
assert all(ends[c] == Fraction(by_hooks(small[c]), by_hooks(lam)) for c in ends) and sum(ends.values()) == 1
assert listed == hooked and sum(f * f for f in listed) == fact(n) and by_hooks((10, 10)) == choose(20, 10) - choose(20, 9)
assert symmetric and s21 == {(2, 1): 1, (1, 2): 1} and s21x3[1, 1, 1] == by_hooks((2, 1)) == 2 and s32x5[1, 1, 1, 1, 1] == 5
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
shape (3, 2), n = 5; hook lengths by row: [4, 3, 1] [2, 1]
hook formula: 5!/(4*3*1*2*1) = 120/24 = 5
standard tableaux by listing all 120 fillings: 5
  [1 2 3/4 5]  [1 2 4/3 5]  [1 2 5/3 4]  [1 3 4/2 5]  [1 3 5/2 4]
as ballot orders (row 1 = yes, row 2 = no): YYYNN YYNYN YYNNY YNYYN YNYNY
reflection count: C(5,2) - C(5,1) = 10 - 5 = 5; corner recurrence, by listing: f(2, 2) + f(3, 1) = 2 + 3 = 5
hook walk ends at corner (1,3) with chance 2/5 = f(2, 2)/f(3, 2) = 2/5
hook walk ends at corner (2,2) with chance 3/5 = f(3, 1)/f(3, 2) = 3/5
all shapes of 5, listed: [1, 4, 5, 6, 5, 4, 1]; by hooks: [1, 4, 5, 6, 5, 4, 1]; squares add to 120 = 5!
rows lengthening downward, 2 over 3: 2 fillings by listing, but hooks give 120/36 = 10/3
shape (10, 10): hook rows 11..2 and 10..1; hooks give 16796; reflection C(20,10) - C(20,9) = 184756 - 167960 = 16796
semistandard (2, 1), entries 1..2: [1 1/2] [1 2/2]; s(2,1)(x1,x2) = x1^2 x2 + x1 x2^2
s(2,1)(x1,x2,x3): 8 tableaux, symmetric under every swap of variables: yes; x1 x2 x3 coefficient 2 = f(2, 1)
s(3,2) in 5 variables: x1 x2 x3 x4 x5 coefficient 5 = f(3, 2)
mistake 1, columns ignored: 10, not 5
mistake 2, hooks counting only cells below: 120/4 = 30, not 5
mistake 3, rows strictly rising in a semistandard tableau: 1 tableau, x1 x2^2, not symmetric
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Young tableaux and hook lengths -- the same check as the Python, in Rust.  No crates.  Five
// ballots, three yes and two no, fill the shape (3, 2), counted by listing, by the hook formula,
// by the hook walk and by reflection; Schur polynomials come from semistandard tableaux.
use std::collections::BTreeMap;
type Cell = (usize, usize); type Frac = (u128, u128); type Tab = Vec<Vec<usize>>;
fn fact(n: u128) -> u128 { (1..=n).product() }
fn choose(n: u128, k: u128) -> u128 { fact(n) / (fact(k) * fact(n - k)) }
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn frac(a: u128, b: u128) -> Frac { let g = gcd(a, b); (a / g, b / g) }
fn add(x: Frac, y: Frac) -> Frac { frac(x.0 * y.1 + y.0 * x.1, x.1 * y.1) }
fn cells(lam: &[usize]) -> Vec<Cell> { (0..lam.len()).flat_map(|i| (0..lam[i]).map(move |j| (i, j))).collect() }
fn hook_cells(lam: &[usize], c: Cell) -> Vec<Cell> {     // the cells right of c, then the cells below c
    (c.1 + 1..lam[c.0]).map(|j| (c.0, j)).chain((c.0 + 1..lam.len()).filter(|&i| lam[i] > c.1).map(|i| (i, c.1))).collect() }
fn hooks(lam: &[usize]) -> Vec<u128> { cells(lam).iter().map(|&c| 1 + hook_cells(lam, c).len() as u128).collect() }
fn by_hooks(lam: &[usize]) -> u128 { fact(lam.iter().sum::<usize>() as u128) / hooks(lam).iter().product::<u128>() }  // road one
fn fill(lam: &[usize], p: &[usize]) -> Tab { let mut k = 0; lam.iter().map(|&r| { k += r; p[k - r..k].to_vec() }).collect() }
fn ok(t: &Tab, strict: bool) -> bool {                  // rows rise (strictly or weakly), columns rise strictly
    cells(&t.iter().map(|r| r.len()).collect::<Vec<_>>()).iter().all(|&(i, j)|
        (j == 0 || t[i][j] > t[i][j - 1] || (!strict && t[i][j] == t[i][j - 1])) && (i == 0 || t[i][j] > t[i - 1][j])) }
fn perms(v: &[usize]) -> Vec<Vec<usize>> {
    if v.is_empty() { return vec![vec![]] }
    (0..v.len()).flat_map(|i| { let mut r = v.to_vec(); let x = r.remove(i); perms(&r).into_iter().map(move |p| [vec![x], p].concat()) }).collect() }
fn words(m: usize, len: usize) -> Vec<Vec<usize>> {
    if len == 0 { vec![vec![]] } else { words(m, len - 1).into_iter().flat_map(|w| (1..=m).map(move |v| [w.clone(), vec![v]].concat())).collect() } }
fn tableaux(lam: &[usize], all: Vec<Vec<usize>>, strict: bool) -> Vec<Tab> { all.iter().map(|p| fill(lam, p)).filter(|t| ok(t, strict)).collect() }
fn standard(lam: &[usize]) -> Vec<Tab> { tableaux(lam, perms(&(1..=lam.iter().sum()).collect::<Vec<usize>>()), true) }  // road two
fn schur(lam: &[usize], m: usize, strict: bool) -> BTreeMap<Vec<usize>, usize> {   // monomial -> count
    let mut p = BTreeMap::new();
    for t in tableaux(lam, words(m, lam.iter().sum()), strict) {
        *p.entry((1..=m).map(|v| t.concat().iter().filter(|&&x| x == v).count()).collect()).or_insert(0) += 1 }
    p }
fn walk(lam: &[usize], c: Cell, out: &mut BTreeMap<Cell, Frac>, w: Frac) {   // road three: the hook walk
    let step = hook_cells(lam, c);
    if step.is_empty() { let e = out.entry(c).or_insert((0, 1)); *e = add(*e, w); }
    for d in &step { walk(lam, *d, out, frac(w.0, w.1 * step.len() as u128)) } }
fn shapes(n: usize, top: usize) -> Vec<Vec<usize>> {
    if n == 0 { vec![vec![]] } else { (1..=top.min(n)).rev().flat_map(|a| shapes(n - a, a).into_iter().map(move |r| [vec![a], r].concat())).collect() } }
fn join<T: ToString>(v: &[T], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }
fn show(t: &Tab) -> String { format!("[{}]", t.iter().map(|r| join(r, " ")).collect::<Vec<_>>().join("/")) }
fn poly(p: &BTreeMap<Vec<usize>, usize>) -> String {
    p.iter().rev().map(|(e, &k)| format!("{}{}", if k > 1 { format!("{} ", k) } else { String::new() },
        join(&e.iter().enumerate().filter(|&(_, &x)| x > 0).map(|(v, &x)| if x > 1 { format!("x{}^{}", v + 1, x) } else { format!("x{}", v + 1) })
        .collect::<Vec<_>>(), " "))).collect::<Vec<_>>().join(" + ") }
fn main() {
    let (lam, n, h, h10, h23) = (vec![3, 2], 5u128, hooks(&[3, 2]), hooks(&[10, 10]), hooks(&[2, 3]).iter().product::<u128>());
    let (syt, ssyt) = (standard(&lam), tableaux(&[2, 1], words(2, 3), false)); let mut ends = BTreeMap::new();
    for c in cells(&lam) { walk(&lam, c, &mut ends, (1, n)) }
    let (a, b) = (standard(&[2, 2]).len() as u128, standard(&[3, 1]).len() as u128);
    let listed: Vec<u128> = shapes(5, 5).iter().map(|mu| standard(mu).len() as u128).collect();
    let hooked: Vec<u128> = shapes(5, 5).iter().map(|mu| by_hooks(mu)).collect();
    let (s21, s21x3, s32x5, s21s) = (schur(&[2, 1], 2, false), schur(&[2, 1], 3, false), schur(&lam, 5, false), schur(&[2, 1], 2, true));
    let symmetric = s21x3.iter().all(|(e, k)| perms(&[0, 1, 2]).iter().all(|s| s21x3[&s.iter().map(|&q| e[q]).collect::<Vec<_>>()] == *k));
    let legs: Vec<u128> = cells(&lam).iter().map(|&(r, j)| (r..2).filter(|&i| lam[i] > j).count() as u128).collect();
    let ballots: Vec<String> = syt.iter().map(|t| (1..=5).map(|v| if t[1].contains(&v) { 'N' } else { 'Y' }).collect()).collect();
    println!("shape (3, 2), n = {}; hook lengths by row: {:?} {:?}", n, &h[..3], &h[3..]);
    println!("hook formula: {}!/({}) = {}/{} = {}", n, join(&h, "*"), fact(n), h.iter().product::<u128>(), by_hooks(&lam));
    println!("standard tableaux by listing all {} fillings: {}\n  {}", fact(n), syt.len(), syt.iter().map(show).collect::<Vec<_>>().join("  "));
    println!("as ballot orders (row 1 = yes, row 2 = no): {}", ballots.join(" "));
    println!("reflection count: C(5,2) - C(5,1) = {} - {} = {}; corner recurrence, by listing: f(2, 2) + f(3, 1) = {} + {} = {}",
             choose(5, 2), choose(5, 1), choose(5, 2) - choose(5, 1), a, b, a + b);
    for ((c, p), (s, mu)) in ends.iter().zip([("(2, 2)", [2, 2]), ("(3, 1)", [3, 1])]) {
        let q = frac(by_hooks(&mu), by_hooks(&lam));
        println!("hook walk ends at corner ({},{}) with chance {}/{} = f{}/f(3, 2) = {}/{}", c.0 + 1, c.1 + 1, p.0, p.1, s, q.0, q.1);
        assert!(*p == q) }
    println!("all shapes of 5, listed: {:?}; by hooks: {:?}; squares add to {} = 5!", listed, hooked, listed.iter().map(|f| f * f).sum::<u128>());
    println!("rows lengthening downward, 2 over 3: {} fillings by listing, but hooks give {}/{} = {}/{}", perms(&[1, 2, 3, 4, 5]).iter().filter(|p| p[0] < p[1] && p[2] < p[3] && p[3] < p[4] && p[0] < p[2] && p[1] < p[3]).count(), fact(n), h23, frac(fact(n), h23).0, frac(fact(n), h23).1);
    println!("shape (10, 10): hook rows {}..{} and {}..{}; hooks give {}; reflection C(20,10) - C(20,9) = {} - {} = {}", h10[0], h10[9], h10[10], h10[19],
             by_hooks(&[10, 10]), choose(20, 10), choose(20, 9), choose(20, 10) - choose(20, 9));
    println!("semistandard (2, 1), entries 1..2: {}; s(2,1)(x1,x2) = {}", ssyt.iter().map(show).collect::<Vec<_>>().join(" "), poly(&s21));
    println!("s(2,1)(x1,x2,x3): {} tableaux, symmetric under every swap of variables: {}; x1 x2 x3 coefficient {} = f(2, 1)", s21x3.values().sum::<usize>(), if symmetric { "yes" } else { "no" }, s21x3[&vec![1, 1, 1]]);
    println!("s(3,2) in 5 variables: x1 x2 x3 x4 x5 coefficient {} = f(3, 2)", s32x5[&vec![1, 1, 1, 1, 1]]);
    println!("mistake 1, columns ignored: {}, not 5", perms(&[1, 2, 3, 4, 5]).iter().filter(|p| p[0] < p[1] && p[1] < p[2] && p[3] < p[4]).count());
    println!("mistake 2, hooks counting only cells below: {}/{} = {}, not 5", fact(n), legs.iter().product::<u128>(), fact(n) / legs.iter().product::<u128>());
    println!("mistake 3, rows strictly rising in a semistandard tableau: {} tableau, {}, not symmetric", s21s.values().sum::<usize>(), poly(&s21s));
    assert!(syt.len() as u128 == by_hooks(&lam) && by_hooks(&lam) == choose(5, 2) - choose(5, 1) && a + b == 5 && h == vec![4, 3, 1, 2, 1]);
    assert!(ends.values().fold((0, 1), |s, &p| add(s, p)) == (1, 1) && listed == hooked && listed.iter().map(|f| f * f).sum::<u128>() == fact(n));
    assert!(by_hooks(&[10, 10]) == choose(20, 10) - choose(20, 9) && symmetric && s21x3[&vec![1, 1, 1]] as u128 == by_hooks(&[2, 1]));
    assert!(s21.len() == 2 && s21[&vec![2, 1]] == 1 && s21[&vec![1, 2]] == 1 && s32x5[&vec![1, 1, 1, 1, 1]] == 5);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
shape (3, 2), n = 5; hook lengths by row: [4, 3, 1] [2, 1]
hook formula: 5!/(4*3*1*2*1) = 120/24 = 5
standard tableaux by listing all 120 fillings: 5
  [1 2 3/4 5]  [1 2 4/3 5]  [1 2 5/3 4]  [1 3 4/2 5]  [1 3 5/2 4]
as ballot orders (row 1 = yes, row 2 = no): YYYNN YYNYN YYNNY YNYYN YNYNY
reflection count: C(5,2) - C(5,1) = 10 - 5 = 5; corner recurrence, by listing: f(2, 2) + f(3, 1) = 2 + 3 = 5
hook walk ends at corner (1,3) with chance 2/5 = f(2, 2)/f(3, 2) = 2/5
hook walk ends at corner (2,2) with chance 3/5 = f(3, 1)/f(3, 2) = 3/5
all shapes of 5, listed: [1, 4, 5, 6, 5, 4, 1]; by hooks: [1, 4, 5, 6, 5, 4, 1]; squares add to 120 = 5!
rows lengthening downward, 2 over 3: 2 fillings by listing, but hooks give 120/36 = 10/3
shape (10, 10): hook rows 11..2 and 10..1; hooks give 16796; reflection C(20,10) - C(20,9) = 184756 - 167960 = 16796
semistandard (2, 1), entries 1..2: [1 1/2] [1 2/2]; s(2,1)(x1,x2) = x1^2 x2 + x1 x2^2
s(2,1)(x1,x2,x3): 8 tableaux, symmetric under every swap of variables: yes; x1 x2 x3 coefficient 2 = f(2, 1)
s(3,2) in 5 variables: x1 x2 x3 x4 x5 coefficient 5 = f(3, 2)
mistake 1, columns ignored: 10, not 5
mistake 2, hooks counting only cells below: 120/4 = 30, not 5
mistake 3, rows strictly rising in a semistandard tableau: 1 tableau, x1 x2^2, not symmetric
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the hook length formula and the symmetry of Schur polynomials for every shape, and checks the worked numbers.

- Take any shape $`\lambda`$ with $`n`$ boxes. Then $`f^{\lambda}`$ equals $`n!`$ divided by the product of the hook lengths of all its boxes.
- Take any shape $`\lambda`$ and any $`m`$. Then reordering $`x_1, \ldots, x_m`$ never changes $`s_{\lambda}(x_1, \ldots, x_m)`$.
- Take any shape $`\lambda`$ with $`n`$ boxes. Then the coefficient of $`x_1 x_2 \cdots x_n`$ in $`s_{\lambda}(x_1, \ldots, x_n)`$ is $`f^{\lambda}`$.
- Take the shape $`(3, 2)`$. Then its hook lengths are 4, 3, 1 and 2, 1, they multiply to 24, and $`120 / 24 = 5`$.
- Reflection gives C(5,2) − C(5,1) = 10 − 5 = 5.
- Take a 10–10 vote. Then the hooks give 16,796, and C(20,10) and C(20,9) are 184,756 and 167,960.
- On 2 boxes over 3, 120/36 is not a whole number.

Listing fillings, the hook walk chances, the example Schur polynomials and the mistake counts are left to the Python and Rust checks.

```lean
-- Young tableaux and the hook length formula: the number of standard Young tableaux of a shape with n boxes is n! divided by the product of its hook lengths, and Schur polynomials are symmetric.
import Mathlib.Combinatorics.Young.SemistandardTableau
import Mathlib.RingTheory.MvPolynomial.Symmetric.Defs
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.GroupTheory.Perm.Sign
import Mathlib.Algebra.Order.BigOperators.Group.LocallyFinite
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.BigOperators.Field

open MvPolynomial

namespace YoungTableauxHookLengths

/-- The hook length of the box `c = (i, j)` of `μ`: the number of boxes of `μ` in its hook, which is
the box itself, the boxes to its right in row `i` and the boxes below it in column `j`. -/
def hookLength (μ : YoungDiagram) (c : ℕ × ℕ) : ℕ :=
  (μ.cells.filter (fun d => (d.1 = c.1 ∧ c.2 ≤ d.2) ∨ (d.2 = c.2 ∧ c.1 ≤ d.1))).card

/-- A standard Young tableau of shape `μ`: a filling of the boxes of `μ` (rows weakly rising,
columns strictly rising, zero off the diagram) that uses each of `1, …, n` exactly once, where
`n` is the number of boxes. Using each number once makes the rows strictly rising too. -/
def StandardYoungTableau (μ : YoungDiagram) : Type :=
  {T : SemistandardYoungTableau μ //
    Set.BijOn (fun c : ℕ × ℕ => T c.1 c.2) (μ : Set (ℕ × ℕ)) (Set.Icc 1 μ.card)}

/-- The semistandard tableaux of shape `μ` with entries from `1` to `m`. -/
def SSYTUpTo (μ : YoungDiagram) (m : ℕ) : Type :=
  {T : SemistandardYoungTableau μ // ∀ c ∈ μ, 1 ≤ T c.1 c.2 ∧ T c.1 c.2 ≤ m}

/-- The weight `x^T` of a tableau with entries `1, …, m`: one variable `x_v` for each entry `v`.
Variable `X v` (for `v : Fin m`) stands for the entry `v + 1`. -/
noncomputable def weight {μ : YoungDiagram} {m : ℕ} (T : SSYTUpTo μ m) :
    MvPolynomial (Fin m) ℤ :=
  ∏ v : Fin m, X v ^ (μ.cells.filter (fun c => T.1 c.1 c.2 = v.val + 1)).card

/-- The Schur polynomial `s_μ(x_1, …, x_m)`: the sum of the weights of all semistandard tableaux
of shape `μ` with entries from `1` to `m`. -/
noncomputable def schur (μ : YoungDiagram) (m : ℕ) : MvPolynomial (Fin m) ℤ :=
  ∑ᶠ T : SSYTUpTo μ m, weight T

section Hook

variable (μ : YoungDiagram)

lemma hook_eq {i j : ℕ} (h : (i, j) ∈ μ) :
    hookLength μ (i, j) + 1 = (μ.rowLen i - j) + (μ.colLen j - i) := by
  unfold hookLength
  rw [Finset.filter_or]
  have hI : μ.cells.filter (fun d => d.1 = (i, j).1 ∧ (i, j).2 ≤ d.2) ∩
      μ.cells.filter (fun d => d.2 = (i, j).2 ∧ (i, j).1 ≤ d.1) = {(i, j)} := by
    ext ⟨x, y⟩
    simp only [Finset.mem_inter, Finset.mem_filter, YoungDiagram.mem_cells, Finset.mem_singleton,
      Prod.mk.injEq]
    constructor
    · rintro ⟨⟨_, h1, _⟩, _, h3, _⟩; exact ⟨h1, h3⟩
    · rintro ⟨rfl, rfl⟩; exact ⟨⟨h, rfl, le_rfl⟩, h, rfl, le_rfl⟩
  have hA : (μ.cells.filter (fun d => d.1 = (i, j).1 ∧ (i, j).2 ≤ d.2)).card = μ.rowLen i - j := by
    have : μ.cells.filter (fun d => d.1 = (i, j).1 ∧ (i, j).2 ≤ d.2) =
        (Finset.Ico j (μ.rowLen i)).image (fun j' => (i, j')) := by
      ext ⟨x, y⟩
      simp only [Finset.mem_filter, YoungDiagram.mem_cells, Finset.mem_image, Finset.mem_Ico,
        Prod.mk.injEq]
      constructor
      · rintro ⟨h1, rfl, h2⟩; exact ⟨y, ⟨h2, YoungDiagram.mem_iff_lt_rowLen.1 h1⟩, rfl, rfl⟩
      · rintro ⟨y', ⟨h1, h2⟩, rfl, rfl⟩; exact ⟨YoungDiagram.mem_iff_lt_rowLen.2 h2, rfl, h1⟩
    rw [this, Finset.card_image_of_injective _ (Prod.mk_right_injective i), Nat.card_Ico]
  have hB : (μ.cells.filter (fun d => d.2 = (i, j).2 ∧ (i, j).1 ≤ d.1)).card = μ.colLen j - i := by
    have : μ.cells.filter (fun d => d.2 = (i, j).2 ∧ (i, j).1 ≤ d.1) =
        (Finset.Ico i (μ.colLen j)).image (fun i' => (i', j)) := by
      ext ⟨x, y⟩
      simp only [Finset.mem_filter, YoungDiagram.mem_cells, Finset.mem_image, Finset.mem_Ico,
        Prod.mk.injEq]
      constructor
      · rintro ⟨h1, rfl, h2⟩; exact ⟨x, ⟨h2, YoungDiagram.mem_iff_lt_colLen.1 h1⟩, rfl, rfl⟩
      · rintro ⟨x', ⟨h1, h2⟩, rfl, rfl⟩; exact ⟨YoungDiagram.mem_iff_lt_colLen.2 h2, rfl, h1⟩
    rw [this, Finset.card_image_of_injective _ (Prod.mk_left_injective j), Nat.card_Ico]
  have := Finset.card_union_add_card_inter (μ.cells.filter (fun d => d.1 = (i, j).1 ∧ (i, j).2 ≤ d.2))
    (μ.cells.filter (fun d => d.2 = (i, j).2 ∧ (i, j).1 ≤ d.1))
  rw [hI, Finset.card_singleton, hA, hB] at this
  omega

/-- A corner box: no box to its right and none below it. -/
def IsCorner (c : ℕ × ℕ) : Prop := c ∈ μ ∧ (c.1 + 1, c.2) ∉ μ ∧ (c.1, c.2 + 1) ∉ μ

instance (c : ℕ × ℕ) : Decidable (IsCorner μ c) := by unfold IsCorner; infer_instance

def corners : Finset (ℕ × ℕ) := μ.cells.filter (IsCorner μ)

lemma corner_rowLen {c : ℕ × ℕ} (hc : IsCorner μ c) : μ.rowLen c.1 = c.2 + 1 := by
  have h1 := YoungDiagram.mem_iff_lt_rowLen.1 hc.1
  have h2 := mt YoungDiagram.mem_iff_lt_rowLen.2 hc.2.2
  omega

lemma corner_colLen {c : ℕ × ℕ} (hc : IsCorner μ c) : μ.colLen c.2 = c.1 + 1 := by
  have h1 := YoungDiagram.mem_iff_lt_colLen.1 hc.1
  have h2 := mt YoungDiagram.mem_iff_lt_colLen.2 hc.2.1
  omega

lemma hook_corner {c : ℕ × ℕ} (hc : IsCorner μ c) : hookLength μ c = 1 := by
  obtain ⟨a, b⟩ := c
  have := hook_eq μ hc.1
  rw [corner_rowLen μ hc, corner_colLen μ hc] at this
  omega

def wcol (c : ℕ × ℕ) (i : ℕ) : ℚ := 1 / ((hookLength μ (i, c.2) : ℚ) - 1)

def wrow (c : ℕ × ℕ) (j : ℕ) : ℚ := 1 / ((hookLength μ (c.1, j) : ℚ) - 1)

def hF (w : ℕ → ℚ) (a α : ℕ) : ℚ :=
  if α < a then w α * ∏ i ∈ Finset.Ico (α + 1) a, (1 + w i) else 1

def hq (c s : ℕ × ℕ) : ℚ :=
  if s.1 ≤ c.1 ∧ s.2 ≤ c.2 then hF (wcol μ c) c.1 s.1 * hF (wrow μ c) c.2 s.2 else 0

lemma Icc_succ_eq_Ioc (a b : ℕ) : Finset.Icc (a + 1) b = Finset.Ioc a b := by
  ext x; simp only [Finset.mem_Icc, Finset.mem_Ioc]; omega

lemma hF_tele (w : ℕ → ℚ) (a α : ℕ) (h : α ≤ a) :
    ∑ x ∈ Finset.Icc α a, hF w a x = ∏ i ∈ Finset.Ico α a, (1 + w i) := by
  obtain ⟨d, rfl⟩ : ∃ d, a = α + d := ⟨a - α, by omega⟩
  clear h
  induction d generalizing α with
  | zero => simp [hF]
  | succ d ih =>
    rw [Finset.Icc_eq_cons_Ioc (by omega), Finset.sum_cons, ← Icc_succ_eq_Ioc,
      show α + (d + 1) = (α + 1) + d by omega, ih (α + 1),
      Finset.prod_eq_prod_Ico_succ_bot (show α < α + 1 + d by omega)]
    unfold hF
    rw [if_pos (show α < α + 1 + d by omega)]
    ring

lemma hF_sum_Ioc (w : ℕ → ℚ) (a α : ℕ) (h : α ≤ a) (e : ℚ) (h1 : α < a → w α * e = 1)
    (h2 : α = a → e = 0) : ∑ x ∈ Finset.Ioc α a, hF w a x = hF w a α * e := by
  rcases Nat.lt_or_ge α a with hα | hα
  · rw [← Icc_succ_eq_Ioc, hF_tele w a (α + 1) hα]
    unfold hF
    rw [if_pos hα]
    calc ∏ i ∈ Finset.Ico (α + 1) a, (1 + w i)
        = (w α * e) * ∏ i ∈ Finset.Ico (α + 1) a, (1 + w i) := by rw [h1 hα, one_mul]
      _ = _ := by ring
  · obtain rfl : α = a := by omega
    simp [h2 rfl]

variable {μ}

lemma hook_ge_two_col {c : ℕ × ℕ} (hc : IsCorner μ c) {i : ℕ} (hi : i < c.1) :
    2 ≤ hookLength μ (i, c.2) := by
  have hm : (i, c.2) ∈ μ := μ.up_left_mem hi.le le_rfl hc.1
  have := hook_eq μ hm
  have h3 := YoungDiagram.mem_iff_lt_rowLen.1 hm
  rw [corner_colLen μ hc] at this
  omega

lemma hook_ge_two_row {c : ℕ × ℕ} (hc : IsCorner μ c) {j : ℕ} (hj : j < c.2) :
    2 ≤ hookLength μ (c.1, j) := by
  have hm : (c.1, j) ∈ μ := μ.up_left_mem le_rfl hj.le hc.1
  have := hook_eq μ hm
  have h3 := YoungDiagram.mem_iff_lt_colLen.1 hm
  rw [corner_rowLen μ hc] at this
  omega

lemma wcol_mul {c : ℕ × ℕ} (hc : IsCorner μ c) {i : ℕ} (hi : i < c.1) :
    wcol μ c i * ((hookLength μ (i, c.2) : ℚ) - 1) = 1 := by
  have h2 := hook_ge_two_col hc hi
  have : ((hookLength μ (i, c.2) : ℚ) - 1) ≠ 0 := by
    have : (2 : ℚ) ≤ hookLength μ (i, c.2) := by exact_mod_cast h2
    linarith
  unfold wcol
  field_simp

lemma wrow_mul {c : ℕ × ℕ} (hc : IsCorner μ c) {j : ℕ} (hj : j < c.2) :
    wrow μ c j * ((hookLength μ (c.1, j) : ℚ) - 1) = 1 := by
  have h2 := hook_ge_two_row hc hj
  have : ((hookLength μ (c.1, j) : ℚ) - 1) ≠ 0 := by
    have : (2 : ℚ) ≤ hookLength μ (c.1, j) := by exact_mod_cast h2
    linarith
  unfold wrow
  field_simp

lemma hq_rec {c : ℕ × ℕ} (hc : IsCorner μ c) {s : ℕ × ℕ} (hs : s ∈ μ) :
    ((hookLength μ s : ℚ) - 1) * hq μ c s =
      ∑ x ∈ Finset.Ioo s.1 (μ.colLen s.2), hq μ c (x, s.2) +
        ∑ y ∈ Finset.Ioo s.2 (μ.rowLen s.1), hq μ c (s.1, y) := by
  obtain ⟨α, β⟩ := s
  obtain ⟨a, b⟩ := c
  simp only at *
  by_cases hle : α ≤ a ∧ β ≤ b
  · have m1 : (α, b) ∈ μ := μ.up_left_mem hle.1 le_rfl hc.1
    have m2 : (a, β) ∈ μ := μ.up_left_mem le_rfl hle.2 hc.1
    have l1 := YoungDiagram.mem_iff_lt_rowLen.1 m1
    have l2 := YoungDiagram.mem_iff_lt_colLen.1 m2
    have g := hook_eq μ hs
    have g1 := hook_eq μ m1
    have g2 := hook_eq μ m2
    have r1 := corner_rowLen μ hc
    have r2 := corner_colLen μ hc
    simp only at r1 r2
    have geo : hookLength μ (α, β) + 1 = hookLength μ (α, b) + hookLength μ (a, β) := by omega
    have geoQ : ((hookLength μ (α, β) : ℚ) - 1) =
        ((hookLength μ (α, b) : ℚ) - 1) + ((hookLength μ (a, β) : ℚ) - 1) := by
      have : ((hookLength μ (α, β) + 1 : ℕ) : ℚ) = ((hookLength μ (α, b) + hookLength μ (a, β) : ℕ) : ℚ) := by
        rw [geo]
      push_cast at this
      linarith
    have hcol : ∑ x ∈ Finset.Ioo α (μ.colLen β), hq μ (a, b) (x, β) =
        hF (wrow μ (a, b)) b β * ∑ x ∈ Finset.Ioc α a, hF (wcol μ (a, b)) a x := by
      rw [Finset.mul_sum]
      have : Finset.Ioc α a = (Finset.Ioo α (μ.colLen β)).filter (· ≤ a) := by
        ext x; simp only [Finset.mem_Ioc, Finset.mem_filter, Finset.mem_Ioo]; omega
      rw [this, Finset.sum_filter]
      apply Finset.sum_congr rfl
      intro x _
      unfold hq
      simp only [hle.2, and_true]
      split_ifs <;> ring
    have hrow : ∑ y ∈ Finset.Ioo β (μ.rowLen α), hq μ (a, b) (α, y) =
        hF (wcol μ (a, b)) a α * ∑ y ∈ Finset.Ioc β b, hF (wrow μ (a, b)) b y := by
      rw [Finset.mul_sum]
      have : Finset.Ioc β b = (Finset.Ioo β (μ.rowLen α)).filter (· ≤ b) := by
        ext x; simp only [Finset.mem_Ioc, Finset.mem_filter, Finset.mem_Ioo]; omega
      rw [this, Finset.sum_filter]
      apply Finset.sum_congr rfl
      intro x _
      unfold hq
      simp only [hle.1, true_and]
    rw [hcol, hrow,
      hF_sum_Ioc _ a α hle.1 ((hookLength μ (α, b) : ℚ) - 1) (fun h => wcol_mul hc h)
        (fun h => by subst h; simp [hook_corner μ hc]),
      hF_sum_Ioc _ b β hle.2 ((hookLength μ (a, β) : ℚ) - 1) (fun h => wrow_mul hc h)
        (fun h => by subst h; simp [hook_corner μ hc])]
    unfold hq
    rw [if_pos hle, geoQ]
    ring
  · unfold hq
    rw [if_neg hle, mul_zero]
    symm
    apply add_eq_zero_iff_of_nonneg (Finset.sum_nonneg ?_) (Finset.sum_nonneg ?_) |>.2
    · constructor
      · apply Finset.sum_eq_zero
        intro x hx
        simp only [Finset.mem_Ioo] at hx
        rw [if_neg (by omega)]
      · apply Finset.sum_eq_zero
        intro y hy
        simp only [Finset.mem_Ioo] at hy
        rw [if_neg (by omega)]
    · intro x hx
      simp only [Finset.mem_Ioo] at hx
      rw [if_neg (by omega)]
    · intro y hy
      simp only [Finset.mem_Ioo] at hy
      rw [if_neg (by omega)]

end Hook

section Hook2

variable {μ : YoungDiagram}

lemma corner_of_le {s c : ℕ × ℕ} (hs : IsCorner μ s) (hc : c ∈ μ) (h1 : s.1 ≤ c.1)
    (h2 : s.2 ≤ c.2) : s = c := by
  obtain ⟨a, b⟩ := s
  obtain ⟨x, y⟩ := c
  simp only at *
  have e1 : a = x := by
    by_contra h; exact hs.2.1 (μ.up_left_mem (by simp only; omega) (by simp only; omega) hc)
  have e2 : b = y := by
    by_contra h; exact hs.2.2 (μ.up_left_mem (by simp only; omega) (by simp only; omega) hc)
  rw [e1, e2]

lemma hq_self {c : ℕ × ℕ} : hq μ c c = 1 := by
  unfold hq hF; simp

lemma isCorner_of_hook_le_one {s : ℕ × ℕ} (hs : s ∈ μ) (h : hookLength μ s ≤ 1) : IsCorner μ s := by
  obtain ⟨a, b⟩ := s
  have := hook_eq μ hs
  have h1 := YoungDiagram.mem_iff_lt_rowLen.1 hs
  have h2 := YoungDiagram.mem_iff_lt_colLen.1 hs
  refine ⟨hs, fun h' => ?_, fun h' => ?_⟩
  · have := YoungDiagram.mem_iff_lt_colLen.1 h'; simp only at this; omega
  · have := YoungDiagram.mem_iff_lt_rowLen.1 h'; simp only at this; omega

lemma mem_corners {c : ℕ × ℕ} : c ∈ corners μ ↔ IsCorner μ c := by
  unfold corners
  rw [Finset.mem_filter, YoungDiagram.mem_cells]
  exact ⟨fun h => h.2, fun h => ⟨h.1, h⟩⟩

lemma sum_hq_corners {s : ℕ × ℕ} (hs : s ∈ μ) : ∑ c ∈ corners μ, hq μ c s = 1 := by
  suffices H : ∀ N, ∀ s ∈ μ, hookLength μ s = N → ∑ c ∈ corners μ, hq μ c s = 1 from
    H _ s hs rfl
  intro N
  induction N using Nat.strong_induction_on with
  | _ N ih =>
  intro s hs hN
  by_cases hN1 : N ≤ 1
  · have hsc : IsCorner μ s := isCorner_of_hook_le_one hs (by omega)
    rw [Finset.sum_eq_single_of_mem s (mem_corners.2 hsc)]
    · exact hq_self
    · intro c hc hne
      have hc' := mem_corners.1 hc
      unfold hq
      rw [if_neg]
      intro h
      exact hne (corner_of_le hsc hc'.1 h.1 h.2).symm
  · obtain ⟨α, β⟩ := s
    have hpos : ((hookLength μ (α, β) : ℚ) - 1) ≠ 0 := by
      have : (2 : ℚ) ≤ hookLength μ (α, β) := by exact_mod_cast (by omega : 2 ≤ hookLength μ (α, β))
      linarith
    apply mul_left_cancel₀ hpos
    rw [Finset.mul_sum, mul_one]
    rw [Finset.sum_congr rfl (fun c hc => hq_rec (mem_corners.1 hc) hs)]
    rw [Finset.sum_add_distrib, Finset.sum_comm]
    rw [Finset.sum_comm (s := corners μ) (t := Finset.Ioo (α, β).2 (μ.rowLen (α, β).1))]
    have g := hook_eq μ hs
    have h1 := YoungDiagram.mem_iff_lt_rowLen.1 hs
    have h2 := YoungDiagram.mem_iff_lt_colLen.1 hs
    have A : ∀ x ∈ Finset.Ioo α (μ.colLen β), ∑ c ∈ corners μ, hq μ c (x, β) = 1 := by
      intro x hx
      simp only [Finset.mem_Ioo] at hx
      have hm : (x, β) ∈ μ := YoungDiagram.mem_iff_lt_colLen.2 hx.2
      have gx := hook_eq μ hm
      have := μ.rowLen_anti α x hx.1.le
      exact ih _ (by omega) _ hm rfl
    have B : ∀ y ∈ Finset.Ioo β (μ.rowLen α), ∑ c ∈ corners μ, hq μ c (α, y) = 1 := by
      intro y hy
      simp only [Finset.mem_Ioo] at hy
      have hm : (α, y) ∈ μ := YoungDiagram.mem_iff_lt_rowLen.2 hy.2
      have gy := hook_eq μ hm
      have := μ.colLen_anti β y hy.1.le
      exact ih _ (by omega) _ hm rfl
    simp only at A B ⊢
    rw [Finset.sum_congr rfl A, Finset.sum_congr rfl B]
    simp only [Finset.sum_const, Nat.card_Ioo, nsmul_eq_mul, mul_one]
    have e : (μ.colLen β - α - 1) + (μ.rowLen α - β - 1) + 1 = hookLength μ (α, β) := by omega
    rw [← e]
    push_cast
    ring

lemma sum_hq_cells {c : ℕ × ℕ} (hc : IsCorner μ c) :
    ∑ s ∈ μ.cells, hq μ c s =
      (∏ i ∈ Finset.range c.1, (1 + wcol μ c i)) * ∏ j ∈ Finset.range c.2, (1 + wrow μ c j) := by
  rw [← Finset.sum_subset (s₁ := Finset.Icc 0 c.1 ×ˢ Finset.Icc 0 c.2) (s₂ := μ.cells)]
  · rw [Finset.sum_product, Finset.range_eq_Ico, Finset.range_eq_Ico,
      ← hF_tele _ _ _ (Nat.zero_le _), ← hF_tele _ _ _ (Nat.zero_le _), Finset.sum_mul_sum]
    apply Finset.sum_congr rfl
    intro x hx
    apply Finset.sum_congr rfl
    intro y hy
    simp only [Finset.mem_Icc] at hx hy
    unfold hq
    rw [if_pos ⟨hx.2, hy.2⟩]
  · intro ⟨x, y⟩ h
    simp only [Finset.mem_product, Finset.mem_Icc] at h
    rw [YoungDiagram.mem_cells]
    exact μ.up_left_mem h.1.2 h.2.2 hc.1
  · intro s _ hs
    unfold hq
    rw [if_neg]
    intro h
    apply hs
    simp only [Finset.mem_product, Finset.mem_Icc]
    omega

lemma sum_corners_cells : ∑ c ∈ corners μ, ∑ s ∈ μ.cells, hq μ c s = μ.card := by
  rw [Finset.sum_comm, Finset.sum_congr rfl (fun s hs => sum_hq_corners ((μ.mem_cells s).1 hs))]
  simp

/-- The diagram `μ` with the corner `c` removed. -/
def eraseCorner (μ : YoungDiagram) (c : ℕ × ℕ) (hc : IsCorner μ c) : YoungDiagram where
  cells := μ.cells.erase c
  isLowerSet := by
    intro a b hba ha
    have ha' : a ∈ μ.cells.erase c := ha
    show b ∈ μ.cells.erase c
    rw [Finset.mem_erase] at ha' ⊢
    have hb : b ∈ μ.cells := μ.isLowerSet hba ha'.2
    refine ⟨?_, hb⟩
    rintro rfl
    apply ha'.1
    exact (corner_of_le hc ((μ.mem_cells _).1 ha'.2) hba.1 hba.2).symm

lemma mem_eraseCorner {c : ℕ × ℕ} (hc : IsCorner μ c) {d : ℕ × ℕ} :
    d ∈ eraseCorner μ c hc ↔ d ∈ μ ∧ d ≠ c := by
  rw [← YoungDiagram.mem_cells, ← YoungDiagram.mem_cells]
  show d ∈ μ.cells.erase c ↔ _
  rw [Finset.mem_erase]
  exact and_comm

lemma card_eraseCorner {c : ℕ × ℕ} (hc : IsCorner μ c) :
    (eraseCorner μ c hc).card = μ.card - 1 :=
  Finset.card_erase_of_mem ((μ.mem_cells c).2 hc.1)

lemma hook_eraseCorner {c : ℕ × ℕ} (hc : IsCorner μ c) (d : ℕ × ℕ) :
    hookLength (eraseCorner μ c hc) d = hookLength μ d -
      (if (c.1 = d.1 ∧ d.2 ≤ c.2) ∨ (c.2 = d.2 ∧ d.1 ≤ c.1) then 1 else 0) := by
  unfold hookLength
  show ((μ.cells.erase c).filter _).card = _
  rw [Finset.filter_erase, Finset.card_erase_eq_ite]
  simp only [Finset.mem_filter, YoungDiagram.mem_cells, hc.1, true_and]
  split_ifs <;> simp

lemma hook_pos {d : ℕ × ℕ} (hd : d ∈ μ) : 1 ≤ hookLength μ d := by
  obtain ⟨a, b⟩ := d
  have := hook_eq μ hd
  have h1 := YoungDiagram.mem_iff_lt_rowLen.1 hd
  have h2 := YoungDiagram.mem_iff_lt_colLen.1 hd
  omega

lemma hookProd_eraseCorner {c : ℕ × ℕ} (hc : IsCorner μ c) :
    (∏ d ∈ μ.cells, (hookLength μ d : ℚ)) = (∑ s ∈ μ.cells, hq μ c s) *
      ∏ d ∈ (eraseCorner μ c hc).cells, (hookLength (eraseCorner μ c hc) d : ℚ) := by
  classical
  rw [sum_hq_cells hc]
  show _ = _ * ∏ d ∈ μ.cells.erase c, (hookLength (eraseCorner μ c hc) d : ℚ)
  rw [← Finset.mul_prod_erase μ.cells _ ((μ.mem_cells c).2 hc.1), hook_corner μ hc,
    Nat.cast_one, one_mul]
  set E := μ.cells.erase c
  set Q : ℕ × ℕ → Prop := fun d => (c.1 = d.1 ∧ d.2 ≤ c.2) ∨ (c.2 = d.2 ∧ d.1 ≤ c.1)
  rw [← Finset.prod_filter_mul_prod_filter_not E Q,
    ← Finset.prod_filter_mul_prod_filter_not E Q (f := fun d => (hookLength (eraseCorner μ c hc) d : ℚ))]
  have hnot : ∏ d ∈ E.filter (fun d => ¬ Q d), (hookLength (eraseCorner μ c hc) d : ℚ) =
      ∏ d ∈ E.filter (fun d => ¬ Q d), (hookLength μ d : ℚ) := by
    apply Finset.prod_congr rfl
    intro d hd
    rw [hook_eraseCorner hc, if_neg (Finset.mem_filter.1 hd).2, Nat.sub_zero]
  rw [hnot, ← mul_assoc]
  congr 1
  obtain ⟨a, b⟩ := c
  have hEQ : E.filter Q = (Finset.range a).image (fun i => (i, b)) ∪
      (Finset.range b).image (fun j => (a, j)) := by
    ext ⟨x, y⟩
    simp only [E, Q, Finset.mem_filter, Finset.mem_erase, YoungDiagram.mem_cells, Finset.mem_union,
      Finset.mem_image, Finset.mem_range, Prod.mk.injEq, ne_eq]
    constructor
    · rintro ⟨⟨hne, hm⟩, h⟩
      rcases h with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · right; exact ⟨y, by omega, h1, rfl⟩
      · left; exact ⟨x, by omega, rfl, h1⟩
    · rintro (⟨i, hi, rfl, rfl⟩ | ⟨j, hj, rfl, rfl⟩)
      · exact ⟨⟨by omega, μ.up_left_mem hi.le le_rfl hc.1⟩, Or.inr ⟨rfl, hi.le⟩⟩
      · exact ⟨⟨by omega, μ.up_left_mem le_rfl hj.le hc.1⟩, Or.inl ⟨rfl, hj.le⟩⟩
  have hdisj : Disjoint ((Finset.range a).image (fun i => (i, b)))
      ((Finset.range b).image (fun j => (a, j))) := by
    rw [Finset.disjoint_left]
    intro p hp hp'
    simp only [Finset.mem_image, Finset.mem_range] at hp hp'
    obtain ⟨i, hi, rfl⟩ := hp
    obtain ⟨j, hj, hji⟩ := hp'
    simp only [Prod.mk.injEq] at hji
    omega
  rw [hEQ, Finset.prod_union hdisj, Finset.prod_union hdisj,
    Finset.prod_image (fun i _ j _ h => (Prod.mk.inj h).1),
    Finset.prod_image (fun i _ j _ h => (Prod.mk.inj h).2),
    Finset.prod_image (fun i _ j _ h => (Prod.mk.inj h).1),
    Finset.prod_image (fun i _ j _ h => (Prod.mk.inj h).2)]
  have hc1 : ∀ i ∈ Finset.range a, (hookLength μ (i, b) : ℚ) =
      (1 + wcol μ (a, b) i) * (hookLength (eraseCorner μ (a, b) hc) (i, b) : ℚ) := by
    intro i hi
    rw [Finset.mem_range] at hi
    have h2 := hook_ge_two_col hc hi
    simp only at h2
    have hw := wcol_mul hc hi
    rw [hook_eraseCorner hc, if_pos (Or.inr ⟨rfl, hi.le⟩), Nat.cast_sub (by omega)]
    simp only at hw ⊢
    push_cast
    linear_combination -hw
  have hc2 : ∀ j ∈ Finset.range b, (hookLength μ (a, j) : ℚ) =
      (1 + wrow μ (a, b) j) * (hookLength (eraseCorner μ (a, b) hc) (a, j) : ℚ) := by
    intro j hj
    rw [Finset.mem_range] at hj
    have h2 := hook_ge_two_row hc hj
    simp only at h2
    have hw := wrow_mul hc hj
    rw [hook_eraseCorner hc, if_pos (Or.inl ⟨rfl, hj.le⟩), Nat.cast_sub (by omega)]
    simp only at hw ⊢
    push_cast
    linear_combination -hw
  rw [Finset.prod_congr rfl hc1, Finset.prod_congr rfl hc2, Finset.prod_mul_distrib,
    Finset.prod_mul_distrib]
  ring

end Hook2
instance finiteSSYTUpTo (μ : YoungDiagram) (m : ℕ) : Finite (SSYTUpTo μ m) := by
  refine Finite.of_injective (fun T : SSYTUpTo μ m => fun c : μ.cells =>
    (⟨T.1 c.1.1 c.1.2, Nat.lt_succ_of_le (T.2 c.1 ((μ.mem_cells _).1 c.2)).2⟩ : Fin (m+1))) ?_
  intro T T' h
  apply Subtype.ext
  ext i j
  by_cases hc : (i, j) ∈ μ
  · have := congrArg Fin.val (congrFun h ⟨(i, j), (μ.mem_cells _).2 hc⟩)
    simpa using this
  · rw [T.1.zeros hc, T'.1.zeros hc]

instance finiteSYT (μ : YoungDiagram) : Finite (StandardYoungTableau μ) :=
  Finite.of_injective (β := SSYTUpTo μ μ.card)
    (fun T : StandardYoungTableau μ => ⟨T.1, fun _ hc => T.2.mapsTo hc⟩)
    (fun _ _ h => Subtype.ext (congrArg (fun S : SSYTUpTo μ μ.card => S.1) h))

section Hook3

variable {μ : YoungDiagram}

/-- Remove the corner box `c` from a tableau. -/
def restrictTab {c : ℕ × ℕ} (hc : IsCorner μ c) (T : SemistandardYoungTableau μ) :
    SemistandardYoungTableau (eraseCorner μ c hc) where
  entry i j := if (i, j) = c then 0 else T i j
  row_weak' := by
    intro i j1 j2 hj hcell
    rw [mem_eraseCorner] at hcell
    have hne : (i, j1) ≠ c := by
      rintro rfl
      exact hc.2.2 (μ.up_left_mem le_rfl (by simp only; omega) hcell.1)
    simp only [if_neg hne, if_neg hcell.2]
    exact T.row_weak hj hcell.1
  col_strict' := by
    intro i1 i2 j hi hcell
    rw [mem_eraseCorner] at hcell
    have hne : (i1, j) ≠ c := by
      rintro rfl
      exact hc.2.1 (μ.up_left_mem (by simp only; omega) le_rfl hcell.1)
    simp only [if_neg hne, if_neg hcell.2]
    exact T.col_strict hi hcell.1
  zeros' := by
    intro i j h
    rw [mem_eraseCorner] at h
    split_ifs with h'
    · rfl
    · exact T.zeros (fun hm => h ⟨hm, h'⟩)

/-- Put the value `v` in the corner box `c`. -/
def extendTab {c : ℕ × ℕ} (hc : IsCorner μ c) (T' : SemistandardYoungTableau (eraseCorner μ c hc))
    (v : ℕ) (hv : ∀ d ∈ eraseCorner μ c hc, T' d.1 d.2 < v) : SemistandardYoungTableau μ where
  entry i j := if (i, j) = c then v else T' i j
  row_weak' := by
    intro i j1 j2 hj hcell
    have hne : (i, j1) ≠ c := by
      rintro rfl
      exact hc.2.2 (μ.up_left_mem le_rfl (by simp only; omega) hcell)
    simp only [if_neg hne]
    split_ifs with h2
    · exact (hv (i, j1) ((mem_eraseCorner hc).2 ⟨μ.up_left_mem le_rfl hj.le hcell, hne⟩)).le
    · exact T'.row_weak hj ((mem_eraseCorner hc).2 ⟨hcell, h2⟩)
  col_strict' := by
    intro i1 i2 j hi hcell
    have hne : (i1, j) ≠ c := by
      rintro rfl
      exact hc.2.1 (μ.up_left_mem (by simp only; omega) le_rfl hcell)
    simp only [if_neg hne]
    split_ifs with h2
    · exact hv (i1, j) ((mem_eraseCorner hc).2 ⟨μ.up_left_mem hi.le le_rfl hcell, hne⟩)
    · exact T'.col_strict hi ((mem_eraseCorner hc).2 ⟨hcell, h2⟩)
  zeros' := by
    intro i j h
    have hne : (i, j) ≠ c := by
      rintro rfl
      exact h hc.1
    simp only [if_neg hne]
    exact T'.zeros (fun hm => h ((mem_eraseCorner hc).1 hm).1)

lemma restrictTab_apply {c : ℕ × ℕ} (hc : IsCorner μ c) (T : SemistandardYoungTableau μ)
    {d : ℕ × ℕ} (hd : d ≠ c) : restrictTab hc T d.1 d.2 = T d.1 d.2 := by
  show (if (d.1, d.2) = c then 0 else T d.1 d.2) = _
  rw [if_neg (by simpa using hd)]

lemma extendTab_apply {c : ℕ × ℕ} (hc : IsCorner μ c)
    (T' : SemistandardYoungTableau (eraseCorner μ c hc)) (v : ℕ) (hv) {d : ℕ × ℕ} :
    extendTab hc T' v hv d.1 d.2 = if d = c then v else T' d.1 d.2 := by
  show (if (d.1, d.2) = c then v else T' d.1 d.2) = _
  simp

lemma restrict_bij {c : ℕ × ℕ} (hc : IsCorner μ c) (T : SemistandardYoungTableau μ)
    (hB : Set.BijOn (fun d : ℕ × ℕ => T d.1 d.2) (μ : Set (ℕ × ℕ)) (Set.Icc 1 μ.card))
    (hT : T c.1 c.2 = μ.card) :
    Set.BijOn (fun d : ℕ × ℕ => restrictTab hc T d.1 d.2) (eraseCorner μ c hc : Set (ℕ × ℕ))
      (Set.Icc 1 (eraseCorner μ c hc).card) := by
  rw [card_eraseCorner]
  refine ⟨?_, ?_, ?_⟩
  · intro d hd
    have hd' := (mem_eraseCorner hc).1 hd
    show restrictTab hc T d.1 d.2 ∈ _
    rw [restrictTab_apply hc T hd'.2]
    have h1 := hB.mapsTo (show d ∈ (μ : Set (ℕ × ℕ)) from hd'.1)
    have h2 : T d.1 d.2 ≠ μ.card := by
      intro h
      exact hd'.2 (hB.injOn (show d ∈ (μ : Set (ℕ × ℕ)) from hd'.1)
        (show c ∈ (μ : Set (ℕ × ℕ)) from hc.1) (show T d.1 d.2 = T c.1 c.2 by rw [h, hT]))
    simp only [Set.mem_Icc] at h1 ⊢
    omega
  · intro d1 h1 d2 h2 heq
    have h1' := (mem_eraseCorner hc).1 h1
    have h2' := (mem_eraseCorner hc).1 h2
    change restrictTab hc T d1.1 d1.2 = restrictTab hc T d2.1 d2.2 at heq
    rw [restrictTab_apply hc T h1'.2, restrictTab_apply hc T h2'.2] at heq
    exact hB.injOn (show d1 ∈ (μ : Set (ℕ × ℕ)) from h1'.1)
      (show d2 ∈ (μ : Set (ℕ × ℕ)) from h2'.1) heq
  · intro w hw
    simp only [Set.mem_Icc] at hw
    obtain ⟨d, hd, hdw⟩ := hB.surjOn (show w ∈ Set.Icc 1 μ.card by
      simp only [Set.mem_Icc]; omega)
    change T d.1 d.2 = w at hdw
    have hne : d ≠ c := by
      rintro rfl
      omega
    refine ⟨d, (mem_eraseCorner hc).2 ⟨hd, hne⟩, ?_⟩
    show restrictTab hc T d.1 d.2 = w
    rw [restrictTab_apply hc T hne]
    exact hdw

lemma extend_lt {c : ℕ × ℕ} (hc : IsCorner μ c) (T' : SemistandardYoungTableau (eraseCorner μ c hc))
    (hB : Set.BijOn (fun d : ℕ × ℕ => T' d.1 d.2) (eraseCorner μ c hc : Set (ℕ × ℕ))
      (Set.Icc 1 (eraseCorner μ c hc).card))
    (hn : 1 ≤ μ.card) : ∀ d ∈ eraseCorner μ c hc, T' d.1 d.2 < μ.card := by
  intro d hd
  have := hB.mapsTo (show d ∈ (eraseCorner μ c hc : Set (ℕ × ℕ)) from hd)
  rw [card_eraseCorner] at this
  simp only [Set.mem_Icc] at this
  omega

lemma extend_bij {c : ℕ × ℕ} (hc : IsCorner μ c) (T' : SemistandardYoungTableau (eraseCorner μ c hc))
    (hB : Set.BijOn (fun d : ℕ × ℕ => T' d.1 d.2) (eraseCorner μ c hc : Set (ℕ × ℕ))
      (Set.Icc 1 (eraseCorner μ c hc).card))
    (hn : 1 ≤ μ.card) :
    Set.BijOn (fun d : ℕ × ℕ => extendTab hc T' μ.card (extend_lt hc T' hB hn) d.1 d.2)
      (μ : Set (ℕ × ℕ)) (Set.Icc 1 μ.card) := by
  have hlt := extend_lt hc T' hB hn
  rw [card_eraseCorner] at hB
  refine ⟨?_, ?_, ?_⟩
  · intro d hd
    simp only [extendTab_apply]
    split_ifs with h
    · simp only [Set.mem_Icc]; omega
    · have := hB.mapsTo (show d ∈ (eraseCorner μ c hc : Set (ℕ × ℕ)) from
        (mem_eraseCorner hc).2 ⟨hd, h⟩)
      simp only [Set.mem_Icc] at this ⊢
      omega
  · intro d1 h1 d2 h2 heq
    simp only [extendTab_apply] at heq
    have m1 : d1 ≠ c → T' d1.1 d1.2 < μ.card := fun h =>
      hlt d1 ((mem_eraseCorner hc).2 ⟨h1, h⟩)
    have m2 : d2 ≠ c → T' d2.1 d2.2 < μ.card := fun h =>
      hlt d2 ((mem_eraseCorner hc).2 ⟨h2, h⟩)
    split_ifs at heq with e1 e2 e2
    · rw [e1, e2]
    · exact absurd heq (by have := m2 e2; omega)
    · exact absurd heq (by have := m1 e1; omega)
    · exact hB.injOn (show d1 ∈ (eraseCorner μ c hc : Set (ℕ × ℕ)) from
        (mem_eraseCorner hc).2 ⟨h1, e1⟩) (show d2 ∈ (eraseCorner μ c hc : Set (ℕ × ℕ)) from
        (mem_eraseCorner hc).2 ⟨h2, e2⟩) heq
  · intro w hw
    simp only [Set.mem_Icc] at hw
    by_cases hwn : w = μ.card
    · refine ⟨c, hc.1, ?_⟩
      simp only [extendTab_apply, if_pos rfl]
      exact hwn.symm
    · obtain ⟨d, hd, hdw⟩ := hB.surjOn (show w ∈ Set.Icc 1 (μ.card - 1) by
        simp only [Set.mem_Icc]; omega)
      have hd' := (mem_eraseCorner hc).1 hd
      refine ⟨d, hd'.1, ?_⟩
      simp only [extendTab_apply, if_neg hd'.2]
      exact hdw

/-- Tableaux with the largest entry in the corner `c` match tableaux of `μ` without `c`. -/
def sytFiberEquiv {c : ℕ × ℕ} (hc : IsCorner μ c) (hn : 1 ≤ μ.card) :
    {T : StandardYoungTableau μ // T.1 c.1 c.2 = μ.card} ≃
      StandardYoungTableau (eraseCorner μ c hc) where
  toFun T := ⟨restrictTab hc T.1.1, restrict_bij hc T.1.1 T.1.2 T.2⟩
  invFun T' := ⟨⟨extendTab hc T'.1 μ.card (extend_lt hc T'.1 T'.2 hn),
    extend_bij hc T'.1 T'.2 hn⟩, by
    show (if (c.1, c.2) = c then μ.card else T'.1 c.1 c.2) = μ.card
    rw [if_pos rfl]⟩
  left_inv T := by
    apply Subtype.ext; apply Subtype.ext
    apply SemistandardYoungTableau.ext
    intro i j
    show (if (i, j) = c then μ.card else (if (i, j) = c then 0 else T.1.1 i j)) = T.1.1 i j
    split_ifs with h
    · obtain rfl := h
      exact T.2.symm
    · rfl
  right_inv T' := by
    apply Subtype.ext
    apply SemistandardYoungTableau.ext
    intro i j
    show (if (i, j) = c then 0 else (if (i, j) = c then μ.card else T'.1 i j)) = T'.1 i j
    split_ifs with h
    · symm
      apply T'.1.zeros
      intro hm
      exact ((mem_eraseCorner hc).1 hm).2 h
    · rfl

lemma exists_corner_max (T : SemistandardYoungTableau μ)
    (hB : Set.BijOn (fun d : ℕ × ℕ => T d.1 d.2) (μ : Set (ℕ × ℕ)) (Set.Icc 1 μ.card))
    (hn : 1 ≤ μ.card) : ∃ d ∈ corners μ, T d.1 d.2 = μ.card := by
  obtain ⟨d, hd, hdn⟩ := hB.surjOn (show μ.card ∈ Set.Icc 1 μ.card by
    simp only [Set.mem_Icc]; omega)
  change T d.1 d.2 = μ.card at hdn
  refine ⟨d, mem_corners.2 ⟨hd, fun h => ?_, fun h => ?_⟩, hdn⟩
  · have h1 := T.col_strict (Nat.lt_add_one d.1) h
    have h2 := hB.mapsTo (show (d.1 + 1, d.2) ∈ (μ : Set (ℕ × ℕ)) from h)
    change T (d.1 + 1) d.2 ∈ Set.Icc 1 μ.card at h2
    simp only [Set.mem_Icc] at h2
    omega
  · have h1 := T.row_weak (Nat.lt_add_one d.2) h
    have h2 := hB.mapsTo (show (d.1, d.2 + 1) ∈ (μ : Set (ℕ × ℕ)) from h)
    change T d.1 (d.2 + 1) ∈ Set.Icc 1 μ.card at h2
    simp only [Set.mem_Icc] at h2
    have := hB.injOn (show (d.1, d.2 + 1) ∈ (μ : Set (ℕ × ℕ)) from h) hd
      (show T d.1 (d.2 + 1) = T d.1 d.2 by omega)
    rw [Prod.ext_iff] at this
    simp at this

lemma corner_unique (T : SemistandardYoungTableau μ)
    (hB : Set.BijOn (fun d : ℕ × ℕ => T d.1 d.2) (μ : Set (ℕ × ℕ)) (Set.Icc 1 μ.card))
    {c1 c2 : ℕ × ℕ} (h1 : c1 ∈ μ) (h2 : c2 ∈ μ) (e1 : T c1.1 c1.2 = μ.card)
    (e2 : T c2.1 c2.2 = μ.card) : c1 = c2 :=
  hB.injOn (show c1 ∈ (μ : Set (ℕ × ℕ)) from h1) (show c2 ∈ (μ : Set (ℕ × ℕ)) from h2)
    (show T c1.1 c1.2 = T c2.1 c2.2 by rw [e1, e2])

lemma card_syt_rec (hn : 1 ≤ μ.card) :
    Nat.card (StandardYoungTableau μ) =
      ∑ c ∈ corners μ, Nat.card {T : StandardYoungTableau μ // T.1 c.1 c.2 = μ.card} := by
  classical
  letI : Fintype (StandardYoungTableau μ) := Fintype.ofFinite _
  have huniv : (Finset.univ : Finset (StandardYoungTableau μ)) = (corners μ).biUnion
      (fun c => Finset.univ.filter (fun T : StandardYoungTableau μ => T.1 c.1 c.2 = μ.card)) := by
    ext T
    rw [Finset.mem_biUnion]
    simp only [Finset.mem_univ, true_iff]
    obtain ⟨d, hd, hdn⟩ := exists_corner_max T.1 T.2 hn
    exact ⟨d, hd, Finset.mem_filter.2 ⟨Finset.mem_univ _, hdn⟩⟩
  rw [Nat.card_eq_fintype_card, ← Finset.card_univ, huniv, Finset.card_biUnion]
  · apply Finset.sum_congr rfl
    intro c _
    rw [Nat.card_eq_fintype_card, Fintype.card_subtype]
  · intro c1 hc1 c2 hc2 hne
    rw [Function.onFun, Finset.disjoint_left]
    intro T h1 h2
    apply hne
    exact corner_unique T.1 T.2 (mem_corners.1 hc1).1 (mem_corners.1 hc2).1
      (Finset.mem_filter.1 h1).2 (Finset.mem_filter.1 h2).2

lemma card_syt_empty (hcells : μ.cells = ∅) : Nat.card (StandardYoungTableau μ) = 1 := by
  rw [Nat.card_eq_one_iff_unique]
  have hnot : ∀ d, d ∉ μ := fun d hd => by
    rw [← YoungDiagram.mem_cells, hcells] at hd; simp at hd
  have hcard : μ.card = 0 := by simp [YoungDiagram.card, hcells]
  refine ⟨⟨fun T T' => Subtype.ext (SemistandardYoungTableau.ext fun i j => by
    rw [T.1.zeros (hnot _), T'.1.zeros (hnot _)])⟩, ⟨⟨SemistandardYoungTableau.highestWeight μ, ?_⟩⟩⟩
  refine ⟨fun d hd => absurd hd (hnot d), fun d hd => absurd hd (hnot d), fun w hw => ?_⟩
  rw [hcard] at hw
  simp only [Set.mem_Icc] at hw
  omega

lemma hookProd_ne_zero (μ : YoungDiagram) : ∏ d ∈ μ.cells, (hookLength μ d : ℚ) ≠ 0 := by
  rw [Finset.prod_ne_zero_iff]
  intro d hd
  have := hook_pos ((μ.mem_cells d).1 hd)
  exact Nat.cast_ne_zero.2 (by omega)

end Hook3

section BK

variable {μ : YoungDiagram}

/-- A cell of `T` holding `k` with `k + 1` below it, or `k + 1` with `k` above it. -/
def bkBound (T : SemistandardYoungTableau μ) (k i j : ℕ) : Prop :=
  (T i j = k ∧ T (i + 1) j = k + 1) ∨ (T i j = k + 1 ∧ 0 < i ∧ T (i - 1) j = k)

instance (T : SemistandardYoungTableau μ) (k i j : ℕ) : Decidable (bkBound T k i j) := by
  unfold bkBound; infer_instance

/-- A free cell: it holds `k` or `k + 1` and is not bound. -/
def bkFree (T : SemistandardYoungTableau μ) (k i j : ℕ) : Prop :=
  (T i j = k ∨ T i j = k + 1) ∧ ¬ bkBound T k i j

instance (T : SemistandardYoungTableau μ) (k i j : ℕ) : Decidable (bkFree T k i j) := by
  unfold bkFree; infer_instance

def bkRank (T : SemistandardYoungTableau μ) (k i j : ℕ) : ℕ :=
  ((Finset.range j).filter (fun j' => bkFree T k i j')).card

def bkRow (T : SemistandardYoungTableau μ) (k i : ℕ) : Finset ℕ :=
  (Finset.range (μ.rowLen i)).filter (fun j => bkFree T k i j)

def bkS (T : SemistandardYoungTableau μ) (k i : ℕ) : ℕ :=
  ((bkRow T k i).filter (fun j => T i j = k + 1)).card

def bkEntry (T : SemistandardYoungTableau μ) (k i j : ℕ) : ℕ :=
  if bkFree T k i j then (if bkRank T k i j < bkS T k i then k else k + 1) else T i j

lemma ssyt_mem_of_pos (T : SemistandardYoungTableau μ) {i j : ℕ} (h : 0 < T i j) : (i, j) ∈ μ := by
  by_contra hc; rw [T.zeros hc] at h; exact lt_irrefl _ h

lemma bkFree_mem (T : SemistandardYoungTableau μ) {k i j : ℕ} (hk : 0 < k)
    (h : bkFree T k i j) : (i, j) ∈ μ :=
  ssyt_mem_of_pos T (by unfold bkFree at h; omega)

lemma bkEntry_not_free (T : SemistandardYoungTableau μ) {k i j : ℕ} (h : ¬ bkFree T k i j) :
    bkEntry T k i j = T i j := by
  simp [bkEntry, h]

lemma bkRank_lt (T : SemistandardYoungTableau μ) {k i j1 j2 : ℕ} (h1 : bkFree T k i j1)
    (hj : j1 < j2) : bkRank T k i j1 < bkRank T k i j2 := by
  unfold bkRank
  apply Finset.card_lt_card
  rw [Finset.ssubset_iff_of_subset]
  · exact ⟨j1, by simp [h1, hj], by simp⟩
  · intro x; simp only [Finset.mem_filter, Finset.mem_range]; intro h; exact ⟨by omega, h.2⟩

lemma bk_row_weak (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) {i j1 j2 : ℕ}
    (hj : j1 < j2) (hc : (i, j2) ∈ μ) : bkEntry T k i j1 ≤ bkEntry T k i j2 := by
  have hrw := T.row_weak hj hc
  have b1 : T (i + 1) j2 = k + 1 → T (i + 1) j1 ≤ T (i + 1) j2 ∧ T i j1 < T (i + 1) j1 := by
    intro h
    have hm : (i + 1, j2) ∈ μ := ssyt_mem_of_pos T (by omega)
    exact ⟨T.row_weak hj hm, T.col_strict (Nat.lt_add_one i) (μ.up_left_mem le_rfl hj.le hm)⟩
  have b2 : 0 < i → T (i - 1) j1 ≤ T (i - 1) j2 ∧ T (i - 1) j2 < T i j2 := fun h =>
    ⟨T.row_weak hj (μ.up_left_mem (Nat.sub_le _ _) le_rfl hc), T.col_strict (by omega) hc⟩
  by_cases f1 : bkFree T k i j1
  · have r := bkRank_lt T f1 hj
    unfold bkEntry
    split_ifs <;> (unfold bkFree bkBound at *; omega)
  · unfold bkEntry
    split_ifs <;> (unfold bkFree bkBound at *; omega)

lemma bk_col_strict (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) {i1 i2 j : ℕ}
    (hi : i1 < i2) (hc : (i2, j) ∈ μ) : bkEntry T k i1 j < bkEntry T k i2 j := by
  have hcs := T.col_strict hi hc
  rcases Nat.lt_or_ge (i1 + 1) i2 with h | h
  · have m1 : (i1 + 1, j) ∈ μ := μ.up_left_mem h.le le_rfl hc
    have a1 := T.col_strict (Nat.lt_add_one i1) m1
    have a2 := T.col_strict h hc
    have m2 : (i2 - 1, j) ∈ μ := μ.up_left_mem (Nat.sub_le _ _) le_rfl hc
    have a3 := T.col_strict (show i1 < i2 - 1 by omega) m2
    unfold bkEntry
    split_ifs <;> (unfold bkFree bkBound at *; omega)
  · obtain rfl : i2 = i1 + 1 := by omega
    unfold bkEntry
    split_ifs <;> (unfold bkFree bkBound at *; simp only [Nat.add_sub_cancel] at *; omega)

/-- The Bender–Knuth move on entries `k` and `k + 1`. -/
def bkTab (T : SemistandardYoungTableau μ) (k : ℕ) (hk : 0 < k) : SemistandardYoungTableau μ where
  entry := bkEntry T k
  row_weak' := fun hj hc => bk_row_weak T hk hj hc
  col_strict' := fun hi hc => bk_col_strict T hk hi hc
  zeros' := fun {i j} h => by
    rw [bkEntry_not_free T (fun hf => h (bkFree_mem T hk hf))]; exact T.zeros h

lemma bkTab_apply (T : SemistandardYoungTableau μ) (k : ℕ) (hk : 0 < k) (i j : ℕ) :
    bkTab T k hk i j = bkEntry T k i j := rfl

lemma bkFree_bkTab (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) (i j : ℕ) :
    bkFree (bkTab T k hk) k i j ↔ bkFree T k i j := by
  simp only [bkFree, bkBound, bkTab_apply]
  by_cases f : bkFree T k i j
  · have hm := bkFree_mem T hk f
    have e0 : bkEntry T k i j = k ∨ bkEntry T k i j = k + 1 := by
      unfold bkEntry; split_ifs <;> simp
    have c1 : T (i + 1) j ≠ 0 → T i j < T (i + 1) j := fun h =>
      T.col_strict (Nat.lt_add_one i) (ssyt_mem_of_pos T (Nat.pos_of_ne_zero h))
    have c2 : 0 < i → T (i - 1) j < T i j := fun h => T.col_strict (by omega) hm
    have E1 : (T (i + 1) j = k ∨ T (i + 1) j = k + 1) ∨
        bkEntry T k (i + 1) j = T (i + 1) j := by
      by_cases fa : bkFree T k (i + 1) j
      · exact Or.inl fa.1
      · exact Or.inr (bkEntry_not_free T fa)
    have E2 : (T (i - 1) j = k ∨ T (i - 1) j = k + 1) ∨
        bkEntry T k (i - 1) j = T (i - 1) j := by
      by_cases fa : bkFree T k (i - 1) j
      · exact Or.inl fa.1
      · exact Or.inr (bkEntry_not_free T fa)
    unfold bkFree bkBound at f
    refine iff_of_true ⟨e0, ?_⟩ f
    omega
  · have g := f
    unfold bkFree bkBound at f
    refine iff_of_false ?_ f
    rw [bkEntry_not_free T g]
    intro ⟨h1, h2⟩
    apply h2
    have hb : (T i j = k ∧ T (i + 1) j = k + 1) ∨ (T i j = k + 1 ∧ 0 < i ∧ T (i - 1) j = k) := by
      tauto
    rcases hb with ⟨ha, hb⟩ | ⟨ha, hi, hb⟩
    · left
      have : ¬ bkFree T k (i + 1) j := by
        unfold bkFree bkBound; simp only [Nat.add_sub_cancel]; omega
      rw [bkEntry_not_free T this]; exact ⟨ha, hb⟩
    · right
      have : ¬ bkFree T k (i - 1) j := by
        unfold bkFree bkBound; rw [Nat.sub_add_cancel hi]; omega
      rw [bkEntry_not_free T this]; exact ⟨ha, hi, hb⟩

lemma card_filter_rank (F : Finset ℕ) (s : ℕ) :
    (F.filter (fun j => (F.filter (· < j)).card < s)).card = min s F.card := by
  induction F using Finset.induction_on_max with
  | empty => simp
  | insert a G hlt ih =>
    have ha : a ∉ G := fun h => lt_irrefl a (hlt a h)
    rw [Finset.filter_insert, Finset.card_insert_of_notMem ha]
    have e1 : (insert a G).filter (· < a) = G := by
      ext x; simp only [Finset.mem_filter, Finset.mem_insert]; constructor
      · rintro ⟨h | h, hx⟩
        · exact absurd hx (h ▸ lt_irrefl a)
        · exact h
      · intro h; exact ⟨Or.inr h, hlt x h⟩
    have e2 : G.filter (fun j => ((insert a G).filter (· < j)).card < s) =
        G.filter (fun j => (G.filter (· < j)).card < s) := by
      apply Finset.filter_congr; intro x hx
      rw [Finset.filter_insert, if_neg (not_lt.2 (hlt x hx).le)]
    rw [e1, e2]
    split_ifs with h
    · rw [Finset.card_insert_of_notMem (fun h' => ha (Finset.mem_filter.1 h').1), ih]; omega
    · rw [ih]; omega

lemma bkRank_eq (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) (i j : ℕ) :
    bkRank T k i j = ((bkRow T k i).filter (· < j)).card := by
  unfold bkRank bkRow
  congr 1
  ext x
  simp only [Finset.mem_filter, Finset.mem_range]
  constructor
  · intro h; exact ⟨⟨YoungDiagram.mem_iff_lt_rowLen.1 (bkFree_mem T hk h.2), h.2⟩, h.1⟩
  · intro h; exact ⟨h.2, h.1.2⟩

lemma bkRow_bkTab (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) (i : ℕ) :
    bkRow (bkTab T k hk) k i = bkRow T k i := by
  unfold bkRow
  exact Finset.filter_congr (fun j _ => bkFree_bkTab T hk i j)

lemma bkRank_bkTab (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) (i j : ℕ) :
    bkRank (bkTab T k hk) k i j = bkRank T k i j := by
  unfold bkRank
  rw [Finset.filter_congr (fun j _ => bkFree_bkTab T hk i j)]

lemma card_rank_lt_bkS (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) (i : ℕ) :
    ((bkRow T k i).filter (fun j => bkRank T k i j < bkS T k i)).card = bkS T k i := by
  simp_rw [bkRank_eq T hk]
  rw [card_filter_rank]
  exact min_eq_left (Finset.card_filter_le _ _)

lemma bkS_bkTab (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) (i : ℕ) :
    bkS (bkTab T k hk) k i = (bkRow T k i).card - bkS T k i := by
  have h := Finset.card_filter_add_card_filter_not (s := bkRow T k i)
    (fun j => bkRank T k i j < bkS T k i)
  rw [card_rank_lt_bkS T hk] at h
  have e : bkS (bkTab T k hk) k i =
      ((bkRow T k i).filter (fun j => ¬ bkRank T k i j < bkS T k i)).card := by
    show ((bkRow (bkTab T k hk) k i).filter (fun j => bkTab T k hk i j = k + 1)).card = _
    rw [bkRow_bkTab]
    congr 1
    apply Finset.filter_congr
    intro j hj
    have f : bkFree T k i j := (Finset.mem_filter.1 hj).2
    rw [bkTab_apply]
    unfold bkEntry
    rw [if_pos f]
    split_ifs with h' <;> simp [h']
  omega

lemma free_val_iff (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) {i j : ℕ}
    (f : bkFree T k i j) :
    T i j = k ↔ bkRank T k i j < ((bkRow T k i).filter (fun j => T i j = k)).card := by
  have hm := bkFree_mem T hk f
  constructor
  · intro hv
    unfold bkRank
    refine lt_of_le_of_lt (Finset.card_le_card (t := ((bkRow T k i).filter
      (fun j => T i j = k)).erase j) ?_) (Finset.card_erase_lt_of_mem ?_)
    · intro x hx
      simp only [Finset.mem_filter, Finset.mem_range] at hx
      have := T.row_weak hx.1 hm
      have fx := hx.2
      unfold bkFree at fx
      simp only [bkRow, Finset.mem_erase, Finset.mem_filter, Finset.mem_range]
      exact ⟨by omega, ⟨YoungDiagram.mem_iff_lt_rowLen.1 (bkFree_mem T hk hx.2), hx.2⟩, by omega⟩
    · simp only [bkRow, Finset.mem_filter, Finset.mem_range]
      exact ⟨⟨YoungDiagram.mem_iff_lt_rowLen.1 hm, f⟩, hv⟩
  · intro h
    by_contra hv
    have hv' : T i j = k + 1 := by have := f.1; omega
    apply absurd h
    rw [not_lt]
    unfold bkRank
    apply Finset.card_le_card
    intro x hx
    simp only [bkRow, Finset.mem_filter, Finset.mem_range] at hx
    simp only [Finset.mem_filter, Finset.mem_range]
    refine ⟨?_, hx.1.2⟩
    by_contra hxj
    have := T.row_weak_of_le (not_lt.1 hxj) (YoungDiagram.mem_iff_lt_rowLen.2 hx.1.1)
    omega

lemma card_T_k (T : SemistandardYoungTableau μ) (k i : ℕ) :
    ((bkRow T k i).filter (fun j => T i j = k)).card = (bkRow T k i).card - bkS T k i := by
  have h := Finset.card_filter_add_card_filter_not (s := bkRow T k i) (fun j => T i j = k)
  have e : (bkRow T k i).filter (fun j => ¬ T i j = k) =
      (bkRow T k i).filter (fun j => T i j = k + 1) := by
    apply Finset.filter_congr
    intro j hj
    have f := (Finset.mem_filter.1 hj).2.1
    omega
  rw [e] at h
  unfold bkS
  omega

lemma bkTab_bkTab (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) :
    bkTab (bkTab T k hk) k hk = T := by
  ext i j
  rw [bkTab_apply]
  unfold bkEntry
  by_cases f : bkFree T k i j
  · rw [if_pos ((bkFree_bkTab T hk i j).2 f), bkRank_bkTab, bkS_bkTab, ← card_T_k]
    split_ifs with h
    · exact ((free_val_iff T hk f).2 h).symm
    · have := f.1
      have := mt (free_val_iff T hk f).1 h
      omega
  · rw [if_neg (mt (bkFree_bkTab T hk i j).1 f), bkTab_apply, bkEntry_not_free T f]

/-- How many boxes of `T` hold `x`. -/
def cnt (T : SemistandardYoungTableau μ) (x : ℕ) : ℕ :=
  (μ.cells.filter (fun c => T c.1 c.2 = x)).card

lemma rows_card (P : ℕ × ℕ → Prop) [DecidablePred P] (hP : ∀ c, P c → c ∈ μ) :
    (μ.cells.filter P).card = ∑ i ∈ Finset.range (μ.colLen 0),
      ((Finset.range (μ.rowLen i)).filter (fun j => P (i, j))).card := by
  classical
  rw [Finset.card_eq_sum_card_fiberwise (f := Prod.fst) (t := Finset.range (μ.colLen 0))]
  · apply Finset.sum_congr rfl
    intro i _
    apply Finset.card_nbij' (fun c => c.2) (fun j => (i, j))
    · intro c hc
      simp only [Finset.mem_coe, Finset.mem_filter, YoungDiagram.mem_cells] at hc
      simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_range]
      obtain ⟨⟨h1, h2⟩, h3⟩ := hc
      subst h3
      exact ⟨YoungDiagram.mem_iff_lt_rowLen.1 h1, h2⟩
    · intro j hj
      simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_range] at hj
      simp only [Finset.mem_coe, Finset.mem_filter, YoungDiagram.mem_cells]
      exact ⟨⟨YoungDiagram.mem_iff_lt_rowLen.2 hj.1, hj.2⟩, trivial⟩
    · intro c hc
      simp only [Finset.mem_coe, Finset.mem_filter] at hc
      ext
      · exact hc.2.symm
      · rfl
    · intro j _; rfl
  · intro c hc
    simp only [Finset.mem_coe, Finset.mem_filter, YoungDiagram.mem_cells] at hc
    simp only [Finset.coe_range, Set.mem_Iio]
    rw [← YoungDiagram.mem_iff_lt_colLen]
    exact μ.up_left_mem le_rfl (Nat.zero_le _) hc.1

lemma cnt_bkTab_k (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) :
    cnt (bkTab T k hk) k = cnt T (k + 1) := by
  unfold cnt
  rw [← Finset.card_filter_add_card_filter_not
      (s := μ.cells.filter (fun c => bkTab T k hk c.1 c.2 = k)) (fun c => bkFree T k c.1 c.2),
    ← Finset.card_filter_add_card_filter_not
      (s := μ.cells.filter (fun c => T c.1 c.2 = k + 1)) (fun c => bkFree T k c.1 c.2)]
  simp only [Finset.filter_filter]
  congr 1
  · rw [rows_card _ (fun c h => bkFree_mem T hk h.2), rows_card _ (fun c h => bkFree_mem T hk h.2)]
    apply Finset.sum_congr rfl
    intro i _
    have e1 : (Finset.range (μ.rowLen i)).filter (fun j => bkTab T k hk i j = k ∧ bkFree T k i j) =
        (bkRow T k i).filter (fun j => bkRank T k i j < bkS T k i) := by
      unfold bkRow
      rw [Finset.filter_filter]
      apply Finset.filter_congr
      intro j _
      rw [bkTab_apply]
      unfold bkEntry
      by_cases f : bkFree T k i j
      · rw [if_pos f]; split_ifs with h <;> simp [h, f]
      · simp [f]
    have e2 : (Finset.range (μ.rowLen i)).filter (fun j => T i j = k + 1 ∧ bkFree T k i j) =
        (bkRow T k i).filter (fun j => T i j = k + 1) := by
      unfold bkRow
      rw [Finset.filter_filter]
      apply Finset.filter_congr
      intro j _
      exact and_comm
    simp only at e1 e2 ⊢
    rw [e1, e2, card_rank_lt_bkS T hk]
    rfl
  · have e : μ.cells.filter (fun c => bkTab T k hk c.1 c.2 = k ∧ ¬ bkFree T k c.1 c.2) =
        μ.cells.filter (fun c => T c.1 c.2 = k ∧ ¬ bkFree T k c.1 c.2) := by
      apply Finset.filter_congr
      intro c _
      rw [bkTab_apply]
      constructor
      · intro h; rw [bkEntry_not_free T h.2] at h; exact h
      · intro h; rw [bkEntry_not_free T h.2]; exact h
    rw [e]
    apply Finset.card_nbij' (fun c => (c.1 + 1, c.2)) (fun c => (c.1 - 1, c.2))
    · intro c hc
      simp only [Finset.mem_coe, Finset.mem_filter, YoungDiagram.mem_cells] at hc ⊢
      obtain ⟨_, h1, h2⟩ := hc
      unfold bkFree bkBound at h2 ⊢
      simp only [Nat.add_sub_cancel] at ⊢
      have h3 : T (c.1 + 1) c.2 = k + 1 := by omega
      exact ⟨ssyt_mem_of_pos T (by omega), h3, by omega⟩
    · intro c hc
      simp only [Finset.mem_coe, Finset.mem_filter, YoungDiagram.mem_cells] at hc ⊢
      obtain ⟨_, h1, h2⟩ := hc
      unfold bkFree bkBound at h2 ⊢
      have hpos : 0 < c.1 := by omega
      have h3 : T (c.1 - 1) c.2 = k := by omega
      rw [Nat.sub_add_cancel hpos]
      exact ⟨ssyt_mem_of_pos T (by omega), h3, by omega⟩
    · intro c _
      simp
    · intro c hc
      simp only [Finset.mem_coe, Finset.mem_filter, YoungDiagram.mem_cells] at hc
      obtain ⟨_, h1, h2⟩ := hc
      unfold bkFree bkBound at h2
      have hpos : 0 < c.1 := by omega
      ext
      · exact Nat.sub_add_cancel hpos
      · rfl

lemma cnt_bkTab_k1 (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) :
    cnt (bkTab T k hk) (k + 1) = cnt T k := by
  rw [← cnt_bkTab_k (bkTab T k hk) hk, bkTab_bkTab]

lemma cnt_bkTab_other (T : SemistandardYoungTableau μ) {k : ℕ} (hk : 0 < k) {x : ℕ}
    (h1 : x ≠ k) (h2 : x ≠ k + 1) : cnt (bkTab T k hk) x = cnt T x := by
  unfold cnt
  congr 1
  apply Finset.filter_congr
  intro c _
  rw [bkTab_apply]
  by_cases f : bkFree T k c.1 c.2
  · have := f.1
    unfold bkEntry
    rw [if_pos f]
    split_ifs <;> omega
  · rw [bkEntry_not_free T f]

end BK

section Sym

variable {μ : YoungDiagram}

/-- The Bender–Knuth move on tableaux with entries `1, …, m`. -/
def bkUp {m : ℕ} (k : ℕ) (hk : 0 < k) (hkm : k + 1 ≤ m) (T : SSYTUpTo μ m) : SSYTUpTo μ m :=
  ⟨bkTab T.1 k hk, fun c hc => by
    rw [bkTab_apply]
    by_cases f : bkFree T.1 k c.1 c.2
    · have := f.1
      unfold bkEntry; rw [if_pos f]; split_ifs <;> omega
    · rw [bkEntry_not_free _ f]; exact T.2 c hc⟩

lemma bkUp_invol {m : ℕ} (k : ℕ) (hk : 0 < k) (hkm : k + 1 ≤ m) :
    Function.Involutive (bkUp (μ := μ) k hk hkm) := fun T =>
  Subtype.ext (bkTab_bkTab T.1 hk)

lemma weight_bkUp (n : ℕ) (i : Fin n) (T : SSYTUpTo μ (n + 1)) :
    rename (Equiv.swap i.castSucc i.succ) (weight T) =
      weight (bkUp (i.val + 1) (Nat.succ_pos _) (Nat.succ_le_of_lt (Nat.succ_lt_succ i.isLt)) T) := by
  unfold weight
  rw [map_prod]
  simp only [map_pow, rename_X]
  apply Fintype.prod_equiv (Equiv.swap i.castSucc i.succ)
  intro v
  congr 1
  change cnt T.1 (v.val + 1) =
    cnt (bkTab T.1 (i.val + 1) (Nat.succ_pos _)) ((Equiv.swap i.castSucc i.succ v).val + 1)
  rcases eq_or_ne v i.castSucc with rfl | h1
  · rw [Equiv.swap_apply_left, Fin.val_succ, Fin.coe_castSucc, cnt_bkTab_k1]
  · rcases eq_or_ne v i.succ with rfl | h2
    · rw [Equiv.swap_apply_right, Fin.val_succ, Fin.coe_castSucc, cnt_bkTab_k]
    · rw [Equiv.swap_apply_of_ne_of_ne h1 h2, cnt_bkTab_other]
      · intro h; apply h1; ext; simp only [Fin.coe_castSucc]; omega
      · intro h; apply h2; ext; simp only [Fin.val_succ]; omega

lemma schur_swap (μ : YoungDiagram) (n : ℕ) (i : Fin n) :
    rename (Equiv.swap i.castSucc i.succ) (schur μ (n + 1)) = schur μ (n + 1) := by
  letI : Fintype (SSYTUpTo μ (n + 1)) := Fintype.ofFinite _
  unfold schur
  rw [finsum_eq_sum_of_fintype, map_sum]
  simp_rw [weight_bkUp]
  exact Fintype.sum_equiv (Function.Involutive.toPerm _ (bkUp_invol (i.val + 1) (Nat.succ_pos _)
    (Nat.succ_le_of_lt (Nat.succ_lt_succ i.isLt)))) _ _ (fun T => rfl)

end Sym

lemma bijOn_iff_counts (μ : YoungDiagram) (T : SemistandardYoungTableau μ) :
    Set.BijOn (fun c : ℕ × ℕ => T c.1 c.2) (μ : Set (ℕ × ℕ)) (Set.Icc 1 μ.card) ↔
      ((∀ c ∈ μ, 1 ≤ T c.1 c.2 ∧ T c.1 c.2 ≤ μ.card) ∧
        ∀ v : Fin μ.card, (μ.cells.filter (fun c => T c.1 c.2 = v.val + 1)).card = 1) := by
  constructor
  · intro h
    refine ⟨fun c hc => h.mapsTo hc, fun v => ?_⟩
    obtain ⟨c, hc, hcv⟩ := h.surjOn (show v.val + 1 ∈ Set.Icc 1 μ.card from
      ⟨by omega, by have := v.2; omega⟩)
    rw [Finset.card_eq_one]
    refine ⟨c, ?_⟩
    ext d
    simp only [Finset.mem_filter, YoungDiagram.mem_cells, Finset.mem_singleton]
    constructor
    · rintro ⟨hd, hdv⟩
      exact h.injOn hd hc (by simp only at hcv ⊢; rw [hdv, hcv])
    · rintro rfl
      exact ⟨hc, hcv⟩
  · rintro ⟨hb, hcnt⟩
    refine ⟨fun c hc => hb c hc, ?_, ?_⟩
    · intro c hc d hd hcd
      simp only at hcd
      have h1 := (hb c hc).1
      have h2 := (hb c hc).2
      have := hcnt ⟨T c.1 c.2 - 1, by omega⟩
      rw [Finset.card_eq_one] at this
      obtain ⟨e, he⟩ := this
      have hce : c ∈ μ.cells.filter (fun c' => T c'.1 c'.2 = (T c.1 c.2 - 1) + 1) := by
        simp only [Finset.mem_filter, YoungDiagram.mem_cells]; exact ⟨hc, by omega⟩
      have hde : d ∈ μ.cells.filter (fun c' => T c'.1 c'.2 = (T c.1 c.2 - 1) + 1) := by
        simp only [Finset.mem_filter, YoungDiagram.mem_cells]; exact ⟨hd, by omega⟩
      rw [he, Finset.mem_singleton] at hce hde
      rw [hce, hde]
    · intro w hw
      obtain ⟨hw1, hw2⟩ := hw
      have := hcnt ⟨w - 1, by omega⟩
      obtain ⟨e, he⟩ := Finset.card_eq_one.1 this
      have : e ∈ μ.cells.filter (fun c' => T c'.1 c'.2 = (w - 1) + 1) := by
        rw [he]; exact Finset.mem_singleton_self _
      simp only [Finset.mem_filter, YoungDiagram.mem_cells] at this
      exact ⟨e, this.1, by simp only; omega⟩

/-- **Hook length formula.** For any partition shape `μ` with `n` boxes, the number of standard
Young tableaux of shape `μ` equals `n!` divided by the product of the hook lengths of all its
boxes. -/
theorem hook_length_formula (μ : YoungDiagram) :
    (Nat.card (StandardYoungTableau μ) : ℚ) =
      (μ.card.factorial : ℚ) / ∏ c ∈ μ.cells, (hookLength μ c : ℚ) := by
  suffices H : ∀ n, ∀ μ : YoungDiagram, μ.card = n →
      (Nat.card (StandardYoungTableau μ) : ℚ) =
        (n.factorial : ℚ) / ∏ c ∈ μ.cells, (hookLength μ c : ℚ) from H _ μ rfl
  intro n
  induction n with
  | zero =>
    intro μ hμ
    have hcells : μ.cells = ∅ := Finset.card_eq_zero.1 hμ
    rw [card_syt_empty hcells, hcells, Finset.prod_empty, Nat.factorial_zero]
    simp
  | succ n ih =>
    intro μ hμ
    have hHne := hookProd_ne_zero μ
    rw [card_syt_rec (by omega), Nat.cast_sum]
    have step : ∀ c ∈ corners μ,
        (Nat.card {T : StandardYoungTableau μ // T.1 c.1 c.2 = μ.card} : ℚ) =
          (n.factorial : ℚ) * (∑ s ∈ μ.cells, hq μ c s) / ∏ d ∈ μ.cells, (hookLength μ d : ℚ) := by
      intro c hc'
      have hc := mem_corners.1 hc'
      rw [Nat.card_congr (sytFiberEquiv hc (by omega)),
        ih (eraseCorner μ c hc) (by rw [card_eraseCorner, hμ]; rfl), hookProd_eraseCorner hc]
      have hH' := hookProd_ne_zero (eraseCorner μ c hc)
      have hR : ∑ s ∈ μ.cells, hq μ c s ≠ 0 := by
        intro h; apply hHne; rw [hookProd_eraseCorner hc, h, zero_mul]
      field_simp
    rw [Finset.sum_congr rfl step, ← Finset.sum_div, ← Finset.mul_sum, sum_corners_cells, hμ,
      Nat.factorial_succ]
    push_cast
    ring

/-- **Schur polynomials are symmetric.** Reordering the variables `x_1, …, x_m` never changes
the Schur polynomial `s_μ(x_1, …, x_m)`. -/
theorem schur_isSymmetric (μ : YoungDiagram) (m : ℕ) : (schur μ m).IsSymmetric := by
  cases m with
  | zero =>
    intro e
    rw [Subsingleton.elim e 1, Equiv.Perm.coe_one, rename_id]
    rfl
  | succ n =>
    intro e
    have hmem : e ∈ Submonoid.closure (Set.range fun i : Fin n => Equiv.swap i.castSucc i.succ) := by
      rw [Equiv.Perm.mclosure_swap_castSucc_succ]; exact Submonoid.mem_top e
    induction hmem using Submonoid.closure_induction with
    | mem x hx => obtain ⟨i, rfl⟩ := hx; exact schur_swap μ n i
    | one => rw [Equiv.Perm.coe_one, rename_id]; rfl
    | mul x y _ _ hx hy => rw [Equiv.Perm.coe_mul, ← rename_rename, hy, hx]

/-- In `s_μ(x_1, …, x_n)`, where `n` is the number of boxes, the coefficient of
`x_1 x_2 ⋯ x_n` is the number of standard Young tableaux of shape `μ`. -/
theorem schur_coeff_prod_eq_card_standard (μ : YoungDiagram) :
    (schur μ μ.card).coeff (Finsupp.equivFunOnFinite.symm (fun _ => 1)) =
      (Nat.card (StandardYoungTableau μ) : ℤ) := by
  classical
  letI : Fintype (SSYTUpTo μ μ.card) := Fintype.ofFinite _
  unfold schur
  rw [finsum_eq_sum_of_fintype, MvPolynomial.coeff_sum]
  simp only [weight, MvPolynomial.coeff_prod_X_pow]
  rw [Finset.sum_boole]
  have key : ∀ T : SSYTUpTo μ μ.card,
      (Finsupp.equivFunOnFinite.symm (fun _ => 1) =
        Finsupp.indicator (Finset.univ : Finset (Fin μ.card))
          (fun i _ => (μ.cells.filter (fun c => T.1 c.1 c.2 = i.val + 1)).card)) ↔
      ∀ v : Fin μ.card, (μ.cells.filter (fun c => T.1 c.1 c.2 = v.val + 1)).card = 1 := by
    intro T
    rw [Finsupp.ext_iff]
    simp only [Finsupp.coe_equivFunOnFinite_symm, Finsupp.indicator_apply,
      Finset.mem_univ, dite_true]
    exact ⟨fun h v => (h v).symm, fun h v => (h v).symm⟩
  simp_rw [key]
  rw [← Fintype.card_subtype, ← Nat.card_eq_fintype_card]
  congr 1
  apply Nat.card_congr
  exact {
    toFun := fun T => ⟨T.1.1, (bijOn_iff_counts μ T.1.1).2 ⟨T.1.2, T.2⟩⟩
    invFun := fun T => ⟨⟨T.1, ((bijOn_iff_counts μ T.1).1 T.2).1⟩, ((bijOn_iff_counts μ T.1).1 T.2).2⟩
    left_inv := fun T => rfl
    right_inv := fun T => rfl }

/-- The shape `(3, 2)` of the card. -/
def shape32 : YoungDiagram := YoungDiagram.ofRowLens [3, 2] (by decide)

/-- The card's hook lengths of `(3, 2)`: 4, 3, 1 in row 1 and 2, 1 in row 2. -/
example : [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1)].map (hookLength shape32) = [4, 3, 1, 2, 1] := by
  decide

/-- The hooks of `(3, 2)` multiply to 24, and `5! / 24 = 5`. -/
example : ∏ c ∈ shape32.cells, hookLength shape32 c = 24 ∧ Nat.factorial 5 / 24 = 5 := by
  decide

/-- Shape `(3, 2)` has 5 boxes. -/
example : shape32.card = 5 := by decide

/-- The reflection count `C(5,2) - C(5,1) = 10 - 5 = 5`. -/
example : Nat.choose 5 2 - Nat.choose 5 1 = 5 := by decide

/-- The (10, 10) shape. -/
def shape1010 : YoungDiagram := YoungDiagram.ofRowLens [10, 10] (by decide)

/-- Shape `(10, 10)` has hooks `11, …, 2` in row 1 and `10, …, 1` in row 2: they multiply to
`11! × 10!`. -/
example : ∏ c ∈ shape1010.cells, hookLength shape1010 c = Nat.factorial 11 * Nat.factorial 10 := by
  decide

/-- Shape `(10, 10)`: `20!` over hooks `11, …, 2` and `10, …, 1` is `16,796`,
which matches `C(20,10) - C(20,9) = 184,756 - 167,960`. -/
example : Nat.factorial 20 / (Nat.factorial 11 * Nat.factorial 10) = 16796 ∧
    Nat.choose 20 10 = 184756 ∧ Nat.choose 20 9 = 167960 := by
  norm_num [Nat.factorial, Nat.choose_eq_factorial_div_factorial]

/-- Rows lengthening downward, 2 boxes over 3: the hooks multiply to 36 and `120 / 36` is not
a whole number. -/
example : ¬ (36 ∣ Nat.factorial 5) := by decide

#print axioms hook_eq
#print axioms corner_rowLen
#print axioms corner_colLen
#print axioms hook_corner
#print axioms Icc_succ_eq_Ioc
#print axioms hF_tele
#print axioms hF_sum_Ioc
#print axioms hook_ge_two_col
#print axioms hook_ge_two_row
#print axioms wcol_mul
#print axioms wrow_mul
#print axioms hq_rec
#print axioms corner_of_le
#print axioms hq_self
#print axioms isCorner_of_hook_le_one
#print axioms mem_corners
#print axioms sum_hq_corners
#print axioms sum_hq_cells
#print axioms sum_corners_cells
#print axioms mem_eraseCorner
#print axioms card_eraseCorner
#print axioms hook_eraseCorner
#print axioms hook_pos
#print axioms hookProd_eraseCorner
#print axioms restrictTab_apply
#print axioms extendTab_apply
#print axioms restrict_bij
#print axioms extend_lt
#print axioms extend_bij
#print axioms exists_corner_max
#print axioms corner_unique
#print axioms card_syt_rec
#print axioms card_syt_empty
#print axioms hookProd_ne_zero
#print axioms ssyt_mem_of_pos
#print axioms bkFree_mem
#print axioms bkEntry_not_free
#print axioms bkRank_lt
#print axioms bk_row_weak
#print axioms bk_col_strict
#print axioms bkTab_apply
#print axioms bkFree_bkTab
#print axioms card_filter_rank
#print axioms bkRank_eq
#print axioms bkRow_bkTab
#print axioms bkRank_bkTab
#print axioms card_rank_lt_bkS
#print axioms bkS_bkTab
#print axioms free_val_iff
#print axioms card_T_k
#print axioms bkTab_bkTab
#print axioms rows_card
#print axioms cnt_bkTab_k
#print axioms cnt_bkTab_k1
#print axioms cnt_bkTab_other
#print axioms bkUp_invol
#print axioms weight_bkUp
#print axioms schur_swap
#print axioms bijOn_iff_counts
#print axioms hook_length_formula
#print axioms schur_isSymmetric
#print axioms schur_coeff_prod_eq_card_standard

end YoungTableauxHookLengths
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'YoungTableauxHookLengths.hook_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.corner_rowLen' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.corner_colLen' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hook_corner' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.Icc_succ_eq_Ioc' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hF_tele' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hF_sum_Ioc' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hook_ge_two_col' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hook_ge_two_row' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.wcol_mul' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.wrow_mul' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hq_rec' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.corner_of_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hq_self' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.isCorner_of_hook_le_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.mem_corners' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.sum_hq_corners' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.sum_hq_cells' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.sum_corners_cells' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.mem_eraseCorner' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.card_eraseCorner' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hook_eraseCorner' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hook_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hookProd_eraseCorner' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.restrictTab_apply' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.extendTab_apply' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.restrict_bij' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.extend_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.extend_bij' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.exists_corner_max' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.corner_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.card_syt_rec' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.card_syt_empty' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hookProd_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.ssyt_mem_of_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkFree_mem' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkEntry_not_free' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkRank_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bk_row_weak' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bk_col_strict' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkTab_apply' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkFree_bkTab' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.card_filter_rank' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkRank_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkRow_bkTab' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkRank_bkTab' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.card_rank_lt_bkS' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkS_bkTab' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.free_val_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.card_T_k' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkTab_bkTab' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.rows_card' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.cnt_bkTab_k' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.cnt_bkTab_k1' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.cnt_bkTab_other' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bkUp_invol' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.weight_bkUp' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.schur_swap' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.bijOn_iff_counts' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.hook_length_formula' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.schur_isSymmetric' depends on axioms: [propext, Classical.choice, Quot.sound]
'YoungTableauxHookLengths.schur_coeff_prod_eq_card_standard' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Weaken the walk.** In `walk`, change `p / len(step)` to `p / (len(step) + 1)`. The chances read 1/3 and 49/120 and the second assert stops the run.
> - **Let columns tie.** In `ok`, change `T[i, j] > T[i - 1, j]` to `T[i, j] >= T[i - 1, j]`. Does the 5 change? No: 1 to 5 never tie. But the symmetry check reads no and the last assert stops the run.
> - **Drop the second row's hooks.** In `hooks`, change `for c in cells(lam)]` to `for c in cells(lam) if c[0] == 0]`. The formula reads 120/12 = 10 and the run stops with an error.

---

## The usual mistake

> [!warning]
> **Checking rows only.** The column rule keeps yes from falling behind. Rows alone give 10 fillings of $`(3, 2)`$, against the true 5.
>
> - **Half a hook.** The hook is the box, its arm to the right and its leg below. Legs alone give 120 / 4 = 30.
> - **Strict rows in a semistandard tableau.** Strict rows leave $`(2, 1)`$ one tableau, $`x_1 x_2^2`$, not symmetric.
> - **Dividing by the row lengths' factorials.** That is the rows-only count, 10 again.

---

## Where you meet it in real life

- **Vote counts and queues.** Two-row shapes count orders where one side never falls behind. Shape $`(10, 10)`$ gives 16,796, one of the [Catalan numbers](../06-Lattice%20Paths%20and%20Catalan%20Numbers/03-catalan-numbers.md).
- **Electron spin.** Five unpaired electron spins reach total spin one half in 5 independent ways, one per tableau of $`(3, 2)`$.
- **Symmetry of shuffles.** Each shape labels one basic way the shuffles of $`n`$ cards act on lists of numbers, of size $`f^{\lambda}`$ ([Permutations](../../03-Algebra/08-Groups/03-permutations-and-the-symmetric-group.md), [Character tables](../../03-Algebra/12-Group%20Representations/03-character-tables.md)): 1, 4, 5, 6, 5, 4, 1 for five cards.

> **Say it back**
> A standard Young tableau fills a partition's box diagram with 1 to n, rising along rows and down columns. The count is n! over the product of hook lengths: 120 / 24 = 5 for (3, 2). The proof takes the largest number out of a corner and reads the formula's fractions as a hook walk's stopping chances. Allowing repeats gives semistandard tableaux, whose weights add to the symmetric Schur polynomial.

---

## What this builds on

- [Integer partitions](01-integer-partitions.md): the shape is a partition's Ferrers diagram, drawn with boxes.
- [Lattice paths](../06-Lattice%20Paths%20and%20Catalan%20Numbers/01-lattice-paths.md): a two-row tableau is a route of yes and no steps that never crosses the diagonal.

## Where this goes next

- [The RSK correspondence](08-rsk-correspondence.md): pairs each shuffle of $`n`$ cards with two standard tableaux of one shape.

The squares of 1, 4, 5, 6, 5, 4, 1 add to 120 = 5!; why this happens for every $`n`$ is the question this card leaves open.

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Frame, J. S., G. de B. Robinson and R. M. Thrall. "The Hook Graphs of the Symmetric Group." *Canadian Journal of Mathematics* 6 (1954). [doi:10.4153/CJM-1954-030-1](https://doi.org/10.4153/CJM-1954-030-1). The hook length formula, first stated and proved.
- Greene, C., A. Nijenhuis and H. S. Wilf. "A probabilistic proof of a formula for the number of Young tableaux of a given shape." *Advances in Mathematics* 31 (1979). [doi:10.1016/0001-8708(79)90023-9](https://doi.org/10.1016/0001-8708(79)90023-9). The hook walk.
- Fulton, William. *Young Tableaux*. Cambridge University Press, 1996. [doi:10.1017/CBO9780511626241](https://doi.org/10.1017/CBO9780511626241). Semistandard tableaux and Schur polynomials.
- Sagan, Bruce E. *The Symmetric Group*, 2nd ed. Springer, 2001. [doi:10.1007/978-1-4757-6804-6](https://doi.org/10.1007/978-1-4757-6804-6). The hook walk proof, and Schur functions from tableaux.
