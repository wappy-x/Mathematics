-- Laplace's equation: a settled temperature with no sources inside a bounded plate stays between its lowest and highest edge temperatures, is fixed by its edge temperatures, and equals its average round every circle inside the plate.
import Mathlib.Analysis.Complex.Harmonic.MeanValue
import Mathlib.Analysis.Complex.AbsMax
import Mathlib.Tactic.NormNum

/-! The plate is a set `U` of points in the plane, written as complex numbers `x + y i`.
A temperature `u : ℂ → ℝ` obeys Laplace's equation `u_xx + u_yy = 0` with no sources inside
(`HarmonicOnNhd u U`: twice continuously differentiable round each point of `U`, Laplacian zero
there). "Every edge held" means `u` is also continuous up to the edge (`closure U`); together these
are Mathlib's `HarmonicContOnCl u U`. The edge is `frontier U`. -/

open InnerProductSpace Metric

theorem laplace_const_on_ball_of_max {u : ℂ → ℝ} {w : ℂ} {r : ℝ}
    (hh : HarmonicOnNhd u (ball w r)) (hmax : ∀ z ∈ ball w r, u z ≤ u w) (hr : 0 < r) :
    ∀ z ∈ ball w r, u z = u w := by
  obtain ⟨F, hF, hFu⟩ := hh.exists_analyticOnNhd_ball_re_eq
  have hw : w ∈ ball w r := mem_ball_self hr
  have hn : ∀ z ∈ ball w r, ‖Complex.exp (F z)‖ = Real.exp (u z) := by
    intro z hz
    rw [Complex.norm_exp]; exact congrArg Real.exp (hFu hz)
  have hd : DifferentiableOn ℂ (fun z => Complex.exp (F z)) (ball w r) :=
    hF.differentiableOn.cexp
  have hm : IsMaxOn (norm ∘ fun z => Complex.exp (F z)) (ball w r) w := by
    intro z hz
    simp only [Set.mem_ofPred_eq, Function.comp_apply]
    rw [hn z hz, hn w hw]
    exact Real.exp_le_exp.2 (hmax z hz)
  intro z hz
  have := Complex.norm_eqOn_of_isPreconnected_of_isMaxOn (convex_ball w r).isPreconnected
    isOpen_ball hd hw hm hz
  simp only [Function.comp_apply, Function.const_apply] at this
  rw [hn z hz, hn w hw] at this
  exact Real.exp_injective this

#print axioms laplace_const_on_ball_of_max

theorem laplace_upper_bound_of_edge {U : Set ℂ} (hU : Bornology.IsBounded U)
    {u : ℂ → ℝ} (hu : HarmonicContOnCl u U) {M : ℝ}
    (hedge : ∀ w ∈ frontier U, u w ≤ M) :
    ∀ z ∈ closure U, u z ≤ M := by
  intro z hz
  obtain ⟨w, hwU, hwmax⟩ := hU.isCompact_closure.exists_isMaxOn ⟨z, hz⟩ hu.continuousOn
  suffices h : ∃ p ∈ frontier U, u p = u w by
    obtain ⟨p, hp, hpw⟩ := h
    have h1 : u z ≤ u w := hwmax hz
    have h2 := hedge p hp
    linarith
  by_cases hwf : w ∈ frontier U
  · exact ⟨w, hwf, rfl⟩
  have hwi : w ∈ interior U := by
    rw [← closure_sdiff_frontier]
    exact ⟨hwU, hwf⟩
  have hne : (interior U)ᶜ.Nonempty := by
    by_contra h
    rw [Set.not_nonempty_iff_eq_empty, Set.compl_empty_iff] at h
    have hUu : U = Set.univ := Set.eq_univ_of_univ_subset (h ▸ interior_subset)
    rw [hUu] at hU
    exact NormedSpace.unbounded_univ ℝ ℂ hU
  have hcl : IsClosed (interior U)ᶜ := isOpen_interior.isClosed_compl
  obtain ⟨p, hp, hpd⟩ := hcl.exists_infDist_eq_dist hne w
  set r := infDist w (interior U)ᶜ with hrdef
  have hr : 0 < r := (hcl.notMem_iff_infDist_pos hne).1 (by simpa using hwi)
  have hball : ball w r ⊆ interior U := ball_infDist_compl_subset
  have hballU : ball w r ⊆ U := hball.trans interior_subset
  have hconst : Set.EqOn u (fun _ => u w) (ball w r) :=
    laplace_const_on_ball_of_max (hu.1.mono hballU)
      (fun y hy => hwmax (subset_closure (hballU hy))) hr
  have hpcl : p ∈ closure (ball w r) := by
    rw [closure_ball w hr.ne', mem_closedBall, dist_comm, hpd]
  have hcont : ContinuousOn u (closure (ball w r)) := hu.2.mono (closure_mono hballU)
  have hext := hconst.of_subset_closure hcont continuousOn_const subset_closure le_rfl
  refine ⟨p, ⟨closure_mono hballU hpcl, hp⟩, hext hpcl⟩

#print axioms laplace_upper_bound_of_edge

/-- The maximum principle. A settled temperature with no sources inside a bounded plate, continuous
up to its edge, has no hot or cold spot inside: if every edge point reads between `m` and `M`,
then every point of the plate reads between `m` and `M` too. Its extremes sit on the edge. -/
theorem laplace_extremes_sit_on_the_edge {U : Set ℂ} (hU : Bornology.IsBounded U)
    {u : ℂ → ℝ} (hu : HarmonicContOnCl u U) {m M : ℝ}
    (hedge : ∀ w ∈ frontier U, m ≤ u w ∧ u w ≤ M) :
    ∀ z ∈ closure U, m ≤ u z ∧ u z ≤ M := by
  intro z hz
  refine ⟨?_, laplace_upper_bound_of_edge hU hu (fun w hw => (hedge w hw).2) z hz⟩
  have h := laplace_upper_bound_of_edge (u := -u) (M := -m) hU hu.neg
    (fun w hw => by simp only [Pi.neg_apply]; linarith [(hedge w hw).1]) z hz
  simp only [Pi.neg_apply] at h
  linarith

/-- Uniqueness for the Dirichlet problem. Two settled temperatures with no sources inside the same
bounded plate, both continuous up to its edge, that agree on the edge agree everywhere on the
plate: the edge temperatures fix the pattern completely. -/
theorem laplace_edge_fixes_everything {U : Set ℂ} (hU : Bornology.IsBounded U)
    {u v : ℂ → ℝ} (hu : HarmonicContOnCl u U) (hv : HarmonicContOnCl v U)
    (hedge : Set.EqOn u v (frontier U)) :
    Set.EqOn u v (closure U) := by
  intro z hz
  have h := laplace_extremes_sit_on_the_edge (m := 0) (M := 0) hU (hu.sub hv)
    (fun w hw => by simp only [Pi.sub_apply]; rw [hedge hw]; simp) z hz
  simp only [Pi.sub_apply] at h
  linarith [h.1, h.2]

/-- The averaging rule. A settled temperature with no sources inside the plate equals, at each
point `c`, its average round any circle centred at `c` that stays inside the plate (the closed disc
of radius `|r|` lies in the plate). -/
theorem laplace_point_is_its_circle_average {U : Set ℂ} {u : ℂ → ℝ}
    (hu : HarmonicOnNhd u U) {c : ℂ} {r : ℝ} (hr : closedBall c |r| ⊆ U) :
    Real.circleAverage u c r = u c := by
  exact (hu.mono hr).circleAverage_eq

-- One interior grid point, h = 1/2: the neighbour average (100 + 0 + 0 + 0) / 4 = 25.
example : ((100 : ℚ) + 0 + 0 + 0) / 4 = 25 := by norm_num
-- Four quarter turns: the four equal centre values add to 100, so each is 25.
example : (4 : ℚ) * 25 = 100 := by norm_num
example : ∀ c : ℚ, 4 * c = 100 → c = 25 := by intro c h; linarith
-- Heated plate, one interior point: 0 + (1/4)(100) / 4 = 25/4 degrees.
example : (0 : ℚ) + (1 / 4) * 100 / 4 = 25 / 4 := by norm_num
-- Half-plane: u = y at (1/2, 2) with grid step 1/10 has neighbour average 2, equal to u there.
example : ((2 : ℚ) + 2 + 21 / 10 + 19 / 10) / 4 = 2 := by norm_num

#print axioms laplace_extremes_sit_on_the_edge
#print axioms laplace_edge_fixes_everything
#print axioms laplace_point_is_its_circle_average
