-- Convection-diffusion: the heat kernel's bell slid along at the flow speed and shrunk by the leak solves u_t + c u_x = κ u_xx - k u for t > 0, holds mass M e^(-kt), and in a frame moving with the flow the equation is exactly the heat equation.
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.FDeriv.Prod

open Real MeasureTheory

/-- The slid bell: `M e^(-kt) / √(4πκt) · exp(-(x - ct)² / (4κt))`, the heat kernel's bell
centred at `ct` instead of 0, scaled by the leak. -/
noncomputable def slidBell (M c κ k x t : ℝ) : ℝ :=
  M * exp (-k * t) / √(4 * π * κ * t) * exp (-(x - c * t) ^ 2 / (4 * κ * t))

/-- Main claim. For constant speed `c` and constant diffusivity `κ > 0` (and any leak `k`
and mass `M`), the slid bell is a classical solution of the convection-diffusion equation
`u_t + c u_x = κ u_xx - k u` at every place `x` and every time `t > 0`: it is twice
continuously differentiable on the half-plane `t > 0`, and the equation holds there. -/
theorem slid_bell_solves_convection_diffusion (M c κ k : ℝ) (hκ : 0 < κ) :
    ContDiffOn ℝ 2 (fun p : ℝ × ℝ => slidBell M c κ k p.1 p.2) {p | 0 < p.2} ∧
    ∀ x t : ℝ, 0 < t →
      deriv (fun s => slidBell M c κ k x s) t
          + c * deriv (fun y => slidBell M c κ k y t) x
        = κ * deriv (fun y => deriv (fun z => slidBell M c κ k z t) y) x
          - k * slidBell M c κ k x t := by
  refine ⟨?_, ?_⟩
  · unfold slidBell
    have h1 : ∀ p ∈ {p : ℝ × ℝ | 0 < p.2}, (4 * π * κ * p.2) ≠ 0 := by
      intro p hp; simp only [Set.mem_ofPred_eq] at hp; positivity
    have h2 : ∀ p ∈ {p : ℝ × ℝ | 0 < p.2}, √(4 * π * κ * p.2) ≠ 0 := by
      intro p hp; simp only [Set.mem_ofPred_eq] at hp; positivity
    have h3 : ∀ p ∈ {p : ℝ × ℝ | 0 < p.2}, (4 * κ * p.2) ≠ 0 := by
      intro p hp; simp only [Set.mem_ofPred_eq] at hp; positivity
    apply ContDiffOn.mul
    · apply ContDiffOn.div _ _ h2
      · fun_prop
      · exact ContDiffOn.sqrt (by fun_prop) h1
    · apply ContDiffOn.exp
      apply ContDiffOn.div _ _ h3 <;> fun_prop
  · intro x t ht
    set S := √(4 * π * κ * t) with hSdef
    have hS : 0 < S := Real.sqrt_pos.mpr (by positivity)
    have hS2 : S ^ 2 = 4 * π * κ * t := Real.sq_sqrt (by positivity)
    set A := M * exp (-k * t) / S with hA
    -- space derivatives
    have hx1 : ∀ y, HasDerivAt (fun z => slidBell M c κ k z t)
        (A * (exp (-(y - c * t) ^ 2 / (4 * κ * t)) * (-(2 * (y - c * t)) / (4 * κ * t)))) y := by
      intro y
      have hg : HasDerivAt (fun z => -(z - c * t) ^ 2 / (4 * κ * t))
          (-(2 * (y - c * t)) / (4 * κ * t)) y := by
        have := (((hasDerivAt_id' y).sub_const (c * t)).pow 2).neg.div_const (4 * κ * t)
        convert this using 1; simp
      exact (hg.exp).const_mul A
    have hd1 : deriv (fun y => deriv (fun z => slidBell M c κ k z t) y) x
        = A * (exp (-(x - c * t) ^ 2 / (4 * κ * t)) *
            ((2 * (x - c * t) / (4 * κ * t)) ^ 2 - 2 / (4 * κ * t))) := by
      have hfun : (fun y => deriv (fun z => slidBell M c κ k z t) y)
          = fun y => A * (exp (-(y - c * t) ^ 2 / (4 * κ * t)) * (-(2 * (y - c * t)) / (4 * κ * t))) := by
        funext y; exact (hx1 y).deriv
      rw [hfun]
      have hg : HasDerivAt (fun z => -(z - c * t) ^ 2 / (4 * κ * t))
          (-(2 * (x - c * t)) / (4 * κ * t)) x := by
        have := (((hasDerivAt_id' x).sub_const (c * t)).pow 2).neg.div_const (4 * κ * t)
        convert this using 1; simp
      have hl : HasDerivAt (fun z => -(2 * (z - c * t)) / (4 * κ * t)) (-2 / (4 * κ * t)) x := by
        have := (((hasDerivAt_id' x).sub_const (c * t)).const_mul 2).neg.div_const (4 * κ * t)
        convert this using 1; simp
      refine ((hg.exp.mul hl).const_mul A).deriv.trans ?_
      ring
    -- time derivative
    have hsq : HasDerivAt (fun s => √(4 * π * κ * s)) (S / (2 * t)) t := by
      have h := ((hasDerivAt_id' t).const_mul (4 * π * κ)).sqrt
        (by show 4 * π * κ * t ≠ 0; positivity)
      convert h using 1
      rw [← hSdef]
      field_simp
      linear_combination hS2
    have hP : HasDerivAt (fun s => M * exp (-k * s)) (M * (exp (-k * t) * (-k))) t := by
      have := (((hasDerivAt_id' t).const_mul (-k)).exp).const_mul M
      simpa using this
    have hg : HasDerivAt (fun s => -(x - c * s) ^ 2 / (4 * κ * s))
        ((2 * c * (x - c * t) * (4 * κ * t) + (x - c * t) ^ 2 * (4 * κ)) / (4 * κ * t) ^ 2) t := by
      have hn := ((((hasDerivAt_id' t).const_mul c).const_sub x).pow 2).neg
      have hd := (hasDerivAt_id' t).const_mul (4 * κ)
      have := hn.div hd (by show 4 * κ * t ≠ 0; positivity)
      convert this using 1
      simp; ring
    have ht1 := ((hP.div hsq hS.ne').mul hg.exp)
    have hdt : deriv (fun s => slidBell M c κ k x s) t
        = (M * (exp (-k * t) * (-k)) * S - M * exp (-k * t) * (S / (2 * t))) / S ^ 2
            * exp (-(x - c * t) ^ 2 / (4 * κ * t))
          + M * exp (-k * t) / S * (exp (-(x - c * t) ^ 2 / (4 * κ * t)) *
            ((2 * c * (x - c * t) * (4 * κ * t) + (x - c * t) ^ 2 * (4 * κ)) / (4 * κ * t) ^ 2)) :=
      ht1.deriv
    rw [hdt, (hx1 x).deriv, hd1]
    unfold slidBell
    rw [← hSdef, ← hA]
    rw [hA]
    field_simp
    ring

/-- Riding with the flow. If `u` is differentiable at every point with `t > 0` and solves
`u_t + c u_x = κ u_xx - k u` there, then in the moving coordinate `ξ = x - ct`, with the leak
removed, `v(ξ, t) = e^(kt) u(ξ + ct, t)` solves exactly the heat equation `v_t = κ v_ξξ`. -/
theorem moving_frame_gives_heat_equation (u : ℝ → ℝ → ℝ) (c κ k : ℝ)
    (hdiff : ∀ x t : ℝ, 0 < t → DifferentiableAt ℝ (fun p : ℝ × ℝ => u p.1 p.2) (x, t))
    (heq : ∀ x t : ℝ, 0 < t →
      deriv (fun s => u x s) t + c * deriv (fun y => u y t) x
        = κ * deriv (fun y => deriv (fun z => u z t) y) x - k * u x t) :
    ∀ ξ t : ℝ, 0 < t →
      deriv (fun s => exp (k * s) * u (ξ + c * s) s) t
        = κ * deriv (fun η => deriv (fun ζ => exp (k * t) * u (ζ + c * t) t) η) ξ := by
  intro ξ t ht
  set F : ℝ × ℝ → ℝ := fun p => u p.1 p.2 with hF
  have hd := (hdiff (ξ + c * t) t ht).hasFDerivAt
  set L := fderiv ℝ F (ξ + c * t, t)
  -- partial derivatives
  have hpt : HasDerivAt (fun s => u (ξ + c * t) s) (L (0, 1)) t := by
    have h1 : HasDerivAt (fun s : ℝ => ((ξ + c * t, s) : ℝ × ℝ)) ((0, 1) : ℝ × ℝ) t :=
      (hasDerivAt_const t (ξ + c * t)).prodMk (hasDerivAt_id t)
    exact hd.comp_hasDerivAt t h1
  have hpx : HasDerivAt (fun y => u y t) (L (1, 0)) (ξ + c * t) := by
    have h1 : HasDerivAt (fun y : ℝ => ((y, t) : ℝ × ℝ)) ((1, 0) : ℝ × ℝ) (ξ + c * t) :=
      (hasDerivAt_id (ξ + c * t)).prodMk (hasDerivAt_const (ξ + c * t) t)
    exact hd.comp_hasDerivAt (ξ + c * t) h1
  have hpath : HasDerivAt (fun s => u (ξ + c * s) s) (L (c, 1)) t := by
    have h1 : HasDerivAt (fun s : ℝ => ((ξ + c * s, s) : ℝ × ℝ)) ((c, 1) : ℝ × ℝ) t := by
      have := (((hasDerivAt_id t).const_mul c).const_add ξ).prodMk (hasDerivAt_id t)
      simpa using this
    exact HasFDerivAt.comp_hasDerivAt (f := fun s : ℝ => ((ξ + c * s, s) : ℝ × ℝ)) t hd h1
  have hL : L (c, 1) = c * L (1, 0) + L (0, 1) := by
    have : ((c, 1) : ℝ × ℝ) = c • ((1, 0) : ℝ × ℝ) + ((0, 1) : ℝ × ℝ) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul]
  have hlhs : deriv (fun s => exp (k * s) * u (ξ + c * s) s) t
      = k * exp (k * t) * u (ξ + c * t) t + exp (k * t) * L (c, 1) := by
    have he : HasDerivAt (fun s => exp (k * s)) (exp (k * t) * k) t := by
      simpa using ((hasDerivAt_id t).const_mul k).exp
    exact (he.mul hpath).deriv.trans (by ring)
  have hrhs : deriv (fun η => deriv (fun ζ => exp (k * t) * u (ζ + c * t) t) η) ξ
      = exp (k * t) * deriv (fun y => deriv (fun z => u z t) y) (ξ + c * t) := by
    have : (fun η => deriv (fun ζ => exp (k * t) * u (ζ + c * t) t) η)
        = fun η => exp (k * t) * deriv (fun z => u z t) (η + c * t) := by
      funext η
      rw [deriv_const_mul_field']
      beta_reduce
      rw [deriv_comp_add_const (fun z => u z t)]
    rw [this, deriv_const_mul_field']
    beta_reduce
    rw [deriv_comp_add_const (fun y => deriv (fun z => u z t) y)]
  have hpde := heq (ξ + c * t) t ht
  rw [hpt.deriv, hpx.deriv] at hpde
  rw [hlhs, hrhs, hL]
  linear_combination exp (k * t) * hpde

/-- Each bell holds the same dye: for `κ > 0` and `t > 0`, the slid bell's total mass along
the whole line is `M e^(-kt)`, wherever its centre `ct` sits (just `M` with no leak). -/
theorem slid_bell_mass (M c κ k t : ℝ) (hκ : 0 < κ) (ht : 0 < t) :
    ∫ x : ℝ, slidBell M c κ k x t = M * exp (-k * t) := by
  unfold slidBell
  rw [integral_const_mul]
  have h1 : (∫ x : ℝ, exp (-(x - c * t) ^ 2 / (4 * κ * t)))
      = ∫ x : ℝ, exp (-(1 / (4 * κ * t)) * x ^ 2) := by
    rw [← integral_sub_right_eq_self (fun x : ℝ => exp (-(1 / (4 * κ * t)) * x ^ 2)) (c * t)]
    congr 1; funext x; congr 1; ring
  rw [h1, integral_gaussian]
  have h2 : π / (1 / (4 * κ * t)) = 4 * π * κ * t := by field_simp
  rw [h2]
  have : 0 < √(4 * π * κ * t) := Real.sqrt_pos.mpr (by positivity)
  field_simp

-- The dye in the pipe, c = 1 m/s, κ = 1/100 m²/s, L = 100 m, exact rationals.
-- Drift time L / c = 100 s.
example : (100 : ℚ) / 1 = 100 := by norm_num
-- 4κt at t = 100 s is 4 m², and the width squared 2κt is 2 m² (the variance 2.000000 m²).
example : 4 * ((1 : ℚ) / 100) * 100 = 4 ∧ 2 * ((1 : ℚ) / 100) * 100 = 2 := by norm_num
-- Péclet number cL/κ over 100 m is 10,000; over 2 cm (1/50 m) it is 2.
example : (1 : ℚ) * 100 / (1 / 100) = 10000 ∧ (1 : ℚ) * (1 / 50) / (1 / 100) = 2 := by norm_num
-- Spreading time L²/κ over 100 m is 1,000,000 s.
example : (100 : ℚ) ^ 2 / (1 / 100) = 1000000 := by norm_num
-- Drift ct equals width √(2κt) at t = 2κ/c² = 1/50 s, when both are 1/50 m (0.02 m).
example : 2 * ((1 : ℚ) / 100) / 1 ^ 2 = 1 / 50 ∧ (1 : ℚ) * (1 / 50) = 1 / 50 ∧
    (1 / 50 : ℚ) ^ 2 = 2 * (1 / 100) * (1 / 50) := by norm_num
-- Bond reading at r = 4%: drift 3/10 · (5/100 - 4/100) = 3/1000, spreading (1/100)²/2 = 1/20000.
example : (3 / 10 : ℚ) * (5 / 100 - 4 / 100) = 3 / 1000 ∧ ((1 : ℚ) / 100) ^ 2 / 2 = 1 / 20000 := by
  norm_num

#print axioms slid_bell_solves_convection_diffusion
#print axioms moving_frame_gives_heat_equation
#print axioms slid_bell_mass
