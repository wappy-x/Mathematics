-- Sharing a joint cost: in every order the extra costs add up to the whole bill, so the Shapley shares add up to c(N); when costs are concave every order's bill and the Shapley bill lie in the core; for the bakery oven the shares are 2000/6, 5000/6 and 11000/6 pounds.
import Mathlib.Tactic

open Finset

variable {n : ℕ}

/-- The first `k` players of an order: player `j` stands in place `pos j`. -/
def firstK (pos : Equiv.Perm (Fin n)) (k : ℕ) : Finset (Fin n) :=
  univ.filter (fun j => (pos j : ℕ) < k)

/-- The players ahead of player `i` in the order. -/
def ahead (pos : Equiv.Perm (Fin n)) (i : Fin n) : Finset (Fin n) := firstK pos (pos i)

/-- The extra cost player `i` adds when it joins the players ahead of it. -/
def extra (c : Finset (Fin n) → ℚ) (pos : Equiv.Perm (Fin n)) (i : Fin n) : ℚ :=
  c (insert i (ahead pos i)) - c (ahead pos i)

/-- The Shapley share: the extra cost averaged over all `n!` orders. -/
def shapley (c : Finset (Fin n) → ℚ) (i : Fin n) : ℚ :=
  (∑ pos : Equiv.Perm (Fin n), extra c pos i) / (Nat.factorial n)

/-- Helper: joining the players ahead of `i` makes the first `pos i + 1` players. -/
theorem insert_ahead (pos : Equiv.Perm (Fin n)) (i : Fin n) :
    insert i (ahead pos i) = firstK pos (pos i + 1) := by
  ext j
  simp only [ahead, firstK, mem_insert, mem_filter, mem_univ, true_and]
  constructor
  · rintro (rfl | h)
    · omega
    · omega
  · intro h
    rcases Nat.lt_succ_iff_lt_or_eq.mp h with h | h
    · exact Or.inr h
    · exact Or.inl (pos.injective (Fin.ext h))

/-- Step 1: in any order, the extra costs telescope to the whole bill. -/
theorem order_bill_adds_up (c : Finset (Fin n) → ℚ) (pos : Equiv.Perm (Fin n)) :
    ∑ i, extra c pos i = c univ - c ∅ := by
  have h1 : ∀ i, extra c pos i = c (firstK pos ((pos i : ℕ) + 1)) - c (firstK pos (pos i)) := by
    intro i
    rw [extra, insert_ahead]
    rfl
  simp only [h1]
  rw [Equiv.sum_comp pos (fun k : Fin n => c (firstK pos ((k : ℕ) + 1)) - c (firstK pos k))]
  rw [Fin.sum_univ_eq_sum_range (fun k => c (firstK pos (k + 1)) - c (firstK pos k)) n]
  rw [Finset.sum_range_sub (fun k => c (firstK pos k))]
  have hn : firstK pos n = univ := by
    ext j
    simp [firstK]
  have h0 : firstK pos 0 = ∅ := by
    ext j
    simp [firstK]
  rw [hn, h0]

/-- Efficiency: the Shapley shares add up to the whole bill `c(N)`, when the empty group costs
nothing. -/
theorem shapley_efficiency (c : Finset (Fin n) → ℚ) (h0 : c ∅ = 0) :
    ∑ i, shapley c i = c univ := by
  simp only [shapley, ← Finset.sum_div]
  rw [Finset.sum_comm]
  simp only [order_bill_adds_up, h0, sub_zero, Finset.sum_const, Finset.card_univ,
    Fintype.card_perm, Fintype.card_fin, nsmul_eq_mul]
  have : (Nat.factorial n : ℚ) ≠ 0 := by exact_mod_cast Nat.factorial_ne_zero n
  field_simp

/-- Concave costs: joining a bigger group never adds more cost. -/
def Concave (c : Finset (Fin n) → ℚ) : Prop :=
  ∀ S T i, S ⊆ T → i ∉ T → c (insert i T) - c T ≤ c (insert i S) - c S

/-- A bill `x` is in the core when it covers the whole cost exactly and charges no group more
than that group would pay on its own. -/
def InCore (c : Finset (Fin n) → ℚ) (x : Fin n → ℚ) : Prop :=
  ∑ i, x i = c univ ∧ ∀ S, ∑ i ∈ S, x i ≤ c S

/-- Step 5, first half: with concave costs, an order's bill charges no group more than that
group would pay on its own. -/
theorem order_bill_le (c : Finset (Fin n) → ℚ) (hc : Concave c) (h0 : c ∅ = 0)
    (pos : Equiv.Perm (Fin n)) (S : Finset (Fin n)) : ∑ i ∈ S, extra c pos i ≤ c S := by
  have key : ∀ k, ∑ i ∈ S.filter (fun j => (pos j : ℕ) < k), extra c pos i
      ≤ c (S.filter (fun j => (pos j : ℕ) < k)) := by
    intro k
    induction k with
    | zero => simp [h0]
    | succ k ih =>
      by_cases hk : k < n
      · set i := pos.symm ⟨k, hk⟩ with hi
        have hpi : (pos i : ℕ) = k := by simp [hi]
        have hfirst : ∀ j, ((pos j : ℕ) < k + 1 ↔ (pos j : ℕ) < k ∨ j = i) := by
          intro j
          constructor
          · intro h
            rcases Nat.lt_succ_iff_lt_or_eq.mp h with h | h
            · exact Or.inl h
            · exact Or.inr (pos.injective (Fin.ext (h.trans hpi.symm)))
          · rintro (h | rfl) <;> omega
        have hsub : S.filter (fun j => (pos j : ℕ) < k) ⊆ firstK pos k := by
          intro j hj
          simp only [mem_filter] at hj
          simp [firstK, hj.2]
        have hnot : i ∉ firstK pos k := by simp [firstK, hpi]
        have hconc := hc _ _ i hsub hnot
        have hextra : extra c pos i = c (insert i (firstK pos k)) - c (firstK pos k) := by
          simp only [extra, ahead, hpi]
        by_cases hiS : i ∈ S
        · have hset : S.filter (fun j => (pos j : ℕ) < k + 1)
              = insert i (S.filter (fun j => (pos j : ℕ) < k)) := by
            ext j
            simp only [mem_filter, mem_insert, hfirst]
            constructor
            · rintro ⟨hj, h | rfl⟩
              · exact Or.inr ⟨hj, h⟩
              · exact Or.inl rfl
            · rintro (rfl | ⟨hj, h⟩)
              · exact ⟨hiS, Or.inr rfl⟩
              · exact ⟨hj, Or.inl h⟩
          have hiN : i ∉ S.filter (fun j => (pos j : ℕ) < k) := by simp [hpi]
          rw [hset, Finset.sum_insert hiN]
          linarith
        · have hset : S.filter (fun j => (pos j : ℕ) < k + 1)
              = S.filter (fun j => (pos j : ℕ) < k) := by
            ext j
            simp only [mem_filter, hfirst]
            constructor
            · rintro ⟨hj, h | rfl⟩
              · exact ⟨hj, h⟩
              · exact absurd hj hiS
            · rintro ⟨hj, h⟩
              exact ⟨hj, Or.inl h⟩
          rw [hset]
          exact ih
      · have hset : S.filter (fun j => (pos j : ℕ) < k + 1)
            = S.filter (fun j => (pos j : ℕ) < k) := by
          ext j
          simp only [mem_filter]
          have := (pos j).isLt
          constructor <;> rintro ⟨hj, h⟩ <;> exact ⟨hj, by omega⟩
        rw [hset]
        exact ih
  have hS : S.filter (fun j => (pos j : ℕ) < n) = S := by
    ext j
    simp only [mem_filter, and_iff_left_iff_imp]
    intro _
    exact (pos j).isLt
  simpa [hS] using key n

/-- Step 5: with concave costs, every order's bill is in the core. -/
theorem order_bill_in_core (c : Finset (Fin n) → ℚ) (hc : Concave c) (h0 : c ∅ = 0)
    (pos : Equiv.Perm (Fin n)) : InCore c (extra c pos) :=
  ⟨by rw [order_bill_adds_up, h0, sub_zero], order_bill_le c hc h0 pos⟩

/-- Step 5: with concave costs, the Shapley bill, the average of the order bills, is in the
core. -/
theorem shapley_in_core (c : Finset (Fin n) → ℚ) (hc : Concave c) (h0 : c ∅ = 0) :
    InCore c (shapley c) := by
  refine ⟨shapley_efficiency c h0, fun S => ?_⟩
  have hpos : (0 : ℚ) < Nat.factorial n := by exact_mod_cast Nat.factorial_pos n
  simp only [shapley, ← Finset.sum_div]
  rw [Finset.sum_comm, div_le_iff₀ hpos]
  calc ∑ pos : Equiv.Perm (Fin n), ∑ i ∈ S, extra c pos i
      ≤ ∑ _pos : Equiv.Perm (Fin n), c S :=
        Finset.sum_le_sum (fun pos _ => order_bill_le c hc h0 pos S)
    _ = c S * Nat.factorial n := by
        simp [Finset.card_univ, Fintype.card_perm, mul_comm]

#print axioms insert_ahead
#print axioms order_bill_adds_up
#print axioms shapley_efficiency
#print axioms order_bill_le
#print axioms order_bill_in_core
#print axioms shapley_in_core

/-- A cost set by the biggest need in the group, as for one oven used in turns. -/
def maxCost (d : Fin n → ℕ) (S : Finset (Fin n)) : ℚ := ((S.sup d : ℕ) : ℚ)

/-- A biggest-need cost is concave: an upgrade forced by a newcomer can only shrink as the group
it joins grows. -/
theorem maxCost_concave (d : Fin n → ℕ) : Concave (maxCost d) := by
  intro S T i hST _
  have hab : ((S.sup d : ℕ) : ℚ) ≤ ((T.sup d : ℕ) : ℚ) := by exact_mod_cast Finset.sup_mono hST
  simp only [maxCost, Finset.sup_insert]
  push_cast
  rcases le_total (d i : ℚ) ((S.sup d : ℕ) : ℚ) with h1 | h1 <;>
    rcases le_total (d i : ℚ) ((T.sup d : ℕ) : ℚ) with h2 | h2 <;>
    simp only [max_eq_left, max_eq_right, h1, h2] <;> linarith

/-- The oven game: Ash, Birch and Cedar are players 0, 1 and 2. -/
def oven : Finset (Fin 3) → ℚ := maxCost ![1000, 2000, 3000]

/-- The twins game: a £1,000 oven has two bakeries' shifts a night. -/
def twins (S : Finset (Fin 3)) : ℚ := 1000 * (((S.card + 1) / 2 : ℕ) : ℚ)

/-- Player `i`'s extra cost in one order of the oven game, in whole pounds. Over the six orders
these add to six times the share. -/
def ovenExtra (i : Fin 3) (pos : Equiv.Perm (Fin 3)) : ℤ :=
  (((insert i (ahead pos i)).sup ![1000, 2000, 3000] : ℕ) : ℤ) -
    (((ahead pos i).sup ![1000, 2000, 3000] : ℕ) : ℤ)

/-- The oven game's Shapley shares: £2,000/6, £5,000/6 and £11,000/6, that is £333.33, £833.33
and £1,833.33. -/
theorem oven_shares :
    shapley oven 0 = 2000 / 6 ∧ shapley oven 1 = 5000 / 6 ∧ shapley oven 2 = 11000 / 6 := by
  have key : ∀ i, (∑ pos : Equiv.Perm (Fin 3), extra oven pos i) =
      ((∑ pos : Equiv.Perm (Fin 3), ovenExtra i pos : ℤ) : ℚ) := by
    intro i
    simp [extra, oven, maxCost, ovenExtra]
  have h0 : ∑ pos : Equiv.Perm (Fin 3), ovenExtra 0 pos = 2000 := by decide
  have h1 : ∑ pos : Equiv.Perm (Fin 3), ovenExtra 1 pos = 5000 := by decide
  have h2 : ∑ pos : Equiv.Perm (Fin 3), ovenExtra 2 pos = 11000 := by decide
  refine ⟨?_, ?_, ?_⟩ <;> rw [shapley, key] <;> simp [h0, h1, h2, Nat.factorial]

theorem oven_shapley_in_core : InCore oven (shapley oven) :=
  shapley_in_core oven (maxCost_concave _) (by simp [oven, maxCost])

theorem twins_not_concave : ¬ Concave twins := by
  intro h
  have := h {0} {0, 1} 2 (by decide) (by decide)
  simp [twins] at this

theorem twins_core_empty : ∀ x : Fin 3 → ℚ, ¬ InCore twins x := by
  rintro x ⟨hN, hS⟩
  have h01 := hS {0, 1}
  have h02 := hS {0, 2}
  have h12 := hS {1, 2}
  simp [Fin.sum_univ_three, twins] at hN h01 h02 h12
  norm_num at hN h01 h02 h12
  linarith

#print axioms maxCost_concave
#print axioms oven_shares
#print axioms oven_shapley_in_core
#print axioms twins_not_concave
#print axioms twins_core_empty
