-- Radon measures and the Riesz representation theorem: every positive linear rule on continuous compactly supported functions on n-dimensional space is the integral against exactly one Radon measure, that measure weighs open sets by functions inside them and compact sets by functions over them, and the rod rule f(0) + area over [0, 1] gives a point mass at 0 plus length on [0, 1].
import Mathlib.MeasureTheory.Integral.RieszMarkovKakutani.Real
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Measure.Dirac.Basic
import Mathlib.Analysis.Normed.Lp.MeasurableSpace
import Mathlib.Analysis.InnerProductSpace.PiL2

open MeasureTheory Set
open scoped CompactlySupported ENNReal

/-- A nonnegative compactly supported function that is at least `1` on a compact set `K`
bounds the measure of `K` by its integral. -/
theorem radon_helper_measure_le_integral {X : Type*} [TopologicalSpace X] [MeasurableSpace X]
    [BorelSpace X] [T2Space X] (μ : Measure X) [IsFiniteMeasureOnCompacts μ]
    (f : C_c(X, ℝ)) (hf : ∀ x, 0 ≤ f x) {K : Set X} (hK : IsCompact K)
    (hfK : ∀ x ∈ K, 1 ≤ f x) : μ K ≤ ENNReal.ofReal (∫ x, f x ∂μ) := by
  rw [ofReal_integral_eq_lintegral_ofReal f.integrable (Filter.Eventually.of_forall hf)]
  calc μ K = ∫⁻ x, K.indicator 1 x ∂μ := (lintegral_indicator_one hK.measurableSet).symm
    _ ≤ ∫⁻ x, ENNReal.ofReal (f x) ∂μ := by
      refine lintegral_mono fun x => ?_
      by_cases hx : x ∈ K
      · simpa [hx] using hfK x hx
      · simp [hx]

/-- A compactly supported function with values in `[0, 1]` and support inside an open set `U`
has integral at most the measure of `U`. -/
theorem radon_helper_integral_le_measure {X : Type*} [TopologicalSpace X] [MeasurableSpace X]
    [BorelSpace X] (μ : Measure X) [IsFiniteMeasureOnCompacts μ]
    (f : C_c(X, ℝ)) (hf : ∀ x, 0 ≤ f x ∧ f x ≤ 1) {U : Set X} (hU : IsOpen U)
    (hfU : tsupport f ⊆ U) : ENNReal.ofReal (∫ x, f x ∂μ) ≤ μ U := by
  rw [ofReal_integral_eq_lintegral_ofReal f.integrable
    (Filter.Eventually.of_forall fun x => (hf x).1)]
  calc ∫⁻ x, ENNReal.ofReal (f x) ∂μ ≤ ∫⁻ x, U.indicator 1 x ∂μ := by
        refine lintegral_mono fun x => ?_
        by_cases hx : x ∈ U
        · simpa [hx] using (hf x).2
        · have : f x = 0 := image_eq_zero_of_notMem_tsupport fun h => hx (hfU h)
          simp [hx, this]
    _ = μ U := lintegral_indicator_one hU.measurableSet

/-- The Riesz representation theorem on `ℝⁿ`: let `Λ` be a linear rule on the continuous functions
with compact support on `ℝⁿ` that is positive (`Λ f ≥ 0` whenever `f ≥ 0`). Then exactly one Radon
measure `μ` (finite on compact sets, outer regular, inner regular on open sets: Mathlib's
`Measure.Regular`) satisfies `Λ f = ∫ f dμ` for every such `f`. -/
theorem riesz_representation_positive_functional (n : ℕ)
    (Λ : C_c(EuclideanSpace ℝ (Fin n), ℝ) →ₗ[ℝ] ℝ)
    (hΛ : ∀ f : C_c(EuclideanSpace ℝ (Fin n), ℝ), (∀ x, 0 ≤ f x) → 0 ≤ Λ f) :
    ∃! μ : Measure (EuclideanSpace ℝ (Fin n)),
      μ.Regular ∧ ∀ f : C_c(EuclideanSpace ℝ (Fin n), ℝ), Λ f = ∫ x, f x ∂μ := by
  let Λ' : C_c(EuclideanSpace ℝ (Fin n), ℝ) →ₚ[ℝ] ℝ :=
    PositiveLinearMap.mk₀ Λ fun f hf => hΛ f fun x => hf x
  refine ⟨RealRMK.rieszMeasure Λ',
    ⟨inferInstance, fun f => by rw [RealRMK.integral_rieszMeasure]; rfl⟩, ?_⟩
  rintro ν ⟨hν, hνrep⟩
  have := hν
  exact Measure.ext_of_integral_eq_on_compactlySupported fun f => by
    rw [← hνrep, RealRMK.integral_rieszMeasure]
    rfl

/-- How the measure is read off the rule: if the Radon measure `μ` represents the positive linear
rule `Λ`, then an open set `U` weighs the most `Λ` gives a function with `0 ≤ f ≤ 1` whose support
lies inside `U`, and a compact set `K` weighs the least `Λ` gives a function that is never negative
and at least `1` on `K`. -/
theorem radon_measure_read_off_from_rule (n : ℕ)
    (Λ : C_c(EuclideanSpace ℝ (Fin n), ℝ) →ₗ[ℝ] ℝ)
    (hΛ : ∀ f : C_c(EuclideanSpace ℝ (Fin n), ℝ), (∀ x, 0 ≤ f x) → 0 ≤ Λ f)
    (μ : Measure (EuclideanSpace ℝ (Fin n))) (hμ : μ.Regular)
    (hrep : ∀ f : C_c(EuclideanSpace ℝ (Fin n), ℝ), Λ f = ∫ x, f x ∂μ) :
    (∀ U : Set (EuclideanSpace ℝ (Fin n)), IsOpen U →
      μ U = ⨆ (f : C_c(EuclideanSpace ℝ (Fin n), ℝ)) (_ : ∀ x, 0 ≤ f x ∧ f x ≤ 1)
        (_ : tsupport f ⊆ U), ENNReal.ofReal (Λ f)) ∧
    (∀ K : Set (EuclideanSpace ℝ (Fin n)), IsCompact K →
      μ K = ⨅ (f : C_c(EuclideanSpace ℝ (Fin n), ℝ)) (_ : ∀ x, 0 ≤ f x)
        (_ : ∀ x ∈ K, 1 ≤ f x), ENNReal.ofReal (Λ f)) := by
  have := hμ
  refine ⟨fun U hU => le_antisymm ?_ ?_, fun K hK => le_antisymm ?_ ?_⟩
  · refine le_of_forall_lt fun r hr => ?_
    obtain ⟨K, hKU, hK, hrK⟩ := hU.exists_lt_isCompact hr
    obtain ⟨g, hg1, hg2, hg3, hg4⟩ := exists_continuousMap_one_of_isCompact_subset_isOpen hK hU hKU
    let f : C_c(EuclideanSpace ℝ (Fin n), ℝ) := ⟨g, hg2⟩
    refine hrK.trans_le ?_
    refine le_trans ?_ (le_iSup_of_le f (le_iSup_of_le (fun x => hg4 x)
      (le_iSup_of_le hg3 le_rfl)))
    rw [hrep]
    exact radon_helper_measure_le_integral μ f (fun x => (hg4 x).1) hK
      fun x hx => (hg1 hx).ge
  · refine iSup_le fun f => iSup_le fun h1 => iSup_le fun h2 => ?_
    rw [hrep]
    exact radon_helper_integral_le_measure μ f h1 hU h2
  · refine le_iInf fun f => le_iInf fun h1 => le_iInf fun h2 => ?_
    rw [hrep]
    exact radon_helper_measure_le_integral μ f h1 hK h2
  · refine le_of_forall_gt fun r hr => ?_
    obtain ⟨U, hKU, hU, hUr⟩ := Set.exists_isOpen_lt_of_lt K r hr
    obtain ⟨g, hg1, hg2, hg3, hg4⟩ := exists_continuousMap_one_of_isCompact_subset_isOpen hK hU hKU
    let f : C_c(EuclideanSpace ℝ (Fin n), ℝ) := ⟨g, hg2⟩
    refine lt_of_le_of_lt (iInf_le_of_le f (iInf_le_of_le (fun x => (hg4 x).1)
      (iInf_le_of_le (fun x hx => (hg1 hx).ge) le_rfl))) ?_
    rw [hrep]
    exact (radon_helper_integral_le_measure μ f (fun x => hg4 x) hU hg3).trans_lt hUr

/-- The rod: the Radon measure on the line that represents the rule `f ↦ f(0) + ∫₀¹ f` is a point
mass of 1 at 0 plus length on `[0, 1]`. So `μ([0, 1]) = 2`, `μ((0, 1)) = 1`, `μ({0}) = 1` and
`μ((-1, 1/2)) = 3/2`. -/
theorem rod_rule_measure (μ : Measure ℝ) (hμ : μ.Regular)
    (hrep : ∀ f : C_c(ℝ, ℝ), f 0 + ∫ x in (0 : ℝ)..1, f x = ∫ x, f x ∂μ) :
    μ = Measure.dirac 0 + volume.restrict (Icc (0 : ℝ) 1) ∧
      μ (Icc 0 1) = 2 ∧ μ (Ioo 0 1) = 1 ∧ μ {0} = 1 ∧ μ (Ioo (-1) (1 / 2)) = 3 / 2 := by
  have := hμ
  have : IsFiniteMeasure (volume.restrict (Icc (0 : ℝ) 1)) :=
    isFiniteMeasure_restrict.mpr (by simp)
  have hμν : μ = Measure.dirac 0 + volume.restrict (Icc (0 : ℝ) 1) :=
    Measure.ext_of_integral_eq_on_compactlySupported fun f => by
      rw [← hrep, integral_add_measure f.integrable f.integrable, integral_dirac,
        intervalIntegral.integral_of_le zero_le_one, integral_Icc_eq_integral_Ioc]
  subst hμν
  refine ⟨rfl, ?_, ?_, ?_, ?_⟩
  · rw [Measure.add_apply, Measure.restrict_apply measurableSet_Icc, inter_self,
      Measure.dirac_apply_of_mem (by simp), Real.volume_Icc]
    norm_num
  · rw [Measure.add_apply, Measure.restrict_apply measurableSet_Ioo,
      inter_eq_left.mpr Ioo_subset_Icc_self, Measure.dirac_apply' _ measurableSet_Ioo,
      Real.volume_Ioo]
    simp
  · rw [Measure.add_apply, Measure.restrict_apply (measurableSet_singleton 0),
      Measure.dirac_apply_of_mem rfl]
    simp
  · have : Ioo (-1 : ℝ) (1 / 2) ∩ Icc 0 1 = Ico 0 (1 / 2) := by
      ext x
      simp only [mem_inter_iff, mem_Ioo, mem_Icc, mem_Ico]
      constructor
      · rintro ⟨⟨_, h2⟩, h3, _⟩
        exact ⟨h3, h2⟩
      · rintro ⟨h1, h2⟩
        exact ⟨⟨by linarith, h2⟩, h1, by linarith⟩
    rw [Measure.add_apply, Measure.restrict_apply measurableSet_Ioo, this,
      Measure.dirac_apply_of_mem (by norm_num), Real.volume_Ico]
    rw [← ENNReal.ofReal_one, ← ENNReal.ofReal_add (by norm_num) (by norm_num),
      show (1 : ℝ) + (1 / 2 - 0) = 3 / 2 by norm_num, ENNReal.ofReal_div_of_pos two_pos]
    simp

-- The card's hand-worked numbers, exactly.
-- A tent over [0, 1]: f(0) + area = 1 + 1.
example : (1 : ℚ) + 1 = 2 := by norm_num
-- A bump inside (0, 1) with ramps of width 1/8: 0 + (1 - 3/8).
example : (0 : ℚ) + (1 - 3 / 8) = 5 / 8 := by norm_num
-- A spike over {0} with half-width 1/100: 1 + 1/200.
example : (1 : ℚ) + 1 / (2 * 100) = 201 / 200 := by norm_num
-- The rule on 1 - x² over [-1, 1]: 1 + (1 - 1/3).
example : (1 : ℚ) + (1 - 1 / 3) = 5 / 3 := by norm_num
-- μ((-1, 1/2)): clamp plus half the rod.
example : (1 : ℚ) + 1 / 2 = 3 / 2 := by norm_num
-- Length on a plateau over [-10, 10] with ramps of width 1: 2R + 1 at R = 10 and R = 100.
example : 2 * 10 + 1 = 21 ∧ 2 * 100 + 1 = 201 := by decide

#print axioms radon_helper_measure_le_integral
#print axioms radon_helper_integral_le_measure
#print axioms riesz_representation_positive_functional
#print axioms radon_measure_read_off_from_rule
#print axioms rod_rule_measure
