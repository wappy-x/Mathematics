-- Robust tests: for one loop with model loop gain L, envelope W and specification weight W_P, every plant inside the envelope keeps the loop closed and meets the specification at every frequency exactly when the stability term plus the performance term stays under 1 at every frequency.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Complex

/-- The return difference factors through the model's return difference. -/
lemma rd_factor (L W Δ : ℂ) (h : 1 + L ≠ 0) :
    1 + L * (1 + W * Δ) = (1 + L) * (1 + W * (L / (1 + L)) * Δ) := by
  field_simp
  ring

/-- Lower bound on `|1 + b Δ|` for `|Δ| ≤ 1`. -/
lemma one_sub_norm_le (b Δ : ℂ) (hΔ : ‖Δ‖ ≤ 1) : 1 - ‖b‖ ≤ ‖1 + b * Δ‖ := by
  have h1 := norm_sub_le (1 + b * Δ) (b * Δ)
  rw [add_sub_cancel_right, norm_one, norm_mul] at h1
  have h2 : ‖b‖ * ‖Δ‖ ≤ ‖b‖ := mul_le_of_le_one_right (norm_nonneg _) hΔ
  linarith

/-- Worst-case value at one frequency. -/
lemma worst_case_aux (a b : ℂ) (hb : ‖b‖ < 1) :
    IsGreatest {x : ℝ | ∃ Δ : ℂ, ‖Δ‖ ≤ 1 ∧ x = ‖a / (1 + b * Δ)‖} (‖a‖ / (1 - ‖b‖)) := by
  have hpos : 0 < 1 - ‖b‖ := by linarith
  constructor
  · refine ⟨-(‖b‖ : ℂ) / b, ?_, ?_⟩
    · rw [norm_div, norm_neg, Complex.norm_real, Real.norm_eq_abs, abs_norm]
      exact div_self_le_one _
    · have hbD : b * (-(‖b‖ : ℂ) / b) = -(‖b‖ : ℂ) := by
        rcases eq_or_ne b 0 with rfl | hb0
        · simp
        · field_simp
      have h1 : (1 : ℂ) + -(‖b‖ : ℂ) = ((1 - ‖b‖ : ℝ) : ℂ) := by push_cast; ring
      rw [hbD, h1, norm_div, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hpos]
  · rintro x ⟨Δ, hΔ, rfl⟩
    rw [norm_div]
    exact div_le_div_of_nonneg_left (norm_nonneg _) hpos (one_sub_norm_le b Δ hΔ)

/-- Pointwise robust stability. -/
lemma stab_forward (L W : ℝ → ℂ) (hL : ∀ ω, 1 + L ω ≠ 0)
    (h : ∀ Δ : ℝ → ℂ, (∀ ω, ‖Δ ω‖ ≤ 1) → ∀ ω, 1 + L ω * (1 + W ω * Δ ω) ≠ 0) (ω : ℝ) :
    ‖W ω * (L ω / (1 + L ω))‖ < 1 := by
  by_contra hc
  replace hc := not_lt.mp hc
  have hc0 : W ω * (L ω / (1 + L ω)) ≠ 0 := by
    intro h0
    rw [h0, norm_zero] at hc
    linarith
  have hD : ∀ ω' : ℝ, ‖(fun _ : ℝ => -1 / (W ω * (L ω / (1 + L ω)))) ω'‖ ≤ 1 := by
    intro ω'
    rw [norm_div, norm_neg, norm_one]
    exact div_le_one_of_le₀ hc (norm_nonneg _)
  apply h _ hD ω
  rw [rd_factor _ _ _ (hL ω)]
  have : (1 : ℂ) + W ω * (L ω / (1 + L ω)) * (-1 / (W ω * (L ω / (1 + L ω)))) = 0 := by
    rw [mul_div_assoc', mul_neg_one, neg_div, div_self hc0, add_neg_cancel]
  rw [this, mul_zero]

lemma stab_backward (L W : ℝ → ℂ) (hL : ∀ ω, 1 + L ω ≠ 0)
    (h : ∀ ω, ‖W ω * (L ω / (1 + L ω))‖ < 1) (Δ : ℝ → ℂ) (hΔ : ∀ ω, ‖Δ ω‖ ≤ 1) (ω : ℝ) :
    1 + L ω * (1 + W ω * Δ ω) ≠ 0 := by
  rw [rd_factor _ _ _ (hL ω)]
  apply mul_ne_zero (hL ω)
  intro h0
  have := one_sub_norm_le (W ω * (L ω / (1 + L ω))) (Δ ω) (hΔ ω)
  rw [h0, norm_zero] at this
  linarith [h ω]

lemma perf_eq (L W W_P Δ : ℂ) (h : 1 + L ≠ 0) :
    W_P / (1 + L * (1 + W * Δ)) = W_P * (1 / (1 + L)) / (1 + W * (L / (1 + L)) * Δ) := by
  rw [rd_factor _ _ _ h, div_mul_eq_div_div, mul_one_div]

#print axioms rd_factor
#print axioms one_sub_norm_le
#print axioms worst_case_aux
#print axioms stab_forward
#print axioms stab_backward
#print axioms perf_eq

/-- Robust performance holds exactly when the sum test passes at every frequency.
At each angular frequency `ω`, `L ω` is the model's loop gain, `W ω` the envelope and `W_P ω` the
performance weight; `S = 1/(1 + L)` and `T = L/(1 + L)`. A plant in the family has loop gain
`L (1 + W Δ)` with `|Δ| ≤ 1`, and the worst `Δ` may differ from frequency to frequency.
Every such plant keeps its return difference `1 + L (1 + W Δ)` away from zero and keeps its own
performance term `|W_P S_J| = |W_P / (1 + L (1 + W Δ))|` under 1 at every frequency
if and only if `|W_P S| + |W T| < 1` at every frequency. -/
theorem robust_performance_iff_sum_lt_one (L W W_P : ℝ → ℂ) (hL : ∀ ω, 1 + L ω ≠ 0) :
    (∀ Δ : ℝ → ℂ, (∀ ω, ‖Δ ω‖ ≤ 1) → ∀ ω,
        1 + L ω * (1 + W ω * Δ ω) ≠ 0 ∧ ‖W_P ω / (1 + L ω * (1 + W ω * Δ ω))‖ < 1) ↔
      ∀ ω, ‖W_P ω * (1 / (1 + L ω))‖ + ‖W ω * (L ω / (1 + L ω))‖ < 1 := by
  constructor
  · intro h ω
    have hT := stab_forward L W hL (fun Δ hΔ ω => (h Δ hΔ ω).1) ω
    obtain ⟨Δ0, hΔ0, heq⟩ := (worst_case_aux (W_P ω * (1 / (1 + L ω))) _ hT).1
    have h2 := (h (fun _ => Δ0) (fun _ => hΔ0) ω).2
    rw [perf_eq _ _ _ _ (hL ω), ← heq] at h2
    have hpos : 0 < 1 - ‖W ω * (L ω / (1 + L ω))‖ := by linarith
    rw [div_lt_one hpos] at h2
    linarith
  · intro h Δ hΔ ω
    have hb : ‖W ω * (L ω / (1 + L ω))‖ < 1 := by
      linarith [norm_nonneg (W_P ω * (1 / (1 + L ω))), h ω]
    refine ⟨stab_backward L W hL (fun ω' => by
      linarith [norm_nonneg (W_P ω' * (1 / (1 + L ω'))), h ω']) Δ hΔ ω, ?_⟩
    rw [perf_eq _ _ _ _ (hL ω)]
    have h1 := (worst_case_aux (W_P ω * (1 / (1 + L ω))) _ hb).2 ⟨Δ ω, hΔ ω, rfl⟩
    have hpos : 0 < 1 - ‖W ω * (L ω / (1 + L ω))‖ := by linarith
    have h2 : ‖W_P ω * (1 / (1 + L ω))‖ / (1 - ‖W ω * (L ω / (1 + L ω))‖) < 1 := by
      rw [div_lt_one hpos]
      linarith [h ω]
    exact lt_of_le_of_lt h1 h2

/-- Robust stability, frequency by frequency: no plant in the envelope's family puts a zero of the
return difference `1 + L (1 + W Δ)` on the imaginary axis (so no closed-loop pole can cross it)
if and only if `|W T| < 1` at every frequency, where `T = L/(1 + L)`. -/
theorem robust_stability_iff_WT_lt_one (L W : ℝ → ℂ) (hL : ∀ ω, 1 + L ω ≠ 0) :
    (∀ Δ : ℝ → ℂ, (∀ ω, ‖Δ ω‖ ≤ 1) → ∀ ω, 1 + L ω * (1 + W ω * Δ ω) ≠ 0) ↔
      ∀ ω, ‖W ω * (L ω / (1 + L ω))‖ < 1 := by
  exact ⟨fun h => stab_forward L W hL h, fun h => stab_backward L W hL h⟩

/-- The worst plant at one frequency: with `a = W_P S` and `b = W T` and `|b| < 1`, the largest
value of `|a / (1 + b Δ)|` over all `|Δ| ≤ 1` is exactly `|a| / (1 - |b|)`, and some `Δ` of size
at most 1 reaches it. -/
theorem worst_case_performance_term (a b : ℂ) (hb : ‖b‖ < 1) :
    IsGreatest {x : ℝ | ∃ Δ : ℂ, ‖Δ‖ ≤ 1 ∧ x = ‖a / (1 + b * Δ)‖} (‖a‖ / (1 - ‖b‖)) := by
  exact worst_case_aux a b hb

-- Worked numbers, exact. Empty belt J0 = 1/5, b = 2/5, tau = 1/50, Kp = 3, Ki = 4.
-- The plant's bottom (J0 s + b)(tau s + 1) at s = 10j is 2.08j = (52/25) j.
example : ((1 / 5 : ℂ) * (10 * I) + 2 / 5) * (1 / 50 * (10 * I) + 1) = 52 / 25 * I := by
  apply Complex.ext <;> simp <;> norm_num

-- Hurwitz ratio (J + b tau)(b + Kp) / (J tau Ki) for the empty, half and full belts: 44.200, 43.633, 43.350.
example : ((1 / 5 : ℚ) + 2 / 5 * (1 / 50)) * (2 / 5 + 3) / (1 / 5 * (1 / 50) * 4) = 221 / 5 := by
  norm_num
example : ((3 / 10 : ℚ) + 2 / 5 * (1 / 50)) * (2 / 5 + 3) / (3 / 10 * (1 / 50) * 4) = 1309 / 30 := by
  norm_num
example : ((2 / 5 : ℚ) + 2 / 5 * (1 / 50)) * (2 / 5 + 3) / (2 / 5 * (1 / 50) * 4) = 867 / 20 := by
  norm_num
example : (1 : ℚ) < 867 / 20 := by norm_num

-- Saturation: Kp = 3 N m per rad/s; a 10 rad/s step asks 30 N m (over a 20 N m drive), a 5 rad/s step 15 N m.
example : 3 * 10 = 30 ∧ 20 < 3 * 10 ∧ 3 * 5 = 15 ∧ 3 * 5 ≤ 20 := by decide

#print axioms robust_performance_iff_sum_lt_one
#print axioms robust_stability_iff_WT_lt_one
#print axioms worst_case_performance_term
