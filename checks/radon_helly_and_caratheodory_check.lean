-- Radon, Helly and Carathéodory: in the plane, any 4 points split into two groups whose hulls meet, finitely many convex sets that meet three at a time all meet, and any point of a hull is a mix of 3 of the points.
import Mathlib.Analysis.Convex.Radon
import Mathlib.Analysis.Convex.Combination
import Mathlib.Data.Real.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Convex.Caratheodory
import Mathlib.Analysis.Convex.Join
import Mathlib.Tactic

open Set

lemma finrank_plane : Module.finrank ℝ (ℝ × ℝ) = 2 := by
  simp [Module.finrank_prod]

lemma affInd_card_le_three {ι : Type*} [Fintype ι] {p : ι → ℝ × ℝ}
    (h : AffineIndependent ℝ p) : Fintype.card ι ≤ 3 := by
  have h1 := h.card_le_finrank_succ
  have h2 := Submodule.finrank_le (vectorSpan ℝ (range p))
  rw [finrank_plane] at h2
  omega

lemma mem_hull_triple {a b c x : ℝ × ℝ} (hx : x ∈ convexHull ℝ ({a, b, c} : Set (ℝ × ℝ))) :
    ∃ wa wb wc : ℝ, 0 ≤ wa ∧ 0 ≤ wb ∧ 0 ≤ wc ∧
      wa + wb + wc = 1 ∧ x = wa • a + wb • b + wc • c := by
  rw [convexHull_insert (insert_nonempty b {c}), convexHull_pair, mem_convexJoin] at hx
  obtain ⟨a', ha', y, ⟨γ, δ, hγ, hδ, hγδ, rfl⟩, α, β, hα, hβ, hαβ, rfl⟩ := hx
  rw [mem_singleton_iff] at ha'
  subst ha'
  refine ⟨α, β * γ, β * δ, hα, mul_nonneg hβ hγ, mul_nonneg hβ hδ, ?_, ?_⟩
  · linear_combination hαβ + β * hγδ
  · simp only [smul_add, mul_smul]; abel

lemma finset_le_three {t : Finset (ℝ × ℝ)} (hne : t.Nonempty) (h : t.card ≤ 3) :
    ∃ a ∈ t, ∃ b ∈ t, ∃ c ∈ t, (t : Set (ℝ × ℝ)) = {a, b, c} := by
  have h1 : 0 < t.card := hne.card_pos
  interval_cases hc : t.card
  · obtain ⟨a, rfl⟩ := Finset.card_eq_one.mp hc
    exact ⟨a, by simp, a, by simp, a, by simp, by simp⟩
  · obtain ⟨a, b, -, rfl⟩ := Finset.card_eq_two.mp hc
    exact ⟨a, by simp, b, by simp, b, by simp, by simp⟩
  · obtain ⟨a, b, c, -, -, -, rfl⟩ := Finset.card_eq_three.mp hc
    exact ⟨a, by simp, b, by simp, c, by simp, by simp⟩

#print axioms finrank_plane
#print axioms affInd_card_le_three
#print axioms mem_hull_triple
#print axioms finset_le_three

/-- **Radon's theorem in the plane.** Any 4 points of the plane split into two groups
whose hulls meet: some group `I` of the points and the rest `Iᶜ` have convex hulls
with a common point. -/
theorem radon_four_points_in_plane (p : Fin 4 → ℝ × ℝ) :
    ∃ I : Set (Fin 4), (convexHull ℝ (p '' I) ∩ convexHull ℝ (p '' Iᶜ)).Nonempty := by
  apply Convex.radon_partition
  intro h
  have := affInd_card_le_three h
  simp at this

/-- **Helly's theorem in the plane.** Finitely many convex sets in the plane that meet
three at a time (every group of at most 3 of them has a common point) all share a
common point. -/
theorem helly_triples_in_plane {ι : Type*} (C : ι → Set (ℝ × ℝ)) (s : Finset ι)
    (h_convex : ∀ j ∈ s, Convex ℝ (C j))
    (h_triples : ∀ I ⊆ s, I.card ≤ 3 → (⋂ j ∈ I, C j).Nonempty) :
    (⋂ j ∈ s, C j).Nonempty := by
  classical
  apply Convex.helly_theorem' h_convex
  intro I hI hcard
  rw [finrank_plane] at hcard
  exact h_triples I hI hcard

/-- **Carathéodory's theorem in the plane.** Any point of the hull of a set of points in
the plane is a mix of 3 of the points: weights never negative, adding to 1, on three
points of the set (repeats allowed when fewer are needed). -/
theorem caratheodory_three_points_in_plane (S : Set (ℝ × ℝ)) (x : ℝ × ℝ)
    (hx : x ∈ convexHull ℝ S) :
    ∃ a ∈ S, ∃ b ∈ S, ∃ c ∈ S, ∃ wa wb wc : ℝ, 0 ≤ wa ∧ 0 ≤ wb ∧ 0 ≤ wc ∧
      wa + wb + wc = 1 ∧ x = wa • a + wb • b + wc • c := by
  rw [convexHull_eq_union] at hx
  simp only [mem_iUnion] at hx
  obtain ⟨t, htS, hind, hxt⟩ := hx
  have hcard := affInd_card_le_three hind
  rw [Fintype.card_coe] at hcard
  have hne : t.Nonempty := by
    rw [← Finset.coe_nonempty, ← convexHull_nonempty_iff (𝕜 := ℝ)]
    exact ⟨x, hxt⟩
  obtain ⟨a, ha, b, hb, c, hc, hteq⟩ := finset_le_three hne hcard
  rw [hteq] at hxt
  exact ⟨a, htS ha, b, htS hb, c, htS hc, mem_hull_triple hxt⟩

/-! ### The card's worked examples -/

-- The turn weights 8, 4, 4, −16 on (0, 0), (4, 0), (0, 4), (1, 1) add to 0 and balance
-- to (0, 0).
example : (8 : ℤ) + 4 + 4 + (-16) = 0 ∧
    8 * 0 + 4 * 4 + 4 * 0 + (-16) * 1 = 0 ∧
    8 * 0 + 4 * 0 + 4 * 4 + (-16) * 1 = 0 := by
  norm_num

-- The Radon point: (8 (0, 0) + 4 (4, 0) + 4 (0, 4)) / 16 = (1, 1).
example : ((8 : ℚ) * 0 + 4 * 4 + 4 * 0) / 16 = 1 ∧ ((8 : ℚ) * 0 + 4 * 0 + 4 * 4) / 16 = 1 := by
  norm_num

-- The Radon split: (1, 1) lies in the hull of (0, 0), (4, 0) and (0, 4).
example : ((1 : ℝ), (1 : ℝ)) ∈
    convexHull ℝ ({((0 : ℝ), (0 : ℝ)), ((4 : ℝ), (0 : ℝ)), ((0 : ℝ), (4 : ℝ))} : Set (ℝ × ℝ)) := by
  rw [convexHull_insert (insert_nonempty _ _), convexHull_pair, mem_convexJoin]
  refine ⟨((0 : ℝ), (0 : ℝ)), mem_singleton _, ((2 : ℝ), (2 : ℝ)),
    ⟨1/2, 1/2, by norm_num, by norm_num, by norm_num, ?_⟩,
    1/2, 1/2, by norm_num, by norm_num, by norm_num, ?_⟩
  · ext <;> simp <;> norm_num
  · ext <;> simp

-- Helly on a line: the crew's windows [0, 5], [2, 7], [4, 9], [3, 6] share exactly [4, 5].
example : Icc (0 : ℝ) 5 ∩ Icc 2 7 ∩ Icc 4 9 ∩ Icc 3 6 = Icc 4 5 := by
  ext x
  simp only [mem_inter_iff, mem_Icc]
  constructor
  · rintro ⟨⟨⟨⟨_, h1⟩, _⟩, h2, _⟩, _⟩
    exact ⟨h2, h1⟩
  · rintro ⟨h1, h2⟩
    refine ⟨⟨⟨⟨?_, ?_⟩, ?_, ?_⟩, ?_, ?_⟩, ?_, ?_⟩ <;> linarith

-- Sets with gaps: {1, 2}, {2, 3}, {1, 3} meet in pairs but share nothing.
example : (({1, 2} : Finset ℕ) ∩ {2, 3}).Nonempty ∧ (({2, 3} : Finset ℕ) ∩ {1, 3}).Nonempty ∧
    (({1, 2} : Finset ℕ) ∩ {1, 3}).Nonempty ∧ ({1, 2} : Finset ℕ) ∩ {2, 3} ∩ {1, 3} = ∅ := by
  decide

-- The corner average of A (2, 1), B (10, 1), C (11, 6), D (7, 4), E (5, 8), F (2, 6)
-- is x = (37/6, 13/3).
example : ((2 : ℚ) + 10 + 11 + 7 + 5 + 2) / 6 = 37 / 6 ∧ ((1 : ℚ) + 1 + 6 + 4 + 8 + 6) / 6 = 13 / 3 := by
  norm_num

-- Carathéodory's mix: x = 40/93 B + 15/62 E + 61/186 F (about 0.4301, 0.2419, 0.3280),
-- weights never negative and adding to 1.
example : (40 / 93 : ℝ) + 15 / 62 + 61 / 186 = 1 ∧
    (40 / 93 : ℝ) • ((10 : ℝ), (1 : ℝ)) + (15 / 62 : ℝ) • ((5 : ℝ), (8 : ℝ)) +
      (61 / 186 : ℝ) • ((2 : ℝ), (6 : ℝ)) = ((37 / 6 : ℝ), (13 / 3 : ℝ)) := by
  refine ⟨by norm_num, ?_⟩
  ext <;> simp <;> norm_num

#print axioms radon_four_points_in_plane
#print axioms helly_triples_in_plane
#print axioms caratheodory_three_points_in_plane
