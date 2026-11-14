-- Options in the book: when Acme's move X is normal with spread s and the rest of the book W is an independent normal with spread v, the delta-gamma loss L = -(ΔX + ½ΓX²) - W has exactly the card's mean, variance, skew and excess kurtosis, and the Cornish-Fisher skew-squared term is -(2z³ - 5z)γ₁²/36.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.Probability.HasLaw

open MeasureTheory ProbabilityTheory NNReal

lemma dg_integrable_pow_gaussianReal (μ : ℝ) (v : ℝ≥0) (n : ℕ) :
    Integrable (fun x : ℝ => x ^ n) (gaussianReal μ v) :=
  integrable_pow_of_mem_interior_integrableExpSet (X := fun x : ℝ => x) (by simp) n

lemma dg_hasDerivAt_gaussianPDFReal (v : ℝ≥0) (x : ℝ) :
    HasDerivAt (gaussianPDFReal 0 v) (-(x / v) * gaussianPDFReal 0 v x) x := by
  have h1 : HasDerivAt (fun x : ℝ => -(x - 0) ^ 2 / (2 * (v : ℝ)))
      (-(2 * (x - 0) ^ 1 * 1) / (2 * (v : ℝ))) x :=
    (((hasDerivAt_id x).sub_const 0).pow 2).neg.div_const (2 * (v : ℝ))
  have h2 := (h1.exp).const_mul (√(2 * Real.pi * v))⁻¹
  rw [gaussianPDFReal_def]
  convert h2 using 1
  ring

lemma dg_integrable_pdf_mul_pow {v : ℝ≥0} (hv : v ≠ 0) (k : ℕ) :
    Integrable (fun x : ℝ => gaussianPDFReal 0 v x * x ^ k) := by
  have h := dg_integrable_pow_gaussianReal 0 v k
  rw [gaussianReal_of_var_ne_zero _ hv, integrable_withDensity_iff (measurable_gaussianPDF _ _)
    (ae_of_all _ fun _ => gaussianPDF_lt_top)] at h
  simpa [toReal_gaussianPDF, mul_comm] using h

lemma dg_moment_succ_succ (v : ℝ≥0) (n : ℕ) :
    ∫ x, x ^ (n + 2) ∂gaussianReal 0 v = (n + 1) * v * ∫ x, x ^ n ∂gaussianReal 0 v := by
  by_cases hv : v = 0
  · subst hv; simp
  rw [integral_gaussianReal_eq_integral_smul hv, integral_gaussianReal_eq_integral_smul hv]
  simp only [smul_eq_mul]
  have key := integral_mul_deriv_eq_deriv_mul_of_integrable
    (u := fun x : ℝ => x ^ (n + 1)) (u' := fun x : ℝ => ((n : ℝ) + 1) * x ^ n)
    (v := gaussianPDFReal 0 v) (v' := fun x => -(x / v) * gaussianPDFReal 0 v x)
    (fun x _ => by simpa using hasDerivAt_pow (n + 1) x)
    (fun x _ => dg_hasDerivAt_gaussianPDFReal v x)
    (by
      refine ((dg_integrable_pdf_mul_pow hv (n + 2)).const_mul (-(1 / (v : ℝ)))).congr ?_
      exact ae_of_all _ fun x => by simp only [Pi.mul_apply]; ring)
    (by
      refine ((dg_integrable_pdf_mul_pow hv n).const_mul ((n : ℝ) + 1)).congr ?_
      exact ae_of_all _ fun x => by simp only [Pi.mul_apply]; ring)
    (by
      refine (dg_integrable_pdf_mul_pow hv (n + 1)).congr ?_
      exact ae_of_all _ fun x => by simp only [Pi.mul_apply]; ring)
  have e1 : ∫ x : ℝ, x ^ (n + 1) * (-(x / v) * gaussianPDFReal 0 v x)
      = -(1 / (v : ℝ)) * ∫ x, gaussianPDFReal 0 v x * x ^ (n + 2) := by
    rw [← integral_const_mul]; congr 1; funext x; ring
  have e2 : ∫ x : ℝ, ((n : ℝ) + 1) * x ^ n * gaussianPDFReal 0 v x
      = ((n : ℝ) + 1) * ∫ x, gaussianPDFReal 0 v x * x ^ n := by
    rw [← integral_const_mul]; congr 1; funext x; ring
  rw [e1, e2] at key
  have hv' : (v : ℝ) ≠ 0 := by exact_mod_cast hv
  field_simp at key
  linear_combination -key

lemma dg_moment_zero (v : ℝ≥0) : ∫ x, x ^ 0 ∂gaussianReal 0 v = 1 := by simp
lemma dg_moment_one (v : ℝ≥0) : ∫ x, x ^ 1 ∂gaussianReal 0 v = 0 := by simp

lemma dg_moments (v : ℝ≥0) :
    ∫ x, x ^ 2 ∂gaussianReal 0 v = v ∧ ∫ x, x ^ 3 ∂gaussianReal 0 v = 0 ∧
    ∫ x, x ^ 4 ∂gaussianReal 0 v = 3 * v ^ 2 ∧ ∫ x, x ^ 5 ∂gaussianReal 0 v = 0 ∧
    ∫ x, x ^ 6 ∂gaussianReal 0 v = 15 * v ^ 3 ∧ ∫ x, x ^ 7 ∂gaussianReal 0 v = 0 ∧
    ∫ x, x ^ 8 ∂gaussianReal 0 v = 105 * v ^ 4 := by
  have h2 := dg_moment_succ_succ v 0
  have h3 := dg_moment_succ_succ v 1
  have h4 := dg_moment_succ_succ v 2
  have h5 := dg_moment_succ_succ v 3
  have h6 := dg_moment_succ_succ v 4
  have h7 := dg_moment_succ_succ v 5
  have h8 := dg_moment_succ_succ v 6
  rw [dg_moment_zero] at h2
  rw [dg_moment_one] at h3
  norm_num at h2 h3 h4 h5 h6 h7 h8
  refine ⟨h2, h3, ?_, ?_, ?_, ?_, ?_⟩
  · rw [h4, h2]; ring
  · rw [h5, h3]; ring
  · rw [h6, h4, h2]; ring
  · rw [h7, h5, h3]; ring
  · rw [h8, h6, h4, h2]; ring


lemma dg_hasLaw {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (volume : Measure Ω)]
    {X : Ω → ℝ} {v : ℝ≥0} (hv : v ≠ 0) (h : Measure.map X volume = gaussianReal 0 v) :
    HasLaw X (gaussianReal 0 v) volume := by
  refine ⟨?_, h⟩
  by_contra hX
  have hne : (volume : Measure Ω) ≠ 0 := IsProbabilityMeasure.ne_zero _
  rw [Measure.map_of_not_aemeasurable_of_ne_zero hX hne] at h
  obtain ⟨a, ha⟩ : ∃ a : ℝ, Measure.dirac a = gaussianReal 0 v := ⟨_, h⟩
  have := nullSingletonClass_gaussianReal (μ := 0) hv
  have := congrArg (fun m : Measure ℝ => m {a}) ha
  simp [measure_singleton] at this

lemma dg_integral_sum {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω} (s : Finset ι)
    (c : ι → ℝ) (f : ι → Ω → ℝ) (hf : ∀ i ∈ s, Integrable (f i) P) :
    ∫ ω, ∑ i ∈ s, c i * f i ω ∂P = ∑ i ∈ s, c i * ∫ ω, f i ω ∂P := by
  rw [integral_finsetSum s (fun i hi => (hf i hi).const_mul (c i))]
  simp_rw [integral_const_mul]

lemma dg_poly9 {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ} {v : ℝ≥0}
    (hX : HasLaw X (gaussianReal 0 v) P) (c : Fin 9 → ℝ) :
    ∫ ω, ∑ i : Fin 9, c i * X ω ^ (i : ℕ) ∂P
      = ∑ i : Fin 9, c i * ∫ x, x ^ (i : ℕ) ∂gaussianReal 0 v := by
  rw [dg_integral_sum Finset.univ c (fun i ω => X ω ^ (i : ℕ))
    (fun i _ => hX.integrable_comp (f := fun x : ℝ => x ^ (i : ℕ))
      (dg_integrable_pow_gaussianReal 0 v i))]
  congr 1; funext i; congr 1
  exact hX.integral_comp (f := fun x : ℝ => x ^ (i : ℕ)) (by fun_prop)

lemma dg_poly9_integrable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ}
    {v : ℝ≥0} (hX : HasLaw X (gaussianReal 0 v) P) (c : Fin 9 → ℝ) :
    Integrable (fun ω => ∑ i : Fin 9, c i * X ω ^ (i : ℕ)) P :=
  integrable_finsetSum _ (fun i _ => (hX.integrable_comp (f := fun x : ℝ => x ^ (i : ℕ))
    (dg_integrable_pow_gaussianReal 0 v i)).const_mul (c i))

lemma dg_indep_sum {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {U W : Ω → ℝ}
    (hUW : IndepFun U W P) (hUm : AEMeasurable U P) (hWm : AEMeasurable W P)
    {n : ℕ} (hU : ∀ j : Fin n, Integrable (fun ω => U ω ^ (j : ℕ)) P)
    (hW : ∀ j : ℕ, Integrable (fun ω => W ω ^ j) P) (d : Fin n → ℝ) (k : ℕ) :
    ∫ ω, ∑ j : Fin n, d j * (U ω ^ (j : ℕ) * W ω ^ (k - (j : ℕ))) ∂P
      = ∑ j : Fin n, d j * ((∫ ω, U ω ^ (j : ℕ) ∂P) * ∫ ω, W ω ^ (k - (j : ℕ)) ∂P) := by
  have hind : ∀ a b : ℕ, IndepFun (fun ω => U ω ^ a) (fun ω => W ω ^ b) P := fun a b =>
    hUW.comp (φ := fun x : ℝ => x ^ a) (ψ := fun x : ℝ => x ^ b) (by fun_prop) (by fun_prop)
  rw [dg_integral_sum Finset.univ d (fun j ω => U ω ^ (j : ℕ) * W ω ^ (k - (j : ℕ)))
    (fun j _ => (hind _ _).integrable_mul (hU _) (hW _))]
  congr 1; funext j; congr 1
  exact (hind _ _).integral_fun_mul_eq_mul_integral
    (hUm.pow_const _).aestronglyMeasurable (hWm.pow_const _).aestronglyMeasurable

lemma dg_loss_moments_core
    {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (volume : Measure Ω)]
    (Δ Γ : ℝ) (s v : ℝ≥0) (X W : Ω → ℝ)
    (hX : HasLaw X (gaussianReal 0 (s ^ 2)) volume)
    (hW : HasLaw W (gaussianReal 0 (v ^ 2)) volume)
    (hXW : IndepFun X W volume) :
    let L : Ω → ℝ := fun ω => -(Δ * X ω + Γ / 2 * X ω ^ 2) - W ω
    let σL2 : ℝ := Δ ^ 2 * (s : ℝ) ^ 2 + 1 / 2 * Γ ^ 2 * (s : ℝ) ^ 4 + (v : ℝ) ^ 2
    (∫ ω, L ω) = -(1 / 2) * Γ * (s : ℝ) ^ 2 ∧
    variance L volume = σL2 ∧
    centralMoment L 3 volume / Real.sqrt (variance L volume) ^ 3 =
      -(3 * Δ ^ 2 * Γ * (s : ℝ) ^ 4 + Γ ^ 3 * (s : ℝ) ^ 6) / Real.sqrt σL2 ^ 3 ∧
    (centralMoment L 4 volume - 3 * variance L volume ^ 2) / variance L volume ^ 2 =
      (12 * Δ ^ 2 * Γ ^ 2 * (s : ℝ) ^ 6 + 3 * Γ ^ 4 * (s : ℝ) ^ 8) / σL2 ^ 2 := by
  intro L σL2
  obtain ⟨m2, m3, m4, m5, m6, m7, m8⟩ := dg_moments (s ^ 2)
  have m0 := dg_moment_zero (s ^ 2)
  have m1 := dg_moment_one (s ^ 2)
  simp only [NNReal.coe_pow] at m2 m4 m6 m8
  obtain ⟨w2, w3, w4, -, -, -, -⟩ := dg_moments (v ^ 2)
  have w0 := dg_moment_zero (v ^ 2)
  have w1 := dg_moment_one (v ^ 2)
  simp only [NNReal.coe_pow] at w2 w4
  have hWE : ∀ n : ℕ, ∫ ω, W ω ^ n = ∫ x, x ^ n ∂gaussianReal 0 (v ^ 2) := fun n =>
    hW.integral_comp (f := fun x : ℝ => x ^ n) (by fun_prop)
  have hWI : ∀ n : ℕ, Integrable (fun ω => W ω ^ n) :=  fun n =>
    hW.integrable_comp (f := fun x : ℝ => x ^ n) (dg_integrable_pow_gaussianReal 0 _ n)
  set U : Ω → ℝ := fun ω => -(Δ * X ω + Γ / 2 * (X ω ^ 2 - (s : ℝ) ^ 2)) with hUdef
  have hXm := hX.aemeasurable
  have hWm := hW.aemeasurable
  have hUm : AEMeasurable U volume := by simp only [hUdef]; fun_prop
  have hLm : AEMeasurable L volume := by simp only [L]; fun_prop
  have hUW : IndepFun U W volume :=
    hXW.comp (φ := fun x : ℝ => -(Δ * x + Γ / 2 * (x ^ 2 - (s : ℝ) ^ 2))) (ψ := id)
      (by fun_prop) measurable_id
  -- representations of the powers of U
  have r1 : (fun ω => U ω ^ 1) = fun ω => ∑ i : Fin 9,
      (![((1/2)*Γ*(s:ℝ)^2), ((-1)*Δ), ((-1/2)*Γ), 0, 0, 0, 0, 0, 0] : Fin 9 → ℝ) i
        * X ω ^ (i : ℕ) := by
    funext ω; simp [hUdef, Fin.sum_univ_succ]; ring
  have r2 : (fun ω => U ω ^ 2) = fun ω => ∑ i : Fin 9,
      (![((1/4)*Γ^2*(s:ℝ)^4), ((-1)*Δ*Γ*(s:ℝ)^2), ((-1/2)*Γ^2*(s:ℝ)^2 + (1)*Δ^2), ((1)*Δ*Γ),
        ((1/4)*Γ^2), 0, 0, 0, 0] : Fin 9 → ℝ) i * X ω ^ (i : ℕ) := by
    funext ω; simp [hUdef, Fin.sum_univ_succ]; ring
  have r3 : (fun ω => U ω ^ 3) = fun ω => ∑ i : Fin 9,
      (![((1/8)*Γ^3*(s:ℝ)^6), ((-3/4)*Δ*Γ^2*(s:ℝ)^4),
        ((-3/8)*Γ^3*(s:ℝ)^4 + (3/2)*Δ^2*Γ*(s:ℝ)^2), ((3/2)*Δ*Γ^2*(s:ℝ)^2 + (-1)*Δ^3),
        ((3/8)*Γ^3*(s:ℝ)^2 + (-3/2)*Δ^2*Γ), ((-3/4)*Δ*Γ^2), ((-1/8)*Γ^3), 0, 0]
        : Fin 9 → ℝ) i * X ω ^ (i : ℕ) := by
    funext ω; simp [hUdef, Fin.sum_univ_succ]; ring
  have r4 : (fun ω => U ω ^ 4) = fun ω => ∑ i : Fin 9,
      (![((1/16)*Γ^4*(s:ℝ)^8), ((-1/2)*Δ*Γ^3*(s:ℝ)^6),
        ((-1/4)*Γ^4*(s:ℝ)^6 + (3/2)*Δ^2*Γ^2*(s:ℝ)^4),
        ((3/2)*Δ*Γ^3*(s:ℝ)^4 + (-2)*Δ^3*Γ*(s:ℝ)^2),
        ((3/8)*Γ^4*(s:ℝ)^4 + (-3)*Δ^2*Γ^2*(s:ℝ)^2 + (1)*Δ^4),
        ((-3/2)*Δ*Γ^3*(s:ℝ)^2 + (2)*Δ^3*Γ), ((-1/4)*Γ^4*(s:ℝ)^2 + (3/2)*Δ^2*Γ^2),
        ((1/2)*Δ*Γ^3), ((1/16)*Γ^4)] : Fin 9 → ℝ) i * X ω ^ (i : ℕ) := by
    funext ω; simp [hUdef, Fin.sum_univ_succ]; ring
  have U0 : ∫ ω, U ω ^ 0 = 1 := by simp
  have U1 : ∫ ω, U ω ^ 1 = 0 := by
    rw [r1, dg_poly9 hX]; simp [Fin.sum_univ_succ, m0, m1, m2]; ring
  have U2 : ∫ ω, U ω ^ 2 = Δ ^ 2 * (s : ℝ) ^ 2 + 1 / 2 * Γ ^ 2 * (s : ℝ) ^ 4 := by
    rw [r2, dg_poly9 hX]; simp [Fin.sum_univ_succ, m0, m1, m2, m3, m4]; ring
  have U3 : ∫ ω, U ω ^ 3 = -(3 * Δ ^ 2 * Γ * (s : ℝ) ^ 4 + Γ ^ 3 * (s : ℝ) ^ 6) := by
    rw [r3, dg_poly9 hX]; simp [Fin.sum_univ_succ, m0, m1, m2, m3, m4, m5, m6]; ring
  have U4 : ∫ ω, U ω ^ 4 = 3 * (Δ ^ 2 * (s : ℝ) ^ 2 + 1 / 2 * Γ ^ 2 * (s : ℝ) ^ 4) ^ 2
      + (12 * Δ ^ 2 * Γ ^ 2 * (s : ℝ) ^ 6 + 3 * Γ ^ 4 * (s : ℝ) ^ 8) := by
    rw [r4, dg_poly9 hX]; simp [Fin.sum_univ_succ, m0, m1, m2, m3, m4, m5, m6, m7, m8]; ring
  have hUI : ∀ j : ℕ, j ≤ 4 → Integrable (fun ω => U ω ^ j) := by
    intro j hj
    interval_cases j
    · simp
    · rw [r1]; exact dg_poly9_integrable hX _
    · rw [r2]; exact dg_poly9_integrable hX _
    · rw [r3]; exact dg_poly9_integrable hX _
    · rw [r4]; exact dg_poly9_integrable hX _
  have E1 : ∫ ω, L ω = -(1 / 2) * Γ * (s : ℝ) ^ 2 := by
    have : (fun ω => L ω) = fun ω => (U ω ^ 1 - W ω ^ 1) + (-(1 / 2) * Γ * (s : ℝ) ^ 2) := by
      funext ω; simp only [L, hUdef]; ring
    rw [this]
    have h1 := integral_add (μ := (volume : Measure Ω))
      (show Integrable (fun ω => U ω ^ 1 - W ω ^ 1) from (hUI 1 (by norm_num)).sub (hWI 1))
      (integrable_const (-(1 / 2) * Γ * (s : ℝ) ^ 2))
    have h2 := integral_sub (μ := (volume : Measure Ω)) (hUI 1 (by norm_num)) (hWI 1)
    simp only [integral_const, smul_eq_mul, probReal_univ, one_mul] at h1
    rw [h1, h2, U1, hWE, w1]; simp
  have U1' : ∫ ω, U ω = 0 := by simpa using U1
  have hvar : variance L volume = Δ ^ 2 * (s : ℝ) ^ 2 + 1 / 2 * Γ ^ 2 * (s : ℝ) ^ 4 + (v : ℝ) ^ 2 := by
    rw [variance_eq_integral hLm]
    have : (fun ω => (L ω - ∫ ω, L ω) ^ 2) = fun ω => ∑ j : Fin 3,
        (![1, -2, 1] : Fin 3 → ℝ) j * (U ω ^ (j : ℕ) * W ω ^ (2 - (j : ℕ))) := by
      funext ω; rw [E1]; simp [L, hUdef, Fin.sum_univ_succ]; ring
    rw [this, dg_indep_sum hUW hUm hWm (fun j => hUI j (by omega)) hWI]
    simp [Fin.sum_univ_succ, U0, U1, U1', U2, hWE, w0, w1, w2]; ring
  have hcm3 : centralMoment L 3 volume = -(3 * Δ ^ 2 * Γ * (s : ℝ) ^ 4 + Γ ^ 3 * (s : ℝ) ^ 6) := by
    have : (L - fun _ => ∫ ω, L ω) ^ 3 = fun ω => ∑ j : Fin 4,
        (![-1, 3, -3, 1] : Fin 4 → ℝ) j * (U ω ^ (j : ℕ) * W ω ^ (3 - (j : ℕ))) := by
      funext ω; rw [E1]; simp [L, hUdef, Fin.sum_univ_succ]; ring
    rw [centralMoment, this, dg_indep_sum hUW hUm hWm (fun j => hUI j (by omega)) hWI]
    simp [Fin.sum_univ_succ, U0, U1, U1', U2, U3, hWE, w0, w1, w2, w3]
  have hcm4 : centralMoment L 4 volume
      = 3 * (Δ ^ 2 * (s : ℝ) ^ 2 + 1 / 2 * Γ ^ 2 * (s : ℝ) ^ 4 + (v : ℝ) ^ 2) ^ 2
        + (12 * Δ ^ 2 * Γ ^ 2 * (s : ℝ) ^ 6 + 3 * Γ ^ 4 * (s : ℝ) ^ 8) := by
    have : (L - fun _ => ∫ ω, L ω) ^ 4 = fun ω => ∑ j : Fin 5,
        (![1, -4, 6, -4, 1] : Fin 5 → ℝ) j * (U ω ^ (j : ℕ) * W ω ^ (4 - (j : ℕ))) := by
      funext ω; rw [E1]; simp [L, hUdef, Fin.sum_univ_succ]; ring
    rw [centralMoment, this, dg_indep_sum hUW hUm hWm (fun j => hUI j (by omega)) hWI]
    simp [Fin.sum_univ_succ, U0, U1, U1', U2, U3, U4, hWE, w0, w1, w2, w3, w4]; ring
  refine ⟨E1, hvar, ?_, ?_⟩
  · rw [hvar, hcm3]
  · rw [hvar, hcm4]; congr 1; ring

#print axioms dg_integrable_pow_gaussianReal
#print axioms dg_hasDerivAt_gaussianPDFReal
#print axioms dg_integrable_pdf_mul_pow
#print axioms dg_moment_succ_succ
#print axioms dg_moment_zero
#print axioms dg_moment_one
#print axioms dg_moments
#print axioms dg_hasLaw
#print axioms dg_integral_sum
#print axioms dg_poly9
#print axioms dg_poly9_integrable
#print axioms dg_indep_sum
#print axioms dg_loss_moments_core


/-- **The delta-gamma loss has these four moments, exactly** (The formula; Why it works, Steps 2
and 3). Let Acme's one-day move `X` be normal with mean 0 and standard deviation `s`, and the rest
of the book's profit `W` be normal with mean 0 and standard deviation `v`, independent of `X`.
For any combined delta `Δ` and gamma `Γ`, the loss `L = -(ΔX + ½ΓX²) - W` has
mean `μ = -½Γs²`, variance `σ_L² = Δ²s² + ½Γ²s⁴ + v²`,
skew `γ₁ = -(3Δ²Γs⁴ + Γ³s⁶)/σ_L³` (third central moment over `σ_L³`) and
excess kurtosis `γ₂ = (12Δ²Γ²s⁶ + 3Γ⁴s⁸)/σ_L⁴` (fourth cumulant over `σ_L⁴`). -/
theorem delta_gamma_loss_moments
    {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (volume : Measure Ω)]
    (Δ Γ : ℝ) (s v : ℝ≥0) (X W : Ω → ℝ)
    (hX : HasLaw X (gaussianReal 0 (s ^ 2)) volume)
    (hW : HasLaw W (gaussianReal 0 (v ^ 2)) volume)
    (hXW : IndepFun X W volume) :
    let L : Ω → ℝ := fun ω => -(Δ * X ω + Γ / 2 * X ω ^ 2) - W ω
    let σL2 : ℝ := Δ ^ 2 * (s : ℝ) ^ 2 + 1 / 2 * Γ ^ 2 * (s : ℝ) ^ 4 + (v : ℝ) ^ 2
    (∫ ω, L ω) = -(1 / 2) * Γ * (s : ℝ) ^ 2 ∧
    variance L volume = σL2 ∧
    centralMoment L 3 volume / Real.sqrt (variance L volume) ^ 3 =
      -(3 * Δ ^ 2 * Γ * (s : ℝ) ^ 4 + Γ ^ 3 * (s : ℝ) ^ 6) / Real.sqrt σL2 ^ 3 ∧
    (centralMoment L 4 volume - 3 * variance L volume ^ 2) / variance L volume ^ 2 =
      (12 * Δ ^ 2 * Γ ^ 2 * (s : ℝ) ^ 6 + 3 * Γ ^ 4 * (s : ℝ) ^ 8) / σL2 ^ 2 := by
  exact dg_loss_moments_core Δ Γ s v X W hX hW hXW

/-- **The calls' part of the loss, in standard units** (Why it works, Step 3, and "The algebra
behind this"). Let `Z` be a standard normal draw. For any real `b` and `c`, the calls' part of
the loss with its mean taken out, `-(bZ + c(Z² - 1))`, has mean 0, variance `b² + 2c²`,
third central moment `-(6b²c + 8c³)` and fourth cumulant (fourth central moment minus three times
the variance squared) `48b²c² + 48c⁴`. -/
theorem calls_part_moments
    {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (volume : Measure Ω)]
    (b c : ℝ) (Z : Ω → ℝ)
    (hZ : Measure.map Z volume = gaussianReal 0 1) :
    let Y : Ω → ℝ := fun ω => -(b * Z ω + c * (Z ω ^ 2 - 1))
    (∫ ω, Y ω) = 0 ∧
    variance Y volume = b ^ 2 + 2 * c ^ 2 ∧
    centralMoment Y 3 volume = -(6 * b ^ 2 * c + 8 * c ^ 3) ∧
    centralMoment Y 4 volume - 3 * (b ^ 2 + 2 * c ^ 2) ^ 2 = 48 * b ^ 2 * c ^ 2 + 48 * c ^ 4 := by
  intro Y
  have hZ' := dg_hasLaw one_ne_zero hZ
  obtain ⟨m2, m3, m4, m5, m6, m7, m8⟩ := dg_moments 1
  have m0 := dg_moment_zero 1
  have m1 := dg_moment_one 1
  simp only [NNReal.coe_one, one_pow, mul_one] at m2 m4 m6 m8
  have hYm : AEMeasurable Y volume := by
    have := hZ'.aemeasurable
    simp only [Y]; fun_prop
  have E1 : ∫ ω, Y ω = 0 := by
    have : (fun ω => Y ω) = fun ω => ∑ i : Fin 9,
        (![((1)*c), ((-1)*b), ((-1)*c), 0, 0, 0, 0, 0, 0] : Fin 9 → ℝ) i * Z ω ^ (i : ℕ) := by
      funext ω; simp [Y, Fin.sum_univ_succ]; ring
    rw [this, dg_poly9 hZ']
    simp [Fin.sum_univ_succ, m0, m1, m2, m3, m4, m5, m6, m7, m8]
  have E2 : ∫ ω, Y ω ^ 2 = b ^ 2 + 2 * c ^ 2 := by
    have : (fun ω => Y ω ^ 2) = fun ω => ∑ i : Fin 9,
        (![((1)*c^2), ((-2)*b*c), ((-2)*c^2 + (1)*b^2), ((2)*b*c), ((1)*c^2), 0, 0, 0, 0]
          : Fin 9 → ℝ) i * Z ω ^ (i : ℕ) := by
      funext ω; simp [Y, Fin.sum_univ_succ]; ring
    rw [this, dg_poly9 hZ']
    simp [Fin.sum_univ_succ, m0, m1, m2, m3, m4, m5, m6, m7, m8]; ring
  have E3 : ∫ ω, Y ω ^ 3 = -(6 * b ^ 2 * c + 8 * c ^ 3) := by
    have : (fun ω => Y ω ^ 3) = fun ω => ∑ i : Fin 9,
        (![((1)*c^3), ((-3)*b*c^2), ((-3)*c^3 + (3)*b^2*c), ((6)*b*c^2 + (-1)*b^3),
          ((3)*c^3 + (-3)*b^2*c), ((-3)*b*c^2), ((-1)*c^3), 0, 0]
          : Fin 9 → ℝ) i * Z ω ^ (i : ℕ) := by
      funext ω; simp [Y, Fin.sum_univ_succ]; ring
    rw [this, dg_poly9 hZ']
    simp [Fin.sum_univ_succ, m0, m1, m2, m3, m4, m5, m6, m7, m8]; ring
  have E4 : ∫ ω, Y ω ^ 4 = 3 * (b ^ 2 + 2 * c ^ 2) ^ 2 + 48 * b ^ 2 * c ^ 2 + 48 * c ^ 4 := by
    have : (fun ω => Y ω ^ 4) = fun ω => ∑ i : Fin 9,
        (![((1)*c^4), ((-4)*b*c^3), ((-4)*c^4 + (6)*b^2*c^2), ((12)*b*c^3 + (-4)*b^3*c),
          ((6)*c^4 + (-12)*b^2*c^2 + (1)*b^4), ((-12)*b*c^3 + (4)*b^3*c),
          ((-4)*c^4 + (6)*b^2*c^2), ((4)*b*c^3), ((1)*c^4)]
          : Fin 9 → ℝ) i * Z ω ^ (i : ℕ) := by
      funext ω; simp [Y, Fin.sum_univ_succ]; ring
    rw [this, dg_poly9 hZ']
    simp [Fin.sum_univ_succ, m0, m1, m2, m3, m4, m5, m6, m7, m8]; ring
  refine ⟨E1, ?_, ?_, ?_⟩
  · rw [variance_eq_integral hYm, E1]; simpa using E2
  · simp only [centralMoment, Pi.pow_apply, Pi.sub_apply, E1, sub_zero]; exact E3
  · simp only [centralMoment, Pi.pow_apply, Pi.sub_apply, E1, sub_zero]; rw [E4]; ring

/-- **The Cornish-Fisher skew-squared term** (Why it works, Step 4, "Detailed proof"). With
`He₂(z) = z² - 1`, `He₅(z) = z⁵ - 10z³ + 15z` and `k = γ₁/6`, the second-order correction
`k²[½He₅ + ½z·He₂² + He₂(2z - z·He₂)]` equals `-γ₁²(2z³ - 5z)/36`, for every real `z` and `γ₁`. -/
theorem cornish_fisher_second_order_term (z γ₁ : ℝ) :
    let He₂ : ℝ := z ^ 2 - 1
    let He₅ : ℝ := z ^ 5 - 10 * z ^ 3 + 15 * z
    let k : ℝ := γ₁ / 6
    k ^ 2 * (1 / 2 * He₅ + 1 / 2 * z * He₂ ^ 2 + He₂ * (2 * z - z * He₂)) =
      -(γ₁ ^ 2 * (2 * z ^ 3 - 5 * z)) / 36 := by
  intro He₂ He₅ k
  simp only [He₂, He₅, k]
  ring

/-! ## The card's whole-number arithmetic ("The algebra behind this")

With `Y = Z² - 1` and the standard normal's even moments 1, 3, 15, 105. -/

-- E[Y²] = 3 - 2 + 1 = 2
example : (3 : ℤ) - 2 + 1 = 2 := by norm_num
-- E[Z²Y] = 3 - 1 = 2
example : (3 : ℤ) - 1 = 2 := by norm_num
-- E[Y³] = 15 - 3·3 + 3 - 1 = 8
example : (15 : ℤ) - 3 * 3 + 3 - 1 = 8 := by norm_num
-- E[Z²Y²] = 15 - 6 + 1 = 10
example : (15 : ℤ) - 6 + 1 = 10 := by norm_num
-- E[Y⁴] = 105 - 60 + 18 - 4 + 1 = 60
example : (105 : ℤ) - 60 + 18 - 4 + 1 = 60 := by norm_num

#print axioms delta_gamma_loss_moments
#print axioms calls_part_moments
#print axioms cornish_fisher_second_order_term
