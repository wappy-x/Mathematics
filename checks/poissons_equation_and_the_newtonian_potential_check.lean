-- Poisson's equation: a uniformly charged ball has the dome potential kQ/(2R)(3 - r²/R²) inside and kQ/r outside, and only one twice-differentiable solution of minus the Laplacian equals the source vanishes far away.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Topology.MetricSpace.Holder
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.DerivativeTest
import Mathlib.Analysis.InnerProductSpace.Projection.Reflection

open MeasureTheory Filter Topology Real Laplacian
open scoped NNReal

/-- Three-dimensional space `ℝ³`, with its usual distance and volume. -/
abbrev E3 := EuclideanSpace ℝ (Fin 3)

section Helpers

open Set

/-- Coordinates `(t, p, q) ↦ (t, p, q) ∈ ℝ³`. -/
noncomputable def coord3 (z : ℝ × ℝ × ℝ) : E3 := WithLp.toLp 2 (Fin.cons z.1 ![z.2.1, z.2.2])

lemma coord3_mp : MeasurePreserving coord3 volume volume := by
  have h1 : MeasurePreserving (Prod.map (id : ℝ → ℝ) (MeasurableEquiv.finTwoArrow (α := ℝ)).symm)
      volume volume :=
    (MeasurePreserving.id volume).prod (volume_preserving_finTwoArrow ℝ).symm
  have h2 := (volume_preserving_piFinSuccAbove (fun _ : Fin 3 => ℝ) 0).symm
  have h3 := PiLp.volume_preserving_toLp (Fin 3)
  have := h3.comp (h2.comp h1)
  convert this using 1
  funext z
  simp only [coord3, Function.comp, Prod.map]
  congr 1
  ext i
  fin_cases i <;> rfl

lemma coord3_norm_sq (z : ℝ × ℝ × ℝ) : ‖coord3 z‖ = √(z.1 ^ 2 + z.2.1 ^ 2 + z.2.2 ^ 2) := by
  rw [EuclideanSpace.norm_eq, Fin.sum_univ_three]
  simp [coord3, add_assoc]

lemma coord3_dist (a : ℝ) (z : ℝ × ℝ × ℝ) :
    ‖a • EuclideanSpace.single (0 : Fin 3) (1 : ℝ) - coord3 z‖ =
      √((a - z.1) ^ 2 + z.2.1 ^ 2 + z.2.2 ^ 2) := by
  rw [EuclideanSpace.norm_eq, Fin.sum_univ_three]
  simp [coord3, add_assoc]

lemma radial_part (m c : ℝ) (hm : 0 ≤ m) :
    ∫ r in (0:ℝ)..√m, r / √(r ^ 2 + c ^ 2) = √(m + c ^ 2) - |c| := by
  have hsm : 0 ≤ √m := Real.sqrt_nonneg m
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hsm
    (f := fun r => √(r ^ 2 + c ^ 2))]
  · simp [Real.sq_sqrt hm, Real.sqrt_sq_eq_abs]
  · exact (by fun_prop : Continuous fun r : ℝ => √(r ^ 2 + c ^ 2)).continuousOn
  · intro r hr
    have hpos : r ^ 2 + c ^ 2 ≠ 0 := by have := hr.1; positivity
    have h := ((hasDerivAt_pow 2 r).add_const (c ^ 2)).sqrt hpos
    convert h using 1
    field_simp
    push_cast; ring
  · rw [intervalIntegrable_iff_integrableOn_Ioc_of_le hsm]
    refine (Measure.integrableOn_of_bounded (M := 1) (by simp [Real.volume_Ioc]) ?_ ?_)
    · exact (by fun_prop : Measurable fun r : ℝ => r / √(r ^ 2 + c ^ 2)).aestronglyMeasurable
    · refine Filter.Eventually.of_forall fun r => ?_
      rw [Real.norm_eq_abs, abs_div, abs_of_nonneg (Real.sqrt_nonneg _)]
      exact div_le_one_of_le₀ (Real.abs_le_sqrt (by nlinarith)) (Real.sqrt_nonneg _)

lemma inner2D (m c : ℝ) (hm : 0 ≤ m) :
    ∫⁻ w : ℝ × ℝ, ENNReal.ofReal (if w.1 ^ 2 + w.2 ^ 2 ≤ m then 1 / √(w.1 ^ 2 + w.2 ^ 2 + c ^ 2) else 0)
      = ENNReal.ofReal (2 * π * (√(m + c ^ 2) - |c|)) := by
  rw [← lintegral_comp_polarCoord_symm]
  have hsq : ∀ p : ℝ × ℝ, (p.1 * cos p.2) ^ 2 + (p.1 * sin p.2) ^ 2 = p.1 ^ 2 := by
    intro p; nlinarith [sin_sq_add_cos_sq p.2]
  simp only [polarCoord_symm_apply, hsq]
  rw [polarCoord_target, Measure.volume_eq_prod, ← Measure.prod_restrict, lintegral_prod]
  swap
  · refine Measurable.aemeasurable ?_
    have h1 : Measurable fun p : ℝ × ℝ => ENNReal.ofReal p.1 := by fun_prop
    refine Measurable.smul h1 (Measurable.ennreal_ofReal (Measurable.ite ?_ ?_ ?_))
    · exact measurableSet_le (by fun_prop) (by fun_prop)
    · fun_prop
    · fun_prop
  simp only [lintegral_const, Measure.restrict_apply_univ, Real.volume_Ioo]
  have hsm : 0 ≤ √m := Real.sqrt_nonneg m
  have hint : IntegrableOn (fun r : ℝ => r / √(r ^ 2 + c ^ 2)) (Ioc 0 √m) := by
    refine (Measure.integrableOn_of_bounded (M := 1) (by simp [Real.volume_Ioc]) ?_ ?_)
    · exact (by fun_prop : Measurable fun r : ℝ => r / √(r ^ 2 + c ^ 2)).aestronglyMeasurable
    · refine Filter.Eventually.of_forall fun r => ?_
      rw [Real.norm_eq_abs, abs_div, abs_of_nonneg (Real.sqrt_nonneg _)]
      exact div_le_one_of_le₀ (Real.abs_le_sqrt (by nlinarith)) (Real.sqrt_nonneg _)
  calc _ = ∫⁻ x in Ioc 0 √m, ENNReal.ofReal (2 * π * (x / √(x ^ 2 + c ^ 2))) := by
        rw [← Ioc_union_Ioi_eq_Ioi hsm, lintegral_union measurableSet_Ioi (Ioc_disjoint_Ioi le_rfl)]
        have h0 : ∫⁻ x in Ioi √m, ENNReal.ofReal x • ENNReal.ofReal
            (if x ^ 2 ≤ m then 1 / √(x ^ 2 + c ^ 2) else 0) * ENNReal.ofReal (π - -π) = 0 := by
          rw [setLIntegral_congr_fun measurableSet_Ioi (g := fun _ => 0)]
          · simp
          · intro x hx
            have hx0 : 0 < x := lt_of_le_of_lt hsm hx
            have : m < x ^ 2 := (Real.sqrt_lt' hx0).1 hx
            simp [not_le.2 this]
        rw [h0, add_zero]
        refine setLIntegral_congr_fun measurableSet_Ioc fun x hx => ?_
        have hx2 : x ^ 2 ≤ m := (Real.le_sqrt hx.1.le hm).1 hx.2
        simp only [hx2, ite_true, smul_eq_mul]
        rw [← ENNReal.ofReal_mul hx.1.le, ← ENNReal.ofReal_mul (by have := hx.1; positivity)]
        congr 1
        ring
    _ = ENNReal.ofReal (∫ x in Ioc 0 √m, 2 * π * (x / √(x ^ 2 + c ^ 2))) := by
        rw [ofReal_integral_eq_lintegral_ofReal (hint.const_mul _)]
        refine (ae_restrict_iff' measurableSet_Ioc).2 (Filter.Eventually.of_forall fun x hx => ?_)
        have := hx.1
        simp only [Pi.zero_apply]
        positivity
    _ = _ := by
        rw [integral_const_mul, ← intervalIntegral.integral_of_le hsm, radial_part m c hm]


lemma hasDerivAt_mul_abs (x : ℝ) : HasDerivAt (fun y : ℝ => y * |y|) (2 * |x|) x := by
  rcases lt_trichotomy x 0 with hx | hx | hx
  · have h := (hasDerivAt_pow 2 x).neg
    refine HasDerivAt.congr_of_eventuallyEq (f := fun y : ℝ => -y ^ 2) ?_ ?_
    · convert h using 1; rw [abs_of_neg hx]; push_cast; ring
    · filter_upwards [Iio_mem_nhds hx] with y hy
      rw [abs_of_neg (show y < 0 from hy)]; ring
  · subst hx
    rw [hasDerivAt_iff_isLittleO_nhds_zero]
    simp only [zero_add, abs_zero, mul_zero, sub_zero, smul_zero]
    have h1 : (fun h : ℝ => |h|) =o[𝓝 0] (fun _ => (1 : ℝ)) := by
      rw [Asymptotics.isLittleO_one_iff]
      simpa using (continuous_abs.tendsto (0 : ℝ))
    have h2 := h1.mul_isBigO (Asymptotics.isBigO_refl (fun h : ℝ => h) (𝓝 0))
    simpa [mul_comm] using h2
  · have h := (hasDerivAt_pow 2 x)
    refine HasDerivAt.congr_of_eventuallyEq (f := fun y : ℝ => y ^ 2) ?_ ?_
    · convert h using 1; rw [abs_of_pos hx]; push_cast; ring
    · filter_upwards [Ioi_mem_nhds hx] with y hy
      rw [abs_of_pos (show 0 < y from hy)]; ring

lemma oneD_pos (R a : ℝ) (hR : 0 < R) (ha : 0 < a) :
    ∫ t in -R..R, (√(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t|) =
      ((R + a) ^ 3 - (R - a) ^ 2 * |R - a|) / (3 * a) - ((R - a) * |R - a| + (R + a) ^ 2) / 2 := by
  have hRR : -R ≤ R := by linarith
  have hcongr : ∀ t ∈ uIcc (-R) R, √(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t| =
      √(R ^ 2 + a ^ 2 - 2 * a * t) - |t - a| := by
    intro t _; rw [abs_sub_comm]; ring_nf
  rw [intervalIntegral.integral_congr hcongr]
  set F : ℝ → ℝ := fun t => -((R ^ 2 + a ^ 2 - 2 * a * t) * √(R ^ 2 + a ^ 2 - 2 * a * t)) / (3 * a)
    - (t - a) * |t - a| / 2 with hF
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hRR (f := F)]
  · have e1 : R ^ 2 + a ^ 2 - 2 * a * R = (R - a) ^ 2 := by ring
    have e2 : R ^ 2 + a ^ 2 - 2 * a * -R = (R + a) ^ 2 := by ring
    simp only [hF, e1, e2, Real.sqrt_sq_eq_abs, abs_of_nonneg (by linarith : (0:ℝ) ≤ R + a),
      show -R - a = -(R + a) by ring, abs_neg]
    field_simp
    ring
  · exact (by fun_prop : Continuous F).continuousOn
  · intro t ht
    have hRt : 0 < (R - t) * (R + t) := mul_pos (by linarith [ht.2]) (by linarith [ht.1])
    have hu : 0 < R ^ 2 + a ^ 2 - 2 * a * t := by nlinarith [sq_nonneg (a - t)]
    have hd : HasDerivAt (fun t : ℝ => R ^ 2 + a ^ 2 - 2 * a * t) (-(2 * a)) t := by
      simpa using ((hasDerivAt_id t).const_mul (2 * a)).const_sub (R ^ 2 + a ^ 2)
    have hs := hd.sqrt hu.ne'
    have hp := ((hd.mul hs).neg.div_const (3 * a)).sub
      (((hasDerivAt_mul_abs (t - a)).comp t ((hasDerivAt_id t).sub_const a)).div_const 2)
    convert hp using 1
    · rw [hF]; funext x; simp [Function.comp]
    have hsq : √(R ^ 2 + a ^ 2 - 2 * a * t) ^ 2 = R ^ 2 + a ^ 2 - 2 * a * t :=
      Real.sq_sqrt hu.le
    have hspos : 0 < √(R ^ 2 + a ^ 2 - 2 * a * t) := Real.sqrt_pos.2 hu
    generalize √(R ^ 2 + a ^ 2 - 2 * a * t) = s at hsq hspos ⊢
    rw [← hsq]
    field_simp
    ring
  · exact (by fun_prop : Continuous fun t : ℝ => √(R ^ 2 + a ^ 2 - 2 * a * t) - |t - a|).intervalIntegrable _ _

lemma oneD_zero (R : ℝ) (hR : 0 < R) :
    ∫ t in -R..R, (√(R ^ 2 - t ^ 2 + (0 - t) ^ 2) - |0 - t|) = R ^ 2 := by
  have hRR : -R ≤ R := by linarith
  have hcongr : ∀ t ∈ uIcc (-R) R, √(R ^ 2 - t ^ 2 + (0 - t) ^ 2) - |0 - t| = R - |t| := by
    intro t _
    rw [show R ^ 2 - t ^ 2 + (0 - t) ^ 2 = R ^ 2 by ring, Real.sqrt_sq hR.le, zero_sub, abs_neg]
  rw [intervalIntegral.integral_congr hcongr]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hRR (f := fun t => R * t - t * |t| / 2)]
  · simp only [abs_neg, abs_of_pos hR]; ring
  · exact (by fun_prop : Continuous fun t : ℝ => R * t - t * |t| / 2).continuousOn
  · intro t _
    have hp := ((hasDerivAt_id t).const_mul R).sub ((hasDerivAt_mul_abs t).div_const 2)
    convert hp using 1
    · funext s; simp
    · ring
  · exact (by fun_prop : Continuous fun t : ℝ => R - |t|).intervalIntegrable _ _


lemma outer_conv (R : ℝ) (hR : 0 < R) (g : ℝ → ℝ) (hg : Continuous g)
    (hnn : ∀ t, t ^ 2 ≤ R ^ 2 → 0 ≤ g t) :
    ∫⁻ t, ENNReal.ofReal (if t ^ 2 ≤ R ^ 2 then g t else 0) = ENNReal.ofReal (∫ t in -R..R, g t) := by
  have hmem : ∀ t : ℝ, t ^ 2 ≤ R ^ 2 ↔ t ∈ Icc (-R) R := by
    intro t
    rw [sq_le_sq, abs_of_pos hR, abs_le, mem_Icc]
  have heq : (fun t => ENNReal.ofReal (if t ^ 2 ≤ R ^ 2 then g t else 0)) =
      (Icc (-R) R).indicator (fun t => ENNReal.ofReal (g t)) := by
    funext t
    by_cases ht : t ^ 2 ≤ R ^ 2
    · rw [if_pos ht, indicator_of_mem ((hmem t).1 ht)]
    · rw [if_neg ht, indicator_of_notMem (fun h => ht ((hmem t).2 h)), ENNReal.ofReal_zero]
  rw [heq, lintegral_indicator measurableSet_Icc, ← ofReal_integral_eq_lintegral_ofReal
    hg.integrableOn_Icc, integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le (by linarith)]
  refine (ae_restrict_iff' measurableSet_Icc).2 (Filter.Eventually.of_forall fun t ht => ?_)
  exact hnn t ((hmem t).2 ht)

lemma ball_lintegral (R a : ℝ) (hR : 0 < R) :
    ∫⁻ z : E3, ENNReal.ofReal (if ‖z‖ ≤ R then 1 / ‖a • EuclideanSpace.single (0 : Fin 3) (1 : ℝ) - z‖ else 0)
      = ENNReal.ofReal (2 * π * ∫ t in -R..R, (√(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t|)) := by
  rw [← coord3_mp.lintegral_comp]
  swap
  · refine Measurable.ennreal_ofReal (Measurable.ite ?_ (by fun_prop) measurable_const)
    exact measurableSet_le (by fun_prop) measurable_const
  simp only [coord3_norm_sq, coord3_dist, Real.sqrt_le_left hR.le]
  rw [Measure.volume_eq_prod, lintegral_prod]
  swap
  · refine Measurable.aemeasurable (Measurable.ennreal_ofReal (Measurable.ite ?_ (by fun_prop) measurable_const))
    exact measurableSet_le (by fun_prop) measurable_const
  have hinner : ∀ t : ℝ, ∫⁻ w : ℝ × ℝ, ENNReal.ofReal (if t ^ 2 + w.1 ^ 2 + w.2 ^ 2 ≤ R ^ 2 then
      1 / √((a - t) ^ 2 + w.1 ^ 2 + w.2 ^ 2) else 0) =
      ENNReal.ofReal (if t ^ 2 ≤ R ^ 2 then 2 * π * (√(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t|) else 0) := by
    intro t
    by_cases ht : t ^ 2 ≤ R ^ 2
    · rw [if_pos ht, ← inner2D (R ^ 2 - t ^ 2) (a - t) (by linarith)]
      congr 1
      funext w
      have hc : (t ^ 2 + w.1 ^ 2 + w.2 ^ 2 ≤ R ^ 2) ↔ (w.1 ^ 2 + w.2 ^ 2 ≤ R ^ 2 - t ^ 2) := by
        constructor <;> intro h <;> linarith
      simp only [hc]
      congr 2
      ring_nf
    · rw [if_neg ht, ENNReal.ofReal_zero]
      have hn : ∀ w : ℝ × ℝ, ¬ (t ^ 2 + w.1 ^ 2 + w.2 ^ 2 ≤ R ^ 2) := fun w h =>
        ht (by nlinarith [sq_nonneg w.1, sq_nonneg w.2])
      simp [hn]
  dsimp only
  simp_rw [hinner]
  have hnn : ∀ t : ℝ, t ^ 2 ≤ R ^ 2 → 0 ≤ 2 * π * (√(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t|) := by
    intro t ht
    refine mul_nonneg (by positivity) (sub_nonneg.2 ?_)
    rw [← Real.sqrt_sq_eq_abs]
    exact Real.sqrt_le_sqrt (by linarith)
  rw [outer_conv R hR _ (by fun_prop) hnn, intervalIntegral.integral_const_mul]


lemma I_nonneg (R a : ℝ) (hR : 0 < R) :
    0 ≤ ∫ t in -R..R, (√(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t|) := by
  refine intervalIntegral.integral_nonneg (by linarith) fun t ht => sub_nonneg.2 ?_
  rw [← Real.sqrt_sq_eq_abs]
  refine Real.sqrt_le_sqrt ?_
  nlinarith [ht.1, ht.2]

lemma I_inside (R a : ℝ) (hR : 0 < R) (ha : 0 ≤ a) (haR : a ≤ R) :
    ∫ t in -R..R, (√(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t|) = R ^ 2 - a ^ 2 / 3 := by
  rcases ha.eq_or_lt with h0 | hpos
  · subst h0; rw [oneD_zero R hR]; ring
  · rw [oneD_pos R a hR hpos, abs_of_nonneg (by linarith : (0:ℝ) ≤ R - a)]
    field_simp
    ring

lemma I_outside (R a : ℝ) (hR : 0 < R) (haR : R ≤ a) :
    ∫ t in -R..R, (√(R ^ 2 - t ^ 2 + (a - t) ^ 2) - |a - t|) = 2 * R ^ 3 / (3 * a) := by
  have hpos : 0 < a := lt_of_lt_of_le hR haR
  rw [oneD_pos R a hR hpos, abs_of_nonpos (by linarith : R - a ≤ 0)]
  field_simp
  ring

lemma reflect_lintegral (R : ℝ) (x : E3) :
    ∫⁻ y : E3, ENNReal.ofReal (if ‖y‖ ≤ R then 1 / ‖x - y‖ else 0) =
      ∫⁻ y : E3, ENNReal.ofReal
        (if ‖y‖ ≤ R then 1 / ‖‖x‖ • EuclideanSpace.single (0 : Fin 3) (1 : ℝ) - y‖ else 0) := by
  set e : E3 := ‖x‖ • EuclideanSpace.single (0 : Fin 3) (1 : ℝ) with he
  have hn : ‖x‖ = ‖e‖ := by simp [he, norm_smul]
  set T : E3 ≃ₗᵢ[ℝ] E3 := Submodule.reflection (ℝ ∙ (x - e))ᗮ with hTdef
  have hT : T x = e := Submodule.reflection_sub hn
  have hmeas : Measurable fun y : E3 => ENNReal.ofReal (if ‖y‖ ≤ R then 1 / ‖e - y‖ else 0) := by
    refine Measurable.ennreal_ofReal (Measurable.ite ?_ (by fun_prop) measurable_const)
    exact measurableSet_le (by fun_prop) measurable_const
  rw [← T.measurePreserving.lintegral_comp hmeas]
  congr 1
  funext y
  rw [← hT, ← map_sub, LinearIsometryEquiv.norm_map, LinearIsometryEquiv.norm_map]

lemma ball_integral_value (R : ℝ) (hR : 0 < R) (x : E3) :
    ∫ y : E3, (if ‖y‖ ≤ R then 1 / ‖x - y‖ else 0) =
      2 * π * ∫ t in -R..R, (√(R ^ 2 - t ^ 2 + (‖x‖ - t) ^ 2) - |‖x‖ - t|) := by
  rw [integral_eq_lintegral_of_nonneg_ae, reflect_lintegral, ball_lintegral R _ hR,
    ENNReal.toReal_ofReal (mul_nonneg (by positivity) (I_nonneg R _ hR))]
  · refine Filter.Eventually.of_forall fun y => ?_
    simp only [Pi.zero_apply]
    split_ifs <;> positivity
  · refine Measurable.aestronglyMeasurable (Measurable.ite ?_ (by fun_prop) measurable_const)
    exact measurableSet_le (by fun_prop) measurable_const



lemma line_derivs (g : E3 → ℝ) (hg : ContDiff ℝ 2 g) (y e : E3) :
    (∀ t : ℝ, HasDerivAt (fun s : ℝ => g (y + s • e)) (fderiv ℝ g (y + t • e) e) t) ∧
    HasDerivAt (fun s : ℝ => fderiv ℝ g (y + s • e) e) (iteratedFDeriv ℝ 2 g y ![e, e]) 0 := by
  have hl : ∀ t : ℝ, HasDerivAt (fun s : ℝ => y + s • e) e t := fun t => by
    simpa using ((hasDerivAt_id t).smul_const e).const_add y
  have hd1 : Differentiable ℝ g := hg.differentiable (by norm_num)
  have hd2 : Differentiable ℝ (fderiv ℝ g) :=
    (hg.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  refine ⟨fun t => (hd1 _).hasFDerivAt.comp_hasDerivAt t (hl t), ?_⟩
  rw [iteratedFDeriv_two_apply]
  have h := (hd2 (y + (0 : ℝ) • e)).hasFDerivAt.comp_hasDerivAt (0 : ℝ) (hl 0)
  rw [zero_smul, add_zero] at h
  exact (ContinuousLinearMap.apply ℝ ℝ e).hasFDerivAt.comp_hasDerivAt (0 : ℝ) h

lemma second_deriv_at_max (g : E3 → ℝ) (hg : ContDiff ℝ 2 g) (ε : ℝ) (y e : E3)
    (he : ‖e‖ = 1) (hmax : IsLocalMax (fun z => g z + ε * ‖z‖ ^ 2) y) :
    iteratedFDeriv ℝ 2 g y ![e, e] + 2 * ε ≤ 0 := by
  obtain ⟨h1, h2⟩ := line_derivs g hg y e
  set c := inner ℝ y e
  let φ : ℝ → ℝ := fun t => g (y + t • e) + ε * (‖y‖ ^ 2 + 2 * c * t + t ^ 2)
  have hφ : φ = (fun z => g z + ε * ‖z‖ ^ 2) ∘ (fun t : ℝ => y + t • e) := by
    funext t
    simp only [φ, Function.comp, norm_add_sq_real, norm_smul, he, inner_smul_right,
      Real.norm_eq_abs, mul_one, sq_abs, c]
    ring
  have hφmax : IsLocalMax φ 0 := by
    rw [hφ]
    refine IsLocalMax.comp_continuous (g := fun t : ℝ => y + t • e) ?_ (by fun_prop)
    simpa using hmax
  have hD : ∀ t, HasDerivAt φ (fderiv ℝ g (y + t • e) e + ε * (2 * c + 2 * t)) t := by
    intro t
    have hp : HasDerivAt (fun s : ℝ => ‖y‖ ^ 2 + 2 * c * s + s ^ 2) (2 * c + 2 * t) t := by
      have := (((hasDerivAt_id t).const_mul (2 * c)).const_add (‖y‖ ^ 2)).add (hasDerivAt_pow 2 t)
      convert this using 1
      · funext s; simp
      · simp
    exact (h1 t).add (hp.const_mul ε)
  have hderiv : deriv φ = fun t => fderiv ℝ g (y + t • e) e + ε * (2 * c + 2 * t) :=
    funext fun t => (hD t).deriv
  have hD2 : HasDerivAt (deriv φ) (iteratedFDeriv ℝ 2 g y ![e, e] + 2 * ε) 0 := by
    rw [hderiv]
    have hq : HasDerivAt (fun t : ℝ => ε * (2 * c + 2 * t)) (2 * ε) 0 := by
      have := (((hasDerivAt_id (0 : ℝ)).const_mul 2).const_add (2 * c)).const_mul ε
      convert this using 1
      · rfl
      · ring
    exact h2.add hq
  by_contra hpos
  push Not at hpos
  have hmin : IsLocalMin φ 0 :=
    isLocalMin_of_deriv_deriv_pos (by rw [hD2.deriv]; exact hpos) hφmax.deriv_eq_zero
      (hD 0).continuousAt
  have hconst : φ =ᶠ[𝓝 0] fun _ => φ 0 := by
    filter_upwards [hφmax, hmin] with t ht1 ht2
    exact le_antisymm ht1 ht2
  have h0 : deriv (deriv φ) 0 = 0 := by
    rw [hconst.deriv.deriv_eq]
    simp
  rw [hD2.deriv] at h0
  linarith

lemma harmonic_vanishing_nonpos (g : E3 → ℝ) (hg : ContDiff ℝ 2 g) (hΔ : ∀ x, Δ g x = 0)
    (hl : Tendsto g (cocompact E3) (𝓝 0)) (x₀ : E3) : g x₀ ≤ 0 := by
  by_contra hpos
  push Not at hpos
  set m := g x₀
  have hev : ∀ᶠ z in cocompact E3, g z < m / 2 := hl.eventually (gt_mem_nhds (by linarith))
  rw [← Metric.cobounded_eq_cocompact, ← comap_norm_atTop, eventually_comap,
    eventually_atTop] at hev
  obtain ⟨R₀, hR₀⟩ := hev
  set R := max R₀ (‖x₀‖ + 1)
  have hRpos : 0 < R := lt_of_lt_of_le (by positivity) (le_max_right _ _)
  set ε := m / (4 * R ^ 2)
  have hε : 0 < ε := by positivity
  set v : E3 → ℝ := fun z => g z + ε * ‖z‖ ^ 2
  have hv : Continuous v := hg.continuous.add (continuous_const.mul (by fun_prop))
  have hx₀ : x₀ ∈ Metric.closedBall (0 : E3) R := by
    rw [Metric.mem_closedBall, dist_zero_right]; linarith [le_max_right R₀ (‖x₀‖ + 1)]
  obtain ⟨y, hy, hymax⟩ := (isCompact_closedBall (0 : E3) R).exists_isMaxOn ⟨x₀, hx₀⟩
    hv.continuousOn
  have hvy : m ≤ v y := by
    have h : g x₀ + ε * ‖x₀‖ ^ 2 ≤ g y + ε * ‖y‖ ^ 2 := hymax hx₀
    simp only [v]
    nlinarith [sq_nonneg ‖x₀‖]
  have hyR : ‖y‖ ≤ R := by simpa using hy
  have hyR₀ : ‖y‖ < R₀ := by
    by_contra hge
    push Not at hge
    have h1 := hR₀ ‖y‖ hge y rfl
    have h2 : ε * ‖y‖ ^ 2 ≤ m / 4 := by
      have : ‖y‖ ^ 2 ≤ R ^ 2 := by gcongr
      calc ε * ‖y‖ ^ 2 ≤ ε * R ^ 2 := by gcongr
        _ = m / 4 := by simp only [ε]; field_simp
    simp only [v] at hvy
    linarith
  have hyball : y ∈ Metric.ball (0 : E3) R := by
    rw [Metric.mem_ball, dist_zero_right]; linarith [le_max_left R₀ (‖x₀‖ + 1)]
  have hloc : IsLocalMax v y :=
    hymax.isLocalMax (Filter.mem_of_superset (Metric.isOpen_ball.mem_nhds hyball)
      Metric.ball_subset_closedBall)
  have hsum := hΔ y
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis g
    (EuclideanSpace.basisFun (Fin 3) ℝ)] at hsum
  beta_reduce at hsum
  rw [Fin.sum_univ_three] at hsum
  have hi : ∀ i, iteratedFDeriv ℝ 2 g y
      ![EuclideanSpace.basisFun (Fin 3) ℝ i, EuclideanSpace.basisFun (Fin 3) ℝ i] + 2 * ε ≤ 0 :=
    fun i => second_deriv_at_max g hg ε y _
      ((EuclideanSpace.basisFun (Fin 3) ℝ).orthonormal.1 i) hloc
  linarith [hi 0, hi 1, hi 2]

end Helpers

#print axioms coord3_mp
#print axioms coord3_norm_sq
#print axioms coord3_dist
#print axioms radial_part
#print axioms inner2D
#print axioms hasDerivAt_mul_abs
#print axioms oneD_pos
#print axioms oneD_zero
#print axioms outer_conv
#print axioms ball_lintegral
#print axioms I_nonneg
#print axioms I_inside
#print axioms I_outside
#print axioms reflect_lintegral
#print axioms ball_integral_value
#print axioms line_derivs
#print axioms second_deriv_at_max
#print axioms harmonic_vanishing_nonpos

/-- **The charged ball.** Charge `Q` spread evenly through a ball of radius `R`, with
charge density `ρ = Q / ((4/3)πR³)` inside and `0` outside, has the potential
`V(x) = (1/(4πε₀)) ∫ ρ(y)/|x - y| dy`. With `k = 1/(4πε₀)` and `r = |x|`, this is the dome
`V = kQ/(2R) · (3 - r²/R²)` for `r ≤ R`, and the point-charge potential `V = kQ/r` for `r ≥ R`. -/
theorem charged_ball_potential (ε₀ Q R : ℝ) (hR : 0 < R) :
    let k := 1 / (4 * π * ε₀)
    let ρ : E3 → ℝ := (Metric.closedBall (0 : E3) R).indicator (fun _ => Q / (4 / 3 * π * R ^ 3))
    let V : E3 → ℝ := fun x => k * ∫ y, ρ y / ‖x - y‖
    (∀ x : E3, ‖x‖ ≤ R → V x = k * Q / (2 * R) * (3 - ‖x‖ ^ 2 / R ^ 2)) ∧
      (∀ x : E3, R ≤ ‖x‖ → V x = k * Q / ‖x‖) := by
  intro k ρ V
  have key : ∀ x : E3, ∫ y, ρ y / ‖x - y‖ =
      Q / (4 / 3 * π * R ^ 3) * ∫ y : E3, (if ‖y‖ ≤ R then 1 / ‖x - y‖ else 0) := by
    intro x
    rw [← integral_const_mul]
    congr 1
    funext y
    simp only [ρ, Set.indicator, Metric.mem_closedBall, dist_zero_right]
    split_ifs <;> ring
  refine ⟨fun x hx => ?_, fun x hx => ?_⟩
  · simp only [V]
    rw [key, ball_integral_value R hR, I_inside R _ hR (norm_nonneg _) hx]
    have h : Q / (4 / 3 * π * R ^ 3) * (2 * π * (R ^ 2 - ‖x‖ ^ 2 / 3)) =
        Q / (2 * R) * (3 - ‖x‖ ^ 2 / R ^ 2) := by
      field_simp
      ring
    rw [h]; ring
  · simp only [V]
    rw [key, ball_integral_value R hR, I_outside R _ hR hx]
    have hx0 : 0 < ‖x‖ := lt_of_lt_of_le hR hx
    have h : Q / (4 / 3 * π * R ^ 3) * (2 * π * (2 * R ^ 3 / (3 * ‖x‖))) = Q / ‖x‖ := by
      field_simp
      ring
    rw [h]; ring

/-- **Only one solution vanishes far away.** If `u₁` and `u₂` are twice continuously
differentiable on all of space, both solve `-Δu = f`, and both tend to `0` far away,
then they are the same function. -/
theorem poisson_solution_vanishing_at_infinity_unique (f u₁ u₂ : E3 → ℝ)
    (h₁ : ContDiff ℝ 2 u₁) (h₂ : ContDiff ℝ 2 u₂)
    (hp₁ : ∀ x, -Δ u₁ x = f x) (hp₂ : ∀ x, -Δ u₂ x = f x)
    (hl₁ : Tendsto u₁ (cocompact E3) (𝓝 0)) (hl₂ : Tendsto u₂ (cocompact E3) (𝓝 0)) :
    u₁ = u₂ := by
  have hc : ContDiff ℝ 2 (u₁ - u₂) := h₁.sub h₂
  have hΔ : ∀ x, Δ (u₁ - u₂) x = 0 := fun x => by
    rw [h₁.contDiffAt.laplacian_sub h₂.contDiffAt]
    have a := hp₁ x
    have b := hp₂ x
    linarith
  have hl : Tendsto (u₁ - u₂) (cocompact E3) (𝓝 0) := by
    have := hl₁.sub hl₂; rw [sub_zero] at this; exact this
  have hle := harmonic_vanishing_nonpos _ hc hΔ hl
  have hge := harmonic_vanishing_nonpos (-(u₁ - u₂)) hc.neg
    (fun x => by rw [InnerProductSpace.laplacian_neg]; simp [hΔ x]) (by have := hl.neg; rw [neg_zero] at this; exact this)
  funext x
  have a := hle x
  have b := hge x
  simp only [Pi.sub_apply, Pi.neg_apply] at a b
  linarith

-- The card's exact ratios, in units of the surface value kQ/R.
-- The centre sits 3/2 times the surface value: (3 - 0)/2.
example : ((3 : ℚ) - 0 ^ 2) / 2 = 3 / 2 := by norm_num
-- Halfway out, r = R/2: (3 - 1/4)/2 = 11/8 (17.8142 MV times 11/8 is 24.4945 MV).
example : ((3 : ℚ) - (1 / 2) ^ 2) / 2 = 11 / 8 := by norm_num
-- Keeping only the inner charge at R/2 gives (1/2)³/(1/2) = 1/4 of kQ/R, not 11/8.
example : ((1 / 2 : ℚ) ^ 3) / (1 / 2) = 1 / 4 := by norm_num
-- Second derivative at the surface: -1 inside, +2 outside (units kQ/R³); the jump 3 is ρ/ε₀ = 3kQ/R³.
example : (2 : ℚ) - (-1) = 3 := by norm_num
-- Stored energy U = (1/2) ∫ ρ V: with s = r/R it is (1/2) ∫₀¹ 3s² (3 - s²)/2 ds = 3/5, in units of kQ²/R.
example : (1 / 2 : ℚ) * (3 * (3 * (1 / 3 : ℚ) - 1 / 5) / 2) = 3 / 5 := by norm_num
-- A uniform charge filling a ball of radius L R has centre potential growing as L²: four-fold per doubling.
example : ((2 : ℚ) * 8) ^ 2 / 8 ^ 2 = 4 := by norm_num

#print axioms charged_ball_potential
#print axioms poisson_solution_vanishing_at_infinity_unique
