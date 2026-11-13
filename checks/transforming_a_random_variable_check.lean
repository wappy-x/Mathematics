-- Transforming a variable: if X has a density and g splits into strictly rising or falling smooth branches, then g(X) has the branch-sum density; for a normal error the squared error has the stated density and CDF; and F_X(X) is uniform.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Function.JacobianOneDim
import Mathlib.MeasureTheory.Constructions.Polish.Basic
import Mathlib.Analysis.Calculus.Deriv.Inverse

open MeasureTheory ProbabilityTheory Set Real
open scoped ENNReal NNReal

open Filter Topology in
lemma tv_image_mem_nhds {g : ℝ → ℝ} {I : Set ℝ} (hI : IsOpen I) (hg : ContinuousOn g I)
    (hm : StrictMonoOn g I ∨ StrictAntiOn g I) {x : ℝ} (hx : x ∈ I) : g '' I ∈ 𝓝 (g x) := by
  obtain ⟨l, u, ⟨hl, hu⟩, hsub⟩ := (mem_nhds_iff_exists_Ioo_subset).1 (hI.mem_nhds hx)
  obtain ⟨a, hla, hax⟩ := exists_between hl
  obtain ⟨b, hxb, hbu⟩ := exists_between hu
  have hab : Icc a b ⊆ I := fun z hz => hsub ⟨by linarith [hz.1], by linarith [hz.2]⟩
  have haI : a ∈ I := hab ⟨le_rfl, by linarith⟩
  have hbI : b ∈ I := hab ⟨by linarith, le_rfl⟩
  have hc : ContinuousOn g (Icc a b) := hg.mono hab
  rcases hm with hm | hm
  · exact Filter.mem_of_superset (Icc_mem_nhds (hm haI hx hax) (hm hx hbI hxb))
      ((intermediate_value_Icc (by linarith) hc).trans (image_mono hab))
  · exact Filter.mem_of_superset (Icc_mem_nhds (hm hx hbI hxb) (hm haI hx hax))
      ((intermediate_value_Icc' (by linarith) hc).trans (image_mono hab))

open Filter Topology in
lemma tv_hasDerivAt_invFunOn {g : ℝ → ℝ} {I : Set ℝ} (hI : IsOpen I)
    (hgd : DifferentiableOn ℝ g I) (hslope : ∀ x ∈ I, deriv g x ≠ 0)
    (hm : StrictMonoOn g I ∨ StrictAntiOn g I) {x : ℝ} (hx : x ∈ I) :
    HasDerivAt (Function.invFunOn g I) (deriv g x)⁻¹ (g x) := by
  have hinj : InjOn g I := hm.elim StrictMonoOn.injOn StrictAntiOn.injOn
  have hleft : LeftInvOn (Function.invFunOn g I) g I := hinj.leftInvOn_invFunOn
  have hgx : Function.invFunOn g I (g x) = x := hleft hx
  have hnhds : g '' I ∈ 𝓝 (g x) := tv_image_mem_nhds hI hgd.continuousOn hm hx
  have hII : Function.invFunOn g I '' (g '' I) = I := hleft.image_image
  have hcont : ContinuousAt (Function.invFunOn g I) (g x) := by
    rcases hm with hm | hm
    · have hmono : StrictMonoOn (Function.invFunOn g I) (g '' I) := by
        rintro _ ⟨a, ha, rfl⟩ _ ⟨b, hb, rfl⟩ hab
        rw [hleft ha, hleft hb]
        exact (hm.lt_iff_lt ha hb).1 hab
      refine hmono.continuousAt_of_image_mem_nhds hnhds ?_
      rw [hII, hgx]; exact hI.mem_nhds hx
    · have hmono : StrictMonoOn (fun y => OrderDual.toDual (Function.invFunOn g I y)) (g '' I) := by
        rintro _ ⟨a, ha, rfl⟩ _ ⟨b, hb, rfl⟩ hab
        simp only [OrderDual.toDual_lt_toDual]
        rw [hleft ha, hleft hb]
        exact (hm.lt_iff_gt ha hb).1 hab
      refine hmono.continuousAt_of_image_mem_nhds hnhds ?_
      have : (fun y => OrderDual.toDual (Function.invFunOn g I y)) '' (g '' I)
          = OrderDual.ofDual ⁻¹' I := by
        rw [← image_image (g := OrderDual.toDual), hII]
        ext z; simp
      rw [this]
      exact (hI.preimage continuous_ofDual).mem_nhds (by simpa [hgx] using hx)
  have hgd' : HasDerivAt g (deriv g x) (Function.invFunOn g I (g x)) := by
    rw [hgx]; exact ((hgd x hx).differentiableAt (hI.mem_nhds hx)).hasDerivAt
  refine HasDerivAt.of_local_left_inverse hcont hgd' (hslope x hx) ?_
  filter_upwards [hnhds] with y hy
  exact Function.invFunOn_eq hy

open Filter Topology in
lemma tv_measurableSet_preimage_inter {g : ℝ → ℝ} {I : Set ℝ} (hI : IsOpen I)
    (hg : ContinuousOn g I) {A : Set ℝ} (hA : MeasurableSet A) :
    MeasurableSet (g ⁻¹' A ∩ I) := by
  classical
  have hm : Measurable (I.piecewise g (fun _ => (0:ℝ))) :=
    hg.measurable_piecewise continuousOn_const hI.measurableSet
  convert (hm hA).inter hI.measurableSet using 1
  ext x
  constructor
  · rintro ⟨h1, h2⟩; exact ⟨by simpa [Set.piecewise_eq_of_mem _ _ _ h2] using h1, h2⟩
  · rintro ⟨h1, h2⟩; exact ⟨by simpa [Set.piecewise_eq_of_mem _ _ _ h2] using h1, h2⟩

open Filter Topology in
lemma tv_invFunOn_sq_Ioi {z : ℝ} (hz : 0 < z) :
    Function.invFunOn (fun x : ℝ => x ^ 2) (Ioi 0) z = √z := by
  have hex : ∃ a ∈ Ioi (0:ℝ), (fun x : ℝ => x ^ 2) a = z :=
    ⟨√z, Real.sqrt_pos.2 hz, by simp [Real.sq_sqrt hz.le]⟩
  obtain ⟨hm, he⟩ := Function.invFunOn_pos hex
  conv_rhs => rw [← he]
  rw [Real.sqrt_sq (le_of_lt hm)]

open Filter Topology in
lemma tv_invFunOn_sq_Iio {z : ℝ} (hz : 0 < z) :
    Function.invFunOn (fun x : ℝ => x ^ 2) (Iio 0) z = -√z := by
  have hex : ∃ a ∈ Iio (0:ℝ), (fun x : ℝ => x ^ 2) a = z :=
    ⟨-√z, by simpa using Real.sqrt_pos.2 hz, by simp [Real.sq_sqrt hz.le]⟩
  obtain ⟨hm, he⟩ := Function.invFunOn_pos hex
  conv_rhs => rw [← he]
  rw [Real.sqrt_sq_eq_abs, abs_of_neg hm, neg_neg]

#print axioms tv_image_mem_nhds
#print axioms tv_hasDerivAt_invFunOn
#print axioms tv_measurableSet_preimage_inter
#print axioms tv_invFunOn_sq_Ioi
#print axioms tv_invFunOn_sq_Iio

/-- Change of variables for densities. Let X have a density f_X. Cut the inputs into
non-overlapping open intervals I_j (branches) that hold all of X's chance, such that on each
branch g is differentiable, strictly rising or strictly falling, with a slope that is never zero.
Let h_j be g run backwards on branch j. Then Y = g(X) has the density
f_Y(y) = ∑_j f_X(h_j(y)) |h_j'(y)|, where branch j counts only at outputs y that it reaches. -/
theorem density_of_function_eq_branch_sum
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : Ω → ℝ} (hX : Measurable X)
    {fX : ℝ → ℝ≥0∞} (hfX_meas : Measurable fX) (hfX : P.map X = volume.withDensity fX)
    {ι : Type*} [Countable ι] {I : ι → Set ℝ}
    (hI_open : ∀ j, IsOpen (I j)) (hI_interval : ∀ j, (I j).OrdConnected)
    (hI_disj : Pairwise (Function.onFun Disjoint I)) (hI_cover : P.map X ((⋃ j, I j)ᶜ) = 0)
    {g : ℝ → ℝ} (hg_diff : ∀ j, DifferentiableOn ℝ g (I j))
    (hg_slope : ∀ j, ∀ x ∈ I j, deriv g x ≠ 0)
    (hg_mono : ∀ j, StrictMonoOn g (I j) ∨ StrictAntiOn g (I j)) :
    P.map (fun ω => g (X ω)) =
      volume.withDensity (fun y => ∑' j, (g '' I j).indicator
        (fun y => fX (Function.invFunOn g (I j) y) *
          ENNReal.ofReal |deriv (Function.invFunOn g (I j)) y|) y) := by
  classical
  have hUopen : IsOpen (⋃ j, I j) := isOpen_iUnion hI_open
  have hcontU : ContinuousOn g (⋃ j, I j) := by
    intro x hx
    obtain ⟨j, hj⟩ := mem_iUnion.1 hx
    exact ((hg_diff j).continuousOn.continuousAt ((hI_open j).mem_nhds hj)).continuousWithinAt
  have hfull : ∀ᵐ x ∂(P.map X), x ∈ ⋃ j, I j := by
    rw [ae_iff]; convert hI_cover using 2
  have hrestr : (P.map X).restrict (⋃ j, I j) = P.map X :=
    Measure.restrict_eq_self_of_ae_mem hfull
  have hgae : AEMeasurable g (P.map X) := by
    rw [← hrestr]; exact hcontU.aemeasurable hUopen.measurableSet
  have hmap : P.map (fun ω => g (X ω)) = (P.map X).map g :=
    (AEMeasurable.map_map_of_aemeasurable hgae hX.aemeasurable).symm
  have hinj : ∀ j, InjOn g (I j) := fun j => (hg_mono j).elim StrictMonoOn.injOn StrictAntiOn.injOn
  have hderiv : ∀ j, ∀ x ∈ I j, HasDerivAt (Function.invFunOn g (I j)) (deriv g x)⁻¹ (g x) :=
    fun j x hx => tv_hasDerivAt_invFunOn (hI_open j) (hg_diff j) (hg_slope j) (hg_mono j) hx
  have hS : ∀ j, MeasurableSet (g '' I j) := fun j =>
    (hI_open j).measurableSet.image_of_continuousOn_injOn (hg_diff j).continuousOn (hinj j)
  have hhcont : ∀ j, ContinuousOn (Function.invFunOn g (I j)) (g '' I j) := by
    rintro j _ ⟨x, hx, rfl⟩
    exact (hderiv j x hx).continuousAt.continuousWithinAt
  have hGmeas : ∀ j, Measurable ((g '' I j).indicator
        (fun y => fX (Function.invFunOn g (I j) y) *
          ENNReal.ofReal |deriv (Function.invFunOn g (I j)) y|)) := by
    intro j
    have hp : Measurable ((g '' I j).piecewise (Function.invFunOn g (I j)) (fun _ => (0:ℝ))) :=
      (hhcont j).measurable_piecewise continuousOn_const (hS j)
    have heq : (g '' I j).indicator
        (fun y => fX (Function.invFunOn g (I j) y) *
          ENNReal.ofReal |deriv (Function.invFunOn g (I j)) y|) =
        (g '' I j).indicator
        (fun y => fX ((g '' I j).piecewise (Function.invFunOn g (I j)) (fun _ => (0:ℝ)) y) *
          ENNReal.ofReal |deriv (Function.invFunOn g (I j)) y|) := by
      apply Set.indicator_congr
      intro y hy
      simp [Set.piecewise_eq_of_mem _ _ _ hy]
    rw [heq]
    refine Measurable.indicator ?_ (hS j)
    exact (hfX_meas.comp hp).mul
      (continuous_abs.measurable.comp (measurable_deriv _)).ennreal_ofReal
  rw [hmap]
  ext A hA
  rw [Measure.map_apply_of_aemeasurable hgae hA, withDensity_apply _ hA, ← hrestr,
    Measure.restrict_apply' hUopen.measurableSet, inter_iUnion, hfX]
  have hsm : ∀ j, MeasurableSet (g ⁻¹' A ∩ I j) := fun j =>
    tv_measurableSet_preimage_inter (hI_open j) (hg_diff j).continuousOn hA
  rw [measure_iUnion (fun i j hij => (hI_disj hij).mono inter_subset_right inter_subset_right) hsm,
    lintegral_tsum (fun j => (hGmeas j).aemeasurable)]
  refine tsum_congr fun j => ?_
  rw [withDensity_apply _ (hsm j), lintegral_indicator (hS j), Measure.restrict_restrict (hS j),
    inter_comm (g '' I j) A, ← image_preimage_inter,
    lintegral_image_eq_lintegral_abs_deriv_mul (hsm j)
      (fun x hx => (((hg_diff j) x hx.2).differentiableAt
        ((hI_open j).mem_nhds hx.2)).hasDerivAt.hasDerivWithinAt)
      ((hinj j).mono inter_subset_right)]
  refine setLIntegral_congr_fun (hsm j) fun x hx => ?_
  rw [(hinj j).leftInvOn_invFunOn hx.2, (hderiv j x hx.2).deriv]
  have hne : |deriv g x| ≠ 0 := abs_ne_zero.2 (hg_slope j x hx.2)
  rw [mul_comm, mul_assoc, ← ENNReal.ofReal_mul (abs_nonneg _), abs_inv,
    inv_mul_cancel₀ hne, ENNReal.ofReal_one, mul_one]

/-- The bottle example in general. If the error X is normal with centre 0 and spread σ > 0,
then the squared error Y = X^2 has density (f_X(√y) + f_X(-√y)) / (2√y) for y > 0 (and 0
elsewhere); this equals e^(-y/(2σ^2)) / (σ √(2π y)); and the CDF route gives
F_Y(y) = 2Φ(√y/σ) - 1 for y ≥ 0, where Φ is the standard normal CDF. -/
theorem density_and_cdf_of_squared_normal
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : Ω → ℝ} (hX : Measurable X) (σ : ℝ≥0) (hσ : σ ≠ 0)
    (hlaw : P.map X = gaussianReal 0 (σ ^ 2)) :
    P.map (fun ω => X ω ^ 2) =
        volume.withDensity (fun y => (Ioi (0 : ℝ)).indicator (fun y => ENNReal.ofReal
          ((gaussianPDFReal 0 (σ ^ 2) (√y) + gaussianPDFReal 0 (σ ^ 2) (-√y)) / (2 * √y))) y) ∧
      (∀ y : ℝ, 0 < y →
        (gaussianPDFReal 0 (σ ^ 2) (√y) + gaussianPDFReal 0 (σ ^ 2) (-√y)) / (2 * √y) =
          1 / ((σ : ℝ) * √(2 * π * y)) * rexp (-y / (2 * (σ : ℝ) ^ 2))) ∧
      (∀ y : ℝ, 0 ≤ y →
        cdf (P.map (fun ω => X ω ^ 2)) y = 2 * cdf (gaussianReal 0 1) (√y / σ) - 1) := by
  have hv : (σ ^ 2 : ℝ≥0) ≠ 0 := pow_ne_zero 2 hσ
  have hσpos : (0:ℝ) < σ := lt_of_le_of_ne σ.2 (by exact_mod_cast hσ.symm)
  refine ⟨?_, ?_, ?_⟩
  · -- density, via the branch formula
    have hsq_Ioi : (fun x : ℝ => x ^ 2) '' Ioi 0 = Ioi 0 := by
      ext y; constructor
      · rintro ⟨x, hx, rfl⟩; simp only [mem_Ioi] at hx ⊢; positivity
      · intro hy; exact ⟨√y, Real.sqrt_pos.2 hy, Real.sq_sqrt (le_of_lt hy)⟩
    have hsq_Iio : (fun x : ℝ => x ^ 2) '' Iio 0 = Ioi 0 := by
      ext y; constructor
      · rintro ⟨x, hx, rfl⟩; simp only [mem_Iio, mem_Ioi] at hx ⊢; nlinarith
      · intro hy
        exact ⟨-√y, by simpa using Real.sqrt_pos.2 hy, by simp [Real.sq_sqrt (le_of_lt hy)]⟩
    have := nullSingletonClass_gaussianReal (μ := 0) hv
    have key := density_of_function_eq_branch_sum (P := P) hX (measurable_gaussianPDF 0 (σ ^ 2))
      (hlaw.trans (gaussianReal_of_var_ne_zero 0 hv))
      (I := fun b : Bool => if b then Ioi (0:ℝ) else Iio 0)
      (by intro b; cases b <;> simp [isOpen_Ioi, isOpen_Iio])
      (by intro b; cases b <;> simp <;> infer_instance)
      (by
        intro i j hij
        cases i <;> cases j <;> simp at hij ⊢
        · exact Set.disjoint_left.2 fun x h1 h2 => by simp at h1 h2; linarith
        · exact Set.disjoint_left.2 fun x h1 h2 => by simp at h1 h2; linarith)
      (by
        have : (⋃ b : Bool, if b then Ioi (0:ℝ) else Iio 0)ᶜ = {0} := by
          ext x; simp
          exact ⟨fun h => le_antisymm h.2 h.1, fun h => ⟨h.ge, h.le⟩⟩
        rw [this, hlaw]; exact measure_singleton 0)
      (g := fun x => x ^ 2)
      (by intro b; exact (differentiable_pow 2).differentiableOn)
      (by
        intro b x hx
        cases b <;> simp at hx <;> simp <;> intro h <;> linarith)
      (by
        intro b; cases b
        · right; intro a ha b hb hab; simp at ha hb ⊢; nlinarith
        · left; intro a ha b hb hab; simp at ha hb ⊢; nlinarith)
    refine key.trans ?_
    congr 1
    funext y
    simp only [tsum_bool, Bool.false_eq_true, ite_false, ite_true, hsq_Ioi, hsq_Iio]
    by_cases hy : 0 < y
    · rw [indicator_of_mem hy, indicator_of_mem hy, indicator_of_mem hy]
      have e1 : Function.invFunOn (fun x : ℝ => x ^ 2) (Iio 0) =ᶠ[nhds y] fun z => -√z := by
        filter_upwards [lt_mem_nhds hy] with z hz using tv_invFunOn_sq_Iio hz
      have e2 : Function.invFunOn (fun x : ℝ => x ^ 2) (Ioi 0) =ᶠ[nhds y] fun z => √z := by
        filter_upwards [lt_mem_nhds hy] with z hz using tv_invFunOn_sq_Ioi hz
      have d1 : deriv (fun z => -√z) y = -(1 / (2 * √y)) :=
        ((Real.hasDerivAt_sqrt hy.ne').neg).deriv
      have d2 : deriv (fun z => √z) y = 1 / (2 * √y) := (Real.hasDerivAt_sqrt hy.ne').deriv
      rw [e1.deriv_eq, e2.deriv_eq, tv_invFunOn_sq_Iio hy, tv_invFunOn_sq_Ioi hy, d1, d2]
      have hs : 0 < √y := Real.sqrt_pos.2 hy
      simp only [gaussianPDF]
      rw [← ENNReal.ofReal_mul (gaussianPDFReal_nonneg _ _ _),
        ← ENNReal.ofReal_mul (gaussianPDFReal_nonneg _ _ _),
        ← ENNReal.ofReal_add (mul_nonneg (gaussianPDFReal_nonneg _ _ _) (abs_nonneg _))
          (mul_nonneg (gaussianPDFReal_nonneg _ _ _) (abs_nonneg _))]
      congr 1
      rw [abs_neg, abs_of_pos (by positivity)]
      field_simp
      ring
    · rw [indicator_of_notMem hy, indicator_of_notMem hy, indicator_of_notMem hy, add_zero]
  · intro y hy
    have hs : 0 < √y := Real.sqrt_pos.2 hy
    simp only [gaussianPDFReal, sub_zero, neg_sq, Real.sq_sqrt hy.le, NNReal.coe_pow]
    have h1 : √(2 * π * ((σ:ℝ) ^ 2)) = σ * √(2 * π) := by
      rw [Real.sqrt_mul (by positivity), Real.sqrt_sq hσpos.le, mul_comm]
    have h2 : √(2 * π * y) = √(2 * π) * √y := Real.sqrt_mul (by positivity) y
    rw [h1, h2]
    have : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
    field_simp
    ring
  · intro y hy
    set N := gaussianReal 0 1 with hN
    have hmapsq : P.map (fun ω => X ω ^ 2) = (gaussianReal 0 (σ ^ 2)).map (fun x => x ^ 2) := by
      rw [← hlaw, Measure.map_map (by fun_prop) hX]; rfl
    have hscale : gaussianReal 0 (σ ^ 2) = N.map (fun x => (σ:ℝ) * x) := by
      rw [hN, gaussianReal_map_const_mul]
      congr 1
      · simp
      · ext; simp
    have hneg : N.map (fun x => -x) = N := by rw [hN, gaussianReal_map_neg, neg_zero]
    have : IsProbabilityMeasure (P.map fun ω => X ω ^ 2) :=
      (Measure.isProbabilityMeasure_map_iff (by fun_prop)).2 inferInstance
    set t := √y / σ with ht
    have hpre1 : (fun x : ℝ => x ^ 2) ⁻¹' Iic y = Icc (-√y) (√y) := by
      ext x; simp [Real.sq_le hy]
    have hpre2 : (fun x : ℝ => (σ:ℝ) * x) ⁻¹' Icc (-√y) (√y) = Icc (-t) t := by
      ext x
      simp only [mem_preimage, mem_Icc, ht]
      rw [← neg_div, div_le_iff₀ hσpos, le_div_iff₀' hσpos]
      constructor <;> rintro ⟨a, b⟩ <;> constructor <;> linarith
    have hpre3 : (fun x : ℝ => -x) ⁻¹' Ioi t = Iio (-t) := by
      ext x; simp [lt_neg]
    rw [cdf_eq_real, hmapsq, map_measureReal_apply (by fun_prop) measurableSet_Iic, hpre1,
      hscale, map_measureReal_apply (by fun_prop) measurableSet_Icc, hpre2, cdf_eq_real]
    have hdiff : Icc (-t) t = Iic t \ Iio (-t) := by
      ext x; simp [and_comm]
    rw [hdiff, measureReal_sdiff (fun x hx => by simp at hx ⊢; linarith [show 0 ≤ t by positivity])
      measurableSet_Iio, ← hpre3, ← map_measureReal_apply (by fun_prop) measurableSet_Ioi, hneg,
      ← compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic]
    ring

/-- Probability integral transform. If the CDF F_X of X has no jumps (it is continuous) and no
flat stretch (it is strictly increasing), then F_X(X) is uniform between 0 and 1:
P(F_X(X) ≤ u) = u for every u between 0 and 1. -/
theorem cdf_of_self_is_uniform
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : Ω → ℝ} (hX : Measurable X)
    (hF_cont : Continuous (cdf (P.map X))) (hF_strict : StrictMono (cdf (P.map X))) :
    ∀ u ∈ Icc (0 : ℝ) 1, P {ω | cdf (P.map X) (X ω) ≤ u} = ENNReal.ofReal u := by
  intro u hu
  have : IsProbabilityMeasure (P.map X) :=
    (Measure.isProbabilityMeasure_map_iff hX.aemeasurable).2 inferInstance
  have hpos : ∀ x, 0 < cdf (P.map X) x := fun x =>
    (cdf_nonneg _ (x - 1)).trans_lt (hF_strict (by linarith))
  rcases hu.1.eq_or_lt with h0 | h0
  · subst h0
    have : {ω | cdf (P.map X) (X ω) ≤ 0} = ∅ := by
      ext ω; simp [(hpos (X ω)).not_ge]
    rw [this]; simp
  rcases hu.2.lt_or_eq with h1 | h1
  · have hlo : ∃ a, cdf (P.map X) a ≤ u := by
      obtain ⟨a, ha⟩ := ((tendsto_cdf_atBot (P.map X)).eventually (gt_mem_nhds h0)).exists
      exact ⟨a, ha.le⟩
    have hhi : ∃ b, u ≤ cdf (P.map X) b := by
      obtain ⟨b, hb⟩ := ((tendsto_cdf_atTop (P.map X)).eventually (lt_mem_nhds h1)).exists
      exact ⟨b, hb.le⟩
    obtain ⟨x, hx⟩ := mem_range_of_exists_le_of_exists_ge hF_cont hlo hhi
    have hset : {ω | cdf (P.map X) (X ω) ≤ u} = X ⁻¹' Iic x := by
      ext ω; simp [← hx, hF_strict.le_iff_le]
    rw [hset, ← Measure.map_apply hX measurableSet_Iic, ← ofReal_cdf, hx]
  · subst h1
    have : {ω | cdf (P.map X) (X ω) ≤ 1} = univ := by
      ext ω; simp [cdf_le_one]
    rw [this]; simp

-- Worked numbers, σ = 2 ml. The two square roots of y = 4 are -2 and 2.
example : √(4 : ℝ) = 2 := by
  rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]

-- The stretch factor on each branch at y = 4 is 1 / (2 × 2), one quarter.
example : 1 / (2 * √(4 : ℝ)) = 1 / 4 := by
  rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]; norm_num

-- At y = 1, two branches each with stretch factor 1/(2√1) = 1/2 add to 1, so f_Y(1) = f_X(1).
example : 2 * (1 / (2 * √(1 : ℝ))) = 1 := by
  rw [Real.sqrt_one]; norm_num

-- The strip of misses from 1 to 3/2 ml (width 1/2) maps to squared errors from 1 to 9/4
-- (width 5/4).
example : (1 : ℚ) ^ 2 = 1 ∧ (3 / 2 : ℚ) ^ 2 = 9 / 4 ∧ (3 / 2 : ℚ) - 1 = 1 / 2 ∧
    (9 / 4 : ℚ) - 1 = 5 / 4 := by
  norm_num

-- Mean σ^2 = 4 and variance 2σ^4 = 32 of the squared error.
example : (2 : ℕ) ^ 2 = 4 ∧ 2 * (2 : ℕ) ^ 4 = 32 := by
  decide

#print axioms density_of_function_eq_branch_sum
#print axioms density_and_cdf_of_squared_normal
#print axioms cdf_of_self_is_uniform
