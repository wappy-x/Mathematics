-- Pigeonhole, extended: however n items are put into k boxes, some box holds at least n/k rounded up, some filing makes that the fullest box exactly, and any n whole numbers in a row hide a run of consecutive ones summing to a multiple of n, with the card's 100-email and ten-day numbers checked.
import Mathlib.Combinatorics.Pigeonhole
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Data.Rat.Floor
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Data.Fintype.Pigeonhole
import Mathlib.Algebra.BigOperators.Intervals

/-- Spread the items of a finite collection `α` over the boxes `β` (at least one box) by a rule
`f` that puts every item in exactly one box. However the items are placed, some box `y` holds
at least `n / k` rounded up, where `n = |α|` items and `k = |β|` boxes. -/
theorem exists_box_with_at_least_ceil_div {α β : Type*} [Fintype α] [Fintype β] [DecidableEq β]
    [Nonempty β] (f : α → β) :
    ∃ y : β, ⌈(Fintype.card α : ℚ) / Fintype.card β⌉₊ ≤ (Finset.univ.filter (fun a => f a = y)).card := by
  set c := ⌈(Fintype.card α : ℚ) / Fintype.card β⌉₊ with hc
  rcases Nat.eq_zero_or_pos c with h0 | hpos
  · exact ⟨Classical.arbitrary β, by rw [h0]; exact Nat.zero_le _⟩
  have hlt : ((c - 1 : ℕ) : ℚ) < (Fintype.card α : ℚ) / Fintype.card β :=
    Nat.lt_ceil.mp (by omega)
  have hk : (0 : ℚ) < Fintype.card β := by exact_mod_cast Fintype.card_pos
  have hmul : Fintype.card β * (c - 1) < Fintype.card α := by
    rw [lt_div_iff₀ hk] at hlt
    exact_mod_cast (by linarith : ((Fintype.card β : ℕ) : ℚ) * ((c - 1 : ℕ) : ℚ) < Fintype.card α)
  obtain ⟨y, hy⟩ := Fintype.exists_lt_card_fiber_of_mul_lt_card f hmul
  exact ⟨y, by omega⟩

/-- The bound cannot be sharpened: for any `n` items and `k ≥ 1` boxes there is a filing in
which every box holds at most `n / k` rounded up, so the fullest box holds exactly that. -/
theorem ceil_div_bound_is_attained (n k : ℕ) (hk : 0 < k) :
    ∃ f : Fin n → Fin k, ∀ y : Fin k,
      (Finset.univ.filter (fun i => f i = y)).card ≤ ⌈(n : ℚ) / k⌉₊ := by
  set c := ⌈(n : ℚ) / k⌉₊ with hc
  have hkq : (0 : ℚ) < k := by exact_mod_cast hk
  have hnc : n ≤ k * c := by
    have h := Nat.le_ceil ((n : ℚ) / k)
    rw [← hc, div_le_iff₀ hkq] at h
    exact_mod_cast (by linarith : (n : ℚ) ≤ (k : ℚ) * (c : ℚ))
  have hlt : ∀ i : Fin n, i.val / c < k := by
    intro i
    have hcpos : 0 < c := by
      rcases Nat.eq_zero_or_pos c with h0 | h0
      · rw [h0] at hnc; have := i.isLt; omega
      · exact h0
    rw [Nat.div_lt_iff_lt_mul hcpos]
    have := i.isLt
    calc i.val < n := this
      _ ≤ k * c := hnc
      _ = k * c := rfl
  refine ⟨fun i => ⟨i.val / c, hlt i⟩, fun y => ?_⟩
  calc (Finset.univ.filter (fun i : Fin n => (⟨i.val / c, hlt i⟩ : Fin k) = y)).card
      ≤ (Finset.range c).card := by
        apply Finset.card_le_card_of_injOn (fun i => i.val % c)
        · intro i _
          have hcpos : 0 < c := by
            rcases Nat.eq_zero_or_pos c with h0 | h0
            · rw [h0] at hnc; have := i.isLt; omega
            · exact h0
          simp only [Finset.coe_range, Set.mem_Iio]
          exact Nat.mod_lt _ hcpos
        · intro i hi j hj hij
          simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hi hj
          have hq : i.val / c = j.val / c := by
            have := congrArg Fin.val (hi.trans hj.symm)
            simpa using this
          apply Fin.ext
          rw [← Nat.div_add_mod i.val c, ← Nat.div_add_mod j.val c, hq]
          simp only at hij
          rw [hij]
    _ = c := Finset.card_range c

/-- Any `n ≥ 1` whole numbers `a 0, a 1, …, a (n − 1)` in a row contain a non-empty run of
consecutive ones, from position `u` up to position `v − 1`, whose total is a multiple of `n`. -/
theorem exists_consecutive_run_sum_dvd (n : ℕ) (hn : 0 < n) (a : ℕ → ℤ) :
    ∃ u v : ℕ, u < v ∧ v ≤ n ∧ (n : ℤ) ∣ ∑ i ∈ Finset.Ico u v, a i := by
  have : NeZero n := ⟨by omega⟩
  let S : ℕ → ℤ := fun j => ∑ i ∈ Finset.range j, a i
  let g : Fin (n + 1) → ZMod n := fun j => (S j.val : ZMod n)
  obtain ⟨x, y, hxy, hg⟩ := Fintype.exists_ne_map_eq_of_card_lt g (by simp)
  have key : ∀ x y : Fin (n + 1), x.val < y.val → g x = g y →
      ∃ u v : ℕ, u < v ∧ v ≤ n ∧ (n : ℤ) ∣ ∑ i ∈ Finset.Ico u v, a i := by
    intro x y hlt he
    refine ⟨x.val, y.val, hlt, by omega, ?_⟩
    rw [Finset.sum_Ico_eq_sub _ hlt.le]
    exact ((ZMod.intCast_eq_intCast_iff _ _ _).mp he).dvd
  rcases lt_or_gt_of_ne (Fin.val_ne_of_ne hxy) with h | h
  · exact key x y h hg
  · exact key y x h hg.symm

-- 100 emails in 12 folders: the average 100/12 rounded up is 9.
example : ⌈(100 : ℚ) / 12⌉₊ = 9 := by
  rw [Nat.ceil_eq_iff (by norm_num)]; norm_num
-- Cap every folder at 8: 12 × 8 = 96 slots, 4 short of 100; evenly, 100 = 8 × 12 + 4.
example : 12 * 8 = 96 ∧ 100 - 96 = 4 ∧ 100 = 8 * 12 + 4 := by decide
-- Four folders of 9 and eight of 8 hold all 100.
example : 4 * 9 + 8 * 8 = 100 := by decide
-- Dealt out one at a time round the 12 folders, the loads are 9, 9, 9, 9 and eight 8s.
example : (List.range 12).map (fun j => ((List.range 100).filter (fun i => i % 12 = j)).length)
    = [9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8] := by decide
-- Mistake 1: for 120 emails in 12 folders, whole part plus 1 gives 11, but the forced load is 10.
example : 120 / 12 + 1 = 11 := by decide
example : ⌈(120 : ℚ) / 12⌉₊ = 10 := by
  rw [Nat.ceil_eq_iff (by norm_num)]; norm_num
-- Mistake 2: 13 folders instead of 12 gives 8, not 9.
example : ⌈(100 : ℚ) / 13⌉₊ = 8 := by
  rw [Nat.ceil_eq_iff (by norm_num)]; norm_num
-- The ten days of arrivals: the eleven running totals, starting with the empty one.
example : (List.range 11).map (fun j => ([23, 41, 17, 8, 36, 52, 12, 29, 4, 31].take j).sum)
    = [0, 23, 64, 81, 89, 125, 177, 189, 218, 222, 253] := by decide
-- Their remainders after dividing by 10.
example : [0, 23, 64, 81, 89, 125, 177, 189, 218, 222, 253].map (· % 10)
    = [0, 3, 4, 1, 9, 5, 7, 9, 8, 2, 3] := by decide
-- 89 and 189 share remainder 9; days 5 to 7 total 189 − 89 = 100, a multiple of 10.
example : 89 % 10 = 9 ∧ 189 % 10 = 9 ∧ 189 - 89 = 100 ∧ 36 + 52 + 12 = 100 ∧ 100 % 10 = 0 := by
  decide
-- The other run the search finds: days 2 to 10 total 230.
example : 41 + 17 + 8 + 36 + 52 + 12 + 29 + 4 + 31 = 230 ∧ 230 % 10 = 0 := by decide

#print axioms exists_box_with_at_least_ceil_div
#print axioms ceil_div_bound_is_attained
#print axioms exists_consecutive_run_sum_dvd
