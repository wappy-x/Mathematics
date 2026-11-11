-- Derivatives from the boundary: for f holomorphic on and inside a circle, every derivative at an inside point is n!/(2πi) times the loop integral of f(z)/(z - a)^(n+1), every derivative of a holomorphic function is again holomorphic, and Cauchy's estimate caps the n-th derivative at the centre by n! M / r^n.
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Complex.Liouville
import Mathlib.Analysis.Complex.RemovableSingularity
import Mathlib.Analysis.Calculus.DSlope

open Complex Metric Real

theorem dslope_coeff_aux (f : ℂ → ℂ) (a : ℂ) (hf : AnalyticAt ℂ f a) (n : ℕ) :
    iteratedDeriv n (dslope f a) a / (n.factorial : ℂ) =
      iteratedDeriv (n + 1) f a / ((n + 1).factorial : ℂ) := by
  have h1 := hf.hasFPowerSeriesAt
  have h2 := h1.dslope_fslope
  have h4 := h2.analyticAt.hasFPowerSeriesAt
  have h5 := h4.eq_formalMultilinearSeries h2
  have h6 := congrArg (fun p => p.coeff n) h5
  simpa [FormalMultilinearSeries.coeff_fslope, FormalMultilinearSeries.coeff_ofScalars] using h6

#print axioms dslope_coeff_aux

theorem loop_aux (c a : ℂ) (R : ℝ) (ha : a ∈ ball c R) (n : ℕ) :
    ∀ f : ℂ → ℂ, DifferentiableOn ℂ f (closedBall c R) →
      ∮ z in C(c, R), f z / (z - a) ^ (n + 1) =
        (2 * π * I) / (n.factorial : ℂ) * iteratedDeriv n f a := by
  have hR : 0 < R := lt_of_le_of_lt dist_nonneg ha
  have hne : ∀ z ∈ sphere c R, z - a ≠ 0 := by
    intro z hz h
    rw [sub_eq_zero] at h
    subst h
    rw [mem_sphere] at hz
    rw [mem_ball] at ha
    linarith
  induction n with
  | zero =>
    intro f hf
    have := hf.circleIntegral_sub_inv_smul ha
    simp only [zero_add, pow_one, Nat.factorial_zero, Nat.cast_one, div_one, iteratedDeriv_zero]
    rw [← smul_eq_mul, ← this]
    congr 1
    funext z
    simp [div_eq_inv_mul]
  | succ n ih =>
    intro f hf
    have hnhds : closedBall c R ∈ nhds a :=
      Filter.mem_of_superset (isOpen_ball.mem_nhds ha) ball_subset_closedBall
    have hd : DifferentiableOn ℂ (dslope f a) (closedBall c R) :=
      (Complex.differentiableOn_dslope hnhds).2 hf
    have han : AnalyticAt ℂ f a := hf.analyticAt hnhds
    have hsplit : ∮ z in C(c, R), f z / (z - a) ^ (n + 1 + 1) =
        ∮ z in C(c, R), (dslope f a z / (z - a) ^ (n + 1) + f a * (z - a) ^ (-(n + 2 : ℤ))) := by
      apply circleIntegral.integral_congr hR.le
      intro z hz
      have h0 := hne z hz
      have hza : z ≠ a := sub_ne_zero.mp h0
      simp only
      rw [dslope_of_ne _ hza, slope_def_field]
      rw [zpow_neg, show (n + 2 : ℤ) = ((n + 2 : ℕ) : ℤ) by push_cast; ring, zpow_natCast]
      field_simp
      ring
    have hi1 : CircleIntegrable (fun z => dslope f a z / (z - a) ^ (n + 1)) c R := by
      apply ContinuousOn.circleIntegrable hR.le
      apply ContinuousOn.div
      · exact hd.continuousOn.mono sphere_subset_closedBall
      · fun_prop
      · intro z hz; exact pow_ne_zero _ (hne z hz)
    have hi2 : CircleIntegrable (fun z => f a * (z - a) ^ (-(n + 2 : ℤ))) c R := by
      apply ContinuousOn.circleIntegrable hR.le
      apply ContinuousOn.mul continuousOn_const
      apply ContinuousOn.zpow₀ (by fun_prop)
      intro z hz; left; exact hne z hz
    rw [hsplit, circleIntegral.integral_add hi1 hi2, ih (dslope f a) hd]
    rw [circleIntegral.integral_const_mul, circleIntegral.integral_sub_zpow_of_ne (by omega), mul_zero,
      add_zero]
    have key := dslope_coeff_aux f a han n
    rw [mul_comm, ← mul_div_assoc, mul_comm (iteratedDeriv n (dslope f a) a), mul_div_assoc, key]
    ring

#print axioms loop_aux

/-- The derivative formula. Let `f` be holomorphic (complex differentiable) on and inside the
circle of radius `R` round `c`, and let `a` be a point strictly inside that circle. Then for every
`n`, the `n`-th derivative of `f` at `a` equals `n!/(2πi)` times the integral once round the circle,
anticlockwise, of `f(z)/(z - a)^(n+1)`. -/
theorem derivative_eq_loop_integral (f : ℂ → ℂ) (c a : ℂ) (R : ℝ) (n : ℕ)
    (hf : DifferentiableOn ℂ f (closedBall c R)) (ha : a ∈ ball c R) :
    iteratedDeriv n f a =
      (n.factorial : ℂ) / (2 * π * I) * ∮ z in C(c, R), f z / (z - a) ^ (n + 1) := by
  rw [loop_aux c a R ha n f hf]
  have h1 : (n.factorial : ℂ) ≠ 0 := by exact_mod_cast n.factorial_ne_zero
  have h2 : (2 * π * I : ℂ) ≠ 0 := two_pi_I_ne_zero
  field_simp

/-- Holomorphic once means holomorphic forever. If `f` is holomorphic on an open set `U`, then
for every `n` its `n`-th derivative is again holomorphic on `U`. -/
theorem holomorphic_once_means_holomorphic_forever (f : ℂ → ℂ) (U : Set ℂ) (hU : IsOpen U)
    (hf : DifferentiableOn ℂ f U) (n : ℕ) :
    DifferentiableOn ℂ (iteratedDeriv n f) U := by
  have ha : AnalyticOnNhd ℂ f U := hf.analyticOnNhd hU
  induction n generalizing f with
  | zero => simpa using hf
  | succ n ih =>
    rw [iteratedDeriv_succ']
    exact ih (deriv f) ha.deriv.differentiableOn ha.deriv

/-- Cauchy's estimate. Let `f` be holomorphic on and inside the circle of radius `r > 0` round
`a`, and let `|f(z)| ≤ M` at every point `z` of that circle. Then for every `n`, the size of the
`n`-th derivative of `f` at the centre `a` is at most `n! M / r^n`. -/
theorem cauchy_estimate (f : ℂ → ℂ) (a : ℂ) (r M : ℝ) (n : ℕ) (hr : 0 < r)
    (hf : DifferentiableOn ℂ f (closedBall a r)) (hM : ∀ z ∈ sphere a r, ‖f z‖ ≤ M) :
    ‖iteratedDeriv n f a‖ ≤ n.factorial * M / r ^ n := by
  exact norm_iteratedDeriv_le_of_forall_mem_sphere_norm_le n hr
    (hf.mono closure_ball_subset_closedBall).diffContOnCl hM

/-! Worked numbers from the card: f(z) = z^3, a = 1, the circle of radius 1 round 1. -/

-- Power rule: z^3, 3z^2, 6z, 6, 0 at z = 1 give 1, 3, 6, 6, 0.
example : ((1 : ℤ) ^ 3, 3 * 1 ^ 2, 6 * 1, 6, 0) = (1, 3, 6, 6, 0) := by norm_num

-- (1 + w)^3 = w^3 + 3w^2 + 3w + 1: the coefficients are 1, 3, 3, 1.
example : (List.range 4).map (Nat.choose 3) = [1, 3, 3, 1] := by decide

-- The loop: only the w^(-1) term, with coefficient 3, survives, so f''(1) = 2! × 3 = 6.
example : Nat.factorial 2 * 3 = 6 := by decide

-- Largest |z^3| on the loop is |2|^3 = 8.
example : (2 : ℕ) ^ 3 = 8 := by norm_num

-- Cauchy's bounds n! × 8 / 1^n for n = 0, 1, 2, 3, 4: 8, 8, 16, 48, 192.
example : (List.range 5).map (fun n => Nat.factorial n * 8 / 1 ^ n) = [8, 8, 16, 48, 192] := by
  decide

-- The bound 2(1 + r)^3 / r^2 at r = 1/2, 1, 2: 27, 16, 27/2 (the best, 13.5).
example : (2 : ℚ) * (1 + 1 / 2) ^ 3 / (1 / 2) ^ 2 = 27 := by norm_num
example : (2 : ℚ) * (1 + 1) ^ 3 / 1 ^ 2 = 16 := by norm_num
example : (2 : ℚ) * (1 + 2) ^ 3 / 2 ^ 2 = 27 / 2 := by norm_num

-- Mistake 1: the loop round 0 for 1/z gives 2! × 1/(0 - 1)^3 = -2, cancelling f''(1) = 2.
example : (Nat.factorial 2 : ℚ) * 1 / (0 - 1) ^ 3 = -2 := by norm_num

-- Mistake 3: M read at the centre, |f(1)| = 1, gives the "bound" 2! × 1 / 1^2 = 2, below 6.
example : Nat.factorial 2 * 1 / 1 ^ 2 = 2 ∧ 2 < 6 := by decide

-- Regatta triangle 0 → 2 → 1 + i: shoelace area 1, so z-bar gives 2i × 1.
example : ((0 : ℚ) * 0 - 2 * 0 + (2 * 1 - 1 * 0) + (1 * 0 - 0 * 1)) / 2 = 1 := by norm_num

#print axioms derivative_eq_loop_integral
#print axioms holomorphic_once_means_holomorphic_forever
#print axioms cauchy_estimate
