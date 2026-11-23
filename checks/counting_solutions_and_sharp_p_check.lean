-- Counting: a verifier's count of accepted certificates is at least 1 exactly when a solution exists, it is at most 2 to the power p(n), and the card's floor and adder counts come out as stated.
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.Polynomial.Eval.Defs

/-! An input `x` has length `size x`. A certificate is a string of `p (size x)` bits, written as a
function `Fin (p (size x)) → Bool` and handed to the verifier as the list of its bits. -/

/-- `#V(x)`: the number of bit strings `c` of length `p (size x)` that the verifier `V` accepts. -/
def sharpV {α : Type*} (size : α → ℕ) (p : ℕ → ℕ) (V : α → List Bool → Bool) (x : α) : ℕ :=
  (Finset.univ.filter (fun c : Fin (p (size x)) → Bool => V x (List.ofFn c) = true)).card

/-- Counting decides: for any verifier `V` and any fixed polynomial `p` bounding the certificate
length, an input `x` has a solution (some certificate of length `p(n)` that `V` accepts) exactly
when the count `#V(x)` is at least 1. -/
theorem has_solution_iff_one_le_count {α : Type*} (size : α → ℕ) (p : Polynomial ℕ)
    (V : α → List Bool → Bool) (x : α) :
    (∃ c : Fin (p.eval (size x)) → Bool, V x (List.ofFn c) = true) ↔
      1 ≤ sharpV size (fun n => p.eval n) V x := by
  unfold sharpV
  rw [Finset.one_le_card, Finset.filter_nonempty_iff]
  simp

/-- Certificates of bounded length keep the count finite: `#V(x)` is at most `2 ^ p(n)`. -/
theorem count_le_two_pow {α : Type*} (size : α → ℕ) (p : Polynomial ℕ)
    (V : α → List Bool → Bool) (x : α) :
    sharpV size (fun n => p.eval n) V x ≤ 2 ^ p.eval (size x) := by
  unfold sharpV
  refine (Finset.card_filter_le _ _).trans ?_
  simp

/-! The floor. Squares are `(row, column)`. The neighbouring pairs are listed flat ones first
(`(r, c)` with `(r, c + 1)`), then upright ones (`(r, c)` with `(r + 1, c)`). A certificate has one
bit per pair, and the verifier accepts when every square lies in exactly one chosen pair. -/

/-- The neighbouring pairs of a floor `rows` squares wide and `cols` squares long. -/
def pairs (rows cols : ℕ) : List ((ℕ × ℕ) × (ℕ × ℕ)) :=
  (List.range rows).flatMap (fun r => (List.range (cols - 1)).map fun c => ((r, c), (r, c + 1))) ++
  (List.range (rows - 1)).flatMap (fun r => (List.range cols).map fun c => ((r, c), (r + 1, c)))

/-- The floor's verifier V: one bit per pair, and every square covered by exactly one chosen pair. -/
def tilingV (f : ℕ × ℕ) (c : List Bool) : Bool :=
  c.length == (pairs f.1 f.2).length &&
  (List.range f.1).all fun r => (List.range f.2).all fun col =>
    (((pairs f.1 f.2).zip c).filter
      (fun e => e.2 && (e.1.1 == (r, col) || e.1.2 == (r, col)))).length == 1

/-- The floor is described by its list of neighbouring pairs; one certificate bit per pair. -/
def floorSize (f : ℕ × ℕ) : ℕ := (pairs f.1 f.2).length

/-- The certificate for a list of dominoes: bit 1 exactly on the pairs the dominoes cover. -/
def bitsOf (f : ℕ × ℕ) (ds : List ((ℕ × ℕ) × (ℕ × ℕ))) : List Bool :=
  (pairs f.1 f.2).map fun e => ds.contains e

/-- All twelve dominoes flat, three to a row. -/
def allFlat : List ((ℕ × ℕ) × (ℕ × ℕ)) :=
  (List.range 4).flatMap fun r => [0, 2, 4].map fun c => ((r, c), (r, c + 1))

/-- The brick pattern of the figure: six upright dominoes cross the middle line. -/
def brick : List ((ℕ × ℕ) × (ℕ × ℕ)) :=
  [0, 2, 4].flatMap fun c =>
    [((0, c), (0, c + 1)), ((1, c), (2, c)), ((1, c + 1), (2, c + 1)), ((3, c), (3, c + 1))]

/-- The brick pattern with its first domino moved onto squares already covered. -/
def moved : List ((ℕ × ℕ) × (ℕ × ℕ)) := ((1, 0), (1, 1)) :: brick.tail

-- The 4 by 6 floor: 24 squares, 38 neighbouring pairs, so 38 certificate bits.
example : (pairs 4 6).length = 38 := by decide
-- The checker V accepts all-flat and brick, and rejects brick less one domino and one moved.
example : tilingV (4, 6) (bitsOf (4, 6) allFlat) = true := by decide
example : tilingV (4, 6) (bitsOf (4, 6) brick) = true := by decide
example : tilingV (4, 6) (bitsOf (4, 6) brick.tail) = false := by decide
example : tilingV (4, 6) (bitsOf (4, 6) moved) = false := by decide
-- The 4 by 2 floor has 5 tilings: #V counts 5 of its 2 ^ 10 certificates.
example : (pairs 4 2).length = 10 := by decide
example : sharpV floorSize id tilingV (4, 2) = 5 := by decide +kernel
-- Worked numbers: two 2 by 6 halves give 13 x 13 = 169; 281 - 169 = 112 cross the middle;
-- twelve free flat-or-upright choices would give 2 ^ 12 = 4096; there are 2 ^ 4 = 16 column states.
example : 13 * 13 = 169 := by norm_num
example : 281 - 169 = 112 := by norm_num
example : 2 ^ 12 = 4096 := by norm_num
example : 2 ^ 4 = 16 := by norm_num

/-! The two-bit adder, built from AND, OR and NOT only. Its 4 input bits `a1 a0 b1 b0` are the
certificate, and the verifier runs the gates and accepts when the sum is the target. -/

/-- XOR from AND, OR and NOT: `(x OR y) AND NOT (x AND y)`. -/
def xorG (x y : Bool) : Bool := (x || y) && !(x && y)

/-- The adder's three output bits as a number: carry out, then bit 1, then bit 0. -/
def adder (a1 a0 b1 b0 : Bool) : ℕ :=
  let t := xorG a1 b1
  let c0 := a0 && b0
  4 * ((a1 && b1) || (t && c0)).toNat + 2 * (xorG t c0).toNat + (xorG a0 b0).toNat

/-- The adder's verifier: read the 4 input bits and accept when the gates output `s`. -/
def adderV (s : ℕ) (c : List Bool) : Bool :=
  match c with
  | [a1, a0, b1, b0] => adder a1 a0 b1 b0 == s
  | _ => false

-- 4 of the 16 input settings give the sum 3: 0 + 3, 1 + 2, 2 + 1, 3 + 0.
example : sharpV (fun _ => 0) (fun _ => 4) adderV 3 = 4 := by decide
-- For every sum from 0 to 6, the count by the gates equals the count of a + b = s.
example : ∀ s : Fin 7, sharpV (fun _ => 0) (fun _ => 4) adderV s.val =
    (Finset.univ.filter (fun ab : Fin 4 × Fin 4 => ab.1.val + ab.2.val = s.val)).card := by
  decide

#print axioms has_solution_iff_one_le_count
#print axioms count_le_two_pow
