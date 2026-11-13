-- Several Brownian motions: mixing two independent Brownian motions with weights rho and sqrt(1 - rho^2) gives a Brownian motion with covariance rho times time, the summed products of their matching steps converge to rho T in mean square, and Ito's formula for a product of two shares gives the drift mu1 + mu2 + rho sigma1 sigma2.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Covariance
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Filter Topology
open scoped NNReal ENNReal

/-! Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion under `P`:
it starts at 0, its increments are independent, an increment over a stretch of length `h` is
normal with mean 0 and variance `h`, and its paths are continuous almost surely.

Mathlib has no Ito integral, so the card's multidimensional Ito formula for general Ito
processes cannot be stated here. This file states the parts the card proves in full: the
Cholesky construction, the rule `dW¹ dW² = ρ dt`, and the formula's drift for the product
of two shares. -/

/-- The card's Cholesky mix: `W²_t = ρ Z¹_t + √(1 - ρ²) Z²_t`. -/
noncomputable def choleskyMix {Ω : Type*} (Z₁ Z₂ : ℝ≥0 → Ω → ℝ) (ρ : ℝ) (t : ℝ≥0) (ω : Ω) : ℝ :=
  ρ * Z₁ t ω + √(1 - ρ ^ 2) * Z₂ t ω

/-- The card's covariation sum: cut the stretch from `0` to `T` into `n` equal steps at the
times `t_k = k T / n`, multiply the matching moves of the two processes and add the products. -/
noncomputable def crossSum {Ω : Type*} (W₁ W₂ : ℝ≥0 → Ω → ℝ) (T : ℝ≥0) (n : ℕ) (ω : Ω) : ℝ :=
  ∑ k ∈ Finset.range n,
    (W₁ ((k + 1 : ℕ) * T / n) ω - W₁ ((k : ℕ) * T / n) ω) *
      (W₂ ((k + 1 : ℕ) * T / n) ω - W₂ ((k : ℕ) * T / n) ω)

lemma indep_eval {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {Z₁ Z₂ : ℝ≥0 → Ω → ℝ}
    (hind : IndepFun (fun ω t => Z₁ t ω) (fun ω t => Z₂ t ω) P) (s t : ℝ≥0) :
    IndepFun (Z₁ s) (Z₂ t) P := by
  have hs : Measurable (fun x : ℝ≥0 → ℝ => x s) := measurable_pi_apply s
  have ht : Measurable (fun x : ℝ≥0 → ℝ => x t) := measurable_pi_apply t
  exact hind.comp hs ht

lemma gaussian_moments (v : ℝ≥0) :
    ∫ x, x ^ 2 ∂gaussianReal 0 v = v ∧ ∫ x, x ^ 4 ∂gaussianReal 0 v = 3 * (v : ℝ) ^ 2 := by
  have h0 : (0 : ℝ) ∈ interior (integrableExpSet (fun x : ℝ => x) (gaussianReal 0 v)) := by simp
  have hm2 := iteratedDeriv_mgf_zero h0 2
  have hm4 := iteratedDeriv_mgf_zero h0 4
  rw [mgf_fun_id_gaussianReal] at hm2 hm4
  set E : ℝ → ℝ := fun t => Real.exp (0 * t + v * t ^ 2 / 2) with hEdef
  have hE : ∀ t, HasDerivAt E (v * t * E t) t := by
    intro t
    have h1 : HasDerivAt (fun t : ℝ => 0 * t + v * t ^ 2 / 2) (v * t) t := by
      have := ((hasDerivAt_id t).const_mul 0).add (((hasDerivAt_pow 2 t).const_mul (v : ℝ)).div_const 2)
      convert this using 1
      · funext s; simp
      · simp; ring
    have := h1.exp
    convert this using 1
    ring
  have key : ∀ (p p' : ℝ → ℝ), (∀ t, HasDerivAt p (p' t) t) →
      deriv (fun t => p t * E t) = fun t => (p' t + p t * (v * t)) * E t := by
    intro p p' hp
    ext t
    rw [((hp t).fun_mul (hE t)).deriv]
    ring
  have d1 : deriv E = fun t => (v * t) * E t := by
    ext t; rw [(hE t).deriv]
  have d2 : deriv (fun t => (v * t) * E t) = fun t => ((v : ℝ) + v ^ 2 * t ^ 2) * E t := by
    rw [key (fun t => v * t) (fun _ => v) (fun t => by simpa using (hasDerivAt_id t).const_mul (v : ℝ))]
    ext t; ring
  have d3 : deriv (fun t => ((v : ℝ) + v ^ 2 * t ^ 2) * E t)
      = fun t => (3 * (v : ℝ) ^ 2 * t + v ^ 3 * t ^ 3) * E t := by
    rw [key (fun t => (v : ℝ) + v ^ 2 * t ^ 2) (fun t => v ^ 2 * (2 * t))
      (fun t => by
        have := ((hasDerivAt_pow 2 t).const_mul ((v : ℝ) ^ 2)).const_add (v : ℝ)
        convert this using 1; simp)]
    ext t; ring
  have d4 : deriv (fun t => (3 * (v : ℝ) ^ 2 * t + v ^ 3 * t ^ 3) * E t)
      = fun t => (3 * (v : ℝ) ^ 2 + v ^ 3 * (3 * t ^ 2) + (3 * (v : ℝ) ^ 2 * t + v ^ 3 * t ^ 3) * (v * t)) * E t := by
    rw [key (fun t => 3 * (v : ℝ) ^ 2 * t + v ^ 3 * t ^ 3) (fun t => 3 * (v : ℝ) ^ 2 + v ^ 3 * (3 * t ^ 2))
      (fun t => by
        have := ((hasDerivAt_id t).const_mul (3 * (v : ℝ) ^ 2)).add
          ((hasDerivAt_pow 3 t).const_mul ((v : ℝ) ^ 3))
        convert this using 1
        · funext s; simp
        · simp)]
  have hE0 : E 0 = 1 := by simp [hEdef]
  constructor
  · have : iteratedDeriv 2 E 0 = v := by
      rw [iteratedDeriv_eq_iterate]
      simp only [Function.iterate_succ, Function.iterate_zero, Function.comp_apply, id]
      rw [d1, d2]; simp [hE0]
    rw [← this, hm2]
    rfl
  · have : iteratedDeriv 4 E 0 = 3 * (v : ℝ) ^ 2 := by
      rw [iteratedDeriv_eq_iterate]
      simp only [Function.iterate_succ, Function.iterate_zero, Function.comp_apply, id]
      rw [d1, d2, d3, d4]; simp [hE0]
    rw [← this, hm4]
    rfl

lemma law_moments {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ} {v : ℝ≥0}
    (hX : HasLaw X (gaussianReal 0 v) P) :
    (∀ p : ℕ, Integrable (fun ω => X ω ^ p) P) ∧ ∫ ω, X ω ∂P = 0 ∧
      ∫ ω, X ω ^ 2 ∂P = v ∧ ∫ ω, X ω ^ 4 ∂P = 3 * (v : ℝ) ^ 2 := by
  have h0 : (0 : ℝ) ∈ interior (integrableExpSet (fun x : ℝ => x) (gaussianReal 0 v)) := by simp
  have hint : ∀ p : ℕ, Integrable (fun x : ℝ => x ^ p) (gaussianReal 0 v) :=
    integrable_pow_of_mem_interior_integrableExpSet h0
  have hval : ∀ p : ℕ, ∫ ω, X ω ^ p ∂P = ∫ x, x ^ p ∂gaussianReal 0 v := fun p =>
    hX.integral_comp (f := fun x : ℝ => x ^ p) (by fun_prop)
  obtain ⟨m2, m4⟩ := gaussian_moments v
  refine ⟨fun p => hX.integrable_fun_comp (hint p), ?_, ?_, ?_⟩
  · have := hval 1
    simp only [pow_one] at this
    rw [this, integral_id_gaussianReal]
  · rw [hval, m2]
  · rw [hval, m4]

lemma step_moments {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {a b : Ω → ℝ} {v : ℝ≥0}
    (ha : HasLaw a (gaussianReal 0 v) P) (hb : HasLaw b (gaussianReal 0 v) P)
    (hab : IndepFun a b P) (ρ c : ℝ) (hc2 : c ^ 2 = 1 - ρ ^ 2) :
    MemLp (fun ω => a ω * (ρ * a ω + c * b ω)) 2 P ∧
      ∫ ω, a ω * (ρ * a ω + c * b ω) ∂P = ρ * v ∧
      Var[fun ω => a ω * (ρ * a ω + c * b ω); P] = (1 + ρ ^ 2) * (v : ℝ) ^ 2 := by
  have hP : IsProbabilityMeasure P := ha.isProbabilityMeasure
  obtain ⟨ia, a1, a2, a4⟩ := law_moments ha
  obtain ⟨ib, b1, b2, b4⟩ := law_moments hb
  have prod : ∀ i j : ℕ, Integrable (fun ω => a ω ^ i * b ω ^ j) P ∧
      ∫ ω, a ω ^ i * b ω ^ j ∂P = (∫ ω, a ω ^ i ∂P) * ∫ ω, b ω ^ j ∂P := by
    intro i j
    have hind : IndepFun (fun ω => a ω ^ i) (fun ω => b ω ^ j) P :=
      hab.comp (φ := fun x : ℝ => x ^ i) (ψ := fun x : ℝ => x ^ j) (by fun_prop) (by fun_prop)
    exact ⟨hind.integrable_mul (ia i) (ib j),
      hind.integral_fun_mul_eq_mul_integral (ia i).aestronglyMeasurable
        (ib j).aestronglyMeasurable⟩
  have hw : (fun ω => a ω * (ρ * a ω + c * b ω))
      = fun ω => ρ * (a ω ^ 2 * b ω ^ 0) + c * (a ω ^ 1 * b ω ^ 1) := by
    funext ω; ring
  have hw2 : (fun ω => (a ω * (ρ * a ω + c * b ω)) ^ 2)
      = fun ω => ρ ^ 2 * (a ω ^ 4 * b ω ^ 0) + (2 * ρ * c * (a ω ^ 3 * b ω ^ 1)
        + c ^ 2 * (a ω ^ 2 * b ω ^ 2)) := by
    funext ω; ring
  have iw : Integrable (fun ω => a ω * (ρ * a ω + c * b ω)) P := by
    rw [hw]; exact ((prod 2 0).1.const_mul ρ).add ((prod 1 1).1.const_mul c)
  have iw2 : Integrable (fun ω => (a ω * (ρ * a ω + c * b ω)) ^ 2) P := by
    rw [hw2]
    exact ((prod 4 0).1.const_mul _).add (((prod 3 1).1.const_mul _).add ((prod 2 2).1.const_mul _))
  have Ew : ∫ ω, a ω * (ρ * a ω + c * b ω) ∂P = ρ * v := by
    rw [hw, integral_add ((prod 2 0).1.const_mul ρ) ((prod 1 1).1.const_mul c),
      integral_const_mul, integral_const_mul, (prod 2 0).2, (prod 1 1).2]
    simp only [pow_zero, integral_const, probReal_univ, smul_eq_mul, mul_one, pow_one, a2, a1, b1]
    ring
  have Ew2 : ∫ ω, (a ω * (ρ * a ω + c * b ω)) ^ 2 ∂P = 3 * ρ ^ 2 * v ^ 2 + c ^ 2 * v ^ 2 := by
    have i3 : Integrable (fun ω => 2 * ρ * c * (a ω ^ 3 * b ω ^ 1)
        + c ^ 2 * (a ω ^ 2 * b ω ^ 2)) P :=
      ((prod 3 1).1.const_mul _).add ((prod 2 2).1.const_mul _)
    rw [hw2, integral_add ((prod 4 0).1.const_mul _) i3,
      integral_add ((prod 3 1).1.const_mul _) ((prod 2 2).1.const_mul _),
      integral_const_mul, integral_const_mul, integral_const_mul, (prod 4 0).2, (prod 3 1).2,
      (prod 2 2).2]
    simp only [pow_zero, integral_const, probReal_univ, smul_eq_mul, mul_one, pow_one, a2, a4,
      b1, b2]
    ring
  have mw : MemLp (fun ω => a ω * (ρ * a ω + c * b ω)) 2 P :=
    (memLp_two_iff_integrable_sq iw.aestronglyMeasurable).2 iw2
  refine ⟨mw, Ew, ?_⟩
  rw [variance_eq_sub mw]
  simp only [Pi.pow_apply]
  rw [Ew2, Ew, hc2]
  ring

lemma pair_gaussian {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {Z₁ Z₂ : ℝ≥0 → Ω → ℝ} (hZ₁ : IsBrownianReal Z₁ P) (hZ₂ : IsBrownianReal Z₂ P)
    (hind : IndepFun (fun ω t => Z₁ t ω) (fun ω t => Z₂ t ω) P) (K : Finset ℝ≥0) :
    HasGaussianLaw (fun ω => (K.restrict (Z₁ · ω), K.restrict (Z₂ · ω))) P :=
  IndepFun.hasGaussianLaw (hZ₁.isGaussianProcess.hasGaussianLaw K)
    (hZ₂.isGaussianProcess.hasGaussianLaw K)
    (hind.comp (φ := fun x => K.restrict x) (ψ := fun x => K.restrict x)
      (Finset.measurable_restrict _) (Finset.measurable_restrict _))

lemma indep_incr {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {Z₁ Z₂ : ℝ≥0 → Ω → ℝ}
    (hind : IndepFun (fun ω t => Z₁ t ω) (fun ω t => Z₂ t ω) P) (s₀ s₁ t₀ t₁ : ℝ≥0) :
    IndepFun (fun ω => Z₁ s₁ ω - Z₁ s₀ ω) (fun ω => Z₂ t₁ ω - Z₂ t₀ ω) P := by
  have hs : Measurable (fun x : ℝ≥0 → ℝ => x s₁ - x s₀) :=
    (measurable_pi_apply s₁).sub (measurable_pi_apply s₀)
  have ht : Measurable (fun x : ℝ≥0 → ℝ => x t₁ - x t₀) :=
    (measurable_pi_apply t₁).sub (measurable_pi_apply t₀)
  exact hind.comp hs ht

lemma brownian_incr_cov {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {s₀ s₁ t₀ t₁ : ℝ≥0}
    (h01 : s₀ ≤ s₁) (h1 : s₁ ≤ t₀) (h2 : t₀ ≤ t₁) :
    cov[fun ω => B s₁ ω - B s₀ ω, fun ω => B t₁ ω - B t₀ ω; P] = 0 := by
  have hP : IsProbabilityMeasure P := hB.isGaussianProcess.isProbabilityMeasure
  have m : ∀ t, MemLp (B t) 2 P := fun t => (hB.isGaussianProcess.hasGaussianLaw_eval t).memLp_two
  rw [covariance_fun_sub_fun_sub (m _) (m _) (m _) (m _), hB.covariance_eval, hB.covariance_eval,
    hB.covariance_eval, hB.covariance_eval, min_eq_left (h1.trans h2), min_eq_left h1,
    min_eq_left ((h01.trans h1).trans h2), min_eq_left (h01.trans h1)]
  ring

lemma step_indep {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {Z₁ Z₂ : ℝ≥0 → Ω → ℝ} (hZ₁ : IsBrownianReal Z₁ P) (hZ₂ : IsBrownianReal Z₂ P)
    (hind : IndepFun (fun ω t => Z₁ t ω) (fun ω t => Z₂ t ω) P) (ρ c : ℝ)
    {s₀ s₁ t₀ t₁ : ℝ≥0} (h01 : s₀ ≤ s₁) (h1 : s₁ ≤ t₀) (h2 : t₀ ≤ t₁) :
    IndepFun (fun ω => (Z₁ s₁ ω - Z₁ s₀ ω) * (ρ * (Z₁ s₁ ω - Z₁ s₀ ω) + c * (Z₂ s₁ ω - Z₂ s₀ ω)))
      (fun ω => (Z₁ t₁ ω - Z₁ t₀ ω) * (ρ * (Z₁ t₁ ω - Z₁ t₀ ω) + c * (Z₂ t₁ ω - Z₂ t₀ ω))) P := by
  have hP : IsProbabilityMeasure P := hZ₁.isGaussianProcess.isProbabilityMeasure
  have m1 : ∀ t, MemLp (Z₁ t) 2 P := fun t => (hZ₁.isGaussianProcess.hasGaussianLaw_eval t).memLp_two
  have m2 : ∀ t, MemLp (Z₂ t) 2 P := fun t => (hZ₂.isGaussianProcess.hasGaussianLaw_eval t).memLp_two
  let X : Fin 2 → Ω → ℝ := ![fun ω => Z₁ s₁ ω - Z₁ s₀ ω, fun ω => Z₂ s₁ ω - Z₂ s₀ ω]
  let Y : Fin 2 → Ω → ℝ := ![fun ω => Z₁ t₁ ω - Z₁ t₀ ω, fun ω => Z₂ t₁ ω - Z₂ t₀ ω]
  let K : Finset ℝ≥0 := {s₀, s₁, t₀, t₁}
  have k0 : s₀ ∈ K := by simp [K]
  have k1 : s₁ ∈ K := by simp [K]
  have k2 : t₀ ∈ K := by simp [K]
  have k3 : t₁ ∈ K := by simp [K]
  let L : ((K → ℝ) × (K → ℝ)) →L[ℝ] ((Fin 2 → ℝ) × (Fin 2 → ℝ)) :=
    { toFun p := (![p.1 ⟨s₁, k1⟩ - p.1 ⟨s₀, k0⟩, p.2 ⟨s₁, k1⟩ - p.2 ⟨s₀, k0⟩],
        ![p.1 ⟨t₁, k3⟩ - p.1 ⟨t₀, k2⟩, p.2 ⟨t₁, k3⟩ - p.2 ⟨t₀, k2⟩])
      map_add' x y := by
        ext i <;> fin_cases i <;> simp <;> ring
      map_smul' r x := by
        ext i <;> fin_cases i <;> simp <;> ring }
  have hG : HasGaussianLaw (fun ω => (fun i => X i ω, fun j => Y j ω)) P := by
    have := (pair_gaussian hZ₁ hZ₂ hind K).map_fun L
    convert this using 2 with ω
    ext i <;> fin_cases i <;> simp [X, Y, L]
  have hcov : ∀ i j, cov[X i, Y j; P] = 0 := by
    intro i j
    fin_cases i <;> fin_cases j
    · exact brownian_incr_cov hZ₁ h01 h1 h2
    · exact (indep_incr hind s₀ s₁ t₀ t₁).covariance_eq_zero ((m1 _).sub (m1 _))
        ((m2 _).sub (m2 _))
    · show cov[fun ω => Z₂ s₁ ω - Z₂ s₀ ω, fun ω => Z₁ t₁ ω - Z₁ t₀ ω; P] = 0
      rw [covariance_comm]
      exact (indep_incr hind t₀ t₁ s₀ s₁).covariance_eq_zero ((m1 _).sub (m1 _))
        ((m2 _).sub (m2 _))
    · exact brownian_incr_cov hZ₂ h01 h1 h2
  have hI := hG.indepFun_of_covariance_eval hcov
  have hg : Measurable (fun v : Fin 2 → ℝ => v 0 * (ρ * v 0 + c * v 1)) := by fun_prop
  exact hI.comp hg hg

lemma cross_core {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {Z₁ Z₂ : ℝ≥0 → Ω → ℝ} (hZ₁ : IsBrownianReal Z₁ P) (hZ₂ : IsBrownianReal Z₂ P)
    (hind : IndepFun (fun ω t => Z₁ t ω) (fun ω t => Z₂ t ω) P) (ρ c : ℝ)
    (hc2 : c ^ 2 = 1 - ρ ^ 2) (tk : ℕ → ℝ≥0) (hmono : Monotone tk) (v : ℝ≥0)
    (hv : ∀ k, nndist (tk (k + 1) : ℝ) (tk k : ℝ) = v) (n : ℕ) (W : ℕ → Ω → ℝ)
    (hW : ∀ k ω, W k ω = (Z₁ (tk (k + 1)) ω - Z₁ (tk k) ω) *
      (ρ * (Z₁ (tk (k + 1)) ω - Z₁ (tk k) ω) + c * (Z₂ (tk (k + 1)) ω - Z₂ (tk k) ω))) :
    ∫ ω, (∑ k ∈ Finset.range n, W k ω) ∂P = n * (ρ * v) ∧
      ∫ ω, (∑ k ∈ Finset.range n, W k ω - n * (ρ * v)) ^ 2 ∂P
        = n * ((1 + ρ ^ 2) * (v : ℝ) ^ 2) := by
  have hP : IsProbabilityMeasure P := hZ₁.isGaussianProcess.isProbabilityMeasure
  have hWf : ∀ k, W k = fun ω => (Z₁ (tk (k + 1)) ω - Z₁ (tk k) ω) *
      (ρ * (Z₁ (tk (k + 1)) ω - Z₁ (tk k) ω) + c * (Z₂ (tk (k + 1)) ω - Z₂ (tk k) ω)) :=
    fun k => funext (hW k)
  have step : ∀ k, MemLp (W k) 2 P ∧ ∫ ω, W k ω ∂P = ρ * v ∧
      Var[W k; P] = (1 + ρ ^ 2) * (v : ℝ) ^ 2 := by
    intro k
    have la : HasLaw (fun ω => Z₁ (tk (k + 1)) ω - Z₁ (tk k) ω) (gaussianReal 0 v) P := by
      have := hZ₁.hasLaw_sub (tk (k + 1)) (tk k)
      rw [← hv k]; exact this
    have lb : HasLaw (fun ω => Z₂ (tk (k + 1)) ω - Z₂ (tk k) ω) (gaussianReal 0 v) P := by
      have := hZ₂.hasLaw_sub (tk (k + 1)) (tk k)
      rw [← hv k]; exact this
    rw [hWf k]
    exact step_moments la lb (indep_incr hind _ _ _ _) ρ c hc2
  have hsum : (fun ω => ∑ k ∈ Finset.range n, W k ω) = ∑ k ∈ Finset.range n, W k := by
    funext ω; simp [Finset.sum_apply]
  have hE : ∫ ω, (∑ k ∈ Finset.range n, W k ω) ∂P = n * (ρ * v) := by
    rw [integral_finsetSum _ (fun k _ => (step k).1.integrable one_le_two)]
    simp [(step _).2.1]
  have hVar : Var[∑ k ∈ Finset.range n, W k; P] = n * ((1 + ρ ^ 2) * (v : ℝ) ^ 2) := by
    rw [IndepFun.variance_sum (fun k _ => (step k).1)]
    · simp [(step _).2.2]
    · intro j _ k _ hjk
      rw [hWf j, hWf k]
      rcases lt_or_gt_of_ne hjk with h | h
      · exact step_indep hZ₁ hZ₂ hind ρ c (hmono (Nat.le_succ j)) (hmono h) (hmono (Nat.le_succ k))
      · exact (step_indep hZ₁ hZ₂ hind ρ c (hmono (Nat.le_succ k)) (hmono h)
          (hmono (Nat.le_succ j))).symm
  refine ⟨hE, ?_⟩
  have hm : MemLp (∑ k ∈ Finset.range n, W k) 2 P := memLp_finsetSum' _ (fun k _ => (step k).1)
  rw [← hVar, variance_eq_integral hm.aemeasurable, ← hsum, hE]

/-- Correlated Brownian motions, built by Cholesky (Steps 0 and 1 of the card). Take two
independent Brownian motions `Z¹` and `Z²` and a correlation `ρ` between `-1` and `1`.
Then `W² = ρ Z¹ + √(1 - ρ²) Z²` is again a Brownian motion, and its covariance with
`W¹ = Z¹` is `ρ` times time: `Cov(W¹_s, W²_t) = ρ min(s, t)`, so `Cov(W¹_t, W²_t) = ρ t`. -/
theorem cholesky_mix_is_brownian_with_correlation {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {Z₁ Z₂ : ℝ≥0 → Ω → ℝ} (hZ₁ : IsBrownianReal Z₁ P) (hZ₂ : IsBrownianReal Z₂ P)
    (hind : IndepFun (fun ω t => Z₁ t ω) (fun ω t => Z₂ t ω) P)
    (ρ : ℝ) (hρ : -1 ≤ ρ ∧ ρ ≤ 1) :
    IsBrownianReal (choleskyMix Z₁ Z₂ ρ) P ∧
      ∀ s t : ℝ≥0, cov[Z₁ s, choleskyMix Z₁ Z₂ ρ t; P] = ρ * min (s : ℝ) t := by
  have hP : IsProbabilityMeasure P := hZ₁.isGaussianProcess.isProbabilityMeasure
  set c := √(1 - ρ ^ 2) with hc
  have hc2 : c ^ 2 = 1 - ρ ^ 2 := by
    rw [hc, Real.sq_sqrt]; nlinarith
  have m1 : ∀ t, MemLp (Z₁ t) 2 P := fun t => (hZ₁.isGaussianProcess.hasGaussianLaw_eval t).memLp_two
  have m2 : ∀ t, MemLp (Z₂ t) 2 P := fun t => (hZ₂.isGaussianProcess.hasGaussianLaw_eval t).memLp_two
  have hX : ∀ t, choleskyMix Z₁ Z₂ ρ t = (fun ω => ρ * Z₁ t ω) + (fun ω => c * Z₂ t ω) := by
    intro t; rfl
  have mX : ∀ t, MemLp (choleskyMix Z₁ Z₂ ρ t) 2 P := fun t => by
    rw [hX]; exact ((m1 t).const_mul ρ).add ((m2 t).const_mul c)
  have hcov : ∀ s t : ℝ≥0, cov[Z₁ s, choleskyMix Z₁ Z₂ ρ t; P] = ρ * min (s : ℝ) t := by
    intro s t
    rw [hX, covariance_add_right (m1 s) ((m1 t).const_mul ρ) ((m2 t).const_mul c),
      covariance_const_mul_right, covariance_const_mul_right, hZ₁.covariance_eval,
      (indep_eval hind s t).covariance_eq_zero (m1 s) (m2 t)]
    simp
  refine ⟨⟨?_, ?_⟩, hcov⟩
  · refine IsGaussianProcess.isPreBrownianReal_of_covariance ?_ ?_ ?_
    · constructor
      intro I
      have hU : HasGaussianLaw (fun ω => (I.restrict (Z₁ · ω), I.restrict (Z₂ · ω))) P :=
        IndepFun.hasGaussianLaw (hZ₁.isGaussianProcess.hasGaussianLaw I)
          (hZ₂.isGaussianProcess.hasGaussianLaw I)
          (hind.comp (φ := fun x => I.restrict x) (ψ := fun x => I.restrict x)
            (Finset.measurable_restrict _) (Finset.measurable_restrict _))
      have := hU.map_fun (ρ • ContinuousLinearMap.fst ℝ (I → ℝ) (I → ℝ)
        + c • ContinuousLinearMap.snd ℝ (I → ℝ) (I → ℝ))
      convert this using 2 with ω
      ext i
      simp [choleskyMix, hc]
    · intro t
      show ∫ ω, (ρ * Z₁ t ω + c * Z₂ t ω) ∂P = 0
      rw [integral_add ((m1 t).integrable one_le_two |>.const_mul ρ)
        ((m2 t).integrable one_le_two |>.const_mul c), integral_const_mul, integral_const_mul,
        hZ₁.integral_eval, hZ₂.integral_eval]
      simp
    · intro s t hst
      rw [hX s, covariance_add_left ((m1 s).const_mul ρ) ((m2 s).const_mul c) (mX t),
        covariance_const_mul_left, covariance_const_mul_left, hcov,
        hX t, covariance_add_right (m2 s) ((m1 t).const_mul ρ) ((m2 t).const_mul c),
        covariance_const_mul_right, covariance_const_mul_right, hZ₂.covariance_eval]
      have h0 : cov[Z₂ s, Z₁ t; P] = 0 := by
        rw [covariance_comm]; exact (indep_eval hind t s).covariance_eq_zero (m1 t) (m2 s)
      rw [h0]
      have hm : min (s : ℝ) t = s := min_eq_left (by exact_mod_cast hst)
      have hm' : ((min s t : ℝ≥0) : ℝ) = s := by rw [min_eq_left hst]
      rw [hm, hm']
      linear_combination (s : ℝ) * hc2
  · filter_upwards [hZ₁.cont, hZ₂.cont] with ω h1 h2
    unfold choleskyMix
    fun_prop

/-- Two correlated noises multiply to their correlation per unit of time (Step 2 of the card):
`[W¹, W²]_T = ρ T`. With `W¹ = Z¹` and `W² = ρ Z¹ + √(1 - ρ²) Z²` as above, and `n ≥ 1`
equal steps of the stretch from `0` to `T`, the sum of products of matching moves averages
exactly `ρ T`, its mean squared error is `(1 + ρ²) T² / n`, and so it converges to `ρ T`
in mean square as the grid gets finer. -/
theorem cross_sum_tendsto_rho_mul_time {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {Z₁ Z₂ : ℝ≥0 → Ω → ℝ} (hZ₁ : IsBrownianReal Z₁ P) (hZ₂ : IsBrownianReal Z₂ P)
    (hind : IndepFun (fun ω t => Z₁ t ω) (fun ω t => Z₂ t ω) P)
    (ρ : ℝ) (hρ : -1 ≤ ρ ∧ ρ ≤ 1) (T : ℝ≥0) :
    (∀ n : ℕ, 1 ≤ n →
        ∫ ω, crossSum Z₁ (choleskyMix Z₁ Z₂ ρ) T n ω ∂P = ρ * T ∧
        ∫ ω, (crossSum Z₁ (choleskyMix Z₁ Z₂ ρ) T n ω - ρ * T) ^ 2 ∂P
          = (1 + ρ ^ 2) * (T : ℝ) ^ 2 / n) ∧
      Tendsto (fun n : ℕ => ∫ ω, (crossSum Z₁ (choleskyMix Z₁ Z₂ ρ) T n ω - ρ * T) ^ 2 ∂P)
        atTop (𝓝 0) := by
  set c := √(1 - ρ ^ 2) with hc
  have hc2 : c ^ 2 = 1 - ρ ^ 2 := by
    rw [hc, Real.sq_sqrt]; nlinarith
  have main : ∀ n : ℕ, 1 ≤ n →
      ∫ ω, crossSum Z₁ (choleskyMix Z₁ Z₂ ρ) T n ω ∂P = ρ * T ∧
      ∫ ω, (crossSum Z₁ (choleskyMix Z₁ Z₂ ρ) T n ω - ρ * T) ^ 2 ∂P
        = (1 + ρ ^ 2) * (T : ℝ) ^ 2 / n := by
    intro n hn
    have hn0 : (n : ℝ) ≠ 0 := by positivity
    let tk : ℕ → ℝ≥0 := fun k => (k : ℝ≥0) * T / n
    have hmono : Monotone tk := by
      intro a b hab
      simp only [tk]
      gcongr
    have hv : ∀ k, nndist (tk (k + 1) : ℝ) (tk k : ℝ) = T / n := by
      intro k
      apply NNReal.eq
      rw [coe_nndist, Real.dist_eq]
      simp only [tk, NNReal.coe_div, NNReal.coe_mul, NNReal.coe_natCast]
      have : ((k + 1 : ℕ) : ℝ) * T / n - (k : ℝ) * T / n = T / n := by
        push_cast; ring
      rw [this, abs_of_nonneg (by positivity)]
    have hcs : ∀ ω, crossSum Z₁ (choleskyMix Z₁ Z₂ ρ) T n ω = ∑ k ∈ Finset.range n,
        (Z₁ (tk (k + 1)) ω - Z₁ (tk k) ω) *
          (ρ * (Z₁ (tk (k + 1)) ω - Z₁ (tk k) ω) + c * (Z₂ (tk (k + 1)) ω - Z₂ (tk k) ω)) := by
      intro ω
      unfold crossSum choleskyMix
      refine Finset.sum_congr rfl (fun k _ => ?_)
      simp only [tk, hc]
      ring
    obtain ⟨h1, h2⟩ := cross_core hZ₁ hZ₂ hind ρ c hc2 tk hmono (T / n) hv n _ (fun _ _ => rfl)
    have hvv : ((T / n : ℝ≥0) : ℝ) = T / n := by simp
    have hρT : (n : ℝ) * (ρ * ((T / n : ℝ≥0) : ℝ)) = ρ * T := by
      rw [hvv]; field_simp
    simp_rw [hcs]
    rw [hρT] at h1 h2
    refine ⟨h1, ?_⟩
    rw [h2, hvv]
    field_simp
  refine ⟨main, ?_⟩
  have hlim : Tendsto (fun n : ℕ => (1 + ρ ^ 2) * (T : ℝ) ^ 2 / n) atTop (𝓝 0) :=
    tendsto_const_div_atTop_nhds_zero_nat _
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  exact (main n hn).2.symm

/-- The product of two shares (Step 4 of the card). Take `f(x₁, x₂) = x₁ x₂` at prices
`A` and `B`, with drift sizes `μ₁ A`, `μ₂ B` and noise sizes `σ₁ A`, `σ₂ B`, and noise
correlation `ρ`. The `dt` part of the multidimensional Ito formula, each slope times its
drift plus half of every second slope (`f₁₁`, `f₁₂`, `f₂₁`, `f₂₂`) times the matching pair of
noise sizes and their correlation, equals `(μ₁ + μ₂ + ρ σ₁ σ₂) A B`. -/
theorem product_ito_drift (μ₁ μ₂ σ₁ σ₂ ρ A B : ℝ) :
    let f : ℝ → ℝ → ℝ := fun x₁ x₂ => x₁ * x₂
    (μ₁ * A) * deriv (fun x => f x B) A + (μ₂ * B) * deriv (fun y => f A y) B
      + (1 / 2) * ((σ₁ * A) * (σ₁ * A) * 1 * deriv (fun x => deriv (fun x' => f x' B) x) A
        + (σ₁ * A) * (σ₂ * B) * ρ * deriv (fun y => deriv (fun x => f x y) A) B
        + (σ₂ * B) * (σ₁ * A) * ρ * deriv (fun x => deriv (fun y => f x y) B) A
        + (σ₂ * B) * (σ₂ * B) * 1 * deriv (fun y => deriv (fun y' => f A y') y) B)
      = (μ₁ + μ₂ + ρ * σ₁ * σ₂) * (A * B) := by
  intro f
  have h1 : ∀ y, (fun x => f x y) = fun x => x * y := fun _ => rfl
  have h2 : ∀ x, (fun y => f x y) = fun y => x * y := fun _ => rfl
  have d1 : ∀ y, deriv (fun x => f x y) = fun _ => y := by
    intro y; rw [h1]; ext x; simp
  have d2 : ∀ x, deriv (fun y => f x y) = fun _ => x := by
    intro x; rw [h2]; ext y; simp
  simp only [d1, d2, deriv_const, deriv_id'']
  ring

/-! The card's worked numbers, as exact fractions: `μ₁ = 0.08 = 2/25`, `σ₁ = 0.20 = 1/5`,
`μ₂ = 0.05 = 1/20`, `σ₂ = 0.30 = 3/10`, `ρ = 0.5 = 1/2`, `A₀ = 100`, `B₀ = 50`. -/

-- Cholesky diagonal entry squared: 1 − 0.25 = 0.75, and the squares add, 0.25 + 0.75 = 1
example : (1 : ℚ) - (1 / 2) ^ 2 = 3 / 4 := by norm_num
example : ((1 : ℚ) / 2) ^ 2 + 3 / 4 = 1 := by norm_num
-- cross term: ρ σ₁ σ₂ = 0.5 × 0.20 × 0.30 = 0.03
example : (1 : ℚ) / 2 * (1 / 5) * (3 / 10) = 3 / 100 := by norm_num
-- drift of the product: 0.08 + 0.05 + 0.03 = 0.16, not 0.13
example : (2 : ℚ) / 25 + 1 / 20 + 1 / 2 * (1 / 5) * (3 / 10) = 4 / 25 := by norm_num
example : (2 : ℚ) / 25 + 1 / 20 = 13 / 100 := by norm_num
-- today's product: 100 × 50 = 5000
example : (100 : ℕ) * 50 = 5000 := by norm_num
-- product's variance per year: 0.04 + 0.09 + 2 × 0.03 = 0.19
example : ((1 : ℚ) / 5) ^ 2 + (3 / 10) ^ 2 + 2 * (1 / 2) * (1 / 5) * (3 / 10) = 19 / 100 := by
  norm_num
-- log drift: 0.16 − 0.19 / 2 = 0.065
example : (4 : ℚ) / 25 - (19 / 100) / 2 = 13 / 200 := by norm_num
-- ratio drift: 0.08 − 0.05 + 0.09 − 0.03 = 0.09
example : (2 : ℚ) / 25 - 1 / 20 + (3 / 10) ^ 2 - 1 / 2 * (1 / 5) * (3 / 10) = 9 / 100 := by
  norm_num
-- today's ratio: 100 / 50 = 2
example : (100 : ℚ) / 50 = 2 := by norm_num
-- wrong mix with weights ρ and 1 − ρ: variance 0.25 + 0.25 = 0.5, not 1
example : ((1 : ℚ) / 2) ^ 2 + (1 - 1 / 2) ^ 2 = 1 / 2 := by norm_num
-- one slice's product: average square ρ²·3 + c² = 1 + 2ρ², variance 1 + ρ², with c² = 1 − ρ²
example : ∀ ρ : ℚ, 3 * ρ ^ 2 + (1 - ρ ^ 2) - ρ ^ 2 = 1 + ρ ^ 2 := by intro ρ; ring

#print axioms cholesky_mix_is_brownian_with_correlation
#print axioms cross_sum_tendsto_rho_mul_time
#print axioms product_ito_drift
#print axioms indep_eval
#print axioms gaussian_moments
#print axioms law_moments
#print axioms step_moments
#print axioms pair_gaussian
#print axioms indep_incr
#print axioms brownian_incr_cov
#print axioms step_indep
#print axioms cross_core
