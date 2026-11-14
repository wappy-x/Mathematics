-- Collateral: the residual exposure left by variation margin is never negative and never more than the threshold plus the minimum transfer plus the trade's gain over the margin period of risk.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real

/-- The ceiling on the residual exposure (Step 4). Let `V t` be the trade's clean value at date
`t`, `H ≥ 0` the threshold, `M ≥ 0` the minimum transfer amount and `δ` the margin period of risk.
The collateral counted at date `t`, `C t`, was set at the last margin call `δ` earlier: it equals
the target `(V (t - δ) - H)⁺`, or differs from it by less than `M` because the minimum transfer rule
left it unmoved. Then the residual exposure `X t = (V t - C t)⁺` satisfies
`0 ≤ X t ≤ H + M + (V t - V (t - δ))⁺`. -/
theorem residual_exposure_le_threshold_add_mta_add_gain
    (V C : ℝ → ℝ) (H M δ : ℝ) (hH : 0 ≤ H) (hM : 0 ≤ M)
    (hC : ∀ t, C t = max (V (t - δ) - H) 0 ∨ |C t - max (V (t - δ) - H) 0| < M) (t : ℝ) :
    0 ≤ max (V t - C t) 0 ∧
      max (V t - C t) 0 ≤ H + M + max (V t - V (t - δ)) 0 := by
  have hA : max (V (t - δ) - H) 0 - M ≤ C t := by
    rcases hC t with h | h
    · rw [h]; linarith
    · have := (abs_lt.mp h).1; linarith
  refine ⟨le_max_right _ _, max_le ?_ ?_⟩
  · have h1 := le_max_left (V (t - δ) - H) 0
    have h2 := le_max_left (V t - V (t - δ)) 0
    linarith
  · have h2 := le_max_right (V t - V (t - δ)) 0
    linarith

/-- Instant margin caps the residual at the threshold (Step 2). If margin could be seized the
moment the counterparty fails, the collateral is `C t = (V t - H)⁺`; for a trade whose value is
never negative (a bought call) and a threshold `H ≥ 0`, the residual `(V t - C t)⁺` is exactly the
smaller of the value and the threshold, `min (V t) H`. -/
theorem instant_margin_residual_eq_min_value_threshold
    (V : ℝ → ℝ) (H : ℝ) (hV : ∀ t, 0 ≤ V t) (hH : 0 ≤ H) (t : ℝ) :
    max (V t - max (V t - H) 0) 0 = min (V t) H := by
  have hv := hV t
  rcases le_total (V t) H with h | h
  · rw [max_eq_right (show V t - H ≤ 0 by linarith), min_eq_left h, sub_zero, max_eq_left hv]
  · rw [max_eq_left (show 0 ≤ V t - H by linarith), min_eq_right h, sub_sub_cancel,
      max_eq_left hH]

/-- The instant-margin CVA ceiling done by hand (Step 2): putting the threshold `H` in place of
the residual in the CVA integral, with discount `e^{-r t}`, default density `λ e^{-λ t}` and
recovery `R`, gives `(1 - R) H λ / (λ + r) (1 - e^{-(λ + r) T})`. -/
theorem instant_margin_cva_ceiling_eq
    (R H lam r T : ℝ) (hlr : lam + r ≠ 0) :
    (1 - R) * H * ∫ t in (0 : ℝ)..T, exp (-r * t) * (lam * exp (-lam * t)) =
      (1 - R) * H * (lam / (lam + r)) * (1 - exp (-(lam + r) * T)) := by
  have h1 : ∀ t : ℝ, exp (-r * t) * (lam * exp (-lam * t)) = lam * exp ((-(lam + r)) * t) := by
    intro t
    rw [mul_left_comm, ← Real.exp_add]
    ring_nf
  simp_rw [h1]
  have hc : (-(lam + r)) ≠ 0 := neg_ne_zero.mpr hlr
  rw [intervalIntegral.integral_const_mul,
    intervalIntegral.integral_comp_mul_left (fun x => exp x) hc, integral_exp]
  simp only [mul_zero, Real.exp_zero, smul_eq_mul]
  field_simp
  ring

#print axioms residual_exposure_le_threshold_add_mta_add_gain
#print axioms instant_margin_residual_eq_min_value_threshold
#print axioms instant_margin_cva_ceiling_eq
