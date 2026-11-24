-- Singular homology: barycentric subdivision shrinks every piece by n/(n+1) per round, so enough rounds fit any open cover, and a point has singular homology ℤ, 0, 0, ...
import Mathlib.Analysis.Normed.Module.Convex
import Mathlib.Analysis.Convex.Topology
import Mathlib.Topology.MetricSpace.Pseudo.Lemmas
import Mathlib.Algebra.Category.ModuleCat.Colimits
import Mathlib.Algebra.Category.ModuleCat.Abelian
import Mathlib.AlgebraicTopology.SingularHomology.Basic

open Metric

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]

/-- One small simplex of the barycentric subdivision of the simplex with corners `v`,
one per ordering `σ` of the corners: its corner `m` is the centre (average) of the first
`m + 1` corners in that order, so the corners run from a corner of `v`, to the middle of
an edge, and so on up to the centre of the whole simplex. -/
noncomputable def sdPiece {n : ℕ} (v : Fin (n + 1) → E) (σ : Equiv.Perm (Fin (n + 1))) :
    Fin (n + 1) → E :=
  fun m => ((m : ℕ) + 1 : ℝ)⁻¹ • ∑ i ∈ Finset.Iic m, v (σ i)

theorem sdPiece_sub_eq {n : ℕ} (v : Fin (n + 1) → E) (σ : Equiv.Perm (Fin (n + 1)))
    (a b : Fin (n + 1)) :
    sdPiece v σ b - sdPiece v σ a = (((b : ℕ) + 1 : ℝ) * ((a : ℕ) + 1))⁻¹ •
      ∑ i ∈ Finset.Iic b, ∑ j ∈ Finset.Iic a, (v (σ i) - v (σ j)) := by
  simp only [sdPiece, Finset.sum_sub_distrib, Finset.sum_const, Fin.card_Iic]
  rw [← Finset.smul_sum, ← Nat.cast_smul_eq_nsmul ℝ, ← Nat.cast_smul_eq_nsmul ℝ, smul_sub,
    smul_smul, smul_smul]
  have ha : ((a : ℕ) + 1 : ℝ) ≠ 0 := by positivity
  have hb : ((b : ℕ) + 1 : ℝ) ≠ 0 := by positivity
  congr 2 <;> push_cast <;> field_simp

#print axioms sdPiece_sub_eq

theorem sdPiece_dist_le {n : ℕ} (v : Fin (n + 1) → E) (σ : Equiv.Perm (Fin (n + 1)))
    (a b : Fin (n + 1)) (hab : a ≤ b) :
    dist (sdPiece v σ b) (sdPiece v σ a) ≤ (n : ℝ) / (n + 1) * diam (Set.range v) := by
  set d := diam (Set.range v)
  have hd : ∀ i j, ‖v (σ i) - v (σ j)‖ ≤ d := fun i j => by
    rw [← dist_eq_norm]
    exact dist_le_diam_of_mem (Set.finite_range v).isBounded (Set.mem_range_self _)
      (Set.mem_range_self _)
  have hd0 : 0 ≤ d := diam_nonneg
  have hinner : ∀ j ∈ Finset.Iic a,
      ‖∑ i ∈ Finset.Iic b, (v (σ i) - v (σ j))‖ ≤ (b : ℕ) * d := by
    intro j hj
    have hjb : j ∈ Finset.Iic b := Finset.mem_Iic.2 ((Finset.mem_Iic.1 hj).trans hab)
    rw [← Finset.sum_erase (Finset.Iic b) (f := fun i => v (σ i) - v (σ j)) (a := j) (by simp)]
    refine (norm_sum_le _ _).trans ?_
    refine (Finset.sum_le_card_nsmul _ _ d (fun i _ => hd i j)).trans ?_
    rw [Finset.card_erase_of_mem hjb, Fin.card_Iic, nsmul_eq_mul]
    simp
  rw [dist_eq_norm, sdPiece_sub_eq, norm_smul, Finset.sum_comm]
  have hsum : ‖∑ j ∈ Finset.Iic a, ∑ i ∈ Finset.Iic b, (v (σ i) - v (σ j))‖ ≤
      ((a : ℕ) + 1 : ℝ) * ((b : ℕ) * d) := by
    refine (norm_sum_le _ _).trans ?_
    refine (Finset.sum_le_card_nsmul _ _ _ hinner).trans ?_
    rw [Fin.card_Iic, nsmul_eq_mul]; push_cast; rfl
  have ha : (0 : ℝ) < (a : ℕ) + 1 := by positivity
  have hb : (0 : ℝ) < (b : ℕ) + 1 := by positivity
  have hbn : ((b : ℕ) : ℝ) / ((b : ℕ) + 1) ≤ (n : ℝ) / (n + 1) := by
    rw [div_le_div_iff₀ hb (by positivity)]
    have : ((b : ℕ) : ℝ) ≤ n := by exact_mod_cast Nat.lt_succ_iff.1 b.isLt
    nlinarith
  rw [Real.norm_eq_abs, abs_of_pos (by positivity)]
  calc (((b : ℕ) + 1 : ℝ) * ((a : ℕ) + 1))⁻¹ * ‖∑ j ∈ Finset.Iic a, ∑ i ∈ Finset.Iic b, (v (σ i) - v (σ j))‖
      ≤ (((b : ℕ) + 1 : ℝ) * ((a : ℕ) + 1))⁻¹ * (((a : ℕ) + 1 : ℝ) * ((b : ℕ) * d)) :=
        mul_le_mul_of_nonneg_left hsum (by positivity)
    _ = ((b : ℕ) : ℝ) / ((b : ℕ) + 1) * d := by field_simp
    _ ≤ (n : ℝ) / (n + 1) * d := mul_le_mul_of_nonneg_right hbn hd0

#print axioms sdPiece_dist_le

theorem sdPiece_diam_le {n : ℕ} (v : Fin (n + 1) → E) (σ : Equiv.Perm (Fin (n + 1))) :
    diam (convexHull ℝ (Set.range (sdPiece v σ))) ≤
      ((n : ℝ) / (n + 1)) * diam (convexHull ℝ (Set.range v)) := by
  rw [convexHull_diam, convexHull_diam]
  refine diam_le_of_forall_dist_le (by positivity) ?_
  rintro _ ⟨a, rfl⟩ _ ⟨b, rfl⟩
  rcases le_total a b with h | h
  · rw [dist_comm]; exact sdPiece_dist_le v σ a b h
  · exact sdPiece_dist_le v σ b a h

#print axioms sdPiece_diam_le

theorem sdPiece_mem_convexHull {n : ℕ} (v : Fin (n + 1) → E) (σ : Equiv.Perm (Fin (n + 1)))
    (m : Fin (n + 1)) : sdPiece v σ m ∈ convexHull ℝ (Set.range v) := by
  have hc : (0 : ℝ) < (Finset.Iic m).card := by rw [Fin.card_Iic]; positivity
  have := Finset.centerMass_mem_convexHull (R := ℝ) (Finset.Iic m) (w := fun _ => (1 : ℝ))
    (z := fun i => v (σ i)) (fun _ _ => zero_le_one) (by simpa using hc)
    (fun i _ => Set.mem_range_self _)
  convert this using 1
  rw [Finset.centerMass]
  simp [sdPiece, Fin.card_Iic]

#print axioms sdPiece_mem_convexHull

theorem foldl_sdPiece_subset {n : ℕ} (σs : List (Equiv.Perm (Fin (n + 1)))) :
    ∀ v : Fin (n + 1) → E,
      convexHull ℝ (Set.range (σs.foldl sdPiece v)) ⊆ convexHull ℝ (Set.range v) := by
  induction σs with
  | nil => intro v; simp
  | cons σ σs ih =>
    intro v
    refine (ih (sdPiece v σ)).trans ?_
    refine convexHull_min ?_ (convex_convexHull ℝ _)
    rintro _ ⟨m, rfl⟩
    exact sdPiece_mem_convexHull v σ m

#print axioms foldl_sdPiece_subset

/-- The shrinking bound: cut an `n`-simplex by barycentric subdivision `r` times (the list
`σs` says which small simplex to keep at each round). Each piece left after `r` rounds has
diameter at most `(n/(n+1))^r` times the diameter of the simplex it came from. -/
theorem barycentric_subdivision_diam_le_pow {n : ℕ} (v : Fin (n + 1) → E)
    (σs : List (Equiv.Perm (Fin (n + 1)))) :
    diam (convexHull ℝ (Set.range (σs.foldl sdPiece v))) ≤
      ((n : ℝ) / (n + 1)) ^ σs.length * diam (convexHull ℝ (Set.range v)) := by
  induction σs generalizing v with
  | nil => simp
  | cons σ σs ih =>
    rw [List.foldl_cons, List.length_cons, pow_succ, mul_assoc]
    exact (ih (sdPiece v σ)).trans
      (mul_le_mul_of_nonneg_left (sdPiece_diam_le v σ) (by positivity))

/-- Enough rounds, set by the Lebesgue number of an open cover: if open sets cover the simplex,
then after some number `r` of rounds of barycentric subdivision every piece lies inside one
set of the cover. -/
theorem subdivision_pieces_eventually_small {n : ℕ} {ι : Type*} (v : Fin (n + 1) → E)
    (U : ι → Set E) (hU : ∀ i, IsOpen (U i))
    (hcover : convexHull ℝ (Set.range v) ⊆ ⋃ i, U i) :
    ∃ r : ℕ, ∀ σs : List (Equiv.Perm (Fin (n + 1))), σs.length = r →
      ∃ i, convexHull ℝ (Set.range (σs.foldl sdPiece v)) ⊆ U i := by
  obtain ⟨δ, hδ, hball⟩ := lebesgue_number_lemma_of_metric
    ((Set.finite_range v).isCompact_convexHull ℝ) hU hcover
  set D := diam (convexHull ℝ (Set.range v))
  have hD : 0 ≤ D := diam_nonneg
  have hc1 : (n : ℝ) / (n + 1) < 1 := by
    rw [div_lt_one (by positivity)]; linarith
  obtain ⟨r, hr⟩ := exists_pow_lt_of_lt_one (show 0 < δ / (D + 1) by positivity) hc1
  refine ⟨r, fun σs hlen => ?_⟩
  set w := σs.foldl sdPiece v
  have hx : w 0 ∈ convexHull ℝ (Set.range v) :=
    foldl_sdPiece_subset σs v (subset_convexHull ℝ _ (Set.mem_range_self 0))
  obtain ⟨i, hi⟩ := hball _ hx
  refine ⟨i, fun y hy => hi ?_⟩
  rw [mem_ball]
  have hdiam := barycentric_subdivision_diam_le_pow v σs
  rw [hlen] at hdiam
  have hbdd : Bornology.IsBounded (convexHull ℝ (Set.range w)) :=
    ((Set.finite_range w).isCompact_convexHull ℝ).isBounded
  have hpos : 0 ≤ ((n : ℝ) / (n + 1)) ^ r := by positivity
  calc dist y (w 0) ≤ diam (convexHull ℝ (Set.range w)) :=
        dist_le_diam_of_mem hbdd hy (subset_convexHull ℝ _ (Set.mem_range_self 0))
    _ ≤ ((n : ℝ) / (n + 1)) ^ r * D := hdiam
    _ ≤ ((n : ℝ) / (n + 1)) ^ r * (D + 1) := by nlinarith
    _ < δ / (D + 1) * (D + 1) := by
        exact mul_lt_mul_of_pos_right hr (by positivity)
    _ = δ := by field_simp

open AlgebraicTopology CategoryTheory Limits in
/-- A point's singular homology with integer coefficients reads 1, 0, 0, 0, ...:
`H_0` is `ℤ` and every `H_k` with `k ≥ 1` is zero. -/
theorem singular_homology_point :
    Nonempty (((singularHomologyFunctor (ModuleCat.{0} ℤ) 0).obj (ModuleCat.of ℤ ℤ)).obj
        (TopCat.of PUnit.{1}) ≅ ModuleCat.of ℤ ℤ) ∧
      ∀ k : ℕ, k ≠ 0 →
        IsZero (((singularHomologyFunctor (ModuleCat.{0} ℤ) k).obj (ModuleCat.of ℤ ℤ)).obj
          (TopCat.of PUnit.{1})) := by
  refine ⟨⟨singularHomologyFunctorZeroOfTotallyDisconnectedSpace _ _ _ ≪≫
    coproductUniqueIso (fun _ : TopCat.of PUnit.{1} => ModuleCat.of ℤ ℤ)⟩, fun k hk => ?_⟩
  exact isZero_singularHomologyFunctor_of_totallyDisconnectedSpace _ _ _ _ hk

-- The bound needs 6 rounds for a cover with Lebesgue number 0.1 m: (2/3)^5 > 1/10 > (2/3)^6.
example : (1 / 10 : ℚ) < (2 / 3) ^ 5 ∧ (2 / 3 : ℚ) ^ 6 < 1 / 10 := by norm_num
-- The wrong factor 1/2 asks for only 4 rounds: (1/2)^3 > 1/10 > (1/2)^4.
example : (1 / 10 : ℚ) < (1 / 2) ^ 3 ∧ (1 / 2 : ℚ) ^ 4 < 1 / 10 := by norm_num
-- A triangle cut once gives 3! = 6 pieces; after 6 rounds the panel is 6^6 = 46,656 triangles.
example : Nat.factorial 3 = 6 ∧ 6 ^ 6 = 46656 := by decide
-- Round 1, measured: corner to centre has squared width 1/3, within the bound (2/3)^2 = 4/9.
example : (1 / 3 : ℚ) ≤ (2 / 3) ^ 2 := by norm_num
-- Round 6, measured: squared width 25213/11337408, within the bound ((2/3)^6)^2.
example : (25213 / 11337408 : ℚ) ≤ ((2 / 3) ^ 6) ^ 2 := by norm_num

#print axioms barycentric_subdivision_diam_le_pow
#print axioms subdivision_pieces_eventually_small
#print axioms singular_homology_point
