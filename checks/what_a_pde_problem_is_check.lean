-- A PDE problem: the cooling-plate bump u = A e^(-2π²κt/L²) sin(πx/L) sin(πy/L) is a classical solution of the full heat problem on the open square with edges at 0 and start A sin(πx/L) sin(πy/L), without start data every multiple of the bump fits, and the start data alone fix the starting rate at the centre.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Topology.Order.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Real Set

/-- The rate in time `u_t` at the place `p` and time `t`, taken inside the time interval
`[0, T]` (so at the last time `T` it is the rate from the past). -/
noncomputable def heatUt (T : ℝ) (u : ℝ × ℝ → ℝ → ℝ) (p : ℝ × ℝ) (t : ℝ) : ℝ :=
  derivWithin (u p) (Icc 0 T) t

/-- The bend along `x`, `u_xx`: the second derivative of `x ↦ u (x, y) t`. -/
noncomputable def heatUxx (u : ℝ × ℝ → ℝ → ℝ) (p : ℝ × ℝ) (t : ℝ) : ℝ :=
  deriv (fun x => deriv (fun x' => u (x', p.2) t) x) p.1

/-- The bend along `y`, `u_yy`: the second derivative of `y ↦ u (x, y) t`. -/
noncomputable def heatUyy (u : ℝ × ℝ → ℝ → ℝ) (p : ℝ × ℝ) (t : ℝ) : ℝ :=
  deriv (fun y => deriv (fun y' => u (p.1, y') t) y) p.2

/-- Rules 1 to 3 of a classical solution, plus the edge data `b`, with no start data:
`u` is continuous on the closed region `closure Ω` for `0 ≤ t ≤ T`; inside `Ω` for
`0 < t ≤ T` the rates `u_t`, `u_xx`, `u_yy` exist and are continuous; the heat equation
`u_t = κ (u_xx + u_yy)` holds there; and `u = b` on the boundary `frontier Ω` for `0 < t ≤ T`. -/
def SolvesHeatWithEdgeData (κ T : ℝ) (Ω : Set (ℝ × ℝ)) (b : ℝ × ℝ → ℝ → ℝ)
    (u : ℝ × ℝ → ℝ → ℝ) : Prop :=
  ContinuousOn (fun q : (ℝ × ℝ) × ℝ => u q.1 q.2) (closure Ω ×ˢ Icc 0 T) ∧
  (∀ p ∈ Ω, ∀ t ∈ Ioc 0 T,
    DifferentiableWithinAt ℝ (u p) (Icc 0 T) t ∧
    DifferentiableAt ℝ (fun x => u (x, p.2) t) p.1 ∧
    DifferentiableAt ℝ (fun x => deriv (fun x' => u (x', p.2) t) x) p.1 ∧
    DifferentiableAt ℝ (fun y => u (p.1, y) t) p.2 ∧
    DifferentiableAt ℝ (fun y => deriv (fun y' => u (p.1, y') t) y) p.2) ∧
  ContinuousOn (fun q : (ℝ × ℝ) × ℝ => heatUt T u q.1 q.2) (Ω ×ˢ Ioc 0 T) ∧
  ContinuousOn (fun q : (ℝ × ℝ) × ℝ => heatUxx u q.1 q.2) (Ω ×ˢ Ioc 0 T) ∧
  ContinuousOn (fun q : (ℝ × ℝ) × ℝ => heatUyy u q.1 q.2) (Ω ×ˢ Ioc 0 T) ∧
  (∀ p ∈ Ω, ∀ t ∈ Ioc 0 T, heatUt T u p t = κ * (heatUxx u p t + heatUyy u p t)) ∧
  (∀ p ∈ frontier Ω, ∀ t ∈ Ioc 0 T, u p t = b p t)

/-- A classical solution of the initial-boundary value problem
`u_t = κ (u_xx + u_yy)` in `Ω × (0, T]`, `u = b` on `∂Ω × (0, T]`, `u(·, 0) = g` on `Ω̄`:
the four rules of the card (continuity on the closed region, continuous rates inside,
the equation inside, the edge and start data met exactly). -/
def IsClassicalHeatSolution (κ T : ℝ) (Ω : Set (ℝ × ℝ)) (b : ℝ × ℝ → ℝ → ℝ)
    (g : ℝ × ℝ → ℝ) (u : ℝ × ℝ → ℝ → ℝ) : Prop :=
  SolvesHeatWithEdgeData κ T Ω b u ∧ ∀ p ∈ closure Ω, u p 0 = g p

lemma pde_deriv_sin_x (a b L : ℝ) :
    deriv (fun x => a * sin (π * x / L) * b) = fun x => a * (cos (π * x / L) * (π / L)) * b := by
  funext x
  have h : HasDerivAt (fun x => sin (π * x / L)) (cos (π * x / L) * (π / L)) x := by
    have := (((hasDerivAt_id x).const_mul π).div_const L).sin
    convert this using 1 <;> simp [mul_div_assoc]
  exact ((h.const_mul a).mul_const b).deriv

lemma pde_deriv_cos_x (a b L : ℝ) :
    deriv (fun x => a * (cos (π * x / L) * (π / L)) * b) =
      fun x => a * (-sin (π * x / L) * (π / L) * (π / L)) * b := by
  funext x
  have h : HasDerivAt (fun x => cos (π * x / L)) (-sin (π * x / L) * (π / L)) x := by
    have := (((hasDerivAt_id x).const_mul π).div_const L).cos
    convert this using 1 <;> simp [mul_div_assoc]
  exact (((h.mul_const (π / L)).const_mul a).mul_const b).deriv

lemma pde_deriv_sin_y (c L : ℝ) :
    deriv (fun y => c * sin (π * y / L)) = fun y => c * (cos (π * y / L) * (π / L)) := by
  have := pde_deriv_sin_x c 1 L
  simpa using this

lemma pde_deriv_cos_y (c L : ℝ) :
    deriv (fun y => c * (cos (π * y / L) * (π / L))) =
      fun y => c * (-sin (π * y / L) * (π / L) * (π / L)) := by
  have := pde_deriv_cos_x c 1 L
  simpa using this

#print axioms pde_deriv_sin_x
#print axioms pde_deriv_cos_x
#print axioms pde_deriv_sin_y
#print axioms pde_deriv_cos_y

lemma pde_bump_solves (κ L T A : ℝ) (hL : 0 < L) :
    SolvesHeatWithEdgeData κ T (Ioo 0 L ×ˢ Ioo 0 L) (fun _ _ => 0)
      (fun p t => A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) *
        sin (π * p.1 / L) * sin (π * p.2 / L)) := by
  have hxx : ∀ p : ℝ × ℝ, ∀ t : ℝ, heatUxx (fun p t => A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) *
        sin (π * p.1 / L) * sin (π * p.2 / L)) p t =
      A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) * (-sin (π * p.1 / L) * (π / L) * (π / L)) *
        sin (π * p.2 / L) := by
    intro p t
    unfold heatUxx
    simp only [pde_deriv_sin_x, pde_deriv_cos_x]
  have hyy : ∀ p : ℝ × ℝ, ∀ t : ℝ, heatUyy (fun p t => A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) *
        sin (π * p.1 / L) * sin (π * p.2 / L)) p t =
      A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) * sin (π * p.1 / L) *
        (-sin (π * p.2 / L) * (π / L) * (π / L)) := by
    intro p t
    unfold heatUyy
    simp only [pde_deriv_sin_y, pde_deriv_cos_y]
  have hdt : ∀ p : ℝ × ℝ, ∀ t : ℝ, HasDerivAt (fun t => A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) *
        sin (π * p.1 / L) * sin (π * p.2 / L))
      (A * (exp (-(2 * π ^ 2 * κ / L ^ 2) * t) * (-(2 * π ^ 2 * κ / L ^ 2))) *
        sin (π * p.1 / L) * sin (π * p.2 / L)) t := by
    intro p t
    have h1 : HasDerivAt (fun t => exp (-(2 * π ^ 2 * κ / L ^ 2) * t))
        (exp (-(2 * π ^ 2 * κ / L ^ 2) * t) * (-(2 * π ^ 2 * κ / L ^ 2))) t := by
      have := ((hasDerivAt_id t).const_mul (-(2 * π ^ 2 * κ / L ^ 2))).exp
      simpa using this
    exact ((h1.const_mul A).mul_const _).mul_const _
  have hut : ∀ p : ℝ × ℝ, ∀ t ∈ Ioc 0 T, heatUt T (fun p t => A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) *
        sin (π * p.1 / L) * sin (π * p.2 / L)) p t =
      A * (exp (-(2 * π ^ 2 * κ / L ^ 2) * t) * (-(2 * π ^ 2 * κ / L ^ 2))) *
        sin (π * p.1 / L) * sin (π * p.2 / L) := by
    intro p t ht
    unfold heatUt
    have hT : 0 < T := lt_of_lt_of_le ht.1 ht.2
    exact (hdt p t).hasDerivWithinAt.derivWithin
      (uniqueDiffOn_Icc hT t (Ioc_subset_Icc_self ht))
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · exact Continuous.continuousOn (by fun_prop)
  · intro p _ t ht
    refine ⟨(hdt p t).differentiableAt.differentiableWithinAt, ?_, ?_, ?_, ?_⟩
    · fun_prop
    · simp only [pde_deriv_sin_x]
      fun_prop
    · fun_prop
    · simp only [pde_deriv_sin_y]
      fun_prop
  · refine ContinuousOn.congr (f := fun q : (ℝ × ℝ) × ℝ =>
      A * (exp (-(2 * π ^ 2 * κ / L ^ 2) * q.2) * (-(2 * π ^ 2 * κ / L ^ 2))) *
        sin (π * q.1.1 / L) * sin (π * q.1.2 / L)) (Continuous.continuousOn (by fun_prop)) ?_
    intro q hq
    exact hut q.1 q.2 hq.2
  · simp only [hxx]
    exact Continuous.continuousOn (by fun_prop)
  · simp only [hyy]
    exact Continuous.continuousOn (by fun_prop)
  · intro p _ t ht
    rw [hut p t ht, hxx, hyy]
    field_simp
    ring
  · intro p hp t _
    rw [frontier_prod_eq, frontier_Ioo hL, closure_Ioo hL.ne] at hp
    have hπ : π * L / L = π := by field_simp
    rcases hp with ⟨_, h2⟩ | ⟨h1, _⟩
    · rcases h2 with h2 | h2
      · simp [h2]
      · rw [mem_singleton_iff] at h2
        simp [h2, hπ]
    · rcases h1 with h1 | h1
      · simp [h1]
      · rw [mem_singleton_iff] at h1
        simp [h1, hπ]

#print axioms pde_bump_solves

/-- The cooling plate, stated in full, has the decaying bump as a classical solution.
On the open square `Ω = (0, L) × (0, L)` with side `L > 0`, constant diffusivity `κ`,
edges held at 0 (data on every edge) and start `g = A sin(πx/L) sin(πy/L)` (which is 0 on
the edges, so start and edge data match), the function
`u = A e^(-2π²κt/L²) sin(πx/L) sin(πy/L)` is a classical solution on `0 ≤ t ≤ T`. -/
theorem cooling_plate_bump_is_classical_solution (κ L T A : ℝ) (hL : 0 < L) :
    IsClassicalHeatSolution κ T (Ioo 0 L ×ˢ Ioo 0 L) (fun _ _ => 0)
      (fun p => A * sin (π * p.1 / L) * sin (π * p.2 / L))
      (fun p t => A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) *
        sin (π * p.1 / L) * sin (π * p.2 / L)) := by
  refine ⟨pde_bump_solves κ L T A hL, ?_⟩
  intro p _
  simp

/-- Leave out the start data and there are many answers: on the same square with the
edges at 0, every multiple `A` of the decaying bump (including `A = 0`, the plate at
0 °C) satisfies the equation, the regularity rules and the edge data, and two different
multiples give different centre readings at every time. -/
theorem no_start_data_every_multiple_fits (κ L T : ℝ) (hL : 0 < L) :
    (∀ A : ℝ, SolvesHeatWithEdgeData κ T (Ioo 0 L ×ˢ Ioo 0 L) (fun _ _ => 0)
      (fun p t => A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) *
        sin (π * p.1 / L) * sin (π * p.2 / L))) ∧
    (∀ A A' t : ℝ,
      A * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) * sin (π * (L / 2) / L) * sin (π * (L / 2) / L) =
        A' * exp (-(2 * π ^ 2 * κ / L ^ 2) * t) * sin (π * (L / 2) / L) *
          sin (π * (L / 2) / L) → A = A') := by
  refine ⟨fun A => pde_bump_solves κ L T A hL, ?_⟩
  intro A A' t h
  have hmid : π * (L / 2) / L = π / 2 := by field_simp
  rw [hmid, sin_pi_div_two] at h
  simpa [exp_ne_zero] using h

/-- The start data already fix the starting rate, so a start rate cannot also be given.
If `u` starts as `g = A sin(πx/L) sin(πy/L)` on the closed square and the heat equation
holds at the centre `(L/2, L/2)` at the start, then the starting rate there is forced:
`u_t = -(2π²κ/L²) A`. With `κ ≠ 0` and `A ≠ 0` it is not 0, so adding "starting rate 0"
leaves no solution. -/
theorem start_rate_forced_by_start_data (κ L A : ℝ) (hL : 0 < L) (u : ℝ × ℝ → ℝ → ℝ)
    (hstart : ∀ p ∈ closure (Ioo 0 L ×ˢ Ioo 0 L),
      u p 0 = A * sin (π * p.1 / L) * sin (π * p.2 / L))
    (heq : derivWithin (u (L / 2, L / 2)) (Ici 0) 0 =
      κ * (heatUxx u (L / 2, L / 2) 0 + heatUyy u (L / 2, L / 2) 0)) :
    derivWithin (u (L / 2, L / 2)) (Ici 0) 0 = -(2 * π ^ 2 * κ / L ^ 2) * A ∧
      (κ ≠ 0 → A ≠ 0 → derivWithin (u (L / 2, L / 2)) (Ici 0) 0 ≠ 0) := by
  have hmid : π * (L / 2) / L = π / 2 := by field_simp
  have hcen : L / 2 ∈ Ioo 0 L := ⟨by linarith, by linarith⟩
  have hx : (fun x' => u (x', L / 2) 0) =ᶠ[nhds (L / 2)]
      (fun x' => A * sin (π * x' / L) * sin (π * (L / 2) / L)) := by
    filter_upwards [Ioo_mem_nhds hcen.1 hcen.2] with x' hx'
    exact hstart (x', L / 2) (subset_closure ⟨hx', hcen⟩)
  have hy : (fun y' => u (L / 2, y') 0) =ᶠ[nhds (L / 2)]
      (fun y' => A * sin (π * (L / 2) / L) * sin (π * y' / L)) := by
    filter_upwards [Ioo_mem_nhds hcen.1 hcen.2] with y' hy'
    exact hstart (L / 2, y') (subset_closure ⟨hcen, hy'⟩)
  have hxx : heatUxx u (L / 2, L / 2) 0 = -(π ^ 2 / L ^ 2) * A := by
    unfold heatUxx
    rw [hx.deriv.deriv_eq, pde_deriv_sin_x, pde_deriv_cos_x]
    simp only [hmid, sin_pi_div_two]
    field_simp
  have hyy : heatUyy u (L / 2, L / 2) 0 = -(π ^ 2 / L ^ 2) * A := by
    unfold heatUyy
    rw [hy.deriv.deriv_eq, pde_deriv_sin_y, pde_deriv_cos_y]
    simp only [hmid, sin_pi_div_two]
    field_simp
  have hrate : derivWithin (u (L / 2, L / 2)) (Ici 0) 0 = -(2 * π ^ 2 * κ / L ^ 2) * A := by
    rw [heq, hxx, hyy]
    ring
  refine ⟨hrate, fun hκ hA => ?_⟩
  rw [hrate]
  have : (2 * π ^ 2 * κ / L ^ 2) ≠ 0 := by
    have := pi_pos
    positivity
  exact mul_ne_zero (neg_ne_zero.mpr this) hA

/-! The card's order table, in whole numbers.  Each term of an equation is listed by its
number of derivatives `(in x, in y, in t)`.  The order is the largest total; the start
fields are the largest count in `t`; the conditions per edge point are half the largest
count in space. -/

/-- The order of a PDE: the largest total number of derivatives in any term. -/
def pdeOrder (terms : List (ℕ × ℕ × ℕ)) : ℕ :=
  (terms.map fun d => d.1 + d.2.1 + d.2.2).foldr max 0

/-- The number of start fields: the order in time. -/
def startFields (terms : List (ℕ × ℕ × ℕ)) : ℕ :=
  (terms.map fun d => d.2.2).foldr max 0

/-- The conditions per edge point: half the order in space. -/
def edgeConditions (terms : List (ℕ × ℕ × ℕ)) : ℕ :=
  (terms.map fun d => d.1 + d.2.1).foldr max 0 / 2

-- Cooling, u_t = κ (u_xx + u_yy): order 2, 1 start field, 1 condition per edge point.
example : (pdeOrder [(0, 0, 1), (2, 0, 0), (0, 2, 0)],
    startFields [(0, 0, 1), (2, 0, 0), (0, 2, 0)],
    edgeConditions [(0, 0, 1), (2, 0, 0), (0, 2, 0)]) = (2, 1, 1) := by decide
-- Held steady, u_xx + u_yy = 0: order 2, 0 start fields, 1 condition per edge point.
example : (pdeOrder [(2, 0, 0), (0, 2, 0)], startFields [(2, 0, 0), (0, 2, 0)],
    edgeConditions [(2, 0, 0), (0, 2, 0)]) = (2, 0, 1) := by decide
-- Ringing membrane, u_tt = c² (u_xx + u_yy): order 2, 2 start fields, 1 condition per edge point.
example : (pdeOrder [(0, 0, 2), (2, 0, 0), (0, 2, 0)],
    startFields [(0, 0, 2), (2, 0, 0), (0, 2, 0)],
    edgeConditions [(0, 0, 2), (2, 0, 0), (0, 2, 0)]) = (2, 2, 1) := by decide
-- Ringing plate, w_tt + D/(ρH)(w_xxxx + 2w_xxyy + w_yyyy) = 0: order 4, 2 start fields,
-- 2 conditions per edge point.
example : (pdeOrder [(0, 0, 2), (4, 0, 0), (2, 2, 0), (0, 4, 0)],
    startFields [(0, 0, 2), (4, 0, 0), (2, 2, 0), (0, 4, 0)],
    edgeConditions [(0, 0, 2), (4, 0, 0), (2, 2, 0), (0, 4, 0)]) = (4, 2, 2) := by decide

#print axioms cooling_plate_bump_is_classical_solution
#print axioms no_start_data_every_multiple_fits
#print axioms start_rate_forced_by_start_data
