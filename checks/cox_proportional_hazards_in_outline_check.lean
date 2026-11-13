-- Cox regression in outline: under proportional hazards the chance that a given man is the first in a risk set to die is his weight e^(beta x) over the total weight, whatever the baseline hazard, and survival becomes the baseline survival raised to the hazard ratio.
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Field

open MeasureTheory Filter Real

/-- The baseline cancels. Men in a risk set `s`, man `k` with covariate `x k`, all alive at
time 0. Man `k` has hazard `e^(β x k) · h₀(t)`, where the baseline hazard `h₀ ≥ 0` is any
curve whose cumulative hazard `H₀` starts at 0 and grows without bound. Man `i` is the first
to die, at time `t`, with density `e^(β x i) h₀(t) ∏ₖ e^(-e^(β x k) H₀(t))`; adding this over
all `t` gives exactly his weight over the total weight, `e^(β x i) / ∑ₖ e^(β x k)`, which does
not depend on `h₀`. -/
theorem cox_first_death_prob_eq_weight_share {ι : Type*} (s : Finset ι) (x : ι → ℝ) (β : ℝ)
    (h₀ H₀ : ℝ → ℝ) (hH₀_zero : H₀ 0 = 0)
    (hH₀_cont : ContinuousWithinAt H₀ (Set.Ici 0) 0)
    (hH₀_deriv : ∀ t > 0, HasDerivAt H₀ (h₀ t) t)
    (hh₀_nonneg : ∀ t > 0, 0 ≤ h₀ t)
    (hH₀_top : Tendsto H₀ atTop atTop)
    {i : ι} (hi : i ∈ s) :
    ∫ t in Set.Ioi (0 : ℝ), exp (β * x i) * h₀ t * ∏ k ∈ s, exp (-(exp (β * x k)) * H₀ t)
      = exp (β * x i) / ∑ k ∈ s, exp (β * x k) := by
  have hprod : ∀ t, ∏ k ∈ s, exp (-(exp (β * x k)) * H₀ t)
      = exp (-(∑ k ∈ s, exp (β * x k)) * H₀ t) := by
    intro t
    rw [← Real.exp_sum, neg_mul, Finset.sum_mul, ← Finset.sum_neg_distrib]
    simp only [neg_mul]
  set W := ∑ k ∈ s, exp (β * x k) with hWdef
  have hW : 0 < W := Finset.sum_pos (fun k _ => exp_pos _) ⟨i, hi⟩
  set w := exp (β * x i) with hwdef
  have hfun : (fun t => w * h₀ t * ∏ k ∈ s, exp (-(exp (β * x k)) * H₀ t))
      = fun t => w * h₀ t * exp (-W * H₀ t) := by
    funext t; rw [hprod t]
  rw [hfun]
  let g : ℝ → ℝ := fun t => -(w / W) * exp (-W * H₀ t)
  have hcont : ContinuousWithinAt g (Set.Ici 0) 0 := by
    have : ContinuousWithinAt (fun t => -W * H₀ t) (Set.Ici 0) 0 :=
      continuousWithinAt_const.mul hH₀_cont
    exact continuousWithinAt_const.mul (continuous_exp.continuousAt.comp_continuousWithinAt this)
  have hderiv : ∀ t ∈ Set.Ioi (0 : ℝ), HasDerivAt g (w * h₀ t * exp (-W * H₀ t)) t := by
    intro t ht
    have h1 := ((hH₀_deriv t ht).const_mul (-W)).exp.const_mul (-(w / W))
    convert h1 using 1
    field_simp
  have hpos : ∀ t ∈ Set.Ioi (0 : ℝ), 0 ≤ w * h₀ t * exp (-W * H₀ t) := by
    intro t ht
    exact mul_nonneg (mul_nonneg (exp_pos _).le (hh₀_nonneg t ht)) (exp_pos _).le
  have hlim : Tendsto g atTop (nhds 0) := by
    have h1 : Tendsto (fun t => -W * H₀ t) atTop atBot :=
      tendsto_neg_atTop_atBot.comp (hH₀_top.const_mul_atTop hW) |>.congr (fun t => by simp)
    have h2 := (Real.tendsto_exp_atBot.comp h1).const_mul (-(w / W))
    simpa [g] using h2
  rw [integral_Ioi_of_hasDerivAt_of_nonneg hcont hderiv hpos hlim]
  simp [g, hH₀_zero]

/-- Given that the first death in the risk set happens at time `t` (where the baseline
hazard is positive), it is man `i`'s with chance `e^(β x i) / ∑ₖ e^(β x k)`: the baseline
`h₀(t)` and the time `t` divide out. -/
theorem cox_conditional_first_death_eq_weight_share {ι : Type*} (s : Finset ι) (x : ι → ℝ)
    (β : ℝ) (h₀ H₀ : ℝ → ℝ) (t : ℝ) (ht : 0 < h₀ t) (i : ι) :
    (exp (β * x i) * h₀ t * ∏ k ∈ s, exp (-(exp (β * x k)) * H₀ t)) /
      (∑ j ∈ s, exp (β * x j) * h₀ t * ∏ k ∈ s, exp (-(exp (β * x k)) * H₀ t))
      = exp (β * x i) / ∑ k ∈ s, exp (β * x k) := by
  have hP : 0 < ∏ k ∈ s, exp (-(exp (β * x k)) * H₀ t) :=
    Finset.prod_pos (fun k _ => exp_pos _)
  rw [← Finset.sum_mul, ← Finset.sum_mul, mul_assoc, mul_assoc]
  exact mul_div_mul_right _ _ (mul_pos ht hP).ne'

/-- Hazard to survival: if the cumulative hazard for covariate `x` is `e^(β x)` times the
baseline's, `H(t | x) = e^(β x) H₀(t)`, then survival `S(t | x) = e^(-H(t | x))` equals the
baseline survival `S₀(t) = e^(-H₀(t))` raised to the power `e^(β x)`. -/
theorem cox_survival_eq_baseline_rpow (β x H₀t : ℝ) :
    exp (-(exp (β * x) * H₀t)) = (exp (-H₀t)) ^ (exp (β * x)) := by
  rw [Real.rpow_def_of_pos (exp_pos _), Real.log_exp]
  ring_nf

-- Step 1, the race of two: a smoker of weight 2 against a non-smoker of weight 1.
example : (2 : ℚ) / (2 + 1) = 2 / 3 := by norm_num

-- Step 2: at year 4, three smokers (weight 2 each) and four non-smokers (weight 1).
example : ((2 + 2 + 2 : ℚ) / (2 * 3 + 4)) = 6 / 10 := by norm_num

-- Worked numbers: the seven expected smoker shares at hazard ratio 2 add to 4,
-- the observed number of smoker deaths (A, C, D, I), so the score is 0 at HR 2.
example : (2 * 5 / (2 * 5 + 5) + 2 * 4 / (2 * 4 + 4) + 2 * 3 / (2 * 3 + 4) + 2 * 2 / (2 * 2 + 4)
    + 2 * 1 / (2 * 1 + 3) + 2 * 1 / (2 * 1 + 2) + 2 * 1 / (2 * 1 + 1) : ℚ) = 4 := by norm_num

-- The information at HR 2: the sum of share × (1 − share) is exactly 247/150 (about 1.6467).
example : ((2 / 3) * (1 / 3) + (2 / 3) * (1 / 3) + (3 / 5) * (2 / 5) + (1 / 2) * (1 / 2)
    + (2 / 5) * (3 / 5) + (1 / 2) * (1 / 2) + (2 / 3) * (1 / 3) : ℚ) = 247 / 150 := by norm_num

-- The doctors: survival 76/100 squared gives a death chance of 264/625 (42.24%), not 48/100.
example : (1 - (76 / 100 : ℚ) ^ 2) = 264 / 625 := by norm_num
example : (1 - (76 / 100 : ℚ) ^ 2) ≠ 2 * (24 / 100) := by norm_num

#print axioms cox_first_death_prob_eq_weight_share
#print axioms cox_conditional_first_death_eq_weight_share
#print axioms cox_survival_eq_baseline_rpow
