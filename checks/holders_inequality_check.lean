-- Holder's inequality: for any measure and matched exponents 1/p + 1/q = 1 with p, q at least 1, the integral of the size of a product of two measurable functions is at most the p-size of the first times the q-size of the second, with its equality case and Young's inequality.
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Function.SpecialFunctions.RCLike
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.MeanInequalities
import Mathlib.MeasureTheory.Function.LpSeminorm.CompareExp

open MeasureTheory

/-- Holder's inequality. On any measure space, for real or complex functions `f` and `g`
measurable with respect to the space's sets, and exponents `p, q` with `1 ≤ p, q ≤ ∞` and
`1/p + 1/q = 1` (with `1/∞ = 0`), the integral of `|f g|` is at most the `p`-size of `f` times
the `q`-size of `g`: `∫ |f g| dμ ≤ ‖f‖_p ‖g‖_q`. Sizes may be infinite; the measure need not
be finite. At `p = q = 2` this is the Cauchy-Schwarz inequality. -/
theorem holder_lintegral_norm_mul_le_eLpNorm_mul_eLpNorm {Ω 𝕜 : Type*} [RCLike 𝕜]
    [MeasurableSpace Ω] (μ : Measure Ω) {p q : ENNReal} (hp : 1 ≤ p) (hq : 1 ≤ q)
    (hpq : p⁻¹ + q⁻¹ = 1) {f g : Ω → 𝕜} (hf : Measurable f) (hg : Measurable g) :
    ∫⁻ x, ‖f x * g x‖ₑ ∂μ ≤ eLpNorm f p μ * eLpNorm g q μ := by
  have : ENNReal.HolderTriple p q 1 := ⟨by simpa using hpq⟩
  have h := eLpNorm_smul_le_mul_eLpNorm (μ := μ) (p := p) (q := q) (r := 1)
    hf.aestronglyMeasurable hg.aestronglyMeasurable
  rw [eLpNorm_one_eq_lintegral_enorm (hf.smul hg).aestronglyMeasurable] at h
  simpa using h

/-- The equality case. For `1 < p < ∞` with `1/p + 1/q = 1`, and measurable `f`, `g` whose
`p`-size and `q`-size are finite and not zero, `∫ |f g| dμ = ‖f‖_p ‖g‖_q` exactly when
`α |f|^p = β |g|^q` almost everywhere for some constants `α, β ≥ 0`, not both zero. -/
theorem holder_eq_iff_rpow_proportional {Ω 𝕜 : Type*} [RCLike 𝕜] [MeasurableSpace Ω]
    (μ : Measure Ω) {p q : ℝ} (hp : 1 < p) (hpq : 1 / p + 1 / q = 1) {f g : Ω → 𝕜}
    (hf : Measurable f) (hg : Measurable g)
    (hf0 : eLpNorm f (ENNReal.ofReal p) μ ≠ 0) (hftop : eLpNorm f (ENNReal.ofReal p) μ ≠ ⊤)
    (hg0 : eLpNorm g (ENNReal.ofReal q) μ ≠ 0) (hgtop : eLpNorm g (ENNReal.ofReal q) μ ≠ ⊤) :
    ∫⁻ x, ‖f x * g x‖ₑ ∂μ = eLpNorm f (ENNReal.ofReal p) μ * eLpNorm g (ENNReal.ofReal q) μ ↔
      ∃ α β : ℝ, 0 ≤ α ∧ 0 ≤ β ∧ (α ≠ 0 ∨ β ≠ 0) ∧
        ∀ᵐ x ∂μ, α * ‖f x‖ ^ p = β * ‖g x‖ ^ q := by
  have hc : p.HolderConjugate q :=
    Real.holderConjugate_iff.mpr ⟨hp, by simpa [one_div] using hpq⟩
  have hp0 : 0 < p := hc.pos
  have hq0 : 0 < q := hc.symm.pos
  set A := eLpNorm f (ENNReal.ofReal p) μ with hA
  set B := eLpNorm g (ENNReal.ofReal q) μ with hB
  have hIf : ∫⁻ x, ‖f x‖ₑ ^ p ∂μ = A ^ p := by
    rw [lintegral_rpow_enorm_eq_rpow_eLpNorm' hp0, hA,
      eLpNorm_eq_eLpNorm' (by simpa using hp0) ENNReal.ofReal_ne_top hf.aestronglyMeasurable,
      ENNReal.toReal_ofReal hp0.le]
  have hIg : ∫⁻ x, ‖g x‖ₑ ^ q ∂μ = B ^ q := by
    rw [lintegral_rpow_enorm_eq_rpow_eLpNorm' hq0, hB,
      eLpNorm_eq_eLpNorm' (by simpa using hq0) ENNReal.ofReal_ne_top hg.aestronglyMeasurable,
      ENNReal.toReal_ofReal hq0.le]
  have hAp0 : A ^ p ≠ 0 := (ENNReal.rpow_pos (pos_iff_ne_zero.2 hf0) hftop).ne'
  have hApt : A ^ p ≠ ⊤ := ENNReal.rpow_ne_top_of_nonneg hp0.le hftop
  have hBq0 : B ^ q ≠ 0 := (ENNReal.rpow_pos (pos_iff_ne_zero.2 hg0) hgtop).ne'
  have hBqt : B ^ q ≠ ⊤ := ENNReal.rpow_ne_top_of_nonneg hq0.le hgtop
  set F : Ω → ENNReal := fun x => ‖f x‖ₑ / A with hFdef
  set G : Ω → ENNReal := fun x => ‖g x‖ₑ / B with hGdef
  have hFm : Measurable F := hf.enorm.div_const _
  have hGm : Measurable G := hg.enorm.div_const _
  have hFp : ∀ x, F x ^ p = ‖f x‖ₑ ^ p / A ^ p := fun x =>
    ENNReal.div_rpow_of_nonneg _ _ hp0.le
  have hGq : ∀ x, G x ^ q = ‖g x‖ₑ ^ q / B ^ q := fun x =>
    ENNReal.div_rpow_of_nonneg _ _ hq0.le
  have hFint : ∫⁻ x, F x ^ p ∂μ = 1 := by
    simp_rw [hFp, div_eq_mul_inv]
    rw [lintegral_mul_const _ (hf.enorm.pow_const p), hIf, ← div_eq_mul_inv,
      ENNReal.div_self hAp0 hApt]
  have hGint : ∫⁻ x, G x ^ q ∂μ = 1 := by
    simp_rw [hGq, div_eq_mul_inv]
    rw [lintegral_mul_const _ (hg.enorm.pow_const q), hIg, ← div_eq_mul_inv,
      ENNReal.div_self hBq0 hBqt]
  have hFG : ∫⁻ x, F x * G x ∂μ = (∫⁻ x, ‖f x * g x‖ₑ ∂μ) / (A * B) := by
    have : ∀ x, F x * G x = ‖f x * g x‖ₑ * (A * B)⁻¹ := by
      intro x
      simp only [hFdef, hGdef, div_eq_mul_inv, enorm_mul]
      rw [ENNReal.mul_inv (Or.inl hf0) (Or.inl hftop)]
      ring
    simp_rw [this]
    rw [lintegral_mul_const _ (show Measurable (fun x => ‖f x * g x‖ₑ) from (hf.mul hg).enorm),
      div_eq_mul_inv]
  set H : Ω → ENNReal := fun x => F x ^ p / ENNReal.ofReal p + G x ^ q / ENNReal.ofReal q
    with hHdef
  have hHm : Measurable H :=
    ((hFm.pow_const p).div_const _).add ((hGm.pow_const q).div_const _)
  have hHint : ∫⁻ x, H x ∂μ = 1 := by
    simp only [hHdef]
    rw [lintegral_add_left ((hFm.pow_const p).div_const _)]
    simp_rw [div_eq_mul_inv]
    rw [lintegral_mul_const _ (hFm.pow_const p), lintegral_mul_const _ (hGm.pow_const q),
      hFint, hGint, one_mul, one_mul, ← ENNReal.ofReal_inv_of_pos hp0,
      ← ENNReal.ofReal_inv_of_pos hq0, ← ENNReal.ofReal_add (inv_nonneg.2 hp0.le)
      (inv_nonneg.2 hq0.le), hc.inv_add_inv_eq_one, ENNReal.ofReal_one]
  have hY : ∀ x, F x * G x ≤ H x := fun x => ENNReal.young_inequality _ _ hc
  have hFtop : ∀ x, F x ≠ ⊤ := fun x => ENNReal.div_ne_top enorm_ne_top hf0
  have hGtop : ∀ x, G x ≠ ⊤ := fun x => ENNReal.div_ne_top enorm_ne_top hg0
  have hYe : ∀ x, F x * G x = H x ↔ F x ^ p = G x ^ q := by
    intro x
    rw [ENNReal.young_inequality_eq_iff _ _ hc]
    simp [hFtop x, hGtop x]
  have hAB0 : A * B ≠ 0 := mul_ne_zero hf0 hg0
  have hABt : A * B ≠ ⊤ := ENNReal.mul_ne_top hftop hgtop
  have step1 : ∫⁻ x, ‖f x * g x‖ₑ ∂μ = A * B ↔ ∫⁻ x, F x * G x ∂μ = 1 := by
    rw [hFG, ENNReal.div_eq_one_iff hAB0 hABt]
  have step2 : ∫⁻ x, F x * G x ∂μ = 1 ↔ ∀ᵐ x ∂μ, F x * G x = H x := by
    constructor
    · intro h
      exact ae_eq_of_ae_le_of_lintegral_le (ae_of_all _ hY) (by rw [h]; exact ENNReal.one_ne_top)
        hHm.aemeasurable (by rw [hHint, h])
    · intro h
      rw [lintegral_congr_ae h, hHint]
  have step3 : (∀ᵐ x ∂μ, F x * G x = H x) ↔ ∀ᵐ x ∂μ, F x ^ p = G x ^ q := by
    constructor
    · intro h
      filter_upwards [h] with x hx using (hYe x).1 hx
    · intro h
      filter_upwards [h] with x hx using (hYe x).2 hx
  have step4 : (∀ᵐ x ∂μ, F x ^ p = G x ^ q) ↔ ∃ α β : ℝ, 0 ≤ α ∧ 0 ≤ β ∧ (α ≠ 0 ∨ β ≠ 0) ∧
        ∀ᵐ x ∂μ, α * ‖f x‖ ^ p = β * ‖g x‖ ^ q := by
    constructor
    · intro h
      refine ⟨((A ^ p)⁻¹).toReal, ((B ^ q)⁻¹).toReal, ENNReal.toReal_nonneg,
        ENNReal.toReal_nonneg, Or.inl ?_, ?_⟩
      · rw [Ne, ENNReal.toReal_eq_zero_iff]
        simp [hAp0, hApt]
      · filter_upwards [h] with x hx
        have := congrArg ENNReal.toReal hx
        rw [hFp, hGq, div_eq_mul_inv, div_eq_mul_inv, ENNReal.toReal_mul, ENNReal.toReal_mul,
          ← ENNReal.toReal_rpow, ← ENNReal.toReal_rpow, toReal_enorm, toReal_enorm] at this
        rw [mul_comm, this, mul_comm]
    · rintro ⟨α, β, hα, hβ, hne, h⟩
      have h' : ∀ᵐ x ∂μ, ENNReal.ofReal α * ‖f x‖ₑ ^ p = ENNReal.ofReal β * ‖g x‖ₑ ^ q := by
        filter_upwards [h] with x hx
        rw [← ofReal_norm, ← ofReal_norm, ENNReal.ofReal_rpow_of_nonneg (norm_nonneg _) hp0.le,
          ENNReal.ofReal_rpow_of_nonneg (norm_nonneg _) hq0.le, ← ENNReal.ofReal_mul hα,
          ← ENNReal.ofReal_mul hβ, hx]
      have hint : ENNReal.ofReal α * A ^ p = ENNReal.ofReal β * B ^ q := by
        rw [← hIf, ← hIg, ← lintegral_const_mul _ (hf.enorm.pow_const p),
          ← lintegral_const_mul _ (hg.enorm.pow_const q)]
        exact lintegral_congr_ae h'
      have hα0 : α ≠ 0 := by
        intro h0
        rw [h0, ENNReal.ofReal_zero, zero_mul, eq_comm, mul_eq_zero] at hint
        rcases hint with hb | hb
        · rw [ENNReal.ofReal_eq_zero] at hb
          rcases hne with hne | hne
          · exact hne h0
          · exact hne (le_antisymm hb hβ)
        · exact hBq0 hb
      have hβ0 : β ≠ 0 := by
        intro h0
        rw [h0, ENNReal.ofReal_zero, zero_mul, mul_eq_zero] at hint
        rcases hint with hb | hb
        · rw [ENNReal.ofReal_eq_zero] at hb
          exact hα0 (le_antisymm hb hα)
        · exact hAp0 hb
      have ha0 : ENNReal.ofReal α ≠ 0 := by
        rw [Ne, ENNReal.ofReal_eq_zero, not_le]; exact lt_of_le_of_ne hα (Ne.symm hα0)
      have hb0 : ENNReal.ofReal β ≠ 0 := by
        rw [Ne, ENNReal.ofReal_eq_zero, not_le]; exact lt_of_le_of_ne hβ (Ne.symm hβ0)
      filter_upwards [h'] with x hx
      rw [hFp, hGq, ← ENNReal.mul_div_mul_left _ _ ha0 ENNReal.ofReal_ne_top,
        ← ENNReal.mul_div_mul_left (‖g x‖ₑ ^ q) _ hb0 ENNReal.ofReal_ne_top, hx, hint]
  rw [step1, step2, step3, step4]

/-- Young's inequality. For numbers `a, b ≥ 0` and `1 < p < ∞` with `1/p + 1/q = 1`,
`a b ≤ a^p / p + b^q / q`, with equality exactly when `a^p = b^q`. -/
theorem young_inequality_with_equality {a b p q : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) (hp : 1 < p)
    (hpq : 1 / p + 1 / q = 1) :
    a * b ≤ a ^ p / p + b ^ q / q ∧ (a * b = a ^ p / p + b ^ q / q ↔ a ^ p = b ^ q) := by
  have hc : p.HolderConjugate q :=
    Real.holderConjugate_iff.mpr ⟨hp, by simpa [one_div] using hpq⟩
  exact ⟨Real.young_inequality_of_nonneg ha hb hc, Real.young_inequality_eq_iff_of_nonneg ha hb hc⟩

-- The turbine week: winds 3, 5, 8, 2, 6, 4, 7 (MWh) and prices 60, 50, 30, 70, 40, 55, 35 ($/MWh).
-- Revenue is $1,515; the sums of squares are 203 and 17750.
example : ∑ i : Fin 7, ![3, 5, 8, 2, 6, 4, 7] i * ![60, 50, 30, 70, 40, 55, 35] i = 1515 := by
  decide
example : ∑ i : Fin 7, ![3, 5, 8, 2, 6, 4, 7] i ^ 2 = 203 := by decide
example : ∑ i : Fin 7, ![60, 50, 30, 70, 40, 55, 35] i ^ 2 = 17750 := by decide
-- Cauchy-Schwarz, squared: 1515^2 ≤ 203 × 17750, so $1,515 sits below the $1,898.22 ceiling.
example : (1515 : ℕ) ^ 2 ≤ 203 * 17750 := by norm_num
-- Lagrange's identity: the slack 203 × 17750 − 1515^2 = 1308025 is the sum of the 21 squares
-- (w_i c_j − w_j c_i)^2 over pairs of days i < j.
example : (203 * 17750 - 1515 ^ 2 : ℤ) = 1308025 := by norm_num
example : ∑ i : Fin 7, ∑ j : Fin 7, (if i < j then
      (![3, 5, 8, 2, 6, 4, 7] i * ![60, 50, 30, 70, 40, 55, 35] j
        - ![3, 5, 8, 2, 6, 4, 7] j * ![60, 50, 30, 70, 40, 55, 35] i : ℤ) ^ 2 else 0) = 1308025 := by
  decide
-- The ends: the wind's top 8 times the total price 340 is $2,720; the total wind 35 times the
-- price's top 70 is $2,450. Both lie above $1,515.
example : ∑ i : Fin 7, ![60, 50, 30, 70, 40, 55, 35] i = 340 := by decide
example : ∑ i : Fin 7, ![3, 5, 8, 2, 6, 4, 7] i = 35 := by decide
example : 8 * 340 = 2720 ∧ 35 * 70 = 2450 ∧ 1515 ≤ 2450 := by norm_num
-- Equality at p = 2: a price of 10 times the wind earns $2,030, and 2030^2 = 203 × (100 × 203).
example : ∑ i : Fin 7, ![3, 5, 8, 2, 6, 4, 7] i * (10 * ![3, 5, 8, 2, 6, 4, 7] i) = 2030 := by
  decide
example : (2030 : ℕ) ^ 2 = 203 * (100 * 203) := by norm_num
-- Equality at p = 3: a price of wind squared earns $1,295, which is also the sum of the cubes,
-- so the ceiling (∑ w^3)^(1/3) (∑ (w^2)^(3/2))^(2/3) is 1295 too.
example : ∑ i : Fin 7, ![3, 5, 8, 2, 6, 4, 7] i * ![3, 5, 8, 2, 6, 4, 7] i ^ 2 = 1295 := by decide
example : ∑ i : Fin 7, ![3, 5, 8, 2, 6, 4, 7] i ^ 3 = 1295 := by decide
-- Pairing the windiest day with the highest price earns $1,885, still below the ceiling:
-- 1885^2 ≤ 203 × 17750.
example : ∑ i : Fin 7, ![2, 3, 4, 5, 6, 7, 8] i * ![30, 35, 40, 50, 55, 60, 70] i = 1885 := by
  decide
example : (1515 : ℕ) < 1885 ∧ 1885 ^ 2 ≤ 203 * 17750 := by norm_num
-- Correlation: centred products add to −185, centred squares to 28 and 8650/7, and
-- ρ² = 185² / (28 × 8650/7) lies below 1.
example : ((7 * 1515 - 35 * 340 : ℚ) / 7) = -185 := by norm_num
example : ((7 * 203 - 35 ^ 2 : ℚ) / 7) = 28 ∧ ((7 * 17750 - 340 ^ 2 : ℚ) / 7) = 8650 / 7 := by
  norm_num
example : ((-185 : ℚ) ^ 2 / (28 * (8650 / 7))) < 1 := by norm_num
-- Young's picture at p = 3, a = 2, b = 3: the area a^3/3 = 8/3 is part of the cover of the
-- rectangle 2 × 3 = 6.
example : (2 : ℚ) ^ 3 / 3 = 8 / 3 ∧ (2 : ℚ) * 3 = 6 := by norm_num
-- Unmatched exponents: 1/3 + 1/3 is not 1.
example : (1 / 3 + 1 / 3 : ℚ) ≠ 1 := by norm_num

#print axioms holder_lintegral_norm_mul_le_eLpNorm_mul_eLpNorm
#print axioms holder_eq_iff_rpow_proportional
#print axioms young_inequality_with_equality
