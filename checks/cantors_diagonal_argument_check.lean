-- Cantor's diagonal: every list of real numbers, one per counting number, misses a real between 0 and 1, the 4-or-5 diagonal number is one it misses, and so the reals are a strictly bigger infinity than the counting numbers.
import Mathlib.Analysis.Real.Cardinality
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Data.Rat.Floor

/-- The decimal digit of `x` in place `n + 1` after the point (place one is `n = 0`):
shift the point `n + 1` places right, drop what is behind it, and keep the last digit. -/
noncomputable def decimalDigit (x : ℝ) (n : ℕ) : ℤ := ⌊x * 10 ^ (n + 1)⌋ % 10

/-- Tail sum of the digit list `d` from place `n`. -/
noncomputable def tailSum (d : ℕ → ℤ) (n : ℕ) : ℝ := ∑' j, (d (n + j) : ℝ) / 10 ^ (j + 1)

lemma geom_summable : Summable (fun j : ℕ => (1 / 10 : ℝ) ^ j) :=
  summable_geometric_of_lt_one (by norm_num) (by norm_num)

lemma geom_sum : ∑' j : ℕ, (1 / 10 : ℝ) ^ j = 10 / 9 := by
  rw [tsum_geometric_of_lt_one (by norm_num) (by norm_num)]; norm_num

lemma term_eq (c : ℝ) (j : ℕ) : c / 10 ^ (j + 1) = (c / 10) * (1 / 10 : ℝ) ^ j := by
  rw [one_div, inv_pow, pow_succ]; field_simp

lemma tail_summable (d : ℕ → ℤ) (hd : ∀ n, d n = 4 ∨ d n = 5) (n : ℕ) :
    Summable (fun j : ℕ => (d (n + j) : ℝ) / 10 ^ (j + 1)) := by
  refine Summable.of_nonneg_of_le (fun j => ?_) (fun j => ?_)
    ((geom_summable.mul_left (5 / 10 : ℝ)))
  · have : (0 : ℝ) ≤ d (n + j) := by rcases hd (n + j) with h | h <;> simp [h] <;> norm_num
    positivity
  · rw [term_eq]
    have : (d (n + j) : ℝ) ≤ 5 := by rcases hd (n + j) with h | h <;> simp [h] <;> norm_num
    have h2 : (0 : ℝ) < (1 / 10) ^ j := by positivity
    nlinarith

lemma tail_bounds (d : ℕ → ℤ) (hd : ∀ n, d n = 4 ∨ d n = 5) (n : ℕ) :
    4 / 9 ≤ tailSum d n ∧ tailSum d n ≤ 5 / 9 := by
  have hs := tail_summable d hd n
  have h4 : ∑' j : ℕ, (4 / 10 : ℝ) * (1 / 10 : ℝ) ^ j = 4 / 9 := by
    rw [tsum_mul_left, geom_sum]; norm_num
  have h5 : ∑' j : ℕ, (5 / 10 : ℝ) * (1 / 10 : ℝ) ^ j = 5 / 9 := by
    rw [tsum_mul_left, geom_sum]; norm_num
  constructor
  · rw [← h4]
    refine Summable.tsum_le_tsum (fun j => ?_) (geom_summable.mul_left _) hs
    rw [term_eq (d (n + j))]
    have : (4 : ℝ) ≤ d (n + j) := by rcases hd (n + j) with h | h <;> simp [h] <;> norm_num
    have h2 : (0 : ℝ) < (1 / 10) ^ j := by positivity
    nlinarith
  · rw [← h5]
    refine Summable.tsum_le_tsum (fun j => ?_) hs (geom_summable.mul_left _)
    rw [term_eq (d (n + j))]
    have : (d (n + j) : ℝ) ≤ 5 := by rcases hd (n + j) with h | h <;> simp [h] <;> norm_num
    have h2 : (0 : ℝ) < (1 / 10) ^ j := by positivity
    nlinarith

lemma tail_rec (d : ℕ → ℤ) (hd : ∀ n, d n = 4 ∨ d n = 5) (n : ℕ) :
    tailSum d n = (d n : ℝ) / 10 + tailSum d (n + 1) / 10 := by
  unfold tailSum
  rw [(tail_summable d hd n).tsum_eq_zero_add]
  congr 1
  · simp
  · rw [← tsum_div_const]
    refine tsum_congr (fun j => ?_)
    rw [show n + (j + 1) = n + 1 + j by ring, div_div, ← pow_succ]

lemma digit_aux (d : ℕ → ℤ) (hd : ∀ n, d n = 4 ∨ d n = 5) (n : ℕ) :
    ∃ N : ℤ, tailSum d 0 * 10 ^ (n + 1) = N + tailSum d (n + 1) ∧ N % 10 = d n := by
  induction n with
  | zero =>
    refine ⟨d 0, ?_, ?_⟩
    · rw [tail_rec d hd 0]; ring
    · rcases hd 0 with h | h <;> simp [h]
  | succ n ih =>
    obtain ⟨N, h1, h2⟩ := ih
    refine ⟨10 * N + d (n + 1), ?_, ?_⟩
    · rw [pow_succ, ← mul_assoc, h1, tail_rec d hd (n + 1)]
      push_cast; ring
    · rcases hd (n + 1) with h | h <;> simp [h]

lemma digit_tail (d : ℕ → ℤ) (hd : ∀ n, d n = 4 ∨ d n = 5) (n : ℕ) :
    decimalDigit (tailSum d 0) n = d n := by
  obtain ⟨N, h1, h2⟩ := digit_aux d hd n
  unfold decimalDigit
  rw [h1]
  have b1 := tail_bounds d hd (n + 1)
  have : ⌊(N : ℝ) + tailSum d (n + 1)⌋ = N := by
    rw [Int.floor_eq_iff]; constructor <;> push_cast <;> linarith [b1.1, b1.2]
  rw [this, h2]

/-- Main diagonal lemma (same statement as `diagonal_number_is_on_no_row`). -/
lemma diag_main (f : ℕ → ℝ) :
    let d : ℕ → ℤ := fun n => if decimalDigit (f n) n = 4 then 5 else 4
    let x : ℝ := ∑' n, (d n : ℝ) / 10 ^ (n + 1)
    x ∈ Set.Ioo (0 : ℝ) 1 ∧ (∀ n, decimalDigit x n = d n) ∧
      (∀ n, decimalDigit x n ≠ decimalDigit (f n) n) ∧ ∀ n, f n ≠ x := by
  intro d x
  have hd : ∀ n, d n = 4 ∨ d n = 5 := by
    intro n; simp only [d]; split_ifs <;> simp
  have hx : x = tailSum d 0 := by simp [x, tailSum]
  have hdig : ∀ n, decimalDigit x n = d n := fun n => by rw [hx]; exact digit_tail d hd n
  have hne : ∀ n, decimalDigit x n ≠ decimalDigit (f n) n := by
    intro n
    rw [hdig n]
    simp only [d]
    split_ifs with h <;> omega
  refine ⟨?_, hdig, hne, fun n hn => hne n (by rw [hn])⟩
  have b := tail_bounds d hd 0
  rw [hx]; constructor <;> linarith [b.1, b.2]

/-- The card's claim: take any list of real numbers, one row for each counting number
(`f 0, f 1, f 2, …`); some real number strictly between 0 and 1 is on no row.
The reals cannot be queued. -/
theorem reals_between_zero_and_one_cannot_be_listed (f : ℕ → ℝ) :
    ∃ x ∈ Set.Ioo (0 : ℝ) 1, ∀ n, f n ≠ x := by
  obtain ⟨hx, -, -, h⟩ := diag_main f
  exact ⟨_, hx, h⟩

/-- The diagonal construction itself: read digit `n + 1` of row `n`, write a 5 where it is a 4
and a 4 everywhere else, and put the changed digits behind a decimal point. The number built
lies between 0 and 1, its digit in each row's own place is the changed digit (a string of 4s and
5s has one spelling), so it disagrees with every row there and equals no row. -/
theorem diagonal_number_is_on_no_row (f : ℕ → ℝ) :
    let d : ℕ → ℤ := fun n => if decimalDigit (f n) n = 4 then 5 else 4
    let x : ℝ := ∑' n, (d n : ℝ) / 10 ^ (n + 1)
    x ∈ Set.Ioo (0 : ℝ) 1 ∧ (∀ n, decimalDigit x n = d n) ∧
      (∀ n, decimalDigit x n ≠ decimalDigit (f n) n) ∧ ∀ n, f n ≠ x := by
  exact diag_main f

/-- The counting numbers are infinite; the reals are a strictly bigger infinity. -/
theorem reals_strictly_bigger_infinity : Cardinal.mk ℕ < Cardinal.mk ℝ := by
  rw [Cardinal.mk_nat, Cardinal.mk_real]
  exact Cardinal.aleph0_lt_continuum

-- The hotel list: 1/7, 1/2, 1/3, 5/9, 1/8 in rooms 1 to 5. Read down the diagonal: 1, 0, 3, 5, 0.
example : (decimalDigit (1 / 7) 0, decimalDigit (1 / 2) 1, decimalDigit (1 / 3) 2,
    decimalDigit (5 / 9) 3, decimalDigit (1 / 8) 4) = (1, 0, 3, 5, 0) := by
  norm_num [decimalDigit]
-- The rooms as whole numbers, first five digits: 14285 50000 33333 55555 12500.
example : (⌊(1 / 7 : ℝ) * 10 ^ 5⌋, ⌊(1 / 2 : ℝ) * 10 ^ 5⌋, ⌊(1 / 3 : ℝ) * 10 ^ 5⌋,
    ⌊(5 / 9 : ℝ) * 10 ^ 5⌋, ⌊(1 / 8 : ℝ) * 10 ^ 5⌋) = (14285, 50000, 33333, 55555, 12500) := by
  norm_num
-- Write 4, or 5 for a 4: no diagonal digit here is a 4, so the rule builds 44444.
example : [1, 0, 3, 5, 0].map (fun d : ℤ => if d = 4 then 5 else 4) = [4, 4, 4, 4, 4] := by
  decide
-- 0.44444… is 4/9: its first five digits are all 4, and each differs from that room's diagonal digit.
example : (decimalDigit (4 / 9) 0, decimalDigit (4 / 9) 1, decimalDigit (4 / 9) 2,
    decimalDigit (4 / 9) 3, decimalDigit (4 / 9) 4) = (4, 4, 4, 4, 4) := by
  norm_num [decimalDigit]
example : decimalDigit (4 / 9) 0 ≠ decimalDigit (1 / 7) 0 ∧ decimalDigit (4 / 9) 1 ≠ decimalDigit (1 / 2) 1 ∧
    decimalDigit (4 / 9) 2 ≠ decimalDigit (1 / 3) 2 ∧ decimalDigit (4 / 9) 3 ≠ decimalDigit (5 / 9) 3 ∧
    decimalDigit (4 / 9) 4 ≠ decimalDigit (1 / 8) 4 := by
  norm_num [decimalDigit]
-- The popular rule, add 1 with 9 coming round to 0, builds 21461, which is none of the five rooms.
example : [1, 0, 3, 5, 0].map (fun d => (d + 1) % 10) = [2, 1, 4, 6, 1] := by decide
example : 21461 ∉ [14285, 50000, 33333, 55555, 12500] := by decide
-- The three mistakes: copying the diagonal gives 10350; adding 1 across room 1 (14285) gives
-- 25396; adding 1 on rows reading 0.4999… gives 50000, the same number in its other spelling.
example : [1, 4, 2, 8, 5].map (fun d => (d + 1) % 10) = [2, 5, 3, 9, 6] := by decide
example : [4, 9, 9, 9, 9].map (fun d => (d + 1) % 10) = [5, 0, 0, 0, 0] := by decide
-- Try changing: swap guests 1 and 5; the diagonal reads 1, 0, 3, 5, 5 and adding 1 gives 21466.
example : (decimalDigit (1 / 8) 0, decimalDigit (1 / 7) 4) = (1, 5) := by norm_num [decimalDigit]
example : [1, 0, 3, 5, 5].map (fun d => (d + 1) % 10) = [2, 1, 4, 6, 6] := by decide

#print axioms reals_between_zero_and_one_cannot_be_listed
#print axioms diagonal_number_is_on_no_row
#print axioms reals_strictly_bigger_infinity
#print axioms geom_summable
#print axioms geom_sum
#print axioms term_eq
#print axioms tail_summable
#print axioms tail_bounds
#print axioms tail_rec
#print axioms digit_aux
#print axioms digit_tail
#print axioms diag_main
