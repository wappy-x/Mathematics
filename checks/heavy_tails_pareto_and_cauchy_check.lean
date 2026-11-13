-- Heavy tails: the Pareto density has area 1 and a finite k-th moment exactly when k is below its shape, while the standard Cauchy density has area 1, a finite average of |Z|^r exactly when r is below 1, and no mean.
import Mathlib.Probability.Distributions.Pareto
import Mathlib.Probability.Distributions.Cauchy
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.JapaneseBracket
import Mathlib.Analysis.SpecialFunctions.NonIntegrable

open MeasureTheory Real Filter Topology ProbabilityTheory

lemma pareto_aux_eq {a b : ℝ} (hb : 0 < b) (k : ℝ) :
    (fun x => x ^ k * paretoPDFReal b a x) =
      Set.indicator (Set.Ici b) (fun x => a * b ^ a * x ^ (k - (a + 1))) := by
  funext x
  by_cases hx : b ≤ x
  · have hx0 : 0 < x := lt_of_lt_of_le hb hx
    rw [Set.indicator_of_mem (Set.mem_Ici.mpr hx), paretoPDFReal, ite_eq_left hx,
      Real.rpow_sub hx0, Real.rpow_neg hx0.le]
    field_simp
  · rw [Set.indicator_of_notMem (by simpa using hx), paretoPDFReal, ite_eq_right hx, mul_zero]

lemma pareto_aux_integrable_iff {a b : ℝ} (ha : 0 < a) (hb : 0 < b) (k : ℝ) :
    Integrable (fun x => x ^ k * paretoPDFReal b a x) ↔ k < a := by
  rw [pareto_aux_eq hb, integrable_indicator_iff measurableSet_Ici,
    integrableOn_Ici_iff_integrableOn_Ioi]
  have hc : a * b ^ a ≠ 0 := by positivity
  rw [IntegrableOn, integrable_const_mul_iff (isUnit_iff_ne_zero.mpr hc), ← IntegrableOn,
    integrableOn_Ioi_rpow_iff hb]
  constructor <;> intro h <;> linarith

lemma pareto_aux_integral {a b : ℝ} (hb : 0 < b) (k : ℝ) (hk : k < a) :
    ∫ x, x ^ k * paretoPDFReal b a x = a * b ^ k / (a - k) := by
  rw [pareto_aux_eq hb, integral_indicator measurableSet_Ici, integral_Ici_eq_integral_Ioi,
    integral_const_mul, integral_Ioi_rpow_of_lt (by linarith) hb]
  have h1 : k - (a + 1) + 1 = k - a := by ring
  have h2 : b ^ k = b ^ a * b ^ (k - a) := by
    rw [← Real.rpow_add hb]; congr 1; ring
  have h3 : a - k ≠ 0 := (sub_pos.mpr hk).ne'
  have h4 : k - a ≠ 0 := (sub_neg.mpr hk).ne
  rw [h1, h2]
  field_simp
  ring

lemma cauchy_std_eq (z : ℝ) : cauchyPDFReal 0 1 z = π⁻¹ * (1 + z ^ 2)⁻¹ := by
  rw [cauchyPDFReal_def]
  simp [add_comm]

lemma cauchy_abs_rpow_integrable {r : ℝ} (hr0 : 0 ≤ r) (hr : r < 1) :
    Integrable (fun z => |z| ^ r * cauchyPDFReal 0 1 z) := by
  have hint : Integrable (fun z : ℝ => (2 * π⁻¹) * (1 + ‖z‖) ^ (-(2 - r))) :=
    (integrable_one_add_norm (by simp only [Module.finrank_self, Nat.cast_one]; linarith)).const_mul _
  refine hint.mono' ((continuous_abs.measurable.pow_const r).mul
    (measurable_cauchyPDFReal 0 1)).aestronglyMeasurable (Filter.Eventually.of_forall fun z => ?_)
  have hpi := Real.pi_pos
  rw [cauchy_std_eq, Real.norm_eq_abs, abs_of_nonneg (by positivity), Real.norm_eq_abs]
  have h1 : |z| ^ r ≤ (1 + |z|) ^ r := Real.rpow_le_rpow (abs_nonneg z) (by linarith) hr0
  have h2 : (1 + |z|) ^ (-(2 - r)) = (1 + |z|) ^ r / (1 + |z|) ^ 2 := by
    rw [show -(2 - r) = r - 2 by ring, Real.rpow_sub (by positivity), Real.rpow_two]
  rw [h2]
  have h3 : (1 + |z|) ^ 2 ≤ 2 * (1 + z ^ 2) := by
    nlinarith [sq_abs z, abs_nonneg z, sq_nonneg (|z| - 1)]
  have h4 : (1 + z ^ 2)⁻¹ ≤ 2 * ((1 + |z|) ^ 2)⁻¹ := by
    rw [← div_eq_mul_inv, inv_eq_one_div, div_le_div_iff₀ (by positivity) (by positivity)]
    nlinarith [h3]
  calc |z| ^ r * (π⁻¹ * (1 + z ^ 2)⁻¹)
      ≤ (1 + |z|) ^ r * (π⁻¹ * (2 * ((1 + |z|) ^ 2)⁻¹)) := by gcongr
    _ = 2 * π⁻¹ * ((1 + |z|) ^ r / (1 + |z|) ^ 2) := by ring

lemma cauchy_abs_rpow_not_integrable {r : ℝ} (hr : 1 ≤ r) :
    ¬ Integrable (fun z => |z| ^ r * cauchyPDFReal 0 1 z) := by
  intro h
  have h2 : IntegrableOn (fun z : ℝ => (2 * π) * (|z| ^ r * cauchyPDFReal 0 1 z)) (Set.Ioi 1) :=
    (h.const_mul _).integrableOn
  apply not_integrableOn_Ioi_inv (a := 1)
  refine h2.mono' measurable_inv.aestronglyMeasurable ?_
  filter_upwards [ae_restrict_mem measurableSet_Ioi] with z hz
  have hz1 : 1 < z := hz
  have hz0 : 0 < z := by linarith
  have hpi := Real.pi_pos
  rw [Real.norm_eq_abs, abs_inv, cauchy_std_eq, abs_of_pos hz0]
  have h1 : z ≤ z ^ r := by
    calc z = z ^ (1 : ℝ) := (Real.rpow_one z).symm
    _ ≤ z ^ r := Real.rpow_le_rpow_of_exponent_le hz1.le hr
  have h3 : 2 * π * (z * (π⁻¹ * (1 + z ^ 2)⁻¹)) = 2 * z / (1 + z ^ 2) := by
    field_simp
  calc z⁻¹ ≤ 2 * π * (z * (π⁻¹ * (1 + z ^ 2)⁻¹)) := by
        rw [h3, inv_eq_one_div, div_le_div_iff₀ hz0 (by positivity)]
        nlinarith
    _ ≤ 2 * π * (z ^ r * (π⁻¹ * (1 + z ^ 2)⁻¹)) := by gcongr

#print axioms pareto_aux_eq
#print axioms pareto_aux_integrable_iff
#print axioms pareto_aux_integral
#print axioms cauchy_std_eq
#print axioms cauchy_abs_rpow_integrable
#print axioms cauchy_abs_rpow_not_integrable

/-- The Pareto law with lower cutoff `b > 0` and shape `a > 0`, with density
`f(x) = a b^a / x^(a+1)` for `x ≥ b` and `0` below `b`, encloses area 1. Its `k`-th moment
`E[X^k]` is finite exactly when `k < a`, and then it equals `a b^k / (a - k)`. -/
theorem pareto_moment_finite_iff_lt_shape {a b : ℝ} (ha : 0 < a) (hb : 0 < b) :
    (∫ x, paretoPDFReal b a x = 1) ∧
    (∀ k : ℝ, Integrable (fun x => x ^ k * paretoPDFReal b a x) ↔ k < a) ∧
    (∀ k : ℝ, k < a → ∫ x, x ^ k * paretoPDFReal b a x = a * b ^ k / (a - k)) := by
  refine ⟨?_, pareto_aux_integrable_iff ha hb, fun k hk => pareto_aux_integral hb k hk⟩
  have := pareto_aux_integral (a := a) hb 0 ha
  simpa [ha.ne'] using this

/-- The standard Cauchy law, with density `g(z) = 1 / (π (1 + z^2))`, encloses area 1;
for a power `r ≥ 0`, the average `E[|Z|^r]` is finite exactly when `r < 1`; and so the
mean `E[Z]` does not exist (`z g(z)` is not integrable over the whole line). -/
theorem cauchy_abs_moment_finite_iff_lt_one :
    (∫ z, cauchyPDFReal 0 1 z = 1) ∧
    (∀ r : ℝ, 0 ≤ r → (Integrable (fun z => |z| ^ r * cauchyPDFReal 0 1 z) ↔ r < 1)) ∧
    ¬ Integrable (fun z => z * cauchyPDFReal 0 1 z) := by
  refine ⟨integral_cauchyPDFReal_eq_one 0 one_ne_zero, fun r hr0 =>
    ⟨fun h => ?_, fun h => cauchy_abs_rpow_integrable hr0 h⟩, ?_⟩
  · by_contra hr
    exact cauchy_abs_rpow_not_integrable (not_lt.mp hr) h
  · intro h
    apply cauchy_abs_rpow_not_integrable (r := 1) le_rfl
    refine h.norm.congr (Filter.Eventually.of_forall fun z => ?_)
    simp only [Real.norm_eq_abs, abs_mul, Real.rpow_one,
      abs_of_nonneg (cauchyPDF_pos 0 one_ne_zero z).le]

/-- For the standard Cauchy density, stopping the left side at `-R` and the right side at
`c R` (with `c > 0`) gives partial means that tend to `ln c / π` as `R` grows, so different
pairings of the cutoffs give different limits and none of them is a mean. -/
theorem cauchy_cutoff_mean_tendsto_log_div_pi {c : ℝ} (hc : 0 < c) :
    Tendsto (fun R : ℝ => ∫ z in (-R)..(c * R), z * cauchyPDFReal 0 1 z)
      atTop (𝓝 (Real.log c / π)) := by
  have hpi := Real.pi_pos
  have hderiv : ∀ x : ℝ, HasDerivAt (fun z : ℝ => Real.log (1 + z ^ 2) / (2 * π))
      (x * cauchyPDFReal 0 1 x) x := by
    intro x
    have h1 : HasDerivAt (fun z : ℝ => 1 + z ^ 2) (2 * x) x := by
      simpa using (hasDerivAt_pow 2 x).const_add 1
    have h2 := (h1.log (by positivity)).div_const (2 * π)
    convert h2 using 1
    rw [cauchy_std_eq]
    field_simp
  have hcont : Continuous fun z : ℝ => z * cauchyPDFReal 0 1 z := by
    simp_rw [cauchy_std_eq]
    exact continuous_id.mul (continuous_const.mul
      ((continuous_const.add (continuous_pow 2)).inv₀ (fun x => (by positivity : (0:ℝ) < 1 + x ^ 2).ne')))
  have heq : ∀ R : ℝ, ∫ z in (-R)..(c * R), z * cauchyPDFReal 0 1 z =
      Real.log (c ^ 2 + (1 - c ^ 2) * (1 + R ^ 2)⁻¹) / (2 * π) := by
    intro R
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hderiv x)
      (hcont.intervalIntegrable _ _)]
    have hA : 0 < 1 + R ^ 2 := by positivity
    have : c ^ 2 + (1 - c ^ 2) * (1 + R ^ 2)⁻¹ = (1 + (c * R) ^ 2) / (1 + (-R) ^ 2) := by
      field_simp
      ring
    rw [this, Real.log_div (by positivity) (by positivity)]
    ring
  simp_rw [heq]
  have hlim : Tendsto (fun R : ℝ => c ^ 2 + (1 - c ^ 2) * (1 + R ^ 2)⁻¹) atTop (𝓝 (c ^ 2)) := by
    have h0 : Tendsto (fun R : ℝ => (1 + R ^ 2)⁻¹) atTop (𝓝 0) :=
      tendsto_inv_atTop_zero.comp
        (tendsto_atTop_add_const_left _ 1 (tendsto_pow_atTop two_ne_zero))
    simpa using (h0.const_mul (1 - c ^ 2)).const_add (c ^ 2)
  have hlog := ((Real.continuousAt_log (by positivity : c ^ 2 ≠ 0)).tendsto.comp hlim).div_const
    (2 * π)
  rw [show Real.log c / π = Real.log (c ^ 2) / (2 * π) by
    rw [Real.log_pow]; push_cast; field_simp]
  exact hlog

-- Worked numbers with b = 1 and shape a = 3/2.
-- Mean fortune: a b / (a - 1) = 3.
example : (3 / 2 : ℚ) * 1 / (3 / 2 - 1) = 3 := by norm_num
-- Mean fortune above 10: a x / (a - 1) at x = 10 is 30.
example : (3 / 2 : ℚ) * 10 / (3 / 2 - 1) = 30 := by norm_num
-- The variance formula a b^2 / ((a-1)^2 (a-2)), used outside its range, gives -12.
example : (3 / 2 : ℚ) * 1 ^ 2 / ((3 / 2 - 1) ^ 2 * (3 / 2 - 2)) = -12 := by norm_num
-- Partial mean 3 (1 - R^(-1/2)) at R = 100, 10000, 1000000.
example : (3 : ℚ) * (1 - 1 / 10) = 27 / 10 := by norm_num
example : (3 : ℚ) * (1 - 1 / 100) = 297 / 100 := by norm_num
example : (3 : ℚ) * (1 - 1 / 1000) = 2997 / 1000 := by norm_num
-- Partial second moment 3 (R^(1/2) - 1) at R = 100, 10000, 1000000.
example : (3 : ℕ) * (10 - 1) = 27 := by decide
example : (3 : ℕ) * (100 - 1) = 297 := by decide
example : (3 : ℕ) * (1000 - 1) = 2997 := by norm_num
-- The square roots used: 100 = 10^2, 10000 = 100^2, 1000000 = 1000^2.
example : (10 : ℕ) ^ 2 = 100 ∧ (100 : ℕ) ^ 2 = 10000 ∧ (1000 : ℕ) ^ 2 = 1000000 := by norm_num

#print axioms pareto_moment_finite_iff_lt_shape
#print axioms cauchy_abs_moment_finite_iff_lt_one
#print axioms cauchy_cutoff_mean_tendsto_log_div_pi
