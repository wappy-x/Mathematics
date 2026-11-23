# Incompressibility: almost every file is its own shortest description

[Syllabus](../../../SYLLABUS.md) → [Computability and complexity](../README.md) → [Computability and Logic](../README.md#s02) → Incompressibility

---

## General Overview

A text file of 16,291 bytes goes into a zip-style coder (LZ78, written out in the checks) and comes out as 6,932 bytes. That is 0.4255 of its size. The coder found the repeats in the text and replaced them with short pointers.

Zip the zipped file again, and it grows to 8,214 bytes. A third pass gives 9,758. The coder is the same program each time. Something about its own output leaves it nothing to find.

This card explains why, and the reason is a count. A **description** of a file is a shorter string from which a fixed program, the **decompressor**, prints the file. The decompressor is a program that reads programs: each description is a small program it runs. Short descriptions are scarce. There are fewer bit strings of length below $`n - c`$ than files of length $`n`$, by a factor of more than $`2^c`$. So fewer than one file in $`2^c`$ can shrink by more than $`c`$ bits, whatever the coder.

A good coder removes the patterns that coders look for. Here LZ78 removes the repeats and leaves only a small skew in the byte counts, so its output looks almost like a typical file of its length to any coder of that kind. The count says almost no typical file can shrink.

The same count gives a definition. A file is **random** when no description is much shorter than the file itself. Almost every file is random in this sense. A random file passes every statistical test a program can run, provided the test flags only a tiny share of files: a share below $`2^{-r}`$, where $`r`$ beats the file's allowed saving $`c`$ plus the bits needed to write down the test and the file's length.

**Fewer than $`2^{n-c}`$ descriptions are shorter than $`n - c`$ bits, so fewer than one file in $`2^c`$ of length $`n`$ can be compressed by more than $`c`$ bits; a file that cannot be compressed is called random, and a good coder's output already looks random to coders of its kind, so a second pass gains almost nothing.**

**What kind of fact this is:** a theorem and a definition. The counting bound and the bound on a second pass are proved on this card in Why it works. That incompressible infinite sequences are exactly the ones random in Martin-Löf's sense is a theorem (Levin and Schnorr) stated with its source. The zip sizes are measurements of one written-out coder on one synthetic text.

### The picture: one text, zipped three times

```
text    ████████████████████████████████  16291 bytes
zip 1   ██████████████                     6932 bytes
zip 2   ████████████████                   8214 bytes
zip 3   ███████████████████                9758 bytes
```

Each bar is the file's size, drawn to scale. The first pass removes the repeats. Every later pass makes the file larger.

---

## The formula

Notation first, in words. A file is a bit string $`x`$ of length $`n`$, written $`\lvert x \rvert = n`$. $`\{0,1\}^n`$ is the set of all $`2^n`$ such strings. As on [Kolmogorov complexity](05-kolmogorov-complexity.md), $`U`$ is the universal machine (the program that reads another program and runs it), and $`K(x)`$ is the length in bits of the shortest program that makes $`U`$ print $`x`$ and halt. $`\#\{\dots\}`$ means "the number of strings in this set".

```math
\#\{\, x \in \{0,1\}^n : K(x) < n - c \,\} \;\le\; 2^{n-c} - 1 \;<\; 2^{-c} \cdot 2^n
```

**Read it aloud:** the files of length n that have a program shorter than n minus c bits number at most two to the n minus c, minus one, which is less than a share one over two to the c of all files of that length.

The definition the count supports:

```math
x \text{ is } c\text{-incompressible} \iff K(x) \ge \lvert x \rvert - c
```

**Read it aloud:** a file is incompressible with slack c when its shortest program is no more than c bits shorter than the file.

A **random** string of length $`n`$ is one that is $`c`$-incompressible for a small $`c`$ fixed in advance. By the first formula, at least $`2^n - 2^{n-c} + 1`$ strings of each length qualify.

The bound on a second pass. Let a first coder turn $`x`$ into $`z`$, and let its decompressor be a program of $`c_D`$ bits. If the first coder wastes $`w`$ bits, so that $`\lvert z \rvert \le K(x) + w`$, then:

```math
K(z) \;\ge\; K(x) - c_D \;\ge\; \lvert z \rvert - w - c_D
```

**Read it aloud:** the zipped file's shortest program is at least the original's minus the decompressor's length, so the zipped file is incompressible with slack w plus c D.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`x`$, $`n = \lvert x \rvert`$ | a file as a bit string; its length in bits | the 16-bit files; zip 1 at 55,456 bits | twice as many files for each extra bit |
| $`\{0,1\}^n`$, $`\#\{\dots\}`$ | all bit strings of length $`n`$; the number of strings in a set | 65,536 strings for $`n = 16`$; at most 255 files with $`K < 8`$ | — |
| $`d`$, $`D`$ | a description; a decompressor: a fixed program that reads a description and prints a file | `1 01 01` prints 0101010101010101 on the card's tiny $`D`$; LZ78's unpacker | — |
| $`p`$ | the period the card's tiny $`D`$ repeats | 1, 2, 4 or 8 bits | each description costs more bits but reaches more files |
| $`U`$, $`K(x)`$ | the universal machine; the shortest program length for $`x`$ on it | only bounded above, by named programs | — |
| $`c`$ | the slack: a file that saves more than $`c`$ bits counts as compressed; [Kolmogorov complexity](05-kolmogorov-complexity.md) calls this $`k`$ and keeps $`c`$ for a fixed constant | 1, 2, 4, 8 | the share that can shrink falls by half per bit |
| $`L`$, $`m`$ | a string's length; the length limit in the count | $`2^L`$ strings of length $`L`$; $`m = n - c = 8`$ gives 255 shorter strings | each extra bit doubles the count |
| $`z`$ | the zipped file | zip 1, 6,932 bytes | — |
| $`c_D`$, $`w`$ | the unpacker's own length in bits; the bits the first coder wastes | $`c_D`$ is fixed; $`w`$ is large here, since a short generator made the text | more slack, so a second pass could gain more |
| $`k`$, $`\binom{n}{k}`$, $`t`$ | the number of 1s; the number of strings with $`k`$ ones; the distance of $`k`$ from $`n/2`$ | 300 ones, about $`2^{876.1076}`$ strings; $`t = 100`$ | further from $`n/2`$ means fewer strings and a shorter description |
| $`S`$, $`F`$ | in the proof, the files that save more than $`c`$ bits; a consistent formal system, as on [Godel's theorems](03-godels-incompleteness-in-outline.md) | at most 255 files in $`S`$ for $`n = 16`$, $`c = 8`$ | — |
| $`T`$, $`A_n`$, $`c_T`$, $`r`$ | a test: a program that lists a set $`A_n`$ of at most $`2^{n-r}`$ suspicious strings; its length in bits; how rare the flagged strings are | the balance test: 1000-bit strings with at most 400 or at least 600 ones, $`r`$ about 31.77 | a stricter test, which a random string passes |

### When it holds

- **The decompressor is fixed before the file is seen.** A decompressor with one file built in prints it from 1 bit. The count still holds, because every other description grows by a bit. $`K`$ fixes $`U`$ once, and the [Kolmogorov complexity](05-kolmogorov-complexity.md) card shows that changing $`U`$ moves $`K`$ by at most a constant.
- **The coding is lossless (one-to-one).** A "coder" that keeps the first 8 bits of a 16-bit file shrinks every file. But 256 files share each output, so nothing can unpack it.
- **The first coder already took the patterns the second one looks for.** The proved bound uses $`\lvert z \rvert \le K(x) + w`$ with small $`w`$. A weak first coder, such as one that only counts bytes, leaves repeats behind, and a second coder of another kind can still gain.
- **The count is over all files of one length.** It says nothing about a particular file. Text, photos and spreadsheets are a tiny, patterned corner of all files, which is why coders work on them.
- **Random means relative to all programs, not to one test.** A file can pass a balance test and still compress: 0101010101010101 has eight 1s and a 5-bit description.

---

## Why it works

### Step 0: descriptions are files too, and short ones are scarce

A description is itself a bit string. A decompressor reads it and prints one file, so each description serves at most one file. To shrink many files, a coder needs many short strings, and there are only so many.

[Pigeonhole](../../01-Foundations/08-Relations%20and%20Functions/08-pigeonhole-principle.md) already shows the blunt form: no coder shrinks every file, since shorter outputs are fewer than inputs. This card sharpens that into a share. It asks how many files can save more than $`c`$ bits.

### Step 1: count the short strings

Each extra bit doubles the number of strings, by the rule of product ([The rules of sum and product](../../04-Combinatorics%20and%20graphs/01-Counting%20Principles/01-rules-of-sum-and-product.md)). So there are $`2^L`$ strings of length exactly $`L`$. Lengths do not overlap, so by the rule of sum the strings shorter than $`m`$ number:

```math
2^0 + 2^1 + \dots + 2^{m-1} = 2^m - 1
```

**Read it aloud:** one empty string, two of length one, four of length two, and so on up to length m minus one, add up to two to the m, minus one.

Put $`m = n - c`$. At most $`2^{n-c} - 1`$ files of length $`n`$ have a description shorter than $`n - c`$ bits. Divide by the $`2^n`$ files:

| Slack $`c`$ | Descriptions shorter than $`16 - c`$ bits | 16-bit files that need $`16 - c`$ bits or more |
| ---: | ---: | ---: |
| 1 | 32,767 | at least 32,769 (50.0015%) |
| 2 | 16,383 | at least 49,153 (75.0015%) |
| 4 | 4,095 | at least 61,441 (93.7515%) |
| 8 | 255 | at least 65,281 (99.6109%) |

The count never used how the decompressor works. It holds for $`U`$, for LZ78, and for every coder anyone will ever write.

<details>
<summary>Detailed proof: fewer than one file in 2^c saves more than c bits</summary>

Fix any decompressor $`D`$: a partial function from bit strings to bit strings. Let $`S`$ be the set of files $`x`$ of length $`n`$ that have some description $`d`$ with $`D(d) = x`$ and $`\lvert d \rvert < n - c`$.

For each $`x`$ in $`S`$, pick its shortest such $`d`$. Different files get different descriptions, because $`D`$ prints one output for each input. So this choice is a one-to-one map from $`S`$ into the strings shorter than $`n - c`$.

There are $`2^{n-c} - 1`$ of those strings (Step 1). A one-to-one map cannot land more items than there are places, so:

$`\displaystyle \#S \le 2^{n-c} - 1 < 2^{n-c} = 2^{-c} \cdot 2^n.`$

Taking $`D = U`$ gives the formula. Taking $`c = 0`$ gives at least one file of every length with $`K(x) \ge n`$.

</details>

### Step 2: the tiny decompressor D, on every 16-bit file

The bound is a ceiling. A real decompressor reaches far fewer files. The card's $`D`$ reads two kinds of description:

1. `0` and then the 16 bits of the file: 17 bits, written out.
2. `1`, two bits choosing a period $`p`$ of 1, 2, 4 or 8, then $`p`$ bits of pattern. $`D`$ repeats the pattern to fill 16 bits. That costs 4, 5, 7 or 11 bits.

The checks run $`D`$ on every string up to 17 bits and keep each file's shortest description.

| Shortest description | Files |
| ---: | ---: |
| 4 bits | 2 |
| 5 bits | 2 |
| 7 bits | 12 |
| 11 bits | 240 |
| 17 bits | 65,280 |

Only 256 files, a share of 0.003906, shrink at all. Each count sits under its bound: 256 files below 15 bits against 32,767 allowed, 16 below 8 bits against 255. The file 0110100110010110 has no pattern $`D`$ can see and costs 17 bits.

### Step 3: define random by incompressibility

Step 1 says most files have no short description on any machine. Kolmogorov and Chaitin turned that into a definition. A string is **random** when it is $`c`$-incompressible for a small fixed $`c`$: no program is much shorter than the string itself.

Two facts make this a fair definition.

1. **Almost every string is random.** With $`c = 8`$, more than 99.6% of strings of every length qualify.
2. **No program can certify one.** $`K`$ is not computable ([Kolmogorov complexity](05-kolmogorov-complexity.md)). Chaitin showed more: a consistent formal system $`F`$, whose axioms a program can list, can prove "$`K(x) > L`$" only for $`L`$ below a constant that depends on $`F`$ (Li and Vitányi give the proof; [Godel's theorems](03-godels-incompleteness-in-outline.md) gives $`F`$, proofs and consistency). Random strings are everywhere, yet past a fixed length none can be proved random.

A compressor's output only bounds $`K`$ from above. So code can show that a file is **not** random, by printing a short description. It can never show that a file is.

For infinite sequences the definition needs care. Martin-Löf (1966) defined a random sequence as one that passes every effective statistical test. Levin and Schnorr proved, as a theorem stated here with its source (Li and Vitányi), that this matches incompressibility of every prefix, once $`K`$ is measured with prefix-free programs (programs whose ends need no marker, since no program is the start of another).

### Step 4: a random string passes every test that flags a small enough share, shown on the balance test

A **test** picks out a small set of strings that look suspicious. Any set that a program can list gives each member a short description: the test's program, plus the member's position in the list. So a small listable set holds only compressible strings, and incompressible strings pass the test.

The balance test shows the mechanism with numbers. Take strings of $`n = 1000`$ bits. A decompressor built for that length reads $`k`$, the count of 1s, in 10 bits, then the position of the string among the $`\binom{1000}{k}`$ strings with $`k`$ ones.

| Ones $`k`$ | $`\log_2 \binom{1000}{k}`$ | Description, bits | Saved |
| ---: | ---: | ---: | ---: |
| 500 | 994.6910 | 1,005 | −5 |
| 450 | 987.4727 | 998 | 2 |
| 400 | 965.6710 | 976 | 24 |
| 300 | 876.1076 | 887 | 113 |
| 100 | 464.4227 | 475 | 525 |

On this decompressor a string with 300 ones saves 113 bits, so it is not 8-incompressible there. Fewer ones means fewer such strings, so every string with at most 400 ones, or by symmetry at least 600, gets a description of at most 976 bits and saves at least 24. On this decompressor, every 8-incompressible string of 1000 bits has between 401 and 599 ones. On $`U`$, add this decompressor's own length to each description.

The strings with at most 400 or at least 600 ones are a share $`2^{-31.77}`$ of all. Hoeffding's inequality ([Concentration](../../09-Probability%20and%20statistics/06-Limit%20Theorems%20in%20Practice/06-concentration-inequalities-hoeffding-and-chernoff.md)), with $`t = 100`$, bounds that share by $`2e^{-2t^2/n} = 2^{-27.85}`$, where $`e`$ is the base of natural logarithms. The checks compute the exact share from whole binomial numbers and confirm it sits below the bound.

<details>
<summary>Detailed proof: a listable set of at most 2^(n-r) strings holds only compressible strings</summary>

Let $`T`$ be a program that, given $`n`$, lists a set $`A_n`$ of at most $`2^{n-r}`$ strings of length $`n`$. For $`x`$ in $`A_n`$, describe $`x`$ by three parts: $`T`$ itself, $`n`$, and the position of $`x`$ in $`T`$'s list.

The position needs $`n - r`$ bits. $`T`$ is a constant $`c_T`$ bits. The length $`n`$ costs about $`2\log_2 n`$ bits in a self-delimiting form, which marks its own end. So:

$`\displaystyle K(x) \le n - r + 2\log_2 n + c_T.`$

If $`x`$ is $`c`$-incompressible, then $`n - c \le K(x)`$, which forces $`r \le c + 2\log_2 n + c_T`$. So a test that flags a share $`2^{-r}`$ with larger $`r`$ cannot flag $`x`$. The overhead grows only like $`\log_2 n`$, while a fixed statistical test, such as the balance test with $`t`$ a tenth of $`n`$, flags a share that shrinks exponentially in $`n`$. For long strings such a test misses every string that is incompressible with small slack.

</details>

### Step 5: why a zipped file will not zip again

[Arithmetic and Lempel-Ziv coding](../../14-Applied%20and%20computational/03-Information%20Theory/06-arithmetic-and-lempel-ziv-coding.md) shows how a zip-style coder works: LZ78 replaces each new phrase with a pointer to an earlier phrase plus one new symbol. The checks write it out over bytes.

The zipped file $`z`$ is a description of the text $`x`$. The unpacker is a fixed program of $`c_D`$ bits. Run any program that prints $`z`$, then run the unpacker on its output, and $`x`$ comes out. That gives $`K(x) \le K(z) + c_D`$, which is the first half of the formula.

If the first coder were the best possible, $`\lvert z \rvert`$ would be close to $`K(x)`$, within a small waste $`w`$. Then $`K(z) \ge \lvert z \rvert - w - c_D`$. The zipped file is incompressible up to the first coder's waste plus a constant. A second pass can win back only what the first pass left behind.

Real coders are not the best possible in this sense. This text came from a short program. Written out in Python with the 32-word list, SplitMix64 and seed 2026, it is 328 bytes and prints the whole text. So $`K(x)`$, measured in Python text at 8 bits a byte as on [Kolmogorov complexity](05-kolmogorov-complexity.md), is at most 2,624 bits, far below zip 1's 55,456, and $`w`$ is large. But that shortcut is the generator itself, and no practical coder searches for it. A practical second coder looks for repeats and skewed byte counts. The first pass removed the repeats and left only a small byte skew.

The count then limits any second coder chosen in advance. Zip 1 is 55,456 bits. Among all files of that length, a share below $`2^{-8}`$ can lose more than 8 bits, and a share below $`2^{-5545}`$ can lose 10%.

| Input | Size, bytes | After LZ78, bytes | Change |
| --- | ---: | ---: | ---: |
| text | 16,291 | 6,932 | −9,359 |
| zip 1 | 6,932 | 8,214 | +1,282 |
| zip 2 | 8,214 | 9,758 | +1,544 |
| coin bytes from SplitMix64 | 6,932 | 8,354 | +1,422 |

Zip 1 behaves almost like coin bytes. Its byte frequencies are nearly flat: 7.7798 bits of entropy per byte (the average surprise per byte, counting each byte by its own frequency), against 3.8028 for the text and 7.9726 for coin bytes. A coder using byte frequencies alone could bring zip 1 to about 0.9725 of its size. That small gap is the waste a byte-counting coder could see. LZ78 cannot take it, because the file has no long repeats left, and its pointers cost more than the bytes they replace.

---

## Worked numbers, by hand

The zipped text, and what any second coder could hope for.

| Step | Arithmetic | Value |
| --- | --- | --- |
| zip 1 in bits | 6,932 × 8 | 55,456 |
| files of that length | $`2^{55456}`$ | — |
| descriptions shorter than 55,456 − 8 bits | $`2^0 + \dots + 2^{55456-9}`$ | $`2^{55456-8} - 1`$ |
| share that can save more than 8 bits | $`(2^{55456-8} - 1) / 2^{55456}`$ | below $`2^{-8}`$ = 0.00390625 |
| share that can save 10% | 55,456 / 10, rounded down: 5,545 bits | below $`2^{-5545}`$ |
| zip 1's flatness | 7.7798 / 8 bits per byte | about 0.9725 |
| what LZ78 actually does | 8,214 − 6,932 | **+1,282 bytes** |

The second pass makes the file 1,282 bytes larger. The count leaves almost no room for any coder to do much better, and this coder does worse.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| A "coder" that keeps the first 8 bits of a 16-bit file | every file 8 bits, but 256 files share each output | not one-to-one, so nothing can unpack it |
| Building the file 0110100110010110 into the decompressor | that file costs 1 bit; 0101010101010101 rises from 5 to 6; 257 files below 15 bits, still under 32,767 | the cost moved; the count did not |
| Calling 0101010101010101 random because it has eight 1s | its description is 5 bits, not 17 | one test is not all programs |
| Zipping the zipped file | 6,932 bytes grow to 8,214 | the first pass already took the patterns |

The code prints all four.

---

## Code, from first principles, and it actually runs

The code imports nothing that compresses. It takes four roads to the same claim. The count of short strings comes from a sum and from the closed form $`2^m - 1`$. The tiny decompressor $`D`$ runs on every description up to 17 bits, and each count of shrinking files is checked against the bound, and the number of files at each description length against a count of files by their repeat period. LZ78, written out, zips a text three times and zips coin bytes from SplitMix64 (seed 2026), and every zipped file unpacks to its input. The balance test compares $`\log_2 \binom{1000}{k}`$ from a sum of logs against exact binomial numbers, and its exact tail against Hoeffding's bound.

### Python

```python
# Incompressibility and randomness -- the check behind the card.  Standard library
# only: no zlib, lzma or random.  Four roads: count descriptions by a sum and by a
# closed form; run a tiny decompressor D on every 16-bit file; zip a text twice with
# LZ78, written out below (the Lempel-Ziv card explains it); price lopsided strings.
from math import log2, e, ceil
MASK = (1 << 64) - 1

class SplitMix64:                        # small seeded generator, written out
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

def lz78_pack(data):                     # bytes in, bytes out: 32-bit length, then (index, byte) pairs
    bits, book, w, i = [], {b"": 0}, b"", 1
    put = lambda v, k: bits.extend((v >> (k - 1 - j)) & 1 for j in range(k))
    put(len(data), 32)
    for b in data:
        wb = w + bytes([b])
        if wb in book:
            w = wb
            continue
        put(book[w], (i - 1).bit_length()); put(b, 8)
        book[wb], w, i = i, b"", i + 1
    if w:
        put(book[w], (i - 1).bit_length())
    bits += [0] * (-len(bits) % 8)
    return bytes(sum(bits[k + j] << (7 - j) for j in range(8)) for k in range(0, len(bits), 8))

def lz78_unpack(blob):                   # the decompressor: a program that reads the packed file
    pos = 0
    def get(k):
        nonlocal pos
        v = 0
        for _ in range(k):
            v = (v << 1) | ((blob[pos >> 3] >> (7 - (pos & 7))) & 1); pos += 1
        return v
    n, book, out, i = get(32), [b""], bytearray(), 1
    while len(out) < n:
        w = book[get((i - 1).bit_length())]
        if len(out) + len(w) == n: out += w; break
        w += bytes([get(8)]); out += w; book.append(w); i += 1
    return bytes(out)

def byte_entropy(data):                  # bits per byte if each byte were coded by its own frequency
    f = [0] * 256
    for b in data: f[b] += 1
    return -sum(c / len(data) * log2(c / len(data)) for c in f if c)

# ---- road 1: count the short descriptions ----
n = 16
print(f"files of {n} bits: 2^{n} = {1 << n}")
for c in (1, 2, 4, 8):
    short = sum(1 << L for L in range(n - c))      # every bit string of length 0 .. n-c-1
    print(f"c = {c}: descriptions shorter than {n - c} bits: {short} = 2^{n - c} - 1; at least {(1 << n) - short} files ({100 * (1 - short / (1 << n)):.4f}%) need {n - c} bits or more")
    assert short == (1 << (n - c)) - 1             # the sum against the closed form
print(f"a file of 1048576 bytes is {8 * 1048576} bits; shrink by more than 8 bits: fewer than 1 file in 2^8 = 256, share < {1 / 256:.8f}; shrink by 1%: share < 2^-{8 * 1048576 // 100}")

# ---- road 2: a tiny decompressor D, run on every description up to 17 bits ----
def D(desc, L):                          # reads a description of L bits; prints a 16-bit file
    if L == 17 and desc >> 16 == 0:      # 0 then 16 bits: the file written out
        return desc
    if L >= 4 and desc >> (L - 1) == 1:  # 1, two bits for period p in (1, 2, 4, 8), then p bits
        p = 1 << ((desc >> (L - 3)) & 3)
        if L == 3 + p:
            pat = desc & ((1 << p) - 1)
            return sum(pat << (p * j) for j in range(16 // p))
    return None                          # not a valid description: D prints nothing
def shortest(dec, top):                  # run dec on every description up to top bits; keep the shortest
    best = {}
    for L in range(top + 1):
        for desc in range(1 << L):
            x = dec(desc, L)
            if x is not None and x not in best:
                best[x] = L              # L rises, so the first hit is the shortest
    return best
best = shortest(D, 17)
hist = sorted((L, list(best.values()).count(L)) for L in set(best.values()))
print(f"D: every one of {len(best)} files gets a description; shortest lengths in bits: {hist}")
assert hist == [(3 + p, 2 ** p - (2 ** (p // 2) if p > 1 else 0)) for p in (1, 2, 4, 8)] + [(17, 2 ** n - 2 ** 8)]  # files by period
for c in (1, 5, 8, 12):
    k = sum(1 for L in best.values() if L < n - c)
    print(f"D: files with a description shorter than {n - c} bits: {k}, bound 2^{n - c} - 1 = {(1 << (n - c)) - 1}")
    assert k <= (1 << (n - c)) - 1                   # brute force under the count
print(f"D: share of 16-bit files that shrink at all: {sum(1 for L in best.values() if L < 16) / (1 << 16):.6f}")
x0 = 0b0110100110010110
print(f"D: file 0101010101010101 (eight 1s, balanced) has shortest description {best[0x5555]} bits; file 0110100110010110 has {best[x0]}")
def D2(desc, L):                         # D with file x0 built in: '1' prints x0, '0' + d runs D on d
    if L == 1:
        return x0 if desc == 1 else None
    return D(desc, L - 1) if L >= 2 and desc >> (L - 1) == 0 else None
best2 = shortest(D2, 18)
k2 = sum(1 for L in best2.values() if L < 15)
print(f"mistake, file built into the decompressor: x0 now {best2[x0]} bit, 0101010101010101 now {best2[0x5555]}; shorter than 15 bits: {k2}, bound 32767")
assert k2 <= (1 << 15) - 1 and best2[0x5555] == best[0x5555] + 1
keep8 = [0] * 256
for x in range(1 << 16): keep8[x >> 8] += 1   # a 'compressor' that keeps the first 8 bits
print(f"mistake, keep the first 8 bits: every file shrinks to 8 bits, {sum(1 for v in keep8 if v)} outputs, {min(keep8)} files share each")

# ---- road 3: zip a text, then zip the zipped file ----
WORDS = ("the a of to and in is it that for on was with as at by this from or be "
         "we file data zip code bit byte short long once again table").split()
rng = SplitMix64(2026)
text = " ".join(WORDS[rng.next() % len(WORDS)] for _ in range(4000)).encode()
print(f"text: 4000 words drawn from {len(WORDS)} by SplitMix64 seed 2026, starting '{text[:40].decode()}'")
GEN = (f'w="{" ".join(WORDS)}".split()\ns=2026;M=2**64-1;t=[]\nfor _ in range(4000):s=s+0x9E3779B97F4A7C15&M;'
       'z=(s^s>>30)*0xBF58476D1CE4E5B9&M;z=(z^z>>27)*0x94D049BB133111EB&M;t.append(w[(z^z>>31)%32])\nprint(" ".join(t),end="")\n')
print(f"named program for the text: {len(GEN)} bytes of Python (word list, SplitMix64, seed 2026), so K(text) <= {8 * len(GEN)} bits")
z1 = lz78_pack(text); z2 = lz78_pack(z1); z3 = lz78_pack(z2)
noise = bytes(rng.next() & 255 for _ in range(len(z1))); zn = lz78_pack(noise)
for name, a, b in (("text -> zip 1", text, z1), ("zip 1 -> zip 2", z1, z2), ("zip 2 -> zip 3", z2, z3), ("coin bytes -> zip", noise, zn)):
    print(f"{name}: {len(a)} bytes -> {len(b)} bytes, change {len(b) - len(a)}, ratio {len(b) / len(a):.4f}")
b1 = 8 * len(z1)
print(f"zip 1 is {b1} bits; any second coder shrinks it by more than 8 bits for a share < 2^-8 of files that size, by 10% for < 2^-{b1 // 10}")
print(f"byte entropy: text {byte_entropy(text):.4f}, zip 1 {byte_entropy(z1):.4f}, zip 2 {byte_entropy(z2):.4f}, coin bytes {byte_entropy(noise):.4f} bits per byte")
print(f"a coder using byte frequencies alone could bring zip 1 to about {byte_entropy(z1) / 8:.4f} of its size")
ok = lz78_unpack(z1) == text and lz78_unpack(lz78_unpack(z2)) == text and lz78_unpack(zn) == noise
print(f"every zip unpacks to its input exactly: {'yes' if ok else 'no'}")
assert ok                                          # lossless: the zipped file is a description
assert len(z1) < len(text) // 2 and len(z2) > len(z1) and len(zn) > len(noise)

# ---- road 4: a lopsided string is compressible, so a random one is balanced ----
N = 1000
def log2_choose(n, k):                   # log2 of n choose k, as a sum of logs
    return sum(log2((n - j) / (j + 1)) for j in range(k))
exact = [1]
for k in range(N):
    exact.append(exact[-1] * (N - k) // (k + 1))   # n choose k by whole numbers
for k in (500, 450, 400, 300, 100):
    cost = 10 + ceil(log2_choose(N, k))
    print(f"{N} bits with {k} ones: count in 10 bits, then which one of 2^{log2_choose(N, k):.4f} such strings: {cost} bits, saves {N - cost}")
    assert abs(log2_choose(N, k) - log2(exact[k])) < 1e-9   # sum of logs against whole numbers
tail = 2 * sum(exact[:401])
hoeff = 1 - 2 * 100 ** 2 / N * log2(e)            # log2 of 2 exp(-2 t^2 / n), t = 100
print(f"strings of {N} bits with at most 400 or at least 600 ones: share 2^{log2(tail) - N:.2f}; Hoeffding bound 2^{hoeff:.2f}")
assert log2(tail) - N < hoeff                      # exact count under an independent bound
print("ALL CHECKS PASS")
```

**Ran 2026-11-19 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
files of 16 bits: 2^16 = 65536
c = 1: descriptions shorter than 15 bits: 32767 = 2^15 - 1; at least 32769 files (50.0015%) need 15 bits or more
c = 2: descriptions shorter than 14 bits: 16383 = 2^14 - 1; at least 49153 files (75.0015%) need 14 bits or more
c = 4: descriptions shorter than 12 bits: 4095 = 2^12 - 1; at least 61441 files (93.7515%) need 12 bits or more
c = 8: descriptions shorter than 8 bits: 255 = 2^8 - 1; at least 65281 files (99.6109%) need 8 bits or more
a file of 1048576 bytes is 8388608 bits; shrink by more than 8 bits: fewer than 1 file in 2^8 = 256, share < 0.00390625; shrink by 1%: share < 2^-83886
D: every one of 65536 files gets a description; shortest lengths in bits: [(4, 2), (5, 2), (7, 12), (11, 240), (17, 65280)]
D: files with a description shorter than 15 bits: 256, bound 2^15 - 1 = 32767
D: files with a description shorter than 11 bits: 16, bound 2^11 - 1 = 2047
D: files with a description shorter than 8 bits: 16, bound 2^8 - 1 = 255
D: files with a description shorter than 4 bits: 0, bound 2^4 - 1 = 15
D: share of 16-bit files that shrink at all: 0.003906
D: file 0101010101010101 (eight 1s, balanced) has shortest description 5 bits; file 0110100110010110 has 17
mistake, file built into the decompressor: x0 now 1 bit, 0101010101010101 now 6; shorter than 15 bits: 257, bound 32767
mistake, keep the first 8 bits: every file shrinks to 8 bits, 256 outputs, 256 files share each
text: 4000 words drawn from 32 by SplitMix64 seed 2026, starting 'to once at or for to at as we of as the '
named program for the text: 328 bytes of Python (word list, SplitMix64, seed 2026), so K(text) <= 2624 bits
text -> zip 1: 16291 bytes -> 6932 bytes, change -9359, ratio 0.4255
zip 1 -> zip 2: 6932 bytes -> 8214 bytes, change 1282, ratio 1.1849
zip 2 -> zip 3: 8214 bytes -> 9758 bytes, change 1544, ratio 1.1880
coin bytes -> zip: 6932 bytes -> 8354 bytes, change 1422, ratio 1.2051
zip 1 is 55456 bits; any second coder shrinks it by more than 8 bits for a share < 2^-8 of files that size, by 10% for < 2^-5545
byte entropy: text 3.8028, zip 1 7.7798, zip 2 7.7087, coin bytes 7.9726 bits per byte
a coder using byte frequencies alone could bring zip 1 to about 0.9725 of its size
every zip unpacks to its input exactly: yes
1000 bits with 500 ones: count in 10 bits, then which one of 2^994.6910 such strings: 1005 bits, saves -5
1000 bits with 450 ones: count in 10 bits, then which one of 2^987.4727 such strings: 998 bits, saves 2
1000 bits with 400 ones: count in 10 bits, then which one of 2^965.6710 such strings: 976 bits, saves 24
1000 bits with 300 ones: count in 10 bits, then which one of 2^876.1076 such strings: 887 bits, saves 113
1000 bits with 100 ones: count in 10 bits, then which one of 2^464.4227 such strings: 475 bits, saves 525
strings of 1000 bits with at most 400 or at least 600 ones: share 2^-31.77; Hoeffding bound 2^-27.85
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`. The binomials come from Pascal's triangle in floating point, since Rust's standard library has no big integers.

```rust
// Incompressibility and randomness -- the same check as the Python, in Rust.  No
// crates.  Four roads: count descriptions by a sum and by a closed form; run a tiny
// decompressor D on every 16-bit file; zip a text twice with LZ78, written out below
// (the Lempel-Ziv card explains it); price lopsided strings.
use std::collections::HashMap;

struct SplitMix64 { s: u64 }                       // small seeded generator, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn blen(v: usize) -> usize { (usize::BITS - v.leading_zeros()) as usize }

fn lz78_pack(data: &[u8]) -> Vec<u8> {             // 32-bit length, then (index, byte) pairs
    let mut bits: Vec<u8> = Vec::new();
    let put = |bits: &mut Vec<u8>, v: usize, k: usize| for j in 0..k { bits.push(((v >> (k - 1 - j)) & 1) as u8) };
    let mut book: HashMap<Vec<u8>, usize> = HashMap::new();
    book.insert(Vec::new(), 0);
    let (mut w, mut i): (Vec<u8>, usize) = (Vec::new(), 1);
    put(&mut bits, data.len(), 32);
    for &b in data {
        let mut wb = w.clone();
        wb.push(b);
        if book.contains_key(&wb) { w = wb; continue; }
        put(&mut bits, book[&w], blen(i - 1));
        put(&mut bits, b as usize, 8);
        book.insert(wb, i);
        w.clear();
        i += 1;
    }
    if !w.is_empty() { put(&mut bits, book[&w], blen(i - 1)); }
    while bits.len() % 8 != 0 { bits.push(0); }
    bits.chunks(8).map(|c| c.iter().fold(0u8, |a, &b| (a << 1) | b)).collect()
}

fn lz78_unpack(blob: &[u8]) -> Vec<u8> {           // the decompressor: a program that reads the packed file
    let mut pos = 0usize;
    let mut get = |k: usize| { let mut v = 0usize; for _ in 0..k {
        v = (v << 1) | ((blob[pos >> 3] >> (7 - (pos & 7))) & 1) as usize; pos += 1; } v };
    let n = get(32);
    let (mut book, mut out, mut i): (Vec<Vec<u8>>, Vec<u8>, usize) = (vec![Vec::new()], Vec::new(), 1);
    while out.len() < n {
        let mut w = book[get(blen(i - 1))].clone();
        if out.len() + w.len() == n { out.extend(&w); break; }
        w.push(get(8) as u8);
        out.extend(&w);
        book.push(w);
        i += 1;
    }
    out
}

fn byte_entropy(data: &[u8]) -> f64 {              // bits per byte if each byte were coded by its own frequency
    let mut f = [0usize; 256];
    for &b in data { f[b as usize] += 1; }
    let n = data.len() as f64;
    -f.iter().filter(|&&c| c > 0).map(|&c| c as f64 / n * (c as f64 / n).log2()).sum::<f64>()
}

fn d(desc: u64, l: u32) -> Option<u64> {           // reads a description of l bits; prints a 16-bit file
    if l == 17 && desc >> 16 == 0 { return Some(desc); }             // 0 then 16 bits: the file written out
    if l >= 4 && desc >> (l - 1) == 1 {                               // 1, two bits for period p, then p bits
        let p = 1u32 << ((desc >> (l - 3)) & 3);
        if l == 3 + p {
            let pat = desc & ((1u64 << p) - 1);
            return Some((0..16 / p).map(|j| pat << (p * j)).sum());
        }
    }
    None                                                              // not a valid description
}

const X0: u64 = 0b0110100110010110;
fn d2(desc: u64, l: u32) -> Option<u64> {          // D with file x0 built in: '1' prints x0, '0' + d runs D
    if l == 1 { return if desc == 1 { Some(X0) } else { None }; }
    if l >= 2 && desc >> (l - 1) == 0 { d(desc, l - 1) } else { None }
}

fn shortest(dec: fn(u64, u32) -> Option<u64>, top: u32) -> Vec<u32> {   // shortest description of each file
    let mut best = vec![u32::MAX; 1 << 16];
    for l in 0..=top { for desc in 0..(1u64 << l) {
        if let Some(x) = dec(desc, l) { if best[x as usize] == u32::MAX { best[x as usize] = l; } }
    } }
    best
}

fn main() {
    let n = 16u32;
    println!("files of {} bits: 2^{} = {}", n, n, 1u64 << n);
    for c in [1u32, 2, 4, 8] {
        let short: u64 = (0..n - c).map(|l| 1u64 << l).sum();
        println!("c = {}: descriptions shorter than {} bits: {} = 2^{} - 1; at least {} files ({:.4}%) need {} bits or more",
            c, n - c, short, n - c, (1u64 << n) - short, 100.0 * (1.0 - short as f64 / (1u64 << n) as f64), n - c);
        assert!(short == (1u64 << (n - c)) - 1);                     // the sum against the closed form
    }
    let m = 8 * 1048576u64;
    println!("a file of 1048576 bytes is {} bits; shrink by more than 8 bits: fewer than 1 file in 2^8 = 256, share < {:.8}; shrink by 1%: share < 2^-{}", m, 1.0 / 256.0, m / 100);
    let best = shortest(d, 17);
    let mut hist: Vec<(u32, usize)> = Vec::new();
    for l in 0..=17u32 { let k = best.iter().filter(|&&b| b == l).count(); if k > 0 { hist.push((l, k)); } }
    println!("D: every one of {} files gets a description; shortest lengths in bits: {:?}", best.iter().filter(|&&b| b != u32::MAX).count(), hist);
    let want: Vec<(u32, usize)> = [1u32, 2, 4, 8].iter().map(|&p| (3 + p, (1usize << p) - (if p > 1 { 1usize << (p / 2) } else { 0 })))
        .chain([(17, (1usize << n) - (1 << 8))]).collect();
    assert!(hist == want);                                           // files by period
    for c in [1u32, 5, 8, 12] {
        let k = best.iter().filter(|&&b| b < n - c).count();
        println!("D: files with a description shorter than {} bits: {}, bound 2^{} - 1 = {}", n - c, k, n - c, (1usize << (n - c)) - 1);
        assert!(k <= (1usize << (n - c)) - 1);                      // brute force under the count
    }
    println!("D: share of 16-bit files that shrink at all: {:.6}", best.iter().filter(|&&b| b < 16).count() as f64 / 65536.0);
    println!("D: file 0101010101010101 (eight 1s, balanced) has shortest description {} bits; file 0110100110010110 has {}", best[0x5555], best[X0 as usize]);
    let best2 = shortest(d2, 18);
    let k2 = best2.iter().filter(|&&b| b < 15).count();
    println!("mistake, file built into the decompressor: x0 now {} bit, 0101010101010101 now {}; shorter than 15 bits: {}, bound 32767", best2[X0 as usize], best2[0x5555], k2);
    assert!(k2 <= (1 << 15) - 1 && best2[0x5555] == best[0x5555] + 1);
    let mut keep8 = [0usize; 256];
    for x in 0..(1usize << 16) { keep8[x >> 8] += 1; }               // a 'compressor' that keeps the first 8 bits
    println!("mistake, keep the first 8 bits: every file shrinks to 8 bits, {} outputs, {} files share each", keep8.iter().filter(|&&v| v > 0).count(), keep8.iter().min().unwrap());

    let words: Vec<&str> = "the a of to and in is it that for on was with as at by this from or be we file data zip code bit byte short long once again table".split(' ').collect();
    let mut rng = SplitMix64 { s: 2026 };
    let text: Vec<u8> = (0..4000).map(|_| words[(rng.next() % words.len() as u64) as usize]).collect::<Vec<_>>().join(" ").into_bytes();
    println!("text: 4000 words drawn from {} by SplitMix64 seed 2026, starting '{}'", words.len(), String::from_utf8_lossy(&text[..40]));
    let gen = format!("w=\"{}\".split()\ns=2026;M=2**64-1;t=[]\nfor _ in range(4000):s=s+0x9E3779B97F4A7C15&M;z=(s^s>>30)*0xBF58476D1CE4E5B9&M;z=(z^z>>27)*0x94D049BB133111EB&M;t.append(w[(z^z>>31)%32])\nprint(\" \".join(t),end=\"\")\n", words.join(" "));
    println!("named program for the text: {} bytes of Python (word list, SplitMix64, seed 2026), so K(text) <= {} bits", gen.len(), 8 * gen.len());
    let (z1, z2, z3) = { let a = lz78_pack(&text); let b = lz78_pack(&a); let c = lz78_pack(&b); (a, b, c) };
    let noise: Vec<u8> = (0..z1.len()).map(|_| (rng.next() & 255) as u8).collect();
    let zn = lz78_pack(&noise);
    for (name, a, b) in [("text -> zip 1", &text, &z1), ("zip 1 -> zip 2", &z1, &z2), ("zip 2 -> zip 3", &z2, &z3), ("coin bytes -> zip", &noise, &zn)] {
        println!("{}: {} bytes -> {} bytes, change {}, ratio {:.4}", name, a.len(), b.len(), b.len() as i64 - a.len() as i64, b.len() as f64 / a.len() as f64);
    }
    let b1 = 8 * z1.len();
    println!("zip 1 is {} bits; any second coder shrinks it by more than 8 bits for a share < 2^-8 of files that size, by 10% for < 2^-{}", b1, b1 / 10);
    println!("byte entropy: text {:.4}, zip 1 {:.4}, zip 2 {:.4}, coin bytes {:.4} bits per byte", byte_entropy(&text), byte_entropy(&z1), byte_entropy(&z2), byte_entropy(&noise));
    println!("a coder using byte frequencies alone could bring zip 1 to about {:.4} of its size", byte_entropy(&z1) / 8.0);
    let ok = lz78_unpack(&z1) == text && lz78_unpack(&lz78_unpack(&z2)) == text && lz78_unpack(&zn) == noise;
    println!("every zip unpacks to its input exactly: {}", if ok { "yes" } else { "no" });
    assert!(ok);                                                     // lossless: the zipped file is a description
    assert!(z1.len() < text.len() / 2 && z2.len() > z1.len() && zn.len() > noise.len());

    let big_n = 1000usize;
    let log2_choose = |k: usize| (0..k).map(|j| ((big_n - j) as f64 / (j + 1) as f64).log2()).sum::<f64>();
    let mut row = vec![0.0f64; big_n + 1];                          // n choose k by Pascal's triangle
    row[0] = 1.0;
    for r in 1..=big_n { for k in (1..=r).rev() { row[k] += row[k - 1]; } }
    for k in [500usize, 450, 400, 300, 100] {
        let cost = 10 + log2_choose(k).ceil() as i64;
        println!("{} bits with {} ones: count in 10 bits, then which one of 2^{:.4} such strings: {} bits, saves {}", big_n, k, log2_choose(k), cost, big_n as i64 - cost);
        assert!((log2_choose(k) - row[k].log2()).abs() < 1e-9);     // sum of logs against Pascal's triangle
    }
    let tail: f64 = 2.0 * row[..=400].iter().sum::<f64>();
    let hoeff = 1.0 - 2.0 * 100.0f64.powi(2) / big_n as f64 * std::f64::consts::E.log2();
    println!("strings of {} bits with at most 400 or at least 600 ones: share 2^{:.2}; Hoeffding bound 2^{:.2}", big_n, tail.log2() - big_n as f64, hoeff);
    assert!(tail.log2() - (big_n as f64) < hoeff);                  // exact count under an independent bound
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
files of 16 bits: 2^16 = 65536
c = 1: descriptions shorter than 15 bits: 32767 = 2^15 - 1; at least 32769 files (50.0015%) need 15 bits or more
c = 2: descriptions shorter than 14 bits: 16383 = 2^14 - 1; at least 49153 files (75.0015%) need 14 bits or more
c = 4: descriptions shorter than 12 bits: 4095 = 2^12 - 1; at least 61441 files (93.7515%) need 12 bits or more
c = 8: descriptions shorter than 8 bits: 255 = 2^8 - 1; at least 65281 files (99.6109%) need 8 bits or more
a file of 1048576 bytes is 8388608 bits; shrink by more than 8 bits: fewer than 1 file in 2^8 = 256, share < 0.00390625; shrink by 1%: share < 2^-83886
D: every one of 65536 files gets a description; shortest lengths in bits: [(4, 2), (5, 2), (7, 12), (11, 240), (17, 65280)]
D: files with a description shorter than 15 bits: 256, bound 2^15 - 1 = 32767
D: files with a description shorter than 11 bits: 16, bound 2^11 - 1 = 2047
D: files with a description shorter than 8 bits: 16, bound 2^8 - 1 = 255
D: files with a description shorter than 4 bits: 0, bound 2^4 - 1 = 15
D: share of 16-bit files that shrink at all: 0.003906
D: file 0101010101010101 (eight 1s, balanced) has shortest description 5 bits; file 0110100110010110 has 17
mistake, file built into the decompressor: x0 now 1 bit, 0101010101010101 now 6; shorter than 15 bits: 257, bound 32767
mistake, keep the first 8 bits: every file shrinks to 8 bits, 256 outputs, 256 files share each
text: 4000 words drawn from 32 by SplitMix64 seed 2026, starting 'to once at or for to at as we of as the '
named program for the text: 328 bytes of Python (word list, SplitMix64, seed 2026), so K(text) <= 2624 bits
text -> zip 1: 16291 bytes -> 6932 bytes, change -9359, ratio 0.4255
zip 1 -> zip 2: 6932 bytes -> 8214 bytes, change 1282, ratio 1.1849
zip 2 -> zip 3: 8214 bytes -> 9758 bytes, change 1544, ratio 1.1880
coin bytes -> zip: 6932 bytes -> 8354 bytes, change 1422, ratio 1.2051
zip 1 is 55456 bits; any second coder shrinks it by more than 8 bits for a share < 2^-8 of files that size, by 10% for < 2^-5545
byte entropy: text 3.8028, zip 1 7.7798, zip 2 7.7087, coin bytes 7.9726 bits per byte
a coder using byte frequencies alone could bring zip 1 to about 0.9725 of its size
every zip unpacks to its input exactly: yes
1000 bits with 500 ones: count in 10 bits, then which one of 2^994.6910 such strings: 1005 bits, saves -5
1000 bits with 450 ones: count in 10 bits, then which one of 2^987.4727 such strings: 998 bits, saves 2
1000 bits with 400 ones: count in 10 bits, then which one of 2^965.6710 such strings: 976 bits, saves 24
1000 bits with 300 ones: count in 10 bits, then which one of 2^876.1076 such strings: 887 bits, saves 113
1000 bits with 100 ones: count in 10 bits, then which one of 2^464.4227 such strings: 475 bits, saves 525
strings of 1000 bits with at most 400 or at least 600 ones: share 2^-31.77; Hoeffding bound 2^-27.85
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the counting bound for every decompressor $`D`$ and every $`n`$ and $`c`$, and checks the card's worked numbers.

- Take any decompressor $`D`$ and any $`n`$ and $`c`$. Then at most $`2^{n-c} - 1`$ files of length $`n`$ have a description shorter than $`n - c`$ bits.
- Take the same $`D`$, $`n`$ and $`c`$. Then at least $`2^n - 2^{n-c} + 1`$ files of length $`n`$ are $`c`$-incompressible on $`D`$.
- Take any length $`m`$. Then there are $`2^m - 1`$ bit strings shorter than $`m`$ bits.
- The tiny $`D`$ prints 0101010101010101 from `1 01 01`, and prints 0110100110010110 from `0` and those 16 bits.
- The Step 1 table is right: 32,767, 16,383, 4,095 and 255 short descriptions; at least 32,769, 49,153, 61,441 and 65,281 files.
- Tiny $`D`$'s table adds up: 2, 2, 12, 240 and 65,280 files make 65,536.
- The zip and balance sums are right, such as 6,932 bytes making 55,456 bits and 8 × 328 = 2,624.

Running tiny $`D`$ on every description, the zip passes, the second-pass bound and the balance test are left to the Python and Rust checks.

```lean
-- Incompressibility: for any fixed decompressor, at most 2^(n-c) - 1 bit strings of length n have a description shorter than n - c bits, so at least 2^n - 2^(n-c) + 1 of them are c-incompressible.
import Mathlib.Data.Set.Card
import Mathlib.Data.List.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Data.Set.Finite.List
import Mathlib.Data.Fintype.BigOperators

open Finset

/-! Files and descriptions are bit strings, `List Bool`. A decompressor `D` is any fixed
partial function from descriptions to files: `D d = some x` means `D` reads `d` and prints
`x`, and `D d = none` means `d` is not a valid description. The universal machine `U` of
the Kolmogorov complexity card is one such `D`, so the bound holds for `K` too. -/

/-- Helper: there are `2^m` bit strings of length `m`. -/
theorem ncard_length_eq (m : ℕ) : {d : List Bool | d.length = m}.ncard = 2 ^ m := by
  rw [← Nat.card_coe_set_eq]
  exact (Nat.card_eq_fintype_card (α := List.Vector Bool m)).trans (by simp [card_vector])

#print axioms ncard_length_eq

/-- Helper: there are `2^m - 1` bit strings shorter than `m`. -/
theorem ncard_length_lt (m : ℕ) : {d : List Bool | d.length < m}.ncard = 2 ^ m - 1 := by
  induction m with
  | zero => simp
  | succ k ih =>
    have hsplit : {d : List Bool | d.length < k + 1} =
        {d : List Bool | d.length < k} ∪ {d : List Bool | d.length = k} := by
      ext d; simp; omega
    have hdisj : Disjoint {d : List Bool | d.length < k} {d : List Bool | d.length = k} := by
      rw [Set.disjoint_left]; intro d h1 h2; simp at h1 h2; omega
    rw [hsplit, Set.ncard_union_eq hdisj (List.finite_length_lt Bool k)
      (List.finite_length_eq Bool k), ih, ncard_length_eq]
    have : 1 ≤ 2 ^ k := Nat.one_le_two_pow
    rw [pow_succ]; omega

#print axioms ncard_length_lt

/-- The counting bound: fix any decompressor `D` before the files are seen. Among the bit
strings `x` of length `n`, those with some description `d` shorter than `n - c` bits
(`D d = some x`, `|d| < n - c`) number at most `2^(n-c) - 1`. Counted with `encard`, so the
set's finiteness is part of the claim. -/
theorem few_files_have_a_description_shorter_than_n_minus_c
    (D : List Bool → Option (List Bool)) (n c : ℕ) :
    {x : List Bool | x.length = n ∧ ∃ d : List Bool, d.length < n - c ∧ D d = some x}.encard
      ≤ ((2 ^ (n - c) - 1 : ℕ) : ℕ∞) := by
  have hsub : {x : List Bool | x.length = n ∧ ∃ d : List Bool, d.length < n - c ∧ D d = some x}
      ⊆ (fun d => (D d).getD []) '' {d : List Bool | d.length < n - c} := by
    rintro x ⟨-, d, hd, hD⟩
    exact ⟨d, hd, by simp [hD]⟩
  calc _ ≤ _ := Set.encard_le_encard hsub
    _ ≤ _ := Set.encard_image_le _ _
    _ = _ := by
      rw [← (List.finite_length_lt Bool (n - c)).cast_ncard_eq, ncard_length_lt]

/-- Random strings abound: for any fixed decompressor `D`, at least `2^n - (2^(n-c) - 1)`
bit strings of length `n` are `c`-incompressible on `D`, meaning every description of them
is at least `n - c` bits long. With `c = 0`, at least one string of every length has no
description shorter than itself. -/
theorem many_files_are_c_incompressible
    (D : List Bool → Option (List Bool)) (n c : ℕ) :
    2 ^ n - (2 ^ (n - c) - 1)
      ≤ {x : List Bool | x.length = n ∧ ∀ d : List Bool, D d = some x → n - c ≤ d.length}.ncard := by
  set I := {x : List Bool | x.length = n ∧ ∀ d : List Bool, D d = some x → n - c ≤ d.length}
  set S := {x : List Bool | x.length = n ∧ ∃ d : List Bool, d.length < n - c ∧ D d = some x}
  have hL : {x : List Bool | x.length = n} ⊆ I ∪ S := by
    intro x hx
    by_cases h : ∀ d : List Bool, D d = some x → n - c ≤ d.length
    · exact Or.inl ⟨hx, h⟩
    · simp only [not_forall, not_le] at h
      obtain ⟨d, hD, hd⟩ := h
      exact Or.inr ⟨hx, d, hd, hD⟩
  have hSfin : S.Finite := (List.finite_length_eq Bool n).subset (fun x (hx : x ∈ S) => hx.1)
  have hS : S.ncard ≤ 2 ^ (n - c) - 1 := by
    have h := few_files_have_a_description_shorter_than_n_minus_c D n c
    rw [← hSfin.cast_ncard_eq] at h
    exact_mod_cast h
  have h1 := Set.ncard_le_ncard hL (((List.finite_length_eq Bool n).subset
    (fun x (hx : x ∈ I) => hx.1)).union hSfin)
  have h2 := Set.ncard_union_le I S
  rw [ncard_length_eq] at h1
  omega

/-- Step 1, the count of short strings: by the rules of sum and product there are `2^L`
bit strings of each length `L`, so the bit strings shorter than `m` number
`2^0 + 2^1 + ... + 2^(m-1) = 2^m - 1`. -/
theorem bit_strings_shorter_than_m_number_two_pow_m_minus_one (m : ℕ) :
    {d : List Bool | d.length < m}.ncard = 2 ^ m - 1 := by
  exact ncard_length_lt m

/-! ### The card's tiny decompressor `D` on 16-bit files

`0` then 16 bits prints the file as written. `1`, two bits choosing a period `p` of 1, 2, 4
or 8, then `p` bits of pattern, prints the pattern repeated to fill 16 bits. -/

/-- Two bits, most significant first, pick the period 1, 2, 4 or 8. -/
def tinyPeriod : Bool → Bool → ℕ
  | false, false => 1
  | false, true => 2
  | true, false => 4
  | true, true => 8

/-- The card's tiny decompressor. -/
def tinyD : List Bool → Option (List Bool)
  | false :: rest => if rest.length = 16 then some rest else none
  | true :: a :: b :: pat =>
      if pat.length = tinyPeriod a b then
        some (List.flatten (List.replicate (16 / tinyPeriod a b) pat))
      else none
  | _ => none

-- `1 01 01` (5 bits) prints 0101010101010101: period 2, pattern 01.
example : tinyD [true, false, true, false, true]
    = some [false, true, false, true, false, true, false, true,
            false, true, false, true, false, true, false, true] := by decide
-- `0` then 0110100110010110 (17 bits) prints that file as written.
example : tinyD (false :: [false, true, true, false, true, false, false, true,
                          true, false, false, true, false, true, true, false])
    = some [false, true, true, false, true, false, false, true,
            true, false, false, true, false, true, true, false] := by decide
-- The four kinds of pattern description cost 4, 5, 7 and 11 bits.
example : [1, 2, 4, 8].map (3 + ·) = [4, 5, 7, 11] := by decide

/-! ### The card's whole-number worked examples -/

-- 2^16 = 65,536 files of 16 bits.
example : 2 ^ 16 = 65536 := by norm_num
-- The sum of 2^L over lengths below 16 - c against the closed form, for c = 1, 2, 4, 8.
example : ∑ L ∈ range 15, 2 ^ L = 2 ^ 15 - 1 ∧ 2 ^ 15 - 1 = 32767 := by decide
example : ∑ L ∈ range 14, 2 ^ L = 2 ^ 14 - 1 ∧ 2 ^ 14 - 1 = 16383 := by decide
example : ∑ L ∈ range 12, 2 ^ L = 2 ^ 12 - 1 ∧ 2 ^ 12 - 1 = 4095 := by decide
example : ∑ L ∈ range 8, 2 ^ L = 2 ^ 8 - 1 ∧ 2 ^ 8 - 1 = 255 := by decide
-- Files that need 16 - c bits or more: at least 32,769, 49,153, 61,441 and 65,281.
example : 65536 - 32767 = 32769 ∧ 65536 - 16383 = 49153 ∧
    65536 - 4095 = 61441 ∧ 65536 - 255 = 65281 := by decide
-- Tiny D: files by shortest description, from the period count 2^p - 2^(p/2), cover all 65,536.
example : 2 ^ 1 = 2 ∧ 2 ^ 2 - 2 ^ 1 = 2 ∧ 2 ^ 4 - 2 ^ 2 = 12 ∧ 2 ^ 8 - 2 ^ 4 = 240 ∧
    2 ^ 16 - 2 ^ 8 = 65280 ∧ 2 + 2 + 12 + 240 + 65280 = 65536 := by decide
-- Tiny D's counts sit under the bound: 256 below 15 bits, 16 below 11 and 8 bits, 0 below 4.
example : 256 ≤ 2 ^ 15 - 1 ∧ 16 ≤ 2 ^ 11 - 1 ∧ 16 ≤ 2 ^ 8 - 1 ∧ 0 ≤ 2 ^ 4 - 1 := by decide
-- With the file built in: 257 files below 15 bits, still under 32,767.
example : 257 ≤ 32767 := by decide
-- Keeping the first 8 bits of 16: 256 outputs, 256 files share each.
example : 2 ^ 16 / 2 ^ 8 = 256 ∧ 2 ^ 8 = 256 := by decide
-- A 1,048,576-byte file is 8,388,608 bits; 1% of that is 83,886 bits, rounded down.
example : 8 * 1048576 = 8388608 ∧ 8388608 / 100 = 83886 := by norm_num
-- Zip 1: 6,932 bytes is 55,456 bits; 10% is 5,545 bits; zip 2 is 1,282 bytes larger.
example : 6932 * 8 = 55456 ∧ 55456 / 10 = 5545 ∧ 8214 - 6932 = 1282 := by norm_num
-- The other passes: 16,291 - 6,932 = 9,359; 9,758 - 8,214 = 1,544; 8,354 - 6,932 = 1,422.
example : 16291 - 6932 = 9359 ∧ 9758 - 8214 = 1544 ∧ 8354 - 6932 = 1422 := by norm_num
-- The 328-byte generator: K(text) is at most 2,624 bits.
example : 8 * 328 = 2624 := by norm_num
-- The balance description saves 1000 - cost bits: -5, 2, 24, 113, 525.
example : (1000 : ℤ) - 1005 = -5 ∧ 1000 - 998 = 2 ∧ 1000 - 976 = 24 ∧
    1000 - 887 = 113 ∧ 1000 - 475 = 525 := by norm_num
-- 10 bits suffice for the count of ones, 0 to 1000.
example : 1000 < 2 ^ 10 := by norm_num

#print axioms few_files_have_a_description_shorter_than_n_minus_c
#print axioms many_files_are_c_incompressible
#print axioms bit_strings_shorter_than_m_number_two_pow_m_minus_one
```

**Checked 2026-11-19 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'ncard_length_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'ncard_length_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'few_files_have_a_description_shorter_than_n_minus_c' depends on axioms: [propext, Classical.choice, Quot.sound]
'many_files_are_c_incompressible' depends on axioms: [propext, Classical.choice, Quot.sound]
'bit_strings_shorter_than_m_number_two_pow_m_minus_one' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Make the text four times longer.** Change `range(4000)` to `range(16000)`. Guess whether the first pass does better. Answer: 65,009 bytes go to 24,680, ratio 0.3796, since LZ78 learns longer phrases. The second pass still grows it, to 30,118 bytes.
> - **Use only the first 4 words.** Change `rng.next() % len(WORDS)` to `rng.next() % 4`. Guess the ratio. Answer: 12,003 bytes go to 2,930, ratio 0.2441. Zip 2 is 3,453 bytes: larger again.
> - **Try 470, 460 and 450 ones.** Change `(500, 450, 400, 300, 100)` to `(470, 460, 450)`. Guess where the balance description starts to save. Answer: −3 and −1 bits at 470 and 460, then 2 bits at 450.

---

## The usual mistake

> [!warning]
> **Believing a clever enough coder can shrink any file, or shrink its own output again.** The count forbids it. Fewer than one file in $`2^c`$ of each length can lose more than $`c`$ bits, whatever the coder. A zipped file has already lost its patterns, so a second pass grows it: 6,932 bytes became 8,214.
>
> - **Treating a compressor's output as $`K`$.** It is only an upper bound. LZ78 packs the text into 6,932 bytes, yet a 328-byte program prints the whole text: the 32-word list, SplitMix64 and seed 2026.
> - **Forgetting the fixed parts of a description.** The balance description of a 1000-bit string with 500 ones costs 1,005 bits, not 995: the 10 bits for the count are part of it.
> - **Reading "most files" as "every file".** With $`c = 8`$, up to 255 of the 65,536 16-bit files may still have descriptions shorter than 8 bits.
> - **Calling a file random because it passes one test.** Balance, flat byte counts and the like rule out some patterns. Randomness means no program at all finds one.

---

## Where you meet it in real life

- **Zip archives of photos and music.** JPEG, MP3 and video files are already compressed, so zipping them saves almost nothing. The DEFLATE format behind zip has a stored block type, which copies data as it is, for this case.
- **Compress, then encrypt.** Good encryption output looks like coin bytes, so it does not compress. Systems that do both compress first.
- **Testing random-number generators.** Test suites include compression-style tests, such as Maurer's universal test, since a stream that compresses is not random. Passing them is not proof of randomness; see [Pseudorandomness](../04-Beyond%20Worst%20Case/04-derandomisation-and-pseudorandomness.md).
- **Claims of repeated compression.** A scheme said to shrink any file, or to shrink its own output again and again, fails the count on this card.
- **Proofs about algorithms.** The incompressibility method proves average-case lower bounds by running an algorithm on an incompressible input, which must behave like a typical one (Li and Vitányi, chapter 6).

> **Say it back**
> There are fewer than $`2^{n-c}`$ bit strings shorter than $`n - c`$, and each one describes at most one file. So fewer than one file in $`2^c`$ of length $`n`$ can be compressed by more than $`c`$ bits, by any coder. A file whose shortest program is nearly as long as the file is called random, and almost every file is random. A random file passes every test a program can run that flags only a tiny share of files, but no program can prove a given file is random. A zipped file already looks random to a zip-style coder, so zipping it again makes it larger.

---

## What this builds on

- [Kolmogorov complexity](05-kolmogorov-complexity.md): the universal machine $`U`$, the length $`K(x)`$ of the shortest program, and the fact that $`K`$ is not computable.
- [The rules of sum and product](../../04-Combinatorics%20and%20graphs/01-Counting%20Principles/01-rules-of-sum-and-product.md): $`2^L`$ strings of each length, and the sum over lengths that gives $`2^m - 1`$.
- [Pigeonhole](../../01-Foundations/08-Relations%20and%20Functions/08-pigeonhole-principle.md): no coder shrinks every file; this card turns that into a share.
- [Arithmetic and Lempel-Ziv coding](../../14-Applied%20and%20computational/03-Information%20Theory/06-arithmetic-and-lempel-ziv-coding.md): how LZ78 replaces repeats with pointers, the coder the checks run.

## Where this goes next

- [Lambda calculus](07-lambda-calculus-in-outline.md), the next card: programs written as functions, a second machine on which descriptions, and so $`K`$, can be measured up to a constant.
- [Pseudorandomness](../04-Beyond%20Worst%20Case/04-derandomisation-and-pseudorandomness.md): strings that are very compressible, since a short seed describes them, yet fool every fast test.

Related on this shelf: [Decidable and semidecidable](01-decidable-and-semidecidable-sets.md) (the compressible strings form a semidecidable set, the random ones do not), [Busy beaver](02-the-busy-beaver-function.md), [Godel's theorems](03-godels-incompleteness-in-outline.md), [Hilbert's tenth problem](04-hilberts-tenth-problem.md) and [Proof assistants](08-proof-assistants-and-formal-verification.md).

The question this card leaves open: if no program can prove a particular file is random, what evidence about one file should count?

---

## Sources

Verified 2026-11-19: every link below resolves to the publisher's page.

- Li, Ming, and Paul Vitányi. *An Introduction to Kolmogorov Complexity and Its Applications*, 4th ed. Springer, 2019. [DOI 10.1007/978-3-030-11298-1](https://doi.org/10.1007/978-3-030-11298-1). The counting bound, the definition of random strings, the Levin–Schnorr theorem (chapter 3) and the incompressibility method (chapter 6).
- Kolmogorov, A. N. "Three approaches to the quantitative definition of information." *International Journal of Computer Mathematics* 2 (1968). [DOI 10.1080/00207166808803030](https://doi.org/10.1080/00207166808803030). The shortest-description measure of information, and randomness as its absence of shortcuts.
- Chaitin, Gregory J. "On the length of programs for computing finite binary sequences." *Journal of the ACM* 13 (1966). [DOI 10.1145/321356.321363](https://doi.org/10.1145/321356.321363). Program length as a measure of pattern, and the count showing most strings have none.
- Martin-Löf, Per. "The definition of random sequences." *Information and Control* 9 (1966). [DOI 10.1016/S0019-9958(66)80018-9](https://doi.org/10.1016/S0019-9958(66)80018-9). Randomness as passing every effective statistical test, the notion of Step 3.
- Ziv, Jacob, and Abraham Lempel. "Compression of individual sequences via variable-rate coding." *IEEE Transactions on Information Theory* 24 (1978). [DOI 10.1109/TIT.1978.1055934](https://doi.org/10.1109/TIT.1978.1055934). LZ78, the coder the checks run twice.
