-- The regularity lemma: every graph with at least m vertices splits into a bounded number of near-equal parts with all but an ε share of the pairs of parts ε-regular, regular pairs count triangles, and few triangles can be removed by deleting few edges.
import Mathlib.Combinatorics.SimpleGraph.Regularity.Lemma
import Mathlib.Combinatorics.SimpleGraph.Triangle.Removal

open Finset

universe u

theorem tc_card_interedges {V : Type u} [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj]
    (s t : Finset V) :
    #(G.interedges s t) = ∑ x ∈ s, #{y ∈ t | G.Adj x y} := by
  rw [SimpleGraph.interedges_def, card_filter, sum_product]
  refine sum_congr rfl fun x _ => ?_
  rw [card_filter]

#print axioms tc_card_interedges

theorem tc_bad_card {V : Type u} [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj]
    (ε : ℝ) (hε : 0 < ε) (s t : Finset V)
    (r : ∀ s' ⊆ s, ∀ t' ⊆ t, ε * #s ≤ #s' → ε * #t ≤ #t' →
      |(G.edgeDensity s' t' : ℝ) - G.edgeDensity s t| ≤ ε)
    (d : 2 * ε ≤ (G.edgeDensity s t : ℝ)) :
    (#{x ∈ s | (#{y ∈ t | G.Adj x y} : ℝ) < ((G.edgeDensity s t : ℝ) - ε) * #t} : ℝ) ≤
      ε * #s := by
  set B := {x ∈ s | (#{y ∈ t | G.Adj x y} : ℝ) < ((G.edgeDensity s t : ℝ) - ε) * #t} with hBdef
  by_contra h
  push Not at h
  have hd1 : (G.edgeDensity s t : ℝ) ≤ 1 := by exact_mod_cast G.edgeDensity_le_one s t
  have hε1 : ε ≤ 1 := by linarith
  have ht : (0 : ℝ) < #t := by
    rcases Nat.eq_zero_or_pos #t with h0 | h0
    · rw [card_eq_zero] at h0
      subst h0
      simp at d
      linarith
    · exact_mod_cast h0
  have hs0 : (0 : ℝ) ≤ #s := Nat.cast_nonneg _
  have hB : (0 : ℝ) < #B := lt_of_le_of_lt (by positivity) h
  have hBne : B.Nonempty := by
    rw [← card_pos]; exact_mod_cast hB
  have key := r B (filter_subset _ _) t Subset.rfl h.le (by nlinarith)
  have hsum : (#(G.interedges B t) : ℝ) < #B * (((G.edgeDensity s t : ℝ) - ε) * #t) := by
    rw [tc_card_interedges, Nat.cast_sum]
    calc ∑ x ∈ B, (#{y ∈ t | G.Adj x y} : ℝ)
        < ∑ x ∈ B, (((G.edgeDensity s t : ℝ) - ε) * #t) :=
          sum_lt_sum_of_nonempty hBne fun x hx => (mem_filter.1 hx).2
      _ = _ := by rw [sum_const, nsmul_eq_mul]
  have hdB : (G.edgeDensity B t : ℝ) < (G.edgeDensity s t : ℝ) - ε := by
    rw [SimpleGraph.edgeDensity_def]
    push_cast
    rw [div_lt_iff₀ (by positivity)]
    linarith
  rw [abs_le] at key
  linarith

#print axioms tc_bad_card

/-- **The regularity lemma.** For every allowed error ε > 0 and whole number m there is a number
M, depending only on ε and m, such that every graph with at least m vertices splits into k parts,
m ≤ k ≤ M, of sizes differing by at most one, with all but at most ε k² pairs of parts ε-regular:
for such a pair (A, B), every X ⊆ A and Y ⊆ B with |X| ≥ ε|A| and |Y| ≥ ε|B| has
|d(X, Y) - d(A, B)| ≤ ε, where d(X, Y) = e(X, Y) / (|X| |Y|) is the edge density. -/
theorem szemeredi_regularity_lemma (ε : ℝ) (hε : 0 < ε) (m : ℕ) :
    ∃ M : ℕ, ∀ (V : Type u) [Fintype V] [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj],
      m ≤ Fintype.card V →
      ∃ P : Finpartition (univ : Finset V),
        P.IsEquipartition ∧ m ≤ #P.parts ∧ #P.parts ≤ M ∧
        ∃ irregular : Finset (Finset V × Finset V),
          (#irregular : ℝ) ≤ ε * (#P.parts : ℝ) ^ 2 ∧
          ∀ A ∈ P.parts, ∀ B ∈ P.parts, A ≠ B → (A, B) ∉ irregular →
            ∀ X ⊆ A, ∀ Y ⊆ B, ε * #A ≤ #X → ε * #B ≤ #Y →
              |(G.edgeDensity X Y : ℝ) - G.edgeDensity A B| ≤ ε := by
  refine ⟨SzemerediRegularity.bound ε m, fun V _ _ G _ hm => ?_⟩
  obtain ⟨P, hP1, hP2, hP3, hP4⟩ := szemeredi_regularity G hε hm
  refine ⟨P, hP1, hP2, hP3, P.nonUniforms G ε, ?_, ?_⟩
  · refine hP4.trans ?_
    have hk : (0 : ℝ) ≤ #P.parts := Nat.cast_nonneg _
    rcases Nat.eq_zero_or_pos #P.parts with h0 | h0
    · simp [h0]
    · rw [Nat.cast_mul, Nat.cast_sub h0]
      push_cast
      nlinarith
  · intro A hA B hB hAB hirr X hX Y hY hXc hYc
    have hu : G.IsUniform ε A B := by
      by_contra hc
      exact hirr ((P.mk_mem_nonUniforms G).2 ⟨hA, hB, hAB, hc⟩)
    exact (hu hX hY (by rwa [mul_comm]) (by rwa [mul_comm])).le

/-- **The triangle counting lemma.** If the three pairs among X, Y, Z are ε-regular, with
densities d_XY, d_YZ, d_XZ each at least 2ε, then the triangles with a corner in each of X, Y, Z
number at least (1 - 2ε)(d_XY - ε)(d_YZ - ε)(d_XZ - ε)|X||Y||Z|. -/
theorem triangle_counting_lemma {V : Type u} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (ε : ℝ) (X Y Z : Finset V)
    (rXY : ∀ X' ⊆ X, ∀ Y' ⊆ Y, ε * #X ≤ #X' → ε * #Y ≤ #Y' →
      |(G.edgeDensity X' Y' : ℝ) - G.edgeDensity X Y| ≤ ε)
    (rYZ : ∀ Y' ⊆ Y, ∀ Z' ⊆ Z, ε * #Y ≤ #Y' → ε * #Z ≤ #Z' →
      |(G.edgeDensity Y' Z' : ℝ) - G.edgeDensity Y Z| ≤ ε)
    (rXZ : ∀ X' ⊆ X, ∀ Z' ⊆ Z, ε * #X ≤ #X' → ε * #Z ≤ #Z' →
      |(G.edgeDensity X' Z' : ℝ) - G.edgeDensity X Z| ≤ ε)
    (dXY : 2 * ε ≤ (G.edgeDensity X Y : ℝ)) (dYZ : 2 * ε ≤ (G.edgeDensity Y Z : ℝ))
    (dXZ : 2 * ε ≤ (G.edgeDensity X Z : ℝ)) :
    (1 - 2 * ε) * ((G.edgeDensity X Y : ℝ) - ε) * ((G.edgeDensity Y Z : ℝ) - ε) *
        ((G.edgeDensity X Z : ℝ) - ε) * #X * #Y * #Z ≤
      #{t ∈ X ×ˢ Y ×ˢ Z | G.Adj t.1 t.2.1 ∧ G.Adj t.2.1 t.2.2 ∧ G.Adj t.1 t.2.2} := by
  rcases lt_trichotomy ε 0 with hε | rfl | hε
  · exfalso
    have hX : (0 : ℝ) ≤ #X := Nat.cast_nonneg _
    have hY : (0 : ℝ) ≤ #Y := Nat.cast_nonneg _
    have := rXY X Subset.rfl Y Subset.rfl (by nlinarith) (by nlinarith)
    simp at this
    linarith
  · have := rXY ∅ (empty_subset _) Y Subset.rfl (by simp) (by simp)
    simp only [SimpleGraph.edgeDensity_empty_left, Rat.cast_zero, zero_sub, abs_neg,
      abs_nonpos_iff] at this
    rw [this]
    simp
  set NY : V → Finset V := fun x => {y ∈ Y | G.Adj x y} with hNY
  set NZ : V → Finset V := fun x => {z ∈ Z | G.Adj x z} with hNZ
  set dxy : ℝ := (G.edgeDensity X Y : ℝ) with hdxy
  set dyz : ℝ := (G.edgeDensity Y Z : ℝ) with hdyz
  set dxz : ℝ := (G.edgeDensity X Z : ℝ) with hdxz
  have hY0 : (0 : ℝ) < #Y := by
    rcases Nat.eq_zero_or_pos #Y with h0 | h0
    · rw [card_eq_zero] at h0
      subst h0
      simp [dxy] at dXY
      linarith
    · exact_mod_cast h0
  have hZ0 : (0 : ℝ) < #Z := by
    rcases Nat.eq_zero_or_pos #Z with h0 | h0
    · rw [card_eq_zero] at h0
      subst h0
      simp [dxz] at dXZ
      linarith
    · exact_mod_cast h0
  set good := {x ∈ X | (dxy - ε) * #Y ≤ (#(NY x) : ℝ) ∧ (dxz - ε) * #Z ≤ (#(NZ x) : ℝ)}
    with hgood
  have hbY := tc_bad_card G ε hε X Y rXY dXY
  have hbZ := tc_bad_card G ε hε X Z rXZ dXZ
  have hgood_card : (1 - 2 * ε) * #X ≤ (#good : ℝ) := by
    have hsub : X ⊆ good ∪ ({x ∈ X | (#{y ∈ Y | G.Adj x y} : ℝ) < (dxy - ε) * #Y} ∪
        {x ∈ X | (#{y ∈ Z | G.Adj x y} : ℝ) < (dxz - ε) * #Z}) := by
      intro x hx
      simp only [mem_union, mem_filter, hgood, hNY, hNZ]
      by_contra hc
      push Not at hc
      obtain ⟨h1, h2, h3⟩ := hc
      exact absurd (h1 hx (h2 hx)) (not_lt.2 (h3 hx))
    have := (card_le_card hsub).trans ((card_union_le _ _).trans
      (Nat.add_le_add_left (card_union_le _ _) _))
    have : (#X : ℝ) ≤ #good + (#{x ∈ X | (#{y ∈ Y | G.Adj x y} : ℝ) < (dxy - ε) * #Y} +
        #{x ∈ X | (#{y ∈ Z | G.Adj x y} : ℝ) < (dxz - ε) * #Z} : ℕ) := by
      exact_mod_cast this
    push_cast at this
    linarith
  have hx : ∀ x ∈ good, (dyz - ε) * (dxy - ε) * (dxz - ε) * #Y * #Z ≤
      (#(G.interedges (NY x) (NZ x)) : ℝ) := by
    intro x hx
    obtain ⟨-, h1, h2⟩ := (mem_filter.1 hx)
    have hY : ε * #Y ≤ (#(NY x) : ℝ) :=
      le_trans (mul_le_mul_of_nonneg_right (by linarith) (Nat.cast_nonneg _)) h1
    have hZ : ε * #Z ≤ (#(NZ x) : ℝ) :=
      le_trans (mul_le_mul_of_nonneg_right (by linarith) (Nat.cast_nonneg _)) h2
    have hNY0 : (0 : ℝ) < #(NY x) := lt_of_lt_of_le (by positivity) hY
    have hNZ0 : (0 : ℝ) < #(NZ x) := lt_of_lt_of_le (by positivity) hZ
    have key := rYZ (NY x) (filter_subset _ _) (NZ x) (filter_subset _ _) hY hZ
    rw [abs_le] at key
    have hden : (G.edgeDensity (NY x) (NZ x) : ℝ) * (#(NY x) * #(NZ x)) =
        #(G.interedges (NY x) (NZ x)) := by
      rw [SimpleGraph.edgeDensity_def]
      push_cast
      field_simp
    rw [← hden]
    calc (dyz - ε) * (dxy - ε) * (dxz - ε) * #Y * #Z
        = (dyz - ε) * (((dxy - ε) * #Y) * ((dxz - ε) * #Z)) := by ring
      _ ≤ (dyz - ε) * (#(NY x) * #(NZ x)) := by
          gcongr
          · linarith
          · nlinarith
      _ ≤ _ := by
          gcongr
          linarith
  have hcount : ∑ x ∈ X, #(G.interedges (NY x) (NZ x)) =
      #{t ∈ X ×ˢ Y ×ˢ Z | G.Adj t.1 t.2.1 ∧ G.Adj t.2.1 t.2.2 ∧ G.Adj t.1 t.2.2} := by
    rw [card_filter, sum_product]
    refine sum_congr rfl fun x _ => ?_
    rw [← card_filter]
    congr 1
    ext ⟨y, z⟩
    simp only [SimpleGraph.mk_mem_interedges_iff, mem_filter, mem_product, hNY, hNZ]
    tauto
  rw [← hcount]
  have hc0 : 0 ≤ (dxy - ε) * (dyz - ε) * (dxz - ε) * #Y * #Z := by
    have : 0 ≤ dxy - ε := by linarith
    have : 0 ≤ dyz - ε := by linarith
    have : 0 ≤ dxz - ε := by linarith
    positivity
  calc (1 - 2 * ε) * (dxy - ε) * (dyz - ε) * (dxz - ε) * #X * #Y * #Z
      = ((1 - 2 * ε) * #X) * ((dxy - ε) * (dyz - ε) * (dxz - ε) * #Y * #Z) := by ring
    _ ≤ #good * ((dxy - ε) * (dyz - ε) * (dxz - ε) * #Y * #Z) :=
        mul_le_mul_of_nonneg_right hgood_card hc0
    _ = ∑ x ∈ good, (dyz - ε) * (dxy - ε) * (dxz - ε) * #Y * #Z := by
        rw [sum_const, nsmul_eq_mul]; ring
    _ ≤ ∑ x ∈ good, (#(G.interedges (NY x) (NZ x)) : ℝ) := sum_le_sum hx
    _ ≤ ∑ x ∈ X, (#(G.interedges (NY x) (NZ x)) : ℝ) :=
        sum_le_sum_of_subset_of_nonneg (filter_subset _ _) fun _ _ _ => Nat.cast_nonneg _
    _ = _ := by push_cast; rfl

/-- **The triangle removal lemma.** For every ε > 0 there is a δ > 0 such that a graph on n
vertices with fewer than δ n³ triangles becomes triangle-free after deleting at most ε n² edges. -/
theorem triangle_removal_lemma (ε : ℝ) (hε : 0 < ε) :
    ∃ δ : ℝ, 0 < δ ∧
      ∀ (V : Type u) [Fintype V] [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj],
        (#(G.cliqueFinset 3) : ℝ) < δ * (Fintype.card V : ℝ) ^ 3 →
        ∃ H : SimpleGraph V, ∃ _ : DecidableRel H.Adj, H ≤ G ∧ H.CliqueFree 3 ∧
          (#(G.edgeFinset \ H.edgeFinset) : ℝ) ≤ ε * (Fintype.card V : ℝ) ^ 2 := by
  refine ⟨SimpleGraph.triangleRemovalBound ε, SimpleGraph.triangleRemovalBound_pos hε,
    fun V _ _ G _ hG => ?_⟩
  obtain ⟨H, hHG, hdec, hcard, hfree⟩ := G.triangle_removal hG
  refine ⟨H, hdec, hHG, hfree, ?_⟩
  have hsub : H.edgeFinset ⊆ G.edgeFinset := SimpleGraph.edgeFinset_subset_edgeFinset.2 hHG
  rw [card_sdiff_of_subset hsub, Nat.cast_sub (card_le_card hsub)]
  push_cast at hcard
  exact hcard.le

/-- The depots and shops: vertices 0-3 are a1-a4, vertices 4-7 are b1-b4; a1, a2 link to b1, b2
and a3, a4 link to b3, b4. -/
def depots : SimpleGraph (Fin 8) where
  Adj i j := i.val / 2 + 2 = j.val / 2 ∨ j.val / 2 + 2 = i.val / 2
  symm := ⟨fun i j h => by omega⟩
  loopless := ⟨fun i h => by omega⟩

instance : DecidableRel depots.Adj := fun i j =>
  inferInstanceAs (Decidable (i.val / 2 + 2 = j.val / 2 ∨ j.val / 2 + 2 = i.val / 2))

-- 8 of the 16 routes run: density 1/2.
example : #(depots.interedges {0, 1, 2, 3} {4, 5, 6, 7}) = 8 := by decide
example : depots.edgeDensity {0, 1, 2, 3} {4, 5, 6, 7} = 1 / 2 := by
  rw [SimpleGraph.edgeDensity_def,
    show #(depots.interedges {0, 1, 2, 3} {4, 5, 6, 7}) = 8 by decide]
  norm_num
-- On the halves {a1, a2} and {b1, b2}: 4 of 4 routes, density 1, gap 1 - 1/2 = 1/2.
example : depots.edgeDensity {0, 1} {4, 5} = 1 := by
  rw [SimpleGraph.edgeDensity_def, show #(depots.interedges {0, 1} {4, 5}) = 4 by decide]
  norm_num
-- Pieces of 3: {a1, a2, a3} and {b1, b2, b3} hold 5 of 9 routes, a gap of 5/9 - 1/2 = 1/18.
example : depots.edgeDensity {0, 1, 2} {4, 5, 6} = 5 / 9 := by
  rw [SimpleGraph.edgeDensity_def, show #(depots.interedges {0, 1, 2} {4, 5, 6}) = 5 by decide]
  norm_num
example : (5 / 9 : ℚ) - 1 / 2 = 1 / 18 := by norm_num
-- Energy: two parts 16 × (1/2)² / 64 = 1/16; four halves (4 + 4)/64 = 1/8; gain 1/16.
example : (16 * (1 / 2) ^ 2 / 64 : ℚ) = 1 / 16 := by norm_num
example : ((4 + 4) / 64 : ℚ) - 1 / 16 = 1 / 16 := by norm_num
-- The gain from squared gaps, 4 × (4/64) × (1/2)², and the promised floor (1/2)⁴ × 16/64 = 1/64.
example : (4 * (4 / 64) * (1 / 2) ^ 2 : ℚ) = 1 / 16 := by norm_num
example : ((1 / 2) ^ 4 * 16 / 64 : ℚ) = 1 / 64 := by norm_num
-- Three parts of 16 at density 1/2: the product rule predicts (1/2)³ × 16³ = 512 triangles.
example : ((1 / 2) ^ 3 * 16 ^ 3 : ℚ) = 512 := by norm_num

#print axioms szemeredi_regularity_lemma
#print axioms triangle_counting_lemma
#print axioms triangle_removal_lemma
