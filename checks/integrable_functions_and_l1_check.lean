-- Integrable functions: a real function is integrable exactly when its positive and negative parts have finite integrals, and on integrable functions the integral is linear, monotone, obeys the triangle inequality and is small on small sets.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.NonIntegrable

open MeasureTheory Set

/-- The definition, Step 1: a measurable real function is integrable exactly when the integral
of its size `|f|` is finite, exactly when its positive part `max f 0` and its negative part
`max (-f) 0` both have finite integral; and then its integral is the integral of the positive
part minus the integral of the negative part. -/
theorem integrable_iff_parts_finite_and_integral_eq_pos_sub_neg
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) {f : Ω → ℝ} (hf : Measurable f) :
    (Integrable f μ ↔ ∫⁻ x, ENNReal.ofReal |f x| ∂μ < ⊤) ∧
    (Integrable f μ ↔
      (∫⁻ x, ENNReal.ofReal (f x) ∂μ < ⊤ ∧ ∫⁻ x, ENNReal.ofReal (-f x) ∂μ < ⊤)) ∧
    (Integrable f μ →
      ∫ x, f x ∂μ =
        (∫⁻ x, ENNReal.ofReal (f x) ∂μ).toReal - (∫⁻ x, ENNReal.ofReal (-f x) ∂μ).toReal) := by
  have habs : (Integrable f μ ↔ ∫⁻ x, ENNReal.ofReal |f x| ∂μ < ⊤) := by
    rw [Integrable, hasFiniteIntegral_iff_norm]
    simp only [Real.norm_eq_abs]
    exact ⟨fun h => h.2, fun h => ⟨hf.aestronglyMeasurable, h⟩⟩
  have hsplit : ∫⁻ x, ENNReal.ofReal |f x| ∂μ =
      ∫⁻ x, ENNReal.ofReal (f x) ∂μ + ∫⁻ x, ENNReal.ofReal (-f x) ∂μ := by
    rw [← lintegral_add_left hf.ennreal_ofReal]
    congr 1
    funext x
    rcases le_total 0 (f x) with h | h
    · rw [abs_of_nonneg h, ENNReal.ofReal_of_nonpos (by linarith : -f x ≤ 0), add_zero]
    · rw [abs_of_nonpos h, ENNReal.ofReal_of_nonpos h, zero_add]
  refine ⟨habs, ?_, fun h => integral_eq_lintegral_pos_part_sub_lintegral_neg_part h⟩
  rw [habs, hsplit, ENNReal.add_lt_top]

/-- The four theorems: for integrable real functions `f`, `g` on any measure space and real
numbers `a`, `b`, the combination `a f + b g` is integrable and its integral is
`a ∫ f + b ∫ g` (linearity); if `f ≤ g` everywhere then `∫ f ≤ ∫ g` (monotonicity);
`|∫ f| ≤ ∫ |f|` (triangle inequality); and for every `ε > 0` there is `δ > 0` such that every
measurable set `A` of measure less than `δ` has `∫_A |f| < ε` (absolute continuity). -/
theorem integral_linear_monotone_triangle_abs_continuous
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) {f g : Ω → ℝ}
    (hf : Integrable f μ) (hg : Integrable g μ) (a b : ℝ) :
    (Integrable (fun x => a * f x + b * g x) μ ∧
      ∫ x, (a * f x + b * g x) ∂μ = a * ∫ x, f x ∂μ + b * ∫ x, g x ∂μ) ∧
    ((∀ x, f x ≤ g x) → ∫ x, f x ∂μ ≤ ∫ x, g x ∂μ) ∧
    |∫ x, f x ∂μ| ≤ ∫ x, |f x| ∂μ ∧
    (∀ ε : ℝ, 0 < ε → ∃ δ : ℝ, 0 < δ ∧
      ∀ A : Set Ω, MeasurableSet A → μ A < ENNReal.ofReal δ → ∫ x in A, |f x| ∂μ < ε) := by
  refine ⟨⟨?_, ?_⟩, fun hle => integral_mono hf hg hle, ?_, ?_⟩
  · exact (hf.const_mul a).add (hg.const_mul b)
  · rw [integral_add (hf.const_mul a) (hg.const_mul b), integral_const_mul, integral_const_mul]
  · simpa only [← Real.norm_eq_abs] using norm_integral_le_integral_norm (μ := μ) f
  · intro ε hε
    have hfin : ∫⁻ x, ENNReal.ofReal |f x| ∂μ ≠ ⊤ := by
      have := hf.2
      rw [hasFiniteIntegral_iff_norm] at this
      simpa only [Real.norm_eq_abs] using this.ne
    obtain ⟨δ₀, hδ₀, hδ⟩ := exists_pos_setLIntegral_lt_of_measure_lt hfin
      (ENNReal.ofReal_pos.mpr hε).ne'
    obtain ⟨r, hr0, hr1, hr2⟩ := ENNReal.lt_iff_exists_real_btwn.mp hδ₀
    refine ⟨r, ENNReal.ofReal_pos.mp hr1, fun A _ hA => ?_⟩
    have hl := hδ A (hA.trans hr2)
    rw [integral_eq_lintegral_of_nonneg_ae
      (Filter.Eventually.of_forall fun x => abs_nonneg (f x)) hf.abs.aestronglyMeasurable.restrict]
    exact ENNReal.toReal_lt_of_lt_ofReal hl

/-- Step 7, the hypothesis is needed: the function `1/x` on `(0, 1]` puts infinite integral
on every interval `(0, δ]` next to 0, however short. -/
theorem lintegral_inv_Ioc_zero_eq_top {δ : ℝ} (hδ : 0 < δ) (hδ1 : δ ≤ 1) :
    ∫⁻ x in Ioc (0 : ℝ) δ, ENNReal.ofReal (1 / x) = ⊤ := by
  by_contra hne
  have hint : IntegrableOn (fun x : ℝ => x⁻¹) (Ioc 0 δ) volume := by
    refine ⟨measurable_inv.aestronglyMeasurable, ?_⟩
    rw [hasFiniteIntegral_iff_ofReal]
    · simpa only [one_div] using lt_top_iff_ne_top.mpr hne
    · exact (ae_restrict_iff' measurableSet_Ioc).mpr
        (Filter.Eventually.of_forall fun x hx => inv_nonneg.mpr hx.1.le)
  have hii : IntervalIntegrable (fun x : ℝ => x⁻¹) volume 0 δ :=
    (intervalIntegrable_iff_integrableOn_Ioc_of_le hδ.le).mpr hint
  rw [intervalIntegrable_inv_iff] at hii
  rcases hii with h | h
  · exact hδ.ne h
  · exact h (by simp [hδ.le])

/-! The card's four-reach warm-up: midpoint depths `d = 7/16, 15/16, 15/16, 7/16` m on four
reaches of 1/4 km, and `h = d - 1/2`. -/

/-- The bed heights `h = d - 1/2` on the four reaches. -/
example : (![7/16, 15/16, 15/16, 7/16] : Fin 4 → ℚ) - (fun _ => 1/2)
    = ![-1/16, 7/16, 7/16, -1/16] := by
  ext i; fin_cases i <;> norm_num

-- positive part: (7/16 + 7/16) × 1/4 = 7/32
example : ∑ i : Fin 4, max ((![-1/16, 7/16, 7/16, -1/16] : Fin 4 → ℚ) i) 0 * (1/4) = 7/32 := by
  norm_num [Fin.sum_univ_four]

-- negative part: (1/16 + 1/16) × 1/4 = 1/32
example : ∑ i : Fin 4, max (-(![-1/16, 7/16, 7/16, -1/16] : Fin 4 → ℚ) i) 0 * (1/4) = 1/32 := by
  norm_num [Fin.sum_univ_four]

-- net 7/32 - 1/32 = 3/16, the same as by linearity 11/16 - 1/2; size 7/32 + 1/32 = 1/4
example : (7/32 : ℚ) - 1/32 = 3/16 ∧ (7/16 + 15/16 + 15/16 + 7/16) * (1/4 : ℚ) - 1/2 = 3/16 ∧
    (7/32 : ℚ) + 1/32 = 1/4 := by
  norm_num

#print axioms integrable_iff_parts_finite_and_integral_eq_pos_sub_neg
#print axioms integral_linear_monotone_triangle_abs_continuous
#print axioms lintegral_inv_Ioc_zero_eq_top
