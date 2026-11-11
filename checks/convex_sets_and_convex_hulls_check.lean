-- Convex sets: the convex hull of finitely many points in the plane is exactly the set of their weighted averages (the smallest convex region holding them), the ground left of a line is convex, and a hull lies left of any line that has every point on its left.
import Mathlib.Analysis.Convex.Combination
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Positivity

open Finset

/-- The card's turn test: twice the signed area of triangle a, b, c. Positive means
walking a to b to c bends left, negative a right bend, zero straight on. -/
def turn (a b c : ℝ × ℝ) : ℝ :=
  (b.1 - a.1) * (c.2 - a.2) - (b.2 - a.2) * (c.1 - a.1)

/-- The hull is the weighted averages. Take any n points p₁, …, pₙ of the plane. The set of
all weighted averages w₁p₁ + … + wₙpₙ, with every weight wᵢ ≥ 0 and the weights adding to 1,
is convex, holds every point, and lies inside every convex region that holds every point.
So it is the smallest convex region holding the points: their convex hull. -/
theorem weighted_averages_are_smallest_convex_region {n : ℕ} (p : Fin n → ℝ × ℝ) :
    let W : Set (ℝ × ℝ) :=
      {x | ∃ w : Fin n → ℝ, (∀ i, 0 ≤ w i) ∧ ∑ i, w i = 1 ∧ ∑ i, w i • p i = x}
    Convex ℝ W ∧ Set.range p ⊆ W ∧
      (∀ S : Set (ℝ × ℝ), Convex ℝ S → Set.range p ⊆ S → W ⊆ S) ∧
      convexHull ℝ (Set.range p) = W := by
  intro W
  have hconv : Convex ℝ W := by
    rintro x ⟨w, hw0, hw1, rfl⟩ y ⟨v, hv0, hv1, rfl⟩ a b ha hb hab
    refine ⟨fun i => a * w i + b * v i, fun i => ?_, ?_, ?_⟩
    · have := hw0 i; have := hv0 i; positivity
    · rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum, hw1, hv1]; linarith
    · simp only [Finset.smul_sum, add_smul, smul_smul, Finset.sum_add_distrib]
  have hrange : Set.range p ⊆ W := by
    rintro _ ⟨i, rfl⟩
    refine ⟨fun j => if j = i then 1 else 0, fun j => ?_, ?_, ?_⟩
    · dsimp only; split_ifs <;> norm_num
    · simp
    · simp [ite_smul]
  have hmin : ∀ S : Set (ℝ × ℝ), Convex ℝ S → Set.range p ⊆ S → W ⊆ S := by
    rintro S hS hpS _ ⟨w, hw0, hw1, rfl⟩
    exact hS.sum_mem (fun i _ => hw0 i) hw1 (fun i _ => hpS ⟨i, rfl⟩)
  refine ⟨hconv, hrange, hmin, ?_⟩
  exact le_antisymm (convexHull_min hrange hconv)
    (hmin _ (convex_convexHull ℝ _) (subset_convexHull ℝ _))

/-- A half-plane is convex (Step 1). For any points a and b, the ground on or to the left of
the line from a to b, every q with turn(a, b, q) ≥ 0, is convex: along a segment, turn
averages its values at the two ends. -/
theorem left_half_plane_convex (a b : ℝ × ℝ) :
    Convex ℝ {q : ℝ × ℝ | 0 ≤ turn a b q} := by
  intro x hx y hy s t hs ht hst
  simp only [Set.mem_ofPred_eq] at hx hy ⊢
  have key : turn a b (s • x + t • y) = s * turn a b x + t * turn a b y := by
    obtain rfl : t = 1 - s := by linarith
    simp only [turn, Prod.fst_add, Prod.snd_add, Prod.smul_fst, Prod.smul_snd, smul_eq_mul]
    ring
  rw [key]
  positivity

/-- The gift-wrapping test (Step 4). If every one of the points lies on or to the left of the
string from a to b, then the whole convex hull of the points lies on or to the left of it. -/
theorem hull_left_of_string_when_every_point_is {n : ℕ} (p : Fin n → ℝ × ℝ)
    (a b : ℝ × ℝ) (h : ∀ i, 0 ≤ turn a b (p i)) :
    ∀ x ∈ convexHull ℝ (Set.range p), 0 ≤ turn a b x := by
  intro x hx
  have hsub : Set.range p ⊆ {q : ℝ × ℝ | 0 ≤ turn a b q} := by
    rintro _ ⟨i, rfl⟩
    exact h i
  exact convexHull_min hsub (left_half_plane_convex a b) hx

-- The eight trees: A (2, 0), B (14, 2), C (18, 10), D (12, 16), E (4, 14), F (0, 6),
-- G (8, 6), H (11, 8).

-- Corner turns round the hull F A B C D E: 40, 76, 88, 72, 60, 56, all left bends.
example : turn (4, 14) (0, 6) (2, 0) = 40 := by norm_num [turn]
example : turn (0, 6) (2, 0) (14, 2) = 76 := by norm_num [turn]
example : turn (2, 0) (14, 2) (18, 10) = 88 := by norm_num [turn]
example : turn (14, 2) (18, 10) (12, 16) = 72 := by norm_num [turn]
example : turn (18, 10) (12, 16) (4, 14) = 60 := by norm_num [turn]
example : turn (12, 16) (4, 14) (0, 6) = 56 := by norm_num [turn]

-- The dented fence turns right: −60 at G (A, G, B) and −48 at H (B, H, C).
example : turn (2, 0) (8, 6) (14, 2) = -60 := by norm_num [turn]
example : turn (14, 2) (11, 8) (18, 10) = -48 := by norm_num [turn]

-- The lower sweep: turn(A, E, G) = −72, turn(A, G, H) = −6, turn(A, H, D) = 64,
-- turn(H, D, B) = −30, turn(A, H, B) = −78, turn(A, B, C) = 88.
example : turn (2, 0) (4, 14) (8, 6) = -72 := by norm_num [turn]
example : turn (2, 0) (8, 6) (11, 8) = -6 := by norm_num [turn]
example : turn (2, 0) (11, 8) (12, 16) = 64 := by norm_num [turn]
example : turn (11, 8) (12, 16) (14, 2) = -30 := by norm_num [turn]
example : turn (2, 0) (11, 8) (14, 2) = -78 := by norm_num [turn]

-- The upper sweep, right to left (C, B, D, H, G, E, A, F), drops B (−72), H (−22), G (−72)
-- and A (−40).
example : turn (18, 10) (14, 2) (12, 16) = -72 := by norm_num [turn]
example : turn (12, 16) (11, 8) (8, 6) = -22 := by norm_num [turn]
example : turn (12, 16) (8, 6) (4, 14) = -72 := by norm_num [turn]
example : turn (4, 14) (2, 0) (0, 6) = -40 := by norm_num [turn]

-- Brute force: every tree lies on or left of edge A to B.
example : ∀ r ∈ ([(2, 0), (14, 2), (18, 10), (12, 16), (4, 14), (0, 6), (8, 6), (11, 8)] :
    List (ℝ × ℝ)), 0 ≤ turn (2, 0) (14, 2) r := by
  norm_num [turn]

-- Shoelace: −12 + 4 + 104 + 168 + 104 + 24 = 392, halved 196 square metres.
example : turn (0, 0) (0, 6) (2, 0) + turn (0, 0) (2, 0) (14, 2) + turn (0, 0) (14, 2) (18, 10)
    + turn (0, 0) (18, 10) (12, 16) + turn (0, 0) (12, 16) (4, 14)
    + turn (0, 0) (4, 14) (0, 6) = 392 := by norm_num [turn]

-- G as a mix of F, B, D: each weight is a ratio of turns, 76/188, 80/188, 32/188,
-- that is 19/47, 20/47, 8/47; they add to 1 and rebuild G = (8, 6).
example : turn (8, 6) (14, 2) (12, 16) = 76 ∧ turn (0, 6) (8, 6) (12, 16) = 80 ∧
    turn (0, 6) (14, 2) (8, 6) = 32 ∧ turn (0, 6) (14, 2) (12, 16) = 188 := by
  norm_num [turn]
example : (19 / 47 : ℝ) + 20 / 47 + 8 / 47 = 1 := by norm_num
example : (19 / 47 : ℝ) • ((0, 6) : ℝ × ℝ) + (20 / 47 : ℝ) • (14, 2) + (8 / 47 : ℝ) • (12, 16)
    = (8, 6) := by
  norm_num [Prod.ext_iff]

-- The midpoint of A and H, (13/2, 4), lies in the notch triangle A, B, G (left of all three sides).
example : 0 ≤ turn (2, 0) (14, 2) (13 / 2, 4) ∧ 0 ≤ turn (14, 2) (8, 6) (13 / 2, 4) ∧
    0 ≤ turn (8, 6) (2, 0) (13 / 2, 4) := by
  norm_num [turn]

#print axioms weighted_averages_are_smallest_convex_region
#print axioms left_half_plane_convex
#print axioms hull_left_of_string_when_every_point_is
