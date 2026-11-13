-- The VIX: the recipe's (F/K₀ - 1)²/T term removes the cost of switching from puts to calls at the listed strike K₀ instead of at the forward F, leaving an over-subtraction between 0 and (2/(3T))(F/K₀ - 1)³, and the 30-day weight w₁ = (N₂ - N₃₀)/(N₂ - N₁) blends total variance so that it lands exactly at 30 days.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open Real intervalIntegral

lemma vix_log_lower_bound (u : ℝ) (hu : 1 ≤ u) : (u - 1) - (u - 1) ^ 2 / 2 ≤ log u := by
  have hmono : MonotoneOn (fun t => log t - ((t - 1) - (t - 1) ^ 2 / 2)) (Set.Ici 1) := by
    refine monotoneOn_of_hasDerivWithinAt_nonneg (convex_Ici 1)
      (f' := fun t => t⁻¹ - (1 - (t - 1))) ?_ ?_ ?_
    · intro t ht
      have ht0 : t ≠ 0 := by have : (1:ℝ) ≤ t := ht; positivity
      exact ((continuousAt_log ht0).sub (by fun_prop)).continuousWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      have ht0 : t ≠ 0 := by have : (1:ℝ) < t := ht; positivity
      refine HasDerivAt.hasDerivWithinAt ?_
      have h1 := ((hasDerivAt_id t).sub_const 1)
      have h2 := (h1.pow 2).div_const 2
      exact ((hasDerivAt_log ht0).sub (h1.sub h2)).congr_deriv (by simp)
    · intro t ht
      rw [interior_Ici] at ht
      have ht1 : (1:ℝ) < t := ht
      have htpos : 0 < t := by linarith
      have : t⁻¹ - (1 - (t - 1)) = (t - 1) ^ 2 / t := by field_simp; ring
      rw [this]; positivity
  have := hmono (Set.mem_Ici.mpr le_rfl) hu hu
  simp at this
  linarith

lemma vix_log_upper_bound (u : ℝ) (hu : 1 ≤ u) :
    log u ≤ (u - 1) - (u - 1) ^ 2 / 2 + (u - 1) ^ 3 / 3 := by
  have hmono : MonotoneOn (fun t => ((t - 1) - (t - 1) ^ 2 / 2 + (t - 1) ^ 3 / 3) - log t)
      (Set.Ici 1) := by
    refine monotoneOn_of_hasDerivWithinAt_nonneg (convex_Ici 1)
      (f' := fun t => (1 - (t - 1) + (t - 1) ^ 2) - t⁻¹) ?_ ?_ ?_
    · intro t ht
      have ht0 : t ≠ 0 := by have : (1:ℝ) ≤ t := ht; positivity
      exact ((by fun_prop : ContinuousAt (fun t : ℝ => (t - 1) - (t - 1) ^ 2 / 2 + (t - 1) ^ 3 / 3) t).sub
        (continuousAt_log ht0)).continuousWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      have ht0 : t ≠ 0 := by have : (1:ℝ) < t := ht; positivity
      refine HasDerivAt.hasDerivWithinAt ?_
      have h1 := ((hasDerivAt_id t).sub_const 1)
      have h2 := (h1.pow 2).div_const 2
      have h3 := (h1.pow 3).div_const 3
      exact (((h1.sub h2).add h3).sub (hasDerivAt_log ht0)).congr_deriv (by simp)
    · intro t ht
      rw [interior_Ici] at ht
      have ht1 : (1:ℝ) < t := ht
      have htpos : 0 < t := by linarith
      have : (1 - (t - 1) + (t - 1) ^ 2) - t⁻¹ = (t - 1) ^ 3 / t := by field_simp; ring
      rw [this]
      have : 0 < t - 1 := by linarith
      positivity
  have := hmono (Set.mem_Ici.mpr le_rfl) hu hu
  simp at this
  linarith

lemma vix_excess_integral (T r F K₀ : ℝ) (hK₀ : 0 < K₀) (hK₀F : K₀ ≤ F)
    (C P : ℝ → ℝ) (hparity : ∀ K, C K - P K = exp (-r * T) * (F - K)) :
    ∫ K in K₀..F, (C K - P K) / K ^ 2 = exp (-r * T) * (F / K₀ - 1 - log (F / K₀)) := by
  have hfun : (fun K => (C K - P K) / K ^ 2) = fun K => exp (-r * T) * ((F - K) / K ^ 2) := by
    funext K; rw [hparity]; ring
  rw [hfun, intervalIntegral.integral_const_mul]
  congr 1
  have hpos : ∀ x ∈ Set.uIcc K₀ F, 0 < x := by
    intro x hx
    rw [Set.uIcc_of_le hK₀F] at hx
    exact lt_of_lt_of_le hK₀ hx.1
  have hF : 0 < F := lt_of_lt_of_le hK₀ hK₀F
  rw [integral_eq_sub_of_hasDerivAt (f := fun K => -F / K - log K)]
  · rw [log_div hF.ne' hK₀.ne']
    field_simp
    ring
  · intro x hx
    have hx0 : x ≠ 0 := (hpos x hx).ne'
    have h := ((hasDerivAt_inv hx0).const_mul (-F)).sub (hasDerivAt_log hx0)
    refine (h.congr_deriv ?_).congr_of_eventuallyEq ?_
    · field_simp
    · filter_upwards with y; simp [div_eq_mul_inv]
  · apply ContinuousOn.intervalIntegrable
    apply ContinuousOn.div (by fun_prop) (by fun_prop)
    intro x hx; exact pow_ne_zero 2 (hpos x hx).ne'

lemma vix_excess_closed_form_aux
    (T r F K₀ : ℝ) (_hT : 0 < T) (hK₀ : 0 < K₀) (hK₀F : K₀ ≤ F)
    (C P : ℝ → ℝ) (hparity : ∀ K, C K - P K = exp (-r * T) * (F - K)) :
    2 * exp (r * T) / T * ∫ K in K₀..F, (C K - P K) / K ^ 2
      = 2 / T * (F / K₀ - 1 - log (F / K₀)) := by
  rw [vix_excess_integral T r F K₀ hK₀ hK₀F C P hparity]
  have he : exp (r * T) * exp (-r * T) = 1 := by rw [← exp_add]; simp
  calc 2 * exp (r * T) / T * (exp (-r * T) * (F / K₀ - 1 - log (F / K₀)))
      = 2 * (exp (r * T) * exp (-r * T)) / T * (F / K₀ - 1 - log (F / K₀)) := by ring
    _ = _ := by rw [he]; ring

#print axioms vix_log_lower_bound
#print axioms vix_log_upper_bound
#print axioms vix_excess_integral
#print axioms vix_excess_closed_form_aux

/-- **The forward-switch correction is right to third order** (Why it works, Step 2 and its
detailed proof). Take one expiry `T > 0` years away, a riskless rate `r`, the forward `F`, and
`K₀` the listed strike at or just below it (`0 < K₀ ≤ F`). Let call and put prices `C K`,
`P K` obey put-call parity at every strike, `C K - P K = e^(-rT) (F - K)`. On the band from
`K₀` to `F` the recipe uses calls where the strip integral uses puts; grown by `e^(rT)` and
weighted by `2/(T K²)`, that excess is `E = (2 e^(rT)/T) ∫_{K₀}^{F} (C K - P K)/K² dK`.
With `x = F/K₀ - 1`, the term the recipe subtracts, `x²/T`, is never smaller than `E` and
over-subtracts by at most `(2/(3T)) x³`, third order in `x`. -/
theorem vix_forward_switch_correction_error_third_order
    (T r F K₀ : ℝ) (hT : 0 < T) (hK₀ : 0 < K₀) (hK₀F : K₀ ≤ F)
    (C P : ℝ → ℝ) (hparity : ∀ K, C K - P K = exp (-r * T) * (F - K)) :
    0 ≤ (F / K₀ - 1) ^ 2 / T - 2 * exp (r * T) / T * ∫ K in K₀..F, (C K - P K) / K ^ 2 ∧
      (F / K₀ - 1) ^ 2 / T - 2 * exp (r * T) / T * ∫ K in K₀..F, (C K - P K) / K ^ 2
        ≤ 2 / (3 * T) * (F / K₀ - 1) ^ 3 := by
  rw [vix_excess_closed_form_aux T r F K₀ hT hK₀ hK₀F C P hparity]
  have hu : 1 ≤ F / K₀ := (one_le_div hK₀).mpr hK₀F
  have h1 := vix_log_lower_bound _ hu
  have h2 := vix_log_upper_bound _ hu
  set u := F / K₀
  have hrw : (u - 1) ^ 2 / T - 2 / T * (u - 1 - log u) = ((u - 1) ^ 2 - 2 * (u - 1 - log u)) / T := by
    ring
  rw [hrw]
  constructor
  · apply div_nonneg _ hT.le
    linarith
  · rw [show 2 / (3 * T) * (u - 1) ^ 3 = (2 / 3 * (u - 1) ^ 3) / T by ring]
    apply (div_le_div_iff_of_pos_right hT).mpr
    linarith

/-- **The excess in closed form** (Why it works, Step 2, detailed proof). Under put-call parity
`C K - P K = e^(-rT) (F - K)`, with `0 < K₀ ≤ F` and `T > 0`, the recipe's excess from using
calls on the band `[K₀, F]` is exactly
`(2 e^(rT)/T) ∫_{K₀}^{F} (C K - P K)/K² dK = (2/T)(F/K₀ - 1 - ln(F/K₀))`. -/
theorem vix_forward_switch_excess_closed_form
    (T r F K₀ : ℝ) (hT : 0 < T) (hK₀ : 0 < K₀) (hK₀F : K₀ ≤ F)
    (C P : ℝ → ℝ) (hparity : ∀ K, C K - P K = exp (-r * T) * (F - K)) :
    2 * exp (r * T) / T * ∫ K in K₀..F, (C K - P K) / K ^ 2
      = 2 / T * (F / K₀ - 1 - log (F / K₀)) := by
  exact vix_excess_closed_form_aux T r F K₀ hT hK₀ hK₀F C P hparity

/-- **The blend lands at exactly 30 days** (The formula; Why it works, Step 3). With the near
expiry `N₁` days out, the next `N₂ > N₁` days out, the target `N₃₀ > 0` days and `N₃₆₅ > 0`
days in a year, the weight `w₁ = (N₂ - N₃₀)/(N₂ - N₁)` blends the two times to exactly the
target, `w₁ N₁ + (1 - w₁) N₂ = N₃₀`. So when both expiries carry the same per-year variance
`v`, the VIX formula `100 √((T₁ v w₁ + T₂ v (1 - w₁)) N₃₆₅/N₃₀)`, with `T_j = N_j/N₃₆₅`,
returns `100 √v`. And the blend interpolates (`0 ≤ w₁ ≤ 1`) exactly when the two expiries
bracket the target, `N₁ ≤ N₃₀ ≤ N₂`. -/
theorem vix_blend_lands_at_thirty_days
    (N₁ N₂ N₃₀ N₃₆₅ v : ℝ) (h12 : N₁ < N₂) (h30 : 0 < N₃₀) (h365 : 0 < N₃₆₅) :
    let w₁ := (N₂ - N₃₀) / (N₂ - N₁)
    w₁ * N₁ + (1 - w₁) * N₂ = N₃₀ ∧
      100 * √((N₁ / N₃₆₅ * v * w₁ + N₂ / N₃₆₅ * v * (1 - w₁)) * (N₃₆₅ / N₃₀)) = 100 * √v ∧
      ((N₁ ≤ N₃₀ ∧ N₃₀ ≤ N₂) ↔ (0 ≤ w₁ ∧ w₁ ≤ 1)) := by
  intro w₁
  have hd : 0 < N₂ - N₁ := by linarith
  have hblend : w₁ * N₁ + (1 - w₁) * N₂ = N₃₀ := by
    simp only [w₁]
    field_simp
    ring
  refine ⟨hblend, ?_, ?_⟩
  · have hin : (N₁ / N₃₆₅ * v * w₁ + N₂ / N₃₆₅ * v * (1 - w₁)) * (N₃₆₅ / N₃₀) = v := by
      rw [show (N₁ / N₃₆₅ * v * w₁ + N₂ / N₃₆₅ * v * (1 - w₁)) * (N₃₆₅ / N₃₀)
          = v * (w₁ * N₁ + (1 - w₁) * N₂) / N₃₀ by field_simp, hblend]
      field_simp
    rw [hin]
  · have h0 : 0 ≤ w₁ ↔ N₃₀ ≤ N₂ := by
      simp only [w₁]
      rw [le_div_iff₀ hd]
      constructor <;> intro h <;> linarith
    have h1 : w₁ ≤ 1 ↔ N₁ ≤ N₃₀ := by
      simp only [w₁]
      rw [div_le_one hd]
      constructor <;> intro h <;> linarith
    rw [h0, h1]
    tauto

-- The card's expiries: 23 and 37 days, target 30. Weight on the near expiry (37 - 30)/(37 - 23) = 1/2.
example : ((37 : ℚ) - 30) / (37 - 23) = 1 / 2 := by norm_num
-- The blend of 23 and 37 days at weights 1/2 and 1/2 is 30 days.
example : (1 / 2 : ℚ) * 23 + (1 - 1 / 2) * 37 = 30 := by norm_num
-- Total-variance weights in years: 23/365 × 1/2 + 37/365 × 1/2 = 30/365, and × 365/30 gives 1.
example : ((23 : ℚ) / 365 * (1 / 2) + 37 / 365 * (1 / 2)) * (365 / 30) = 1 := by norm_num
-- Edge case: the near expiry sits exactly 30 days out, so w₁ = 1 and the next expiry drops out.
example : ((37 : ℚ) - 30) / (37 - 30) = 1 := by norm_num
-- A flat 20% surface: per-year variance 1/25, and 100 √(1/25) = 20.
example : 100 * √((1 : ℝ) / 25) = 20 := by
  rw [show (1 : ℝ) / 25 = (1 / 5) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]; norm_num

#print axioms vix_forward_switch_correction_error_third_order
#print axioms vix_forward_switch_excess_closed_form
#print axioms vix_blend_lands_at_thirty_days
