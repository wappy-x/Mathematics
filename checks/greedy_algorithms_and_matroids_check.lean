-- Greedy: the earliest-finish walk keeps the most talks one room can hold, it stays ahead of every other schedule talk by talk, and on a hereditary family heaviest-first greed finds a heaviest allowed set for every weighting of zero or more exactly when the family is a matroid, with the card's twelve talks checked.
import Mathlib.Combinatorics.Matroid.IndepAxioms
import Mathlib.Combinatorics.Matroid.Minor.Restrict
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Group.Finset.Piecewise

namespace GreedyMatroids

/-! ## Talks in one room

Talk `i` starts at time `s i` and finishes at `f i`, in any ordered time scale `α` (minutes in the
card's example). Two different talks clash when they overlap: `s i < f j` and `s j < f i`. A talk
that starts the minute another ends does not clash with it. -/

variable {ι α : Type*}

/-- A schedule: a set of talks no two of which clash. -/
def IsSchedule [LinearOrder α] (s f : ι → α) (S : Finset ι) : Prop :=
  ∀ i ∈ S, ∀ j ∈ S, i ≠ j → ¬ (s i < f j ∧ s j < f i)

instance [LinearOrder α] [DecidableEq ι] (s f : ι → α) : DecidablePred (IsSchedule s f) :=
  fun S => by unfold IsSchedule; infer_instance

/-- The earliest-finish walk. Walk down the list of talks (sorted so finishing times rise). Keep a
talk if nothing is kept yet, or if it starts no earlier than the last kept talk ends; otherwise
skip it. The first argument is the end of the last kept talk (`none` before any is kept). The
result lists the kept talks `g₁, g₂, …` in the order kept. -/
def earliestFinish [LinearOrder α] (s f : ι → α) : Option α → List ι → List ι
  | _, [] => []
  | none, i :: l => i :: earliestFinish s f (some (f i)) l
  | some e, i :: l =>
      if e ≤ s i then i :: earliestFinish s f (some (f i)) l else earliestFinish s f (some e) l

theorem ef_sublist [LinearOrder α] (s f : ι → α) :
    ∀ (e : Option α) (l : List ι), (earliestFinish s f e l).Sublist l
  | _, [] => by simp [earliestFinish]
  | none, i :: l => by
      simp only [earliestFinish]; exact (ef_sublist s f _ l).cons_cons i
  | some e, i :: l => by
      simp only [earliestFinish]; split_ifs
      · exact (ef_sublist s f _ l).cons_cons i
      · exact (ef_sublist s f _ l).cons i

theorem ef_start [LinearOrder α] (s f : ι → α) (hsf : ∀ i, s i < f i) :
    ∀ (e : α) (l : List ι), ∀ k ∈ earliestFinish s f (some e) l, e ≤ s k
  | _, [] => by simp [earliestFinish]
  | e, i :: l => by
      intro k hk
      simp only [earliestFinish] at hk
      split_ifs at hk with h
      · rcases List.mem_cons.1 hk with rfl | hk
        · exact h
        · exact h.trans ((hsf i).le.trans (ef_start s f hsf _ l k hk))
      · exact ef_start s f hsf e l k hk

theorem ef_pairwise [LinearOrder α] (s f : ι → α) (hsf : ∀ i, s i < f i) :
    ∀ (e : Option α) (l : List ι), (earliestFinish s f e l).Pairwise (fun i j => f i ≤ s j)
  | _, [] => by simp [earliestFinish]
  | none, i :: l => by
      simp only [earliestFinish]
      exact List.pairwise_cons.2 ⟨fun k hk => ef_start s f hsf _ l k hk, ef_pairwise s f hsf _ l⟩
  | some e, i :: l => by
      simp only [earliestFinish]; split_ifs
      · exact List.pairwise_cons.2 ⟨fun k hk => ef_start s f hsf _ l k hk, ef_pairwise s f hsf _ l⟩
      · exact ef_pairwise s f hsf _ l

theorem pairwise_or {R : ι → ι → Prop} :
    ∀ l : List ι, l.Pairwise R → ∀ a ∈ l, ∀ b ∈ l, a ≠ b → R a b ∨ R b a
  | [], _ => by simp
  | x :: l, h => by
      intro a ha b hb hab
      rw [List.pairwise_cons] at h
      rcases List.mem_cons.1 ha with ha' | ha' <;> rcases List.mem_cons.1 hb with hb' | hb'
      · exact absurd (ha'.trans hb'.symm) hab
      · rw [ha']; exact Or.inl (h.1 b hb')
      · rw [hb']; exact Or.inr (h.1 a ha')
      · exact pairwise_or l h.2 a ha' b hb' hab

theorem ef_ahead [LinearOrder α] (s f : ι → α) (hsf : ∀ i, s i < f i) :
    ∀ (e : Option α) (l : List ι), l.Pairwise (fun i j => f i ≤ f j) →
    ∀ (o : List ι), o.Pairwise (fun i j => f i ≤ s j) → (∀ k ∈ o, k ∈ l) →
    (∀ k ∈ o, ∀ e', e = some e' → e' ≤ s k) →
    (∀ (j : ℕ) (hg : j < (earliestFinish s f e l).length) (hj : j < o.length),
        f (earliestFinish s f e l)[j] ≤ f o[j]) ∧
      o.length ≤ (earliestFinish s f e l).length
  | _, [], _, o, _, hol, _ => by
      cases o with
      | nil => simp
      | cons k o => exact absurd (hol k (by simp)) (by simp)
  | e, i :: l, hl, o, ho, hol, hoe => by
      have hl' := List.pairwise_cons.1 hl
      have keep : (∀ (j : ℕ) (hg : j < (i :: earliestFinish s f (some (f i)) l).length)
          (hj : j < o.length), f (i :: earliestFinish s f (some (f i)) l)[j] ≤ f o[j]) ∧
          o.length ≤ (i :: earliestFinish s f (some (f i)) l).length := by
        cases o with
        | nil => simp
        | cons k o =>
          have ho' := List.pairwise_cons.1 ho
          have hik : f i ≤ f k := by
            rcases List.mem_cons.1 (hol k (by simp)) with h | h
            · rw [h]
            · exact hl'.1 k h
          have IH := ef_ahead s f hsf (some (f i)) l hl'.2 o ho'.2
            (fun m hm => by
              have h1 : f i ≤ s m := hik.trans (ho'.1 m hm)
              rcases List.mem_cons.1 (hol m (by simp [hm])) with h | h
              · rw [h] at h1; exact absurd h1 (not_le.2 (hsf _))
              · exact h)
            (fun m hm e' he' => by cases he'; exact hik.trans (ho'.1 m hm))
          refine ⟨fun j hg hj => ?_, by simpa using IH.2⟩
          cases j with
          | zero => simpa using hik
          | succ j => simpa using IH.1 j (by simpa using hg) (by simpa using hj)
      cases e with
      | none => exact keep
      | some e =>
        simp only [earliestFinish]
        split_ifs with h
        · exact keep
        · exact ef_ahead s f hsf (some e) l hl'.2 o ho
            (fun m hm => by
              rcases List.mem_cons.1 (hol m hm) with h' | h'
              · rw [h'] at hm; exact absurd (hoe i hm e rfl) h
              · exact h')
            hoe

/-- **Earliest finish keeps the most talks.** One room, fixed times, every talk counting the
same. Sort all the talks so that finishing times rise, with ties in any order, and run the
earliest-finish walk. The talks it keeps form a schedule, and no schedule holds more talks. -/
theorem earliest_finish_keeps_most_talks [LinearOrder α] [Fintype ι] [DecidableEq ι]
    (s f : ι → α) (hsf : ∀ i, s i < f i)
    (order : List ι) (hnodup : order.Nodup) (hall : ∀ i, i ∈ order)
    (hsorted : order.Pairwise (fun i j => f i ≤ f j)) :
    (earliestFinish s f none order).Nodup ∧
      IsSchedule s f (earliestFinish s f none order).toFinset ∧
      ∀ S : Finset ι, IsSchedule s f S → S.card ≤ (earliestFinish s f none order).length := by
  refine ⟨(ef_sublist s f none order).nodup hnodup, ?_, ?_⟩
  · intro i hi j hj hij hov
    rw [List.mem_toFinset] at hi hj
    rcases pairwise_or _ (ef_pairwise s f hsf none order) i hi j hj hij with h | h
    · exact absurd hov.2 (not_lt.2 h)
    · exact absurd hov.1 (not_lt.2 h)
  · intro S hS
    let le : ι → ι → Bool := fun i j => decide (f i ≤ f j)
    have hperm : (S.toList.mergeSort le).Perm S.toList := List.mergeSort_perm _ _
    have hsort : (S.toList.mergeSort le).Pairwise (fun i j => le i j) :=
      List.pairwise_mergeSort (fun a b c hab hbc => by
          simp only [le, decide_eq_true_eq] at *; exact hab.trans hbc)
        (fun a b => by simp only [le, Bool.or_eq_true, decide_eq_true_eq]; exact le_total _ _) _
    have hnd : (S.toList.mergeSort le).Nodup := hperm.nodup_iff.2 (Finset.nodup_toList S)
    have ho : (S.toList.mergeSort le).Pairwise (fun i j => f i ≤ s j) := by
      refine (List.Pairwise.and hsort hnd).imp_of_mem ?_
      intro a b ha hb hab
      have ha' : a ∈ S := by simpa using hperm.subset ha
      have hb' : b ∈ S := by simpa using hperm.subset hb
      have h1 : f a ≤ f b := by simpa [le] using hab.1
      have := hS a ha' b hb' hab.2
      exact not_lt.1 fun h => this ⟨(hsf a).trans_le h1, h⟩
    have := (ef_ahead s f hsf none order hsorted _ ho (fun k _ => hall k)
      (fun _ _ _ h => by cases h)).2
    rw [hperm.length_eq, Finset.length_toList] at this
    exact this

/-- **Staying ahead.** Under the same conditions, take any other schedule and list its talks in
time order, `o₁, o₂, …, oₘ`, each starting no earlier than the one before ends. Then greedy's
`j`-th talk ends no later than the other schedule's `j`-th talk, for every `j` up to the smaller
of the two counts, and so greedy keeps at least as many talks: `k ≥ m`. -/
theorem earliest_finish_stays_ahead [LinearOrder α] [Fintype ι] [DecidableEq ι]
    (s f : ι → α) (hsf : ∀ i, s i < f i)
    (order : List ι) (hnodup : order.Nodup) (hall : ∀ i, i ∈ order)
    (hsorted : order.Pairwise (fun i j => f i ≤ f j))
    (o : List ι) (ho : o.Pairwise (fun i j => f i ≤ s j)) :
    (∀ (j : ℕ) (hg : j < (earliestFinish s f none order).length) (hj : j < o.length),
        f (earliestFinish s f none order)[j] ≤ f o[j]) ∧
      o.length ≤ (earliestFinish s f none order).length := by
  exact ef_ahead s f hsf none order hsorted o ho (fun k _ => hall k) (fun _ _ _ h => by cases h)

/-! ## Heaviest-first greed and matroids

A family of allowed sets of items is a predicate `Allowed` on finite sets of items. -/

/-- The greedy walk: go down the list of items and keep each one that still leaves an allowed
set. The first argument is the set kept so far. Heaviest-first greed is this walk on a list
sorted from heaviest to lightest, started from the empty set. -/
def greedy {β : Type*} [DecidableEq β] (Allowed : Finset β → Prop) [DecidablePred Allowed] :
    Finset β → List β → Finset β
  | K, [] => K
  | K, x :: l =>
      if Allowed (insert x K) then greedy Allowed (insert x K) l else greedy Allowed K l

section GreedyHelpers

variable {β : Type*} [DecidableEq β] (Allowed : Finset β → Prop) [DecidablePred Allowed]

theorem greedy_allowed : ∀ (K : Finset β) (l : List β), Allowed K → Allowed (greedy Allowed K l)
  | K, [], h => by simpa [greedy] using h
  | K, x :: l, h => by
      simp only [greedy]; split_ifs with hx
      · exact greedy_allowed _ l hx
      · exact greedy_allowed _ l h

theorem greedy_subset : ∀ (K : Finset β) (l : List β), K ⊆ greedy Allowed K l
  | K, [] => by simp [greedy]
  | K, x :: l => by
      simp only [greedy]; split_ifs
      · exact (Finset.subset_insert x K).trans (greedy_subset _ l)
      · exact greedy_subset _ l

theorem greedy_subset_union : ∀ (K : Finset β) (l : List β), greedy Allowed K l ⊆ K ∪ l.toFinset
  | K, [] => by simp [greedy]
  | K, x :: l => by
      simp only [greedy]; split_ifs
      · refine (greedy_subset_union _ l).trans ?_
        intro y hy; simp only [Finset.mem_union, Finset.mem_insert, List.mem_toFinset,
          List.mem_cons] at hy ⊢; tauto
      · refine (greedy_subset_union _ l).trans ?_
        intro y hy; simp only [Finset.mem_union, List.mem_toFinset, List.mem_cons] at hy ⊢; tauto

theorem greedy_append : ∀ (K : Finset β) (l₁ l₂ : List β),
    greedy Allowed K (l₁ ++ l₂) = greedy Allowed (greedy Allowed K l₁) l₂
  | K, [], l₂ => rfl
  | K, x :: l, l₂ => by
      simp only [List.cons_append, greedy]; split_ifs
      · exact greedy_append _ l l₂
      · exact greedy_append _ l l₂

theorem greedy_takes_all (hher : ∀ I J : Finset β, Allowed J → I ⊆ J → Allowed I) :
    ∀ (K : Finset β) (l : List β), Allowed (K ∪ l.toFinset) → greedy Allowed K l = K ∪ l.toFinset
  | K, [], _ => by simp [greedy]
  | K, x :: l, h => by
      have hx : Allowed (insert x K) := hher _ _ h (by
        intro y hy; simp only [Finset.mem_insert, Finset.mem_union, List.mem_toFinset,
          List.mem_cons] at hy ⊢; tauto)
      have heq : insert x K ∪ l.toFinset = K ∪ (x :: l).toFinset := by
        ext y; simp only [Finset.mem_insert, Finset.mem_union, List.mem_toFinset,
          List.mem_cons]; tauto
      simp only [greedy, if_pos hx]
      rw [greedy_takes_all hher _ l (by rw [heq]; exact h), heq]

theorem greedy_takes_none : ∀ (K : Finset β) (l : List β),
    (∀ x ∈ l, ¬ Allowed (insert x K)) → greedy Allowed K l = K
  | K, [], _ => by simp [greedy]
  | K, x :: l, h => by
      simp only [greedy, if_neg (h x (by simp))]
      exact greedy_takes_none K l (fun y hy => h y (by simp [hy]))

theorem allowed_extend (haug : ∀ I J : Finset β, Allowed I → Allowed J → I.card < J.card →
      ∃ e ∈ J, e ∉ I ∧ Allowed (insert e I)) :
    ∀ n : ℕ, ∀ I J : Finset β, J.card - I.card = n → Allowed I → Allowed J →
      ∃ B, I ⊆ B ∧ B ⊆ I ∪ J ∧ Allowed B ∧ J.card ≤ B.card
  | 0 => fun I J hn hI _ => ⟨I, subset_rfl, Finset.subset_union_left, hI, by omega⟩
  | n + 1 => fun I J hn hI hJ => by
      obtain ⟨e, heJ, heI, he⟩ := haug I J hI hJ (by omega)
      obtain ⟨B, h1, h2, h3, h4⟩ := allowed_extend haug n (insert e I) J
        (by rw [Finset.card_insert_of_notMem heI]; omega) he hJ
      refine ⟨B, (Finset.subset_insert _ _).trans h1, h2.trans ?_, h3, h4⟩
      intro y hy
      simp only [Finset.mem_union, Finset.mem_insert] at hy ⊢
      rcases hy with (hy | hy) | hy
      · exact Or.inr (hy ▸ heJ)
      · exact Or.inl hy
      · exact Or.inr hy

theorem greedy_optimal (hher : ∀ I J : Finset β, Allowed J → I ⊆ J → Allowed I)
    (haug : ∀ I J : Finset β, Allowed I → Allowed J → I.card < J.card →
      ∃ e ∈ J, e ∉ I ∧ Allowed (insert e I)) (w : β → ℝ) (hw : ∀ x, 0 ≤ w x) :
    ∀ (l : List β) (K J : Finset β), l.Pairwise (fun x y => w y ≤ w x) → Allowed J → K ⊆ J →
      J ⊆ K ∪ l.toFinset → ∑ x ∈ J, w x ≤ ∑ x ∈ greedy Allowed K l, w x
  | [], K, J, _, _, hKJ, hJK => by
      have : J = K := Finset.Subset.antisymm (by simpa using hJK) hKJ
      simp [greedy, this]
  | x :: l, K, J, hl, hJ, hKJ, hJK => by
      have hl' := List.pairwise_cons.1 hl
      simp only [greedy]
      split_ifs with hx
      · by_cases hxJ : x ∈ J
        · refine greedy_optimal hher haug w hw l (insert x K) J hl'.2 hJ
            (Finset.insert_subset hxJ hKJ) ?_
          intro y hy
          have := hJK hy
          simp only [Finset.mem_union, Finset.mem_insert, List.mem_toFinset,
            List.mem_cons] at this ⊢
          tauto
        · obtain ⟨B, hB1, hB2, hB3, hB4⟩ :=
            allowed_extend Allowed haug _ (insert x K) J rfl hx hJ
          have hxB : x ∈ B := hB1 (Finset.mem_insert_self _ _)
          have hBJ : B.erase x ⊆ J := by
            intro y hy
            rw [Finset.mem_erase] at hy
            have := hB2 hy.2
            simp only [Finset.mem_union, Finset.mem_insert] at this
            rcases this with (h | h) | h
            · exact absurd h hy.1
            · exact hKJ h
            · exact h
          have hcard : (J \ B.erase x).card ≤ 1 := by
            rw [Finset.card_sdiff_of_subset hBJ, Finset.card_erase_of_mem hxB]; omega
          have hsmall : ∀ y ∈ J \ B.erase x, w y ≤ w x := by
            intro y hy
            rw [Finset.mem_sdiff, Finset.mem_erase] at hy
            have hyx : y ≠ x := fun h => hxJ (h ▸ hy.1)
            have hyB : y ∉ B := fun h => hy.2 ⟨hyx, h⟩
            have hyK : y ∉ K := fun h => hyB (hB1 (Finset.mem_insert_of_mem h))
            have := hJK hy.1
            simp only [Finset.mem_union, List.mem_toFinset, List.mem_cons] at this
            rcases this with h | h | h
            · exact absurd h hyK
            · exact absurd h hyx
            · exact hl'.1 y h
          have hJB : ∑ y ∈ J, w y ≤ ∑ y ∈ B, w y := by
            rw [← Finset.sum_sdiff hBJ, ← Finset.add_sum_erase B w hxB]
            have : ∑ y ∈ J \ B.erase x, w y ≤ w x := by
              calc ∑ y ∈ J \ B.erase x, w y ≤ (J \ B.erase x).card • w x :=
                    Finset.sum_le_card_nsmul _ _ _ hsmall
                _ ≤ w x := by
                    rw [nsmul_eq_mul]
                    exact mul_le_of_le_one_left (hw x) (by exact_mod_cast hcard)
            linarith
          refine hJB.trans (greedy_optimal hher haug w hw l (insert x K) B hl'.2 hB3 hB1 ?_)
          intro y hy
          have h1 := hB2 hy
          simp only [Finset.mem_union, Finset.mem_insert] at h1
          rcases h1 with h1 | h1
          · exact Finset.mem_union_left _ (Finset.mem_insert.2 h1)
          · have := hJK h1
            simp only [Finset.mem_union, Finset.mem_insert, List.mem_toFinset,
              List.mem_cons] at this ⊢
            tauto
      · have hxJ : x ∉ J := fun h => hx (hher _ _ hJ (Finset.insert_subset h hKJ))
        refine greedy_optimal hher haug w hw l K J hl'.2 hJ hKJ ?_
        intro y hy
        have := hJK hy
        simp only [Finset.mem_union, List.mem_toFinset, List.mem_cons] at this ⊢
        rcases this with h | h | h
        · exact Or.inl h
        · exact absurd (h ▸ hy) hxJ
        · exact Or.inr h

end GreedyHelpers

/-- **Rado (1957) and Edmonds (1971).** Take a finite set of items and a hereditary family of
allowed sets (every part of an allowed set is allowed). Heaviest-first greed finds a heaviest
allowed set for every choice of weights of zero or more, and every way of ordering ties, if and
only if the family is a matroid: the independent sets of some matroid on all the items. -/
theorem heaviest_first_greedy_optimal_iff_matroid {β : Type*} [Fintype β] [DecidableEq β]
    (Allowed : Finset β → Prop) [DecidablePred Allowed]
    (hher : ∀ I J : Finset β, Allowed J → I ⊆ J → Allowed I) :
    (∀ w : β → ℝ, (∀ x, 0 ≤ w x) →
      ∀ order : List β, order.Nodup → (∀ x, x ∈ order) →
        order.Pairwise (fun x y => w y ≤ w x) →
          Allowed (greedy Allowed ∅ order) ∧
            ∀ J : Finset β, Allowed J → ∑ x ∈ J, w x ≤ ∑ x ∈ greedy Allowed ∅ order, w x) ↔
      ∃ M : Matroid β, M.E = Set.univ ∧ ∀ I : Finset β, M.Indep (I : Set β) ↔ Allowed I := by
  constructor
  · intro H
    obtain ⟨order0, hnd0, hall0⟩ : ∃ l : List β, l.Nodup ∧ ∀ x, x ∈ l :=
      ⟨Finset.univ.toList, Finset.nodup_toList _, by simp⟩
    have hempty : Allowed ∅ :=
      hher _ _ (H (fun _ => 0) (fun _ => le_rfl) order0 hnd0 hall0
        (hnd0.imp fun _ => le_rfl)).1 (Finset.empty_subset _)
    have haug : ∀ I J : Finset β, Allowed I → Allowed J → I.card < J.card →
        ∃ e ∈ J, e ∉ I ∧ Allowed (insert e I) := by
      intro I J hI hJ hIJ
      by_contra hcon
      push_neg at hcon
      set m := (I \ J).card with hm
      let w : β → ℝ := fun x => if x ∈ I then (m : ℝ) + 2 else if x ∈ J then (m : ℝ) + 1 else 0
      have hw : ∀ x, 0 ≤ w x := by
        intro x; simp only [w]; split_ifs <;> positivity
      let l1 := I.toList
      let l2 := (J \ I).toList
      let l3 := (Finset.univ \ (I ∪ J)).toList
      have hm1 : ∀ x ∈ l1, w x = (m : ℝ) + 2 := by
        intro x hx; simp only [l1, Finset.mem_toList] at hx; simp [w, hx]
      have hm2 : ∀ x ∈ l2, w x = (m : ℝ) + 1 := by
        intro x hx
        simp only [l2, Finset.mem_toList, Finset.mem_sdiff] at hx; simp [w, hx.1, hx.2]
      have hm3 : ∀ x ∈ l3, w x = 0 := by
        intro x hx
        simp only [l3, Finset.mem_toList, Finset.mem_sdiff, Finset.mem_univ, true_and,
          Finset.mem_union, not_or] at hx
        simp [w, hx.1, hx.2]
      have hnd : (l1 ++ l2 ++ l3).Nodup := by
        rw [List.nodup_append, List.nodup_append]
        refine ⟨⟨Finset.nodup_toList _, Finset.nodup_toList _, ?_⟩, Finset.nodup_toList _, ?_⟩
        · intro a ha b hb hab; subst hab
          simp only [l1, l2, Finset.mem_toList, Finset.mem_sdiff] at ha hb; exact hb.2 ha
        · intro a ha b hb hab; subst hab
          simp only [l1, l2, l3, List.mem_append, Finset.mem_toList, Finset.mem_sdiff,
            Finset.mem_univ, true_and, Finset.mem_union, not_or] at ha hb
          tauto
      have hall : ∀ x, x ∈ l1 ++ l2 ++ l3 := by
        intro x
        simp only [l1, l2, l3, List.mem_append, Finset.mem_toList, Finset.mem_sdiff,
          Finset.mem_univ, true_and, Finset.mem_union, not_or]
        tauto
      have hsort : (l1 ++ l2 ++ l3).Pairwise (fun x y => w y ≤ w x) := by
        rw [List.pairwise_append, List.pairwise_append]
        refine ⟨⟨?_, ?_, ?_⟩, ?_, ?_⟩
        · exact (Finset.nodup_toList I).imp_of_mem fun ha hb _ => by rw [hm1 _ ha, hm1 _ hb]
        · exact (Finset.nodup_toList (J \ I)).imp_of_mem fun ha hb _ => by
            rw [hm2 _ ha, hm2 _ hb]
        · intro a ha b hb; rw [hm1 a ha, hm2 b hb]; linarith
        · exact (Finset.nodup_toList _).imp_of_mem fun ha hb _ => by rw [hm3 _ ha, hm3 _ hb]
        · intro a ha b hb
          rw [hm3 b hb]
          exact hw a
      have hG : greedy Allowed ∅ (l1 ++ l2 ++ l3) = greedy Allowed I l3 := by
        rw [greedy_append, greedy_append,
          greedy_takes_all Allowed hher ∅ l1 (by simpa [l1] using hI)]
        have : (∅ : Finset β) ∪ l1.toFinset = I := by simp [l1]
        rw [this, greedy_takes_none Allowed I l2]
        intro x hx
        simp only [l2, Finset.mem_toList, Finset.mem_sdiff] at hx
        exact hcon x hx.1 hx.2
      have hopt := (H w hw _ hnd hall hsort).2 J hJ
      rw [hG] at hopt
      have h1 : ∑ x ∈ greedy Allowed I l3, w x = ∑ x ∈ I, w x := by
        symm
        apply Finset.sum_subset (greedy_subset Allowed I l3)
        intro x hx hxI
        have := greedy_subset_union Allowed I l3 hx
        simp only [Finset.mem_union, List.mem_toFinset, l3, Finset.mem_toList,
          Finset.mem_sdiff, Finset.mem_univ, true_and, not_or] at this
        rcases this with h | h
        · exact absurd h hxI
        · simp [w, h.1, h.2]
      have h2 : ∑ x ∈ I, w x = I.card * ((m : ℝ) + 2) := by
        rw [Finset.sum_congr rfl (fun x hx => show w x = (m : ℝ) + 2 by simp [w, hx]),
          Finset.sum_const, nsmul_eq_mul]
      have h3 : ∑ x ∈ J, w x = (J ∩ I).card * ((m : ℝ) + 2) + (J \ I).card * ((m : ℝ) + 1) := by
        rw [← Finset.sum_inter_add_sum_sdiff J I w,
          Finset.sum_congr rfl (fun x hx => show w x = (m : ℝ) + 2 by
            simp [w, (Finset.mem_inter.1 hx).2]),
          Finset.sum_congr rfl (fun x hx => show w x = (m : ℝ) + 1 by
            simp [w, (Finset.mem_sdiff.1 hx).1, (Finset.mem_sdiff.1 hx).2]),
          Finset.sum_const, Finset.sum_const, nsmul_eq_mul, nsmul_eq_mul]
      have c1 : (I ∩ J).card + (I \ J).card = I.card := Finset.card_inter_add_card_sdiff I J
      have c2 : (J ∩ I).card + (J \ I).card = J.card := Finset.card_inter_add_card_sdiff J I
      have c3 : (J ∩ I).card = (I ∩ J).card := by rw [Finset.inter_comm]
      have c4 : m + 1 ≤ (J \ I).card := by omega
      have c4' : (m : ℝ) + 1 ≤ ((J \ I).card : ℝ) := by exact_mod_cast c4
      have c1' : ((I.card : ℕ) : ℝ) = ((J ∩ I).card : ℝ) + m := by
        rw [hm]; exact_mod_cast (by omega : I.card = (J ∩ I).card + (I \ J).card)
      rw [h1, h2, h3, c1'] at hopt
      nlinarith
    refine ⟨(IndepMatroid.ofFinset Set.univ Allowed hempty (fun I J hJ hIJ => hher I J hJ hIJ)
      (fun I J hI hJ hIJ => haug I J hI hJ hIJ) (fun _ _ => Set.subset_univ _)).matroid, rfl, ?_⟩
    intro I
    simp
  · rintro ⟨M, -, hMI⟩ w hw order _ hall hsort
    have haug : ∀ I J : Finset β, Allowed I → Allowed J → I.card < J.card →
        ∃ e ∈ J, e ∉ I ∧ Allowed (insert e I) := by
      intro I J hI hJ hIJ
      obtain ⟨e, he, heI, hi⟩ := ((hMI I).2 hI).augment_finset ((hMI J).2 hJ) hIJ
      exact ⟨e, he, heI, (hMI _).1 (by simpa using hi)⟩
    have hempty : Allowed ∅ := (hMI ∅).1 (by simpa using M.empty_indep)
    exact ⟨greedy_allowed Allowed ∅ order hempty, fun J hJ =>
      greedy_optimal Allowed hher haug w hw order ∅ J hsort hJ (Finset.empty_subset _)
        (fun x _ => by simp [hall x])⟩

/-! ## The card's twelve talks

Talks A to L are `0` to `11`; times are minutes after midnight (9:00 is 540). -/

/-- Start times: A 9:00, B 9:30, C 10:00, D 10:45, E 11:45, F 12:15, G 13:00, H 13:50,
I 14:30, J 15:00, K 16:00, L 17:15. -/
def st : Fin 12 → ℕ := ![540, 570, 600, 645, 705, 735, 780, 830, 870, 900, 960, 1035]

/-- Finish times: A 13:00, B 10:30, C 11:15, D 12:00, E 12:30, F 13:30, G 14:00, H 14:40,
I 15:30, J 16:30, K 17:30, L 18:00. -/
def fi : Fin 12 → ℕ := ![780, 630, 675, 720, 750, 810, 840, 880, 930, 990, 1050, 1080]

/-- Expected audiences: A 120, B 60, C 50, D 70, E 55, F 40, G 80, H 30, I 75, J 65, K 90, L 35. -/
def aud : Fin 12 → ℕ := ![120, 60, 50, 70, 55, 40, 80, 30, 75, 65, 90, 35]

/-- The talks sorted by finishing time: B C D E A F G H I J K L. -/
def byFinish : List (Fin 12) := [1, 2, 3, 4, 0, 5, 6, 7, 8, 9, 10, 11]

-- Every talk ends after it starts, and the list is sorted by finishing time.
example : ∀ i, st i < fi i := by decide
example : byFinish.Pairwise (fun i j => fi i ≤ fi j) := by decide
-- The earliest-finish walk keeps B, D, F, H, J and L: six talks.
example : earliestFinish st fi none byFinish = [1, 3, 5, 7, 9, 11] := by decide
-- Of the 4096 subsets, 254 are schedules; none holds more than 6 talks, and only B D F H J L holds 6.
example : (Finset.univ : Finset (Finset (Fin 12))).card = 4096 := by
  rw [Finset.card_univ, Fintype.card_finset, Fintype.card_fin]; norm_num
example : (Finset.univ.filter (IsSchedule st fi)).card = 254 := by decide +kernel
example : (Finset.univ.filter (IsSchedule st fi)).sup Finset.card = 6 := by decide +kernel
example : Finset.univ.filter (fun S : Finset (Fin 12) => IsSchedule st fi S ∧ S.card = 6) =
    {{1, 3, 5, 7, 9, 11}} := by decide +kernel
-- Other rules, walking a different order and keeping each talk that still fits:
-- earliest start keeps A, G, I, K (4 talks),
example : greedy (IsSchedule st fi) ∅ [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] = {0, 6, 8, 10} := by
  decide
-- shortest first (ties by start) keeps B, E, H, J, L (5 talks),
example : greedy (IsSchedule st fi) ∅ [4, 11, 7, 1, 6, 8, 2, 3, 5, 9, 10, 0] = {1, 4, 7, 9, 11} := by
  decide
-- fewest clashes (ties by start) keeps B, D, G, I, L (5 talks).
example : greedy (IsSchedule st fi) ∅ [11, 1, 6, 7, 8, 9, 10, 2, 3, 4, 5, 0] = {1, 3, 6, 8, 11} := by
  decide
-- Biggest audience first keeps A, G, I, K: 365 people.
example : greedy (IsSchedule st fi) ∅ [0, 10, 6, 8, 3, 9, 1, 4, 2, 5, 11, 7] = {0, 6, 8, 10} := by
  decide
example : ∑ i ∈ ({0, 6, 8, 10} : Finset (Fin 12)), aud i = 365 := by decide
-- The best schedule, B D G I K, draws 375, and no schedule draws more; earliest finish draws 300.
example : IsSchedule st fi {1, 3, 6, 8, 10} ∧ ∑ i ∈ ({1, 3, 6, 8, 10} : Finset (Fin 12)), aud i = 375 := by
  decide
example : (Finset.univ.filter (IsSchedule st fi)).sup (fun S => ∑ i ∈ S, aud i) = 375 := by
  decide +kernel
example : ∑ i ∈ ({1, 3, 5, 7, 9, 11} : Finset (Fin 12)), aud i = 300 := by decide
-- The exchange property fails: {B, D} is bigger than {A}, yet neither B nor D can join A.
example : IsSchedule st fi {0} ∧ IsSchedule st fi {1, 3} ∧
    ¬ IsSchedule st fi {1, 0} ∧ ¬ IsSchedule st fi {3, 0} := by decide
-- B and D together outweigh A: 60 + 70 = 130 against 120.
example : aud 1 + aud 3 = 130 ∧ aud 0 = 120 := by decide
-- The converse weights with p = 1: greed gets p(p + 2) = 3, the bigger set (p + 1)² = 4.
example : (1 : ℕ) * (1 + 2) < (1 + 1) * (1 + 1) := by norm_num
-- Coins 1, 3, 4 for 6: greed pays 4 + 1 + 1, three coins; 3 + 3 is two.
example : 4 + 1 + 1 = 6 ∧ 3 + 3 = 6 := by norm_num

#print axioms ef_sublist
#print axioms ef_start
#print axioms ef_pairwise
#print axioms pairwise_or
#print axioms ef_ahead
#print axioms greedy_allowed
#print axioms greedy_subset
#print axioms greedy_subset_union
#print axioms greedy_append
#print axioms greedy_takes_all
#print axioms greedy_takes_none
#print axioms allowed_extend
#print axioms greedy_optimal
#print axioms earliest_finish_keeps_most_talks
#print axioms earliest_finish_stays_ahead
#print axioms heaviest_first_greedy_optimal_iff_matroid

end GreedyMatroids
