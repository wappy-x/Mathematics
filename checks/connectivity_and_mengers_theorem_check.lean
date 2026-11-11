-- How many cuts break a network: in every finite network the most routes between two stations that share no line equals the fewest lines whose closure separates them, the same holds for stations when the two are not joined by a line, a line is a bridge exactly when it lies on no loop, and the card's eight-station railway numbers check out.
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Finite
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Combinatorics.SimpleGraph.DeleteEdges
import Mathlib.Combinatorics.SimpleGraph.Paths
import Mathlib

namespace ConnectivityAndMengersTheorem

open SimpleGraph

/-! ### Helper lemmas for the proofs below -/

section Helpers

variable {V : Type*}

def R (H : SimpleGraph V) (S : Set V) : V → V → Prop :=
  Relation.ReflTransGen (fun u v => H.Adj u v ∧ u ∈ S ∧ v ∈ S)

def Link (H : SimpleGraph V) (A B S : Set V) : Prop :=
  ∃ a ∈ A, ∃ b ∈ B, a ∈ S ∧ b ∈ S ∧ R H S a b

theorem R_symm {H : SimpleGraph V} {S : Set V} {a b : V} (h : R H S a b) : R H S b a := by
  induction h with
  | refl => exact Relation.ReflTransGen.refl
  | tail _ hst ih => exact Relation.ReflTransGen.head ⟨hst.1.symm, hst.2.2, hst.2.1⟩ ih

theorem R_mono {H K : SimpleGraph V} {S T : Set V}
    (hHK : ∀ u v, u ∈ S → v ∈ S → H.Adj u v → K.Adj u v) (hST : S ⊆ T) {a b : V}
    (h : R H S a b) : R K T a b := by
  induction h with
  | refl => exact Relation.ReflTransGen.refl
  | tail _ hst ih => exact ih.tail ⟨hHK _ _ hst.2.1 hst.2.2 hst.1, hST hst.2.1, hST hst.2.2⟩

theorem R_mem {H : SimpleGraph V} {S : Set V} {a b : V} (h : R H S a b) (ha : a ∈ S) : b ∈ S := by
  induction h with
  | refl => exact ha
  | tail _ hs _ => exact hs.2.2

theorem Link_symm {H : SimpleGraph V} {A B S : Set V} (h : Link H A B S) : Link H B A S := by
  obtain ⟨a, ha, b, hb, haS, hbS, h⟩ := h
  exact ⟨b, hb, a, ha, hbS, haS, R_symm h⟩

theorem Link_mono_graph {H K : SimpleGraph V} (hHK : H ≤ K) {A B S : Set V} (h : Link H A B S) :
    Link K A B S := by
  obtain ⟨a, ha, b, hb, haS, hbS, h⟩ := h
  exact ⟨a, ha, b, hb, haS, hbS, R_mono (fun _ _ _ _ h => hHK h) subset_rfl h⟩

theorem first_hit {H : SimpleGraph V} {S X : Set V} {a b : V} (h : R H S a b) (haX : a ∉ X) :
    (b ∉ X ∧ R H (S ∩ Xᶜ) a b) ∨
      ∃ u z, u ∈ S ∧ u ∉ X ∧ z ∈ S ∧ z ∈ X ∧ H.Adj u z ∧ R H (S ∩ Xᶜ) a u := by
  induction h with
  | refl => exact Or.inl ⟨haX, Relation.ReflTransGen.refl⟩
  | @tail c d _ hcd ih =>
    rcases ih with ⟨hcX, hR⟩ | hex
    · by_cases hdX : d ∈ X
      · exact Or.inr ⟨c, d, hcd.2.1, hcX, hcd.2.2, hdX, hcd.1, hR⟩
      · exact Or.inl ⟨hdX, hR.tail ⟨hcd.1, ⟨hcd.2.1, hcX⟩, ⟨hcd.2.2, hdX⟩⟩⟩
    · exact Or.inr hex

theorem R_reached {H : SimpleGraph V} {T : Set V} {a v : V} (h : R H T a v) :
    R H {w | w ∈ T ∧ R H T a w} a v := by
  induction h with
  | refl => exact Relation.ReflTransGen.refl
  | @tail c d hac hcd ih => exact ih.tail ⟨hcd.1, ⟨hcd.2.1, hac⟩, ⟨hcd.2.2, hac.tail hcd⟩⟩

theorem trim {H : SimpleGraph V} {A X S : Set V} (hS : Link H A X S) :
    ∃ S' ⊆ S, ∃ x ∈ X, x ∈ S' ∧ (∀ v ∈ S', v ∈ X → v = x) ∧ (∃ a ∈ A, a ∈ S' ∧ R H S' a x) ∧
      (∀ v ∈ S', v ∉ X → ∃ a ∈ A, a ∉ X ∧ R H Xᶜ a v) := by
  obtain ⟨a, ha, b, hb, haS, hbS, hR⟩ := hS
  by_cases haX : a ∈ X
  · refine ⟨{a}, by simpa using haS, a, haX, rfl, fun v hv _ => hv,
      ⟨a, ha, rfl, Relation.ReflTransGen.refl⟩, ?_⟩
    intro v hv hvX
    rw [Set.mem_singleton_iff] at hv
    subst hv
    exact absurd haX hvX
  rcases first_hit hR haX with ⟨hbX, _⟩ | ⟨u, z, huS, huX, hzS, hzX, huz, hau⟩
  · exact absurd hb hbX
  let C : Set V := {w | w ∈ S ∩ Xᶜ ∧ R H (S ∩ Xᶜ) a w}
  have hCsub : C ⊆ S := fun w hw => hw.1.1
  refine ⟨insert z C, Set.insert_subset hzS hCsub, z, hzX, Set.mem_insert _ _, ?_,
    ⟨a, ha, Or.inr ⟨⟨haS, haX⟩, Relation.ReflTransGen.refl⟩, ?_⟩, ?_⟩
  · rintro v (rfl | hv) hvX
    · rfl
    · exact absurd hvX hv.1.2
  · have h1 : R H C a u := R_reached hau
    have h2 : R H (insert z C) a u := R_mono (fun _ _ _ _ h => h) (Set.subset_insert _ _) h1
    exact h2.tail ⟨huz, Or.inr ⟨⟨huS, huX⟩, hau⟩, Set.mem_insert _ _⟩
  · rintro v (rfl | hv) hvX
    · exact absurd hzX hvX
    · exact ⟨a, ha, haX, R_mono (fun _ _ _ _ h => h) Set.inter_subset_right hv.2⟩

theorem combine {H : SimpleGraph V} {A B : Set V} {X : Finset V} {k : ℕ} (hk : X.card = k)
    (hsep : ¬ Link H A B (↑X)ᶜ)
    (S : Fin k → Set V) (hS : ∀ i, Link H A ↑X (S i))
    (hSd : Pairwise fun i j => Disjoint (S i) (S j))
    (T : Fin k → Set V) (hT : ∀ i, Link H ↑X B (T i))
    (hTd : Pairwise fun i j => Disjoint (T i) (T j)) :
    ∃ U : Fin k → Set V, (∀ i, Link H A B (U i)) ∧ Pairwise fun i j => Disjoint (U i) (U j) := by
  choose S' hS'sub x hxX hxS' hxu hSa hSr using fun i => trim (hS i)
  choose T' hT'sub y hyX hyT' hyu hTb hTr using fun i => trim (Link_symm (hT i))
  have hxinj : Function.Injective x := by
    intro i j hij
    by_contra hne
    exact Set.disjoint_left.mp (hSd hne) (hS'sub i (hxS' i)) (hij ▸ hS'sub j (hxS' j))
  have hyinj : Function.Injective y := by
    intro i j hij
    by_contra hne
    exact Set.disjoint_left.mp (hTd hne) (hT'sub i (hyT' i)) (hij ▸ hT'sub j (hyT' j))
  classical
  have hysurj : ∀ z ∈ X, ∃ j, y j = z := by
    have hsub : Finset.univ.image y ⊆ X := by
      intro z hz
      simp only [Finset.mem_image, Finset.mem_univ, true_and] at hz
      obtain ⟨j, rfl⟩ := hz
      exact hyX j
    have heq : Finset.univ.image y = X := Finset.eq_of_subset_of_card_le hsub
      (by rw [Finset.card_image_of_injective _ hyinj, hk]; simp)
    intro z hz
    rw [← heq] at hz
    simpa using hz
  choose σ hσ using fun i => hysurj (x i) (hxX i)
  have cross : ∀ i j v, v ∈ S' i → v ∈ T' (σ j) → i = j := by
    intro i j v hvS hvT
    by_cases hvX : v ∈ (X : Set V)
    · have h1 := hxu i v hvS hvX
      have h2 := hyu (σ j) v hvT hvX
      apply hxinj
      rw [← h1, ← hσ j, h2]
    · exfalso
      obtain ⟨a, ha, haX, hav⟩ := hSr i v hvS hvX
      obtain ⟨b, hb, hbX, hbv⟩ := hTr (σ j) v hvT hvX
      exact hsep ⟨a, ha, b, hb, haX, hbX, Relation.ReflTransGen.trans hav (R_symm hbv)⟩
  refine ⟨fun i => S' i ∪ T' (σ i), ?_, ?_⟩
  · intro i
    obtain ⟨a, ha, haS, har⟩ := hSa i
    obtain ⟨b, hb, hbT, hbr⟩ := hTb (σ i)
    refine ⟨a, ha, b, hb, Or.inl haS, Or.inr hbT, ?_⟩
    have h1 : R H (S' i ∪ T' (σ i)) a (x i) :=
      R_mono (fun _ _ _ _ h => h) Set.subset_union_left har
    have h2 : R H (S' i ∪ T' (σ i)) b (y (σ i)) :=
      R_mono (fun _ _ _ _ h => h) Set.subset_union_right hbr
    rw [hσ i] at h2
    exact Relation.ReflTransGen.trans h1 (R_symm h2)
  · intro i j hij
    show Disjoint _ _
    rw [Set.disjoint_left]
    rintro v (hv | hv) (hw | hw)
    · exact Set.disjoint_left.mp (hSd hij) (hS'sub i hv) (hS'sub j hw)
    · exact hij (cross i j v hv hw)
    · exact hij (cross j i v hw hv).symm
    · have : σ i ≠ σ j := fun h => hij (hxinj (by rw [← hσ i, ← hσ j, h]))
      exact Set.disjoint_left.mp (hTd this) (hT'sub _ hv) (hT'sub _ hw)

theorem base_case [Fintype V] {G : SimpleGraph V} (hG : ∀ u v, ¬ G.Adj u v) (A B : Set V) (k : ℕ)
    (hk : ∀ X : Finset V, ¬ Link G A B (↑X)ᶜ → k ≤ X.card) :
    ∃ S : Fin k → Set V, (∀ i, Link G A B (S i)) ∧ Pairwise fun i j => Disjoint (S i) (S j) := by
  classical
  have hR : ∀ S a b, R G S a b → a = b := by
    intro S a b h
    induction h with
    | refl => rfl
    | tail _ h _ => exact absurd h.1 (hG _ _)
  let X : Finset V := Finset.univ.filter (fun v => v ∈ A ∧ v ∈ B)
  have hsep : ¬ Link G A B (↑X)ᶜ := by
    rintro ⟨a, ha, b, hb, haX, _, h⟩
    obtain rfl := hR _ _ _ h
    exact haX (by simp [X, ha, hb])
  have hkX := hk X hsep
  let g : Fin k → V := fun i => (X.equivFin.symm (Fin.castLE hkX i)).1
  have hg : Function.Injective g := by
    intro i j hij
    exact Fin.castLE_injective hkX (X.equivFin.symm.injective (Subtype.val_injective hij))
  have hgX : ∀ i, g i ∈ X := fun i => (X.equivFin.symm (Fin.castLE hkX i)).2
  refine ⟨fun i => {g i}, fun i => ?_, fun i j hij => ?_⟩
  · have := hgX i
    simp only [X, Finset.mem_filter] at this
    exact ⟨g i, this.2.1, g i, this.2.2, rfl, rfl, Relation.ReflTransGen.refl⟩
  · simpa using hg.ne hij

def cf [DecidableEq V] (x y : V) (w : V) : V := if w = x then y else w

def contr [DecidableEq V] (G : SimpleGraph V) (x y : V) : SimpleGraph V :=
  SimpleGraph.fromRel fun u v => ∃ u' v', G.Adj u' v' ∧ cf x y u' = u ∧ cf x y v' = v

theorem contr_adj [DecidableEq V] {G : SimpleGraph V} {x y u v : V} (h : (contr G x y).Adj u v) :
    ∃ u' v', G.Adj u' v' ∧ cf x y u' = u ∧ cf x y v' = v := by
  obtain ⟨_, ⟨u', v', h1, h2, h3⟩ | ⟨u', v', h1, h2, h3⟩⟩ := h
  · exact ⟨u', v', h1, h2, h3⟩
  · exact ⟨v', u', h1.symm, h3, h2⟩

theorem ncard_deleteEdge_lt [Finite V] (G : SimpleGraph V) {x y : V} (h : G.Adj x y) :
    (G.deleteEdges {s(x, y)}).edgeSet.ncard < G.edgeSet.ncard := by
  rw [edgeSet_deleteEdges]
  exact Set.ncard_sdiff_singleton_lt_of_mem h

theorem ncard_contr_lt [Finite V] [DecidableEq V] (G : SimpleGraph V) {x y : V} (h : G.Adj x y) :
    (contr G x y).edgeSet.ncard < G.edgeSet.ncard := by
  have hyx : y ≠ x := (G.ne_of_adj h).symm
  have hsub : (contr G x y).edgeSet ⊆ Sym2.map (cf x y) '' (G.edgeSet \ {s(x, y)}) := by
    intro e he
    induction e using Sym2.ind with
    | _ u v =>
    rw [mem_edgeSet] at he
    have huv : u ≠ v := (contr G x y).ne_of_adj he
    obtain ⟨u', v', h', rfl, rfl⟩ := contr_adj he
    refine ⟨s(u', v'), ⟨h', ?_⟩, by simp⟩
    intro heq
    rw [Set.mem_singleton_iff, Sym2.eq_iff] at heq
    apply huv
    rcases heq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;> simp [cf, hyx]
  calc (contr G x y).edgeSet.ncard
      ≤ (Sym2.map (cf x y) '' (G.edgeSet \ {s(x, y)})).ncard := Set.ncard_le_ncard hsub
    _ ≤ (G.edgeSet \ {s(x, y)}).ncard := Set.ncard_image_le
    _ < G.edgeSet.ncard := Set.ncard_sdiff_singleton_lt_of_mem h

theorem fiber_R [DecidableEq V] {G : SimpleGraph V} {x y : V} (h : G.Adj x y) (S' : Set V)
    {u w : V} (huw : cf x y u = cf x y w) (hu : cf x y u ∈ S') : R G (cf x y ⁻¹' S') u w := by
  have hyx : y ≠ x := (G.ne_of_adj h).symm
  have hx : x ∈ cf x y ⁻¹' S' ↔ y ∈ S' := by simp [cf]
  have hy : y ∈ cf x y ⁻¹' S' ↔ y ∈ S' := by simp [cf, hyx]
  by_cases hux : u = x <;> by_cases hwx : w = x
  · subst hux hwx; exact Relation.ReflTransGen.refl
  · simp only [cf, hux, hwx, ↓reduceIte] at huw hu
    subst hux huw
    exact Relation.ReflTransGen.single ⟨h, hx.2 hu, hy.2 hu⟩
  · simp only [cf, hux, hwx, ↓reduceIte] at huw hu
    subst hwx huw
    exact Relation.ReflTransGen.single ⟨h.symm, hy.2 hu, hx.2 hu⟩
  · simp only [cf, hux, hwx, ↓reduceIte] at huw
    subst huw
    exact Relation.ReflTransGen.refl

theorem lift_R [DecidableEq V] {G : SimpleGraph V} {x y : V} (h : G.Adj x y) (S' : Set V) {u z : V}
    (hR : R (contr G x y) S' (cf x y u) z) (hu : cf x y u ∈ S') :
    ∀ w, cf x y w = z → R G (cf x y ⁻¹' S') u w := by
  induction hR with
  | refl => intro w hw; exact fiber_R h S' hw.symm hu
  | @tail z1 z2 _ hst ih =>
    intro w hw
    obtain ⟨hadj, hz1, hz2⟩ := hst
    obtain ⟨u', v', h', rfl, rfl⟩ := contr_adj hadj
    have h1 := ih u' rfl
    have h2 : R G (cf x y ⁻¹' S') u v' := h1.tail ⟨h', hz1, hz2⟩
    exact Relation.ReflTransGen.trans h2 (fiber_R h S' hw.symm hz2)

theorem lift_link [DecidableEq V] {G : SimpleGraph V} {x y : V} (h : G.Adj x y) {A B S' : Set V}
    (hL : Link (contr G x y) (cf x y '' A) (cf x y '' B) S') : Link G A B (cf x y ⁻¹' S') := by
  obtain ⟨_, ⟨a, ha, rfl⟩, _, ⟨b, hb, rfl⟩, haS, hbS, hR⟩ := hL
  exact ⟨a, ha, b, hb, haS, hbS, lift_R h S' hR haS b rfl⟩

theorem push_link [DecidableEq V] {G : SimpleGraph V} {x y : V} {A B : Set V} (Y : Set V)
    (hL : Link G A B (cf x y ⁻¹' Yᶜ)) : Link (contr G x y) (cf x y '' A) (cf x y '' B) Yᶜ := by
  obtain ⟨a, ha, b, hb, haS, hbS, hR⟩ := hL
  refine ⟨_, ⟨a, ha, rfl⟩, _, ⟨b, hb, rfl⟩, haS, hbS, ?_⟩
  clear hb hbS
  induction hR with
  | refl => exact Relation.ReflTransGen.refl
  | @tail c d _ hcd ih =>
    obtain ⟨hadj, hc, hd⟩ := hcd
    by_cases he : cf x y c = cf x y d
    · rw [← he]; exact ih
    · exact ih.tail ⟨⟨he, Or.inl ⟨c, d, hadj, rfl, rfl⟩⟩, hc, hd⟩

theorem cut_link {G : SimpleGraph V} {A B X S : Set V} {x y : V} (hx : x ∈ X) (hy : y ∈ X)
    (hsep : ¬ Link G A B Xᶜ) (hL : Link G A B S) : Link (G.deleteEdges {s(x, y)}) A X S := by
  obtain ⟨a, ha, b, hb, haS, hbS, hR⟩ := hL
  by_cases haX : a ∈ X
  · exact ⟨a, ha, a, haX, haS, haS, Relation.ReflTransGen.refl⟩
  rcases first_hit hR haX with ⟨hbX, hR'⟩ | ⟨u, z, huS, huX, hzS, hzX, huz, hau⟩
  · exact absurd ⟨a, ha, b, hb, haX, hbX, R_mono (fun _ _ _ _ h => h) Set.inter_subset_right hR'⟩
      hsep
  · have hne : ∀ p q, p ∉ X → s(p, q) ∉ ({s(x, y)} : Set (Sym2 V)) := by
      intro p q hp heq
      rw [Set.mem_singleton_iff, Sym2.eq_iff] at heq
      rcases heq with ⟨rfl, _⟩ | ⟨rfl, _⟩ <;> contradiction
    have hau' : R (G.deleteEdges {s(x, y)}) S a u :=
      R_mono (S := S ∩ Xᶜ) (fun p q hp _ hpq => deleteEdges_adj.mpr ⟨hpq, hne p q hp.2⟩) Set.inter_subset_left hau
    exact ⟨a, ha, z, hzX, haS, hzS, hau'.tail ⟨deleteEdges_adj.mpr ⟨huz, hne u z huX⟩, huS, hzS⟩⟩

theorem core_aux [Fintype V] [DecidableEq V] (n : ℕ) : ∀ (G : SimpleGraph V),
    G.edgeSet.ncard = n → ∀ (A B : Set V) (k : ℕ),
    (∀ X : Finset V, ¬ Link G A B (↑X)ᶜ → k ≤ X.card) →
    ∃ S : Fin k → Set V, (∀ i, Link G A B (S i)) ∧ Pairwise fun i j => Disjoint (S i) (S j) := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro G hn A B k hk
  by_cases hedge : ∃ x y, G.Adj x y
  swap
  · push Not at hedge
    exact base_case hedge A B k hk
  obtain ⟨x, y, hxy⟩ := hedge
  have hne : x ≠ y := G.ne_of_adj hxy
  by_contra hno
  have hno' : ¬ ∃ S : Fin k → Set V,
      (∀ i, Link (contr G x y) (cf x y '' A) (cf x y '' B) (S i)) ∧
        Pairwise fun i j => Disjoint (S i) (S j) := by
    rintro ⟨S, hS, hd⟩
    exact hno ⟨fun i => cf x y ⁻¹' S i, fun i => lift_link hxy (hS i),
      fun i j hij => (hd hij).preimage _⟩
  obtain ⟨Y, hY, hYk⟩ : ∃ Y : Finset V,
      ¬ Link (contr G x y) (cf x y '' A) (cf x y '' B) (↑Y)ᶜ ∧ Y.card < k := by
    by_contra hcon
    push Not at hcon
    exact hno' (ih _ (hn ▸ ncard_contr_lt G hxy) _ rfl _ _ k hcon)
  let X : Finset V := Finset.univ.filter (fun v => cf x y v ∈ Y)
  have hXc : ((↑X : Set V))ᶜ = cf x y ⁻¹' (↑Y : Set V)ᶜ := by ext v; simp [X]
  have hsepX : ¬ Link G A B (↑X)ᶜ := by
    rw [hXc]; intro hL; exact hY (push_link _ hL)
  have hkX := hk X hsepX
  have hcfx : cf x y x = y := by simp [cf]
  have hcfy : cf x y y = y := by simp [cf, hne.symm]
  have hcfv : ∀ v, v ≠ x → cf x y v = v := by intro v hv; simp [cf, hv]
  have hyY : y ∈ Y := by
    by_contra hyY
    have : X ⊆ Y := by
      intro v hv
      simp only [X, Finset.mem_filter, Finset.mem_univ, true_and] at hv
      by_cases hvx : v = x
      · subst hvx; rw [hcfx] at hv; exact absurd hv hyY
      · rwa [hcfv v hvx] at hv
    have := Finset.card_le_card this
    omega
  have hxX : x ∈ X := by simp [X, hcfx, hyY]
  have hyX : y ∈ X := by simp [X, hcfy, hyY]
  have hXle : X.card ≤ k := by
    have : X ⊆ insert x Y := by
      intro v hv
      simp only [X, Finset.mem_filter, Finset.mem_univ, true_and] at hv
      by_cases hvx : v = x
      · simp [hvx]
      · rw [hcfv v hvx] at hv; exact Finset.mem_insert_of_mem hv
    have := Finset.card_le_card this
    have := Finset.card_insert_le x Y
    omega
  have hXk : X.card = k := le_antisymm hXle hkX
  have hlt' : (G.deleteEdges {s(x, y)}).edgeSet.ncard < n := hn ▸ ncard_deleteEdge_lt G hxy
  have hG'le : G.deleteEdges {s(x, y)} ≤ G := deleteEdges_le _
  have hxX' : x ∈ (↑X : Set V) := hxX
  have hyX' : y ∈ (↑X : Set V) := hyX
  obtain ⟨S, hS, hSd⟩ := ih _ hlt' (G.deleteEdges {s(x, y)}) rfl A ↑X k (by
    intro Z hZ
    apply hk Z
    intro hL
    exact hZ (cut_link hxX' hyX' hsepX hL))
  obtain ⟨T, hT, hTd⟩ := ih _ hlt' (G.deleteEdges {s(x, y)}) rfl ↑X B k (by
    intro Z hZ
    apply hk Z
    intro hL
    exact hZ (Link_symm (cut_link hxX' hyX' (fun h => hsepX (Link_symm h)) (Link_symm hL))))
  have hsep' : ¬ Link (G.deleteEdges {s(x, y)}) A B (↑X)ᶜ :=
    fun h => hsepX (Link_mono_graph hG'le h)
  obtain ⟨U, hU, hUd⟩ := combine hXk hsep' S hS hSd T hT hTd
  exact hno ⟨U, fun i => Link_mono_graph hG'le (hU i), hUd⟩

theorem core [Fintype V] [DecidableEq V] (G : SimpleGraph V) (A B : Set V) :
    ∃ X : Finset V, ¬ Link G A B (↑X)ᶜ ∧ ∃ S : Fin X.card → Set V,
      (∀ i, Link G A B (S i)) ∧ Pairwise fun i j => Disjoint (S i) (S j) := by
  classical
  have hex : ∃ n, ∃ X : Finset V, ¬ Link G A B (↑X)ᶜ ∧ X.card = n :=
    ⟨_, Finset.univ, by rintro ⟨a, -, -, -, ha, -⟩; simp at ha, rfl⟩
  obtain ⟨X, hX, hcard⟩ := Nat.find_spec hex
  refine ⟨X, hX, ?_⟩
  rw [hcard]
  exact core_aux _ G rfl A B _ (fun Z hZ => Nat.find_min' hex ⟨Z, hZ, rfl⟩)

theorem R_to_walk {K : SimpleGraph V} {S : Set V} {a b : V} (h : R K S a b) (ha : a ∈ S) :
    ∃ p : K.Walk a b, ∀ v ∈ p.support, v ∈ S := by
  induction h using Relation.ReflTransGen.head_induction_on with
  | refl => exact ⟨Walk.nil, by simpa using ha⟩
  | head hst _ ih =>
    obtain ⟨p, hp⟩ := ih hst.2.2
    refine ⟨Walk.cons hst.1 p, ?_⟩
    intro v hv
    rw [Walk.support_cons, List.mem_cons] at hv
    rcases hv with rfl | hv
    · exact hst.2.1
    · exact hp v hv

theorem walk_to_link {G H : SimpleGraph V} {s t : V} {X : Set V}
    (hH : ∀ u v, u ≠ s → u ≠ t → v ≠ s → v ≠ t → G.Adj u v → H.Adj u v) :
    ∀ {c d : V} (q : G.Walk c d), d = t → c ≠ t → s ∉ q.support →
      (∀ v ∈ q.support, v ≠ t → v ∉ X) → ∃ b, G.Adj t b ∧ b ∉ X ∧ R H Xᶜ c b := by
  intro c d q
  induction q with
  | nil => intro hd hct; exact absurd hd hct
  | @cons c d' d h q ih =>
    intro hd hct hs hX
    have hcs : c ≠ s := fun h' => hs (by simp [h'])
    have hcX : c ∉ X := hX c (by simp) hct
    by_cases hdt : d' = t
    · subst hdt
      exact ⟨c, h.symm, hcX, Relation.ReflTransGen.refl⟩
    · have hs' : s ∉ q.support := fun h' => hs (by simp [h'])
      have hds : d' ≠ s := fun h' => hs' (h' ▸ q.start_mem_support)
      obtain ⟨b, hb, hbX, hR⟩ := ih hd hdt hs' (fun v hv hvt => hX v (by simp [hv]) hvt)
      have hdX : d' ∉ X := hX d' (by simp) hdt
      exact ⟨b, hb, hbX, Relation.ReflTransGen.head ⟨hH c d' hcs hct hds hdt h, hcX, hdX⟩ hR⟩

theorem path_to_link {G H : SimpleGraph V} {s t : V} {X : Set V}
    (hH : ∀ u v, u ≠ s → u ≠ t → v ≠ s → v ≠ t → G.Adj u v → H.Adj u v)
    (hst : s ≠ t) (hadj : ¬ G.Adj s t) (p : G.Walk s t) (hp : p.IsPath)
    (hX : ∀ v ∈ p.support, v ≠ s → v ≠ t → v ∉ X) :
    ∃ a b, G.Adj s a ∧ G.Adj t b ∧ a ∉ X ∧ b ∉ X ∧ R H Xᶜ a b := by
  cases p with
  | nil => exact absurd rfl hst
  | @cons _ a _ h q =>
    rw [Walk.cons_isPath_iff] at hp
    have hat : a ≠ t := fun h' => hadj (h' ▸ h)
    have has : a ≠ s := (G.ne_of_adj h).symm
    obtain ⟨b, hb, hbX, hR⟩ := walk_to_link hH q rfl hat hp.2
      (fun v hv hvt => hX v (by simp [hv]) (fun h' => hp.2 (h' ▸ hv)) hvt)
    exact ⟨a, b, h, hb, hX a (by simp) has hat, hbX, hR⟩

theorem line_walk {G D : SimpleGraph V} {L : SimpleGraph (Sym2 V)} {X : Set (Sym2 V)} {t : V}
    (hD : ∀ u v, D.Adj u v → s(u, v) ∈ G.edgeSet ∧ s(u, v) ∉ X)
    (hL : ∀ e f, e ≠ f → e ∈ G.edgeSet → f ∈ G.edgeSet → (∃ v, v ∈ e ∧ v ∈ f) → L.Adj e f) :
    ∀ {c d : V}, D.Walk c d → d = t → ∀ u, D.Adj u c →
      ∃ b, b ∈ G.edgeSet ∧ t ∈ b ∧ b ∉ X ∧ R L Xᶜ s(u, c) b := by
  intro c d q
  induction q with
  | nil =>
    intro hd u hu
    subst hd
    obtain ⟨h1, h2⟩ := hD _ _ hu
    exact ⟨_, h1, Sym2.mem_mk_right _ _, h2, Relation.ReflTransGen.refl⟩
  | @cons c d _ h q ih =>
    intro hd u hu
    obtain ⟨b, hb1, hb2, hbX, hR⟩ := ih hd c h
    obtain ⟨h1, h2⟩ := hD _ _ hu
    obtain ⟨h3, h4⟩ := hD _ _ h
    refine ⟨b, hb1, hb2, hbX, ?_⟩
    by_cases heq : s(u, c) = s(c, d)
    · rw [heq]; exact hR
    · exact Relation.ReflTransGen.head
        ⟨hL _ _ heq h1 h3 ⟨c, Sym2.mem_mk_right _ _, Sym2.mem_mk_left _ _⟩, h2, h4⟩ hR

end Helpers

#print axioms R_symm
#print axioms R_mono
#print axioms R_mem
#print axioms Link_symm
#print axioms Link_mono_graph
#print axioms first_hit
#print axioms R_reached
#print axioms trim
#print axioms combine
#print axioms base_case
#print axioms contr_adj
#print axioms ncard_deleteEdge_lt
#print axioms ncard_contr_lt
#print axioms fiber_R
#print axioms lift_R
#print axioms lift_link
#print axioms push_link
#print axioms cut_link
#print axioms core_aux
#print axioms core
#print axioms R_to_walk
#print axioms walk_to_link
#print axioms path_to_link
#print axioms line_walk

/-- The card's main result, Menger's theorem, line form. Take any finite network (a simple graph
`G` on a finite set of stations `V`) and two different stations `s` and `t`. Let `k` be the most
routes from `s` to `t` (paths: no station repeated) that pairwise share no line. Then `k` is also
the fewest lines whose closure leaves no route from `s` to `t`: there is a largest family of
line-disjoint routes and a smallest separating set of lines, and they have the same size. -/
theorem most_line_disjoint_routes_eq_fewest_separating_lines {V : Type*} [Fintype V]
    (G : SimpleGraph V) (s t : V) (hst : s ≠ t) :
    ∃ k : ℕ,
      IsGreatest {n : ℕ | ∃ P : Fin n → G.Path s t,
          Pairwise fun i j => List.Disjoint (P i : G.Walk s t).edges (P j : G.Walk s t).edges} k ∧
      IsLeast {n : ℕ | ∃ F : Finset (Sym2 V), (↑F : Set (Sym2 V)) ⊆ G.edgeSet ∧
          ¬ (G.deleteEdges ↑F).Reachable s t ∧ F.card = n} k := by
  classical
  let L : SimpleGraph (Sym2 V) :=
    SimpleGraph.fromRel fun e f => e ∈ G.edgeSet ∧ f ∈ G.edgeSet ∧ ∃ v, v ∈ e ∧ v ∈ f
  let A : Set (Sym2 V) := {e | e ∈ G.edgeSet ∧ s ∈ e}
  let B : Set (Sym2 V) := {e | e ∈ G.edgeSet ∧ t ∈ e}
  obtain ⟨X, hX, S, hS, hSd⟩ := core L A B
  -- weak duality
  have weak : ∀ n (P : Fin n → G.Path s t),
      (Pairwise fun i j => List.Disjoint (P i : G.Walk s t).edges (P j : G.Walk s t).edges) →
      ∀ F : Finset (Sym2 V), ¬ (G.deleteEdges ↑F).Reachable s t → n ≤ F.card := by
    intro n P hP F hF
    have hex : ∀ i, ∃ e ∈ (P i : G.Walk s t).edges, e ∈ F := by
      intro i
      by_contra hne
      push Not at hne
      exact hF ⟨(P i : G.Walk s t).toDeleteEdges ↑F (fun e he => by simpa using hne e he)⟩
    choose g hg1 hg2 using hex
    have hinj : Function.Injective g := by
      intro i j hij
      by_contra hne
      exact hP hne (hg1 i) (hij ▸ hg1 j)
    have := Finset.card_le_card_of_injOn g (s := Finset.univ) (t := F)
      (fun i _ => hg2 i) hinj.injOn
    simpa using this
  -- the separating set of lines
  let F : Finset (Sym2 V) := X.filter (· ∈ G.edgeSet)
  have hFsub : (↑F : Set (Sym2 V)) ⊆ G.edgeSet := by
    intro e he
    simp only [F, Finset.coe_filter, Set.mem_ofPred_eq] at he
    exact he.2
  have hadjF : ∀ u v, (G.deleteEdges ↑F).Adj u v → s(u, v) ∈ G.edgeSet ∧ s(u, v) ∉ X := by
    intro u v huv
    rw [deleteEdges_adj] at huv
    refine ⟨huv.1, fun hX' => huv.2 ?_⟩
    simp only [F, Finset.coe_filter, Set.mem_ofPred_eq]
    exact ⟨hX', huv.1⟩
  have hFsep : ¬ (G.deleteEdges ↑F).Reachable s t := by
    rintro ⟨p⟩
    cases p with
    | nil => exact hst rfl
    | @cons _ c _ h q =>
      obtain ⟨b, hb1, hb2, hbX, hR⟩ := line_walk (L := L) hadjF
        (fun e f hef he hf hv => ⟨hef, Or.inl ⟨he, hf, hv⟩⟩) q rfl s h
      obtain ⟨h1, h2⟩ := hadjF _ _ h
      exact hX ⟨_, ⟨h1, Sym2.mem_mk_left _ _⟩, b, ⟨hb1, hb2⟩, h2, hbX, hR⟩
  -- the routes
  have hroute : ∀ i, ∃ P : G.Path s t, ∀ e ∈ (P : G.Walk s t).edges, e ∈ S i := by
    intro i
    obtain ⟨a, ha, b, hb, haS, hbS, hR⟩ := hS i
    have hedge : ∀ e ∈ G.edgeSet, e ∈ S i → ∀ v w, v ∈ e → w ∈ e →
        (G.deleteEdges (S i)ᶜ).Reachable v w := by
      intro e he heS v w hv hw
      induction e using Sym2.ind with | h x y =>
      have hxy : (G.deleteEdges (S i)ᶜ).Adj x y :=
        deleteEdges_adj.mpr ⟨G.mem_edgeSet.mp he, fun h => h heS⟩
      rw [Sym2.mem_iff] at hv hw
      rcases hv with rfl | rfl <;> rcases hw with rfl | rfl
      · rfl
      · exact hxy.reachable
      · exact hxy.symm.reachable
      · rfl
    have hinv : ∀ e, R L (S i) a e → ∀ v ∈ e, (G.deleteEdges (S i)ᶜ).Reachable s v := by
      intro e he
      induction he with
      | refl => exact fun v hv => hedge a ha.1 haS s v ha.2 hv
      | @tail e1 e2 h12 hst' ih =>
        intro v hv
        obtain ⟨⟨_, hr⟩, h1, h2⟩ := hst'
        rcases hr with ⟨_, he2, w, hw1, hw2⟩ | ⟨he2, _, w, hw2, hw1⟩
        · exact (ih w hw1).trans (hedge e2 he2 h2 w v hw2 hv)
        · exact (ih w hw1).trans (hedge e2 he2 h2 w v hw2 hv)
    obtain ⟨p⟩ := hinv b hR t hb.2
    refine ⟨(p.mapLe (deleteEdges_le _)).toPath, fun e he => ?_⟩
    have he' := Walk.edges_toPath_subset_edges _ he
    rw [Walk.edges_mapLe_eq_edges] at he'
    have := p.edges_subset_edgeSet he'
    rw [edgeSet_deleteEdges] at this
    simpa using this.2
  choose P hP using hroute
  have hPd : Pairwise fun i j =>
      List.Disjoint (P i : G.Walk s t).edges (P j : G.Walk s t).edges := by
    intro i j hij e hi hj
    exact Set.disjoint_left.mp (hSd hij) (hP i e hi) (hP j e hj)
  have hFX : F.card = X.card := le_antisymm (Finset.card_filter_le _ _) (weak _ P hPd F hFsep)
  refine ⟨X.card, ⟨⟨P, hPd⟩, ?_⟩, ⟨F, hFsub, hFsep, hFX⟩, ?_⟩
  · rintro n ⟨Q, hQ⟩
    exact (weak n Q hQ F hFsep).trans hFX.le
  · rintro n ⟨F', -, hF', rfl⟩
    exact weak _ P hPd F' hF'

/-- Menger's theorem, station form. In a finite network, take two different stations `s` and `t`
not joined by a line. Let `k` be the most routes from `s` to `t` that pairwise share no station
except their two ends. Then `k` is also the fewest stations, other than `s` and `t`, whose closure
leaves no route from `s` to `t` (every route from `s` to `t` passes a closed station). -/
theorem most_station_disjoint_routes_eq_fewest_separating_stations {V : Type*} [Fintype V]
    (G : SimpleGraph V) (s t : V) (hst : s ≠ t) (hadj : ¬ G.Adj s t) :
    ∃ k : ℕ,
      IsGreatest {n : ℕ | ∃ P : Fin n → G.Path s t,
          Pairwise fun i j => ∀ v ∈ (P i : G.Walk s t).support,
            v ∈ (P j : G.Walk s t).support → v = s ∨ v = t} k ∧
      IsLeast {n : ℕ | ∃ W : Finset V, s ∉ W ∧ t ∉ W ∧
          (∀ p : G.Walk s t, ∃ v ∈ W, v ∈ p.support) ∧ W.card = n} k := by
  classical
  let H : SimpleGraph V := G.deleteEdges {e | s ∈ e ∨ t ∈ e}
  have hH : ∀ u v, u ≠ s → u ≠ t → v ≠ s → v ≠ t → G.Adj u v → H.Adj u v := by
    intro u v hus hut hvs hvt huv
    refine deleteEdges_adj.mpr ⟨huv, ?_⟩
    simp only [Set.mem_ofPred_eq, Sym2.mem_iff]
    rintro ((h | h) | (h | h)) <;> simp_all
  let A : Set V := {v | G.Adj s v}
  let B : Set V := {v | G.Adj t v}
  obtain ⟨X, hX, S, hS, hSd⟩ := core H A B
  -- weak duality
  have weak : ∀ n (P : Fin n → G.Path s t),
      (Pairwise fun i j => ∀ v ∈ (P i : G.Walk s t).support,
        v ∈ (P j : G.Walk s t).support → v = s ∨ v = t) →
      ∀ W : Finset V, s ∉ W → t ∉ W → (∀ p : G.Walk s t, ∃ v ∈ W, v ∈ p.support) →
        n ≤ W.card := by
    intro n P hP W hsW htW hW
    choose g hg1 hg2 using fun i => hW (P i : G.Walk s t)
    have hinj : Function.Injective g := by
      intro i j hij
      by_contra hne
      rcases hP hne (g i) (hg2 i) (hij ▸ hg2 j) with h | h
      · exact hsW (h ▸ hg1 i)
      · exact htW (h ▸ hg1 i)
    have := Finset.card_le_card_of_injOn g (s := Finset.univ) (t := W)
      (fun i _ => hg1 i) hinj.injOn
    simpa using this
  -- the separating set of stations
  let W : Finset V := (X.erase s).erase t
  have hsW : s ∉ W := by simp [W]
  have htW : t ∉ W := by simp [W]
  have hWsep : ∀ p : G.Walk s t, ∃ v ∈ W, v ∈ p.support := by
    intro p
    by_contra hne
    push Not at hne
    have hX' : ∀ v ∈ (p.toPath : G.Walk s t).support, v ≠ s → v ≠ t → v ∉ (X : Set V) := by
      intro v hv hvs hvt hvX
      have hvX' : v ∈ X := hvX
      exact hne v (by simp [W, hvs, hvt, hvX']) (Walk.support_toPath_subset_support _ hv)
    obtain ⟨a, b, ha, hb, haX, hbX, hR⟩ :=
      path_to_link hH hst hadj (p.toPath : G.Walk s t) p.toPath.2 hX'
    exact hX ⟨a, ha, b, hb, haX, hbX, hR⟩
  -- the routes
  have hroute : ∀ i, ∃ P : G.Path s t, ∀ v ∈ (P : G.Walk s t).support,
      v = s ∨ v = t ∨ v ∈ S i := by
    intro i
    obtain ⟨a, ha, b, hb, haS, hbS, hR⟩ := hS i
    obtain ⟨w, hw⟩ := R_to_walk hR haS
    let q : G.Walk s t := Walk.cons ha ((w.mapLe (deleteEdges_le _)).concat hb.symm)
    refine ⟨q.toPath, fun v hv => ?_⟩
    have hv' := Walk.support_toPath_subset_support _ hv
    simp only [q, Walk.support_cons, Walk.support_concat, Walk.support_mapLe_eq_support,
      List.mem_cons, List.mem_append, List.not_mem_nil, or_false] at hv'
    rcases hv' with h | h | h
    · exact Or.inl h
    · exact Or.inr (Or.inr (hw v h))
    · exact Or.inr (Or.inl h)
  choose P hP using hroute
  have hPd : Pairwise fun i j => ∀ v ∈ (P i : G.Walk s t).support,
      v ∈ (P j : G.Walk s t).support → v = s ∨ v = t := by
    intro i j hij v hi hj
    rcases hP i v hi with h | h | h
    · exact Or.inl h
    · exact Or.inr h
    rcases hP j v hj with h' | h' | h'
    · exact Or.inl h'
    · exact Or.inr h'
    exact absurd h' (Set.disjoint_left.mp (hSd hij) h)
  have hWX : W.card = X.card := by
    refine le_antisymm ?_ (weak _ P hPd W hsW htW hWsep)
    exact (Finset.card_erase_le).trans Finset.card_erase_le
  refine ⟨X.card, ⟨⟨P, hPd⟩, ?_⟩, ⟨W, hsW, htW, hWsep, hWX⟩, ?_⟩
  · rintro n ⟨Q, hQ⟩
    exact (weak n Q hQ W hsW htW hWsep).trans hWX.le
  · rintro n ⟨W', hs', ht', hW', rfl⟩
    exact weak _ P hPd W' hs' ht' hW'

/-- Bridges. In a finite network, removing a line `e` adds a separate piece (the number of
connected pieces of `G - e` is larger than that of `G`) exactly when `e` lies on no loop
(no cycle of `G` uses `e`). -/
theorem removing_line_adds_piece_iff_on_no_loop {V : Type*} [Finite V]
    (G : SimpleGraph V) (e : Sym2 V) (he : e ∈ G.edgeSet) :
    Nat.card G.ConnectedComponent < Nat.card (G.deleteEdges {e}).ConnectedComponent ↔
      ∀ (u : V) (c : G.Walk u u), c.IsCycle → e ∉ c.edges := by
  have hb : G.IsBridge e ↔ ∀ (u : V) (c : G.Walk u u), c.IsCycle → e ∉ c.edges :=
    (isBridge_iff_forall_cycle_notMem he).trans ⟨fun h u c => h c, fun h u c => h u c⟩
  rw [← hb]
  let φ : (G.deleteEdges {e}).ConnectedComponent → G.ConnectedComponent :=
    ConnectedComponent.map (Hom.ofLE (deleteEdges_le _))
  have hφ : ∀ v, φ ((G.deleteEdges {e}).connectedComponentMk v) = G.connectedComponentMk v :=
    fun v => rfl
  have hsurj : Function.Surjective φ := by
    intro c
    induction c using ConnectedComponent.ind with
    | h v => exact ⟨_, hφ v⟩
  constructor
  · intro hlt
    by_contra hnb
    have hinj : Function.Injective φ := by
      intro c1 c2 h12
      induction c1 using ConnectedComponent.ind with | h u =>
      induction c2 using ConnectedComponent.ind with | h v =>
      rw [hφ, hφ, ConnectedComponent.eq] at h12
      exact ConnectedComponent.eq.mpr (h12.reachable_deleteEdges_of_not_isBridge hnb)
    have := Nat.card_congr (Equiv.ofBijective φ ⟨hinj, hsurj⟩)
    omega
  · intro hbr
    have hle := Nat.card_le_card_of_surjective φ hsurj
    refine lt_of_le_of_ne hle (fun heq => ?_)
    have hbij := hsurj.bijective_of_nat_card_le heq.symm.le
    induction e using Sym2.ind with | h x y =>
    have hxy : (G.deleteEdges {s(x, y)}).connectedComponentMk x =
        (G.deleteEdges {s(x, y)}).connectedComponentMk y :=
      hbij.1 (by rw [hφ, hφ]; exact ConnectedComponent.eq.mpr (G.mem_edgeSet.mp he).reachable)
    exact isBridge_iff.mp hbr (ConnectedComponent.eq.mp hxy)

/-! ### The card's railway

Stations: S = 0, A = 1, B = 2, J = 3, C = 4, D = 5, E = 6, T = 7.
Lines: S–A, S–B, A–J, B–J, J–C, C–T, J–D, D–E, E–T. -/

/-- The nine lines of the railway, as unordered pairs of stations. -/
def railLines : Finset (Sym2 (Fin 8)) :=
  {s(0, 1), s(0, 2), s(1, 3), s(2, 3), s(3, 4), s(4, 7), s(3, 5), s(5, 6), s(6, 7)}

/-- The railway: two stations are joined exactly when their pair is one of the nine lines. -/
def rail : SimpleGraph (Fin 8) := SimpleGraph.fromRel fun x y => s(x, y) ∈ railLines

instance : DecidableRel rail.Adj := fun x y => by unfold rail; infer_instance

-- 8 stations and 9 lines.
example : Fintype.card (Fin 8) = 8 := by decide
example : rail.edgeFinset.card = 9 := by decide

-- Closing S–A and S–B separates S from T, so λ(S, T) ≤ 2.
example : ¬ (rail.deleteEdges {s(0, 1), s(0, 2)}).Reachable 0 7 := by decide

-- Closing one line is not enough: after closing S–A, S still reaches T.
example : (rail.deleteEdges {s(0, 1)}).Reachable 0 7 := by decide

-- The railway is one piece.
example : rail.Connected := by decide

-- No bridge: for every line x–y, x still reaches y with that line closed.
example : ∀ x y : Fin 8, rail.Adj x y → (rail.deleteEdges {s(x, y)}).Reachable x y := by decide

-- J is a cut vertex: with station J closed, S no longer reaches T, so κ(S, T) ≤ 1.
example : ¬ (rail.induce {v | v ≠ 3}).Reachable ⟨0, by decide⟩ ⟨7, by decide⟩ := by decide

-- With C–T closed, J–C becomes a bridge.
example : (rail.deleteEdges {s(4, 7)}).IsBridge s(3, 4) := by
  rw [isBridge_iff]; decide

-- The hand count of separating pairs: one line off each west route (2 · 2) or one off each
-- east route (2 · 3), 10 in all; and 2 · 2 = 4 routes from S to T.
example : 2 * 2 + 2 * 3 = 10 := by decide
example : 2 * 2 = 4 := by decide

#print axioms most_line_disjoint_routes_eq_fewest_separating_lines
#print axioms most_station_disjoint_routes_eq_fewest_separating_stations
#print axioms removing_line_adds_piece_iff_on_no_loop

end ConnectivityAndMengersTheorem
