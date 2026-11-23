-- Working on a problem: in the plane, n distinct points have at most n(1 + sqrt(8n - 7))/4 pairs at distance exactly 1, because the unit neighbours of every point, taken two at a time, number at most 2 · C(n, 2), and nine points do reach 18 such pairs.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Geometry.Euclidean.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Combinatorics.Enumerative.DoubleCounting
import Mathlib.Algebra.Order.Chebyshev
import Mathlib.Data.Nat.Choose.Cast

open Finset

/-- The plane, with ordinary straight-line distance. -/
abbrev Plane := EuclideanSpace ℝ (Fin 2)

/-- The unit neighbours of `v` in `P`: the points of `P` at distance exactly 1 from `v`.
Their number is the degree d(v). -/
noncomputable def unitNeighbours (P : Finset Plane) (v : Plane) : Finset Plane :=
  {w ∈ P | dist v w = 1}

/-- The unit pairs of `P`: the unordered pairs {p, q} of distinct points of `P` with
|p − q| = 1. -/
noncomputable def unitPairs (P : Finset Plane) : Finset (Finset Plane) :=
  {s ∈ P.powersetCard 2 | ∀ p ∈ s, ∀ q ∈ s, p ≠ q → dist p q = 1}

/-- Two common unit neighbours at most: two distinct points `a`, `b` of the plane have at most
two points of `P` at distance 1 from both (two unit circles with different centres meet at most
twice). -/
lemma card_common_unit_neighbours_le_two (P : Finset Plane) {a b : Plane} (hab : a ≠ b) :
    (P.filter (fun v => dist v a = 1 ∧ dist v b = 1)).card ≤ 2 := by
  by_contra h
  push Not at h
  obtain ⟨x, hx, y, hy, z, hz, hxy, hxz, hyz⟩ := Finset.two_lt_card.mp h
  simp only [Finset.mem_filter] at hx hy hz
  have hd : Module.finrank ℝ (EuclideanSpace ℝ (Fin 2)) = 2 := by simp
  rcases EuclideanGeometry.eq_of_dist_eq_of_dist_eq_of_finrank_eq_two hd hab hxy hx.2.1 hy.2.1
      hz.2.1 hx.2.2 hy.2.2 hz.2.2 with h | h
  · exact hxz h.symm
  · exact hyz h.symm

/-- The cherry count, as a helper (the theorem below restates it): summing C(d(v), 2) over the
points gives at most 2 · C(n, 2). -/
lemma sum_choose_degree_le (P : Finset Plane) :
    ∑ v ∈ P, (unitNeighbours P v).card.choose 2 ≤ 2 * P.card.choose 2 := by
  classical
  have h1 : ∀ v ∈ P, (unitNeighbours P v).card.choose 2 =
      ((P.powersetCard 2).bipartiteAbove (fun v s => s ⊆ unitNeighbours P v) v).card := by
    intro v _
    rw [← Finset.card_powersetCard]
    congr 1
    ext s
    simp only [Finset.bipartiteAbove, Finset.mem_filter, Finset.mem_powersetCard]
    constructor
    · rintro ⟨hs, hc⟩
      exact ⟨⟨hs.trans (Finset.filter_subset _ _), hc⟩, hs⟩
    · rintro ⟨⟨_, hc⟩, hs⟩
      exact ⟨hs, hc⟩
  rw [Finset.sum_congr rfl h1, Finset.sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow]
  have h2 : ∀ s ∈ P.powersetCard 2,
      (P.bipartiteBelow (fun v s => s ⊆ unitNeighbours P v) s).card ≤ 2 := by
    intro s hs
    rw [Finset.mem_powersetCard] at hs
    obtain ⟨a, b, hab, rfl⟩ := Finset.card_eq_two.mp hs.2
    refine le_trans (Finset.card_le_card ?_) (card_common_unit_neighbours_le_two P hab)
    intro v hv
    simp only [Finset.bipartiteBelow, Finset.mem_filter, Finset.insert_subset_iff,
      Finset.singleton_subset_iff, unitNeighbours] at hv ⊢
    exact ⟨hv.1, hv.2.1.2, hv.2.2.2⟩
  calc ∑ s ∈ P.powersetCard 2, (P.bipartiteBelow (fun v s => s ⊆ unitNeighbours P v) s).card
      ≤ (P.powersetCard 2).card • 2 := Finset.sum_le_card_nsmul _ _ _ h2
    _ = 2 * P.card.choose 2 := by rw [Finset.card_powersetCard, smul_eq_mul, mul_comm]

/-- Each point lies in at most d(v) unit pairs: every unit pair through `v` is `{v, w}` for a
unit neighbour `w` of `v`. -/
lemma card_unitPairs_through_le (P : Finset Plane) (v : Plane) :
    ((unitPairs P).filter (fun s => v ∈ s)).card ≤ (unitNeighbours P v).card := by
  classical
  calc ((unitPairs P).filter (fun s => v ∈ s)).card
      ≤ ((unitNeighbours P v).image (fun w => ({v, w} : Finset Plane))).card := by
        apply Finset.card_le_card
        intro s hs
        simp only [unitPairs, Finset.mem_filter, Finset.mem_powersetCard] at hs
        obtain ⟨⟨⟨hsP, hs2⟩, hunit⟩, hv⟩ := hs
        obtain ⟨a, b, hab, rfl⟩ := Finset.card_eq_two.mp hs2
        simp only [Finset.mem_image, unitNeighbours, Finset.mem_filter]
        simp only [Finset.mem_insert, Finset.mem_singleton] at hv
        have ha : a ∈ P := hsP (by simp)
        have hb : b ∈ P := hsP (by simp)
        rcases hv with rfl | rfl
        · exact ⟨b, ⟨hb, hunit v (by simp) b (by simp) hab⟩, rfl⟩
        · exact ⟨a, ⟨ha, hunit v (by simp) a (by simp) (Ne.symm hab)⟩, Finset.pair_comm _ _⟩
    _ ≤ (unitNeighbours P v).card := Finset.card_image_le

/-- The handshake count, as an inequality: twice the number of unit pairs is at most the sum of
the degrees. -/
lemma two_mul_card_unitPairs_le_sum_degree (P : Finset Plane) :
    2 * (unitPairs P).card ≤ ∑ v ∈ P, (unitNeighbours P v).card := by
  classical
  have h1 : 2 * (unitPairs P).card =
      ∑ s ∈ unitPairs P, (P.bipartiteBelow (fun v s => v ∈ s) s).card := by
    rw [mul_comm, ← smul_eq_mul, ← Finset.sum_const]
    apply Finset.sum_congr rfl
    intro s hs
    simp only [unitPairs, Finset.mem_filter, Finset.mem_powersetCard] at hs
    simp only [Finset.bipartiteBelow, Finset.filter_mem_eq_inter, Finset.inter_eq_right.mpr hs.1.1,
      hs.1.2]
  rw [h1, ← Finset.sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow]
  exact Finset.sum_le_sum (fun v _ => card_unitPairs_through_le P v)

/-- The nine points of the two-triangle picture: `t i + r j`, where `t` is a unit equilateral
triangle and `r` is the same triangle turned a quarter turn. -/
noncomputable def twoTriangles (x : Fin 3 × Fin 3) : Plane :=
  !₂[![0, 1, 1 / 2] x.1 + ![0, 0, -(Real.sqrt 3 / 2)] x.2,
     ![0, 0, Real.sqrt 3 / 2] x.1 + ![0, 1, 1 / 2] x.2]

/-- The squared distances in the two-triangle picture: 0 for a point and itself, 1 for two points
sharing a triangle, and 2 or 2 ± sqrt 3 otherwise. -/
lemma twoTriangles_sq_dist (x y : Fin 3 × Fin 3) :
    (x = y → (dist (twoTriangles x) (twoTriangles y)) ^ 2 = 0) ∧
    (x ≠ y ∧ (x.1 = y.1 ∨ x.2 = y.2) → (dist (twoTriangles x) (twoTriangles y)) ^ 2 = 1) ∧
    (x.1 ≠ y.1 ∧ x.2 ≠ y.2 → (dist (twoTriangles x) (twoTriangles y)) ^ 2 = 2 ∨
      (dist (twoTriangles x) (twoTriangles y)) ^ 2 = 2 + Real.sqrt 3 ∨
      (dist (twoTriangles x) (twoTriangles y)) ^ 2 = 2 - Real.sqrt 3) := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  rw [EuclideanSpace.dist_eq, Real.sq_sqrt (Finset.sum_nonneg (fun _ _ => sq_nonneg _))]
  simp only [twoTriangles, Fin.sum_univ_two, Real.dist_eq, sq_abs]
  obtain ⟨a, b⟩ := x
  obtain ⟨c, d⟩ := y
  fin_cases a <;> fin_cases b <;> fin_cases c <;> fin_cases d <;>
    simp <;> ring_nf <;> simp [h3] <;> ring_nf <;> norm_num

/-- In the two-triangle picture, two points are at distance 1 exactly when they are different
and share a triangle. -/
lemma twoTriangles_dist_eq_one_iff (x y : Fin 3 × Fin 3) :
    dist (twoTriangles x) (twoTriangles y) = 1 ↔ x ≠ y ∧ (x.1 = y.1 ∨ x.2 = y.2) := by
  obtain ⟨h0, h1, h2⟩ := twoTriangles_sq_dist x y
  have hs1 : 1 < Real.sqrt 3 := by
    rw [show (1 : ℝ) = Real.sqrt 1 by simp]
    exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
  have hd := dist_nonneg (x := twoTriangles x) (y := twoTriangles y)
  constructor
  · intro h
    by_cases hxy : x = y
    · have := h0 hxy; rw [h] at this; norm_num at this
    · refine ⟨hxy, ?_⟩
      by_contra hc
      push Not at hc
      rcases h2 hc with h' | h' | h' <;> rw [h] at h' <;> nlinarith
  · intro h
    have := h1 h
    nlinarith

/-- The nine points of the two-triangle picture are distinct. -/
lemma twoTriangles_injective : Function.Injective twoTriangles := by
  intro x y hxy
  by_contra hne
  obtain ⟨_, h1, h2⟩ := twoTriangles_sq_dist x y
  have hs1 : Real.sqrt 3 < 2 := by
    rw [show (2 : ℝ) = Real.sqrt 4 by
      rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]]
    exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
  rw [hxy, dist_self] at h1 h2
  by_cases hc : x.1 = y.1 ∨ x.2 = y.2
  · exact absurd (h1 ⟨hne, hc⟩) (by norm_num)
  · push Not at hc
    have hs0 := Real.sqrt_nonneg 3
    rcases h2 hc with h' | h' | h' <;> nlinarith

/-- The rook's pairs of the 3 by 3 board: 18 pairs of squares share a row or a column. -/
lemma card_rook_pairs :
    ((Finset.univ.powersetCard 2).filter (fun s : Finset (Fin 3 × Fin 3) =>
      ∀ a ∈ s, ∀ b ∈ s, a ≠ b → (a.1 = b.1 ∨ a.2 = b.2))).card = 18 := by
  decide

/-- The counting bound (Erdős 1946): any n distinct points in the plane have at most
n(1 + sqrt(8n − 7))/4 pairs at distance exactly 1, so u(n) ≤ n(1 + sqrt(8n − 7))/4. -/
theorem unit_pairs_le_counting_bound (P : Finset Plane) :
    ((unitPairs P).card : ℝ) ≤ (P.card : ℝ) * (1 + Real.sqrt (8 * (P.card : ℝ) - 7)) / 4 := by
  classical
  rcases Nat.eq_zero_or_pos P.card with h0 | hpos
  · have hP : P = ∅ := Finset.card_eq_zero.mp h0
    subst hP
    simp [unitPairs]
  set n : ℝ := (P.card : ℝ) with hn
  set D : ℝ := ∑ v ∈ P, ((unitNeighbours P v).card : ℝ) with hD
  set Q : ℝ := ∑ v ∈ P, ((unitNeighbours P v).card : ℝ) ^ 2 with hQ
  set u : ℝ := ((unitPairs P).card : ℝ) with hu
  -- the cherry count, over the reals: Q − D ≤ 2 n (n − 1)
  have hcherry : Q - D ≤ 2 * n * (n - 1) := by
    have h := sum_choose_degree_le P
    have h' : ((∑ v ∈ P, (unitNeighbours P v).card.choose 2 : ℕ) : ℝ) ≤
        ((2 * P.card.choose 2 : ℕ) : ℝ) := by exact_mod_cast h
    push_cast [Nat.cast_choose_two] at h'
    have hs : ∑ v ∈ P, ((unitNeighbours P v).card : ℝ) * (((unitNeighbours P v).card : ℝ) - 1) / 2
        = (Q - D) / 2 := by
      rw [hQ, hD, ← Finset.sum_sub_distrib, Finset.sum_div]
      apply Finset.sum_congr rfl
      intro v _
      ring
    rw [hs] at h'
    linarith
  -- the handshake count: 2u ≤ D
  have hhand : 2 * u ≤ D := by
    have h := two_mul_card_unitPairs_le_sum_degree P
    rw [hu, hD]
    exact_mod_cast h
  -- Cauchy–Schwarz: D² ≤ n Q
  have hcs : D ^ 2 ≤ n * Q := sq_sum_le_card_mul_sum_sq
  have hu0 : 0 ≤ u := Nat.cast_nonneg _
  · have hn1 : (1 : ℝ) ≤ n := by rw [hn]; exact_mod_cast hpos
    set r : ℝ := Real.sqrt (8 * n - 7) with hr
    have hr2 : r ^ 2 = 8 * n - 7 := Real.sq_sqrt (by linarith)
    have hr0 : 0 ≤ r := Real.sqrt_nonneg _
    have hquad : D ^ 2 - n * D - 2 * n ^ 2 * (n - 1) ≤ 0 := by nlinarith
    have hDle : D ≤ n * (1 + r) / 2 := by
      by_contra hc
      push Not at hc
      have hpos1 : 0 < D - n * (1 + r) / 2 := by linarith
      have hpos2 : 0 < D - n * (1 - r) / 2 := by nlinarith
      have hprod := mul_pos hpos1 hpos2
      have hexp : (D - n * (1 + r) / 2) * (D - n * (1 - r) / 2) =
          D ^ 2 - n * D - 2 * n ^ 2 * (n - 1) := by
        have : (D - n * (1 + r) / 2) * (D - n * (1 - r) / 2) =
            D ^ 2 - n * D + n ^ 2 * (1 - r ^ 2) / 4 := by ring
        rw [this, hr2]
        ring
      linarith
    linarith

/-- The cherry count: for n distinct points in the plane, summing C(d(v), 2) over every point v
gives at most 2 · C(n, 2), because two points share at most 2 unit neighbours. -/
theorem sum_choose_degree_le_two_mul_choose (P : Finset Plane) :
    ∑ v ∈ P, (unitNeighbours P v).card.choose 2 ≤ 2 * P.card.choose 2 := by
  exact sum_choose_degree_le P

/-- Two triangles summed: some nine distinct points in the plane have exactly 18 pairs at
distance exactly 1 (so u(9) ≥ 18). -/
theorem exists_nine_points_eighteen_unit_pairs :
    ∃ P : Finset Plane, P.card = 9 ∧ (unitPairs P).card = 18 := by
  refine ⟨Finset.univ.map ⟨twoTriangles, twoTriangles_injective⟩, by simp, ?_⟩
  unfold unitPairs
  rw [Finset.powersetCard_map, Finset.filter_map, Finset.card_map, ← card_rook_pairs]
  congr 1
  apply Finset.filter_congr
  intro s _
  simp only [Function.comp_apply, RelEmbedding.coe_toEmbedding, Finset.mapEmbedding_apply,
    Finset.mem_map,
    Function.Embedding.coeFn_mk, forall_exists_index, and_imp, forall_apply_eq_imp_iff₂,
    twoTriangles_injective.ne_iff, twoTriangles_dist_eq_one_iff]
  constructor
  · intro h a ha b hb hab
    exact (h a ha b hb hab).2
  · intro h a ha b hb hab
    exact ⟨hab, h a ha b hb hab⟩

/-- The 3 by 3 square grid: 12 unit pairs among its 9 points (squared distance 1). -/
example :
    ((((Finset.Icc (0 : ℤ) 2) ×ˢ (Finset.Icc (0 : ℤ) 2)).powersetCard 2).filter
      (fun s => ∀ p ∈ s, ∀ q ∈ s, p ≠ q → (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2 = 1)).card = 12 := by
  decide

/-- Erdős's distance on a grid too small for it: no pair of the 3 by 3 grid is at squared
distance 65. -/
example :
    ((((Finset.Icc (0 : ℤ) 2) ×ˢ (Finset.Icc (0 : ℤ) 2)).powersetCard 2).filter
      (fun s => ∀ p ∈ s, ∀ q ∈ s, p ≠ q → (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2 = 65)).card = 0 := by
  decide

/-- The nine points of the picture all have degree 4: 9 · C(4, 2) = 54 cherries,
at most 2 · C(9, 2) = 72. -/
example : 9 * Nat.choose 4 2 = 54 ∧ 2 * Nat.choose 9 2 = 72 ∧ 54 ≤ 72 := by decide

/-- The counting bound at n = 9 allows 20 unit pairs but not 21: with u = 20,
4u − n = 71 and 71² ≤ 9² · 65; with u = 21, 4u − n = 75 and 75² > 9² · 65. -/
example : (4 * 20 - 9) ^ 2 ≤ 9 ^ 2 * (8 * 9 - 7) ∧ 9 ^ 2 * (8 * 9 - 7) < (4 * 21 - 9) ^ 2 := by
  norm_num

/-- The lattice pattern floor(3n − sqrt(12n − 3)) gives 16 at n = 9: 12 · 9 − 3 = 105 lies
strictly between 10² and 11², so its square root has whole part 10 and floor(27 − sqrt 105) = 16,
against u(9) = 18. -/
example : 12 * 9 - 3 = 105 ∧ 10 ^ 2 < 105 ∧ 105 < 11 ^ 2 ∧ 3 * 9 - 10 - 1 = 16 ∧ 16 < 18 := by
  decide

/-- Four dimensions, scaled by 10: five points on each of two circles of squared radius 50 in
perpendicular planes; all 5 × 5 = 25 pairs across the circles are at squared distance 100,
more than the plane's u(10) = 20. -/
example :
    (((({(1, 7), (5, 5), (7, 1), (7, -1), (5, -5)} : Finset (ℤ × ℤ)) ×ˢ
      ({(1, 7), (5, 5), (7, 1), (7, -1), (5, -5)} : Finset (ℤ × ℤ))).filter
      (fun x => x.1.1 ^ 2 + x.1.2 ^ 2 + x.2.1 ^ 2 + x.2.2 ^ 2 = 100)).card = 25) ∧ 20 < 25 := by
  decide

#print axioms card_common_unit_neighbours_le_two
#print axioms sum_choose_degree_le
#print axioms card_unitPairs_through_le
#print axioms two_mul_card_unitPairs_le_sum_degree
#print axioms twoTriangles_sq_dist
#print axioms twoTriangles_dist_eq_one_iff
#print axioms twoTriangles_injective
#print axioms card_rook_pairs
#print axioms unit_pairs_le_counting_bound
#print axioms sum_choose_degree_le_two_mul_choose
#print axioms exists_nine_points_eighteen_unit_pairs
