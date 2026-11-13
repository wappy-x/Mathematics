-- Stepping an SDE: on the same independent bell-curve kicks, the mean squared gap between the Euler (or Milstein) reading and the exact geometric Brownian motion price has an exact closed form at every step count, and Andersen's QE draws are non-negative with exactly the target mean and variance.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory Real

lemma gm_iter (v : ℝ) :
    iteratedDeriv 1 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => v * t * rexp (v * t ^ 2 / 2)) ∧
    iteratedDeriv 2 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => (v + v^2 * t^2) * rexp (v * t ^ 2 / 2)) ∧
    iteratedDeriv 3 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => (3 * v^2 * t + v^3 * t^3) * rexp (v * t ^ 2 / 2)) ∧
    iteratedDeriv 4 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => (3 * v^2 + 6 * v^3 * t^2 + v^4 * t^4) * rexp (v * t ^ 2 / 2)) := by
  have hE : ∀ t, HasDerivAt (fun t => rexp (v * t ^ 2 / 2)) (v * t * rexp (v * t ^ 2 / 2)) t := by
    intro t
    have h1 : HasDerivAt (fun t : ℝ => v * t ^ 2 / 2) (v * t) t := by
      have := ((hasDerivAt_pow 2 t).const_mul v).div_const 2
      convert this using 1; push_cast; ring
    convert h1.exp using 1; ring
  have hP : ∀ (p : ℝ → ℝ) (p' : ℝ) (t : ℝ), HasDerivAt p p' t →
      HasDerivAt (fun t => p t * rexp (v * t ^ 2 / 2)) ((p' + p t * (v * t)) * rexp (v * t ^ 2 / 2)) t := by
    intro p p' t hp
    convert hp.mul (hE t) using 1; ring
  have d1 : iteratedDeriv 1 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => v * t * rexp (v * t ^ 2 / 2)) := by
    rw [iteratedDeriv_one]; funext t; exact (hE t).deriv
  have d2 : iteratedDeriv 2 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => (v + v^2 * t^2) * rexp (v * t ^ 2 / 2)) := by
    rw [iteratedDeriv_succ, d1]; funext t
    have := hP (fun t => v * t) v t (by simpa using (hasDerivAt_id t).const_mul v)
    convert this.deriv using 1; ring
  have d3 : iteratedDeriv 3 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => (3 * v^2 * t + v^3 * t^3) * rexp (v * t ^ 2 / 2)) := by
    rw [iteratedDeriv_succ, d2]; funext t
    have := hP (fun t => v + v^2 * t^2) (v^2 * (2 * t)) t (by
      have := ((hasDerivAt_pow 2 t).const_mul (v^2)).const_add v
      convert this using 1; push_cast; ring)
    convert this.deriv using 1; ring
  have d4 : iteratedDeriv 4 (fun t => rexp (v * t ^ 2 / 2)) = (fun t => (3 * v^2 + 6 * v^3 * t^2 + v^4 * t^4) * rexp (v * t ^ 2 / 2)) := by
    rw [iteratedDeriv_succ, d3]; funext t
    have := hP (fun t => 3 * v^2 * t + v^3 * t^3) (3 * v^2 + v^3 * (3 * t^2)) t (by
      have := ((hasDerivAt_id t).const_mul (3 * v^2)).fun_add ((hasDerivAt_pow 3 t).const_mul (v^3))
      convert this using 1 <;> first | (funext s; simp) | (push_cast; ring))
    convert this.deriv using 1; ring
  exact ⟨d1, d2, d3, d4⟩

#print axioms gm_iter

lemma gm (v : NNReal) (t : ℝ) (n : ℕ) :
    ∫ x, x ^ n * rexp (t * x) ∂gaussianReal 0 v = iteratedDeriv n (fun t => rexp ((v:ℝ) * t ^ 2 / 2)) t := by
  have h := iteratedDeriv_mgf (X := fun x : ℝ => x) (μ := gaussianReal 0 v) (t := t) (by simp) n
  rw [mgf_fun_id_gaussianReal] at h
  simpa using h.symm

#print axioms gm

lemma gint (v : NNReal) (t : ℝ) (n : ℕ) :
    Integrable (fun x : ℝ => x ^ n * rexp (t * x)) (gaussianReal 0 v) :=
  integrable_pow_mul_exp_of_mem_interior_integrableExpSet (X := fun x : ℝ => x) (by simp) n

#print axioms gint

lemma gpoly (v : NNReal) (t a0 a1 a2 a3 a4 : ℝ) :
    Integrable (fun x : ℝ => (a0 + a1 * x + a2 * x ^ 2 + a3 * x ^ 3 + a4 * x ^ 4) * rexp (t * x))
      (gaussianReal 0 v) ∧
    ∫ x, (a0 + a1 * x + a2 * x ^ 2 + a3 * x ^ 3 + a4 * x ^ 4) * rexp (t * x) ∂gaussianReal 0 v
      = (a0 + a1 * (v * t) + a2 * (v + v ^ 2 * t ^ 2) + a3 * (3 * v ^ 2 * t + v ^ 3 * t ^ 3)
          + a4 * (3 * v ^ 2 + 6 * v ^ 3 * t ^ 2 + v ^ 4 * t ^ 4)) * rexp (v * t ^ 2 / 2) := by
  have e : (fun x : ℝ => (a0 + a1 * x + a2 * x ^ 2 + a3 * x ^ 3 + a4 * x ^ 4) * rexp (t * x))
      = fun x => a0 * (x ^ 0 * rexp (t * x)) + a1 * (x ^ 1 * rexp (t * x))
        + a2 * (x ^ 2 * rexp (t * x)) + a3 * (x ^ 3 * rexp (t * x)) + a4 * (x ^ 4 * rexp (t * x)) := by
    funext x; ring
  have i : ∀ (a : ℝ) (n : ℕ), Integrable (fun x : ℝ => a * (x ^ n * rexp (t * x))) (gaussianReal 0 v) :=
    fun a n => (gint v t n).const_mul a
  refine ⟨?_, ?_⟩
  · rw [e]; exact ((((i a0 0).fun_add (i a1 1)).fun_add (i a2 2)).fun_add (i a3 3)).fun_add (i a4 4)
  · rw [e, integral_add (((i a0 0).fun_add (i a1 1)).fun_add (i a2 2) |>.fun_add (i a3 3)) (i a4 4),
      integral_add (((i a0 0).fun_add (i a1 1)).fun_add (i a2 2)) (i a3 3),
      integral_add ((i a0 0).fun_add (i a1 1)) (i a2 2), integral_add (i a0 0) (i a1 1)]
    simp only [integral_const_mul, gm]
    obtain ⟨d1, d2, d3, d4⟩ := gm_iter (v : ℝ)
    rw [d1, d2, d3, d4, iteratedDeriv_zero]
    ring

#print axioms gpoly

lemma gap_pi {N : ℕ} (ν : Measure ℝ) [IsProbabilityMeasure ν] (f g : ℝ → ℝ)
    (hf : Integrable (fun x => f x ^ 2) ν) (hg : Integrable (fun x => g x ^ 2) ν)
    (hfg : Integrable (fun x => f x * g x) ν) (S₀ : ℝ) :
    ∫ x, (S₀ * ∏ k, f (x k) - S₀ * ∏ k, g (x k)) ^ 2 ∂(Measure.pi fun _ : Fin N => ν)
      = S₀ ^ 2 * ((∫ x, f x ^ 2 ∂ν) ^ N + (∫ x, g x ^ 2 ∂ν) ^ N
          - 2 * (∫ x, f x * g x ∂ν) ^ N) := by
  have e : ∀ x : Fin N → ℝ, (S₀ * ∏ k, f (x k) - S₀ * ∏ k, g (x k)) ^ 2
      = S₀ ^ 2 * ∏ k, f (x k) ^ 2 + S₀ ^ 2 * ∏ k, g (x k) ^ 2
        - (2 * S₀ ^ 2) * ∏ k, (f (x k) * g (x k)) := by
    intro x; rw [Finset.prod_pow, Finset.prod_pow, Finset.prod_mul_distrib]; ring
  simp_rw [e]
  have i1 := Integrable.fintype_prod (f := fun (_ : Fin N) x => f x ^ 2) (μ := fun _ => ν) (fun _ => hf)
  have i2 := Integrable.fintype_prod (f := fun (_ : Fin N) x => g x ^ 2) (μ := fun _ => ν) (fun _ => hg)
  have i3 := Integrable.fintype_prod (f := fun (_ : Fin N) x => f x * g x) (μ := fun _ => ν) (fun _ => hfg)
  rw [integral_sub ((i1.const_mul _).fun_add (i2.const_mul _)) (i3.const_mul _),
    integral_add (i1.const_mul _) (i2.const_mul _), integral_const_mul, integral_const_mul,
    integral_const_mul, integral_fintype_prod_eq_pow (fun x => f x ^ 2),
    integral_fintype_prod_eq_pow (fun x => g x ^ 2), integral_fintype_prod_eq_pow (fun x => f x * g x)]
  simp only [Fintype.card_fin]
  ring

#print axioms gap_pi

lemma qe_log_integrals (p : ℝ) (hp1 : p < 1) :
    IntegrableOn (fun u => log ((1 - p) / (1 - u))) (Set.Ioc p 1) ∧
    IntegrableOn (fun u => log ((1 - p) / (1 - u)) ^ 2) (Set.Ioc p 1) ∧
    ∫ u in p..1, log ((1 - p) / (1 - u)) = 1 - p ∧
    ∫ u in p..1, log ((1 - p) / (1 - u)) ^ 2 = 2 * (1 - p) := by
  have hc : 0 < 1 - p := by linarith
  have hml : Continuous (fun u : ℝ => (1 - u) * log (1 - u)) :=
    continuous_mul_log.comp (by fun_prop)
  -- antiderivative of the log
  have hFc : Continuous (fun u : ℝ => -(1 - u) * log (1 - p) + (1 - u) * log (1 - u) + u) :=
    ((by fun_prop : Continuous (fun u : ℝ => -(1 - u) * log (1 - p))).add hml).add continuous_id'
  have hFd : ∀ u ∈ Set.Ioo p 1, HasDerivAt
      (fun u : ℝ => -(1 - u) * log (1 - p) + (1 - u) * log (1 - u) + u)
      (log ((1 - p) / (1 - u))) u := by
    intro u hu
    have h1u : 0 < 1 - u := by linarith [hu.2]
    have hv : HasDerivAt (fun x : ℝ => 1 - x) (-1) u := by
      simpa using (hasDerivAt_id' u).const_sub 1
    have hl := hv.log h1u.ne'
    have := ((hv.neg.mul_const (log (1 - p))).add (hv.mul hl)).add (hasDerivAt_id' u)
    convert this using 1
    rw [log_div hc.ne' h1u.ne']; field_simp; ring
  -- antiderivative of the squared log
  have hGd : ∀ u ∈ Set.Ioo p 1, HasDerivAt
      (fun u : ℝ => -((1 - u) * (log (1 - p) - log (1 - u)) ^ 2
        + 2 * (1 - u) * (log (1 - p) - log (1 - u)) + 2 * (1 - u)))
      (log ((1 - p) / (1 - u)) ^ 2) u := by
    intro u hu
    have h1u : 0 < 1 - u := by linarith [hu.2]
    have hv : HasDerivAt (fun x : ℝ => 1 - x) (-1) u := by
      simpa using (hasDerivAt_id' u).const_sub 1
    have hl := (hasDerivAt_const u (log (1 - p))).sub (hv.log h1u.ne')
    have := (((hv.mul (hl.pow 2)).add ((hv.const_mul 2).mul hl)).add (hv.const_mul 2)).neg
    convert this using 1
    simp only [Pi.sub_apply, Pi.pow_apply]
    rw [log_div hc.ne' h1u.ne']; field_simp; ring
  have hGc : ContinuousOn (fun u : ℝ => -((1 - u) * (log (1 - p) - log (1 - u)) ^ 2
        + 2 * (1 - u) * (log (1 - p) - log (1 - u)) + 2 * (1 - u))) (Set.Icc p 1) := by
    have hs : Continuous (fun u : ℝ => √(1 - u) * log √(1 - u)) :=
      continuous_mul_log.comp (by fun_prop)
    have hcont : Continuous (fun u : ℝ => -((1 - u) * log (1 - p) ^ 2
        - 2 * log (1 - p) * ((1 - u) * log (1 - u)) + 4 * (√(1 - u) * log √(1 - u)) ^ 2
        + 2 * ((1 - u) * log (1 - p) - (1 - u) * log (1 - u)) + 2 * (1 - u))) := by
      have := hml; have := hs; fun_prop
    refine hcont.continuousOn.congr ?_
    intro u hu
    have h0 : 0 ≤ 1 - u := by linarith [hu.2]
    simp only
    rw [log_sqrt h0, mul_pow, sq_sqrt h0]
    ring
  have hpos1 : ∀ u ∈ Set.Ioo p 1, 0 ≤ log ((1 - p) / (1 - u)) := by
    intro u hu
    have h1u : 0 < 1 - u := by linarith [hu.2]
    apply log_nonneg
    rw [le_div_iff₀ h1u]; linarith [hu.1]
  have i1 := intervalIntegral.integrableOn_deriv_of_nonneg hFc.continuousOn hFd hpos1
  have i2 := intervalIntegral.integrableOn_deriv_of_nonneg hGc hGd (fun u _ => sq_nonneg _)
  refine ⟨i1, i2, ?_, ?_⟩
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hp1.le hFc.continuousOn hFd
      ((intervalIntegrable_iff_integrableOn_Ioc_of_le hp1.le).2 i1)]
    simp; ring
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hp1.le hGc hGd
      ((intervalIntegrable_iff_integrableOn_Ioc_of_le hp1.le).2 i2)]
    simp

#print axioms qe_log_integrals

lemma restrict_Icc_Ioi (p : ℝ) (hp0 : 0 ≤ p) :
    (volume.restrict (Set.Icc (0 : ℝ) 1)).restrict (Set.Ioi p) = volume.restrict (Set.Ioc p 1) := by
  rw [Measure.restrict_restrict measurableSet_Ioi]
  congr 1
  ext u
  simp only [Set.mem_inter_iff, Set.mem_Ioi, Set.mem_Icc, Set.mem_Ioc]
  constructor
  · rintro ⟨h1, -, h3⟩; exact ⟨h1, h3⟩
  · rintro ⟨h1, h3⟩; exact ⟨h1, by linarith, h3⟩

#print axioms restrict_Icc_Ioi

/-! The card's model, geometric Brownian motion, is stepped `N` times over `T` years, so a step
has length `h = T / N`. Step `k` gets the kick `ΔW k`, a bell-curve draw with average zero and
variance `h`, and the `N` kicks are independent. All three rules are fed the same kicks:

* exact:    `S_T = S_0 * ∏ exp ((μ - σ²/2) h + σ ΔW k)`
* Euler:    `Y_N = S_0 * ∏ (1 + μ h + σ ΔW k)`
* Milstein: `Y_N = S_0 * ∏ (1 + μ h + σ ΔW k + σ²/2 (ΔW k² - h))`

Mathlib has no Ito calculus, so this file states the card's exact results about these products,
which is what Step 4 proves. The shrinking rates (√h, h) are published limits the card checks
against numbers but does not prove, so they are not stated here. -/

/-- **Euler's exact path gap (Step 4).** On the same `N` independent kicks, each a bell curve with
average zero and variance `h = T / N`, the average of the squared gap between Euler's reading
and the exact price at the year's end is
`S_0² [((1 + μh)² + σ²h)^N + e^((2μ + σ²)T) − 2 e^(μT) (1 + (μ + σ²)h)^N]`,
exactly, at every step count, with no assumption that the factors stay positive. -/
theorem euler_path_gap_exact {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (N : ℕ) (hN : 0 < N) (T : ℝ) (hT : 0 ≤ T)
    (ΔW : Fin N → Ω → ℝ) (hind : iIndepFun ΔW P)
    (hlaw : ∀ k, HasLaw (ΔW k) (gaussianReal 0 (T / N).toNNReal) P)
    (S₀ μ σ : ℝ) :
    ∫ ω, (S₀ * ∏ k, (1 + μ * (T / N) + σ * ΔW k ω)
          - S₀ * ∏ k, exp ((μ - σ ^ 2 / 2) * (T / N) + σ * ΔW k ω)) ^ 2 ∂P
      = S₀ ^ 2 * (((1 + μ * (T / N)) ^ 2 + σ ^ 2 * (T / N)) ^ N
          + exp ((2 * μ + σ ^ 2) * T)
          - 2 * exp (μ * T) * (1 + (μ + σ ^ 2) * (T / N)) ^ N) := by
  set h := T / (N : ℝ) with hh
  set v := h.toNNReal with hvdef
  have hv : (v : ℝ) = h := Real.coe_toNNReal _ (div_nonneg hT (Nat.cast_nonneg _))
  have hNh : (N : ℝ) * h = T := by
    rw [hh]; field_simp
  have hL := hind.hasLaw_pi hlaw
  have hI := hL.integral_comp (f := fun x : Fin N → ℝ => (S₀ * ∏ k, (1 + μ * h + σ * x k)
          - S₀ * ∏ k, exp ((μ - σ ^ 2 / 2) * h + σ * x k)) ^ 2) (by fun_prop)
  simp only [Function.comp_def] at hI
  rw [hI]
  have ef : (fun x : ℝ => (1 + μ * h + σ * x) ^ 2) = fun x =>
      ((1 + μ * h) ^ 2 + 2 * (1 + μ * h) * σ * x + σ ^ 2 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4)
        * rexp (0 * x) := by
    funext x; simp; ring
  have eg : (fun x : ℝ => rexp ((μ - σ ^ 2 / 2) * h + σ * x) ^ 2) = fun x =>
      (rexp (2 * ((μ - σ ^ 2 / 2) * h)) + 0 * x + 0 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4)
        * rexp ((2 * σ) * x) := by
    funext x; simp only [zero_mul, add_zero]; rw [sq, ← exp_add, ← exp_add]; ring_nf
  have efg : (fun x : ℝ => (1 + μ * h + σ * x) * rexp ((μ - σ ^ 2 / 2) * h + σ * x)) = fun x =>
      (rexp ((μ - σ ^ 2 / 2) * h) * (1 + μ * h) + rexp ((μ - σ ^ 2 / 2) * h) * σ * x
        + 0 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4) * rexp (σ * x) := by
    funext x; rw [exp_add]; ring
  rw [gap_pi (gaussianReal 0 v) (fun x => 1 + μ * h + σ * x)
    (fun x => exp ((μ - σ ^ 2 / 2) * h + σ * x))
    (by rw [ef]; exact (gpoly _ _ _ _ _ _ _).1) (by rw [eg]; exact (gpoly _ _ _ _ _ _ _).1)
    (by rw [efg]; exact (gpoly _ _ _ _ _ _ _).1)]
  rw [ef, eg, efg, (gpoly _ _ _ _ _ _ _).2, (gpoly _ _ _ _ _ _ _).2, (gpoly _ _ _ _ _ _ _).2, hv]
  have E2 : rexp (2 * ((μ - σ ^ 2 / 2) * h)) * rexp (h * (2 * σ) ^ 2 / 2) = rexp ((2 * μ + σ ^ 2) * h) := by
    rw [← exp_add]; ring_nf
  have E1 : rexp ((μ - σ ^ 2 / 2) * h) * rexp (h * σ ^ 2 / 2) = rexp (μ * h) := by
    rw [← exp_add]; ring_nf
  have A1 : ((1 + μ * h) ^ 2 + 2 * (1 + μ * h) * σ * (h * 0) + σ ^ 2 * (h + h ^ 2 * 0 ^ 2)
      + 0 * (3 * h ^ 2 * 0 + h ^ 3 * 0 ^ 3) + 0 * (3 * h ^ 2 + 6 * h ^ 3 * 0 ^ 2 + h ^ 4 * 0 ^ 4))
      * rexp (h * 0 ^ 2 / 2) = (1 + μ * h) ^ 2 + σ ^ 2 * h := by simp
  have A2 : (rexp (2 * ((μ - σ ^ 2 / 2) * h)) + 0 * (h * (2 * σ)) + 0 * (h + h ^ 2 * (2 * σ) ^ 2)
      + 0 * (3 * h ^ 2 * (2 * σ) + h ^ 3 * (2 * σ) ^ 3)
      + 0 * (3 * h ^ 2 + 6 * h ^ 3 * (2 * σ) ^ 2 + h ^ 4 * (2 * σ) ^ 4)) * rexp (h * (2 * σ) ^ 2 / 2)
      = rexp ((2 * μ + σ ^ 2) * h) := by simp only [zero_mul, add_zero]; exact E2
  have A3 : (rexp ((μ - σ ^ 2 / 2) * h) * (1 + μ * h) + rexp ((μ - σ ^ 2 / 2) * h) * σ * (h * σ)
      + 0 * (h + h ^ 2 * σ ^ 2) + 0 * (3 * h ^ 2 * σ + h ^ 3 * σ ^ 3)
      + 0 * (3 * h ^ 2 + 6 * h ^ 3 * σ ^ 2 + h ^ 4 * σ ^ 4)) * rexp (h * σ ^ 2 / 2)
      = rexp (μ * h) * (1 + (μ + σ ^ 2) * h) := by
    rw [← E1]; ring
  rw [A1, A2, A3, mul_pow, ← exp_nat_mul, ← exp_nat_mul]
  have : (N : ℝ) * ((2 * μ + σ ^ 2) * h) = (2 * μ + σ ^ 2) * T := by rw [← hNh]; ring
  have h2 : (N : ℝ) * (μ * h) = μ * T := by rw [← hNh]; ring
  rw [this, h2]; ring

/-- **Milstein's exact path gap (Step 4, detailed proof).** With Milstein's factor
`1 + μh + σΔW + σ²/2 (ΔW² − h)` in place of Euler's, on the same kicks, the same three-term
formula holds with one extra piece `σ⁴h²/2` in the squared average and in the cross average:
`S_0² [((1 + μh)² + σ²h + σ⁴h²/2)^N + e^((2μ + σ²)T) − 2 e^(μT) (1 + (μ + σ²)h + σ⁴h²/2)^N]`. -/
theorem milstein_path_gap_exact {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (N : ℕ) (hN : 0 < N) (T : ℝ) (hT : 0 ≤ T)
    (ΔW : Fin N → Ω → ℝ) (hind : iIndepFun ΔW P)
    (hlaw : ∀ k, HasLaw (ΔW k) (gaussianReal 0 (T / N).toNNReal) P)
    (S₀ μ σ : ℝ) :
    ∫ ω, (S₀ * ∏ k, (1 + μ * (T / N) + σ * ΔW k ω
              + σ ^ 2 / 2 * (ΔW k ω ^ 2 - T / N))
          - S₀ * ∏ k, exp ((μ - σ ^ 2 / 2) * (T / N) + σ * ΔW k ω)) ^ 2 ∂P
      = S₀ ^ 2 * (((1 + μ * (T / N)) ^ 2 + σ ^ 2 * (T / N) + σ ^ 4 * (T / N) ^ 2 / 2) ^ N
          + exp ((2 * μ + σ ^ 2) * T)
          - 2 * exp (μ * T) * (1 + (μ + σ ^ 2) * (T / N) + σ ^ 4 * (T / N) ^ 2 / 2) ^ N) := by
  set h := T / (N : ℝ) with hh
  set v := h.toNNReal with hvdef
  have hv : (v : ℝ) = h := Real.coe_toNNReal _ (div_nonneg hT (Nat.cast_nonneg _))
  have hNh : (N : ℝ) * h = T := by
    rw [hh]; field_simp
  have hL := hind.hasLaw_pi hlaw
  have hI := hL.integral_comp (f := fun x : Fin N → ℝ => (S₀ * ∏ k, (1 + μ * h + σ * x k
              + σ ^ 2 / 2 * (x k ^ 2 - h))
          - S₀ * ∏ k, exp ((μ - σ ^ 2 / 2) * h + σ * x k)) ^ 2) (by fun_prop)
  simp only [Function.comp_def] at hI
  rw [hI]
  set d := 1 + μ * h - σ ^ 2 / 2 * h with hd
  have ef : (fun x : ℝ => (1 + μ * h + σ * x + σ ^ 2 / 2 * (x ^ 2 - h)) ^ 2) = fun x =>
      (d ^ 2 + 2 * d * σ * x + (σ ^ 2 + d * σ ^ 2) * x ^ 2 + σ ^ 3 * x ^ 3 + σ ^ 4 / 4 * x ^ 4)
        * rexp (0 * x) := by
    funext x; simp only [zero_mul, exp_zero, mul_one]; rw [hd]; ring
  have eg : (fun x : ℝ => rexp ((μ - σ ^ 2 / 2) * h + σ * x) ^ 2) = fun x =>
      (rexp (2 * ((μ - σ ^ 2 / 2) * h)) + 0 * x + 0 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4)
        * rexp ((2 * σ) * x) := by
    funext x; simp only [zero_mul, add_zero]; rw [sq, ← exp_add, ← exp_add]; ring_nf
  have efg : (fun x : ℝ => (1 + μ * h + σ * x + σ ^ 2 / 2 * (x ^ 2 - h))
      * rexp ((μ - σ ^ 2 / 2) * h + σ * x)) = fun x =>
      (rexp ((μ - σ ^ 2 / 2) * h) * d + rexp ((μ - σ ^ 2 / 2) * h) * σ * x
        + rexp ((μ - σ ^ 2 / 2) * h) * (σ ^ 2 / 2) * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4)
        * rexp (σ * x) := by
    funext x; rw [exp_add, hd]; ring
  rw [gap_pi (gaussianReal 0 v) (fun x => 1 + μ * h + σ * x + σ ^ 2 / 2 * (x ^ 2 - h))
    (fun x => exp ((μ - σ ^ 2 / 2) * h + σ * x))
    (by rw [ef]; exact (gpoly _ _ _ _ _ _ _).1) (by rw [eg]; exact (gpoly _ _ _ _ _ _ _).1)
    (by rw [efg]; exact (gpoly _ _ _ _ _ _ _).1)]
  rw [ef, eg, efg, (gpoly _ _ _ _ _ _ _).2, (gpoly _ _ _ _ _ _ _).2, (gpoly _ _ _ _ _ _ _).2, hv]
  have E2 : rexp (2 * ((μ - σ ^ 2 / 2) * h)) * rexp (h * (2 * σ) ^ 2 / 2) = rexp ((2 * μ + σ ^ 2) * h) := by
    rw [← exp_add]; ring_nf
  have E1 : rexp ((μ - σ ^ 2 / 2) * h) * rexp (h * σ ^ 2 / 2) = rexp (μ * h) := by
    rw [← exp_add]; ring_nf
  have A1 : (d ^ 2 + 2 * d * σ * (h * 0) + (σ ^ 2 + d * σ ^ 2) * (h + h ^ 2 * 0 ^ 2)
      + σ ^ 3 * (3 * h ^ 2 * 0 + h ^ 3 * 0 ^ 3) + σ ^ 4 / 4 * (3 * h ^ 2 + 6 * h ^ 3 * 0 ^ 2 + h ^ 4 * 0 ^ 4))
      * rexp (h * 0 ^ 2 / 2) = (1 + μ * h) ^ 2 + σ ^ 2 * h + σ ^ 4 * h ^ 2 / 2 := by
    simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero, zero_div,
      exp_zero, mul_one, add_zero]
    rw [hd]; ring
  have A2 : (rexp (2 * ((μ - σ ^ 2 / 2) * h)) + 0 * (h * (2 * σ)) + 0 * (h + h ^ 2 * (2 * σ) ^ 2)
      + 0 * (3 * h ^ 2 * (2 * σ) + h ^ 3 * (2 * σ) ^ 3)
      + 0 * (3 * h ^ 2 + 6 * h ^ 3 * (2 * σ) ^ 2 + h ^ 4 * (2 * σ) ^ 4)) * rexp (h * (2 * σ) ^ 2 / 2)
      = rexp ((2 * μ + σ ^ 2) * h) := by simp only [zero_mul, add_zero]; exact E2
  have A3 : (rexp ((μ - σ ^ 2 / 2) * h) * d + rexp ((μ - σ ^ 2 / 2) * h) * σ * (h * σ)
      + rexp ((μ - σ ^ 2 / 2) * h) * (σ ^ 2 / 2) * (h + h ^ 2 * σ ^ 2)
      + 0 * (3 * h ^ 2 * σ + h ^ 3 * σ ^ 3)
      + 0 * (3 * h ^ 2 + 6 * h ^ 3 * σ ^ 2 + h ^ 4 * σ ^ 4)) * rexp (h * σ ^ 2 / 2)
      = rexp (μ * h) * (1 + (μ + σ ^ 2) * h + σ ^ 4 * h ^ 2 / 2) := by
    rw [← E1, hd]; ring
  rw [A1, A2, A3, mul_pow, ← exp_nat_mul, ← exp_nat_mul]
  have : (N : ℝ) * ((2 * μ + σ ^ 2) * h) = (2 * μ + σ ^ 2) * T := by rw [← hNh]; ring
  have h2 : (N : ℝ) * (μ * h) = μ * T := by rw [← hNh]; ring
  rw [this, h2]; ring

/-- **Andersen's QE scheme matches both moments (Step 5).** Given a target average `m > 0` and
variance `w > 0`, with relative spread `ψ = w / m²`:

* *Squared branch*, for `ψ ≤ 2`: with `b² = 2/ψ − 1 + √(2/ψ) √(2/ψ − 1)` and `a = m / (1 + b²)`,
  the draw `Y = a (b + Z)²`, `Z` a standard bell curve, is never negative, averages `m`, and has
  variance `w`.
* *Exponential branch*, for `ψ ≥ 1`: with `p = (ψ − 1)/(ψ + 1)` and `β = (1 − p)/m`, the draw
  `Y = 0` when `U ≤ p` and `Y = (1/β) ln ((1 − p)/(1 − U))` otherwise, `U` even on `[0, 1]`,
  is never negative, averages `m`, and has variance `w`. -/
theorem qe_matches_mean_and_variance {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (Z U : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P)
    (hU : HasLaw U (volume.restrict (Set.Icc (0 : ℝ) 1)) P)
    (m w : ℝ) (hm : 0 < m) (hw : 0 < w) :
    (w / m ^ 2 ≤ 2 →
      let ψ := w / m ^ 2
      let b := √(2 / ψ - 1 + √(2 / ψ) * √(2 / ψ - 1))
      let a := m / (1 + b ^ 2)
      let Y := fun ω => a * (b + Z ω) ^ 2
      (∀ ω, 0 ≤ Y ω) ∧ ∫ ω, Y ω ∂P = m ∧ variance Y P = w) ∧
    (1 ≤ w / m ^ 2 →
      let ψ := w / m ^ 2
      let p := (ψ - 1) / (ψ + 1)
      let β := (1 - p) / m
      let Y := fun ω => if U ω ≤ p then 0 else 1 / β * log ((1 - p) / (1 - U ω))
      (∀ᵐ ω ∂P, 0 ≤ Y ω) ∧ ∫ ω, Y ω ∂P = m ∧ variance Y P = w) := by
  have hm2 : 0 < m ^ 2 := by positivity
  have hψpos : 0 < w / m ^ 2 := div_pos hw hm2
  refine ⟨?_, ?_⟩
  · intro hψ
    dsimp only
    set ψ := w / m ^ 2 with hψd
    have hwψ : w = ψ * m ^ 2 := by rw [hψd]; field_simp
    have hq : ψ * (2 / ψ) = 2 := by field_simp
    have hq1 : 0 ≤ 2 / ψ - 1 := by
      rw [sub_nonneg, le_div_iff₀ hψpos]; linarith
    set s := √(2 / ψ) with hsd
    set r := √(2 / ψ - 1) with hrd
    have hs : s ^ 2 = 2 / ψ := sq_sqrt (by positivity)
    have hr : r ^ 2 = 2 / ψ - 1 := sq_sqrt hq1
    have hB : 0 ≤ 2 / ψ - 1 + s * r := add_nonneg hq1 (mul_nonneg (sqrt_nonneg _) (sqrt_nonneg _))
    set b := √(2 / ψ - 1 + s * r) with hbd
    have hb : b ^ 2 = 2 / ψ - 1 + s * r := sq_sqrt hB
    have hkey : ψ * (1 + b ^ 2) ^ 2 = 4 * b ^ 2 + 2 := by
      rw [hb]
      linear_combination (2 * (2 / ψ) - 1 + 2 * s * r) * hq + ψ * r ^ 2 * hs + ψ * (2 / ψ) * hr
    have h1b : 0 < 1 + b ^ 2 := by positivity
    set a := m / (1 + b ^ 2) with had
    have ha : 0 ≤ a := div_nonneg hm.le h1b.le
    have ef : (fun z : ℝ => a * (b + z) ^ 2) = fun z =>
        (a * b ^ 2 + 2 * a * b * z + a * z ^ 2 + 0 * z ^ 3 + 0 * z ^ 4) * rexp (0 * z) := by
      funext z; simp only [zero_mul, exp_zero, mul_one, add_zero]; ring
    have ef2 : (fun z : ℝ => (a * (b + z) ^ 2) ^ 2) = fun z =>
        (a ^ 2 * b ^ 4 + 4 * a ^ 2 * b ^ 3 * z + 6 * a ^ 2 * b ^ 2 * z ^ 2 + 4 * a ^ 2 * b * z ^ 3
          + a ^ 2 * z ^ 4) * rexp (0 * z) := by
      funext z; simp only [zero_mul, exp_zero, mul_one]; ring
    have hI1 := hZ.integral_comp (f := fun z : ℝ => a * (b + z) ^ 2) (by fun_prop)
    have hI2 := hZ.integral_comp (f := fun z : ℝ => (a * (b + z) ^ 2) ^ 2) (by fun_prop)
    simp only [Function.comp_def] at hI1 hI2
    have hmean : ∫ ω, a * (b + Z ω) ^ 2 ∂P = m := by
      rw [hI1, ef, (gpoly _ _ _ _ _ _ _).2]
      simp only [NNReal.coe_one, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero,
        zero_div, exp_zero, mul_one, add_zero, one_pow]
      rw [had]; field_simp; ring
    have hmem : MemLp (fun ω => a * (b + Z ω) ^ 2) 2 P := by
      have : MemLp (fun z : ℝ => a * (b + z) ^ 2) 2 (gaussianReal 0 1) := by
        rw [memLp_two_iff_integrable_sq (by fun_prop), ef2]
        exact (gpoly _ _ _ _ _ _ _).1
      exact hZ.memLp_comp this
    refine ⟨fun ω => mul_nonneg ha (sq_nonneg _), hmean, ?_⟩
    rw [variance_eq_sub hmem]
    simp only [Pi.pow_apply]
    rw [hmean, hI2, ef2, (gpoly _ _ _ _ _ _ _).2]
    simp only [NNReal.coe_one]
    have : (a ^ 2 * b ^ 4 + 4 * a ^ 2 * b ^ 3 * (1 * 0) + 6 * a ^ 2 * b ^ 2 * (1 + 1 ^ 2 * 0 ^ 2)
        + 4 * a ^ 2 * b * (3 * 1 ^ 2 * 0 + 1 ^ 3 * 0 ^ 3)
        + a ^ 2 * (3 * 1 ^ 2 + 6 * 1 ^ 3 * 0 ^ 2 + 1 ^ 4 * 0 ^ 4)) * rexp (1 * 0 ^ 2 / 2) - m ^ 2
        = a ^ 2 * (4 * b ^ 2 + 2) - (m ^ 2 - (a * (1 + b ^ 2)) ^ 2) := by
      simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero, zero_div,
        exp_zero, mul_one, add_zero, one_pow]
      ring
    rw [this]
    have hma : a * (1 + b ^ 2) = m := by rw [had]; field_simp
    rw [hma, sub_self, sub_zero, ← hkey, had, hwψ]
    field_simp
  · intro hψ
    dsimp only
    set ψ := w / m ^ 2 with hψd
    have hwψ : w = ψ * m ^ 2 := by rw [hψd]; field_simp
    have hψ1 : 0 < ψ + 1 := by linarith
    set p := (ψ - 1) / (ψ + 1) with hpd
    have hp0 : 0 ≤ p := div_nonneg (by linarith) hψ1.le
    have hp1 : p < 1 := by rw [hpd, div_lt_one hψ1]; linarith
    have hc : 0 < 1 - p := by linarith
    have hcψ : 1 - p = 2 / (ψ + 1) := by rw [hpd]; field_simp; ring
    set β := (1 - p) / m with hβd
    have hβ : 0 < β := div_pos hc hm
    set K : ℝ → ℝ := fun u => 1 / β * log ((1 - p) / (1 - u)) with hK
    have hg : (fun u : ℝ => if u ≤ p then 0 else 1 / β * log ((1 - p) / (1 - u)))
        = (Set.Ioi p).indicator K := by
      funext u
      simp only [Set.indicator_apply, Set.mem_Ioi, hK]
      by_cases hu : u ≤ p
      · simp [hu, not_lt.mpr hu]
      · simp [hu, not_le.mp hu]
    have hg2 : (fun u : ℝ => (if u ≤ p then 0 else 1 / β * log ((1 - p) / (1 - u))) ^ 2)
        = (Set.Ioi p).indicator (fun u => K u ^ 2) := by
      funext u
      simp only [Set.indicator_apply, Set.mem_Ioi, hK]
      by_cases hu : u ≤ p
      · simp [hu, not_lt.mpr hu]
      · simp [hu, not_le.mp hu]
    obtain ⟨i1, i2, I1, I2⟩ := qe_log_integrals p hp1
    have hmeas : Measurable (fun u : ℝ => if u ≤ p then 0 else 1 / β * log ((1 - p) / (1 - u))) := by
      rw [hg]; exact Measurable.indicator (by fun_prop) measurableSet_Ioi
    have hR := restrict_Icc_Ioi p hp0
    have hI1 := hU.integral_comp hmeas.aestronglyMeasurable
    have hI2 := hU.integral_comp (hmeas.pow_const 2).aestronglyMeasurable
    simp only [Function.comp_def] at hI1 hI2
    have hmean : ∫ ω, (if U ω ≤ p then 0 else 1 / β * log ((1 - p) / (1 - U ω))) ∂P = m := by
      rw [hI1, hg, integral_indicator measurableSet_Ioi, hR, ← intervalIntegral.integral_of_le hp1.le,
        hK, intervalIntegral.integral_const_mul, I1, hβd]
      field_simp
    have hmem : MemLp (fun ω => if U ω ≤ p then 0 else 1 / β * log ((1 - p) / (1 - U ω))) 2 P := by
      have : MemLp (fun u : ℝ => if u ≤ p then 0 else 1 / β * log ((1 - p) / (1 - u))) 2
          (volume.restrict (Set.Icc (0 : ℝ) 1)) := by
        rw [memLp_two_iff_integrable_sq hmeas.aestronglyMeasurable]
        rw [hg2, integrable_indicator_iff measurableSet_Ioi, IntegrableOn, hR, hK]
        simp only [mul_pow]
        exact i2.const_mul _
      exact hU.memLp_comp this
    refine ⟨?_, hmean, ?_⟩
    · refine ae_of_ae_map (p := fun u : ℝ =>
        0 ≤ if u ≤ p then 0 else 1 / β * log ((1 - p) / (1 - u))) hU.aemeasurable ?_
      rw [hU.map_eq]
      refine ae_restrict_of_forall_mem measurableSet_Icc ?_
      intro u hu
      by_cases hup : u ≤ p
      · simp [hup]
      · simp only [hup, ite_false]
        refine mul_nonneg (by positivity) ?_
        rcases eq_or_lt_of_le hu.2 with h1 | h1
        · simp [h1]
        · apply log_nonneg
          rw [le_div_iff₀ (by linarith)]; linarith [not_le.mp hup]
    · rw [variance_eq_sub hmem]
      simp only [Pi.pow_apply]
      rw [hmean, hI2, hg2, integral_indicator measurableSet_Ioi, hR,
        ← intervalIntegral.integral_of_le hp1.le, hK]
      simp only [mul_pow]
      rw [intervalIntegral.integral_const_mul, I2, hβd, hwψ]
      have hcne : (1 - p) ≠ 0 := hc.ne'
      field_simp
      rw [hcψ]
      field_simp
      ring

/-! The card's exact worked arithmetic. Acme: drift μ = r − q = 5% − 2% = 3/100,
volatility σ = 1/5, one year. Heston variance: v = 9/100, θ = 1/25, κ = ln 2, η² = (2/25) ln 2,
so over one year `e^(−κ) = 1/2`. -/

-- The drift is r − q: 5% less 2% is 3%.
example : (5 / 100 : ℚ) - 2 / 100 = 3 / 100 := by norm_num

-- Twelve monthly steps: Euler's one-step average factor is 1 + μh = 1 + (3/100)(1/12) = 401/400.
example : (1 : ℚ) + 3 / 100 * (1 / 12) = 401 / 400 := by norm_num

-- One year-long Euler step turns negative when the kick falls below −(1 + μ)/σ = −5.15.
example : -(1 + 3 / 100 : ℚ) / (1 / 5) = -515 / 100 := by norm_num

-- Hand Euler the kick ΔW = −6 in one year-long step: 100 (1 + 3/100 − 6 · 1/5) = −17.
example : (100 : ℚ) * (1 + 3 / 100 - 6 * (1 / 5)) = -17 := by norm_num

-- The variance model sits on the boundary: 2κθ = 2 · ln 2 · (1/25) equals η² = (2/25) ln 2.
example : 2 * Real.log 2 * (1 / 25) = 2 / 25 * Real.log 2 := by ring

-- The exact average of next year's variance, with e^(−κ) = 1/2: 9/100 · 1/2 + 1/25 · 1/2 = 0.065.
example : (9 / 100 : ℚ) * (1 / 2) + 1 / 25 * (1 - 1 / 2) = 65 / 1000 := by norm_num

-- Its exact variance, η² (v e^(−κ)(1 − e^(−κ)) + θ (1 − e^(−κ))²/2) / κ, where η²/κ = 2/25:
-- 2/25 · (9/100 · 1/4 + 1/25 · 1/4 / 2) = 0.0022.
example : (2 / 25 : ℚ) * (9 / 100 * (1 / 2) * (1 - 1 / 2) + 1 / 25 * (1 - 1 / 2) ^ 2 / 2)
    = 22 / 10000 := by norm_num

-- The relative spread ψ = 0.0022 / 0.065² = 88/169, about 0.520710.
example : (22 / 10000 : ℚ) / (65 / 1000) ^ 2 = 88 / 169 := by norm_num

-- Doubling η multiplies the variance by four, to 0.0088, and ψ to 352/169, about 2.082840.
example : (4 : ℚ) * (22 / 10000) = 88 / 10000 ∧ (88 / 10000 : ℚ) / (65 / 1000) ^ 2 = 352 / 169 := by
  norm_num

-- The exponential branch there: p = (ψ − 1)/(ψ + 1) = 183/521, about 0.351248,
-- and β = (1 − p)/m = 5200/521, about 9.980806.
example : ((352 / 169 : ℚ) - 1) / (352 / 169 + 1) = 183 / 521 ∧
    (1 - 183 / 521 : ℚ) / (65 / 1000) = 5200 / 521 := by norm_num

-- That branch's mean (1 − p)/β and variance 2(1 − p)/β² − m² are exactly 0.065 and 0.0088.
example : (1 - 183 / 521 : ℚ) / (5200 / 521) = 65 / 1000 ∧
    2 * (1 - 183 / 521 : ℚ) / (5200 / 521) ^ 2 - (65 / 1000) ^ 2 = 88 / 10000 := by norm_num

#print axioms euler_path_gap_exact
#print axioms milstein_path_gap_exact
#print axioms qe_matches_mean_and_variance
