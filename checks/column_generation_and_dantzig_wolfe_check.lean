-- Column generation: when no pattern that fits a board is worth more than one board at the restricted master's dual prices, the restricted plan, padded with zeros, is a best plan of the full pattern master, and at every round the master's value divided by the best pattern's worth, and the total length over the board length, are floors under every plan.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Tactic

open Finset

/-! The card's notation.
* `ι` indexes the piece lengths; `l i` is the length of piece `i` and `L` the board length,
  both in whole metres (or centimetres); `d i` is the number of pieces of length `i` wanted.
* A pattern is `a : ι → ℕ`, how many pieces of each length one board gives. It fits a board
  when `∑ i, l i * a i ≤ L`.
* `P` is a finite list of patterns that fit, the columns of the full master;
  `P' ⊆ P` is the restricted master's list.
* A plan `x` gives `x p` boards (a real number, as in the LP) to each pattern `p`. It is
  feasible for the full master when `x p ≥ 0` on `P` and `∑ p ∈ P, p i * x p ≥ d i` for every `i`.
  Every pattern costs one board, so the plan's value is `∑ p ∈ P, x p`, to be minimised.
* `y i` is the dual price of piece `i`; the worth of pattern `a` at the prices is
  `∑ i, y i * a i`; the pricing problem asks for the largest worth over all patterns that fit. -/

/-- Weak duality for the pattern master: if the prices `y ≥ 0` value no pattern of `P` above
`v`, every plan covering the order uses at least `∑ d i y i / v` boards, written here without
the division. -/
theorem weak_duality_patterns
    {ι : Type*} [Fintype ι] (d : ι → ℝ) (P : Finset (ι → ℕ))
    (y : ι → ℝ) (hy : ∀ i, 0 ≤ y i) (v : ℝ)
    (hP : ∀ a ∈ P, ∑ i, y i * (a i : ℝ) ≤ v)
    (z : (ι → ℕ) → ℝ) (hz_nonneg : ∀ p ∈ P, 0 ≤ z p)
    (hz_cover : ∀ i, d i ≤ ∑ p ∈ P, (p i : ℝ) * z p) :
    ∑ i, d i * y i ≤ v * ∑ p ∈ P, z p := by
  calc ∑ i, d i * y i ≤ ∑ i, (∑ p ∈ P, (p i : ℝ) * z p) * y i :=
        Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_right (hz_cover i) (hy i)
    _ = ∑ p ∈ P, z p * ∑ i, y i * (p i : ℝ) := by
        simp_rw [Finset.sum_mul, Finset.mul_sum]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun p _ => Finset.sum_congr rfl fun i _ => ?_
        ring
    _ ≤ ∑ p ∈ P, z p * v :=
        Finset.sum_le_sum fun p hp => mul_le_mul_of_nonneg_left (hP p hp) (hz_nonneg p hp)
    _ = v * ∑ p ∈ P, z p := by rw [← Finset.sum_mul, mul_comm]

/-- The stopping test proves optimality. Let the restricted master's plan `x'` cover the order
using only the listed patterns `P'`, let the prices `y ≥ 0` come from an optimal restricted master,
so that the plan and the prices meet (`∑ x' = ∑ d i y i`, LP strong duality on the restricted
master), and let the pricing problem, solved exactly, find no pattern that fits a board worth more
than one board. Then the plan padded with zero boards on every unlisted pattern is feasible for
the full master, has the same value, and no feasible plan of the full master uses fewer boards:
the patterns never listed cannot help. -/
theorem restricted_master_optimal_of_no_pattern_worth_more_than_one
    {ι : Type*} [Fintype ι] [DecidableEq (ι → ℕ)]
    (l : ι → ℕ) (L : ℕ) (d : ι → ℝ) (P P' : Finset (ι → ℕ))
    (hP : ∀ a ∈ P, ∑ i, l i * a i ≤ L) (hP' : P' ⊆ P)
    (x' : (ι → ℕ) → ℝ) (hx'_nonneg : ∀ p ∈ P', 0 ≤ x' p)
    (hx'_cover : ∀ i, d i ≤ ∑ p ∈ P', (p i : ℝ) * x' p)
    (y : ι → ℝ) (hy : ∀ i, 0 ≤ y i)
    (hmeet : ∑ p ∈ P', x' p = ∑ i, d i * y i)
    (hprice : ∀ a : ι → ℕ, ∑ i, l i * a i ≤ L → ∑ i, y i * (a i : ℝ) ≤ 1) :
    let x : (ι → ℕ) → ℝ := fun p => if p ∈ P' then x' p else 0
    (∀ p ∈ P, 0 ≤ x p) ∧ (∀ i, d i ≤ ∑ p ∈ P, (p i : ℝ) * x p) ∧
      ∑ p ∈ P, x p = ∑ p ∈ P', x' p ∧
      ∀ z : (ι → ℕ) → ℝ, (∀ p ∈ P, 0 ≤ z p) → (∀ i, d i ≤ ∑ p ∈ P, (p i : ℝ) * z p) →
        ∑ p ∈ P', x' p ≤ ∑ p ∈ P, z p := by
  intro x
  have hsum : ∀ f : (ι → ℕ) → ℝ, ∑ p ∈ P, (if p ∈ P' then f p else 0) = ∑ p ∈ P', f p := by
    intro f
    rw [Finset.sum_ite_mem, Finset.inter_eq_right.mpr hP']
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro p _
    show 0 ≤ (if p ∈ P' then x' p else 0)
    split_ifs with h
    · exact hx'_nonneg p h
    · exact le_refl 0
  · intro i
    have : ∑ p ∈ P, (p i : ℝ) * x p = ∑ p ∈ P', (p i : ℝ) * x' p := by
      rw [← hsum (fun p => (p i : ℝ) * x' p)]
      refine Finset.sum_congr rfl fun p _ => ?_
      show (p i : ℝ) * (if p ∈ P' then x' p else 0) = _
      split_ifs <;> simp
    rw [this]
    exact hx'_cover i
  · exact hsum x'
  · intro z hz_nonneg hz_cover
    have h := weak_duality_patterns d P y hy 1 (fun a ha => hprice a (hP a ha)) z hz_nonneg
      hz_cover
    rw [hmeet]
    linarith

/-- Farley's floor at every round. Let the restricted master's value be `z_RMP = ∑ d i y i` at
prices `y ≥ 0`, and let `v* > 0` be at least the worth of every pattern that fits a board (the
pricing value). Then every feasible plan of the full master uses at least `z_RMP / v*` boards:
the prices `y / v*` value no pattern above one board, and weak duality does the rest. -/
theorem master_value_div_pricing_value_le_lp
    {ι : Type*} [Fintype ι]
    (l : ι → ℕ) (L : ℕ) (d : ι → ℝ) (P : Finset (ι → ℕ))
    (hP : ∀ a ∈ P, ∑ i, l i * a i ≤ L)
    (y : ι → ℝ) (hy : ∀ i, 0 ≤ y i) (zRMP v : ℝ) (hz : zRMP = ∑ i, d i * y i) (hv : 0 < v)
    (hprice : ∀ a : ι → ℕ, ∑ i, l i * a i ≤ L → ∑ i, y i * (a i : ℝ) ≤ v)
    (z : (ι → ℕ) → ℝ) (hz_nonneg : ∀ p ∈ P, 0 ≤ z p)
    (hz_cover : ∀ i, d i ≤ ∑ p ∈ P, (p i : ℝ) * z p) :
    zRMP / v ≤ ∑ p ∈ P, z p := by
  have h := weak_duality_patterns d P y hy v (fun a ha => hprice a (hP a ha)) z hz_nonneg
    hz_cover
  rw [hz, div_le_iff₀ hv]
  linarith

/-- The length floor. Price each piece at its share of a board, `y i = l i / L`. Every pattern
fits on one board, so no pattern is worth more than one board, and every feasible plan of the full
master uses at least the total length of the order divided by the board length. -/
theorem total_length_div_board_length_le_lp
    {ι : Type*} [Fintype ι]
    (l : ι → ℕ) (L : ℕ) (hL : 0 < L) (d : ι → ℝ) (P : Finset (ι → ℕ))
    (hP : ∀ a ∈ P, ∑ i, l i * a i ≤ L)
    (z : (ι → ℕ) → ℝ) (hz_nonneg : ∀ p ∈ P, 0 ≤ z p)
    (hz_cover : ∀ i, d i ≤ ∑ p ∈ P, (p i : ℝ) * z p) :
    (∑ i, (l i : ℝ) * d i) / L ≤ ∑ p ∈ P, z p := by
  have hLpos : (0 : ℝ) < L := by exact_mod_cast hL
  have hprice : ∀ a ∈ P, ∑ i, ((l i : ℝ) / L) * (a i : ℝ) ≤ 1 := by
    intro a ha
    have h1 : (∑ i, ((l i * a i : ℕ) : ℝ)) ≤ (L : ℝ) := by
      rw [← Nat.cast_sum]; exact_mod_cast hP a ha
    calc ∑ i, ((l i : ℝ) / L) * (a i : ℝ) = (∑ i, ((l i * a i : ℕ) : ℝ)) / L := by
          rw [Finset.sum_div]
          refine Finset.sum_congr rfl fun i _ => ?_
          push_cast; ring
      _ ≤ 1 := by rw [div_le_one hLpos]; exact h1
  have h := weak_duality_patterns d P (fun i => (l i : ℝ) / L)
    (fun i => div_nonneg (Nat.cast_nonneg _) hLpos.le) 1 hprice z hz_nonneg hz_cover
  have heq : (∑ i, (l i : ℝ) * d i) / L = ∑ i, d i * ((l i : ℝ) / L) := by
    rw [Finset.sum_div]
    refine Finset.sum_congr rfl fun i _ => ?_
    ring
  rw [heq]
  linarith

-- Round 0: the plain patterns (3, 0, 0), (0, 2, 0), (0, 0, 2) need 10, 10 and 5 boards, 25 in all,
-- and break even at the prices 1/3, 1/2, 1/2.
example : (3 : ℚ) * 10 = 30 ∧ (2 : ℚ) * 10 = 20 ∧ (2 : ℚ) * 5 = 10 ∧ (10 + 10 + 5 : ℚ) = 25 ∧
    (3 : ℚ) * (1 / 3) = 1 ∧ (2 : ℚ) * (1 / 2) = 1 ∧ (30 : ℚ) / 3 + 20 / 2 + 10 / 2 = 25 := by
  norm_num

-- Round 0 pricing: (2, 1, 0) is worth 2/3 + 1/2 = 7/6 of a board, so its reduced cost is -1/6.
example : (2 : ℚ) * (1 / 3) + 1 * (1 / 2) + 0 * (1 / 2) = 7 / 6 ∧ (1 : ℚ) - 7 / 6 = -1 / 6 := by
  norm_num

-- Round 0 pricing, in sixths: (2, 1, 0) fits a 10 m board yet is worth 7 sixths, more than 6.
example : 3 * 2 + 4 * 1 + 5 * 0 ≤ 10 ∧ 6 < 2 * 2 + 3 * 1 + 3 * 0 := by decide

-- Round 0 floors: Farley's 25 / (7/6) = 150/7, and the Lagrangian floor with κ = 25,
-- 25 + 25 × (1 - 7/6) = 125/6, which is weaker.
example : (25 : ℚ) / (7 / 6) = 150 / 7 ∧ (25 : ℚ) + 25 * (1 - 7 / 6) = 125 / 6 ∧
    (125 / 6 : ℚ) < 150 / 7 := by
  norm_num

-- Round 1: 15 boards of (2, 1, 0), 5/2 of (0, 2, 0) and 5 of (0, 0, 2) cover 30, 20 and 10 pieces
-- with 45/2 boards; the prices 1/4, 1/2, 1/2 break even on the patterns in use and are worth 45/2.
example : (15 : ℚ) * 2 = 30 ∧ (15 : ℚ) * 1 + 5 / 2 * 2 = 20 ∧ (5 : ℚ) * 2 = 10 ∧
    (15 + 5 / 2 + 5 : ℚ) = 45 / 2 ∧
    (2 : ℚ) * (1 / 4) + 1 / 2 = 1 ∧ (2 : ℚ) * (1 / 2) = 1 ∧
    (30 : ℚ) * (1 / 4) + 20 * (1 / 2) + 10 * (1 / 2) = 45 / 2 := by
  norm_num

-- Round 1 pricing, in quarters: every pattern (a, b, c) that fits a 10 m board is worth at most
-- one board at the prices 1/4, 1/2, 1/2, so the loop stops.
example : ∀ a < 4, ∀ b < 3, ∀ c < 3, 3 * a + 4 * b + 5 * c ≤ 10 → a + 2 * b + 2 * c ≤ 4 := by
  decide

-- The decking order has 11 patterns that fit a 10 m board, not counting the empty one.
example : ((range 4 ×ˢ range 3 ×ˢ range 3).filter
    (fun t : ℕ × ℕ × ℕ => 3 * t.1 + 4 * t.2.1 + 5 * t.2.2 ≤ 10 ∧ t ≠ (0, 0, 0))).card = 11 := by
  decide

-- The length floor: 3 × 30 + 4 × 20 + 5 × 10 = 220 m of pieces, so at least 220 / 10 = 22 boards.
example : 3 * 30 + 4 * 20 + 5 * 10 = 220 ∧ (220 : ℚ) / 10 = 22 := by norm_num

-- The board-by-board LP: 22 boards each holding 15/11, 10/11 and 5/11 pieces fill 10 m exactly
-- and cover the order.
example : (3 : ℚ) * (15 / 11) + 4 * (10 / 11) + 5 * (5 / 11) = 10 ∧
    (22 : ℚ) * (15 / 11) = 30 ∧ (22 : ℚ) * (10 / 11) = 20 ∧ (22 : ℚ) * (5 / 11) = 10 := by
  norm_num

-- Whole boards: 15 of (2, 1, 0), 3 of (0, 2, 0) and 5 of (0, 0, 2) are 23 boards covering
-- 30, 21 and 10 pieces, with 10 m unused: 6 m of offcut and one spare 4 m piece.
example : 15 + 3 + 5 = 23 ∧ 15 * 2 = 30 ∧ 15 * 1 + 3 * 2 = 21 ∧ 5 * 2 = 10 ∧
    23 * 10 - 220 = 10 ∧ 3 * 2 + 5 * 0 = 6 ∧ 10 - 6 = 4 := by
  norm_num

-- Rounding the LP plan down: 15 + 2 + 5 = 22 boards give only 15 + 4 = 19 of the 20 middle pieces.
example : 15 + 2 + 5 = 22 ∧ 15 * 1 + 2 * 2 = 19 ∧ 19 < 20 := by norm_num

-- Greedy pricing at round 0: per metre the 4 m piece scores 1/8, above 1/9 and 1/10, and two 4 m
-- pieces are worth exactly 1, so greedy reports no improving pattern.
example : (1 / 3 : ℚ) / 3 = 1 / 9 ∧ (1 / 2 : ℚ) / 4 = 1 / 8 ∧ (1 / 2 : ℚ) / 5 = 1 / 10 ∧
    (1 / 10 : ℚ) < 1 / 9 ∧ (1 / 9 : ℚ) < 1 / 8 ∧ (2 : ℚ) * (1 / 2) = 1 := by
  norm_num

-- The ten-length run: the order's total length over a 1,000 cm board is 1509/25 = 60.36 boards,
-- equal to the LP value, and the final prices 3/25, 3/20, 9/50 are 120, 150, 180 cm over 1,000 cm.
example : (120 * 30 + 150 * 25 + 180 * 40 + 230 * 22 + 270 * 18 + 310 * 35 + 340 * 14 +
      380 * 20 + 430 * 12 + 470 * 16 : ℚ) / 1000 = 1509 / 25 ∧
    (120 : ℚ) / 1000 = 3 / 25 ∧ (150 : ℚ) / 1000 = 3 / 20 ∧ (180 : ℚ) / 1000 = 9 / 50 := by
  norm_num

-- Try changing: 11 m boards give the length floor 220 / 11 = 20.
example : (220 : ℚ) / 11 = 20 := by norm_num

#print axioms weak_duality_patterns
#print axioms restricted_master_optimal_of_no_pattern_worth_more_than_one
#print axioms master_value_div_pricing_value_le_lp
#print axioms total_length_div_board_length_le_lp
