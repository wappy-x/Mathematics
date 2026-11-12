# Counting coin-flip paths: how many end at a given height, how many return to zero, how many never touch it

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Lattice Paths and Catalan Numbers](../README.md#s06) → Counting coin-flip paths

---

## General Overview

Flip a coin ten times and write the run down: H T T H H H T H T T. Score every head +1 and every tail −1, then keep a running total. It opens at zero, steps up or down by one at each flip, and after the tenth stands somewhere between −10 and +10. That run of totals is a **path**, the word used from here on.

Ten flips fall 1,024 ways. Four counts inside those 1,024 do most of the work. 252 paths end level, back at zero, and 210 end at +2. Of the 252 that end level, 42 never once dip below zero, and only 14 stay strictly above zero from the first flip to the ninth.

No coin has to be thrown to get those numbers. A path is fixed by which flips came up heads and by nothing else, so counting paths is counting sets of flips. The ending height says how many heads there were.

**The ending height fixes the head count, so the paths finishing there number C(n, (n+h)/2); ruling out the paths that dip below zero divides that count down to a Catalan number.**

**What kind of fact this is:** a theorem, proved on this card in Why it works.

### The picture: where 1,024 paths finish

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Ten flips scored +1/-1: how many of the 1,024 paths end at each height"
    x-axis "Height after the tenth flip" [-10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10]
    y-axis "Number of paths" 0 --> 260
    line [1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1]
```

Odd heights are missing on purpose: ten flips cannot finish at an odd total.

---

## The formula

Notation first, in words. $n$ is the number of flips, $h$ the height the path ends at, $u$ how many flips came up heads. C(n, k) in brackets is the count of ways to choose k things from n, read "n choose k". A Catalan number keeps the shelf's notation, Cat(m) ([Catalan numbers](03-catalan-numbers.md)).

$$P(n, h) \;=\; C\!\left(n,\ \frac{n + h}{2}\right)$$

**Read it aloud:** count the paths ending at a height by choosing which flips were heads, and the height fixes how many heads that is.

Set the height to zero with an even flip count $n = 2m$, and the path is back where it started:

$$P(2m,\ 0) \;=\; C(2m,\ m)$$

Of those returns, the ones that never drop below zero and the ones that stay strictly above zero in between are two neighbouring Catalan numbers:

$$\text{never below zero} = \mathrm{Cat}(m) = \frac{C(2m,\ m)}{m+1}, \qquad \text{strictly above zero} = \mathrm{Cat}(m-1)$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $n$ | flips in the path, one step each | 10 | more paths, spread wider |
| $h$ | the height the path ends at | 0, or +2 | falls away from zero |
| $u$ | flips that came up heads | 5 to end level, 6 for +2 | the ending height rises |
| $m$ | half the flips, when the flip count is even | 5 | — |
| $P(n,h)$ | paths of $n$ flips ending at $h$ | 252 at zero, 210 at +2 | — |
| $C(n,k)$ | ways to choose k things from n | C(10, 5) = 252 | — |
| $\mathrm{Cat}(m)$ | the m-th Catalan number | Cat(5) = 42, Cat(4) = 14 | grows, but slower |

### When it holds

- **Every flip moves the total by one, up or down.** A step of any other size breaks the link between head count and height, and the count comes out too low.
- **Flip count and ending height share parity: both even or both odd.** Ten flips cannot end at +1: the formula asks for five and a half heads, and the count is 0.
- **The height cannot outrun the flips.** Outside −n to n, (n + h)/2 leaves the range 0 to n and the count is 0 again.
- **The Catalan counts assume a level ending.** Paths that stay above zero and finish elsewhere are the ballot numbers of [The reflection principle](02-reflection-principle-and-ballot-problem.md).

---

## Why it works

### Step 0: a path is nothing but its set of heads

H T T H H H T H T T is the set of head positions 1, 4, 5, 6, 8. Hand back that set and the run comes back with it: every position left out was a tail. Different sets give different runs, and every set is some run. Counting paths is counting subsets of the ten positions.

### Step 1: the ending height fixes the head count

With u heads the tails number n − u. Each head adds one, each tail takes one away:

$$h = u - (n - u) = 2u - n, \qquad u = \frac{n + h}{2}$$

No slack in that. A ten-flip path ending at +2 had exactly six heads, so those paths are the subsets of size six: C(10, 6) = 210. Ending at zero needs five: C(10, 5) = 252. When flip count and height disagree in parity, (n + h)/2 is not whole and the count is zero — not small, none.

### Step 2: ending level is the middle of the row

Put h = 0 into Step 1: the head count is n/2, which needs n even. Write n = 2m and the count is C(2m, m), the middle entry of row 2m of Pascal's triangle ([The middle of the row](../03-Binomial%20Coefficients%20and%20Identities/07-central-binomial-and-bounds.md)). With m of 5 that is 252.

### Step 3: never dipping below zero is a Catalan count

Of the 252 level enders, some sink below zero and some never do. The ones staying at or above zero throughout are called Dyck paths ([Lattice paths](01-lattice-paths.md)). They are counted by the Catalan number Cat(m) — the middle entry shared among m + 1 equal parts:

$$\mathrm{Cat}(m) = \frac{C(2m,\ m)}{m+1} \quad\longrightarrow\quad \frac{252}{6} = 42$$

The divisor is proved on [Catalan numbers](03-catalan-numbers.md). The reflection principle reaches the same 42 without it: every dipping path matches one for one with a path ending at −2 ([The reflection principle](02-reflection-principle-and-ballot-problem.md)), and those number C(10, 4) = 210, leaving 252 − 210 = 42.

### Step 4: staying strictly above zero costs two flips

Demand more: the total stays above zero at every step from the first to the ninth, touching zero only at the two ends. Such a path is an **excursion**.

Two flips are then forced. The first must be a head, or the total is −1 at once. The tenth must be a tail, since the ninth total is at least +1 and the path has to finish at zero.

Between them, eight flips carry the total from +1 back to +1 without touching zero. Subtract 1 from each of those eight totals and the stretch is a Dyck path of eight flips: it opens and closes at zero and never goes negative.

Add the 1 back, glue the head and tail on again, and the excursion returns, so the two collections match one for one.

Nothing in that argument used the number ten. Excursions of 2m flips are counted by the Dyck paths of 2m − 2, one Catalan number back:

$$\mathrm{Cat}(m-1) = \frac{C(2m - 2,\ m - 1)}{m} \quad\longrightarrow\quad \frac{70}{5} = 14$$

---

## Worked numbers, by hand

Ten flips, a head worth +1 and a tail worth −1. The shelf's house example is the sixth row of the table below: of the 252 paths that return to zero, 42 never dip below it.

| Step | Arithmetic | Value |
| --- | --- | --- |
| all runs of ten flips | 2 multiplied by itself ten times | 1,024 |
| heads to end level | (10 + 0)/2 | 5 |
| paths ending level | C(10, 5) | **252** |
| heads to end at +2 | (10 + 2)/2 | 6 |
| paths ending at +2 | C(10, 6) | **210** |
| of those 252, never below zero | 252 shared among 6 | **42** |
| of those 252, strictly above zero | C(8, 4)/5 = 70/5 | **14** |

Of those 252, one in six never goes under zero, and one in eighteen keeps clear of it the whole way.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| A height of +1 in ten flips | 0 | 10 + 1 is odd, so no head count gives it |
| The height put into the choice count | 45 | C(10, 2) reads the height; the slot wants 6 |
| 252 shared among 5 instead of 6 | 50.4 | The divisor is m + 1; a count comes out whole |
| The never-below count used for excursions | 42 | Two flips are forced, leaving a shorter Dyck count: 14 |

The code prints all four.

---

## Code, from first principles, and it actually runs

Nothing is imported, and every count is reached twice. One road walks all 1,024 runs a flip at a time, tracking the running total, its lowest point, and its lowest point before the end; it knows no formula. The other builds C(n, (n+h)/2) from a product written out in the script and divides the middle entry down; it looks at no path. A four-flip run is the second worked case.

### Python

```python
# Counting coin-flip paths -- the check behind the card.  Nothing is imported.
# Ten fair flips scored +1 for heads and -1 for tails; the path is the running
# total.  Every count is reached twice: once by walking all 2^n sequences step
# by step, once from a closed form built out of a product written out here.
N, M = 10, 4                              # ten flips, and a four-flip warm-up

def choose(n, k):                         # C(n, k), built here, nothing imported
    top, bot = 1, 1
    for i in range(k):
        top, bot = top * (n - i), bot * (i + 1)
    return top // bot if 0 <= k <= n else 0

def catalan(m):                           # the m-th Catalan number
    return choose(2 * m, m) // (m + 1)

def walk(n):                              # road one: every +1/-1 sequence, one at a time
    ends = [0] * (2 * n + 1)              # ends[h + n] counts paths finishing at height h
    dyck = high = 0                       # never below zero; strictly above zero between
    for code in range(2 ** n):
        s, low, inner = 0, 0, n           # height, lowest height, lowest before the end
        for k in range(1, n + 1):
            s += 1 if (code >> (k - 1)) & 1 else -1
            low = min(low, s)
            inner = min(inner, s) if k < n else inner
        ends[s + n] += 1
        dyck += 1 if s == 0 and low >= 0 else 0
        high += 1 if s == 0 and inner > 0 else 0
    return ends, dyck, high

def formula(n):                           # road two: the closed forms, nothing listed
    ends = [choose(n, (n + h) // 2) if (n + h) % 2 == 0 else 0 for h in range(-n, n + 1)]
    return ends, catalan(n // 2), catalan(n // 2 - 1)

def row(name, values):
    print(f"{name:<24}" + "".join(f"{v:>5}" for v in values))

seen, dyck, high = walk(N)
calc, dyck_c, high_c = formula(N)
small, small_dyck, small_high = walk(M)
evens = list(range(-N, N + 1, 2))
print(f"{N} flips scored +1/-1: 2^{N} = {2 ** N} sequences, {sum(seen)} paths listed")
row("ending height", evens)
row("paths, by listing", [seen[h + N] for h in evens])
row("paths, by C(n, (n+h)/2)", [calc[h + N] for h in evens])
print(f"end level, height 0: listed {seen[N]}, C({N}, {N // 2}) = {calc[N]}")
print(f"end at +2:           listed {seen[N + 2]}, C({N}, {(N + 2) // 2}) = {calc[N + 2]}")
print(f"never below zero:    listed {dyck}, C({N}, {N // 2})/{N // 2 + 1} = {dyck_c}")
print(f"strictly above zero: listed {high}, C({N - 2}, {N // 2 - 1})/{N // 2} = {high_c}")
print(f"{M} flips: {2 ** M} sequences, {small[M]} end level, {small_dyck} never below zero, "
      f"{small_high} strictly above")
print(f"mistake 1, ending at +1 in {N} flips: {N} + 1 is odd, so {calc[N + 1]} paths")
print(f"mistake 2, C({N}, 2) from the height, not the head count: {choose(N, 2)}, not {calc[N + 2]}")
print(f"mistake 3, {calc[N]} shared among {N // 2} instead of {N // 2 + 1}: "
      f"{calc[N] / (N // 2):.1f}, not a whole number")
print(f"mistake 4, the never-below count used for the strictly-above one: {dyck}, not {high}")
assert seen == calc                                      # two roads, one distribution
assert sum(calc) == 2 ** N and seen[N] == 252            # the whole row sums to 2^n
assert (dyck, high) == (42, 14) == (dyck_c, high_c)      # listing against closed form
assert small == [1, 0, 4, 0, 6, 0, 4, 0, 1] and (small_dyck, small_high) == (2, 1)
print("ALL CHECKS PASS")
```

**Ran 2026-09-14 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
10 flips scored +1/-1: 2^10 = 1024 sequences, 1024 paths listed
ending height             -10   -8   -6   -4   -2    0    2    4    6    8   10
paths, by listing           1   10   45  120  210  252  210  120   45   10    1
paths, by C(n, (n+h)/2)     1   10   45  120  210  252  210  120   45   10    1
end level, height 0: listed 252, C(10, 5) = 252
end at +2:           listed 210, C(10, 6) = 210
never below zero:    listed 42, C(10, 5)/6 = 42
strictly above zero: listed 14, C(8, 4)/5 = 14
4 flips: 16 sequences, 6 end level, 2 never below zero, 1 strictly above
mistake 1, ending at +1 in 10 flips: 10 + 1 is odd, so 0 paths
mistake 2, C(10, 2) from the height, not the head count: 45, not 210
mistake 3, 252 shared among 5 instead of 6: 50.4, not a whole number
mistake 4, the never-below count used for the strictly-above one: 42, not 14
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Counting coin-flip paths -- the same check as the Python, in Rust.  No crates.
// Ten fair flips scored +1 for heads and -1 for tails; the path is the running
// total.  Every count is reached twice: once by walking all 2^n sequences step
// by step, once from a closed form built out of a product written out here.
const N: i64 = 10;                            // ten flips
const M: i64 = 4;                             // and a four-flip warm-up

fn choose(n: i64, k: i64) -> i64 {            // C(n, k), built here, no crates
    if k < 0 || k > n { return 0 }
    let (mut top, mut bot) = (1i64, 1i64);
    for i in 0..k { top *= n - i; bot *= i + 1 }
    top / bot
}

fn catalan(m: i64) -> i64 {                   // the m-th Catalan number
    choose(2 * m, m) / (m + 1)
}

fn walk(n: i64) -> (Vec<i64>, i64, i64) {     // road one: every +1/-1 sequence, one at a time
    let mut ends = vec![0i64; (2 * n + 1) as usize];  // ends[h + n]: paths finishing at h
    let (mut dyck, mut high) = (0i64, 0i64);  // never below zero; strictly above zero between
    for code in 0..(1i64 << n) {
        let (mut s, mut low, mut inner) = (0i64, 0i64, n);  // height, lowest, lowest before the end
        for k in 1..=n {
            s += if (code >> (k - 1)) & 1 == 1 { 1 } else { -1 };
            if s < low { low = s }
            if k < n && s < inner { inner = s }
        }
        ends[(s + n) as usize] += 1;
        if s == 0 && low >= 0 { dyck += 1 }
        if s == 0 && inner > 0 { high += 1 }
    }
    (ends, dyck, high)
}

fn formula(n: i64) -> (Vec<i64>, i64, i64) {  // road two: the closed forms, nothing listed
    let ends = (-n..=n)
        .map(|h| if (n + h) % 2 == 0 { choose(n, (n + h) / 2) } else { 0 })
        .collect();
    (ends, catalan(n / 2), catalan(n / 2 - 1))
}

fn row(name: &str, values: &[i64]) {
    let mut line = format!("{:<24}", name);
    for v in values { line.push_str(&format!("{:>5}", v)) }
    println!("{}", line);
}

fn main() {
    let (seen, dyck, high) = walk(N);
    let (calc, dyck_c, high_c) = formula(N);
    let (small, small_dyck, small_high) = walk(M);
    let evens: Vec<i64> = (-N..=N).step_by(2).collect();
    let at = |v: &Vec<i64>, h: i64| v[(h + N) as usize];
    let total: i64 = seen.iter().sum();
    println!("{} flips scored +1/-1: 2^{} = {} sequences, {} paths listed", N, N, 1i64 << N, total);
    row("ending height", &evens);
    row("paths, by listing", &evens.iter().map(|&h| at(&seen, h)).collect::<Vec<i64>>());
    row("paths, by C(n, (n+h)/2)", &evens.iter().map(|&h| at(&calc, h)).collect::<Vec<i64>>());
    println!("end level, height 0: listed {}, C({}, {}) = {}", at(&seen, 0), N, N / 2, at(&calc, 0));
    println!("end at +2:           listed {}, C({}, {}) = {}", at(&seen, 2), N, (N + 2) / 2, at(&calc, 2));
    println!("never below zero:    listed {}, C({}, {})/{} = {}", dyck, N, N / 2, N / 2 + 1, dyck_c);
    println!("strictly above zero: listed {}, C({}, {})/{} = {}", high, N - 2, N / 2 - 1, N / 2, high_c);
    println!("{} flips: {} sequences, {} end level, {} never below zero, {} strictly above",
             M, 1i64 << M, small[M as usize], small_dyck, small_high);
    println!("mistake 1, ending at +1 in {} flips: {} + 1 is odd, so {} paths", N, N, at(&calc, 1));
    println!("mistake 2, C({}, 2) from the height, not the head count: {}, not {}",
             N, choose(N, 2), at(&calc, 2));
    println!("mistake 3, {} shared among {} instead of {}: {:.1}, not a whole number",
             at(&calc, 0), N / 2, N / 2 + 1, at(&calc, 0) as f64 / (N / 2) as f64);
    println!("mistake 4, the never-below count used for the strictly-above one: {}, not {}", dyck, high);
    assert!(seen == calc);                                      // two roads, one distribution
    assert!(calc.iter().sum::<i64>() == 1i64 << N && at(&seen, 0) == 252);  // the row sums to 2^n
    assert!((dyck, high) == (42, 14) && (dyck_c, high_c) == (42, 14));  // listing against closed form
    assert!(small == vec![1, 0, 4, 0, 6, 0, 4, 0, 1] && (small_dyck, small_high) == (2, 1));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-14 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
10 flips scored +1/-1: 2^10 = 1024 sequences, 1024 paths listed
ending height             -10   -8   -6   -4   -2    0    2    4    6    8   10
paths, by listing           1   10   45  120  210  252  210  120   45   10    1
paths, by C(n, (n+h)/2)     1   10   45  120  210  252  210  120   45   10    1
end level, height 0: listed 252, C(10, 5) = 252
end at +2:           listed 210, C(10, 6) = 210
never below zero:    listed 42, C(10, 5)/6 = 42
strictly above zero: listed 14, C(8, 4)/5 = 14
4 flips: 16 sequences, 6 end level, 2 never below zero, 1 strictly above
mistake 1, ending at +1 in 10 flips: 10 + 1 is odd, so 0 paths
mistake 2, C(10, 2) from the height, not the head count: 45, not 210
mistake 3, 252 shared among 5 instead of 6: 50.4, not a whole number
mistake 4, the never-below count used for the strictly-above one: 42, not 14
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the three counts for every number of flips, not just ten.

- Paths of n flips ending at height h number C(n, (n + h)/2). This needs n and h both even or both odd, and h between −n and n.
- Of the paths of 2m flips that end at zero, the ones that never dip below zero number Cat(m).
- Of those same 2m-flip paths, the excursions number Cat(m − 1). They stay strictly above zero from the first flip to the one before last.
- Listing the ten-flip paths one by one gives 252 ending level, 210 ending at +2, 42 never below zero and 14 excursions.

Listing the whole ten-flip row path by path, and the 50.4 from the wrong divisor, are left to the Python and Rust checks.

```lean
-- Counting coin-flip paths: of the n-flip paths scored +1 per head and −1 per tail, those ending at height h number C(n, (n + h)/2), and of the 2m-flip paths ending at zero, Cat(m) never dip below zero and Cat(m − 1) stay strictly above zero in between, with the card's ten-flip numbers checked.
import Mathlib.Combinatorics.Enumerative.Catalan.Basic
import Mathlib.Combinatorics.Enumerative.DyckWord
import Mathlib.Data.Finset.Powerset
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Group.Unbundled.Abs
import Mathlib.Algebra.Group.Int.Even
import Mathlib.Tactic.NormNum

/-- One flip scored: a head (`true`) is worth `+1`, a tail (`false`) is worth `−1`. -/
def flipStep (b : Bool) : ℤ := if b then 1 else -1

/-- The running total of the path `f` (a run of `n` flips, `f i = true` meaning flip `i` came up
heads) after its first `k` flips. After all `n` flips it is the height the path ends at. -/
def heightAfter {n : ℕ} (f : Fin n → Bool) (k : ℕ) : ℤ :=
  ∑ i ∈ Finset.univ.filter (fun i : Fin n => (i : ℕ) < k), flipStep (f i)

open DyckStep

/-- A head becomes an up step, a tail a down step. -/
def boolToStep (b : Bool) : DyckStep := if b then U else D

lemma heightAfter_succ {n : ℕ} (f : Fin n → Bool) (k : ℕ) :
    heightAfter f (k + 1) = heightAfter f k + (if h : k < n then flipStep (f ⟨k, h⟩) else 0) := by
  unfold heightAfter
  split_ifs with hk
  · have : Finset.univ.filter (fun i : Fin n => (i : ℕ) < k + 1) =
        insert ⟨k, hk⟩ (Finset.univ.filter (fun i : Fin n => (i : ℕ) < k)) := by
      ext i; simp [Fin.ext_iff]; omega
    rw [this, Finset.sum_insert (by simp), add_comm]
  · have : Finset.univ.filter (fun i : Fin n => (i : ℕ) < k + 1) =
        Finset.univ.filter (fun i : Fin n => (i : ℕ) < k) := by
      ext i; have := i.2; simp; omega
    rw [this, add_zero]

lemma heightAfter_eq_list {n : ℕ} (f : Fin n → Bool) (k : ℕ) :
    heightAfter f k = (((List.ofFn f).take k).map flipStep).sum := by
  induction k with
  | zero => simp [heightAfter]
  | succ k ih =>
    rw [heightAfter_succ, ih, List.take_add_one]
    split_ifs with hk
    · simp [hk]
    · simp [hk]

lemma sum_map_flipStep (l : List Bool) :
    (l.map flipStep).sum = ((l.map boolToStep).count U : ℤ) - (l.map boolToStep).count D := by
  induction l with
  | nil => simp
  | cons b l ih =>
    cases b <;> simp [flipStep, boolToStep, ih] <;> ring

/-- The path as a list of up and down steps. -/
def stepWord {n : ℕ} (f : Fin n → Bool) : List DyckStep := (List.ofFn f).map boolToStep

@[simp] lemma length_stepWord {n : ℕ} (f : Fin n → Bool) : (stepWord f).length = n := by
  simp [stepWord]

lemma heightAfter_eq_count {n : ℕ} (f : Fin n → Bool) (k : ℕ) :
    heightAfter f k = (((stepWord f).take k).count U : ℤ) - ((stepWord f).take k).count D := by
  rw [heightAfter_eq_list, sum_map_flipStep, stepWord, List.map_take]

lemma count_U_add_count_D (l : List DyckStep) : l.count U + l.count D = l.length := by
  induction l with
  | nil => simp
  | cons s l ih => cases s <;> simp <;> omega

/-- Read a word of steps back as a run of flips. -/
def ofStepWord {n : ℕ} (l : List DyckStep) (hl : l.length = n) : Fin n → Bool :=
  fun i => decide (l[(i : ℕ)]'(by rw [hl]; exact i.2) = U)

lemma stepWord_ofStepWord {n : ℕ} (l : List DyckStep) (hl : l.length = n) :
    stepWord (ofStepWord l hl) = l := by
  apply List.ext_getElem (by simp [hl])
  intro i h1 h2
  simp only [stepWord, ofStepWord, List.getElem_map, List.getElem_ofFn, boolToStep]
  cases l[i] <;> simp

lemma ofStepWord_stepWord {n : ℕ} (f : Fin n → Bool) :
    ofStepWord (stepWord f) (length_stepWord f) = f := by
  funext i
  simp only [stepWord, ofStepWord, List.getElem_map, List.getElem_ofFn, boolToStep]
  cases f i <;> simp

/-- Paths that never dip below zero and end at zero match Dyck words. -/
def pathDyckEquiv (m : ℕ) :
    {f : Fin (2 * m) → Bool //
      heightAfter f (2 * m) = 0 ∧ ∀ k : ℕ, k ≤ 2 * m → 0 ≤ heightAfter f k} ≃
    {p : DyckWord // p.semilength = m} where
  toFun f := ⟨⟨stepWord f.1, by
      have h := f.2.1
      rw [heightAfter_eq_count, List.take_of_length_le (by simp)] at h
      omega, by
      intro i
      by_cases hi : i ≤ 2 * m
      · have h := f.2.2 i hi
        rw [heightAfter_eq_count] at h
        omega
      · have h := f.2.2 (2 * m) le_rfl
        rw [heightAfter_eq_count, List.take_of_length_le (by simp)] at h
        rw [List.take_of_length_le (by simp; omega)]
        omega⟩, by
      have h := f.2.1
      rw [heightAfter_eq_count, List.take_of_length_le (by simp)] at h
      have h2 := count_U_add_count_D (stepWord f.1)
      simp only [length_stepWord] at h2
      show (stepWord f.1).count U = m
      omega⟩
  invFun p := ⟨ofStepWord p.1.toList (by rw [← p.1.two_mul_semilength_eq_length, p.2]), by
      constructor
      · rw [heightAfter_eq_count, stepWord_ofStepWord,
          List.take_of_length_le (by rw [← p.1.two_mul_semilength_eq_length, p.2]),
          p.1.count_U_eq_count_D]
        simp
      · intro k _
        rw [heightAfter_eq_count, stepWord_ofStepWord]
        have := p.1.count_D_le_count_U k
        omega⟩
  left_inv f := by
    apply Subtype.ext
    exact ofStepWord_stepWord f.1
  right_inv p := by
    apply Subtype.ext
    apply DyckWord.ext
    exact stepWord_ofStepWord p.1.toList (by rw [← p.1.two_mul_semilength_eq_length, p.2])

lemma pathDyckEquiv_toList (m : ℕ) (f) : ((pathDyckEquiv m f).1.toList) = stepWord f.1 := rfl

/-- Wrapping a Dyck word in one outer pair of brackets, and unwrapping it. -/
def nestEquiv (m : ℕ) :
    {p : {p : DyckWord // p.semilength = m + 1} // p.1.IsNested} ≃
    {q : DyckWord // q.semilength = m} where
  toFun p := ⟨p.1.1.denest p.2, by
    have h := congrArg DyckWord.semilength (p.1.1.nest_denest p.2)
    rw [DyckWord.semilength_nest, p.1.2] at h
    omega⟩
  invFun q := ⟨⟨q.1.nest, by rw [DyckWord.semilength_nest, q.2]⟩, DyckWord.IsNested.nest⟩
  left_inv p := by
    apply Subtype.ext; apply Subtype.ext; exact p.1.1.nest_denest p.2
  right_inv q := by
    apply Subtype.ext; exact q.1.denest_nest

/-- The card's main formula. Every flip moves the total by one, up or down. If the flip count `n`
and the ending height `h` are both even or both odd, and `h` lies between `−n` and `n`, then the
paths of `n` flips that end at height `h` number `C(n, (n + h)/2)`. -/
theorem paths_ending_at_height_eq_choose (n : ℕ) (h : ℤ) (hpar : Even ((n : ℤ) + h))
    (hrange : |h| ≤ n) :
    (Finset.univ.filter (fun f : Fin n → Bool => heightAfter f n = h)).card =
      n.choose ((n + h) / 2).toNat := by
  obtain ⟨t, ht⟩ := hpar
  obtain ⟨h1, h2⟩ := abs_le.mp hrange
  have hdiv : ((n : ℤ) + h) / 2 = t := by omega
  have ht0 : 0 ≤ t := by omega
  have key : ∀ f : Fin n → Bool,
      heightAfter f n = 2 * ((Finset.univ.filter (fun i => f i = true)).card : ℤ) - n := by
    intro f
    have hf : ∀ b : Bool, flipStep b = 2 * (if b = true then (1 : ℤ) else 0) - 1 := by
      intro b; cases b <;> simp [flipStep]
    unfold heightAfter
    rw [Finset.filter_true_of_mem (fun i _ => i.2)]
    simp_rw [hf]
    rw [Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_boole]
    simp
  rw [hdiv, show n.choose t.toNat = (Finset.powersetCard t.toNat (Finset.univ : Finset (Fin n))).card
    by simp [Finset.card_powersetCard]]
  apply Finset.card_nbij' (fun f => Finset.univ.filter (fun i => f i = true))
    (fun s => fun i => decide (i ∈ s))
  · intro f hf
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hf
    simp only [Finset.mem_coe, Finset.mem_powersetCard, Finset.subset_univ, true_and]
    rw [key] at hf
    omega
  · intro s hs
    simp only [Finset.mem_coe, Finset.mem_powersetCard, Finset.subset_univ, true_and] at hs
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq]
    rw [key]
    have : Finset.univ.filter (fun i => decide (i ∈ s) = true) = s := by ext; simp
    rw [this, hs]
    omega
  · intro f _
    funext i
    simp
  · intro s _
    ext; simp

/-- Of the paths of `2m` flips that end back at zero, the ones whose running total never dips
below zero number the Catalan number `Cat(m) = C(2m, m)/(m + 1)`. -/
theorem never_below_zero_returns_eq_catalan (m : ℕ) :
    (Finset.univ.filter (fun f : Fin (2 * m) → Bool =>
      heightAfter f (2 * m) = 0 ∧ ∀ k : ℕ, k ≤ 2 * m → 0 ≤ heightAfter f k)).card = catalan m := by
  rw [← Fintype.card_subtype, ← Nat.card_eq_fintype_card, Nat.card_congr (pathDyckEquiv m),
    Nat.card_eq_fintype_card, DyckWord.card_dyckWord_semilength_eq_catalan]

/-- Of the paths of `2m` flips that end back at zero, the ones whose running total stays strictly
above zero after every flip from the first to the one before last number `Cat(m − 1)`. -/
theorem strictly_above_zero_returns_eq_catalan_pred (m : ℕ) :
    (Finset.univ.filter (fun f : Fin (2 * m) → Bool =>
      heightAfter f (2 * m) = 0 ∧ ∀ k : ℕ, k < 2 * m → 0 < k → 0 < heightAfter f k)).card =
      catalan (m - 1) := by
  cases m with
  | zero => simp [heightAfter]
  | succ m =>
    rw [← Fintype.card_subtype, ← Nat.card_eq_fintype_card]
    have hQP : ∀ {f : Fin (2 * (m + 1)) → Bool},
        (heightAfter f (2 * (m + 1)) = 0 ∧
          ∀ k : ℕ, k < 2 * (m + 1) → 0 < k → 0 < heightAfter f k) →
        (heightAfter f (2 * (m + 1)) = 0 ∧
          ∀ k : ℕ, k ≤ 2 * (m + 1) → 0 ≤ heightAfter f k) := by
      intro f hf
      refine ⟨hf.1, fun k hk => ?_⟩
      rcases Nat.eq_zero_or_pos k with h0 | h0
      · subst h0; simp [heightAfter]
      · rcases Nat.lt_or_ge k (2 * (m + 1)) with h1 | h1
        · exact (hf.2 k h1 h0).le
        · rw [show k = 2 * (m + 1) by omega, hf.1]
    have e := (Equiv.subtypeSubtypeEquivSubtype hQP).symm.trans
      ((Equiv.subtypeEquiv (q := fun p => p.1.IsNested) (pathDyckEquiv (m + 1)) (by
        intro x
        simp only [DyckWord.IsNested, pathDyckEquiv_toList, length_stepWord]
        constructor
        · intro h
          refine ⟨?_, ?_⟩
          · intro h0
            have := congrArg (fun p => p.toList.length) h0
            simp [pathDyckEquiv_toList] at this
          · intro i hi1 hi2
            have := h.2 i hi2 hi1
            rw [heightAfter_eq_count] at this
            omega
        · rintro ⟨-, h⟩
          refine ⟨x.2.1, fun k hk1 hk2 => ?_⟩
          rw [heightAfter_eq_count]
          have := h hk2 hk1
          omega)).trans (nestEquiv m))
    rw [Nat.card_congr e, Nat.card_eq_fintype_card, DyckWord.card_dyckWord_semilength_eq_catalan]
    rfl

-- Ten flips: 2^10 = 1024 runs in all.
example : Fintype.card (Fin 10 → Bool) = 1024 := by simp
-- Heads needed: (10 + 0)/2 = 5 to end level, (10 + 2)/2 = 6 to end at +2.
example : (10 + 0) / 2 = 5 ∧ (10 + 2) / 2 = 6 := by decide
-- 252 paths end level, 210 end at +2, 42 never dip below zero, 14 stay strictly above.
example : Nat.choose 10 5 = 252 ∧ Nat.choose 10 6 = 210 := by decide
example : catalan 5 = 42 ∧ 252 / 6 = 42 ∧ 252 = 6 * 42 := by
  rw [catalan_eq_centralBinom_div, Nat.centralBinom_eq_two_mul_choose]; decide
example : catalan 4 = 14 ∧ Nat.choose 8 4 = 70 ∧ 70 / 5 = 14 ∧ 70 = 5 * 14 := by
  rw [catalan_eq_centralBinom_div, Nat.centralBinom_eq_two_mul_choose]; decide
-- The reflection count: 210 paths end at −2, leaving 252 − 210 = 42.
example : Nat.choose 10 4 = 210 ∧ 252 - 210 = 42 := by decide
-- The whole ten-flip row of the chart: 1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1.
example : (List.range 11).map (Nat.choose 10) = [1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1] := by
  decide
-- The same ten-flip counts, made path by path from the definitions above.
example : (Finset.univ.filter (fun f : Fin 10 → Bool => heightAfter f 10 = 0)).card = 252 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 10 → Bool => heightAfter f 10 = 2)).card = 210 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 10 → Bool =>
    heightAfter f 10 = 0 ∧ ∀ k : ℕ, k ≤ 10 → 0 ≤ heightAfter f k)).card = 42 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 10 → Bool =>
    heightAfter f 10 = 0 ∧ ∀ k : ℕ, k < 10 → 0 < k → 0 < heightAfter f k)).card = 14 := by
  decide +kernel
-- Parity: ten flips cannot end at +1, so no path does.
example : (Finset.univ.filter (fun f : Fin 10 → Bool => heightAfter f 10 = 1)).card = 0 := by
  decide +kernel
-- The card's run H T T H H H T H T T (heads at flips 1, 4, 5, 6, 8) ends level.
example : heightAfter ![true, false, false, true, true, true, false, true, false, false] 10 = 0 := by
  decide +kernel
-- The four-flip warm-up, counted path by path: 16 runs, 6 end level, 2 never below zero, 1 strictly above.
example : (Finset.univ.filter (fun f : Fin 4 → Bool => heightAfter f 4 = 0)).card = 6 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 4 → Bool =>
    heightAfter f 4 = 0 ∧ ∀ k : ℕ, k ≤ 4 → 0 ≤ heightAfter f k)).card = 2 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 4 → Bool =>
    heightAfter f 4 = 0 ∧ ∀ k : ℕ, k < 4 → 0 < k → 0 < heightAfter f k)).card = 1 := by
  decide +kernel
-- The mistakes: C(10, 2) = 45 is not 210; and 252/5 is not whole (252 = 5 · 50 + 2).
example : Nat.choose 10 2 = 45 ∧ 252 % 5 = 2 := by decide

#print axioms boolToStep
#print axioms heightAfter_succ
#print axioms heightAfter_eq_list
#print axioms sum_map_flipStep
#print axioms stepWord
#print axioms length_stepWord
#print axioms heightAfter_eq_count
#print axioms count_U_add_count_D
#print axioms ofStepWord
#print axioms stepWord_ofStepWord
#print axioms ofStepWord_stepWord
#print axioms pathDyckEquiv
#print axioms pathDyckEquiv_toList
#print axioms nestEquiv
#print axioms paths_ending_at_height_eq_choose
#print axioms never_below_zero_returns_eq_catalan
#print axioms strictly_above_zero_returns_eq_catalan_pred
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'boolToStep' does not depend on any axioms
'heightAfter_succ' depends on axioms: [propext, Classical.choice, Quot.sound]
'heightAfter_eq_list' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_map_flipStep' depends on axioms: [propext]
'stepWord' does not depend on any axioms
'length_stepWord' depends on axioms: [propext, Quot.sound]
'heightAfter_eq_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'count_U_add_count_D' depends on axioms: [propext, Quot.sound]
'ofStepWord' does not depend on any axioms
'stepWord_ofStepWord' depends on axioms: [propext, Quot.sound]
'ofStepWord_stepWord' depends on axioms: [propext, Quot.sound]
'pathDyckEquiv' depends on axioms: [propext, Classical.choice, Quot.sound]
'pathDyckEquiv_toList' depends on axioms: [propext, Classical.choice, Quot.sound]
'nestEquiv' depends on axioms: [propext, Classical.choice, Quot.sound]
'paths_ending_at_height_eq_choose' depends on axioms: [propext, Classical.choice, Quot.sound]
'never_below_zero_returns_eq_catalan' depends on axioms: [propext, Classical.choice, Quot.sound]
'strictly_above_zero_returns_eq_catalan_pred' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the ten-flip numbers, so expect one to stop the program.
> - **Twelve flips.** Set `N` to `12`: 4,096 runs, 924 ending level, 132 never below zero, 42 excursions. The second assert stops it, since 924 is not 252.
> - **Allow a touch at zero.** Change `inner > 0` to `inner >= 0`: the listed strictly-above count climbs from 14 to 42 while the closed form still says 14, and the third assert stops it.
> - **Share among m instead of m + 1.** Change `// (m + 1)` to `// m` in `catalan`: the closed form returns 50 where the listing counts 42, and the third assert stops it.

---

## The usual mistake

> [!warning]
> **Treating "ends level" as the ordinary outcome.** Zero is the single most crowded finish and still takes only 252 of the 1,024 runs, under a quarter. The gap widens with every flip: the row doubles, its middle entry does not.
>
> - **Reading the height into the choice count.** C(10, 2) for a finish at +2 gives 45. The lower slot takes the head count, 6: C(10, 6) = 210.
> - **Forgetting parity.** Ten flips ending at +1 is not a rare path; it is no path. The count is 0.
> - **Sharing the middle entry among the wrong number.** 252 divided by 5 is 50.4, which cannot count anything. The divisor is 6.
> - **Running "never below zero" and "strictly above zero" together.** Different demands, different counts: 42 and 14.

---

## Where you meet it in real life

- **Vote counting.** A tally that must never let the trailing candidate lead is a path that must never dip below zero — see [The reflection principle](02-reflection-principle-and-ballot-problem.md).
- **Balanced brackets.** Read a head as an opening bracket and a tail as a closing one: the paths that never dip below zero are the strings that never close what was not opened, 42 of them on ten symbols ([Catalan everywhere](04-catalan-bijections.md)).
- **Grids.** Turn each head into a step east and each tail into a step north and the path becomes a route across a grid ([Lattice paths](01-lattice-paths.md)).

> **Say it back**
> A run of coin flips scored +1 and −1 draws a path, and the path is fixed by which flips were heads. The ending height fixes the head count, (n + h)/2, so the paths ending there number C(n, (n+h)/2): 210 endings at +2 and 252 at zero, out of 1,024 runs. Of those 252, the ones that never dip below zero number 42, the middle entry shared among six. The ones staying strictly above zero number 14, two flips forced and a shorter count left.

---

## What this builds on

- [Catalan numbers](03-catalan-numbers.md): why the paths that never dip below zero are the middle entry shared among m + 1, and the sequence 1, 1, 2, 5, 14, 42 this card lands on twice.
- [The middle of the row](../03-Binomial%20Coefficients%20and%20Identities/07-central-binomial-and-bounds.md): C(2m, m) as the biggest entry of an even row, and how large it is.

## Where this goes next

- [Binomial](../../09-Probability%20and%20statistics/03-Discrete%20Distributions/01-bernoulli-and-binomial.md): the same row of counts divided by 1,024, read as chances.
- [Simple random walk](../../11-Stochastic%20processes%20and%20calculus/01-Random%20Walks%20and%20Filtrations/02-simple-random-walk.md): the walk as a process in time, with its long-run behaviour.
- **Probability and statistics.** Divide each count here by 1,024 and it becomes a chance, because a fair coin makes the 1,024 runs equally likely. The shape of the row, high in the middle and thin at the edges, is the bell curve before anyone takes a limit.
- **Stochastic processes.** Shrink the step and speed up the flips and the staircase becomes a continuous wandering line, with these counts surviving in another form.

This card counts and stops there: turning 252 out of 1,024 into a chance is the first thing the probability wing does with these numbers.

---

## Sources

Verified 14 Sep 2026: every link below resolves to the publisher's page.

- Feller, William. *An Introduction to Probability Theory and Its Applications*, Volume 1, 3rd ed. Wiley. [Publisher page](https://www.wiley.com/en-us/An+Introduction+to+Probability+Theory+and+Its+Applications%2C+Volume+1%2C+3rd+Edition-p-9780471257080). Chapter III works these path counts out in full.
- Stanley, Richard P. *Catalan Numbers*. Cambridge University Press, 2015. [Publisher page](https://www.cambridge.org/core/books/catalan-numbers/5441FB5B09E9C01185834D9CBB9DFAD9). The Dyck-path reading of the Catalan numbers.
- Renault, Marc. "Lost (and Found) in Translation: André's Actual Method and Its Application to the Generalized Ballot Problem." *The American Mathematical Monthly* 115, no. 4 (2008). [doi:10.1080/00029890.2008.11920537](https://doi.org/10.1080/00029890.2008.11920537). What André's 1887 method actually was, and how the mirror argument came to carry his name.
- "A000108: Catalan numbers." The On-Line Encyclopedia of Integer Sequences. [Sequence page](https://oeis.org/A000108). The sequence 1, 1, 2, 5, 14, 42, 132 and its path readings.
