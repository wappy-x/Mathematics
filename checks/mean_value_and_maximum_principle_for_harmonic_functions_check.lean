-- Mean value and maximum principle: a harmonic function on a plane region equals its average round any circle whose closed disk fits in the region, and on a bounded region with continuous boundary values it stays between its lowest and highest boundary values, so the boundary values fix it.
import Mathlib.Analysis.Complex.Harmonic.MeanValue
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.Complex.AbsMax

open InnerProductSpace Metric Real

/-- Helper: a harmonic function on a bounded open set, continuous up to the edge, takes its
largest value on the closure at some boundary point. -/theorem harmonic_exists_frontier_isMaxOn {D : Set ℂ} {u : ℂ → ℝ}
    (hD : IsOpen D) (hbdd : Bornology.IsBounded D) (hne : D.Nonempty) (hu : HarmonicOnNhd u D)
    (hcont : ContinuousOn u (closure D)) :
    ∃ b ∈ frontier D, IsMaxOn u (closure D) b := by
  have hc : IsCompact (closure D) := hbdd.isCompact_closure
  obtain ⟨w, hwD, hle⟩ : ∃ w ∈ closure D, IsMaxOn u (closure D) w :=
    hc.exists_isMaxOn hne.closure hcont
  rw [closure_eq_interior_union_frontier, Set.mem_union, hD.interior_eq] at hwD
  rcases hwD with hwD | hwD
  swap
  · exact ⟨w, hwD, hle⟩
  have hne_univ : D ≠ Set.univ := fun h => hc.ne_univ (by rw [h, closure_univ])
  obtain ⟨z, hzD, hzw⟩ := exists_mem_frontier_infDist_compl_eq_dist hwD hne_univ
  refine ⟨z, hzD, fun x hx => (hle hx).out.trans_eq ?_⟩
  set ρ := dist w z with hρ
  have hball : ball w ρ ⊆ D := by rw [← hzw]; exact ball_infDist_compl_subset
  have hρpos : 0 < ρ := by
    refine dist_pos.2 ?_
    rintro rfl
    exact hzD.2 (by rw [hD.interior_eq]; exact hwD)
  obtain ⟨F, hF, hFu⟩ := (hu.mono hball).exists_analyticOnNhd_ball_re_eq
  have hwb : w ∈ ball w ρ := mem_ball_self hρpos
  have hG : DifferentiableOn ℂ (fun y => Complex.exp (F y)) (ball w ρ) :=
    fun y hy => ((hF y hy).differentiableAt.cexp).differentiableWithinAt
  have hnorm : ∀ y ∈ ball w ρ, ‖Complex.exp (F y)‖ = Real.exp (u y) := by
    intro y hy
    rw [Complex.norm_exp]; exact congrArg Real.exp (hFu hy)
  have hmax : IsMaxOn (norm ∘ fun y => Complex.exp (F y)) (ball w ρ) w := by
    intro y hy
    simp only [Set.mem_ofPred_eq, Function.comp_apply]
    rw [hnorm y hy, hnorm w hwb]
    exact Real.exp_le_exp.2 (hle (subset_closure (hball hy)))
  have heq := Complex.norm_eqOn_of_isPreconnected_of_isMaxOn (convex_ball w ρ).isPreconnected
    isOpen_ball hG hwb hmax
  have hEq : Set.EqOn u (fun _ => u w) (ball w ρ) := by
    intro y hy
    have := heq hy
    simp only [Function.comp_apply, Function.const_apply] at this
    rw [hnorm y hy, hnorm w hwb] at this
    exact Real.exp_injective this
  have hcl : closure (ball w ρ) ⊆ closure D := closure_mono hball
  have hEq' := hEq.of_subset_closure (hcont.mono hcl) continuousOn_const subset_closure le_rfl
  have hz : z ∈ closure (ball w ρ) := by
    rw [closure_ball w hρpos.ne']
    exact mem_closedBall.2 (by rw [dist_comm])
  exact (hEq' hz).symm

#print axioms harmonic_exists_frontier_isMaxOn

/-- Mean value property: if `u` is harmonic in an open region `D` of the plane and the whole
closed disk of radius `r` round `a` lies inside `D`, then `u(a)` is the average of `u`
round the circle of radius `r` centred at `a`:
`u(a) = (1 / 2π) ∫₀^{2π} u(a + r e^{iθ}) dθ`. -/
theorem harmonic_value_eq_circle_average {D : Set ℂ} {u : ℂ → ℝ} {a : ℂ} {r : ℝ}
    (hD : IsOpen D) (hu : HarmonicOnNhd u D) (hr : 0 ≤ r) (hdisk : closedBall a r ⊆ D) :
    u a = (1 / (2 * π)) *
      ∫ θ in (0 : ℝ)..(2 * π), u (a + (r : ℂ) * Complex.exp ((θ : ℂ) * Complex.I)) := by
  have h := InnerProductSpace.HarmonicOnNhd.circleAverage_eq (f := u) (c := a) (R := r)
    (hu.mono (by rwa [abs_of_nonneg hr]))
  rw [circleAverage_def, smul_eq_mul] at h
  rw [← h, one_div]
  rfl

/-- Weak maximum principle: if `D` is a bounded open region, `u` is harmonic in `D` and
continuous up to its edge, then at every point `z` inside, `u(z)` lies between the lowest
and the highest value of `u` on the boundary `∂D`: some boundary point has value at most
`u(z)` and some boundary point has value at least `u(z)`. -/
theorem harmonic_between_boundary_min_and_max {D : Set ℂ} {u : ℂ → ℝ}
    (hD : IsOpen D) (hbdd : Bornology.IsBounded D) (hu : HarmonicOnNhd u D)
    (hcont : ContinuousOn u (closure D)) :
    ∀ z ∈ D, (∃ b ∈ frontier D, u b ≤ u z) ∧ (∃ b ∈ frontier D, u z ≤ u b) := by
  intro z hz
  obtain ⟨b₁, hb₁, hmax⟩ := harmonic_exists_frontier_isMaxOn hD hbdd ⟨z, hz⟩ hu hcont
  obtain ⟨b₂, hb₂, hmin⟩ := harmonic_exists_frontier_isMaxOn hD hbdd ⟨z, hz⟩ hu.neg hcont.neg
  refine ⟨⟨b₂, hb₂, ?_⟩, ⟨b₁, hb₁, hmax (subset_closure hz)⟩⟩
  have := (hmin (subset_closure hz)).out
  simp only [Pi.neg_apply] at this
  linarith

/-- Uniqueness for the Dirichlet problem: two functions harmonic in a bounded open region `D`,
continuous up to its edge, that agree on the whole boundary `∂D` agree everywhere in `D`. -/
theorem harmonic_eq_of_eq_on_boundary {D : Set ℂ} {u₁ u₂ : ℂ → ℝ}
    (hD : IsOpen D) (hbdd : Bornology.IsBounded D)
    (hu₁ : HarmonicOnNhd u₁ D) (hu₂ : HarmonicOnNhd u₂ D)
    (hc₁ : ContinuousOn u₁ (closure D)) (hc₂ : ContinuousOn u₂ (closure D))
    (hbd : Set.EqOn u₁ u₂ (frontier D)) :
    Set.EqOn u₁ u₂ D := by
  intro z hz
  obtain ⟨⟨b, hb, h1⟩, ⟨b', hb', h2⟩⟩ := harmonic_between_boundary_min_and_max hD hbdd
    (hu₁.sub hu₂) (hc₁.sub hc₂) z hz
  have e1 := hbd hb
  have e2 := hbd hb'
  simp only [Pi.sub_apply] at h1 h2
  linarith

-- The film u = x^2 - y^2 at the centre: 0^2 - 0^2 = 0.
example : (0 : ℤ) ^ 2 - 0 ^ 2 = 0 := by norm_num

-- Highest value on the frame: 1^2 = 1.
example : (1 : ℤ) ^ 2 = 1 := by norm_num

-- Grid film in units of the step 0.1 (heights in hundredths): u(i, j) = i^2 - j^2.
-- The node (5, 0) equals the average of its four neighbours: (36 + 16 + 24 + 24) / 4 = 25.
example : ((6 : ℤ) ^ 2 - 0 ^ 2 + (4 ^ 2 - 0 ^ 2) + (5 ^ 2 - 1 ^ 2) + (5 ^ 2 - (-1) ^ 2)) / 4
    = 5 ^ 2 - 0 ^ 2 := by norm_num

-- Highest inside grid node (9, 0), since 9^2 + 0^2 < 10^2: height 81 hundredths.
example : (9 : ℤ) ^ 2 + 0 ^ 2 < 10 ^ 2 ∧ (9 : ℤ) ^ 2 - 0 ^ 2 = 81 := by norm_num

-- Pushed sheet x^2 - y^2 + (3/2)(1 - x^2 - y^2): u_xx + u_yy = (2 - 3) + (-2 - 3) = -6.
example : ((2 : ℤ) - 3) + (-2 - 3) = -6 := by norm_num

#print axioms harmonic_value_eq_circle_average
#print axioms harmonic_between_boundary_min_and_max
#print axioms harmonic_eq_of_eq_on_boundary
