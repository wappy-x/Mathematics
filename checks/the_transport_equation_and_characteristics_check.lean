-- The transport equation: for a constant speed c the only smooth solution of u_t + c u_x = 0 with starting shape f is f(x - c t), and for the speed 2 + x/2 the solution is f((x + 4) e^(-t/2) - 4).
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt

/-- A quantity carried at constant speed `c` without mixing obeys `u_t + c u_x = 0`.
Given a starting shape `f` with a continuous slope, the shifted shape `f (x - c t)`
has continuous partial derivatives, solves the equation and starts at `f`
(existence), and every solution with continuous partial derivatives that starts
at `f` equals `f (x - c t)` at every place `x` and every time `t ≥ 0` since the
start (uniqueness). Here `u (x, t)` is the value at place `x` and time `t`, and the
partial derivatives are the derivatives of the slices `s ↦ u (x, s)` and
`y ↦ u (y, t)`. -/
theorem transport_solution_is_shifted_shape (c : ℝ) (f : ℝ → ℝ) (hf : ContDiff ℝ 1 f) :
    (ContDiff ℝ 1 (fun p : ℝ × ℝ => f (p.1 - c * p.2)) ∧
      (∀ x t : ℝ, deriv (fun s => f (x - c * s)) t + c * deriv (fun y => f (y - c * t)) x = 0) ∧
      (∀ x : ℝ, f (x - c * 0) = f x)) ∧
    (∀ u : ℝ × ℝ → ℝ, ContDiff ℝ 1 u →
      (∀ x t : ℝ, 0 ≤ t →
        deriv (fun s => u (x, s)) t + c * deriv (fun y => u (y, t)) x = 0) →
      (∀ x : ℝ, u (x, 0) = f x) →
      ∀ x t : ℝ, 0 ≤ t → u (x, t) = f (x - c * t)) := by
  have hfd : Differentiable ℝ f := hf.differentiable (by norm_num)
  refine ⟨⟨?_, ?_, ?_⟩, ?_⟩
  · exact hf.comp (contDiff_fst.sub (contDiff_const.mul contDiff_snd))
  · intro x t
    have h1 : HasDerivAt (fun s => f (x - c * s)) (deriv f (x - c * t) * (0 - c * 1)) t :=
      (hfd _).hasDerivAt.comp t ((hasDerivAt_const t x).sub ((hasDerivAt_id t).const_mul c))
    have h2 : HasDerivAt (fun y => f (y - c * t)) (deriv f (x - c * t) * (1 - 0)) x :=
      (hfd _).hasDerivAt.comp x ((hasDerivAt_id x).sub (hasDerivAt_const x (c * t)))
    rw [h1.deriv, h2.deriv]; ring
  · intro x; simp
  · intro u hu hpde h0 x t ht
    have hud : Differentiable ℝ u := hu.differentiable (by norm_num)
    have hs : ∀ y s : ℝ, deriv (fun s => u (y, s)) s = fderiv ℝ u (y, s) (0, 1) := by
      intro y s
      have := (hud (y, s)).hasFDerivAt.comp_hasDerivAt s
        ((hasDerivAt_const s y).prodMk (hasDerivAt_id s))
      exact this.deriv
    have hy : ∀ y s : ℝ, deriv (fun y => u (y, s)) y = fderiv ℝ u (y, s) (1, 0) := by
      intro y s
      have := (hud (y, s)).hasFDerivAt.comp_hasDerivAt y
        ((hasDerivAt_id y).prodMk (hasDerivAt_const y s))
      exact this.deriv
    set g : ℝ → ℝ := fun s => u (x - c * t + c * s, s) with hg
    have hgd : ∀ s, 0 ≤ s → HasDerivAt g 0 s := by
      intro s hs0
      have hp : HasDerivAt (fun s : ℝ => (x - c * t + c * s, s)) (c * 1, 1) s :=
        (((hasDerivAt_id s).const_mul c).const_add (x - c * t)).prodMk (hasDerivAt_id s)
      have := HasFDerivAt.comp_hasDerivAt (l := u) (f := fun s : ℝ => (x - c * t + c * s, s)) s
        (hud (x - c * t + c * s, s)).hasFDerivAt hp
      have hv : ((c * 1, 1) : ℝ × ℝ) = c • ((1, 0) : ℝ × ℝ) + ((0, 1) : ℝ × ℝ) := by
        ext <;> simp
      have hz : fderiv ℝ u (x - c * t + c * s, s) (c * 1, 1) = 0 := by
        rw [hv, map_add, map_smul, ← hs, ← hy, smul_eq_mul]
        have := hpde (x - c * t + c * s) s hs0
        linarith
      rw [hz] at this
      exact this
    have hcont : Continuous g :=
      hud.continuous.comp (by fun_prop)
    have key := constant_of_has_deriv_right_zero (a := 0) (b := t) hcont.continuousOn
      (fun s hs => (hgd s hs.1).hasDerivWithinAt) t ⟨ht, le_rfl⟩
    simp only [hg] at key
    rw [← h0]
    convert key using 2 <;> ext <;> simp

/-- Varying speed `c(x) = 2 + x/2`: for a starting shape `f` with a continuous slope,
`u (x, t) = f ((x + 4) e^(-t/2) - 4)` solves `u_t + (2 + x/2) u_x = 0` and starts at `f`.
The value at `(x, t)` is the starting value at the label of the path through that point. -/
theorem transport_varying_speed_solution (f : ℝ → ℝ) (hf : ContDiff ℝ 1 f) :
    (∀ x t : ℝ,
      deriv (fun s => f ((x + 4) * Real.exp (-s / 2) - 4)) t +
        (2 + x / 2) * deriv (fun y => f ((y + 4) * Real.exp (-t / 2) - 4)) x = 0) ∧
    (∀ x : ℝ, f ((x + 4) * Real.exp (-0 / 2) - 4) = f x) := by
  have hfd : Differentiable ℝ f := hf.differentiable (by norm_num)
  refine ⟨?_, ?_⟩
  · intro x t
    have h1 : HasDerivAt (fun s => f ((x + 4) * Real.exp (-s / 2) - 4))
        (deriv f ((x + 4) * Real.exp (-t / 2) - 4) *
          ((x + 4) * (Real.exp (-t / 2) * (-1 / 2)))) t := by
      have he : HasDerivAt (fun s : ℝ => Real.exp (-s / 2)) (Real.exp (-t / 2) * (-1 / 2)) t := by
        have := ((hasDerivAt_id t).neg.div_const 2).exp
        convert this using 1 <;> simp
      exact (hfd _).hasDerivAt.comp t ((he.const_mul (x + 4)).sub_const 4)
    have h2 : HasDerivAt (fun y => f ((y + 4) * Real.exp (-t / 2) - 4))
        (deriv f ((x + 4) * Real.exp (-t / 2) - 4) * ((1 + 0) * Real.exp (-t / 2))) x :=
      (hfd _).hasDerivAt.comp x
        ((((hasDerivAt_id x).add (hasDerivAt_const x 4)).mul_const (Real.exp (-t / 2))).sub_const 4)
    rw [h1.deriv, h2.deriv]; ring
  · intro x; simp

/-- Where the smooth solution stops: for `u_t + u u_x = 0` starting from the profile
`g(a) = 2 + e^(-a^2)`, the most negative slope of `g` is `-√2 e^(-1/2)`, so neighbouring
paths first meet at time `-1 / (that slope) = √(e/2)`. -/
theorem breaking_time_of_bump_profile :
    IsLeast (Set.range (deriv (fun a : ℝ => 2 + Real.exp (-a ^ 2))))
        (-(Real.sqrt 2 * Real.exp (-1 / 2))) ∧
      -1 / (-(Real.sqrt 2 * Real.exp (-1 / 2))) = Real.sqrt (Real.exp 1 / 2) := by
  have hd : ∀ a : ℝ, deriv (fun a : ℝ => 2 + Real.exp (-a ^ 2)) a
      = -(2 * a * Real.exp (-a ^ 2)) := by
    intro a
    have : HasDerivAt (fun a : ℝ => 2 + Real.exp (-a ^ 2))
        (Real.exp (-a ^ 2) * (-(2 * a))) a := by
      have h := ((hasDerivAt_pow 2 a).neg).exp.const_add 2
      convert h using 1
      simp
    rw [this.deriv]; ring
  have hs2 : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hs2p : 0 < Real.sqrt 2 := by positivity
  refine ⟨⟨⟨Real.sqrt 2 / 2, ?_⟩, ?_⟩, ?_⟩
  · rw [hd]
    have : -(Real.sqrt 2 / 2) ^ 2 = -1 / 2 := by
      rw [div_pow, hs2]; ring
    rw [this]; ring
  · rintro _ ⟨a, rfl⟩
    rw [hd]
    have e1 : a ^ 2 - 1 / 2 + 1 ≤ Real.exp (a ^ 2 - 1 / 2) := Real.add_one_le_exp _
    have e2 : Real.sqrt 2 * a ≤ a ^ 2 + 1 / 2 := by
      nlinarith [sq_nonneg (a - Real.sqrt 2 / 2)]
    have e3 : Real.exp (a ^ 2 - 1 / 2) * Real.exp (-a ^ 2) = Real.exp (-1 / 2) := by
      rw [← Real.exp_add]; ring_nf
    have hpos : 0 < Real.exp (-a ^ 2) := Real.exp_pos _
    have : Real.sqrt 2 * a * Real.exp (-a ^ 2) ≤ Real.exp (-1 / 2) := by
      rw [← e3]
      exact mul_le_mul_of_nonneg_right (by linarith) hpos.le
    have : 2 * a * Real.exp (-a ^ 2) ≤ Real.sqrt 2 * Real.exp (-1 / 2) := by
      have h := mul_le_mul_of_nonneg_left this hs2p.le
      calc 2 * a * Real.exp (-a ^ 2) = Real.sqrt 2 ^ 2 * a * Real.exp (-a ^ 2) := by rw [hs2]
        _ = Real.sqrt 2 * (Real.sqrt 2 * a * Real.exp (-a ^ 2)) := by ring
        _ ≤ _ := h
    linarith
  · rw [Real.sqrt_div (Real.exp_pos 1).le, ← Real.exp_half]
    have h1 : Real.exp (-1 / 2) * Real.exp (1 / 2) = 1 := by
      rw [← Real.exp_add]; norm_num
    have hne : Real.exp (-1 / 2) ≠ 0 := (Real.exp_pos _).ne'
    field_simp
    linarith [h1]

-- The station at 5 km, at 3 pm (t = 3 h), on a 2 km/h river reads the water from x - ct = -1 km.
example : (5 : ℤ) - 2 * 3 = -1 := by norm_num
-- The plume moves 3 km downstream after 1.5 hours and 6 km after 3 hours.
example : (2 : ℚ) * (3 / 2) = 3 := by norm_num
example : (2 : ℤ) * 3 = 6 := by norm_num
-- Constant speed 2: parcels starting at a = -2, -1, 0, 1, 2 reach a + 2 * 2 after 2 hours.
example : ([-2, -1, 0, 1, 2] : List ℤ).map (fun a => a + 2 * 2) = [2, 3, 4, 5, 6] := by decide
-- The wrong shift f(x + ct): the station at 6 km at 3 pm reads the spill at 6 + 2 * 3 = 12 km, not 0.
example : (6 : ℤ) + 2 * 3 = 12 ∧ (6 : ℤ) - 2 * 3 = 0 := by norm_num

#print axioms transport_solution_is_shifted_shape
#print axioms transport_varying_speed_solution
#print axioms breaking_time_of_bump_profile
