---
type: card
wing: 01-Foundations
shelf: Everyday Arithmetic
topic: Fractions, decimals and percentages
item: Fractions
kind: definition
status: verified
updated: 2026-09-06
needs_first:
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/03-multiplying-and-dividing|multiplying-and-dividing]]"
next:
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/08-decimals|decimals]]"
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/09-ratios-and-rates|ratios-and-rates]]"
tags:
  - mathematics
  - foundations
  - fractions
---

# Fractions: parts of a whole, and how to add, multiply and divide them

Foundations → Everyday Arithmetic → Fractions, decimals and percentages → Fractions

---

## General Overview

A pizza turns up cut into 8 slices. Three of you. You eat 3 slices. Your friend had "a quarter". The third is at the shop, asking what is left.

You know 3 slices of 8 is 3/8 of the pizza. What you cannot do in one move is add 3/8 and 1/4: different sized pieces.

Later, a recipe wants 3/4 cup of flour, you are making half a batch, and your only measure is a 1/8-cup scoop.

**A fraction is a division left standing: the top shared into the pieces the bottom names. Pieces only add when they are the same size; multiplying and dividing need no matching.**

### The picture: the pizza in eighths

```
one block per slice, eight slices in the whole box

the whole pizza  ████████ 8/8
you              ███      3/8
your friend      ██       2/8
together         █████    5/8
left in the box  ███      3/8
```

In eighths, the blocks stack.

---

## The formula

Nothing to memorise. Three worked statements:

**3/8 + 1/4 = 3/8 + 2/8 = 5/8** — three slices plus two is five of the eight.

**1/2 × 3/4 = 3/8** — half of three quarters of a cup is three eighths.

**3/8 ÷ 1/8 = 3/8 × 8/1 = 3/1** — three eighths of a cup holds three one-eighth scoops.

| Part | Plain meaning | In our example |
| --- | --- | --- |
| the bottom number (the denominator) | how many equal pieces the whole was cut into | 8 slices, 4 quarters in a cup |
| the top number (the numerator) | how many of those pieces you have | 3 slices, 3 quarter-cups |
| a common bottom (a common denominator) | one piece size both fractions fit | 1/4 becomes 2/8 |
| the flip (its reciprocal) | the fraction upside down | 1/8 flips to 8/1 |
| tidying up (simplifying, to lowest terms) | dividing top and bottom by what goes into both | 2/8 tidies to 1/4 |

---

## Why it works

### Step 0: a fraction is a division nobody finished

Share 8 slices between 3 people. From [multiplying-and-dividing](03-multiplying-and-dividing.md): 2 each, 2 over. Cut those two into thirds and everyone holds 2 slices and 2/3 of a slice.

Write that share in one mark: **8/3** — the pile on top, the number sharing underneath. The fraction is the division, parked rather than done. The bottom is never 0: you cannot cut a pizza into no pieces.

### Step 1: cut both amounts to one size, then add

Cut each quarter of the pizza in two and you have eighths: a quarter of 8 slices is 2 slices. Nothing was added or thrown out, so 1/4 and 2/8 are one amount spelt two ways. Multiplying top and bottom by the same number cuts finer; dividing both goes back. Dividing both is simplifying; this card calls it tidying.

That is what makes adding work. 3/8 and 1/4 will not add, the way three slices and two mouthfuls will not. Rewrite the quarter as 2/8 and both are in one unit: three plus two is five, 5/8. Multiplying the two bottoms always gives a size both fit into. Taking away works the same: match the bottoms, take the tops away. The whole pizza is 8/8, so 8/8 − 5/8 = 3/8.

### Step 2: multiplying is the word "of"

Half a batch of a 3/4-cup recipe means half **of** 3/4. Cut the cup into 4, take 3. Halve every quarter: the pieces are eighths, and your 3 are 3 eighths. Halving doubled the bottom and left the top alone. So 1/2 × 3/4 is 3/8 cup — tops times tops, bottoms times bottoms.

### Step 3: dividing asks how many fit

You have 3/8 cup of flour and a 1/8-cup scoop. How many scoops? Three. Nobody needs a rule for that.

Watch the rule do it. Dividing by 1/8 asks how many eighths there are, and each cup holds 8, so it is multiplying by 8: 3/8 × 8/1. The 8s cancel, leaving 3/1 — a top over one, which is 3.

Dividing by a fraction is multiplying by its flip. Dividing by 2/3 is dividing by 2 thirds: times 3 for the thirds, halved for the 2 — times 3/2. That is why dividing by something between 0 and 1 makes the answer bigger.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| your share | 3 of 8 slices | 3/8 |
| your friend's quarter | 1/4 in eighths | 2/8 |
| together | 3/8 + 2/8 | **5/8** |
| left in the box | 8/8 − 5/8 | **3/8** |
| half a batch of 3/4 cup | 1/2 × 3/4 | **3/8 cup** |
| in 1/8-cup scoops | 3/8 × 8/1 | **3/1, which is 3** |
| a fair share of the 8 | 8 shared by 3 | **8/3**, or 2 slices and 2/3 |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Adding tops and bottoms straight | 1/3 | 4/12 is less than the 3/8 you ate alone |
| Dividing without flipping the scoop | 3/64 | Shrinks the flour instead of counting scoops |
| Sharing 8 by 3, dropping the leftover | 2 | Two slices each, and two nobody eats |

---

## Code, from first principles, and it actually runs

Nothing is imported. A fraction is a top and a bottom, tidied by the biggest whole number dividing both. A second road checks it: the same pizza counted in whole eighths.

### Python

```python
# Fractions -- the check behind the card.  Nothing is imported.  A pizza cut into
# 8 slices for three people, and a recipe wanting 3/4 cup of flour when you make
# half a batch.  Second road: the same story counted in whole eighths of a pizza.
def hcf(a, b):                          # the biggest whole number dividing both
    return a if b == 0 else hcf(b, a % b)
def tidy(t, b):                         # 2/8 -> 1/4
    return (t // hcf(t, b), b // hcf(t, b))
def add(x, y):                          # a common bottom, add the tops, then tidy
    return tidy(x[0] * y[1] + y[0] * x[1], x[1] * y[1])
def times(x, y):                        # tops times tops, bottoms times bottoms
    return tidy(x[0] * y[0], x[1] * y[1])
def row(name, f):
    print(f"{name:<34}{f[0]:>3}/{f[1]}")
yours, friend, share = (3, 8), (1, 4), tidy(8, 3)
both, flour = add(yours, friend), times((1, 2), (3, 4))
left, scoops = add((1, 1), (-both[0], both[1])), times(flour, (8, 1))  # take away: add a minus top
row(f"you ate {yours[0]} of the 8 slices", yours)
row("your friend ate a quarter", (2, 8))
row("together", both)
row("left in the box", left)
row("half a batch of 3/4 cup, in cups", flour)
row("that flour in 1/8-cup scoops", scoops)
row("a fair share of the 8 slices", share)
print(f"a fair share is {share[0] // share[1]} slices and {share[0] % share[1]}/{share[1]} of a slice")
m1, m2 = tidy(3 + 1, 8 + 4), times(yours, (1, 8))
print(f"the three mistakes come out at {m1[0]}/{m1[1]}, {m2[0]}/{m2[1]} and {8 // 3}")
assert both == tidy(3 + 2, 8) and left == tidy(8 - 5, 8)
assert flour == tidy(6 // 2, 8) and share[0] == 2 * share[1] + 2
assert scoops == (3, 1) and times(scoops, (1, 8)) == flour
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
you ate 3 of the 8 slices           3/8
your friend ate a quarter           2/8
together                            5/8
left in the box                     3/8
half a batch of 3/4 cup, in cups    3/8
that flour in 1/8-cup scoops        3/1
a fair share of the 8 slices        8/3
a fair share is 2 slices and 2/3 of a slice
the three mistakes come out at 1/3, 3/64 and 2
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Fractions -- the same check as fractions_check.py, in Rust.  No crates.  A
// pizza cut into 8 slices for three people, and a recipe wanting 3/4 cup of
// flour when you make half a batch.  Second road: the story counted in eighths.
fn hcf(a: i64, b: i64) -> i64 { if b == 0 { a } else { hcf(b, a % b) } }

fn tidy(t: i64, b: i64) -> (i64, i64) { (t / hcf(t, b), b / hcf(t, b)) }  // 2/8 -> 1/4

fn add(x: (i64, i64), y: (i64, i64)) -> (i64, i64) {   // a common bottom, add the tops
    tidy(x.0 * y.1 + y.0 * x.1, x.1 * y.1)
}

fn times(x: (i64, i64), y: (i64, i64)) -> (i64, i64) { // tops times tops, bottoms times bottoms
    tidy(x.0 * y.0, x.1 * y.1)
}

fn row(name: &str, f: (i64, i64)) { println!("{:<34}{:>3}/{}", name, f.0, f.1); }

fn main() {
    let (yours, friend, share) = ((3i64, 8i64), (1i64, 4i64), tidy(8, 3));
    let (both, flour) = (add(yours, friend), times((1, 2), (3, 4)));
    let (left, scoops) = (add((1, 1), (-both.0, both.1)), times(flour, (8, 1))); // take away: add a minus top
    row(&format!("you ate {} of the 8 slices", yours.0), yours);
    row("your friend ate a quarter", (2, 8));
    row("together", both);
    row("left in the box", left);
    row("half a batch of 3/4 cup, in cups", flour);
    row("that flour in 1/8-cup scoops", scoops);
    row("a fair share of the 8 slices", share);
    println!("a fair share is {} slices and {}/{} of a slice",
             share.0 / share.1, share.0 % share.1, share.1);
    let (m1, m2) = (tidy(3 + 1, 8 + 4), times(yours, (1, 8)));
    println!("the three mistakes come out at {}/{}, {}/{} and {}",
             m1.0, m1.1, m2.0, m2.1, 8 / 3);
    assert!(both == tidy(3 + 2, 8) && left == tidy(8 - 5, 8));
    assert!(flour == tidy(6 / 2, 8) && share.0 == 2 * share.1 + 2);
    assert!(scoops == (3, 1) && times(scoops, (1, 8)) == flour);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
you ate 3 of the 8 slices           3/8
your friend ate a quarter           2/8
together                            5/8
left in the box                     3/8
half a batch of 3/4 cup, in cups    3/8
that flour in 1/8-cup scoops        3/1
a fair share of the 8 slices        8/3
a fair share is 2 slices and 2/3 of a slice
the three mistakes come out at 1/3, 3/64 and 2
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the house numbers, so one will fire.
> - **A third of a batch, not half.** The flour comes out at 1/4 cup, the scoops at 2/1, and the second assert fires.
> - **Eat one more slice.** Start with 4 of the 8: together is 3/4, and the first assert fires.

---

## The usual mistake

> [!warning]
> **Adding the tops and adding the bottoms.** 3/8 plus 1/4 is not 4/12. It cannot be: 4/12 tidies to 1/3, less than the 3/8 you ate alone, and adding pizza never shrinks the pile. Tops add only once the bottoms match.
>
> - **Reading a bigger bottom as a bigger number.** It means smaller pieces: 1/8 of a pizza is less than 1/4.
> - **Matching bottoms before multiplying.** Never needed: halving 3/4 straight off gives 3/8.
> - **Dividing without the flip.** 3/8 × 1/8 gives 3/64, a crumb, not 3 scoops.
> - **Leaving it untidy.** 2/8 is not wrong, just loud: 1/4.

---

## Where you meet it in real life

- **Cooking.** Half batches, double batches, a cup marked in quarters and thirds. Scaling a recipe: [ratios-and-rates](09-ratios-and-rates.md).
- **Money and time.** A quarter past, half an hour, half price — small bottoms, easy in your head.
- **Anything sold in a fixed cut.** Spanners in sixteenths of an inch, music in quarter and eighth notes.

> **Say it back**
> A fraction is a division left standing: the bottom counts the equal pieces the whole was cut into, the top counts how many you hold. Add, and take away, only over a common bottom. Multiply tops by tops and bottoms by bottoms. Divide by flipping the second one. Tidy by dividing both by what goes into both.

---

## What this builds on

- [multiplying-and-dividing](03-multiplying-and-dividing.md): sharing a pile that does not come out even. This card cuts the leftover up and names it.

## Where this goes next

- [decimals](08-decimals.md): fractions whose bottom is ten, a hundred, a thousand.
- [ratios-and-rates](09-ratios-and-rates.md): comparing two amounts and scaling both.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Wu, Hung-Hsi. *Understanding Numbers in Elementary School Mathematics*. American Mathematical Society, 2011. [Publisher page](https://bookstore.ams.org/mbk-79/). Why the rules are what they are.
- Lamon, Susan J. *Teaching Fractions and Ratios for Understanding*, 4th ed. Routledge, 2020. [Publisher page](https://www.routledge.com/Teaching-Fractions-and-Ratios-for-Understanding-Essential-Content-Knowledge-and-Instructional-Strategies-for-Teachers/Lamon/p/book/9781138536777). Where the usual mistakes come from.
- O'Connor, J. J. and Robertson, E. F. "Ahmes". MacTutor History of Mathematics Archive, University of St Andrews. [Article](https://mathshistory.st-andrews.ac.uk/Biographies/Ahmes/). Scribe of the Rhind papyrus: loaves shared out.
