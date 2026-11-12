-- Shooting: when the miss is a straight line in the aim that really moves with the aim, one secant step through two different shots lands exactly, and for the cable y'' = y the runs are exactly cosh x + s sinh x, so one aim lands on the far post.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.Calculus.ContDiff.Basic

/-- A function whose derivative is `k` times itself is `f 0 * exp (k x)`. -/
theorem shooting_exp_unique (f : ℝ → ℝ) (k : ℝ) (hf : ∀ x, HasDerivAt f (k * f x) x) (x : ℝ) :
    f x = f 0 * Real.exp (k * x) := by
  set h : ℝ → ℝ := fun t => f t * Real.exp (-(k * t)) with hh
  have hd : ∀ t, HasDerivAt h 0 t := by
    intro t
    have h1 : HasDerivAt (fun t => -(k * t)) (-(k * 1)) t :=
      ((hasDerivAt_id t).const_mul k).neg
    have h2 := (hf t).mul (h1.exp)
    convert h2 using 1
    ring
  have hc : ∀ t, h t = h 0 := by
    intro t
    exact is_const_of_deriv_eq_zero (fun t => (hd t).differentiableAt)
      (fun t => (hd t).deriv) t 0
  have := hc x
  simp only [hh, mul_zero, neg_zero, Real.exp_zero, mul_one] at this
  have he : Real.exp (-(k * x)) * Real.exp (k * x) = 1 := by
    rw [← Real.exp_add]; simp
  calc f x = f x * Real.exp (-(k * x)) * Real.exp (k * x) := by rw [mul_assoc, he, mul_one]
    _ = f 0 * Real.exp (k * x) := by rw [this]

/-- Two shots solve a linear problem exactly: if the miss `g` is a straight line in the aim
`s` whose steepness `b` is not zero (the landing depends on the aim), then from any two
different shots `s₀` and `s₁` the secant aim `s₁ - g s₁ * (s₁ - s₀) / (g s₁ - g s₀)` has
miss zero. -/
theorem secant_step_exact_for_linear_miss (g : ℝ → ℝ) (a b : ℝ)
    (hg : ∀ s, g s = a + b * s) (hb : b ≠ 0) (s₀ s₁ : ℝ) (hs : s₀ ≠ s₁) :
    g (s₁ - g s₁ * (s₁ - s₀) / (g s₁ - g s₀)) = 0 := by
  have hd : s₁ - s₀ ≠ 0 := sub_ne_zero.mpr (Ne.symm hs)
  have hden : g s₁ - g s₀ = b * (s₁ - s₀) := by rw [hg, hg]; ring
  rw [hden, hg, hg s₁]
  field_simp
  ring

/-- For the cable `y'' = y`, a height of 1 and a slope of `s` at the left end fix the run:
a twice-differentiable `y` has bending equal to its height everywhere, height 1 and slope `s`
at `x = 0`, exactly when `y x = cosh x + s * sinh x` for every `x`. -/
theorem cable_run_is_cosh_add_s_sinh (s : ℝ) (y : ℝ → ℝ) (hy : ContDiff ℝ 2 y) :
    ((∀ x, deriv (deriv y) x = y x) ∧ y 0 = 1 ∧ deriv y 0 = s) ↔
      y = fun x => Real.cosh x + s * Real.sinh x := by
  have hd1 : ∀ x, HasDerivAt (fun x => Real.cosh x + s * Real.sinh x)
      (Real.sinh x + s * Real.cosh x) x := fun x =>
    (Real.hasDerivAt_cosh x).add ((Real.hasDerivAt_sinh x).const_mul s)
  have hd2 : ∀ x, HasDerivAt (fun x => Real.sinh x + s * Real.cosh x)
      (Real.cosh x + s * Real.sinh x) x := fun x =>
    (Real.hasDerivAt_sinh x).add ((Real.hasDerivAt_cosh x).const_mul s)
  constructor
  · rintro ⟨h2, h0, h1⟩
    have hy' : ContDiff ℝ (1 + 1) y := by norm_num; exact hy
    rw [contDiff_succ_iff_deriv] at hy'
    obtain ⟨hdy, -, hdy'⟩ := hy'
    have hddy : Differentiable ℝ (deriv y) := hdy'.differentiable (by norm_num)
    have hp : ∀ x, HasDerivAt (fun t => y t + deriv y t) (1 * (y x + deriv y x)) x := by
      intro x
      have := (hdy x).hasDerivAt.add (hddy x).hasDerivAt
      rw [h2] at this
      convert this using 1; ring
    have hm : ∀ x, HasDerivAt (fun t => y t - deriv y t) ((-1) * (y x - deriv y x)) x := by
      intro x
      have := (hdy x).hasDerivAt.sub (hddy x).hasDerivAt
      rw [h2] at this
      convert this using 1; ring
    funext x
    have ep := shooting_exp_unique _ 1 hp x
    have em := shooting_exp_unique _ (-1) hm x
    simp only [h0, h1] at ep em
    rw [Real.cosh_eq, Real.sinh_eq]
    have : Real.exp (-x) = Real.exp ((-1) * x) := by ring_nf
    rw [this]
    simp only [one_mul] at ep
    linear_combination (ep + em) / 2
  · rintro rfl
    have e1 : deriv (fun x => Real.cosh x + s * Real.sinh x) =
        fun x => Real.sinh x + s * Real.cosh x := funext fun x => (hd1 x).deriv
    have e2 : deriv (fun x => Real.sinh x + s * Real.cosh x) =
        fun x => Real.cosh x + s * Real.sinh x := funext fun x => (hd2 x).deriv
    refine ⟨fun x => ?_, by simp, ?_⟩
    · rw [e1, e2]
    · rw [e1]; simp

/-- The cable's run with slope `s` lands on the 2 cm post at `x = 1` exactly when
`s = (2 - cosh 1) / sinh 1`: the aim is unique. -/
theorem cable_aim_lands_iff (s : ℝ) :
    Real.cosh 1 + s * Real.sinh 1 = 2 ↔ s = (2 - Real.cosh 1) / Real.sinh 1 := by
  have hp : 0 < Real.sinh 1 := Real.sinh_pos_iff.mpr one_pos
  rw [eq_div_iff hp.ne']
  constructor <;> intro h <;> linarith

-- The worked table: the shot with slope 1 lands at cosh 1 + sinh 1 = e.
example : Real.cosh 1 + 1 * Real.sinh 1 = Real.exp 1 := by
  rw [one_mul, Real.cosh_add_sinh]

#print axioms shooting_exp_unique
#print axioms secant_step_exact_for_linear_miss
#print axioms cable_run_is_cosh_add_s_sinh
#print axioms cable_aim_lands_iff
