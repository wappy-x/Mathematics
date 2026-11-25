# Steiner triple systems: triples covering every pair exactly once, which exist exactly when v leaves remainder 1 or 3 on division by 6

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Designs](../README.md#s16) → Steiner triple systems

---

## General Overview

A test kitchen has 9 recipes, numbered 1 to 9, and wants every pair compared side by side. Each taster tries 3 recipes at a time.

Lay the 9 points in a 3 by 3 grid. Draw the 3 rows, the 3 columns, and the diagonals, letting a diagonal run off one edge and come back on the opposite edge. That gives 3 diagonals each way, 12 lines in all, one triple per taster. Any two of the 9 points lie on exactly one of the 12 lines.

A list of triples with that property is a **Steiner triple system**: v points and 3-point blocks (triples) such that every pair of points lies in exactly one triple. It is a block design ([Block designs](01-block-designs-and-fishers-inequality.md)).

It works for 9 points but not for 10 or 11. This card proves which v are possible, builds a system for each, and solves an 1850 puzzle: walk 15 schoolgirls in rows of three for 7 days so no two walk together twice.

**Counting pairs forces v to leave remainder 1 or 3 on division by 6, and for every such v a triple system can be built, so these are exactly the sizes that work.**

**What kind of fact this is:** a theorem, proved in Why it works: the necessary condition and the remainder-3 construction in full, the remainder-1 construction in outline. The code checks both.

### The picture: the 12 lines of the 3 by 3 grid

| | column 0 | column 1 | column 2 |
| --- | :---: | :---: | :---: |
| **row 0** | 1 | 2 | 3 |
| **row 1** | 4 | 5 | 6 |
| **row 2** | 7 | 8 | 9 |

The 12 lines, in four directions of three:

| Direction | The three lines |
| --- | --- |
| rows | 1 2 3 · 4 5 6 · 7 8 9 |
| columns | 1 4 7 · 2 5 8 · 3 6 9 |
| diagonals, wrapping round | 1 5 9 · 2 6 7 · 3 4 8 |
| anti-diagonals, wrapping round | 1 6 8 · 2 4 9 · 3 5 7 |

Each direction uses every point once, so every point sits on 4 lines.

---

## The formula

Notation: $`v`$ counts points, $`b`$ counts triples, and $`r`$ counts the triples through one point. "$`a \equiv c \pmod 6`$" says a and c leave the same remainder on division by 6 ([Congruence](../../02-Number%20theory/03-Clock%20Arithmetic/01-congruence-mod-n.md)).

```math
r = \frac{v-1}{2}, \qquad b = \frac{v(v-1)}{6}, \qquad \text{a system exists} \iff v \equiv 1 \text{ or } 3 \pmod 6
```

**Read it aloud:** each point is on (v − 1)/2 triples, there are v(v − 1)/6 triples in all, and a system exists exactly when v leaves remainder 1 or 3 on division by 6.

The construction for $`v = 6n + 3`$, due to R. C. Bose (1939), uses a **halving rule** on the numbers $`0`$ to $`2n`$, counted round a clock of $`2n + 1`$:

```math
x \circ y = (n + 1)(x + y) \bmod (2n + 1)
```

**Read it aloud:** add x and y, then halve round the clock; multiplying by n + 1 halves, because twice n + 1 is one past the clock size.

The points are $`(x, i)`$: number $`x`$ on layer $`i`$, with three layers counted round a clock of 3. Two kinds of triple:

- **upright:** $`\{(x, 0), (x, 1), (x, 2)\}`$, one for each $`x`$;
- **rule:** $`\{(x, i), (y, i), (x \circ y, i + 1)\}`$, one for each layer $`i`$ and each pair $`x \ne y`$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`v`$ | number of points | 9 grid points; 15 girls | more triples |
| $`b`$ | number of triples | 12 lines; 35 walking rows | grows with v |
| $`r`$ | triples through one point | 4 lines; 7 days | grows with v |
| $`a \equiv c \pmod 6`$ | same remainder on division by 6 | 9 and 15 both leave 3 | — |
| $`n`$ | size setting: v = 6n + 3 or 6n + 1 | 1, for v = 9 | the next size |
| $`(x, i)`$; $`y`$, $`z`$ | point number x on layer i; y, z: other point numbers | x from 0 to 2, layers 0 to 2 | — |
| $`x \circ y`$; $`s`$ | x + y halved round the clock; s: the sum Skolem's rule halves | the third number of a rule triple | — |
| $`\infty`$ | the extra point in Skolem's method | the 7th point when v = 7 | — |

### When it holds

- **Every pair exactly once.** Let each pair sit in two triples and the mod-6 rule no longer applies.
- **Blocks of exactly 3.** Bigger blocks give a different divisibility condition; the mod-6 rule is for triples.
- **An odd clock for halving.** On an even clock, 2 has no partner multiplying to 1, so halving fails; v = 6n + 1 needs Skolem's changed rule.
- **Three layers.** Of any two different layers, one comes right after the other round the clock of 3, so one rule reaches every cross-layer pair.

---

## Why it works

### Step 0: count the same pairs two ways

Each pair is in one triple and each triple holds 3 pairs. So counting pairs directly and triple by triple must agree.

### Step 1: around one point, v must be odd

Fix one point. It pairs with the other $`v - 1`$ points, and each triple through it covers 2 of those pairs, so

```math
r = \frac{v - 1}{2}
```

For $`r`$ to be whole, v must be odd. On the grid, 8 partners in twos give 4 lines.

### Step 2: over the whole set, 6 must divide v(v − 1)

There are $`v(v-1)/2`$ pairs in all ([Block designs](01-block-designs-and-fishers-inequality.md) counts them the same way). Each triple covers 3, so

```math
b = \frac{v(v-1)}{2 \times 3} = \frac{v(v-1)}{6}
```

On the grid, 36 pairs in threes give 12 lines.

### Step 3: the two conditions together give remainder 1 or 3

An odd v leaves remainder 1, 3 or 5 on division by 6.

- **Remainder 1:** $`v - 1`$ is a multiple of 6, so 6 divides $`v(v-1)`$.
- **Remainder 3:** $`v`$ is a multiple of 3 and $`v - 1`$ is even, so 6 divides the product.
- **Remainder 5:** neither $`v`$ nor $`v - 1`$ is a multiple of 3 (they leave 5 and 4), so 3 does not divide the product. No system.

So a system needs $`v \equiv 1`$ or $`3 \pmod 6`$: 3, 7, 9, 13, 15 and so on. A brute-force search in the code finds systems for exactly 3, 7, 9 and 13 among v = 3 to 13.

### Step 4: Bose's construction covers every pair once, for v = 6n + 3

The proof uses three properties of the halving rule.

- **Order does not matter:** $`x \circ y = y \circ x`$.
- **A number halved with itself returns:** $`x \circ x = x`$.
- **Each answer comes once:** $`x \circ y = z`$ has the one solution $`y = 2z - x`$.

Now take any two points. There are three cases.

1. **Same number, different layers:** only the upright triple of that number.
2. **Same layer, $`(x, i)`$ and $`(y, i)`$:** only the rule triple with third point $`(x \circ y, i + 1)`$.
3. **Different numbers and layers, $`(x, i)`$ and $`(z, i + 1)`$:** a shared rule triple needs $`x \circ y = z`$. Exactly one $`y`$ works, and it is not $`x`$, because $`x \circ x = x \ne z`$.

So each pair lands in exactly one triple. For $`v = 9`$: 3 uprights and 9 rule triples, 12 in all, the grid's lines renamed, since 9 points carry only one system.

### Step 5: Skolem's construction for v = 6n + 1, in outline

For $`v = 6n + 1`$ the layers have $`2n`$ points, an even clock where halving fails. Th. Skolem (1958) repaired the rule.

- **New halving:** let $`s = (x + y) \bmod 2n`$. An even $`s`$ is halved as usual; an odd $`s`$ goes to $`n + (s - 1)/2`$.
- **Fewer uprights:** now $`x \circ x = x`$ only for $`x`$ below $`n`$, so only those $`n`$ numbers keep an upright triple.
- **One extra point $`\infty`$:** the pairs the rule misses go into triples $`\{\infty, (x + n, i), (x, i + 1)\}`$, for each $`x`$ below $`n`$.

The code checks it for $`v = 7`$ (7 triples: the Fano plane from [Block designs](01-block-designs-and-fishers-inequality.md), renamed) and $`v = 13`$ (26 triples).

### Step 6: Kirkman's schoolgirls need more than a triple system

In 1850 T. P. Kirkman asked for 15 schoolgirls to walk in 5 rows of 3 for 7 days, no two in a row twice. The 35 rows must be a triple system on 15 points that also splits into 7 days, each using every girl once: a **resolvable** system. The grid's four directions are already four such "days" for 9 girls.

Name the girls A0 to A6, B0 to B6 and Z. Write day 1, then get each next day by adding 1 to every number round a clock of 7.

<details>
<summary>Why adding 1 each day never repeats a pair</summary>

Shifting a pair keeps its gap round the 7-clock. Day 1's A pairs (A1 A2 A4) have gaps 1, 2 and 3, as do its B pairs (B2 B3, B4 B6, B5 B1 round the clock): every possible gap once per letter. Day 1's mixed pairs give each B-minus-A value round the clock once. Z meets everyone because A0 and B0 visit all seven positions.

</details>

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| grid: pairs among 9 points | 9 × 8 / 2 | 36 |
| grid: lines needed | 36 pairs / 3 per line | **12** |
| grid: lines through one point | 8 partners / 2 per line | **4** |
| grid: lines drawn | 3 rows + 3 columns + 3 diagonals + 3 anti-diagonals | 12, every pair once |
| Kirkman: pairs among 15 girls | 15 × 14 / 2 | 105 |
| Kirkman: rows of three | 105 / 3 | 35 |
| Kirkman: days | 35 rows / 5 per day, or 14 partners / 2 per day | **7** |

For 15 girls the count gives 7 days, and this schedule reaches it:

| Day | Row 1 | Row 2 | Row 3 | Row 4 | Row 5 |
| --- | --- | --- | --- | --- | --- |
| 1 | Z A0 B0 | A1 A2 A4 | A3 B1 B5 | A5 B4 B6 | A6 B2 B3 |
| 2 | Z A1 B1 | A2 A3 A5 | A4 B2 B6 | A6 B5 B0 | A0 B3 B4 |
| 3 | Z A2 B2 | A3 A4 A6 | A5 B3 B0 | A0 B6 B1 | A1 B4 B5 |
| 4 | Z A3 B3 | A4 A5 A0 | A6 B4 B1 | A1 B0 B2 | A2 B5 B6 |
| 5 | Z A4 B4 | A5 A6 A1 | A0 B5 B2 | A2 B1 B3 | A3 B6 B0 |
| 6 | Z A5 B5 | A6 A0 A2 | A1 B6 B3 | A3 B2 B4 | A4 B0 B1 |
| 7 | Z A6 B6 | A0 A1 A3 | A2 B0 B4 | A4 B3 B5 | A5 B1 B2 |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Tic-tac-toe lines only, no wrapping | 8 lines cover 24 of 36 pairs | the wrapped diagonals are missing |
| Bose without the upright triples | 9 triples cover 27 of 36 pairs | same-number pairs lose their triple |
| v = 11, because it is odd | r = 5, but b = 110 / 6 = 18.33 | 3 must also divide v(v − 1) |

---

## Code, from first principles, and it actually runs

Two independent roads lead to the possible sizes: the counting rule, and a brute-force search that knows nothing of counting. Every construction (grid, Bose, Skolem, Kirkman) is then checked pair by pair against the count v(v − 1)/2.

### Python

```python
# Steiner triple systems: triples covering every pair of v points exactly once.  No imports.
def cover(blocks):                     # (distinct pairs covered, most times one pair is covered)
    seen = {}
    for a, b, c in blocks:
        for p in ((a, b), (a, c), (b, c)): seen[tuple(sorted(p))] = seen.get(tuple(sorted(p)), 0) + 1
    return len(seen), max(seen.values())
def sts(v, blocks): return len({p for t in blocks for p in t}) == v and cover(blocks) == (v * (v - 1) // 2, 1)
def search(v, used):                   # brute force: can every uncovered pair still be tripled?
    for a in range(v):
        for b in range(a + 1, v):
            if not used[a][b]:
                for c in range(b + 1, v):
                    if not used[a][c] and not used[b][c]:
                        for x, y in ((a, b), (a, c), (b, c)): used[x][y] = used[y][x] = True
                        if search(v, used): return True
                        for x, y in ((a, b), (a, c), (b, c)): used[x][y] = used[y][x] = False
                return False
    return True
def bose(n):                           # v = 6n + 3: point x on layer i is numbered x + q*i
    q = 2 * n + 1
    return [(x, x + q, x + 2 * q) for x in range(q)], [(x + q * i, y + q * i, (x + y) * (n + 1) % q
            + q * ((i + 1) % 3)) for i in range(3) for x in range(q) for y in range(x + 1, q)]
def skolem(n):                         # v = 6n + 1: three layers of 2n points, plus point 6n
    m, half = 2 * n, lambda s: s // 2 if s % 2 == 0 else n + s // 2
    return ([(x, x + m, x + 2 * m) for x in range(n)]
            + [(6 * n, x + n + m * i, x + m * ((i + 1) % 3)) for x in range(n) for i in range(3)]
            + [(x + m * i, y + m * i, half((x + y) % m) + m * ((i + 1) % 3))
               for i in range(3) for x in range(m) for y in range(x + 1, m)])
yn = lambda claim: "yes" if claim else "no"
cell = lambda x, y: 3 * (x % 3) + y % 3 + 1          # grid row x, column y, read 1 to 9
rows, cols = [[cell(c, t) for t in range(3)] for c in range(3)], [[cell(t, c) for t in range(3)] for c in range(3)]
diag, anti = [[cell(t, t + c) for t in range(3)] for c in range(3)], [[cell(t, c - t) for t in range(3)] for c in range(3)]
lines, ttt = rows + cols + diag + anti, rows + cols + [[1, 5, 9], [3, 5, 7]]
fano = [(1, 2, 4), (2, 3, 5), (3, 4, 6), (4, 5, 7), (5, 6, 1), (6, 7, 2), (7, 1, 3)]
base = [(14, 0, 7), (1, 2, 4), (3, 8, 12), (5, 11, 13), (6, 9, 10)]   # A0-A6 = 0-6, B0-B6 = 7-13, Z = 14
days = [[[p if p == 14 else (p + d) % 7 + 7 * (p // 7) for p in t] for t in base] for d in range(7)]
name, walks = lambda p: "Z" if p == 14 else "AB"[p // 7] + str(p % 7), [t for day in days for t in day]
by_count = [v for v in range(3, 16) if (v - 1) % 2 == 0 and v * (v - 1) % 6 == 0]
by_rule = [v for v in range(3, 16) if v % 6 in (1, 3)]
found = [v for v in range(3, 14) if search(v, [[False] * v for _ in range(v)])]
up, rule = bose(1)
print(f"v = 3 to 15 with r and b whole: {by_count}; remainder 1 or 3 on division by 6: {by_rule}")
print(f"brute-force search, v = 3 to 13: a system exists for {found}")
print(f"grid rows {rows}, columns {cols}")
print(f"grid diagonals {diag}, anti-diagonals {anti}")
print(f"v = 9: pairs 9 x 8 / 2 = 36, b = 36 / 3 = {36 // 3}, r = 8 / 2 = {8 // 2}; grid lines {len(lines)}, every pair once: {yn(sts(9, lines))}")
print(f"Bose v = 9: {len(up)} upright + {len(rule)} rule triples, every pair once: {yn(sts(9, up + rule))}; v = 15: {len(sum(bose(2), []))} triples, {yn(sts(15, sum(bose(2), [])))}")
print(f"Skolem v = 7 and 13: {len(skolem(1))} and {len(skolem(2))} triples, {yn(sts(7, skolem(1)))}, {yn(sts(13, skolem(2)))}; Fano plane: {len(fano)} lines, {yn(sts(7, fano))}")
for d, day in enumerate(days): print(f"day {d + 1}: " + " | ".join(" ".join(name(p) for p in t) for t in day))
print(f"Kirkman v = 15: pairs 15 x 14 / 2 = 105, b = 105 / 3 = {len(walks)}, r = 14 / 2 = 7, days {len(walks)} / 5 = {len(days)}; "
      f"each day uses all 15 girls: {yn(all(sorted(sum(day, [])) == list(range(15)) for day in days))}; every pair once: {yn(sts(15, walks))}")
print(f"mistake 1, tic-tac-toe lines only: {len(ttt)} lines cover {cover(ttt)[0]} of 36 pairs")
print(f"mistake 2, Bose v = 9 without the uprights: {len(rule)} triples cover {cover(rule)[0]} of 36 pairs")
print(f"mistake 3, v = 11 is odd, r = {10 // 2}, but b = 110 / 6 = {110 / 6:.2f}")
assert by_count == by_rule == [3, 7, 9, 13, 15] and found == [3, 7, 9, 13]    # counting against search
assert sts(9, lines) and len(lines) == 9 * 8 // 6 and sts(9, up + rule) and sts(7, fano)
assert all(sts(6 * n + 3, sum(bose(n), [])) and sts(6 * n + 1, skolem(n)) for n in range(1, 5))
assert sts(15, walks) and all(sorted(sum(day, [])) == list(range(15)) for day in days)
assert cover(rule)[0] == 36 - 9 and cover(ttt) == (24, 1)
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
v = 3 to 15 with r and b whole: [3, 7, 9, 13, 15]; remainder 1 or 3 on division by 6: [3, 7, 9, 13, 15]
brute-force search, v = 3 to 13: a system exists for [3, 7, 9, 13]
grid rows [[1, 2, 3], [4, 5, 6], [7, 8, 9]], columns [[1, 4, 7], [2, 5, 8], [3, 6, 9]]
grid diagonals [[1, 5, 9], [2, 6, 7], [3, 4, 8]], anti-diagonals [[1, 6, 8], [2, 4, 9], [3, 5, 7]]
v = 9: pairs 9 x 8 / 2 = 36, b = 36 / 3 = 12, r = 8 / 2 = 4; grid lines 12, every pair once: yes
Bose v = 9: 3 upright + 9 rule triples, every pair once: yes; v = 15: 35 triples, yes
Skolem v = 7 and 13: 7 and 26 triples, yes, yes; Fano plane: 7 lines, yes
day 1: Z A0 B0 | A1 A2 A4 | A3 B1 B5 | A5 B4 B6 | A6 B2 B3
day 2: Z A1 B1 | A2 A3 A5 | A4 B2 B6 | A6 B5 B0 | A0 B3 B4
day 3: Z A2 B2 | A3 A4 A6 | A5 B3 B0 | A0 B6 B1 | A1 B4 B5
day 4: Z A3 B3 | A4 A5 A0 | A6 B4 B1 | A1 B0 B2 | A2 B5 B6
day 5: Z A4 B4 | A5 A6 A1 | A0 B5 B2 | A2 B1 B3 | A3 B6 B0
day 6: Z A5 B5 | A6 A0 A2 | A1 B6 B3 | A3 B2 B4 | A4 B0 B1
day 7: Z A6 B6 | A0 A1 A3 | A2 B0 B4 | A4 B3 B5 | A5 B1 B2
Kirkman v = 15: pairs 15 x 14 / 2 = 105, b = 105 / 3 = 35, r = 14 / 2 = 7, days 35 / 5 = 7; each day uses all 15 girls: yes; every pair once: yes
mistake 1, tic-tac-toe lines only: 8 lines cover 24 of 36 pairs
mistake 2, Bose v = 9 without the uprights: 9 triples cover 27 of 36 pairs
mistake 3, v = 11 is odd, r = 5, but b = 110 / 6 = 18.33
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Steiner triple systems: triples covering every pair of v points exactly once.  No crates.
type T = [usize; 3];
fn cover(blocks: &[T]) -> (usize, usize) {        // (distinct pairs covered, most times one pair is covered)
    let mut seen: Vec<((usize, usize), usize)> = Vec::new();
    for t in blocks {
        for (a, b) in [(t[0], t[1]), (t[0], t[2]), (t[1], t[2])] {
            let p = (a.min(b), a.max(b));
            match seen.iter_mut().find(|e| e.0 == p) { Some(e) => e.1 += 1, None => seen.push((p, 1)) }
        }
    }
    (seen.len(), seen.iter().map(|e| e.1).max().unwrap())
}
fn sts(v: usize, b: &[T]) -> bool { let mut p = b.concat(); p.sort(); p.dedup(); p.len() == v && cover(b) == (v * (v - 1) / 2, 1) }
fn search(v: usize, used: &mut Vec<Vec<bool>>) -> bool {   // brute force: can every uncovered pair still be tripled?
    for a in 0..v { for b in a + 1..v { if !used[a][b] {
        for c in b + 1..v { if !used[a][c] && !used[b][c] {
            for (x, y) in [(a, b), (a, c), (b, c)] { used[x][y] = true; used[y][x] = true }
            if search(v, used) { return true }
            for (x, y) in [(a, b), (a, c), (b, c)] { used[x][y] = false; used[y][x] = false }
        } }
        return false
    } } }
    true
}
fn bose(n: usize) -> (Vec<T>, Vec<T>) {           // v = 6n + 3: point x on layer i is numbered x + q*i
    let (q, mut rule) = (2 * n + 1, Vec::new());
    for i in 0..3 { for x in 0..q { for y in x + 1..q {
        rule.push([x + q * i, y + q * i, (x + y) * (n + 1) % q + q * ((i + 1) % 3)]) } } }
    ((0..q).map(|x| [x, x + q, x + 2 * q]).collect(), rule)
}
fn skolem(n: usize) -> Vec<T> {                   // v = 6n + 1: three layers of 2n points, plus point 6n
    let m = 2 * n; let half = |s: usize| if s % 2 == 0 { s / 2 } else { n + s / 2 };
    let mut out: Vec<T> = (0..n).map(|x| [x, x + m, x + 2 * m]).collect();
    for x in 0..n { for i in 0..3 { out.push([6 * n, x + n + m * i, x + m * ((i + 1) % 3)]) } }
    for i in 0..3 { for x in 0..m { for y in x + 1..m {
        out.push([x + m * i, y + m * i, half((x + y) % m) + m * ((i + 1) % 3)]) } } }
    out
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn cell(x: usize, y: usize) -> usize { 3 * (x % 3) + y % 3 + 1 }    // grid row x, column y, read 1 to 9
fn name(p: usize) -> String { if p == 14 { "Z".to_string() } else { format!("{}{}", if p < 7 { "A" } else { "B" }, p % 7) } }
fn main() {
    let three = |f: &dyn Fn(usize, usize) -> usize| -> Vec<T> { (0..3).map(|c| [f(c, 0), f(c, 1), f(c, 2)]).collect() };
    let (rows, cols) = (three(&|c, t| cell(c, t)), three(&|c, t| cell(t, c)));
    let (diag, anti) = (three(&|c, t| cell(t, t + c)), three(&|c, t| cell(t, c + 3 - t)));
    let lines: Vec<T> = [rows.clone(), cols.clone(), diag.clone(), anti.clone()].concat();
    let ttt: Vec<T> = [rows.clone(), cols.clone(), vec![[1, 5, 9], [3, 5, 7]]].concat();
    let fano: Vec<T> = vec![[1, 2, 4], [2, 3, 5], [3, 4, 6], [4, 5, 7], [5, 6, 1], [6, 7, 2], [7, 1, 3]];
    let base: Vec<T> = vec![[14, 0, 7], [1, 2, 4], [3, 8, 12], [5, 11, 13], [6, 9, 10]];   // A0-A6 = 0-6, B0-B6 = 7-13, Z = 14
    let days: Vec<Vec<T>> = (0..7).map(|d| base.iter().map(|t| t.map(|p| if p == 14 { 14 } else { (p + d) % 7 + 7 * (p / 7) })).collect()).collect();
    let walks: Vec<T> = days.concat();
    let full = days.iter().all(|day| { let mut g: Vec<usize> = day.concat(); g.sort(); g == (0..15).collect::<Vec<usize>>() });
    let by_count: Vec<usize> = (3..16).filter(|v| (v - 1) % 2 == 0 && v * (v - 1) % 6 == 0).collect();
    let by_rule: Vec<usize> = (3..16).filter(|v| v % 6 == 1 || v % 6 == 3).collect();
    let found: Vec<usize> = (3..14).filter(|&v| search(v, &mut vec![vec![false; v]; v])).collect();
    let (up, rule) = bose(1);
    let b15 = { let (u, r) = bose(2); [u, r].concat() };
    println!("v = 3 to 15 with r and b whole: {:?}; remainder 1 or 3 on division by 6: {:?}", by_count, by_rule);
    println!("brute-force search, v = 3 to 13: a system exists for {:?}", found);
    println!("grid rows {:?}, columns {:?}", rows, cols);
    println!("grid diagonals {:?}, anti-diagonals {:?}", diag, anti);
    println!("v = 9: pairs 9 x 8 / 2 = 36, b = 36 / 3 = {}, r = 8 / 2 = {}; grid lines {}, every pair once: {}", 36 / 3, 8 / 2, lines.len(), yn(sts(9, &lines)));
    println!("Bose v = 9: {} upright + {} rule triples, every pair once: {}; v = 15: {} triples, {}", up.len(), rule.len(), yn(sts(9, &[up.clone(), rule.clone()].concat())), b15.len(), yn(sts(15, &b15)));
    println!("Skolem v = 7 and 13: {} and {} triples, {}, {}; Fano plane: {} lines, {}", skolem(1).len(), skolem(2).len(), yn(sts(7, &skolem(1))), yn(sts(13, &skolem(2))), fano.len(), yn(sts(7, &fano)));
    for (d, day) in days.iter().enumerate() {
        let rows: Vec<String> = day.iter().map(|t| t.iter().map(|&p| name(p)).collect::<Vec<String>>().join(" ")).collect();
        println!("day {}: {}", d + 1, rows.join(" | "));
    }
    println!("Kirkman v = 15: pairs 15 x 14 / 2 = 105, b = 105 / 3 = {}, r = 14 / 2 = 7, days {} / 5 = {}; each day uses all 15 girls: {}; every pair once: {}", walks.len(), walks.len(), days.len(), yn(full), yn(sts(15, &walks)));
    println!("mistake 1, tic-tac-toe lines only: {} lines cover {} of 36 pairs", ttt.len(), cover(&ttt).0);
    println!("mistake 2, Bose v = 9 without the uprights: {} triples cover {} of 36 pairs", rule.len(), cover(&rule).0);
    println!("mistake 3, v = 11 is odd, r = {}, but b = 110 / 6 = {:.2}", 10 / 2, 110.0 / 6.0);
    assert!(by_count == by_rule && by_rule == vec![3, 7, 9, 13, 15] && found == vec![3, 7, 9, 13]);   // counting against search
    assert!(sts(9, &lines) && lines.len() == 9 * 8 / 6 && sts(9, &[up, rule.clone()].concat()) && sts(7, &fano));
    assert!((1..5).all(|n| sts(6 * n + 3, &{ let (u, r) = bose(n); [u, r].concat() }) && sts(6 * n + 1, &skolem(n))));
    assert!(sts(15, &walks) && full);
    assert!(cover(&rule).0 == 36 - 9 && cover(&ttt) == (24, 1));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
v = 3 to 15 with r and b whole: [3, 7, 9, 13, 15]; remainder 1 or 3 on division by 6: [3, 7, 9, 13, 15]
brute-force search, v = 3 to 13: a system exists for [3, 7, 9, 13]
grid rows [[1, 2, 3], [4, 5, 6], [7, 8, 9]], columns [[1, 4, 7], [2, 5, 8], [3, 6, 9]]
grid diagonals [[1, 5, 9], [2, 6, 7], [3, 4, 8]], anti-diagonals [[1, 6, 8], [2, 4, 9], [3, 5, 7]]
v = 9: pairs 9 x 8 / 2 = 36, b = 36 / 3 = 12, r = 8 / 2 = 4; grid lines 12, every pair once: yes
Bose v = 9: 3 upright + 9 rule triples, every pair once: yes; v = 15: 35 triples, yes
Skolem v = 7 and 13: 7 and 26 triples, yes, yes; Fano plane: 7 lines, yes
day 1: Z A0 B0 | A1 A2 A4 | A3 B1 B5 | A5 B4 B6 | A6 B2 B3
day 2: Z A1 B1 | A2 A3 A5 | A4 B2 B6 | A6 B5 B0 | A0 B3 B4
day 3: Z A2 B2 | A3 A4 A6 | A5 B3 B0 | A0 B6 B1 | A1 B4 B5
day 4: Z A3 B3 | A4 A5 A0 | A6 B4 B1 | A1 B0 B2 | A2 B5 B6
day 5: Z A4 B4 | A5 A6 A1 | A0 B5 B2 | A2 B1 B3 | A3 B6 B0
day 6: Z A5 B5 | A6 A0 A2 | A1 B6 B3 | A3 B2 B4 | A4 B0 B1
day 7: Z A6 B6 | A0 A1 A3 | A2 B0 B4 | A4 B3 B5 | A5 B1 B2
Kirkman v = 15: pairs 15 x 14 / 2 = 105, b = 105 / 3 = 35, r = 14 / 2 = 7, days 35 / 5 = 7; each day uses all 15 girls: yes; every pair once: yes
mistake 1, tic-tac-toe lines only: 8 lines cover 24 of 36 pairs
mistake 2, Bose v = 9 without the uprights: 9 triples cover 27 of 36 pairs
mistake 3, v = 11 is odd, r = 5, but b = 110 / 6 = 18.33
ALL CHECKS PASS
```

### Lean

Lean proves the remainder rule and the counts for every v, Bose's construction for every n, and checks the worked examples.

- Take $`v \ge 1`$ points. Then a Steiner triple system on them exists exactly when v leaves remainder 1 or 3 on division by 6.
- For remainder 1, Lean builds Skolem's system in full, where the card gives only an outline.
- Take any Steiner triple system on v points. Then $`6b = v(v-1)`$, and each point lies on r triples, with $`2r = v - 1`$.
- Take any n. Then Bose's upright and rule triples cover every pair of the $`6n + 3`$ points $`(x, i)`$ exactly once.
- The 12 grid lines, the Fano plane's 7 lines and Kirkman's 35 rows each cover every pair exactly once.
- Each of Kirkman's 7 days uses every girl exactly once.
- For 9 points Lean checks 36 pairs, 12 lines and 4 lines per point. For 15 girls it checks 105 pairs, 35 rows and 7 days.
- For v = 11, Lean checks that v is odd but 6 does not divide 110.

The brute-force search for v = 3 to 13 and the first two mistakes in the table are left to the Python and Rust checks.

```lean
-- Steiner triple systems: a set of v points carries triples covering every pair exactly once exactly when v leaves remainder 1 or 3 on division by 6.
import Mathlib.Data.Finset.Card
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Fintype.Prod
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.Ring
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.LinearCombination
import Mathlib.Data.ZMod.Basic

open Finset

/-- `B` is a Steiner triple system on the point set `V`: every block is a 3-point subset of `V`,
and every pair of different points of `V` lies in exactly one block. -/
def IsSteinerTripleSystem {α : Type*} [DecidableEq α] (V : Finset α) (B : Finset (Finset α)) : Prop :=
  (∀ t ∈ B, t ⊆ V ∧ t.card = 3) ∧
    ∀ x ∈ V, ∀ y ∈ V, x ≠ y → (B.filter fun t => x ∈ t ∧ y ∈ t).card = 1

instance {α : Type*} [DecidableEq α] (V : Finset α) (B : Finset (Finset α)) :
    Decidable (IsSteinerTripleSystem V B) := by
  unfold IsSteinerTripleSystem; infer_instance

theorem sts_point_count {α : Type*} [DecidableEq α] (V : Finset α)
    (B : Finset (Finset α)) (h : IsSteinerTripleSystem V B) (x : α) (hx : x ∈ V) :
    (B.filter fun t => x ∈ t).card * 2 = V.card - 1 := by
  have key := Finset.sum_card_inter (s := V.erase x) (B := B.filter fun t => x ∈ t) (n := 1)
    (by
      intro a ha
      rw [Finset.filter_filter]
      have := h.2 x hx a (Finset.mem_of_mem_erase ha) (Finset.ne_of_mem_erase ha).symm
      simpa using this)
  rw [Finset.card_erase_of_mem hx, mul_one] at key
  rw [← key, Finset.card_eq_sum_ones, Finset.sum_mul]
  apply Finset.sum_congr rfl
  intro t ht
  rw [Finset.mem_filter] at ht
  obtain ⟨htB, hxt⟩ := ht
  have hsub := (h.1 t htB).1
  have : V.erase x ∩ t = t.erase x := by
    ext y; simp only [Finset.mem_inter, Finset.mem_erase]
    constructor
    · rintro ⟨⟨h1, _⟩, h3⟩; exact ⟨h1, h3⟩
    · rintro ⟨h1, h3⟩; exact ⟨⟨h1, hsub h3⟩, h3⟩
  rw [this, Finset.card_erase_of_mem hxt, (h.1 t htB).2]
  rfl
#print axioms sts_point_count

theorem sts_counts_aux {α : Type*} [DecidableEq α] (V : Finset α)
    (B : Finset (Finset α)) (h : IsSteinerTripleSystem V B) :
    B.card * 6 = V.card * (V.card - 1) ∧
      ∀ x ∈ V, (B.filter fun t => x ∈ t).card * 2 = V.card - 1 := by
  refine ⟨?_, sts_point_count V B h⟩
  have h3 : ∑ t ∈ B, (V ∩ t).card = B.card * 3 := by
    rw [Finset.card_eq_sum_ones, Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro t ht
    rw [Finset.inter_eq_right.mpr (h.1 t ht).1, (h.1 t ht).2, one_mul]
  have hsum : ∑ t ∈ B, (V ∩ t).card = ∑ x ∈ V, (B.filter fun t => x ∈ t).card := by
    simp_rw [← Finset.filter_mem_eq_inter, Finset.card_eq_sum_ones, Finset.sum_filter]
    exact Finset.sum_comm
  have h2 : (∑ x ∈ V, (B.filter fun t => x ∈ t).card) * 2 = V.card * (V.card - 1) := by
    rw [Finset.sum_mul, Finset.sum_congr rfl (fun x hx => sts_point_count V B h x hx)]
    simp
  rw [← h2, ← hsum, h3]; ring
#print axioms sts_counts_aux

theorem sts_necessity (v : ℕ) (hv : 0 < v) (B : Finset (Finset ℕ))
    (h : IsSteinerTripleSystem (range v) B) : v % 6 = 1 ∨ v % 6 = 3 := by
  obtain ⟨h1, h2⟩ := sts_counts_aux _ B h
  have h2' := h2 0 (by simpa using hv)
  simp only [card_range] at h1 h2'
  have hmod : v * (v - 1) % 6 = 0 := by rw [← h1]; simp
  rw [Nat.mul_mod] at hmod
  have : v % 6 < 6 := Nat.mod_lt _ (by norm_num)
  have e : (v - 1) % 6 = (v % 6 + 5) % 6 := by omega
  rw [e] at hmod
  interval_cases hr : v % 6 <;> omega
#print axioms sts_necessity

theorem sts_of_third {α : Type*} [Fintype α] [DecidableEq α] (c : α → α → α)
    (h1 : ∀ x y, x ≠ y → c x y ≠ x) (hcomm : ∀ x y, c x y = c y x)
    (hinv : ∀ x y, x ≠ y → c x (c x y) = y) (B : Finset (Finset α))
    (hB : ∀ t ∈ B, ∃ x y, x ≠ y ∧ t = {x, y, c x y})
    (hB' : ∀ x y, x ≠ y → ({x, y, c x y} : Finset α) ∈ B) :
    IsSteinerTripleSystem univ B := by
  have h2 : ∀ x y, x ≠ y → c x y ≠ y := fun x y hxy => by
    rw [hcomm]; exact h1 y x (Ne.symm hxy)
  have hcard : ∀ x y, x ≠ y → ({x, y, c x y} : Finset α).card = 3 := by
    intro x y hxy
    rw [Finset.card_insert_of_notMem, Finset.card_pair (h2 x y hxy).symm]
    simp only [Finset.mem_insert, Finset.mem_singleton, not_or]
    exact ⟨hxy, (h1 x y hxy).symm⟩
  refine ⟨fun t ht => ?_, fun x _ y _ hxy => ?_⟩
  · obtain ⟨x, y, hxy, rfl⟩ := hB t ht
    exact ⟨Finset.subset_univ _, hcard x y hxy⟩
  · rw [Finset.card_eq_one]
    refine ⟨{x, y, c x y}, ?_⟩
    ext t
    simp only [Finset.mem_filter, Finset.mem_singleton]
    constructor
    · rintro ⟨ht, hx, hy⟩
      obtain ⟨a, b, hab, rfl⟩ := hB t ht
      have e1 : c b a = c a b := hcomm b a
      have e2 : c a (c a b) = b := hinv a b hab
      have e3 : c (c a b) a = b := by rw [hcomm]; exact e2
      have e4 : c b (c a b) = a := by rw [← e1]; exact hinv b a (Ne.symm hab)
      have e5 : c (c a b) b = a := by rw [hcomm]; exact e4
      simp only [Finset.mem_insert, Finset.mem_singleton] at hx hy
      rcases hx with rfl | rfl | rfl <;> rcases hy with rfl | rfl | rfl <;>
        first
        | exact absurd rfl hxy
        | (simp only [e1, e2, e3, e4, e5]; done)
        | (simp only [e1, e2, e3, e4, e5]; ext z; simp only [Finset.mem_insert, Finset.mem_singleton]; tauto)
    · rintro rfl
      refine ⟨hB' x y hxy, by simp, by simp⟩
#print axioms sts_of_third

theorem sts_map {α β : Type*} [DecidableEq α] [DecidableEq β] (f : α ↪ β) {V : Finset α}
    {B : Finset (Finset α)} (h : IsSteinerTripleSystem V B) :
    IsSteinerTripleSystem (V.map f) (B.image fun t => t.map f) := by
  refine ⟨fun t ht => ?_, fun x hx y hy hxy => ?_⟩
  · obtain ⟨s, hs, rfl⟩ := Finset.mem_image.mp ht
    exact ⟨Finset.map_subset_map.mpr (h.1 s hs).1, by rw [Finset.card_map, (h.1 s hs).2]⟩
  · obtain ⟨a, ha, rfl⟩ := Finset.mem_map.mp hx
    obtain ⟨b, hb, rfl⟩ := Finset.mem_map.mp hy
    have hab : a ≠ b := fun e => hxy (by rw [e])
    rw [Finset.filter_image, Finset.card_image_of_injective _ (Finset.map_injective f)]
    simp only [Finset.mem_map']
    exact h.2 a ha b hb hab
#print axioms sts_map

theorem sts_range_of_fintype {T : Type*} [Fintype T] [DecidableEq T] {B : Finset (Finset T)}
    (h : IsSteinerTripleSystem univ B) :
    ∃ B' : Finset (Finset ℕ), IsSteinerTripleSystem (range (Fintype.card T)) B' := by
  let f : T ↪ ℕ := (Fintype.equivFin T).toEmbedding.trans Fin.valEmbedding
  have e : (univ : Finset T).map f = range (Fintype.card T) := by
    rw [← Finset.map_map, Finset.map_univ_equiv, Fin.map_valEmbedding_univ]
    ext m; simp
  exact ⟨_, e ▸ sts_map f h⟩
#print axioms sts_range_of_fintype

theorem z3_a : ∀ i j : ZMod 3, i ≠ j → -i - j ≠ i := by decide
#print axioms z3_a

theorem z3_b : ∀ i : ZMod 3, i + 1 ≠ i := by decide
#print axioms z3_b

theorem z3_c : ∀ i j : ZMod 3, i ≠ j → j ≠ i + 1 → i = j + 1 := by decide
#print axioms z3_c

theorem z3_d : ∀ i : ZMod 3, i ≠ i + 1 + 1 := by decide
#print axioms z3_d

theorem z3_e : ∀ i j : ZMod 3, i ≠ j → ({i, j, -i - j} : Finset (ZMod 3)) = {0, 1, 2} := by decide
#print axioms z3_e

theorem z3_f : ∀ i : ZMod 3, i + 2 ≠ i := by decide
#print axioms z3_f

theorem z3_g : ∀ i : ZMod 3, i - 1 ≠ i := by decide
#print axioms z3_g

theorem z3_h : ∀ i : ZMod 3, i - 1 ≠ i + 1 := by decide
#print axioms z3_h

theorem z3_i : ∀ i : ZMod 3, i + 2 + 2 = i + 1 := by decide
#print axioms z3_i

theorem z3_j : ∀ i : ZMod 3, i + 1 + 2 = i := by decide
#print axioms z3_j

theorem z3_k : ∀ i : ZMod 3, i + 2 ≠ i + 1 := by decide
#print axioms z3_k

theorem bose_two_half (n : ℕ) : (2 : ZMod (2 * n + 1)) * ((n : ZMod (2 * n + 1)) + 1) = 1 := by
  have h : ((2 * n + 1 : ℕ) : ZMod (2 * n + 1)) = 0 := ZMod.natCast_self _
  push_cast at h
  linear_combination h
#print axioms bose_two_half

theorem bose_cancel_two (n : ℕ) {a b : ZMod (2 * n + 1)} (h : 2 * a = 2 * b) : a = b := by
  linear_combination ((n : ZMod (2 * n + 1)) + 1) * h - (a - b) * bose_two_half n
#print axioms bose_cancel_two

/-- The third point of the Bose triple through two points. -/
def boseThird (n : ℕ) (p q : ZMod (2 * n + 1) × ZMod 3) : ZMod (2 * n + 1) × ZMod 3 :=
  if p.1 = q.1 then (p.1, -p.2 - q.2)
  else if p.2 = q.2 then (((n : ZMod (2 * n + 1)) + 1) * (p.1 + q.1), p.2 + 1)
  else if q.2 = p.2 + 1 then (2 * q.1 - p.1, p.2)
  else (2 * p.1 - q.1, q.2)

theorem boseThird_ne (n : ℕ) : ∀ x y, x ≠ y → boseThird n x y ≠ x := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  rintro ⟨x, i⟩ ⟨y, j⟩ hne
  simp only [boseThird]
  split_ifs with e1 e2 e3
  · subst e1
    have : i ≠ j := fun e => hne (by rw [e])
    intro e; exact z3_a i j this (Prod.ext_iff.mp e).2
  · intro e; exact z3_b i (Prod.ext_iff.mp e).2
  · intro e
    simp only [Prod.mk.injEq] at e e1
    exact e1 (hc2 (by linear_combination e.1)).symm
  · intro e
    simp only [Prod.mk.injEq] at e e2
    exact e2 e.2.symm
#print axioms boseThird_ne

theorem boseThird_comm (n : ℕ) : ∀ x y, boseThird n x y = boseThird n y x := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  rintro ⟨x, i⟩ ⟨y, j⟩
  simp only [boseThird]
  by_cases e1 : x = y
  · subst e1; simp only [ite_true]; ext <;> simp only <;> ring
  · rw [if_neg e1, if_neg (Ne.symm e1)]
    by_cases e2 : i = j
    · subst e2; simp only [ite_true]; ext <;> simp only; ring
    · rw [if_neg e2, if_neg (Ne.symm e2)]
      by_cases e3 : j = i + 1
      · subst e3; rw [if_pos rfl, if_neg (z3_d i)]
      · rw [if_neg e3, if_pos (z3_c i j e2 e3)]
#print axioms boseThird_comm

theorem boseThird_inv (n : ℕ) : ∀ x y, x ≠ y → boseThird n x (boseThird n x y) = y := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  rintro ⟨x, i⟩ ⟨y, j⟩ hne
  by_cases e1 : x = y
  · subst e1
    simp only [boseThird, ite_true]
    ext <;> simp only; ring
  · by_cases e2 : i = j
    · subst e2
      have hr : x ≠ ((n : ZMod (2 * n + 1)) + 1) * (x + y) := by
        intro e; apply e1
        linear_combination (2 : ZMod (2 * n + 1)) * e + (x + y) * h2
      simp only [boseThird, if_neg e1, ite_true, if_neg hr, if_neg (z3_b i).symm]
      ext <;> simp only
      linear_combination (x + y) * h2
    · by_cases e3 : j = i + 1
      · subst e3
        have hr : x ≠ 2 * y - x := by
          intro e; apply e1; apply hc2; linear_combination e
        simp only [boseThird, if_neg e1, if_neg e2, ite_true, if_neg hr]
        ext <;> simp only
        linear_combination y * h2
      · have hr : x ≠ 2 * x - y := by
          intro e; apply e1; linear_combination -e
        have hi := z3_c i j e2 e3
        simp only [boseThird, if_neg e1, if_neg e2, if_neg e3, if_neg hr]
        congr 1; ring
#print axioms boseThird_inv

theorem bose_exists (n : ℕ) : ∃ B : Finset (Finset (ZMod (2 * n + 1) × ZMod 3)),
    IsSteinerTripleSystem univ B :=
  ⟨_, sts_of_third (boseThird n) (boseThird_ne n) (boseThird_comm n) (boseThird_inv n)
    (((univ ×ˢ univ).filter fun pq : (ZMod (2 * n + 1) × ZMod 3) × (ZMod (2 * n + 1) × ZMod 3) =>
      pq.1 ≠ pq.2).image fun pq => {pq.1, pq.2, boseThird n pq.1 pq.2})
    (fun t ht => by
      obtain ⟨⟨p, q⟩, hpq, rfl⟩ := Finset.mem_image.mp ht
      exact ⟨p, q, (Finset.mem_filter.mp hpq).2, rfl⟩)
    (fun p q hpq => Finset.mem_image.mpr ⟨(p, q), by simp [hpq], rfl⟩)⟩
#print axioms bose_exists

def sAddN (n a b : ℕ) : ℕ := if a + b < 2 * n then a + b else a + b - 2 * n

def sSig (n s : ℕ) : ℕ := if s % 2 = 0 then s / 2 else n + s / 2

def sRho (n b : ℕ) : ℕ := if b < n then 2 * b else 2 * (b - n) + 1

def sSub (n r a : ℕ) : ℕ := if a ≤ r then r - a else r + 2 * n - a

def sOp (n : ℕ) (x y : Fin (2 * n)) : Fin (2 * n) :=
  ⟨sSig n (sAddN n x y), by
    have := x.2; have := y.2; simp only [sSig, sAddN]; split_ifs <;> omega⟩

def sDv (n : ℕ) (a b : Fin (2 * n)) : Fin (2 * n) :=
  ⟨sSub n (sRho n b) a, by
    have := a.2; have := b.2; simp only [sSub, sRho]; split_ifs <;> omega⟩

theorem sOp_comm (n : ℕ) (x y : Fin (2 * n)) : sOp n x y = sOp n y x := by
  simp only [sOp, sAddN, Nat.add_comm (x : ℕ)]
#print axioms sOp_comm

theorem sOp_dv (n : ℕ) (a b : Fin (2 * n)) : sOp n a (sDv n a b) = b := by
  apply Fin.ext
  have := a.2; have := b.2
  simp only [sOp, sDv, sSig, sAddN, sSub, sRho]
  split_ifs <;> omega
#print axioms sOp_dv

theorem sDv_op (n : ℕ) (a y : Fin (2 * n)) : sDv n a (sOp n a y) = y := by
  apply Fin.ext
  have := a.2; have := y.2
  simp only [sOp, sDv, sSig, sAddN, sSub, sRho]
  split_ifs <;> omega
#print axioms sDv_op

theorem sOp_self (n : ℕ) (x : Fin (2 * n)) :
    (sOp n x x : ℕ) = if (x : ℕ) < n then (x : ℕ) else x - n := by
  have := x.2
  simp only [sOp, sSig, sAddN]
  split_ifs <;> omega
#print axioms sOp_self

theorem sOp_inj (n : ℕ) {x y z : Fin (2 * n)} (h : sOp n x y = sOp n x z) : y = z := by
  rw [← sDv_op n x y, h, sDv_op]
#print axioms sOp_inj

def sInfty (n : ℕ) (y : Fin (2 * n)) (j : ZMod 3) : Option (Fin (2 * n) × ZMod 3) :=
  if h : (y : ℕ) < n then some (⟨y + n, by omega⟩, j - 1) else some (⟨y - n, by omega⟩, j + 1)

def sUp (n : ℕ) (x : Fin (2 * n)) (i : ZMod 3) (y : Fin (2 * n)) : Option (Fin (2 * n) × ZMod 3) :=
  if sOp n x x = y then (if (x : ℕ) < n then some (x, i + 2) else none) else some (sDv n x y, i)

def sThird (n : ℕ) : Option (Fin (2 * n) × ZMod 3) → Option (Fin (2 * n) × ZMod 3) →
    Option (Fin (2 * n) × ZMod 3)
  | none, none => none
  | none, some (y, j) => sInfty n y j
  | some (x, i), none => sInfty n x i
  | some (x, i), some (y, j) =>
    if i = j then some (sOp n x y, i + 1) else if j = i + 1 then sUp n x i y else sUp n y j x

theorem sThird_comm (n : ℕ) (p q : Option (Fin (2 * n) × ZMod 3)) :
    sThird n p q = sThird n q p := by
  rcases p with _ | ⟨x, i⟩ <;> rcases q with _ | ⟨y, j⟩
  · rfl
  · rfl
  · rfl
  · simp only [sThird]
    by_cases e2 : i = j
    · subst e2; simp only [ite_true, sOp_comm]
    · rw [if_neg e2, if_neg (Ne.symm e2)]
      by_cases e3 : j = i + 1
      · subst e3; rw [if_pos rfl, if_neg (z3_d i)]
      · rw [if_neg e3, if_pos (z3_c i j e2 e3)]
#print axioms sThird_comm

theorem sThird_ne (n : ℕ) (p q : Option (Fin (2 * n) × ZMod 3)) (hne : p ≠ q) :
    sThird n p q ≠ p := by
  rcases p with _ | ⟨x, i⟩ <;> rcases q with _ | ⟨y, j⟩
  · exact absurd rfl hne
  · simp only [sThird, sInfty]; split_ifs <;> simp
  · simp only [sThird, sInfty]; split_ifs
    · simp
    · simp [(z3_b i)]
  · simp only [sThird]
    by_cases e2 : i = j
    · subst e2; simp
    · rw [if_neg e2]
      by_cases e3 : j = i + 1
      · rw [if_pos e3]; simp only [sUp]
        split_ifs with h1 h2
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro _; exact z3_f i
        · simp
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro h; apply absurd _ h1; conv_rhs => rw [← sOp_dv n x y]
          rw [h]
      · rw [if_neg e3]; simp only [sUp]
        have hi := z3_c i j e2 e3
        split_ifs with h1 h2
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro _; rw [hi]; exact z3_k j
        · simp
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro _; exact Ne.symm e2
#print axioms sThird_ne

theorem sInfty_inv (n : ℕ) (y : Fin (2 * n)) (j : ZMod 3) :
    sThird n none (sInfty n y j) = some (y, j) := by
  unfold sInfty
  by_cases hy : (y : ℕ) < n
  · rw [dif_pos hy]; simp only [sThird, sInfty]
    rw [dif_neg (by simp)]
    simp only [Option.some.injEq, Prod.mk.injEq]
    exact ⟨Fin.ext (by simp), by ring⟩
  · rw [dif_neg hy]; simp only [sThird, sInfty]
    rw [dif_pos (by show (y : ℕ) - n < n; omega)]
    simp only [Option.some.injEq, Prod.mk.injEq]
    exact ⟨Fin.ext (by show (y : ℕ) - n + n = y; omega), by ring⟩
#print axioms sInfty_inv

theorem sThird_ss (n : ℕ) (x : Fin (2 * n)) (i : ZMod 3) (y : Fin (2 * n)) (j : ZMod 3) :
    sThird n (some (x, i)) (some (y, j)) =
      if i = j then some (sOp n x y, i + 1) else if j = i + 1 then sUp n x i y else sUp n y j x :=
  rfl
#print axioms sThird_ss

theorem sThird_sn (n : ℕ) (x : Fin (2 * n)) (i : ZMod 3) :
    sThird n (some (x, i)) none = sInfty n x i := rfl
#print axioms sThird_sn

theorem sThird_inv (n : ℕ) (p q : Option (Fin (2 * n) × ZMod 3)) (hne : p ≠ q) :
    sThird n p (sThird n p q) = q := by
  rcases p with _ | ⟨x, i⟩ <;> rcases q with _ | ⟨y, j⟩
  · exact absurd rfl hne
  · exact sInfty_inv n y j
  · -- p = (x, i), q = ∞
    rw [sThird_sn]; unfold sInfty
    by_cases hx : (x : ℕ) < n
    · rw [dif_pos hx, sThird_ss, if_neg (z3_g i).symm, if_neg (z3_h i)]
      unfold sUp
      rw [if_pos (Fin.ext (by rw [sOp_self]; simp <;> omega)), if_neg (by simp)]
    · rw [dif_neg hx, sThird_ss, if_neg (z3_b i).symm, if_pos rfl]
      unfold sUp
      rw [if_pos (Fin.ext (by rw [sOp_self]; simp <;> omega)), if_neg hx]
  · rw [sThird_ss]
    by_cases e2 : i = j
    · subst e2
      have hxy : x ≠ y := fun e => hne (by rw [e])
      rw [if_pos rfl, sThird_ss, if_neg (z3_b i).symm, if_pos rfl]
      unfold sUp
      rw [if_neg (fun e => hxy (sOp_inj n e)), sDv_op]
    · rw [if_neg e2]
      by_cases e3 : j = i + 1
      · subst e3
        rw [if_pos rfl]
        unfold sUp
        by_cases h1 : sOp n x x = y
        · rw [if_pos h1]
          by_cases hx : (x : ℕ) < n
          · have hy : y = x := by
              rw [← h1]; exact Fin.ext (by rw [sOp_self, if_pos hx])
            subst hy
            rw [if_pos hx, sThird_ss, if_neg (z3_f i).symm, if_neg (z3_k i)]
            unfold sUp
            rw [if_pos h1, if_pos hx, z3_i]
          · rw [if_neg hx, sThird_sn]
            unfold sInfty
            rw [dif_neg hx]
            simp only [Option.some.injEq, Prod.mk.injEq, and_true]
            rw [← h1]; exact Fin.ext (by rw [sOp_self, if_neg hx])
        · rw [if_neg h1]
          rw [sThird_ss, if_pos rfl, sOp_dv]
      · have hi := z3_c i j e2 e3
        rw [if_neg e3]
        unfold sUp
        by_cases h1 : sOp n y y = x
        · rw [if_pos h1]
          by_cases hy : (y : ℕ) < n
          · have hx : x = y := by
              rw [← h1]; exact Fin.ext (by rw [sOp_self, if_pos hy])
            subst hx
            rw [if_pos hy, sThird_ss, if_neg (by rw [hi]; exact (z3_k j).symm),
              if_pos (by rw [hi]; ring)]
            unfold sUp
            rw [if_pos h1, if_pos hy, hi, z3_j]
          · rw [if_neg hy, sThird_sn]
            unfold sInfty
            have hx : (x : ℕ) < n := by rw [← h1, sOp_self, if_neg hy]; omega
            rw [dif_pos hx]
            simp only [Option.some.injEq, Prod.mk.injEq]
            refine ⟨Fin.ext ?_, by rw [hi]; ring⟩
            simp only [← h1, sOp_self, if_neg hy]; omega
        · rw [if_neg h1]
          have hw : sDv n y x ≠ y := fun e => h1 (by conv_rhs => rw [← sOp_dv n y x]; rw [e])
          rw [sThird_ss, if_neg e2, if_neg e3]
          unfold sUp
          have h2 : sOp n (sDv n y x) (sDv n y x) ≠ x := by
            intro e
            apply hw
            apply sOp_inj n (x := sDv n y x)
            rw [e, sOp_comm, sOp_dv]
          rw [if_neg h2]
          have : sDv n (sDv n y x) x = y := by
            apply sOp_inj n (x := sDv n y x)
            rw [sOp_dv, sOp_comm, sOp_dv]
          rw [this]
#print axioms sThird_inv

theorem skolem_exists (n : ℕ) : ∃ B : Finset (Finset (Option (Fin (2 * n) × ZMod 3))),
    IsSteinerTripleSystem univ B :=
  ⟨_, sts_of_third (sThird n) (sThird_ne n) (sThird_comm n) (sThird_inv n)
    (((univ ×ˢ univ).filter fun pq : Option (Fin (2 * n) × ZMod 3) × Option (Fin (2 * n) × ZMod 3) =>
      pq.1 ≠ pq.2).image fun pq => {pq.1, pq.2, sThird n pq.1 pq.2})
    (fun t ht => by
      obtain ⟨⟨p, q⟩, hpq, rfl⟩ := Finset.mem_image.mp ht
      exact ⟨p, q, (Finset.mem_filter.mp hpq).2, rfl⟩)
    (fun p q hpq => Finset.mem_image.mpr ⟨(p, q), by simp [hpq], rfl⟩)⟩
#print axioms skolem_exists

/-- Main claim: a Steiner triple system on v points (v at least 1) exists exactly when
v leaves remainder 1 or 3 on division by 6. -/
theorem steiner_triple_system_exists_iff (v : ℕ) (hv : 0 < v) :
    (∃ B : Finset (Finset ℕ), IsSteinerTripleSystem (range v) B) ↔ v % 6 = 1 ∨ v % 6 = 3 := by
  constructor
  · rintro ⟨B, h⟩
    exact sts_necessity v hv B h
  · rintro (h | h)
    · obtain ⟨n, rfl⟩ : ∃ n, v = 6 * n + 1 := ⟨v / 6, by omega⟩
      obtain ⟨B, hB⟩ := skolem_exists n
      have e : Fintype.card (Option (Fin (2 * n) × ZMod 3)) = 6 * n + 1 := by
        simp [ZMod.card]; ring
      have := sts_range_of_fintype hB
      rwa [e] at this
    · obtain ⟨n, rfl⟩ : ∃ n, v = 6 * n + 3 := ⟨v / 6, by omega⟩
      obtain ⟨B, hB⟩ := bose_exists n
      have e : Fintype.card (ZMod (2 * n + 1) × ZMod 3) = 6 * n + 3 := by
        simp [ZMod.card]; ring
      have := sts_range_of_fintype hB
      rwa [e] at this

/-- The counts: in a Steiner triple system on v points, each point lies on r = (v - 1)/2 triples
and there are b = v(v - 1)/6 triples in all. -/
theorem steiner_triple_system_counts {α : Type*} [DecidableEq α] (V : Finset α)
    (B : Finset (Finset α)) (h : IsSteinerTripleSystem V B) :
    B.card * 6 = V.card * (V.card - 1) ∧
      ∀ x ∈ V, (B.filter fun t => x ∈ t).card * 2 = V.card - 1 := by
  exact sts_counts_aux V B h

/-- Bose's triples for v = 6n + 3 on the points (x, i), x counted round a clock of 2n + 1 and
i round a clock of 3: the uprights {(x,0), (x,1), (x,2)} and, for x ≠ y on layer i,
{(x,i), (y,i), ((n+1)(x+y), i+1)}. -/
def boseBlocks (n : ℕ) : Finset (Finset (ZMod (2 * n + 1) × ZMod 3)) :=
  (univ.image fun x : ZMod (2 * n + 1) => ({(x, 0), (x, 1), (x, 2)} : Finset _)) ∪
    ((univ ×ˢ univ ×ˢ univ).filter
        (fun p : ZMod 3 × ZMod (2 * n + 1) × ZMod (2 * n + 1) => p.2.1 ≠ p.2.2)).image
      fun p => ({(p.2.1, p.1), (p.2.2, p.1), (((n : ZMod (2 * n + 1)) + 1) * (p.2.1 + p.2.2), p.1 + 1)} :
        Finset _)

/-- Bose's construction: for every n, the uprights and rule triples form a Steiner triple system
on the 6n + 3 points (x, i). -/
theorem bose_construction_is_steiner_triple_system (n : ℕ) :
    IsSteinerTripleSystem (univ : Finset (ZMod (2 * n + 1) × ZMod 3)) (boseBlocks n) := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  apply sts_of_third (boseThird n) (boseThird_ne n) (boseThird_comm n) (boseThird_inv n)
  · rintro t ht
    rcases Finset.mem_union.mp ht with ht | ht
    · obtain ⟨x, -, rfl⟩ := Finset.mem_image.mp ht
      refine ⟨(x, 0), (x, 1), by simp, ?_⟩
      simp only [boseThird, ite_true]
      rfl
    · obtain ⟨⟨i, a, b⟩, hp, rfl⟩ := Finset.mem_image.mp ht
      simp only [Finset.mem_filter] at hp
      refine ⟨(a, i), (b, i), by simp [hp.2], ?_⟩
      simp only [boseThird, if_neg hp.2, ite_true]
  · rintro ⟨x, i⟩ ⟨y, j⟩ hne
    by_cases e1 : x = y
    · subst e1
      have hij : i ≠ j := fun e => hne (by rw [e])
      simp only [boseThird, ite_true]
      apply Finset.mem_union_left
      refine Finset.mem_image.mpr ⟨x, Finset.mem_univ _, ?_⟩
      have := z3_e i j hij
      have key : ∀ s : Finset (ZMod 3), s.image (Prod.mk x) = s.image (Prod.mk x) := fun _ => rfl
      calc ({(x, 0), (x, 1), (x, 2)} : Finset _) = ({0, 1, 2} : Finset (ZMod 3)).image (Prod.mk x) := by
            simp [Finset.image_insert]
        _ = ({i, j, -i - j} : Finset (ZMod 3)).image (Prod.mk x) := by rw [this]
        _ = _ := by simp [Finset.image_insert]
    · apply Finset.mem_union_right
      rw [Finset.mem_image]
      by_cases e2 : i = j
      · subst e2
        refine ⟨(i, x, y), by simp [e1], ?_⟩
        simp only [boseThird, if_neg e1, ite_true]
      · by_cases e3 : j = i + 1
        · subst e3
          refine ⟨(i, x, 2 * y - x), by simp; intro e; apply e1; apply hc2; linear_combination e, ?_⟩
          have : ((n : ZMod (2 * n + 1)) + 1) * (x + (2 * y - x)) = y := by linear_combination y * h2
          simp only [boseThird, if_neg e1, if_neg e2, ite_true, this]
          ext z; simp only [Finset.mem_insert, Finset.mem_singleton]; tauto
        · have hi := z3_c i j e2 e3
          refine ⟨(j, y, 2 * x - y), by simp; intro e; apply e1; apply hc2; linear_combination -e, ?_⟩
          have : ((n : ZMod (2 * n + 1)) + 1) * (y + (2 * x - y)) = x := by linear_combination x * h2
          simp only [boseThird, if_neg e1, if_neg e2, if_neg e3, this, ← hi]
          ext z; simp only [Finset.mem_insert, Finset.mem_singleton]; tauto

-- v = 9: the 12 wrapped lines of the 3 by 3 grid cover every pair once.
example : IsSteinerTripleSystem (Icc 1 9)
    {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {1, 4, 7}, {2, 5, 8}, {3, 6, 9},
     {1, 5, 9}, {2, 6, 7}, {3, 4, 8}, {1, 6, 8}, {2, 4, 9}, {3, 5, 7}} := by decide

-- The Fano plane: 7 points and 7 lines, every pair on exactly one line.
example : IsSteinerTripleSystem (Icc 1 7)
    {{1, 2, 4}, {2, 3, 5}, {3, 4, 6}, {4, 5, 7}, {5, 6, 1}, {6, 7, 2}, {7, 1, 3}} := by decide

-- Kirkman's schoolgirls (A0-A6 = 0-6, B0-B6 = 7-13, Z = 14): the 7 days of 5 rows give 35 rows
-- covering every pair once, and each day every girl walks in exactly one row.
example :
    let days : List (Finset (Finset ℕ)) := [
      {{14, 0, 7}, {1, 2, 4}, {3, 8, 12}, {5, 11, 13}, {6, 9, 10}},
      {{14, 1, 8}, {2, 3, 5}, {4, 9, 13}, {6, 12, 7}, {0, 10, 11}},
      {{14, 2, 9}, {3, 4, 6}, {5, 10, 7}, {0, 13, 8}, {1, 11, 12}},
      {{14, 3, 10}, {4, 5, 0}, {6, 11, 8}, {1, 7, 9}, {2, 12, 13}},
      {{14, 4, 11}, {5, 6, 1}, {0, 12, 9}, {2, 8, 10}, {3, 13, 7}},
      {{14, 5, 12}, {6, 0, 2}, {1, 13, 10}, {3, 9, 11}, {4, 7, 8}},
      {{14, 6, 13}, {0, 1, 3}, {2, 7, 11}, {4, 10, 12}, {5, 8, 9}}]
    IsSteinerTripleSystem (range 15) (days.foldr (· ∪ ·) ∅) ∧
      (days.foldr (· ∪ ·) ∅).card = 35 ∧
      ∀ d ∈ days, d.card = 5 ∧ ∀ g ∈ range 15, (d.filter fun t => g ∈ t).card = 1 := by
  decide

-- Worked numbers: v = 9 gives 36 pairs, b = 12, r = 4; v = 15 gives 105 pairs, b = 35, 7 days;
-- v = 11 is odd but 6 does not divide 110.
example : 9 * 8 / 2 = 36 ∧ 9 * 8 / 6 = 12 ∧ 8 / 2 = 4 := by norm_num
example : 15 * 14 / 2 = 105 ∧ 105 / 3 = 35 ∧ 35 / 5 = 7 ∧ 14 / 2 = 7 := by norm_num
example : 11 % 2 = 1 ∧ 110 % 6 ≠ 0 := by norm_num
-- Between 3 and 15, the sizes with r and b whole are exactly those with remainder 1 or 3.
example : (Icc 3 15).filter (fun v => (v - 1) % 2 = 0 ∧ v * (v - 1) % 6 = 0) = {3, 7, 9, 13, 15} ∧
    (Icc 3 15).filter (fun v => v % 6 = 1 ∨ v % 6 = 3) = {3, 7, 9, 13, 15} := by decide

#print axioms steiner_triple_system_exists_iff
#print axioms steiner_triple_system_counts
#print axioms bose_construction_is_steiner_triple_system
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'sts_point_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'sts_counts_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'sts_necessity' depends on axioms: [propext, Classical.choice, Quot.sound]
'sts_of_third' depends on axioms: [propext, Classical.choice, Quot.sound]
'sts_map' depends on axioms: [propext, Classical.choice, Quot.sound]
'sts_range_of_fintype' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_a' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_b' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_c' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_d' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_e' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_f' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_g' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_h' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_i' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_j' depends on axioms: [propext, Classical.choice, Quot.sound]
'z3_k' depends on axioms: [propext, Classical.choice, Quot.sound]
'bose_two_half' depends on axioms: [propext, Quot.sound]
'bose_cancel_two' depends on axioms: [propext, Quot.sound]
'boseThird_ne' depends on axioms: [propext, Classical.choice, Quot.sound]
'boseThird_comm' depends on axioms: [propext, Classical.choice, Quot.sound]
'boseThird_inv' depends on axioms: [propext, Classical.choice, Quot.sound]
'bose_exists' depends on axioms: [propext, Classical.choice, Quot.sound]
'sOp_comm' depends on axioms: [propext, Quot.sound]
'sOp_dv' depends on axioms: [propext, Quot.sound]
'sDv_op' depends on axioms: [propext, Quot.sound]
'sOp_self' depends on axioms: [propext, Quot.sound]
'sOp_inj' depends on axioms: [propext, Quot.sound]
'sThird_comm' depends on axioms: [propext, Classical.choice, Quot.sound]
'sThird_ne' depends on axioms: [propext, Classical.choice, Quot.sound]
'sInfty_inv' depends on axioms: [propext, Classical.choice, Quot.sound]
'sThird_ss' depends on axioms: [propext, Quot.sound]
'sThird_sn' depends on axioms: [propext, Quot.sound]
'sThird_inv' depends on axioms: [propext, Classical.choice, Quot.sound]
'skolem_exists' depends on axioms: [propext, Classical.choice, Quot.sound]
'steiner_triple_system_exists_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'steiner_triple_system_counts' depends on axioms: [propext, Classical.choice, Quot.sound]
'bose_construction_is_steiner_triple_system' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Guess first: bigger systems.** Change `range(1, 5)` in the third assert to `range(1, 7)`, so Bose and Skolem run up to v = 39. Answer: still ALL CHECKS PASS.
> - **Guess first: break the halving.** Change `(n + 1)` to `n` in `bose`. Answer: pairs repeat and the second assert stops the run.
> - **Guess first: swap one girl.** Change `(3, 8, 12)` in `base` to `(3, 8, 11)`. Answer: B4 walks twice on day 1, both Kirkman checks print no, and the fourth assert stops the run.

---

## The usual mistake

> [!warning]
> **Taking "v is odd" as the whole condition.** Oddness comes from one point's pairs (Step 1). The total count needs 3 to divide v(v − 1) as well (Step 2). For v = 11, r = 5 is whole but b = 110 / 6 = 18.33 is not, so no system on 11 points exists.
>
> - **Lines that do not wrap.** The tic-tac-toe lines, 3 rows, 3 columns and the 2 corner diagonals, are 8 lines covering only 24 of the 36 pairs.
> - **Dropping Bose's uprights.** The 9 rule triples for v = 9 cover 27 of 36 pairs; the 9 same-number pairs across layers have no triple.
> - **Counting partners as days.** Each girl has 14 partners, but she meets 2 a day, so the walk takes 14 / 2 = 7 days, not 14.

---

## Where you meet it in real life

- **Rotating groups.** Workshops that rotate people in threes, no two together twice, can use Kirkman's schedule.
- **Taste tests.** To compare 9 recipes when a taster judges only 3, give 12 tasters one grid line each: every pair of recipes is compared exactly once.
- **Error-correcting codes.** In the Hamming code of length 7, which fixes any one flipped bit, the 7 codewords with three 1s are the Fano plane's lines ([Hamming and Reed-Solomon](../../14-Applied%20and%20computational/03-Information%20Theory/08-error-correcting-codes-hamming-and-reed-solomon.md)).

> **Say it back**
> A Steiner triple system covers every pair of v points with exactly one triple. Counting pairs at one point makes v odd; counting all pairs makes 6 divide v(v − 1); together, v leaves remainder 1 or 3 on division by 6. Bose's halving rule builds every remainder-3 system and Skolem's repaired rule every remainder-1 system. The grid's 12 wrapped lines are the system on 9 points, and Kirkman's 15 girls need one that also splits into 7 days.

---

## What this builds on

- [Block designs](01-block-designs-and-fishers-inequality.md): points, blocks and the two pair counts that become Step 1 and Step 2 here.
- [Congruence](../../02-Number%20theory/03-Clock%20Arithmetic/01-congruence-mod-n.md): remainders on division by 6, and arithmetic round a clock, used by the halving rule and Kirkman's shifts.

## Where this goes next

- [Finite planes and orthogonal Latin squares](03-projective-planes-and-orthogonal-latin-squares.md): the grid's 12 lines are the affine plane of order 3 (lines can be parallel), and the Fano plane is the plane of order 2.
- [Hadamard matrices](04-hadamard-matrices.md): another design family, where the balance is between plus and minus signs rather than pairs in triples.

Triple systems are the smallest Steiner systems S(t, k, v): every t of v points lie in exactly one block of k. S(5, 6, 12) is the famous large one. The open question: how many different triple systems exist on v points, up to renaming? The count is known only for small v.

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- van Lint, J. H., and R. M. Wilson. *A Course in Combinatorics*, 2nd ed. Cambridge University Press, 2001. [doi:10.1017/CBO9780511987045](https://doi.org/10.1017/CBO9780511987045). Chapter 19, Designs: Steiner systems, the counting conditions and Kirkman's problem.
- Colbourn, Charles J., and Alexander Rosa. *Triple Systems*. Oxford University Press, 1999. [doi:10.1093/oso/9780198535768.001.0001](https://doi.org/10.1093/oso/9780198535768.001.0001). The standard monograph: existence, Bose's and Skolem's constructions, uniqueness for 7 and 9 points.
- Bose, R. C. "On the construction of balanced incomplete block designs." *Annals of Eugenics* 9 (1939), 353–399. [doi:10.1111/j.1469-1809.1939.tb02219.x](https://doi.org/10.1111/j.1469-1809.1939.tb02219.x). The construction for v = 6n + 3.
- Skolem, Th. "Some remarks on the triple systems of Steiner." *Mathematica Scandinavica* 6 (1958), 273–280. [doi:10.7146/math.scand.a-10551](https://doi.org/10.7146/math.scand.a-10551). The construction for v = 6n + 1.
