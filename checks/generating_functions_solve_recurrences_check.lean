-- Solving a recurrence with a generating function: a sequence that obeys a fixed-weight two-step rule has as its series one polynomial over another, with bottom 1 minus each weight on its power of x and top built from the two starting values; when the bottom factors into two different brackets the split gives a closed formula for every term, and the Fibonacci series is x / (1 - x - x^2).
import Mathlib.RingTheory.PowerSeries.Inverse
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp

open PowerSeries

/-- The method's theorem. Take any numbers and a rule with fixed weights c₁ and c₂ and nothing
added: a(n) = c₁ · a(n−1) + c₂ · a(n−2) from n = 2 on. Then the series a(0) + a(1) x + a(2) x² + ⋯
is one polynomial over another: on top a(0) + (a(1) − c₁ · a(0)) x, underneath 1 − c₁ x − c₂ x².
The bottom starts at 1, so the division never stalls. -/
theorem fixed_weight_rule_series_is_ratio_of_polynomials {K : Type*} [Field K]
    (c₁ c₂ : K) (a : ℕ → K) (h : ∀ n, a (n + 2) = c₁ * a (n + 1) + c₂ * a n) :
    mk a = (C (a 0) + C (a 1 - c₁ * a 0) * X) * (1 - C c₁ * X - C c₂ * X ^ 2)⁻¹ := by
  rw [eq_mul_inv_iff_mul_eq (by simp)]
  have e : mk a * (1 - C c₁ * X - C c₂ * X ^ 2)
      = mk a - C c₁ * (mk a * X ^ 1) - C c₂ * (mk a * X ^ 2) := by ring
  rw [e]
  ext n
  rcases n with _ | _ | n
  · simp [coeff_mul_X_pow', coeff_C_mul, coeff_X]
  · simp [coeff_mul_X_pow', coeff_C_mul, coeff_X]
  · simp [coeff_mul_X_pow', coeff_C_mul, coeff_X, h]

/-- Factor and split. If the bottom 1 − c₁ x − c₂ x² is two different brackets (1 − r x)(1 − s x),
with r ≠ s, then splitting the fraction into A / (1 − r x) + B / (1 − s x) and reading off each
geometric piece gives every term: a(n) = A · rⁿ + B · sⁿ, where the two amounts solve the two
equations A + B = a(0) and A r + B s = a(1). -/
theorem split_gives_closed_formula {K : Type*} [Field K]
    (c₁ c₂ r s : K) (a : ℕ → K) (h : ∀ n, a (n + 2) = c₁ * a (n + 1) + c₂ * a n)
    (hfac : (1 - C c₁ * X - C c₂ * X ^ 2 : K⟦X⟧) = (1 - C r * X) * (1 - C s * X))
    (hrs : r ≠ s) :
    ∀ n, a n = (a 1 - s * a 0) / (r - s) * r ^ n + (r * a 0 - a 1) / (r - s) * s ^ n := by
  have e : (1 - C r * X) * (1 - C s * X) = (1 - C (r + s) * X - C (-(r * s)) * X ^ 2 : K⟦X⟧) := by
    simp only [map_add, map_neg, map_mul]; ring
  rw [e] at hfac
  have h1 := congrArg (coeff 1) hfac
  have h2 := congrArg (coeff 2) hfac
  simp only [map_sub, coeff_one, coeff_C_mul, coeff_X, coeff_X_pow] at h1 h2
  norm_num at h1 h2
  have hc1 : c₁ = r + s := by linear_combination -h1
  have hc2 : c₂ = -(r * s) := by linear_combination -h2
  have hrs' : r - s ≠ 0 := sub_ne_zero.mpr hrs
  set f : ℕ → K := fun n => (a 1 - s * a 0) / (r - s) * r ^ n + (r * a 0 - a 1) / (r - s) * s ^ n
    with hf
  have key : ∀ n, a n = f n ∧ a (n + 1) = f (n + 1) := by
    intro n
    induction n with
    | zero =>
      constructor
      · simp only [hf]; field_simp; ring
      · simp only [hf]; field_simp; ring
    | succ n ih =>
      refine ⟨ih.2, ?_⟩
      rw [show n + 1 + 1 = n + 2 by ring, h, ih.1, ih.2]
      rw [hc1, hc2]
      simp only [hf]; field_simp; ring
  intro n
  exact (key n).1

/-- The drum bar. The Fibonacci series F(0) + F(1) x + F(2) x² + ⋯ , with F(0) = 0 and F(1) = 1,
is x / (1 − x − x²). -/
theorem fibonacci_series_eq_x_over_one_sub_x_sub_x_sq :
    mk (fun n => (Nat.fib n : ℚ)) = X * (1 - X - X ^ 2)⁻¹ := by
  have := fixed_weight_rule_series_is_ratio_of_polynomials (1 : ℚ) 1 (fun n => (Nat.fib n : ℚ)) (by intro n; simp [Nat.fib_add_two]; ring)
  rw [this]
  simp

-- The drum bar's counts: F(0) to F(13), ending at 233 on x^13.
example : (List.range 14).map Nat.fib = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233] := by
  decide
-- A 4-beat bar has five patterns of one- and two-beat notes: 1111, 112, 121, 211, 22.
example : [[1, 1, 1, 1], [1, 1, 2], [1, 2, 1], [2, 1, 1], [2, 2]].map List.sum = [4, 4, 4, 4, 4] ∧
    [[1, 1, 1, 1], [1, 1, 2], [1, 2, 1], [2, 1, 1], [2, 2]].Nodup ∧ Nat.fib 5 = 5 := by
  decide
-- The whole-number case: (1 − 2x)(1 − 3x) = 1 − 5x + 6x², the rates 2 and 3.
example : ((1 - 2 * X) * (1 - 3 * X) : ℤ⟦X⟧) = 1 - 5 * X + 6 * X ^ 2 := by
  ring
-- a(n) = 2^n + 3^n lists 2, 5, 13, 35, 97, 275, 793, 2315, 6817 and obeys a(n) = 5 a(n−1) − 6 a(n−2).
example : (List.range 9).map (fun n => 2 ^ n + 3 ^ n) = [2, 5, 13, 35, 97, 275, 793, 2315, 6817] := by
  decide
example : ∀ n < 7, (2 : ℤ) ^ (n + 2) + 3 ^ (n + 2) = 5 * (2 ^ (n + 1) + 3 ^ (n + 1)) - 6 * (2 ^ n + 3 ^ n) := by
  decide
-- The split's two amounts are 1 and 1: A + B = 2 and 2A + 3B = 5.
example : (1 : ℤ) + 1 = 2 ∧ 2 * 1 + 3 * 1 = 5 := by decide
-- Mistake 2, the signs copied down: 1 − 5x − 6x² gives 2, 5, 37, 215, 1297, so a(4) = 1297, not 97.
example : (5 : ℤ) * 2 + 6 * 0 + (-5) = 5 ∧ (5 : ℤ) * 5 + 6 * 2 = 37 ∧ (5 : ℤ) * 37 + 6 * 5 = 215 ∧
    (5 : ℤ) * 215 + 6 * 37 = 1297 := by decide
-- Mistake 3, the split fitted to the constant only: A = 2, B = 0 gives 2 · 2^4 = 32, not 97.
example : 2 * 2 ^ 4 = 32 ∧ 2 ^ 4 + 3 ^ 4 = 97 := by decide

#print axioms fixed_weight_rule_series_is_ratio_of_polynomials
#print axioms split_gives_closed_formula
#print axioms fibonacci_series_eq_x_over_one_sub_x_sub_x_sq
