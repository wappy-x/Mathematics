# Integer partitions: a number as a sum of whole parts with order ignored, drawn as rows of dots

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Partitions](../README.md#s08) → Integer partitions

---

## General Overview

A steel yard has an eight-metre pipe to cut into whole-metre pieces: one eight-metre length, or pieces of three, three and two metres, or eight one-metre pieces.

The yard cares which lengths come out and how many of each, not the order of the cuts. Three-three-two and two-three-three produce the same bundle of pieces, so they count as one plan. There are 22 plans.

Cap every piece at three metres so it fits in a three-metre van, and the count drops to 10. Lift that cap and allow at most three pieces instead, any lengths: also 10. The match is not luck — one picture turns each restriction into the other.

A whole number written as a sum of whole numbers of at least one, order thrown away, is a **partition**. In the pipe example the card also calls one a **plan**. Drawn as rows of dots, one row per part, longest on top, it is a **Ferrers diagram**, after Norman Macleod Ferrers, whose argument about these pictures J. J. Sylvester printed in 1853.

**A partition splits a whole number into whole parts, order ignored; turning its dot diagram swaps "how many parts" with "biggest part".**

**What kind of fact this is:** a definition, since no simple formula gives the count. The turn matching few parts with small parts is a theorem, proved in Why it works.

### The picture: eight dots, turned on the diagonal

| 6+1+1, three rows | its turn, 3+1+1+1+1+1 |
| --- | --- |
| ● ● ● ● ● ● | ● ● ● |
| ● | ● |
| ● | ● |
|  | ● |
|  | ● |
|  | ● |

Left: one row per piece, longest on top. Right: the same eight dots read down the columns. Three rows, longest six, became six rows, longest three.

---

## The formula

Notation first, in words. A partition is written as its parts joined by plus signs, biggest first: 3+3+2. The number of partitions of $`n`$ is written $`p(n)`$, read "p of n".

```math
p(n) = \text{how many ways } n = a_1 + a_2 + \cdots + a_r \text{ with } a_1 \ge a_2 \ge \cdots \ge a_r \ge 1
```

**Read it aloud:** count the ways to write the number as a sum of whole numbers of at least one, listed biggest first.

The small numbers are labels, not multiplications: $`a_1`$ is the first part, $`a_2`$ the second, $`r`$ how many parts. Biggest-first throws the order away, so each partition has one legal writing and counting writings counts partitions.

Two capped counts carry this card. $`R_k(n)`$ counts the partitions of $`n`$ with at most $`k`$ parts — few rows of dots. $`C_k(n)`$ counts those with every part at most $`k`$ — short rows. They are always equal:

```math
R_k(n) = C_k(n)
```

**Read it aloud:** into few parts, or into small parts, is the same number of ways — at eight metres with a cap of three, 10 each.

The capped count is reachable without listing, from smaller capped counts — a **recurrence**:

```math
R_k(n) = R_k(n-k) + R_{k-1}(n)
```

Either the partition uses exactly $`k`$ parts, and then one unit comes off every part, leaving $`n-k`$ in at most $`k`$ parts; or it uses fewer than $`k`$. Start from $`R_k(0) = 1`$, $`R_0(n) = 0`$ for $`n`$ at least one, and $`R_k(n) = 0`$ whenever $`n`$ is below zero.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`n`$ | the number being split | 8 metres | more plans, fast |
| $`p(n)`$ | how many partitions $`n`$ has | 22 | — |
| $`a_1`$, $`a_2`$, …, $`a_r`$ | the parts, biggest first | 3, 3, 2 | — |
| $`i`$, $`a_i`$ | a place in the list, and its part | place 2 holds 3 | — |
| $`r`$ | how many parts | 3 | — |
| $`k`$ | the cap, on part count or part size | 3 | both capped counts rise |
| $`R_k(n)`$ | partitions with at most $`k`$ parts | 10 | — |
| $`C_k(n)`$ | partitions with every part at most $`k`$ | 10 | — |

### When it holds

- **Every part is a whole number of at least one.** Allow a part of zero and a plan gains endlessly many copies of it: nothing finite to count.
- **The order is thrown away.** Count cut orders instead and the pipe holds 128 sequences, not 22.
- **Zero has one partition, the empty sum.** Set that to nothing and the build-up below cannot start.
- **The turn pairs a cap with the same cap.** Mismatch them and nothing holds: at most three parts is 10, parts of at most four 15.

---

## Why it works

### Step 0: a partition is a shape, not a list

The partition 6+1+1 is not three numbers held in order. Put one row of dots per part, longest at the top, every row starting at the left margin. The rows come sorted, so the shape records the partition and nothing else.

### Step 1: read the shape down its columns

The first column of 6+1+1 is three dots tall; columns two to six hold one dot each. Those heights, written as a partition, are 3+1+1+1+1+1.

It works for every shape. A column's height is how many rows reach that far, and rows never lengthen going down, so heights never rise going right: a legal partition of the same dots. Reading a shape down its columns is taking its **conjugate**; this card calls it the turn.

### Step 2: turning twice gives back the original

Turn 3+1+1+1+1+1 and its columns read six dots, then one, then one: 6+1+1 again. Turning undoes itself, so it pairs the 22 plans of eight off one for one, nothing doubled and nothing stranded. The code turns all 22 twice.

### Step 3: the turn trades rows for the longest row

A turned shape's top row is the original's first column, which holds one dot per row, since every row reaches column one. So the row count before the turn is the biggest part after it.

Read that as a restriction: at most three rows turns into biggest part at most three, and back. Collections matched one for one are the same size ([Bijections and double counting](../02-Repeats%2C%20Groups%20and%20Double%20Counting/05-bijection-and-double-counting.md)): the theorem $`R_k(n) = C_k(n)`$. Both are 10 here, and the code prints the ten pairs.

<details>
<summary>Detailed proof: the turn, written out</summary>

Take parts $`a_1 \ge a_2 \ge \cdots \ge a_r \ge 1`$ adding to $`n`$. For each column up to $`a_1`$, let its height be the number of parts reaching it. Heights are at least one, since $`a_1`$ reaches every column. They never rise going right, since a part reaching one column reaches the one before it.

Each part is counted once per column it reaches, so the heights add to $`n`$. They form a partition of $`n`$ with $`a_1`$ parts whose first height is $`r`$: the two numbers traded.

Turn again. A column's height is at least $`i`$ exactly when at least $`i`$ parts reach it. Because the parts fall, that happens exactly when $`a_i`$ reaches it, so $`a_i`$ columns have height $`i`$ or more. The turned shape's $`i`$th column counts just those, standing $`a_i`$ dots tall, and the second turn hands back $`a_1, a_2, \ldots, a_r`$.

</details>

### Step 4: counting without drawing anything

The recurrence fills capped counts from smaller ones: at most three pieces from eight metres is at most three from five metres plus at most two from eight, 5+5 = 10.

For $`p(n)`$, build up by piece length. Start with the one way to cut zero metres and let one-metre pieces in: every pipe length now has one plan.

Let two-metre pieces in and each pipe gains the plans two metres shorter, since each new plan is a shorter one with a two-metre piece added. Carry on to eight-metre pieces and the counts read 1, 1, 2, 3, 5, 7, 11, 15, 22, nothing listed.

That loop written as one line of algebra is Euler's product, the next card ([Euler's product](02-partitions-generating-function.md)).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| plans by piece count, 1 to 8 pieces | 1+4+5+5+3+2+1+1 | **22** |
| plans by longest piece, 1 to 8 metres | 1+4+5+5+3+2+1+1 | **22 again** |
| at most three pieces | 1+4+5 | **10** |
| no piece over three metres | 1+4+5 | **10** |
| the same 10 without listing | 5+5 | **10** |

The first two rows agree term by term, not only in total: 5 plans use exactly three pieces, and 5 have a longest piece of exactly three metres — the turn, seen as a table.

```
Plans for an 8-metre pipe by how many pieces, one █ per plan

1 piece     █                    1
2 pieces    ████                 4
3 pieces    █████                5
4 pieces    █████                5
5 pieces    ███                  3
6 pieces    ██                   2
7 pieces    █                    1
8 pieces    █                    1
```

The first three bars add to 10: every plan with at most three pieces. Read them as "longest piece is k metres" and they give the 10 with no piece over three metres.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Counting cut orders, order kept | 128 | 3+3+2 and 2+3+3 are one plan |
| Stars and bars for three named pieces | 21 | Three named slots; unnamed, only 5 |
| "At most three" read as "exactly three" | 5 | The one- and two-piece plans are dropped |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Three roads meet: listing every plan up to eight metres, building the counts up one piece length at a time without listing, and the capped recurrence. The turn then runs on the shapes themselves, and the ordered cut sequences are enumerated and collapsed, reaching 22 a fourth way.

### Python

```python
# Integer partitions -- the check behind the card.  Nothing is imported.  An 8-metre
# pipe is cut into whole-metre pieces, order ignored.  p(n) is reached twice, by
# listing every plan and by a build-up that lists none, and the flip of the dot
# diagram is then run on the plans themselves.
N, K = 8, 3
def splits(n, biggest):                  # road one: list the plans, longest piece first
    if n == 0:
        return [()]
    return [(a,) + r for a in range(min(biggest, n), 0, -1) for r in splits(n - a, a)]
def built_up(n):                         # road two: add one piece length at a time
    p = [1] + [0] * n
    for a in range(1, n + 1):
        for i in range(a, n + 1):
            p[i] += p[i - a]
    return p
def few(n, k):                           # road three: R(n,k) = R(n-k,k) + R(n,k-1)
    if n == 0:
        return 1
    return 0 if n < 0 or k == 0 else few(n - k, k) + few(n, k - 1)
def flip(s):                             # the dot diagram turned over: rows become columns
    return tuple(sum(1 for a in s if a >= j) for j in range(1, s[0] + 1))
def ordered_cuts(n):                     # order kept: every ordered sequence of lengths
    return [()] if n == 0 else [(a,) + r for a in range(1, n + 1) for r in ordered_cuts(n - a)]
def row(name, values):
    print(f"{name:<31}" + "".join(f"{v:>4}" for v in values))
cum = lambda xs: [sum(xs[:i + 1]) for i in range(len(xs))]
show = lambda s: "+".join(str(a) for a in s)
all8 = splits(N, N)
listed = [len(splits(n, n)) for n in range(N + 1)]
exact = [sum(1 for s in all8 if len(s) == k) for k in range(1, N + 1)]
longest = [sum(1 for s in all8 if s[0] == k) for k in range(1, N + 1)]
few_pieces, short_pieces = [s for s in all8 if len(s) <= K], [s for s in all8 if s[0] <= K]
ordered = ordered_cuts(N)
collapsed = {tuple(sorted(r, reverse=True)) for r in ordered}
pairs = [f"{show(s)}/{show(flip(s))}" for s in few_pieces]
print(f"an {N}-metre pipe cut into whole-metre pieces, order ignored")
row("metres n", list(range(N + 1)))
row("plans p(n), by listing", listed)
row("plans p(n), by the build-up", built_up(N))
row("pieces k, or longest piece k", list(range(1, N + 1)))
row("plans with exactly k pieces", exact)
row("plans whose longest piece is k", longest)
row("plans with at most k pieces", cum(exact))
row("plans with no piece over k", cum(longest))
print(f"at most {K} pieces: {cum(exact)[K - 1]}; no piece over {K} metres: {cum(longest)[K - 1]}; "
      f"without listing, R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = {few(5, 3)} + {few(8, 2)} = {few(8, 3)}")
print(f"the flip carries the first collection onto the second, one for one: "
      f"{'yes' if sorted(flip(s) for s in few_pieces) == sorted(short_pieces) else 'no'}; "
      f"flipping twice returns every plan: {'yes' if all(flip(flip(s)) == s for s in all8) else 'no'}")
print(f"the {len(few_pieces)} plans with at most {K} pieces, each with its flip:")
print("  " + "  ".join(pairs[:5]))
print("  " + "  ".join(pairs[5:]))
print(f"mistake 1, cut orders counted: {len(ordered)}, not {listed[N]}")
print(f"mistake 2, stars and bars for three named pieces: {sum(1 for r in ordered if len(r) == 3)}, not {exact[2]}")
print(f"mistake 3, at most {K} pieces read as exactly {K}: {exact[K - 1]}, not {cum(exact)[K - 1]}")
assert listed == built_up(N) == [1, 1, 2, 3, 5, 7, 11, 15, 22]
assert sorted(flip(s) for s in few_pieces) == sorted(short_pieces)
assert [few(N, k) for k in range(1, N + 1)] == cum(exact) == cum(longest)
assert collapsed == set(all8) and all(flip(flip(s)) == s for s in all8)
print("ALL CHECKS PASS")
```

**Ran 2026-11-25 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
an 8-metre pipe cut into whole-metre pieces, order ignored
metres n                          0   1   2   3   4   5   6   7   8
plans p(n), by listing            1   1   2   3   5   7  11  15  22
plans p(n), by the build-up       1   1   2   3   5   7  11  15  22
pieces k, or longest piece k      1   2   3   4   5   6   7   8
plans with exactly k pieces       1   4   5   5   3   2   1   1
plans whose longest piece is k    1   4   5   5   3   2   1   1
plans with at most k pieces       1   5  10  15  18  20  21  22
plans with no piece over k        1   5  10  15  18  20  21  22
at most 3 pieces: 10; no piece over 3 metres: 10; without listing, R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = 5 + 5 = 10
the flip carries the first collection onto the second, one for one: yes; flipping twice returns every plan: yes
the 10 plans with at most 3 pieces, each with its flip:
  8/1+1+1+1+1+1+1+1  7+1/2+1+1+1+1+1+1  6+2/2+2+1+1+1+1  6+1+1/3+1+1+1+1+1  5+3/2+2+2+1+1
  5+2+1/3+2+1+1+1  4+4/2+2+2+2  4+3+1/3+2+2+1  4+2+2/3+3+1+1  3+3+2/3+3+2
mistake 1, cut orders counted: 128, not 22
mistake 2, stars and bars for three named pieces: 21, not 5
mistake 3, at most 3 pieces read as exactly 3: 5, not 10
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Integer partitions -- the same check as the Python, in Rust.  No crates.  An 8-metre
// pipe is cut into whole-metre pieces, order ignored.  p(n) is reached twice, by
// listing every plan and by a build-up that lists none, and the flip of the dot
// diagram is then run on the plans themselves.
const N: usize = 8;
const K: usize = 3;
fn writings(n: usize, cap: usize, keep_order: bool) -> Vec<Vec<usize>> {
    if n == 0 { return vec![vec![]] }           // road one: list them, longest piece first
    let mut out: Vec<Vec<usize>> = Vec::new();
    for a in (1..=cap.min(n)).rev() {
        for r in writings(n - a, if keep_order { n - a } else { a }, keep_order) { out.push([vec![a], r].concat()) }
    }
    out
}
fn built_up(n: usize) -> Vec<i64> {             // road two: add one piece length at a time
    let mut p = vec![0i64; n + 1]; p[0] = 1;
    for a in 1..=n { for i in a..=n { p[i] += p[i - a] } }
    p
}
fn few(n: i64, k: i64) -> i64 {                 // road three: R(n,k) = R(n-k,k) + R(n,k-1)
    if n == 0 { return 1 }
    if n < 0 || k == 0 { return 0 }
    few(n - k, k) + few(n, k - 1)
}
fn flip(s: &[usize]) -> Vec<usize> {            // the diagram turned over: rows become columns
    (1..=s[0]).map(|j| s.iter().filter(|&&a| a >= j).count()).collect()
}
fn show(s: &[usize]) -> String { s.iter().map(|a| a.to_string()).collect::<Vec<String>>().join("+") }
fn sort(v: &[Vec<usize>]) -> Vec<Vec<usize>> { let mut o = v.to_vec(); o.sort(); o }
fn cum(xs: &[i64]) -> Vec<i64> { xs.iter().scan(0i64, |a, &x| { *a += x; Some(*a) }).collect() }
fn row(name: &str, values: &[i64]) {
    let mut line = format!("{:<31}", name);
    for v in values { line.push_str(&format!("{:>4}", v)) }
    println!("{}", line);
}
fn main() {
    let all8 = writings(N, N, false);
    let listed: Vec<i64> = (0..=N).map(|n| writings(n, n, false).len() as i64).collect();
    let exact: Vec<i64> = (1..=N).map(|k| all8.iter().filter(|s| s.len() == k).count() as i64).collect();
    let longest: Vec<i64> = (1..=N).map(|k| all8.iter().filter(|s| s[0] == k).count() as i64).collect();
    let (at_most, no_over) = (cum(&exact), cum(&longest));
    let few_pieces: Vec<Vec<usize>> = all8.iter().filter(|s| s.len() <= K).cloned().collect();
    let short_pieces: Vec<Vec<usize>> = all8.iter().filter(|s| s[0] <= K).cloned().collect();
    let flipped: Vec<Vec<usize>> = few_pieces.iter().map(|s| flip(s)).collect();
    let ordered = writings(N, N, true);
    let mut collapsed: Vec<Vec<usize>> = ordered.iter()
        .map(|r| { let mut v = r.clone(); v.sort_by(|a, b| b.cmp(a)); v }).collect();
    collapsed.sort(); collapsed.dedup();
    let pairs: Vec<String> = few_pieces.iter().map(|s| format!("{}/{}", show(s), show(&flip(s)))).collect();
    let by_recur: Vec<i64> = (1..=N as i64).map(|k| few(N as i64, k)).collect();
    println!("an {}-metre pipe cut into whole-metre pieces, order ignored", N);
    row("metres n", &(0..=N as i64).collect::<Vec<i64>>());
    row("plans p(n), by listing", &listed);
    row("plans p(n), by the build-up", &built_up(N));
    row("pieces k, or longest piece k", &(1..=N as i64).collect::<Vec<i64>>());
    row("plans with exactly k pieces", &exact);
    row("plans whose longest piece is k", &longest);
    row("plans with at most k pieces", &at_most);
    row("plans with no piece over k", &no_over);
    println!("at most {} pieces: {}; no piece over {} metres: {}; without listing, \
              R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = {} + {} = {}",
             K, at_most[K - 1], K, no_over[K - 1], few(5, 3), few(8, 2), few(8, 3));
    println!("the flip carries the first collection onto the second, one for one: {}; \
              flipping twice returns every plan: {}",
             if sort(&flipped) == sort(&short_pieces) { "yes" } else { "no" },
             if all8.iter().all(|s| flip(&flip(s)) == *s) { "yes" } else { "no" });
    println!("the {} plans with at most {} pieces, each with its flip:", few_pieces.len(), K);
    println!("  {}", pairs[..5].join("  "));
    println!("  {}", pairs[5..].join("  "));
    println!("mistake 1, cut orders counted: {}, not {}", ordered.len(), listed[N]);
    println!("mistake 2, stars and bars for three named pieces: {}, not {}",
             ordered.iter().filter(|r| r.len() == 3).count(), exact[2]);
    println!("mistake 3, at most {} pieces read as exactly {}: {}, not {}", K, K, exact[K - 1], at_most[K - 1]);
    assert!(listed == built_up(N) && listed == vec![1, 1, 2, 3, 5, 7, 11, 15, 22]);
    assert!(sort(&flipped) == sort(&short_pieces));
    assert!(by_recur == at_most && at_most == no_over);
    assert!(collapsed == sort(&all8) && all8.iter().all(|s| flip(&flip(s)) == *s));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-25 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
an 8-metre pipe cut into whole-metre pieces, order ignored
metres n                          0   1   2   3   4   5   6   7   8
plans p(n), by listing            1   1   2   3   5   7  11  15  22
plans p(n), by the build-up       1   1   2   3   5   7  11  15  22
pieces k, or longest piece k      1   2   3   4   5   6   7   8
plans with exactly k pieces       1   4   5   5   3   2   1   1
plans whose longest piece is k    1   4   5   5   3   2   1   1
plans with at most k pieces       1   5  10  15  18  20  21  22
plans with no piece over k        1   5  10  15  18  20  21  22
at most 3 pieces: 10; no piece over 3 metres: 10; without listing, R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = 5 + 5 = 10
the flip carries the first collection onto the second, one for one: yes; flipping twice returns every plan: yes
the 10 plans with at most 3 pieces, each with its flip:
  8/1+1+1+1+1+1+1+1  7+1/2+1+1+1+1+1+1  6+2/2+2+1+1+1+1  6+1+1/3+1+1+1+1+1  5+3/2+2+2+1+1
  5+2+1/3+2+1+1+1  4+4/2+2+2+2  4+3+1/3+2+2+1  4+2+2/3+3+1+1  3+3+2/3+3+2
mistake 1, cut orders counted: 128, not 22
mistake 2, stars and bars for three named pieces: 21, not 5
mistake 3, at most 3 pieces read as exactly 3: 5, not 10
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's facts for every whole number and every cap, not just for eight metres.

- Few parts or small parts, the same count: $`R_k(n) = C_k(n)`$.
- The turn gives a partition of the same number, and turning twice gives back the original.
- The turn swaps the number of parts with the biggest part.
- The recurrence $`R_k(n) = R_k(n-k) + R_{k-1}(n)`$ holds whenever $`k`$ is at least one and $`n`$ is at least $`k`$.
- Its starting values hold too: $`R_k(0) = 1`$, and $`R_0(n) = 0`$ for $`n`$ at least one.
- For an 8-metre pipe: 10 plans with at most three pieces, 10 with no piece over three metres, 5 with exactly three, 15 with none over four.

The count of 22, the build-up by piece length and the ten printed pairs are left to the Python and Rust checks.

```lean
-- Integer partitions: for every n and every cap k, the partitions of n with at most k parts are exactly as many as those with every part at most k, because turning the dot diagram swaps the part count with the biggest part and undoes itself.
import Mathlib.Combinatorics.Enumerative.Partition.YoungDiagram
import Mathlib.Tactic.NormNum.Basic

theorem ip_helper_rowLens_sup (μ : YoungDiagram) :
    (μ.rowLens : Multiset ℕ).sup = μ.rowLen 0 := by
  apply le_antisymm
  · apply Multiset.sup_le.mpr
    intro b hb
    rw [Multiset.mem_coe, YoungDiagram.rowLens, List.mem_map] at hb
    obtain ⟨i, -, rfl⟩ := hb
    exact μ.rowLen_anti 0 i (Nat.zero_le i)
  · rcases Nat.eq_zero_or_pos (μ.rowLen 0) with h | h
    · rw [h]; exact Nat.zero_le _
    · apply Multiset.le_sup
      rw [Multiset.mem_coe, YoungDiagram.rowLens, List.mem_map]
      refine ⟨0, ?_, rfl⟩
      rw [List.mem_range, ← YoungDiagram.mem_iff_lt_colLen, YoungDiagram.mem_iff_lt_rowLen]
      exact h

theorem ip_helper_card_conjugate {n : ℕ} (p : Nat.Partition n) :
    Multiset.card p.conjugate.parts = p.parts.sup := by
  have h1 : p.parts = ((YoungDiagram.ofPartition p).rowLens : Multiset ℕ) := by
    rw [YoungDiagram.rowLens_ofPartition_eq_sort_parts, Multiset.sort_eq]
  have h2 : p.conjugate.parts = ((YoungDiagram.ofPartition p).transpose.rowLens : Multiset ℕ) :=
    rfl
  rw [h2, h1, ip_helper_rowLens_sup, Multiset.coe_card, YoungDiagram.length_rowLens,
    YoungDiagram.colLen_transpose]

theorem ip_helper_sup_conjugate {n : ℕ} (p : Nat.Partition n) :
    p.conjugate.parts.sup = Multiset.card p.parts := by
  have := ip_helper_card_conjugate p.conjugate
  rw [Nat.Partition.conjugate_conjugate] at this
  exact this.symm

/-- Add one part `a` to a partition of `n`, giving a partition of `n + a`. -/
def ip_helper_cons {n : ℕ} (a : ℕ) (ha : 0 < a) (q : Nat.Partition n) : Nat.Partition (n + a) where
  parts := a ::ₘ q.parts
  parts_pos := by
    intro i hi
    rcases Multiset.mem_cons.mp hi with rfl | hi
    · exact ha
    · exact q.parts_pos hi
  parts_sum := by rw [Multiset.sum_cons, q.parts_sum, Nat.add_comm]

theorem ip_helper_parts_at_most_recurrence (n k : ℕ) :
    (Finset.univ.filter (fun p : Nat.Partition (n + (k + 1)) => ∀ i ∈ p.parts, i ≤ k + 1)).card =
      (Finset.univ.filter (fun p : Nat.Partition n => ∀ i ∈ p.parts, i ≤ k + 1)).card +
        (Finset.univ.filter (fun p : Nat.Partition (n + (k + 1)) => ∀ i ∈ p.parts, i ≤ k)).card := by
  rw [← Finset.card_filter_add_card_filter_not
    (fun p : Nat.Partition (n + (k + 1)) => k + 1 ∈ p.parts)]
  congr 1
  · symm
    apply Finset.card_bij (fun q _ => ip_helper_cons (k + 1) (Nat.succ_pos k) q)
    · intro q hq
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hq ⊢
      refine ⟨?_, Multiset.mem_cons_self _ _⟩
      intro i hi
      rcases Multiset.mem_cons.mp hi with rfl | hi
      · exact le_rfl
      · exact hq i hi
    · intro q₁ _ q₂ _ h
      have := congrArg Nat.Partition.parts h
      exact Nat.Partition.ext ((Multiset.cons_inj_right _).mp this)
    · intro p hp
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hp
      obtain ⟨hle, hmem⟩ := hp
      refine ⟨⟨p.parts.erase (k + 1), fun hi => p.parts_pos (Multiset.mem_of_mem_erase hi), ?_⟩,
        ?_, ?_⟩
      · have := Multiset.sum_erase hmem
        rw [p.parts_sum] at this
        omega
      · simp only [Finset.mem_filter, Finset.mem_univ, true_and]
        intro i hi
        exact hle i (Multiset.mem_of_mem_erase hi)
      · apply Nat.Partition.ext
        exact Multiset.cons_erase hmem
  · congr 1
    ext p
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    constructor
    · rintro ⟨h1, h2⟩ i hi
      have := h1 i hi
      rcases Nat.lt_or_ge i (k + 1) with h | h
      · omega
      · have : i = k + 1 := by omega
        subst this; exact absurd hi h2
    · intro h
      refine ⟨fun i hi => (h i hi).trans (Nat.le_succ k), fun hi => ?_⟩
      have := h _ hi; omega

#print axioms ip_helper_rowLens_sup
#print axioms ip_helper_card_conjugate
#print axioms ip_helper_sup_conjugate
#print axioms ip_helper_cons
#print axioms ip_helper_parts_at_most_recurrence

/-- Few parts or small parts, the same count. For every whole number n and every cap k, the
partitions of n with at most k parts are exactly as many as the partitions of n whose every
part is at most k: R_k(n) = C_k(n). -/
theorem card_at_most_k_parts_eq_card_parts_at_most_k (n k : ℕ) :
    (Finset.univ.filter (fun p : Nat.Partition n => Multiset.card p.parts ≤ k)).card =
      (Finset.univ.filter (fun p : Nat.Partition n => ∀ i ∈ p.parts, i ≤ k)).card := by
  apply Finset.card_nbij' Nat.Partition.conjugate Nat.Partition.conjugate
  · intro p hp
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hp ⊢
    intro i hi
    exact (Multiset.le_sup hi).trans ((ip_helper_sup_conjugate p) ▸ hp)
  · intro p hp
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hp ⊢
    rw [ip_helper_card_conjugate]
    exact Multiset.sup_le.mpr hp
  · intro p _; exact Nat.Partition.conjugate_conjugate p
  · intro p _; exact Nat.Partition.conjugate_conjugate p

/-- The turn. Reading a partition's dot diagram down its columns (its conjugate) gives a
partition of the same number; turning twice gives back the original; and the turn trades the
number of parts with the biggest part (both read as 0 for the empty partition of 0). -/
theorem conjugate_swaps_part_count_and_biggest_part (n : ℕ)
    (p : Nat.Partition n) :
    p.conjugate.conjugate = p ∧
      Multiset.card p.conjugate.parts = p.parts.sup ∧
      p.conjugate.parts.sup = Multiset.card p.parts := by
  exact ⟨Nat.Partition.conjugate_conjugate p, ip_helper_card_conjugate p,
    ip_helper_sup_conjugate p⟩

/-- The capped count without listing. Zero has one partition into at most k parts (the empty
sum); a positive number has none into at most 0 parts; and for a cap k of at least one and n of
at least k, R_k(n) = R_k(n - k) + R_{k-1}(n): either exactly k parts, and one unit comes off
each, or fewer than k parts. -/
theorem at_most_k_parts_recurrence (n k : ℕ) :
    (Finset.univ.filter (fun p : Nat.Partition 0 => Multiset.card p.parts ≤ k)).card = 1 ∧
      (Finset.univ.filter (fun p : Nat.Partition (n + 1) => Multiset.card p.parts ≤ 0)).card = 0 ∧
      (Finset.univ.filter
          (fun p : Nat.Partition (n + (k + 1)) => Multiset.card p.parts ≤ k + 1)).card =
        (Finset.univ.filter (fun p : Nat.Partition n => Multiset.card p.parts ≤ k + 1)).card +
          (Finset.univ.filter
            (fun p : Nat.Partition (n + (k + 1)) => Multiset.card p.parts ≤ k)).card := by
  refine ⟨?_, ?_, ?_⟩
  · rw [Finset.card_eq_one]
    refine ⟨⟨0, by simp, by simp⟩, ?_⟩
    ext p
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton]
    have hp : p.parts = 0 := by
      have h := p.parts_sum
      rw [Multiset.sum_eq_zero_iff] at h
      exact Multiset.eq_zero_of_forall_notMem fun i hi => by
        have := p.parts_pos hi; have := h i hi; omega
    constructor
    · intro _; exact Nat.Partition.ext hp
    · intro _; rw [hp]; simp
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro p _ h
    have h0 : p.parts = 0 := Multiset.card_eq_zero.mp (Nat.le_zero.mp h)
    have := p.parts_sum
    rw [h0, Multiset.sum_zero] at this
    omega
  · rw [card_at_most_k_parts_eq_card_parts_at_most_k, card_at_most_k_parts_eq_card_parts_at_most_k,
      card_at_most_k_parts_eq_card_parts_at_most_k]
    exact ip_helper_parts_at_most_recurrence n k

-- The card's worked numbers for an 8-metre pipe.
-- Plans by piece count, 1 to 8 pieces, add to 22; so do plans by longest piece.
example : 1 + 4 + 5 + 5 + 3 + 2 + 1 + 1 = 22 := by norm_num
-- At most three pieces: a ≥ b ≥ c ≥ 0 with a + b + c = 8 (a 0 means an unused slot): 10 plans.
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => t.2.2 ≤ t.2.1 ∧ t.2.1 ≤ t.1 ∧ t.1 + t.2.1 + t.2.2 = 8)).card = 10 := by decide
-- No piece over three metres: x ones, y twos and z threes with x + 2y + 3z = 8: also 10 plans.
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => t.1 + 2 * t.2.1 + 3 * t.2.2 = 8)).card = 10 := by decide
-- Exactly three pieces: 5 plans, half of the 10 ("at most" read as "exactly").
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => 1 ≤ t.2.2 ∧ t.2.2 ≤ t.2.1 ∧ t.2.1 ≤ t.1 ∧ t.1 + t.2.1 + t.2.2 = 8)).card = 5 := by
  decide
-- The recurrence: R_3(8) = R_3(5) + R_2(8) = 5 + 5 = 10.
example : ((Finset.range 6 ×ˢ Finset.range 6 ×ˢ Finset.range 6).filter
    (fun t => t.2.2 ≤ t.2.1 ∧ t.2.1 ≤ t.1 ∧ t.1 + t.2.1 + t.2.2 = 5)).card = 5 := by decide
example : ((Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => t.2 ≤ t.1 ∧ t.1 + t.2 = 8)).card = 5 := by decide
example : 5 + 5 = 10 := by norm_num
-- Mismatched caps: pieces of at most four metres give 15 plans, not 10.
example : ((Finset.range 9 ×ˢ Finset.range 5 ×ˢ Finset.range 3 ×ˢ Finset.range 3).filter
    (fun t => t.1 + 2 * t.2.1 + 3 * t.2.2.1 + 4 * t.2.2.2 = 8)).card = 15 := by decide
-- The turn of 6+1+1: column heights 3, 1, 1, 1, 1, 1; turning again gives 6, 1, 1.
example : (List.range 6).map (fun j => ([6, 1, 1].filter (fun a => j + 1 ≤ a)).length)
    = [3, 1, 1, 1, 1, 1] := by decide
example : (List.range 3).map (fun j => ([3, 1, 1, 1, 1, 1].filter (fun a => j + 1 ≤ a)).length)
    = [6, 1, 1] := by decide
-- Stars and bars for three named pieces: 21 ordered triples of at least 1 adding to 8, not 5.
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => 1 ≤ t.1 ∧ 1 ≤ t.2.1 ∧ 1 ≤ t.2.2 ∧ t.1 + t.2.1 + t.2.2 = 8)).card = 21 := by decide
-- Cut orders with order kept: 2 ^ 7 = 128 for an 8-metre pipe, not 22.
example : 2 ^ (8 - 1) = 128 := by norm_num

#print axioms card_at_most_k_parts_eq_card_parts_at_most_k
#print axioms conjugate_swaps_part_count_and_biggest_part
#print axioms at_most_k_parts_recurrence
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'ip_helper_rowLens_sup' depends on axioms: [propext, Classical.choice, Quot.sound]
'ip_helper_card_conjugate' depends on axioms: [propext, Classical.choice, Quot.sound]
'ip_helper_sup_conjugate' depends on axioms: [propext, Classical.choice, Quot.sound]
'ip_helper_cons' depends on axioms: [propext, Quot.sound]
'ip_helper_parts_at_most_recurrence' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_at_most_k_parts_eq_card_parts_at_most_k' depends on axioms: [propext, Classical.choice, Quot.sound]
'conjugate_swaps_part_count_and_biggest_part' depends on axioms: [propext, Classical.choice, Quot.sound]
'at_most_k_parts_recurrence' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Move the cap.** Set `K` to `4`: nothing breaks, the capped rows agree at 15, and 15 pairs print. The theorem is not about three.
> - **Break the turn.** In `flip`, change `a >= j` to `a > j`: the turned shapes lose a dot and stop adding to eight, so nothing pairs off and the second assert stops the run.
> - **Drop a recurrence term.** In `few`, return `few(n - k, k)` alone: the recurrence road reads 0 where the listing prints 10, and the third assert stops it.

---

## The usual mistake

> [!warning]
> **Counting cut orders.** Three-three-two and two-three-three are two cut orders and one plan. Cut orders give 128 for an 8-metre pipe, plans 22. Whether order matters is the whole question.
>
> - **Reaching for a formula.** No formula as simple as a binomial coefficient gives $`p(n)`$; the exact ones are deep and long. The build-up above, or the next card's product, is how the number is got.
> - **Using stars and bars.** Three named pieces adding to eight metres is 21 ways ([Stars and bars](../02-Repeats%2C%20Groups%20and%20Double%20Counting/02-stars-and-bars.md)). Take the names off and 5 remain.
> - **Confusing "at most" with "exactly".** At most three pieces is 10, exactly three is 5. The capped counts here are all "at most".
> - **Naming the items.** Eight named jobs on identical machines is a different, much larger count ([Set partitions and Bell numbers](03-set-partitions-and-bell-numbers.md)). Here the metre units are interchangeable.

---

## Where you meet it in real life

- **Cutting stock.** Steel pipes, timber beams and paper rolls cut to whole-unit lengths: a yard cares which lengths come out, not the order of the cuts.
- **Rhythm and metre.** A composer filling an eight-beat bar picks one of the 22 note-length tallies, then arranges it into ordered rhythms ([Arranging with repeats](../02-Repeats%2C%20Groups%20and%20Double%20Counting/01-multiset-permutations.md)) — where order does matter, giving 128 rhythms.
- **Shuffles by their loops.** Follow each card through a shuffle and the cards fall into closed loops whose lengths partition the pack, so eight cards have 22 shuffle shapes ([Counting shuffles by their loops](05-permutations-by-cycles.md)).

> **Say it back**
> A partition is a number written as a sum of whole parts, biggest first, order thrown away; eight metres have 22 plans. Drawn as rows of dots, longest on top, it becomes a shape, and reading that shape down its columns gives another partition of the same number. Turning twice returns the original, so the turn pairs the 22 off one for one. Since it swaps the row count with the longest row, at most three pieces and no piece over three metres must match: 10 each.

---

## What this builds on

- [Stars and bars](../02-Repeats%2C%20Groups%20and%20Double%20Counting/02-stars-and-bars.md): splitting a total among named bowls, where empty bowls count and a binomial coefficient answers. Take the names off and the formula goes too.

## Where this goes next

- [Euler's product](02-partitions-generating-function.md): the build-up by piece length written as one product, Euler's way into the later facts.
- [The twelvefold way](06-twelvefold-way.md): the grid of named-or-unnamed items and boxes, with this card in one of its twelve cells.
- [Young tableaux and the hook length formula](07-young-tableaux-and-hook-lengths.md): fill a partition's diagram with 1 to n rising along rows and down columns, and n! over the product of hook lengths counts the ways.
- [The RSK correspondence](08-rsk-correspondence.md): every shuffle becomes a pair of same-shaped tableaux, so the squared tableau counts add up to n!, and the first row is the longest rising run.

The build-up fills a row of counts one loop at a time; turning that loop into one product lets factor cancellations prove new partition identities at a stroke.

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Olver, F. W. J., et al., eds. *NIST Digital Library of Mathematical Functions*, §26.9, "Integer Partitions: Restricted Number and Part Size." [dlmf.nist.gov/26.9](https://dlmf.nist.gov/26.9). Free. The Ferrers graph, the conjugate, the recurrence of Step 4 (26.9.8), and Table 26.9.1, whose row for eight reads 1, 5, 10, 15, 18, 20, 21, 22 for caps of one to eight.
- O'Connor, J. J., and E. F. Robertson. "Norman Macleod Ferrers." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Ferrers/). Free. Quotes Sylvester's 1853 note crediting Ferrers with the turning argument.
- Andrews, George E. *The Theory of Partitions*. Cambridge University Press, 1984. [doi:10.1017/CBO9780511608650](https://doi.org/10.1017/CBO9780511608650). Chapter 1, the diagrams and capped counts in full.
- Sloane, N. J. A., et al. "A000041: the number of partitions of n." *The On-Line Encyclopedia of Integer Sequences*. [oeis.org/A000041](https://oeis.org/A000041). Free. An independent record of 1, 1, 2, 3, 5, 7, 11, 15, 22.
