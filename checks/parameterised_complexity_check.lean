-- Parameterised complexity: the bounded search tree and the Buss-Goldsmith kernel decide whether at most k officers can watch every street, in at most (k + 1)m + 2^(k+1) k^2 counted steps.
import Mathlib.Combinatorics.SimpleGraph.VertexCover
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum.BigOperators
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open SimpleGraph

/-! The plan is a Mathlib `SimpleGraph G` on junctions `V`; a set of officers watching every
street is Mathlib's `G.IsVertexCover`. The method reads the plan as a list of streets, each a
pair of its two ends. The code below is the card's Python, step for step: a "node" is one call
of the search, and a "step" is one street looked at. -/

variable {V : Type*} [DecidableEq V]

/-- `es` lists the streets of `G`, each street exactly once, as a pair of its two ends. -/
def IsStreetList (G : SimpleGraph V) (es : List (V × V)) : Prop :=
  (es.map fun e => s(e.1, e.2)).Nodup ∧
    ∀ e : Sym2 V, e ∈ es.map (fun e => s(e.1, e.2)) ↔ e ∈ G.edgeSet

/-- Look through the streets in order for one with no officer at either end. Gives that street,
if there is one, and the number of streets looked at. -/
def firstOpen (on : List V) : List (V × V) → Option (V × V) × ℕ
  | [] => (none, 0)
  | e :: rest =>
    if e.1 ∈ on ∨ e.2 ∈ on then ((firstOpen on rest).1, (firstOpen on rest).2 + 1)
    else (some e, 1)

/-- What a run reports: the answer, the nodes of the search tree, and the steps. -/
structure Run where
  yes : Bool
  nodes : ℕ
  steps : ℕ
deriving DecidableEq

/-- Road 1, the bounded search tree, with `k` officers left and officers already at `on`. An
unwatched street `(u, v)` needs an officer at `u` or at `v`; try `u`, and if that fails, `v`. -/
def searchTree (es : List (V × V)) : ℕ → List V → Run
  | 0, on =>
    match firstOpen on es with
    | (none, s) => ⟨true, 1, s⟩
    | (some _, s) => ⟨false, 1, s⟩
  | k + 1, on =>
    match firstOpen on es with
    | (none, s) => ⟨true, 1, s⟩
    | (some (u, v), s) =>
      let a := searchTree es k (u :: on)
      if a.yes then ⟨true, a.nodes + 1, a.steps + s⟩
      else
        let b := searchTree es k (v :: on)
        ⟨b.yes, a.nodes + b.nodes + 1, a.steps + b.steps + s⟩

/-- The streets of the list `st` that meet junction `w`. -/
def degIn (st : List (V × V)) (w : V) : ℕ :=
  st.countP fun e => e.1 = w ∨ e.2 = w

/-- Rule 1's junctions: those meeting more than `k` of the streets `st`. -/
def high (st : List (V × V)) (k : ℕ) : List V :=
  ((st.flatMap fun e => [e.1, e.2]).dedup).filter fun w => k < degIn st w

/-- What the kernel reports: Rule 2's verdict (`alive` is false when the answer is already no),
the junctions forced by Rule 1, the streets left, the budget left `k'`, and the steps. -/
structure Kernel (V : Type*) where
  alive : Bool
  forced : List V
  rest : List (V × V)
  budget : ℕ
  steps : ℕ

/-- Road 2, part one: the Buss-Goldsmith kernel, for at most `rounds` rounds. Each round reads
every street once to count degrees. If Rule 1 forces no junction, or more than `k`, it stops
and applies Rule 2: carry on only if at most `k` were forced and at most `k * k` streets are
left. Otherwise it places officers at the forced junctions, removes their streets, lowers `k`
and goes round again. Each round but the last spends an officer, so `k + 1` rounds suffice. -/
def kernel : ℕ → List (V × V) → ℕ → Kernel V
  | rounds, st, k =>
    let b := high st k
    let stop : Kernel V := ⟨decide (b.length ≤ k ∧ st.length ≤ k * k), [], st, k, st.length⟩
    match rounds with
    | 0 => stop
    | r + 1 =>
      if b = [] ∨ k < b.length then stop
      else
        let t := kernel r (st.filter fun e => e.1 ∉ b ∧ e.2 ∉ b) (k - b.length)
        ⟨t.alive, b ++ t.forced, t.rest, t.budget, t.steps + st.length⟩

/-- Road 2: the kernel, then the bounded search tree on the streets left, with the budget left.
Gives the answer and the total steps. -/
def kernelThenTree (es : List (V × V)) (k : ℕ) : Bool × ℕ :=
  let r := kernel (k + 1) es k
  if r.alive then
    let t := searchTree r.rest r.budget r.forced
    (t.yes, r.steps + t.steps)
  else (false, r.steps)

/-! Helper lemmas for the three theorems below. -/
theorem firstOpen_steps_le (on : List V) (es : List (V × V)) : (firstOpen on es).2 ≤ es.length := by
  induction es with
  | nil => simp [firstOpen]
  | cons e rest ih =>
    simp only [firstOpen]
    split_ifs <;> simp only [List.length_cons] <;> omega

theorem firstOpen_none (on : List V) (es : List (V × V)) (h : (firstOpen on es).1 = none) :
    ∀ e ∈ es, e.1 ∈ on ∨ e.2 ∈ on := by
  induction es with
  | nil => simp
  | cons e rest ih =>
    simp only [firstOpen] at h
    split_ifs at h with h1
    · intro x hx
      rcases List.mem_cons.1 hx with rfl | hx
      · exact h1
      · exact ih h x hx

theorem firstOpen_some (on : List V) (es : List (V × V)) (x : V × V)
    (h : (firstOpen on es).1 = some x) : x ∈ es ∧ x.1 ∉ on ∧ x.2 ∉ on := by
  induction es with
  | nil => simp [firstOpen] at h
  | cons e rest ih =>
    simp only [firstOpen] at h
    split_ifs at h with h1
    · exact ⟨List.mem_cons_of_mem _ (ih h).1, (ih h).2⟩
    · simp only [Option.some.injEq] at h
      subst h
      simp only [not_or] at h1
      exact ⟨List.mem_cons_self .., h1⟩

theorem searchTree_yes (es : List (V × V)) (k : ℕ) : ∀ on : List V,
    (searchTree es k on).yes = true ↔
      ∃ S : Finset V, S.card ≤ k ∧ ∀ e ∈ es, e.1 ∈ on ∨ e.2 ∈ on ∨ e.1 ∈ S ∨ e.2 ∈ S := by
  induction k with
  | zero =>
    intro on
    rw [searchTree]
    rcases h : firstOpen on es with ⟨_ | x, s⟩
    · simp only [true_iff]
      refine ⟨∅, by simp, fun e he => ?_⟩
      rcases firstOpen_none on es (by rw [h]) e he with h' | h'
      · exact Or.inl h'
      · exact Or.inr (Or.inl h')
    · simp only [Bool.false_eq_true, false_iff, not_exists, not_and]
      intro S hS hcov
      have hS0 : S = ∅ := Finset.card_eq_zero.1 (by omega)
      subst hS0
      obtain ⟨hx, h1, h2⟩ := firstOpen_some on es x (by rw [h])
      rcases hcov x hx with h' | h' | h' | h' <;> simp_all
  | succ k ih =>
    intro on
    rcases h : firstOpen on es with ⟨_ | ⟨u, v⟩, s⟩
    · rw [searchTree, h]
      simp only [true_iff]
      refine ⟨∅, by simp, fun e he => ?_⟩
      rcases firstOpen_none on es (by rw [h]) e he with h' | h'
      · exact Or.inl h'
      · exact Or.inr (Or.inl h')
    · obtain ⟨hx, hu, hv⟩ := firstOpen_some on es (u, v) (by rw [h])
      have key : (searchTree es (k + 1) on).yes = true ↔
          (searchTree es k (u :: on)).yes = true ∨ (searchTree es k (v :: on)).yes = true := by
        rw [searchTree, h]
        dsimp only
        split_ifs with ha <;> simp [ha]
      rw [key, ih, ih]
      constructor
      · rintro (⟨S, hS, hc⟩ | ⟨S, hS, hc⟩)
        · refine ⟨insert u S, (Finset.card_insert_le _ _).trans (by omega), fun e he => ?_⟩
          rcases hc e he with h' | h' | h' | h'
          · rcases List.mem_cons.1 h' with h' | h'
            · exact Or.inr (Or.inr (Or.inl (by simp [h'])))
            · exact Or.inl h'
          · rcases List.mem_cons.1 h' with h' | h'
            · exact Or.inr (Or.inr (Or.inr (by simp [h'])))
            · exact Or.inr (Or.inl h')
          · exact Or.inr (Or.inr (Or.inl (Finset.mem_insert_of_mem h')))
          · exact Or.inr (Or.inr (Or.inr (Finset.mem_insert_of_mem h')))
        · refine ⟨insert v S, (Finset.card_insert_le _ _).trans (by omega), fun e he => ?_⟩
          rcases hc e he with h' | h' | h' | h'
          · rcases List.mem_cons.1 h' with h' | h'
            · exact Or.inr (Or.inr (Or.inl (by simp [h'])))
            · exact Or.inl h'
          · rcases List.mem_cons.1 h' with h' | h'
            · exact Or.inr (Or.inr (Or.inr (by simp [h'])))
            · exact Or.inr (Or.inl h')
          · exact Or.inr (Or.inr (Or.inl (Finset.mem_insert_of_mem h')))
          · exact Or.inr (Or.inr (Or.inr (Finset.mem_insert_of_mem h')))
      · rintro ⟨S, hS, hc⟩
        have huv : u ∈ S ∨ v ∈ S := by
          rcases hc _ hx with h' | h' | h' | h'
          · exact absurd h' hu
          · exact absurd h' hv
          · exact Or.inl h'
          · exact Or.inr h'
        rcases huv with hu' | hv'
        · left
          refine ⟨S.erase u, by rw [Finset.card_erase_of_mem hu']; omega, fun e he => ?_⟩
          rcases hc e he with h' | h' | h' | h'
          · exact Or.inl (List.mem_cons_of_mem _ h')
          · exact Or.inr (Or.inl (List.mem_cons_of_mem _ h'))
          · by_cases heu : e.1 = u
            · exact Or.inl (by simp [heu])
            · exact Or.inr (Or.inr (Or.inl (Finset.mem_erase.2 ⟨heu, h'⟩)))
          · by_cases heu : e.2 = u
            · exact Or.inr (Or.inl (by simp [heu]))
            · exact Or.inr (Or.inr (Or.inr (Finset.mem_erase.2 ⟨heu, h'⟩)))
        · right
          refine ⟨S.erase v, by rw [Finset.card_erase_of_mem hv']; omega, fun e he => ?_⟩
          rcases hc e he with h' | h' | h' | h'
          · exact Or.inl (List.mem_cons_of_mem _ h')
          · exact Or.inr (Or.inl (List.mem_cons_of_mem _ h'))
          · by_cases heu : e.1 = v
            · exact Or.inl (by simp [heu])
            · exact Or.inr (Or.inr (Or.inl (Finset.mem_erase.2 ⟨heu, h'⟩)))
          · by_cases heu : e.2 = v
            · exact Or.inr (Or.inl (by simp [heu]))
            · exact Or.inr (Or.inr (Or.inr (Finset.mem_erase.2 ⟨heu, h'⟩)))

theorem searchTree_nodes (es : List (V × V)) (k : ℕ) : ∀ on : List V,
    (searchTree es k on).nodes ≤ 2 ^ (k + 1) - 1 := by
  induction k with
  | zero =>
    intro on
    rw [searchTree]
    rcases firstOpen on es with ⟨_ | x, s⟩ <;> simp
  | succ k ih =>
    intro on
    rw [searchTree]
    have h1 : 1 ≤ 2 ^ (k + 1) := Nat.one_le_two_pow
    have h2 := Nat.pow_succ 2 (k + 1)
    rcases firstOpen on es with ⟨_ | ⟨u, v⟩, s⟩
    · dsimp only
      omega
    · dsimp only
      have ha := ih (u :: on)
      have hb := ih (v :: on)
      split_ifs <;> dsimp only <;> omega

theorem searchTree_steps (es : List (V × V)) (k : ℕ) : ∀ on : List V,
    (searchTree es k on).steps ≤ (searchTree es k on).nodes * es.length := by
  induction k with
  | zero =>
    intro on
    rw [searchTree]
    have := firstOpen_steps_le on es
    rcases h : firstOpen on es with ⟨_ | x, s⟩ <;> rw [h] at this <;> simpa using this
  | succ k ih =>
    intro on
    rw [searchTree]
    have := firstOpen_steps_le on es
    rcases h : firstOpen on es with ⟨_ | ⟨u, v⟩, s⟩ <;> rw [h] at this
    · simpa using this
    · dsimp only at this ⊢
      have ha := ih (u :: on)
      have hb := ih (v :: on)
      split_ifs
      · dsimp only
        rw [Nat.add_mul, one_mul]
        omega
      · dsimp only
        rw [Nat.add_mul, Nat.add_mul, one_mul]
        omega

theorem mem_high (st : List (V × V)) (k : ℕ) (w : V) : w ∈ high st k ↔ k < degIn st w := by
  unfold high
  rw [List.mem_filter, List.mem_dedup, decide_eq_true_iff]
  constructor
  · exact fun h => h.2
  · intro h
    refine ⟨?_, h⟩
    have hpos : 0 < degIn st w := by omega
    unfold degIn at hpos
    obtain ⟨e, he, hp⟩ := List.countP_pos_iff.1 hpos
    rw [List.mem_flatMap]
    refine ⟨e, he, ?_⟩
    simp only [decide_eq_true_iff] at hp
    rcases hp with hp | hp <;> simp [hp]

theorem high_nodup (st : List (V × V)) (k : ℕ) : (high st k).Nodup :=
  (List.nodup_dedup _).filter _

theorem degIn_le_card (st : List (V × V)) (hnd : (st.map fun e => s(e.1, e.2)).Nodup)
    (S : Finset V) (hS : ∀ e ∈ st, e.1 ∈ S ∨ e.2 ∈ S) (w : V) (hw : w ∉ S) :
    degIn st w ≤ S.card := by
  unfold degIn
  rw [List.countP_eq_length_filter]
  set L := st.filter fun e => decide (e.1 = w ∨ e.2 = w) with hL
  have hLsub : L.Sublist st := List.filter_sublist
  have hndL : (L.map fun e => s(e.1, e.2)).Nodup := hnd.sublist (hLsub.map _)
  let f : V × V → V := fun e => if e.1 = w then e.2 else e.1
  have hmemL : ∀ e ∈ L, e ∈ st ∧ (e.1 = w ∨ e.2 = w) := by
    intro e he
    rw [hL, List.mem_filter, decide_eq_true_iff] at he
    exact he
  have hfS : ∀ e ∈ L, f e ∈ S := by
    intro e he
    obtain ⟨hst, hw'⟩ := hmemL e he
    simp only [f]
    split_ifs with h1
    · rcases hS e hst with h | h
      · exact absurd (h1 ▸ h) hw
      · exact h
    · rcases hw' with h | h
      · exact absurd h h1
      · rcases hS e hst with h' | h'
        · exact h'
        · exact absurd (h ▸ h') hw
  have hsym : ∀ e ∈ L, s(e.1, e.2) = s(w, f e) := by
    intro e he
    obtain ⟨_, hw'⟩ := hmemL e he
    simp only [f]
    split_ifs with h1
    · rw [h1]
    · rcases hw' with h | h
      · exact absurd h h1
      · rw [h, Sym2.eq_swap]
  have hinj := List.inj_on_of_nodup_map hndL
  have hndf : (L.map f).Nodup := by
    refine List.Nodup.map_on ?_ (List.Nodup.of_map _ hndL)
    intro x hx y hy hxy
    exact hinj hx hy (by rw [hsym x hx, hsym y hy, hxy])
  calc L.length = (L.map f).length := (List.length_map _).symm
    _ = (L.map f).toFinset.card := (List.toFinset_card_of_nodup hndf).symm
    _ ≤ S.card := by
      apply Finset.card_le_card
      intro x hx
      rw [List.mem_toFinset, List.mem_map] at hx
      obtain ⟨e, he, rfl⟩ := hx
      exact hfS e he

theorem length_le_sum_degIn (st : List (V × V)) (S : Finset V)
    (hS : ∀ e ∈ st, e.1 ∈ S ∨ e.2 ∈ S) : st.length ≤ ∑ s ∈ S, degIn st s := by
  induction st with
  | nil => simp
  | cons e rest ih =>
    have ih' := ih (fun x hx => hS x (List.mem_cons_of_mem _ hx))
    have hone : 1 ≤ ∑ s ∈ S, (if (e.1 = s ∨ e.2 = s) then 1 else 0) := by
      rw [Finset.sum_boole]
      apply Finset.card_pos.2
      rcases hS e (List.mem_cons_self ..) with h | h
      · exact ⟨e.1, Finset.mem_filter.2 ⟨h, Or.inl rfl⟩⟩
      · exact ⟨e.2, Finset.mem_filter.2 ⟨h, Or.inr rfl⟩⟩
    have hsum : ∑ s ∈ S, degIn (e :: rest) s =
        ∑ s ∈ S, degIn rest s + ∑ s ∈ S, (if (e.1 = s ∨ e.2 = s) then 1 else 0) := by
      rw [← Finset.sum_add_distrib]
      apply Finset.sum_congr rfl
      intro s _
      unfold degIn
      rw [List.countP_cons]
      simp
    rw [hsum, List.length_cons]
    omega

theorem length_le_of_low (st : List (V × V)) (k : ℕ) (S : Finset V) (hk : S.card ≤ k)
    (hS : ∀ e ∈ st, e.1 ∈ S ∨ e.2 ∈ S) (hlow : ∀ w, degIn st w ≤ k) : st.length ≤ k * k := by
  calc st.length ≤ ∑ s ∈ S, degIn st s := length_le_sum_degIn st S hS
    _ ≤ ∑ _s ∈ S, k := Finset.sum_le_sum fun s _ => hlow s
    _ = S.card * k := by rw [Finset.sum_const, smul_eq_mul]
    _ ≤ k * k := Nat.mul_le_mul_right _ hk

theorem high_subset (st : List (V × V)) (hnd : (st.map fun e => s(e.1, e.2)).Nodup) (k : ℕ)
    (S : Finset V) (hk : S.card ≤ k) (hS : ∀ e ∈ st, e.1 ∈ S ∨ e.2 ∈ S) :
    (high st k).toFinset ⊆ S := by
  intro w hw
  rw [List.mem_toFinset, mem_high] at hw
  by_contra hwS
  have := degIn_le_card st hnd S hS w hwS
  omega

theorem kernel_budget (rounds : ℕ) : ∀ (st : List (V × V)) (k : ℕ),
    (kernel rounds st k).budget ≤ k := by
  induction rounds with
  | zero => intro st k; rw [kernel]
  | succ r ih =>
    intro st k
    rw [kernel]
    dsimp only
    split_ifs with h
    · exact le_rfl
    · exact (ih _ _).trans (Nat.sub_le _ _)

theorem kernel_steps (rounds : ℕ) : ∀ (st : List (V × V)) (k : ℕ),
    (kernel rounds st k).steps ≤ (k + 1) * st.length := by
  induction rounds with
  | zero => intro st k; rw [kernel]; dsimp only; exact Nat.le_mul_of_pos_left _ (Nat.succ_pos k)
  | succ r ih =>
    intro st k
    rw [kernel]
    dsimp only
    split_ifs with h
    · dsimp only; exact Nat.le_mul_of_pos_left _ (Nat.succ_pos k)
    · dsimp only
      simp only [not_or, not_lt] at h
      obtain ⟨hne, hle⟩ := h
      have hpos : 0 < (high st k).length := List.length_pos_iff.2 hne
      have h1 := ih (List.filter (fun e => decide (e.1 ∉ high st k ∧ e.2 ∉ high st k)) st)
        (k - (high st k).length)
      have h2 : (List.filter (fun e => decide (e.1 ∉ high st k ∧ e.2 ∉ high st k)) st).length ≤
          st.length := List.length_filter_le _ _
      have h3 : k - (high st k).length + 1 ≤ k := by omega
      calc _ ≤ (k - (high st k).length + 1) *
            (List.filter (fun e => decide (e.1 ∉ high st k ∧ e.2 ∉ high st k)) st).length +
            st.length := Nat.add_le_add_right h1 _
        _ ≤ k * st.length + st.length := Nat.add_le_add_right (Nat.mul_le_mul h3 h2) _
        _ = (k + 1) * st.length := by rw [Nat.add_mul, one_mul]

theorem kernel_alive (rounds : ℕ) : ∀ (st : List (V × V)) (k : ℕ),
    (kernel rounds st k).alive = true →
      (kernel rounds st k).rest.length ≤ (kernel rounds st k).budget * (kernel rounds st k).budget := by
  induction rounds with
  | zero =>
    intro st k h
    rw [kernel] at h ⊢
    dsimp only at h ⊢
    exact (of_decide_eq_true h).2
  | succ r ih =>
    intro st k h
    rw [kernel] at h ⊢
    dsimp only at h ⊢
    split_ifs at h ⊢ with h0
    · exact (of_decide_eq_true h).2
    · exact ih _ _ h

theorem kernel_rest (rounds : ℕ) : ∀ (st : List (V × V)) (k : ℕ),
    ∀ e ∈ (kernel rounds st k).rest,
      e ∈ st ∧ e.1 ∉ (kernel rounds st k).forced ∧ e.2 ∉ (kernel rounds st k).forced := by
  induction rounds with
  | zero =>
    intro st k e he
    rw [kernel] at he ⊢
    dsimp only at he ⊢
    simp [he]
  | succ r ih =>
    intro st k e he
    rw [kernel] at he ⊢
    dsimp only at he ⊢
    split_ifs at he ⊢ with h0
    · simp [he]
    · obtain ⟨h1, h2, h3⟩ := ih _ _ e he
      rw [List.mem_filter, decide_eq_true_iff] at h1
      simp only [List.mem_append, not_or]
      exact ⟨h1.1, ⟨h1.2.1, h2⟩, ⟨h1.2.2, h3⟩⟩

theorem kernel_correct (rounds : ℕ) : ∀ (st : List (V × V)) (k : ℕ), k < rounds →
    (st.map fun e => s(e.1, e.2)).Nodup →
    ((∃ S : Finset V, S.card ≤ k ∧ ∀ e ∈ st, e.1 ∈ S ∨ e.2 ∈ S) ↔
      ((kernel rounds st k).alive = true ∧ ∃ S : Finset V, S.card ≤ (kernel rounds st k).budget ∧
        ∀ e ∈ (kernel rounds st k).rest, e.1 ∈ S ∨ e.2 ∈ S)) := by
  induction rounds with
  | zero => intro st k hk; omega
  | succ r ih =>
    intro st k hk hnd
    rw [kernel]
    dsimp only
    split_ifs with h0
    · dsimp only
      constructor
      · rintro ⟨S, hS, hc⟩
        refine ⟨?_, S, hS, hc⟩
        have hsub := high_subset st hnd k S hS hc
        have hlen : (high st k).length ≤ k := by
          rw [← List.toFinset_card_of_nodup (high_nodup st k)]
          exact (Finset.card_le_card hsub).trans hS
        refine decide_eq_true ⟨hlen, ?_⟩
        rcases h0 with h0 | h0
        · refine length_le_of_low st k S hS hc fun w => ?_
          by_contra hw
          have : w ∈ high st k := (mem_high st k w).2 (by omega)
          rw [h0] at this
          exact List.not_mem_nil this
        · omega
      · exact fun h => h.2
    · simp only [not_or, not_lt] at h0
      obtain ⟨hne, hle⟩ := h0
      have hpos : 0 < (high st k).length := List.length_pos_iff.2 hne
      have hnd' : ((List.filter (fun e => decide (e.1 ∉ high st k ∧ e.2 ∉ high st k)) st).map
          fun e => s(e.1, e.2)).Nodup := hnd.sublist (List.filter_sublist.map _)
      rw [← ih _ _ (by omega) hnd']
      have hcard : (high st k).toFinset.card = (high st k).length :=
        List.toFinset_card_of_nodup (high_nodup st k)
      constructor
      · rintro ⟨S, hS, hc⟩
        have hsub := high_subset st hnd k S hS hc
        refine ⟨S \ (high st k).toFinset, ?_, fun e he => ?_⟩
        · rw [Finset.card_sdiff_of_subset hsub, hcard]
          omega
        · rw [List.mem_filter, decide_eq_true_iff] at he
          obtain ⟨he, h1, h2⟩ := he
          rcases hc e he with h | h
          · exact Or.inl (Finset.mem_sdiff.2 ⟨h, by simpa using h1⟩)
          · exact Or.inr (Finset.mem_sdiff.2 ⟨h, by simpa using h2⟩)
      · rintro ⟨S, hS, hc⟩
        refine ⟨S ∪ (high st k).toFinset, ?_, fun e he => ?_⟩
        · calc (S ∪ (high st k).toFinset).card ≤ S.card + (high st k).toFinset.card :=
                Finset.card_union_le _ _
            _ ≤ k := by rw [hcard]; omega
        · by_cases h1 : e.1 ∈ high st k
          · exact Or.inl (Finset.mem_union_right _ (List.mem_toFinset.2 h1))
          · by_cases h2 : e.2 ∈ high st k
            · exact Or.inr (Finset.mem_union_right _ (List.mem_toFinset.2 h2))
            · have he' : e ∈ List.filter (fun e => decide (e.1 ∉ high st k ∧ e.2 ∉ high st k)) st :=
                List.mem_filter.2 ⟨he, decide_eq_true ⟨h1, h2⟩⟩
              rcases hc e he' with h | h
              · exact Or.inl (Finset.mem_union_left _ h)
              · exact Or.inr (Finset.mem_union_left _ h)

omit [DecidableEq V] in
theorem cover_iff_streets (G : SimpleGraph V) (es : List (V × V)) (hes : IsStreetList G es)
    (C : Finset V) : G.IsVertexCover ↑C ↔ ∀ e ∈ es, e.1 ∈ C ∨ e.2 ∈ C := by
  constructor
  · intro hC e he
    have hm : s(e.1, e.2) ∈ G.edgeSet :=
      (hes.2 _).1 (List.mem_map.2 ⟨e, he, rfl⟩)
    rw [mem_edgeSet] at hm
    simpa using hC hm
  · intro hc v w hadj
    have hm : s(v, w) ∈ es.map (fun e => s(e.1, e.2)) := (hes.2 _).2 ((mem_edgeSet G).2 hadj)
    obtain ⟨e, he, hew⟩ := List.mem_map.1 hm
    rw [Sym2.eq_iff] at hew
    simp only [Finset.mem_coe]
    rcases hew with ⟨h1, h2⟩ | ⟨h1, h2⟩
    · rw [← h1, ← h2]; exact hc e he
    · rw [← h1, ← h2]; exact (hc e he).symm

omit [DecidableEq V] in
theorem exists_cover_iff_streets (G : SimpleGraph V) (es : List (V × V)) (hes : IsStreetList G es)
    (k : ℕ) : (∃ C : Finset V, C.card ≤ k ∧ G.IsVertexCover ↑C) ↔
      ∃ S : Finset V, S.card ≤ k ∧ ∀ e ∈ es, e.1 ∈ S ∨ e.2 ∈ S := by
  simp only [cover_iff_streets G es hes]

/-- The card's theorem: vertex cover is fixed-parameter tractable. The kernel followed by the
bounded search tree answers yes exactly when at most `k` officers can watch every street of the
plan, and it looks at no more than `(k + 1) m + 2^(k+1) k^2` streets, where `m` is the number
of streets: `k + 1` passes to shrink the plan, then a search that does not depend on the plan's
size at all. -/
theorem vertex_cover_fixed_parameter_tractable (G : SimpleGraph V) (es : List (V × V))
    (hes : IsStreetList G es) (k : ℕ) :
    ((kernelThenTree es k).1 = true ↔ ∃ C : Finset V, C.card ≤ k ∧ G.IsVertexCover ↑C) ∧
      (kernelThenTree es k).2 ≤ (k + 1) * es.length + 2 ^ (k + 1) * k ^ 2 := by
  have hcorr := kernel_correct (k + 1) es k (Nat.lt_succ_self k) hes.1
  have hsteps := kernel_steps (k + 1) es k
  have hbud := kernel_budget (k + 1) es k
  rw [exists_cover_iff_streets G es hes, hcorr]
  unfold kernelThenTree
  dsimp only
  by_cases ha : (kernel (k + 1) es k).alive = true
  · simp only [ha, ↓reduceIte]
    constructor
    · rw [searchTree_yes]
      simp only [true_and]
      apply exists_congr
      intro S
      apply and_congr_right
      intro _
      apply forall₂_congr
      intro e he
      have := kernel_rest (k + 1) es k e he
      simp [this.2.1, this.2.2]
    · have ht : (searchTree (kernel (k + 1) es k).rest (kernel (k + 1) es k).budget
          (kernel (k + 1) es k).forced).steps ≤ 2 ^ (k + 1) * k ^ 2 :=
        calc _ ≤ (searchTree (kernel (k + 1) es k).rest (kernel (k + 1) es k).budget
              (kernel (k + 1) es k).forced).nodes * (kernel (k + 1) es k).rest.length :=
              searchTree_steps _ _ _
          _ ≤ (2 ^ ((kernel (k + 1) es k).budget + 1) - 1) *
              ((kernel (k + 1) es k).budget * (kernel (k + 1) es k).budget) :=
              Nat.mul_le_mul (searchTree_nodes _ _ _) (kernel_alive _ _ _ ha)
          _ ≤ 2 ^ (k + 1) * k ^ 2 :=
              Nat.mul_le_mul ((Nat.sub_le _ _).trans (Nat.pow_le_pow_right (by norm_num) (by omega)))
                (by rw [sq]; exact Nat.mul_le_mul hbud hbud)
      omega
  · simp only [ha, Bool.false_eq_true, ↓reduceIte]
    simp only [false_and, iff_self, true_and]
    omega

/-- Step 1, the bounded search tree on its own: it answers yes exactly when at most `k` officers
can watch every street, and its tree has at most `2^(k+1) - 1` nodes, whatever the plan's size. -/
theorem bounded_search_tree_correct (G : SimpleGraph V) (es : List (V × V))
    (hes : IsStreetList G es) (k : ℕ) :
    ((searchTree es k []).yes = true ↔ ∃ C : Finset V, C.card ≤ k ∧ G.IsVertexCover ↑C) ∧
      (searchTree es k []).nodes ≤ 2 ^ (k + 1) - 1 := by
  refine ⟨?_, searchTree_nodes es k []⟩
  rw [searchTree_yes, exists_cover_iff_streets G es hes]
  simp

/-- Step 2, the two kernel rules, in any finite plan. Rule 1: a junction meeting more than `k`
streets is in every set of at most `k` officers that watches every street. Rule 2: if no junction
meets more than `k` streets and at most `k` officers watch every street, there are at most `k^2`
streets. -/
theorem buss_kernel_rules [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj] (k : ℕ)
    (C : Finset V) (hC : G.IsVertexCover ↑C) (hk : C.card ≤ k) :
    (∀ v, k < G.degree v → v ∈ C) ∧ ((∀ v, G.degree v ≤ k) → G.edgeFinset.card ≤ k ^ 2) := by
  constructor
  · intro v hv
    by_contra hvC
    have hsub : G.neighborFinset v ⊆ C := by
      intro w hw
      rw [mem_neighborFinset] at hw
      rcases hC hw with h | h
      · exact absurd h hvC
      · exact h
    have := Finset.card_le_card hsub
    rw [card_neighborFinset_eq_degree] at this
    omega
  · intro hdeg
    have hsub : G.edgeFinset ⊆ C.biUnion fun c => G.incidenceFinset c := by
      intro e he
      induction e using Sym2.ind with
      | h v w =>
        rw [mem_edgeFinset, mem_edgeSet] at he
        rw [Finset.mem_biUnion]
        rcases hC he with h | h
        · exact ⟨v, h, mem_incidenceFinset.2 ((mem_incidenceSet G v w).2 he)⟩
        · refine ⟨w, h, mem_incidenceFinset.2 ?_⟩
          rw [Sym2.eq_swap]; exact (mem_incidenceSet G w v).2 he.symm
    calc G.edgeFinset.card ≤ (C.biUnion fun c => G.incidenceFinset c).card := Finset.card_le_card hsub
      _ ≤ C.card * k := Finset.card_biUnion_le_card_mul _ _ _ fun c _ => by
          rw [card_incidenceFinset_eq_degree]; exact hdeg c
      _ ≤ k ^ 2 := by rw [sq]; exact Nat.mul_le_mul_right _ hk

/-! The festival plan, built as in the card's code: hubs 0-9, partners 10-19, junction 20 meets
every hub, and junctions 21 and up hang side streets off the hubs. -/

/-- The card's festival plan on `n` junctions. -/
def festival (n : ℕ) : List (ℕ × ℕ) :=
  ((List.range n).drop 21).flatMap (fun j =>
      if j < 33 then [(0, j)] else if j < 45 then [(1, j)]
      else [(2 + j % 8, j), (2 + (j + 3) % 8, j)]) ++
    (List.range 10).map (fun h => (20, h)) ++ (List.range 10).map (fun h => (h, (h + 1) % 10)) ++
    (List.range 10).map (fun h => (h, 10 + h))

-- 60 junctions and 84 streets; junctions 0, 1 and 20 meet 16, 16 and 10 streets.
example : (festival 60).length = 84 := by decide +kernel
example : degIn (festival 60) 0 = 16 ∧ degIn (festival 60) 1 = 16 ∧ degIn (festival 60) 20 = 10 := by
  decide +kernel
-- Road 1 with 10 officers: yes, after 11 nodes and 329 steps; the ceiling is 2^11 - 1 = 2,047.
example : searchTree (festival 60) 10 [] = ⟨true, 11, 329⟩ := by decide +kernel
example : 2 ^ 11 - 1 = 2047 := by norm_num
-- Road 1 with 9 officers: no, after all 1,023 = 2^10 - 1 nodes and 30,878 steps.
example : searchTree (festival 60) 9 [] = ⟨false, 1023, 30878⟩ := by decide +kernel
-- Road 2 with 10 officers: Rule 1 forces junctions 0 and 1, removing 31 streets and leaving 53
-- for k' = 8, under Rule 2's limit 8 * 8 = 64; then yes in 229 steps in all.
example : (kernel 11 (festival 60) 10).forced = [0, 1] ∧ (kernel 11 (festival 60) 10).rest.length = 53 ∧
    (kernel 11 (festival 60) 10).budget = 8 := by decide +kernel
example : kernelThenTree (festival 60) 10 = (true, 229) := by decide +kernel
-- Road 2 with 9 officers: the kernel alone answers no in 142 steps.
example : kernelThenTree (festival 60) 9 = (false, 142) := by decide +kernel
-- Road 3: officers at junctions 0 to 9 watch every street.
example : (festival 60).all (fun e => e.1 < 10 ∨ e.2 < 10) = true := by decide +kernel
-- The ceiling (k + 1) m + 2^(k+1) k^2 at k = 10, m = 84.
example : (10 + 1) * 84 + 2 ^ (10 + 1) * 10 ^ 2 = 205724 := by norm_num
-- Brute force: sets of at most 10 junctions out of 60.
example : ∑ i ∈ Finset.range 11, Nat.choose 60 i = 93178047049 := by
  simp [Finset.sum_range_succ, Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial,
    Nat.factorial]
-- What breaks: branching in or out on all 60 junctions; a ring of 200 needing k = 100.
example : 2 ^ 60 = 1152921504606846976 := by norm_num
example : 2 ^ 101 - 1 = 2535301200456458802993406410751 := by norm_num

#print axioms firstOpen_steps_le
#print axioms firstOpen_none
#print axioms firstOpen_some
#print axioms searchTree_yes
#print axioms searchTree_nodes
#print axioms searchTree_steps
#print axioms mem_high
#print axioms high_nodup
#print axioms degIn_le_card
#print axioms length_le_sum_degIn
#print axioms length_le_of_low
#print axioms high_subset
#print axioms kernel_budget
#print axioms kernel_steps
#print axioms kernel_alive
#print axioms kernel_rest
#print axioms kernel_correct
#print axioms cover_iff_streets
#print axioms exists_cover_iff_streets
#print axioms vertex_cover_fixed_parameter_tractable
#print axioms bounded_search_tree_correct
#print axioms buss_kernel_rules
