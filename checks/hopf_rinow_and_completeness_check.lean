-- Hopf-Rinow: on a connected Riemannian manifold, completeness is the same as closed bounded sets being compact, and on a globe a great circle is shortest exactly up to the antipode, where every heading ties.
import Mathlib.Geometry.Manifold.Riemannian.Basic
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Set Manifold Bundle
open scoped Manifold ContDiff ENNReal

/-- Hopf-Rinow-Cohn-Vossen, metric form: in a complete, locally compact metric space where one can
always walk most of the way from `x` towards `y` (approximate shortest routes), every closed ball
is compact. -/
theorem isCompact_closedBall_of_approx_route {X : Type*} [MetricSpace X] [CompleteSpace X]
    [LocallyCompactSpace X]
    (happ : ∀ x y : X, ∀ r : ℝ, 0 ≤ r → r ≤ dist x y → ∀ δ : ℝ, 0 < δ →
      ∃ z, dist x z ≤ r ∧ dist z y < dist x y - r + δ)
    (x : X) (r₀ : ℝ) : IsCompact (Metric.closedBall x r₀) := by
  have app' : ∀ y : X, ∀ r : ℝ, 0 ≤ r → ∀ δ : ℝ, 0 < δ →
      ∃ z, dist x z ≤ r ∧ dist z y < max (dist x y - r) 0 + δ := by
    intro y r hr δ hδ
    rcases le_total (dist x y) r with h | h
    · exact ⟨y, h, by simp; linarith [le_max_right (dist x y - r) 0]⟩
    · obtain ⟨z, hz1, hz2⟩ := happ x y r hr h δ hδ
      exact ⟨z, hz1, by linarith [le_max_left (dist x y - r) 0]⟩
  by_contra hr₀
  let S := {r : ℝ | IsCompact (Metric.closedBall x r)}
  have down : ∀ r s, s ∈ S → r ≤ s → r ∈ S := fun r s hs hrs =>
    IsCompact.of_isClosed_subset hs Metric.isClosed_closedBall
      (Metric.closedBall_subset_closedBall hrs)
  have h0 : (0 : ℝ) ∈ S := by
    show IsCompact _
    rw [Metric.closedBall_zero]; exact isCompact_singleton
  have bdd : BddAbove S := ⟨r₀, fun s hs => by
    by_contra hlt; push Not at hlt; exact hr₀ (down _ _ hs hlt.le)⟩
  set ρ := sSup S with hρdef
  have hρ0 : 0 ≤ ρ := le_csSup bdd h0
  have below : ∀ r < ρ, r ∈ S := fun r hr => by
    obtain ⟨s, hs, hrs⟩ := exists_lt_of_lt_csSup ⟨0, h0⟩ hr
    exact down r s hs hrs.le
  have hρS : ρ ∈ S := by
    rcases hρ0.eq_or_lt with h | h
    · rw [← h]; exact h0
    · show IsCompact _
      apply TotallyBounded.isCompact_of_isClosed _ Metric.isClosed_closedBall
      rw [Metric.totallyBounded_iff]
      intro ε hε
      set η := min (ε / 3) (ρ / 2) with hηdef
      have hη : 0 < η := lt_min (by linarith) (by linarith)
      have hη1 := min_le_left (ε / 3) (ρ / 2)
      have hη2 := min_le_right (ε / 3) (ρ / 2)
      have hrS : ρ - η ∈ S := below _ (by linarith)
      have hr0 : 0 ≤ ρ - η := by linarith
      obtain ⟨t, ht, hcover⟩ :=
        Metric.totallyBounded_iff.1 (IsCompact.totallyBounded hrS) (ε / 3) (by linarith)
      refine ⟨t, ht, fun y hy => ?_⟩
      obtain ⟨z, hz1, hz2⟩ := app' y (ρ - η) hr0 (ε / 3) (by linarith)
      have hz : z ∈ Metric.closedBall x (ρ - η) := by
        rw [Metric.mem_closedBall, dist_comm]; exact hz1
      obtain ⟨w, hw, hzw⟩ := mem_iUnion₂.1 (hcover hz)
      refine mem_iUnion₂.2 ⟨w, hw, ?_⟩
      rw [Metric.mem_ball] at hzw ⊢
      rw [Metric.mem_closedBall, dist_comm] at hy
      have hm : max (dist x y - (ρ - η)) 0 ≤ η := max_le (by linarith) hη.le
      calc dist y w ≤ dist y z + dist z w := dist_triangle _ _ _
        _ < ε := by rw [dist_comm y z]; linarith
  obtain ⟨K', hK', hsub⟩ := exists_compact_superset (show IsCompact (Metric.closedBall x ρ) from hρS)
  obtain ⟨δ, hδ, hth⟩ := IsCompact.exists_thickening_subset_open
    (show IsCompact (Metric.closedBall x ρ) from hρS) isOpen_interior hsub
  have hbig : ρ + δ / 2 ∈ S := by
    show IsCompact _
    apply hK'.of_isClosed_subset Metric.isClosed_closedBall
    intro y hy
    apply interior_subset
    apply hth
    rw [Metric.mem_thickening_iff]
    obtain ⟨z, hz1, hz2⟩ := app' y ρ hρ0 (δ / 2) (by linarith)
    refine ⟨z, ?_, ?_⟩
    · rw [Metric.mem_closedBall, dist_comm]; exact hz1
    · rw [Metric.mem_closedBall, dist_comm] at hy
      have hm : max (dist x y - ρ) 0 ≤ δ / 2 := max_le (by linarith) (by linarith)
      rw [dist_comm]; linarith
  have := le_csSup bdd hbig
  linarith

/-! The standard way to say "let `M` be a smooth Riemannian manifold without boundary, of finite
dimension": its distance `edist p q` is the infimum of the lengths of `C¹` routes from `p` to `q`,
each length measured with the metric's norm on the tangent spaces (`IsRiemannianManifold`). -/

section HopfRinow

variable
  {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
  {H : Type*} [TopologicalSpace H] {I : ModelWithCorners ℝ E H} [I.Boundaryless]
  {M : Type*} [MetricSpace M] [ChartedSpace H M] [IsManifold I ∞ M]
  [RiemannianBundle (fun (x : M) ↦ TangentSpace I x)]
  [IsContMDiffRiemannianBundle I ∞ E (fun (x : M) ↦ TangentSpace I x)]
  [IsRiemannianManifold I M]

include I in
omit [FiniteDimensional ℝ E] [I.Boundaryless] in
/-- On a Riemannian manifold one can walk distance `r` from `x` towards `y` and land almost on a
shortest route: the rest of the way is at most `d(x, y) - r + δ`. -/
theorem riemannian_exists_approx_route (x y : M) (r : ℝ) (hr : 0 ≤ r) (hry : r ≤ dist x y)
    (δ : ℝ) (hδ : 0 < δ) : ∃ z, dist x z ≤ r ∧ dist z y < dist x y - r + δ := by
  have h1 : riemannianEDist I x y < ENNReal.ofReal (dist x y + δ) := by
    rw [← IsRiemannianManifold.out (I := I), edist_dist,
      ENNReal.ofReal_lt_ofReal_iff (by linarith [dist_nonneg (x := x) (y := y)])]
    linarith
  obtain ⟨γ, hγ0, hγ1, hγ, hlen⟩ := exists_lt_of_riemannianEDist_lt h1
  have hcont : ContinuousOn (fun t => dist x (γ t)) (Icc 0 1) :=
    (continuous_const.dist continuous_id).comp_continuousOn hγ.continuousOn
  have hrmem : r ∈ Icc ((fun t => dist x (γ t)) 0) ((fun t => dist x (γ t)) 1) :=
    ⟨by simp [hγ0, hr], by simp [hγ1, hry]⟩
  obtain ⟨t, ht, hft⟩ := intermediate_value_Icc zero_le_one hcont hrmem
  have e1 : edist x (γ t) ≤ pathELength I γ 0 t := by
    rw [IsRiemannianManifold.out (I := I)]
    exact riemannianEDist_le_pathELength (hγ.mono (Icc_subset_Icc le_rfl ht.2)) hγ0 rfl ht.1
  have e2 : edist (γ t) y ≤ pathELength I γ t 1 := by
    rw [IsRiemannianManifold.out (I := I)]
    exact riemannianEDist_le_pathELength (hγ.mono (Icc_subset_Icc ht.1 le_rfl)) rfl hγ1 ht.2
  have e3 := pathELength_add (I := I) (γ := γ) ht.1 ht.2
  have h2 : edist x (γ t) + edist (γ t) y < ENNReal.ofReal (dist x y + δ) :=
    calc edist x (γ t) + edist (γ t) y ≤ pathELength I γ 0 t + pathELength I γ t 1 :=
          add_le_add e1 e2
      _ = pathELength I γ 0 1 := e3
      _ < _ := hlen
  rw [edist_dist, edist_dist, ← ENNReal.ofReal_add dist_nonneg dist_nonneg,
    ENNReal.ofReal_lt_ofReal_iff (by linarith [dist_nonneg (x := x) (y := y)])] at h2
  simp only at hft
  exact ⟨γ t, hft.le, by linarith⟩

include I in
/-- Hopf-Rinow, the equivalence of (a) and (c). A connected Riemannian manifold is complete
exactly when every closed and bounded set in it is compact. -/
theorem complete_iff_closed_bounded_compact [ConnectedSpace M] :
    CompleteSpace M ↔ ∀ s : Set M, IsClosed s → Bornology.IsBounded s → IsCompact s := by
  constructor
  · intro hc
    have : LocallyCompactSpace M := Manifold.locallyCompact_of_finiteDimensional I
    have : ProperSpace M :=
      ⟨isCompact_closedBall_of_approx_route (riemannian_exists_approx_route (I := I))⟩
    intro s hs hb
    exact Metric.isCompact_of_isClosed_isBounded hs hb
  · intro h
    have : ProperSpace M :=
      ⟨fun x r => h _ Metric.isClosed_closedBall Metric.isBounded_closedBall⟩
    infer_instance


end HopfRinow

section Globe

variable {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

/-- On the globe, the cut point is the antipode. Take a globe of radius `R > 0` (the points at
distance `R` from the centre, where the distance between two points is `R` times the angle between
them at the centre). Fly from `p` along the great circle `γ(t) = cos(t/R) p + R sin(t/R) u`, where
`u` is a unit heading flat along the ground at `p`. After flying `t` km, for `0 ≤ t ≤ 2πR`, the
distance home is `min(t, 2πR - t)`: the route flown is shortest exactly until `t = πR`, and after
that the way back round is shorter. Every heading `u` reaches the antipode `-p` at `t = πR`, so
there all routes tie. -/
theorem great_circle_shortest_until_antipode (R : ℝ) (hR : 0 < R) (p u : F) (hp : ‖p‖ = R)
    (hu : ‖u‖ = 1) (hpu : inner ℝ p u = 0) (t : ℝ) (ht0 : 0 ≤ t) (ht : t ≤ 2 * Real.pi * R) :
    let γ : ℝ → F := fun s => Real.cos (s / R) • p + (R * Real.sin (s / R)) • u
    R * InnerProductGeometry.angle p (γ t) = min t (2 * Real.pi * R - t) ∧
      γ (Real.pi * R) = -p := by
  intro γ
  constructor
  · have hR0 : R ≠ 0 := hR.ne'
    have hinner : inner ℝ p (γ t) = Real.cos (t / R) * R ^ 2 := by
      simp only [γ, inner_add_right, inner_smul_right, hpu, real_inner_self_eq_norm_sq, hp]
      ring
    have hnorm : ‖γ t‖ = R := by
      have h2 : ‖γ t‖ ^ 2 = R ^ 2 := by
        simp only [γ]
        rw [norm_add_sq_real, inner_smul_left, inner_smul_right, hpu, norm_smul, norm_smul,
          Real.norm_eq_abs, Real.norm_eq_abs, hp, hu]
        simp only [mul_zero, mul_one, conj_trivial]
        rw [mul_pow, sq_abs, sq_abs]
        nlinarith [Real.sin_sq_add_cos_sq (t / R)]
      have := abs_of_pos hR
      nlinarith [norm_nonneg (γ t), sq_nonneg (‖γ t‖ - R), sq_nonneg (‖γ t‖ + R)]
    unfold InnerProductGeometry.angle
    rw [hinner, hnorm, hp]
    have hc : Real.cos (t / R) * R ^ 2 / (R * R) = Real.cos (t / R) := by
      field_simp
    rw [hc]
    have hθ0 : 0 ≤ t / R := div_nonneg ht0 hR.le
    have hθ2 : t / R ≤ 2 * Real.pi := by rw [div_le_iff₀ hR]; linarith
    rcases le_total t (Real.pi * R) with h | h
    · have hθ : t / R ≤ Real.pi := by rw [div_le_iff₀ hR]; linarith
      rw [Real.arccos_cos hθ0 hθ, min_eq_left (by linarith)]
      field_simp
    · have hθ : Real.pi ≤ t / R := by rw [le_div_iff₀ hR]; linarith
      rw [← Real.cos_two_pi_sub, Real.arccos_cos (by linarith) (by linarith),
        min_eq_right (by linarith)]
      field_simp
  · simp only [γ]
    rw [mul_div_assoc, div_self hR.ne', mul_one, Real.cos_pi, Real.sin_pi]
    simp

end Globe

#print axioms isCompact_closedBall_of_approx_route
#print axioms riemannian_exists_approx_route
#print axioms complete_iff_closed_bounded_compact
#print axioms great_circle_shortest_until_antipode
