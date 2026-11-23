-- P and NP: a sudoku puzzle of any side k = m·m can be completed exactly when some filled grid passes the checker, any verifier-defined problem is decided by searching all 2^(N+1) − 1 certificates of length at most N, and the card's 4 by 4 puzzle has exactly one completion while its no-instance has none.
import Mathlib.Logic.Equiv.Fin.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Data.Fintype.BigOperators

namespace PAndNP

/-! ### Sudoku of side k = m · m

A cell is a row and a column in `Fin (m * m)`. A digit is an element of `Fin (m * m)`;
the digit written d on the card (1 to k) is stored as d − 1. A puzzle gives some cells
(`some d`) and leaves the rest blank (`none`). The box of a cell is found by splitting its row
and column with `finProdFinEquiv : Fin m × Fin m ≃ Fin (m * m)`, which sends (a, i) to m·a + i:
a picks the band of boxes, i the place inside it. -/

/-- A filled grid: a digit in every cell. This is the certificate c, k² cells long. -/
abbrev Grid (m : ℕ) := Fin (m * m) → Fin (m * m) → Fin (m * m)

/-- A puzzle: a given digit or a blank in every cell. This is the input x. -/
abbrev Puzzle (m : ℕ) := Fin (m * m) → Fin (m * m) → Option (Fin (m * m))

/-- The digits of box (a, b), read cell by cell. -/
def box {m : ℕ} (c : Grid m) (a b : Fin m) : Fin m × Fin m → Fin (m * m) :=
  fun p => c (finProdFinEquiv (a, p.1)) (finProdFinEquiv (b, p.2))

/-- The sudoku rule: every row, every column and every box holds each digit exactly once. -/
def IsLegal {m : ℕ} (c : Grid m) : Prop :=
  (∀ r, Function.Bijective (c r)) ∧
  (∀ j, Function.Bijective (fun r => c r j)) ∧
  (∀ a b, Function.Bijective (box c a b))

/-- The grid agrees with every given of the puzzle. -/
def Agrees {m : ℕ} (x : Puzzle m) (c : Grid m) : Prop :=
  ∀ r j d, x r j = some d → c r j = d

instance {m : ℕ} (x : Puzzle m) (c : Grid m) : Decidable (Agrees x c) := by
  unfold Agrees; infer_instance

/-- A legal completion of the puzzle. -/
def IsCompletion {m : ℕ} (x : Puzzle m) (c : Grid m) : Prop :=
  Agrees x c ∧ IsLegal c

/-- SUDOKU: the yes-or-no problem "can this puzzle be completed at all?", as the set of
puzzles whose answer is yes. -/
def SUDOKU (m : ℕ) : Set (Puzzle m) := {x | ∃ c, IsCompletion x c}

/-- The card's verifier V(x, c). Pass 1 compares each cell with the given, where there is one.
Pass 2 reads each of the 3k groups and ticks its digits off a list, rejecting on a repeat:
it checks only that no digit appears twice in a group. -/
def verify {m : ℕ} (x : Puzzle m) (c : Grid m) : Bool :=
  decide (Agrees x c) &&
  decide (∀ r, Function.Injective (c r)) &&
  decide (∀ j, Function.Injective (fun r => c r j)) &&
  decide (∀ a b, Function.Injective (box c a b))

/-- Step 2 of the card: SUDOKU has the form NP asks for, with the filled grid as certificate and
the tick-list checker as verifier. Both halves hold for every grid c: the verifier accepts c
exactly when c is a legal completion of x (so a completion is a certificate it accepts, and
anything it accepts is a completion). Hence a puzzle is a yes exactly when some certificate makes
the verifier accept. -/
theorem sudoku_yes_iff_some_certificate_accepted (m : ℕ) (x : Puzzle m) :
    (∀ c : Grid m, verify x c = true ↔ IsCompletion x c) ∧
    (x ∈ SUDOKU m ↔ ∃ c : Grid m, verify x c = true) := by
  have key : ∀ c : Grid m, verify x c = true ↔ IsCompletion x c := by
    intro c
    have hbox : ∀ a b, Function.Injective (box c a b) ↔ Function.Bijective (box c a b) := by
      intro a b
      rw [Fintype.bijective_iff_injective_and_card]
      simp [Fintype.card_prod, Fintype.card_fin]
    simp only [verify, IsCompletion, IsLegal, Bool.and_eq_true, decide_eq_true_eq]
    simp only [← Finite.injective_iff_bijective, ← hbox, and_assoc]
  refine ⟨key, ?_⟩
  show (∃ c, IsCompletion x c) ↔ _
  simp only [key]

/-! ### Step 4: a verifier gives an exponential search -/

/-- Every string of bits of length at most N. -/
def certificates (N : ℕ) : Finset (List Bool) :=
  (Finset.range (N + 1)).biUnion fun n =>
    (Finset.univ : Finset (Fin n → Bool)).image List.ofFn

/-- Step 4 of the card (NP sits inside EXP): if a problem's yes-inputs are exactly those with
some certificate of at most |x|^d bits that the verifier accepts, then running the verifier on
every bit string of length at most |x|^d decides the problem, and there are 2^(|x|^d + 1) − 1
such strings, so the search is exponential in a power of n. -/
theorem verifier_problem_decided_by_search (L : Set (List Bool))
    (V : List Bool → List Bool → Bool) (d : ℕ)
    (hL : ∀ x, x ∈ L ↔ ∃ c : List Bool, c.length ≤ x.length ^ d ∧ V x c = true)
    (x : List Bool) :
    (x ∈ L ↔ ∃ c ∈ certificates (x.length ^ d), V x c = true) ∧
    (certificates (x.length ^ d)).card = 2 ^ (x.length ^ d + 1) - 1 := by
  have mem : ∀ N (c : List Bool), c ∈ certificates N ↔ c.length ≤ N := by
    intro N c
    simp only [certificates, Finset.mem_biUnion, Finset.mem_range, Finset.mem_image,
      Finset.mem_univ, true_and]
    constructor
    · rintro ⟨n, hn, f, rfl⟩
      simp only [List.length_ofFn]
      omega
    · intro h
      exact ⟨c.length, by omega, c.get, List.ofFn_get c⟩
  have geom : ∀ N : ℕ, (Finset.range (N + 1)).sum (fun n => 2 ^ n) = 2 ^ (N + 1) - 1 := by
    intro N
    induction N with
    | zero => simp
    | succ k ih =>
      rw [Finset.sum_range_succ, ih, pow_succ 2 (k + 1)]
      have : 1 ≤ 2 ^ (k + 1) := Nat.one_le_two_pow
      omega
  refine ⟨?_, ?_⟩
  · rw [hL x]
    constructor
    · rintro ⟨c, hc, hv⟩
      exact ⟨c, (mem _ c).2 hc, hv⟩
    · rintro ⟨c, hc, hv⟩
      exact ⟨c, (mem _ c).1 hc, hv⟩
  · rw [certificates, Finset.card_biUnion]
    · have : ∀ n ∈ Finset.range (x.length ^ d + 1),
          ((Finset.univ : Finset (Fin n → Bool)).image List.ofFn).card = 2 ^ n := by
        intro n _
        rw [Finset.card_image_of_injective _ List.ofFn_injective]
        simp
      rw [Finset.sum_congr rfl this, geom]
    · intro i _ j _ hij
      simp only [Function.onFun]
      rw [Finset.disjoint_left]
      intro l hi hj
      simp only [Finset.mem_image, Finset.mem_univ, true_and] at hi hj
      obtain ⟨f, rfl⟩ := hi
      obtain ⟨g, hg⟩ := hj
      have := congrArg List.length hg
      simp only [List.length_ofFn] at this
      exact hij this.symm

/-! ### The card's 4 by 4 puzzle -/

/-- The digit written d (1 to 4) on the card, stored as d − 1. -/
def dig (d : ℕ) : Fin (2 * 2) := ⟨(d + 3) % 4, Nat.mod_lt _ (by norm_num)⟩

/-- A card row of digits, 0 for a blank. -/
def given (d : ℕ) : Option (Fin (2 * 2)) := if d = 0 then none else some (dig d)

/-- The puzzle 1.3. / .41. / 2..3 / .3.1 -/
def puzzle : Puzzle 2 := fun r j =>
  given (![![1, 0, 3, 0], ![0, 4, 1, 0], ![2, 0, 0, 3], ![0, 3, 0, 1]] r j)

/-- The no-instance 1.3. / .41. / 2..3 / .3.2: the last given changed from 1 to 2. -/
def broken : Puzzle 2 := fun r j =>
  given (![![1, 0, 3, 0], ![0, 4, 1, 0], ![2, 0, 0, 3], ![0, 3, 0, 2]] r j)

/-- The completion 1234 / 3412 / 2143 / 4321. -/
def solution : Grid 2 := fun r j =>
  dig (![![1, 2, 3, 4], ![3, 4, 1, 2], ![2, 1, 4, 3], ![4, 3, 2, 1]] r j)

/-- The solution with its cells in row 1, columns 2 and 3, swapped: 1324 / 3412 / 2143 / 4321. -/
def swapped : Grid 2 := fun r j =>
  dig (![![1, 3, 2, 4], ![3, 4, 1, 2], ![2, 1, 4, 3], ![4, 3, 2, 1]] r j)

/-- The card's worked result: blind search, backtracking and the list of all 288 grids agree that
the 4 by 4 puzzle has exactly one completion, 1234 / 3412 / 2143 / 4321, and that the
no-instance has none. -/
theorem card_puzzle_unique_and_broken_none :
    (∀ c : Grid 2, IsCompletion puzzle c ↔ c = solution) ∧ broken ∉ SUDOKU 2 := by
  refine ⟨fun c => ⟨fun ⟨hag, hr, hc, _⟩ => ?_, fun h => ?_⟩, ?_⟩
  · have r := fun i => (hr i).1
    have k := fun j => (hc j).1
    have h00 : c 0 0 = 0 := hag 0 0 _ rfl
    have h02 : c 0 2 = 2 := hag 0 2 _ rfl
    have h11 : c 1 1 = 3 := hag 1 1 _ rfl
    have h12 : c 1 2 = 0 := hag 1 2 _ rfl
    have h20 : c 2 0 = 1 := hag 2 0 _ rfl
    have h23 : c 2 3 = 2 := hag 2 3 _ rfl
    have h31 : c 3 1 = 2 := hag 3 1 _ rfl
    have h33 : c 3 3 = 0 := hag 3 3 _ rfl
    have h01 : c 0 1 = 1 := by
      have a1 : c 0 1 ≠ c 0 0 := (r 0).ne (by decide)
      have a2 : c 0 1 ≠ c 0 2 := (r 0).ne (by decide)
      have a3 : c 0 1 ≠ c 1 1 := (k 1).ne (by decide)
      rw [h00] at a1; rw [h02] at a2; rw [h11] at a3
      revert a1 a2 a3; generalize c 0 1 = v; revert v; decide
    have h03 : c 0 3 = 3 := by
      have a1 : c 0 3 ≠ c 0 0 := (r 0).ne (by decide)
      have a2 : c 0 3 ≠ c 0 1 := (r 0).ne (by decide)
      have a3 : c 0 3 ≠ c 0 2 := (r 0).ne (by decide)
      rw [h00] at a1; rw [h01] at a2; rw [h02] at a3
      revert a1 a2 a3; generalize c 0 3 = v; revert v; decide
    have h10 : c 1 0 = 2 := by
      have a1 : c 1 0 ≠ c 1 1 := (r 1).ne (by decide)
      have a2 : c 1 0 ≠ c 1 2 := (r 1).ne (by decide)
      have a3 : c 1 0 ≠ c 2 0 := (k 0).ne (by decide)
      rw [h11] at a1; rw [h12] at a2; rw [h20] at a3
      revert a1 a2 a3; generalize c 1 0 = v; revert v; decide
    have h13 : c 1 3 = 1 := by
      have a1 : c 1 3 ≠ c 1 0 := (r 1).ne (by decide)
      have a2 : c 1 3 ≠ c 1 1 := (r 1).ne (by decide)
      have a3 : c 1 3 ≠ c 1 2 := (r 1).ne (by decide)
      rw [h10] at a1; rw [h11] at a2; rw [h12] at a3
      revert a1 a2 a3; generalize c 1 3 = v; revert v; decide
    have h21 : c 2 1 = 0 := by
      have a1 : c 2 1 ≠ c 0 1 := (k 1).ne (by decide)
      have a2 : c 2 1 ≠ c 1 1 := (k 1).ne (by decide)
      have a3 : c 2 1 ≠ c 3 1 := (k 1).ne (by decide)
      rw [h01] at a1; rw [h11] at a2; rw [h31] at a3
      revert a1 a2 a3; generalize c 2 1 = v; revert v; decide
    have h22 : c 2 2 = 3 := by
      have a1 : c 2 2 ≠ c 2 0 := (r 2).ne (by decide)
      have a2 : c 2 2 ≠ c 2 1 := (r 2).ne (by decide)
      have a3 : c 2 2 ≠ c 2 3 := (r 2).ne (by decide)
      rw [h20] at a1; rw [h21] at a2; rw [h23] at a3
      revert a1 a2 a3; generalize c 2 2 = v; revert v; decide
    have h30 : c 3 0 = 3 := by
      have a1 : c 3 0 ≠ c 0 0 := (k 0).ne (by decide)
      have a2 : c 3 0 ≠ c 1 0 := (k 0).ne (by decide)
      have a3 : c 3 0 ≠ c 2 0 := (k 0).ne (by decide)
      rw [h00] at a1; rw [h10] at a2; rw [h20] at a3
      revert a1 a2 a3; generalize c 3 0 = v; revert v; decide
    have h32 : c 3 2 = 1 := by
      have a1 : c 3 2 ≠ c 3 0 := (r 3).ne (by decide)
      have a2 : c 3 2 ≠ c 3 1 := (r 3).ne (by decide)
      have a3 : c 3 2 ≠ c 3 3 := (r 3).ne (by decide)
      rw [h30] at a1; rw [h31] at a2; rw [h33] at a3
      revert a1 a2 a3; generalize c 3 2 = v; revert v; decide
    funext i j
    fin_cases i <;> fin_cases j <;> assumption
  · subst h
    exact ((sudoku_yes_iff_some_certificate_accepted 2 puzzle).1 solution).1 (by decide)
  · rintro ⟨c, hag, hr, hc, _⟩
    have r := fun i => (hr i).1
    have k := fun j => (hc j).1
    have h00 : c 0 0 = 0 := hag 0 0 _ rfl
    have h02 : c 0 2 = 2 := hag 0 2 _ rfl
    have h11 : c 1 1 = 3 := hag 1 1 _ rfl
    have h12 : c 1 2 = 0 := hag 1 2 _ rfl
    have h20 : c 2 0 = 1 := hag 2 0 _ rfl
    have h33 : c 3 3 = 1 := hag 3 3 _ rfl
    have h01 : c 0 1 = 1 := by
      have a1 : c 0 1 ≠ c 0 0 := (r 0).ne (by decide)
      have a2 : c 0 1 ≠ c 0 2 := (r 0).ne (by decide)
      have a3 : c 0 1 ≠ c 1 1 := (k 1).ne (by decide)
      rw [h00] at a1; rw [h02] at a2; rw [h11] at a3
      revert a1 a2 a3; generalize c 0 1 = v; revert v; decide
    have h10 : c 1 0 = 2 := by
      have a1 : c 1 0 ≠ c 1 1 := (r 1).ne (by decide)
      have a2 : c 1 0 ≠ c 1 2 := (r 1).ne (by decide)
      have a3 : c 1 0 ≠ c 2 0 := (k 0).ne (by decide)
      rw [h11] at a1; rw [h12] at a2; rw [h20] at a3
      revert a1 a2 a3; generalize c 1 0 = v; revert v; decide
    have h13 : c 1 3 = 1 := by
      have a1 : c 1 3 ≠ c 1 0 := (r 1).ne (by decide)
      have a2 : c 1 3 ≠ c 1 1 := (r 1).ne (by decide)
      have a3 : c 1 3 ≠ c 1 2 := (r 1).ne (by decide)
      rw [h10] at a1; rw [h11] at a2; rw [h12] at a3
      revert a1 a2 a3; generalize c 1 3 = v; revert v; decide
    have : c 1 3 ≠ c 3 3 := (k 3).ne (by decide)
    rw [h13, h33] at this
    exact this rfl

-- The verifier accepts the solution and rejects it with two cells swapped.
example : verify puzzle solution = true := by decide
example : verify puzzle swapped = false := by decide
-- The puzzle has 8 givens, so 8 blanks; n = 16 cells × 3 bits = 48.
example : ((List.finRange 4).flatMap fun r => (List.finRange 4).filter fun j =>
    (puzzle r j).isSome).length = 8 := by decide
example : 16 * 3 = 48 ∧ 16 - 8 = 8 := by norm_num
-- The verifier's reads: 16 for the givens plus 12 groups × 4 cells = 64 = 4 · 4².
example : 16 + 12 * 4 = 64 ∧ 4 * 4 ^ 2 = 64 := by norm_num
-- Blind search: 4^8 = 65,536 fillings at 64 reads each, 4,194,304 reads.
example : 4 ^ 8 = 65536 ∧ 65536 * 64 = 4194304 := by norm_num
-- The guessing machine: 65,536 branches of 8 guesses + 64 reads = 72 moves.
example : 8 + 64 = 72 := by norm_num
-- Rows-only verifier: each row has 2 blanks, so 2! · 2! · 2! · 2! = 16 fillings pass.
example : Nat.factorial 2 * Nat.factorial 2 * Nat.factorial 2 * Nat.factorial 2 = 16 := by decide
-- Listing every failed filling of the no-instance: 65,536 × 16 = 1,048,576 digits.
example : 65536 * 16 = 1048576 := by norm_num
-- The scale table: cells k², n = k² · bits per cell, 3k groups, 4k² reads.
example : 9 * 9 = 81 ∧ 81 * 4 = 324 ∧ 3 * 9 = 27 ∧ 4 * 9 ^ 2 = 324 := by norm_num
example : 16 * 16 = 256 ∧ 256 * 5 = 1280 ∧ 3 * 16 = 48 ∧ 4 * 16 ^ 2 = 1024 := by norm_num
example : 25 * 25 = 625 ∧ 625 * 5 = 3125 ∧ 3 * 25 = 75 ∧ 4 * 25 ^ 2 = 2500 := by norm_num
-- A 9 by 9 with 17 givens: 64 blanks, and 9^64 rounds to 1.18 × 10^61.
example : 81 - 17 = 64 := by norm_num
example : 1175 * 10 ^ 58 ≤ 9 ^ 64 ∧ 9 ^ 64 < 1185 * 10 ^ 58 := by norm_num
-- 9^64 has 62 digits.
example : 10 ^ 61 ≤ 9 ^ 64 ∧ 9 ^ 64 < 10 ^ 62 := by norm_num

#print axioms sudoku_yes_iff_some_certificate_accepted
#print axioms verifier_problem_decided_by_search
#print axioms card_puzzle_unique_and_broken_none

end PAndNP
