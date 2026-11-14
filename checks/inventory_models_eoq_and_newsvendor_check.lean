-- Stock: the order size √(2KD/h) is the one cheapest yearly order size, where ordering cost equals holding cost, and a one-shot order whose demand curve reaches (p - c)/((p - c) + (c - v)) maximizes expected profit.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.Bochner.Basic

open MeasureTheory ProbabilityTheory

/-- Economic order quantity: with order cost `K > 0`, demand rate `D > 0` and holding cost
`h > 0`, the yearly cost `C(Q) = K D / Q + h Q / 2` of order size `Q > 0` is smallest at
`Q* = √(2 K D / h)`, and no other positive order size does as well. -/
theorem eoq_minimizes_yearly_cost (K D h : ℝ) (hK : 0 < K) (hD : 0 < D) (hh : 0 < h) :
    let C : ℝ → ℝ := fun Q => K * D / Q + h * Q / 2
    let Qstar : ℝ := Real.sqrt (2 * K * D / h)
    0 < Qstar ∧ ∀ Q : ℝ, 0 < Q → C Qstar ≤ C Q ∧ (C Q = C Qstar → Q = Qstar) := by
  intro C Qstar
  have hpos : 0 < 2 * K * D / h := by positivity
  have hs : 0 < Qstar := Real.sqrt_pos.mpr hpos
  have hsq : Qstar ^ 2 = 2 * K * D / h := Real.sq_sqrt hpos.le
  have hKD : K * D = h * Qstar ^ 2 / 2 := by
    rw [hsq]; field_simp
  have hdiff : ∀ Q : ℝ, 0 < Q → C Q - C Qstar = h * (Q - Qstar) ^ 2 / (2 * Q) := by
    intro Q hQ
    simp only [C]
    rw [hKD]
    field_simp
    ring
  refine ⟨hs, fun Q hQ => ⟨?_, fun hEq => ?_⟩⟩
  · have := hdiff Q hQ
    have : 0 ≤ h * (Q - Qstar) ^ 2 / (2 * Q) := by positivity
    linarith
  · have h0 := hdiff Q hQ
    rw [hEq, sub_self] at h0
    have h1 : h * (Q - Qstar) ^ 2 = 0 := by
      field_simp at h0
      linarith
    have h2 : (Q - Qstar) ^ 2 = 0 := by
      rcases mul_eq_zero.mp h1 with h3 | h3
      · exact absurd h3 hh.ne'
      · exact h3
    have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h2
    linarith

/-- At the best order size the yearly ordering cost `K D / Q*` equals the yearly holding cost
`h Q* / 2`, the minimum yearly cost is `√(2 K D h)`, and any order size `Q` costs
`C(Q*) · (Q / Q* + Q* / Q) / 2` (the flat bottom of the cost curve). -/
theorem eoq_ordering_equals_holding (K D h : ℝ) (hK : 0 < K) (hD : 0 < D) (hh : 0 < h) :
    let C : ℝ → ℝ := fun Q => K * D / Q + h * Q / 2
    let Qstar : ℝ := Real.sqrt (2 * K * D / h)
    K * D / Qstar = h * Qstar / 2 ∧ C Qstar = Real.sqrt (2 * K * D * h) ∧
      ∀ Q : ℝ, 0 < Q → C Q = C Qstar * ((Q / Qstar + Qstar / Q) / 2) := by
  intro C Qstar
  have hpos : 0 < 2 * K * D / h := by positivity
  have hs : 0 < Qstar := Real.sqrt_pos.mpr hpos
  have hsq : Qstar ^ 2 = 2 * K * D / h := Real.sq_sqrt hpos.le
  have hKD : K * D = h * Qstar ^ 2 / 2 := by
    rw [hsq]; field_simp
  have hCs : C Qstar = h * Qstar := by
    simp only [C]
    rw [hKD]
    field_simp
    ring
  refine ⟨?_, ?_, ?_⟩
  · rw [hKD]; field_simp
  · rw [hCs]
    have : 2 * K * D * h = (h * Qstar) ^ 2 := by
      rw [mul_pow, hsq]; field_simp
    rw [this, Real.sqrt_sq (by positivity)]
  · intro Q hQ
    rw [hCs]
    simp only [C]
    rw [hKD]
    field_simp
    ring

/-- Newsvendor critical fractile: for a one-shot order with price `p`, unit cost `c` and
leftover value `v < p`, and any demand distribution `μ` with a finite mean, an order `Q*` at
which the chance demand is at most `Q*` equals `c_u / (c_u + c_o)`, with `c_u = p - c` and
`c_o = c - v`, gives expected profit `p · min(demand, Q) + v · (leftovers) - c · Q` at least as
large as any other order size `Q`. -/
theorem newsvendor_critical_fractile (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (hμ : Integrable id μ) (p c v : ℝ) (hvp : v < p) (Qstar : ℝ)
    (hF : cdf μ Qstar = (p - c) / ((p - c) + (c - v))) (Q : ℝ) :
    ∫ d, (p * min d Q + v * max (Q - d) 0 - c * Q) ∂μ ≤
      ∫ d, (p * min d Qstar + v * max (Qstar - d) 0 - c * Qstar) ∂μ := by
  have hpv : 0 < p - v := by linarith
  have hden : (p - c) + (c - v) = p - v := by ring
  rw [hden] at hF
  have hFc : (p - v) * cdf μ Qstar = p - c := by
    rw [hF]; field_simp
  have hint : ∀ Q' : ℝ, Integrable (fun d : ℝ => max (Q' - d) 0) μ := by
    intro Q'
    have h1 : Integrable (fun d : ℝ => Q' - d) μ := (integrable_const Q').sub hμ
    exact h1.sup (integrable_const (0 : ℝ))
  have key : ∀ Q' : ℝ, ∫ d, (p * min d Q' + v * max (Q' - d) 0 - c * Q') ∂μ
      = (p - c) * Q' - (p - v) * ∫ d, max (Q' - d) 0 ∂μ := by
    intro Q'
    have hpt : ∀ d : ℝ, p * min d Q' + v * max (Q' - d) 0 - c * Q'
        = (p - c) * Q' - (p - v) * max (Q' - d) 0 := by
      intro d
      have : min d Q' = Q' - max (Q' - d) 0 := by
        rcases le_total d Q' with hd | hd
        · rw [min_eq_left hd, max_eq_left (by linarith)]; ring
        · rw [min_eq_right hd, max_eq_right (by linarith)]; ring
      rw [this]; ring
    simp_rw [hpt]
    rw [integral_sub (integrable_const _) ((hint Q').const_mul (p - v)), integral_const,
      integral_const_mul]
    simp
  rw [key Q, key Qstar]
  have hmeas : MeasurableSet (Set.Iic Qstar) := measurableSet_Iic
  have hind : Integrable (fun d : ℝ => (Set.Iic Qstar).indicator (fun _ => (1 : ℝ)) d) μ :=
    (integrable_const (1 : ℝ)).indicator hmeas
  have hmono : ∫ d, (max (Qstar - d) 0 + (Q - Qstar) * (Set.Iic Qstar).indicator (fun _ => (1 : ℝ)) d) ∂μ
      ≤ ∫ d, max (Q - d) 0 ∂μ := by
    apply integral_mono ((hint Qstar).add (hind.const_mul (Q - Qstar))) (hint Q)
    intro d
    by_cases hd : d ≤ Qstar
    · simp only [Pi.add_apply, Set.indicator, Set.mem_Iic, hd, ite_true, mul_one]
      rw [max_eq_left (by linarith : (0:ℝ) ≤ Qstar - d)]
      have := le_max_left (Q - d) 0
      linarith
    · simp only [Pi.add_apply, Set.indicator, Set.mem_Iic, hd, ite_false, mul_zero, add_zero]
      rw [max_eq_right (by linarith : Qstar - d ≤ 0)]
      exact le_max_right _ _
  rw [integral_add (hint Qstar) (hind.const_mul (Q - Qstar)), integral_const_mul,
    integral_indicator_const _ hmeas] at hmono
  rw [cdf_eq_real] at hFc
  simp only [smul_eq_mul, mul_one] at hmono
  have h1 := mul_le_mul_of_nonneg_left hmono hpv.le
  have h2 : (p - v) * ((Q - Qstar) * μ.real (Set.Iic Qstar)) = (p - c) * (Q - Qstar) := by
    rw [← hFc]; ring
  nlinarith [h1, h2]

-- Butter: D = 100 cases a week for 52 weeks.
example : (100 : ℕ) * 52 = 5200 := by norm_num
-- 2KD = 2 · 125 · 5200 = 1,300,000, and 2KD/h with h = £2.60 = 13/5 is 500,000.
example : (2 : ℚ) * 125 * 5200 = 1300000 := by norm_num
example : (2 : ℚ) * 125 * 5200 / (13 / 5) = 500000 := by norm_num
-- Q* = √500,000 lies between 707 and 708, so the best whole delivery is about 707 cases.
example : 707 ^ 2 ≤ 500000 ∧ 500000 < 708 ^ 2 := by norm_num
-- Two independent weeks with spread 20: variance 20² + 20² = 800.
example : (20 : ℕ) ^ 2 + 20 ^ 2 = 800 := by norm_num
-- Croissants: c_u = 2.80 - 0.70 = 2.10, c_o = 0.70 - 0, fractile 3/4.
example : ((14 / 5 : ℚ) - 7 / 10) / (((14 / 5 : ℚ) - 7 / 10) + (7 / 10 - 0)) = 3 / 4 := by norm_num
-- The flipped fractile c_o / (c_u + c_o) is 1/4.
example : ((7 / 10 : ℚ) - 0) / (((14 / 5 : ℚ) - 7 / 10) + (7 / 10 - 0)) = 1 / 4 := by norm_num
-- Baking cost of 140 croissants at £0.70: £98.
example : (7 / 10 : ℚ) * 140 = 98 := by norm_num

#print axioms eoq_minimizes_yearly_cost
#print axioms eoq_ordering_equals_holding
#print axioms newsvendor_critical_fractile
