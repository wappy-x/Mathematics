-- The fundamental law: inside the card's model, the best information ratio any active weights can reach is exactly IC times the square root of the breadth divided by the square root of one minus IC squared, it comes from weights that follow the forecasts, independent bets add their squared ratios, and an information coefficient always lies between -1 and +1.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Order.Bounds.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Finset

/-- The average of a list of `n` numbers across the stocks: `x̄ = (Σ_i x_i) / n`. -/
noncomputable def crossMean {n : ℕ} (x : Fin n → ℝ) : ℝ := (∑ i, x i) / n

/-- The information coefficient of scores `z` against residual returns `θ`, the correlation
`Σ (z_i - z̄)(θ_i - θ̄) / (√(Σ (z_i - z̄)²) √(Σ (θ_i - θ̄)²))`. -/
noncomputable def infoCoeff {n : ℕ} (z θ : Fin n → ℝ) : ℝ :=
  (∑ i, (z i - crossMean z) * (θ i - crossMean θ)) /
    (Real.sqrt (∑ i, (z i - crossMean z) ^ 2) * Real.sqrt (∑ i, (θ i - crossMean θ) ^ 2))

/-- The information ratio of active weights `h`, for forecasts `α` and independent leftover
risks `s`: expected active return `E[A] = Σ h_i α_i` over active risk `√Var(A)`, where
`Var(A) = Σ h_i² s_i²`. -/
noncomputable def infoRatio {n : ℕ} (h α s : Fin n → ℝ) : ℝ :=
  (∑ i, h i * α i) / Real.sqrt (∑ i, h i ^ 2 * s i ^ 2)

/-- Cauchy-Schwarz with an absolute value. -/
theorem abs_sum_mul_le_sqrt_mul_sqrt {n : ℕ} (f g : Fin n → ℝ) :
    |∑ i, f i * g i| ≤ Real.sqrt (∑ i, f i ^ 2) * Real.sqrt (∑ i, g i ^ 2) := by
  rw [abs_le]
  refine ⟨?_, Real.sum_mul_le_sqrt_mul_sqrt _ f g⟩
  have h := Real.sum_mul_le_sqrt_mul_sqrt Finset.univ f (fun i => -g i)
  simp only [mul_neg, Finset.sum_neg_distrib, neg_sq] at h
  linarith

#print axioms abs_sum_mul_le_sqrt_mul_sqrt

/-- A nonzero weight vector with positive risks has positive active variance. -/
theorem sum_sq_mul_sq_pos {n : ℕ} (h s : Fin n → ℝ) (hh : h ≠ 0) (hs : ∀ i, 0 < s i) :
    0 < ∑ i, h i ^ 2 * s i ^ 2 := by
  obtain ⟨j, hj⟩ := Function.ne_iff.mp hh
  apply Finset.sum_pos' (fun i _ => by positivity)
  refine ⟨j, Finset.mem_univ _, ?_⟩
  have := hs j
  simp only [Pi.zero_apply] at hj
  positivity

#print axioms sum_sq_mul_sq_pos

/-- Helper copy of the squares law, so the fundamental law can use it. -/
theorem best_ir_helper {n : ℕ} (hn : 0 < n) (α s : Fin n → ℝ)
    (hs : ∀ i, 0 < s i) :
    IsGreatest {r | ∃ h : Fin n → ℝ, h ≠ 0 ∧ r = infoRatio h α s}
        (Real.sqrt (∑ i, (α i / s i) ^ 2)) ∧
      ∀ c : ℝ, 0 < c → α ≠ 0 →
        infoRatio (fun i => c * α i / s i ^ 2) α s = Real.sqrt (∑ i, (α i / s i) ^ 2) := by
  have hub : ∀ h : Fin n → ℝ, h ≠ 0 → infoRatio h α s ≤ Real.sqrt (∑ i, (α i / s i) ^ 2) := by
    intro h hh
    have hA := sum_sq_mul_sq_pos h s hh hs
    unfold infoRatio
    rw [div_le_iff₀ (Real.sqrt_pos.mpr hA)]
    have key : ∑ i, h i * α i = ∑ i, (h i * s i) * (α i / s i) := by
      refine Finset.sum_congr rfl (fun i _ => ?_)
      have := (hs i).ne'
      field_simp
    have key2 : ∑ i, h i ^ 2 * s i ^ 2 = ∑ i, (h i * s i) ^ 2 := by
      refine Finset.sum_congr rfl (fun i _ => ?_)
      ring
    rw [key, key2, mul_comm (Real.sqrt _)]
    exact Real.sum_mul_le_sqrt_mul_sqrt _ _ _
  have heq : ∀ c : ℝ, 0 < c → α ≠ 0 →
      infoRatio (fun i => c * α i / s i ^ 2) α s = Real.sqrt (∑ i, (α i / s i) ^ 2) := by
    intro c hc hα
    set S := ∑ i, (α i / s i) ^ 2 with hSdef
    have hS : 0 < S := by
      obtain ⟨j, hj⟩ := Function.ne_iff.mp hα
      apply Finset.sum_pos' (fun i _ => by positivity)
      refine ⟨j, Finset.mem_univ _, ?_⟩
      have := (hs j).ne'
      simp only [Pi.zero_apply] at hj
      have : α j / s j ≠ 0 := div_ne_zero hj this
      positivity
    unfold infoRatio
    have hnum : ∑ i, c * α i / s i ^ 2 * α i = c * S := by
      rw [hSdef, Finset.mul_sum]
      refine Finset.sum_congr rfl (fun i _ => ?_)
      have := (hs i).ne'
      field_simp
    have hden : ∑ i, (c * α i / s i ^ 2) ^ 2 * s i ^ 2 = c ^ 2 * S := by
      rw [hSdef, Finset.mul_sum]
      refine Finset.sum_congr rfl (fun i _ => ?_)
      have := (hs i).ne'
      field_simp
    rw [hnum, hden, Real.sqrt_mul (by positivity), Real.sqrt_sq hc.le]
    have hsq := Real.sq_sqrt hS.le
    have hpos := Real.sqrt_pos.mpr hS
    field_simp
    linarith
  refine ⟨⟨?_, fun r ⟨h, hh, hr⟩ => hr ▸ hub h hh⟩, heq⟩
  by_cases hα : α = 0
  · refine ⟨fun _ => 1, ?_, ?_⟩
    · intro h1
      have := congrFun h1 ⟨0, hn⟩
      simp at this
    · subst hα
      simp [infoRatio]
  · exact ⟨fun i => 1 * α i / s i ^ 2, fun h0 => hα (funext fun i => by
      have := congrFun h0 i
      have hsi := (hs i).ne'
      simp only [Pi.zero_apply, one_mul, div_eq_zero_iff, pow_eq_zero_iff, ne_eq,
        OfNat.ofNat_ne_zero, not_false_eq_true] at this
      simpa [hsi] using this), (heq 1 one_pos hα).symm⟩

#print axioms best_ir_helper

/-- The fundamental law, exact form inside the card's model. Take `n ≥ 1` independent bets
(breadth `BR = n`), scores `z` rescaled so that their squares add to `n`, residual volatility
`ω > 0`, and skill `IC` with `|IC| < 1`. Grinold's forecast is `α_i = IC ω z_i` and each bet's
leftover risk is `s = ω √(1 - IC²)`. Then the best information ratio over all nonzero active
weights is exactly `|IC| √BR / √(1 - IC²)` (that is `IC √BR / √(1 - IC²)` for a forecaster with
positive skill), and weights that follow the forecasts, `h = α`, reach it. -/
theorem fundamental_law_exact_information_ratio {n : ℕ} (hn : 0 < n) (z : Fin n → ℝ)
    (hz : ∑ i, z i ^ 2 = n) (ω IC : ℝ) (hω : 0 < ω) (hIC : |IC| < 1) :
    IsGreatest
        {r | ∃ h : Fin n → ℝ, h ≠ 0 ∧
          r = infoRatio h (fun i => IC * ω * z i) (fun _ => ω * Real.sqrt (1 - IC ^ 2))}
        (|IC| * Real.sqrt n / Real.sqrt (1 - IC ^ 2)) ∧
      (IC ≠ 0 →
        infoRatio (fun i => IC * ω * z i) (fun i => IC * ω * z i)
            (fun _ => ω * Real.sqrt (1 - IC ^ 2))
          = |IC| * Real.sqrt n / Real.sqrt (1 - IC ^ 2)) := by
  have hIC2 : 0 < 1 - IC ^ 2 := by
    have : IC ^ 2 < 1 := by
      rw [← sq_abs]
      nlinarith [abs_nonneg IC]
    linarith
  set s := ω * Real.sqrt (1 - IC ^ 2) with hsdef
  have hs : 0 < s := mul_pos hω (Real.sqrt_pos.mpr hIC2)
  have hval : Real.sqrt (∑ i, (IC * ω * z i / s) ^ 2)
      = |IC| * Real.sqrt n / Real.sqrt (1 - IC ^ 2) := by
    have hsum : ∑ i, (IC * ω * z i / s) ^ 2 = (IC ^ 2 * n) / (1 - IC ^ 2) := by
      have hs2 : s ^ 2 = ω ^ 2 * (1 - IC ^ 2) := by
        rw [hsdef, mul_pow, Real.sq_sqrt hIC2.le]
      have : ∀ i, (IC * ω * z i / s) ^ 2 = (IC ^ 2 / (1 - IC ^ 2)) * z i ^ 2 := by
        intro i
        rw [div_pow, hs2]
        have := hω.ne'
        have := hIC2.ne'
        field_simp
      simp_rw [this]
      rw [← Finset.mul_sum, hz]
      ring
    rw [hsum, Real.sqrt_div' _ hIC2.le, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq_eq_abs]
  obtain ⟨hgr, heq⟩ := best_ir_helper hn (fun i => IC * ω * z i)
    (fun _ => s) (fun _ => hs)
  rw [hval] at hgr heq
  refine ⟨hgr, fun hIC0 => ?_⟩
  have hα : (fun i => IC * ω * z i) ≠ 0 := by
    intro h0
    have hz0 : ∀ i, z i = 0 := by
      intro i
      have := congrFun h0 i
      simp only [Pi.zero_apply, mul_eq_zero] at this
      rcases this with (h | h) | h
      · exact absurd h hIC0
      · exact absurd h hω.ne'
      · exact h
    have : (n : ℝ) = 0 := by
      rw [← hz]
      simp [hz0]
    have : (n : ℝ) ≠ 0 := by positivity
    contradiction
  have := heq (s ^ 2) (by positivity) hα
  have hfun : (fun i => s ^ 2 * (IC * ω * z i) / s ^ 2) = (fun i => IC * ω * z i) := by
    funext i
    have : s ^ 2 ≠ 0 := by positivity
    field_simp
  rw [hfun] at this
  exact this

/-- Independent bets combine in squares. For forecasts `α_i` and leftover risks `s_i > 0` on
`n ≥ 1` independent bets, no nonzero active weights beat the information ratio
`√(Σ_i (α_i / s_i)²)`, and the weights `h_i = c α_i / s_i²` reach it for every `c > 0`
whenever some forecast is nonzero. -/
theorem best_information_ratio_adds_in_squares {n : ℕ} (hn : 0 < n) (α s : Fin n → ℝ)
    (hs : ∀ i, 0 < s i) :
    IsGreatest {r | ∃ h : Fin n → ℝ, h ≠ 0 ∧ r = infoRatio h α s}
        (Real.sqrt (∑ i, (α i / s i) ^ 2)) ∧
      ∀ c : ℝ, 0 < c → α ≠ 0 →
        infoRatio (fun i => c * α i / s i ^ 2) α s = Real.sqrt (∑ i, (α i / s i) ^ 2) := by
  exact best_ir_helper hn α s hs

/-- The information coefficient is a correlation, so it runs from -1 to +1. -/
theorem info_coeff_between_neg_one_and_one {n : ℕ} (z θ : Fin n → ℝ) :
    -1 ≤ infoCoeff z θ ∧ infoCoeff z θ ≤ 1 := by
  unfold infoCoeff
  set x := ∑ i, (z i - crossMean z) * (θ i - crossMean θ)
  set y := Real.sqrt (∑ i, (z i - crossMean z) ^ 2) * Real.sqrt (∑ i, (θ i - crossMean θ) ^ 2)
  have hxy : |x| ≤ y := abs_sum_mul_le_sqrt_mul_sqrt _ _
  have hy : 0 ≤ y := by positivity
  rcases hy.lt_or_eq with hy | hy
  · rw [← abs_le, abs_div, abs_of_pos hy, div_le_one hy]
    exact hxy
  · rw [← hy, div_zero]
    norm_num

-- The toy: scores -2, -1, 0, 1, 2 and residual returns -2, 0, 1, -1, 2 percent.
-- Score times return adds to 7; the squared scores and the squared returns each add to 10.
example : (∑ i : Fin 5, (![-2, -1, 0, 1, 2] : Fin 5 → ℤ) i * (![-2, 0, 1, -1, 2] : Fin 5 → ℤ) i)
    = 7 := by decide
example : (∑ i : Fin 5, (![-2, -1, 0, 1, 2] : Fin 5 → ℤ) i ^ 2) = 10 := by decide
example : (∑ i : Fin 5, (![-2, 0, 1, -1, 2] : Fin 5 → ℤ) i ^ 2) = 10 := by decide

-- The toy IC is 7 / √(10 × 10) = 7/10.
example : infoCoeff ![-2, -1, 0, 1, 2] ![-2, 0, 1, -1, 2] = 7 / 10 := by
  have h : Real.sqrt 10 * Real.sqrt 10 = 10 := Real.mul_self_sqrt (by norm_num)
  simp [infoCoeff, crossMean, Fin.sum_univ_succ]
  norm_num [h]

-- The rank IC: ranks 1 to 5 against 1, 3, 4, 2, 5 give the same 7/10.
example : infoCoeff ![1, 2, 3, 4, 5] ![1, 3, 4, 2, 5] = 7 / 10 := by
  have h : Real.sqrt 10 * Real.sqrt 10 = 10 := Real.mul_self_sqrt (by norm_num)
  simp [infoCoeff, crossMean, Fin.sum_univ_succ]
  norm_num [h]

-- IC 1/20 on 500 bets: the law squared is IC² × BR = 5/4 (the law is √5/2, about 1.118),
-- and the exact model squared is IC² × BR / (1 - IC²) = 500/399 (about 1.1194²).
example : ((1 / 20 : ℚ) ^ 2 * 500) = 5 / 4 := by norm_num
example : ((1 / 20 : ℚ) ^ 2 * 500) / (1 - (1 / 20) ^ 2) = 500 / 399 := by norm_num

-- Doubling skill matches quadrupling breadth: IC 1/10 on 500 and IC 1/20 on 2000 both give 5.
example : ((1 / 10 : ℚ) ^ 2 * 500) = (1 / 20) ^ 2 * 2000 := by norm_num

-- 50 lockstep groups: IC² × 50 = 1/8 (IR about 0.354). Monthly fresh bets: IC² × 6000 = 15
-- (IR about 3.87), which is 12 times the yearly 5/4, so the IR scales by √12, not 12.
example : ((1 / 20 : ℚ) ^ 2 * 50) = 1 / 8 := by norm_num
example : ((1 / 20 : ℚ) ^ 2 * (12 * 500)) = 15 ∧ (15 : ℚ) = 12 * (5 / 4) := by norm_num

-- Forecast for a score of +1: IC × ω × 1 = 1/20 × 1/4 = 1/80 (1.25 percent);
-- share of variance explained: IC² = 1/400 (0.25 percent).
example : ((1 / 20 : ℚ) * (1 / 4) * 1) = 1 / 80 := by norm_num
example : ((1 / 20 : ℚ) ^ 2) = 1 / 400 := by norm_num

-- Market timing, breadth 1: IC² = 5/9 (IC about 0.745) gives IC² / (1 - IC²) = 5/4,
-- the same squared ratio as IC 1/20 on 500 bets.
example : ((5 / 9 : ℚ) / (1 - 5 / 9)) = 5 / 4 := by norm_num

#print axioms fundamental_law_exact_information_ratio
#print axioms best_information_ratio_adds_in_squares
#print axioms info_coeff_between_neg_one_and_one
