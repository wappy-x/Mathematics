-- Triangulating a polygon: the card's 12-corner comb is a simple polygon that needs 4 guards, wherever they stand, plus the card's worked numbers. The general n/3 guard bound and the n - 2 triangle count are not proved here.
import Mathlib.Analysis.Convex.Hull
import Mathlib.Analysis.Convex.Segment
import Mathlib.Topology.Algebra.Module.Basic
import Mathlib.Topology.Bornology.Basic
import Mathlib.Topology.Connected.Basic
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Algebra.CharP.Invertible
import Mathlib.Basic.Real.Basic
import Mathlib.Analysis.Normed.Group.Bounded
import Mathlib.Analysis.Normed.Group.Constructions
import Mathlib.Analysis.Normed.Group.Real
import Mathlib.Analysis.Convex.PathConnected

noncomputable section

namespace ArtGallery

/-! A polygon with `n` corners is a map `P : Fin n → ℝ × ℝ`, corner `i` followed by corner
`i + 1` (wrapping from the last corner to the first). The definitions of fence, boundary,
simple polygon, inside and anticlockwise walk are those of the Shoelace card. -/

/-- The cross product of two arrows in the plane. -/
def cross (u v : ℝ × ℝ) : ℝ := u.1 * v.2 - u.2 * v.1

/-- The turn test: positive for a left turn walking `a → b → c`, negative for a right turn. -/
def turn (a b c : ℝ × ℝ) : ℝ := cross (b - a) (c - a)

/-- The shoelace sum: half the sum of each corner crossed with the next. -/
def shoelace {n : ℕ} [NeZero n] (P : Fin n → ℝ × ℝ) : ℝ :=
  (1 / 2) * ∑ i, cross (P i) (P (i + 1))

/-- Fence `i`: the straight wall from corner `i` to the next corner. -/
def fence {n : ℕ} [NeZero n] (P : Fin n → ℝ × ℝ) (i : Fin n) : Set (ℝ × ℝ) :=
  segment ℝ (P i) (P (i + 1))

/-- The boundary: all the fences together. -/
def boundary {n : ℕ} [NeZero n] (P : Fin n → ℝ × ℝ) : Set (ℝ × ℝ) := ⋃ i, fence P i

/-- A simple polygon: at least three corners, all different, and one loop that never crosses
itself (so it has no holes). Neighbouring fences meet only at their shared corner; all other
pairs of fences never meet. -/
def IsSimple {n : ℕ} [NeZero n] (P : Fin n → ℝ × ℝ) : Prop :=
  3 ≤ n ∧ Function.Injective P ∧
    ∀ i j : Fin n, i ≠ j →
      fence P i ∩ fence P j =
        if j = i + 1 then {P j} else if i = j + 1 then {P i} else ∅

/-- The inside: points off the boundary whose piece of the plane, with the boundary removed,
is bounded. -/
def inside {n : ℕ} [NeZero n] (P : Fin n → ℝ × ℝ) : Set (ℝ × ℝ) :=
  {p | p ∉ boundary P ∧ Bornology.IsBounded (connectedComponentIn (boundary P)ᶜ p)}

/-- The gallery: the inside together with its walls. -/
def gallery {n : ℕ} [NeZero n] (P : Fin n → ℝ × ℝ) : Set (ℝ × ℝ) := inside P ∪ boundary P

/-- A guard at `g` sees the point `p` when the straight line of sight from `g` to `p` stays in
the gallery: walls block sight, and a guard sees all the way round. -/
def Sees {n : ℕ} [NeZero n] (P : Fin n → ℝ × ℝ) (g p : ℝ × ℝ) : Prop :=
  segment ℝ g p ⊆ gallery P

/-- The comb from Step 5, in metres: a 14 m spine 1 m deep with four prongs 7 m tall. -/
def comb : Fin 12 → ℝ × ℝ :=
  ![(0, 0), (14, 0), (13, 7), (12, 1), (10, 1), (9, 7), (8, 1), (6, 1),
    (5, 7), (4, 1), (2, 1), (1, 7)]

/-- A point of a segment, written with one parameter. -/
lemma seg_coords {a b p : ℝ × ℝ} (hp : p ∈ segment ℝ a b) :
    ∃ s : ℝ, 0 ≤ s ∧ s ≤ 1 ∧ p.1 = (1 - s) * a.1 + s * b.1 ∧ p.2 = (1 - s) * a.2 + s * b.2 := by
  obtain ⟨u, v, hu, hv, huv, rfl⟩ := hp
  obtain rfl : u = 1 - v := by linarith
  exact ⟨v, hv, by linarith, by simp, by simp⟩

/-- An open half-plane is convex. -/
lemma convex_lin (α β c : ℝ) : Convex ℝ {p : ℝ × ℝ | α * p.1 + β * p.2 < c} := by
  intro x hx y hy a b ha hb hab
  simp only [Set.mem_ofPred_eq, Prod.fst_add, Prod.snd_add, Prod.smul_fst, Prod.smul_snd,
    smul_eq_mul] at hx hy ⊢
  have e : α * (a * x.1 + b * y.1) + β * (a * x.2 + b * y.2)
      = a * (α * x.1 + β * x.2) + b * (α * y.1 + β * y.2) := by ring
  rw [e]
  have ec : a * c + b * c = c := by rw [← add_mul, hab, one_mul]
  rcases ha.lt_or_eq with ha0 | ha0
  · nlinarith [mul_lt_mul_of_pos_left hx ha0, mul_le_mul_of_nonneg_left hy.le hb]
  · have hb0 : 0 < b := by linarith
    nlinarith [mul_lt_mul_of_pos_left hy hb0, mul_le_mul_of_nonneg_left hx.le ha]

/-- A set that reaches arbitrarily far out is not bounded. -/
lemma not_bounded_of {R : Set (ℝ × ℝ)} (h : ∀ r : ℝ, 0 ≤ r → ∃ p ∈ R, r < ‖p‖) :
    ¬ Bornology.IsBounded R := by
  intro hb
  obtain ⟨C, hC⟩ := isBounded_iff_forall_norm_le.1 hb
  obtain ⟨p, hp, hr⟩ := h |C| (abs_nonneg C)
  linarith [hC p hp, le_abs_self C]

/-- A convex, unbounded set that misses the comb's walls lies outside the comb's gallery. -/
lemma not_mem_gallery {R : Set (ℝ × ℝ)} (hc : Convex ℝ R) (hd : ∀ p ∈ boundary comb, p ∉ R)
    (hu : ¬ Bornology.IsBounded R) {q : ℝ × ℝ} (hq : q ∈ R) : q ∉ gallery comb := by
  rintro (h | h)
  · exact hu (h.2.subset
      (hc.isPreconnected.subset_connectedComponentIn hq (fun p hp hpb => hd p hpb hp)))
  · exact hd q h hq

/-- Below the spine is outside the comb. -/
lemma below_out {q : ℝ × ℝ} (hq : q.2 < 0) : q ∉ gallery comb := by
  refine not_mem_gallery (R := {p | 0 * p.1 + 1 * p.2 < 0}) (convex_lin _ _ _) ?_ ?_
    (by simpa using hq)
  · intro p hp
    obtain ⟨i, hi⟩ := Set.mem_iUnion.1 hp
    obtain ⟨s, hs0, hs1, e1, e2⟩ := seg_coords hi
    simp only [Set.mem_ofPred_eq]
    intro k
    fin_cases i <;> simp [comb] at e1 e2 <;> linarith
  · refine not_bounded_of fun r _ => ⟨(0, -(r + 1)), by simp; linarith, ?_⟩
    have h := norm_snd_le ((0 : ℝ), -(r + 1))
    simp only [Real.norm_eq_abs] at h
    linarith [neg_abs_le (-(r + 1))]

/-- The gap between two neighbouring prongs, open upwards, is outside the comb. -/
lemma gap_out (a b : ℝ) (hab : (a = 71 ∧ b = 61) ∨ (a = 47 ∧ b = 37) ∨ (a = 23 ∧ b = 13))
    {q : ℝ × ℝ} (h1 : 6 * q.1 - q.2 < a) (h2 : b < 6 * q.1 + q.2) (h3 : 1 < q.2) :
    q ∉ gallery comb := by
  refine not_mem_gallery (R := {p | 6 * p.1 + (-1) * p.2 < a} ∩ {p | (-6) * p.1 + (-1) * p.2 < -b}
    ∩ {p | 0 * p.1 + (-1) * p.2 < -1})
    (((convex_lin _ _ _).inter (convex_lin _ _ _)).inter (convex_lin _ _ _)) ?_ ?_
    ⟨⟨by simp; linarith, by simp; linarith⟩, by simp; linarith⟩
  · intro p hp
    obtain ⟨i, hi⟩ := Set.mem_iUnion.1 hp
    obtain ⟨s, hs0, hs1, e1, e2⟩ := seg_coords hi
    simp only [Set.mem_inter_iff, Set.mem_ofPred_eq]
    rintro ⟨⟨k1, k2⟩, k3⟩
    rcases hab with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;>
      fin_cases i <;> simp [comb] at e1 e2 <;> linarith
  · refine not_bounded_of fun r hr => ⟨((a + b) / 12, r + 2), ⟨⟨?_, ?_⟩, ?_⟩, ?_⟩
    · simp; rcases hab with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;> linarith
    · simp; rcases hab with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;> linarith
    · simp; linarith
    · have h := norm_snd_le ((a + b) / 12, r + 2)
      simp only [Real.norm_eq_abs] at h
      linarith [le_abs_self (r + 2)]

/-- A point a little way from `A` towards `g`, on the segment between them. -/
lemma near_point (g A : ℝ × ℝ) : ∃ t u v : ℝ, 0 < t ∧ u = t * (g.1 - A.1) ∧ v = t * (g.2 - A.2) ∧
    |u| ≤ 1 ∧ |v| ≤ 1 ∧ (A.1 + u, A.2 + v) ∈ segment ℝ g A := by
  set D := 1 + |g.1 - A.1| + |g.2 - A.2| with hD
  have hD0 : 0 < D := by positivity
  refine ⟨1 / D, _, _, by positivity, rfl, rfl, ?_, ?_, ?_⟩
  · rw [abs_mul, abs_of_pos (by positivity : (0:ℝ) < 1 / D), one_div_mul_eq_div,
      div_le_one hD0]
    linarith [abs_nonneg (g.2 - A.2)]
  · rw [abs_mul, abs_of_pos (by positivity : (0:ℝ) < 1 / D), one_div_mul_eq_div,
      div_le_one hD0]
    linarith [abs_nonneg (g.1 - A.1)]
  · have ht1 : 1 / D ≤ 1 := by rw [div_le_one hD0]; linarith [abs_nonneg (g.1 - A.1), abs_nonneg (g.2 - A.2)]
    refine ⟨1 / D, 1 - 1 / D, by positivity, by linarith, by ring, ?_⟩
    ext <;> simp <;> ring

/-- The comb is a simple polygon. -/
lemma comb_simple : IsSimple comb := by
  refine ⟨by norm_num, ?_, ?_⟩
  · intro i j h
    fin_cases i <;> fin_cases j <;> simp [comb] at h ⊢
  · intro i j hij
    fin_cases i <;> fin_cases j <;>
      first
      | exact absurd rfl hij
      | (rw [ite_eq_left (by decide)]
         ext p
         constructor
         · rintro ⟨h1, h2⟩
           obtain ⟨s, hs0, hs1, e1, e2⟩ := seg_coords h1
           obtain ⟨t, ht0, ht1, e3, e4⟩ := seg_coords h2
           simp [comb] at e1 e2 e3 e4 ⊢
           refine Prod.ext ?_ ?_ <;> simp <;> linarith
         · intro hp
           rw [Set.mem_singleton_iff] at hp
           subst hp
           exact ⟨right_mem_segment _ _ _, left_mem_segment _ _ _⟩)
      | (rw [ite_eq_right (by decide), ite_eq_left (by decide)]
         ext p
         constructor
         · rintro ⟨h1, h2⟩
           obtain ⟨s, hs0, hs1, e1, e2⟩ := seg_coords h1
           obtain ⟨t, ht0, ht1, e3, e4⟩ := seg_coords h2
           simp [comb] at e1 e2 e3 e4 ⊢
           refine Prod.ext ?_ ?_ <;> simp <;> linarith
         · intro hp
           rw [Set.mem_singleton_iff] at hp
           subst hp
           exact ⟨left_mem_segment _ _ _, right_mem_segment _ _ _⟩)
      | (rw [ite_eq_right (by decide), ite_eq_right (by decide)]
         ext p
         simp only [Set.mem_inter_iff, Set.mem_empty_iff_false, iff_false, not_and]
         intro h1 h2
         obtain ⟨s, hs0, hs1, e1, e2⟩ := seg_coords h1
         obtain ⟨t, ht0, ht1, e3, e4⟩ := seg_coords h2
         simp [comb] at e1 e2 e3 e4
         linarith)

/-- A guard who sees the tip of the first prong stands in that prong's wedge. -/
lemma sees_tip2 {g : ℝ × ℝ} (h : Sees comb g (comb 2)) : 71 ≤ 6 * g.1 - g.2 ∧ 0 ≤ g.2 := by
  have hA : comb 2 = (13, 7) := by simp [comb]
  have hg : g ∈ gallery comb := h (left_mem_segment _ _ _)
  refine ⟨?_, ?_⟩
  · by_contra hlt
    obtain ⟨t, u, v, ht, hu, hv, hu1, hv1, hs⟩ := near_point g (comb 2)
    rw [hA] at hu hv hs
    have k : 6 * u - v = t * (6 * g.1 - g.2 - 71) := by rw [hu, hv]; ring
    have k' := mul_neg_of_pos_of_neg ht (by linarith : 6 * g.1 - g.2 - 71 < 0)
    rw [abs_le] at hu1 hv1
    exact gap_out 71 61 (Or.inl ⟨rfl, rfl⟩) (q := ((13 : ℝ) + u, (7 : ℝ) + v))
      (by simp; linarith) (by simp; linarith) (by simp; linarith) (h hs)
  · by_contra hlt
    exact below_out (by linarith) hg

/-- A guard who sees the tip of the second prong stands in that prong's wedge. -/
lemma sees_tip5 {g : ℝ × ℝ} (h : Sees comb g (comb 5)) :
    47 ≤ 6 * g.1 - g.2 ∧ 6 * g.1 + g.2 ≤ 61 ∧ 0 ≤ g.2 := by
  have hA : comb 5 = (9, 7) := by simp [comb]
  have hg : g ∈ gallery comb := h (left_mem_segment _ _ _)
  obtain ⟨t, u, v, ht, hu, hv, hu1, hv1, hs⟩ := near_point g (comb 5)
  rw [hA] at hu hv hs
  rw [abs_le] at hu1 hv1
  refine ⟨?_, ?_, ?_⟩
  · by_contra hlt
    have k : 6 * u - v = t * (6 * g.1 - g.2 - 47) := by rw [hu, hv]; ring
    have k' := mul_neg_of_pos_of_neg ht (by linarith : 6 * g.1 - g.2 - 47 < 0)
    exact gap_out 47 37 (Or.inr (Or.inl ⟨rfl, rfl⟩)) (q := ((9 : ℝ) + u, (7 : ℝ) + v))
      (by simp; linarith) (by simp; linarith) (by simp; linarith) (h hs)
  · by_contra hlt
    have k : 6 * u + v = t * (6 * g.1 + g.2 - 61) := by rw [hu, hv]; ring
    have k' := mul_pos ht (by linarith : 0 < 6 * g.1 + g.2 - 61)
    exact gap_out 71 61 (Or.inl ⟨rfl, rfl⟩) (q := ((9 : ℝ) + u, (7 : ℝ) + v))
      (by simp; linarith) (by simp; linarith) (by simp; linarith) (h hs)
  · by_contra hlt
    exact below_out (by linarith) hg

/-- A guard who sees the tip of the third prong stands in that prong's wedge. -/
lemma sees_tip8 {g : ℝ × ℝ} (h : Sees comb g (comb 8)) :
    23 ≤ 6 * g.1 - g.2 ∧ 6 * g.1 + g.2 ≤ 37 ∧ 0 ≤ g.2 := by
  have hA : comb 8 = (5, 7) := by simp [comb]
  have hg : g ∈ gallery comb := h (left_mem_segment _ _ _)
  obtain ⟨t, u, v, ht, hu, hv, hu1, hv1, hs⟩ := near_point g (comb 8)
  rw [hA] at hu hv hs
  rw [abs_le] at hu1 hv1
  refine ⟨?_, ?_, ?_⟩
  · by_contra hlt
    have k : 6 * u - v = t * (6 * g.1 - g.2 - 23) := by rw [hu, hv]; ring
    have k' := mul_neg_of_pos_of_neg ht (by linarith : 6 * g.1 - g.2 - 23 < 0)
    exact gap_out 23 13 (Or.inr (Or.inr ⟨rfl, rfl⟩)) (q := ((5 : ℝ) + u, (7 : ℝ) + v))
      (by simp; linarith) (by simp; linarith) (by simp; linarith) (h hs)
  · by_contra hlt
    have k : 6 * u + v = t * (6 * g.1 + g.2 - 37) := by rw [hu, hv]; ring
    have k' := mul_pos ht (by linarith : 0 < 6 * g.1 + g.2 - 37)
    exact gap_out 47 37 (Or.inr (Or.inl ⟨rfl, rfl⟩)) (q := ((5 : ℝ) + u, (7 : ℝ) + v))
      (by simp; linarith) (by simp; linarith) (by simp; linarith) (h hs)
  · by_contra hlt
    exact below_out (by linarith) hg

/-- A guard who sees the tip of the fourth prong stands in that prong's wedge. -/
lemma sees_tip11 {g : ℝ × ℝ} (h : Sees comb g (comb 11)) : 6 * g.1 + g.2 ≤ 13 ∧ 0 ≤ g.2 := by
  have hA : comb 11 = (1, 7) := by simp [comb]
  have hg : g ∈ gallery comb := h (left_mem_segment _ _ _)
  refine ⟨?_, ?_⟩
  · by_contra hlt
    obtain ⟨t, u, v, ht, hu, hv, hu1, hv1, hs⟩ := near_point g (comb 11)
    rw [hA] at hu hv hs
    rw [abs_le] at hu1 hv1
    have k : 6 * u + v = t * (6 * g.1 + g.2 - 13) := by rw [hu, hv]; ring
    have k' := mul_pos ht (by linarith : 0 < 6 * g.1 + g.2 - 13)
    exact gap_out 23 13 (Or.inr (Or.inr ⟨rfl, rfl⟩)) (q := ((1 : ℝ) + u, (7 : ℝ) + v))
      (by simp; linarith) (by simp; linarith) (by simp; linarith) (h hs)
  · by_contra hlt
    exact below_out (by linarith) hg


/-- The ceiling cannot be lowered. The 12-corner comb is a simple polygon, and any set of
guards, standing anywhere, that sees every point of it has at least 12 / 3 = 4 guards. -/
theorem comb_needs_four_guards :
    IsSimple comb ∧
      ∀ G : Finset (ℝ × ℝ), (∀ p ∈ gallery comb, ∃ g ∈ G, Sees comb g p) → 12 / 3 ≤ G.card := by
  refine ⟨comb_simple, fun G hG => ?_⟩
  have m : ∀ k, comb k ∈ gallery comb :=
    fun k => Or.inr (Set.mem_iUnion.2 ⟨k, left_mem_segment _ _ _⟩)
  obtain ⟨g1, h1G, h1⟩ := hG _ (m 2)
  obtain ⟨g2, h2G, h2⟩ := hG _ (m 5)
  obtain ⟨g3, h3G, h3⟩ := hG _ (m 8)
  obtain ⟨g4, h4G, h4⟩ := hG _ (m 11)
  have a1 := sees_tip2 h1
  have a2 := sees_tip5 h2
  have a3 := sees_tip8 h3
  have a4 := sees_tip11 h4
  have hsub : ({g1, g2, g3, g4} : Finset (ℝ × ℝ)) ⊆ G := by
    intro x hx
    simp only [Finset.mem_insert, Finset.mem_singleton] at hx
    rcases hx with rfl | rfl | rfl | rfl <;> assumption
  have hcard : ({g1, g2, g3, g4} : Finset (ℝ × ℝ)).card = 4 := by
    rw [Finset.card_insert_of_notMem, Finset.card_insert_of_notMem, Finset.card_pair]
    · rintro rfl; linarith
    · simp only [Finset.mem_insert, Finset.mem_singleton]
      rintro (rfl | rfl) <;> linarith
    · simp only [Finset.mem_insert, Finset.mem_singleton]
      rintro (rfl | rfl | rfl) <;> linarith
  calc 12 / 3 = 4 := by norm_num
    _ = _ := hcard.symm
    _ ≤ G.card := Finset.card_le_card hsub

/-! The card's worked numbers. Corners A to F of the survey field are `0` to `5`. -/

/-- The survey field, in hundreds of metres. -/
def field : Fin 6 → ℝ × ℝ := ![(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)]

-- D is reflex: turn(C, D, E) = −20.
example : turn (field 2) (field 3) (field 4) = -20 := by
  norm_num [turn, cross, field]

-- The four clipped triangles FAB, BCD, FBD, DEF turn left, with doubled areas 40, 18, 9, 16,
-- adding to twice the field's 41.5 hectares.
example : turn (field 5) (field 0) (field 1) = 40 ∧ turn (field 1) (field 2) (field 3) = 18 ∧
    turn (field 5) (field 1) (field 3) = 9 ∧ turn (field 3) (field 4) (field 5) = 16 := by
  norm_num [turn, cross, field]

example : shoelace field = 83 / 2 := by
  norm_num [shoelace, cross, field, Fin.sum_univ_succ]

-- 4 = 6 − 2 triangles; colours D 1, E 2, F 3, B 2, C 3, A 1 give one of each per triangle,
-- and the rarest colour has 2 = 6 / 3 corners.
example : let col : Fin 6 → ℕ := ![1, 2, 3, 1, 2, 3]
    let T : List (Fin 6 × Fin 6 × Fin 6) := [(5, 0, 1), (1, 2, 3), (5, 1, 3), (3, 4, 5)]
    T.length = 6 - 2 ∧ (∀ t ∈ T, col t.1 ≠ col t.2.1 ∧ col t.2.1 ≠ col t.2.2 ∧ col t.1 ≠ col t.2.2) ∧
      (Finset.univ.filter (fun v => col v = 1)).card = 6 / 3 := by
  decide +kernel

-- The comb: 10 = 12 − 2 triangles, colours acfi, behk, dgjl, one of each per triangle,
-- rarest colour 4 = 12 / 3.
example : let col : Fin 12 → ℕ := ![1, 2, 1, 3, 2, 1, 3, 2, 1, 3, 2, 3]
    let T : List (Fin 12 × Fin 12 × Fin 12) :=
      [(1, 2, 3), (0, 1, 3), (0, 3, 4), (4, 5, 6), (0, 4, 6), (0, 6, 7), (7, 8, 9), (0, 7, 9),
        (0, 9, 10), (0, 10, 11)]
    T.length = 12 - 2 ∧ (∀ t ∈ T, col t.1 ≠ col t.2.1 ∧ col t.2.1 ≠ col t.2.2 ∧ col t.1 ≠ col t.2.2) ∧
      (Finset.univ.filter (fun v => col v = 1)).card = 12 / 3 := by
  decide +kernel

#print axioms seg_coords
#print axioms convex_lin
#print axioms not_bounded_of
#print axioms not_mem_gallery
#print axioms below_out
#print axioms gap_out
#print axioms near_point
#print axioms comb_simple
#print axioms sees_tip2
#print axioms sees_tip5
#print axioms sees_tip8
#print axioms sees_tip11
#print axioms comb_needs_four_guards

end ArtGallery

end
