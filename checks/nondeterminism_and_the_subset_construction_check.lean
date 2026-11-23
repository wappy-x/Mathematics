-- Guessing machines: tracking the set of states a guessing machine (an NFA with ε-moves) could be in gives an ordinary DFA with the same language and at most 2^N reached states, and "the k-th symbol from the end is c" needs only k + 1 guessing states but at least 2^k ordinary ones.
import Mathlib.Computability.EpsilonNFA
import Mathlib.Data.Set.Card
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Powerset

open Set

universe u v

variable {α : Type u} {σ : Type}

/-- The card's subset construction. Its states are sets `T` of guessing-machine states.
It starts at `E(start)`, moves by `δ_D(T, a) = E(⋃ q ∈ T, δ(q, a))`, and accepts at `T`
exactly when `T` meets the accepting states `F`. -/
def subsetDFA (M : εNFA α σ) : DFA α (Set σ) where
  step T a := M.εClosure (⋃ q ∈ T, M.step q (some a))
  start := M.εClosure M.start
  accept := {T | ∃ q ∈ T, q ∈ M.accept}

/-- Helper: the subset machine's state after reading `x` is exactly the set of states the
guessing machine could be in. -/
theorem subsetDFA_eval (M : εNFA α σ) (x : List α) : (subsetDFA M).eval x = M.eval x := by
  induction x using List.reverseRecOn with
  | nil => rfl
  | append_singleton x a ih =>
    rw [DFA.eval_append_singleton, εNFA.eval_append_singleton, ← ih]
    ext s
    simp only [subsetDFA, εNFA.mem_stepSet_iff]
    rw [εNFA.mem_εClosure_iff_exists]
    simp only [Set.mem_iUnion, exists_prop]
    constructor
    · rintro ⟨t, ⟨q, hq, ht⟩, hs⟩
      exact ⟨q, hq, (M.mem_εClosure_iff_exists).2 ⟨t, ht, hs⟩⟩
    · rintro ⟨q, hq, hs⟩
      obtain ⟨t, ht, hs⟩ := (M.mem_εClosure_iff_exists).1 hs
      exact ⟨t, ⟨q, hq, ht⟩, hs⟩

#print axioms subsetDFA_eval

/-- Subset construction (Rabin and Scott, 1959). For a guessing machine with finitely many
states, ε-moves allowed, which accepts when some guess accepts, the ordinary machine built from
the sets of states it could be in accepts exactly the same strings. So guessing never lets a
finite automaton recognize anything new: the language is regular. -/
theorem subset_construction_accepts_same_language [Fintype σ] (M : εNFA α σ) :
    (subsetDFA M).accepts = M.accepts ∧ M.accepts.IsRegular := by
  have h : (subsetDFA M).accepts = M.accepts := by
    ext x
    rw [DFA.mem_accepts, subsetDFA_eval]
    exact ⟨fun ⟨q, h1, h2⟩ => ⟨q, h2, h1⟩, fun ⟨q, h1, h2⟩ => ⟨q, h2, h1⟩⟩
  classical
  exact ⟨h, Set σ, inferInstance, subsetDFA M, h⟩

/-- The price is bounded: the sets the subset construction actually reaches number at most
`2^N`, where `N` is the number of guessing-machine states. -/
theorem subset_construction_reached_sets_le [Fintype σ] (M : εNFA α σ) :
    (Set.range (subsetDFA M).eval).ncard ≤ 2 ^ Fintype.card σ := by
  classical
  calc (Set.range (subsetDFA M).eval).ncard ≤ Nat.card (Set σ) := Set.ncard_le_card _
    _ = 2 ^ Fintype.card σ := by rw [Nat.card_eq_fintype_card, Fintype.card_set]

/-- The two-letter alphabet of the card's Step 4: the letters `c` and `x`. -/
inductive CX
  | c
  | x
  deriving DecidableEq

instance : Fintype CX := ⟨{CX.c, CX.x}, fun a => by cases a <;> decide⟩

/-- "The k-th symbol from the end is c": strings `u ++ c :: v` with `v` of length `k - 1`. -/
def kthFromEndC (k : ℕ) : Language CX :=
  {w | ∃ u v : List CX, w = u ++ CX.c :: v ∧ v.length = k - 1}

/-- Helper: the empty string has no `c` anywhere. -/
theorem endP_nil (n : ℕ) :
    ¬ ∃ u v : List CX, ([] : List CX) = u ++ CX.c :: v ∧ v.length = n := by
  rintro ⟨u, v, h, -⟩
  simp at h

#print axioms endP_nil

/-- Helper: `w ++ [a]` ends in `c` exactly when `a = c`. -/
theorem endP_zero (w : List CX) (a : CX) :
    (∃ u v : List CX, w ++ [a] = u ++ CX.c :: v ∧ v.length = 0) ↔ a = CX.c := by
  constructor
  · rintro ⟨u, v, h, hv⟩
    rw [List.length_eq_zero_iff] at hv
    subst hv
    exact List.singleton_inj.mp (List.append_inj' h rfl).2
  · rintro rfl
    exact ⟨w, [], rfl, rfl⟩

#print axioms endP_zero

/-- Helper: a `c` with `n + 1` symbols after it in `w ++ [a]` is a `c` with `n` symbols after
it in `w`. -/
theorem endP_succ (w : List CX) (a : CX) (n : ℕ) :
    (∃ u v : List CX, w ++ [a] = u ++ CX.c :: v ∧ v.length = n + 1) ↔
      ∃ u v : List CX, w = u ++ CX.c :: v ∧ v.length = n := by
  constructor
  · rintro ⟨u, v, h, hv⟩
    rcases List.eq_nil_or_concat v with rfl | ⟨L, b, rfl⟩
    · simp at hv
    · refine ⟨u, L, ?_, by simpa using hv⟩
      have : w ++ [a] = (u ++ CX.c :: L) ++ [b] := by rw [h]; simp
      exact (List.append_inj' this rfl).1
  · rintro ⟨u, v, rfl, hv⟩
    exact ⟨u, v ++ [a], by simp, by simp [hv]⟩

#print axioms endP_succ

/-- Helper: the `k + 1`-state guessing machine. State `0` loops on every letter and guesses
on `c` by moving to state `1`; state `i ≥ 1` moves to `i + 1` on every letter; state `k` accepts. -/
def kthNFA (k : ℕ) : NFA CX (Fin (k + 1)) where
  step i a := {j | (i.val = 0 ∧ j.val = 0) ∨ (i.val = 0 ∧ a = CX.c ∧ j.val = 1) ∨
    (1 ≤ i.val ∧ j.val = i.val + 1)}
  start := {j | j.val = 0}
  accept := {j | j.val = k}

/-- Helper: state `j ≥ 1` is reachable on `w` exactly when `w` has a `c` with `j - 1`
symbols after it. -/
theorem kthNFA_eval (k : ℕ) (w : List CX) (j : Fin (k + 1)) :
    j ∈ (kthNFA k).eval w ↔
      j.val = 0 ∨ (1 ≤ j.val ∧ ∃ u v : List CX, w = u ++ CX.c :: v ∧ v.length = j.val - 1) := by
  induction w using List.reverseRecOn generalizing j with
  | nil =>
    simp only [NFA.eval_nil, kthNFA, Set.mem_ofPred_eq]
    constructor
    · intro h
      exact Or.inl h
    · rintro (h | ⟨-, h⟩)
      · exact h
      · exact absurd h (endP_nil _)
  | append_singleton w a ih =>
    rw [NFA.eval_append_singleton, NFA.mem_stepSet]
    have h0 : (⟨0, by omega⟩ : Fin (k + 1)) ∈ (kthNFA k).eval w := (ih _).2 (Or.inl rfl)
    constructor
    · rintro ⟨i, hi, hj⟩
      simp only [kthNFA, Set.mem_ofPred_eq] at hj
      rcases hj with ⟨-, hj⟩ | ⟨-, rfl, hj⟩ | ⟨hi1, hj⟩
      · exact Or.inl hj
      · right
        refine ⟨by omega, ?_⟩
        rw [hj]
        exact (endP_zero w _).2 rfl
      · right
        refine ⟨by omega, ?_⟩
        obtain ⟨m, hm⟩ : ∃ m, i.val = m + 1 := ⟨i.val - 1, by omega⟩
        have hjm : j.val - 1 = m + 1 := by omega
        rw [hjm, endP_succ]
        rcases (ih i).1 hi with h | ⟨-, h⟩
        · omega
        · rw [hm] at h
          simpa using h
    · rintro (hj | ⟨hj1, hP⟩)
      · exact ⟨⟨0, by omega⟩, h0, Or.inl ⟨rfl, hj⟩⟩
      · obtain ⟨m, hm⟩ : ∃ m, j.val = m + 1 := ⟨j.val - 1, by omega⟩
        rw [hm] at hP
        cases m with
        | zero =>
          have ha := (endP_zero w a).1 hP
          exact ⟨⟨0, by omega⟩, h0, Or.inr (Or.inl ⟨rfl, ha, hm⟩)⟩
        | succ m =>
          have hP' : ∃ u v : List CX, w ++ [a] = u ++ CX.c :: v ∧ v.length = m + 1 := by
            simpa using hP
          rw [endP_succ] at hP'
          refine ⟨⟨m + 1, by omega⟩, (ih _).2 (Or.inr ⟨by simp, by simpa using hP'⟩), ?_⟩
          exact Or.inr (Or.inr ⟨Nat.le_add_left 1 m, hm⟩)

#print axioms kthNFA_eval

/-- Helper: for `k ≥ 1`, `w` is in the language exactly when it has length at least `k` and
its symbol at position `length - k` is `c`. -/
theorem kth_mem_iff (k : ℕ) (hk : 1 ≤ k) (w : List CX) :
    w ∈ kthFromEndC k ↔ k ≤ w.length ∧ w[w.length - k]? = some CX.c := by
  constructor
  · rintro ⟨u, v, rfl, hv⟩
    have hlen : (u ++ CX.c :: v).length - k = u.length := by simp; omega
    refine ⟨by simp; omega, ?_⟩
    rw [hlen]
    simp
  · rintro ⟨hle, hget⟩
    obtain ⟨hn, hc⟩ := List.getElem?_eq_some_iff.1 hget
    refine ⟨w.take (w.length - k), w.drop (w.length - k + 1), ?_, ?_⟩
    · rw [← hc, ← List.drop_eq_getElem_cons hn, List.take_append_drop]
    · simp
      omega

#print axioms kth_mem_iff

/-- The price can be every subset. For `k ≥ 1`, a guessing machine with `k + 1` states
recognizes "the k-th symbol from the end is c", but every ordinary machine (DFA) that
recognizes it has at least `2^k` states. -/
theorem kth_from_end_needs_two_pow_states (k : ℕ) (hk : 1 ≤ k) :
    (∃ M : NFA CX (Fin (k + 1)), M.accepts = kthFromEndC k) ∧
      ∀ (τ : Type v) [Fintype τ] (D : DFA CX τ), D.accepts = kthFromEndC k →
        2 ^ k ≤ Fintype.card τ := by
  refine ⟨⟨kthNFA k, ?_⟩, ?_⟩
  · ext w
    constructor
    · rintro ⟨j, hj, hw⟩
      simp only [kthNFA, Set.mem_ofPred_eq] at hj
      rcases (kthNFA_eval k w j).1 hw with h | ⟨-, h⟩
      · omega
      · rw [hj] at h
        exact h
    · intro hw
      exact ⟨Fin.last k, rfl, (kthNFA_eval k w _).2 (Or.inr ⟨by simp; omega, hw⟩)⟩
  · intro τ _ D hD
    classical
    let f : (Fin k → CX) → τ := fun x => D.eval (List.ofFn x)
    have hf : Function.Injective f := by
      intro x y hxy
      by_contra hne
      obtain ⟨i, hi⟩ : ∃ i, x i ≠ y i := Function.ne_iff.1 hne
      have key : ∀ z : Fin k → CX,
          (List.ofFn z ++ List.replicate i.val CX.x) ∈ kthFromEndC k ↔ z i = CX.c := by
        intro z
        rw [kth_mem_iff k hk]
        simp [List.getElem?_append_left, i.isLt]
      have hacc : ∀ z : Fin k → CX, (List.ofFn z ++ List.replicate i.val CX.x) ∈ D.accepts ↔
          D.evalFrom (f z) (List.replicate i.val CX.x) ∈ D.accept := by
        intro z
        rw [DFA.mem_accepts, DFA.eval, DFA.evalFrom_of_append]
        rfl
      have hx := key x
      have hy := key y
      rw [← hD, hacc] at hx hy
      rw [hxy] at hx
      have hxy' : x i = CX.c ↔ y i = CX.c := hx.symm.trans hy
      cases hxi : x i <;> cases hyi : y i <;> simp_all
    have hcard : Fintype.card (Fin k → CX) = 2 ^ k := by
      rw [Fintype.card_fun, Fintype.card_fin]
      rfl
    rw [← hcard]
    exact Fintype.card_le_of_injective f hf

/-! The card's whole-number worked examples. -/

-- The till's guessing machine has 11 states, so 2,048 possible sets.
example : 2 ^ 11 = 2048 := by norm_num

-- The 21 reached sets counted by hand: the start set, then 5 kinds of partial match,
-- times A4 present or not, times B4 present or not; 15 of them hold A4 or B4.
example : 1 + 5 * 2 * 2 = 21 := by norm_num
example : 5 * 3 = 15 := by norm_num
example : 21 < 2 ^ 11 := by norm_num

-- The DFA table has 21 rows and 39 symbol columns.
example : 21 * 39 = 819 := by norm_num

-- All strings of length 0 to 6 over the 7 letters c, a, s, h, r, d, x.
example : (∑ n ∈ Finset.range 7, 7 ^ n) = 137257 := by decide

-- "k-th from the end is c" for k = 1 to 10: 2^k subset states, 1,024 at k = 10.
example : (List.range 10).map (fun k => 2 ^ (k + 1)) =
    [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024] := by decide

-- For k = 3 there are 8 strings of length 3 over c and x, against 4 guessing states.
example : Fintype.card (Fin 3 → CX) = 8 := by decide
example : 4 < 2 ^ 3 := by norm_num

-- The card's pair: ccxx has c third from the end, so it is in the language.
example : [CX.c, CX.c, CX.x, CX.x] ∈ kthFromEndC 3 := ⟨[CX.c], [CX.x, CX.x], rfl, rfl⟩

#print axioms subset_construction_accepts_same_language
#print axioms subset_construction_reached_sets_le
#print axioms kth_from_end_needs_two_pow_states
