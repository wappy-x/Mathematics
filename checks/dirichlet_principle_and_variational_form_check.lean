-- Dirichlet's principle: on a bounded plane region, a surface with the given rim heights solves Laplace's equation inside exactly when it has the least Dirichlet energy among all smooth surfaces with those rim heights, every other such surface stores more by exactly the energy of the difference, and the least-energy surface is the only one.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.LineDeriv.IntegrationByParts
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.Analysis.Calculus.BumpFunction.FiniteDimension
import Mathlib.Analysis.Real.Cardinality
import Mathlib.Analysis.SpecialFunctions.SmoothTransition

open Set Real Laplacian MeasureTheory

/-! The plane is `ℂ`: the point `(x, y)` is `x + y i`. The region `Ω` is a bounded open set (the
inside of the wire loop) and its rim `∂Ω` is `frontier Ω`. A surface is a height `w : ℂ → ℝ`.
"Smooth up to the rim" is `ContDiff ℝ 1 w`: heights and first slopes continuous everywhere.
The slopes are `w_x = fderiv ℝ w z 1` and `w_y = fderiv ℝ w z I`. Laplace's equation is Mathlib's
Laplacian `Δ u = u_xx + u_yy` set to zero. -/

/-- The Dirichlet energy over `Ω`: half the summed squared slope, `E(w) = ½ ∫_Ω (w_x² + w_y²) dA`. -/
noncomputable def dirichletEnergy (Ω : Set ℂ) (w : ℂ → ℝ) : ℝ :=
  (1 / 2) * ∫ z in Ω, ((fderiv ℝ w z 1) ^ 2 + (fderiv ℝ w z Complex.I) ^ 2)

lemma dp_laplacian_eq (u : ℂ → ℝ) (z : ℂ) :
    Δ u z = fderiv ℝ (fderiv ℝ u) z 1 1 + fderiv ℝ (fderiv ℝ u) z Complex.I Complex.I := by
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_complexPlane]; simp [iteratedFDeriv_two_apply]

lemma dp_fderiv_apply {u : ℂ → ℝ} {z : ℂ} (h : DifferentiableAt ℝ (fderiv ℝ u) z) (v w : ℂ) :
    fderiv ℝ (fun y => fderiv ℝ u y v) z w = fderiv ℝ (fderiv ℝ u) z w v := by
  rw [fderiv_clm_apply h (differentiableAt_const v)]; simp

lemma dp_cont_mul {Ω K : Set ℂ} {h k : ℂ → ℝ} (hΩ : IsOpen Ω) (hK : IsClosed K) (hKΩ : K ⊆ Ω)
    (hh : ContinuousOn h Ω) (hk : Continuous k) (hk0 : ∀ z ∉ K, k z = 0) :
    Continuous (fun z => h z * k z) := by
  rw [continuous_iff_continuousAt]
  intro z
  by_cases hz : z ∈ Ω
  · exact ((hh.continuousAt (hΩ.mem_nhds hz)).mul hk.continuousAt)
  · have hzK : z ∉ K := fun h => hz (hKΩ h)
    have : (fun z => h z * k z) =ᶠ[nhds z] fun _ => 0 := by
      filter_upwards [hK.isOpen_compl.mem_nhds hzK] with y hy
      simp [hk0 y hy]
    exact continuousAt_const.congr this.symm

lemma dp_fderiv_zero_off {K : Set ℂ} {k : ℂ → ℝ} (hK : IsClosed K) (hk0 : ∀ z ∉ K, k z = 0)
    {z : ℂ} (hz : z ∉ K) : fderiv ℝ k z = 0 := by
  have : k =ᶠ[nhds z] fun _ => 0 := by
    filter_upwards [hK.isOpen_compl.mem_nhds hz] with y hy
    exact hk0 y hy
  rw [this.fderiv_eq]; simp

lemma dp_integrable {Ω K : Set ℂ} {h k : ℂ → ℝ} (hΩ : IsOpen Ω) (hK : IsCompact K) (hKΩ : K ⊆ Ω)
    (hh : ContinuousOn h Ω) (hk : Continuous k) (hk0 : ∀ z ∉ K, k z = 0) :
    Integrable (fun z => h z * k z) := by
  apply (dp_cont_mul hΩ hK.isClosed hKΩ hh hk hk0).integrable_of_hasCompactSupport
  exact HasCompactSupport.intro hK (fun z hz => by simp [hk0 z hz])

lemma dp_intOn {Ω : Set ℂ} (hbdd : Bornology.IsBounded Ω) {f : ℂ → ℝ} (hf : Continuous f) :
    IntegrableOn f Ω :=
  (hf.continuousOn.integrableOn_compact hbdd.isCompact_closure).mono_set subset_closure

lemma dp_cont_d {f : ℂ → ℝ} (hf : ContDiff ℝ 1 f) (v : ℂ) :
    Continuous (fun z => fderiv ℝ f z v) :=
  (hf.continuous_fderiv one_ne_zero).clm_apply continuous_const

lemma dp_ibp {Ω K : Set ℂ} (hΩ : IsOpen Ω) {u ψ : ℂ → ℝ} (hu : ContDiff ℝ 1 u)
    (hu2 : ContDiffOn ℝ 2 u Ω) (hψ : ContDiff ℝ 1 ψ) (hK : IsCompact K) (hKΩ : K ⊆ Ω)
    (hψ0 : ∀ z ∉ K, ψ z = 0) :
    ∫ z, (fderiv ℝ u z 1 * fderiv ℝ ψ z 1 + fderiv ℝ u z Complex.I * fderiv ℝ ψ z Complex.I)
      = -∫ z, ψ z * Δ u z := by
  have hd1 : ContDiffOn ℝ 1 (fun y => fderiv ℝ u y) Ω := hu2.fderiv_of_isOpen hΩ (by norm_num)
  have hdiff : ∀ z ∈ Ω, DifferentiableAt ℝ (fderiv ℝ u) z := fun z hz =>
    (hd1.differentiableOn one_ne_zero z hz).differentiableAt (hΩ.mem_nhds hz)
  have hd2 : ContinuousOn (fun y => fderiv ℝ (fderiv ℝ u) y) Ω :=
    hd1.continuousOn_fderiv_of_isOpen hΩ le_rfl
  have hψd : ∀ z, DifferentiableAt ℝ ψ z := fun z => (hψ.differentiable one_ne_zero) z
  have hts : tsupport ψ ⊆ K := closure_minimal (fun z hz => by
    by_contra h; exact hz (hψ0 z h)) hK.isClosed
  have key : ∀ v : ℂ, ∫ z, fderiv ℝ u z v * fderiv ℝ ψ z v
      = -∫ z, fderiv ℝ (fderiv ℝ u) z v v * ψ z := by
    intro v
    have hEq : (fun x => fderiv ℝ (fun y => fderiv ℝ u y v) x v * ψ x)
        = fun x => fderiv ℝ (fderiv ℝ u) x v v * ψ x := by
      funext x
      by_cases hx : x ∈ Ω
      · rw [dp_fderiv_apply (hdiff x hx)]
      · have : x ∉ K := fun h => hx (hKΩ h)
        simp [hψ0 x this]
    have h1 : Integrable (fun x => fderiv ℝ (fderiv ℝ u) x v v * ψ x) :=
      dp_integrable hΩ hK hKΩ ((hd2.clm_apply continuousOn_const).clm_apply continuousOn_const)
        hψ.continuous hψ0
    have h2 : Integrable (fun x => fderiv ℝ u x v * fderiv ℝ ψ x v) :=
      dp_integrable hΩ hK hKΩ (dp_cont_d hu v).continuousOn (dp_cont_d hψ v)
        (fun z hz => by simp [dp_fderiv_zero_off hK.isClosed hψ0 hz])
    have h3 : Integrable (fun x => fderiv ℝ u x v * ψ x) :=
      dp_integrable hΩ hK hKΩ (dp_cont_d hu v).continuousOn hψ.continuous hψ0
    have := integral_mul_fderiv_eq_neg_fderiv_mul_of_integrable (μ := volume)
      (f := fun y => fderiv ℝ u y v) (g := ψ) (v := v) (hEq ▸ h1) h2 h3
      (fun x hx => (hd1.clm_apply contDiffOn_const).differentiableOn one_ne_zero x
        (hKΩ (hts hx)) |>.differentiableAt (hΩ.mem_nhds (hKΩ (hts hx))))
      (fun x _ => hψd x)
    rw [this, hEq]
  have i2 : ∀ v : ℂ, Integrable (fun x => fderiv ℝ u x v * fderiv ℝ ψ x v) := fun v =>
    dp_integrable hΩ hK hKΩ (dp_cont_d hu v).continuousOn (dp_cont_d hψ v)
      (fun z hz => by simp [dp_fderiv_zero_off hK.isClosed hψ0 hz])
  have i1 : ∀ v : ℂ, Integrable (fun x => fderiv ℝ (fderiv ℝ u) x v v * ψ x) := fun v =>
    dp_integrable hΩ hK hKΩ ((hd2.clm_apply continuousOn_const).clm_apply continuousOn_const)
      hψ.continuous hψ0
  rw [integral_add (i2 1) (i2 Complex.I), key, key, ← neg_add, ← integral_add (i1 1) (i1 _)]
  congr 1
  apply integral_congr_ae
  filter_upwards with z
  rw [dp_laplacian_eq]; ring

lemma dp_k_cd : ContDiff ℝ 1 (fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1)) :=
  contDiff_id.mul (Real.smoothTransition.contDiff.comp ((contDiff_id.pow 2).sub contDiff_const))

lemma dp_k_zero {t : ℝ} (ht : |t| ≤ 1) : t * Real.smoothTransition (t ^ 2 - 1) = 0 := by
  have : t ^ 2 ≤ 1 := by
    rw [← sq_abs]; nlinarith [abs_nonneg t]
  rw [Real.smoothTransition.zero_of_nonpos (by linarith), mul_zero]

lemma dp_k_deriv {t : ℝ} (ht : 2 ≤ |t|) :
    deriv (fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1)) t = 1 := by
  have h4 : 2 < t ^ 2 := by rw [← sq_abs]; nlinarith
  have : (fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1)) =ᶠ[nhds t] fun s => s := by
    filter_upwards [(isOpen_lt continuous_const (continuous_pow 2)).mem_nhds h4] with s hs
    rw [Real.smoothTransition.one_of_one_le (by linarith), mul_one]
  rw [this.deriv_eq, deriv_id'']

lemma dp_k_cont : Continuous (deriv (fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1))) :=
  dp_k_cd.continuous_deriv le_rfl

lemma dp_k_bound : ∃ C, ∀ t, |deriv (fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1)) t| ≤ C := by
  obtain ⟨C, hC⟩ := (isCompact_Icc (a := (-2 : ℝ)) (b := 2)).exists_bound_of_continuousOn
    dp_k_cont.continuousOn
  refine ⟨max C 1, fun t => ?_⟩
  by_cases ht : 2 ≤ |t|
  · rw [dp_k_deriv ht]; simp
  · push Not at ht
    have := hC t (by rw [mem_Icc]; constructor <;> linarith [abs_lt.1 ht])
    rw [Real.norm_eq_abs] at this
    exact this.trans (le_max_left _ _)

lemma dp_trunc_step {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {u φ : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hu2 : ContDiffOn ℝ 2 u Ω) (hlap : ∀ z ∈ Ω, Δ u z = 0)
    (hφ : ContDiff ℝ 1 φ) (hφ0 : ∀ z ∈ frontier Ω, φ z = 0) (n : ℕ) :
    ∫ z in Ω, deriv (fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1)) (((n : ℝ) + 1) * φ z) *
      (fderiv ℝ u z 1 * fderiv ℝ φ z 1 + fderiv ℝ u z Complex.I * fderiv ℝ φ z Complex.I) = 0 := by
  classical
  set k := fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1) with hk
  set c : ℝ := (n : ℝ) + 1 with hcdef
  have hc : 0 < c := by positivity
  set ψ : ℂ → ℝ := fun z => if z ∈ Ω then k (c * φ z) * c⁻¹ else 0 with hψdef
  set K := closure Ω ∩ {z | 1 / c ≤ |φ z|} with hKdef
  have hKc : IsCompact K :=
    hbdd.isCompact_closure.inter_right (isClosed_le continuous_const hφ.continuous.abs)
  have hKΩ : K ⊆ Ω := by
    intro z hz
    by_contra hzΩ
    have hfr : z ∈ frontier Ω := ⟨hz.1, by rwa [hΩ.interior_eq]⟩
    have h1 := hz.2
    simp only [mem_ofPred_eq] at h1
    rw [hφ0 z hfr, abs_zero] at h1
    have : 0 < 1 / c := by positivity
    linarith
  have hψ0 : ∀ z ∉ K, ψ z = 0 := by
    intro z hz
    simp only [hψdef]
    split_ifs with hzΩ
    · have hlt : |φ z| < 1 / c := by
        by_contra h; push Not at h; exact hz ⟨subset_closure hzΩ, h⟩
      have : |c * φ z| ≤ 1 := by
        rw [abs_mul, abs_of_pos hc]
        have := (lt_div_iff₀' hc).1 hlt
        linarith
      simp [hk, dp_k_zero this]
    · rfl
  have hloc : ∀ z ∈ Ω, ψ =ᶠ[nhds z] fun z => k (c * φ z) * c⁻¹ := by
    intro z hz
    filter_upwards [hΩ.mem_nhds hz] with y hy
    simp [hψdef, hy]
  have hψcd : ContDiff ℝ 1 ψ := by
    rw [contDiff_iff_contDiffAt]
    intro z
    by_cases hz : z ∈ Ω
    · exact ((dp_k_cd.comp (contDiff_const.mul hφ)).mul contDiff_const).contDiffAt.congr_of_eventuallyEq
        (hloc z hz)
    · have hzK : z ∉ K := fun h => hz (hKΩ h)
      have : ψ =ᶠ[nhds z] fun _ => 0 := by
        filter_upwards [hKc.isClosed.isOpen_compl.mem_nhds hzK] with y hy
        exact hψ0 y hy
      exact contDiffAt_const.congr_of_eventuallyEq this
  have hψd : ∀ z ∈ Ω, ∀ v : ℂ, fderiv ℝ ψ z v = deriv k (c * φ z) * fderiv ℝ φ z v := by
    intro z hz v
    have h1 : HasFDerivAt (fun z => c * φ z) (c • fderiv ℝ φ z) z :=
      ((hφ.differentiable one_ne_zero) z).hasFDerivAt.const_mul c
    have h2 : HasDerivAt k (deriv k (c * φ z)) (c * φ z) :=
      ((dp_k_cd.differentiable one_ne_zero) _).hasDerivAt
    have h4 : HasFDerivAt (fun z => k (c * φ z)) (deriv k (c * φ z) • c • fderiv ℝ φ z) z :=
      HasDerivAt.comp_hasFDerivAt (h₂ := k) z h2 h1
    have h3 := h4.mul_const c⁻¹
    rw [(hloc z hz).fderiv_eq, h3.fderiv]
    simp
    field_simp
  have hibp := dp_ibp hΩ hu hu2 hψcd hKc hKΩ hψ0
  have hzero : ∫ z, ψ z * Δ u z = 0 := by
    rw [integral_eq_zero_of_ae]
    filter_upwards with z
    by_cases hz : z ∈ Ω
    · simp [hlap z hz]
    · simp [hψdef, hz]
  rw [hzero, neg_zero] at hibp
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Ω)] at hibp
  · rw [← hibp]
    apply setIntegral_congr_fun hΩ.measurableSet
    intro z hz
    simp only [hψd z hz]
    ring
  · intro z hz
    have hzK : z ∉ K := fun h => hz (hKΩ h)
    simp [dp_fderiv_zero_off hKc.isClosed hψ0 hzK]

lemma dp_trunc {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {u φ : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hu2 : ContDiffOn ℝ 2 u Ω) (hlap : ∀ z ∈ Ω, Δ u z = 0)
    (hφ : ContDiff ℝ 1 φ) (hφ0 : ∀ z ∈ frontier Ω, φ z = 0)
    (hae : ∀ᵐ z ∂(volume.restrict Ω), φ z ≠ 0) :
    ∫ z in Ω, (fderiv ℝ u z 1 * fderiv ℝ φ z 1
      + fderiv ℝ u z Complex.I * fderiv ℝ φ z Complex.I) = 0 := by
  set k := fun t : ℝ => t * Real.smoothTransition (t ^ 2 - 1) with hk
  set G : ℂ → ℝ := fun z => fderiv ℝ u z 1 * fderiv ℝ φ z 1
      + fderiv ℝ u z Complex.I * fderiv ℝ φ z Complex.I with hG
  have hGc : Continuous G :=
    ((dp_cont_d hu 1).mul (dp_cont_d hφ 1)).add ((dp_cont_d hu _).mul (dp_cont_d hφ _))
  obtain ⟨C, hC⟩ := dp_k_bound
  have hlim := tendsto_integral_of_dominated_convergence (μ := volume.restrict Ω)
    (F := fun (n : ℕ) z => deriv k (((n : ℝ) + 1) * φ z) * G z) (f := G)
    (fun z => C * ‖G z‖) (fun n => ?_) ?_ (fun n => ?_) ?_
  · have h0 : (fun n : ℕ => ∫ z in Ω, deriv k (((n : ℝ) + 1) * φ z) * G z) = fun _ => 0 := by
      funext n; exact dp_trunc_step hΩ hbdd hu hu2 hlap hφ hφ0 n
    rw [h0] at hlim
    exact tendsto_nhds_unique hlim tendsto_const_nhds
  · exact ((dp_k_cont.comp (continuous_const.mul hφ.continuous)).mul hGc).aestronglyMeasurable
  · exact ((dp_intOn hbdd hGc).norm.const_mul C)
  · filter_upwards with z
    rw [norm_mul]
    exact mul_le_mul_of_nonneg_right (by rw [Real.norm_eq_abs]; exact hC _) (norm_nonneg _)
  · filter_upwards [hae] with z hz
    apply tendsto_const_nhds.congr'
    have hpos : 0 < |φ z| := abs_pos.2 hz
    rw [Filter.EventuallyEq, Filter.eventually_atTop]
    refine ⟨⌈2 / |φ z|⌉₊, fun n hn => ?_⟩
    have h1 : 2 / |φ z| ≤ n := (Nat.le_ceil _).trans (by exact_mod_cast hn)
    have h2 : 2 ≤ |((n : ℝ) + 1) * φ z| := by
      rw [abs_mul, abs_of_pos (by positivity : (0:ℝ) < n + 1)]
      rw [div_le_iff₀ hpos] at h1
      nlinarith
    simp only [hk, dp_k_deriv h2, one_mul]

lemma dp_intG {Ω : Set ℂ} (hbdd : Bornology.IsBounded Ω) {u f : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hf : ContDiff ℝ 1 f) :
    IntegrableOn (fun z => fderiv ℝ u z 1 * fderiv ℝ f z 1
      + fderiv ℝ u z Complex.I * fderiv ℝ f z Complex.I) Ω :=
  dp_intOn hbdd (((dp_cont_d hu 1).mul (dp_cont_d hf 1)).add
    ((dp_cont_d hu Complex.I).mul (dp_cont_d hf Complex.I)))

lemma dp_orth {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {u φ : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hu2 : ContDiffOn ℝ 2 u Ω) (hlap : ∀ z ∈ Ω, Δ u z = 0)
    (hφ : ContDiff ℝ 1 φ) (hφ0 : ∀ z ∈ frontier Ω, φ z = 0) :
    ∫ z in Ω, (fderiv ℝ u z 1 * fderiv ℝ φ z 1
      + fderiv ℝ u z Complex.I * fderiv ℝ φ z Complex.I) = 0 := by
  obtain ⟨η, hηs, hη, -⟩ := hΩ.exists_contDiff_support_eq (n := 1)
  have hη1 : ContDiff ℝ 1 η := by exact_mod_cast hη
  have hηΩ : ∀ z, η z ≠ 0 ↔ z ∈ Ω := fun z => by rw [← hηs]; rfl
  have hη0 : ∀ z ∈ frontier Ω, η z = 0 := by
    intro z hz
    by_contra h
    have := (hηΩ z).1 h
    exact hz.2 (by rwa [hΩ.interior_eq])
  set S := {t : ℝ | 0 < volume.restrict Ω {z | φ z / η z = t}} with hSdef
  have hS : S.Countable := Measure.countable_meas_level_set_pos
    (hφ.continuous.measurable.div hη1.continuous.measurable)
  set I : (ℂ → ℝ) → ℝ := fun f => ∫ z in Ω, (fderiv ℝ u z 1 * fderiv ℝ f z 1
      + fderiv ℝ u z Complex.I * fderiv ℝ f z Complex.I) with hI
  have hlin : ∀ δ ∉ S, I φ - δ * I η = 0 := by
    intro δ hδ
    have hnull : volume.restrict Ω {z | φ z / η z = δ} = 0 := by
      by_contra h; exact hδ (pos_iff_ne_zero.2 h)
    have hae : ∀ᵐ z ∂(volume.restrict Ω), (fun z => φ z - δ * η z) z ≠ 0 := by
      filter_upwards [measure_eq_zero_iff_ae_notMem.1 hnull, ae_restrict_mem hΩ.measurableSet]
        with z hz hzΩ
      intro h
      apply hz
      have hne := (hηΩ z).2 hzΩ
      field_simp
      linarith
    have hcd : ContDiff ℝ 1 (fun z => φ z - δ * η z) := hφ.sub (contDiff_const.mul hη1)
    have h := dp_trunc hΩ hbdd hu hu2 hlap hcd
      (fun z hz => by simp [hφ0 z hz, hη0 z hz]) hae
    have hd : ∀ z v, fderiv ℝ (fun z => φ z - δ * η z) z v
        = fderiv ℝ φ z v - δ * fderiv ℝ η z v := by
      intro z v
      rw [fderiv_fun_sub ((hφ.differentiable one_ne_zero) z)
        (((hη1.differentiable one_ne_zero) z).const_mul δ), fderiv_const_mul
        ((hη1.differentiable one_ne_zero) z)]
      simp
    simp only [hd] at h
    have i1 := dp_intG hbdd hu hφ
    have i2 := (dp_intG hbdd hu hη1).const_mul δ
    rw [hI]
    simp only
    rw [← integral_const_mul, ← integral_sub i1 i2, ← h]
    congr 1; funext z; ring
  obtain ⟨δ₁, hδ₁⟩ : ∃ δ, δ ∉ S := by
    by_contra h; push Not at h
    exact Cardinal.not_countable_real (hS.mono (fun x _ => h x))
  obtain ⟨δ₂, hδ₂⟩ : ∃ δ, δ ∉ insert δ₁ S := by
    by_contra h; push Not at h
    exact Cardinal.not_countable_real ((hS.insert δ₁).mono (fun x _ => h x))
  have h₁ := hlin δ₁ hδ₁
  have h₂ := hlin δ₂ (fun h => hδ₂ (mem_insert_of_mem _ h))
  have hne : δ₂ ≠ δ₁ := fun h => hδ₂ (h ▸ mem_insert _ _)
  have hJ : I η = 0 := by
    have : (δ₂ - δ₁) * I η = 0 := by linarith
    rcases mul_eq_zero.1 this with h | h
    · exact absurd (sub_eq_zero.1 h) hne
    · exact h
  have : I φ = 0 := by rw [hJ, mul_zero, sub_zero] at h₁; exact h₁
  exact this

lemma dp_energy_expand {Ω : Set ℂ} (hbdd : Bornology.IsBounded Ω) {f g : ℂ → ℝ}
    (hf : ContDiff ℝ 1 f) (hg : ContDiff ℝ 1 g) (t : ℝ) :
    dirichletEnergy Ω (fun z => f z + t * g z) = dirichletEnergy Ω f
      + t * (∫ z in Ω, (fderiv ℝ f z 1 * fderiv ℝ g z 1
          + fderiv ℝ f z Complex.I * fderiv ℝ g z Complex.I))
      + t ^ 2 * dirichletEnergy Ω g := by
  have hd : ∀ z v, fderiv ℝ (fun z => f z + t * g z) z v = fderiv ℝ f z v + t * fderiv ℝ g z v := by
    intro z v
    rw [fderiv_fun_add ((hf.differentiable one_ne_zero) z)
      (((hg.differentiable one_ne_zero) z).const_mul t), fderiv_const_mul
      ((hg.differentiable one_ne_zero) z)]
    simp
  unfold dirichletEnergy
  simp only [hd]
  have iA : IntegrableOn (fun z => (fderiv ℝ f z 1) ^ 2 + (fderiv ℝ f z Complex.I) ^ 2) Ω :=
    dp_intOn hbdd (((dp_cont_d hf 1).pow 2).add ((dp_cont_d hf _).pow 2))
  have iC : IntegrableOn (fun z => (fderiv ℝ g z 1) ^ 2 + (fderiv ℝ g z Complex.I) ^ 2) Ω :=
    dp_intOn hbdd (((dp_cont_d hg 1).pow 2).add ((dp_cont_d hg _).pow 2))
  have iB := dp_intG hbdd hf hg
  have key : ∫ z in Ω, ((fderiv ℝ f z 1 + t * fderiv ℝ g z 1) ^ 2
      + (fderiv ℝ f z Complex.I + t * fderiv ℝ g z Complex.I) ^ 2)
      = (∫ z in Ω, ((fderiv ℝ f z 1) ^ 2 + (fderiv ℝ f z Complex.I) ^ 2))
        + (2 * t) * (∫ z in Ω, (fderiv ℝ f z 1 * fderiv ℝ g z 1
          + fderiv ℝ f z Complex.I * fderiv ℝ g z Complex.I))
        + t ^ 2 * (∫ z in Ω, ((fderiv ℝ g z 1) ^ 2 + (fderiv ℝ g z Complex.I) ^ 2)) := by
    have e : (fun z => (fderiv ℝ f z 1 + t * fderiv ℝ g z 1) ^ 2
        + (fderiv ℝ f z Complex.I + t * fderiv ℝ g z Complex.I) ^ 2)
        = fun z => (((fderiv ℝ f z 1) ^ 2 + (fderiv ℝ f z Complex.I) ^ 2)
          + (2 * t) * (fderiv ℝ f z 1 * fderiv ℝ g z 1
            + fderiv ℝ f z Complex.I * fderiv ℝ g z Complex.I))
          + t ^ 2 * ((fderiv ℝ g z 1) ^ 2 + (fderiv ℝ g z Complex.I) ^ 2) := by
      funext z; ring
    have iAB : IntegrableOn (fun z => ((fderiv ℝ f z 1) ^ 2 + (fderiv ℝ f z Complex.I) ^ 2)
          + (2 * t) * (fderiv ℝ f z 1 * fderiv ℝ g z 1
            + fderiv ℝ f z Complex.I * fderiv ℝ g z Complex.I)) Ω := iA.add (iB.const_mul _)
    rw [e, integral_add iAB (iC.const_mul _),
      integral_add iA (iB.const_mul _), integral_const_mul, integral_const_mul]
  rw [key]; ring

lemma dp_energy_nonneg (Ω : Set ℂ) (hΩ : IsOpen Ω) (f : ℂ → ℝ) : 0 ≤ dirichletEnergy Ω f := by
  unfold dirichletEnergy
  apply mul_nonneg (by norm_num)
  exact setIntegral_nonneg hΩ.measurableSet (fun z _ => by positivity)

lemma dp_energy_split {Ω : Set ℂ} (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) {u w : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hu2 : ContDiffOn ℝ 2 u Ω) (hlap : ∀ z ∈ Ω, Δ u z = 0)
    (hw : ContDiff ℝ 1 w) (hrim : EqOn w u (frontier Ω)) :
    dirichletEnergy Ω w = dirichletEnergy Ω u + dirichletEnergy Ω (w - u) := by
  have hφ : ContDiff ℝ 1 (w - u) := hw.sub hu
  have hφ0 : ∀ z ∈ frontier Ω, (w - u) z = 0 := fun z hz => by simp [hrim hz]
  have horth := dp_orth hΩ hbdd hu hu2 hlap hφ hφ0
  have hexp := dp_energy_expand hbdd hu hφ 1
  have hw' : (fun z => u z + 1 * (w - u) z) = w := by funext z; simp
  rw [hw'] at hexp
  rw [hexp, horth]; ring

lemma dp_notMem_of_frontier {Ω : Set ℂ} (hΩ : IsOpen Ω) {z : ℂ} (hz : z ∈ frontier Ω) :
    z ∉ Ω := by
  have := hz.2; rwa [hΩ.interior_eq] at this

lemma dp_zero_of_grad {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {φ : ℂ → ℝ}
    (hφ : ContDiff ℝ 1 φ) (hd : ∀ z ∈ Ω, fderiv ℝ φ z 1 = 0)
    (h0 : ∀ z ∈ frontier Ω, φ z = 0) : EqOn φ 0 (closure Ω) := by
  intro z hz
  by_cases hzΩ : z ∈ Ω
  swap
  · exact h0 z ⟨hz, by rwa [hΩ.interior_eq]⟩
  obtain ⟨R, hR⟩ := hbdd.exists_norm_le
  have hgc : Continuous (fun t : ℝ => z + (t : ℂ)) := continuous_const.add Complex.continuous_ofReal
  set T := {t : ℝ | 0 ≤ t} ∩ ((fun t : ℝ => z + (t : ℂ)) ⁻¹' Ωᶜ) with hTdef
  have hTc : IsClosed T :=
    (isClosed_le continuous_const continuous_id).inter (hΩ.isClosed_compl.preimage hgc)
  have hR0 : 0 ≤ R := (norm_nonneg z).trans (hR z hzΩ)
  have hTne : R + ‖z‖ + 1 ∈ T := by
    refine ⟨(by linarith [norm_nonneg z] : (0:ℝ) ≤ R + ‖z‖ + 1), ?_⟩
    intro h
    have h1 := hR _ h
    have h2 : ‖((R + ‖z‖ + 1 : ℝ) : ℂ)‖ ≤ ‖z + ((R + ‖z‖ + 1 : ℝ) : ℂ)‖ + ‖z‖ := by
      have := norm_sub_le (z + ((R + ‖z‖ + 1 : ℝ) : ℂ)) z
      simpa using this
    rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (by linarith [norm_nonneg z])] at h2
    linarith
  have hTbdd : BddBelow T := ⟨0, fun t ht => ht.1⟩
  set s := sInf T with hsdef
  have hsT : s ∈ T := hTc.csInf_mem ⟨_, hTne⟩ hTbdd
  have hlt : ∀ t, 0 ≤ t → t < s → z + (t : ℂ) ∈ Ω := fun t ht hts => by
    by_contra h
    exact absurd (csInf_le hTbdd ⟨ht, h⟩) (not_le.2 hts)
  have hs0 : 0 < s := by
    have hs0' : (0:ℝ) ≤ s := hsT.1
    rcases hs0'.lt_or_eq with h | h
    · exact h
    · exfalso; apply hsT.2; rw [← h]; simpa using hzΩ
  have hcl : z + (s : ℂ) ∈ closure Ω := by
    apply mem_closure_of_tendsto (f := fun t : ℝ => z + (t : ℂ)) (b := nhdsWithin s (Iio s))
      (hgc.continuousAt.tendsto.mono_left nhdsWithin_le_nhds)
    filter_upwards [Ioo_mem_nhdsLT hs0] with t ht
    exact hlt t ht.1.le ht.2
  have hfr : z + (s : ℂ) ∈ frontier Ω := ⟨hcl, by rw [hΩ.interior_eq]; exact hsT.2⟩
  have hconst := constant_of_has_deriv_right_zero (f := fun t : ℝ => φ (z + (t : ℂ)))
    (a := 0) (b := s) (hφ.continuous.comp hgc).continuousOn (fun x hx => by
      have hx' : z + (x : ℂ) ∈ Ω := hlt x hx.1 hx.2
      have hg : HasDerivAt (fun t : ℝ => z + (t : ℂ)) 1 x := by
        simpa using ((hasDerivAt_id x).ofReal_comp).const_add z
      have := ((hφ.differentiable one_ne_zero) (z + x)).hasFDerivAt.comp_hasDerivAt x hg
      rw [hd _ hx'] at this
      exact this.hasDerivWithinAt) s ⟨hs0.le, le_rfl⟩
  simp only [Complex.ofReal_zero, add_zero] at hconst
  rw [← hconst]
  exact h0 _ hfr

/-- Dirichlet's principle. Let `Ω` be a bounded open region of the plane (the inside of the loop;
being bounded, every smooth surface on it has finite energy) and `g` the rim heights.
Let `u` be a surface smooth up to the rim, with `u = g` on the rim and continuous second
derivatives inside. Then `u` solves Laplace's equation `Δu = 0` at every point of `Ω` exactly
when it has the least Dirichlet energy: `E(u) ≤ E(w)` for every smooth surface `w` with `w = g`
on the rim. -/
theorem laplace_iff_least_dirichlet_energy {Ω : Set ℂ} (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) {g u : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hu2 : ContDiffOn ℝ 2 u Ω) (hug : EqOn u g (frontier Ω)) :
    (∀ z ∈ Ω, Δ u z = 0) ↔
      ∀ w : ℂ → ℝ, ContDiff ℝ 1 w → EqOn w g (frontier Ω) →
        dirichletEnergy Ω u ≤ dirichletEnergy Ω w := by
  constructor
  · intro hlap w hw hwg
    have hrim : EqOn w u (frontier Ω) := fun z hz => (hwg hz).trans (hug hz).symm
    rw [dp_energy_split hΩ hbdd hu hu2 hlap hw hrim]
    linarith [dp_energy_nonneg Ω hΩ (w - u)]
  · intro hmin
    have hd1 : ContDiffOn ℝ 1 (fun y => fderiv ℝ u y) Ω := hu2.fderiv_of_isOpen hΩ (by norm_num)
    have hd2 : ContinuousOn (fun y => fderiv ℝ (fderiv ℝ u) y) Ω :=
      hd1.continuousOn_fderiv_of_isOpen hΩ le_rfl
    have hcont : ContinuousOn (Δ u) Ω := by
      have : ContinuousOn (fun z => fderiv ℝ (fderiv ℝ u) z 1 1
          + fderiv ℝ (fderiv ℝ u) z Complex.I Complex.I) Ω :=
        ((hd2.clm_apply continuousOn_const).clm_apply continuousOn_const).add
          ((hd2.clm_apply continuousOn_const).clm_apply continuousOn_const)
      exact this.congr (fun z _ => dp_laplacian_eq u z)
    have hzero : ∀ ψ : ℂ → ℝ, ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) ψ → HasCompactSupport ψ → tsupport ψ ⊆ Ω →
        ∫ x, ψ x • Δ u x = 0 := by
      intro ψ hψ hψc hψΩ
      have hψ1 : ContDiff ℝ 1 ψ := hψ.of_le (by exact_mod_cast le_top)
      have hψ0 : ∀ z ∉ tsupport ψ, ψ z = 0 := fun z hz => image_eq_zero_of_notMem_tsupport hz
      have hibp := dp_ibp hΩ hu hu2 hψ1 hψc hψΩ hψ0
      set A := ∫ z in Ω, (fderiv ℝ u z 1 * fderiv ℝ ψ z 1
          + fderiv ℝ u z Complex.I * fderiv ℝ ψ z Complex.I) with hA
      have hA0 : A = 0 := by
        set B := dirichletEnergy Ω ψ
        have hB : 0 ≤ B := dp_energy_nonneg Ω hΩ ψ
        have hmt := hmin (fun z => u z + (-A / (B + 1)) * ψ z)
          (hu.add (contDiff_const.mul hψ1)) (fun z hz => by
            have : ψ z = 0 := hψ0 z (fun h => dp_notMem_of_frontier hΩ hz (hψΩ h))
            simp [this, hug hz])
        rw [dp_energy_expand hbdd hu hψ1] at hmt
        have h' : 0 ≤ (-A / (B + 1)) * A + (-A / (B + 1)) ^ 2 * B := by linarith
        have h'' : (-A / (B + 1)) * A + (-A / (B + 1)) ^ 2 * B = -A ^ 2 / (B + 1) ^ 2 := by
          field_simp; ring
        rw [h''] at h'
        have hpos : 0 < (B + 1) ^ 2 := by positivity
        have : A ^ 2 ≤ 0 := by
          have := div_nonneg_iff.1 h'
          rcases this with ⟨h1, _⟩ | ⟨_, h2⟩
          · linarith
          · linarith
        exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 (le_antisymm this (sq_nonneg A))
      rw [hA, setIntegral_eq_integral_of_forall_compl_eq_zero] at hA0
      · rw [hA0] at hibp
        simp only [smul_eq_mul]
        linarith
      · intro z hz
        have hz' : z ∉ tsupport ψ := fun h => hz (hψΩ h)
        simp [dp_fderiv_zero_off (isClosed_tsupport ψ) hψ0 hz']
    have hae := hΩ.ae_eq_zero_of_integral_contDiff_smul_eq_zero
      (hcont.locallyIntegrableOn hΩ.measurableSet) hzero
    have hEq : EqOn (Δ u) 0 Ω := Measure.eqOn_open_of_ae_eq
      ((ae_restrict_iff' hΩ.measurableSet).2 hae) hΩ hcont continuousOn_const
    exact fun z hz => hEq hz

/-- The extra energy is the energy of the difference. If `u` solves Laplace's equation in the
bounded open region `Ω` (twice continuously differentiable there, `Δu = 0`) and is smooth up to the
rim, then every smooth surface `w` with the same rim heights stores
`E(w) = E(u) + E(w − u)`. -/
theorem dirichlet_energy_eq_least_add_energy_of_difference {Ω : Set ℂ} (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) {u w : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hu2 : ContDiffOn ℝ 2 u Ω) (hlap : ∀ z ∈ Ω, Δ u z = 0)
    (hw : ContDiff ℝ 1 w) (hrim : EqOn w u (frontier Ω)) :
    dirichletEnergy Ω w = dirichletEnergy Ω u + dirichletEnergy Ω (w - u) := by
  exact dp_energy_split hΩ hbdd hu hu2 hlap hw hrim

/-- The least-energy surface is unique. If `u` solves Laplace's equation in the bounded open region
`Ω` and is smooth up to the rim, and a smooth surface `w` with the same rim heights stores no more
energy, `E(w) ≤ E(u)`, then `w = u` everywhere on the closed region `Ω̄`. -/
theorem eq_of_dirichlet_energy_le_harmonic {Ω : Set ℂ} (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) {u w : ℂ → ℝ}
    (hu : ContDiff ℝ 1 u) (hu2 : ContDiffOn ℝ 2 u Ω) (hlap : ∀ z ∈ Ω, Δ u z = 0)
    (hw : ContDiff ℝ 1 w) (hrim : EqOn w u (frontier Ω))
    (hle : dirichletEnergy Ω w ≤ dirichletEnergy Ω u) :
    EqOn w u (closure Ω) := by
  have h2 := dirichlet_energy_eq_least_add_energy_of_difference hΩ hbdd hu hu2 hlap hw hrim
  have hE : dirichletEnergy Ω (w - u) = 0 :=
    le_antisymm (by linarith) (dp_energy_nonneg Ω hΩ _)
  have hφ : ContDiff ℝ 1 (w - u) := hw.sub hu
  have hint : ∫ z in Ω, ((fderiv ℝ (w - u) z 1) ^ 2 + (fderiv ℝ (w - u) z Complex.I) ^ 2) = 0 := by
    unfold dirichletEnergy at hE; linarith
  have hc : Continuous (fun z => (fderiv ℝ (w - u) z 1) ^ 2
      + (fderiv ℝ (w - u) z Complex.I) ^ 2) :=
    ((dp_cont_d hφ 1).pow 2).add ((dp_cont_d hφ _).pow 2)
  have hae := (integral_eq_zero_iff_of_nonneg_ae (ae_of_all _ (fun z => by positivity))
    (dp_intOn hbdd hc)).1 hint
  have hzero := Measure.eqOn_open_of_ae_eq hae hΩ hc.continuousOn continuousOn_const
  have hd1 : ∀ z ∈ Ω, fderiv ℝ (w - u) z 1 = 0 := by
    intro z hz
    have := hzero hz
    simp only [Pi.zero_apply] at this
    nlinarith [sq_nonneg (fderiv ℝ (w - u) z 1), sq_nonneg (fderiv ℝ (w - u) z Complex.I)]
  have hφ0 : ∀ z ∈ frontier Ω, (w - u) z = 0 := fun z hz => by simp [hrim hz]
  have := dp_zero_of_grad hΩ hbdd hφ hd1 hφ0
  intro z hz
  have := this hz
  simp only [Pi.sub_apply, Pi.zero_apply] at this
  linarith

/-! The card's worked numbers, for the loop of radius 5 cm with rim height `cos 2θ` cm. -/

-- the harmonic film `(x² − y²)/25`: u_xx + u_yy = 2/25 − 2/25 = 0
example : (2 : ℚ) / 25 - 2 / 25 = 0 := by norm_num

-- the film's height at (2.5, 0) cm: 2.5²/25 = 0.25 cm
example : ((5 : ℚ) / 2) ^ 2 / 25 = 1 / 4 := by norm_num

-- the rival `(x⁴ − y⁴)/625` has Laplacian 12(x² − y²)/625; at (3, 1) cm that is 96/625 per cm, not 0
example : (12 : ℚ) * (3 ^ 2 - 1 ^ 2) / 625 = 96 / 625 := by norm_num

-- E(u): profile h = ρ², so (h'² + 4h²/ρ²) ρ = 8ρ³; E(u) = (π/2)∫₀¹ 8ρ³ dρ = (π/2)·2 = π cm²
example : ∫ ρ in (0 : ℝ)..1, 8 * ρ ^ 3 = 2 := by norm_num [integral_pow]
example : π / 2 * 2 = π := by ring

-- E(w): profile h = ρ⁴, so (16ρ⁶ + 4ρ⁶) ρ = 20ρ⁷; E(w) = (π/2)·(5/2) = 5π/4 cm²
example : ∫ ρ in (0 : ℝ)..1, 20 * ρ ^ 7 = 5 / 2 := by norm_num [integral_pow]
example : π / 2 * (5 / 2) = 5 * π / 4 := by ring

-- E(w − u): profile h = ρ⁴ − ρ², integrand 20ρ⁷ − 24ρ⁵ + 8ρ³; E(w − u) = (π/2)·(1/2) = π/4 cm²
example : (20 : ℚ) / 8 - 24 / 6 + 8 / 4 = 1 / 2 := by norm_num
example : π / 2 * (1 / 2) = π / 4 := by ring

-- the gap is the energy of the difference: 5π/4 = π + π/4
example : 5 * π / 4 = π + π / 4 := by ring

#print axioms dp_laplacian_eq
#print axioms dp_fderiv_apply
#print axioms dp_cont_mul
#print axioms dp_fderiv_zero_off
#print axioms dp_integrable
#print axioms dp_intOn
#print axioms dp_cont_d
#print axioms dp_ibp
#print axioms dp_k_cd
#print axioms dp_k_zero
#print axioms dp_k_deriv
#print axioms dp_k_cont
#print axioms dp_k_bound
#print axioms dp_trunc_step
#print axioms dp_trunc
#print axioms dp_intG
#print axioms dp_orth
#print axioms dp_energy_expand
#print axioms dp_energy_nonneg
#print axioms dp_energy_split
#print axioms dp_notMem_of_frontier
#print axioms dp_zero_of_grad
#print axioms laplace_iff_least_dirichlet_energy
#print axioms dirichlet_energy_eq_least_add_energy_of_difference
#print axioms eq_of_dirichlet_energy_le_harmonic
