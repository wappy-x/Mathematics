# Matrices: a table of numbers with a size, plus the named shapes you will keep meeting

[Syllabus](../../../SYLLABUS.md) → [Algebra](../README.md) → [Matrices](../README.md#s04) → Matrices

---

## General Overview

A cafe writes down what it sold. Monday: 2 coffees and 1 pastry. Tuesday: 1 coffee and 1 pastry. Two rows, one per day; two columns, one per product. Take the words away and four numbers are left, still in their places:

`[[2, 1], [1, 1]]`

That is a **matrix**: a rectangular table of numbers, written row by row in square brackets, with its size stated as rows by columns. This one is 2 by 2.

The position does the work. Wednesday's row is `[3, 2]`: 3 coffees, 2 pastries. That 3 counts coffees only because of where it sits — the trick of the 5 in 523 meaning five hundreds ([Place value](../../01-Foundations/01-Everyday%20Arithmetic/01-place-value.md)).

A few shapes recur often enough to have names. They fill the back half of this card.

**A matrix is a table of numbers where each number's position is part of its meaning, and the size — rows by columns — is part of the matrix.**

**What kind of fact this is:** a definition, with one convention inside it: rows are counted before columns.

### The picture: the cafe's week, five days by two products

|  | coffee | pastry |
| --- | --- | --- |
| **Mon** | 2 | 1 |
| **Tue** | 1 | 1 |
| **Wed** | 3 | 2 |
| **Thu** | 2 | 1 |
| **Fri** | 4 | 3 |

Five rows, two columns: a 5 by 2 matrix, `[[2, 1], [1, 1], [3, 2], [2, 1], [4, 3]]`, whose first two rows are the two-day table.

---

## The formula

Notation first, in words: a matrix A with m rows and n columns is m by n, and the number in row i, column j is its **entry**, written a_ij. Row number first. Always.

$$(A + B)_{ij} = a_{ij} + b_{ij}, \qquad (cA)_{ij} = c\,a_{ij}, \qquad (A^{T})_{ij} = a_{ji}$$

$$\operatorname{tr}(A) = a_{11} + a_{22} + \cdots + a_{nn}$$

**Read it aloud:** same-size tables add entry by matching entry; scaling multiplies every entry by one number; transposing swaps each entry's row and column numbers; the trace adds the diagonal entries.

| Symbol | Plain meaning | In the cafe's table | Change it and… |
| --- | --- | --- | --- |
| $A$, $B$ | two matrices of the same size | `[[2, 1], [1, 1]]` the two days, `[[3, 2], [2, 1]]` week two | — |
| $m$, $n$ | how many rows, how many columns | 5 and 2 for the week | a taller or wider table |
| $a_{ij}$, $b_{ij}$ | their entries in row i, column j; both count from 1 | a_21 is 1: Tuesday's coffees | another slot is read |
| $c$ | a plain number to scale by | 2, for days that doubled | every entry scales with it |
| $A^{T}$ | $A$ transposed: rows become columns | the week tipped: 2 by 5, not 5 by 2 | the size flips too |
| $I$ | the identity: 1s down the diagonal, 0s elsewhere | `[[1, 0], [0, 1]]` | — |
| $\operatorname{tr}(A)$ | the trace: the diagonal entries added | 2 + 1 = 3 | it rises with a diagonal entry |

The **main diagonal** is the entries whose row number equals their column number: a_11, a_22, on down. Only a **square** table — as many rows as columns — has one reaching the bottom-right corner.

### When it holds

- **Rows all the same length.** A ragged table is no matrix: a_ij names nothing where row i has run out.
- **Matching sizes to add.** 5 by 2 plus 2 by 2 has no answer; labels must match too, or the sum adds coffees to pastries.
- **Any size to scale or transpose.** An m by n table transposes to n by m.
- **Square tables for the trace and the named shapes.** On the 5 by 2 week the diagonal stops after two entries, and adding those two mixes coffees with pastries.

---

## Why it works

### Step 0: a table is a matrix once the size is nailed down

Ten numbers are ten numbers. Arranged 5 by 2 they are the cafe's week; arranged 2 by 5, a different matrix. The size is part of the matrix: two matrices are equal only when their sizes match and every matching slot agrees.

That is why adding needs matching sizes: a 5 by 2 and a 2 by 2 table have no slot-by-slot pairing. Their sum does not exist. Not wrong — nonexistent.

### Step 1: the row number first, the column number second

a_21 means row 2, column 1: in the two-day table, Tuesday's coffees, 1. Read backwards it becomes a_12, Monday's pastries, also 1 here, so nothing looks wrong. In `[[2, 1], [0, 1]]` the error shows: row 2, column 1 is 0, row 1, column 2 is 1.

### Step 2: adding and scaling happen slot by slot

Week two sells `[[3, 2], [2, 1]]`. The two-week total goes slot by slot: Monday coffee 2 + 3 = 5, Monday pastry 1 + 2 = 3, Tuesday coffee 1 + 2 = 3, Tuesday pastry 1 + 1 = 2. The sum is `[[5, 3], [3, 2]]`, still 2 by 2.

Scaling is the same with one multiplier: a pair of days that sold exactly double is 2A = `[[4, 2], [2, 2]]`. Nothing moves; every number is multiplied where it stands. Both leave each slot's meaning alone; multiplication does not ([Matrix multiplication](03-matrix-multiplication.md)).

### Step 3: the transpose asks the same question the other way

The week table is days by products: pick a day, read across. Tip it over and it is products by days: pick a product, read across. That is the **transpose**, written $A^{T}$.

|  | Mon | Tue | Wed | Thu | Fri |
| --- | --- | --- | --- | --- | --- |
| **coffee** | 2 | 1 | 3 | 2 | 4 |
| **pastry** | 1 | 1 | 2 | 1 | 3 |

The 5 by 2 became 2 by 5. No number changed meaning: Wednesday's 3 coffees sits along the coffee row, not down the coffee column. Each entry swaps its two numbers, so doing it twice puts everything back.

### Step 4: the shapes worth naming, and the trace

Four patterns come up constantly, all of them square, and one table can earn several names.

| Name | What is special | Example |
| --- | --- | --- |
| **diagonal** | every entry off the diagonal is 0 | `[[4, 0], [0, 3]]` — the cafe's prices, $4 a coffee, $3 a pastry |
| **identity** | diagonal, with 1s on it; written $I$ | `[[1, 0], [0, 1]]` |
| **triangular** | one side of the diagonal is all 0: upper if the zeros are below, lower if above | `[[2, 1], [0, 1]]`, upper triangular |
| **symmetric** | the flip does nothing: $A^{T}$ equals $A$, so a_ij equals a_ji | `[[2, 1], [1, 1]]` — the two-day table, by coincidence |

The identity is the do-nothing one: it keeps each number with weight 1 and none of the others, so whatever it is applied to comes back unchanged. Applying a matrix is the next card.

The **trace** adds the main diagonal into one number: 3 for the two-day table (2 + 1), 2 for the identity, 7 for the prices, 3 for the upper triangular table.

The trace of a sales table means nothing: it adds Monday's coffees to Tuesday's pastries. It is useful where rows and columns list the *same* items, and later, where it equals the sum of a square table's stretch factors, its eigenvalues.

A matrix is also a rule turning one list of numbers into another. That is the rest of this shelf: [Matrix times vector](02-matrix-times-vector.md) applies one, [Matrix multiplication](03-matrix-multiplication.md) chains two, [Linear maps](04-linear-maps-as-matrices.md) says which rules can be written this way.

---

## Worked numbers, by hand

The cafe's week, `[[2, 1], [1, 1], [3, 2], [2, 1], [4, 3]]`, and the two-day table A = `[[2, 1], [1, 1]]`.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the week table, then tipped over | five days down, two products across | 5 by 2, then 2 by 5 |
| coffees, down column 1 | 2 + 1 + 3 + 2 + 4 | **12** |
| pastries, down column 2 | 1 + 1 + 2 + 1 + 3 | **8** |
| the same totals, along the transpose's rows | row 1, then row 2 | 12 and 8 |
| two weeks of both days | A + `[[3, 2], [2, 1]]` | `[[5, 3], [3, 2]]` |
| a doubled pair of days | 2A | `[[4, 2], [2, 2]]` |
| A transposed | swap the row and column numbers | `[[2, 1], [1, 1]]`, equal to A |
| trace of A | 2 + 1 | **3** |

The cafe sold 12 coffees and 8 pastries that week; the transpose makes those read as easily as the daily figures.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Adding across the rows, not down the columns | 3, 2, 5, 3, 7 | those are the five day totals, not the two product totals |
| Reading row 2, column 1 of `[[2, 1], [0, 1]]` backwards | 1 instead of 0 | the row number comes first |
| Calling `[[2, 1], [0, 1]]` symmetric | transpose `[[2, 0], [1, 1]]` | the flip moved the 1 |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. The scripts build the cafe's week as rows, then reach the product totals two independent ways: adding *down* each column, and adding *across* each row of the transpose. Both must give 12 coffees and 8 pastries. A second case runs the two-day table through its sum, scaling, transpose and traces.

### Python

```python
# Matrices -- the check behind the card.  Nothing is imported.  The cafe's
# sales table has five days down the rows and two products across the columns.
# Two roads to the per-product totals: add down the columns of the table, and
# add across the rows of its transpose.  Second worked case: the two-day square
# table A, its sum with week two, its scaling, and the named shapes.
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri"]
PRODUCTS = ["coffee", "pastry"]
SALES = [[2, 1], [1, 1], [3, 2], [2, 1], [4, 3]]      # 5 rows by 2 columns

def rows(M): return len(M)
def cols(M): return len(M[0])
def transpose(M): return [[M[i][j] for i in range(rows(M))] for j in range(cols(M))]
def add(M, N): return [[M[i][j] + N[i][j] for j in range(cols(M))] for i in range(rows(M))]
def scale(c, M): return [[c * M[i][j] for j in range(cols(M))] for i in range(rows(M))]

def trace(M):                                          # add the main diagonal
    total = 0
    for i in range(rows(M)):
        total += M[i][i]
    return total

def show(M): return "[[" + "], [".join(", ".join(str(x) for x in r) for r in M) + "]]"

def grid(label, M, names, what):
    print("%s, %d rows by %d columns (%s)" % (label, rows(M), cols(M), what))
    for name, row in zip(names, M):
        print("  %-7s" % name + "".join("%3d" % x for x in row))

FLIPPED = transpose(SALES)
down = [sum(SALES[i][j] for i in range(rows(SALES))) for j in range(cols(SALES))]   # road one
across = [sum(row) for row in FLIPPED]                                             # road two
grid("sales table", SALES, DAYS, "days by products")
grid("transposed", FLIPPED, PRODUCTS, "products by days")
print("coffees and pastries, down the columns:  %d  %d   (%d items in all)"
      % (down[0], down[1], down[0] + down[1]))
print("coffees and pastries, across the rows of the transpose:  %d  %d" % (across[0], across[1]))
print("day totals, across the rows of the sales table: " + " ".join(str(sum(r)) for r in SALES))

A = [[2, 1], [1, 1]]
B = [[3, 2], [2, 1]]
TRI = [[2, 1], [0, 1]]
IDENT = [[1, 0], [0, 1]]
PRICES = [[4, 0], [0, 3]]
print("two days only, A = %s, %d rows by %d columns" % (show(A), rows(A), cols(A)))
print("week two B = %s;  A + B = %s;  2A = %s" % (show(B), show(add(A, B)), show(scale(2, A))))
print("A transposed = %s, equal to A, so A is symmetric" % show(transpose(A)))
print("upper triangular %s: row 2 column 1 is %d, row 1 column 2 is %d; transposed %s, not equal to it"
      % (show(TRI), TRI[1][0], TRI[0][1], show(transpose(TRI))))
print("prices on the diagonal %s; identity %s" % (show(PRICES), show(IDENT)))
print("traces: A %d, identity %d, prices %d, triangular %d"
      % (trace(A), trace(IDENT), trace(PRICES), trace(TRI)))

assert FLIPPED == [[2, 1, 3, 2, 4], [1, 1, 2, 1, 3]] and (rows(FLIPPED), cols(FLIPPED)) == (cols(SALES), rows(SALES))
assert down == across and down == [12, 8]
assert transpose(FLIPPED) == SALES and add(A, B) == [[5, 3], [3, 2]] and scale(2, A) == [[4, 2], [2, 2]]
assert transpose(A) == A and transpose(TRI) != TRI and [trace(A), trace(IDENT), trace(PRICES), trace(TRI)] == [3, 2, 7, 3]
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
sales table, 5 rows by 2 columns (days by products)
  Mon      2  1
  Tue      1  1
  Wed      3  2
  Thu      2  1
  Fri      4  3
transposed, 2 rows by 5 columns (products by days)
  coffee   2  1  3  2  4
  pastry   1  1  2  1  3
coffees and pastries, down the columns:  12  8   (20 items in all)
coffees and pastries, across the rows of the transpose:  12  8
day totals, across the rows of the sales table: 3 2 5 3 7
two days only, A = [[2, 1], [1, 1]], 2 rows by 2 columns
week two B = [[3, 2], [2, 1]];  A + B = [[5, 3], [3, 2]];  2A = [[4, 2], [2, 2]]
A transposed = [[2, 1], [1, 1]], equal to A, so A is symmetric
upper triangular [[2, 1], [0, 1]]: row 2 column 1 is 0, row 1 column 2 is 1; transposed [[2, 0], [1, 1]], not equal to it
prices on the diagonal [[4, 0], [0, 3]]; identity [[1, 0], [0, 1]]
traces: A 3, identity 2, prices 7, triangular 3
ALL CHECKS PASS
```

### Rust

Same numbers and labels, built with `rustc --edition 2021 -O`.

```rust
// Matrices -- the same check as the Python, in Rust.  No crates.  The cafe's
// sales table has five days down the rows and two products across the columns.
// Two roads to the per-product totals: add down the columns of the table, and
// add across the rows of its transpose.  Second worked case: the two-day square
// table A, its sum with week two, its scaling, and the named shapes.
type Mat = Vec<Vec<i64>>;
fn mat(rows: &[&[i64]]) -> Mat { rows.iter().map(|r| r.to_vec()).collect() }
fn rows(m: &Mat) -> usize { m.len() }
fn cols(m: &Mat) -> usize { m[0].len() }
fn transpose(m: &Mat) -> Mat {
    (0..cols(m)).map(|j| (0..rows(m)).map(|i| m[i][j]).collect()).collect()
}
fn add(a: &Mat, b: &Mat) -> Mat {
    (0..rows(a)).map(|i| (0..cols(a)).map(|j| a[i][j] + b[i][j]).collect()).collect()
}
fn scale(c: i64, a: &Mat) -> Mat {
    (0..rows(a)).map(|i| (0..cols(a)).map(|j| c * a[i][j]).collect()).collect()
}

fn trace(m: &Mat) -> i64 {                             // add the main diagonal
    let mut total = 0;
    for i in 0..rows(m) {
        total += m[i][i];
    }
    total
}

fn show(m: &Mat) -> String {
    let rs: Vec<String> = m.iter()
        .map(|r| r.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))
        .collect();
    format!("[[{}]]", rs.join("], ["))
}

fn grid(label: &str, m: &Mat, names: &[&str], what: &str) {
    println!("{}, {} rows by {} columns ({})", label, rows(m), cols(m), what);
    for (name, row) in names.iter().zip(m.iter()) {
        let mut line = format!("  {:<7}", name);
        for x in row { line.push_str(&format!("{:>3}", x)); }
        println!("{}", line);
    }
}

fn main() {
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    let products = ["coffee", "pastry"];
    let sales = mat(&[&[2, 1], &[1, 1], &[3, 2], &[2, 1], &[4, 3]]);   // 5 rows by 2 columns
    let flipped = transpose(&sales);
    let down: Vec<i64> = (0..cols(&sales))                             // road one
        .map(|j| (0..rows(&sales)).map(|i| sales[i][j]).sum()).collect();
    let across: Vec<i64> = flipped.iter().map(|r| r.iter().sum()).collect();   // road two
    grid("sales table", &sales, &days, "days by products");
    grid("transposed", &flipped, &products, "products by days");
    println!("coffees and pastries, down the columns:  {}  {}   ({} items in all)",
             down[0], down[1], down[0] + down[1]);
    println!("coffees and pastries, across the rows of the transpose:  {}  {}", across[0], across[1]);
    let day_totals: Vec<i64> = sales.iter().map(|r| r.iter().sum()).collect();
    let shown: Vec<String> = day_totals.iter().map(|t| t.to_string()).collect();
    println!("day totals, across the rows of the sales table: {}", shown.join(" "));

    let a = mat(&[&[2, 1], &[1, 1]]);
    let b = mat(&[&[3, 2], &[2, 1]]);
    let tri = mat(&[&[2, 1], &[0, 1]]);
    let ident = mat(&[&[1, 0], &[0, 1]]);
    let prices = mat(&[&[4, 0], &[0, 3]]);
    println!("two days only, A = {}, {} rows by {} columns", show(&a), rows(&a), cols(&a));
    println!("week two B = {};  A + B = {};  2A = {}", show(&b), show(&add(&a, &b)), show(&scale(2, &a)));
    println!("A transposed = {}, equal to A, so A is symmetric", show(&transpose(&a)));
    println!("upper triangular {}: row 2 column 1 is {}, row 1 column 2 is {}; transposed {}, not equal to it",
             show(&tri), tri[1][0], tri[0][1], show(&transpose(&tri)));
    println!("prices on the diagonal {}; identity {}", show(&prices), show(&ident));
    println!("traces: A {}, identity {}, prices {}, triangular {}",
             trace(&a), trace(&ident), trace(&prices), trace(&tri));

    assert!(flipped == mat(&[&[2, 1, 3, 2, 4], &[1, 1, 2, 1, 3]]) && rows(&flipped) == cols(&sales) && cols(&flipped) == rows(&sales));
    assert!(down == across && down == vec![12, 8]);
    assert!(transpose(&flipped) == sales && add(&a, &b) == mat(&[&[5, 3], &[3, 2]]) && scale(2, &a) == mat(&[&[4, 2], &[2, 2]]));
    assert!(transpose(&a) == a && transpose(&tri) != tri && vec![trace(&a), trace(&ident), trace(&prices), trace(&tri)] == vec![3, 2, 7, 3]);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
sales table, 5 rows by 2 columns (days by products)
  Mon      2  1
  Tue      1  1
  Wed      3  2
  Thu      2  1
  Fri      4  3
transposed, 2 rows by 5 columns (products by days)
  coffee   2  1  3  2  4
  pastry   1  1  2  1  3
coffees and pastries, down the columns:  12  8   (20 items in all)
coffees and pastries, across the rows of the transpose:  12  8
day totals, across the rows of the sales table: 3 2 5 3 7
two days only, A = [[2, 1], [1, 1]], 2 rows by 2 columns
week two B = [[3, 2], [2, 1]];  A + B = [[5, 3], [3, 2]];  2A = [[4, 2], [2, 2]]
A transposed = [[2, 1], [1, 1]], equal to A, so A is symmetric
upper triangular [[2, 1], [0, 1]]: row 2 column 1 is 0, row 1 column 2 is 1; transposed [[2, 0], [1, 1]], not equal to it
prices on the diagonal [[4, 0], [0, 3]]; identity [[1, 0], [0, 1]]
traces: A 3, identity 2, prices 7, triangular 3
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the transpose and symmetry rules for tables of every size, and checks the cafe's own tables number by number.

- Transposing an m by n table gives an n by m table, and each entry swaps its row and column numbers.
- Transposing twice puts every number back where it started.
- Adding down a column of a table gives the same total as adding across the matching row of its transpose.
- A square table is symmetric exactly when a_ij equals a_ji for every pair off the diagonal.
- The cafe's tables come out as on the card: totals 12 and 8, the sum, 2A, the four named shapes and their traces.

Printing the tables, and the experiments in the box below, are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 79 lines</summary>

```lean
-- Matrices: transposing an m by n table gives an n by m table with each entry's row and column numbers swapped, doing it twice gives the table back, the column totals of a table are the row totals of its transpose, and a square table is symmetric exactly when every entry a_ij equals a_ji off the diagonal; the cafe's own tables are checked number by number.
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.Notation

open Matrix

/-- The transpose tips the table over. For every size m by n and every table A of that size,
the transpose is n by m, the entry in its row j, column i is A's entry in row i, column j,
and transposing twice puts every number back where it started. -/
theorem transpose_swaps_entries_and_twice_gives_back {α : Type*} (m n : ℕ)
    (A : Matrix (Fin m) (Fin n) α) :
    (∀ i : Fin m, ∀ j : Fin n, Aᵀ j i = A i j) ∧ Aᵀᵀ = A := by
  exact ⟨fun i j => rfl, Matrix.transpose_transpose A⟩

/-- The same totals read two ways. For every m by n table of numbers, adding down column j
of the table gives the same total as adding across row j of its transpose. -/
theorem column_totals_are_row_totals_of_transpose {α : Type*} [AddCommMonoid α] (m n : ℕ)
    (A : Matrix (Fin m) (Fin n) α) (j : Fin n) :
    ∑ i : Fin m, A i j = ∑ i : Fin m, Aᵀ j i := by
  rfl

/-- Symmetric is tested pair by pair. A square table is symmetric (its transpose equals it)
exactly when every pair of entries across the diagonal agrees: a_ij equals a_ji for every row i
and column j off the diagonal (i different from j). The diagonal entries never need checking. -/
theorem symmetric_iff_entries_match_off_diagonal {α : Type*} (n : ℕ)
    (A : Matrix (Fin n) (Fin n) α) :
    A.IsSymm ↔ ∀ i j : Fin n, i ≠ j → A i j = A j i := by
  constructor
  · intro h i j _
    have := congrFun (congrFun h j) i
    simpa [Matrix.transpose_apply] using this
  · intro h
    ext i j
    by_cases hij : j = i
    · subst hij; rfl
    · exact (h i j (Ne.symm hij)).symm

-- The cafe's week: five days by two products, and its transpose, two by five.
example : (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ)ᵀ
    = !![2, 1, 3, 2, 4; 1, 1, 2, 1, 3] := by decide
-- Coffees 12 and pastries 8, down the columns of the week.
example : ∑ i : Fin 5, (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ) i 0 = 12 ∧
    ∑ i : Fin 5, (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ) i 1 = 8 := by decide
-- 12 coffees and 8 pastries: 20 items in all.
example : (12 : ℤ) + 8 = 20 := by decide
-- The same 12 and 8 across the rows of the transpose.
example : ∑ j : Fin 5, (!![2, 1, 3, 2, 4; 1, 1, 2, 1, 3] : Matrix (Fin 2) (Fin 5) ℤ) 0 j = 12 ∧
    ∑ j : Fin 5, (!![2, 1, 3, 2, 4; 1, 1, 2, 1, 3] : Matrix (Fin 2) (Fin 5) ℤ) 1 j = 8 := by decide
-- The mistake: totals across the rows are the day totals 3, 2, 5, 3, 7.
example : (fun i : Fin 5 => ∑ j : Fin 2, (!![2, 1; 1, 1; 3, 2; 2, 1; 4, 3] : Matrix (Fin 5) (Fin 2) ℤ) i j)
    = ![3, 2, 5, 3, 7] := by decide
-- Two weeks of both days, and a doubled pair of days.
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) + !![3, 2; 2, 1] = !![5, 3; 3, 2] := by decide
example : (2 : ℤ) • (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) = !![4, 2; 2, 2] := by decide
-- A = [[2, 1], [1, 1]] is symmetric; its trace is 2 + 1 = 3. Its entry a_21 is 1.
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ = !![2, 1; 1, 1] := by decide
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).IsSymm := by decide
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).trace = 3 := by decide
example : (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ) 1 0 = 1 := by decide
-- The upper triangular table [[2, 1], [0, 1]]: row 2, column 1 is 0, row 1, column 2 is 1,
-- zeros below the diagonal, trace 3, and its transpose [[2, 0], [1, 1]] is not equal to it.
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) 1 0 = 0 ∧
    (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) 0 1 = 1 := by decide
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).BlockTriangular id := by decide
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).trace = 3 := by decide
example : (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ = !![2, 0; 1, 1] ∧
    (!![2, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ ≠ !![2, 1; 0, 1] := by decide
-- The prices table is diagonal, $4 and $3, with trace 7.
example : (!![4, 0; 0, 3] : Matrix (Fin 2) (Fin 2) ℤ) = diagonal ![4, 3] := by decide
example : (!![4, 0; 0, 3] : Matrix (Fin 2) (Fin 2) ℤ).trace = 7 := by decide
-- The identity: 1s down the diagonal, 0s elsewhere, trace 2.
example : (1 : Matrix (Fin 2) (Fin 2) ℤ) = !![1, 0; 0, 1] := by decide
example : (1 : Matrix (Fin 2) (Fin 2) ℤ).trace = 2 := by decide

#print axioms transpose_swaps_entries_and_twice_gives_back
#print axioms column_totals_are_row_totals_of_transpose
#print axioms symmetric_iff_entries_match_off_diagonal
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'transpose_swaps_entries_and_twice_gives_back' depends on axioms: [propext, Quot.sound]
'column_totals_are_row_totals_of_transpose' depends on axioms: [propext, Classical.choice, Quot.sound]
'symmetric_iff_entries_match_off_diagonal' depends on axioms: [propext, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. An assert stops the program when a number comes out wrong; these are pinned to the cafe's numbers.
> - **Add a sixth day.** Put `[1, 4]` on the end of the sales table: 6 by 2, its transpose 2 by 6, the totals 13 and 12, and the first assert stops it.
> - **Total the rows by mistake.** Point `across` at the rows of `SALES`, not `FLIPPED`: the roads disagree, 5 day totals against 2 product totals, and the second assert stops it.
> - **Make the triangular table symmetric.** Set `TRI` to `[[2, 1], [1, 1]]`. It is now A, its transpose equals it, and the last assert stops it.

---

## The usual mistake

> [!warning]
> **Reading the size or an entry column-first.** A 5 by 2 matrix has five rows and two columns, and a_21 is row 2, column 1 — Tuesday's coffees, not Monday's pastries. In `[[2, 1], [1, 1]]` both are 1, so the mistake hides.
>
> - **Adding tables of different sizes.** There is no answer, not a wrong answer.
> - **Adding across the rows when the question is about columns.** The week's rows total 3, 2, 5, 3, 7 — day totals, not the product totals 12 and 8.
> - **Calling any square table with a repeated number symmetric.** The test is pair by pair: a_ij must equal a_ji off the diagonal.

---

## Where you meet it in real life

- **Spreadsheets.** Any sheet with labelled rows and columns is a matrix with its labels attached; "switch rows and columns" is the transpose.
- **Price lists.** A diagonal matrix holds one price per product with nothing crossing over: `[[4, 0], [0, 3]]` for the cafe. Putting those prices to work is [Matrix times vector](02-matrix-times-vector.md).

> **Say it back**
> A matrix is a table of numbers, written row by row in square brackets, sized rows by columns. Each number means what it means because of where it sits: row number first, column number second. Same-size tables add slot by slot, scaling multiplies every slot, and transposing tips the table over: the cafe's 5 by 2 days-by-products becomes a 2 by 5 products-by-days with the same 12 coffees and 8 pastries. Square tables get the named shapes — diagonal, identity, triangular, symmetric — and the trace, the main diagonal added up.

---

## What this builds on

- [Vectors](../03-Vectors/01-vectors.md): a single list of numbers where position carries meaning; each row and each column of a matrix is one.
- [Place value](../../01-Foundations/01-Everyday%20Arithmetic/01-place-value.md): the first idea in the library where *where* a number sits changes what it means.

## Where this goes next

- [Matrix times vector](02-matrix-times-vector.md): the sales table meets a price list, and the answer reads two ways.
- [The adjacency matrix](../../04-Combinatorics%20and%20graphs/09-Graphs%20-%20Dots%20and%20Lines/07-adjacency-matrix-and-walk-counting.md): a square table of which dots are joined.
- [AES](../../14-Applied%20and%20computational/04-Cryptography/02-symmetric-ciphers-and-aes.md): the Advanced Encryption Standard, a widely used cipher, holds its state as a 4 by 4 table of bytes.
- Simplicial complexes and chains: tables recording which piece borders which, signs included.
- Lie group: square matrices that form groups in their own right.
- BQP (the problems a quantum computer can solve efficiently): a quantum gate is a square table acting on a list of numbers.

A table on its own only stores. What turns it into a rule sending one list of numbers to another is [Matrix times vector](02-matrix-times-vector.md).

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Sylvester, J. J. "XLVII. Additions to the Articles in the September Number of This Journal, 'On a New Class of Theorems,' and on Pascal's Theorem." *The London, Edinburgh, and Dublin Philosophical Magazine and Journal of Science* 37, no. 251 (1850): 363–370. [doi:10.1080/14786445008646629](https://doi.org/10.1080/14786445008646629). The first use of the word "matrix".
- Cayley, Arthur. "A Memoir on the Theory of Matrices." *Philosophical Transactions of the Royal Society of London* 148 (1858): 17–37. [doi:10.1098/rstl.1858.0002](https://doi.org/10.1098/rstl.1858.0002). Where matrices become things to add, scale and multiply.
- *College Algebra 2e*, section 7.5, "Matrices and Matrix Operations." OpenStax, Rice University. [Textbook page](https://openstax.org/books/college-algebra-2e/pages/7-5-matrices-and-matrix-operations). Size, entries, addition and scaling, free.
- *Linear Algebra* (18.06). MIT OpenCourseWare. [Course page](https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/). Where these tables go once treated as rules, not storage.
