-- Helmholtz: on a bounded region with a fixed edge, every eigenvalue of −Δ is real and positive and shapes with different eigenvalues are perpendicular; on an a by b rectangle the shapes sin(mπx/a) sin(nπy/b) are eigenfunctions with λ = π²(m²/a² + n²/b²) that also meet the plate's simply supported edge and Δ²φ = λ²φ; and the dome x(a − x) y(b − y) has Rayleigh quotient 10/a² + 10/b², above the lowest eigenvalue.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Complex.ReImTopology
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Analysis.Calculus.LineDeriv.IntegrationByParts
import Mathlib.Analysis.SpecialFunctions.SmoothTransition
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.MeasureTheory.Measure.OpenPos

open Set Real Laplacian MeasureTheory Complex

/-! The plane is `ℂ`: the point `(x, y)` is `x + y i`, so `z.re = x` and `z.im = y`. The region
`Ω` is a bounded open set and its edge `∂Ω` is `frontier Ω`. "Twice continuously differentiable up
to the edge" is `ContDiff ℝ 1 φ` (shape and slopes continuous everywhere) with `ContDiffOn ℝ 2 φ Ω`
(second derivatives continuous inside). `Δ` is Mathlib's Laplacian, `Δφ = φ_xx + φ_yy`. A shape may
be complex-valued, as in the card's detailed proof; an eigenvalue is then a complex number `lam`
and the card proves it is real. -/

/-- The plate's face, the open rectangle `0 < x < a`, `0 < y < b`. -/
def plateFace (a b : ℝ) : Set ℂ := Ioo 0 a ×ℂ Ioo 0 b

/-- The rectangle's mode `φ_mn(x, y) = sin(mπx/a) · sin(nπy/b)`. -/
noncomputable def rectMode (a b : ℝ) (m n : ℕ) : ℂ → ℝ :=
  fun z => Real.sin (m * π * z.re / a) * Real.sin (n * π * z.im / b)

/-- The rectangle's eigenvalue `λ_mn = π² (m²/a² + n²/b²)`. -/
noncomputable def rectEigenvalue (a b : ℝ) (m n : ℕ) : ℝ :=
  π ^ 2 * ((m : ℝ) ^ 2 / a ^ 2 + (n : ℝ) ^ 2 / b ^ 2)

/-- The Rayleigh quotient of a trial shape `w(x, y)` on the `a` by `b` rectangle:
`R(w) = ∫∫ (w_x² + w_y²) dx dy / ∫∫ w² dx dy`. -/
noncomputable def rectRayleigh (a b : ℝ) (w : ℝ → ℝ → ℝ) : ℝ :=
  (∫ x in (0 : ℝ)..a, ∫ y in (0 : ℝ)..b,
      ((deriv (fun s => w s y) x) ^ 2 + (deriv (fun t => w x t) y) ^ 2)) /
    (∫ x in (0 : ℝ)..a, ∫ y in (0 : ℝ)..b, (w x y) ^ 2)

/-! Helper lemmas for the proofs below. -/

theorem helm_laplacian_eq_fderiv {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
    (f : ℂ → F) (z : ℂ) :
    Δ f z = fderiv ℝ (fderiv ℝ f) z 1 1 + fderiv ℝ (fderiv ℝ f) z Complex.I Complex.I := by
  simp [InnerProductSpace.laplacian_eq_iteratedFDeriv_complexPlane, iteratedFDeriv_two_apply]
theorem helm_continuous_mul_of_tsupport {Ω : Set ℂ} (hΩ : IsOpen Ω) {F w : ℂ → ℂ}
    (hF : ContinuousOn F Ω) (hw : Continuous w) (hwΩ : tsupport w ⊆ Ω) :
    Continuous (fun z => F z * w z) := by
  rw [continuous_iff_continuousAt]
  intro z
  by_cases hz : z ∈ Ω
  · exact (hF.continuousAt (hΩ.mem_nhds hz)).mul hw.continuousAt
  · have h0 : w =ᶠ[nhds z] fun _ => 0 := notMem_tsupport_iff_eventuallyEq.mp (fun h => hz (hwΩ h))
    have : (fun z => F z * w z) =ᶠ[nhds z] fun _ => 0 := h0.mono fun y hy => by simp [hy]
    exact continuousAt_const.congr this.symm

theorem helm_ibp {Ω : Set ℂ} (hΩ : IsOpen Ω) {φ w : ℂ → ℂ} (hφ : ContDiff ℝ 1 φ)
    (hφ2 : ContDiffOn ℝ 2 φ Ω) (hw : ContDiff ℝ 1 w) (hwc : HasCompactSupport w)
    (hwΩ : tsupport w ⊆ Ω) :
    ∫ z, Δ φ z * w z = -∫ z, (fderiv ℝ φ z 1 * fderiv ℝ w z 1 +
      fderiv ℝ φ z Complex.I * fderiv ℝ w z Complex.I) := by
  have hD2 : ∀ x ∈ Ω, HasFDerivAt (fderiv ℝ φ) (fderiv ℝ (fderiv ℝ φ) x) x := fun x hx =>
    (((hφ2.contDiffAt (hΩ.mem_nhds hx)).fderiv_right (m := 1) (by norm_num)).differentiableAt
      (by norm_num)).hasFDerivAt
  have hD2c : ContinuousOn (fderiv ℝ (fderiv ℝ φ)) Ω :=
    (hφ2.fderiv_of_isOpen hΩ (m := 1) (by norm_num)).continuousOn_fderiv_of_isOpen hΩ le_rfl
  have hφ1c : Continuous (fderiv ℝ φ) := hφ.continuous_fderiv one_ne_zero
  have hw1c : Continuous (fderiv ℝ w) := hw.continuous_fderiv one_ne_zero
  have hwcont : Continuous w := hw.continuous
  have hwd : Differentiable ℝ w := hw.differentiable one_ne_zero
  have hD2int : ∀ v, Integrable (fun z => fderiv ℝ (fderiv ℝ φ) z v v * w z) := by
    intro v
    have hc : ContinuousOn (fun z => fderiv ℝ (fderiv ℝ φ) z v v) Ω :=
      ((hD2c.clm_apply continuousOn_const).clm_apply continuousOn_const)
    exact (helm_continuous_mul_of_tsupport hΩ hc hwcont hwΩ).integrable_of_hasCompactSupport
      hwc.mul_left
  have step : ∀ v, ∫ z, fderiv ℝ φ z v * fderiv ℝ w z v =
      -∫ z, fderiv ℝ (fderiv ℝ φ) z v v * w z := by
    intro v
    have h1 : Integrable (fun z => fderiv ℝ φ z v * fderiv ℝ w z v) :=
      ((hφ1c.clm_apply continuous_const).mul (hw1c.clm_apply continuous_const)).integrable_of_hasCompactSupport
        (hwc.fderiv_apply (𝕜 := ℝ) v).mul_left
    have h2 : Integrable (fun z => fderiv ℝ φ z v * w z) :=
      ((hφ1c.clm_apply continuous_const).mul hwcont).integrable_of_hasCompactSupport hwc.mul_left
    have := integral_bilinear_hasFDerivAt_right_eq_neg_left_of_integrable (μ := volume)
      (B := ContinuousLinearMap.mul ℝ ℂ) (f := fun z => fderiv ℝ φ z v)
      (f' := fun z => (ContinuousLinearMap.apply ℝ ℂ v).comp (fderiv ℝ (fderiv ℝ φ) z))
      (g := w) (g' := fderiv ℝ w) (v := v) (by simpa using hD2int v) (by simpa using h1)
      (by simpa using h2)
      (fun x hx => (ContinuousLinearMap.apply ℝ ℂ v).hasFDerivAt.comp x (hD2 x (hwΩ hx)))
      (fun x _ => (hwd x).hasFDerivAt)
    simpa using this
  have hsplit : ∀ z, Δ φ z * w z = fderiv ℝ (fderiv ℝ φ) z 1 1 * w z +
      fderiv ℝ (fderiv ℝ φ) z Complex.I Complex.I * w z := by
    intro z; rw [helm_laplacian_eq_fderiv]; ring
  simp_rw [hsplit]
  rw [integral_add (hD2int 1) (hD2int Complex.I)]
  have i1 : Integrable (fun z => fderiv ℝ φ z 1 * fderiv ℝ w z 1) :=
    ((hφ1c.clm_apply continuous_const).mul (hw1c.clm_apply continuous_const)).integrable_of_hasCompactSupport
      (hwc.fderiv_apply (𝕜 := ℝ) 1).mul_left
  have iI : Integrable (fun z => fderiv ℝ φ z Complex.I * fderiv ℝ w z Complex.I) :=
    ((hφ1c.clm_apply continuous_const).mul (hw1c.clm_apply continuous_const)).integrable_of_hasCompactSupport
      (hwc.fderiv_apply (𝕜 := ℝ) Complex.I).mul_left
  rw [integral_add i1 iI, step 1, step Complex.I]
  ring
theorem helm_st_deriv_eq_zero {x : ℝ} (hx : 1 < x ∨ x < 0) :
    deriv Real.smoothTransition x = 0 := by
  rcases hx with hx | hx
  · have : Real.smoothTransition =ᶠ[nhds x] fun _ => (1 : ℝ) :=
      Filter.eventually_of_mem (Ioi_mem_nhds hx) fun y hy => Real.smoothTransition.one_of_one_le (le_of_lt hy)
    rw [this.deriv_eq]; simp
  · have : Real.smoothTransition =ᶠ[nhds x] fun _ => (0 : ℝ) :=
      Filter.eventually_of_mem (Iio_mem_nhds hx) fun y hy => Real.smoothTransition.zero_of_nonpos (le_of_lt hy)
    rw [this.deriv_eq]; simp

theorem helm_st_deriv_bound : ∃ S : ℝ, ∀ x, |deriv Real.smoothTransition x| ≤ S := by
  have hc : Continuous (deriv Real.smoothTransition) :=
    (Real.smoothTransition.contDiff (n := 1)).continuous_deriv le_rfl
  obtain ⟨S, hS⟩ := (isCompact_Icc (a := (0 : ℝ)) (b := 1)).exists_bound_of_continuousOn hc.continuousOn
  refine ⟨S, fun x => ?_⟩
  by_cases hx : x ∈ Icc (0 : ℝ) 1
  · simpa using hS x hx
  · have h0 : (0 : ℝ) ≤ S := le_trans (norm_nonneg _) (hS 0 ⟨le_rfl, zero_le_one⟩)
    simp only [mem_Icc, not_and_or, not_le] at hx
    rw [helm_st_deriv_eq_zero (by tauto)]
    simpa using h0

/-- The cut-off test function `conj ψ · s(k q − 1)`, kept to the region. -/
theorem helm_cutoff {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {ψ : ℂ → ℂ}
    {q : ℂ → ℝ} (hψ : ContDiff ℝ 1 ψ) (hq : ContDiff ℝ 1 q) (hq0 : ∀ z ∈ frontier Ω, q z = 0)
    {k : ℝ} :
    ContDiff ℝ 1 (Ω.indicator fun z => (starRingEnd ℂ) (ψ z) *
        ((Real.smoothTransition (k * q z - 1) : ℝ) : ℂ)) ∧
    HasCompactSupport (Ω.indicator fun z => (starRingEnd ℂ) (ψ z) *
        ((Real.smoothTransition (k * q z - 1) : ℝ) : ℂ)) ∧
    tsupport (Ω.indicator fun z => (starRingEnd ℂ) (ψ z) *
        ((Real.smoothTransition (k * q z - 1) : ℝ) : ℂ)) ⊆ Ω ∧
    ∀ z ∈ Ω, ∀ v : ℂ, fderiv ℝ (Ω.indicator fun z => (starRingEnd ℂ) (ψ z) *
        ((Real.smoothTransition (k * q z - 1) : ℝ) : ℂ)) z v =
      (starRingEnd ℂ) (fderiv ℝ ψ z v) * ((Real.smoothTransition (k * q z - 1) : ℝ) : ℂ) +
      (starRingEnd ℂ) (ψ z) *
        ((deriv Real.smoothTransition (k * q z - 1) * (k * fderiv ℝ q z v) : ℝ) : ℂ) := by
  set g : ℂ → ℂ := fun z => (starRingEnd ℂ) (ψ z) *
    ((Real.smoothTransition (k * q z - 1) : ℝ) : ℂ) with hgdef
  set K : Set ℂ := closure Ω ∩ {z | 1 ≤ k * q z} with hKdef
  have hqc : Continuous q := hq.continuous
  have hKcl : IsClosed K := isClosed_closure.inter (isClosed_le continuous_const
    (continuous_const.mul hqc))
  have hKc : IsCompact K := hbdd.isCompact_closure.of_isClosed_subset hKcl inter_subset_left
  have hKΩ : K ⊆ Ω := by
    rintro z ⟨hz1, hz2⟩
    by_contra hz
    have : z ∈ frontier Ω := by
      rw [frontier, hΩ.interior_eq]; exact ⟨hz1, hz⟩
    have := hq0 z this
    simp only [mem_ofPred_eq, this, mul_zero] at hz2
    linarith
  have hsupp : tsupport (Ω.indicator g) ⊆ K := by
    apply closure_minimal _ hKcl
    intro z hz
    rw [Function.mem_support] at hz
    have hzΩ : z ∈ Ω := by
      by_contra h; exact hz (indicator_of_notMem h _)
    rw [indicator_of_mem hzΩ] at hz
    refine ⟨subset_closure hzΩ, ?_⟩
    by_contra h
    simp only [mem_ofPred_eq, not_le] at h
    apply hz
    simp only [g, Real.smoothTransition.zero_of_nonpos (by linarith : k * q z - 1 ≤ 0),
      Complex.ofReal_zero, mul_zero]
  have hg : ContDiff ℝ 1 g :=
    (Complex.conjCLE.contDiff.comp hψ).mul (Complex.ofRealCLM.contDiff.comp
      (Real.smoothTransition.contDiff.comp ((contDiff_const.mul hq).sub contDiff_const)))
  have hloc : ∀ z ∈ Ω, Ω.indicator g =ᶠ[nhds z] g := fun z hz =>
    Filter.eventually_of_mem (hΩ.mem_nhds hz) fun y hy => indicator_of_mem hy _
  have hzero : ∀ z ∉ Ω, Ω.indicator g =ᶠ[nhds z] fun _ => 0 := fun z hz =>
    notMem_tsupport_iff_eventuallyEq.mp (fun h => hz (hKΩ (hsupp h)))
  refine ⟨?_, hKc.of_isClosed_subset (isClosed_tsupport _) hsupp, hsupp.trans hKΩ, ?_⟩
  · rw [contDiff_iff_contDiffAt]
    intro z
    by_cases hz : z ∈ Ω
    · exact hg.contDiffAt.congr_of_eventuallyEq (hloc z hz)
    · exact contDiffAt_const.congr_of_eventuallyEq (hzero z hz)
  · intro z hz v
    rw [(hloc z hz).fderiv_eq]
    have hc : HasFDerivAt (fun z => (starRingEnd ℂ) (ψ z))
        ((Complex.conjCLE : ℂ →L[ℝ] ℂ).comp (fderiv ℝ ψ z)) z :=
      (Complex.conjCLE : ℂ →L[ℝ] ℂ).hasFDerivAt.comp z
        ((hψ.differentiable one_ne_zero z).hasFDerivAt)
    have ht : HasFDerivAt (fun z => Real.smoothTransition (k * q z - 1))
        (deriv Real.smoothTransition (k * q z - 1) • (k • fderiv ℝ q z)) z :=
      ((Real.smoothTransition.contDiff (n := 1)).differentiable one_ne_zero _).hasDerivAt.comp_hasFDerivAt z
        ((((hq.differentiable one_ne_zero z).hasFDerivAt).const_mul k).sub_const 1)
    have ht' : HasFDerivAt (fun z => ((Real.smoothTransition (k * q z - 1) : ℝ) : ℂ))
        (Complex.ofRealCLM.comp (deriv Real.smoothTransition (k * q z - 1) • (k • fderiv ℝ q z))) z :=
      Complex.ofRealCLM.hasFDerivAt.comp z ht
    have hgd : HasFDerivAt g _ z := hc.mul ht'
    rw [hgd.fderiv]
    simp
    ring

theorem helm_green {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {φ ψ : ℂ → ℂ}
    {q : ℂ → ℝ} (hφ : ContDiff ℝ 1 φ) (hφ2 : ContDiffOn ℝ 2 φ Ω) {C : ℝ}
    (hΔ : ∀ z ∈ Ω, ‖Δ φ z‖ ≤ C) (hψ : ContDiff ℝ 1 ψ) (hq : ContDiff ℝ 1 q)
    (hq0 : ∀ z ∈ frontier Ω, q z = 0) (hψq : ∀ z ∈ Ω, ‖ψ z‖ ^ 2 ≤ q z) {L : ℝ}
    (hL : ∀ z ∈ Ω, ‖ψ z‖ * ‖fderiv ℝ q z‖ ≤ L * q z) :
    ∫ z in Ω, Δ φ z * (starRingEnd ℂ) (ψ z) =
      -∫ z in Ω, {z | 0 < q z}.indicator (fun z => fderiv ℝ φ z 1 * (starRingEnd ℂ) (fderiv ℝ ψ z 1) +
        fderiv ℝ φ z Complex.I * (starRingEnd ℂ) (fderiv ℝ ψ z Complex.I)) z := by
  have hΩm : MeasurableSet Ω := hΩ.measurableSet
  have hcl : IsCompact (closure Ω) := hbdd.isCompact_closure
  have hfin : volume Ω < ⊤ := hbdd.measure_lt_top
  have hψc : Continuous ψ := hψ.continuous
  have hqc : Continuous q := hq.continuous
  have hφ1c : Continuous (fderiv ℝ φ) := hφ.continuous_fderiv one_ne_zero
  have hψ1c : Continuous (fderiv ℝ ψ) := hψ.continuous_fderiv one_ne_zero
  have hq1c : Continuous (fderiv ℝ q) := hq.continuous_fderiv one_ne_zero
  have hsc : Continuous Real.smoothTransition := Real.smoothTransition.continuous
  have hsdc : Continuous (deriv Real.smoothTransition) :=
    (Real.smoothTransition.contDiff (n := 1)).continuous_deriv le_rfl
  have hD2c : ContinuousOn (fderiv ℝ (fderiv ℝ φ)) Ω :=
    (hφ2.fderiv_of_isOpen hΩ (m := 1) (by norm_num)).continuousOn_fderiv_of_isOpen hΩ le_rfl
  have hΔc : ContinuousOn (Δ φ) Ω := by
    have : Δ φ = fun z => fderiv ℝ (fderiv ℝ φ) z 1 1 +
        fderiv ℝ (fderiv ℝ φ) z Complex.I Complex.I := funext (helm_laplacian_eq_fderiv φ)
    rw [this]
    exact ((hD2c.clm_apply continuousOn_const).clm_apply continuousOn_const).add
      ((hD2c.clm_apply continuousOn_const).clm_apply continuousOn_const)
  obtain ⟨Mψ, hMψ⟩ := hcl.exists_bound_of_continuousOn hψc.continuousOn
  obtain ⟨Mφ1, hMφ1⟩ := hcl.exists_bound_of_continuousOn hφ1c.continuousOn
  obtain ⟨Mψ1, hMψ1⟩ := hcl.exists_bound_of_continuousOn hψ1c.continuousOn
  obtain ⟨S, hS⟩ := helm_st_deriv_bound
  have hS0 : 0 ≤ S := le_trans (abs_nonneg _) (hS 0)
  -- the cut-off integrands
  set k : ℕ → ℝ := fun n => (n : ℝ) + 1 with hkdef
  have hk : ∀ n, 0 < k n := fun n => by positivity
  set P : ℕ → ℂ → ℂ → ℂ := fun n z v =>
    (starRingEnd ℂ) (fderiv ℝ ψ z v) * ((Real.smoothTransition (k n * q z - 1) : ℝ) : ℂ) +
      (starRingEnd ℂ) (ψ z) *
        ((deriv Real.smoothTransition (k n * q z - 1) * (k n * fderiv ℝ q z v) : ℝ) : ℂ) with hPdef
  set A : ℕ → ℂ → ℂ := fun n z =>
    Δ φ z * ((starRingEnd ℂ) (ψ z) * ((Real.smoothTransition (k n * q z - 1) : ℝ) : ℂ)) with hAdef
  set B : ℕ → ℂ → ℂ := fun n z =>
    fderiv ℝ φ z 1 * P n z 1 + fderiv ℝ φ z Complex.I * P n z Complex.I with hBdef
  set T : ℂ → ℂ := fun z => {z | 0 < q z}.indicator (fun z => fderiv ℝ φ z 1 *
    (starRingEnd ℂ) (fderiv ℝ ψ z 1) + fderiv ℝ φ z Complex.I *
      (starRingEnd ℂ) (fderiv ℝ ψ z Complex.I)) z with hTdef
  -- the identity for each cut-off
  have hid : ∀ n, ∫ z in Ω, A n z = -∫ z in Ω, B n z := by
    intro n
    obtain ⟨h1, h2, h3, h4⟩ := helm_cutoff hΩ hbdd hψ hq hq0 (k := k n)
    have key := helm_ibp hΩ hφ hφ2 h1 h2 h3
    set w := (Ω.indicator fun z => (starRingEnd ℂ) (ψ z) *
        ((Real.smoothTransition (k n * q z - 1) : ℝ) : ℂ)) with hwdef
    have hfd0 : ∀ z ∉ Ω, fderiv ℝ w z = 0 := fun z hz =>
      Function.notMem_support.mp (fun h => hz (h3 (support_fderiv_subset ℝ h)))
    have e1 : ∫ z, Δ φ z * w z = ∫ z in Ω, A n z := by
      rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Ω)
        (fun z hz => by simp only [w, indicator_of_notMem hz, mul_zero])]
      exact setIntegral_congr_fun hΩm (fun z hz => by simp only [w, indicator_of_mem hz, A])
    have e2 : ∫ z, (fderiv ℝ φ z 1 * fderiv ℝ w z 1 +
        fderiv ℝ φ z Complex.I * fderiv ℝ w z Complex.I) = ∫ z in Ω, B n z := by
      rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Ω)
        (fun z hz => by simp only [hfd0 z hz, ContinuousLinearMap.zero_apply, mul_zero, add_zero])]
      exact setIntegral_congr_fun hΩm (fun z hz => by simp only [h4 z hz, B, P])
    rw [← e1, ← e2]
    exact key
  -- bounds
  have hP : ∀ n, ∀ z ∈ Ω, ∀ v : ℂ, ‖v‖ = 1 → ‖P n z v‖ ≤ Mψ1 + 2 * S * |L| := by
    intro n z hz v hv
    have hq0' : 0 ≤ q z := le_trans (by positivity) (hψq z hz)
    have t1 : ‖(starRingEnd ℂ) (fderiv ℝ ψ z v) *
        ((Real.smoothTransition (k n * q z - 1) : ℝ) : ℂ)‖ ≤ Mψ1 := by
      rw [norm_mul, Complex.norm_conj, Complex.norm_real, Real.norm_eq_abs,
        abs_of_nonneg (Real.smoothTransition.nonneg _)]
      calc ‖fderiv ℝ ψ z v‖ * _ ≤ ‖fderiv ℝ ψ z v‖ * 1 := by
            gcongr; exact Real.smoothTransition.le_one _
        _ ≤ ‖fderiv ℝ ψ z‖ * ‖v‖ := by rw [mul_one]; exact (fderiv ℝ ψ z).le_opNorm v
        _ ≤ Mψ1 := by rw [hv, mul_one]; exact hMψ1 z (subset_closure hz)
    have t2 : ‖(starRingEnd ℂ) (ψ z) * ((deriv Real.smoothTransition (k n * q z - 1) *
        (k n * fderiv ℝ q z v) : ℝ) : ℂ)‖ ≤ 2 * S * |L| := by
      rw [norm_mul, Complex.norm_conj, Complex.norm_real, Real.norm_eq_abs, abs_mul, abs_mul,
        abs_of_pos (hk n)]
      by_cases hd : deriv Real.smoothTransition (k n * q z - 1) = 0
      · rw [hd]; simp; positivity
      · have hle : k n * q z ≤ 2 := by
          by_contra h; replace h := not_le.mp h
          exact hd (helm_st_deriv_eq_zero (Or.inl (by linarith)))
        have hqv : |fderiv ℝ q z v| ≤ ‖fderiv ℝ q z‖ := by
          have := (fderiv ℝ q z).le_opNorm v
          rw [hv, mul_one, Real.norm_eq_abs] at this; exact this
        have hk0 := hk n
        calc ‖ψ z‖ * (|deriv Real.smoothTransition (k n * q z - 1)| * (k n * |fderiv ℝ q z v|))
            ≤ ‖ψ z‖ * (S * (k n * ‖fderiv ℝ q z‖)) := by gcongr; exact hS _
          _ = S * k n * (‖ψ z‖ * ‖fderiv ℝ q z‖) := by ring
          _ ≤ S * k n * (|L| * q z) := by
            exact mul_le_mul_of_nonneg_left
              ((hL z hz).trans (mul_le_mul_of_nonneg_right (le_abs_self L) hq0')) (by positivity)
          _ = S * |L| * (k n * q z) := by ring
          _ ≤ S * |L| * 2 := by gcongr
          _ = 2 * S * |L| := by ring
    exact (norm_add_le _ _).trans (by linarith)
  have hφv : ∀ z ∈ Ω, ∀ v : ℂ, ‖v‖ = 1 → ‖fderiv ℝ φ z v‖ ≤ Mφ1 := by
    intro z hz v hv
    have := (fderiv ℝ φ z).le_opNorm v
    rw [hv, mul_one] at this
    exact this.trans (hMφ1 z (subset_closure hz))
  have hBb : ∀ n, ∀ z ∈ Ω, ‖B n z‖ ≤ 2 * (Mφ1 * (Mψ1 + 2 * S * |L|)) := by
    intro n z hz
    have h1 : ‖(1 : ℂ)‖ = 1 := by simp
    have hI : ‖Complex.I‖ = 1 := by simp
    have a1 := hφv z hz 1 h1
    have aI := hφv z hz Complex.I hI
    have b1 := hP n z hz 1 h1
    have bI := hP n z hz Complex.I hI
    have hb0 : 0 ≤ Mψ1 + 2 * S * |L| := le_trans (norm_nonneg _) b1
    have hM0 : 0 ≤ Mφ1 := le_trans (norm_nonneg _) a1
    calc ‖B n z‖ ≤ ‖fderiv ℝ φ z 1‖ * ‖P n z 1‖ + ‖fderiv ℝ φ z Complex.I‖ * ‖P n z Complex.I‖ := by
          simp only [B]; exact (norm_add_le _ _).trans (by rw [norm_mul, norm_mul])
      _ ≤ Mφ1 * (Mψ1 + 2 * S * |L|) + Mφ1 * (Mψ1 + 2 * S * |L|) := by
          gcongr
      _ = _ := by ring
  have hAb : ∀ n, ∀ z ∈ Ω, ‖A n z‖ ≤ C * Mψ := by
    intro n z hz
    simp only [A]
    rw [norm_mul, norm_mul, Complex.norm_conj, Complex.norm_real, Real.norm_eq_abs,
      abs_of_nonneg (Real.smoothTransition.nonneg _)]
    have := Real.smoothTransition.le_one (k n * q z - 1)
    have h0 := Real.smoothTransition.nonneg (k n * q z - 1)
    have hC : 0 ≤ C := le_trans (norm_nonneg _) (hΔ z hz)
    calc ‖Δ φ z‖ * (‖ψ z‖ * Real.smoothTransition (k n * q z - 1)) ≤ C * (Mψ * 1) := by
          have hm := hMψ z (subset_closure hz)
          have hm0 : 0 ≤ Mψ := le_trans (norm_nonneg _) hm
          exact mul_le_mul (hΔ z hz) (mul_le_mul hm this h0 hm0) (by positivity) hC
      _ = C * Mψ := by ring
  -- eventual behaviour at each point
  have hev : ∀ z ∈ Ω, ∀ᶠ n in Filter.atTop,
      A n z = Δ φ z * (starRingEnd ℂ) (ψ z) ∧ B n z = T z := by
    intro z hz
    by_cases hqz : 0 < q z
    · obtain ⟨N, hN⟩ := exists_nat_gt (2 / q z)
      refine Filter.eventually_atTop.2 ⟨N, fun n hn => ?_⟩
      have hkq : 2 < k n * q z := by
        have : (N : ℝ) ≤ n := by exact_mod_cast hn
        have h2 : 2 < N * q z := by rwa [div_lt_iff₀ hqz] at hN
        simp only [k]; nlinarith
      have hs1 : Real.smoothTransition (k n * q z - 1) = 1 :=
        Real.smoothTransition.one_of_one_le (by linarith)
      have hd0 : deriv Real.smoothTransition (k n * q z - 1) = 0 :=
        helm_st_deriv_eq_zero (Or.inl (by linarith))
      refine ⟨by simp [A, hs1], by simp [B, P, T, hs1, hd0, hqz]⟩
    · have hψ0 : ψ z = 0 := by
        have h1 := hψq z hz
        have h2 : ‖ψ z‖ ≤ 0 := by nlinarith [norm_nonneg (ψ z)]
        exact norm_eq_zero.mp (le_antisymm h2 (norm_nonneg _))
      refine Filter.Eventually.of_forall fun n => ?_
      have hs0 : Real.smoothTransition (k n * q z - 1) = 0 :=
        Real.smoothTransition.zero_of_nonpos (by nlinarith [hk n])
      exact ⟨by simp [A, hψ0], by simp [B, P, T, hs0, hψ0, hqz]⟩
  -- dominated convergence
  have hlimA : Filter.Tendsto (fun n => ∫ z in Ω, A n z) Filter.atTop
      (nhds (∫ z in Ω, Δ φ z * (starRingEnd ℂ) (ψ z))) := by
    refine tendsto_integral_of_dominated_convergence (fun _ => C * Mψ) (fun n => ?_)
      (integrableOn_const hfin.ne) (fun n => ae_restrict_of_forall_mem hΩm (hAb n))
      (ae_restrict_of_forall_mem hΩm fun z hz => ?_)
    · have hc : Continuous fun z => (starRingEnd ℂ) (ψ z) *
          ((Real.smoothTransition (k n * q z - 1) : ℝ) : ℂ) :=
        (Complex.continuous_conj.comp hψc).mul (Complex.continuous_ofReal.comp
          (hsc.comp ((continuous_const.mul hqc).sub continuous_const)))
      exact (hΔc.mul hc.continuousOn).aestronglyMeasurable hΩm
    · exact tendsto_const_nhds.congr' ((hev z hz).mono fun n hn => hn.1.symm)
  have hlimB : Filter.Tendsto (fun n => ∫ z in Ω, B n z) Filter.atTop (nhds (∫ z in Ω, T z)) := by
    refine tendsto_integral_of_dominated_convergence (fun _ => 2 * (Mφ1 * (Mψ1 + 2 * S * |L|)))
      (fun n => ?_) (integrableOn_const hfin.ne) (fun n => ae_restrict_of_forall_mem hΩm (hBb n))
      (ae_restrict_of_forall_mem hΩm fun z hz => ?_)
    · have hPc : ∀ v, Continuous fun z => P n z v := fun v =>
        ((Complex.continuous_conj.comp (hψ1c.clm_apply continuous_const)).mul
          (Complex.continuous_ofReal.comp (hsc.comp ((continuous_const.mul hqc).sub continuous_const)))).add
        ((Complex.continuous_conj.comp hψc).mul (Complex.continuous_ofReal.comp
          ((hsdc.comp ((continuous_const.mul hqc).sub continuous_const)).mul
            (continuous_const.mul (hq1c.clm_apply continuous_const)))))
      exact (((hφ1c.clm_apply continuous_const).mul (hPc 1)).add
        ((hφ1c.clm_apply continuous_const).mul (hPc Complex.I))).aestronglyMeasurable
    · exact tendsto_const_nhds.congr' ((hev z hz).mono fun n hn => hn.2.symm)
  have hneg := hlimB.neg
  rw [show (fun n => -∫ z in Ω, B n z) = fun n => ∫ z in Ω, A n z from
    funext fun n => (hid n).symm] at hneg
  exact tendsto_nhds_unique hlimA hneg

theorem helm_normsq_hasFDerivAt {f : ℂ → ℂ} (hf : ContDiff ℝ 1 f) (z : ℂ) :
    ∃ D : ℂ →L[ℝ] ℝ, HasFDerivAt (fun z => ‖f z‖ ^ 2) D z ∧
      ‖D‖ ≤ 2 * ‖f z‖ * ‖fderiv ℝ f z‖ := by
  refine ⟨_, ((hf.differentiable one_ne_zero z).hasFDerivAt).norm_sq, ?_⟩
  rw [two_smul]
  have h : ‖(innerSL ℝ (f z)).comp (fderiv ℝ f z)‖ ≤ ‖f z‖ * ‖fderiv ℝ f z‖ := by
    have := ContinuousLinearMap.opNorm_comp_le (innerSL ℝ (f z)) (fderiv ℝ f z)
    rwa [innerSL_apply_norm] at this
  calc _ ≤ ‖(innerSL ℝ (f z)).comp (fderiv ℝ f z)‖ + ‖(innerSL ℝ (f z)).comp (fderiv ℝ f z)‖ :=
        norm_add_le _ _
    _ ≤ _ := by linarith

theorem helm_eigenvalue_real_pos {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω)
    {φ : ℂ → ℂ} {lam : ℂ} (hφ : ContDiff ℝ 1 φ) (hφ2 : ContDiffOn ℝ 2 φ Ω)
    (hφ0 : ∀ z ∈ frontier Ω, φ z = 0) (hφeq : ∀ z ∈ Ω, -Δ φ z = lam * φ z)
    (hφne : ∃ z ∈ Ω, φ z ≠ 0) :
    lam.im = 0 ∧ 0 < lam.re := by
  have hΩm : MeasurableSet Ω := hΩ.measurableSet
  have hcl : IsCompact (closure Ω) := hbdd.isCompact_closure
  have hφc : Continuous φ := hφ.continuous
  have hφ1c : Continuous (fderiv ℝ φ) := hφ.continuous_fderiv one_ne_zero
  obtain ⟨Mφ, hMφ⟩ := hcl.exists_bound_of_continuousOn hφc.continuousOn
  obtain ⟨Mφ1, hMφ1⟩ := hcl.exists_bound_of_continuousOn hφ1c.continuousOn
  set q : ℂ → ℝ := fun z => ‖φ z‖ ^ 2 with hqdef
  have hq : ContDiff ℝ 1 q := (contDiff_norm_sq ℝ).comp hφ
  have hqc : Continuous q := hq.continuous
  have hΔeq : ∀ z ∈ Ω, Δ φ z = -(lam * φ z) := fun z hz => by rw [← hφeq z hz, neg_neg]
  have G := helm_green hΩ hbdd hφ hφ2 (C := ‖lam‖ * Mφ) (fun z hz => by
      rw [hΔeq z hz, norm_neg, norm_mul]
      exact mul_le_mul_of_nonneg_left (hMφ z (subset_closure hz)) (norm_nonneg _))
    hφ hq (fun z hz => by simp [q, hφ0 z hz]) (fun z _ => le_rfl) (L := 2 * Mφ1) (fun z hz => by
      obtain ⟨D, hD, hDn⟩ := helm_normsq_hasFDerivAt hφ z
      rw [hD.fderiv]
      have h1 := hMφ1 z (subset_closure hz)
      calc ‖φ z‖ * ‖D‖ ≤ ‖φ z‖ * (2 * ‖φ z‖ * ‖fderiv ℝ φ z‖) :=
            mul_le_mul_of_nonneg_left hDn (norm_nonneg _)
        _ ≤ ‖φ z‖ * (2 * ‖φ z‖ * Mφ1) := by gcongr
        _ = 2 * Mφ1 * q z := by simp only [q]; ring)
  set g : ℂ → ℝ := fun z => ‖fderiv ℝ φ z 1‖ ^ 2 + ‖fderiv ℝ φ z Complex.I‖ ^ 2 with hgdef
  have hgc : Continuous g := by
    simp only [g]
    exact ((hφ1c.clm_apply continuous_const).norm.pow 2).add
      ((hφ1c.clm_apply continuous_const).norm.pow 2)
  set e : ℂ → ℝ := {z | 0 < q z}.indicator g with hedef
  set N : ℝ := ∫ z in Ω, q z with hNdef
  set E : ℝ := ∫ z in Ω, e z with hEdef
  have hLHS : ∫ z in Ω, Δ φ z * (starRingEnd ℂ) (φ z) = -(lam * (N : ℂ)) := by
    rw [setIntegral_congr_fun hΩm (g := fun z => -(lam * ((q z : ℝ) : ℂ))) (fun z hz => by
      simp only [hΔeq z hz, q]
      rw [neg_mul, mul_assoc, Complex.mul_conj']
      push_cast; ring)]
    rw [integral_neg, integral_const_mul, integral_complex_ofReal]
  have hRHS : ∫ z in Ω, {z | 0 < q z}.indicator (fun z => fderiv ℝ φ z 1 *
      (starRingEnd ℂ) (fderiv ℝ φ z 1) + fderiv ℝ φ z Complex.I *
        (starRingEnd ℂ) (fderiv ℝ φ z Complex.I)) z = (E : ℂ) := by
    rw [hEdef, ← integral_complex_ofReal]
    refine setIntegral_congr_fun hΩm (fun z _ => ?_)
    by_cases hz : z ∈ {z | 0 < q z}
    · simp only [e, indicator_of_mem hz, g, Complex.mul_conj']
      push_cast; ring
    · simp only [e, indicator_of_notMem hz, Complex.ofReal_zero]
  rw [hLHS, hRHS, neg_inj] at G
  -- N > 0
  obtain ⟨z0, hz0, hφz0⟩ := hφne
  have hN : 0 < N := by
    have hqint : IntegrableOn q Ω :=
      (hqc.continuousOn.integrableOn_compact hcl).mono_set subset_closure
    rw [hNdef, setIntegral_pos_iff_support_of_nonneg_ae
      (Filter.Eventually.of_forall (fun z => by simp only [q, Pi.zero_apply]; positivity)) hqint]
    exact (hqc.isOpen_support.inter hΩ).measure_pos volume
      ⟨z0, by simp [q, hφz0], hz0⟩
  -- E > 0
  have hE : 0 < E := by
    have heint : IntegrableOn e Ω :=
      ((hgc.continuousOn.integrableOn_compact hcl).mono_set subset_closure).indicator
        (measurableSet_lt measurable_const hqc.measurable)
    have he0 : ∀ z, 0 ≤ e z := fun z => indicator_nonneg (fun z _ => by simp only [g]; positivity) z
    rcases (setIntegral_nonneg hΩm (fun z _ => he0 z)).lt_or_eq with h | h
    · exact h
    exfalso
    have hae := (setIntegral_eq_zero_iff_of_nonneg_ae (Filter.Eventually.of_forall he0) heint).mp
      h.symm
    set U : Set ℂ := Ω ∩ {z | 0 < q z} with hUdef
    have hUo : IsOpen U := hΩ.inter (isOpen_lt continuous_const hqc)
    have hae' : e =ᵐ[volume.restrict U] 0 :=
      ae_restrict_of_ae_restrict_of_subset inter_subset_left hae
    have hEq := Measure.eqOn_open_of_ae_eq hae' hUo
      (hgc.continuousOn.congr (fun z hz => indicator_of_mem hz.2 _)) continuousOn_const
    have hD0 : ∀ z ∈ U, fderiv ℝ φ z = 0 := by
      intro z hz
      have h0 := hEq hz
      simp only [e, indicator_of_mem hz.2, Pi.zero_apply, g] at h0
      have ha := sq_nonneg ‖fderiv ℝ φ z 1‖
      have hb := sq_nonneg ‖fderiv ℝ φ z Complex.I‖
      have h1 : fderiv ℝ φ z 1 = 0 :=
        norm_eq_zero.mp (pow_eq_zero_iff two_ne_zero |>.mp (by linarith))
      have hI : fderiv ℝ φ z Complex.I = 0 :=
        norm_eq_zero.mp (pow_eq_zero_iff two_ne_zero |>.mp (by linarith))
      ext1 h
      have hh : h = h.re • (1 : ℂ) + h.im • Complex.I := by apply Complex.ext <;> simp
      rw [hh, map_add, map_smul, map_smul, h1, hI]
      simp
    have hz0U : z0 ∈ U := ⟨hz0, by simp [q, hφz0]⟩
    set Cc := connectedComponentIn U z0 with hCcdef
    have hCo : IsOpen Cc := hUo.connectedComponentIn
    have hCp : IsPreconnected Cc := isPreconnected_connectedComponentIn
    have hCU : Cc ⊆ U := connectedComponentIn_subset _ _
    have hz0C : z0 ∈ Cc := mem_connectedComponentIn hz0U
    have hconst : EqOn φ (fun _ => φ z0) Cc := fun x hx =>
      hCo.is_const_of_fderiv_eq_zero hCp (hφ.differentiable one_ne_zero).differentiableOn
        (fun y hy => hD0 y (hCU hy)) hx hz0C
    have hfront : (frontier Cc).Nonempty := nonempty_frontier_iff.2
      ⟨⟨z0, hz0C⟩, fun h => NormedSpace.unbounded_univ ℝ ℂ
        (h ▸ hbdd.subset (hCU.trans inter_subset_left))⟩
    obtain ⟨p, hp⟩ := hfront
    have hpcl : p ∈ closure Cc := frontier_subset_closure hp
    have hpC : p ∉ Cc := by rw [hCo.frontier_eq] at hp; exact hp.2
    have hφp : φ p = φ z0 := (hconst.closure hφc continuous_const) hpcl
    have hpΩcl : p ∈ closure Ω := closure_mono (hCU.trans inter_subset_left) hpcl
    by_cases hpΩ : p ∈ Ω
    · have hpU : p ∈ U := ⟨hpΩ, by simp [q, hφp, hφz0]⟩
      obtain ⟨r, hr, hball⟩ := Metric.isOpen_iff.mp hUo p hpU
      obtain ⟨b, hbC, hb⟩ := Metric.mem_closure_iff.mp hpcl r hr
      have hbB : b ∈ Metric.ball p r := by rw [Metric.mem_ball, dist_comm]; exact hb
      have hsub := (convex_ball p r).isPreconnected.subset_connectedComponentIn hbB hball
      rw [← connectedComponentIn_eq hbC] at hsub
      exact hpC (hsub (Metric.mem_ball_self hr))
    · have : p ∈ frontier Ω := by rw [frontier, hΩ.interior_eq]; exact ⟨hpΩcl, hpΩ⟩
      exact hφz0 (hφp ▸ hφ0 p this)
  -- conclude
  have hlam : lam = ((E / N : ℝ) : ℂ) := by
    have hN' : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
    rw [Complex.ofReal_div, ← G]; field_simp
  rw [hlam]
  exact ⟨Complex.ofReal_im _, by rw [Complex.ofReal_re]; positivity⟩

theorem helm_hasFDerivAt_prodForm {A B : ℝ → ℝ} {A' B' : ℝ} {w : ℂ}
    (hA : HasDerivAt A A' w.re) (hB : HasDerivAt B B' w.im) :
    HasFDerivAt (fun z : ℂ => A z.re * B z.im)
      ((A w.re) • (B' • Complex.imCLM) + (B w.im) • (A' • Complex.reCLM)) w := by
  have h1 : HasFDerivAt (fun z : ℂ => A z.re) (A' • Complex.reCLM) w := by
    have := hA.comp_hasFDerivAt w Complex.reCLM.hasFDerivAt
    simpa [Function.comp_def] using this
  have h2 : HasFDerivAt (fun z : ℂ => B z.im) (B' • Complex.imCLM) w := by
    have := hB.comp_hasFDerivAt w Complex.imCLM.hasFDerivAt
    simpa [Function.comp_def] using this
  exact h1.mul h2

theorem helm_fderiv_prodForm {A B : ℝ → ℝ} (hA : Differentiable ℝ A) (hB : Differentiable ℝ B) :
    fderiv ℝ (fun z : ℂ => A z.re * B z.im) = fun w =>
      (deriv A w.re * B w.im) • Complex.reCLM + (A w.re * deriv B w.im) • Complex.imCLM := by
  funext w
  rw [(helm_hasFDerivAt_prodForm (hA w.re).hasDerivAt (hB w.im).hasDerivAt).fderiv]
  ext h <;> simp <;> ring

theorem helm_laplacian_prodForm {A B : ℝ → ℝ} (hA : Differentiable ℝ A) (hB : Differentiable ℝ B)
    (hA' : Differentiable ℝ (deriv A)) (hB' : Differentiable ℝ (deriv B)) (z : ℂ) :
    Δ (fun z : ℂ => A z.re * B z.im) z =
      deriv (deriv A) z.re * B z.im + A z.re * deriv (deriv B) z.im := by
  rw [helm_laplacian_eq_fderiv, helm_fderiv_prodForm hA hB]
  have d1 := helm_hasFDerivAt_prodForm (w := z) (hA' z.re).hasDerivAt (hB z.im).hasDerivAt
  have d2 := helm_hasFDerivAt_prodForm (w := z) (hA z.re).hasDerivAt (hB' z.im).hasDerivAt
  have D : HasFDerivAt (fun w : ℂ => (deriv A w.re * B w.im) • Complex.reCLM +
      (A w.re * deriv B w.im) • Complex.imCLM) _ z :=
    (d1.smul_const Complex.reCLM).add (d2.smul_const Complex.imCLM)
  rw [D.fderiv]
  simp
  ring

theorem helm_sin_derivs (k c : ℝ) :
    Differentiable ℝ (fun x => k * Real.sin (c * x)) ∧
    deriv (fun x => k * Real.sin (c * x)) = (fun x => k * c * Real.cos (c * x)) ∧
    Differentiable ℝ (fun x => k * c * Real.cos (c * x)) ∧
    deriv (fun x => k * c * Real.cos (c * x)) = (fun x => -c ^ 2 * (k * Real.sin (c * x))) := by
  have h1 : ∀ x, HasDerivAt (fun x => k * Real.sin (c * x)) (k * c * Real.cos (c * x)) x := by
    intro x
    have := ((hasDerivAt_id x).const_mul c).sin.const_mul k
    convert this using 1 <;> simp [Function.comp_def]; ring
  have h2 : ∀ x, HasDerivAt (fun x => k * c * Real.cos (c * x)) (-c ^ 2 * (k * Real.sin (c * x))) x := by
    intro x
    have := ((hasDerivAt_id x).const_mul c).cos.const_mul (k * c)
    convert this using 1 <;> simp [Function.comp_def]; ring
  exact ⟨fun x => (h1 x).differentiableAt, funext fun x => (h1 x).deriv,
    fun x => (h2 x).differentiableAt, funext fun x => (h2 x).deriv⟩

theorem helm_laplacian_sinsin (k c d : ℝ) (z : ℂ) :
    Δ (fun z : ℂ => (k * Real.sin (c * z.re)) * Real.sin (d * z.im)) z =
      -(c ^ 2 + d ^ 2) * ((k * Real.sin (c * z.re)) * Real.sin (d * z.im)) := by
  obtain ⟨a1, a2, a3, a4⟩ := helm_sin_derivs k c
  obtain ⟨b1, b2, b3, b4⟩ := helm_sin_derivs 1 d
  have := helm_laplacian_prodForm (A := fun x => k * Real.sin (c * x))
    (B := fun x => 1 * Real.sin (d * x)) a1 b1 (a2 ▸ a3) (b2 ▸ b3) z
  rw [a2, a4, b2, b4] at this
  simp only [one_mul] at this
  rw [this]
  ring

theorem helm_integral_quartic (c0 c1 c2 c3 c4 b : ℝ) :
    ∫ y in (0 : ℝ)..b, (c0 + c1 * y + c2 * y ^ 2 + c3 * y ^ 3 + c4 * y ^ 4) =
      c0 * b + c1 * b ^ 2 / 2 + c2 * b ^ 3 / 3 + c3 * b ^ 4 / 4 + c4 * b ^ 5 / 5 := by
  have hd : ∀ y ∈ uIcc (0 : ℝ) b, HasDerivAt
      (fun y : ℝ => c0 * y + c1 * (y ^ 2 / 2) + c2 * (y ^ 3 / 3) + c3 * (y ^ 4 / 4) + c4 * (y ^ 5 / 5))
      (c0 + c1 * y + c2 * y ^ 2 + c3 * y ^ 3 + c4 * y ^ 4) y := by
    intro y _
    have h : HasDerivAt
      (fun y : ℝ => c0 * y + c1 * (y ^ 2 / 2) + c2 * (y ^ 3 / 3) + c3 * (y ^ 4 / 4) + c4 * (y ^ 5 / 5))
      (c0 * 1 + c1 * (((2 : ℕ) : ℝ) * y ^ (2 - 1) / 2) + c2 * (((3 : ℕ) : ℝ) * y ^ (3 - 1) / 3)
        + c3 * (((4 : ℕ) : ℝ) * y ^ (4 - 1) / 4) + c4 * (((5 : ℕ) : ℝ) * y ^ (5 - 1) / 5)) y :=
      (((((hasDerivAt_id' y).const_mul c0).add
      (((hasDerivAt_pow 2 y).div_const 2).const_mul c1)).add
      (((hasDerivAt_pow 3 y).div_const 3).const_mul c2)).add
      (((hasDerivAt_pow 4 y).div_const 4).const_mul c3)).add
      (((hasDerivAt_pow 5 y).div_const 5).const_mul c4)
    convert h using 1
    norm_num
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd (Continuous.intervalIntegrable (by fun_prop) _ _)]
  ring

/-- The Helmholtz problem with a fixed edge, on any bounded region. Let `Ω` be a bounded open
region. Let `φ` be a nonzero shape, twice continuously differentiable up to the edge, zero on the
edge, with `−Δφ = λφ` inside; let `ψ` be another such shape with number `μ`. Then the number `λ` is
real and positive, and if `λ ≠ μ` the two shapes are perpendicular: `∫_Ω φ · conj ψ = 0`. -/
theorem dirichlet_eigenvalues_real_positive_and_modes_orthogonal {Ω : Set ℂ} (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) {φ ψ : ℂ → ℂ} {lam mu : ℂ}
    (hφ : ContDiff ℝ 1 φ) (hφ2 : ContDiffOn ℝ 2 φ Ω) (hφ0 : ∀ z ∈ frontier Ω, φ z = 0)
    (hφeq : ∀ z ∈ Ω, -Δ φ z = lam * φ z) (hφne : ∃ z ∈ Ω, φ z ≠ 0)
    (hψ : ContDiff ℝ 1 ψ) (hψ2 : ContDiffOn ℝ 2 ψ Ω) (hψ0 : ∀ z ∈ frontier Ω, ψ z = 0)
    (hψeq : ∀ z ∈ Ω, -Δ ψ z = mu * ψ z) (hψne : ∃ z ∈ Ω, ψ z ≠ 0) :
    lam.im = 0 ∧ 0 < lam.re ∧
      (lam ≠ mu → ∫ z in Ω, φ z * (starRingEnd ℂ) (ψ z) = 0) := by
  obtain ⟨hlim, hlre⟩ := helm_eigenvalue_real_pos hΩ hbdd hφ hφ2 hφ0 hφeq hφne
  obtain ⟨hmim, -⟩ := helm_eigenvalue_real_pos hΩ hbdd hψ hψ2 hψ0 hψeq hψne
  refine ⟨hlim, hlre, fun hne => ?_⟩
  have hΩm : MeasurableSet Ω := hΩ.measurableSet
  have hcl : IsCompact (closure Ω) := hbdd.isCompact_closure
  obtain ⟨Mφ, hMφ⟩ := hcl.exists_bound_of_continuousOn hφ.continuous.continuousOn
  obtain ⟨Mψ, hMψ⟩ := hcl.exists_bound_of_continuousOn hψ.continuous.continuousOn
  obtain ⟨Mφ1, hMφ1⟩ :=
    hcl.exists_bound_of_continuousOn (hφ.continuous_fderiv one_ne_zero).continuousOn
  obtain ⟨Mψ1, hMψ1⟩ :=
    hcl.exists_bound_of_continuousOn (hψ.continuous_fderiv one_ne_zero).continuousOn
  set q : ℂ → ℝ := fun z => ‖φ z‖ ^ 2 + ‖ψ z‖ ^ 2 with hqdef
  have hq : ContDiff ℝ 1 q := ((contDiff_norm_sq ℝ).comp hφ).add ((contDiff_norm_sq ℝ).comp hψ)
  have hq0 : ∀ z ∈ frontier Ω, q z = 0 := fun z hz => by simp [q, hφ0 z hz, hψ0 z hz]
  set M : ℝ := |Mφ1| + |Mψ1| with hMdef
  have hM0 : 0 ≤ M := by positivity
  have hDq : ∀ z ∈ Ω, ‖fderiv ℝ q z‖ ≤ 2 * M * (‖φ z‖ + ‖ψ z‖) := by
    intro z hz
    obtain ⟨D1, hD1, hD1n⟩ := helm_normsq_hasFDerivAt hφ z
    obtain ⟨D2, hD2, hD2n⟩ := helm_normsq_hasFDerivAt hψ z
    have hD : HasFDerivAt q (D1 + D2) z := hD1.add hD2
    rw [hD.fderiv]
    have a' : ‖fderiv ℝ φ z‖ ≤ M := (hMφ1 z (subset_closure hz)).trans
      ((le_abs_self _).trans (le_add_of_nonneg_right (abs_nonneg _)))
    have b' : ‖fderiv ℝ ψ z‖ ≤ M := (hMψ1 z (subset_closure hz)).trans
      ((le_abs_self _).trans (le_add_of_nonneg_left (abs_nonneg _)))
    calc ‖D1 + D2‖ ≤ ‖D1‖ + ‖D2‖ := norm_add_le _ _
      _ ≤ 2 * ‖φ z‖ * ‖fderiv ℝ φ z‖ + 2 * ‖ψ z‖ * ‖fderiv ℝ ψ z‖ := add_le_add hD1n hD2n
      _ ≤ 2 * ‖φ z‖ * M + 2 * ‖ψ z‖ * M := by gcongr
      _ = _ := by ring
  have hLφ : ∀ z ∈ Ω, ‖φ z‖ * ‖fderiv ℝ q z‖ ≤ (3 * M) * q z := by
    intro z hz
    have ha := norm_nonneg (φ z)
    have hb := norm_nonneg (ψ z)
    calc ‖φ z‖ * ‖fderiv ℝ q z‖ ≤ ‖φ z‖ * (2 * M * (‖φ z‖ + ‖ψ z‖)) :=
          mul_le_mul_of_nonneg_left (hDq z hz) ha
      _ ≤ 3 * M * q z := by
          simp only [q]
          nlinarith [mul_nonneg hM0 (sq_nonneg (‖φ z‖ - ‖ψ z‖)), mul_nonneg hM0 (sq_nonneg ‖ψ z‖)]
  have hLψ : ∀ z ∈ Ω, ‖ψ z‖ * ‖fderiv ℝ q z‖ ≤ (3 * M) * q z := by
    intro z hz
    have ha := norm_nonneg (φ z)
    have hb := norm_nonneg (ψ z)
    calc ‖ψ z‖ * ‖fderiv ℝ q z‖ ≤ ‖ψ z‖ * (2 * M * (‖φ z‖ + ‖ψ z‖)) :=
          mul_le_mul_of_nonneg_left (hDq z hz) hb
      _ ≤ 3 * M * q z := by
          simp only [q]
          nlinarith [mul_nonneg hM0 (sq_nonneg (‖φ z‖ - ‖ψ z‖)), mul_nonneg hM0 (sq_nonneg ‖φ z‖)]
  have hΔφ : ∀ z ∈ Ω, Δ φ z = -(lam * φ z) := fun z hz => by rw [← hφeq z hz, neg_neg]
  have hΔψ : ∀ z ∈ Ω, Δ ψ z = -(mu * ψ z) := fun z hz => by rw [← hψeq z hz, neg_neg]
  have G1 := helm_green hΩ hbdd hφ hφ2 (C := ‖lam‖ * Mφ) (fun z hz => by
      rw [hΔφ z hz, norm_neg, norm_mul]
      exact mul_le_mul_of_nonneg_left (hMφ z (subset_closure hz)) (norm_nonneg _))
    hψ hq hq0 (fun z _ => le_add_of_nonneg_left (by positivity)) hLψ
  have G2 := helm_green hΩ hbdd hψ hψ2 (C := ‖mu‖ * Mψ) (fun z hz => by
      rw [hΔψ z hz, norm_neg, norm_mul]
      exact mul_le_mul_of_nonneg_left (hMψ z (subset_closure hz)) (norm_nonneg _))
    hφ hq hq0 (fun z _ => le_add_of_nonneg_right (by positivity)) hLφ
  have L1 : ∫ z in Ω, Δ φ z * (starRingEnd ℂ) (ψ z) =
      -(lam * ∫ z in Ω, φ z * (starRingEnd ℂ) (ψ z)) := by
    rw [setIntegral_congr_fun hΩm (g := fun z => -(lam * (φ z * (starRingEnd ℂ) (ψ z))))
      (fun z hz => by simp only [hΔφ z hz]; ring), integral_neg, integral_const_mul]
  have L2 : ∫ z in Ω, Δ ψ z * (starRingEnd ℂ) (φ z) =
      -(mu * ∫ z in Ω, ψ z * (starRingEnd ℂ) (φ z)) := by
    rw [setIntegral_congr_fun hΩm (g := fun z => -(mu * (ψ z * (starRingEnd ℂ) (φ z))))
      (fun z hz => by simp only [hΔψ z hz]; ring), integral_neg, integral_const_mul]
  have hconjI : (starRingEnd ℂ) (∫ z in Ω, ψ z * (starRingEnd ℂ) (φ z)) =
      ∫ z in Ω, φ z * (starRingEnd ℂ) (ψ z) := by
    rw [← integral_conj]; congr 1; funext z; simp only [map_mul, Complex.conj_conj]; ring
  have hconjT : (starRingEnd ℂ) (∫ z in Ω, {z | 0 < q z}.indicator (fun z => fderiv ℝ ψ z 1 *
      (starRingEnd ℂ) (fderiv ℝ φ z 1) + fderiv ℝ ψ z Complex.I *
        (starRingEnd ℂ) (fderiv ℝ φ z Complex.I)) z) =
      ∫ z in Ω, {z | 0 < q z}.indicator (fun z => fderiv ℝ φ z 1 *
      (starRingEnd ℂ) (fderiv ℝ ψ z 1) + fderiv ℝ φ z Complex.I *
        (starRingEnd ℂ) (fderiv ℝ ψ z Complex.I)) z := by
    rw [← integral_conj]; congr 1; funext z
    by_cases hz : z ∈ {z | 0 < q z}
    · simp only [indicator_of_mem hz, map_add, map_mul, Complex.conj_conj]; ring
    · simp only [indicator_of_notMem hz, map_zero]
  have hmu : (starRingEnd ℂ) mu = mu := Complex.conj_eq_iff_im.mpr hmim
  rw [L1] at G1
  rw [L2] at G2
  have G2' := congrArg (starRingEnd ℂ) G2
  simp only [map_neg, map_mul, hmu, hconjI, hconjT] at G2'
  have key : (lam - mu) * ∫ z in Ω, φ z * (starRingEnd ℂ) (ψ z) = 0 := by
    linear_combination (-1 : ℂ) * G1 + G2'
  exact (mul_eq_zero.mp key).resolve_left (sub_ne_zero.mpr hne)

/-- The rectangle's list. On an `a` by `b` rectangle, for whole numbers `m, n ≥ 1`, the shape
`φ_mn = sin(mπx/a) sin(nπy/b)` is not zero, is zero on all four edges, and solves
`−Δφ_mn = λ_mn φ_mn` with `λ_mn = π² (m²/a² + n²/b²) > 0`. It also meets the plate's simply
supported edge, `Δφ_mn = 0` there, and the plate operator gives `Δ²φ_mn = λ_mn² φ_mn`, which is
why a plate's notes go as `λ`, not `√λ`. -/
theorem rectangle_modes_are_dirichlet_eigenfunctions {a b : ℝ} (ha : 0 < a) (hb : 0 < b)
    {m n : ℕ} (hm : 1 ≤ m) (hn : 1 ≤ n) :
    0 < rectEigenvalue a b m n ∧
    (∀ z : ℂ, -Δ (rectMode a b m n) z = rectEigenvalue a b m n * rectMode a b m n z) ∧
    (∀ z ∈ frontier (plateFace a b), rectMode a b m n z = 0) ∧
    (∃ z ∈ plateFace a b, rectMode a b m n z ≠ 0) ∧
    (∀ z ∈ frontier (plateFace a b), Δ (rectMode a b m n) z = 0) ∧
    (∀ z : ℂ, Δ (Δ (rectMode a b m n)) z = rectEigenvalue a b m n ^ 2 * rectMode a b m n z) := by
  set c : ℝ := m * π / a
  set d : ℝ := n * π / b
  have hmode : rectMode a b m n = fun z : ℂ => (1 * Real.sin (c * z.re)) * Real.sin (d * z.im) := by
    funext z; simp only [rectMode, c, d, one_mul]; congr 2 <;> ring
  have hlam : rectEigenvalue a b m n = c ^ 2 + d ^ 2 := by
    simp only [rectEigenvalue, c, d]; field_simp
  have hlap : ∀ z, Δ (rectMode a b m n) z = -rectEigenvalue a b m n * rectMode a b m n z := by
    intro z; rw [hmode, helm_laplacian_sinsin, hlam]
  have hlapfun : Δ (rectMode a b m n) =
      fun z : ℂ => ((-(c ^ 2 + d ^ 2)) * Real.sin (c * z.re)) * Real.sin (d * z.im) := by
    funext z; rw [hlap, hmode, hlam]; ring
  have hpos : 0 < rectEigenvalue a b m n := by
    have hm' : (1 : ℝ) ≤ m := by exact_mod_cast hm
    unfold rectEigenvalue
    have := Real.pi_pos
    positivity
  have hsa : Real.sin (m * π * a / a) = 0 := by
    rw [show (m : ℝ) * π * a / a = (m : ℤ) * π by field_simp; simp, Real.sin_int_mul_pi]
  have hsb : Real.sin (n * π * b / b) = 0 := by
    rw [show (n : ℝ) * π * b / b = (n : ℤ) * π by field_simp; simp, Real.sin_int_mul_pi]
  have hzero : ∀ z ∈ frontier (plateFace a b), rectMode a b m n z = 0 := by
    intro z hz
    rw [plateFace, Complex.frontier_reProdIm, closure_Ioo ha.ne, closure_Ioo hb.ne,
      frontier_Ioo ha, frontier_Ioo hb] at hz
    simp only [rectMode]
    rcases hz with ⟨_, hz⟩ | ⟨hz, _⟩
    · simp only [mem_insert_iff, mem_singleton_iff, mem_preimage] at hz
      rcases hz with h | h <;> simp [h, hsb]
    · simp only [mem_insert_iff, mem_singleton_iff, mem_preimage] at hz
      rcases hz with h | h <;> simp [h, hsa]
  refine ⟨hpos, fun z => by rw [hlap]; ring, hzero, ?_, fun z hz => by rw [hlap, hzero z hz]; ring, ?_⟩
  · have hm' : (1 : ℝ) ≤ m := by exact_mod_cast hm
    have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
    refine ⟨⟨a / (2 * m), b / (2 * n)⟩, ?_, ?_⟩
    · simp only [plateFace, mem_reProdIm]
      simp
      refine ⟨⟨by positivity, ?_⟩, ⟨by positivity, ?_⟩⟩
      · rw [div_lt_iff₀ (by positivity)]; nlinarith
      · rw [div_lt_iff₀ (by positivity)]; nlinarith
    · simp only [rectMode]
      simp
      rw [show (m : ℝ) * π * (a / (2 * m)) / a = π / 2 by field_simp,
        show (n : ℝ) * π * (b / (2 * n)) / b = π / 2 by field_simp]
      simp
  · intro z
    rw [hlapfun, helm_laplacian_sinsin, hmode, hlam]
    ring

/-- The dome's upper bound. On an `a` by `b` rectangle, the trial shape `w = x(a − x) y(b − y)`,
which is zero on the edge, has Rayleigh quotient exactly `10/a² + 10/b²`, and this lies above the
lowest eigenvalue `λ_11 = π² (1/a² + 1/b²)`. -/
theorem dome_rayleigh_quotient_above_lowest_eigenvalue {a b : ℝ} (ha : 0 < a) (hb : 0 < b) :
    rectRayleigh a b (fun x y => x * (a - x) * (y * (b - y))) = 10 / a ^ 2 + 10 / b ^ 2 ∧
    rectEigenvalue a b 1 1 < 10 / a ^ 2 + 10 / b ^ 2 := by
  have hdx : ∀ x y : ℝ, deriv (fun s => s * (a - s) * (y * (b - y))) x = (a - 2 * x) * (y * (b - y)) := by
    intro x y
    have h : HasDerivAt (fun s => s * (a - s) * (y * (b - y))) ((1 * (a - x) + x * -1) * (y * (b - y))) x :=
      (((hasDerivAt_id' x).mul ((hasDerivAt_id' x).const_sub a)).mul_const (y * (b - y)))
    rw [h.deriv]; ring
  have hdy : ∀ x y : ℝ, deriv (fun t => x * (a - x) * (t * (b - t))) y = x * (a - x) * (b - 2 * y) := by
    intro x y
    have h : HasDerivAt (fun t => x * (a - x) * (t * (b - t))) (x * (a - x) * (1 * (b - y) + y * -1)) y :=
      (((hasDerivAt_id' y).mul ((hasDerivAt_id' y).const_sub b)).const_mul (x * (a - x)))
    rw [h.deriv]; ring
  have hin1 : ∀ x : ℝ, ∫ y in (0 : ℝ)..b, (((a - 2 * x) * (y * (b - y))) ^ 2 +
      (x * (a - x) * (b - 2 * y)) ^ 2) = (x * (a - x)) ^ 2 * b ^ 3 / 3 + (a - 2 * x) ^ 2 * b ^ 5 / 30 := by
    intro x
    calc _ = ∫ y in (0 : ℝ)..b, ((x * (a - x)) ^ 2 * b ^ 2 + (-4 * b * (x * (a - x)) ^ 2) * y
          + ((a - 2 * x) ^ 2 * b ^ 2 + 4 * (x * (a - x)) ^ 2) * y ^ 2 + (-2 * b * (a - 2 * x) ^ 2) * y ^ 3
          + (a - 2 * x) ^ 2 * y ^ 4) := by
          congr 1; funext y; ring
      _ = _ := by rw [helm_integral_quartic]; ring
  have hin2 : ∀ x : ℝ, ∫ y in (0 : ℝ)..b, (x * (a - x) * (y * (b - y))) ^ 2 =
      (x * (a - x)) ^ 2 * b ^ 5 / 30 := by
    intro x
    calc _ = ∫ y in (0 : ℝ)..b, (0 + 0 * y + (x * (a - x)) ^ 2 * b ^ 2 * y ^ 2
          + (-2 * b * (x * (a - x)) ^ 2) * y ^ 3 + (x * (a - x)) ^ 2 * y ^ 4) := by
          congr 1; funext y; ring
      _ = _ := by rw [helm_integral_quartic]; ring
  have hout1 : ∫ x in (0 : ℝ)..a, ((x * (a - x)) ^ 2 * b ^ 3 / 3 + (a - 2 * x) ^ 2 * b ^ 5 / 30) =
      a ^ 5 * b ^ 3 / 90 + a ^ 3 * b ^ 5 / 90 := by
    calc _ = ∫ x in (0 : ℝ)..a, (a ^ 2 * b ^ 5 / 30 + (-4 * a * b ^ 5 / 30) * x
          + (a ^ 2 * b ^ 3 / 3 + 4 * b ^ 5 / 30) * x ^ 2 + (-2 * a * b ^ 3 / 3) * x ^ 3
          + (b ^ 3 / 3) * x ^ 4) := by
          congr 1; funext x; ring
      _ = _ := by rw [helm_integral_quartic]; ring
  have hout2 : ∫ x in (0 : ℝ)..a, (x * (a - x)) ^ 2 * b ^ 5 / 30 = a ^ 5 * b ^ 5 / 900 := by
    calc _ = ∫ x in (0 : ℝ)..a, (0 + 0 * x + (a ^ 2 * b ^ 5 / 30) * x ^ 2
          + (-2 * a * b ^ 5 / 30) * x ^ 3 + (b ^ 5 / 30) * x ^ 4) := by
          congr 1; funext x; ring
      _ = _ := by rw [helm_integral_quartic]; ring
  refine ⟨?_, ?_⟩
  · simp only [rectRayleigh, hdx, hdy, hin1, hin2, hout1, hout2]
    field_simp
    ring
  · unfold rectEigenvalue
    have h1 := Real.pi_lt_d2
    have h0 := Real.pi_pos
    have hpi : π ^ 2 < 10 := by nlinarith
    have : 0 < 1 / a ^ 2 + 1 / b ^ 2 := by positivity
    calc π ^ 2 * (((1 : ℕ) : ℝ) ^ 2 / a ^ 2 + ((1 : ℕ) : ℝ) ^ 2 / b ^ 2)
        = π ^ 2 * (1 / a ^ 2 + 1 / b ^ 2) := by simp
      _ < 10 * (1 / a ^ 2 + 1 / b ^ 2) := by gcongr
      _ = _ := by ring

/-! The card's worked numbers, for the 0.6 m by 0.4 m plate (a = 3/5, b = 2/5). -/

-- order of the modes: λ_mn = π² (4m² + 9n²)/1.44, so order by 4m² + 9n²; for m, n up to 8
-- the modes below (3,1)'s value 45 are exactly (1,1), (2,1), (1,2)
example : ((Finset.Icc 1 8 ×ˢ Finset.Icc 1 8).filter (fun p : ℕ × ℕ => 4 * p.1 ^ 2 + 9 * p.2 ^ 2 < 45))
    = {(1, 1), (2, 1), (1, 2)} := by decide

-- (1,1) 13, (2,1) 25, (1,2) 40, (3,1) 45
example : (4 * 1 ^ 2 + 9 * 1 ^ 2, 4 * 2 ^ 2 + 9 * 1 ^ 2, 4 * 1 ^ 2 + 9 * 2 ^ 2, 4 * 3 ^ 2 + 9 * 1 ^ 2)
    = (13, 25, 40, 45) := by norm_num

-- plate ratios λ_21/λ_11 = 25/13 (1.923) and λ_12/λ_11 = 40/13 (3.077)
example : rectEigenvalue (3 / 5) (2 / 5) 2 1 / rectEigenvalue (3 / 5) (2 / 5) 1 1 = 25 / 13 := by
  have := Real.pi_pos
  unfold rectEigenvalue
  field_simp
  norm_num

example : rectEigenvalue (3 / 5) (2 / 5) 1 2 / rectEigenvalue (3 / 5) (2 / 5) 1 1 = 40 / 13 := by
  have := Real.pi_pos
  unfold rectEigenvalue
  field_simp
  norm_num

-- the dome's quotient 10/a² + 10/b² = 1625/18 1/m² (90.278)
example : (10 : ℚ) / (3 / 5) ^ 2 + 10 / (2 / 5) ^ 2 = 1625 / 18 := by norm_num

-- a mode's size ∫φ² = ab/4 = 3/50 m² (0.06 m²)
example : ((3 : ℚ) / 5) * (2 / 5) / 4 = 3 / 50 := by norm_num

-- the unit dome 16 x(a − x) y(b − y)/(a² b²) peaks at 1 in the centre
example : (16 : ℚ) * (3 / 10 * (3 / 5 - 3 / 10)) * (1 / 5 * (2 / 5 - 1 / 5)) / ((3 / 5) ^ 2 * (2 / 5) ^ 2)
    = 1 := by norm_num

#print axioms dirichlet_eigenvalues_real_positive_and_modes_orthogonal
#print axioms rectangle_modes_are_dirichlet_eigenfunctions
#print axioms dome_rayleigh_quotient_above_lowest_eigenvalue
#print axioms helm_laplacian_eq_fderiv
#print axioms helm_continuous_mul_of_tsupport
#print axioms helm_ibp
#print axioms helm_st_deriv_eq_zero
#print axioms helm_st_deriv_bound
#print axioms helm_cutoff
#print axioms helm_green
#print axioms helm_normsq_hasFDerivAt
#print axioms helm_eigenvalue_real_pos
#print axioms helm_hasFDerivAt_prodForm
#print axioms helm_fderiv_prodForm
#print axioms helm_laplacian_prodForm
#print axioms helm_sin_derivs
#print axioms helm_laplacian_sinsin
#print axioms helm_integral_quartic
