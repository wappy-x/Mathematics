# Least common multiple: the first number both divide into, and why gcd times lcm equals the product

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Greatest Common Divisor and Euclid's Algorithm](../README.md#s02) → Least common multiple

---

## General Overview

A drum pattern 6 beats long, over a bass line 8 beats long. Both start on beat one. The drum comes round after 6 beats, the bass after 8, then they slide out of step.

Keep counting and they snap back. The drum comes round on beat 6, 12, 18, 24. The bass on 8, 16, 24. First number in both lists: 24. Four drum loops, three bass loops, back on beat one.

That 24 is the **least common multiple** of 6 and 8 — lcm(6, 8) for short. A multiple of a number is that number counted out whole times; a common multiple turns up in both counts; the least one is where the patterns meet. [Greatest common divisor](01-gcd.md) asked what goes into both; this asks what both go into.

**The first number both go into is the two numbers multiplied, divided by the biggest number that goes into both.**

### The picture: 24 beats

```
drum, every 6   .....D.....D.....D.....D
bass, every 8   .......B.......B.......B
both            .......................*
```

One column per beat, 24 of them. D is the drum coming round, B the bass. Only the last has both.

---

## The formula

On our two loops:

**lcm(6, 8) = 24, and gcd(6, 8) × lcm(6, 8) = 2 × 24 = 48 = 6 × 8**

**Read it aloud:** the first beat both patterns come round on is 24, and the biggest number going into both loops, times that beat, is 6 × 8.

Two ways to the 24. From the lists: write out the multiples of each, stop at the first shared one. From the primes, the numbers that break down no further ([Primes and composites](../01-Divisibility%20and%20Primes/05-primes-and-composites.md)): 6 = 2 × 3 and 8 = 2 × 2 × 2, so take each prime as often as the greedier wants it — three 2s and one 3, and 2 × 2 × 2 × 3 = 24.

| Piece | Plain meaning | In our beats |
| --- | --- | --- |
| a multiple | the number counted out whole times | 6, 12, 18, 24 |
| the least common multiple, lcm | the first number in both lists of multiples | 24 |
| the greatest common divisor, gcd | the biggest number going into both ([Greatest common divisor](01-gcd.md)) | 2 |
| the product | the two loop lengths multiplied | 48 |

---

## Why it works

### Step 0 — there is a first shared beat to find

Play the drum 8 times and the bass 6 times: both finish at beat 48, so shared beats exist. Any collection of counting numbers that is not empty has a smallest member ([Strong induction and the least element](../../01-Foundations/06-Proof/05-strong-induction-and-well-ordering.md)), and that smallest shared beat is the least common multiple.

### Step 1 — every shared beat is a multiple of the first one

Take any beat where both patterns come round. Divide it by 24 and keep the remainder ([Division with a remainder](../01-Divisibility%20and%20Primes/04-division-with-remainder.md)): a whole number of 24s, plus a remainder under 24.

Those 24s are a shared beat, and so is the beat you started with. Subtract, and the remainder is shared too — 6 goes into both, so 6 goes into their difference, and the same for 8. But a shared beat under 24 would have beaten 24 to the title, so the remainder is nothing. Shared beats are exactly 24, 48, and on up in 24s.

### Step 2 — why the gcd is exactly what to divide by

48 is a shared beat, so 24 goes into it: 48 ÷ 24 = 2. That 2 turns out to be the gcd. Here is why.

It goes into both loops: 48 is 6 × 8 and 24 is 6 × 4, so the 6s cancel and 48 ÷ 24 is 8 ÷ 4 = 2; the 8s cancel the same way, 6 ÷ 3 = 2.

Nothing bigger does. Take any number that goes into both, call it d, and divide 48 by it: the answer is 6 times (8 ÷ d), and 8 times (6 ÷ d), so it is a shared beat. Shared beats are 24 or more, so 48 ÷ d is 24 or more, so d is 2 or less.

So the biggest number into both, times the first number both go into, is the two multiplied — and nothing here was special to 6 and 8, or to any two counting numbers.

The prime route says it too: for each prime the lcm takes the most and the gcd the fewest, and most plus fewest is how many the two have between them ([Prime factorisation](../01-Divisibility%20and%20Primes/07-prime-factorisation.md)).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the drum's multiples | 6 × 1, 6 × 2, 6 × 3, 6 × 4 | 6, 12, 18, 24 |
| the bass's multiples | 8 × 1, 8 × 2, 8 × 3 | 8, 16, 24 |
| first beat in both | lcm(6, 8) | **24** |
| what goes into both | 1 and 2, so gcd(6, 8) | 2 |
| the short way | 6 × 8 = 48, then 48 ÷ 2 | **24** |

The patterns lock up every 24 beats — at 120 beats a minute, once every 12 seconds.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Multiplying, 6 × 8 | 48 | A shared beat, but the second one |
| Adding, 6 + 8 | 14 | Nothing comes round on 14 |
| Taking the longer loop | 8 | The drum is mid-pattern at beat 8 |

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one steps along the multiples of 6 until 8 goes into one too. Road two divides the product by the gcd. Road three builds it from prime pieces.

### Python

```python
# Least common multiple -- the check behind the card.  Nothing is imported.  A 6-beat drum
# pattern against an 8-beat bass line: the first beat they both come round on, three roads.
def walk_to_shared(a, b):           # road one: step along the multiples of a until b goes in too
    m = a
    while m % b != 0: m += a
    return m
def primes_of(n):                   # the prime pieces of n, smallest first: 8 -> 2, 2, 2
    out, d = [], 2
    while n > 1:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out
def most_of_each(a, b):             # road three: each prime, as often as the greedier of the two wants it
    pa, pb = primes_of(a), primes_of(b)
    return [p for p in sorted(set(pa + pb)) for _ in range(max(pa.count(p), pb.count(p)))]
def product(fs): return fs[0] * product(fs[1:]) if fs else 1
def show(fs, sep=" x "): return sep.join(str(f) for f in fs)
drum, bass = 6, 8
shared, g = walk_to_shared(drum, bass), max(d for d in range(1, drum + 1) if drum % d == 0 and bass % d == 0)
mult = most_of_each(drum, bass)
print(f"road one, step along the multiples -- drum comes round on {show(range(drum, shared + 1, drum), ', ')};  bass on {show(range(bass, shared + 1, bass), ', ')}")
print(f"the first beat in both lists is {shared}, and nothing under it is in both (checked 1 to {shared - 1})")
print(f"road two, the link -- gcd({drum}, {bass}) = {g}, product {drum} x {bass} = {drum * bass}, and {drum * bass} / {g} = {drum * bass // g}")
print(f"road three, from the primes -- {drum} = {show(primes_of(drum))}, {bass} = {show(primes_of(bass))}, most of each = {show(mult)} = {product(mult)}")
print(f"over {shared} beats the drum plays {shared // drum} loops and the bass {shared // bass};  at 120 beats a minute, {shared * 60 // 120} seconds")
print(f"the three mistakes come out at {drum * bass}, {drum + bass} and {bass}")
assert shared == 24 and shared % drum == 0 and shared % bass == 0
assert all(m % drum or m % bass for m in range(1, shared))
assert g * shared == drum * bass == 48 and product(mult) == shared
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
road one, step along the multiples -- drum comes round on 6, 12, 18, 24;  bass on 8, 16, 24
the first beat in both lists is 24, and nothing under it is in both (checked 1 to 23)
road two, the link -- gcd(6, 8) = 2, product 6 x 8 = 48, and 48 / 2 = 24
road three, from the primes -- 6 = 2 x 3, 8 = 2 x 2 x 2, most of each = 2 x 2 x 2 x 3 = 24
over 24 beats the drum plays 4 loops and the bass 3;  at 120 beats a minute, 12 seconds
the three mistakes come out at 48, 14 and 8
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Least common multiple -- the same check as the Python twin, in Rust.  No crates.  A 6-beat drum
// pattern against an 8-beat bass line: the first beat they both come round on, three roads.
fn walk_to_shared(a: i64, b: i64) -> i64 {   // road one: step along the multiples of a until b goes in too
    let mut m = a;
    while m % b != 0 { m += a; }
    m
}
fn primes_of(n: i64) -> Vec<i64> {           // the prime pieces of n, smallest first: 8 -> 2, 2, 2
    let (mut out, mut n, mut d) = (Vec::new(), n, 2);
    while n > 1 { while n % d == 0 { out.push(d); n /= d; } d += 1; }
    out
}
fn most_of_each(a: i64, b: i64) -> Vec<i64> {  // road three: each prime, as often as the greedier of the two wants it
    let (pa, pb) = (primes_of(a), primes_of(b));
    let count = |v: &Vec<i64>, p: i64| v.iter().filter(|&&q| q == p).count();
    let mut all = [pa.clone(), pb.clone()].concat(); all.sort(); all.dedup();
    let mut out = Vec::new();
    for p in all { for _ in 0..count(&pa, p).max(count(&pb, p)) { out.push(p); } }
    out
}
fn product(fs: &[i64]) -> i64 { fs.iter().product() }
fn show(fs: &[i64], sep: &str) -> String { fs.iter().map(|f| f.to_string()).collect::<Vec<String>>().join(sep) }
fn main() {
    let (drum, bass) = (6i64, 8i64);
    let (shared, mult) = (walk_to_shared(drum, bass), most_of_each(drum, bass));
    let g = (1..=drum).filter(|d| drum % d == 0 && bass % d == 0).max().unwrap();   // gcd, from the factor lists
    let (dl, bl): (Vec<i64>, Vec<i64>) = ((1..=shared / drum).map(|k| k * drum).collect(), (1..=shared / bass).map(|k| k * bass).collect());
    println!("road one, step along the multiples -- drum comes round on {};  bass on {}", show(&dl, ", "), show(&bl, ", "));
    println!("the first beat in both lists is {}, and nothing under it is in both (checked 1 to {})", shared, shared - 1);
    println!("road two, the link -- gcd({}, {}) = {}, product {} x {} = {}, and {} / {} = {}", drum, bass, g, drum, bass, drum * bass, drum * bass, g, drum * bass / g);
    println!("road three, from the primes -- {} = {}, {} = {}, most of each = {} = {}", drum, show(&primes_of(drum), " x "), bass, show(&primes_of(bass), " x "), show(&mult, " x "), product(&mult));
    println!("over {} beats the drum plays {} loops and the bass {};  at 120 beats a minute, {} seconds", shared, shared / drum, shared / bass, shared * 60 / 120);
    println!("the three mistakes come out at {}, {} and {}", drum * bass, drum + bass, bass);
    assert!(shared == 24 && shared % drum == 0 && shared % bass == 0);
    assert!((1..shared).all(|m| m % drum != 0 || m % bass != 0));
    assert!(g * shared == drum * bass && drum * bass == 48 && product(&mult) == shared);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
road one, step along the multiples -- drum comes round on 6, 12, 18, 24;  bass on 8, 16, 24
the first beat in both lists is 24, and nothing under it is in both (checked 1 to 23)
road two, the link -- gcd(6, 8) = 2, product 6 x 8 = 48, and 48 / 2 = 24
road three, from the primes -- 6 = 2 x 3, 8 = 2 x 2 x 2, most of each = 2 x 2 x 2 x 3 = 24
over 24 beats the drum plays 4 loops and the bass 3;  at 120 beats a minute, 12 seconds
the three mistakes come out at 48, 14 and 8
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to these loops, so expect one to fire.
> - **Loops that share nothing.** Set `bass` to 7. Nothing but 1 goes into both, so the first shared beat is the two multiplied.
> - **Loops that share more.** Set `drum` to 4. It goes into 8 exactly, so the first shared beat is 8 and the gcd is 4.

---

## The usual mistake

> [!warning]
> **Multiplying the two numbers and calling that the answer.** 6 × 8 = 48 is a beat both patterns come round on, so it looks right — but they met at 24 first. Multiplying gives the first meeting only when the two share nothing but 1; what they do share gets counted twice.
>
> - **Swapping the two words.** gcd(6, 8) is 2; lcm(6, 8) is 24. One goes into both; both go into the other.
> - **Adding the loops.** 6 + 8 is 14, and neither pattern comes round on 14.
> - **Expecting an answer bigger than the longer loop.** When the shorter loop goes into the longer exactly, the answer is just the longer one.

---

## Where you meet it in real life

- **Polyrhythms.** A 6 against an 8 is a pattern drummers play, and the bar it fits in is 24 beats long: [When cycles meet again](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/04-cycles-that-realign.md).
- **Common denominators.** Sixths and eighths get rewritten over 24 before adding.
- **Gears.** A 6-tooth wheel driving an 8-tooth wheel: the same two teeth meet after 24 teeth.

> **Say it back**
> Multiples of 6: 6, 12, 18, 24. Multiples of 8: 8, 16, 24. The first number in both lists is the least common multiple, 24, and every later shared number is a multiple of it. The short way: 6 × 8 = 48, then divide by the biggest number going into both, 48 ÷ 2 = 24.

---

## What this builds on

- [Multiplying and dividing](../../01-Foundations/01-Everyday%20Arithmetic/03-multiplying-and-dividing.md): multiples, and the division that undoes them.
- [Greatest common divisor](01-gcd.md): the biggest number going into both, the 2 this card divides by.

## Where this goes next

- [The Chinese remainder theorem](../03-Clock%20Arithmetic/06-chinese-remainder-theorem.md): which beat lands two patterns on any pair of positions you pick.
- [When cycles meet again](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/04-cycles-that-realign.md): cycles of different lengths meeting again, drawn as time.

---

## Sources

Verified 6 Sep 2026: every link below resolves to the publisher's page.

- Euclid. *Elements*, Book VII, Propositions 34 and 35, c. 300 BC. [D. E. Joyce's edition](https://mathcs.clarku.edu/~djoyce/elements/bookVII/propVII34.html). Step 1, 2,300 years old.
- Apostol, Tom M. *Introduction to Analytic Number Theory*. Springer, 1976. [doi:10.1007/978-1-4757-5579-4](https://doi.org/10.1007/978-1-4757-5579-4). Chapter 1, *The Fundamental Theorem of Arithmetic*, the modern statement of the link.
- Hammack, Richard. *Book of Proof*, 3rd ed., 2018. [Full text, free](https://richardhammack.github.io/BookOfProof/Main.pdf). The remainder and smallest-member arguments behind Steps 0 and 1.
