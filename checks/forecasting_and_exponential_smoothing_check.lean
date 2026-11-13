-- Forecasting: under the innovations model with independent normal misses, the Holt-Winters forecast error h months ahead (h at most one season) is normal with variance σ² times 1 + Σ (α(1 + jβ))², which has a closed form; the updates have an error-correction form, and simple smoothing is a fading weighted average.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Algebra.BigOperators.Intervals

open MeasureTheory ProbabilityTheory Finset

lemma hw_gaussian_weighted_sum
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (σ : ℝ) (ε : ℕ → Ω → ℝ)
    (h_indep : iIndepFun ε P)
    (h_normal : ∀ k, HasLaw (ε k) (gaussianReal 0 (σ ^ 2).toNNReal) P)
    (c : ℕ → ℝ) (n : ℕ) :
    HasLaw (fun ω => ∑ i ∈ range n, c i * ε i ω)
      (gaussianReal 0 (σ ^ 2 * ∑ i ∈ range n, c i ^ 2).toNNReal) P := by
  induction n with
  | zero =>
    simp only [range_zero, sum_empty, mul_zero, Real.toNNReal_zero, gaussianReal_zero_var]
    exact ⟨aemeasurable_const, by simp [Measure.map_const]⟩
  | succ n ih =>
    set f : ℕ → Ω → ℝ := fun i ω => c i * ε i ω with hf
    have hfi : iIndepFun f P := h_indep.comp (fun i x => c i * x) (fun i => by fun_prop)
    have hfm : ∀ i, AEMeasurable (f i) P := fun i => (h_normal i).aemeasurable.const_mul (c i)
    have hI : IndepFun (∑ j ∈ range n, f j) (f n) P := hfi.indepFun_sum_range_succ₀ hfm n
    have hsum : (∑ j ∈ range n, f j) = fun ω => ∑ i ∈ range n, c i * ε i ω := by
      ext ω; simp [hf, Finset.sum_apply]
    rw [hsum] at hI
    have hn : HasLaw (f n) _ P := gaussianReal_const_mul (h_normal n) (c n)
    have key := gaussianReal_add_gaussianReal_of_indepFun hI ih hn
    have hfun : (fun ω => ∑ i ∈ range (n + 1), c i * ε i ω)
        = (fun ω => ∑ i ∈ range n, c i * ε i ω) + f n := by
      ext ω; simp [hf, Finset.sum_range_succ]
    rw [hfun]
    refine ⟨?_, ?_⟩
    · exact ih.aemeasurable.add (hfm n)
    · rw [key]
      congr 1
      · ring
      · have h1 : 0 ≤ σ ^ 2 := sq_nonneg σ
        have h2 : 0 ≤ ∑ i ∈ range n, c i ^ 2 := sum_nonneg (fun i _ => sq_nonneg _)
        ext
        simp only [NNReal.coe_add, NNReal.coe_mul, NNReal.coe_mk,
          Real.coe_toNNReal _ h1, Real.coe_toNNReal _ (mul_nonneg h1 h2)]
        rw [Real.coe_toNNReal _ (mul_nonneg h1 (sum_nonneg (fun i _ => sq_nonneg _))),
          sum_range_succ]
        ring

#print axioms hw_gaussian_weighted_sum

lemma hw_closed_form (α β : ℝ) (n : ℕ) :
    ∑ j ∈ Ico 1 (n + 1), (α * (1 + (j : ℝ) * β)) ^ 2
      = (n : ℝ) * (α ^ 2 + α ^ 2 * β * ((n : ℝ) + 1)
          + α ^ 2 * β ^ 2 * ((n : ℝ) + 1) * (2 * ((n : ℝ) + 1) - 1) / 6) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [sum_Ico_succ_top (by omega), ih]
    push_cast
    ring

#print axioms hw_closed_form

/-- Holt-Winters forecast intervals. Stand at month 0 with level `L 0`, trend `B 0` and stored
seasons `S 1, …, S m` (`S j` is the season used for month `j`). Each later month `k + 1` has the
actual value `y (k+1) = L k + B k + S (k+1) + ε k`: the one-month forecast plus a miss `ε k`, and
the level, trend and season then update by the card's three equations. If the misses are
independent and each is normal with mean 0 and spread `σ`, then for every horizon `h` from 1 to
`m` the forecast error `y h - (L 0 + h B 0 + S h)` is normal with mean 0 and variance `σ² v_h`,
where `v_h = 1 + Σ_{j=1}^{h-1} c_j²` with `c_j = α (1 + j β)`, and
`v_h = 1 + (h-1)[α² + α²βh + α²β²h(2h-1)/6]`. -/
theorem holt_winters_forecast_error_normal
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (α β γ σ : ℝ) (m : ℕ)
    (ε y L B S : ℕ → Ω → ℝ)
    (h_indep : iIndepFun ε P)
    (h_normal : ∀ k, HasLaw (ε k) (gaussianReal 0 (σ ^ 2).toNNReal) P)
    (h_obs : ∀ k ω, y (k + 1) ω = L k ω + B k ω + S (k + 1) ω + ε k ω)
    (h_level : ∀ k ω, L (k + 1) ω = α * (y (k + 1) ω - S (k + 1) ω) + (1 - α) * (L k ω + B k ω))
    (h_trend : ∀ k ω, B (k + 1) ω = β * (L (k + 1) ω - L k ω) + (1 - β) * B k ω)
    (h_season : ∀ k ω, S (k + 1 + m) ω = γ * (y (k + 1) ω - L k ω - B k ω) + (1 - γ) * S (k + 1) ω)
    (h : ℕ) (h_pos : 1 ≤ h) (h_le : h ≤ m) :
    HasLaw (fun ω => y h ω - (L 0 ω + (h : ℝ) * B 0 ω + S h ω))
        (gaussianReal 0
          (σ ^ 2 * (1 + ∑ j ∈ Ico 1 h, (α * (1 + (j : ℝ) * β)) ^ 2)).toNNReal) P ∧
      1 + ∑ j ∈ Ico 1 h, (α * (1 + (j : ℝ) * β)) ^ 2
        = 1 + ((h : ℝ) - 1) * (α ^ 2 + α ^ 2 * β * h + α ^ 2 * β ^ 2 * h * (2 * h - 1) / 6) := by
  obtain ⟨n, rfl⟩ : ∃ n, h = n + 1 := ⟨h - 1, by omega⟩
  -- error-correction forms
  have hL : ∀ k ω, L (k + 1) ω = L k ω + B k ω + α * ε k ω := by
    intro k ω; rw [h_level, h_obs]; ring
  have hB : ∀ k ω, B (k + 1) ω = B k ω + α * β * ε k ω := by
    intro k ω; rw [h_trend, hL]; ring
  have hBsum : ∀ k ω, B k ω = B 0 ω + α * β * ∑ i ∈ range k, ε i ω := by
    intro k ω
    induction k with
    | zero => simp
    | succ k ih => rw [hB, ih, sum_range_succ]; ring
  have hLB : ∀ k ω, L k ω + B k ω = L 0 ω + ((k : ℝ) + 1) * B 0 ω
      + ∑ i ∈ range k, α * (1 + ((k : ℝ) - i) * β) * ε i ω := by
    intro k ω
    induction k with
    | zero => simp
    | succ k ih =>
      have e1 : ∑ i ∈ range k, α * (1 + (((k + 1 : ℕ) : ℝ) - i) * β) * ε i ω
          = ∑ i ∈ range k, α * (1 + ((k : ℝ) - i) * β) * ε i ω
            + α * β * ∑ i ∈ range k, ε i ω := by
        rw [mul_sum, ← sum_add_distrib]
        refine sum_congr rfl (fun i _ => ?_)
        push_cast; ring
      rw [hL, hB, sum_range_succ, e1]
      have := ih
      push_cast
      linear_combination ih + hBsum k ω
  -- coefficients
  set c : ℕ → ℝ := fun i => if i < n then α * (1 + ((n : ℝ) - i) * β) else 1 with hc
  have herr : (fun ω => y (n + 1) ω - (L 0 ω + ((n + 1 : ℕ) : ℝ) * B 0 ω + S (n + 1) ω))
      = fun ω => ∑ i ∈ range (n + 1), c i * ε i ω := by
    ext ω
    rw [sum_range_succ, h_obs]
    have hcn : c n = 1 := by simp [hc]
    have hci : ∑ i ∈ range n, c i * ε i ω
        = ∑ i ∈ range n, α * (1 + ((n : ℝ) - i) * β) * ε i ω :=
      sum_congr rfl (fun i hi => by simp [hc, mem_range.mp hi])
    rw [hcn, hci]
    have := hLB n ω
    push_cast
    linear_combination this
  have hvar : ∑ i ∈ range (n + 1), c i ^ 2 = 1 + ∑ j ∈ Ico 1 (n + 1), (α * (1 + (j : ℝ) * β)) ^ 2 := by
    rw [sum_range_succ, sum_Ico_eq_sum_range, add_comm]
    have hcn : c n = 1 := by simp [hc]
    rw [hcn, one_pow, Nat.add_sub_cancel]
    congr 1
    rw [← sum_range_reflect]
    refine sum_congr rfl (fun i hi => ?_)
    have hi' := mem_range.mp hi
    have : n - 1 - i < n := by omega
    simp only [hc, this, ite_true]
    have hcast : ((n - 1 - i : ℕ) : ℝ) = (n : ℝ) - 1 - i := by
      rw [Nat.cast_sub (by omega), Nat.cast_sub (by omega)]; simp
    rw [hcast]; push_cast; ring
  refine ⟨?_, ?_⟩
  · rw [herr, ← hvar]
    exact hw_gaussian_weighted_sum P σ ε h_indep h_normal c (n + 1)
  · rw [hw_closed_form]; push_cast; ring

/-- Error-correction form (Step 3). With the one-month miss `e = y - (ℓ + b + s)`, the three
Holt-Winters updates are the old prediction plus a share of the miss: the new level is
`ℓ + b + α e`, the new trend is `b + α β e`, and the new season is `s + γ e`. -/
theorem holt_winters_error_correction_form (α β γ y l b s : ℝ) :
    α * (y - s) + (1 - α) * (l + b) = l + b + α * (y - (l + b + s)) ∧
      β * ((α * (y - s) + (1 - α) * (l + b)) - l) + (1 - β) * b
        = b + α * β * (y - (l + b + s)) ∧
      γ * (y - l - b) + (1 - γ) * s = s + γ * (y - (l + b + s)) := by
  refine ⟨by ring, by ring, by ring⟩

/-- Simple exponential smoothing is a weighted average of every past month (Step 1). If
`ℓ (t+1) = α y (t+1) + (1 - α) ℓ t` for every month, then `ℓ t` is the sum of
`α (1 - α)^j y (t - j)` over `j < t`, plus `(1 - α)^t ℓ 0`; and these weights, counting the
starting value's share, add up to 1. -/
theorem simple_smoothing_weighted_average (α : ℝ) (y ℓ : ℕ → ℝ)
    (h_rec : ∀ t, ℓ (t + 1) = α * y (t + 1) + (1 - α) * ℓ t) (t : ℕ) :
    ℓ t = ∑ j ∈ range t, α * (1 - α) ^ j * y (t - j) + (1 - α) ^ t * ℓ 0 ∧
      ∑ j ∈ range t, α * (1 - α) ^ j + (1 - α) ^ t = 1 := by
  induction t with
  | zero => simp
  | succ t ih =>
    obtain ⟨ih1, ih2⟩ := ih
    refine ⟨?_, ?_⟩
    · rw [h_rec, sum_range_succ']
      have : ∀ j ∈ range t, α * (1 - α) ^ (j + 1) * y (t + 1 - (j + 1))
          = (1 - α) * (α * (1 - α) ^ j * y (t - j)) := by
        intro j _
        rw [Nat.add_sub_add_right]; ring
      rw [sum_congr rfl this, ← mul_sum, ih1]
      simp only [pow_zero, mul_one, Nat.sub_zero]
      ring
    · rw [sum_range_succ]; linear_combination ih2

-- The 1959 counts, January to December, in thousands: the "same month last year" forecast of 1960.
example : (360 + 342 + 406 + 396 + 420 + 472 + 548 + 559 + 463 + 407 + 362 + 405 : ℕ) = 5140 := by
  norm_num

-- The actual 1960 counts add up to 5714 thousand.
example : (417 + 391 + 419 + 461 + 472 + 535 + 622 + 606 + 508 + 461 + 390 + 432 : ℕ) = 5714 := by
  norm_num

-- The "same month last year" forecast falls short by 574 thousand.
example : (5714 - 5140 : ℕ) = 574 := by
  norm_num

-- Random-walk case α = 1, β = 0: the widening factor at h = 12 is 12.
example : 1 + ∑ j ∈ Ico (1 : ℕ) 12, ((1 : ℝ) * (1 + (j : ℝ) * 0)) ^ 2 = 12 := by
  norm_num

#print axioms holt_winters_forecast_error_normal
#print axioms holt_winters_error_correction_form
#print axioms simple_smoothing_weighted_average
