-- Erdos problems: the easy lower bound on distinct distances, the Erdős–Rado sunflower bound, the fact that six 2-sets are the most with no 3-petal sunflower, and the card's whole-number counts are exact.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Geometry.Euclidean.Basic

/-- A sunflower: a family of sets whose pairwise overlaps are all the same set (the core).
The core may be empty, so pairwise disjoint sets form a sunflower. -/
def IsSunflower {α : Type*} [DecidableEq α] (G : Finset (Finset α)) : Prop :=
  ∀ A ∈ G, ∀ B ∈ G, ∀ C ∈ G, ∀ D ∈ G, A ≠ B → C ≠ D → A ∩ B = C ∩ D

instance {α : Type*} [DecidableEq α] (G : Finset (Finset α)) : Decidable (IsSunflower G) := by
  unfold IsSunflower; infer_instance

/-- Two circles with different centres in the plane share at most two points. -/
theorem card_le_two_of_dist_eq {p q : EuclideanSpace ℝ (Fin 2)} (hpq : p ≠ q)
    (T : Finset (EuclideanSpace ℝ (Fin 2))) (a b : ℝ)
    (hT : ∀ x ∈ T, dist x p = a ∧ dist x q = b) : T.card ≤ 2 := by
  by_contra h
  push Not at h
  obtain ⟨x, hx, y, hy, z, hz, hxy, hxz, hyz⟩ := Finset.two_lt_card.mp h
  have := EuclideanGeometry.eq_of_dist_eq_of_dist_eq_of_finrank_eq_two finrank_euclideanSpace_fin
    hpq hxy (hT x hx).1 (hT y hy).1 (hT z hz).1 (hT x hx).2 (hT y hy).2 (hT z hz).2
  rcases this with h | h
  · exact hxz h.symm
  · exact hyz h.symm

/-- A family whose distinct pairs all overlap in the same set is a sunflower. -/
theorem isSunflower_of_inter_eq {α : Type*} [DecidableEq α] (G : Finset (Finset α))
    (K : Finset α) (h : ∀ A ∈ G, ∀ B ∈ G, A ≠ B → A ∩ B = K) : IsSunflower G := by
  intro A hA B hB C hC D hD hAB hCD
  rw [h A hA B hB hAB, h C hC D hD hCD]

/-- Two different 2-sets that share a point overlap in exactly that point. -/
theorem pair_inter_eq_singleton {α : Type*} [DecidableEq α] {X Y : Finset α} {v : α}
    (hX : X.card = 2) (hY : Y.card = 2) (hXY : X ≠ Y) (hvX : v ∈ X) (hvY : v ∈ Y) :
    X ∩ Y = {v} := by
  have hv : v ∈ X ∩ Y := Finset.mem_inter.mpr ⟨hvX, hvY⟩
  have hle : (X ∩ Y).card ≤ 1 := by
    by_contra h
    push Not at h
    have h1 : X ∩ Y = X :=
      Finset.eq_of_subset_of_card_le Finset.inter_subset_left (by omega)
    have h2 : X ∩ Y = Y :=
      Finset.eq_of_subset_of_card_le Finset.inter_subset_right (by omega)
    exact hXY (h1.symm.trans h2)
  exact Finset.eq_singleton_iff_unique_mem.mpr
    ⟨hv, fun w hw => Finset.card_le_one.mp hle w hw v hv⟩

/-- With no 3-petal sunflower, at most two of the 2-sets contain any one point. -/
theorem star_card_le_two {α : Type*} [DecidableEq α] (F : Finset (Finset α))
    (h2 : ∀ A ∈ F, A.card = 2) (hfree : ∀ G ∈ F.powersetCard 3, ¬ IsSunflower G) (v : α) :
    (F.filter (fun A => v ∈ A)).card ≤ 2 := by
  by_contra h
  push Not at h
  obtain ⟨A, hA, B, hB, C, hC, hAB, hAC, hBC⟩ := Finset.two_lt_card.mp h
  have hsub : ({A, B, C} : Finset (Finset α)) ⊆ F.filter (fun A => v ∈ A) := by
    intro X hX
    simp only [Finset.mem_insert, Finset.mem_singleton] at hX
    rcases hX with rfl | rfl | rfl <;> assumption
  apply hfree {A, B, C}
  · rw [Finset.mem_powersetCard]
    refine ⟨hsub.trans (Finset.filter_subset _ _), ?_⟩
    rw [Finset.card_insert_of_notMem (by simp [hAB, hAC]), Finset.card_pair hBC]
  · apply isSunflower_of_inter_eq _ {v}
    intro X hX Y hY hXY
    have hX' := Finset.mem_filter.mp (hsub hX)
    have hY' := Finset.mem_filter.mp (hsub hY)
    exact pair_inter_eq_singleton (h2 X hX'.1) (h2 Y hY'.1) hXY hX'.2 hY'.2

/-- With no 3-petal sunflower, at most three of the 2-sets meet a given one (itself included). -/
theorem card_le_three_add {α : Type*} [DecidableEq α] (F : Finset (Finset α))
    (h2 : ∀ A ∈ F, A.card = 2) (hfree : ∀ G ∈ F.powersetCard 3, ¬ IsSunflower G)
    (e : Finset α) (he : e ∈ F) :
    F.card ≤ 3 + (F.filter (fun f => f ∩ e = ∅)).card := by
  obtain ⟨a, b, hab, rfl⟩ := Finset.card_eq_two.mp (h2 e he)
  have hsub : F ⊆ (F.filter (fun f => a ∈ f) ∪ F.filter (fun f => b ∈ f)) ∪
      F.filter (fun f => f ∩ {a, b} = ∅) := by
    intro f hf
    by_cases ha : a ∈ f
    · simp [hf, ha]
    by_cases hb : b ∈ f
    · simp [hf, hb]
    · simp only [Finset.mem_union, Finset.mem_filter]
      right
      refine ⟨hf, ?_⟩
      ext x
      simp only [Finset.mem_inter, Finset.mem_insert, Finset.mem_singleton,
        Finset.notMem_empty, iff_false, not_and]
      rintro hx (rfl | rfl) <;> contradiction
  have hX := star_card_le_two F h2 hfree a
  have hY := star_card_le_two F h2 hfree b
  have hint : 1 ≤ (F.filter (fun f => a ∈ f) ∩ F.filter (fun f => b ∈ f)).card :=
    Finset.card_pos.mpr ⟨{a, b}, by simp [he]⟩
  have h3 := Finset.card_union_add_card_inter (F.filter (fun f => a ∈ f))
    (F.filter (fun f => b ∈ f))
  have h4 := Finset.card_le_card hsub
  have h5 := Finset.card_union_le (F.filter (fun f => a ∈ f) ∪ F.filter (fun f => b ∈ f))
    (F.filter fun f => f ∩ {a, b} = ∅)
  omega

/-- The easy lower bound for distinct distances: n different points in the plane make at
least t₀ different distances, where t₀ is the least whole number with 2t₀² + t₀ ≥ n − 1.
Said another way: whenever 2s² + s < n − 1, the points make more than s distances. -/
theorem distinct_distances_ge_easy_bound (S : Finset (EuclideanSpace ℝ (Fin 2))) (s : ℕ)
    (hs : 2 * s ^ 2 + s < S.card - 1) :
    s < (S.offDiag.image fun p => dist p.1 p.2).card := by
  set D := S.offDiag.image fun p => dist p.1 p.2 with hD
  by_contra hcon
  push Not at hcon
  obtain ⟨p, hp, q, hq, hpq⟩ := Finset.one_lt_card.mp (by omega : 1 < S.card)
  set T := (S.erase p).erase q with hTdef
  have key : T.card ≤ 2 * (D ×ˢ D).card := by
    calc T.card ≤ 2 * (T.image fun x => (dist x p, dist x q)).card := by
          apply Finset.card_le_mul_card_image
          intro ab _
          apply card_le_two_of_dist_eq hpq _ ab.1 ab.2
          intro x hx
          rw [Finset.mem_filter] at hx
          rw [← hx.2]
          exact ⟨rfl, rfl⟩
      _ ≤ 2 * (D ×ˢ D).card := by
          apply Nat.mul_le_mul_left
          apply Finset.card_le_card
          intro ab hab
          obtain ⟨x, hx, rfl⟩ := Finset.mem_image.mp hab
          simp only [hTdef, Finset.mem_erase] at hx
          simp only [Finset.mem_product, hD, Finset.mem_image, Finset.mem_offDiag]
          exact ⟨⟨(x, p), ⟨hx.2.2, hp, hx.2.1⟩, rfl⟩, ⟨(x, q), ⟨hx.2.2, hq, hx.1⟩, rfl⟩⟩
  rw [Finset.card_product] at key
  have hT : T.card = S.card - 1 - 1 := by
    rw [hTdef, Finset.card_erase_of_mem (Finset.mem_erase.mpr ⟨hpq.symm, hq⟩),
      Finset.card_erase_of_mem hp]
  have hD1 : 1 ≤ D.card :=
    Finset.card_pos.mpr ⟨dist p q, Finset.mem_image.mpr ⟨(p, q), by simp [hp, hq, hpq], rfl⟩⟩
  have hsq : D.card * D.card ≤ s * s := Nat.mul_le_mul hcon hcon
  have hs' : 2 * (s * s) + s < S.card - 1 := by rw [← pow_two]; exact hs
  generalize D.card * D.card = t2 at key hsq
  generalize s * s = s2 at hs' hsq
  omega

/-- The Erdős–Rado sunflower bound: a family of more than w! (r − 1)^w distinct sets, each
with w members, contains r sets forming a sunflower. -/
theorem erdos_rado_sunflower {α : Type*} [DecidableEq α] (w r : ℕ) (F : Finset (Finset α))
    (hw : ∀ A ∈ F, A.card = w) (hF : w.factorial * (r - 1) ^ w < F.card) :
    ∃ G ∈ F.powersetCard r, IsSunflower G := by
  induction w generalizing F with
  | zero =>
    exfalso
    have : F.card ≤ 1 := by
      apply Finset.card_le_one.mpr
      intro a ha b hb
      rw [Finset.card_eq_zero.mp (hw a ha), Finset.card_eq_zero.mp (hw b hb)]
    simp at hF
    omega
  | succ w ih =>
    let P := F.powerset.filter (fun M => ∀ A ∈ M, ∀ B ∈ M, A ≠ B → A ∩ B = ∅)
    have hPne : P.Nonempty := ⟨∅, by simp [P]⟩
    obtain ⟨M, hMP, hMmax⟩ := P.exists_max_image Finset.card hPne
    have hMP' := Finset.mem_filter.mp hMP
    have hMF : M ⊆ F := Finset.mem_powerset.mp hMP'.1
    have hMdisj := hMP'.2
    by_cases hr : r ≤ M.card
    · obtain ⟨G, hGM, hGcard⟩ := Finset.exists_subset_card_eq hr
      refine ⟨G, Finset.mem_powersetCard.mpr ⟨hGM.trans hMF, hGcard⟩, ?_⟩
      apply isSunflower_of_inter_eq G ∅
      intro A hA B hB hAB
      exact hMdisj A (hGM hA) B (hGM hB) hAB
    · push Not at hr
      set U := M.biUnion id with hUdef
      have hU : U.card ≤ (r - 1) * (w + 1) := by
        calc U.card ≤ ∑ A ∈ M, (id A).card := Finset.card_biUnion_le
          _ = ∑ A ∈ M, (w + 1) := Finset.sum_congr rfl (fun A hA => hw A (hMF hA))
          _ = M.card * (w + 1) := by simp
          _ ≤ (r - 1) * (w + 1) := Nat.mul_le_mul_right _ (by omega)
      have hmeet : ∀ A ∈ F, ∃ x ∈ U, x ∈ A := by
        intro A hA
        by_contra hno
        push Not at hno
        by_cases hAM : A ∈ M
        · have hne : A.Nonempty := by
            rw [← Finset.card_pos, hw A hA]
            omega
          obtain ⟨x, hx⟩ := hne
          exact hno x (Finset.mem_biUnion.mpr ⟨A, hAM, hx⟩) hx
        · have hdA : ∀ D ∈ M, A ∩ D = ∅ := by
            intro D hD
            rw [Finset.eq_empty_iff_forall_notMem]
            intro x hx
            rw [Finset.mem_inter] at hx
            exact hno x (Finset.mem_biUnion.mpr ⟨D, hD, hx.2⟩) hx.1
          have hins : insert A M ∈ P := by
            refine Finset.mem_filter.mpr ⟨Finset.mem_powerset.mpr (Finset.insert_subset hA hMF), ?_⟩
            intro B hB C hC hBC
            rw [Finset.mem_insert] at hB hC
            rcases hB with rfl | hB <;> rcases hC with rfl | hC
            · exact absurd rfl hBC
            · exact hdA C hC
            · rw [Finset.inter_comm]; exact hdA B hB
            · exact hMdisj B hB C hC hBC
          have := hMmax _ hins
          rw [Finset.card_insert_of_notMem hAM] at this
          omega
      have hex : ∃ x ∈ U, w.factorial * (r - 1) ^ w < (F.filter (fun A => x ∈ A)).card := by
        by_contra hno
        push Not at hno
        have h1 : F.card ≤ ∑ x ∈ U, (F.filter (fun A => x ∈ A)).card := by
          calc F.card ≤ (U.biUnion fun x => F.filter (fun A => x ∈ A)).card := by
                apply Finset.card_le_card
                intro A hA
                obtain ⟨x, hxU, hxA⟩ := hmeet A hA
                exact Finset.mem_biUnion.mpr ⟨x, hxU, Finset.mem_filter.mpr ⟨hA, hxA⟩⟩
            _ ≤ _ := Finset.card_biUnion_le
        have h2 : ∑ x ∈ U, (F.filter (fun A => x ∈ A)).card ≤
            U.card * (w.factorial * (r - 1) ^ w) := by
          have := Finset.sum_le_card_nsmul U _ _ hno
          simpa using this
        have h3 : U.card * (w.factorial * (r - 1) ^ w) ≤ (w + 1).factorial * (r - 1) ^ (w + 1) := by
          rw [Nat.factorial_succ, pow_succ]
          calc U.card * (w.factorial * (r - 1) ^ w)
              ≤ ((r - 1) * (w + 1)) * (w.factorial * (r - 1) ^ w) := Nat.mul_le_mul_right _ hU
            _ = (w + 1) * w.factorial * ((r - 1) ^ w * (r - 1)) := by ring
        omega
      obtain ⟨x, -, hx⟩ := hex
      set Fx := F.filter (fun A => x ∈ A) with hFx
      set F' := Fx.image (fun A : Finset α => A.erase x) with hF'
      have hinj : Set.InjOn (fun A : Finset α => A.erase x) Fx := by
        intro A hA B hB hAB
        have hA' := (Finset.mem_filter.mp (Finset.mem_coe.mp hA)).2
        have hB' := (Finset.mem_filter.mp (Finset.mem_coe.mp hB)).2
        have := congrArg (insert x) hAB
        simp only at this
        rwa [Finset.insert_erase hA', Finset.insert_erase hB'] at this
      have hF'card : F'.card = Fx.card := Finset.card_image_of_injOn hinj
      have hw' : ∀ B ∈ F', B.card = w := by
        intro B hB
        obtain ⟨A, hA, rfl⟩ := Finset.mem_image.mp hB
        rw [Finset.mem_filter] at hA
        rw [Finset.card_erase_of_mem hA.2, hw A hA.1]
        rfl
      obtain ⟨G', hG'mem, hG'sun⟩ := ih F' hw' (by rw [hF'card]; exact hx)
      rw [Finset.mem_powersetCard] at hG'mem
      obtain ⟨hG'F', hG'card⟩ := hG'mem
      have hxnot : ∀ B ∈ G', x ∉ B := by
        intro B hB
        obtain ⟨A, -, rfl⟩ := Finset.mem_image.mp (hG'F' hB)
        exact Finset.notMem_erase x A
      refine ⟨G'.image (insert x), ?_, ?_⟩
      · rw [Finset.mem_powersetCard]
        constructor
        · intro A hA
          obtain ⟨B, hB, rfl⟩ := Finset.mem_image.mp hA
          obtain ⟨A', hA', hA'B⟩ := Finset.mem_image.mp (hG'F' hB)
          rw [Finset.mem_filter] at hA'
          rw [← hA'B, Finset.insert_erase hA'.2]
          exact hA'.1
        · rw [Finset.card_image_of_injOn, hG'card]
          intro B hB C hC hBC
          have := congrArg (fun S : Finset α => S.erase x) hBC
          rwa [Finset.erase_insert (hxnot B hB), Finset.erase_insert (hxnot C hC)] at this
      · intro A hA B hB C hC D hD hAB hCD
        obtain ⟨A', hA', rfl⟩ := Finset.mem_image.mp hA
        obtain ⟨B', hB', rfl⟩ := Finset.mem_image.mp hB
        obtain ⟨C', hC', rfl⟩ := Finset.mem_image.mp hC
        obtain ⟨D', hD', rfl⟩ := Finset.mem_image.mp hD
        have hA'B' : A' ≠ B' := fun h => hAB (h ▸ rfl)
        have hC'D' : C' ≠ D' := fun h => hCD (h ▸ rfl)
        rw [← Finset.insert_inter_distrib, ← Finset.insert_inter_distrib,
          hG'sun A' hA' B' hB' C' hC' D' hD' hA'B' hC'D']

/-- Sunflowers of edges: a family of distinct 2-member sets with no three forming a sunflower
has at most 6 members, so f(2, 3) = 7 (two separate triangles reach 6). -/
theorem sunflower_free_edges_le_six {α : Type*} [DecidableEq α] (F : Finset (Finset α))
    (h2 : ∀ A ∈ F, A.card = 2) (hfree : ∀ G ∈ F.powersetCard 3, ¬ IsSunflower G) :
    F.card ≤ 6 := by
  by_contra h
  push Not at h
  obtain ⟨e, he⟩ : F.Nonempty := Finset.card_pos.mp (by omega)
  have hne : ∀ A ∈ F, A.Nonempty := fun A hA => by
    rw [← Finset.card_pos, h2 A hA]; omega
  have hc1 := card_le_three_add F h2 hfree e he
  set F1 := F.filter (fun f => f ∩ e = ∅) with hF1
  have hF1sub : F1 ⊆ F := Finset.filter_subset _ _
  obtain ⟨f, hf⟩ : F1.Nonempty := Finset.card_pos.mp (by omega)
  have h2' : ∀ A ∈ F1, A.card = 2 := fun A hA => h2 A (hF1sub hA)
  have hfree' : ∀ G ∈ F1.powersetCard 3, ¬ IsSunflower G :=
    fun G hG => hfree G (Finset.powersetCard_mono hF1sub hG)
  have hc2 := card_le_three_add F1 h2' hfree' f hf
  obtain ⟨g, hg⟩ : (F1.filter (fun g => g ∩ f = ∅)).Nonempty := Finset.card_pos.mp (by omega)
  rw [Finset.mem_filter] at hg
  have hfF := Finset.mem_filter.mp hf
  have hgF := Finset.mem_filter.mp hg.1
  have hfe : f ∩ e = ∅ := hfF.2
  have hge : g ∩ e = ∅ := hgF.2
  have hgf : g ∩ f = ∅ := hg.2
  have hneq : ∀ X ∈ F, ∀ Y ∈ F, X ∩ Y = ∅ → X ≠ Y := by
    intro X hX Y _ hXY hEq
    subst hEq
    rw [Finset.inter_self] at hXY
    exact (hne X hX).ne_empty hXY
  have h_fe := hneq f hfF.1 e he hfe
  have h_ge := hneq g hgF.1 e he hge
  have h_gf := hneq g hgF.1 f hfF.1 hgf
  apply hfree {e, f, g}
  · rw [Finset.mem_powersetCard]
    refine ⟨?_, ?_⟩
    · intro X hX
      simp only [Finset.mem_insert, Finset.mem_singleton] at hX
      rcases hX with rfl | rfl | rfl
      · exact he
      · exact hfF.1
      · exact hgF.1
    · rw [Finset.card_insert_of_notMem (by simp [h_fe.symm, h_ge.symm]), Finset.card_pair h_gf.symm]
  · apply isSunflower_of_inter_eq _ ∅
    intro X hX Y hY hXY
    simp only [Finset.mem_insert, Finset.mem_singleton] at hX hY
    rcases hX with rfl | rfl | rfl <;> rcases hY with rfl | rfl | rfl <;>
      first
      | exact absurd rfl hXY
      | assumption
      | rwa [Finset.inter_comm]

/-- Squared distance between two whole-number grid points. -/
def sqDist (p q : ℤ × ℤ) : ℤ := (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2

/-- Squared distance in the triangular lattice, coordinates along two unit vectors 60° apart. -/
def triDist (p q : ℤ × ℤ) : ℤ :=
  (p.1 - q.1) ^ 2 + (p.1 - q.1) * (p.2 - q.2) + (p.2 - q.2) ^ 2

/-- The 3 by 3 grid. -/
def grid3 : Finset (ℤ × ℤ) := Finset.Icc 0 2 ×ˢ Finset.Icc 0 2

/-- The hexagon and its centre, in triangular-lattice coordinates. -/
def hexagon : Finset (ℤ × ℤ) := {(0, 0), (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)}

-- The database's states add up: 570 + 339 + 144 + 104 + 46 + 18 = 1,221, with 46 = 29 + 9 + 8
-- open but finitely checkable and 18 = 9 + 5 + 4 tied to the axioms.
example : 570 + 339 + 144 + 104 + (29 + 9 + 8) + (9 + 5 + 4) = 1221 := by norm_num
-- The 3 by 3 grid: 5 distinct distances, 24 ordered unit pairs, so 12 unit pairs.
example : (grid3.offDiag.image fun p => sqDist p.1 p.2).card = 5 := by decide +kernel
example : (grid3.offDiag.filter fun p => sqDist p.1 p.2 = 1).card = 24 := by decide
-- The hexagon and its centre: 3 distinct distances and 12 unit pairs (24 ordered).
example : (hexagon.offDiag.image fun p => triDist p.1 p.2).card = 3 := by decide
example : (hexagon.offDiag.filter fun p => triDist p.1 p.2 = 1).card = 24 := by decide
-- The 10 by 10 grid makes 50 distinct squared distances a² + b², 0 ≤ a ≤ b ≤ 9, not both 0.
example : (((Finset.range 10 ×ˢ Finset.range 10).filter fun p => p.1 ≤ p.2 ∧ 0 < p.2).image
    fun p => p.1 ^ 2 + p.2 ^ 2).card = 50 := by decide
-- The easy bound for a million points is 707: 2·707² + 707 ≥ 999,999 > 2·706² + 706.
example : 2 * 707 ^ 2 + 707 = 1000405 ∧ 2 * 706 ^ 2 + 706 = 997578 ∧
    2 * 706 ^ 2 + 706 < 1000000 - 1 ∧ 1000000 - 1 ≤ 2 * 707 ^ 2 + 707 := by norm_num
-- Pairs among a million points.
example : 1000000 * (1000000 - 1) / 2 = 499999500000 := by norm_num
-- Fermat's test: 45 = 36 + 9 is a sum of two squares; 21 = 3 · 7 is not.
example : 45 = 6 ^ 2 + 3 ^ 2 ∧ ∀ a ∈ Finset.range 5, ∀ b ∈ Finset.range 5, a ^ 2 + b ^ 2 ≠ 21 := by
  decide
-- The grid's most repeated squared distance: 160,225 = 5² · 13 · 17 · 29.
example : (160225 : ℕ) = 5 ^ 2 * 13 * 17 * 29 := by norm_num
-- n^(4/3) at a million points is 100,000,000: (10^8)^3 = (10^6)^4.
example : ((10 : ℕ) ^ 8) ^ 3 = (10 ^ 6) ^ 4 := by norm_num
-- Erdős–Rado for edges and 3 petals allows up to 2! · 2² = 8.
example : Nat.factorial 2 * (3 - 1) ^ 2 = 8 := by decide
/-- Two separate triangles on 6 points. -/
def twoTriangles : Finset (Finset (Fin 6)) := {{0, 1}, {1, 2}, {0, 2}, {3, 4}, {4, 5}, {3, 5}}

/-- A ring of 8 edges on 8 points. -/
def ring8 : Finset (Finset (Fin 8)) :=
  {{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 6}, {6, 7}, {7, 0}}

-- Two separate triangles: 6 edges, no three of them a sunflower.
example : twoTriangles.card = 6 := by decide +kernel
example : ∀ A ∈ twoTriangles, ∀ B ∈ twoTriangles, ∀ C ∈ twoTriangles,
    A ≠ B → A ≠ C → B ≠ C → ¬ IsSunflower {A, B, C} := by decide +kernel
-- A ring of 8 edges has no three at one point, but three of its edges are disjoint,
-- and three disjoint edges are a sunflower.
example : ring8.card = 8 ∧ ∀ v : Fin 8, (ring8.filter fun e => v ∈ e).card ≤ 2 := by
  decide +kernel
example : ({{0, 1}, {2, 3}, {4, 5}} : Finset (Finset (Fin 8))) ⊆ ring8 ∧
    IsSunflower ({{0, 1}, {2, 3}, {4, 5}} : Finset (Finset (Fin 8))) := by decide +kernel

#print axioms distinct_distances_ge_easy_bound
#print axioms erdos_rado_sunflower
#print axioms sunflower_free_edges_le_six
#print axioms card_le_two_of_dist_eq
#print axioms isSunflower_of_inter_eq
#print axioms pair_inter_eq_singleton
#print axioms star_card_le_two
#print axioms card_le_three_add
