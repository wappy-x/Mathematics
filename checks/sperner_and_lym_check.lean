-- Sperner's theorem: for an antichain of subsets of an n-element set, the LYM scores 1/C(n, |A|) add to at most 1, so it has at most C(n, ⌊n/2⌋) members, and only a whole middle layer has exactly that many.
import Mathlib.Combinatorics.SetFamily.LYM
import Mathlib.Combinatorics.Enumerative.DoubleCounting
import Mathlib.Data.Fintype.Powerset
import Mathlib.Tactic.NormNum

open Finset

/-- Off the two middle sizes, the binomial coefficient is strictly below the middle one. -/
theorem choose_lt_middle_of_ne {n r : ℕ} (hr : r ≤ n) (h1 : r ≠ n / 2) (h2 : r ≠ (n + 1) / 2) :
    n.choose r < n.choose (n / 2) := by
  have step : ∀ m, m < n / 2 → n.choose m < n.choose (n / 2) := by
    intro m hm
    have hpos : 0 < n.choose m := Nat.choose_pos (by omega)
    have key := Nat.choose_succ_right_eq n m
    have hlt : n.choose m < n.choose (m + 1) := by
      by_contra hcon
      push Not at hcon
      have : n.choose (m + 1) * (m + 1) < n.choose m * (n - m) := by
        calc n.choose (m + 1) * (m + 1) ≤ n.choose m * (m + 1) := Nat.mul_le_mul_right _ hcon
          _ < n.choose m * (n - m) := Nat.mul_lt_mul_of_pos_left (by omega) hpos
      omega
    exact lt_of_lt_of_le hlt (Nat.choose_le_middle _ _)
  rcases lt_or_gt_of_ne h1 with h | h
  · exact step r h
  · rw [← Nat.choose_symm hr]
    exact step (n - r) (by omega)

#print axioms choose_lt_middle_of_ne

/-- The two middle layers have the same size. -/
theorem choose_half_succ_eq (n : ℕ) : n.choose ((n + 1) / 2) = n.choose (n / 2) :=
  Nat.choose_symm_of_eq_add (by omega)

#print axioms choose_half_succ_eq

/-- In an odd-size ground set of size `2k+1`, a family of `(k+1)`-sets whose shadow is no
larger than itself is closed: every `(k+1)`-set above a shadow member is in the family. -/
theorem upper_closed_of_card_shadow_le {α : Type*} [Fintype α] [DecidableEq α] {k : ℕ}
    (hα : Fintype.card α = 2 * k + 1) (U : Finset (Finset α))
    (hU : (U : Set (Finset α)).Sized (k + 1)) (hle : #((shadow U)) ≤ #U) :
    ∀ X ∈ (shadow U), ∀ T : Finset α, X ⊆ T → #T = k + 1 → T ∈ U := by
  by_contra hcon
  push Not at hcon
  obtain ⟨X, hX, T, hXT, hT, hTU⟩ := hcon
  have hsh : ∀ a ∈ (shadow U), #a = k := fun a ha => by
    have := hU.shadow ha
    simpa using this
  have key := sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow
    (r := fun (a b : Finset α) => a ⊆ b) (s := (shadow U)) (t := U)
  have hbelow : ∀ b ∈ U, k + 1 ≤ #(((shadow U)).bipartiteBelow (fun a b => a ⊆ b) b) := by
    intro b hb
    rw [← hU hb, ← card_image_of_injOn b.erase_injOn]
    refine card_le_card ?_
    intro x hx
    rw [mem_image] at hx
    obtain ⟨a, ha, rfl⟩ := hx
    rw [mem_bipartiteBelow]
    exact ⟨erase_mem_shadow hb ha, erase_subset _ _⟩
  have habove_sub : ∀ a ∈ (shadow U),
      U.bipartiteAbove (fun a b => a ⊆ b) a ⊆ aᶜ.image (fun x => insert x a) := by
    intro a ha b hb
    rw [mem_bipartiteAbove] at hb
    obtain ⟨x, hx, rfl⟩ := exists_eq_insert_iff.2 ⟨hb.2, by rw [hsh a ha, hU hb.1]⟩
    exact mem_image_of_mem _ (mem_compl.2 hx)
  have hcompl : ∀ a ∈ (shadow U), #aᶜ = k + 1 := fun a ha => by
    rw [card_compl, hα, hsh a ha]; omega
  have habove : ∀ a ∈ (shadow U), #(U.bipartiteAbove (fun a b => a ⊆ b) a) ≤ k + 1 := by
    intro a ha
    calc _ ≤ #(aᶜ.image (fun x => insert x a)) := card_le_card (habove_sub a ha)
      _ ≤ #aᶜ := card_image_le
      _ = k + 1 := hcompl a ha
  have hTmem : T ∈ Xᶜ.image (fun x => insert x X) := by
    obtain ⟨x, hx, rfl⟩ := exists_eq_insert_iff.2 ⟨hXT, by rw [hsh X hX, hT]⟩
    exact mem_image_of_mem _ (mem_compl.2 hx)
  have hX_lt : #(U.bipartiteAbove (fun a b => a ⊆ b) X) < k + 1 := by
    have hsub : U.bipartiteAbove (fun a b => a ⊆ b) X ⊆ (Xᶜ.image (fun x => insert x X)).erase T := by
      intro b hb
      refine mem_erase.2 ⟨?_, habove_sub X hX hb⟩
      rintro rfl
      exact hTU ((mem_bipartiteAbove _).1 hb).1
    calc _ ≤ #((Xᶜ.image (fun x => insert x X)).erase T) := card_le_card hsub
      _ = #(Xᶜ.image (fun x => insert x X)) - 1 := card_erase_of_mem hTmem
      _ < k + 1 := by
        have h1 : #(Xᶜ.image (fun x => insert x X)) ≤ k + 1 :=
          card_image_le.trans (hcompl X hX).le
        have h2 : 0 < #(Xᶜ.image (fun x => insert x X)) := card_pos.2 ⟨T, hTmem⟩
        omega
  have hlhs : ∑ a ∈ (shadow U), #(U.bipartiteAbove (fun a b => a ⊆ b) a) < ∑ _a ∈ (shadow U), (k + 1) :=
    sum_lt_sum habove ⟨X, hX, hX_lt⟩
  have hrhs : ∑ _b ∈ U, (k + 1) ≤ ∑ b ∈ U, #(((shadow U)).bipartiteBelow (fun a b => a ⊆ b) b) :=
    sum_le_sum hbelow
  rw [sum_const] at hlhs hrhs
  rw [Nat.nsmul_eq_mul] at hlhs hrhs
  have : #U * (k + 1) < #((shadow U)) * (k + 1) := by omega
  have := Nat.lt_of_mul_lt_mul_right this
  omega

#print axioms upper_closed_of_card_shadow_le

/-- A nonempty closed family of `(k+1)`-sets (as above) is the whole layer: any `(k+1)`-set is
reached from a member by swapping one element at a time. -/
theorem eq_powersetCard_of_upper_closed {α : Type*} [Fintype α] [DecidableEq α] {k : ℕ}
    (U : Finset (Finset α)) (hU : (U : Set (Finset α)).Sized (k + 1))
    (hcl : ∀ X ∈ (shadow U), ∀ T : Finset α, X ⊆ T → #T = k + 1 → T ∈ U) (hne : U.Nonempty) :
    U = (univ : Finset α).powersetCard (k + 1) := by
  obtain ⟨T0, hT0⟩ := hne
  have hT0c : #T0 = k + 1 := hU hT0
  have claim : ∀ d : ℕ, ∀ T : Finset α, #T = k + 1 → #(T0 \ T) ≤ d → T ∈ U := by
    intro d
    induction d with
    | zero =>
      intro T hT hd
      have h0 : T0 \ T = ∅ := card_eq_zero.1 (by omega)
      have hsub : T0 ⊆ T := sdiff_eq_empty_iff_subset.1 h0
      have : T0 = T := eq_of_subset_of_card_le hsub (by omega)
      exact this ▸ hT0
    | succ d ih =>
      intro T hT hd
      by_cases hd' : #(T0 \ T) ≤ d
      · exact ih T hT hd'
      have hpos : 0 < #(T0 \ T) := by omega
      obtain ⟨a, ha⟩ := card_pos.1 hpos
      have hcomm : #(T \ T0) = #(T0 \ T) := card_sdiff_comm (by omega)
      obtain ⟨b, hb⟩ := card_pos.1 (hcomm ▸ hpos : 0 < #(T \ T0))
      rw [mem_sdiff] at ha hb
      have hbT : b ∈ T := hb.1
      have haT' : a ∉ T.erase b := fun h => ha.2 (mem_of_mem_erase h)
      have hXc : #(T.erase b) = k := by rw [card_erase_of_mem hbT, hT]; omega
      have hT''c : #(insert a (T.erase b)) = k + 1 := by
        rw [card_insert_of_notMem haT', hXc]
      have hsd : T0 \ insert a (T.erase b) ⊆ (T0 \ T).erase a := by
        intro x hx
        rw [mem_sdiff, mem_insert, not_or, mem_erase, not_and] at hx
        rw [mem_erase, mem_sdiff]
        refine ⟨hx.2.1, hx.1, fun hxT => ?_⟩
        have hxb : x ≠ b := fun h => hb.2 (h ▸ hx.1)
        exact hx.2.2 hxb hxT
      have hd2 : #(T0 \ insert a (T.erase b)) ≤ d := by
        calc _ ≤ #((T0 \ T).erase a) := card_le_card hsd
          _ = #(T0 \ T) - 1 := card_erase_of_mem (mem_sdiff.2 ha)
          _ ≤ d := by omega
      have hT'' := ih _ hT''c hd2
      have hXsh : T.erase b ∈ (shadow U) :=
        mem_shadow_iff_exists_mem_card_add_one.2 ⟨_, hT'', subset_insert _ _, by rw [hT''c, hXc]⟩
      exact hcl _ hXsh T (erase_subset _ _) hT
  ext T
  rw [mem_powersetCard]
  constructor
  · intro hT
    exact ⟨subset_univ _, hU hT⟩
  · rintro ⟨-, hT⟩
    exact claim (k + 1) T hT (by
      calc _ ≤ #T0 := card_le_card sdiff_subset
        _ = k + 1 := hT0c)

#print axioms eq_powersetCard_of_upper_closed

/-- The odd case of the equality: an antichain of `k`- and `(k+1)`-sets of a `(2k+1)`-set with
`C(2k+1, k)` members is a whole layer. -/
theorem antichain_odd_eq_layer {α : Type*} [Fintype α] [DecidableEq α] {k : ℕ}
    (hα : Fintype.card α = 2 * k + 1) (𝒜 : Finset (Finset α))
    (h𝒜 : IsAntichain (· ⊆ ·) (𝒜 : Set (Finset α)))
    (hsize : ∀ A ∈ 𝒜, #A = k ∨ #A = k + 1) (hcard : #𝒜 = (2 * k + 1).choose k) :
    𝒜 = (univ : Finset α).powersetCard k ∨ 𝒜 = (univ : Finset α).powersetCard (k + 1) := by
  set U := 𝒜.filter (fun A => #A = k + 1) with hUdef
  set L := 𝒜.filter (fun A => ¬ #A = k + 1) with hLdef
  have hUL : #U + #L = #𝒜 := card_filter_add_card_filter_not _
  have hUs : (U : Set (Finset α)).Sized (k + 1) := fun A hA => (mem_filter.1 hA).2
  have hLs : ∀ A ∈ L, #A = k := fun A hA => by
    rw [mem_filter] at hA
    rcases hsize A hA.1 with h | h
    · exact h
    · exact absurd h hA.2
  have hdisj : Disjoint ((shadow U)) L := by
    rw [disjoint_left]
    intro X hX hXL
    obtain ⟨s, hs, hXs, hsc⟩ := mem_shadow_iff_exists_mem_card_add_one.1 hX
    have hXA : X ∈ 𝒜 := (mem_filter.1 hXL).1
    have hsA : s ∈ 𝒜 := (mem_filter.1 hs).1
    have hne : X ≠ s := by rintro rfl; omega
    exact h𝒜 hXA hsA hne hXs
  have hsub : (shadow U) ∪ L ⊆ (univ : Finset α).powersetCard k := by
    intro X hX
    rw [mem_powersetCard]
    refine ⟨subset_univ _, ?_⟩
    rcases mem_union.1 hX with h | h
    · simpa using hUs.shadow h
    · exact hLs X h
  have hcardk : #((univ : Finset α).powersetCard k) = (2 * k + 1).choose k := by
    rw [card_powersetCard, card_univ, hα]
  have hle : #((shadow U)) ≤ #U := by
    have := card_le_card hsub
    rw [card_union_of_disjoint hdisj, hcardk] at this
    omega
  rcases U.eq_empty_or_nonempty with hU0 | hU0
  · left
    refine eq_of_subset_of_card_le ?_ (by rw [hcardk, hcard])
    intro A hA
    rw [mem_powersetCard]
    refine ⟨subset_univ _, ?_⟩
    rcases hsize A hA with h | h
    · exact h
    · have : A ∈ U := mem_filter.2 ⟨hA, h⟩
      rw [hU0] at this
      exact absurd this (notMem_empty _)
  · right
    have hUeq := eq_powersetCard_of_upper_closed U hUs
      (upper_closed_of_card_shadow_le hα U hUs hle) hU0
    have hUA : U = 𝒜 := by
      refine eq_of_subset_of_card_le (filter_subset _ _) ?_
      rw [hcard, hUeq, card_powersetCard, card_univ, hα]
      exact (Nat.choose_symm_of_eq_add (by omega)).le
    rw [← hUA, hUeq]

#print axioms antichain_odd_eq_layer

/-- **Sperner's theorem.** Take `n` things. A family `𝒜` of groups of them in which no member
sits inside another (an antichain) has at most `C(n, ⌊n/2⌋)` members, the size of the
middle layer. -/
theorem antichain_card_le_middle_choose {n : ℕ} (𝒜 : Finset (Finset (Fin n)))
    (h𝒜 : IsAntichain (· ⊆ ·) (𝒜 : Set (Finset (Fin n)))) :
    #𝒜 ≤ n.choose (n / 2) := by
  simpa using h𝒜.sperner

/-- **The LYM inequality.** Score each member `A` of an antichain of groups of `n` things
`1 / C(n, |A|)`; the scores add up to at most `1`. -/
theorem lym_sum_inv_choose_le_one {n : ℕ} (𝒜 : Finset (Finset (Fin n)))
    (h𝒜 : IsAntichain (· ⊆ ·) (𝒜 : Set (Finset (Fin n)))) :
    ∑ A ∈ 𝒜, (1 : ℚ) / n.choose #A ≤ 1 := by
  simpa [one_div] using lubell_yamamoto_meshalkin_inequality_sum_inv_choose (𝕜 := ℚ) h𝒜

/-- **Only a middle layer reaches the cap.** An antichain of groups of `n` things has exactly
`C(n, ⌊n/2⌋)` members if and only if it is the whole layer of groups of size `⌊n/2⌋` or the
whole layer of size `⌈n/2⌉`. For even `n` these are the same layer; for odd `n` there are two
winners. -/
theorem antichain_card_eq_middle_choose_iff {n : ℕ} (𝒜 : Finset (Finset (Fin n)))
    (h𝒜 : IsAntichain (· ⊆ ·) (𝒜 : Set (Finset (Fin n)))) :
    #𝒜 = n.choose (n / 2) ↔
      𝒜 = (univ : Finset (Fin n)).powersetCard (n / 2) ∨
        𝒜 = (univ : Finset (Fin n)).powersetCard ((n + 1) / 2) := by
  constructor
  · intro hcard
    have hsize : ∀ A ∈ 𝒜, #A = n / 2 ∨ #A = (n + 1) / 2 := by
      by_contra hcon
      push Not at hcon
      obtain ⟨A, hA, h1, h2⟩ := hcon
      have hAn : #A ≤ n := by simpa using card_le_univ A
      have hlt := choose_lt_middle_of_ne hAn h1 h2
      have hmid : (0 : ℚ) < n.choose (n / 2) := by
        exact_mod_cast Nat.choose_pos (Nat.div_le_self _ _)
      have hlym := lym_sum_inv_choose_le_one 𝒜 h𝒜
      have hlow : ∑ _B ∈ 𝒜, (1 : ℚ) / n.choose (n / 2) < ∑ B ∈ 𝒜, (1 : ℚ) / n.choose #B := by
        refine sum_lt_sum (fun B hB => ?_) ⟨A, hA, ?_⟩
        · have hBn : #B ≤ n := by simpa using card_le_univ B
          have hpos : (0 : ℚ) < n.choose #B := by exact_mod_cast Nat.choose_pos hBn
          gcongr
          exact_mod_cast Nat.choose_le_middle _ _
        · have hpos : (0 : ℚ) < n.choose #A := by exact_mod_cast Nat.choose_pos hAn
          gcongr
      rw [sum_const, nsmul_eq_mul, hcard, mul_one_div, div_self hmid.ne'] at hlow
      exact lt_irrefl _ (hlow.trans_le hlym)
    rcases Nat.even_or_odd' n with ⟨k, rfl | rfl⟩
    · left
      have hk : 2 * k / 2 = k := by omega
      rw [hk]
      refine eq_of_subset_of_card_le ?_ (by rw [card_powersetCard, card_univ, Fintype.card_fin, hcard, hk])
      intro A hA
      rw [mem_powersetCard]
      refine ⟨subset_univ _, ?_⟩
      rcases hsize A hA with h | h <;> omega
    · have hk1 : (2 * k + 1) / 2 = k := by omega
      have hk2 : (2 * k + 1 + 1) / 2 = k + 1 := by omega
      rw [hk1, hk2]
      rw [hk1] at hcard
      exact antichain_odd_eq_layer (Fintype.card_fin _) 𝒜 h𝒜
        (fun A hA => by rcases hsize A hA with h | h <;> omega) hcard
  · rintro (rfl | rfl)
    · rw [card_powersetCard, card_univ, Fintype.card_fin]
    · rw [card_powersetCard, card_univ, Fintype.card_fin, choose_half_succ_eq]

-- Managers 1, 2, 3, 4 are `0, 1, 2, 3` in `Fin 4`.
-- The 16 groups by size: 1, 4, 6, 4, 1.
example : (List.range 5).map
    (fun k => #((univ : Finset (Fin 4)).powersetCard k)) = [1, 4, 6, 4, 1] := by decide
-- The six pairs are an antichain with C(4, 2) = 6 members.
example : #((univ : Finset (Fin 4)).powersetCard 2) = 6 ∧ Nat.choose 4 2 = 6 ∧
    ∀ A ∈ (univ : Finset (Fin 4)).powersetCard 2,
      ∀ B ∈ (univ : Finset (Fin 4)).powersetCard 2, A ⊆ B → A = B := by decide
-- The vault book {1}, {2,3}, {2,4}, {3,4} is an antichain with no room left for any other group.
example : (∀ A ∈ ({{0}, {1, 2}, {1, 3}, {2, 3}} : Finset (Finset (Fin 4))),
      ∀ B ∈ ({{0}, {1, 2}, {1, 3}, {2, 3}} : Finset (Finset (Fin 4))), A ⊆ B → A = B) ∧
    ∀ B : Finset (Fin 4), B ∉ ({{0}, {1, 2}, {1, 3}, {2, 3}} : Finset (Finset (Fin 4))) →
      ∃ A ∈ ({{0}, {1, 2}, {1, 3}, {2, 3}} : Finset (Finset (Fin 4))), A ⊆ B ∨ B ⊆ A := by
  decide
-- Orders through each line, k!(4-k)!: 6, 4, 4, 4, so the book meets 18 of the 4! = 24 orders.
example : (∑ A ∈ ({{0}, {1, 2}, {1, 3}, {2, 3}} : Finset (Finset (Fin 4))),
    (#A).factorial * (4 - #A).factorial) = 18 ∧ Nat.factorial 4 = 24 := by decide
-- The vault book's LYM score: 1/4 + 3/6 = 3/4.
example : ∑ A ∈ ({{0}, {1, 2}, {1, 3}, {2, 3}} : Finset (Finset (Fin 4))),
    (1 : ℚ) / (Nat.choose 4 #A) = 3 / 4 := by
  rw [sum_insert (by decide), sum_insert (by decide), sum_insert (by decide), sum_singleton]
  have h1 : #({0} : Finset (Fin 4)) = 1 := by decide
  have h2 : #({1, 2} : Finset (Fin 4)) = 2 := by decide
  have h3 : #({1, 3} : Finset (Fin 4)) = 2 := by decide
  have h4 : #({2, 3} : Finset (Fin 4)) = 2 := by decide
  rw [h1, h2, h3, h4]
  norm_num [Nat.choose]
-- Mistake 1: the six pairs plus {1} have 7 lines, 3 nested pairs, and weight 30 of 24.
example : #(insert {0} ((univ : Finset (Fin 4)).powersetCard 2)) = 7 ∧
    #((((univ : Finset (Fin 4)).powersetCard 2)).filter (fun B => ({0} : Finset (Fin 4)) ⊆ B)) = 3 ∧
    (∑ A ∈ insert {0} ((univ : Finset (Fin 4)).powersetCard 2),
      (#A).factorial * (4 - #A).factorial) = 30 := by decide
-- Mistake 3: the four singles meet all 24 orders but have only 4 lines.
example : #((univ : Finset (Fin 4)).powersetCard 1) = 4 ∧
    (∑ A ∈ (univ : Finset (Fin 4)).powersetCard 1, (#A).factorial * (4 - #A).factorial) = 24 := by
  decide
-- Step 6: six chains cover the 16 groups, each nested step by step.
example :
    let chains : List (List (Finset (Fin 4))) :=
      [[∅, {0}, {0, 1}, {0, 1, 2}, univ], [{1}, {1, 2}, {1, 2, 3}], [{2}, {0, 2}, {0, 2, 3}],
        [{3}, {0, 3}, {0, 1, 3}], [{1, 3}], [{2, 3}]]
    (∀ B : Finset (Fin 4), ∃ c ∈ chains, B ∈ c) ∧ (chains.map List.length).sum = 16 ∧
      ∀ c ∈ chains, c.IsChain (· ⊆ ·) := by
  decide
-- n = 5: the 2-groups and the 3-groups each hold C(5, 2) = 10 sets.
example : #((univ : Finset (Fin 5)).powersetCard 2) = 10 ∧
    #((univ : Finset (Fin 5)).powersetCard 3) = 10 ∧ Nat.choose 5 2 = 10 := by decide
-- The cap C(n, ⌊n/2⌋) for n = 1 to 10.
example : (List.range 10).map (fun m => (m + 1).choose ((m + 1) / 2)) =
    [1, 2, 3, 6, 10, 20, 35, 70, 126, 252] := by decide

#print axioms antichain_card_le_middle_choose
#print axioms lym_sum_inv_choose_le_one
#print axioms antichain_card_eq_middle_choose_iff
