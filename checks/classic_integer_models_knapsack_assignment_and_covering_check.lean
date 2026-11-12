-- Four classic models: the assignment rules accept exactly the pairings, adding every loop ban accepts exactly the single routes, and the festival's whole-number answers check out.
import Mathlib.GroupTheory.Perm.Cycle.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Factorial.Basic

open Finset

theorem helper_val_fin_two (a : Fin 2) : (a : ℕ) = if a = 1 then 1 else 0 := by
  revert a; decide

theorem helper_sum_fin_two {ι : Type*} (s : Finset ι) (g : ι → Fin 2) :
    ∑ j ∈ s, (g j : ℕ) = (s.filter (fun j => g j = 1)).card := by
  rw [Finset.card_filter]
  exact Finset.sum_congr rfl (fun j _ => helper_val_fin_two (g j))

#print axioms helper_val_fin_two
#print axioms helper_sum_fin_two

/-- Routing (Step 4 and its detailed proof): give every stop exactly one next stop, never itself
(one leg out and one leg in at every stop). Then the van's plan is one closed loop through all
`n` stops exactly when every group `S` of 2 to `n - 1` stops holds at most `|S| - 1` legs that
start and end inside `S` (the loop bans). -/
theorem loop_bans_accept_exactly_the_routes {n : ℕ} (σ : Equiv.Perm (Fin n))
    (hσ : ∀ i, σ i ≠ i) :
    σ.IsCycleOn Set.univ ↔
      ∀ S : Finset (Fin n), 2 ≤ S.card → S.card ≤ n - 1 →
        (S.filter (fun i => σ i ∈ S)).card ≤ S.card - 1 := by
  constructor
  · intro hc S h2 hS
    have hlt : (S.filter (fun i => σ i ∈ S)).card < S.card := by
      apply Finset.card_lt_card
      refine ⟨Finset.filter_subset _ _, fun hsub => ?_⟩
      have hinv : ∀ i ∈ S, σ i ∈ S := fun i hi => (Finset.mem_filter.mp (hsub hi)).2
      have hpow : ∀ (k : ℕ), ∀ i ∈ S, (σ ^ k) i ∈ S := by
        intro k
        induction k with
        | zero => intro i hi; simpa using hi
        | succ k ih =>
          intro i hi
          rw [pow_succ', Equiv.Perm.mul_apply]
          exact hinv _ (ih i hi)
      obtain ⟨a, ha⟩ : S.Nonempty := card_pos.mp (by omega : 0 < S.card)
      obtain ⟨b, hb⟩ : ∃ b, b ∉ S := by
        by_contra hall
        push Not at hall
        have : S = univ := eq_univ_of_forall hall
        rw [this, card_univ, Fintype.card_fin] at hS h2
        omega
      obtain ⟨k, -, hk⟩ := (hc.2 (Set.mem_univ a) (Set.mem_univ b)).exists_pow_eq'
      exact hb (hk ▸ hpow k a ha)
    omega
  · intro h
    classical
    by_contra hnc
    obtain ⟨a, b, hab⟩ : ∃ a b, ¬ σ.SameCycle a b := by
      by_contra hall
      push Not at hall
      exact hnc ⟨⟨fun x _ => Set.mem_univ _, σ.injective.injOn,
        fun y _ => ⟨σ.symm y, Set.mem_univ _, by simp⟩⟩, fun x _ y _ => hall x y⟩
    set S := univ.filter (fun i => σ.SameCycle a i) with hSdef
    have hsub2 : ({a, σ a} : Finset (Fin n)) ⊆ S := by
      intro i hi
      simp only [Finset.mem_insert, Finset.mem_singleton] at hi
      rcases hi with rfl | rfl
      · simpa [hSdef] using Equiv.Perm.SameCycle.refl σ i
      · simpa [hSdef, Equiv.Perm.sameCycle_apply_right] using Equiv.Perm.SameCycle.refl σ a
    have hcard2 : 2 ≤ S.card := by
      have : ({a, σ a} : Finset (Fin n)).card = 2 := by
        rw [Finset.card_pair (Ne.symm (hσ a))]
      rw [← this]
      exact Finset.card_le_card hsub2
    have hcardn : S.card ≤ n - 1 := by
      have hsub : S ⊆ univ.erase b := by
        intro i hi
        simp only [hSdef, Finset.mem_filter, Finset.mem_univ, true_and] at hi
        simp only [Finset.mem_erase, Finset.mem_univ, and_true]
        rintro rfl
        exact hab hi
      have := Finset.card_le_card hsub
      rw [Finset.card_erase_of_mem (Finset.mem_univ _), card_univ, Fintype.card_fin] at this
      exact this
    have hfilt : S.filter (fun i => σ i ∈ S) = S := by
      apply Finset.filter_true_of_mem
      intro i hi
      simp only [hSdef, Finset.mem_filter, Finset.mem_univ, true_and] at hi ⊢
      exact Equiv.Perm.sameCycle_apply_right.mpr hi
    have := h S hcard2 hcardn
    rw [hfilt] at this
    omega

/-- Assignment (Step 2): a grid of 0-1 switches with exactly one 1 in every row and exactly one 1
in every column is a pairing of rows with columns, and every pairing gives such a grid. -/
theorem assignment_rules_accept_exactly_the_pairings {n : ℕ} (x : Fin n → Fin n → Fin 2) :
    ((∀ i, ∑ j, (x i j : ℕ) = 1) ∧ ∀ j, ∑ i, (x i j : ℕ) = 1) ↔
      ∃ σ : Equiv.Perm (Fin n), ∀ i j, x i j = if σ i = j then 1 else 0 := by
  constructor
  · rintro ⟨hr, hc⟩
    have hr' : ∀ i, ∃ j, univ.filter (fun j => x i j = 1) = {j} := fun i => by
      rw [← Finset.card_eq_one, ← helper_sum_fin_two]
      exact hr i
    have hc' : ∀ j, ∃ i, univ.filter (fun i => x i j = 1) = {i} := fun j => by
      rw [← Finset.card_eq_one, ← helper_sum_fin_two]
      exact hc j
    choose f hf using hr'
    have hf1 : ∀ i j, x i j = 1 ↔ f i = j := by
      intro i j
      have := Finset.ext_iff.mp (hf i) j
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton] at this
      rw [this, eq_comm]
    have hinj : Function.Injective f := by
      intro a b hab
      obtain ⟨i, hi⟩ := hc' (f a)
      have ha : a ∈ univ.filter (fun i => x i (f a) = 1) := by simp [hf1]
      have hb : b ∈ univ.filter (fun i => x i (f a) = 1) := by simp [hf1, hab]
      rw [hi, Finset.mem_singleton] at ha hb
      rw [ha, hb]
    refine ⟨Equiv.ofBijective f (Finite.injective_iff_bijective.mp hinj), fun i j => ?_⟩
    simp only [Equiv.ofBijective_apply]
    split_ifs with h
    · exact (hf1 i j).mpr h
    · have := (hf1 i j).not.mpr h
      revert this
      generalize x i j = a
      revert a
      decide
  · rintro ⟨σ, hσ⟩
    refine ⟨fun i => ?_, fun j => ?_⟩
    · rw [helper_sum_fin_two, Finset.card_eq_one]
      refine ⟨σ i, ?_⟩
      ext j
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton, hσ]
      split_ifs with h
      · simp [h]
      · constructor
        · intro h'; exact absurd h' (by decide)
        · intro h'; exact absurd h'.symm h
    · rw [helper_sum_fin_two, Finset.card_eq_one]
      refine ⟨σ.symm j, ?_⟩
      ext i
      simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton, hσ]
      split_ifs with h
      · simp [← h]
      · constructor
        · intro h'; exact absurd h' (by decide)
        · intro h'; subst h'; exact absurd (by simp) h

/-- Assignment (Step 2): of all the 0-1 grids with `n` rows and `n` columns, exactly `n!` obey the
assignment rules, one for each ordering (24 of 65,536 when `n = 4`). -/
theorem assignment_grid_count (n : ℕ) :
    (univ.filter (fun x : Fin n → Fin n → Fin 2 =>
      (∀ i, ∑ j, (x i j : ℕ) = 1) ∧ ∀ j, ∑ i, (x i j : ℕ) = 1)).card = n.factorial := by
  have hset : univ.filter (fun x : Fin n → Fin n → Fin 2 =>
      (∀ i, ∑ j, (x i j : ℕ) = 1) ∧ ∀ j, ∑ i, (x i j : ℕ) = 1) =
      univ.image (fun σ : Equiv.Perm (Fin n) => fun i j => if σ i = j then (1 : Fin 2) else 0) := by
    ext x
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_image]
    rw [assignment_rules_accept_exactly_the_pairings]
    constructor
    · rintro ⟨σ, h⟩
      exact ⟨σ, funext fun i => funext fun j => (h i j).symm⟩
    · rintro ⟨σ, rfl⟩
      exact ⟨σ, fun i j => rfl⟩
  rw [hset, Finset.card_image_of_injective, Finset.card_univ, Fintype.card_perm, Fintype.card_fin]
  intro σ τ h
  refine Equiv.ext fun i => ?_
  have hx : (if σ i = σ i then (1 : Fin 2) else 0) = (if τ i = σ i then 1 else 0) :=
    congrFun (congrFun h i) (σ i)
  by_contra hne
  have h1 : (if σ i = σ i then (1 : Fin 2) else 0) = 1 := by simp
  have h0 : (if τ i = σ i then (1 : Fin 2) else 0) = 0 := by simp [Ne.symm hne]
  have : (1 : Fin 2) = 0 := by rw [h1, h0] at hx; exact hx
  exact absurd this (by decide)

/-! ### The card's worked examples -/

-- Knapsack: the 16 booked acts (fee in pounds, tickets) spend exactly 40,000 pounds for 7,100 tickets.
example : ([2000, 3500, 1000, 3500, 3500, 3500, 1500, 1500, 5000, 2500, 500, 2500, 4500, 500, 4000, 500] : List ℕ).sum = 40000 := by decide
example : ([364, 524, 285, 530, 576, 510, 362, 354, 667, 457, 237, 491, 637, 274, 575, 257] : List ℕ).sum = 7100 := by decide
-- Knapsack: the best 16 acts by tickets per pound use 75 units of 500 pounds and draw 6,782 tickets.
example : ([1, 1, 1, 2, 3, 3, 5, 5, 4, 7, 7, 7, 7, 8, 9, 5] : List ℕ).sum = 75 := by decide
example : ([274, 257, 237, 285, 362, 354, 491, 457, 364, 576, 530, 524, 510, 575, 637, 349] : List ℕ).sum = 6782 := by decide
-- Knapsack: 5/7 of act 43 (483 tickets) is worth 345, so the fractional bound is 7,127, 27 above 7,100.
example : (5 : ℚ) / 7 * 483 = 345 ∧ (6782 : ℚ) + 345 = 7127 ∧ (7127 : ℚ) - 7100 = 27 := by norm_num
example : 2 ^ 60 = 1152921504606846976 ∧ 60 * 81 = 4860 := by norm_num

-- Assignment: crowd in hundreds; rows Kestrel, Lumen, Marrow, Nettle; columns Main 21:00,
-- Main 19:00, Tent 21:00, Tent 19:00.
def crowd : Fin 4 → Fin 4 → ℕ := ![![92, 70, 55, 40], ![88, 60, 64, 45], ![75, 66, 50, 48], ![70, 52, 58, 30]]

-- 2^16 grids, 4! pairings.
example : 2 ^ 16 = 65536 ∧ Nat.factorial 4 = 24 := by decide
-- The best timetable (Kestrel Main 19:00, Lumen Main 21:00, Marrow Tent 19:00, Nettle Tent 21:00) draws 264.
example : crowd 0 1 + crowd 1 0 + crowd 2 3 + crowd 3 2 = 264 := by decide
-- No timetable beats 264 hundred, and none falls below 220 hundred.
example : ∀ σ : Equiv.Perm (Fin 4), ∑ i, crowd i (σ i) ≤ 264 := by decide
example : ∀ σ : Equiv.Perm (Fin 4), 220 ≤ ∑ i, crowd i (σ i) := by decide
-- Each act grabbing its best free slot in turn: Kestrel Main 21:00, Lumen Tent 21:00, Marrow Main 19:00, Nettle Tent 19:00.
example : crowd 0 0 + crowd 1 2 + crowd 2 1 + crowd 3 3 = 252 := by decide

-- Covering: post p (P1..P6 as 0..5) reaches these zones and costs this many pounds.
def zones : Fin 6 → Finset ℕ := ![{3, 4, 5}, {1, 2, 3, 8}, {1, 6, 8}, {2, 5, 7}, {1, 2, 3, 4, 6, 7}, {8}]
def postCost : Fin 6 → ℕ := ![3000, 4500, 3200, 3200, 5700, 1500]
def Covers (C : Finset (Fin 6)) : Prop := ∀ z ∈ Finset.Icc 1 8, ∃ p ∈ C, z ∈ zones p
instance : DecidablePred Covers := fun C => by unfold Covers; infer_instance

-- P1 + P3 + P4 covers every zone for 9,400 pounds, and no cover is cheaper.
example : Covers {0, 2, 3} ∧ ∑ p ∈ ({0, 2, 3} : Finset (Fin 6)), postCost p = 9400 := by decide
example : ∀ C : Finset (Fin 6), Covers C → 9400 ≤ ∑ p ∈ C, postCost p := by decide
-- 25 of the 64 choices cover every zone.
example : (univ.filter Covers).card = 25 := by decide
-- Under "exactly once" no choice of posts works.
example : ¬ ∃ C : Finset (Fin 6), ∀ z ∈ Finset.Icc 1 8, (C.filter (fun p => z ∈ zones p)).card = 1 := by decide
-- Greedy P5 + P6 + P1 costs 10,200 pounds.
example : Covers {4, 5, 0} ∧ ∑ p ∈ ({4, 5, 0} : Finset (Fin 6)), postCost p = 10200 := by decide

-- Routing: metres between stops G, M, F, T, N, S (0..5).
def dist : Fin 6 → Fin 6 → ℕ :=
  ![![0, 300, 200, 900, 1100, 800], ![300, 0, 250, 600, 800, 900], ![200, 250, 0, 700, 1000, 650],
    ![900, 600, 700, 0, 300, 350], ![1100, 800, 1000, 300, 0, 400], ![800, 900, 650, 350, 400, 0]]
def tourLength (t : List (Fin 6)) : ℕ := ((t.zip (t.tail ++ t.take 1)).map (fun e => dist e.1 e.2)).sum

-- Round 1: the loops G-M-F and T-N-S total 1,800 m.
example : tourLength [0, 1, 2] + tourLength [3, 4, 5] = 1800 := by decide
-- Round 2: back-and-forth trips G-F, M-T, N-S total 2,400 m.
example : tourLength [0, 2] + tourLength [1, 3] + tourLength [4, 5] = 2400 := by decide
-- The route G-M-T-N-S-F-G is 2,450 m, and none of the 120 directed tours from G is shorter.
example : tourLength [0, 1, 3, 4, 5, 2] = 2450 := by decide
set_option maxRecDepth 20000 in
example : (([1, 2, 3, 4, 5] : List (Fin 6)).permutations').length = 120 := by decide
set_option maxRecDepth 20000 in
example : ∀ p ∈ ([1, 2, 3, 4, 5] : List (Fin 6)).permutations', 2450 ≤ tourLength (0 :: p) := by decide

#print axioms loop_bans_accept_exactly_the_routes
#print axioms assignment_rules_accept_exactly_the_pairings
#print axioms assignment_grid_count
