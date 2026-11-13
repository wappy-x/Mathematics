-- A short-rate model: if every riskless two-bond hedge earns the bank rate, all zeros share one market price of risk and satisfy the term structure equation; a normal path area I gives E[e^-I] = e^(-m + v/2); and the Vasicek closed form solves the equation with value 1 at maturity.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Probability.Distributions.Gaussian.Real

open Real MeasureTheory ProbabilityTheory
open scoped NNReal

/-- Helper: the derivative of `y ↦ exp (C - b y)`. -/
theorem tse_hasDerivAt_exp_affine (C b x : ℝ) :
    HasDerivAt (fun y => Real.exp (C - b * y)) (-b * Real.exp (C - b * x)) x := by
  have h := (((hasDerivAt_id x).const_mul b).const_sub C).exp
  refine h.congr_deriv ?_
  simp only [id]
  ring

/-- Helper: the clock derivative of the Vasicek closed form. -/
theorem tse_vasicek_time_deriv (a K c T r t : ℝ) (ha : a ≠ 0) :
    HasDerivAt
      (fun u => Real.exp (K * ((1 - Real.exp (-(a * (T - u)))) / a - (T - u))
        - c * ((1 - Real.exp (-(a * (T - u)))) / a) ^ 2 / (4 * a)
        - (1 - Real.exp (-(a * (T - u)))) / a * r))
      (Real.exp (K * ((1 - Real.exp (-(a * (T - t)))) / a - (T - t))
        - c * ((1 - Real.exp (-(a * (T - t)))) / a) ^ 2 / (4 * a)
        - (1 - Real.exp (-(a * (T - t)))) / a * r)
        * (K * a * ((1 - Real.exp (-(a * (T - t)))) / a)
          + c * ((1 - Real.exp (-(a * (T - t)))) / a) * Real.exp (-(a * (T - t))) / (2 * a)
          + Real.exp (-(a * (T - t))) * r)) t := by
  have hT : HasDerivAt (fun u : ℝ => T - u) (-1) t := by
    simpa using (hasDerivAt_id t).const_sub T
  have hE : HasDerivAt (fun u => Real.exp (-(a * (T - u))))
      (Real.exp (-(a * (T - t))) * -(a * -1)) t := (hT.const_mul a).neg.exp
  have hB := (hE.const_sub 1).div_const a
  have hL := hB.sub hT
  have hSq := ((hB.pow 2).const_mul c).div_const (4 * a)
  have hR := hB.mul_const r
  have h := (((hL.const_mul K).sub hSq).sub hR).exp
  refine h.congr_deriv ?_
  simp only [Pi.sub_apply, Pi.pow_apply]
  generalize Real.exp (-(a * (T - t))) = e
  have hinv : a * a⁻¹ = 1 := mul_inv_cancel₀ ha
  field_simp
  linear_combination (4 * e * c - 4 * e ^ 2 * c) * hinv

/-- Steps 2 to 4. One random rate drives every zero. At each date `t` and rate `r`, the zero
maturing at `T` has price `P T t r`, with clock slope `p_t`, rate slope `p_r` and curvature
`p_rr`. The rate drifts at `μ t r` with volatility `s t r`. By Itô's lemma the zero's expected
return is `α = (p_t + μ p_r + ½ s² p_rr) / p` and its volatility is `β = -s p_r / p`. Each zero
moves with the rate (`s p_r ≠ 0`). If, for every two zeros alive at `t`, the hedge holding
`β_{T₂}` dollars of the first and `-β_{T₁}` dollars of the second earns exactly the bank rate on
its value, then there is one market price of risk `λ`, depending only on the date and today's
rate, such that every zero satisfies the term structure equation
`p_t + (μ + λ s) p_r + ½ s² p_rr - r p = 0`. -/
theorem term_structure_equation_of_no_arbitrage
    (P : ℝ → ℝ → ℝ → ℝ) (μ s : ℝ → ℝ → ℝ) (α β : ℝ → ℝ → ℝ → ℝ)
    (hα : ∀ T t r, α T t r =
      (deriv (fun u => P T u r) t + μ t r * deriv (fun x => P T t x) r
        + 1 / 2 * s t r ^ 2 * deriv (fun x => deriv (fun y => P T t y) x) r) / P T t r)
    (hβ : ∀ T t r, β T t r = -(s t r * deriv (fun x => P T t x) r) / P T t r)
    (hP : ∀ T t r, t < T → P T t r ≠ 0)
    (hmoves : ∀ T t r, t < T → s t r * deriv (fun x => P T t x) r ≠ 0)
    (hhedge : ∀ T₁ T₂ t r, t < T₁ → t < T₂ →
      β T₂ t r * α T₁ t r - β T₁ t r * α T₂ t r = r * (β T₂ t r - β T₁ t r)) :
    ∃ lam : ℝ → ℝ → ℝ, ∀ T t r, t < T →
      deriv (fun u => P T u r) t + (μ t r + lam t r * s t r) * deriv (fun x => P T t x) r
        + 1 / 2 * s t r ^ 2 * deriv (fun x => deriv (fun y => P T t y) x) r
        - r * P T t r = 0 := by
  refine ⟨fun t r => (α (t + 1) t r - r) / β (t + 1) t r, fun T t r hT => ?_⟩
  have h1 : t < t + 1 := by linarith
  have hb : ∀ T', t < T' → β T' t r ≠ 0 := by
    intro T' hT' h0
    have := hβ T' t r
    rw [h0, eq_comm, div_eq_zero_iff] at this
    rcases this with h | h
    · exact hmoves T' t r hT' (neg_eq_zero.mp h)
    · exact hP T' t r hT' h
  have hh := hhedge T (t + 1) t r hT h1
  have hb1 := hb (t + 1) h1
  have hPT := hP T t r hT
  have ha := hα T t r
  have hbT := hβ T t r
  rw [eq_div_iff hPT] at ha hbT
  generalize deriv (fun u => P T u r) t = D1 at *
  generalize deriv (fun x => P T t x) r = D2 at *
  generalize deriv (fun x => deriv (fun y => P T t y) x) r = D3 at *
  have key : α T t r - r = (α (t + 1) t r - r) / β (t + 1) t r * β T t r := by
    field_simp
    linarith
  linear_combination -ha + (α (t + 1) t r - r) / β (t + 1) t r * hbT + P T t r * key

/-- Step 6. If the area `I` under the rate's path is normal with mean `m` and variance `v`,
then the average of the path discount `e^{-I}` is `e^{-m + v/2}`. -/
theorem average_discount_of_normal_area
    {Ω : Type*} [MeasurableSpace Ω] (Q : Measure Ω) [IsProbabilityMeasure Q]
    (I : Ω → ℝ) (m : ℝ) (v : ℝ≥0) (hI : HasLaw I (gaussianReal m v) Q) :
    ∫ ω, Real.exp (-I ω) ∂Q = Real.exp (-m + v / 2) := by
  have h := mgf_gaussianReal hI (-1)
  simp only [mgf] at h
  have e : (fun ω => Real.exp (-1 * I ω)) = fun ω => Real.exp (-I ω) := by
    funext ω; ring_nf
  rw [e] at h
  rw [h]
  congr 1
  ring

/-- The equation, checked on the example model. With the rate pulled toward `θ` at speed
`a > 0` and volatility `σ` in the pricing world, the closed-form zero price
`p(t, r) = exp((θ - σ²/(2a²))(B - τ) - σ² B²/(4a) - B r)`, where `τ = T - t` and
`B = (1 - e^{-aτ})/a`, solves `p_t + a(θ - r) p_r + ½ σ² p_rr - r p = 0` at every date and
rate, and is worth exactly 1 at maturity. -/
theorem vasicek_price_solves_term_structure_equation
    (a θ σ T : ℝ) (ha : 0 < a) :
    let B : ℝ → ℝ := fun τ => (1 - Real.exp (-(a * τ))) / a
    let p : ℝ → ℝ → ℝ := fun t r =>
      Real.exp ((θ - σ ^ 2 / (2 * a ^ 2)) * (B (T - t) - (T - t))
        - σ ^ 2 * B (T - t) ^ 2 / (4 * a) - B (T - t) * r)
    (∀ t r, deriv (fun u => p u r) t + a * (θ - r) * deriv (fun x => p t x) r
        + 1 / 2 * σ ^ 2 * deriv (fun x => deriv (fun y => p t y) x) r - r * p t r = 0)
      ∧ ∀ r, p T r = 1 := by
  intro B p
  have ha0 : a ≠ 0 := ha.ne'
  refine ⟨fun t r => ?_, fun r => ?_⟩
  · have hr : ∀ x, HasDerivAt (fun y => p t y) (-(B (T - t)) * p t x) x := fun x =>
      tse_hasDerivAt_exp_affine _ _ x
    have hd1 : deriv (fun y => p t y) = fun x => -(B (T - t)) * p t x :=
      funext fun x => (hr x).deriv
    have hd2 : deriv (fun x => deriv (fun y => p t y) x) r
        = -(B (T - t)) * (-(B (T - t)) * p t r) := by
      rw [hd1]
      exact ((hr r).const_mul _).deriv
    have ht : HasDerivAt (fun u => p u r) (p t r
        * ((θ - σ ^ 2 / (2 * a ^ 2)) * a * B (T - t)
          + σ ^ 2 * B (T - t) * Real.exp (-(a * (T - t))) / (2 * a)
          + Real.exp (-(a * (T - t))) * r)) t :=
      tse_vasicek_time_deriv a (θ - σ ^ 2 / (2 * a ^ 2)) (σ ^ 2) T r t ha0
    rw [ht.deriv, hd2, (hr r).deriv]
    have hBv : B (T - t) = (1 - Real.exp (-(a * (T - t)))) / a := rfl
    rw [hBv]
    field_simp
    ring
  · simp [p, B]

-- The card's example: a real-world level of 4.5% with market price of risk 0.15, volatility 1%
-- and speed 0.3 prices bonds as if the rate were pulled toward 5%.
example : (45 / 1000 : ℚ) + 15 / 100 * (1 / 100) / (3 / 10) = 5 / 100 := by norm_num

-- Flipping the market price of risk to -0.15 keeps the 5% pricing level with a 5.5% real level.
example : (55 / 1000 : ℚ) + (-15 / 100) * (1 / 100) / (3 / 10) = 5 / 100 := by norm_num

#print axioms tse_hasDerivAt_exp_affine
#print axioms tse_vasicek_time_deriv
#print axioms term_structure_equation_of_no_arbitrage
#print axioms average_discount_of_normal_area
#print axioms vasicek_price_solves_term_structure_equation
