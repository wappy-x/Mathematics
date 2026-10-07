---
type: card
wing: 04-Combinatorics and graphs
shelf: Partitions
topic: Splitting a whole number
item: Integer partitions
kind: definition
status: verified
updated: 2026-09-19
needs_first:
  - "[[Cards/04-Combinatorics and graphs/02-Repeats, Groups and Double Counting/02-stars-and-bars|stars-and-bars]]"
next:
  - "[[Cards/04-Combinatorics and graphs/08-Partitions/02-partitions-generating-function|partitions-generating-function]]"
  - "[[Cards/04-Combinatorics and graphs/08-Partitions/06-twelvefold-way|twelvefold-way]]"
tags:
  - mathematics
  - combinatorics and graphs
  - integer-partitions
---

# Integer partitions: a number as a sum of whole parts with order ignored, drawn as rows of dots

Combinatorics and graphs → Partitions → Splitting a whole number → Integer partitions

---

## General Overview

A bar of music holds eight beats. A composer fills it with notes, each note a whole number of beats long: one note of eight beats, or three then three then two, or eight single beats.

Ask something narrower than "which rhythm": which note lengths the bar uses and how many of each, order set aside. Three-three-two and two-three-three are then one answer. There are 22.

Cap every note at three beats and the count drops to 10. Lift that cap and allow at most three notes instead, any lengths: also 10. The match is not luck — one picture turns each restriction into the other.

A whole number written as a sum of whole numbers of at least one, order thrown away, is a **partition** — the word used from here on. Drawn as rows of dots, one row per part, longest on top, it is a **Ferrers diagram**, after Norman Macleod Ferrers, whose argument about these pictures J. J. Sylvester printed in 1853.

**A partition is a whole number written as a sum of whole parts, order discarded; drawn as rows of dots it turns on its diagonal, and the turn trades "how many parts" for "how big the biggest part is".**

**What kind of fact this is:** a definition, since no formula as simple as a binomial coefficient gives the count; the turn that matches few parts with small parts is a theorem, proved on this card in Why it works.

### The picture: eight dots, turned on the diagonal

| 6+1+1, three rows | its turn, 3+1+1+1+1+1 |
| --- | --- |
| ● ● ● ● ● ● | ● ● ● |
| ● | ● |
| ● | ● |
|  | ● |
|  | ● |
|  | ● |

Left: one row per note, longest on top. Right: the same eight dots read down the columns. Three rows, longest six, became six rows, longest three.

---

## The formula

Notation first, in words. A partition is written as its parts joined by plus signs, biggest first: 3+3+2. The number of partitions of $n$ is written $p(n)$, read "p of n".

$$p(n) = \text{how many ways } n = a_1 + a_2 + \cdots + a_r \text{ with } a_1 \ge a_2 \ge \cdots \ge a_r \ge 1$$

**Read it aloud:** count the ways to write the number as a sum of whole numbers of at least one, listed biggest first.

The small numbers are labels, not multiplications: $a_1$ is the first part, $a_2$ the second, $r$ how many parts. Biggest-first throws the order away, so each partition has one legal writing and counting writings counts partitions.

Two capped counts carry this card. $R_k(n)$ counts the partitions of $n$ with at most $k$ parts — few rows of dots. $C_k(n)$ counts those with every part at most $k$ — short rows. They are always equal:

$$R_k(n) = C_k(n)$$

**Read it aloud:** into few parts, or into small parts, is the same number of ways — at eight beats with a cap of three, 10 each.

The capped count is reachable without listing, from smaller capped counts — a **recurrence**:

$$R_k(n) = R_k(n-k) + R_{k-1}(n)$$

Either the partition uses exactly $k$ parts, and then one unit comes off every part, leaving $n-k$ in at most $k$ parts; or it uses fewer than $k$. Start from $R_k(0) = 1$ and $R_0(n) = 0$ for $n$ at least one.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $n$ | the number being split | 8 beats | more splits, fast |
| $p(n)$ | how many partitions $n$ has | 22 | — |
| $a_1$, $a_2$, …, $a_r$ | the parts, biggest first | 3, 3, 2 | — |
| $i$, $a_i$ | a place in the list, and its part | place 2 holds 3 | — |
| $r$ | how many parts | 3 | — |
| $k$ | the cap, on part count or part size | 3 | both capped counts rise |
| $R_k(n)$ | partitions with at most $k$ parts | 10 | — |
| $C_k(n)$ | partitions with every part at most $k$ | 10 | — |

### When it holds

- **Every part is a whole number of at least one.** Allow a part of zero and a split gains endlessly many copies of it: nothing finite to count.
- **The order is thrown away.** Count orders instead and the bar holds 128 rhythms, not 22.
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

Turn 3+1+1+1+1+1 and its columns read six dots, then one, then one: 6+1+1 again. Turning undoes itself, so it pairs the 22 splits of eight off one for one, nothing doubled and nothing stranded. The code turns all 22 twice.

### Step 3: the turn trades rows for the longest row

A turned shape's top row is the original's first column, which holds one dot per row, since every row reaches column one. So the row count before the turn is the biggest part after it.

Read that as a restriction: at most three rows turns into biggest part at most three, and back. Collections matched one for one are the same size ([bijection-and-double-counting](../02-Repeats%2C%20Groups%20and%20Double%20Counting/05-bijection-and-double-counting.md)): the theorem $R_k(n) = C_k(n)$. Both are 10 here, and the code prints the ten pairs.

<details>
<summary>Detailed proof: the turn, written out</summary>

Take parts $a_1 \ge a_2 \ge \cdots \ge a_r \ge 1$ adding to $n$, and let each column's height, up to column $a_1$, be the number of parts reaching it. Heights are at least one, since the first part reaches every column; they never rise going right, since a part reaching one column reaches the one before it; and they add to $n$, each part counted once per column it reaches. So the heights are a partition of $n$ with $a_1$ parts whose first height is $r$: the two numbers traded.

Turn again. A column's height is at least $i$ exactly when $i$ parts or more reach it, which for parts in falling order says the $i$th part reaches it: the new shape has $a_i$ heights of $i$ or more. Its own $i$th column counts just those, so it stands $a_i$ dots tall, and the second turn hands back $a_1, a_2, \ldots, a_r$.

</details>

### Step 4: counting without drawing anything

The recurrence fills capped counts from smaller ones: at most three notes in eight beats is at most three in five beats plus at most two in eight, 5+5 = 10.

For $p(n)$, build up by note length. Start with the one way to fill zero beats and let one-beat notes in: every bar length now has one way. Let two-beat notes in and each bar gains the ways to fill it two beats shorter, every such split being a shorter one with a two-beat note added. Carry on to eight-beat notes and the counts read 1, 1, 2, 3, 5, 7, 11, 15, 22, nothing listed.

That loop written as one line of algebra is Euler's product, the next card ([partitions-generating-function](02-partitions-generating-function.md)).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| splits by note count, 1 to 8 notes | 1+4+5+5+3+2+1+1 | **22** |
| splits by biggest note, 1 to 8 beats | 1+4+5+5+3+2+1+1 | **22 again** |
| at most three notes | 1+4+5 | **10** |
| no note over three beats | 1+4+5 | **10** |
| the same 10 without listing | 5+5 | **10** |

The first two rows agree term by term, not only in total: 5 splits use exactly three notes, and 5 have a biggest note of exactly three beats — the turn, seen as a table.

```
Splits of eight beats by how many notes, one █ per split

1 note     █                    1
2 notes    ████                 4
3 notes    █████                5
4 notes    █████                5
5 notes    ███                  3
6 notes    ██                   2
7 notes    █                    1
8 notes    █                    1
```

The first three bars add to 10: every split playable with at most three notes. Read them as "biggest note is k beats" and they give the 10 with no note over three.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Counting rhythms, order kept | 128 | 3+3+2 and 2+3+3 are one split |
| Stars and bars for three notes | 21 | Three named slots; unnamed, only 5 |
| "At most three" read as "exactly three" | 5 | The one- and two-note splits are dropped |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Three roads meet: listing every split up to eight beats, building the counts up one note length at a time without listing, and the capped recurrence. The turn then runs on the shapes themselves, and the ordered rhythms are enumerated and collapsed, reaching 22 a fourth way.

### Python

```python
# Integer partitions -- the check behind the card.  Nothing is imported.  A bar
# of 8 beats is split into notes a whole number of beats long, order ignored.
# p(n) is reached twice, by listing every split and by a build-up that lists
# none, and the flip of the dot diagram is then run on the splits themselves.
N, K = 8, 3
def splits(n, biggest):                  # road one: list the splits, biggest note first
    if n == 0:
        return [()]
    return [(a,) + r for a in range(min(biggest, n), 0, -1) for r in splits(n - a, a)]
def built_up(n):                         # road two: add one note length at a time
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
def rhythms(n):                          # order kept: every ordered writing of n
    return [()] if n == 0 else [(a,) + r for a in range(1, n + 1) for r in rhythms(n - a)]
def row(name, values):
    print(f"{name:<31}" + "".join(f"{v:>4}" for v in values))
cum = lambda xs: [sum(xs[:i + 1]) for i in range(len(xs))]
show = lambda s: "+".join(str(a) for a in s)
all8 = splits(N, N)
listed = [len(splits(n, n)) for n in range(N + 1)]
exact = [sum(1 for s in all8 if len(s) == k) for k in range(1, N + 1)]
longest = [sum(1 for s in all8 if s[0] == k) for k in range(1, N + 1)]
few_notes, short_notes = [s for s in all8 if len(s) <= K], [s for s in all8 if s[0] <= K]
ordered = rhythms(N)
collapsed = {tuple(sorted(r, reverse=True)) for r in ordered}
pairs = [f"{show(s)}/{show(flip(s))}" for s in few_notes]
print(f"a bar of {N} beats, notes a whole number of beats long, order ignored")
row("beats n", list(range(N + 1)))
row("splits p(n), by listing", listed)
row("splits p(n), by the build-up", built_up(N))
row("notes k, or longest note k", list(range(1, N + 1)))
row("splits with exactly k notes", exact)
row("splits whose longest note is k", longest)
row("splits with at most k notes", cum(exact))
row("splits with no note over k", cum(longest))
print(f"at most {K} notes: {cum(exact)[K - 1]}; no note over {K} beats: {cum(longest)[K - 1]}; "
      f"without listing, R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = {few(5, 3)} + {few(8, 2)} = {few(8, 3)}")
print(f"the flip carries the first collection onto the second, one for one: "
      f"{'yes' if sorted(flip(s) for s in few_notes) == sorted(short_notes) else 'no'}; "
      f"flipping twice returns every split: {'yes' if all(flip(flip(s)) == s for s in all8) else 'no'}")
print(f"the {len(few_notes)} splits with at most {K} notes, each with its flip:")
print("  " + "  ".join(pairs[:5]))
print("  " + "  ".join(pairs[5:]))
print(f"mistake 1, rhythms counted in order: {len(ordered)}, not {listed[N]}")
print(f"mistake 2, stars and bars for three named notes: {sum(1 for r in ordered if len(r) == 3)}, not {exact[2]}")
print(f"mistake 3, at most {K} notes read as exactly {K}: {exact[K - 1]}, not {cum(exact)[K - 1]}")
assert listed == built_up(N) == [1, 1, 2, 3, 5, 7, 11, 15, 22]
assert sorted(flip(s) for s in few_notes) == sorted(short_notes)
assert [few(N, k) for k in range(1, N + 1)] == cum(exact) == cum(longest)
assert collapsed == set(all8) and all(flip(flip(s)) == s for s in all8)
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
a bar of 8 beats, notes a whole number of beats long, order ignored
beats n                           0   1   2   3   4   5   6   7   8
splits p(n), by listing           1   1   2   3   5   7  11  15  22
splits p(n), by the build-up      1   1   2   3   5   7  11  15  22
notes k, or longest note k        1   2   3   4   5   6   7   8
splits with exactly k notes       1   4   5   5   3   2   1   1
splits whose longest note is k    1   4   5   5   3   2   1   1
splits with at most k notes       1   5  10  15  18  20  21  22
splits with no note over k        1   5  10  15  18  20  21  22
at most 3 notes: 10; no note over 3 beats: 10; without listing, R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = 5 + 5 = 10
the flip carries the first collection onto the second, one for one: yes; flipping twice returns every split: yes
the 10 splits with at most 3 notes, each with its flip:
  8/1+1+1+1+1+1+1+1  7+1/2+1+1+1+1+1+1  6+2/2+2+1+1+1+1  6+1+1/3+1+1+1+1+1  5+3/2+2+2+1+1
  5+2+1/3+2+1+1+1  4+4/2+2+2+2  4+3+1/3+2+2+1  4+2+2/3+3+1+1  3+3+2/3+3+2
mistake 1, rhythms counted in order: 128, not 22
mistake 2, stars and bars for three named notes: 21, not 5
mistake 3, at most 3 notes read as exactly 3: 5, not 10
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Integer partitions -- the same check as the Python, in Rust.  No crates.  A bar
// of 8 beats is split into notes a whole number of beats long, order ignored.
// p(n) is reached twice, by listing every split and by a build-up that lists
// none, and the flip of the dot diagram is then run on the splits themselves.
const N: usize = 8;
const K: usize = 3;
fn writings(n: usize, cap: usize, keep_order: bool) -> Vec<Vec<usize>> {
    if n == 0 { return vec![vec![]] }           // road one: list them, biggest note first
    let mut out: Vec<Vec<usize>> = Vec::new();
    for a in (1..=cap.min(n)).rev() {
        for r in writings(n - a, if keep_order { n - a } else { a }, keep_order) { out.push([vec![a], r].concat()) }
    }
    out
}
fn built_up(n: usize) -> Vec<i64> {             // road two: add one note length at a time
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
    let few_notes: Vec<Vec<usize>> = all8.iter().filter(|s| s.len() <= K).cloned().collect();
    let short_notes: Vec<Vec<usize>> = all8.iter().filter(|s| s[0] <= K).cloned().collect();
    let flipped: Vec<Vec<usize>> = few_notes.iter().map(|s| flip(s)).collect();
    let ordered = writings(N, N, true);
    let mut collapsed: Vec<Vec<usize>> = ordered.iter()
        .map(|r| { let mut v = r.clone(); v.sort_by(|a, b| b.cmp(a)); v }).collect();
    collapsed.sort(); collapsed.dedup();
    let pairs: Vec<String> = few_notes.iter().map(|s| format!("{}/{}", show(s), show(&flip(s)))).collect();
    let by_recur: Vec<i64> = (1..=N as i64).map(|k| few(N as i64, k)).collect();
    println!("a bar of {} beats, notes a whole number of beats long, order ignored", N);
    row("beats n", &(0..=N as i64).collect::<Vec<i64>>());
    row("splits p(n), by listing", &listed);
    row("splits p(n), by the build-up", &built_up(N));
    row("notes k, or longest note k", &(1..=N as i64).collect::<Vec<i64>>());
    row("splits with exactly k notes", &exact);
    row("splits whose longest note is k", &longest);
    row("splits with at most k notes", &at_most);
    row("splits with no note over k", &no_over);
    println!("at most {} notes: {}; no note over {} beats: {}; without listing, \
              R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = {} + {} = {}",
             K, at_most[K - 1], K, no_over[K - 1], few(5, 3), few(8, 2), few(8, 3));
    println!("the flip carries the first collection onto the second, one for one: {}; \
              flipping twice returns every split: {}",
             if sort(&flipped) == sort(&short_notes) { "yes" } else { "no" },
             if all8.iter().all(|s| flip(&flip(s)) == *s) { "yes" } else { "no" });
    println!("the {} splits with at most {} notes, each with its flip:", few_notes.len(), K);
    println!("  {}", pairs[..5].join("  "));
    println!("  {}", pairs[5..].join("  "));
    println!("mistake 1, rhythms counted in order: {}, not {}", ordered.len(), listed[N]);
    println!("mistake 2, stars and bars for three named notes: {}, not {}",
             ordered.iter().filter(|r| r.len() == 3).count(), exact[2]);
    println!("mistake 3, at most {} notes read as exactly {}: {}, not {}", K, K, exact[K - 1], at_most[K - 1]);
    assert!(listed == built_up(N) && listed == vec![1, 1, 2, 3, 5, 7, 11, 15, 22]);
    assert!(sort(&flipped) == sort(&short_notes));
    assert!(by_recur == at_most && at_most == no_over);
    assert!(collapsed == sort(&all8) && all8.iter().all(|s| flip(&flip(s)) == *s));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
a bar of 8 beats, notes a whole number of beats long, order ignored
beats n                           0   1   2   3   4   5   6   7   8
splits p(n), by listing           1   1   2   3   5   7  11  15  22
splits p(n), by the build-up      1   1   2   3   5   7  11  15  22
notes k, or longest note k        1   2   3   4   5   6   7   8
splits with exactly k notes       1   4   5   5   3   2   1   1
splits whose longest note is k    1   4   5   5   3   2   1   1
splits with at most k notes       1   5  10  15  18  20  21  22
splits with no note over k        1   5  10  15  18  20  21  22
at most 3 notes: 10; no note over 3 beats: 10; without listing, R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = 5 + 5 = 10
the flip carries the first collection onto the second, one for one: yes; flipping twice returns every split: yes
the 10 splits with at most 3 notes, each with its flip:
  8/1+1+1+1+1+1+1+1  7+1/2+1+1+1+1+1+1  6+2/2+2+1+1+1+1  6+1+1/3+1+1+1+1+1  5+3/2+2+2+1+1
  5+2+1/3+2+1+1+1  4+4/2+2+2+2  4+3+1/3+2+2+1  4+2+2/3+3+1+1  3+3+2/3+3+2
mistake 1, rhythms counted in order: 128, not 22
mistake 2, stars and bars for three named notes: 21, not 5
mistake 3, at most 3 notes read as exactly 3: 5, not 10
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Move the cap.** Set `K` to `4`: nothing breaks, the capped rows agree at 15, and 15 pairs print. The theorem is not about three.
> - **Break the turn.** In `flip`, change `a >= j` to `a > j`: the turned shapes lose a dot and stop adding to eight, so nothing pairs off and the second assert stops the run.
> - **Drop a recurrence term.** In `few`, return `few(n - k, k)` alone: the recurrence road reads 0 where the listing prints 10, and the third assert stops it.

---

## The usual mistake

> [!warning]
> **Counting the rhythms.** Three-three-two and two-three-three are two rhythms and one split. Rhythms give 128 for eight beats, splits 22. Whether order matters is the whole question.
>
> - **Reaching for a formula.** No formula as simple as a binomial coefficient gives $p(n)$; the exact ones are deep and long. The build-up above, or the next card's product, is how the number is got.
> - **Using stars and bars.** Three named notes filling eight beats is 21 ways ([stars-and-bars](../02-Repeats%2C%20Groups%20and%20Double%20Counting/02-stars-and-bars.md)). Take the names off and 5 remain.
> - **Confusing "at most" with "exactly".** At most three notes is 10, exactly three is 5. The capped counts here are all "at most".
> - **Naming the items.** Eight named jobs on identical machines is a different, much larger count ([set-partitions-and-bell-numbers](03-set-partitions-and-bell-numbers.md)). Here the beats are interchangeable.

---

## Where you meet it in real life

- **Rhythm and metre.** The 22 splits of an eight-beat bar are the ingredient lists a composer chooses from, each unfolding into its orderings ([multiset-permutations](../02-Repeats%2C%20Groups%20and%20Double%20Counting/01-multiset-permutations.md)).
- **Cutting stock.** An eight-metre pipe cut into whole-metre pieces: the yard cares which lengths come out, not the order of the cuts. 22 plans, 10 under a three-metre limit.
- **Shuffles by their loops.** Follow each card through a shuffle and the cards fall into closed loops whose lengths partition the pack, so eight cards have 22 shuffle shapes ([permutations-by-cycles](05-permutations-by-cycles.md)).

> **Say it back**
> A partition is a number written as a sum of whole parts, biggest first, order thrown away; eight beats have 22. Drawn as rows of dots, longest on top, it becomes a shape, and reading that shape down its columns gives another partition of the same number. Turning twice returns the original, so the turn pairs the 22 off one for one. Since it swaps the row count with the longest row, at most three notes and no note over three beats must match: 10 each.

---

## What this builds on

- [stars-and-bars](../02-Repeats%2C%20Groups%20and%20Double%20Counting/02-stars-and-bars.md): splitting a total among named bowls, where empty bowls count and a binomial coefficient answers. Take the names off and the formula goes too.

## Where this goes next

- [partitions-generating-function](02-partitions-generating-function.md): the build-up by note length written as one product, Euler's way into the later facts.
- [twelvefold-way](06-twelvefold-way.md): the grid of named-or-unnamed items and boxes, with this card in one of its twelve cells.

The build-up fills a row of counts without saying why they grow as they do; turning the loop into a product makes the pattern visible.

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Olver, F. W. J., et al., eds. *NIST Digital Library of Mathematical Functions*, §26.9, "Integer Partitions: Restricted Number and Part Size." [dlmf.nist.gov/26.9](https://dlmf.nist.gov/26.9). Free. The Ferrers graph, the conjugate, the recurrence of Step 4 (26.9.8), and Table 26.9.1, whose row for eight reads 1, 5, 10, 15, 18, 20, 21, 22 for caps of one to eight.
- O'Connor, J. J., and E. F. Robertson. "Norman Macleod Ferrers." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Ferrers/). Free. Quotes Sylvester's 1853 note crediting Ferrers with the turning argument.
- Andrews, George E. *The Theory of Partitions*. Cambridge University Press, 1984. [doi:10.1017/CBO9780511608650](https://doi.org/10.1017/CBO9780511608650). Chapter 1, the diagrams and capped counts in full.
- Sloane, N. J. A., et al. "A000041: the number of partitions of n." *The On-Line Encyclopedia of Integer Sequences*. [oeis.org/A000041](https://oeis.org/A000041). Free. An independent record of 1, 1, 2, 3, 5, 7, 11, 15, 22.
