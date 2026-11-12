-- The integrating factor: for y' + p(t)y = q(t) with p and q continuous on an interval, the weight e^(integral of p) makes the left side one derivative, the weighted-input formula is the only solution, and any two solutions differ by a multiple of 1/μ.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open intervalIntegral

/-- Helper: the running integral of a function continuous on an open interval through 0
has that function as its rate at each point of the interval. -/
theorem if_helper_hasDerivAt_integral
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (h0 : (0 : ℝ) ∈ I)
    (f : ℝ → ℝ) (hf : ContinuousOn f I) (t : ℝ) (ht : t ∈ I) :
    HasDerivAt (fun u => ∫ x in (0 : ℝ)..u, f x) (f t) t := by
  apply integral_hasDerivAt_right
  · exact (hf.mono (hIc.uIcc_subset h0 ht)).intervalIntegrable
  · exact hf.stronglyMeasurableAtFilter hIo t ht
  · exact hf.continuousAt (hIo.mem_nhds ht)

/-- Helper: a function with rate 0 at every point of an open interval through 0 keeps its
value at 0 across the interval. -/
theorem if_helper_const
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (h0 : (0 : ℝ) ∈ I)
    (z : ℝ → ℝ) (hz : ∀ t ∈ I, HasDerivAt z 0 t) (t : ℝ) (ht : t ∈ I) : z t = z 0 := by
  refine hIo.is_const_of_deriv_eq_zero hIc.isPreconnected
    (fun x hx => (hz x hx).differentiableAt.differentiableWithinAt) ?_ ht h0
  intro x hx
  exact (hz x hx).deriv

/-- Helper: the weight μ(t) = e^(∫₀ᵗ p) has rate μ(t) p(t) on the interval. -/
theorem if_helper_hasDerivAt_exp
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (h0 : (0 : ℝ) ∈ I)
    (p : ℝ → ℝ) (hp : ContinuousOn p I) (t : ℝ) (ht : t ∈ I) :
    HasDerivAt (fun s => Real.exp (∫ r in (0 : ℝ)..s, p r))
      (Real.exp (∫ r in (0 : ℝ)..t, p r) * p t) t :=
  (if_helper_hasDerivAt_integral I hIo hIc h0 p hp t ht).exp

/-- Helper: the weight times q is continuous on the interval. -/
theorem if_helper_continuousOn
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (h0 : (0 : ℝ) ∈ I)
    (p q : ℝ → ℝ) (hp : ContinuousOn p I) (hq : ContinuousOn q I) :
    ContinuousOn (fun s => Real.exp (∫ r in (0 : ℝ)..s, p r) * q s) I := by
  refine ContinuousOn.mul ?_ hq
  intro x hx
  exact (if_helper_hasDerivAt_exp I hIo hIc h0 p hp x hx).continuousAt.continuousWithinAt

/-- The method: let p and q be continuous on an open interval I containing the start 0, and let
μ(t) = e^(∫₀ᵗ p). Then y(t) = (y₀ + ∫₀ᵗ μ(s) q(s) ds) / μ(t) starts at y₀ and solves
y' + p(t) y = q(t) at every point of I, and every solution of y' + p y = q on I with y(0) = y₀
equals it on the whole of I: exactly one solution, lasting on the whole interval. -/
theorem integrating_factor_formula_is_the_only_solution
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (h0 : (0 : ℝ) ∈ I)
    (p q : ℝ → ℝ) (hp : ContinuousOn p I) (hq : ContinuousOn q I) (y₀ : ℝ) :
    ((fun t => (y₀ + ∫ s in (0 : ℝ)..t, Real.exp (∫ r in (0 : ℝ)..s, p r) * q s)
          / Real.exp (∫ r in (0 : ℝ)..t, p r)) 0 = y₀ ∧
      ∀ t ∈ I, HasDerivAt
        (fun t => (y₀ + ∫ s in (0 : ℝ)..t, Real.exp (∫ r in (0 : ℝ)..s, p r) * q s)
          / Real.exp (∫ r in (0 : ℝ)..t, p r))
        (q t - p t * ((y₀ + ∫ s in (0 : ℝ)..t, Real.exp (∫ r in (0 : ℝ)..s, p r) * q s)
          / Real.exp (∫ r in (0 : ℝ)..t, p r))) t) ∧
    ∀ y : ℝ → ℝ, y 0 = y₀ → (∀ t ∈ I, HasDerivAt y (q t - p t * y t) t) →
      ∀ t ∈ I, y t = (y₀ + ∫ s in (0 : ℝ)..t, Real.exp (∫ r in (0 : ℝ)..s, p r) * q s)
          / Real.exp (∫ r in (0 : ℝ)..t, p r) := by
  have hμ := if_helper_hasDerivAt_exp I hIo hIc h0 p hp
  have hG := if_helper_hasDerivAt_integral I hIo hIc h0 _ (if_helper_continuousOn I hIo hIc h0 p q hp hq)
  refine ⟨⟨by simp, ?_⟩, ?_⟩
  · intro t ht
    have hpos := Real.exp_pos (∫ r in (0 : ℝ)..t, p r)
    have := ((hG t ht).const_add y₀).div (hμ t ht) hpos.ne'
    convert this using 1
    field_simp
  · intro y hy0 hy t ht
    have hz : ∀ t ∈ I, HasDerivAt
        (fun s => Real.exp (∫ r in (0 : ℝ)..s, p r) * y s
          - ∫ s in (0 : ℝ)..s, Real.exp (∫ r in (0 : ℝ)..s, p r) * q s) 0 t := by
      intro t ht
      have := ((hμ t ht).mul (hy t ht)).sub (hG t ht)
      convert this using 1
      ring
    have hc := if_helper_const I hIo hIc h0 _ hz t ht
    simp only [integral_same, Real.exp_zero, one_mul, sub_zero, hy0] at hc
    have hpos := Real.exp_pos (∫ r in (0 : ℝ)..t, p r)
    rw [eq_div_iff hpos.ne']
    linarith

/-- Step 2, the collapse: with p continuous on an open interval I containing 0 and
μ(t) = e^(∫₀ᵗ p), multiplying by μ turns the left side y' + p y into one derivative:
at every t in I where y has rate y'(t), the product μ y has rate μ(t) (y'(t) + p(t) y(t)). -/
theorem integrating_factor_left_side_is_one_derivative
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (h0 : (0 : ℝ) ∈ I)
    (p : ℝ → ℝ) (hp : ContinuousOn p I) (y : ℝ → ℝ) (y' t : ℝ) (ht : t ∈ I)
    (hy : HasDerivAt y y' t) :
    HasDerivAt (fun s => Real.exp (∫ r in (0 : ℝ)..s, p r) * y s)
      (Real.exp (∫ r in (0 : ℝ)..t, p r) * (y' + p t * y t)) t := by
  have := (if_helper_hasDerivAt_exp I hIo hIc h0 p hp t ht).mul hy
  convert this using 1
  ring

/-- Step 4, transient plus forced: with p continuous on an open interval I containing 0, any two
solutions of y' + p y = q on I differ by a multiple of 1/μ, namely
y₁(t) − y₂(t) = (y₁(0) − y₂(0)) / e^(∫₀ᵗ p). -/
theorem solutions_differ_by_multiple_of_inverse_factor
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (h0 : (0 : ℝ) ∈ I)
    (p q : ℝ → ℝ) (hp : ContinuousOn p I) (y₁ y₂ : ℝ → ℝ)
    (h₁ : ∀ t ∈ I, HasDerivAt y₁ (q t - p t * y₁ t) t)
    (h₂ : ∀ t ∈ I, HasDerivAt y₂ (q t - p t * y₂ t) t) :
    ∀ t ∈ I, y₁ t - y₂ t = (y₁ 0 - y₂ 0) / Real.exp (∫ r in (0 : ℝ)..t, p r) := by
  have hμ := if_helper_hasDerivAt_exp I hIo hIc h0 p hp
  have hz : ∀ t ∈ I, HasDerivAt
      (fun s => Real.exp (∫ r in (0 : ℝ)..s, p r) * (y₁ s - y₂ s)) 0 t := by
    intro t ht
    have := (hμ t ht).mul ((h₁ t ht).sub (h₂ t ht))
    convert this using 1
    simp only [Pi.sub_apply]
    ring
  intro t ht
  have hc := if_helper_const I hIo hIc h0 _ hz t ht
  simp only [integral_same, Real.exp_zero, one_mul] at hc
  have hpos := Real.exp_pos (∫ r in (0 : ℝ)..t, p r)
  rw [eq_div_iff hpos.ne']
  linarith

-- The room: T(t) = 20 + sin t − 2 cos t − 8e^(−t/2) solves T' + T/2 = 10 + (5/2) sin t.
example (t : ℝ) :
    HasDerivAt (fun t => 20 + Real.sin t - 2 * Real.cos t - 8 * Real.exp (-(1 / 2) * t))
      (10 + 5 / 2 * Real.sin t
        - 1 / 2 * (20 + Real.sin t - 2 * Real.cos t - 8 * Real.exp (-(1 / 2) * t))) t := by
  have h := ((((Real.hasDerivAt_sin t).const_add 20).sub ((Real.hasDerivAt_cos t).const_mul 2)).sub
    ((((hasDerivAt_id t).const_mul (-(1 / 2 : ℝ))).exp).const_mul 8))
  convert h using 1
  · funext x; simp [Real.sin, Real.cos]
  · simp
    ring

-- The room starts at 10 C.
example : (20 : ℝ) + Real.sin 0 - 2 * Real.cos 0 - 8 * Real.exp (-(1 / 2) * 0) = 10 := by
  simp
  norm_num

-- The transient's size: C = 10 − 20 + 2 = −8.
example : (10 : ℤ) - 20 + 2 = -8 := by norm_num

-- The forced height squared: 1² + (−2)² = 5, so the height is √5.
example : (1 : ℤ) ^ 2 + (-2) ^ 2 = 5 := by norm_num

-- The coffee: T = 20 + 60e^(−t/10) reaches 50 C at t = 10 ln 2.
example : (20 : ℝ) + 60 * Real.exp (-(1 / 10) * (10 * Real.log 2)) = 50 := by
  have : -(1 / 10 : ℝ) * (10 * Real.log 2) = -Real.log 2 := by ring
  rw [this, Real.exp_neg, Real.exp_log (by norm_num)]
  norm_num

#print axioms if_helper_hasDerivAt_integral
#print axioms if_helper_const
#print axioms if_helper_hasDerivAt_exp
#print axioms if_helper_continuousOn
#print axioms integrating_factor_formula_is_the_only_solution
#print axioms integrating_factor_left_side_is_one_derivative
#print axioms solutions_differ_by_multiple_of_inverse_factor
