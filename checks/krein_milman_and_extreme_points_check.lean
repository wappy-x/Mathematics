-- Krein-Milman: a nonempty compact convex set in a real normed space has extreme points and is the closure of their convex hull.
import Mathlib.Analysis.Convex.KreinMilman
import Mathlib.Analysis.LocallyConvex.WithSeminorms
import Mathlib.LinearAlgebra.AffineSpace.FiniteDimensional
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Normed.Module.HahnBanach
import Mathlib.Analysis.Normed.Affine.AddTorsorBases
import Mathlib.Analysis.Convex.Caratheodory

open Set

theorem km_aux_supporting_functional
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {K : Set E}
    (hconv : Convex ℝ K) {a x₁ x₂ : E} (ha : a ∈ K) (hx₁ : x₁ ∈ K) (hx₂ : x₂ ∈ K)
    (hray : ∀ t : ℝ, 0 < t → a + t • (x₂ - x₁) ∉ K) :
    ∃ g : E →L[ℝ] ℝ, (∀ k ∈ K, g k ≤ g a) ∧ ∃ k₀ ∈ K, g k₀ < g a := by
  set S : Set E := (fun k => k - a) '' K with hS
  set V : Submodule ℝ E := Submodule.span ℝ S with hV
  set K' : Set V := ((↑) : V → E) ⁻¹' S with hK'
  have hmemK' : ∀ v : V, v ∈ K' ↔ (v : E) + a ∈ K := by
    intro v
    simp only [hK', hS, mem_preimage, mem_image]
    constructor
    · rintro ⟨k, hk, hkv⟩
      rw [← hkv]; simpa using hk
    · intro h
      exact ⟨(v : E) + a, h, by simp⟩
  have hSconv : Convex ℝ S := by
    have : S = (fun k => -a + k) '' K := by simp [hS, neg_add_eq_sub]
    rw [this]
    exact hconv.translate (-a)
  have hK'conv : Convex ℝ K' := hSconv.linear_preimage V.subtype
  have h0 : (0 : V) ∈ K' := by rw [hmemK']; simpa using ha
  have hspan : affineSpan ℝ K' = ⊤ := by
    rw [AffineSubspace.affineSpan_eq_top_iff_vectorSpan_eq_top_of_nonempty ℝ V V ⟨0, h0⟩,
      vectorSpan_eq_span_vsub_set_right ℝ h0]
    simp only [vsub_eq_sub, sub_zero, image_id']
    exact Submodule.span_span_coe_preimage
  have hint : (interior K').Nonempty := (hK'conv.interior_nonempty_iff_affineSpan_eq_top).2 hspan
  have hu : x₂ - x₁ ∈ V := by
    have h1 : x₁ - a ∈ V := Submodule.subset_span ⟨x₁, hx₁, rfl⟩
    have h2 : x₂ - a ∈ V := Submodule.subset_span ⟨x₂, hx₂, rfl⟩
    have := V.sub_mem h2 h1
    simpa using this
  set u' : V := ⟨x₂ - x₁, hu⟩
  have h0int : (0 : V) ∉ interior K' := by
    intro h
    have hev : ∀ᶠ t in nhds (0 : ℝ), t • u' ∈ K' := by
      have hc : Continuous fun t : ℝ => t • u' := continuous_id.smul continuous_const
      have : interior K' ∈ nhds ((fun t : ℝ => t • u') 0) := by
        simpa using isOpen_interior.mem_nhds h
      exact Filter.mem_of_superset (hc.continuousAt.preimage_mem_nhds this)
        fun t (ht : t • u' ∈ interior K') => (interior_subset (s := K') ht : _)
    obtain ⟨t, ht, htpos⟩ :=
      ((hev.filter_mono nhdsWithin_le_nhds).and (self_mem_nhdsWithin (s := Ioi (0 : ℝ)))).exists
    apply hray t htpos
    have := (hmemK' _).1 ht
    simpa [u', add_comm] using this
  obtain ⟨f, hf⟩ := geometric_hahn_banach_open_point hK'conv.interior isOpen_interior h0int
  have hfle : ∀ w ∈ K', f w ≤ 0 := by
    have hcl : K' ⊆ closure (interior K') := by
      rw [hK'conv.closure_interior_eq_closure_of_nonempty_interior hint]; exact subset_closure
    have hclosed : IsClosed {w : V | f w ≤ 0} := isClosed_le f.continuous continuous_const
    intro w hw
    have := closure_minimal (fun z hz => by simpa using (hf z hz).le) hclosed (hcl hw)
    exact this
  obtain ⟨g, hg, -⟩ := exists_extension_norm_eq V f
  refine ⟨g, fun k hk => ?_, ?_⟩
  · have hv : k - a ∈ V := Submodule.subset_span ⟨k, hk, rfl⟩
    have h1 := hfle ⟨k - a, hv⟩ ((hmemK' _).2 (by simpa using hk))
    have h2 := hg ⟨k - a, hv⟩
    simp only [map_sub] at h2
    linarith
  · obtain ⟨w, hw⟩ := hint
    have hwK := (hmemK' w).1 (interior_subset hw)
    refine ⟨(w : E) + a, hwK, ?_⟩
    have h1 := hf w hw
    have h2 := hg w
    simp only [map_zero] at h1
    rw [map_add]
    linarith
theorem km_aux_finrank_lt
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {K F : Set E}
    (hFK : F ⊆ K) (hFne : F.Nonempty) (g : E →L[ℝ] ℝ) (c : ℝ) (hF : ∀ z ∈ F, g z = c)
    {k₀ : E} (hk₀ : k₀ ∈ K) (hgk₀ : g k₀ ≠ c) :
    Module.finrank ℝ (affineSpan ℝ F).direction < Module.finrank ℝ (affineSpan ℝ K).direction := by
  have hlt : affineSpan ℝ F < affineSpan ℝ K := by
    refine lt_of_le_of_ne (affineSpan_mono ℝ hFK) ?_
    intro heq
    have hk : k₀ ∈ affineSpan ℝ F := heq ▸ subset_affineSpan ℝ K hk₀
    have hmap : (g : E →ₗ[ℝ] ℝ).toAffineMap k₀ ∈
        (affineSpan ℝ F).map (g : E →ₗ[ℝ] ℝ).toAffineMap := ⟨k₀, hk, rfl⟩
    rw [AffineSubspace.map_span] at hmap
    have hsub : (g : E →ₗ[ℝ] ℝ).toAffineMap '' F ⊆ {c} := by
      rintro _ ⟨z, hz, rfl⟩
      simpa using hF z hz
    have := affineSpan_mono ℝ hsub hmap
    rw [AffineSubspace.mem_affineSpan_singleton] at this
    exact hgk₀ (by simpa using this)
  exact Submodule.finrank_lt_finrank_of_lt
    (AffineSubspace.direction_lt_of_nonempty hlt (hFne.mono (subset_affineSpan ℝ F)))

theorem km_aux_subset_convexHull_extremePoints
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] :
    ∀ (n : ℕ) (K : Set E), IsCompact K → Convex ℝ K →
      Module.finrank ℝ (affineSpan ℝ K).direction = n → K ⊆ convexHull ℝ (K.extremePoints ℝ) := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro K hK hconv hn
  -- a point from which a ray inside the span leaves `K` at once lies in a lower-dimensional face
  have key : ∀ a ∈ K, ∀ y₁ ∈ K, ∀ y₂ ∈ K, (∀ t : ℝ, 0 < t → a + t • (y₂ - y₁) ∉ K) →
      a ∈ convexHull ℝ (K.extremePoints ℝ) := by
    intro a ha y₁ hy₁ y₂ hy₂ hray
    obtain ⟨g, hga, k₀, hk₀, hgk₀⟩ := km_aux_supporting_functional hconv ha hy₁ hy₂ hray
    set F : Set E := {z ∈ K | ∀ w ∈ K, g w ≤ g z} with hFdef
    have hexp : IsExposed ℝ K F := fun _ => ⟨g, rfl⟩
    have haF : a ∈ F := ⟨ha, hga⟩
    have hFc : ∀ z ∈ F, g z = g a := fun z hz => le_antisymm (hga z hz.1) (hz.2 a ha)
    have hlt := km_aux_finrank_lt (K := K) (F := F) (fun z hz => hz.1) ⟨a, haF⟩ g (g a) hFc hk₀
      hgk₀.ne
    rw [hn] at hlt
    have hsub := ih _ hlt F (hexp.isCompact hK) (hexp.convex hconv) rfl haF
    exact convexHull_mono hexp.isExtreme.extremePoints_subset_extremePoints hsub
  intro x hx
  by_cases hxe : x ∈ K.extremePoints ℝ
  · exact subset_convexHull ℝ _ hxe
  rw [mem_extremePoints] at hxe
  push Not at hxe
  obtain ⟨x₁, hx₁, x₂, hx₂, hseg, hne⟩ := hxe hx
  set u : E := x₂ - x₁ with hu
  have hu0 : u ≠ 0 := by
    intro h0
    have : x₂ = x₁ := sub_eq_zero.1 h0
    rw [this, openSegment_same] at hseg
    exact hne hseg.symm (by rw [this]; exact hseg.symm)
  set T : Set ℝ := {t | x + t • u ∈ K} with hT
  have hTclosed : IsClosed T :=
    hK.isClosed.preimage (continuous_const.add (continuous_id.smul continuous_const))
  obtain ⟨C, hC⟩ := (isBounded_iff_forall_norm_le.1 hK.isBounded)
  have hupos : 0 < ‖u‖ := norm_pos_iff.2 hu0
  have hTsub : T ⊆ Icc (-(2 * C / ‖u‖)) (2 * C / ‖u‖) := by
    intro t ht
    have h1 := hC _ ht
    have h2 := hC _ hx
    have h3 : |t| * ‖u‖ ≤ 2 * C := by
      rw [← Real.norm_eq_abs, ← norm_smul]
      calc ‖t • u‖ = ‖(x + t • u) - x‖ := by simp
        _ ≤ ‖x + t • u‖ + ‖x‖ := norm_sub_le _ _
        _ ≤ 2 * C := by linarith
    have h4 : |t| ≤ 2 * C / ‖u‖ := (le_div_iff₀ hupos).2 h3
    exact abs_le.1 h4
  have hTc : IsCompact T := isCompact_Icc.of_isClosed_subset hTclosed hTsub
  have h0T : (0 : ℝ) ∈ T := by simpa [hT] using hx
  obtain ⟨s, hsT, hsmax⟩ := hTc.exists_isMaxOn ⟨0, h0T⟩ continuousOn_id
  obtain ⟨s', hs'T, hs'min⟩ := hTc.exists_isMinOn ⟨0, h0T⟩ continuousOn_id
  have hsmax' : ∀ t ∈ T, t ≤ s := fun t ht => isMaxOn_iff.1 hsmax t ht
  have hs'min' : ∀ t ∈ T, s' ≤ t := fun t ht => isMinOn_iff.1 hs'min t ht
  have ha : x + s • u ∈ convexHull ℝ (K.extremePoints ℝ) := by
    refine key _ hsT x₁ hx₁ x₂ hx₂ fun t ht hmem => ?_
    have : s + t ∈ T := by
      show x + (s + t) • u ∈ K
      rw [add_smul, ← add_assoc]; exact hmem
    linarith [hsmax' _ this]
  have hb : x + s' • u ∈ convexHull ℝ (K.extremePoints ℝ) := by
    refine key _ hs'T x₂ hx₂ x₁ hx₁ fun t ht hmem => ?_
    have : s' - t ∈ T := by
      show x + (s' - t) • u ∈ K
      have : x + (s' - t) • u = x + s' • u + t • (x₁ - x₂) := by rw [hu]; module
      rw [this]; exact hmem
    linarith [hs'min' _ this]
  have hs0 : 0 ≤ s := hsmax' 0 h0T
  have hs'0 : s' ≤ 0 := hs'min' 0 h0T
  rcases eq_or_lt_of_le hs0 with h | h
  · rw [← h, zero_smul, add_zero] at ha; exact ha
  have hd : 0 < s - s' := by linarith
  refine (convex_convexHull ℝ _).segment_subset hb ha ⟨s / (s - s'), -s' / (s - s'),
    div_nonneg hs0 hd.le, div_nonneg (by linarith) hd.le, by field_simp; ring, ?_⟩
  have e1 : (s / (s - s')) • (x + s' • u) + (-s' / (s - s')) • (x + s • u) =
      (s / (s - s') + -s' / (s - s')) • x + (s / (s - s') * s' + -s' / (s - s') * s) • u := by
    module
  have e2 : s / (s - s') + -s' / (s - s') = 1 := by field_simp; ring
  have e3 : s / (s - s') * s' + -s' / (s - s') * s = 0 := by field_simp; ring
  rw [e1, e2, e3, one_smul, zero_smul, add_zero]

/-- **The Krein-Milman theorem.** If `K` is a nonempty compact convex set in a real normed space,
then `K` has an extreme point (a point that is not the midpoint of two other points of `K`), and
`K` is the closure of the convex hull of its extreme points: every point of `K` is an average of
extreme points or a limit of such averages. -/
theorem krein_milman_compact_convex_eq_closed_hull_of_extreme_points
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {K : Set E}
    (hK : IsCompact K) (hconv : Convex ℝ K) (hne : K.Nonempty) :
    (K.extremePoints ℝ).Nonempty ∧ closure (convexHull ℝ (K.extremePoints ℝ)) = K := by
  exact ⟨hK.extremePoints_nonempty hne, closure_convexHull_extremePoints hK hconv⟩

/-- **Minkowski's theorem**, the finite case. If `K` is a compact convex set of dimension `d`
(the dimension of the smallest flat containing it) in a finite-dimensional real normed space,
then every point `x` of `K` is an average of at most `d + 1` extreme points of `K`:
`x = λ₁ v₁ + ⋯ + λₘ vₘ` with every `vₖ` extreme, every `λₖ ≥ 0`, the weights adding to 1,
and `m ≤ d + 1`. -/
theorem minkowski_point_is_average_of_at_most_d_plus_one_extreme_points
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {K : Set E}
    (hK : IsCompact K) (hconv : Convex ℝ K) {x : E} (hx : x ∈ K) :
    ∃ (m : ℕ) (w : Fin m → ℝ) (v : Fin m → E),
      m ≤ Module.finrank ℝ (affineSpan ℝ K).direction + 1 ∧
      (∀ k, 0 ≤ w k) ∧ ∑ k, w k = 1 ∧ (∀ k, v k ∈ K.extremePoints ℝ) ∧
      ∑ k, w k • v k = x := by
  have hxc := km_aux_subset_convexHull_extremePoints _ K hK hconv rfl hx
  obtain ⟨ι, _, z, w, hz, hind, hw, hw1, hwz⟩ := eq_pos_convex_span_of_mem_convexHull hxc
  have hcard : Fintype.card ι ≤ Module.finrank ℝ (affineSpan ℝ K).direction + 1 := by
    refine hind.card_le_finrank_succ.trans (Nat.add_le_add_right ?_ 1)
    rw [direction_affineSpan]
    exact Submodule.finrank_mono (vectorSpan_mono ℝ (hz.trans extremePoints_subset))
  let e : ι ≃ Fin (Fintype.card ι) := Fintype.equivFin ι
  refine ⟨Fintype.card ι, w ∘ e.symm, z ∘ e.symm, hcard, fun k => (hw _).le, ?_,
    fun k => hz ⟨_, rfl⟩, ?_⟩
  · rw [← hw1]; exact e.symm.sum_comp w
  · rw [← hwz]; exact e.symm.sum_comp (fun i => w i • z i)

/-- **Bauer's maximum principle, linear case.** A bounded linear functional `φ` reaches its
largest value on a nonempty compact convex set `K` in a real normed space at an extreme point
of `K`. -/
theorem bauer_bounded_functional_max_at_extreme_point
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {K : Set E}
    (hK : IsCompact K) (hconv : Convex ℝ K) (hne : K.Nonempty) (φ : E →L[ℝ] ℝ) :
    ∃ e ∈ K.extremePoints ℝ, ∀ y ∈ K, φ y ≤ φ e := by
  have h : IsExposed ℝ K {z ∈ K | ∀ w ∈ K, φ w ≤ φ z} := fun _ => ⟨φ, rfl⟩
  obtain ⟨z, hzK, hz⟩ := hK.exists_isMaxOn hne φ.continuous.continuousOn
  obtain ⟨e, he⟩ := (h.isCompact hK).extremePoints_nonempty ⟨z, hzK, fun w hw => hz hw⟩
  exact ⟨e, h.isExtreme.extremePoints_subset_extremePoints he, he.1.2⟩

-- The allowed plans: depot 1 sends u, v, 30 - u - v; depot 2 sends 15 - u, 25 - v, u + v - 20.
-- There are 161 whole-pallet plans.
example : ((List.range 16).flatMap fun u => (List.range 26).filterMap fun v =>
    if 20 ≤ u + v && u + v ≤ 30 then some (u, v) else none).length = 161 := by rfl

-- The proportional plan: x_ij = a_i b_j / 50.
example : (30 * 15 / 50, 30 * 25 / 50, 30 * 10 / 50) = (9, 15, 6) := by norm_num
example : (20 * 15 / 50, 20 * 25 / 50, 20 * 10 / 50) = (6, 10, 4) := by norm_num

-- The peel: depot 2 to shop 1 runs out first, at t = 15/9 = 5/3, stopping at (15, 35/3).
example : (15 / 9 : ℚ) = 5 / 3 ∧ (5 / 3 : ℚ) < 10 / 4 ∧ (5 / 3 : ℚ) < 20 / 5 := by norm_num
example : (0 + 5 / 3 * 9 : ℚ) = 15 ∧ (20 + 5 / 3 * (-5) : ℚ) = 35 / 3 := by norm_num
-- First split 1 - 1/t and 1/t; second split on the edge u = 15; the product weights.
example : (1 - 1 / (5 / 3) : ℚ) = 2 / 5 ∧ (1 / (5 / 3) : ℚ) = 3 / 5 := by norm_num
example : (1 / 3 * 5 + 2 / 3 * 15 : ℚ) = 35 / 3 := by norm_num
example : (3 / 5 * (1 / 3) : ℚ) = 1 / 5 ∧ (3 / 5 * (2 / 3) : ℚ) = 2 / 5 := by norm_num

-- The rebuild: 2/5 (0, 20) + 1/5 (15, 5) + 2/5 (15, 15) = (9, 15).
example : (2 / 5 * 0 + 1 / 5 * 15 + 2 / 5 * 15 : ℚ) = 9 ∧
    (2 / 5 * 20 + 1 / 5 * 5 + 2 / 5 * 15 : ℚ) = 15 := by norm_num

-- Corner costs at £4, £6, £9 from depot 1 and £5, £3, £7 from depot 2, and the cost check.
example : 4 * 0 + 6 * 20 + 9 * 10 + 5 * 15 + 3 * 5 + 7 * 0 = 300 := by norm_num
example : 4 * 15 + 6 * 5 + 9 * 10 + 5 * 0 + 3 * 20 + 7 * 0 = 240 := by norm_num
example : 4 * 15 + 6 * 15 + 9 * 0 + 5 * 0 + 3 * 10 + 7 * 10 = 250 := by norm_num
example : 4 * 9 + 6 * 15 + 9 * 6 + 5 * 6 + 3 * 10 + 7 * 4 = 268 := by norm_num
example : (2 / 5 * 300 + 1 / 5 * 240 + 2 / 5 * 250 : ℚ) = 268 := by norm_num

-- One plan, many rebuilds: the other three corner triangles that hold (9, 15).
example : (2 / 15 * 0 + 2 / 5 * 5 + 7 / 15 * 15 : ℚ) = 9 ∧
    (2 / 15 * 20 + 2 / 5 * 25 + 7 / 15 * 5 : ℚ) = 15 := by norm_num
example : (1 / 5 * 0 + 3 / 10 * 5 + 1 / 2 * 15 : ℚ) = 9 ∧
    (1 / 5 * 25 + 3 / 10 * 25 + 1 / 2 * 5 : ℚ) = 15 := by norm_num
example : (2 / 5 * 0 + 2 / 5 * 15 + 1 / 5 * 15 : ℚ) = 9 ∧
    (2 / 5 * 25 + 2 / 5 * 5 + 1 / 5 * 15 : ℚ) = 15 := by norm_num

-- N depots and N shops: N! corners, dimension (N - 1)^2.
example : (Nat.factorial 2, Nat.factorial 3, Nat.factorial 4) = (2, 6, 24) := by decide
example : ((2 - 1) ^ 2, (3 - 1) ^ 2, (4 - 1) ^ 2) = (1, 4, 9) := by decide

#print axioms km_aux_supporting_functional
#print axioms km_aux_finrank_lt
#print axioms km_aux_subset_convexHull_extremePoints
#print axioms krein_milman_compact_convex_eq_closed_hull_of_extreme_points
#print axioms minkowski_point_is_average_of_at_most_d_plus_one_extreme_points
#print axioms bauer_bounded_functional_max_at_extreme_point
