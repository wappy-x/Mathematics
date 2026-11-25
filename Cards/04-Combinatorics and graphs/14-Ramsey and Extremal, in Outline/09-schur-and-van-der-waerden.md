# Ramsey theory on the whole numbers: Schur's single-coloured x + y = z, van der Waerden's single-coloured progressions, and the Hales-Jewett theorem behind both

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Ramsey and Extremal, in Outline](../README.md#s14) → Ramsey theory on the whole numbers

---

## General Overview

Paint 1, 2, 5 and 6 red and 3, 4, 7 and 8 blue. No three equally spaced numbers, such as 2, 5, 8, share a colour. Equally spaced numbers form an **arithmetic progression**: a list with one fixed gap, like 2, 5, 8 with gap 3.

Add 9 and no colouring escapes; the code tries them all. So 9 is the threshold, written $`W(3; 2) = 9`$: progressions of 3 terms, 2 colours.

Sums behave the same way. Colour 1 and 4 red, 2 and 3 blue: no colour holds a sum $`x + y = z`$, with $`x = y`$ allowed. Add 5 and it fails: red 5 gives 1 + 4 = 5, blue 5 gives 2 + 3 = 5.

Issai Schur proved in 1917 that this always happens, for any number of colours.

These are the Ramsey facts of [Friends and strangers](01-friends-and-strangers.md) and [Ramsey numbers](02-ramsey-numbers.md), moved onto the whole numbers.

**Finitely colour enough consecutive whole numbers and one colour holds a sum x + y = z (Schur) and any chosen progression length (van der Waerden, via Hales-Jewett).**

**What kind of fact this is:** three theorems. Schur's is proved here, and $`W(3; 2) = 9`$ by hand and by search. Van der Waerden's and Hales-Jewett are stated, with the link between them proved.

### The picture: 8 numbers dodge, 9 cannot

| Number | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Colour | red | red | blue | blue | red | red | blue | blue | ? |
| If 9 is red | **red** | | | | **red** | | | | **red** |
| If 9 is blue | | | | | | | **blue** | **blue** | **blue** |

Red 9 completes 1, 5, 9; blue 9 completes 7, 8, 9. Other colourings fail at 9 in other ways; the code checks them all.

---

## The formula

A **colouring** gives each number one colour. A colouring **dodges** a pattern when no copy of the pattern has all its numbers in one colour.

- $`S(r)`$ is the **Schur number**: the largest $`N`$ for which some colouring of 1 to $`N`$ with $`r`$ colours dodges every $`x + y = z`$.
- $`W(3; r)`$ is the **van der Waerden number**: the fewest numbers, 1 to $`W`$, that force a single-coloured progression $`a,\ a+d,\ a+2d`$ with $`r`$ colours.
- $`R_r(3)`$ is the triangle Ramsey number: the fewest points that force a one-colour triangle when every line between two points gets one of $`r`$ colours. With two colours it is $`R(3,3) = 6`$.

Schur's theorem, in the form this card proves:

```math
S(r) \le R_r(3) - 2
```

**Read it aloud:** the longest run dodging x + y = z is at most the triangle Ramsey number minus two.

For two colours: $`S(2) \le 6 - 2 = 4`$, and red 1, 4, blue 2, 3 dodges. So $`S(2) = 4`$.

The key step turns three points into a sum. For points $`i < j < l`$ on a line:

```math
(j - i) + (l - j) = l - i
```

**Read it aloud:** the gap from i to j plus the gap from j to l is the gap from i to l.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`r`$ | number of colours | 2 | every threshold rises |
| $`N`$ | the numbers in play are 1 to $`N`$ | 4 for Schur, 8 for progressions | dodging gets harder |
| $`x, y, z`$; $`i < j < l`$ | a sum $`x + y = z`$ ($`x = y`$ allowed); in the proof, gaps between three points | points 0, 1, 5 give 1 + 4 = 5 | — |
| $`S(r)`$ | Schur number | $`S(2) = 4`$; $`S(3) = 13`$ | — |
| $`R_r(3)`$ | triangle Ramsey number | $`R(3,3) = 6`$; with 3 colours, $`R(3,3,3) = 17`$ | Schur's ceiling rises |
| $`a, d`$ | first term and gap of a progression $`a, a+d, a+2d`$ | 1 and 4: 1, 5, 9 | — |
| $`W(k; r)`$ | fewest numbers forcing a one-colour progression of $`k`$ terms | $`W(3; 2) = 9`$ | rises fast with $`k`$ |
| $`n`$ | dimension of a noughts-and-crosses board | 2 for paper, 3 for the cube | lines multiply |

### When it holds

- **Finitely many colours.** Give every number its own colour and nothing is single-coloured.
- **x = y is allowed in Schur.** Demand different numbers and the dodge stretches from 1..4 to 1..8.
- **Every number in the run is coloured.** Leave one out and patterns through it stop counting.
- **Equal gaps, not any three numbers.** 1, 2, 5 are all red but not a progression.

---

## Why it works

### Step 0: gaps between points are numbers

Put points 0, 1, …, 5 on a line. Colour each link by the colour of its gap: link 1–5 gets the colour of 4. A triangle $`i < j < l`$ carries gaps that add up, $`(j-i) + (l-j) = l-i`$, so a one-colour triangle is a one-colour sum.

### Step 1: Schur's theorem from triangles

Colour 1 to 5 with two colours. Then all links among points 0 to 5 are coloured, and $`R(3,3) = 6`$ gives a one-colour triangle ([Friends and strangers](01-friends-and-strangers.md)). Its gaps $`x = j - i`$, $`y = l - j`$, $`z = l - i`$ share that colour.

So 1 to 5 cannot dodge; the code checks all 32 colourings. In the example, red 5 gives points 0, 1, 5 (gaps 1, 4, 5); blue 5 gives points 0, 2, 5 (gaps 2, 3, 5).

With $`r`$ colours, $`R_r(3)`$ points have gaps 1 to $`R_r(3) - 1`$, so that run cannot dodge: $`S(r) \le R_r(3) - 2`$. Ramsey's theorem ([Ramsey numbers](02-ramsey-numbers.md)) makes every $`S(r)`$ finite.

### Step 2: ceiling and floor

For two colours the ceiling 4 is met: $`S(2) = 4`$. Only 2 colourings of 1 to 4 dodge, red 1, 4, blue 2, 3 and its colour swap.

For three colours, $`R_3(3) = 17`$ (Greenwood and Gleason, 1955; not proved here) gives the ceiling 15. The search finds the longest dodge is 1 to 13, so $`S(3) = 13`$. The triangle road gives a ceiling, not the value, as on [Ramsey numbers](02-ramsey-numbers.md).

### Step 3: W(3; 2) = 9

The picture shows 1 to 8 dodge. For 9, a short hand argument starting from 4 and 6 covers every colouring. The search agrees: 6 colourings of 1 to 8 dodge, and none of 1 to 9.

<details>
<summary>Detailed proof: every 2-colouring of 1 to 9 has a single-coloured progression</summary>

Suppose a colouring of 1 to 9 dodges.

**4 and 6 share a colour, say red.** Then 2 is blue (from 2, 4, 6), 5 is blue (from 4, 5, 6) and 8 is blue (from 4, 6, 8). But 2, 5, 8 is a progression, all blue.

**4 and 6 differ.** Say 4 is red and 6 blue. Reflecting $`x \to 10 - x`$ swaps 4 and 6 and keeps progressions, so we may also take 5 red. Then, one forced step at a time:

1. 4, 5 red, so 3 is blue (3, 4, 5).
2. 3, 6 blue, so 9 is red (3, 6, 9).
3. 5, 9 red, so 1 is blue (1, 5, 9) and 7 is blue (5, 7, 9).
4. 6, 7 blue, so 8 is red (6, 7, 8).
5. 1, 3 blue, so 2 is red (1, 2, 3).

Now 2, 5, 8 are all red. Both cases fail, so no dodge exists.

</details>

### Step 4: van der Waerden's theorem

Bartel van der Waerden proved in 1927 that for every length $`k`$ and number of colours $`r`$, some $`W(k; r)`$ forces a single-coloured progression of $`k`$ terms. The proof is a nested pigeonhole argument ([Pigeonhole, extended](../04-Inclusion-Exclusion%20and%20Pigeonhole/05-pigeonhole-extended.md)), with no density or analysis, unlike Szemerédi's later theorem, which also implies it.

The values grow fast; few are known.

### Step 5: the Hales-Jewett theorem, on a noughts-and-crosses board

Number the rows and columns of a noughts-and-crosses board 0, 1, 2, so each cell is a two-digit word such as 21. A **Hales-Jewett line** (combinatorial line) comes from a template with fixed digits and at least one moving place $`*`$; moving places run 0, 1, 2 together.

- Template $`1*`$ gives 10, 11, 12: a row.
- Template $`**`$ gives 00, 11, 22: a diagonal.
- The other diagonal, 02, 11, 20, needs one place rising while the other falls. No template does that.

Each place is 0, 1, 2 or moving, minus the all-fixed case. That leaves $`4^n - 3^n`$ Hales-Jewett lines in $`n`$ dimensions: 7 on the paper board, against the game's 8 winning lines.

**The Hales-Jewett theorem** (Alfred Hales and Robert Jewett, 1963): for any alphabet size and number of colours, a board of high enough dimension forces a single-coloured Hales-Jewett line. In game terms, noughts and crosses in enough dimensions cannot be drawn.

The paper board can draw: 16 full boards of 5 crosses and 4 noughts hold no line. No 2-colouring of the $`3 \times 3 \times 3`$ cube dodges all 49 winning lines. But 1644 dodge its 37 Hales-Jewett lines, so three dimensions are not yet enough for the theorem.

### Step 6: Hales-Jewett gives van der Waerden

Add up a cell's digits. Along a Hales-Jewett line the sum rises each step by the number of moving places: $`*1*`$ gives 010, 111, 212 with sums 1, 3, 5. So every line's sums form a 3-term progression; the code checks all 37 in the cube.

Colour each cell by the colour of its digit sum. A single-coloured line becomes a single-coloured progression among the sums 0 to $`2n`$, so $`W(3; r) \le 2n + 1`$. Longer alphabets give longer progressions.

Schur's pattern comes from Ramsey's theorem instead. Both meet in a theorem of Ronald Graham and Bruce Rothschild (1971) that contains Ramsey's theorem and Hales-Jewett.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Schur dodge on 1 to 4 | red 1, 4; blue 2, 3; check 1+1, 1+2, 1+3, 2+2 | 0 single-coloured sums |
| add 5 as red | triangle on points 0, 1, 5 | 1 + 4 = 5, all red |
| add 5 as blue | triangle on points 0, 2, 5 | 2 + 3 = 5, all blue |
| Schur ceiling, 2 colours | $`R(3,3) - 2 = 6 - 2`$ | **S(2) = 4** |
| progression dodge on 1 to 8 | red 1, 2, 5, 6; blue 3, 4, 7, 8 | 0 single-coloured progressions |
| colourings of 1 to 8 that dodge | search | 6 |
| colourings of 1 to 9 that dodge | hand proof and search | 0, so **W(3; 2) = 9** |
| Hales-Jewett lines on the paper board | $`4^2 - 3^2 = 16 - 9`$ | 7 |
| digit sums along $`*1*`$ | 0+1+0, 1+1+1, 2+1+2 | 1, 3, 5 |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Demanding x different from y | longest dodge 1 to 8, not 4 | A different pattern |
| Reading the triangle ceiling as the value, 3 colours | S(3) = 15 | The search finds 13 |
| Counting the anti-diagonal as a Hales-Jewett line | 8 lines, not 7 | One place rises while the other falls |
| Treating the cube's 49 lines as Hales-Jewett lines | no dodge in 3 dimensions | Only 37 are; 1644 colourings dodge those |

---

## Code, from first principles, and it actually runs

Nothing is imported. Each pattern becomes a list of triples that must not share one colour. Road one tries every colouring; road two grows colourings one number at a time, dropping failures. For Schur on 1 to 5, a third road finds a one-colour triangle on six points. Board lines come from templates, and digit sums are checked along each.

### Python

```python
# Schur and van der Waerden -- the check behind the card.  Nothing is imported.  Cells count from 0; col[i] is
# cell i's colour; a "triple" lists cells that must not all share one colour.  Road one tries every colouring;
# road two grows colourings one cell at a time, keeping those that dodge.
def every(m, r):                                   # all colourings of m cells with r colours
    out = [[]]
    for _ in range(m): out = [c + [k] for c in out for k in range(r)]
    return out
def mono(col, triples): return sum(len({col[c] for c in t}) == 1 for t in triples)
def brute(m, r, triples): return [sum(mono(c, [t for t in triples if max(t) < n]) == 0 for c in every(n, r)) for n in range(1, m + 1)]
def grow(m, r, triples):                           # road two: dodging colourings of cells 0..n-1, for each n
    by, counts = [[sorted(t) for t in triples if max(t) == i] for i in range(m)], [0] * m
    def go(col):
        for k in range(r if len(col) < m else 0):
            if not any(all(col[c] == k for c in t[:-1]) for t in by[len(col)]):
                counts[len(col)] += 1; go(col + [k])
    go([]); return counts
def schur(m, strict=False): return [(x - 1, y - 1, x + y - 1) for x in range(1, m) for y in range(x + strict, m + 1 - x)]
def ap(m): return [(a, a + d, a + 2 * d) for a in range(m) for d in range(1, m) if a + 2 * d < m]
def lines(n, geo):                                 # lines of the 3 x ... x 3 board; "+" runs 0,1,2 and "-" runs 2,1,0
    opts, out = [0, 1, 2, "+"] + ["-"] * geo, []
    for code in range(len(opts) ** n):
        p = [opts[code // len(opts) ** i % len(opts)] for i in range(n)]
        moving = [o for o in p if o in ("+", "-")]
        if moving and moving[0] == "+":            # a line and its reverse are counted once
            out.append(tuple(sum(3 ** i * (j if o == "+" else 2 - j if o == "-" else o) for i, o in enumerate(p)) for j in range(3)))
    return out
def last(counts): return max(n + 1 for n in range(len(counts)) if counts[n])
col4, cv = [0, 1, 1, 0], [0, 0, 1, 1, 0, 0, 1, 1]  # red is 0: Schur's 1, 4 red; van der Waerden's 1, 2, 5, 6 red
print(f"Schur: red [1, 4], blue [2, 3]: single-coloured x + y = z on 1..4: {mono(col4, schur(4))}")
s_b, s_g = brute(5, 2, schur(5)), grow(5, 2, schur(5))
print(f"2-colourings of 1..n dodging x + y = z, n = 1..5, every colouring tried: {s_b}")
print(f"the same, grown one number at a time: {s_g}")
def triangle(col):                                 # road three: points 0..5, the side i-j coloured by |i - j|
    return [(j - i, k - j, k - i) for i in range(6) for j in range(i + 1, 6) for k in range(j + 1, 6) if col[j - i - 1] == col[k - j - 1] == col[k - i - 1]]
tri = sum(len(t := triangle(c)) > 0 and all(mono(c, [(x - 1, y - 1, z - 1)]) for x, y, z in t) for c in every(5, 2))
print(f"Ramsey road: colourings of 1..5 whose 6 points hold a single-coloured triangle: {tri} of 32")
for k, name in ((0, "red"), (1, "blue")):
    x, y, z = triangle(col4 + [k])[0]; print(f"add 5 as {name}: the triangle gives {x} + {y} = {z}, all {name}")
s3 = grow(14, 3, schur(14))
print(f"three colours: longest dodge 1..{last(s3)}; Ramsey ceiling R(3,3,3) - 2 = 17 - 2 = {17 - 2}")
print(f"van der Waerden: red [1, 2, 5, 6], blue [3, 4, 7, 8]: single-coloured progressions on 1..8: {mono(cv, ap(8))}")
w_b, w_g = brute(9, 2, ap(9)), grow(9, 2, ap(9))
print(f"2-colourings of 1..n dodging 3-term progressions, n = 1..9, every colouring tried: {w_b}")
print(f"the same, grown one number at a time: {w_g}; so W(3; 2) = {w_b.index(0) + 1}")
g2, c2, g3, c3 = lines(2, 1), lines(2, 0), lines(3, 1), lines(3, 0)
draws = sum(mono(c, g2) == 0 for c in every(9, 2) if sum(c) == 5)
print(f"noughts and crosses: lines {len(g2)}, Hales-Jewett lines {len(c2)} = 4^2 - 3^2; drawn full boards (5 X, 4 O): {draws}")
cube_g, cube_c = grow(27, 2, g3)[-1], grow(27, 2, c3)[-1]
print(f"3 x 3 x 3 cube: lines {len(g3)} = (5^3 - 3^3)/2, 2-colourings dodging them all: {cube_g}")
print(f"cube: Hales-Jewett lines {len(c3)} = 4^3 - 3^3, 2-colourings dodging them all: {cube_c}")
sums = [[sum(c // 3 ** i % 3 for i in range(3)) for c in t] for t in c3]
ok = sum(s[1] - s[0] == s[2] - s[1] > 0 for s in sums)
print(f"Hales-Jewett lines whose digit sums form a 3-term progression: {ok} of {len(c3)}; line (j, 1, j): {sums[c3.index((3, 13, 23))]}")
weak = grow(10, 2, schur(10, True))
print(f"mistake, demanding x different from y: longest dodge 1..{last(weak)}")
assert s_b == s_g and s_b[4] == 0 and s_b[3] == 2 and tri == 32           # Schur on 1..5: three roads agree
assert w_b == w_g and w_b[8] == 0 and w_b[7] == 6 and mono(cv, ap(8)) == 0  # W(3; 2) = 9: two roads agree
assert last(s3) == 13 and len(c2) == 4**2 - 3**2 and len(g3) == (5**3 - 3**3) // 2 and cube_g == 0
assert draws == 16 and cube_c > 0 and ok == len(c3) and last(weak) == 8
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
Schur: red [1, 4], blue [2, 3]: single-coloured x + y = z on 1..4: 0
2-colourings of 1..n dodging x + y = z, n = 1..5, every colouring tried: [2, 2, 4, 2, 0]
the same, grown one number at a time: [2, 2, 4, 2, 0]
Ramsey road: colourings of 1..5 whose 6 points hold a single-coloured triangle: 32 of 32
add 5 as red: the triangle gives 1 + 4 = 5, all red
add 5 as blue: the triangle gives 2 + 3 = 5, all blue
three colours: longest dodge 1..13; Ramsey ceiling R(3,3,3) - 2 = 17 - 2 = 15
van der Waerden: red [1, 2, 5, 6], blue [3, 4, 7, 8]: single-coloured progressions on 1..8: 0
2-colourings of 1..n dodging 3-term progressions, n = 1..9, every colouring tried: [2, 4, 6, 10, 14, 20, 16, 6, 0]
the same, grown one number at a time: [2, 4, 6, 10, 14, 20, 16, 6, 0]; so W(3; 2) = 9
noughts and crosses: lines 8, Hales-Jewett lines 7 = 4^2 - 3^2; drawn full boards (5 X, 4 O): 16
3 x 3 x 3 cube: lines 49 = (5^3 - 3^3)/2, 2-colourings dodging them all: 0
cube: Hales-Jewett lines 37 = 4^3 - 3^3, 2-colourings dodging them all: 1644
Hales-Jewett lines whose digit sums form a 3-term progression: 37 of 37; line (j, 1, j): [1, 3, 5]
mistake, demanding x different from y: longest dodge 1..8
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Schur and van der Waerden -- the same check as the Python, in Rust.  No crates.  Cells count from 0; col[i] is
// cell i's colour; a "triple" lists cells that must not all share one colour.  Road one tries every colouring;
// road two grows colourings one cell at a time, keeping those that dodge.
type T = Vec<[usize; 3]>;
fn every(m: usize, r: usize) -> Vec<Vec<usize>> {                 // all colourings of m cells with r colours
    (0..m).fold(vec![vec![]], |out, _| out.iter().flat_map(|c: &Vec<usize>| (0..r).map(move |k| [c.clone(), vec![k]].concat())).collect())
}
fn mono(col: &[usize], t: &T) -> usize { t.iter().filter(|s| col[s[0]] == col[s[1]] && col[s[1]] == col[s[2]]).count() }
fn brute(m: usize, r: usize, t: &T) -> Vec<usize> {
    (1..=m).map(|n| { let u: T = t.iter().filter(|s| *s.iter().max().unwrap() < n).cloned().collect();
                      every(n, r).iter().filter(|c| mono(c, &u) == 0).count() }).collect()
}
fn go(col: &mut Vec<usize>, m: usize, r: usize, by: &Vec<T>, counts: &mut Vec<usize>) {
    let i = col.len();
    for k in 0..if i < m { r } else { 0 } {
        if !by[i].iter().any(|s| col[s[0]] == k && col[s[1]] == k) { counts[i] += 1; col.push(k); go(col, m, r, by, counts); col.pop(); }
    }
}
fn grow(m: usize, r: usize, t: &T) -> Vec<usize> {               // road two: dodging colourings of cells 0..n-1
    let (mut by, mut counts): (Vec<T>, Vec<usize>) = (vec![vec![]; m], vec![0; m]);
    for s in t { let mut u = *s; u.sort(); by[u[2]].push(u) }
    go(&mut vec![], m, r, &by, &mut counts);
    counts
}
fn schur(m: usize, strict: bool) -> T {
    (1..m).flat_map(|x| (x + strict as usize..=m - x).map(move |y| [x - 1, y - 1, x + y - 1])).collect()
}
fn ap(m: usize) -> T { let mut v = vec![]; for a in 0..m { for d in 1..m { if a + 2 * d < m { v.push([a, a + d, a + 2 * d]) } } } v }
fn lines(n: u32, geo: bool) -> T {                                // 0, 1, 2 fixed; 3 runs 0,1,2; 4 runs 2,1,0
    let (w, mut out): (usize, T) = (if geo { 5 } else { 4 }, vec![]);
    for code in 0..w.pow(n) {
        let p: Vec<usize> = (0..n).map(|i| code / w.pow(i) % w).collect();
        if p.iter().find(|&&o| o > 2) != Some(&3) { continue }     // a line and its reverse are counted once
        let cell = |j: usize| p.iter().enumerate().map(|(i, &o)| 3usize.pow(i as u32) * match o { 3 => j, 4 => 2 - j, _ => o }).sum::<usize>();
        out.push([cell(0), cell(1), cell(2)]);
    }
    out
}
fn last(c: &[usize]) -> usize { (0..c.len()).filter(|&n| c[n] > 0).max().unwrap() + 1 }
fn triangle(col: &[usize]) -> Vec<(usize, usize, usize)> {        // road three: points 0..5, side i-j coloured by j - i
    (0..6).flat_map(|i| (i + 1..6).flat_map(move |j| (j + 1..6).map(move |k| (j - i, k - j, k - i))))
        .filter(|&(x, y, z)| col[x - 1] == col[y - 1] && col[y - 1] == col[z - 1]).collect()
}
fn main() {
    let (col4, cv) = (vec![0, 1, 1, 0], vec![0, 0, 1, 1, 0, 0, 1, 1]);
    println!("Schur: red [1, 4], blue [2, 3]: single-coloured x + y = z on 1..4: {}", mono(&col4, &schur(4, false)));
    let (s_b, s_g) = (brute(5, 2, &schur(5, false)), grow(5, 2, &schur(5, false)));
    println!("2-colourings of 1..n dodging x + y = z, n = 1..5, every colouring tried: {:?}", s_b);
    println!("the same, grown one number at a time: {:?}", s_g);
    let tri = every(5, 2).iter().filter(|c| { let t = triangle(c); !t.is_empty() && t.iter().all(|&(x, y, z)| c[x - 1] == c[y - 1] && c[y - 1] == c[z - 1]) }).count();
    println!("Ramsey road: colourings of 1..5 whose 6 points hold a single-coloured triangle: {} of 32", tri);
    for (k, name) in [(0, "red"), (1, "blue")] {
        let (x, y, z) = triangle(&[col4.clone(), vec![k]].concat())[0];
        println!("add 5 as {}: the triangle gives {} + {} = {}, all {}", name, x, y, z, name);
    }
    let s3 = grow(14, 3, &schur(14, false));
    println!("three colours: longest dodge 1..{}; Ramsey ceiling R(3,3,3) - 2 = 17 - 2 = {}", last(&s3), 17 - 2);
    println!("van der Waerden: red [1, 2, 5, 6], blue [3, 4, 7, 8]: single-coloured progressions on 1..8: {}", mono(&cv, &ap(8)));
    let (w_b, w_g) = (brute(9, 2, &ap(9)), grow(9, 2, &ap(9)));
    println!("2-colourings of 1..n dodging 3-term progressions, n = 1..9, every colouring tried: {:?}", w_b);
    println!("the same, grown one number at a time: {:?}; so W(3; 2) = {}", w_g, w_b.iter().position(|&x| x == 0).unwrap() + 1);
    let (g2, c2, g3, c3) = (lines(2, true), lines(2, false), lines(3, true), lines(3, false));
    let draws = every(9, 2).iter().filter(|c| c.iter().sum::<usize>() == 5 && mono(c, &g2) == 0).count();
    println!("noughts and crosses: lines {}, Hales-Jewett lines {} = 4^2 - 3^2; drawn full boards (5 X, 4 O): {}", g2.len(), c2.len(), draws);
    let (cube_g, cube_c) = (grow(27, 2, &g3)[26], grow(27, 2, &c3)[26]);
    println!("3 x 3 x 3 cube: lines {} = (5^3 - 3^3)/2, 2-colourings dodging them all: {}", g3.len(), cube_g);
    println!("cube: Hales-Jewett lines {} = 4^3 - 3^3, 2-colourings dodging them all: {}", c3.len(), cube_c);
    let sums: Vec<Vec<usize>> = c3.iter().map(|t| t.iter().map(|&c| (0..3).map(|i| c / 3usize.pow(i) % 3).sum()).collect()).collect();
    let ok = sums.iter().filter(|s| s[1] > s[0] && s[1] - s[0] + s[1] == s[2]).count();
    let e = &sums[c3.iter().position(|t| *t == [3, 13, 23]).unwrap()];
    println!("Hales-Jewett lines whose digit sums form a 3-term progression: {} of {}; line (j, 1, j): {:?}", ok, c3.len(), e);
    let weak = grow(10, 2, &schur(10, true));
    println!("mistake, demanding x different from y: longest dodge 1..{}", last(&weak));
    assert!(s_b == s_g && s_b[4] == 0 && s_b[3] == 2 && tri == 32);            // Schur on 1..5: three roads agree
    assert!(w_b == w_g && w_b[8] == 0 && w_b[7] == 6 && mono(&cv, &ap(8)) == 0); // W(3; 2) = 9: two roads agree
    assert!(last(&s3) == 13 && c2.len() == 16 - 9 && g3.len() == (125 - 27) / 2 && cube_g == 0);
    assert!(draws == 16 && cube_c > 0 && ok == c3.len() && last(&weak) == 8);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
Schur: red [1, 4], blue [2, 3]: single-coloured x + y = z on 1..4: 0
2-colourings of 1..n dodging x + y = z, n = 1..5, every colouring tried: [2, 2, 4, 2, 0]
the same, grown one number at a time: [2, 2, 4, 2, 0]
Ramsey road: colourings of 1..5 whose 6 points hold a single-coloured triangle: 32 of 32
add 5 as red: the triangle gives 1 + 4 = 5, all red
add 5 as blue: the triangle gives 2 + 3 = 5, all blue
three colours: longest dodge 1..13; Ramsey ceiling R(3,3,3) - 2 = 17 - 2 = 15
van der Waerden: red [1, 2, 5, 6], blue [3, 4, 7, 8]: single-coloured progressions on 1..8: 0
2-colourings of 1..n dodging 3-term progressions, n = 1..9, every colouring tried: [2, 4, 6, 10, 14, 20, 16, 6, 0]
the same, grown one number at a time: [2, 4, 6, 10, 14, 20, 16, 6, 0]; so W(3; 2) = 9
noughts and crosses: lines 8, Hales-Jewett lines 7 = 4^2 - 3^2; drawn full boards (5 X, 4 O): 16
3 x 3 x 3 cube: lines 49 = (5^3 - 3^3)/2, 2-colourings dodging them all: 0
cube: Hales-Jewett lines 37 = 4^3 - 3^3, 2-colourings dodging them all: 1644
Hales-Jewett lines whose digit sums form a 3-term progression: 37 of 37; line (j, 1, j): [1, 3, 5]
mistake, demanding x different from y: longest dodge 1..8
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves all three theorems for every number of colours, and the two-colour values $`S(2) = 4`$ and $`W(3; 2) = 9`$.

- Schur's theorem: with finitely many colours, some run 1 to $`N`$ forces a single-coloured $`x + y = z`$, with $`x = y`$ allowed.
- Suppose every colouring of the links between points 0 to $`M - 1`$ forces a single-coloured triangle. Then every colouring of 1 to $`M - 1`$ forces a single-coloured $`x + y = z`$.
- Van der Waerden's theorem: for every length $`k`$ and number of colours, some run 1 to $`N`$ forces a single-coloured progression of $`k`$ terms.
- The Hales-Jewett theorem: for any alphabet size and any number of colours, a board of high enough dimension forces a single-coloured Hales-Jewett line.
- Take two colours on 1 to 4. Then red 1, 4 and blue 2, 3 dodge every sum, and exactly 2 colourings dodge.
- Take two colours on 1 to 5. Then no colouring dodges $`x + y = z`$, so $`S(2) = 4`$.
- Take two colours on 1 to 8. Then red 1, 2, 5, 6 and blue 3, 4, 7, 8 dodge every progression, and exactly 6 colourings dodge.
- Take two colours on 1 to 9. Then no colouring dodges a 3-term progression, so $`W(3; 2) = 9`$.

Python and Rust alone check $`S(3) = 13`$, the line counts on the boards, the 16 draws and the 1644 cube dodges.

```lean
-- Ramsey theory on the whole numbers: colour enough consecutive whole numbers with finitely many colours and one colour must hold a sum x + y = z (Schur) and a progression of any chosen length (van der Waerden), with Schur's run bounded by the triangle Ramsey threshold, the Hales-Jewett theorem, and the two-colour values S(2) = 4 and W(3; 2) = 9 checked.
import Mathlib.Combinatorics.HalesJewett
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Finset.Max
import Mathlib.Combinatorics.Pigeonhole
import Mathlib.Algebra.Order.BigOperators.Group.Finset

/-- Helper: triangle Ramsey for any number of colours, on any large enough set of naturals. -/
theorem svdw_tri_ramsey {κ : Type*} [DecidableEq κ] (r : ℕ) :
    ∃ N : ℕ, ∀ V : Finset ℕ, N ≤ V.card → ∀ T : Finset κ, T.card ≤ r →
      ∀ c : ℕ → ℕ → κ, (∀ i ∈ V, ∀ j ∈ V, i < j → c i j ∈ T) →
        ∃ i ∈ V, ∃ j ∈ V, ∃ l ∈ V, i < j ∧ j < l ∧ c i j = c i l ∧ c j l = c i l := by
  induction r with
  | zero =>
    refine ⟨2, fun V hV T hT c hc => ?_⟩
    have hT0 : T = ∅ := Finset.card_eq_zero.1 (by omega)
    obtain ⟨a, ha, b, hb, hab⟩ := Finset.one_lt_card.1 (by omega : 1 < V.card)
    exfalso
    rcases lt_or_gt_of_ne hab with h | h
    · simpa [hT0] using hc a ha b hb h
    · simpa [hT0] using hc b hb a ha h
  | succ r ih =>
    obtain ⟨N, hN⟩ := ih
    refine ⟨(r + 1) * N + 2, fun V hV T hT c hc => ?_⟩
    have hVne : V.Nonempty := Finset.card_pos.1 (by omega)
    set v := V.min' hVne with hv
    have hvV : v ∈ V := V.min'_mem hVne
    set V' := V.erase v with hV'
    have hV'card : V'.card = V.card - 1 := Finset.card_erase_of_mem hvV
    have hlt : ∀ j ∈ V', v < j := by
      intro j hj
      rw [Finset.mem_erase] at hj
      exact lt_of_le_of_ne (V.min'_le j hj.2) (Ne.symm hj.1)
    have hmaps : ∀ j ∈ V', c v j ∈ T := fun j hj =>
      hc v hvV j (Finset.mem_of_mem_erase hj) (hlt j hj)
    obtain ⟨j0, hj0⟩ : V'.Nonempty := Finset.card_pos.1 (by omega)
    have hTne : T.Nonempty := ⟨_, hmaps j0 hj0⟩
    obtain ⟨t, htT, hW⟩ := Finset.exists_le_card_fiber_of_mul_le_card_of_maps_to hmaps hTne
      (n := N) (by
        calc T.card * N ≤ (r + 1) * N := Nat.mul_le_mul_right _ hT
          _ ≤ V'.card := by omega)
    set W := V'.filter (fun j => c v j = t) with hWdef
    have hWV : ∀ j ∈ W, j ∈ V ∧ v < j ∧ c v j = t := by
      intro j hj
      rw [hWdef, Finset.mem_filter] at hj
      exact ⟨Finset.mem_of_mem_erase hj.1, hlt j hj.1, hj.2⟩
    by_cases h : ∃ j ∈ W, ∃ l ∈ W, j < l ∧ c j l = t
    · obtain ⟨j, hj, l, hl, hjl, hc'⟩ := h
      obtain ⟨hjV, hvj, hcj⟩ := hWV j hj
      obtain ⟨hlV, hvl, hcl⟩ := hWV l hl
      exact ⟨v, hvV, j, hjV, l, hlV, hvj, hjl, by rw [hcj, hcl], by rw [hc', hcl]⟩
    · push Not at h
      obtain ⟨i, hi, j, hj, l, hl, h1, h2, h3, h4⟩ := hN W hW (T.erase t)
        (by rw [Finset.card_erase_of_mem htT]; omega) c
        (fun i hi j hj hij => Finset.mem_erase.2
          ⟨h i hi j hj hij, hc i (hWV i hi).1 j (hWV j hj).1 hij⟩)
      exact ⟨i, (hWV i hi).1, j, (hWV j hj).1, l, (hWV l hl).1, h1, h2, h3, h4⟩

#print axioms svdw_tri_ramsey

/-- Helper: Schur from triangles (same statement as `schur_from_triangles`). -/
theorem svdw_schur_from_triangles {κ : Type*} (M : ℕ)
    (hR : ∀ c : ℕ → ℕ → κ, ∃ i j l : ℕ,
        i < j ∧ j < l ∧ l < M ∧ c i j = c i l ∧ c j l = c i l) :
    ∀ C : ℕ → κ, ∃ x y z : ℕ,
        1 ≤ x ∧ 1 ≤ y ∧ x + y = z ∧ z ≤ M - 1 ∧ C x = C z ∧ C y = C z := by
  intro C
  obtain ⟨i, j, l, hij, hjl, hlM, h1, h2⟩ := hR (fun i j => C (j - i))
  refine ⟨j - i, l - j, l - i, by omega, by omega, by omega, by omega, h1, h2⟩

#print axioms svdw_schur_from_triangles

/-- Helper: Hales-Jewett with dimension `Fin n` (same statement as `hales_jewett`). -/
theorem svdw_hales_jewett (m r : ℕ) :
    ∃ n : ℕ, ∀ C : (Fin n → Fin m) → Fin r,
      ∃ l : Combinatorics.Line (Fin m) (Fin n), l.IsMono C := by
  obtain ⟨ι, ιfin, hι⟩ := Combinatorics.Line.exists_mono_in_high_dimension (Fin m) (Fin r)
  refine ⟨Fintype.card ι, fun C => ?_⟩
  obtain ⟨l, c, cl⟩ := hι fun v => C (v ∘ (Fintype.equivFin ι).symm)
  refine ⟨⟨l.idxFun ∘ (Fintype.equivFin ι).symm, ?_⟩, c, fun x => ?_⟩
  · obtain ⟨i, hi⟩ := l.proper
    exact ⟨Fintype.equivFin ι i, by simpa using hi⟩
  · rw [← cl x]
    rfl

#print axioms svdw_hales_jewett

/-- Helper: van der Waerden with a finite bound, from Hales-Jewett. -/
theorem svdw_vdw (r k : ℕ) : ∃ N : ℕ, ∀ C : ℕ → Fin r, ∃ a d : ℕ,
        1 ≤ a ∧ 1 ≤ d ∧ a + (k - 1) * d ≤ N ∧ ∀ i < k, C (a + i * d) = C a := by
  classical
  rcases Nat.eq_zero_or_pos k with hk | hk
  · subst hk
    exact ⟨1, fun C => ⟨1, 1, le_rfl, le_rfl, by simp, fun i hi => absurd hi (Nat.not_lt_zero _)⟩⟩
  obtain ⟨n, hn⟩ := svdw_hales_jewett k r
  refine ⟨1 + n * (k - 1), fun C => ?_⟩
  obtain ⟨l, c, hl⟩ := hn fun w => C (1 + ∑ i, (w i).val)
  set d := (Finset.univ.filter (fun i => l.idxFun i = none)).card with hd
  set A := ∑ i, ((l.idxFun i).map Fin.val).getD 0 with hA
  have key : ∀ x : Fin k, ∑ i, (l x i).val = A + x.val * d := by
    intro x
    have hpt : ∀ i, (l x i).val =
        ((l.idxFun i).map Fin.val).getD 0 + (if l.idxFun i = none then x.val else 0) := by
      intro i
      rw [Combinatorics.Line.coe_apply]
      cases l.idxFun i <;> simp
    rw [Finset.sum_congr rfl (fun i _ => hpt i), Finset.sum_add_distrib, ← Finset.sum_filter,
      Finset.sum_const, smul_eq_mul, hA, hd, Nat.mul_comm]
  have hdpos : 1 ≤ d := by
    obtain ⟨i, hi⟩ := l.proper
    exact Finset.card_pos.2 ⟨i, by simp [hi]⟩
  have hval : ∀ i < k, C (1 + A + i * d) = c := by
    intro i hi
    have := hl ⟨i, hi⟩
    simp only at this
    rw [key] at this
    simpa [Nat.add_assoc] using this
  refine ⟨1 + A, d, by omega, hdpos, ?_, fun i hi => by rw [hval i hi, ← hval 0 hk]; simp⟩
  have h1 := key ⟨k - 1, by omega⟩
  have h2 : ∑ i, (l ⟨k - 1, by omega⟩ i).val ≤ ∑ _i : Fin n, (k - 1) :=
    Finset.sum_le_sum fun i _ => by have := (l ⟨k - 1, by omega⟩ i).isLt; omega
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, smul_eq_mul] at h2
  simp only at h1
  have h3 : (k - 1) * d + A ≤ n * (k - 1) := by rw [Nat.add_comm, ← h1]; exact h2
  omega

#print axioms svdw_vdw

/-- **Schur and van der Waerden.** Fix a finite number `r` of colours.
Schur: there is a run `1, …, N` such that every colouring of it holds a single-coloured sum
`x + y = z`, with `x = y` allowed.
Van der Waerden: for every length `k` there is a run `1, …, N` such that every colouring of it
holds a single-coloured progression `a, a + d, …, a + (k - 1) d` with gap `d ≥ 1`.
A colouring is a map `C : ℕ → Fin r`; only its values on `1, …, N` are used. -/
theorem schur_and_van_der_waerden (r : ℕ) :
    (∃ N : ℕ, ∀ C : ℕ → Fin r, ∃ x y z : ℕ,
        1 ≤ x ∧ 1 ≤ y ∧ x + y = z ∧ z ≤ N ∧ C x = C z ∧ C y = C z) ∧
    (∀ k : ℕ, ∃ N : ℕ, ∀ C : ℕ → Fin r, ∃ a d : ℕ,
        1 ≤ a ∧ 1 ≤ d ∧ a + (k - 1) * d ≤ N ∧ ∀ i < k, C (a + i * d) = C a) := by
  classical
  refine ⟨?_, svdw_vdw r⟩
  obtain ⟨N, hN⟩ := svdw_tri_ramsey (κ := Fin r) r
  refine ⟨N, fun C => ?_⟩
  obtain ⟨x, y, z, h1, h2, h3, h4, h5, h6⟩ := svdw_schur_from_triangles N (fun c => by
    obtain ⟨i, -, j, -, l, hl, hij, hjl, e1, e2⟩ := hN (Finset.range N) (by simp)
      Finset.univ (by simp) c (by simp)
    exact ⟨i, j, l, hij, hjl, Finset.mem_range.1 hl, e1, e2⟩) C
  exact ⟨x, y, z, h1, h2, h3, by omega, h5, h6⟩

/-- **Schur from triangles** (the card's `S(r) ≤ R_r(3) - 2`). If `M` points `0, …, M - 1` are
enough that every colouring of the links between them holds a single-coloured triangle, then
every colouring of `1, …, M - 1` holds a single-coloured sum `x + y = z`: colour the link
`i < j` by the colour of the gap `j - i`, and a triangle `i < j < l` gives
`(j - i) + (l - j) = l - i`. -/
theorem schur_from_triangles {κ : Type*} (M : ℕ)
    (hR : ∀ c : ℕ → ℕ → κ, ∃ i j l : ℕ,
        i < j ∧ j < l ∧ l < M ∧ c i j = c i l ∧ c j l = c i l) :
    ∀ C : ℕ → κ, ∃ x y z : ℕ,
        1 ≤ x ∧ 1 ≤ y ∧ x + y = z ∧ z ≤ M - 1 ∧ C x = C z ∧ C y = C z := by
  exact svdw_schur_from_triangles M hR

/-- **The Hales-Jewett theorem.** For any alphabet size `m` and any number of colours `r`, a
board `{0, …, m - 1}^n` of high enough dimension `n` forces a single-coloured Hales-Jewett
(combinatorial) line under every colouring of its cells. -/
theorem hales_jewett (m r : ℕ) :
    ∃ n : ℕ, ∀ C : (Fin n → Fin m) → Fin r,
      ∃ l : Combinatorics.Line (Fin m) (Fin n), l.IsMono C := by
  exact svdw_hales_jewett m r

/-! Worked examples from the card. In the `Fin` examples, index `i` stands for the number `i + 1`;
`true` is blue and `false` is red. -/

-- Schur dodge on 1 to 4: red 1, 4 and blue 2, 3 hold no single-coloured x + y = z.
example : ∀ x y : Fin 4, x.val + y.val + 1 < 4 →
    ¬ (![false, true, true, false] x = ![false, true, true, false] (x + y + 1) ∧
       ![false, true, true, false] y = ![false, true, true, false] (x + y + 1)) := by
  decide

-- Exactly 2 two-colourings of 1 to 4 dodge x + y = z.
example : (Finset.univ.filter (fun c : Fin 4 → Bool =>
    ∀ x y : Fin 4, x.val + y.val + 1 < 4 → ¬ (c x = c (x + y + 1) ∧ c y = c (x + y + 1)))).card = 2 := by
  decide

-- S(2) = 4: every two-colouring of 1 to 5 holds a single-coloured x + y = z.
example : ∀ c : Fin 5 → Bool, ∃ x y : Fin 5,
    x.val + y.val + 1 < 5 ∧ c x = c (x + y + 1) ∧ c y = c (x + y + 1) := by
  decide

-- Progression dodge on 1 to 8: red 1, 2, 5, 6 and blue 3, 4, 7, 8 hold no single-coloured a, a+d, a+2d.
example : ∀ a d : Fin 8, 0 < d.val → a.val + 2 * d.val < 8 →
    ¬ (![false, false, true, true, false, false, true, true] a =
         ![false, false, true, true, false, false, true, true] (a + d) ∧
       ![false, false, true, true, false, false, true, true] a =
         ![false, false, true, true, false, false, true, true] (a + d + d)) := by
  decide

-- Exactly 6 two-colourings of 1 to 8 dodge three-term progressions.
example : (Finset.univ.filter (fun c : Fin 8 → Bool =>
    ∀ a d : Fin 8, 0 < d.val → a.val + 2 * d.val < 8 → ¬ (c a = c (a + d) ∧ c a = c (a + d + d)))).card = 6 := by
  decide

-- W(3; 2) = 9: every two-colouring of 1 to 9 holds a single-coloured a, a+d, a+2d.
example : ∀ c : Fin 9 → Bool, ∃ a d : Fin 9,
    0 < d.val ∧ a.val + 2 * d.val < 9 ∧ c a = c (a + d) ∧ c a = c (a + d + d) := by
  decide +kernel

#print axioms schur_and_van_der_waerden
#print axioms schur_from_triangles
#print axioms hales_jewett
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'svdw_tri_ramsey' depends on axioms: [propext, Classical.choice, Quot.sound]
'svdw_schur_from_triangles' depends on axioms: [propext, Quot.sound]
'svdw_hales_jewett' depends on axioms: [propext, Classical.choice, Quot.sound]
'svdw_vdw' depends on axioms: [propext, Classical.choice, Quot.sound]
'schur_and_van_der_waerden' depends on axioms: [propext, Classical.choice, Quot.sound]
'schur_from_triangles' depends on axioms: [propext, Quot.sound]
'hales_jewett' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Three colours, progressions.** Add the line `print(last(grow(27, 3, ap(27))))` before the asserts. It prints 26, so $`W(3; 3) = 27`$.
> - **Odd red, even blue for Schur.** Set `col4` to `[0, 1, 0, 1]`. The first line reports 1 single-coloured sum: 2 + 2 = 4, all blue.
> - **Alternate the colours on 1 to 8.** Set `cv` to `[0, 1, 0, 1, 0, 1, 0, 1]`. Gap 2 keeps one colour, so 4 progressions are single-coloured and the second assert stops the run.
> - **Four dimensions.** Print `len(lines(4, 0))`: $`4^4 - 3^4`$ gives 175 Hales-Jewett lines.

---

## The usual mistake

> [!warning]
> **Expecting the pattern in a fixed colour.** The colouring chooses which colour holds it. Colour 1 to 9 all blue and red holds nothing.
>
> - **Forgetting that x may equal y.** Requiring different numbers stretches the 2-colour Schur dodge from 4 to 8.
> - **Taking the triangle ceiling as exact.** For 3 colours, R(3,3,3) − 2 = 15, but S(3) = 13.
> - **Counting every winning line as a Hales-Jewett line.** The 3 × 3 × 3 cube has 49 winning lines (0 dodges), but only 37 Hales-Jewett lines (1644 dodges).

---

## Where you meet it in real life

- **Additive combinatorics.** Asking which patterns survive any colouring grew into the study of patterns in dense sets and the primes.
- **Computer search.** Schur and van der Waerden numbers are standard hard tests for search programs; known values stop after a handful.
- **Games.** Hales and Jewett wrote about games like noughts and crosses. In enough dimensions a draw is impossible, so the first player can force a win.

> **Say it back**
> Colour 1 to N with a few colours; for N large enough one colour holds x + y = z, and one holds a progression of any chosen length. Schur's theorem follows from triangle Ramsey numbers: gaps between three points add up. With two colours, 1 to 4 dodges x + y = z and 1 to 5 cannot; 1 to 8 dodges three-term progressions and 1 to 9 cannot. Van der Waerden's theorem follows from Hales-Jewett on high-dimensional noughts and crosses, by adding each cell's digits.

---

## What this builds on

- [Friends and strangers](01-friends-and-strangers.md): $`R(3,3) = 6`$, the triangle fact behind Schur's theorem.
- [Ramsey numbers](02-ramsey-numbers.md): every Ramsey number is finite; a ceiling is not an exact value.
- [Pigeonhole, extended](../04-Inclusion-Exclusion%20and%20Pigeonhole/05-pigeonhole-extended.md): the principle van der Waerden's proof applies repeatedly.

## Where this goes next

- [Dilworth's theorem](../15-Orders%20and%20Set%20Systems/01-dilworths-theorem.md): the first card of the next shelf, turning from forced patterns in colourings to chains, antichains, and set systems.
- [Long progressions](../../21-Algebraic%20and%20analytic%20number%20theory/08-Additive%20Combinatorics%20and%20Probabilistic%20Number%20Theory/05-szemeredi-and-green-tao-in-outline.md): Szemerédi's density theorem and progressions in the primes.

$`W(3; 2) = 9`$ falls to a hand argument, while how fast $`W(k; 2)`$ grows with $`k`$ is far from settled. The next shelf moves from Ramsey patterns to partial orders and set systems, opening with Dilworth's theorem.

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Schur, I. "Über die Kongruenz x^m + y^m ≡ z^m (mod p)." *Jahresbericht der Deutschen Mathematiker-Vereinigung* 25 (1917): 114–116. [EuDML record](https://eudml.org/doc/145475). The original: Schur's theorem, proved on the way to a result on congruences.
- Hales, A. W., and R. I. Jewett. "Regularity and positional games." *Transactions of the American Mathematical Society* 106 (1963): 222–229. [doi:10.1090/S0002-9947-1963-0143712-1](https://doi.org/10.1090/S0002-9947-1963-0143712-1). The Hales-Jewett theorem, with van der Waerden as a corollary.
- Graham, R. L., B. L. Rothschild, and J. H. Spencer. *Ramsey Theory*, 2nd ed. Wiley, 1990. [Publisher page](https://www.wiley.com/en-us/Ramsey+Theory%2C+2nd+Edition-p-9780471500469). Schur, van der Waerden, Hales-Jewett and the Graham-Rothschild theorem in one place.
