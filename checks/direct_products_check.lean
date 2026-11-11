-- Direct products: two clocks of m and n positions, run side by side, are one clock of m × n positions exactly when m and n share no factor, a pair comes home after the least common multiple of its halves' return times, and the settings multiply.
import Mathlib.Data.ZMod.Basic
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Tactic.Linarith

/-- Two clocks make one bigger clock exactly when their sizes share no factor. For clocks of
m and n positions (m and n at least 1), the pairs of readings, each clock turning on its own,
are the m × n clock relabelled (a relabelling that carries addition) exactly when m and n have
no common factor above 1. -/
theorem two_clocks_make_one_clock_iff_coprime (m n : ℕ) (hm : 0 < m) (hn : 0 < n) :
    Nonempty (ZMod (m * n) ≃+ ZMod m × ZMod n) ↔ Nat.Coprime m n := by
  constructor
  · rintro ⟨e⟩
    have h1 : addOrderOf (1 : ZMod (m * n)) = m * n := by
      rw [ZMod.addOrderOf_one]
    have h2 : addOrderOf (e 1) = m * n := by
      rw [AddEquiv.addOrderOf_eq e, h1]
    have h3 : ∀ (k : ℕ) (a : ZMod k), addOrderOf a ∣ k := fun k a =>
      addOrderOf_dvd_of_nsmul_eq_zero (by rw [nsmul_eq_mul]; simp)
    have h4 : m * n ∣ Nat.lcm m n := by
      rw [← h2]
      generalize e 1 = x
      rw [Prod.addOrderOf]
      exact Nat.lcm_dvd ((h3 m x.1).trans (Nat.dvd_lcm_left m n)) ((h3 n x.2).trans (Nat.dvd_lcm_right m n))
    have h5 : Nat.gcd m n * Nat.lcm m n = m * n := Nat.gcd_mul_lcm m n
    have h6 : 0 < Nat.lcm m n := Nat.lcm_pos hm hn
    have h7 := Nat.le_of_dvd h6 h4
    have h8 : Nat.gcd m n = 1 := by
      have : 0 < Nat.gcd m n := Nat.gcd_pos_of_pos_left n hm
      by_contra hne
      have : 2 ≤ Nat.gcd m n := by omega
      nlinarith [Nat.mul_le_mul_right (Nat.lcm m n) this]
    exact h8
  · intro h
    exact ⟨(ZMod.chineseRemainder h).toAddEquiv⟩

/-- A pair comes home when both halves do at once. In any two groups, if g and h each come
home after some number of repeats, the pair (g, h) comes home first after the least common
multiple of their return times. -/
theorem pair_order_eq_lcm {G H : Type*} [Group G] [Group H] (g : G) (h : H)
    (hg : IsOfFinOrder g) (hh : IsOfFinOrder h) :
    orderOf (g, h) = Nat.lcm (orderOf g) (orderOf h) := by
  rw [Prod.orderOf_mk]

/-- The settings multiply. For two finite groups, the direct product has as many members as
the first group times the second. -/
theorem card_prod_eq_mul {G H : Type*} [Group G] [Group H] [Finite G] [Finite H] :
    Nat.card (G × H) = Nat.card G * Nat.card H := by
  have := Nat.card_prod G H
  exact this

-- The padlock: 3 × 5 = 15 settings; adding the dial counts gives 8, the mistake.
example : Fintype.card (ZMod 3 × ZMod 5) = 15 := by decide
example : 3 * 5 = 15 ∧ 3 + 5 = 8 := by decide
-- The joint notch from (0,0): 15 settings visited, all different, before coming home.
example : (List.range 15).map (fun k => (k % 3, k % 5)) =
    [(0, 0), (1, 1), (2, 2), (0, 3), (1, 4), (2, 0), (0, 1), (1, 2), (2, 3), (0, 4), (1, 0),
      (2, 1), (0, 2), (1, 3), (2, 4)] := by decide
example : ((List.range 15).map (fun k => (k % 3, k % 5))).Nodup := by decide
-- The joint notch's return time: lcm(3, 5) = 15, and no earlier repeat has both dials home.
example : Nat.lcm 3 5 = 15 := by decide
example : ∀ k < 15, 0 < k → k % 3 ≠ 0 ∨ k % 5 ≠ 0 := by decide
-- Orders by reading 0 to 14, walked on the 15-dial and from the lcm of each dial's own return time.
example : (List.range 15).map (fun k => 15 / Nat.gcd k 15) =
    [1, 15, 15, 5, 15, 3, 5, 15, 15, 5, 3, 15, 5, 15, 15] := by decide
example : (List.range 15).map (fun k => Nat.lcm (3 / Nat.gcd (k % 3) 3) (5 / Nat.gcd (k % 5) 5)) =
    [1, 15, 15, 5, 15, 3, 5, 15, 15, 5, 3, 15, 5, 15, 15] := by decide
-- Reading 14 is the pair (2, 4); the reverse (10 × 2 + 6 × 4) mod 15 gives 14.
example : 14 % 3 = 2 ∧ 14 % 5 = 4 ∧ (10 * 2 + 6 * 4) % 15 = 14 := by decide
-- 10 carries the 3-dial, 6 the 5-dial.
example : 10 % 3 = 1 ∧ 10 % 5 = 0 ∧ 6 % 3 = 0 ∧ 6 % 5 = 1 := by decide
-- The grid of readings, rows the 3-dial, columns the 5-dial.
example : (List.range 3).map (fun a => (List.range 5).map (fun b => (10 * a + 6 * b) % 15)) =
    [[0, 6, 12, 3, 9], [10, 1, 7, 13, 4], [5, 11, 2, 8, 14]] := by decide
-- All 15 settings translate back, and all 225 pair sums match the 15-clock.
example : ∀ k < 15, (10 * (k % 3) + 6 * (k % 5)) % 15 = k := by decide
example : ∀ a < 3, ∀ b < 5, ∀ c < 3, ∀ d < 5,
    (10 * ((a + c) % 3) + 6 * ((b + d) % 5)) % 15 =
      ((10 * a + 6 * b) % 15 + (10 * c + 6 * d) % 15) % 15 := by decide
-- Two switches: every pattern comes home in two flips at most; a 4-dial's notch does not.
example : ∀ x : ZMod 2 × ZMod 2, x + x = 0 := by decide
example : (1 : ZMod 4) + 1 ≠ 0 ∧ (1 : ZMod 4) + 1 + 1 ≠ 0 ∧ (1 : ZMod 4) + 1 + 1 + 1 = 0 := by
  decide
-- Multiplying the switch return times gives 4; the lcm gives 2. 2 and 2 share a factor; 3 and 5 do not.
example : 2 * 2 = 4 ∧ Nat.lcm 2 2 = 2 := by decide
example : ¬ Nat.Coprime 2 2 ∧ Nat.Coprime 3 5 := by decide
-- A 6-dial with a 4-dial: 24 settings, longest return lcm(6, 4) = 12, gcd(6, 4) = 2.
example : 6 * 4 = 24 ∧ Nat.lcm 6 4 = 12 ∧ Nat.gcd 6 4 = 2 := by decide
-- Try changing: a 3-dial with a 6-dial reaches only lcm(3, 6) = 6 of 18 settings.
example : 3 * 6 = 18 ∧ Nat.lcm 3 6 = 6 := by decide

#print axioms two_clocks_make_one_clock_iff_coprime
#print axioms pair_order_eq_lcm
#print axioms card_prod_eq_mul
