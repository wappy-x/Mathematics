-- The brachistochrone: when a cost F(y, y') ignores x, every Euler-Lagrange solution keeps F - y' * dF/dy' constant, so the fastest slide keeps y (1 + y'^2) constant, and the cycloid of radius R keeps it at 2R and is timed at sqrt(R/g) seconds per radian.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

open Real Set

/-- The Beltrami identity. Let the cost per unit across be F(y, p), a function of the depth y
and the slope p only, not of x (here F is twice continuously differentiable on an open set U).
If a twice continuously differentiable curve y on an open interval stays in U and solves the
Euler-Lagrange equation dF/dy = d/dx (dF/dp) there, then F - y' * dF/dp is constant along it.
Partial derivatives are written with `fderiv`: dF/dy at q is `fderiv ℝ F q (1, 0)` and
dF/dp at q is `fderiv ℝ F q (0, 1)`. -/
theorem beltrami_identity (F : ℝ × ℝ → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hF : ContDiffOn ℝ 2 F U) (y : ℝ → ℝ) (a b : ℝ)
    (hy : ContDiffOn ℝ 2 y (Ioo a b))
    (hyU : ∀ x ∈ Ioo a b, (y x, deriv y x) ∈ U)
    (hEL : ∀ x ∈ Ioo a b,
      fderiv ℝ F (y x, deriv y x) (1, 0) =
        deriv (fun t => fderiv ℝ F (y t, deriv y t) (0, 1)) x) :
    ∃ C : ℝ, ∀ x ∈ Ioo a b,
      F (y x, deriv y x) - deriv y x * fderiv ℝ F (y x, deriv y x) (0, 1) = C := by
  have hdy : ContDiffOn ℝ 1 (deriv y) (Ioo a b) := hy.deriv_of_isOpen isOpen_Ioo (by norm_num)
  have key : ∀ x ∈ Ioo a b, HasDerivAt
      (fun t => F (y t, deriv y t) - deriv y t * fderiv ℝ F (y t, deriv y t) (0, 1)) 0 x := by
    intro x hx
    have hyd : HasDerivAt y (deriv y x) x :=
      ((hy.contDiffAt (isOpen_Ioo.mem_nhds hx)).differentiableAt (by norm_num)).hasDerivAt
    have hdyd : HasDerivAt (deriv y) (deriv (deriv y) x) x :=
      ((hdy.contDiffAt (isOpen_Ioo.mem_nhds hx)).differentiableAt (by norm_num)).hasDerivAt
    have hφ : HasDerivAt (fun t => (y t, deriv y t)) (deriv y x, deriv (deriv y) x) x :=
      hyd.prodMk hdyd
    have hFc : ContDiffAt ℝ 2 F (y x, deriv y x) := hF.contDiffAt (hU.mem_nhds (hyU x hx))
    have hFd : HasFDerivAt F (fderiv ℝ F (y x, deriv y x)) (y x, deriv y x) :=
      (hFc.differentiableAt (by norm_num)).hasFDerivAt
    have h1 := hFd.comp_hasDerivAt x hφ
    have hG : DifferentiableAt ℝ (fun t => fderiv ℝ F (y t, deriv y t) (0, 1)) x := by
      have hfd : DifferentiableAt ℝ (fderiv ℝ F) (y x, deriv y x) :=
        (hFc.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
      have : DifferentiableAt ℝ (fun t => fderiv ℝ F (y t, deriv y t)) x :=
        hfd.comp x hφ.differentiableAt
      exact this.clm_apply (differentiableAt_const _)
    have h2 := hdyd.mul hG.hasDerivAt
    have h3 := h1.sub h2
    rw [← hEL x hx] at h3
    convert h3 using 1
    · rfl
    have e : ((deriv y x, deriv (deriv y) x) : ℝ × ℝ) =
        deriv y x • ((1:ℝ), (0:ℝ)) + deriv (deriv y) x • ((0:ℝ), (1:ℝ)) := by
      ext <;> simp
    · rw [e, map_add, map_smul, map_smul]
      simp only [smul_eq_mul]
      ring
  exact isOpen_Ioo.exists_is_const_of_deriv_eq_zero isPreconnected_Ioo
    (fun t ht => (key t ht).differentiableAt.differentiableWithinAt)
    (fun t ht => (key t ht).deriv)

/-- The slide. With the descent-time cost F(y, p) = sqrt((1 + p^2) / y) (the integrand of
T[y] without its constant factor 1/sqrt(2g)), every twice continuously differentiable slide
with positive depth on an open interval that solves the Euler-Lagrange equation keeps
depth times (1 + slope^2) constant: y (1 + y'^2) = C. -/
theorem brachistochrone_depth_times_one_plus_slope_sq_const (y : ℝ → ℝ) (a b : ℝ)
    (hy : ContDiffOn ℝ 2 y (Ioo a b))
    (hpos : ∀ x ∈ Ioo a b, 0 < y x)
    (hEL : ∀ x ∈ Ioo a b,
      fderiv ℝ (fun q : ℝ × ℝ => Real.sqrt ((1 + q.2 ^ 2) / q.1)) (y x, deriv y x) (1, 0) =
        deriv (fun t => fderiv ℝ (fun q : ℝ × ℝ => Real.sqrt ((1 + q.2 ^ 2) / q.1))
          (y t, deriv y t) (0, 1)) x) :
    ∃ C : ℝ, ∀ x ∈ Ioo a b, y x * (1 + deriv y x ^ 2) = C := by
  set F : ℝ × ℝ → ℝ := fun q => Real.sqrt ((1 + q.2 ^ 2) / q.1) with hFdef
  have hU : IsOpen {q : ℝ × ℝ | 0 < q.1} := isOpen_lt continuous_const continuous_fst
  have hF : ContDiffOn ℝ 2 F {q : ℝ × ℝ | 0 < q.1} := by
    apply ContDiffOn.sqrt
    · apply ContDiffOn.div
      · exact (contDiff_const.add (contDiff_snd.pow 2)).contDiffOn
      · exact contDiff_fst.contDiffOn
      · intro q hq; exact ne_of_gt hq
    · intro q hq
      have : (0:ℝ) < q.1 := hq
      positivity
  -- the partial derivative in the slope
  have hFp : ∀ q : ℝ × ℝ, 0 < q.1 →
      fderiv ℝ F q (0, 1) = (2 * q.2 / q.1) / (2 * Real.sqrt ((1 + q.2 ^ 2) / q.1)) := by
    intro q hq
    have hFc : ContDiffAt ℝ 2 F q := hF.contDiffAt (hU.mem_nhds hq)
    have hFd : HasFDerivAt F (fderiv ℝ F q) q :=
      (hFc.differentiableAt (by norm_num)).hasFDerivAt
    have hl : HasDerivAt (fun t : ℝ => ((q.1, t) : ℝ × ℝ)) ((0:ℝ), (1:ℝ)) q.2 :=
      (hasDerivAt_const q.2 q.1).prodMk (hasDerivAt_id q.2)
    have h1 := hFd.comp_hasDerivAt (x := q.2) (by simpa using hl)
    have h2 : HasDerivAt (fun t : ℝ => Real.sqrt ((1 + t ^ 2) / q.1))
        ((2 * q.2 / q.1) / (2 * Real.sqrt ((1 + q.2 ^ 2) / q.1))) q.2 := by
      have hd : HasDerivAt (fun t : ℝ => (1 + t ^ 2) / q.1) (2 * q.2 / q.1) q.2 := by
        have := ((hasDerivAt_pow 2 q.2).const_add 1).div_const q.1
        simpa using this
      exact hd.sqrt (by positivity)
    exact h1.unique h2
  obtain ⟨C, hC⟩ := beltrami_identity F _ hU hF y a b hy (fun x hx => hpos x hx) hEL
  refine ⟨1 / C ^ 2, fun x hx => ?_⟩
  have h := hC x hx
  rw [hFp _ (hpos x hx)] at h
  simp only [hFdef] at h
  set Y := y x
  set p := deriv y x
  have hY : 0 < Y := hpos x hx
  have hS : 0 < (1 + p ^ 2) / Y := by positivity
  set s := Real.sqrt ((1 + p ^ 2) / Y) with hs
  have hs0 : 0 < s := Real.sqrt_pos.mpr hS
  have hs2 : s ^ 2 = (1 + p ^ 2) / Y := Real.sq_sqrt hS.le
  have hCe : C * (Y * s) = 1 := by
    rw [← h]
    have hs2' : s ^ 2 * Y = 1 + p ^ 2 := by rw [hs2]; field_simp
    field_simp
    linarith [hs2']
  have : Y * (1 + p ^ 2) = (Y * s) ^ 2 := by
    rw [mul_pow, hs2]; field_simp
  rw [this]
  have hC0 : C ≠ 0 := by rintro rfl; simp at hCe
  field_simp
  nlinarith [hCe]

/-- The cycloid. For a wheel of radius R > 0 and gravity g > 0, the cycloid
x = R(θ - sin θ), y = R(1 - cos θ) satisfies the Beltrami rule with C = 2R at every wheel
angle θ strictly between 0 and 2π (where dx/dθ is not zero and the slope is (dy/dθ)/(dx/dθ)),
and the descent time from the platform to wheel angle θ₁, the integral of
arc length over speed sqrt(2 g y), is T = θ₁ sqrt(R/g). -/
theorem cycloid_beltrami_and_descent_time (R g : ℝ) (hR : 0 < R) (hg : 0 < g) :
    (∀ θ ∈ Ioo 0 (2 * π),
      deriv (fun t => R * (t - sin t)) θ ≠ 0 ∧
      R * (1 - cos θ) *
          (1 + (deriv (fun t => R * (1 - cos t)) θ / deriv (fun t => R * (t - sin t)) θ) ^ 2)
        = 2 * R) ∧
    (∀ θ₁ ∈ Ioc 0 (2 * π),
      ∫ θ in (0 : ℝ)..θ₁,
          Real.sqrt ((deriv (fun t => R * (t - sin t)) θ ^ 2 +
              deriv (fun t => R * (1 - cos t)) θ ^ 2) / (2 * g * (R * (1 - cos θ))))
        = θ₁ * Real.sqrt (R / g)) := by
  have hx' : ∀ t, deriv (fun t => R * (t - sin t)) t = R * (1 - cos t) := by
    intro t
    simp
  have hy' : ∀ t, deriv (fun t => R * (1 - cos t)) t = R * sin t := by
    intro t
    simp
  have hcos : ∀ θ ∈ Ioo 0 (2 * π), 0 < 1 - cos θ := by
    intro θ hθ
    have h1 : cos θ ≠ 1 := by
      rw [Ne, cos_eq_one_iff_of_lt_of_lt (by linarith [hθ.1, pi_pos]) hθ.2]
      exact ne_of_gt hθ.1
    have h2 := cos_le_one θ
    have : cos θ < 1 := lt_of_le_of_ne h2 h1
    linarith
  refine ⟨fun θ hθ => ?_, fun θ₁ hθ₁ => ?_⟩
  · have hc := hcos θ hθ
    rw [hx', hy']
    refine ⟨by positivity, ?_⟩
    have hs := sin_sq_add_cos_sq θ
    field_simp
    nlinarith [hs]
  · rw [intervalIntegral.integral_congr_uIoo (g := fun _ => Real.sqrt (R / g))]
    · simp
    · intro θ hθ
      rw [uIoo_of_le hθ₁.1.le] at hθ
      have hc := hcos θ ⟨hθ.1, lt_of_lt_of_le hθ.2 hθ₁.2⟩
      simp only [hx', hy']
      congr 1
      have hs := sin_sq_add_cos_sq θ
      field_simp
      nlinarith [hs]

-- The exit is 2 m across and 1 m down: the exit ratio x / y is 2.
example : (2 : ℚ) / 1 = 2 := by norm_num

-- The circular arc through the platform and the exit: centre (2^2 + 1^2) / (2 * 2) = 5/4 m across,
-- and the exit (2, 1) lies on the circle of that radius about (5/4, 0).
example : ((2 : ℚ) ^ 2 + 1 ^ 2) / (2 * 2) = 5 / 4 ∧ ((2 : ℚ) - 5 / 4) ^ 2 + 1 ^ 2 = (5 / 4) ^ 2 := by
  norm_num

-- The mistake "slide must end level": C = 1 m, R = 1/2 m; the cycloid bottoms out at θ = π,
-- at x = R(π - sin π) = π/2 across and y = R(1 - cos π) = 1 down.
example : (1 / 2 : ℝ) * (π - sin π) = π / 2 ∧ (1 / 2 : ℝ) * (1 - cos π) = 1 := by
  constructor <;> simp <;> ring

#print axioms beltrami_identity
#print axioms brachistochrone_depth_times_one_plus_slope_sq_const
#print axioms cycloid_beltrami_and_descent_time
