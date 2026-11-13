-- Transforming a derivative: for a signal with no jump whose rate is continuous and which, with its rate, grows no faster than M e^(at), the transform of the rate is s times the transform minus the starting value at every s with Re s > a; twice over it gives s^2 Y − s y(0) − y'(0), so the car's equation y'' + 2y' + 5y = 0 becomes (s^2 + 2s + 5) Y = (s + 2) y(0) + y'(0).
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals

open MeasureTheory Set Complex

/-- The card's Laplace transform: `Y(s) = ∫₀^∞ e^(−st) y(t) dt`, a signal `y` from time zero
on, weighted by `e^(−st)` for a complex number `s`, and added up. -/
noncomputable def laplace (y : ℝ → ℂ) (s : ℂ) : ℂ :=
  ∫ t in Ioi (0 : ℝ), cexp (-(s * t)) * y t

lemma laplace_kernel_norm (s : ℂ) (y : ℝ → ℂ) (M a t : ℝ)
    (h : ‖y t‖ ≤ M * Real.exp (a * t)) :
    ‖cexp (-(s * t)) * y t‖ ≤ M * Real.exp ((a - s.re) * t) := by
  rw [norm_mul, Complex.norm_exp]
  have e : (-(s * (t : ℂ))).re = -(s.re * t) := by simp
  rw [e]
  calc Real.exp (-(s.re * t)) * ‖y t‖ ≤ Real.exp (-(s.re * t)) * (M * Real.exp (a * t)) :=
        mul_le_mul_of_nonneg_left h (Real.exp_pos _).le
    _ = M * Real.exp ((a - s.re) * t) := by
        rw [show (a - s.re) * t = a * t + -(s.re * t) by ring, Real.exp_add]; ring

lemma laplace_integrableOn (y : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hy : ContinuousOn y (Ici 0))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖y t‖ ≤ M * Real.exp (a * t))
    (hs : a < s.re) :
    IntegrableOn (fun t : ℝ => cexp (-(s * t)) * y t) (Ioi 0) := by
  have hint : IntegrableOn (fun t : ℝ => M * Real.exp ((a - s.re) * t)) (Ioi 0) :=
    (integrableOn_exp_mul_Ioi (by linarith) 0).const_mul M
  refine hint.mono' ?_ ?_
  · refine ContinuousOn.aestronglyMeasurable ?_ measurableSet_Ioi
    refine ContinuousOn.mul ?_ (hy.mono Ioi_subset_Ici_self)
    fun_prop
  · filter_upwards [ae_restrict_mem measurableSet_Ioi] with t ht
    exact laplace_kernel_norm s y M a t (hgrowth t (le_of_lt ht))

lemma laplace_kernel_hasDerivAt (s : ℂ) (t : ℝ) :
    HasDerivAt (fun t : ℝ => cexp (-(s * t))) (-s * cexp (-(s * t))) t := by
  have h := (((hasDerivAt_id t).ofReal_comp).const_mul (-s)).cexp
  convert h using 1
  · funext x; simp
  · simp; ring

open Filter Topology in
theorem laplace_deriv_aux (y y' : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hy : ContinuousOn y (Ici 0))
    (hderiv : ∀ t ∈ Ioi (0 : ℝ), HasDerivAt y (y' t) t)
    (hy' : ContinuousOn y' (Ici 0))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖y t‖ ≤ M * Real.exp (a * t))
    (hgrowth' : ∀ t : ℝ, 0 ≤ t → ‖y' t‖ ≤ M * Real.exp (a * t))
    (hs : a < s.re) :
    laplace y' s = s * laplace y s - y 0 := by
  have hI := laplace_integrableOn y M a s hy hgrowth hs
  have hI' := laplace_integrableOn y' M a s hy' hgrowth' hs
  have hzero : Tendsto ((fun t : ℝ => cexp (-(s * t))) * y) (𝓝[>] 0) (𝓝 (y 0)) := by
    have hc : ContinuousWithinAt ((fun t : ℝ => cexp (-(s * t))) * y) (Ioi 0) 0 := by
      refine ContinuousWithinAt.mul ?_ ((hy 0 self_mem_Ici).mono Ioi_subset_Ici_self)
      exact (by fun_prop : Continuous fun t : ℝ => cexp (-(s * t))).continuousWithinAt
    simpa using hc.tendsto
  have hinf : Tendsto ((fun t : ℝ => cexp (-(s * t))) * y) atTop (𝓝 0) := by
    have hb : Tendsto (fun t : ℝ => M * Real.exp ((a - s.re) * t)) atTop (𝓝 0) := by
      have : Tendsto (fun t : ℝ => (a - s.re) * t) atTop atBot :=
        tendsto_id.const_mul_atTop_of_neg (by linarith)
      simpa using (Real.tendsto_exp_atBot.comp this).const_mul M
    refine squeeze_zero_norm' ?_ hb
    filter_upwards [eventually_ge_atTop 0] with t ht
    exact laplace_kernel_norm s y M a t (hgrowth t ht)
  have hparts := integral_Ioi_mul_deriv_eq_deriv_mul
    (u := fun t : ℝ => cexp (-(s * t))) (u' := fun t : ℝ => -s * cexp (-(s * t)))
    (v := y) (v' := y')
    (fun t _ => laplace_kernel_hasDerivAt s t) hderiv hI'
    (by
      refine IntegrableOn.congr_fun (hI.const_mul (-s)) (fun t _ => ?_) measurableSet_Ioi
      simp only [Pi.mul_apply]; ring)
    hzero hinf
  unfold laplace
  rw [hparts]
  have : (∫ t in Ioi (0:ℝ), -s * cexp (-(s * t)) * y t)
      = -s * ∫ t in Ioi (0:ℝ), cexp (-(s * t)) * y t := by
    rw [← integral_const_mul]; congr 1; ext t; ring
  rw [this]; ring

#print axioms laplace_kernel_norm
#print axioms laplace_integrableOn
#print axioms laplace_kernel_hasDerivAt
#print axioms laplace_deriv_aux

/-- The derivative rule: if the signal `y` has no jump from time zero on, has rate `y'` after
time zero with `y'` continuous from time zero on, and both `y` and `y'` stay below `M e^(at)` in
size, then at every `s` with real part above `a` the transform of the rate is `s Y(s) − y(0)`. -/
theorem laplace_deriv_eq_mul_sub_initial (y y' : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hy : ContinuousOn y (Ici 0))
    (hderiv : ∀ t ∈ Ioi (0 : ℝ), HasDerivAt y (y' t) t)
    (hy' : ContinuousOn y' (Ici 0))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖y t‖ ≤ M * Real.exp (a * t))
    (hgrowth' : ∀ t : ℝ, 0 ≤ t → ‖y' t‖ ≤ M * Real.exp (a * t))
    (hs : a < s.re) :
    laplace y' s = s * laplace y s - y 0 := by
  exact laplace_deriv_aux y y' M a s hy hderiv hy' hgrowth hgrowth' hs

/-- The second-derivative rule: if `y`, its rate `y'` and its acceleration `y''` are continuous
from time zero on, `y'` is the rate of `y` and `y''` the rate of `y'` after time zero, and all
three stay below `M e^(at)` in size, then at every `s` with real part above `a` the transform of
the acceleration is `s² Y(s) − s y(0) − y'(0)`. -/
theorem laplace_second_deriv (y y' y'' : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hy : ContinuousOn y (Ici 0))
    (hderiv : ∀ t ∈ Ioi (0 : ℝ), HasDerivAt y (y' t) t)
    (hy' : ContinuousOn y' (Ici 0))
    (hderiv' : ∀ t ∈ Ioi (0 : ℝ), HasDerivAt y' (y'' t) t)
    (hy'' : ContinuousOn y'' (Ici 0))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖y t‖ ≤ M * Real.exp (a * t))
    (hgrowth' : ∀ t : ℝ, 0 ≤ t → ‖y' t‖ ≤ M * Real.exp (a * t))
    (hgrowth'' : ∀ t : ℝ, 0 ≤ t → ‖y'' t‖ ≤ M * Real.exp (a * t))
    (hs : a < s.re) :
    laplace y'' s = s ^ 2 * laplace y s - s * y 0 - y' 0 := by
  rw [laplace_deriv_eq_mul_sub_initial y' y'' M a s hy' hderiv' hy'' hgrowth' hgrowth'' hs,
    laplace_deriv_eq_mul_sub_initial y y' M a s hy hderiv hy' hgrowth hgrowth' hs]
  ring

/-- The car's transformed equation: if `y` solves `y'' + 2y' + 5y = 0` from time zero on, under
the same hypotheses as the second-derivative rule, then at every `s` with real part above `a`
the starting values land on the known side: `(s² + 2s + 5) Y(s) = (s + 2) y(0) + y'(0)`. -/
theorem laplace_car_equation (y y' y'' : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hy : ContinuousOn y (Ici 0))
    (hderiv : ∀ t ∈ Ioi (0 : ℝ), HasDerivAt y (y' t) t)
    (hy' : ContinuousOn y' (Ici 0))
    (hderiv' : ∀ t ∈ Ioi (0 : ℝ), HasDerivAt y' (y'' t) t)
    (hy'' : ContinuousOn y'' (Ici 0))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖y t‖ ≤ M * Real.exp (a * t))
    (hgrowth' : ∀ t : ℝ, 0 ≤ t → ‖y' t‖ ≤ M * Real.exp (a * t))
    (hgrowth'' : ∀ t : ℝ, 0 ≤ t → ‖y'' t‖ ≤ M * Real.exp (a * t))
    (hode : ∀ t : ℝ, 0 ≤ t → y'' t + 2 * y' t + 5 * y t = 0)
    (hs : a < s.re) :
    (s ^ 2 + 2 * s + 5) * laplace y s = (s + 2) * y 0 + y' 0 := by
  have h1 := laplace_deriv_eq_mul_sub_initial y y' M a s hy hderiv hy' hgrowth hgrowth' hs
  have h2 := laplace_second_deriv y y' y'' M a s hy hderiv hy' hderiv' hy'' hgrowth hgrowth'
    hgrowth'' hs
  have hI := laplace_integrableOn y M a s hy hgrowth hs
  have hI' := laplace_integrableOn y' M a s hy' hgrowth' hs
  have hI'' := laplace_integrableOn y'' M a s hy'' hgrowth'' hs
  have h0 : laplace y'' s + 2 * laplace y' s + 5 * laplace y s = 0 := by
    unfold laplace
    rw [← integral_const_mul, ← integral_const_mul, ← integral_add hI'' (hI'.const_mul 2),
      ← integral_add ?_ (hI.const_mul 5)]
    swap
    · exact hI''.add (hI'.const_mul 2)
    rw [setIntegral_congr_fun measurableSet_Ioi (g := fun _ => (0:ℂ)) ?_]
    · simp
    · intro t ht
      simp only
      have := hode t (le_of_lt ht)
      linear_combination cexp (-(s * t)) * this
  rw [h1, h2] at h0
  linear_combination h0

-- Worked numbers, exact.
-- At s = 2 with y(0) = 1, y'(0) = 0: (s^2 + 2s + 5) Y = s + 2 reads 13 Y = 4, so Y = 4/13.
example : ((2 : ℚ) ^ 2 + 2 * 2 + 5) = 13 ∧ (2 + 2 : ℚ) * 1 + 0 = 4 ∧ (13 : ℚ) * (4 / 13) = 4 := by
  norm_num
-- Transform of the velocity: sY − y(0) = 8/13 − 1 = −5/13 (−0.384615).
example : (2 : ℚ) * (4 / 13) - 1 = -5 / 13 := by norm_num
-- Transform of the acceleration: s^2 Y − s y(0) − y'(0) = 16/13 − 2 − 0 = −10/13 (−0.769231).
example : (2 : ℚ) ^ 2 * (4 / 13) - 2 * 1 - 0 = -10 / 13 := by norm_num
-- Back into the rate law: −10/13 + 2(−5/13) + 5(4/13) = 0.
example : (-10 / 13 : ℚ) + 2 * (-5 / 13) + 5 * (4 / 13) = 0 := by norm_num
-- At s = 0: Y = 2/5, sY − y(0) = −1, s^2 Y − s y(0) − y'(0) = 0.
example : ((0 : ℚ) + 2) / (0 ^ 2 + 2 * 0 + 5) = 2 / 5 ∧ (0 : ℚ) * (2 / 5) - 1 = -1 ∧
    (0 : ℚ) ^ 2 * (2 / 5) - 0 * 1 - 0 = 0 := by norm_num
-- Mistake 1: taking the velocity's transform as sY gives 8/13 (0.615385), and the equation
-- becomes 13 Y = 0, forcing Y = 0.
example : (2 : ℚ) * (4 / 13) = 8 / 13 := by norm_num
example (Y : ℚ) (h : (13 : ℚ) * Y = 0) : Y = 0 := by linarith
-- Mistake 2: s^2 Y − y(0) − y'(0) puts y(0) + y'(0) + 2 y(0) = 3 on the right: Y = 3/13 (0.230769).
example : ((1 : ℚ) + 0 + 2 * 1) / 13 = 3 / 13 := by norm_num

#print axioms laplace_deriv_eq_mul_sub_initial
#print axioms laplace_second_deriv
#print axioms laplace_car_equation
