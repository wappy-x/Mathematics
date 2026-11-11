-- Hall's theorem: with finitely many applicants, every applicant can get a post of her own exactly when every group of applicants is qualified, between them, for at least as many posts as the group has members; and in general the most that can be placed is the number of applicants minus the worst group's shortfall.
import Mathlib.Combinatorics.Hall.Basic
import Mathlib.Data.Set.Card
import Mathlib.Data.ENat.Lattice
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Lattice

/-! Applicants form a type `α` with finitely many members, posts form any type `β`, and
`r a b` says applicant `a` is qualified for post `b`: one line of the bipartite graph, always
running from an applicant to a post. A group of applicants is `S : Finset α`, and the posts it
reaches, `N(S)` on the card, are `{b | ∃ a ∈ S, r a b}`. Their sizes are counted in `ℕ∞`
(`Set.encard`), so a group that reaches infinitely many posts counts as reaching `⊤`.
A full placement is a one-to-one map `f : α → β` sending every applicant to a post she is
qualified for. A partial placement is a set `P` of placed applicants and a map `f` that is
one-to-one on `P` and gives each of them a post she is qualified for. -/

/-- Hall's theorem. With finitely many applicants, every applicant can be given a post she is
qualified for, no post shared, exactly when every group `S` of applicants is qualified, between
them, for at least `|S|` posts: `|N(S)| ≥ |S|` for every group `S`. -/
theorem full_placement_iff_hall_condition {α β : Type*} [Finite α] (r : α → β → Prop) :
    (∃ f : α → β, Function.Injective f ∧ ∀ a, r a (f a)) ↔
      ∀ S : Finset α, (S.card : ℕ∞) ≤ {b | ∃ a ∈ S, r a b}.encard := by
  classical
  have := Fintype.ofFinite α
  constructor
  · rintro ⟨f, hf, hr⟩ S
    calc (S.card : ℕ∞) = ((S : Set α)).encard := by simp
      _ ≤ _ := Set.encard_le_encard_of_injOn
          (fun a ha => (⟨a, ha, hr a⟩ : ∃ a' ∈ S, r a' (f a))) hf.injOn
  · intro h
    have key : ∀ a, ∃ t : Finset β, (t : Set β) ⊆ {b | r a b} ∧
        ((t.card : ℕ∞) = min ({b | r a b}.encard) (Nat.card α)) := by
      intro a
      obtain ⟨t, hts, htc⟩ :=
        Set.exists_subset_encard_eq (min_le_left ({b | r a b}.encard) ((Nat.card α : ℕ∞)))
      have hfin : t.Finite := Set.finite_of_encard_le_coe (htc ▸ min_le_right _ _)
      refine ⟨hfin.toFinset, by simpa using hts, ?_⟩
      rw [← htc, ← Set.encard_coe_eq_coe_finsetCard]; simp
    choose t hts htc using key
    suffices hall : ∀ S : Finset α, S.card ≤ (S.biUnion t).card by
      obtain ⟨f, hf, hft⟩ := (Finset.all_card_le_biUnion_card_iff_exists_injective t).1 hall
      exact ⟨f, hf, fun a => hts a (hft a)⟩
    intro S
    by_cases hbig : ∃ a ∈ S, ((Nat.card α : ℕ) : ℕ∞) ≤ {b | r a b}.encard
    · obtain ⟨a, ha, hle⟩ := hbig
      have h1 : (t a).card = Nat.card α := by
        have := htc a; rw [min_eq_right hle] at this; exact_mod_cast this
      calc S.card ≤ Nat.card α := by rw [Nat.card_eq_fintype_card]; exact S.card_le_univ
        _ = (t a).card := h1.symm
        _ ≤ _ := Finset.card_le_card (Finset.subset_biUnion_of_mem t ha)
    · push Not at hbig
      have heq : ∀ a ∈ S, (t a : Set β) = {b | r a b} := by
        intro a ha
        have hc := htc a
        rw [min_eq_left (hbig a ha).le] at hc
        exact (t a).finite_toSet.eq_of_subset_of_encard_le (hts a)
          (by rw [Set.encard_coe_eq_coe_finsetCard, hc])
      have hU : ((S.biUnion t : Finset β) : Set β) = {b | ∃ a ∈ S, r a b} := by
        ext b
        simp only [Finset.coe_biUnion, Set.mem_iUnion, Set.mem_ofPred_eq, Finset.mem_coe,
          exists_prop]
        constructor
        · rintro ⟨a, ha, hb⟩; exact ⟨a, ha, hts a hb⟩
        · rintro ⟨a, ha, hb⟩
          refine ⟨a, ha, ?_⟩
          show b ∈ (t a : Set β)
          rw [heq a ha]; exact hb
      have := h S
      rw [← hU, Set.encard_coe_eq_coe_finsetCard] at this
      exact_mod_cast this

/-- Helper: the defect formula holds once there is at least one post (`[Nonempty β]`). -/
theorem max_placed_eq_card_sub_defect_of_nonempty {α β : Type*} [Finite α] [Nonempty β]
    (r : α → β → Prop) :
    IsGreatest
      {k : ℕ∞ | ∃ (P : Finset α) (f : α → β), Set.InjOn f P ∧ (∀ a ∈ P, r a (f a)) ∧
        k = (P.card : ℕ∞)}
      ((Nat.card α : ℕ∞) - ⨆ S : Finset α, ((S.card : ℕ∞) - {b | ∃ a ∈ S, r a b}.encard)) := by
  classical
  have := Fintype.ofFinite α
  set D : Finset α → ℕ∞ := fun S => (S.card : ℕ∞) - {b | ∃ a ∈ S, r a b}.encard with hD
  obtain ⟨S0, hS0⟩ := Finite.exists_max D
  have hsup : (⨆ S : Finset α, D S) = D S0 := le_antisymm (iSup_le hS0) (le_iSup D S0)
  change IsGreatest _ ((Nat.card α : ℕ∞) - ⨆ S : Finset α, D S)
  rw [hsup, Nat.card_eq_fintype_card]
  set n := Fintype.card α
  have hDle : D S0 ≤ (S0.card : ℕ∞) := tsub_le_self
  obtain ⟨d, hd⟩ : ∃ d : ℕ, D S0 = d :=
    ⟨(D S0).toNat, (ENat.natCast_toNat (ne_top_of_le_ne_top (ENat.natCast_ne_top _) hDle)).symm⟩
  rw [hd]
  constructor
  · -- existence: add `d` extra posts open to everyone and apply Hall's theorem
    let r' : α → β ⊕ Fin d → Prop := fun a x => Sum.elim (r a) (fun _ => True) x
    obtain ⟨f', hf', hr'⟩ := (full_placement_iff_hall_condition r').2 (by
      intro S
      rcases S.eq_empty_or_nonempty with rfl | ⟨a0, ha0⟩
      · simp
      have h1 : (S.card : ℕ∞) ≤ {b | ∃ a ∈ S, r a b}.encard + d := by
        have h := hS0 S
        rw [hd] at h
        rw [add_comm]; exact tsub_le_iff_right.1 h
      have hdisj : Disjoint (Sum.inl '' {b | ∃ a ∈ S, r a b}) (Set.range (Sum.inr : Fin d → β ⊕ Fin d)) := by
        rw [Set.disjoint_left]
        rintro _ ⟨b, -, rfl⟩ ⟨i, hi⟩
        cases hi
      calc (S.card : ℕ∞) ≤ {b | ∃ a ∈ S, r a b}.encard + d := h1
        _ = (Sum.inl '' {b | ∃ a ∈ S, r a b}).encard +
            (Set.range (Sum.inr : Fin d → β ⊕ Fin d)).encard := by
          rw [Sum.inl_injective.injOn.encard_image, Sum.inr_injective.encard_range]; simp
        _ = (Sum.inl '' {b | ∃ a ∈ S, r a b} ∪ Set.range (Sum.inr : Fin d → β ⊕ Fin d)).encard :=
          (Set.encard_union_eq hdisj).symm
        _ ≤ _ := by
          apply Set.encard_le_encard
          rintro x (⟨b, ⟨a, ha, hb⟩, rfl⟩ | ⟨i, rfl⟩)
          · exact ⟨a, ha, hb⟩
          · exact ⟨a0, ha0, trivial⟩)
    let f : α → β := fun a => Sum.elim id (fun _ => Classical.arbitrary β) (f' a)
    let P' := Finset.univ.filter (fun a => ∃ b, f' a = Sum.inl b)
    have hP' : ∀ a ∈ P', f' a = Sum.inl (f a) := by
      intro a ha
      obtain ⟨b, hb⟩ := (Finset.mem_filter.1 ha).2
      simp [f, hb]
    have hQ : (Finset.univ.filter (fun a => ¬ ∃ b, f' a = Sum.inl b)).card ≤ d := by
      calc _ ≤ (Finset.univ.map ⟨(Sum.inr : Fin d → β ⊕ Fin d), Sum.inr_injective⟩).card := by
            apply Finset.card_le_card_of_injOn f'
            · intro a ha
              have ha' := (Finset.mem_filter.1 ha).2
              rcases hfa : f' a with b | i
              · exact (ha' ⟨b, hfa⟩).elim
              · simp
            · exact hf'.injOn
        _ = d := by simp
    have hsplit : P'.card + (Finset.univ.filter (fun a => ¬ ∃ b, f' a = Sum.inl b)).card = n := by
      rw [Finset.card_filter_add_card_filter_not, Finset.card_univ]
    have hdn : d ≤ n := by
      have h1 : (d : ℕ∞) ≤ S0.card := hd ▸ hDle
      have h2 : d ≤ S0.card := by exact_mod_cast h1
      have h3 : S0.card ≤ n := S0.card_le_univ
      omega
    obtain ⟨P, hPP', hPc⟩ := Finset.exists_subset_card_eq (s := P') (n := n - d) (by omega)
    refine ⟨P, f, ?_, ?_, ?_⟩
    · intro a1 h1 a2 h2 h
      apply hf'
      rw [hP' a1 (hPP' h1), hP' a2 (hPP' h2), h]
    · intro a ha
      have := hr' a
      rw [hP' a (hPP' ha)] at this
      exact this
    · rw [hPc]; exact (ENat.natCast_sub n d).symm
  · -- upper bound
    rintro k ⟨P, f, hinj, hr, rfl⟩
    by_cases hN : (S0.card : ℕ∞) ≤ {b | ∃ a ∈ S0, r a b}.encard
    · have : D S0 = 0 := tsub_eq_zero_of_le hN
      rw [hd] at this
      have hd0 : d = 0 := by exact_mod_cast this
      subst hd0
      simp only [Nat.cast_zero, tsub_zero, Nat.cast_le]
      exact P.card_le_univ
    · push Not at hN
      have hfin : {b | ∃ a ∈ S0, r a b}.Finite := Set.finite_of_encard_le_coe hN.le
      set m := hfin.toFinset.card
      have hm : {b | ∃ a ∈ S0, r a b}.encard = m := by
        rw [← Set.encard_coe_eq_coe_finsetCard]; simp
      rw [hm] at hN
      have hmlt : m < S0.card := by exact_mod_cast hN
      have hdm : d = S0.card - m := by
        have : D S0 = ((S0.card - m : ℕ) : ℕ∞) := by
          simp only [hD, hm]; push_cast [hmlt.le]; rfl
        rw [hd] at this; exact_mod_cast this
      have h1 : (P ∩ S0).card ≤ m := by
        have : ((P ∩ S0 : Finset α) : Set α).encard ≤ {b | ∃ a ∈ S0, r a b}.encard := by
          apply Set.encard_le_encard_of_injOn
          · intro a ha
            simp only [Finset.coe_inter, Set.mem_inter_iff, Finset.mem_coe] at ha
            exact ⟨a, ha.2, hr a ha.1⟩
          · exact hinj.mono (by simp)
        rw [hm, Set.encard_coe_eq_coe_finsetCard] at this
        exact_mod_cast this
      have h2 : (P \ S0).card ≤ n - S0.card := by
        calc (P \ S0).card ≤ (Finset.univ \ S0).card :=
              Finset.card_le_card (Finset.sdiff_subset_sdiff (Finset.subset_univ _) le_rfl)
          _ = n - S0.card := by rw [Finset.card_univ_sdiff]
      have h3 := Finset.card_inter_add_card_sdiff P S0
      have h4 : S0.card ≤ n := S0.card_le_univ
      have : P.card ≤ n - d := by omega
      calc (P.card : ℕ∞) ≤ ((n - d : ℕ) : ℕ∞) := by exact_mod_cast this
        _ = (n : ℕ∞) - d := by push_cast [show d ≤ n by omega]; rfl

#print axioms max_placed_eq_card_sub_defect_of_nonempty

/-- The defect formula. With finitely many applicants and at least one post, the largest number that can be placed
(each in a post she is qualified for, no post shared) is the number of applicants minus the
defect: the most by which any group, the empty one included, outnumbers the posts it reaches,
`ν(G) = |A| - max_S (|S| - |N(S)|)`. -/
theorem max_placed_eq_card_sub_defect {α β : Type*} [Finite α] [Nonempty β] (r : α → β → Prop) :
    IsGreatest
      {k : ℕ∞ | ∃ (P : Finset α) (f : α → β), Set.InjOn f P ∧ (∀ a ∈ P, r a (f a)) ∧
        k = (P.card : ℕ∞)}
      ((Nat.card α : ℕ∞) - ⨆ S : Finset α, ((S.card : ℕ∞) - {b | ∃ a ∈ S, r a b}.encard)) := by
  exact max_placed_eq_card_sub_defect_of_nonempty r

/-! The hotel. Applicants 0 to 5 are Ana, Ben, Cleo, Dev, Eve, Fay. Posts 0 to 5 are front desk,
kitchen, laundry, bar, maintenance, accounts. Each list is the posts that applicant qualifies for. -/

/-- The blocked hiring from the card. -/
def blocked : Fin 6 → Finset (Fin 6) := ![{0, 5}, {0, 5}, {5}, {1, 2, 3}, {2, 4}, {3, 4, 1}]

/-- The repaired hiring: Cleo also trains on the laundry. -/
def repaired : Fin 6 → Finset (Fin 6) := ![{0, 5}, {0, 5}, {5, 2}, {1, 2, 3}, {2, 4}, {3, 4, 1}]

/-- The repaired hiring with the accounts post deleted. -/
def noAccounts : Fin 6 → Finset (Fin 6) := ![{0}, {0}, {2}, {1, 2, 3}, {2, 4}, {3, 4, 1}]

-- Qualification lines: 13 in the blocked hiring, 14 after the repair.
example : ∑ a, (blocked a).card = 13 ∧ ∑ a, (repaired a).card = 14 := by decide
-- Groups to check: each of 6 applicants in or out, 2^6 = 64.
example : Fintype.card (Finset (Fin 6)) = 64 := by decide
-- Ana, Ben, Cleo reach two posts, front desk and accounts: 3 members, 2 posts, gap 1.
example : ({0, 1, 2} : Finset (Fin 6)).biUnion blocked = {0, 5} ∧
    (({0, 1, 2} : Finset (Fin 6)).biUnion blocked).card = 2 := by decide
-- Mistake 2: the trio has 5 lines but reaches only 2 posts.
example : (blocked 0).card + (blocked 1).card + (blocked 2).card = 5 := by decide
-- Mistake 1: every applicant alone passes, all 6 qualify for something.
example : ∀ a, (blocked a).Nonempty := by decide
-- Blocked: the worst gap over all 64 groups is 1.
example : (∀ S : Finset (Fin 6), S.card ≤ (S.biUnion blocked).card + 1) ∧
    ∃ S : Finset (Fin 6), S.card = (S.biUnion blocked).card + 1 := by decide
-- Blocked: 6 - 1 = 5 placed; Ana-accounts, Ben-front desk, Dev-kitchen, Eve-maintenance, Fay-bar.
example : (∀ a ∈ ({0, 1, 3, 4, 5} : Finset (Fin 6)), ∀ a' ∈ ({0, 1, 3, 4, 5} : Finset (Fin 6)),
      (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a = (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a' → a = a') ∧
    ∀ a ∈ ({0, 1, 3, 4, 5} : Finset (Fin 6)), (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a ∈ blocked a := by
  decide
-- Repaired: the worst gap over all 64 groups is 0, Hall's condition holds.
example : ∀ S : Finset (Fin 6), S.card ≤ (S.biUnion repaired).card := by decide
-- Repaired: Ana-accounts, Ben-front desk, Cleo-laundry, Dev-kitchen, Eve-maintenance, Fay-bar.
example : Function.Injective (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) ∧
    ∀ a, (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a ∈ repaired a := by decide
-- Complete placements by census: blocked 0, repaired 4.
example : ((Fintype.piFinset blocked).filter Function.Injective).card = 0 ∧
    ((Fintype.piFinset repaired).filter Function.Injective).card = 4 := by
  decide
-- Mistake 3: delete accounts from the repaired hiring and the gap is back to 1.
example : (∀ S : Finset (Fin 6), S.card ≤ (S.biUnion noAccounts).card + 1) ∧
    ∃ S : Finset (Fin 6), S.card = (S.biUnion noAccounts).card + 1 := by decide

#print axioms full_placement_iff_hall_condition
#print axioms max_placed_eq_card_sub_defect
