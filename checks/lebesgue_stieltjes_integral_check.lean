-- The Lebesgue-Stieltjes integral: integrating g against the distribution function F of a random quantity X gives the average of g(X), the integral against a bounded-variation F is g times its jumps plus g times the slope of its absolutely continuous part, and integration by parts on (a, b] needs one extra term for every point where both functions jump.
import Mathlib.MeasureTheory.Measure.Stieltjes
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Function.AbsolutelyContinuous
import Mathlib.Topology.Order.LeftRightLim
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Tactic.NormNum
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.IntervalIntegral.AbsolutelyContinuousFun
import Mathlib.MeasureTheory.Integral.Bochner.SumMeasure
import Mathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap
import Mathlib.MeasureTheory.Integral.Lebesgue.Countable
import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.MeasureTheory.Function.LocallyIntegrable
import Mathlib.Analysis.Calculus.FDeriv.Measurable
import Mathlib.Algebra.Order.Group.MinMax

open MeasureTheory Set Function
open scoped ENNReal

lemma ls_hasSum_integral_countable_type {X : Type*} [MeasurableSpace X] [Countable X]
    [MeasurableSingletonClass X] {μ : Measure X} {f : X → ℝ} (hf : Integrable f μ) :
    HasSum (fun x => μ.real {x} * f x) (∫ x, f x ∂μ) := by
  have h1 : Integrable f (Measure.sum fun a => μ {a} • Measure.dirac a) := by
    rwa [Measure.sum_smul_dirac]
  have := hasSum_integral_measure h1
  rw [Measure.sum_smul_dirac] at this
  convert this using 1
  ext a
  rw [integral_smul_measure, integral_dirac, measureReal_def, smul_eq_mul]

#print axioms ls_hasSum_integral_countable_type

lemma ls_hasSum_setIntegral_countable {μ : Measure ℝ} (f : ℝ → ℝ) {s : Set ℝ}
    (hs : s.Countable) (hf : IntegrableOn f s μ) :
    HasSum (fun x => s.indicator (fun y => μ.real {y} * f y) x) (∫ x in s, f x ∂μ) := by
  have hi : Countable s := hs.to_subtype
  have hf' : Integrable (fun (x : s) ↦ f x) (Measure.comap Subtype.val μ) := by
    rw [IntegrableOn, ← map_comap_subtype_coe, integrable_map_measure] at hf
    · exact hf
    · exact hf.aestronglyMeasurable
    · exact measurable_subtype_coe.aemeasurable
    · exact hs.measurableSet
  rw [← integral_subtype_comap hs.measurableSet]
  have key := ls_hasSum_integral_countable_type hf'
  rw [← hasSum_subtype_iff_indicator]
  convert key using 1
  ext a
  simp only [Function.comp, measureReal_def]
  rw [Measure.comap_apply Subtype.val Subtype.coe_injective
    (fun s' hs' ↦ MeasurableSet.subtype_image hs.measurableSet hs') _ (MeasurableSet.singleton a)]
  simp

#print axioms ls_hasSum_setIntegral_countable

lemma ls_jump_nonneg (f : StieltjesFunction ℝ) (x : ℝ) : 0 ≤ f x - leftLim f x :=
  sub_nonneg.2 (f.mono.leftLim_le le_rfl)

#print axioms ls_jump_nonneg

lemma ls_real_singleton (f : StieltjesFunction ℝ) (x : ℝ) :
    f.measure.real {x} = f x - leftLim f x := by
  rw [measureReal_def, f.measure_singleton, ENNReal.toReal_ofReal (ls_jump_nonneg f x)]

#print axioms ls_real_singleton

lemma ls_jump_eq_zero (f : StieltjesFunction ℝ) {x : ℝ} (hx : x ∉ {x | leftLim f x ≠ f x}) :
    f x - leftLim f x = 0 := by
  simp only [ne_eq, mem_ofPred_eq, not_not] at hx
  rw [hx, sub_self]

#print axioms ls_jump_eq_zero

lemma ls_hasSum_atoms (f : StieltjesFunction ℝ) (h : ℝ → ℝ) {C : Set ℝ} (hC : C.Countable)
    (hsupp : ∀ x ∉ C, (f x - leftLim f x) * h x = 0)
    (hint : IntegrableOn h C f.measure) :
    HasSum (fun x => (f x - leftLim f x) * h x) (∫ x in C, h x ∂f.measure) := by
  have := ls_hasSum_setIntegral_countable h hC hint
  convert this using 1
  ext x
  by_cases hx : x ∈ C
  · simp [Set.indicator_of_mem hx, ls_real_singleton]
  · simp [Set.indicator_of_notMem hx, hsupp x hx]

#print axioms ls_hasSum_atoms

lemma ls_leftLim_sub (F : ℝ → ℝ) (F₁ F₂ : StieltjesFunction ℝ) (a x : ℝ) (hax : a < x)
    (hF : ∀ y ∈ Ioo a x, F y = F₁ y - F₂ y) :
    leftLim F x = leftLim F₁ x - leftLim F₂ x := by
  apply leftLim_eq_of_tendsto
  have h := (F₁.mono.tendsto_leftLim x).sub (F₂.mono.tendsto_leftLim x)
  refine h.congr' ?_
  filter_upwards [Ioo_mem_nhdsLT hax] with y hy
  exact (hF y hy).symm

#print axioms ls_leftLim_sub

lemma ls_integrableOn_Ioc (f : ℝ → ℝ) (hf : Monotone f) (g : StieltjesFunction ℝ) (a b : ℝ) :
    IntegrableOn f (Ioc a b) g.measure :=
  ((hf.monotoneOn _).integrableOn_isCompact isCompact_Icc).mono_set Ioc_subset_Icc_self

#print axioms ls_integrableOn_Ioc

lemma ls_ibp_core (f g : StieltjesFunction ℝ) (a b : ℝ) (hab : a ≤ b) :
    (∫ x in Ioc a b, f x ∂g.measure) + (∫ x in Ioc a b, g x ∂f.measure) - (f b * g b - f a * g a)
      = ∫ x in Ioc a b, (g x - leftLim g x) ∂f.measure := by
  set I := Ioc a b with hI
  have hIm : MeasurableSet I := measurableSet_Ioc
  have hffin : f.measure I ≠ ∞ := by rw [hI, f.measure_Ioc]; exact ENNReal.ofReal_ne_top
  have hgfin : g.measure I ≠ ∞ := by rw [hI, g.measure_Ioc]; exact ENNReal.ofReal_ne_top
  set μ := f.measure.restrict I with hμ
  set ν := g.measure.restrict I with hν
  have : IsFiniteMeasure μ := isFiniteMeasure_restrict.2 (by rw [f.measure_Ioc]; exact ENNReal.ofReal_ne_top)
  have : IsFiniteMeasure ν := isFiniteMeasure_restrict.2 (by rw [g.measure_Ioc]; exact ENNReal.ofReal_ne_top)
  set S₁ : Set (ℝ × ℝ) := {p | p.1 ≤ p.2} with hS₁
  set S₂ : Set (ℝ × ℝ) := {p | p.2 ≤ p.1} with hS₂
  have mS₁ : MeasurableSet S₁ := measurableSet_le measurable_fst measurable_snd
  have mS₂ : MeasurableSet S₂ := measurableSet_le measurable_snd measurable_fst
  have h1 : μ.prod ν S₁ = ∫⁻ y, μ (Iic y) ∂ν := by
    rw [Measure.prod_apply_symm mS₁]; rfl
  have h2 : μ.prod ν S₂ = ∫⁻ x, ν (Iic x) ∂μ := by
    rw [Measure.prod_apply mS₂]; rfl
  have h3 : μ.prod ν (S₁ ∪ S₂) = μ univ * ν univ := by
    have : S₁ ∪ S₂ = univ ×ˢ univ := by
      ext p; simp only [hS₁, hS₂, mem_union, mem_ofPred_eq, mem_prod, mem_univ, and_self,
        iff_true]; exact le_total _ _
    rw [this, Measure.prod_prod]
  have h4 : μ.prod ν (S₁ ∩ S₂) = ∫⁻ x, ν {x} ∂μ := by
    rw [Measure.prod_apply (mS₁.inter mS₂)]
    congr 1; ext x; congr 1; ext y
    simp only [hS₁, hS₂, mem_preimage, mem_inter_iff, mem_ofPred_eq, mem_singleton_iff]
    constructor
    · rintro ⟨h1, h2⟩; exact le_antisymm h2 h1
    · rintro rfl; exact ⟨le_rfl, le_rfl⟩
  have h5 := measure_union_add_inter (μ := μ.prod ν) S₁ mS₂
  -- integrability
  have fI : IntegrableOn (fun x => f x) I g.measure := ls_integrableOn_Ioc f f.mono g a b
  have gI : IntegrableOn (fun x => g x) I f.measure := ls_integrableOn_Ioc g g.mono f a b
  have gLI : IntegrableOn (fun x => leftLim g x) I f.measure :=
    ls_integrableOn_Ioc _ g.mono.leftLim f a b
  have fI' : IntegrableOn (fun y => f y - f a) I g.measure := fI.sub (integrableOn_const hgfin)
  have gI' : IntegrableOn (fun y => g y - g a) I f.measure := gI.sub (integrableOn_const hffin)
  have gJ : IntegrableOn (fun y => g y - leftLim g y) I f.measure := gI.sub gLI
  have hP0 : ∀ y ∈ I, 0 ≤ f y - f a := fun y hy => sub_nonneg.2 (f.mono hy.1.le)
  have hQ0 : ∀ y ∈ I, 0 ≤ g y - g a := fun y hy => sub_nonneg.2 (g.mono hy.1.le)
  have v1 : ∫⁻ y, μ (Iic y) ∂ν = ENNReal.ofReal (∫ y in I, (f y - f a) ∂g.measure) := by
    rw [ofReal_integral_eq_lintegral_ofReal fI'
      ((ae_restrict_iff' hIm).2 (Filter.Eventually.of_forall hP0))]
    apply setLIntegral_congr_fun hIm
    intro y hy
    simp only
    rw [hμ, Measure.restrict_apply measurableSet_Iic]
    have : Iic y ∩ I = Ioc a y := by
      ext z; simp only [hI, mem_inter_iff, mem_Iic, mem_Ioc]
      constructor
      · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
      · rintro ⟨h1, h2⟩; exact ⟨h2, h1, h2.trans hy.2⟩
    rw [this, f.measure_Ioc]
  have v2 : ∫⁻ x, ν (Iic x) ∂μ = ENNReal.ofReal (∫ y in I, (g y - g a) ∂f.measure) := by
    rw [ofReal_integral_eq_lintegral_ofReal gI'
      ((ae_restrict_iff' hIm).2 (Filter.Eventually.of_forall hQ0))]
    apply setLIntegral_congr_fun hIm
    intro y hy
    simp only
    rw [hν, Measure.restrict_apply measurableSet_Iic]
    have : Iic y ∩ I = Ioc a y := by
      ext z; simp only [hI, mem_inter_iff, mem_Iic, mem_Ioc]
      constructor
      · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
      · rintro ⟨h1, h2⟩; exact ⟨h2, h1, h2.trans hy.2⟩
    rw [this, g.measure_Ioc]
  have v3 : ∫⁻ x, ν {x} ∂μ = ENNReal.ofReal (∫ y in I, (g y - leftLim g y) ∂f.measure) := by
    rw [ofReal_integral_eq_lintegral_ofReal gJ
      ((ae_restrict_iff' hIm).2 (Filter.Eventually.of_forall fun y _ => ls_jump_nonneg g y))]
    apply setLIntegral_congr_fun hIm
    intro y hy
    simp only
    rw [hν, Measure.restrict_apply (measurableSet_singleton y),
      singleton_inter_of_mem hy, g.measure_singleton]
  have v4 : μ univ = ENNReal.ofReal (f b - f a) := by
    rw [hμ, Measure.restrict_apply_univ, f.measure_Ioc]
  have v5 : ν univ = ENNReal.ofReal (g b - g a) := by
    rw [hν, Measure.restrict_apply_univ, g.measure_Ioc]
  rw [h1, h2, h3, h4, v1, v2, v3, v4, v5] at h5
  have n1 : 0 ≤ f b - f a := sub_nonneg.2 (f.mono hab)
  have n2 : 0 ≤ g b - g a := sub_nonneg.2 (g.mono hab)
  have n3 : 0 ≤ ∫ y in I, (g y - leftLim g y) ∂f.measure :=
    setIntegral_nonneg hIm fun y _ => ls_jump_nonneg g y
  have n4 : 0 ≤ ∫ y in I, (f y - f a) ∂g.measure := setIntegral_nonneg hIm hP0
  have n5 : 0 ≤ ∫ y in I, (g y - g a) ∂f.measure := setIntegral_nonneg hIm hQ0
  rw [← ENNReal.ofReal_mul n1, ← ENNReal.ofReal_add (mul_nonneg n1 n2) n3,
    ← ENNReal.ofReal_add n4 n5,
    ENNReal.ofReal_eq_ofReal_iff (add_nonneg (mul_nonneg n1 n2) n3) (add_nonneg n4 n5)] at h5
  have r1 : ∫ y in I, (f y - f a) ∂g.measure = (∫ y in I, f y ∂g.measure) - (g b - g a) * f a := by
    rw [integral_sub fI (integrableOn_const hgfin), setIntegral_const, measureReal_def, g.measure_Ioc,
      ENNReal.toReal_ofReal n2, smul_eq_mul]
  have r2 : ∫ y in I, (g y - g a) ∂f.measure = (∫ y in I, g y ∂f.measure) - (f b - f a) * g a := by
    rw [integral_sub gI (integrableOn_const hffin), setIntegral_const, measureReal_def, f.measure_Ioc,
      ENNReal.toReal_ofReal n1, smul_eq_mul]
  rw [r1, r2] at h5
  linear_combination -h5

#print axioms ls_ibp_core

/-- The average of g(X) is the integral of g against F: if `X` is a random quantity on a
probability space and `F` is its distribution function, `F x = P(X ≤ x)`, then for every Borel
`g ≥ 0` (integral possibly infinite) the average of `g(X)` equals the integral of `g` against the
measure `F` builds, and the same holds for every Borel `g` of both signs whose integral against
`F` is finite. -/
theorem expectation_eq_integral_against_distribution_function
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (hX : Measurable X) (F : StieltjesFunction ℝ)
    (hF : ∀ x, F x = (P {ω | X ω ≤ x}).toReal) :
    (∀ g : ℝ → ℝ≥0∞, Measurable g → ∫⁻ ω, g (X ω) ∂P = ∫⁻ x, g x ∂F.measure) ∧
      (∀ g : ℝ → ℝ, Measurable g → Integrable g F.measure →
        ∫ ω, g (X ω) ∂P = ∫ x, g x ∂F.measure) := by
  have : IsProbabilityMeasure (P.map X) := inferInstance
  have hFeq : F = ProbabilityTheory.cdf (P.map X) := by
    ext x
    rw [hF, ProbabilityTheory.cdf_eq_real, measureReal_def, Measure.map_apply hX measurableSet_Iic]
    rfl
  have hμ : F.measure = P.map X := by rw [hFeq]; exact ProbabilityTheory.measure_cdf _
  refine ⟨fun g hg => ?_, fun g hg _ => ?_⟩
  · rw [hμ, lintegral_map hg hX]
  · rw [hμ, integral_map hX.aemeasurable hg.aestronglyMeasurable]

/-- Jumps plus a density: let `F = F₁ - F₂` be right-continuous of bounded variation, split into
two increasing right-continuous functions, with `∫ g dF = ∫ g dμ_{F₁} - ∫ g dμ_{F₂}`. Suppose
its continuous part `F_c` (the change of `F` minus the sum of its jumps, on every `(a, b]`) is
absolutely continuous on every bounded interval. Then for every Borel `g` with finite integral,
`∫ g dF` is the sum over all points `x` of `g(x)` times the jump `F(x) - F(x-)`, plus the ordinary
integral of `g` times the slope `F_c'`. -/
theorem integral_eq_sum_over_jumps_add_integral_against_slope
    (F : ℝ → ℝ) (F₁ F₂ : StieltjesFunction ℝ) (hF : ∀ x, F x = F₁ x - F₂ x)
    (Fc : ℝ → ℝ)
    (hFc : ∀ a b : ℝ, a ≤ b →
      (F b - F a) - (Fc b - Fc a) = ∑' x : Ioc a b, (F x - leftLim F x))
    (hac : ∀ a b : ℝ, AbsolutelyContinuousOnInterval Fc a b)
    (g : ℝ → ℝ) (hg : Measurable g)
    (hg₁ : Integrable g F₁.measure) (hg₂ : Integrable g F₂.measure) :
    ∫ x, g x ∂F₁.measure - ∫ x, g x ∂F₂.measure =
      ∑' x : ℝ, g x * (F x - leftLim F x) + ∫ x, g x * deriv Fc x := by
  set h := deriv Fc with hh
  have hmeas : Measurable h := measurable_deriv Fc
  set ν₁ := F₁.measure.restrict {x | leftLim F₁ x ≠ F₁ x} with hν₁
  set ν₂ := F₂.measure.restrict {x | leftLim F₂ x ≠ F₂ x} with hν₂
  set lp : Measure ℝ := volume.withDensity (fun x => ((h x).toNNReal : ℝ≥0∞)) with hlp
  set lm : Measure ℝ := volume.withDensity (fun x => ((-h x).toNNReal : ℝ≥0∞)) with hlm
  have hjump : ∀ x, F x - leftLim F x = (F₁ x - leftLim F₁ x) - (F₂ x - leftLim F₂ x) := by
    intro x
    rw [ls_leftLim_sub F F₁ F₂ (x - 1) x (by linarith) (fun y _ => hF y), hF x]
    ring
  have hint : ∀ a b : ℝ, a ≤ b → IntegrableOn h (Ioc a b) := fun a b hab =>
    (intervalIntegrable_iff_integrableOn_Ioc_of_le hab).1 (hac a b).intervalIntegrable_deriv
  have hftc : ∀ a b : ℝ, a ≤ b → ∫ x in Ioc a b, h x = Fc b - Fc a := by
    intro a b hab
    rw [← intervalIntegral.integral_of_le hab]
    exact (hac a b).integral_deriv_eq_sub
  have hlpI : ∀ a b, lp (Ioc a b) = ∫⁻ x in Ioc a b, ENNReal.ofReal (h x) := fun a b =>
    withDensity_apply _ measurableSet_Ioc
  have hlmI : ∀ a b, lm (Ioc a b) = ∫⁻ x in Ioc a b, ENNReal.ofReal (-h x) := fun a b =>
    withDensity_apply _ measurableSet_Ioc
  have hsplit : ∀ a b, a ≤ b →
      ∫ x in Ioc a b, h x = (lp (Ioc a b)).toReal - (lm (Ioc a b)).toReal := by
    intro a b hab
    rw [hlpI, hlmI]
    exact integral_eq_lintegral_pos_part_sub_lintegral_neg_part (hint a b hab)
  have hlp_fin : ∀ a b, a ≤ b → lp (Ioc a b) ≠ ∞ := fun a b hab => by
    rw [hlpI]; exact (hint a b hab).lintegral_lt_top.ne
  have hlm_fin : ∀ a b, a ≤ b → lm (Ioc a b) ≠ ∞ := fun a b hab => by
    rw [hlmI]; exact (hint a b hab).neg.lintegral_lt_top.ne
  have hjs : ∀ (f : StieltjesFunction ℝ) (a b : ℝ),
      HasSum (fun x => (Ioc a b).indicator (fun y => f y - leftLim f y) x)
        ((f.measure.restrict {x | leftLim f x ≠ f x}) (Ioc a b)).toReal := by
    intro f a b
    have hfin : f.measure (Ioc a b) ≠ ∞ := by rw [f.measure_Ioc]; exact ENNReal.ofReal_ne_top
    have := ls_hasSum_atoms f ((Ioc a b).indicator 1) f.countable_leftLim_ne
      (fun x hx => by rw [ls_jump_eq_zero f hx, zero_mul])
      ((integrable_indicator_iff measurableSet_Ioc).2 (integrableOn_const hfin)).integrableOn
    convert this using 1
    · ext x
      by_cases hx : x ∈ Ioc a b <;> simp [hx]
    · rw [integral_indicator_one measurableSet_Ioc, measureReal_def]
  have hν_fin : ∀ (f : StieltjesFunction ℝ) (a b : ℝ),
      (f.measure.restrict {x | leftLim f x ≠ f x}) (Ioc a b) ≠ ∞ := fun f a b =>
    ne_top_of_le_ne_top (by rw [f.measure_Ioc]; exact ENNReal.ofReal_ne_top)
      (Measure.restrict_apply_le _ _)
  have hsumI : ∀ a b, ∑' x : Ioc a b, (F x - leftLim F x) =
      (ν₁ (Ioc a b)).toReal - (ν₂ (Ioc a b)).toReal := by
    intro a b
    rw [tsum_subtype (Ioc a b) (fun x => F x - leftLim F x)]
    rw [← ((hjs F₁ a b).sub (hjs F₂ a b)).tsum_eq]
    congr 1
    ext x
    by_cases hx : x ∈ Ioc a b <;> simp [hx, hjump]
  have hM : F₁.measure + ν₂ + lm = F₂.measure + ν₁ + lp := by
    have m1 : ∀ a b, F₁.measure (Ioc a b) ≠ ∞ := fun a b => by
      rw [F₁.measure_Ioc]; exact ENNReal.ofReal_ne_top
    have m2 : ∀ a b, F₂.measure (Ioc a b) ≠ ∞ := fun a b => by
      rw [F₂.measure_Ioc]; exact ENNReal.ofReal_ne_top
    apply Measure.ext_of_Ioc'
    · intro a b hab
      simp only [Measure.coe_add, Pi.add_apply]
      exact ENNReal.add_ne_top.2 ⟨ENNReal.add_ne_top.2 ⟨m1 a b, hν_fin F₂ a b⟩,
        hlm_fin a b hab.le⟩
    · intro a b hab
      simp only [Measure.coe_add, Pi.add_apply]
      rw [← ENNReal.toReal_eq_toReal_iff'
        (ENNReal.add_ne_top.2 ⟨ENNReal.add_ne_top.2 ⟨m1 a b, hν_fin F₂ a b⟩, hlm_fin a b hab.le⟩)
        (ENNReal.add_ne_top.2 ⟨ENNReal.add_ne_top.2 ⟨m2 a b, hν_fin F₁ a b⟩, hlp_fin a b hab.le⟩),
        ENNReal.toReal_add (ENNReal.add_ne_top.2 ⟨m1 a b, hν_fin F₂ a b⟩) (hlm_fin a b hab.le),
        ENNReal.toReal_add (ENNReal.add_ne_top.2 ⟨m2 a b, hν_fin F₁ a b⟩) (hlp_fin a b hab.le),
        ENNReal.toReal_add (m1 a b) (hν_fin F₂ a b), ENNReal.toReal_add (m2 a b) (hν_fin F₁ a b),
        F₁.measure_Ioc, F₂.measure_Ioc, ENNReal.toReal_ofReal (sub_nonneg.2 (F₁.mono hab.le)),
        ENNReal.toReal_ofReal (sub_nonneg.2 (F₂.mono hab.le))]
      have e1 := hFc a b hab.le
      rw [hsumI, hF a, hF b] at e1
      have e2 := hsplit a b hab.le
      have e3 := hftc a b hab.le
      linarith
  have hP : MeasurableSet {x | 0 ≤ h x} := measurableSet_le measurable_const hmeas
  have hN : MeasurableSet {x | h x ≤ 0} := measurableSet_le hmeas measurable_const
  have lm_P : lm.restrict {x | 0 ≤ h x} = 0 := by
    rw [Measure.restrict_eq_zero, hlm, withDensity_apply _ hP]
    calc ∫⁻ x in {x | 0 ≤ h x}, ((-h x).toNNReal : ℝ≥0∞)
        = ∫⁻ x in {x | 0 ≤ h x}, 0 := setLIntegral_congr_fun hP (fun x hx => by
          simp only [ENNReal.coe_eq_zero, Real.toNNReal_eq_zero]
          exact neg_nonpos.2 hx)
      _ = 0 := lintegral_zero
  have lp_Pc : lp.restrict {x | 0 ≤ h x}ᶜ = 0 := by
    rw [Measure.restrict_eq_zero, hlp, withDensity_apply _ hP.compl]
    calc ∫⁻ x in {x | 0 ≤ h x}ᶜ, ((h x).toNNReal : ℝ≥0∞)
        = ∫⁻ x in {x | 0 ≤ h x}ᶜ, 0 := setLIntegral_congr_fun hP.compl (fun x hx => by
          simp only [mem_compl_iff, mem_ofPred_eq, not_le] at hx
          simp only [ENNReal.coe_eq_zero, Real.toNNReal_eq_zero]
          exact hx.le)
      _ = 0 := lintegral_zero
  have lp_N : lp.restrict {x | h x ≤ 0} = 0 := by
    rw [Measure.restrict_eq_zero, hlp, withDensity_apply _ hN]
    calc ∫⁻ x in {x | h x ≤ 0}, ((h x).toNNReal : ℝ≥0∞)
        = ∫⁻ x in {x | h x ≤ 0}, 0 := setLIntegral_congr_fun hN (fun x hx => by
          simp only [ENNReal.coe_eq_zero, Real.toNNReal_eq_zero]
          exact hx)
      _ = 0 := lintegral_zero
  have lm_Nc : lm.restrict {x | h x ≤ 0}ᶜ = 0 := by
    rw [Measure.restrict_eq_zero, hlm, withDensity_apply _ hN.compl]
    calc ∫⁻ x in {x | h x ≤ 0}ᶜ, ((-h x).toNNReal : ℝ≥0∞)
        = ∫⁻ x in {x | h x ≤ 0}ᶜ, 0 := setLIntegral_congr_fun hN.compl (fun x hx => by
          simp only [mem_compl_iff, mem_ofPred_eq, not_le] at hx
          simp only [ENNReal.coe_eq_zero, Real.toNNReal_eq_zero]
          linarith)
      _ = 0 := lintegral_zero
  have hlp_le : lp ≤ F₁.measure + ν₂ := by
    have e := congrArg (fun m : Measure ℝ => m.restrict {x | 0 ≤ h x}) hM
    simp only [Measure.restrict_add, lm_P, add_zero] at e
    rw [Measure.le_iff']
    intro s
    calc lp s = lp.restrict {x | 0 ≤ h x} s + lp.restrict {x | 0 ≤ h x}ᶜ s := by
          rw [← Measure.add_apply, Measure.restrict_add_restrict_compl hP]
      _ = lp.restrict {x | 0 ≤ h x} s := by rw [lp_Pc, Measure.coe_zero, Pi.zero_apply, add_zero]
      _ ≤ (F₂.measure.restrict {x | 0 ≤ h x} + ν₁.restrict {x | 0 ≤ h x} +
            lp.restrict {x | 0 ≤ h x}) s := by
          rw [Measure.add_apply]; exact le_add_self
      _ = (F₁.measure.restrict {x | 0 ≤ h x} + ν₂.restrict {x | 0 ≤ h x}) s :=
          (congrArg (fun m : Measure ℝ => m s) e).symm
      _ ≤ (F₁.measure + ν₂) s := by
          rw [Measure.add_apply, Measure.add_apply]
          exact add_le_add (Measure.restrict_apply_le _ _) (Measure.restrict_apply_le _ _)
  have hlm_le : lm ≤ F₂.measure + ν₁ := by
    have e := congrArg (fun m : Measure ℝ => m.restrict {x | h x ≤ 0}) hM
    simp only [Measure.restrict_add, lp_N, add_zero] at e
    rw [Measure.le_iff']
    intro s
    calc lm s = lm.restrict {x | h x ≤ 0} s + lm.restrict {x | h x ≤ 0}ᶜ s := by
          rw [← Measure.add_apply, Measure.restrict_add_restrict_compl hN]
      _ = lm.restrict {x | h x ≤ 0} s := by rw [lm_Nc, Measure.coe_zero, Pi.zero_apply, add_zero]
      _ ≤ (F₁.measure.restrict {x | h x ≤ 0} + ν₂.restrict {x | h x ≤ 0} +
            lm.restrict {x | h x ≤ 0}) s := by
          rw [Measure.add_apply]; exact le_add_self
      _ = (F₂.measure.restrict {x | h x ≤ 0} + ν₁.restrict {x | h x ≤ 0}) s :=
          congrArg (fun m : Measure ℝ => m s) e
      _ ≤ (F₂.measure + ν₁) s := by
          rw [Measure.add_apply, Measure.add_apply]
          exact add_le_add (Measure.restrict_apply_le _ _) (Measure.restrict_apply_le _ _)
  have in1 : Integrable g ν₁ := hg₁.mono_measure Measure.restrict_le_self
  have in2 : Integrable g ν₂ := hg₂.mono_measure Measure.restrict_le_self
  have ilp : Integrable g lp := (hg₁.add_measure in2).mono_measure hlp_le
  have ilm : Integrable g lm := (hg₂.add_measure in1).mono_measure hlm_le
  have e := congrArg (fun m : Measure ℝ => ∫ x, g x ∂m) hM
  rw [integral_add_measure (hg₁.add_measure in2) ilm, integral_add_measure hg₁ in2,
    integral_add_measure (hg₂.add_measure in1) ilp, integral_add_measure hg₂ in1] at e
  have hs₁ : HasSum (fun x => g x * (F₁ x - leftLim F₁ x)) (∫ x, g x ∂ν₁) := by
    have := ls_hasSum_atoms F₁ g F₁.countable_leftLim_ne
      (fun x hx => by rw [ls_jump_eq_zero F₁ hx, zero_mul]) hg₁.integrableOn
    convert this using 1
    ext x
    ring
  have hs₂ : HasSum (fun x => g x * (F₂ x - leftLim F₂ x)) (∫ x, g x ∂ν₂) := by
    have := ls_hasSum_atoms F₂ g F₂.countable_leftLim_ne
      (fun x hx => by rw [ls_jump_eq_zero F₂ hx, zero_mul]) hg₂.integrableOn
    convert this using 1
    ext x
    ring
  have hsum : ∑' x, g x * (F x - leftLim F x) = ∫ x, g x ∂ν₁ - ∫ x, g x ∂ν₂ := by
    rw [← (hs₁.sub hs₂).tsum_eq]
    congr 1
    ext x
    rw [hjump]
    ring
  have hm1 : Measurable fun x => (h x).toNNReal := hmeas.real_toNNReal
  have hm2 : Measurable fun x => (-h x).toNNReal := hmeas.neg.real_toNNReal
  have ilp' : Integrable (fun x => (h x).toNNReal • g x) :=
    (integrable_withDensity_iff_integrable_smul hm1).1 ilp
  have ilm' : Integrable (fun x => (-h x).toNNReal • g x) :=
    (integrable_withDensity_iff_integrable_smul hm2).1 ilm
  have hdens : ∫ x, g x ∂lp - ∫ x, g x ∂lm = ∫ x, g x * h x := by
    rw [hlp, hlm, integral_withDensity_eq_integral_smul hm1,
      integral_withDensity_eq_integral_smul hm2, ← integral_sub ilp' ilm']
    congr 1
    ext x
    rw [NNReal.smul_def, NNReal.smul_def, smul_eq_mul, smul_eq_mul, Real.coe_toNNReal',
      Real.coe_toNNReal']
    have := max_zero_sub_eq_self (h x)
    linear_combination (g x) * this
  rw [hsum, ← hdens]
  linarith

/-- Integration by parts with the jump term: let `F` and `G` be right-continuous and of bounded
variation on `[a, b]`, written on `[a, b]` as `F = F₁ - F₂` and `G = G₁ - G₂` with increasing
right-continuous parts, and integrate against them by `∫ h dF = ∫ h dμ_{F₁} - ∫ h dμ_{F₂}`. Then
`∫_(a,b] F dG + ∫_(a,b] G dF = F(b) G(b) - F(a) G(a) + Σ_{a < x ≤ b} ΔF(x) ΔG(x)`, where
`ΔF(x) = F(x) - F(x-)` is the jump of `F` at `x`. -/
theorem integration_by_parts_with_jump_term
    (a b : ℝ) (hab : a ≤ b) (F G : ℝ → ℝ) (F₁ F₂ G₁ G₂ : StieltjesFunction ℝ)
    (hF : ∀ x ∈ Icc a b, F x = F₁ x - F₂ x) (hG : ∀ x ∈ Icc a b, G x = G₁ x - G₂ x) :
    ((∫ x in Ioc a b, F x ∂G₁.measure) - ∫ x in Ioc a b, F x ∂G₂.measure) +
        ((∫ x in Ioc a b, G x ∂F₁.measure) - ∫ x in Ioc a b, G x ∂F₂.measure) =
      F b * G b - F a * G a +
        ∑' x : Ioc a b, (F x - leftLim F x) * (G x - leftLim G x) := by
  set I := Ioc a b with hI
  have hIm : MeasurableSet I := measurableSet_Ioc
  have hjF : ∀ x ∈ I, F x - leftLim F x = (F₁ x - leftLim F₁ x) - (F₂ x - leftLim F₂ x) := by
    intro x hx
    rw [ls_leftLim_sub F F₁ F₂ a x hx.1 (fun y hy => hF y ⟨hy.1.le, hy.2.le.trans hx.2⟩),
      hF x (Ioc_subset_Icc_self hx)]
    ring
  have hjG : ∀ x ∈ I, G x - leftLim G x = (G₁ x - leftLim G₁ x) - (G₂ x - leftLim G₂ x) := by
    intro x hx
    rw [ls_leftLim_sub G G₁ G₂ a x hx.1 (fun y hy => hG y ⟨hy.1.le, hy.2.le.trans hx.2⟩),
      hG x (Ioc_subset_Icc_self hx)]
    ring
  have hS : ∀ f g : StieltjesFunction ℝ,
      HasSum (fun x => I.indicator (fun y => (f y - leftLim f y) * (g y - leftLim g y)) x)
        (∫ x in I, (g x - leftLim g x) ∂f.measure) := by
    intro f g
    have gJ : IntegrableOn (fun y => g y - leftLim g y) I f.measure :=
      (ls_integrableOn_Ioc _ g.mono f a b).sub (ls_integrableOn_Ioc _ g.mono.leftLim f a b)
    have hz : ∀ x ∉ {x | leftLim g x ≠ g x},
        I.indicator (fun y => g y - leftLim g y) x = 0 := by
      intro x hx
      by_cases hxI : x ∈ I
      · rw [indicator_of_mem hxI, ls_jump_eq_zero g hx]
      · rw [indicator_of_notMem hxI]
    have := ls_hasSum_atoms f (I.indicator fun y => g y - leftLim g y) g.countable_leftLim_ne
      (fun x hx => by rw [hz x hx, mul_zero])
      ((integrable_indicator_iff hIm).2 gJ).integrableOn
    rw [setIntegral_eq_integral_of_forall_compl_eq_zero hz, integral_indicator hIm] at this
    convert this using 1
    ext x
    by_cases hx : x ∈ I <;> simp [hx]
  have hIF : ∀ m : StieltjesFunction ℝ, ∫ x in I, F x ∂m.measure =
      ∫ x in I, F₁ x ∂m.measure - ∫ x in I, F₂ x ∂m.measure := by
    intro m
    rw [← integral_sub (ls_integrableOn_Ioc _ F₁.mono m a b) (ls_integrableOn_Ioc _ F₂.mono m a b)]
    exact setIntegral_congr_fun hIm (fun x hx => hF x (Ioc_subset_Icc_self hx))
  have hIG : ∀ m : StieltjesFunction ℝ, ∫ x in I, G x ∂m.measure =
      ∫ x in I, G₁ x ∂m.measure - ∫ x in I, G₂ x ∂m.measure := by
    intro m
    rw [← integral_sub (ls_integrableOn_Ioc _ G₁.mono m a b) (ls_integrableOn_Ioc _ G₂.mono m a b)]
    exact setIntegral_congr_fun hIm (fun x hx => hG x (Ioc_subset_Icc_self hx))
  have hsum : ∑' x : I, (F x - leftLim F x) * (G x - leftLim G x) =
      (∫ x in I, (G₁ x - leftLim G₁ x) ∂F₁.measure) - (∫ x in I, (G₁ x - leftLim G₁ x) ∂F₂.measure)
      - (∫ x in I, (G₂ x - leftLim G₂ x) ∂F₁.measure)
      + (∫ x in I, (G₂ x - leftLim G₂ x) ∂F₂.measure) := by
    rw [tsum_subtype I (fun x => (F x - leftLim F x) * (G x - leftLim G x))]
    rw [← ((((hS F₁ G₁).sub (hS F₂ G₁)).sub (hS F₁ G₂)).add (hS F₂ G₂)).tsum_eq]
    congr 1
    ext x
    by_cases hx : x ∈ I
    · simp only [indicator_of_mem hx, hjF x hx, hjG x hx]
      ring
    · simp [hx]
  have c11 := ls_ibp_core F₁ G₁ a b hab
  have c12 := ls_ibp_core F₁ G₂ a b hab
  have c21 := ls_ibp_core F₂ G₁ a b hab
  have c22 := ls_ibp_core F₂ G₂ a b hab
  rw [hsum, hIF, hIF, hIG, hIG, hF a ⟨le_rfl, hab⟩, hF b ⟨hab, le_rfl⟩, hG a ⟨le_rfl, hab⟩,
    hG b ⟨hab, le_rfl⟩]
  linear_combination c11 - c12 - c21 + c22

/-! Worked numbers from the card, in exact fractions. The claim: $0 with chance 3/10, otherwise
spread evenly over (0, 1000] with density 7/10000 per dollar. -/

/-- The claim's distribution function, on rational dollar amounts. -/
def claimF (x : ℚ) : ℚ := if x < 0 then 0 else if x < 1000 then 3 / 10 + 7 / 10000 * x else 1

-- E[X]: jump part 3/10 × 0, spread part 7/10000 × 1000^2 / 2; together $350.
example : (3 / 10 : ℚ) * 0 + 7 / 10000 * (1000 ^ 2 / 2) = 350 := by norm_num
-- Fee case E[50 + X]: jump part 3/10 × 50 = 15, spread part 7/10000 × (50 × 1000 + 1000^2 / 2) = 385.
example : (3 / 10 : ℚ) * 50 = 15 ∧ (7 / 10000 : ℚ) * (50 * 1000 + 1000 ^ 2 / 2) = 385 ∧
    (15 : ℚ) + 385 = 400 := by norm_num
-- Tail area: half of 7/10 × 1000 is $350.
example : (1 / 2 : ℚ) * (7 / 10) * 1000 = 350 := by norm_num
-- The tail 1 - F(x) at x = 0, 500, 1000 is 7/10, 35/100, 0.
example : 1 - claimF 0 = 7 / 10 ∧ 1 - claimF 500 = 35 / 100 ∧ 1 - claimF 1000 = 0 := by
  norm_num [claimF]
-- By parts on (0, 500]: ∫ x dF = 7/10000 × 500^2 / 2 = 87.5; tail area 7/10 × 500 - 87.5 = 262.5;
-- boundary term 500 × 35/100 = 175; and 262.5 - 175 = 87.5.
example : (7 / 10000 : ℚ) * (500 ^ 2 / 2) = 175 / 2 ∧
    (7 / 10 : ℚ) * 500 - 7 / 10000 * (500 ^ 2 / 2) = 525 / 2 ∧
    (500 : ℚ) * (1 - claimF 500) = 175 ∧ (525 / 2 : ℚ) - 175 = 175 / 2 := by
  norm_num [claimF]
-- At b = 1000 the boundary term is 0.
example : (1000 : ℚ) * (1 - claimF 1000) = 0 := by norm_num [claimF]
-- F against F, directly: jump 3/10 × 3/10 + strip 3/10 × 7/10 + triangle (7/10000)^2 × 1000^2 / 2.
example : (3 / 10 : ℚ) * (3 / 10) + 3 / 10 * (7 / 10000 * 1000) + (7 / 10000) ^ 2 * (1000 ^ 2 / 2)
    = 545 / 1000 := by norm_num
-- F against F, by parts with the jump term: (1 × 1 - 0 × 0 + 3/10 × 3/10) / 2 = 0.545, not 1/2.
example : ((1 : ℚ) * 1 - 0 * 0 + 3 / 10 * (3 / 10)) / 2 = 545 / 1000 := by norm_num
-- The square: the left-limit integral 0.455 and 0.545 add to 1.
example : (0 : ℚ) * (3 / 10) + 3 / 10 * (7 / 10000 * 1000) + (7 / 10000) ^ 2 * (1000 ^ 2 / 2) +
    545 / 1000 = 1 := by norm_num
-- Mistakes: density 1/1000 with no 7/10 weight gives $500; F in place of 1 - F gives 1000 - 350.
example : (1 / 1000 : ℚ) * (1000 ^ 2 / 2) = 500 ∧ (1000 : ℚ) - 350 = 650 := by norm_num

/-- Left-tag and right-tag Riemann-Stieltjes sums for `g` on (-100, 1000] with `n` equal pieces. -/
def rsLeft (g : ℚ → ℚ) (n : ℕ) : ℚ :=
  ∑ i ∈ Finset.range n, g (-100 + i * (1100 / n)) *
    (claimF (-100 + (i + 1) * (1100 / n)) - claimF (-100 + i * (1100 / n)))
def rsRight (g : ℚ → ℚ) (n : ℕ) : ℚ :=
  ∑ i ∈ Finset.range n, g (-100 + (i + 1) * (1100 / n)) *
    (claimF (-100 + (i + 1) * (1100 / n)) - claimF (-100 + i * (1100 / n)))

-- With g(x) = x and 11 pieces: left tags give 285, right tags 385.
example : rsLeft (fun x => x) 11 = 285 ∧ rsRight (fun x => x) 11 = 385 := by
  norm_num [rsLeft, rsRight, claimF, Finset.sum_range_succ]
-- With g stepping from 0 to 1 at $0 and 11 pieces: left tags give 7/10, right tags 1.
example : rsLeft (fun x => if 0 ≤ x then 1 else 0) 11 = 7 / 10 ∧
    rsRight (fun x => if 0 ≤ x then 1 else 0) 11 = 1 := by
  norm_num [rsLeft, rsRight, claimF, Finset.sum_range_succ]
-- Cantor stages: total length (2/3)^10 = 1024/59049, just above 0.0173 and below 0.0174.
example : (2 / 3 : ℚ) ^ 10 = 1024 / 59049 ∧ 173 / 10000 < (2 / 3 : ℚ) ^ 10 ∧
    (2 / 3 : ℚ) ^ 10 < 174 / 10000 := by norm_num

#print axioms expectation_eq_integral_against_distribution_function
#print axioms integral_eq_sum_over_jumps_add_integral_against_slope
#print axioms integration_by_parts_with_jump_term
