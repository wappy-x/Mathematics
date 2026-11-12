-- Irrational numbers: no fraction multiplied by itself gives 2, and a fraction's decimal always stops or repeats, so a decimal that does neither is irrational.
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

/-- The digit in place `n + 1` after the decimal point of `x` (place 1 is the first digit
after the point): the last digit of the whole part of `x × 10^(n+1)`. -/
noncomputable def decimalDigit (x : ℝ) (n : ℕ) : ℤ := ⌊x * 10 ^ (n + 1)⌋ % 10

/-- Root 2 is not a fraction: any number that gives 2 when multiplied by itself is
irrational, that is, it is not a ratio of two whole numbers. -/
theorem root_two_is_not_a_fraction (x : ℝ) (hx : x * x = 2) : Irrational x := by
  refine irrational_nrt_of_notint_nrt 2 2 (by rw [sq, hx]; norm_num) ?_ two_pos
  rintro ⟨y, rfl⟩
  have h : y * y = 2 := by exact_mod_cast hx
  have h1 : |y| * |y| = 2 := by rw [← abs_mul, h]; norm_num
  have h0 : 0 ≤ |y| := abs_nonneg y
  rcases le_or_gt |y| 1 with h2 | h2
  · nlinarith
  · have : 2 ≤ |y| := by omega
    nlinarith

/-- A fraction's decimal always stops or falls into a repeating block: for every fraction q,
either from some place on every digit is 0, or from some place on a block of k ≥ 1 digits
comes back forever. -/
theorem fraction_decimal_stops_or_repeats (q : ℚ) :
    (∃ N : ℕ, ∀ n ≥ N, decimalDigit q n = 0) ∨
      (∃ N k : ℕ, 0 < k ∧ ∀ n ≥ N, decimalDigit q (n + k) = decimalDigit q n) := by
  right
  obtain ⟨N, M, hNM, hEq⟩ := (Set.finite_Ico (0 : ℤ) q.den).exists_lt_map_eq_of_forall_mem
    (f := fun n : ℕ => q.num * 10 ^ n % (q.den : ℤ)) (fun n => by
      have hd : (0 : ℤ) < q.den := by exact_mod_cast q.den_pos
      exact ⟨Int.emod_nonneg _ hd.ne', Int.emod_lt_of_pos _ hd⟩)
  have hdvd : (q.den : ℤ) ∣ q.num * 10 ^ M - q.num * 10 ^ N := Int.ModEq.dvd hEq
  obtain ⟨z, hz⟩ := hdvd
  have hzq : (q : ℝ) * 10 ^ M - (q : ℝ) * 10 ^ N = z := by
    have hq : (q : ℚ) * 10 ^ M - q * 10 ^ N = z := by
      have hden : (q.den : ℚ) ≠ 0 := by exact_mod_cast q.den_ne_zero
      have hz' : ((q.num * 10 ^ M - q.num * 10 ^ N : ℤ) : ℚ) = (q.den : ℚ) * z := by
        rw [hz]; push_cast; ring
      rw [← Rat.num_div_den q]
      field_simp
      push_cast at hz'
      linear_combination hz'
    have h := congrArg (fun r : ℚ => (r : ℝ)) hq
    push_cast at h
    exact h
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_lt hNM
  refine ⟨N, k + 1, Nat.succ_pos k, fun n hn => ?_⟩
  obtain ⟨e, rfl⟩ := Nat.exists_eq_add_of_le hn
  unfold decimalDigit
  have key : (q : ℝ) * 10 ^ (N + e + (k + 1) + 1) =
      (q : ℝ) * 10 ^ (N + e + 1) + ((10 * (10 ^ e * z) : ℤ) : ℝ) := by
    push_cast
    have : (q : ℝ) * 10 ^ (N + e + (k + 1) + 1) - (q : ℝ) * 10 ^ (N + e + 1)
        = 10 ^ (e + 1) * ((q : ℝ) * 10 ^ (N + k + 1) - (q : ℝ) * 10 ^ N) := by ring
    rw [hzq] at this
    linear_combination this
  rw [key, Int.floor_add_intCast, Int.add_mul_emod_self_left]

/-- So a decimal that neither stops nor repeats belongs to no fraction: the number is
irrational. -/
theorem non_repeating_decimal_is_irrational (x : ℝ)
    (h_stops : ¬ ∃ N : ℕ, ∀ n ≥ N, decimalDigit x n = 0)
    (h_repeats : ¬ ∃ N k : ℕ, 0 < k ∧ ∀ n ≥ N, decimalDigit x (n + k) = decimalDigit x n) :
    Irrational x := by
  rintro ⟨q, rfl⟩
  rcases fraction_decimal_stops_or_repeats q with h | h
  · exact h_stops h
  · exact h_repeats h

-- The tile in millimetres: the square on the diagonal is 2 × 1000 × 1000 = 2000000.
example : 2 * 1000 * 1000 = 2000000 := by norm_num
-- The 1414 mark squares to 1999396, 604 short; the 1415 mark squares to 2002225, 2225 over.
example : 1414 * 1414 = 1999396 ∧ 1415 * 1415 = 2002225 := by norm_num
example : 2000000 - 1414 * 1414 = 604 ∧ 1415 * 1415 - 2000000 = 2225 := by norm_num
example : 1414 * 1414 < 2 * 1000 * 1000 ∧ 2 * 1000 * 1000 < 1415 * 1415 := by norm_num
-- Root 2 to eight places, 1.41421356: 141421356 squared stays under 2 × 10^16, one more goes over.
example : 141421356 ^ 2 ≤ 2 * 10 ^ 16 ∧ 2 * 10 ^ 16 < 141421357 ^ 2 := by norm_num
-- The near misses: 7 × 7 = 49 against 2 × 5 × 5 = 50; 99 × 99 = 9801 against 2 × 70 × 70 = 9800.
example : 7 * 7 = 49 ∧ 2 * 5 * 5 = 50 ∧ 99 * 99 = 9801 ∧ 2 * 70 * 70 = 9800 := by norm_num
example : 99 * 99 - 2 * 70 * 70 = 1 := by norm_num
-- Five elevenths by long division: digits 4 5 4 5 4 5 4 5, remainders 6 5 6 5 6 5 6 5.
example : (List.range 8).map (fun n => 5 * 10 ^ (n + 1) / 11 % 10) = [4, 5, 4, 5, 4, 5, 4, 5] := by
  decide
example : (List.range 8).map (fun n => 5 * 10 ^ (n + 1) % 11) = [6, 5, 6, 5, 6, 5, 6, 5] := by
  decide
-- Shift and subtract: 100 copies of 5/11 take away one copy leaves 45, so it is 45/99 = 5/11.
example : (100 : ℚ) * (5 / 11) - 5 / 11 = 45 := by norm_num
example : (45 : ℚ) / 99 = 5 / 11 := by norm_num
example : Nat.gcd 45 99 = 9 ∧ 45 / 9 = 5 ∧ 99 / 9 = 11 := by decide
-- Try changing: a tape ten times finer, marks 14142 short and 14143 over.
example : 14142 * 14142 < 2 * 10000 * 10000 ∧ 2 * 10000 * 10000 < 14143 * 14143 := by norm_num
-- Try changing: divide 5 by 8 and a remainder hits zero, so the decimal stops at 0.625.
example : (List.range 3).map (fun n => 5 * 10 ^ (n + 1) / 8 % 10) = [6, 2, 5] ∧
    5 * 10 ^ 3 % 8 = 0 := by decide
-- A4 paper: 297 by 210 mm is 99/70.
example : (297 : ℚ) / 210 = 99 / 70 := by norm_num

#print axioms root_two_is_not_a_fraction
#print axioms fraction_decimal_stops_or_repeats
#print axioms non_repeating_decimal_is_irrational
