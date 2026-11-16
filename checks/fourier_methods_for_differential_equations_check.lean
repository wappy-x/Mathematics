-- Solving differential equations by transform: the Fourier transform turns a linear equation with constant coefficients into division by its symbol, turns heat flow on a line into one fading factor per frequency whose transform back solves the heat equation, equals blurring by the heat kernel and starts at the given profile, and gives a pushed oscillator's steady swing by one division.
import Mathlib.Analysis.Fourier.FourierTransformDeriv
import Mathlib.Analysis.SpecialFunctions.Gaussian.FourierTransform
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Analysis.SpecialFunctions.Complex.Arg

open Real Complex MeasureTheory Filter Topology
open scoped FourierTransform

/-! Mathlib's `𝓕 f ξ = ∫ f(x) e^(−2πiξx) dx` is exactly the card's transform, with `ξ` in
ripples per unit length (or hertz) and no factor in front. -/

/-- The symbol of `p_n u^(n) + ... + p_1 u' + p_0 u`: what the equation does to one ripple,
`P(ξ) = ∑_{j=0}^{n} p_j (2πiξ)^j`. -/
noncomputable def symbol (n : ℕ) (p : ℕ → ℂ) (ξ : ℝ) : ℂ :=
  ∑ j ∈ Finset.range (n + 1), p j * (2 * π * I * ξ) ^ j

/-- The heat kernel on the line: `G(x, t) = e^(−x²/(4κt)) / √(4πκt)`. -/
noncomputable def heatKernel (κ t x : ℝ) : ℝ :=
  Real.exp (-x ^ 2 / (4 * κ * t)) / Real.sqrt (4 * π * κ * t)

/-- The transform route for heat on a line: fade each frequency of the start `f` by
`e^(−4π²κξ²t)` and transform back,
`u(x, t) = ∫ f̂(ξ) e^(−4π²κξ²t) e^(2πiξx) dξ`. -/
noncomputable def heatByTransform (κ : ℝ) (f : ℝ → ℂ) (x t : ℝ) : ℂ :=
  ∫ ξ : ℝ, 𝓕 f ξ * cexp (((-4 * π ^ 2 * κ * ξ ^ 2 * t : ℝ)) : ℂ) * cexp (2 * π * I * ξ * x)

/-- The oscillator's symbol for `y'' + b y' + k y`: `P(ξ) = k + b (2πiξ) + (2πiξ)²`,
that is `k − 4π²ξ² + 2πiξ b`. -/
noncomputable def oscSymbol (b k ξ : ℝ) : ℂ :=
  k + b * (2 * π * I * ξ) + (2 * π * I * ξ) ^ 2

set_option backward.isDefEq.respectTransparency false in
lemma gauss_fubini_raw {f : ℝ → ℂ} (hf : Integrable f) (v : ℝ) {c : ℝ} (hc : 0 < c) :
    ∫ w : ℝ, cexp (- c⁻¹ * ‖w‖ ^ 2 + 2 * π * I * (inner ℝ v w)) • 𝓕 f w
      = ∫ w : ℝ, ((π * c : ℂ) ^ (Module.finrank ℝ ℝ / 2 : ℂ)
          * cexp (-π ^ 2 * c * ‖v - w‖ ^ 2)) • f w := by
  have J : Integrable (fun w : ℝ ↦ cexp (- c⁻¹ * ‖w‖ ^ 2 + 2 * π * I * (inner ℝ v w))) :=
    GaussianFourier.integrable_cexp_neg_mul_sq_norm_add (by simpa) _ _
  have B : ∫ w : ℝ, cexp (- c⁻¹ * ‖w‖ ^ 2 + 2 * π * I * (inner ℝ v w)) • 𝓕 f w
      = ∫ w : ℝ, 𝓕 (fun w ↦ cexp (- c⁻¹ * ‖w‖ ^ 2 + 2 * π * I * (inner ℝ v w))) w • f w := by
    simpa using! (VectorFourier.integral_fourierIntegral_smul_eq_flip (L := innerₗ ℝ)
      Real.continuous_fourierChar continuous_inner J hf).symm
  rw [B]
  congr with w
  rw [fourier_gaussian_innerProductSpace' (by simpa)]
  congr
  · simp
  · simp; ring

lemma gauss_fubini {f : ℝ → ℂ} (hf : Integrable f) (v : ℝ) {c : ℝ} (hc : 0 < c) :
    ∫ w : ℝ, 𝓕 f w * cexp (((-c⁻¹ * w ^ 2 : ℝ)) : ℂ) * cexp (2 * π * I * w * v)
      = ∫ w : ℝ, ((π * c : ℂ) ^ (Module.finrank ℝ ℝ / 2 : ℂ)
          * cexp (-π ^ 2 * c * ‖v - w‖ ^ 2)) • f w := by
  rw [← gauss_fubini_raw hf v hc]
  congr 1
  funext w
  rw [smul_eq_mul, mul_assoc, ← Complex.exp_add, mul_comm]
  congr 2
  have hi : inner ℝ v w = v * w := by simp [RCLike.inner_apply, mul_comm]
  rw [Real.norm_eq_abs, hi, ← ofReal_pow, sq_abs]
  push_cast
  ring


lemma heat_c_pos {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) : 0 < (4 * π ^ 2 * κ * t)⁻¹ := by
  have := Real.pi_pos
  positivity

lemma hbt_eq {κ : ℝ} (hκ : 0 < κ) {f : ℝ → ℂ} (hf : Integrable f) (x t : ℝ) (ht : 0 < t)
    (c : ℝ) (hc : c = (4 * π ^ 2 * κ * t)⁻¹) :
    heatByTransform κ f x t = ∫ w : ℝ, ((π * c : ℂ) ^ (Module.finrank ℝ ℝ / 2 : ℂ)
          * cexp (-π ^ 2 * c * ‖x - w‖ ^ 2)) • f w := by
  have h := gauss_fubini hf x (c := c) (by rw [hc]; exact heat_c_pos hκ ht)
  rw [← h, heatByTransform]
  congr 1
  funext ξ
  congr 3
  rw [hc, inv_inv]
  ring_nf

lemma kernel_eq {κ t : ℝ} (hκ : 0 < κ) (ht : 0 < t) (c : ℝ) (hc : c = (4 * π ^ 2 * κ * t)⁻¹)
    (u : ℝ) :
    ((π * c : ℂ) ^ (Module.finrank ℝ ℝ / 2 : ℂ)
          * cexp (-π ^ 2 * c * ‖u‖ ^ 2)) = (heatKernel κ t u : ℂ) := by
  have hπ := Real.pi_pos
  have h1 : (π * c : ℂ) = (((4 * π * κ * t)⁻¹ : ℝ) : ℂ) := by
    rw [← ofReal_mul, hc]
    congr 1
    field_simp
  have h2 : (Module.finrank ℝ ℝ / 2 : ℂ) = ((1 / 2 : ℝ) : ℂ) := by
    simp
  rw [h1, h2, ← ofReal_cpow (by positivity), ← Real.sqrt_eq_rpow, Real.sqrt_inv, heatKernel]
  have h3 : (-π ^ 2 * c * ‖u‖ ^ 2 : ℂ) = ((-u ^ 2 / (4 * κ * t) : ℝ) : ℂ) := by
    have hu2 : ((|u| : ℝ) : ℂ) ^ 2 = ((u ^ 2 : ℝ) : ℂ) := by rw [← ofReal_pow, sq_abs]
    rw [Real.norm_eq_abs, hu2]
    have : (-π ^ 2 * c * u ^ 2 : ℝ) = -u ^ 2 / (4 * κ * t) := by
      rw [hc]; field_simp
    rw [← this]
    push_cast
    ring
  rw [h3, ← ofReal_exp]
  push_cast
  ring

lemma heat_part2 {κ : ℝ} (hκ : 0 < κ) {f : ℝ → ℂ} (hf : Integrable f) :
    ∀ x t : ℝ, 0 < t →
      heatByTransform κ f x t = ∫ z : ℝ, (heatKernel κ t (x - z) : ℂ) * f z := by
  intro x t ht
  rw [hbt_eq hκ hf x t ht _ rfl]
  congr 1
  funext z
  rw [smul_eq_mul, kernel_eq hκ ht _ rfl]

lemma heat_part3 {κ : ℝ} (hκ : 0 < κ) {f : ℝ → ℂ} (hf : Integrable f) :
    ∀ x : ℝ, ContinuousAt f x →
      Tendsto (fun t => heatByTransform κ f x t) (𝓝[>] 0) (𝓝 (f x)) := by
  intro x hx
  have hπ := Real.pi_pos
  have hct : Tendsto (fun t : ℝ => (4 * π ^ 2 * κ * t)⁻¹) (𝓝[>] 0) atTop := by
    have : Tendsto (fun t : ℝ => (4 * π ^ 2 * κ)⁻¹ * t⁻¹) (𝓝[>] 0) atTop :=
      Tendsto.const_mul_atTop (by positivity) tendsto_inv_nhdsGT_zero
    refine this.congr (fun t => ?_)
    simp only [mul_inv]
  have hT := (Real.tendsto_integral_gaussian_smul' (V := ℝ) hf hx).comp hct
  refine hT.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with t ht
  rw [hbt_eq hκ hf x t ht _ rfl]
  rfl

lemma integrable_abs_pow_mul_gauss {b : ℝ} (hb : 0 < b) (n : ℕ) :
    Integrable (fun x : ℝ => |x| ^ n * Real.exp (-b * x ^ 2)) := by
  have h := (integrable_rpow_mul_exp_neg_mul_sq hb (s := (n : ℝ))
    (by have := n.cast_nonneg (α := ℝ); linarith)).norm
  refine h.congr (ae_of_all _ (fun x => ?_))
  simp only [Real.rpow_natCast, Real.norm_eq_abs, abs_mul, abs_pow,
    abs_of_pos (Real.exp_pos _)]

lemma int_of_gauss_bound {G : ℝ → ℂ} (hG : Continuous G) {C b : ℝ} (hb : 0 < b) (n : ℕ)
    (hbd : ∀ ξ, ‖G ξ‖ ≤ C * (|ξ| ^ n * Real.exp (-b * ξ ^ 2))) : Integrable G :=
  Integrable.mono' ((integrable_abs_pow_mul_gauss hb n).const_mul C) hG.aestronglyMeasurable
    (ae_of_all _ hbd)

lemma fourier_cont {f : ℝ → ℂ} (hf : Integrable f) : Continuous (𝓕 f) :=
  VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar
    (innerSL ℝ).continuous₂ hf

lemma norm_osc (ξ x : ℝ) : ‖cexp (2 * π * I * ξ * x)‖ = 1 := by
  rw [Complex.norm_exp]; simp

lemma heat_part1 {κ : ℝ} (hκ : 0 < κ) {f : ℝ → ℂ} (hf : Integrable f) :
    ∀ x t : ℝ, 0 < t →
      ContDiff ℝ 2 (fun y => heatByTransform κ f y t) ∧
      HasDerivAt (fun s => heatByTransform κ f x s)
        (κ * deriv (deriv (fun y => heatByTransform κ f y t)) x) t := by
  intro x t ht
  have hπ := Real.pi_pos
  set M := ∫ z, ‖f z‖ with hMdef
  have hM : ∀ ξ, ‖𝓕 f ξ‖ ≤ M := fun ξ => norm_fourier_le_integral_norm f ξ
  have hM0 : 0 ≤ M := integral_nonneg (fun _ => norm_nonneg _)
  have hcont := fourier_cont hf
  set g : ℝ → ℂ := fun ξ => 𝓕 f ξ * cexp (((-4 * π ^ 2 * κ * ξ ^ 2 * t : ℝ)) : ℂ) with hg
  have hb : 0 < 4 * π ^ 2 * κ * t := by positivity
  have hgn : ∀ ξ : ℝ, ‖g ξ‖ ≤ M * Real.exp (-(4 * π ^ 2 * κ * t) * ξ ^ 2) := by
    intro ξ
    rw [hg]
    simp only
    rw [norm_mul, Complex.norm_exp_ofReal]
    have : -4 * π ^ 2 * κ * ξ ^ 2 * t = -(4 * π ^ 2 * κ * t) * ξ ^ 2 := by ring
    rw [this]
    exact mul_le_mul_of_nonneg_right (hM ξ) (Real.exp_pos _).le
  have hgc : Continuous g := by rw [hg]; fun_prop
  have hmom : ∀ n : ℕ, Integrable (fun ξ : ℝ => ξ ^ n • g ξ) := fun n =>
    int_of_gauss_bound (by fun_prop) hb n (fun ξ => by
      rw [norm_smul, norm_pow, Real.norm_eq_abs]
      calc |ξ| ^ n * ‖g ξ‖ ≤ |ξ| ^ n * (M * Real.exp (-(4 * π ^ 2 * κ * t) * ξ ^ 2)) :=
            mul_le_mul_of_nonneg_left (hgn ξ) (by positivity)
        _ = M * (|ξ| ^ n * Real.exp (-(4 * π ^ 2 * κ * t) * ξ ^ 2)) := by ring)
  have hmom' : ∀ n : ℕ, Integrable (fun ξ : ℝ => ‖ξ‖ ^ n * ‖g ξ‖) := fun n => by
    refine (hmom n).norm.congr (ae_of_all _ (fun ξ => ?_))
    simp only [norm_smul, norm_pow]
  have hrepr : (fun y => heatByTransform κ f y t) = fun y => 𝓕 g (-y) := by
    funext y
    rw [heatByTransform, Real.fourier_real_eq_integral_exp_smul]
    congr 1
    funext ξ
    rw [smul_eq_mul, hg]
    have : cexp (2 * π * I * ξ * y) = cexp (((-2 * π * ξ * -y : ℝ) : ℂ) * I) := by
      congr 1; push_cast; ring
    rw [this]
    ring
  constructor
  · rw [hrepr]
    have := (contDiff_fourier (N := 2) (fun n _ => hmom' n)).comp contDiff_neg
    exact this
  · have hdd : deriv (deriv (fun y => heatByTransform κ f y t)) x
        = ∫ ξ : ℝ, cexp (((-2 * π * ξ * -x : ℝ) : ℂ) * I) • ((-2 * π * I * ξ) ^ 2 • g ξ) := by
      have h2 : deriv (deriv (fun y => heatByTransform κ f y t))
          = iteratedDeriv 2 (fun y => heatByTransform κ f y t) := by
        rw [iteratedDeriv_succ, iteratedDeriv_one]
      rw [h2, hrepr, iteratedDeriv_comp_neg,
        iteratedDeriv_fourier (N := 2) (fun n _ => hmom n) (by norm_num),
        Real.fourier_real_eq_integral_exp_smul]
      simp
    have hb2 : 0 < 2 * π ^ 2 * κ * t := by positivity
    let F : ℝ → ℝ → ℂ := fun s ξ =>
      𝓕 f ξ * cexp (((-4 * π ^ 2 * κ * ξ ^ 2 * s : ℝ)) : ℂ) * cexp (2 * π * I * ξ * x)
    let F' : ℝ → ℝ → ℂ := fun s ξ =>
      𝓕 f ξ * (cexp (((-4 * π ^ 2 * κ * ξ ^ 2 * s : ℝ)) : ℂ)
        * ((-4 * π ^ 2 * κ * ξ ^ 2 : ℝ) : ℂ)) * cexp (2 * π * I * ξ * x)
    let bound : ℝ → ℝ := fun ξ =>
      M * (4 * π ^ 2 * κ) * (|ξ| ^ 2 * Real.exp (-(2 * π ^ 2 * κ * t) * ξ ^ 2))
    have hF_meas : ∀ᶠ s in 𝓝 t, AEStronglyMeasurable (F s) volume :=
      Filter.Eventually.of_forall (fun s => (by fun_prop : Continuous (F s)).aestronglyMeasurable)
    have hF_int : Integrable (F t) := by
      refine int_of_gauss_bound (by fun_prop) hb 0 (C := M) (fun ξ => ?_)
      simp only [F]
      rw [norm_mul, norm_mul, Complex.norm_exp_ofReal, norm_osc, mul_one, pow_zero, one_mul]
      have : -4 * π ^ 2 * κ * ξ ^ 2 * t = -(4 * π ^ 2 * κ * t) * ξ ^ 2 := by ring
      rw [this]
      exact mul_le_mul_of_nonneg_right (hM ξ) (Real.exp_pos _).le
    have hF'_meas : AEStronglyMeasurable (F' t) volume :=
      (by fun_prop : Continuous (F' t)).aestronglyMeasurable
    have h_bound : ∀ᵐ ξ ∂volume, ∀ s ∈ Set.Ioi (t / 2), ‖F' s ξ‖ ≤ bound ξ := by
      refine ae_of_all _ (fun ξ s hs => ?_)
      have hs' : t / 2 < s := hs
      simp only [F', bound]
      rw [norm_mul, norm_mul, norm_mul, Complex.norm_exp_ofReal, norm_osc, mul_one,
        Complex.norm_real, Real.norm_eq_abs]
      have habs : |(-4 * π ^ 2 * κ * ξ ^ 2 : ℝ)| = 4 * π ^ 2 * κ * ξ ^ 2 := by
        rw [show (-4 * π ^ 2 * κ * ξ ^ 2 : ℝ) = -(4 * π ^ 2 * κ * ξ ^ 2) by ring, abs_neg,
          abs_of_nonneg (by positivity)]
      rw [habs, sq_abs]
      have hexp : Real.exp (-4 * π ^ 2 * κ * ξ ^ 2 * s)
          ≤ Real.exp (-(2 * π ^ 2 * κ * t) * ξ ^ 2) := by
        apply Real.exp_le_exp.mpr
        have : 0 ≤ π ^ 2 * κ * ξ ^ 2 * (4 * s - 2 * t) :=
          mul_nonneg (by positivity) (by linarith)
        nlinarith [this]
      calc ‖𝓕 f ξ‖ * (Real.exp (-4 * π ^ 2 * κ * ξ ^ 2 * s) * (4 * π ^ 2 * κ * ξ ^ 2))
          ≤ M * (Real.exp (-(2 * π ^ 2 * κ * t) * ξ ^ 2) * (4 * π ^ 2 * κ * ξ ^ 2)) :=
            mul_le_mul (hM ξ) (mul_le_mul_of_nonneg_right hexp (by positivity))
              (by positivity) hM0
        _ = M * (4 * π ^ 2 * κ) * (ξ ^ 2 * Real.exp (-(2 * π ^ 2 * κ * t) * ξ ^ 2)) := by ring
    have bound_int : Integrable bound :=
      (integrable_abs_pow_mul_gauss hb2 2).const_mul (M * (4 * π ^ 2 * κ))
    have h_diff : ∀ᵐ ξ ∂volume, ∀ s ∈ Set.Ioi (t / 2), HasDerivAt (F · ξ) (F' s ξ) s := by
      refine ae_of_all _ (fun ξ s _ => ?_)
      have h0 : HasDerivAt (fun s : ℝ => (-4 * π ^ 2 * κ * ξ ^ 2) * s)
          (-4 * π ^ 2 * κ * ξ ^ 2) s := by
        have := (hasDerivAt_id s).const_mul (-4 * π ^ 2 * κ * ξ ^ 2)
        simp only [id, mul_one] at this
        exact this
      exact ((h0.ofReal_comp.cexp).const_mul (𝓕 f ξ)).mul_const (cexp (2 * π * I * ξ * x))
    have h := hasDerivAt_integral_of_dominated_loc_of_deriv_le (x₀ := t) (s := Set.Ioi (t / 2))
      (F := F) (F' := F') (bound := bound) (Ioi_mem_nhds (by linarith)) hF_meas hF_int
      hF'_meas h_bound bound_int h_diff
    have h3 : HasDerivAt (fun s => heatByTransform κ f x s) (∫ ξ, F' t ξ) t := h.2
    refine h3.congr_deriv ?_
    symm
    rw [hdd, ← integral_const_mul]
    congr 1
    funext ξ
    simp only [F', hg, smul_eq_mul]
    have hW : cexp (((-2 * π * ξ * -x : ℝ) : ℂ) * I) = cexp (2 * π * I * ξ * x) := by
      congr 1; push_cast; ring
    rw [hW]
    push_cast
    linear_combination (4 * π ^ 2 * κ * ξ ^ 2 * 𝓕 f ξ
      * cexp (-4 * π ^ 2 * κ * ξ ^ 2 * t) * cexp (2 * π * I * ξ * x)) * I_sq

lemma hasDerivAt_re_mul_cexp (A c : ℂ) (t : ℝ) :
    HasDerivAt (fun s : ℝ => (A * cexp (c * s)).re) ((A * c * cexp (c * t)).re) t := by
  have h1 : HasDerivAt (fun s : ℝ => c * (s : ℂ)) c t := by
    simpa using ((hasDerivAt_id t).ofReal_comp).const_mul c
  have h2 : HasDerivAt (fun s : ℝ => A * cexp (c * s)) (A * (cexp (c * t) * c)) t :=
    (h1.cexp).const_mul A
  have h3 := Complex.reCLM.hasFDerivAt.comp_hasDerivAt t h2
  simp only [Function.comp_def, Complex.reCLM_apply] at h3
  rw [show A * c * cexp (c * t) = A * (cexp (c * t) * c) by ring]
  exact h3

/-- The method: transform the equation, divide by the symbol. Take a linear equation with
constant coefficients, `p_n u^(n) + ... + p_1 u' + p_0 u = g`. If the solution `u` has `n`
continuous derivatives, each with finite total size, the push `g` has finite total size, and the
symbol `P(ξ) = ∑ p_j (2πiξ)^j` is never zero on the real frequencies, then at every frequency the
equation becomes `P(ξ) û(ξ) = ĝ(ξ)`, so `û(ξ) = ĝ(ξ) / P(ξ)`. -/
theorem transform_turns_equation_into_division_by_symbol
    (n : ℕ) (p : ℕ → ℂ) (u g : ℝ → ℂ)
    (hu : ContDiff ℝ n u)
    (hu_int : ∀ j ≤ n, Integrable (iteratedDeriv j u))
    (hg : Integrable g)
    (hsol : ∀ x, ∑ j ∈ Finset.range (n + 1), p j * iteratedDeriv j u x = g x)
    (hP : ∀ ξ : ℝ, symbol n p ξ ≠ 0) :
    ∀ ξ : ℝ, symbol n p ξ * 𝓕 u ξ = 𝓕 g ξ ∧ 𝓕 u ξ = 𝓕 g ξ / symbol n p ξ := by
  intro ξ
  have key : symbol n p ξ * 𝓕 u ξ = 𝓕 g ξ := by
    have hg' : g = fun x => ∑ j ∈ Finset.range (n + 1), p j * iteratedDeriv j u x :=
      funext (fun x => (hsol x).symm)
    have hT : ∀ j ∈ Finset.range (n + 1),
        𝓕 (iteratedDeriv j u) ξ = (2 * π * I * ξ) ^ j * 𝓕 u ξ := by
      intro j hj
      have hj' : j ≤ n := Nat.lt_succ_iff.mp (Finset.mem_range.mp hj)
      have := fourier_iteratedDeriv (N := (n : ℕ∞)) hu
        (fun k hk => hu_int k (by exact_mod_cast hk)) (by exact_mod_cast hj')
      rw [this]
      simp [smul_eq_mul]
    have hlin : 𝓕 g ξ = ∑ j ∈ Finset.range (n + 1), p j * 𝓕 (iteratedDeriv j u) ξ := by
      rw [hg', Real.fourier_eq]
      simp_rw [Finset.smul_sum]
      rw [integral_finsetSum]
      · refine Finset.sum_congr rfl (fun j hj => ?_)
        rw [Real.fourier_eq, ← integral_const_mul]
        congr 1
        funext v
        simp only [Circle.smul_def, smul_eq_mul]
        ring
      · intro j hj
        have hj' : j ≤ n := Nat.lt_succ_iff.mp (Finset.mem_range.mp hj)
        have := (Real.fourierIntegral_convergent_iff (μ := volume) ξ).2
          ((hu_int j hj').const_mul (p j))
        simpa using this
    rw [hlin, symbol, Finset.sum_mul]
    refine Finset.sum_congr rfl (fun j hj => ?_)
    rw [hT j hj]
    ring
  refine ⟨key, ?_⟩
  rw [← key]
  field_simp [hP ξ]

/-- Heat on a line by transform. For a start `f` of finite total size and diffusivity `κ > 0`,
the transform route `u(x, t) = ∫ f̂(ξ) e^(−4π²κξ²t) e^(2πiξx) dξ`, forward in time `t > 0`,
is twice differentiable in `x` and solves `u_t = κ u_xx`; it equals the start blurred by the
heat kernel, `u(x, t) = ∫ G(x − z, t) f(z) dz`; and as `t` falls to 0 it tends to `f(x)` at
every point where `f` is continuous. -/
theorem heat_by_transform_solves_heat_equation
    (κ : ℝ) (hκ : 0 < κ) (f : ℝ → ℂ) (hf : Integrable f) :
    (∀ x t : ℝ, 0 < t →
      ContDiff ℝ 2 (fun y => heatByTransform κ f y t) ∧
      HasDerivAt (fun s => heatByTransform κ f x s)
        (κ * deriv (deriv (fun y => heatByTransform κ f y t)) x) t) ∧
    (∀ x t : ℝ, 0 < t →
      heatByTransform κ f x t = ∫ z : ℝ, (heatKernel κ t (x - z) : ℂ) * f z) ∧
    (∀ x : ℝ, ContinuousAt f x →
      Tendsto (fun t => heatByTransform κ f x t) (𝓝[>] 0) (𝓝 (f x))) := by
  exact ⟨heat_part1 hκ hf, heat_part2 hκ hf, heat_part3 hκ hf⟩

/-- The steady swing from one division: `y(t) = Re((F₀ / P(ξ₀)) e^(2πiξ₀t))`. -/
noncomputable def steadySwing (b k F₀ ξ₀ t : ℝ) : ℝ :=
  ((F₀ : ℂ) / oscSymbol b k ξ₀ * cexp (2 * π * I * ξ₀ * t)).re

/-- The forced oscillator's steady swing by one division. For `y'' + b y' + k y = F₀ cos(2πξ₀t)`
with the symbol `P(ξ₀) = k − 4π²ξ₀² + 2πiξ₀ b` not zero at the push's frequency, the steady swing
`y(t) = Re((F₀ / P(ξ₀)) e^(2πiξ₀t))` solves the equation, and its size never exceeds
`|F₀| / |P(ξ₀)|` and reaches it. -/
theorem steady_swing_by_one_division (b k F₀ ξ₀ : ℝ) (hP : oscSymbol b k ξ₀ ≠ 0) :
    (∀ t : ℝ,
      deriv (deriv (steadySwing b k F₀ ξ₀)) t + b * deriv (steadySwing b k F₀ ξ₀) t
        + k * steadySwing b k F₀ ξ₀ t = F₀ * Real.cos (2 * π * ξ₀ * t)) ∧
    (∀ t : ℝ, |steadySwing b k F₀ ξ₀ t| ≤ |F₀| / ‖oscSymbol b k ξ₀‖) ∧
    (∃ t : ℝ, |steadySwing b k F₀ ξ₀ t| = |F₀| / ‖oscSymbol b k ξ₀‖) := by
  set A : ℂ := (F₀ : ℂ) / oscSymbol b k ξ₀ with hA
  set c : ℂ := 2 * π * I * ξ₀ with hc
  have hfun : steadySwing b k F₀ ξ₀ = fun s : ℝ => (A * cexp (c * s)).re := rfl
  have hd1 : deriv (steadySwing b k F₀ ξ₀) = fun s : ℝ => (A * c * cexp (c * s)).re := by
    rw [hfun]; funext s; exact (hasDerivAt_re_mul_cexp A c s).deriv
  have hd2 : deriv (deriv (steadySwing b k F₀ ξ₀)) =
      fun s : ℝ => (A * c * c * cexp (c * s)).re := by
    rw [hd1]; funext s; exact (hasDerivAt_re_mul_cexp (A * c) c s).deriv
  have hnormA : ‖A‖ = |F₀| / ‖oscSymbol b k ξ₀‖ := by
    rw [hA, norm_div, Complex.norm_real, Real.norm_eq_abs]
  have hnorme : ∀ s : ℝ, ‖cexp (c * s)‖ = 1 := by
    intro s
    rw [Complex.norm_exp]
    simp [hc]
  refine ⟨?_, ?_, ?_⟩
  · intro t
    rw [hd2, hd1, hfun]
    simp only
    have hAP : A * (c * c + b * c + k) = F₀ := by
      rw [hA]
      have : c * c + b * c + k = oscSymbol b k ξ₀ := by
        rw [oscSymbol, hc]; ring
      rw [this]
      field_simp
    calc (A * c * c * cexp (c * t)).re + b * (A * c * cexp (c * t)).re + k * (A * cexp (c * t)).re
        = (A * (c * c + b * c + k) * cexp (c * t)).re := by
          rw [← Complex.re_ofReal_mul, ← Complex.re_ofReal_mul, ← Complex.add_re,
            ← Complex.add_re]
          congr 1; ring
      _ = F₀ * Real.cos (2 * π * ξ₀ * t) := by
          rw [hAP, Complex.re_ofReal_mul, Complex.exp_re]
          congr 1
          have hre : (c * t).re = 0 := by simp [hc]
          have him : (c * t).im = 2 * π * ξ₀ * t := by simp [hc]
          rw [hre, him, Real.exp_zero, one_mul]
  · intro t
    rw [hfun, ← hnormA]
    calc |(A * cexp (c * t)).re| ≤ ‖A * cexp (c * t)‖ := Complex.abs_re_le_norm _
      _ = ‖A‖ := by rw [norm_mul, hnorme, mul_one]
  · rw [← hnormA, hfun]
    by_cases hξ : ξ₀ = 0
    · refine ⟨0, ?_⟩
      have hAr : A = ((F₀ / k : ℝ) : ℂ) := by
        rw [hA, oscSymbol, hξ]; push_cast; ring
      rw [hAr]
      simp [Complex.norm_real, abs_div]
    · refine ⟨-(arg A) / (2 * π * ξ₀), ?_⟩
      have hξc : (ξ₀ : ℂ) ≠ 0 := by exact_mod_cast hξ
      have hπc : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
      have hct : c * ((-(arg A) / (2 * π * ξ₀) : ℝ) : ℂ) = -(arg A : ℂ) * I := by
        rw [hc]; push_cast
        field_simp
      show |(A * cexp (c * ((-(arg A) / (2 * π * ξ₀) : ℝ) : ℂ))).re| = ‖A‖
      rw [hct]
      have : A * cexp (-(arg A : ℂ) * I) = (‖A‖ : ℂ) := by
        conv_lhs => rw [← Complex.norm_mul_exp_arg_mul_I A]
        rw [mul_assoc, ← Complex.exp_add]
        simp
      rw [this, Complex.ofReal_re, abs_of_nonneg (norm_nonneg _)]

/-! The card's exact worked numbers. -/

-- Six hours from dawn to noon, in seconds.
example : (6 : ℕ) * 3600 = 21600 := by norm_num

-- The bell's variance at noon: 2κt with κ = 1/80000 m²/s and t = 21600 s is 27/50 m² (0.54).
example : (2 : ℚ) * (1 / 80000) * 21600 = 27 / 50 := by norm_num

-- The tent's area, the total extra heat: 40 °C × 1/2 m = 20 °C·m.
example : (40 : ℚ) * (1 / 2) = 20 := by norm_num

-- Spreads add: the tent's variance a²/6 = 1/24 plus 27/50 gives 349/600 m² (0.581667).
example : ((1 : ℚ) / 2) ^ 2 / 6 + 27 / 50 = 349 / 600 := by norm_num

-- The mirror image sits 2d = 2 × 3/5 = 6/5 m away (1.2 m).
example : (2 : ℚ) * (3 / 5) = 6 / 5 := by norm_num

-- The roots of s² + 2s + 5 are −1 ± 2i.
example : ((-1 + 2 * I : ℂ)) ^ 2 + 2 * (-1 + 2 * I) + 5 = 0 := by
  ring_nf; rw [I_sq]; ring
example : ((-1 - 2 * I : ℂ)) ^ 2 + 2 * (-1 - 2 * I) + 5 = 0 := by
  ring_nf; rw [I_sq]; ring

#print axioms gauss_fubini_raw
#print axioms gauss_fubini
#print axioms heat_c_pos
#print axioms hbt_eq
#print axioms kernel_eq
#print axioms heat_part2
#print axioms heat_part3
#print axioms integrable_abs_pow_mul_gauss
#print axioms int_of_gauss_bound
#print axioms fourier_cont
#print axioms norm_osc
#print axioms heat_part1
#print axioms hasDerivAt_re_mul_cexp
#print axioms transform_turns_equation_into_division_by_symbol
#print axioms heat_by_transform_solves_heat_equation
#print axioms steady_swing_by_one_division
