-- The fundamental solution: the potential 1/(4πr) of a unit point source in space, and −ln r/(2π) in the plane, satisfy the point-source identity −ΔΦ = δ against every test function, and are harmonic away from the source.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.LineDeriv.IntegrationByParts
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.Analysis.SpecialFunctions.JapaneseBracket
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.NegMulLog
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.InnerProductSpace.Calculus

open Real Laplacian MeasureTheory InnerProductSpace
open scoped ContDiff

/-! Space is `EuclideanSpace ℝ (Fin 3)` and the plane is `EuclideanSpace ℝ (Fin 2)`, each with
its Lebesgue measure `volume`. The source sits at the origin and `r = ‖x‖` is the distance to it.
The Laplacian is Mathlib's `Δ f = f_{x₁x₁} + … + f_{x_dx_d}`. A test function (a "test bump")
is a real function that is infinitely differentiable (`ContDiff ℝ ∞ φ`) and zero outside a
bounded set (`HasCompactSupport φ`). The statement `−ΔΦ = δ` as distributions means exactly
`∫ Φ · (−Δφ) dx = φ(0)` for every test function `φ`. At the origin itself Lean's `1 / 0 = 0`
and `log 0 = 0` give `Φ` the value `0`; one point has measure zero, so the integrals do not see
it. -/

/-- The fundamental solution of the Laplacian in space: `Φ(x) = 1 / (4π|x|)`. -/
noncomputable def fundSol3 (x : EuclideanSpace ℝ (Fin 3)) : ℝ := 1 / (4 * π * ‖x‖)

/-- The fundamental solution of the Laplacian in the plane: `Φ(x) = −ln|x| / (2π)`. -/
noncomputable def fundSol2 (x : EuclideanSpace ℝ (Fin 2)) : ℝ := -Real.log ‖x‖ / (2 * π)

section FundSolHelpers

open Filter Set Metric
open scoped Topology

open Module in
lemma laplacian_radial {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E] (g g' : ℝ → ℝ) (g'' : ℝ) (x : E)
    (hg : ∀ᶠ s in 𝓝 (‖x‖ ^ 2), HasDerivAt g (g' s) s) (hg' : HasDerivAt g' g'' (‖x‖ ^ 2)) :
    (Δ (fun y : E => g (‖y‖ ^ 2)) : E → ℝ) x =
      4 * ‖x‖ ^ 2 * g'' + 2 * finrank ℝ E * g' (‖x‖ ^ 2) := by
  have hc : Continuous (fun y : E => ‖y‖ ^ 2) := by fun_prop
  have h1 : ∀ᶠ y in 𝓝 x, HasFDerivAt (fun y => g (‖y‖ ^ 2))
      (g' (‖y‖ ^ 2) • ((2:ℕ) • innerSL ℝ y)) y := by
    filter_upwards [(hc.tendsto x).eventually hg] with y hy
    exact hy.comp_hasFDerivAt y (hasStrictFDerivAt_norm_sq y).hasFDerivAt
  have h2 : fderiv ℝ (fun y => g (‖y‖ ^ 2)) =ᶠ[𝓝 x]
      fun y => g' (‖y‖ ^ 2) • ((2:ℕ) • innerSL ℝ y) := h1.mono fun y hy => hy.fderiv
  have hcd : HasFDerivAt (fun y : E => g' (‖y‖ ^ 2)) (g'' • ((2:ℕ) • innerSL ℝ x)) x :=
    hg'.comp_hasFDerivAt x (hasStrictFDerivAt_norm_sq x).hasFDerivAt
  have hl : HasFDerivAt (fun y : E => (2:ℕ) • innerSL ℝ y) ((2:ℕ) • innerSL ℝ) x := by
    have := ((innerSL ℝ : E →L[ℝ] E →L[ℝ] ℝ).hasFDerivAt (x := x)).const_smul (2:ℕ)
    exact this
  have h3 : HasFDerivAt (fun y => g' (‖y‖ ^ 2) • ((2:ℕ) • innerSL ℝ y)) _ x := hcd.smul hl
  rw [laplacian_eq_iteratedFDeriv_stdOrthonormalBasis]
  simp only [iteratedFDeriv_two_apply]
  rw [h2.fderiv_eq, h3.fderiv]
  set b := stdOrthonormalBasis ℝ E
  simp
  have hb : ∀ i, innerSL ℝ (b i) (b i) = 1 := by
    intro i
    simp [b.orthonormal.1 i]
  have hs : ∑ i, ⟪x, b i⟫_ℝ * ⟪x, b i⟫_ℝ = ‖x‖ ^ 2 := by
    rw [← real_inner_self_eq_norm_sq, ← b.sum_inner_mul_inner x x]
    exact Finset.sum_congr rfl fun i _ => by
      rw [real_inner_comm (b i) x]
  simp only [hb]
  calc _ = ∑ i, (2 * g' (‖x‖ ^ 2) + 4 * g'' * (⟪x, b i⟫_ℝ * ⟪x, b i⟫_ℝ)) :=
        Finset.sum_congr rfl fun i _ => by ring
    _ = _ := by
        rw [Finset.sum_add_distrib, Finset.sum_const, ← Finset.mul_sum, hs]
        simp only [Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
        ring

noncomputable def P3 (a : ℝ) (y : EuclideanSpace ℝ (Fin 3)) : ℝ :=
  (4 * π)⁻¹ * (‖y‖ ^ 2 + a) ^ (-1/2 : ℝ)

lemma P3_hasDerivAt1 (a s : ℝ) (h : 0 < s + a) :
    HasDerivAt (fun s : ℝ => (4 * π)⁻¹ * (s + a) ^ (-1/2 : ℝ))
      ((4 * π)⁻¹ * (-1/2 * (s + a) ^ (-3/2 : ℝ))) s := by
  have := (((hasDerivAt_id s).add_const a).rpow_const (p := (-1/2 : ℝ)) (Or.inl h.ne')).const_mul
    (4 * π)⁻¹
  convert this using 2
  simp only [id]; norm_num

lemma P3_hasDerivAt2 (a s : ℝ) (h : 0 < s + a) :
    HasDerivAt (fun s : ℝ => (4 * π)⁻¹ * (-1/2 * (s + a) ^ (-3/2 : ℝ)))
      ((4 * π)⁻¹ * (-1/2 * (-3/2 * (s + a) ^ (-5/2 : ℝ)))) s := by
  have := ((((hasDerivAt_id s).add_const a).rpow_const (p := (-3/2 : ℝ)) (Or.inl h.ne')).const_mul
    (-1/2 : ℝ)).const_mul (4 * π)⁻¹
  convert this using 3
  simp only [id]; norm_num

lemma laplacian_P3 (a : ℝ) (x : EuclideanSpace ℝ (Fin 3)) (h : 0 < ‖x‖ ^ 2 + a) :
    Δ (P3 a) x = -3 * (4 * π)⁻¹ * a * (‖x‖ ^ 2 + a) ^ (-5/2 : ℝ) := by
  have hev : ∀ᶠ s in 𝓝 (‖x‖ ^ 2), HasDerivAt (fun s : ℝ => (4 * π)⁻¹ * (s + a) ^ (-1/2 : ℝ))
      ((fun s : ℝ => (4 * π)⁻¹ * (-1/2 * (s + a) ^ (-3/2 : ℝ))) s) s := by
    have : ∀ᶠ s in 𝓝 (‖x‖ ^ 2), 0 < s + a :=
      ((continuous_id.add continuous_const).tendsto (‖x‖ ^ 2)).eventually (lt_mem_nhds (by simpa using h))
    exact this.mono fun s hs => P3_hasDerivAt1 a s hs
  have := laplacian_radial _ _ _ x hev (P3_hasDerivAt2 a _ h)
  rw [show P3 a = fun y => (4 * π)⁻¹ * (‖y‖ ^ 2 + a) ^ (-1/2 : ℝ) from rfl, this]
  simp only [finrank_euclideanSpace_fin]
  have e : (‖x‖ ^ 2 + a) ^ (-3/2 : ℝ) = (‖x‖ ^ 2 + a) ^ (-5/2 : ℝ) * (‖x‖ ^ 2 + a) := by
    rw [← Real.rpow_add_one h.ne']; norm_num
  rw [e]; push_cast; ring

noncomputable def L2 (a : ℝ) (y : EuclideanSpace ℝ (Fin 2)) : ℝ :=
  -(4 * π)⁻¹ * Real.log (‖y‖ ^ 2 + a)

lemma L2_hasDerivAt1 (a s : ℝ) (h : 0 < s + a) :
    HasDerivAt (fun s : ℝ => -(4 * π)⁻¹ * Real.log (s + a)) (-(4 * π)⁻¹ * (s + a)⁻¹) s := by
  have := (((hasDerivAt_id s).add_const a).log h.ne').const_mul (-(4 * π)⁻¹)
  convert this using 2 <;> simp

lemma L2_hasDerivAt2 (a s : ℝ) (h : 0 < s + a) :
    HasDerivAt (fun s : ℝ => -(4 * π)⁻¹ * (s + a)⁻¹) (-(4 * π)⁻¹ * (-1 / (s + a) ^ 2)) s := by
  have := (((hasDerivAt_id s).add_const a).inv h.ne').const_mul (-(4 * π)⁻¹)
  convert this using 2 <;> simp

lemma laplacian_L2 (a : ℝ) (x : EuclideanSpace ℝ (Fin 2)) (h : 0 < ‖x‖ ^ 2 + a) :
    Δ (L2 a) x = -a / (π * (‖x‖ ^ 2 + a) ^ 2) := by
  have hev : ∀ᶠ s in 𝓝 (‖x‖ ^ 2), HasDerivAt (fun s : ℝ => -(4 * π)⁻¹ * Real.log (s + a))
      ((fun s : ℝ => -(4 * π)⁻¹ * (s + a)⁻¹) s) s := by
    have : ∀ᶠ s in 𝓝 (‖x‖ ^ 2), 0 < s + a :=
      ((continuous_id.add continuous_const).tendsto (‖x‖ ^ 2)).eventually
        (lt_mem_nhds (by simpa using h))
    exact this.mono fun s hs => L2_hasDerivAt1 a s hs
  have := laplacian_radial _ _ _ x hev (L2_hasDerivAt2 a _ h)
  rw [show L2 a = fun y => -(4 * π)⁻¹ * Real.log (‖y‖ ^ 2 + a) from rfl, this]
  simp only [finrank_euclideanSpace_fin]
  have hp := Real.pi_pos
  field_simp
  push_cast
  ring

lemma fundSol3_eq : fundSol3 = P3 0 := by
  funext y
  simp only [fundSol3, P3, add_zero]
  rw [← Real.rpow_natCast, ← Real.rpow_mul (norm_nonneg _)]
  norm_num
  rw [Real.rpow_neg_one]; ring

lemma fundSol2_eq : fundSol2 = L2 0 := by
  funext y
  simp only [fundSol2, L2, add_zero, Real.log_pow]
  push_cast
  field_simp
  ring

lemma fundamental_solution_harmonic_off_source_aux :
    HarmonicOnNhd fundSol3 {x | x ≠ 0} ∧ HarmonicOnNhd fundSol2 {x | x ≠ 0} := by
  constructor
  · intro x hx
    rw [fundSol3_eq]
    have hx' : ∀ y : EuclideanSpace ℝ (Fin 3), y ≠ 0 → 0 < ‖y‖ ^ 2 + 0 := fun y hy => by
      simpa [sq_pos_iff] using hy
    refine ⟨?_, ?_⟩
    · have : ContDiffAt ℝ 2 (fun s : ℝ => s ^ (-1/2 : ℝ)) (‖x‖ ^ 2 + 0) :=
        contDiffAt_rpow_const_of_ne (hx' x hx).ne'
      exact contDiffAt_const.mul (this.comp x ((contDiff_norm_sq ℝ).add contDiff_const).contDiffAt)
    · filter_upwards [isOpen_ne.mem_nhds hx] with y hy
      rw [laplacian_P3 0 y (hx' y hy)]
      simp
  · intro x hx
    rw [fundSol2_eq]
    have hx' : ∀ y : EuclideanSpace ℝ (Fin 2), y ≠ 0 → 0 < ‖y‖ ^ 2 + 0 := fun y hy => by
      simpa [sq_pos_iff] using hy
    refine ⟨?_, ?_⟩
    · exact contDiffAt_const.mul ((contDiffAt_log.2 (hx' x hx).ne').comp x
        ((contDiff_norm_sq ℝ).add contDiff_const).contDiffAt)
    · filter_upwards [isOpen_ne.mem_nhds hx] with y hy
      rw [laplacian_L2 0 y (hx' y hy)]
      simp

lemma contDiff_fderiv_apply' {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {u : E → ℝ} (hu : ContDiff ℝ ∞ u) (w : E) : ContDiff ℝ ∞ (fun y => fderiv ℝ u y w) :=
  (hu.fderiv_right (m := ∞) (by simp)).clm_apply contDiff_const

lemma fderiv_fderiv_apply' {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {u : E → ℝ} (hu : ContDiff ℝ ∞ u) (x w : E) :
    fderiv ℝ (fderiv ℝ u) x w w = fderiv ℝ (fun y => fderiv ℝ u y w) x w := by
  have hd : DifferentiableAt ℝ (fderiv ℝ u) x :=
    ((hu.fderiv_right (m := ∞) (by simp)).differentiable (by simp)) x
  rw [fderiv_clm_apply hd (differentiableAt_const w)]
  simp

lemma green_one {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    [MeasurableSpace E] [BorelSpace E] (μ : Measure E) [μ.IsAddHaarMeasure]
    (u φ : E → ℝ) (hu : ContDiff ℝ ∞ u) (hφ : ContDiff ℝ ∞ φ) (hc : HasCompactSupport φ) (w : E) :
    ∫ x, u x * fderiv ℝ (fderiv ℝ φ) x w w ∂μ = ∫ x, fderiv ℝ (fderiv ℝ u) x w w * φ x ∂μ := by
  have hφw := contDiff_fderiv_apply' hφ w
  have huw := contDiff_fderiv_apply' hu w
  have hφww := contDiff_fderiv_apply' hφw w
  have huww := contDiff_fderiv_apply' huw w
  have hcw : HasCompactSupport (fun y => fderiv ℝ φ y w) := hc.fderiv_apply ℝ w
  have hcww : HasCompactSupport (fun y => fderiv ℝ (fun y => fderiv ℝ φ y w) y w) :=
    hcw.fderiv_apply ℝ w
  simp only [fderiv_fderiv_apply' hφ, fderiv_fderiv_apply' hu]
  have h1 := integral_mul_fderiv_eq_neg_fderiv_mul_of_integrable (μ := μ) (f := u)
    (g := fun y => fderiv ℝ φ y w) (v := w)
    ((huw.continuous.mul hφw.continuous).integrable_of_hasCompactSupport hcw.mul_left)
    ((hu.continuous.mul hφww.continuous).integrable_of_hasCompactSupport hcww.mul_left)
    ((hu.continuous.mul hφw.continuous).integrable_of_hasCompactSupport hcw.mul_left)
    (fun x _ => (hu.differentiable (by simp)) x) (fun x _ => (hφw.differentiable (by simp)) x)
  have h2 := integral_mul_fderiv_eq_neg_fderiv_mul_of_integrable (μ := μ)
    (f := fun y => fderiv ℝ u y w) (g := φ) (v := w)
    ((huww.continuous.mul hφ.continuous).integrable_of_hasCompactSupport hc.mul_left)
    ((huw.continuous.mul hφw.continuous).integrable_of_hasCompactSupport hcw.mul_left)
    ((huw.continuous.mul hφ.continuous).integrable_of_hasCompactSupport hc.mul_left)
    (fun x _ => (huw.differentiable (by simp)) x) (fun x _ => (hφ.differentiable (by simp)) x)
  rw [h1, h2, neg_neg]

lemma green {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
    [MeasurableSpace E] [BorelSpace E] (μ : Measure E) [μ.IsAddHaarMeasure]
    (u φ : E → ℝ) (hu : ContDiff ℝ ∞ u) (hφ : ContDiff ℝ ∞ φ) (hc : HasCompactSupport φ) :
    ∫ x, u x * (Δ φ : E → ℝ) x ∂μ = ∫ x, (Δ u : E → ℝ) x * φ x ∂μ := by
  rw [laplacian_eq_iteratedFDeriv_stdOrthonormalBasis φ,
    laplacian_eq_iteratedFDeriv_stdOrthonormalBasis u]
  simp only [iteratedFDeriv_two_apply, Matrix.cons_val_zero, Matrix.cons_val_one,
    Finset.mul_sum, Finset.sum_mul]
  have hint : ∀ (f g : E → ℝ), ContDiff ℝ ∞ f → ContDiff ℝ ∞ g → HasCompactSupport g → ∀ w : E,
      Integrable (fun x => f x * fderiv ℝ (fderiv ℝ g) x w w) μ := by
    intro f g hf hg hgc w
    simp only [fderiv_fderiv_apply' hg]
    exact (hf.continuous.mul (contDiff_fderiv_apply' (contDiff_fderiv_apply' hg w) w).continuous
      ).integrable_of_hasCompactSupport ((hgc.fderiv_apply ℝ w).fderiv_apply ℝ w).mul_left
  have hint2 : ∀ w : E, Integrable (fun x => fderiv ℝ (fderiv ℝ u) x w w * φ x) μ := by
    intro w
    simp only [fderiv_fderiv_apply' hu]
    exact ((contDiff_fderiv_apply' (contDiff_fderiv_apply' hu w) w).continuous.mul
      hφ.continuous).integrable_of_hasCompactSupport hc.mul_left
  rw [integral_finsetSum _ (fun i _ => hint u φ hu hφ hc _),
    integral_finsetSum _ (fun i _ => hint2 _)]
  exact Finset.sum_congr rfl fun i _ => green_one μ u φ hu hφ hc _

lemma laplacian_test {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E] {φ : E → ℝ} (hφ : ContDiff ℝ ∞ φ) (hc : HasCompactSupport φ) :
    Continuous (Δ φ : E → ℝ) ∧ HasCompactSupport (Δ φ : E → ℝ) := by
  have he : (Δ φ : E → ℝ) = fun x => ∑ i, fderiv ℝ (fun y => fderiv ℝ φ y
      (stdOrthonormalBasis ℝ E i)) x (stdOrthonormalBasis ℝ E i) := by
    rw [laplacian_eq_iteratedFDeriv_stdOrthonormalBasis φ]
    funext x
    simp only [iteratedFDeriv_two_apply, Matrix.cons_val_zero, Matrix.cons_val_one,
      fderiv_fderiv_apply' hφ]
  refine ⟨?_, ?_⟩
  · rw [he]
    exact continuous_finsetSum _ fun i _ =>
      (contDiff_fderiv_apply' (contDiff_fderiv_apply' hφ _) _).continuous
  · refine hc.mono' fun x hx => ?_
    by_contra hx'
    apply hx
    have h0 : φ =ᶠ[𝓝 x] (fun _ => (0:ℝ)) := (notMem_tsupport_iff_eventuallyEq.1 hx')
    rw [(laplacian_congr_nhds h0).eq_of_nhds]
    simp

lemma integrable_mul_of_ball {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [MeasurableSpace E] [BorelSpace E] [ProperSpace E] {μ : Measure E}
    (Φ g : E → ℝ) (hΦ : ∀ R, IntegrableOn Φ (ball 0 R) μ) (hg : Continuous g)
    (hgc : HasCompactSupport g) : Integrable (fun x => Φ x * g x) μ := by
  obtain ⟨R, hR⟩ := hgc.isCompact.isBounded.subset_ball 0
  have : IntegrableOn (fun x => Φ x * g x) (ball 0 R) μ :=
    (hΦ R).mul_continuousOn_of_subset hg.continuousOn measurableSet_ball
      (isCompact_closedBall 0 R) ball_subset_closedBall
  exact this.integrable_of_forall_notMem_eq_zero fun x hx => by
    simp [image_eq_zero_of_notMem_tsupport (fun h => hx (hR h))]

lemma fundSol3_integrableOn (R : ℝ) : IntegrableOn fundSol3 (ball 0 R) := by
  have : IntegrableOn (fun r : ℝ => r ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin 3)) - 1) •
      (1 / (4 * π * r))) (Ioo 0 R) := by
    have hc : IntegrableOn (fun r : ℝ => r / (4 * π)) (Ioo 0 R) :=
      ((continuous_id.div_const _).continuousOn.integrableOn_Icc).mono_set Ioo_subset_Icc_self
    refine hc.congr_fun (fun r hr => ?_) measurableSet_Ioo
    have : (0:ℝ) < r := hr.1
    simp only [finrank_euclideanSpace_fin, smul_eq_mul]
    field_simp
  exact (integrableOn_fun_norm_addHaar volume (f := fun r => 1 / (4 * π * r))).2 this

lemma fundSol2_integrableOn (R : ℝ) : IntegrableOn fundSol2 (ball 0 R) := by
  have : IntegrableOn (fun r : ℝ => r ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin 2)) - 1) •
      (-Real.log r / (2 * π))) (Ioo 0 R) := by
    have hc : IntegrableOn (fun r : ℝ => -(r * Real.log r) / (2 * π)) (Ioo 0 R) :=
      ((Real.continuous_mul_log.neg.div_const _).continuousOn.integrableOn_Icc).mono_set
        Ioo_subset_Icc_self
    refine hc.congr_fun (fun r hr => ?_) measurableSet_Ioo
    simp only [finrank_euclideanSpace_fin, smul_eq_mul]
    ring
  exact (integrableOn_fun_norm_addHaar volume (f := fun r => -Real.log r / (2 * π))).2 this

lemma I1 : ∫ r in Ioi (0:ℝ), r ^ 2 * (1 + r ^ 2) ^ (-5/2 : ℝ) = 1 / 3 := by
  have hderiv : ∀ r ∈ Ici (0:ℝ), HasDerivAt (fun r : ℝ => r ^ 3 * (1 + r ^ 2) ^ (-3/2 : ℝ) / 3)
      (r ^ 2 * (1 + r ^ 2) ^ (-5/2 : ℝ)) r := by
    intro r _
    have hp : (0:ℝ) < 1 + r ^ 2 := by positivity
    have h1 := ((hasDerivAt_pow 3 r).mul ((((hasDerivAt_id r).pow 2).const_add 1).rpow_const
      (p := (-3/2 : ℝ)) (Or.inl hp.ne'))).div_const 3
    have e : (1 + r ^ 2) ^ (-(3/2) : ℝ) = (1 + r ^ 2) ^ (-(5/2) : ℝ) * (1 + r ^ 2) := by
      rw [← Real.rpow_add_one hp.ne']; norm_num
    refine h1.congr_deriv ?_
    simp only [id, Pi.pow_apply]
    norm_num
    rw [e]
    ring
  have hlim : Tendsto (fun r : ℝ => r ^ 3 * (1 + r ^ 2) ^ (-3/2 : ℝ) / 3) atTop (𝓝 (1 / 3)) := by
    have hu : Tendsto (fun r : ℝ => r ^ 2 / (1 + r ^ 2)) atTop (𝓝 1) := by
      have h0 : Tendsto (fun r : ℝ => (1 + r ^ 2)⁻¹) atTop (𝓝 0) :=
        tendsto_inv_atTop_zero.comp (tendsto_atTop_add_const_left _ _
          (tendsto_pow_atTop two_ne_zero))
      have := (tendsto_const_nhds (x := (1:ℝ))).sub h0
      simp only [sub_zero] at this
      refine this.congr' (Eventually.of_forall fun r => ?_)
      have hp : (0:ℝ) < 1 + r ^ 2 := by positivity
      field_simp
      ring
    have h2 := (hu.rpow_const (p := (3/2 : ℝ)) (Or.inl one_ne_zero)).div_const 3
    simp only [Real.one_rpow] at h2
    refine h2.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with r hr
    have hp : (0:ℝ) < 1 + r ^ 2 := by positivity
    rw [Real.div_rpow (by positivity) hp.le, show (-3/2:ℝ) = -(3/2) by norm_num,
      Real.rpow_neg hp.le, ← div_eq_mul_inv]
    congr 2
    rw [← Real.rpow_natCast, ← Real.rpow_natCast, ← Real.rpow_mul hr.le]
    norm_num
  have := integral_Ioi_of_hasDerivAt_of_nonneg' hderiv (fun r _ => by positivity) hlim
  rw [this]
  simp

lemma I2 : ∫ r in Ioi (0:ℝ), r * ((1 + r ^ 2) ^ 2)⁻¹ = 1 / 2 := by
  have hderiv : ∀ r ∈ Ici (0:ℝ), HasDerivAt (fun r : ℝ => -(1 + r ^ 2)⁻¹ / 2)
      (r * ((1 + r ^ 2) ^ 2)⁻¹) r := by
    intro r _
    have hp : (0:ℝ) < 1 + r ^ 2 := by positivity
    have h1 := ((((hasDerivAt_id r).pow 2).const_add 1).inv hp.ne').neg.div_const 2
    refine h1.congr_deriv ?_
    simp only [id, Pi.pow_apply]
    field_simp
    ring
  have hlim : Tendsto (fun r : ℝ => -(1 + r ^ 2)⁻¹ / 2) atTop (𝓝 0) := by
    have h0 : Tendsto (fun r : ℝ => (1 + r ^ 2)⁻¹) atTop (𝓝 0) :=
      tendsto_inv_atTop_zero.comp (tendsto_atTop_add_const_left _ _
        (tendsto_pow_atTop two_ne_zero))
    simpa using h0.neg.div_const 2
  have := integral_Ioi_of_hasDerivAt_of_nonneg' hderiv
    (fun r hr => by have : (0:ℝ) < r := hr; positivity) hlim
  rw [this]
  norm_num

lemma integral_K3 :
    ∫ y : EuclideanSpace ℝ (Fin 3), 3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ) = 1 := by
  have := integral_fun_norm_addHaar (volume : Measure (EuclideanSpace ℝ (Fin 3)))
    (fun r => 3 * (4 * π)⁻¹ * (1 + r ^ 2) ^ (-5/2 : ℝ))
  rw [this]
  have hv : (volume : Measure (EuclideanSpace ℝ (Fin 3))).real (ball 0 1) = π * 4 / 3 := by
    simp only [Measure.real, EuclideanSpace.volume_ball_fin_three]
    rw [ENNReal.toReal_mul]
    simp [ENNReal.toReal_ofReal (by positivity : (0:ℝ) ≤ π * 4 / 3)]
  have hi : ∫ r in Ioi (0:ℝ), r ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin 3)) - 1) •
      (3 * (4 * π)⁻¹ * (1 + r ^ 2) ^ (-5/2 : ℝ)) = 3 * (4 * π)⁻¹ * (1 / 3) := by
    rw [← I1, ← integral_const_mul]
    refine setIntegral_congr_fun measurableSet_Ioi fun r _ => ?_
    simp only [finrank_euclideanSpace_fin, smul_eq_mul]
    ring
  rw [hi, hv]
  simp only [finrank_euclideanSpace_fin, smul_eq_mul, nsmul_eq_mul]
  have := Real.pi_pos
  field_simp
  norm_num

lemma integral_K2 :
    ∫ y : EuclideanSpace ℝ (Fin 2), π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹ = 1 := by
  have := integral_fun_norm_addHaar (volume : Measure (EuclideanSpace ℝ (Fin 2)))
    (fun r => π⁻¹ * ((1 + r ^ 2) ^ 2)⁻¹)
  rw [this]
  have hv : (volume : Measure (EuclideanSpace ℝ (Fin 2))).real (ball 0 1) = π := by
    simp only [Measure.real, EuclideanSpace.volume_ball_fin_two]
    rw [ENNReal.toReal_mul]
    simp [ENNReal.toReal_ofReal Real.pi_pos.le]
  have hi : ∫ r in Ioi (0:ℝ), r ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin 2)) - 1) •
      (π⁻¹ * ((1 + r ^ 2) ^ 2)⁻¹) = π⁻¹ * (1 / 2) := by
    rw [← I2, ← integral_const_mul]
    refine setIntegral_congr_fun measurableSet_Ioi fun r _ => ?_
    simp only [finrank_euclideanSpace_fin, smul_eq_mul]
    ring
  rw [hi, hv]
  simp only [finrank_euclideanSpace_fin, smul_eq_mul, nsmul_eq_mul]
  have := Real.pi_pos
  field_simp
  norm_num

lemma limit_space (φ : EuclideanSpace ℝ (Fin 3) → ℝ) (hφ : ContDiff ℝ ∞ φ)
    (hc : HasCompactSupport φ) :
    Tendsto (fun ε : ℝ => ∫ y, 3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ) * φ (ε • y))
      (𝓝[>] 0) (𝓝 (φ 0)) := by
  obtain ⟨C, hC⟩ := hφ.continuous.bounded_above_of_compact_support hc
  have hK : Integrable (fun y : EuclideanSpace ℝ (Fin 3) =>
      3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ)) := by
    have := integrable_rpow_neg_one_add_norm_sq (E := EuclideanSpace ℝ (Fin 3))
      (μ := volume) (r := 5) (by simp; norm_num)
    exact (this.const_mul (3 * (4 * π)⁻¹)).congr (Eventually.of_forall fun y => by norm_num)
  have hlim := tendsto_integral_filter_of_dominated_convergence
    (l := 𝓝[>] (0:ℝ)) (μ := volume)
    (F := fun ε y => 3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ) * φ (ε • y))
    (f := fun y => 3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ) * φ 0)
    (fun y => 3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ) * C)
    (Eventually.of_forall fun ε => (hK.aestronglyMeasurable.mul
      (hφ.continuous.comp (continuous_const_smul ε)).aestronglyMeasurable :))
    (Eventually.of_forall fun ε => Eventually.of_forall fun y => by
      rw [norm_mul]
      have h0 : 0 ≤ 3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ) := by positivity
      rw [Real.norm_of_nonneg h0]
      exact mul_le_mul_of_nonneg_left (hC _) h0)
    (hK.mul_const C)
    (Eventually.of_forall fun y => by
      refine tendsto_const_nhds.mul ?_
      have : Tendsto (fun ε : ℝ => ε • y) (𝓝[>] 0) (𝓝 ((0:ℝ) • y)) :=
        ((continuous_id.smul continuous_const).tendsto 0).mono_left nhdsWithin_le_nhds
      rw [zero_smul] at this
      exact (hφ.continuous.tendsto 0).comp this)
  rwa [integral_mul_const, integral_K3, one_mul] at hlim

lemma P3_contDiff (ε : ℝ) (hε : 0 < ε) : ContDiff ℝ ∞ (P3 (ε ^ 2)) :=
  contDiff_const.mul (((contDiff_norm_sq ℝ).add contDiff_const).rpow_const_of_ne
    fun x => by positivity)

lemma reg_space (φ : EuclideanSpace ℝ (Fin 3) → ℝ) (hφ : ContDiff ℝ ∞ φ)
    (hc : HasCompactSupport φ) (ε : ℝ) (hε : 0 < ε) :
    ∫ x, P3 (ε ^ 2) x * (-(Δ φ x)) =
      ∫ y, 3 * (4 * π)⁻¹ * (1 + ‖y‖ ^ 2) ^ (-5/2 : ℝ) * φ (ε • y) := by
  have hg := green volume (P3 (ε ^ 2)) φ (P3_contDiff ε hε) hφ hc
  simp only [mul_neg, integral_neg]
  rw [hg]
  have h1 : ∀ x, Δ (P3 (ε ^ 2)) x * φ x =
      -(3 * (4 * π)⁻¹ * ε ^ 2 * (‖x‖ ^ 2 + ε ^ 2) ^ (-5/2 : ℝ) * φ x) := by
    intro x
    rw [laplacian_P3 _ x (by positivity)]
    ring
  simp only [h1, integral_neg, neg_neg]
  have hcov := Measure.integral_comp_smul (volume : Measure (EuclideanSpace ℝ (Fin 3)))
    (fun x => 3 * (4 * π)⁻¹ * ε ^ 2 * (‖x‖ ^ 2 + ε ^ 2) ^ (-5/2 : ℝ) * φ x) ε
  simp only [finrank_euclideanSpace_fin, smul_eq_mul] at hcov
  rw [abs_of_pos (by positivity)] at hcov
  have e : ∫ x, 3 * (4 * π)⁻¹ * ε ^ 2 * (‖x‖ ^ 2 + ε ^ 2) ^ (-5/2 : ℝ) * φ x =
      ε ^ 3 * ∫ y, 3 * (4 * π)⁻¹ * ε ^ 2 * (‖ε • y‖ ^ 2 + ε ^ 2) ^ (-5/2 : ℝ) * φ (ε • y) := by
    rw [hcov]
    field_simp
  rw [e, ← integral_const_mul]
  refine integral_congr_ae (Eventually.of_forall fun y => ?_)
  simp only
  rw [norm_smul, Real.norm_of_nonneg hε.le]
  have h2 : (ε * ‖y‖) ^ 2 + ε ^ 2 = ε ^ 2 * (1 + ‖y‖ ^ 2) := by ring
  rw [h2, Real.mul_rpow (by positivity) (by positivity)]
  have h3 : (ε ^ 2) ^ (-5/2 : ℝ) = (ε ^ 5)⁻¹ := by
    rw [← Real.rpow_natCast ε 2, ← Real.rpow_mul hε.le, ← Real.rpow_natCast ε 5,
      ← Real.rpow_neg hε.le]
    norm_num
  rw [h3]
  field_simp

lemma limit_space_lhs (φ : EuclideanSpace ℝ (Fin 3) → ℝ) (hφ : ContDiff ℝ ∞ φ)
    (hc : HasCompactSupport φ) :
    Tendsto (fun ε : ℝ => ∫ x, P3 (ε ^ 2) x * (-(Δ φ x))) (𝓝[>] 0)
      (𝓝 (∫ x, fundSol3 x * (-(Δ φ x)))) := by
  obtain ⟨hΔc, hΔs⟩ := laplacian_test hφ hc
  have hne : ∀ᵐ x ∂(volume : Measure (EuclideanSpace ℝ (Fin 3))), x ∈ ({0}ᶜ : Set _) :=
    compl_mem_ae_iff.2 (measure_singleton 0)
  refine tendsto_integral_filter_of_dominated_convergence
    (fun x => |fundSol3 x * Δ φ x|) ?_ ?_ ?_ ?_
  · filter_upwards [self_mem_nhdsWithin] with ε hε
    exact ((P3_contDiff ε hε).continuous.mul hΔc.neg).aestronglyMeasurable
  · filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
    filter_upwards [hne] with x (hx : x ≠ 0)
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_neg]
    refine mul_le_mul_of_nonneg_right ?_ (abs_nonneg _)
    have hx2 : 0 < ‖x‖ ^ 2 := by simpa [sq_pos_iff] using hx
    rw [fundSol3_eq, abs_of_nonneg (by unfold P3; positivity),
      abs_of_nonneg (by unfold P3; positivity)]
    unfold P3
    refine mul_le_mul_of_nonneg_left ?_ (by positivity)
    exact Real.rpow_le_rpow_of_nonpos (by simpa using hx2) (by simp; positivity) (by norm_num)
  · exact (integrable_mul_of_ball fundSol3 _ fundSol3_integrableOn hΔc hΔs).abs
  · filter_upwards [hne] with x (hx : x ≠ 0)
    refine Tendsto.mul ?_ tendsto_const_nhds
    have hx2 : 0 < ‖x‖ ^ 2 := by simpa [sq_pos_iff] using hx
    have hcont : ContinuousAt (fun ε : ℝ => (4 * π)⁻¹ * (‖x‖ ^ 2 + ε ^ 2) ^ (-1/2 : ℝ)) 0 :=
      continuousAt_const.mul ((continuousAt_const.add (continuous_pow 2).continuousAt).rpow_const
        (Or.inl (by simp; positivity)))
    have := hcont.tendsto.mono_left (nhdsWithin_le_nhds (s := Ioi 0))
    rw [fundSol3_eq]
    simpa [P3] using this

lemma point_source_identity_space_aux (φ : EuclideanSpace ℝ (Fin 3) → ℝ)
    (hφ : ContDiff ℝ ∞ φ) (hc : HasCompactSupport φ) :
    ∫ x, fundSol3 x * (-(Δ φ x)) = φ 0 := by
  have h2 : Tendsto (fun ε : ℝ => ∫ x, P3 (ε ^ 2) x * (-(Δ φ x))) (𝓝[>] 0) (𝓝 (φ 0)) := by
    refine (limit_space φ hφ hc).congr' ?_
    filter_upwards [self_mem_nhdsWithin] with ε hε
    exact (reg_space φ hφ hc ε hε).symm
  exact tendsto_nhds_unique (limit_space_lhs φ hφ hc) h2

lemma L2_contDiff (ε : ℝ) (hε : 0 < ε) : ContDiff ℝ ∞ (L2 (ε ^ 2)) :=
  contDiff_const.mul (((contDiff_norm_sq ℝ).add contDiff_const).log fun x => by positivity)

lemma reg_plane (φ : EuclideanSpace ℝ (Fin 2) → ℝ) (hφ : ContDiff ℝ ∞ φ)
    (hc : HasCompactSupport φ) (ε : ℝ) (hε : 0 < ε) :
    ∫ x, L2 (ε ^ 2) x * (-(Δ φ x)) = ∫ y, π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹ * φ (ε • y) := by
  have hg := green volume (L2 (ε ^ 2)) φ (L2_contDiff ε hε) hφ hc
  simp only [mul_neg, integral_neg]
  rw [hg]
  have h1 : ∀ x, Δ (L2 (ε ^ 2)) x * φ x = -(ε ^ 2 / (π * (‖x‖ ^ 2 + ε ^ 2) ^ 2) * φ x) := by
    intro x
    rw [laplacian_L2 _ x (by positivity)]
    ring
  simp only [h1, integral_neg, neg_neg]
  have hcov := Measure.integral_comp_smul (volume : Measure (EuclideanSpace ℝ (Fin 2)))
    (fun x => ε ^ 2 / (π * (‖x‖ ^ 2 + ε ^ 2) ^ 2) * φ x) ε
  simp only [finrank_euclideanSpace_fin, smul_eq_mul] at hcov
  rw [abs_of_pos (by positivity)] at hcov
  have e : ∫ x, ε ^ 2 / (π * (‖x‖ ^ 2 + ε ^ 2) ^ 2) * φ x =
      ε ^ 2 * ∫ y, ε ^ 2 / (π * (‖ε • y‖ ^ 2 + ε ^ 2) ^ 2) * φ (ε • y) := by
    rw [hcov]
    field_simp
  rw [e, ← integral_const_mul]
  refine integral_congr_ae (Eventually.of_forall fun y => ?_)
  simp only
  rw [norm_smul, Real.norm_of_nonneg hε.le]
  have := Real.pi_pos
  field_simp
  ring

lemma limit_plane (φ : EuclideanSpace ℝ (Fin 2) → ℝ) (hφ : ContDiff ℝ ∞ φ)
    (hc : HasCompactSupport φ) :
    Tendsto (fun ε : ℝ => ∫ y, π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹ * φ (ε • y))
      (𝓝[>] 0) (𝓝 (φ 0)) := by
  obtain ⟨C, hC⟩ := hφ.continuous.bounded_above_of_compact_support hc
  have hK : Integrable (fun y : EuclideanSpace ℝ (Fin 2) => π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹) := by
    have := integrable_rpow_neg_one_add_norm_sq (E := EuclideanSpace ℝ (Fin 2))
      (μ := volume) (r := 4) (by simp; norm_num)
    refine (this.const_mul π⁻¹).congr (Eventually.of_forall fun y => ?_)
    simp only
    rw [show (-(4:ℝ) / 2) = -((2:ℕ):ℝ) by norm_num, Real.rpow_neg (by positivity),
      Real.rpow_natCast]
  have hlim := tendsto_integral_filter_of_dominated_convergence
    (l := 𝓝[>] (0:ℝ)) (μ := volume)
    (F := fun ε y => π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹ * φ (ε • y))
    (f := fun y => π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹ * φ 0)
    (fun y => π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹ * C)
    (Eventually.of_forall fun ε => (hK.aestronglyMeasurable.mul
      (hφ.continuous.comp (continuous_const_smul ε)).aestronglyMeasurable :))
    (Eventually.of_forall fun ε => Eventually.of_forall fun y => by
      rw [norm_mul]
      have h0 : 0 ≤ π⁻¹ * ((1 + ‖y‖ ^ 2) ^ 2)⁻¹ := by positivity
      rw [Real.norm_of_nonneg h0]
      exact mul_le_mul_of_nonneg_left (hC _) h0)
    (hK.mul_const C)
    (Eventually.of_forall fun y => by
      refine tendsto_const_nhds.mul ?_
      have : Tendsto (fun ε : ℝ => ε • y) (𝓝[>] 0) (𝓝 ((0:ℝ) • y)) :=
        ((continuous_id.smul continuous_const).tendsto 0).mono_left nhdsWithin_le_nhds
      rw [zero_smul] at this
      exact (hφ.continuous.tendsto 0).comp this)
  rwa [integral_mul_const, integral_K2, one_mul] at hlim

lemma log_bound (s e : ℝ) (hs : 0 < s) (he0 : 0 ≤ e) (he1 : e ≤ 1) :
    |Real.log (s + e)| ≤ |Real.log s| + Real.log (s + 1) := by
  rcases le_or_gt 1 (s + e) with h | h
  · rw [abs_of_nonneg (Real.log_nonneg h)]
    have := Real.log_le_log (by linarith) (by linarith : s + e ≤ s + 1)
    have := abs_nonneg (Real.log s)
    linarith
  · rw [abs_of_neg (Real.log_neg (by linarith) h)]
    have h1 : Real.log s ≤ Real.log (s + e) := Real.log_le_log hs (by linarith)
    have h2 : Real.log s < 0 := Real.log_neg hs (by linarith)
    rw [abs_of_neg h2]
    have := Real.log_nonneg (by linarith : (1:ℝ) ≤ s + 1)
    linarith

lemma limit_plane_lhs (φ : EuclideanSpace ℝ (Fin 2) → ℝ) (hφ : ContDiff ℝ ∞ φ)
    (hc : HasCompactSupport φ) :
    Tendsto (fun ε : ℝ => ∫ x, L2 (ε ^ 2) x * (-(Δ φ x))) (𝓝[>] 0)
      (𝓝 (∫ x, fundSol2 x * (-(Δ φ x)))) := by
  obtain ⟨hΔc, hΔs⟩ := laplacian_test hφ hc
  have hne : ∀ᵐ x ∂(volume : Measure (EuclideanSpace ℝ (Fin 2))), x ∈ ({0}ᶜ : Set _) :=
    compl_mem_ae_iff.2 (measure_singleton 0)
  have hlogc : Continuous (fun x : EuclideanSpace ℝ (Fin 2) => Real.log (‖x‖ ^ 2 + 1)) :=
    ((continuous_norm.pow 2).add continuous_const).log fun x =>
      (by positivity : (0:ℝ) < ‖x‖ ^ 2 + 1).ne'
  refine tendsto_integral_filter_of_dominated_convergence
    (fun x => |fundSol2 x * Δ φ x| + (4 * π)⁻¹ * Real.log (‖x‖ ^ 2 + 1) * ‖Δ φ x‖)
    ?_ ?_ ?_ ?_
  · filter_upwards [self_mem_nhdsWithin] with ε hε
    exact ((L2_contDiff ε hε).continuous.mul hΔc.neg).aestronglyMeasurable
  · filter_upwards [Ioo_mem_nhdsGT (zero_lt_one' ℝ)] with ε hε
    filter_upwards [hne] with x (hx : x ≠ 0)
    have hx2 : 0 < ‖x‖ ^ 2 := by simpa [sq_pos_iff] using hx
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_neg, Real.norm_eq_abs, fundSol2_eq]
    have hb := log_bound (‖x‖ ^ 2) (ε ^ 2) hx2 (by positivity)
      (by nlinarith [hε.1, hε.2])
    have hpi : 0 < (4 * π)⁻¹ := by have := Real.pi_pos; positivity
    simp only [L2, abs_mul, abs_neg, abs_of_pos hpi, add_zero]
    have := mul_le_mul_of_nonneg_right (mul_le_mul_of_nonneg_left hb hpi.le) (abs_nonneg (Δ φ x))
    linarith
  · have h2 : Integrable (fun x => (4 * π)⁻¹ * Real.log (‖x‖ ^ 2 + 1) * ‖Δ φ x‖) :=
      ((continuous_const.mul hlogc).mul hΔc.norm).integrable_of_hasCompactSupport
        hΔs.norm.mul_left
    exact (integrable_mul_of_ball fundSol2 _ fundSol2_integrableOn hΔc hΔs).abs.add h2
  · filter_upwards [hne] with x (hx : x ≠ 0)
    refine Tendsto.mul ?_ tendsto_const_nhds
    have hx2 : 0 < ‖x‖ ^ 2 := by simpa [sq_pos_iff] using hx
    have hcont : ContinuousAt (fun ε : ℝ => -(4 * π)⁻¹ * Real.log (‖x‖ ^ 2 + ε ^ 2)) 0 :=
      continuousAt_const.mul ((continuousAt_const.add (continuous_pow 2).continuousAt).log
        (by simp; positivity))
    have := hcont.tendsto.mono_left (nhdsWithin_le_nhds (s := Ioi 0))
    rw [fundSol2_eq]
    simpa [L2] using this

lemma point_source_identity_plane_aux (φ : EuclideanSpace ℝ (Fin 2) → ℝ)
    (hφ : ContDiff ℝ ∞ φ) (hc : HasCompactSupport φ) :
    ∫ x, fundSol2 x * (-(Δ φ x)) = φ 0 := by
  have h2 : Tendsto (fun ε : ℝ => ∫ x, L2 (ε ^ 2) x * (-(Δ φ x))) (𝓝[>] 0) (𝓝 (φ 0)) := by
    refine (limit_plane φ hφ hc).congr' ?_
    filter_upwards [self_mem_nhdsWithin] with ε hε
    exact (reg_plane φ hφ hc ε hε).symm
  exact tendsto_nhds_unique (limit_plane_lhs φ hφ hc) h2

end FundSolHelpers

#print axioms laplacian_radial
#print axioms P3_hasDerivAt1
#print axioms P3_hasDerivAt2
#print axioms laplacian_P3
#print axioms L2_hasDerivAt1
#print axioms L2_hasDerivAt2
#print axioms laplacian_L2
#print axioms fundSol3_eq
#print axioms fundSol2_eq
#print axioms fundamental_solution_harmonic_off_source_aux
#print axioms contDiff_fderiv_apply'
#print axioms fderiv_fderiv_apply'
#print axioms green_one
#print axioms green
#print axioms laplacian_test
#print axioms integrable_mul_of_ball
#print axioms fundSol3_integrableOn
#print axioms fundSol2_integrableOn
#print axioms I1
#print axioms I2
#print axioms integral_K3
#print axioms integral_K2
#print axioms limit_space
#print axioms P3_contDiff
#print axioms reg_space
#print axioms limit_space_lhs
#print axioms point_source_identity_space_aux
#print axioms L2_contDiff
#print axioms reg_plane
#print axioms limit_plane
#print axioms log_bound
#print axioms limit_plane_lhs
#print axioms point_source_identity_plane_aux

/-- The point-source identity in space: for every test function `φ` on three-dimensional space,
weighing minus the Laplacian of `φ` by the potential `Φ = 1/(4π|x|)` and adding up over all of
space gives back the bump's value at the source, `∫ Φ (−Δφ) dx = φ(0)`. That is, `−ΔΦ = δ`. -/
theorem point_source_identity_space (φ : EuclideanSpace ℝ (Fin 3) → ℝ)
    (hφ : ContDiff ℝ ∞ φ) (hc : HasCompactSupport φ) :
    ∫ x, fundSol3 x * (-(Δ φ x)) = φ 0 := by
  exact point_source_identity_space_aux φ hφ hc

/-- The point-source identity in the plane: for every test function `φ` on the plane, the
logarithmic potential `Φ = −ln|x|/(2π)` (the field across a long charged wire) satisfies
`∫ Φ (−Δφ) dx = φ(0)`, so `−ΔΦ = δ` in two dimensions too. -/
theorem point_source_identity_plane (φ : EuclideanSpace ℝ (Fin 2) → ℝ)
    (hφ : ContDiff ℝ ∞ φ) (hc : HasCompactSupport φ) :
    ∫ x, fundSol2 x * (-(Δ φ x)) = φ 0 := by
  exact point_source_identity_plane_aux φ hφ hc

/-- Away from the source both potentials solve Laplace's equation point by point: `1/(4π|x|)` is
harmonic on space minus the origin, and `−ln|x|/(2π)` is harmonic on the plane minus the
origin. -/
theorem fundamental_solution_harmonic_off_source :
    HarmonicOnNhd fundSol3 {x | x ≠ 0} ∧ HarmonicOnNhd fundSol2 {x | x ≠ 0} := by
  exact fundamental_solution_harmonic_off_source_aux

/-! The card's exact whole-number values: by Step 1, `Δ(r^p) = p (p + d − 2) r^(p − 2)`. At
`r = 1 m` the field shape `1/r²` taken as a potential in space (`p = −2`, `d = 3`) has Laplacian
exactly `2`, and `1/r` taken as the wire's potential in the plane (`p = −1`, `d = 2`) has Laplacian
exactly `1`, not `0`. The right powers, `p = 2 − d`, give `0`. -/
example : (-2 : ℤ) * (-2 + 3 - 2) = 2 := by norm_num
example : (-1 : ℤ) * (-1 + 2 - 2) = 1 := by norm_num
example : ∀ d : ℤ, (2 - d) * ((2 - d) + d - 2) = 0 := by intro d; ring

#print axioms point_source_identity_space
#print axioms point_source_identity_plane
#print axioms fundamental_solution_harmonic_off_source
