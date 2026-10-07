# Even and odd: the two-way split, and what adding and multiplying do to it

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Divisibility and Primes](../README.md#s01) → Even and odd

---

## General Overview

The hallway light was off on Monday. By Sunday the switch had been flipped 37 times. Nobody watched. Is the light on or off?

You do not need to replay the week. One fact about 37 does it: it is odd. Flips cancel in pairs — on, off, back where you started. Pair the 37 up: 18 pairs and one flip over. The pairs change nothing; the leftover turns the light on.

Every whole number is one of two kinds. **Even**: it pairs off with nothing left over. **Odd**: one is always left over. That kind is the number's **parity**.

**Parity is predictable under adding and multiplying: you can tell whether an answer is even or odd from the numbers going in, without doing the sum.**

### The picture: the whole parity table

| Two numbers | Added, they give | Multiplied, they give |
| --- | --- | --- |
| even and even | even | even |
| even and odd | odd | even |
| odd and odd | **even** | **odd** |

The bottom row is where people slip: odd plus odd is even, odd times odd is odd.

---

## The formula

The week, written out. Eleven trips down the hall, three flips a trip — on, off, on, hunting for keys — then four more from your housemate.

**11 × 3 = 33, and odd × odd = odd**

**33 + 4 = 37, and odd + even = odd**

37 is odd, so the light is on.

Pairing off:

**37 = 18 × 2 + 1** — eighteen pairs and one over: odd.

**38 = 19 × 2** — nineteen pairs, nothing over: even.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| even | pairs off with nothing over; 2 divides it ([Divides](01-divides.md)) | 4, 30, 38, and 0 |
| odd | pairs off with exactly one over | 3, 11, 33, 37 |
| parity | which of the two a number is | 37 has odd parity |
| a flip | one press of the switch | 37 of them all week |

---

## Why it works

### Pairs are the whole idea

Line a count up in twos. Four flips: two pairs, nothing over — even. Three flips: one pair, one over — odd. There is no third outcome. No flips at all is even too: no pairs, nothing over.

A pair of flips puts the switch back where it was, so pairs never matter to the light. Only the leftover does.

### Adding: only the leftovers meet

Put two counts together and the pairs from each sit alongside, still pairs. Only the leftovers are loose.

Two odd counts bring one leftover each, those two make a pair, and nothing is over: the total is even. 33 + 5 = 38, which is 19 pairs.

One odd and one even bring a single leftover, which has nothing to pair with. The total is odd: 33 + 4 = 37.

### Multiplying: peel one group off

11 × 3 is eleven threes. Take one three away and ten threes are left: 10 × 3 = 30. An even number of groups always pairs off, two at a time, so 30 is even. Put the peeled-off three back: even plus odd is odd. So 33 is odd.

That runs for any two odds: an odd count of groups is an even count plus one, the even part totals even, the last group is odd. One even factor anywhere: the groups pair off, or each group pairs off inside itself.

---

## Worked numbers, by hand

The switch, off on Monday.

| Step | Arithmetic | Value |
| --- | --- | --- |
| eleven trips, three flips each | 11 × 3 | 33 |
| the housemate's flips | — | 4 |
| all the flips | 33 + 4 | 37 |
| paired off, the check | 18 × 2 + 1 | **37** |
| the light, from off | odd count, so it changed | **on** |
| had the housemate flipped 5 | 33 + 5 | 38 |
| paired off, the check | 19 × 2 | 38 |
| the light, from off | even count, so it did not | off |

The light is on, and nobody watched.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Using the adding rule on 11 × 3 | 33 called even | odd plus odd is even, odd times odd is odd |
| Calling 33 + 5 odd, since both are odd | 38 called odd | the two leftovers pair off |
| Forgetting the light started off | on at 38 flips | parity gives the change, not the state |

The code prints the right answer to all three.

---

## Code, from first principles, and it actually runs

Each count is read by pairing off, then checked the slow way: a switch flipped one press at a time.

### Python

```python
# Even and odd -- the check behind the card.  Nothing is imported.  The hallway switch:
# eleven trips, three flips each, plus four.  Counts paired off, then flipped one by one.
def parity(n):                     # n // 2 is whole-number division: the number of pairs
    return "even" if n - 2 * (n // 2) == 0 else "odd"   # the leftover is 0 or 1

def flip(n):                       # the switch starts off; flip it n times
    on = False
    for _ in range(n): on = not on
    return "on" if on else "off"

def row(label, work, value):
    print(f"{label:<30}{work:>16}   {parity(value)}")

trips, each, extra, instead = 11, 3, 4, 5
mine = trips * each
total, other = mine + extra, mine + instead
row("eleven trips, three flips each", f"{trips} x {each} = {mine}", mine)
row("the housemate's flips", f"{extra}", extra)
row("all the flips", f"{mine} + {extra} = {total}", total)
row("paired off", f"{total // 2} x 2{' + 1' if parity(total) == 'odd' else ''} = {total}", total)
print(f"{f'starts off, {total} flips':<30}{flip(total):>16}")
row("had the housemate flipped 5", f"{mine} + {instead} = {other}", other)
row("paired off", f"{other // 2} x 2{' + 1' if parity(other) == 'odd' else ''} = {other}", other)
print(f"{f'starts off, {other} flips':<30}{flip(other):>16}")
row("peel one trip off the eleven", f"{trips - 1} x {each} = {mine - each}", mine - each)
row("nobody touches it", "0", 0)
assert flip(total) == "on" and parity(total) == "odd" and total == 2 * (total // 2) + 1
assert flip(other) == "off" and parity(other) == "even" and other == 2 * (other // 2)
assert mine == (trips - 1) * each + each and parity(mine - each) == "even"
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
eleven trips, three flips each     11 x 3 = 33   odd
the housemate's flips                        4   even
all the flips                      33 + 4 = 37   odd
paired off                     18 x 2 + 1 = 37   odd
starts off, 37 flips                        on
had the housemate flipped 5        33 + 5 = 38   even
paired off                         19 x 2 = 38   even
starts off, 38 flips                       off
peel one trip off the eleven       10 x 3 = 30   even
nobody touches it                            0   even
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Even and odd -- the same check as even_and_odd_check.py, in Rust.  No crates.  The
// hallway switch: eleven trips, three flips each, plus four.  Paired off, then flipped.
fn parity(n: i64) -> &'static str {    // n / 2 is whole-number division: the number of pairs
    if n - 2 * (n / 2) == 0 { "even" } else { "odd" }   // the leftover is 0 or 1
}

fn flip(n: i64) -> &'static str {      // the switch starts off; flip it n times
    let mut on = false;
    for _ in 0..n { on = !on; }
    if on { "on" } else { "off" }
}

fn row(label: &str, work: String, value: i64) {
    println!("{:<30}{:>16}   {}", label, work, parity(value));
}

fn main() {
    let (trips, each, extra, instead) = (11i64, 3i64, 4i64, 5i64);
    let mine = trips * each;
    let (total, other, peeled) = (mine + extra, mine + instead, mine - each);
    row("eleven trips, three flips each", format!("{} x {} = {}", trips, each, mine), mine);
    row("the housemate's flips", format!("{}", extra), extra);
    row("all the flips", format!("{} + {} = {}", mine, extra, total), total);
    let over = if parity(total) == "odd" { " + 1" } else { "" };
    row("paired off", format!("{} x 2{} = {}", total / 2, over, total), total);
    println!("{:<30}{:>16}", format!("starts off, {} flips", total), flip(total));
    row("had the housemate flipped 5", format!("{} + {} = {}", mine, instead, other), other);
    let over = if parity(other) == "odd" { " + 1" } else { "" };
    row("paired off", format!("{} x 2{} = {}", other / 2, over, other), other);
    println!("{:<30}{:>16}", format!("starts off, {} flips", other), flip(other));
    row("peel one trip off the eleven", format!("{} x {} = {}", trips - 1, each, peeled), peeled);
    row("nobody touches it", "0".to_string(), 0);
    assert!(flip(total) == "on" && parity(total) == "odd" && total == 2 * (total / 2) + 1);
    assert!(flip(other) == "off" && parity(other) == "even" && other == 2 * (other / 2));
    assert!(mine == (trips - 1) * each + each && parity(peeled) == "even");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
eleven trips, three flips each     11 x 3 = 33   odd
the housemate's flips                        4   even
all the flips                      33 + 4 = 37   odd
paired off                     18 x 2 + 1 = 37   odd
starts off, 37 flips                        on
had the housemate flipped 5        33 + 5 = 38   even
paired off                         19 x 2 = 38   even
starts off, 38 flips                       off
peel one trip off the eleven       10 x 3 = 30   even
nobody touches it                            0   even
ALL CHECKS PASS
```

The two outputs match line for line: whole counts, nothing to round.

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to these numbers, so expect one to fire.
> - **Give the housemate one more flip.** Set `extra` to 5: the total is 38, even, light off.
> - **Make the trips even.** Set `trips` to 10: ten threes pair off, so your own flips change nothing and the light ends off.

---

## The usual mistake

> [!warning]
> **Reading odd plus odd as odd.** Two odd counts add to an even one: each brings a leftover, and the two pair. 33 + 5 = 38. Odd times odd stays odd: 11 × 3 = 33.
>
> - Calling 0 odd. Zero pairs off with nothing left over, so it is even, and nobody touching the switch leaves the light as it was.
> - Calling -3 even. Negatives split the same way: -4 is even, -3 is odd.
> - Reading the count's parity as the light's state. 37 flips says the light changed; it says on only because it started off.
> - Expecting a row for dividing. There is none: two evens can divide to an odd. See [Division with a remainder](04-division-with-remainder.md).

---

## Where you meet it in real life

- **Anything that toggles.** A light switch, a door bolt. Count the presses; the parity gives the state, however long ago you stopped watching.
- **Splitting a group in two.** An odd headcount will not split into two equal halves; one person is left over. Same fact as 2 not dividing it: [Divides](01-divides.md).
- **Ruling a claim out.** Someone says three odd numbers add to an even total. Say no without hearing them: two odds make an even, and that even plus the third odd is odd. It narrows down [Pythagorean triples](../07-For%20the%20Curious/01-pythagorean-triples.md) later.

> **Say it back**
> Every whole number pairs off cleanly or with one left over. Clean is even, one over is odd: that is its parity. Adding, only the leftovers matter, so odd plus odd is even and odd plus even is odd. Multiplying, one even factor pairs everything off, so only odd times odd stays odd. The switch was flipped 37 times, 37 is odd, the light is on.

---

## What this builds on

- [Adding and subtracting](../../01-Foundations/01-Everyday%20Arithmetic/02-adding-and-subtracting.md): putting counts together, the adding half of the table.
- [Multiplying and dividing](../../01-Foundations/01-Everyday%20Arithmetic/03-multiplying-and-dividing.md): groups of equal size, like eleven trips of three flips.
- [Divides](01-divides.md): going in with nothing left over. Even is that word with a 2 in it.

## Where this goes next

- [Pythagorean triples](../07-For%20the%20Curious/01-pythagorean-triples.md): parity rules out shapes of triple that cannot exist, before the hunt starts.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Hammack, Richard. *Book of Proof*, 3rd ed. [Author's site](https://richardhammack.github.io/BookOfProof/), free [full text](https://richardhammack.github.io/BookOfProof/Main.pdf), CC BY-NC-ND. Chapter 4: even and odd, the first claim a proof is tried on.
- Euclid, *Elements*, Book IX, propositions 21 to 34, in David E. Joyce's edition. [Clark University](https://mathcs.clarku.edu/~djoyce/elements/bookIX/bookIX.html). This card's table, proposition by proposition, from about 300 BC.
- Graham, Ronald L., Donald E. Knuth and Oren Patashnik. *Concrete Mathematics*, 2nd ed. Addison-Wesley, 1994. [Publisher page](https://www.informit.com/store/concrete-mathematics-a-foundation-for-computer-science-9780201558029). Chapter 4, parity as the first case of divisibility.
