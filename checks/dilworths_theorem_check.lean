-- Dilworth's theorem: in every finite order the fewest chains that hold every item equals the size of the largest antichain, with Mirsky's dual and the Erdos-Szekeres bound.
import Mathlib.Order.Antichain
import Mathlib.Order.Preorder.Chain
import Mathlib.Order.Monotone.Defs
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Powerset
import Mathlib.Order.Lattice.Nat
import Mathlib.Order.SetNotation
import Mathlib.NumberTheory.Divisors
import Mathlib.Order.Preorder.Finite
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Data.Finset.Max
import Mathlib.Data.Set.Monotone
import Mathlib.Order.Interval.Finset.Nat

/-- Helper for Dilworth. If `c` colors a finite set `S` with fewer than `m` colors so that each
color class is a chain, then an antichain `A` of `m` items inside `S` meets every color. -/
theorem dilworth_antichain_meets_every_color {α : Type*} [PartialOrder α] (S A : Finset α)
    (m : ℕ) (c : α → ℕ) (hAS : A ⊆ S) (hA : IsAntichain (· ≤ ·) (A : Set α)) (hcard : A.card = m)
    (hc1 : ∀ x ∈ S, c x < m) (hc2 : ∀ x ∈ S, ∀ y ∈ S, c x = c y → x ≤ y ∨ y ≤ x) :
    ∀ z ∈ S, ∃ a ∈ A, c a = c z := by
  classical
  intro z hz
  have hinj : Set.InjOn c (A : Set α) := by
    intro a ha b hb hab
    by_contra hne
    rcases hc2 a (hAS ha) b (hAS hb) hab with h | h
    · exact hA ha hb hne h
    · exact hA hb ha (Ne.symm hne) h
  have hsub : A.image c ⊆ Finset.range m := by
    intro k hk
    obtain ⟨a, ha, rfl⟩ := Finset.mem_image.1 hk
    exact Finset.mem_range.2 (hc1 a (hAS ha))
  have heq : A.image c = Finset.range m :=
    Finset.eq_of_subset_of_card_le hsub
      (by rw [Finset.card_image_of_injOn hinj, hcard, Finset.card_range])
  have hz' : c z ∈ A.image c := heq ▸ Finset.mem_range.2 (hc1 z hz)
  simpa using hz'

/-- Helper for Dilworth, the induction. If no antichain inside the finite set `s` has more than
`m` items, then `s` can be colored with the colors `0, ..., m - 1` so that each color class is a
chain. -/
theorem dilworth_chain_coloring {α : Type*} [PartialOrder α] (s : Finset α) :
    ∀ m : ℕ, (∀ A ⊆ s, IsAntichain (· ≤ ·) (A : Set α) → A.card ≤ m) →
      ∃ c : α → ℕ, (∀ x ∈ s, c x < m) ∧ ∀ x ∈ s, ∀ y ∈ s, c x = c y → x ≤ y ∨ y ≤ x := by
  classical
  induction s using Finset.strongInduction with
  | H s ih =>
  intro m hm
  rcases s.eq_empty_or_nonempty with rfl | ⟨y0, hy0⟩
  · exact ⟨fun _ => 0, by simp, by simp⟩
  -- a top item `y` and a bottom item `x ≤ y`
  obtain ⟨y, -, hymax⟩ := s.exists_le_maximal hy0
  have hys : y ∈ s := hymax.1
  obtain ⟨x, hxy, hxmin⟩ :=
    (s.filter (· ≤ y)).exists_le_minimal (a := y) (Finset.mem_filter.2 ⟨hys, le_rfl⟩)
  have hxs : x ∈ s := (Finset.mem_filter.1 hxmin.1).1
  have hxmin' : ∀ z ∈ s, z ≤ x → x ≤ z := fun z hz hzx =>
    hxmin.2 (Finset.mem_filter.2 ⟨hz, hzx.trans hxy⟩) hzx
  have hm1 : 1 ≤ m := by
    have := hm {y} (by simpa using hys) (by simp)
    simpa using this
  set t := (s.erase x).erase y with ht
  have hts : t ⊂ s := by
    refine Finset.ssubset_iff_subset_ne.2 ⟨fun z hz => ?_, fun h => ?_⟩
    · simp only [ht, Finset.mem_erase] at hz
      exact hz.2.2
    · have : y ∈ t := h ▸ hys
      simp [ht] at this
  by_cases hcase : ∀ A ⊆ t, IsAntichain (· ≤ ·) (A : Set α) → A.card ≤ m - 1
  · -- the rest needs only `m - 1` chains; the chain `x ≤ y` takes the last color
    obtain ⟨c, hc1, hc2⟩ := ih t hts (m - 1) hcase
    refine ⟨fun z => if z ∈ t then c z else m - 1, ?_, ?_⟩
    · intro z hz
      by_cases hzt : z ∈ t
      · simp only [hzt, ite_true]; have := hc1 z hzt; omega
      · simp only [hzt, ite_false]; omega
    · have hxy' : ∀ z ∈ s, z ∉ t → z = x ∨ z = y := by
        intro z hz hzt
        by_contra h
        push Not at h
        exact hzt (by simp [ht, h.1, h.2, hz])
      intro z1 hz1 z2 hz2 h
      by_cases h1 : z1 ∈ t <;> by_cases h2 : z2 ∈ t <;> simp only [h1, h2, ite_true, ite_false] at h
      · exact hc2 z1 h1 z2 h2 h
      · have := hc1 z1 h1; omega
      · have := hc1 z2 h2; omega
      · rcases hxy' z1 hz1 h1 with rfl | rfl <;> rcases hxy' z2 hz2 h2 with rfl | rfl <;> simp [hxy]
  · -- an antichain `A` of `m` items avoiding `x` and `y`: split into the items below and above it
    push Not at hcase
    obtain ⟨A, hAt, hA, hAcard⟩ := hcase
    have hAs : A ⊆ s := hAt.trans hts.subset
    have hAm : A.card = m := le_antisymm (hm A hAs hA) (by omega)
    set D := s.filter (fun z => ∃ a ∈ A, z ≤ a) with hD
    set U := s.filter (fun z => ∃ a ∈ A, a ≤ z) with hU
    have hyA : y ∉ A := fun h => by have := hAt h; simp [ht] at this
    have hxA : x ∉ A := fun h => by have := hAt h; simp [ht] at this
    have hDs : D ⊂ s := by
      refine Finset.ssubset_iff_subset_ne.2 ⟨Finset.filter_subset _ _, fun h => ?_⟩
      have : y ∈ D := h ▸ hys
      obtain ⟨-, a, ha, hya⟩ := Finset.mem_filter.1 this
      have : a = y := le_antisymm (hymax.2 (hAs ha) hya) hya
      exact hyA (this ▸ ha)
    have hUs : U ⊂ s := by
      refine Finset.ssubset_iff_subset_ne.2 ⟨Finset.filter_subset _ _, fun h => ?_⟩
      have : x ∈ U := h ▸ hxs
      obtain ⟨-, a, ha, hax⟩ := Finset.mem_filter.1 this
      have : x = a := le_antisymm (hxmin' a (hAs ha) hax) hax
      exact hxA (this ▸ ha)
    have hAD : A ⊆ D := fun a ha => Finset.mem_filter.2 ⟨hAs ha, a, ha, le_rfl⟩
    have hAU : A ⊆ U := fun a ha => Finset.mem_filter.2 ⟨hAs ha, a, ha, le_rfl⟩
    have hcover : ∀ z ∈ s, z ∈ D ∨ z ∈ U := by
      intro z hz
      by_contra h
      push Not at h
      have hzD : ∀ a ∈ A, ¬ z ≤ a := fun a ha hza => h.1 (Finset.mem_filter.2 ⟨hz, a, ha, hza⟩)
      have hzU : ∀ a ∈ A, ¬ a ≤ z := fun a ha haz => h.2 (Finset.mem_filter.2 ⟨hz, a, ha, haz⟩)
      have hzA : z ∉ A := fun hzA => hzD z hzA le_rfl
      have hanti : IsAntichain (· ≤ ·) ((insert z A : Finset α) : Set α) := by
        rw [Finset.coe_insert]
        exact hA.insert (fun b hb _ => hzU b hb) (fun b hb _ => hzD b hb)
      have := hm (insert z A) (Finset.insert_subset hz hAs) hanti
      rw [Finset.card_insert_of_notMem hzA] at this
      omega
    obtain ⟨c1, hc1, hc1'⟩ := ih D hDs m (fun B hB hB' => hm B (hB.trans hDs.subset) hB')
    obtain ⟨c2, hc2, hc2'⟩ := ih U hUs m (fun B hB hB' => hm B (hB.trans hUs.subset) hB')
    have hDle : ∀ z ∈ D, ∀ a ∈ A, c1 a = c1 z → z ≤ a := by
      intro z hz a ha hca
      obtain ⟨-, a', ha', hza'⟩ := Finset.mem_filter.1 hz
      rcases hc1' z hz a (hAD ha) hca.symm with h | h
      · exact h
      · by_cases haa : a = a'
        · exact haa ▸ hza'
        · exact absurd (h.trans hza') (hA ha ha' haa)
    have hUle : ∀ z ∈ U, ∀ a ∈ A, c2 a = c2 z → a ≤ z := by
      intro z hz a ha hca
      obtain ⟨-, a', ha', ha'z⟩ := Finset.mem_filter.1 hz
      rcases hc2' z hz a (hAU ha) hca.symm with h | h
      · by_cases haa : a' = a
        · exact haa ▸ ha'z
        · exact absurd (ha'z.trans h) (hA ha' ha haa)
      · exact h
    have hAinj : ∀ a ∈ A, ∀ b ∈ A, c1 a = c1 b → a = b := by
      intro a ha b hb hab
      by_contra hne
      rcases hc1' a (hAD ha) b (hAD hb) hab with h | h
      · exact hA ha hb hne h
      · exact hA hb ha (Ne.symm hne) h
    have hsurj := dilworth_antichain_meets_every_color U A m c2 hAU hA hAm hc2 hc2'
    choose! g hgA hg using hsurj
    refine ⟨fun z => if z ∈ D then c1 z else c1 (g z), ?_, ?_⟩
    · intro z hz
      by_cases hzD : z ∈ D
      · simp only [hzD, ite_true]; exact hc1 z hzD
      · have hzU : z ∈ U := (hcover z hz).resolve_left hzD
        simp only [hzD, ite_false]; exact hc1 _ (hAD (hgA z hzU))
    · intro z1 hz1 z2 hz2 h
      by_cases h1 : z1 ∈ D <;> by_cases h2 : z2 ∈ D <;> simp only [h1, h2, ite_true, ite_false] at h
      · exact hc1' z1 h1 z2 h2 h
      · have hz2U : z2 ∈ U := (hcover z2 hz2).resolve_left h2
        exact Or.inl ((hDle z1 h1 _ (hgA z2 hz2U) h.symm).trans
          (hUle z2 hz2U _ (hgA z2 hz2U) (hg z2 hz2U)))
      · have hz1U : z1 ∈ U := (hcover z1 hz1).resolve_left h1
        exact Or.inr ((hDle z2 h2 _ (hgA z1 hz1U) h).trans
          (hUle z1 hz1U _ (hgA z1 hz1U) (hg z1 hz1U)))
      · have hz1U : z1 ∈ U := (hcover z1 hz1).resolve_left h1
        have hz2U : z2 ∈ U := (hcover z2 hz2).resolve_left h2
        have hgg := hAinj _ (hgA z1 hz1U) _ (hgA z2 hz2U) h
        refine hc2' z1 hz1U z2 hz2U ?_
        rw [← hg z1 hz1U, ← hg z2 hz2U, hgg]

/-- Helper for Mirsky: the height of `x`, the most items in a chain whose items all lie at or
below `x`. -/
noncomputable def mirskyHeight {α : Type*} [PartialOrder α] [Fintype α] (x : α) : ℕ :=
  open scoped Classical in
  (Finset.univ.filter (fun C : Finset α => IsChain (· ≤ ·) (C : Set α) ∧ ∀ y ∈ C, y ≤ x)).sup
    Finset.card

/-- Helper for Mirsky: the height of `x` is at least 1, since `{x}` is a chain. -/
theorem mirskyHeight_pos {α : Type*} [PartialOrder α] [Fintype α] (x : α) :
    1 ≤ mirskyHeight x := by
  classical
  unfold mirskyHeight
  have hx : ({x} : Finset α) ∈ Finset.univ.filter
      (fun C : Finset α => IsChain (· ≤ ·) (C : Set α) ∧ ∀ y ∈ C, y ≤ x) :=
    Finset.mem_filter.2 ⟨Finset.mem_univ _, by simp, by simp⟩
  have := Finset.le_sup (f := Finset.card) hx
  simpa using this

/-- Helper for Mirsky: the height rises strictly along `<`. -/
theorem mirskyHeight_lt {α : Type*} [PartialOrder α] [Fintype α] {x y : α} (hxy : x < y) :
    mirskyHeight x < mirskyHeight y := by
  classical
  unfold mirskyHeight
  set F := fun z : α => Finset.univ.filter
      (fun C : Finset α => IsChain (· ≤ ·) (C : Set α) ∧ ∀ w ∈ C, w ≤ z) with hF
  have hne : (F x).Nonempty := ⟨∅, by simp [hF]⟩
  obtain ⟨C, hC, hCeq⟩ := Finset.exists_mem_eq_sup (F x) hne Finset.card
  simp only [hF, Finset.mem_filter, Finset.mem_univ, true_and] at hC
  have hyC : y ∉ C := fun hy => absurd (hC.2 y hy) (not_le_of_gt hxy)
  have hins : insert y C ∈ F y := by
    simp only [hF, Finset.mem_filter, Finset.mem_univ, true_and, Finset.coe_insert,
      Finset.mem_insert, forall_eq_or_imp, le_rfl]
    refine ⟨hC.1.insert fun b hb _ => Or.inr ((hC.2 b hb).trans hxy.le), fun w hw =>
      (hC.2 w hw).trans hxy.le⟩
  have := Finset.le_sup (f := Finset.card) hins
  rw [Finset.card_insert_of_notMem hyC] at this
  have hsx : (F x).sup Finset.card = C.card := hCeq
  simp only [hF] at hsx this ⊢
  omega

/-- Helper for Erdos-Szekeres: the possible lengths of a rising run that ends at place `i`. -/
noncomputable def esRunsTo {ι β : Type*} [Fintype ι] [LinearOrder ι] [LinearOrder β]
    (f : ι → β) (i : ι) : Finset ℕ :=
  open scoped Classical in
  Finset.image Finset.card {t : Finset ι | IsGreatest (t : Set ι) i ∧ StrictMonoOn f t}

/-- Helper for Erdos-Szekeres: the longest rising run that ends at place `i`. -/
noncomputable def esLongestTo {ι β : Type*} [Fintype ι] [LinearOrder ι] [LinearOrder β]
    (f : ι → β) (i : ι) : ℕ :=
  (esRunsTo f i).max' ⟨1, Finset.mem_image.2 ⟨{i}, by simp⟩⟩

/-- Helper for Erdos-Szekeres (after Bhavik Mehta's proof in Mathlib's archive): if `i < j` and
`f i < f j`, a longest rising run ending at `i` grows by `j`, so the longest run ending at `j` is
longer. -/
theorem esLongestTo_lt {ι β : Type*} [Fintype ι] [LinearOrder ι] [LinearOrder β] {f : ι → β}
    {i j : ι} (hij : i < j) (hfij : f i < f j) : esLongestTo f i < esLongestTo f j := by
  classical
  rw [Nat.lt_iff_add_one_le]
  refine Finset.le_max' _ _ ?_
  have : esLongestTo f i ∈ esRunsTo f i := Finset.max'_mem _ _
  simp only [esRunsTo, Finset.mem_image, Finset.mem_filter, Finset.mem_univ, true_and,
    and_assoc] at this
  obtain ⟨t, hti, ht₁, ht₂⟩ := this
  simp only [esRunsTo, Finset.mem_image, Finset.mem_filter, Finset.mem_univ, true_and, and_assoc]
  have hlt : ∀ x ∈ t, x < j := fun x hx => (hti.2 hx).trans_lt hij
  refine ⟨insert j t, ?_, ?_, ?_⟩
  · convert hti.insert j
    · simp
    · rw [max_eq_left hij.le]
  · simp only [Finset.coe_insert]
    rw [strictMonoOn_insert_iff_of_forall_le]
    · exact ⟨fun x hx _ => (ht₁.monotoneOn hx hti.1 (hti.2 hx)).trans_lt hfij, ht₁⟩
    · exact fun x hx => (hlt x hx).le
  · have : j ∉ t := fun hj => lt_irrefl _ (hlt _ hj)
    simp [this, ht₂]

#print axioms dilworth_antichain_meets_every_color
#print axioms dilworth_chain_coloring
#print axioms mirskyHeight_pos
#print axioms mirskyHeight_lt
#print axioms esLongestTo_lt

/-- Dilworth's theorem. In a finite order, the fewest chains `C 0, ..., C (k - 1)` whose union is
every item equals the largest number of items in an antichain (a set no two of whose items
compare). -/
theorem dilworth_min_chain_cover_eq_max_antichain (α : Type*) [PartialOrder α] [Fintype α] :
    sInf {k : ℕ | ∃ C : Fin k → Set α,
        (∀ i, IsChain (· ≤ ·) (C i)) ∧ (⋃ i, C i) = Set.univ} =
      sSup {m : ℕ | ∃ A : Finset α, IsAntichain (· ≤ ·) (A : Set α) ∧ A.card = m} := by
  classical
  set S := {m : ℕ | ∃ A : Finset α, IsAntichain (· ≤ ·) (A : Set α) ∧ A.card = m} with hS
  have hbdd : BddAbove S := ⟨Fintype.card α, by rintro _ ⟨A, -, rfl⟩; exact A.card_le_univ⟩
  have hSne : S.Nonempty := ⟨0, ∅, by simp⟩
  -- `sSup S` chains suffice: color the items, one chain per color
  have hmem : sSup S ∈ {k : ℕ | ∃ C : Fin k → Set α,
      (∀ i, IsChain (· ≤ ·) (C i)) ∧ (⋃ i, C i) = Set.univ} := by
    obtain ⟨c, hc1, hc2⟩ := dilworth_chain_coloring (Finset.univ : Finset α) (sSup S)
      (fun A _ hA => le_csSup hbdd ⟨A, hA, rfl⟩)
    refine ⟨fun i => {x | c x = i}, fun i x hx y hy _ => ?_, ?_⟩
    · exact hc2 x (Finset.mem_univ _) y (Finset.mem_univ _) (hx.trans hy.symm)
    · ext x
      simp only [Set.mem_iUnion, Set.mem_ofPred_eq, Set.mem_univ, iff_true]
      exact ⟨⟨c x, hc1 x (Finset.mem_univ _)⟩, rfl⟩
  refine le_antisymm (Nat.sInf_le hmem) (le_csInf ⟨_, hmem⟩ ?_)
  -- no fewer chains: each chain holds at most one item of an antichain
  rintro k ⟨C, hC, hU⟩
  refine csSup_le hSne ?_
  rintro _ ⟨A, hA, rfl⟩
  have hin : ∀ a : α, ∃ i, a ∈ C i := fun a => Set.mem_iUnion.1 (hU ▸ Set.mem_univ a)
  choose idx hidx using hin
  have hinj : Set.InjOn idx (A : Set α) := by
    intro a ha b hb hab
    by_contra hne
    have hb' : b ∈ C (idx a) := by rw [hab]; exact hidx b
    rcases hC (idx a) (hidx a) hb' hne with h | h
    · exact hA ha hb hne h
    · exact hA hb ha (Ne.symm hne) h
  simpa using Finset.card_le_card_of_injOn idx (t := Finset.univ)
    (fun _ _ => Finset.mem_coe.2 (Finset.mem_univ _)) hinj

/-- Mirsky's theorem, the mirror image. In a finite order, the most items in one chain equals
the fewest antichains whose union is every item. -/
theorem mirsky_max_chain_eq_min_antichain_cover (α : Type*) [PartialOrder α] [Fintype α] :
    sSup {m : ℕ | ∃ C : Finset α, IsChain (· ≤ ·) (C : Set α) ∧ C.card = m} =
      sInf {k : ℕ | ∃ A : Fin k → Set α,
        (∀ i, IsAntichain (· ≤ ·) (A i)) ∧ (⋃ i, A i) = Set.univ} := by
  classical
  set S := {m : ℕ | ∃ C : Finset α, IsChain (· ≤ ·) (C : Set α) ∧ C.card = m} with hS
  have hbdd : BddAbove S := ⟨Fintype.card α, by rintro _ ⟨C, -, rfl⟩; exact C.card_le_univ⟩
  have hSne : S.Nonempty := ⟨0, ∅, by simp⟩
  have hle : ∀ x : α, mirskyHeight x ≤ sSup S := fun x =>
    Finset.sup_le fun C hC => le_csSup hbdd ⟨C, (Finset.mem_filter.1 hC).2.1, rfl⟩
  -- `sSup S` antichains suffice: layer `i` holds the items of height `i + 1`
  have hmem : sSup S ∈ {k : ℕ | ∃ A : Fin k → Set α,
      (∀ i, IsAntichain (· ≤ ·) (A i)) ∧ (⋃ i, A i) = Set.univ} := by
    refine ⟨fun i => {x | mirskyHeight x = i.val + 1}, fun i x hx y hy hxy hle' => ?_, ?_⟩
    · have := mirskyHeight_lt (lt_of_le_of_ne hle' hxy)
      simp only [Set.mem_ofPred_eq] at hx hy
      omega
    · ext x
      simp only [Set.mem_iUnion, Set.mem_ofPred_eq, Set.mem_univ, iff_true]
      have h1 := mirskyHeight_pos x
      have h2 := hle x
      exact ⟨⟨mirskyHeight x - 1, by omega⟩, by simp only; omega⟩
  refine le_antisymm (le_csInf ⟨_, hmem⟩ ?_) (Nat.sInf_le hmem)
  -- no fewer antichains: each antichain holds at most one item of a chain
  rintro k ⟨A, hA, hU⟩
  refine csSup_le hSne ?_
  rintro _ ⟨C, hC, rfl⟩
  have hin : ∀ a : α, ∃ i, a ∈ A i := fun a => Set.mem_iUnion.1 (hU ▸ Set.mem_univ a)
  choose idx hidx using hin
  have hinj : Set.InjOn idx (C : Set α) := by
    intro a ha b hb hab
    by_contra hne
    have hb' : b ∈ A (idx a) := by rw [hab]; exact hidx b
    rcases hC ha hb hne with h | h
    · exact hA (idx a) (hidx a) hb' hne h
    · exact hA (idx a) hb' (hidx a) (Ne.symm hne) h
  simpa using Finset.card_le_card_of_injOn idx (t := Finset.univ)
    (fun _ _ => Finset.mem_coe.2 (Finset.mem_univ _)) hinj

/-- The Erdos-Szekeres bound, as a corollary. For a list of `n` different numbers, if no rising
run (items picked in order, each larger than the one before) has more than `r` items and no
falling run has more than `s` items, then `n ≤ s * r`. -/
theorem erdos_szekeres_length_le_falling_mul_rising {α : Type*} [LinearOrder α] {n : ℕ}
    (f : Fin n → α) (hf : Function.Injective f) (r s : ℕ)
    (hr : ∀ t : Finset (Fin n), StrictMonoOn f (t : Set (Fin n)) → t.card ≤ r)
    (hs : ∀ t : Finset (Fin n), StrictAntiOn f (t : Set (Fin n)) → t.card ≤ s) :
    n ≤ s * r := by
  classical
  by_contra hlt
  push Not at hlt
  -- label place `i` by the longest rising run and the longest falling run ending there
  let g : Fin n → αᵒᵈ := fun i => OrderDual.toDual (f i)
  let p : Fin n → ℕ × ℕ := fun i => (esLongestTo f i, esLongestTo g i)
  have hp : Function.Injective p := by
    apply Function.Injective.of_lt_imp_ne
    intro i j hij q
    rcases lt_or_gt_of_ne (hf.ne hij.ne) with h | h
    · exact (esLongestTo_lt hij h).ne congr($q.1)
    · exact (esLongestTo_lt (f := g) hij h).ne congr($q.2)
  have hmaps : Set.MapsTo p (Finset.univ : Finset (Fin n))
      (Finset.Icc 1 r ×ˢ Finset.Icc 1 s : Finset (ℕ × ℕ)) := by
    intro i _
    have hf1 : esLongestTo f i ∈ esRunsTo f i := Finset.max'_mem _ _
    have hg1 : esLongestTo g i ∈ esRunsTo g i := Finset.max'_mem _ _
    have hf0 : 1 ≤ esLongestTo f i := Finset.le_max' _ 1 (Finset.mem_image.2 ⟨{i}, by simp⟩)
    have hg0 : 1 ≤ esLongestTo g i := Finset.le_max' _ 1 (Finset.mem_image.2 ⟨{i}, by simp⟩)
    simp only [esRunsTo, Finset.mem_image, Finset.mem_filter, Finset.mem_univ, true_and]
      at hf1 hg1
    obtain ⟨t, ht, htc⟩ := hf1
    obtain ⟨u, hu, huc⟩ := hg1
    have h1 := hr t ht.2
    have h2 := hs u (fun a ha b hb hab => hu.2 ha hb hab)
    simp only [p, Finset.coe_product, Set.mem_prod, Finset.coe_Icc, Set.mem_Icc]
    omega
  have := Finset.card_le_card_of_injOn p hmaps hp.injOn
  simp only [Finset.card_univ, Fintype.card_fin, Finset.card_product, Nat.card_Icc,
    Nat.add_sub_cancel] at this
  rw [Nat.mul_comm] at hlt
  omega

/-! The card's example: the divisors of 12 under "divides". -/

-- The six items.
example : Nat.divisors 12 = {1, 2, 3, 4, 6, 12} := by decide

-- 12 comparable pairs, the 12 lines of the two-sided graph.
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 ≠ p.2 ∧ p.1 ∣ p.2)).card = 12 := by decide

-- Two chains, 1 | 2 | 4 | 12 and 3 | 6, hold all six items.
example : ∀ a ∈ ({1, 2, 4, 12} : Finset ℕ), ∀ b ∈ ({1, 2, 4, 12} : Finset ℕ), a ∣ b ∨ b ∣ a := by
  decide
example : ∀ a ∈ ({3, 6} : Finset ℕ), ∀ b ∈ ({3, 6} : Finset ℕ), a ∣ b ∨ b ∣ a := by decide
example : ({1, 2, 4, 12} : Finset ℕ) ∪ {3, 6} = Nat.divisors 12 := by decide

-- 4 and 6 form an antichain, as do 2 and 3, and 3 and 4.
example : ¬ 4 ∣ 6 ∧ ¬ 6 ∣ 4 := by decide
example : ¬ 2 ∣ 3 ∧ ¬ 3 ∣ 2 := by decide
example : ¬ 3 ∣ 4 ∧ ¬ 4 ∣ 3 := by decide

-- No antichain has 3 items: every 3 divisors contain a pair where one divides the other.
example : ∀ t ∈ (Nat.divisors 12).powerset, t.card = 3 →
    ∃ a ∈ t, ∃ b ∈ t, a ≠ b ∧ a ∣ b := by decide

-- One chain cannot hold all six: 4 and 6 do not compare.
example : ¬ ∀ a ∈ Nat.divisors 12, ∀ b ∈ Nat.divisors 12, a ∣ b ∨ b ∣ a := by decide

-- Mirsky's layers {1}, {2, 3}, {4, 6}, {12}: 4 antichains, matching the longest chain 1, 2, 4, 12.
example : ({1} : Finset ℕ) ∪ {2, 3} ∪ {4, 6} ∪ {12} = Nat.divisors 12 := by decide

/-! The prices of Step 5, in cents. -/

-- The falling run on days 3, 5, 7.
example : (4460 : ℕ) > 4395 ∧ (4395 : ℕ) > 4288 := by decide

-- The three rising runs: days 1, 5, 10; days 2, 3, 6, 9; days 4, 7, 8.
example : (4320 : ℕ) < 4395 ∧ (4395 : ℕ) < 4570 := by decide
example : (4210 : ℕ) < 4460 ∧ (4460 : ℕ) < 4630 ∧ (4630 : ℕ) < 4705 := by decide
example : (4165 : ℕ) < 4288 ∧ (4288 : ℕ) < 4515 := by decide

-- The 16 subsets of {1, 2, 3, 4}: the two-element subsets number 6.
example : ((Finset.univ : Finset (Fin 4)).powerset.filter (fun t => t.card = 2)).card = 6 := by
  decide

#print axioms dilworth_min_chain_cover_eq_max_antichain
#print axioms mirsky_max_chain_eq_min_antichain_cover
#print axioms erdos_szekeres_length_le_falling_mul_rising
