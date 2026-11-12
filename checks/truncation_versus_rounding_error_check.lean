-- Two different errors: the truncation laws behind the card hold exactly: a quadratic's forward slope is off by a times h and its central slope by nothing, the series for e cut after 1/n! falls short by between 1/(n+1)! and (n+2)/(n+1) times that, and when the error is exactly C h^p the halving ratio is 2^p.
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Data.Nat.Factorial.Basic

open Finset

/-- The stone's truncation is plain algebra. For a quadratic position
`s(x) = a x^2 + b x + c` and any step `h ≠ 0`, the forward slope
`(s(t+h) - s(t)) / h` misses the true slope `s'(t)` by exactly `a h`
(truncation of order 1 with constant `a`; for the stone `a = 4.9`), while the
central slope `(s(t+h) - s(t-h)) / (2h)` has no truncation error at all. -/
theorem quadratic_slope_truncation (a b c t h : ℝ) (s : ℝ → ℝ)
    (hs : ∀ x, s x = a * x ^ 2 + b * x + c) (hh : h ≠ 0) :
    (s (t + h) - s t) / h - deriv s t = a * h ∧
      (s (t + h) - s (t - h)) / (2 * h) - deriv s t = 0 := by
  have hfun : s = fun x => a * x ^ 2 + b * x + c := funext hs
  have hd : deriv s t = 2 * a * t + b := by
    subst hfun
    have h1 : HasDerivAt (fun x : ℝ => a * x ^ 2 + b * x + c) (a * (2 * t) + b) t := by
      have hx2 : HasDerivAt (fun x : ℝ => x ^ 2) (2 * t) t := by
        simpa using hasDerivAt_pow 2 t
      have := HasDerivAt.add_const c (HasDerivAt.add (HasDerivAt.const_mul a hx2) (HasDerivAt.const_mul b (hasDerivAt_id t)))
      simpa using this
    rw [h1.deriv]; ring
  rw [hd, hs, hs, hs]
  constructor
  · field_simp
    ring
  · field_simp
    ring

/-- A cut-off series. Stopping the series `e = 1 + 1/1! + 1/2! + ...` after the
term `1/n!` leaves a truncation error (the dropped tail) that is at least the
next term `1/(n+1)!` and at most that term times `(n+2)/(n+1)`. -/
theorem exp_one_series_tail_bounds (n : ℕ) :
    1 / ((n + 1).factorial : ℝ) ≤
        Real.exp 1 - ∑ k ∈ range (n + 1), 1 / (k.factorial : ℝ) ∧
      Real.exp 1 - ∑ k ∈ range (n + 1), 1 / (k.factorial : ℝ) ≤
        1 / ((n + 1).factorial : ℝ) * ((n + 2) / (n + 1)) := by
  have hs : ∀ m : ℕ, ∑ k ∈ range m, 1 / (k.factorial : ℝ) =
      ∑ k ∈ range m, (1 : ℝ) ^ k / (k.factorial : ℝ) := by
    intro m; simp
  constructor
  · have h := Real.sum_le_exp_of_nonneg (x := 1) zero_le_one (n + 2)
    rw [← hs, sum_range_succ] at h
    linarith
  · have h := Real.exp_bound (x := 1) (by simp) (n := n + 1) (Nat.succ_pos n)
    rw [← hs] at h
    have h2 := (abs_le.mp h).2
    refine le_trans h2 (le_of_eq ?_)
    have hf : ((n + 1).factorial : ℝ) ≠ 0 := by positivity
    have hn : ((n : ℝ) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring

/-- The halving test. If a recipe's answer is its exact value plus a pure
truncation term, `A(x) = A* + C x^p` with `C ≠ 0` and order `p ≥ 1`, then for
any step `h ≠ 0` the change from `h` to `h/2`, divided by the change from `h/2`
to `h/4`, is exactly `2^p`. -/
theorem halving_ratio_eq_two_pow (A : ℝ → ℝ) (Astar C h : ℝ) (p : ℕ)
    (hA : ∀ x, A x = Astar + C * x ^ p) (hC : C ≠ 0) (hp : 1 ≤ p) (hh : h ≠ 0) :
    (A h - A (h / 2)) / (A (h / 2) - A (h / 4)) = 2 ^ p := by
  rw [hA, hA, hA]
  have h2 : (2 : ℝ) ^ p ≠ 0 := by positivity
  have hp1 : (2 : ℝ) ^ p ≠ 1 := by
    have : (1 : ℝ) < 2 ^ p := one_lt_pow₀ (by norm_num) (by omega)
    exact ne_of_gt this
  have hhp : h ^ p ≠ 0 := pow_ne_zero p hh
  have e1 : (h / 2) ^ p = h ^ p / 2 ^ p := div_pow h 2 p
  have e2 : (h / 4) ^ p = h ^ p / (2 ^ p * 2 ^ p) := by
    rw [div_pow, ← mul_pow]; norm_num
  have hsub : (2 : ℝ) ^ p - 1 ≠ 0 := sub_ne_zero.mpr hp1
  rw [e1, e2]
  generalize (2 : ℝ) ^ p = q at *
  generalize h ^ p = H at *
  have hden : Astar + C * (H / q) - (Astar + C * (H / (q * q))) = C * H * (q - 1) / (q * q) := by
    field_simp
    ring
  have hden0 : C * H * (q - 1) / (q * q) ≠ 0 :=
    div_ne_zero (mul_ne_zero (mul_ne_zero hC hhp) hsub) (mul_ne_zero h2 h2)
  rw [hden, div_eq_iff hden0]
  field_simp
  ring

-- Worked numbers, in exact rationals: the stone s(t) = 49/10 t^2 at t = 3 s.
-- Position at 3 s is 44.1 m and at 3.01 s is 44.39449 m.
example : (49 / 10 : ℚ) * 3 * 3 = 441 / 10 := by norm_num
example : (49 / 10 : ℚ) * (301 / 100) * (301 / 100) = 4439449 / 100000 := by norm_num
-- The forward slope with step 1/100 s is 29.449 m/s, so its error is 0.049 = 4.9 × 0.01.
example : ((49 / 10 : ℚ) * (3 + 1 / 100) ^ 2 - 49 / 10 * 3 ^ 2) / (1 / 100) = 29449 / 1000 := by
  norm_num
example : (29449 / 1000 : ℚ) - 294 / 10 = 49 / 10 * (1 / 100) := by norm_num
-- The central slope with the same step is exactly 29.4 m/s.
example : ((49 / 10 : ℚ) * (3 + 1 / 100) ^ 2 - 49 / 10 * (3 - 1 / 100) ^ 2) / (2 * (1 / 100)) =
    294 / 10 := by norm_num
-- The next term after 1/10! is 1/11!, and 11! = 39916800.
example : Nat.factorial 11 = 39916800 := by decide
-- The tracker's exact recipe: 0.1 added ten million times is 1,000,000.
example : (10 ^ 7 : ℚ) * (1 / 10) = 10 ^ 6 := by norm_num

#print axioms quadratic_slope_truncation
#print axioms exp_one_series_tail_bounds
#print axioms halving_ratio_eq_two_pow
