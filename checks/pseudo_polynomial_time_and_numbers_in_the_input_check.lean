-- Pseudo-polynomial time: the knapsack capacity table fills (k + 1)(W + 1) cells, which is at most a polynomial in the input's length and its largest number, but no polynomial in the length alone bounds it.
import Mathlib.Data.Nat.Log
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Order.BigOperators.Group.List
import Mathlib.Algebra.Polynomial.Eval.Degree

open Polynomial

/-- Binary digits needed to write the whole number `x` (at least 1, so 0 takes one digit):
800 takes 10. -/
def bits (x : ℕ) : ℕ := Nat.log 2 x + 1

/-- The input's length `n`: binary digits of every parcel weight, every fee and the van's
capacity `W` (separators left out, as on the card). A parcel is a pair (weight, fee). -/
def inputLength (parcels : List (ℕ × ℕ)) (W : ℕ) : ℕ :=
  (parcels.map fun p => bits p.1 + bits p.2).sum + bits W

/-- `M`, the largest number in the input: the biggest weight, fee or capacity. -/
def maxNumber (parcels : List (ℕ × ℕ)) (W : ℕ) : ℕ :=
  (parcels.map fun p => max p.1 p.2).foldr max W

/-- `T`, the cells the capacity table fills: one row for each of 0, 1, ..., k parcels and one
column for each room 0, 1, ..., W, one comparison per cell. -/
def tableCells (parcels : List (ℕ × ℕ)) (W : ℕ) : ℕ :=
  (parcels.length + 1) * (W + 1)

/-- The capacity table's entry `K(i, c)`: the best fee from the parcels in the list with `c`
units of room, each parcel taken whole or left: the better of leaving the first parcel out or
taking it when it fits. -/
def bestFee : List (ℕ × ℕ) → ℕ → ℕ
  | [], _ => 0
  | (w, v) :: rest, c =>
      if w ≤ c then max (bestFee rest c) (v + bestFee rest (c - w)) else bestFee rest c

theorem lt_two_pow_bits (x : ℕ) : x < 2 ^ bits x :=
  Nat.lt_pow_succ_log_self (by norm_num) x

theorem bits_mul_two_pow (x j : ℕ) (hx : x ≠ 0) : bits (x * 2 ^ j) = bits x + j := by
  induction j with
  | zero => simp
  | succ j ih =>
    have h0 : x * 2 ^ j ≠ 0 := by positivity
    unfold bits at *
    rw [pow_succ, ← mul_assoc, Nat.log_mul_base (by norm_num) h0]
    omega

theorem length_le_inputLength (parcels : List (ℕ × ℕ)) (W : ℕ) :
    parcels.length ≤ inputLength parcels W := by
  induction parcels with
  | nil => simp [inputLength]
  | cons p rest ih =>
    simp only [inputLength, List.map_cons, List.sum_cons, List.length_cons] at *
    have : 1 ≤ bits p.1 := by unfold bits; omega
    omega

theorem le_maxNumber (parcels : List (ℕ × ℕ)) (W : ℕ) : W ≤ maxNumber parcels W := by
  induction parcels with
  | nil => simp [maxNumber]
  | cons p rest ih =>
    simp only [maxNumber, List.map_cons, List.foldr_cons] at *
    omega

theorem maxNumber_lt (parcels : List (ℕ × ℕ)) (W : ℕ) :
    maxNumber parcels W < 2 ^ inputLength parcels W := by
  induction parcels with
  | nil => simpa [maxNumber, inputLength] using lt_two_pow_bits W
  | cons p rest ih =>
    simp only [maxNumber, inputLength, List.map_cons, List.foldr_cons, List.sum_cons] at *
    have h1 := lt_two_pow_bits p.1
    have h2 := lt_two_pow_bits p.2
    set R := (List.map (fun p => bits p.1 + bits p.2) rest).sum
    have e1 : 2 ^ bits p.1 ≤ 2 ^ (bits p.1 + bits p.2 + R + bits W) :=
      Nat.pow_le_pow_right (by norm_num) (by omega)
    have e2 : 2 ^ bits p.2 ≤ 2 ^ (bits p.1 + bits p.2 + R + bits W) :=
      Nat.pow_le_pow_right (by norm_num) (by omega)
    have e3 : 2 ^ (R + bits W) ≤ 2 ^ (bits p.1 + bits p.2 + R + bits W) :=
      Nat.pow_le_pow_right (by norm_num) (by omega)
    omega

theorem eval_le (p : ℕ[X]) (x : ℕ) : p.eval x ≤ p.eval 1 * (x + 1) ^ p.natDegree := by
  rw [eval_eq_sum_range, eval_eq_sum_range, Finset.sum_mul]
  apply Finset.sum_le_sum
  intro i hi
  rw [Finset.mem_range] at hi
  rw [one_pow, mul_one]
  apply Nat.mul_le_mul_left
  calc x ^ i ≤ (x + 1) ^ i := Nat.pow_le_pow_left (by omega) i
    _ ≤ (x + 1) ^ p.natDegree := Nat.pow_le_pow_right (by omega) (by omega)

theorem sq_le_two_pow (s : ℕ) (hs : 4 ≤ s) : s * s ≤ 2 ^ s := by
  induction s, hs using Nat.le_induction with
  | base => norm_num
  | succ s hs ih =>
    rw [pow_succ]
    nlinarith

theorem exists_poly_lt_two_pow (C d : ℕ) : ∃ x : ℕ, C * (x + 2) ^ d < 2 ^ x := by
  obtain ⟨s, hsdef⟩ : ∃ s, s = C + d + 4 := ⟨_, rfl⟩
  refine ⟨2 ^ s, ?_⟩
  have hx : 2 ^ s + 2 ≤ 2 ^ (s + 1) := by
    have e : 2 ^ (s + 1) = 2 ^ s * 2 := pow_succ 2 s
    have : 2 ≤ 2 ^ s := by
      calc 2 = 2 ^ 1 := by norm_num
        _ ≤ 2 ^ s := Nat.pow_le_pow_right (by norm_num) (by omega)
    clear hsdef
    generalize 2 ^ (s + 1) = a at *
    generalize 2 ^ s = b at *
    omega
  have h1 : (2 ^ s + 2) ^ d ≤ 2 ^ ((s + 1) * d) := by
    rw [pow_mul]; exact Nat.pow_le_pow_left hx d
  have h2 : C < 2 ^ C := Nat.lt_two_pow_self
  have h3 : C + (s + 1) * d ≤ 2 ^ s := by
    have := sq_le_two_pow s (by omega)
    nlinarith
  calc C * (2 ^ s + 2) ^ d ≤ C * 2 ^ ((s + 1) * d) := Nat.mul_le_mul_left C h1
    _ < 2 ^ C * 2 ^ ((s + 1) * d) := Nat.mul_lt_mul_of_pos_right h2 (by positivity)
    _ = 2 ^ (C + (s + 1) * d) := by rw [pow_add]
    _ ≤ 2 ^ 2 ^ s := Nat.pow_le_pow_right (by norm_num) h3

#print axioms lt_two_pow_bits
#print axioms bits_mul_two_pow
#print axioms length_le_inputLength
#print axioms le_maxNumber
#print axioms maxNumber_lt
#print axioms eval_le
#print axioms sq_le_two_pow
#print axioms exists_poly_lt_two_pow

/-- Pseudo-polynomial time. For any parcel list and any capacity, the capacity table's cell count
`T = (k + 1)(W + 1)` is at most `(n + 1)(M + 1)`, a polynomial in the input's length `n` and its
largest number `M`; while the largest number can be nearly 2 to the power of the length,
`M < 2 ^ n`. -/
theorem table_cells_pseudo_polynomial (parcels : List (ℕ × ℕ)) (W : ℕ) :
    tableCells parcels W ≤ (inputLength parcels W + 1) * (maxNumber parcels W + 1) ∧
      maxNumber parcels W < 2 ^ inputLength parcels W := by
  refine ⟨?_, maxNumber_lt parcels W⟩
  unfold tableCells
  exact Nat.mul_le_mul (by have := length_le_inputLength parcels W; omega)
    (by have := le_maxNumber parcels W; omega)

/-- The capacity table is not a polynomial-time method: no polynomial `p` bounds its cell count
by the input's length alone, `T ≤ p(n)` for every input. -/
theorem table_cells_not_polynomial :
    ¬ ∃ p : ℕ[X], ∀ (parcels : List (ℕ × ℕ)) (W : ℕ),
      tableCells parcels W ≤ p.eval (inputLength parcels W) := by
  rintro ⟨p, hp⟩
  obtain ⟨x, hx⟩ := exists_poly_lt_two_pow (p.eval 1) p.natDegree
  have h := hp [] (2 ^ x)
  have hb : inputLength [] (2 ^ x) = x + 1 := by
    simp [inputLength, bits, Nat.log_pow (by norm_num : 1 < 2)]
  rw [hb] at h
  have h2 : p.eval (x + 1) ≤ p.eval 1 * (x + 2) ^ p.natDegree := eval_le p (x + 1)
  simp [tableCells] at h
  omega

/-- The van's five parcels at 1 kg (tiles 300 kg £90, timber 400 kg £110, boiler 200 kg £70,
piano 500 kg £150, fridge 100 kg £40; van 800 kg). -/
def van : List (ℕ × ℕ) := [(300, 90), (400, 110), (200, 70), (500, 150), (100, 40)]

/-- The same parcels with every weight doubled `j` times. -/
def vanDoubled (j : ℕ) : List (ℕ × ℕ) := van.map fun p => (p.1 * 2 ^ j, p.2)

/-- Doubling every weight and the van's capacity `j` times adds 6 binary digits per doubling,
`n_j = 87 + 6j`, while the table fills `T_j = 6 (800 · 2^j + 1)` cells, more than `2^j`. -/
theorem van_doubling_length_and_cells (j : ℕ) :
    inputLength (vanDoubled j) (800 * 2 ^ j) = 87 + 6 * j ∧
      tableCells (vanDoubled j) (800 * 2 ^ j) = 6 * (800 * 2 ^ j + 1) ∧
      2 ^ j < tableCells (vanDoubled j) (800 * 2 ^ j) := by
  have hb : ∀ x : ℕ, x ≠ 0 → bits (x * 2 ^ j) = bits x + j := fun x hx => bits_mul_two_pow x j hx
  refine ⟨?_, ?_, ?_⟩
  · simp only [inputLength, vanDoubled, van, List.map_cons, List.map_nil, List.sum_cons,
      List.sum_nil]
    rw [hb 300 (by norm_num), hb 400 (by norm_num), hb 200 (by norm_num), hb 500 (by norm_num),
      hb 100 (by norm_num), hb 800 (by norm_num)]
    have e : bits 300 = 9 ∧ bits 400 = 9 ∧ bits 200 = 8 ∧ bits 500 = 9 ∧ bits 100 = 7 ∧
        bits 800 = 10 ∧ bits 90 = 7 ∧ bits 110 = 7 ∧ bits 70 = 7 ∧ bits 150 = 8 ∧
        bits 40 = 6 := by decide
    omega
  · simp [tableCells, vanDoubled, van]
  · simp only [tableCells, vanDoubled, van, List.length_map, List.length_cons, List.length_nil]
    have := Nat.one_le_two_pow (n := j)
    generalize 2 ^ j = t at *
    omega

-- The van in 100 kg units, in kilograms, and in grams.
def van100 : List (ℕ × ℕ) := van.map fun p => (p.1 / 100, p.2)
def vanGram : List (ℕ × ℕ) := van.map fun p => (p.1 * 1000, p.2)

-- 800 kg takes 10 binary digits.
example : bits 800 = 10 := by decide
-- Lengths 50, 87 and 147 binary digits.
example : inputLength van100 8 = 50 := by decide
example : inputLength van 800 = 87 := by decide
example : inputLength vanGram 800000 = 147 := by decide
-- Cells 54, 4,806 and 4,800,006.
example : tableCells van100 8 = 54 := by decide
example : tableCells van 800 = 4806 := by decide
example : tableCells vanGram 800000 = 4800006 := by decide
-- The best fee is £260 at every unit.
example : bestFee van100 8 = 260 := by decide
example : bestFee van 800 = 260 := by decide
example : bestFee vanGram 800000 = 260 := by decide
-- The capacity table's last row in 100 kg steps.
example : (List.range 9).map (bestFee van100) = [0, 40, 70, 110, 130, 160, 200, 220, 260] := by
  decide
-- One doubling from 1 kg: 93 digits, 9,606 cells.
example : inputLength (vanDoubled 1) 1600 = 93 := by decide
example : tableCells (vanDoubled 1) 1600 = 9606 := by decide
-- 40 doublings: 327 digits, 5,277,655,813,324,806 cells against 327 ^ 3 = 34,965,783.
example : tableCells (vanDoubled 40) (800 * 2 ^ 40) = 5277655813324806 := by decide
example : 327 ^ 3 = 34965783 := by norm_num
-- The table passes n ^ 3 by n = 147 (10 doublings): 4,915,206 cells against 3,176,523.
example : tableCells (vanDoubled 10) (800 * 2 ^ 10) = 4915206 ∧ 147 ^ 3 = 3176523 := by decide
example : tableCells van 800 < 87 ^ 3 := by decide
-- What breaks: true weights 330, 420, 240, 470, 140 kg; the exact best fee is £240.
example : bestFee [(330, 90), (420, 110), (240, 70), (470, 150), (140, 40)] 800 = 240 := by decide
-- Rounded to 100 kg, the table picks boiler + piano + fridge (fee 260 in 8 units), truly 850 kg.
example : bestFee [(3, 90), (4, 110), (2, 70), (5, 150), (1, 40)] 8 = 260 ∧ 240 + 470 + 140 = 850 := by
  decide
-- Ten parcels (each twice) at 1 kg: 8,811 cells, best £270.
example : tableCells (van ++ van) 800 = 8811 := by decide
example : bestFee (van ++ van) 800 = 270 := by decide

#print axioms table_cells_pseudo_polynomial
#print axioms table_cells_not_polynomial
#print axioms van_doubling_length_and_cells
