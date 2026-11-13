-- Reading a currency quote: with positive quotes dealt both ways, no loop round a triangle of currencies pays exactly when the direct cross equals the product of the two legs, with bid and ask no loop pays exactly when the cross sits inside the band from bid times bid to ask times ask, and away from the product exactly one direction of the loop pays.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Basic.Logic.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

/-! A pair `AB` quoted at price `S_AB` means one unit of `A` (the base, the thing) costs `S_AB`
units of `B` (the quote currency, the money). Selling the first-named currency multiplies by the
price; buying it divides. Below, `sAB` is EURUSD-style (B per A), `sBC` is USDJPY-style (C per B),
and `q` is a directly quoted cross AC (C per A), dealt both ways at that one price. -/

/-- **Without free money, a cross rate equals the product of the two quotes it is built from.**
Start with one unit of `A`. The loop `A → B → C → A` sells `A` at `sAB`, sells `B` at `sBC`, and
buys `A` back from the cross dealer at `q`, ending with `sAB * sBC / q` units of `A`. The reverse
loop `A → C → B → A` sells `A` to the cross dealer at `q`, buys `B` with `C` at `sBC`, and buys `A`
with `B` at `sAB`, ending with `q / sBC / sAB` units of `A`. Neither loop brings back more than
the one unit it started with exactly when `q = sAB * sBC`. -/
theorem no_free_loop_iff_cross_eq_product (sAB sBC q : ℝ)
    (hAB : 0 < sAB) (hBC : 0 < sBC) (hq : 0 < q) :
    (sAB * sBC / q ≤ 1 ∧ q / sBC / sAB ≤ 1) ↔ q = sAB * sBC := by
  have e : q / sBC / sAB = q / (sAB * sBC) := by rw [div_div, mul_comm sBC sAB]
  rw [e, div_le_one hq, div_le_one (mul_pos hAB hBC)]
  constructor
  · rintro ⟨h1, h2⟩; linarith
  · intro h; exact ⟨h.ge, h.le⟩

/-- **With bid and ask, no loop pays exactly when the quoted cross lies in the band
`b_AB * b_BC ≤ q ≤ a_AB * a_BC`.** Each leg has a bid (where the dealer buys the base currency)
and an ask (where the dealer sells it); a cross dealer quotes the single price `q`, dealt both
ways. Starting from any amount `X` of `C`: buying `B` at the ask `aBC`, then `A` at the ask `aAB`,
then selling `A` to the cross dealer gives `X / aBC / aAB * q`; buying `A` from the cross dealer,
then selling it for `B` at the bid `bAB` and the `B` for `C` at the bid `bBC`, gives
`X / q * bAB * bBC`. Neither loop ends above its start, for every starting amount, exactly when
the cross sits inside the band. -/
theorem no_free_loop_iff_cross_in_band (bAB aAB bBC aBC q : ℝ)
    (hbAB : 0 < bAB) (haAB : 0 < aAB) (hbBC : 0 < bBC) (haBC : 0 < aBC) (hq : 0 < q) :
    (∀ X : ℝ, 0 < X → X / aBC / aAB * q ≤ X ∧ X / q * bAB * bBC ≤ X) ↔
      (bAB * bBC ≤ q ∧ q ≤ aAB * aBC) := by
  have hP : 0 < aAB * aBC := mul_pos haAB haBC
  have e1 : ∀ X : ℝ, X / aBC / aAB * q = X * (q / (aAB * aBC)) := by
    intro X; field_simp
  have e2 : ∀ X : ℝ, X / q * bAB * bBC = X * (bAB * bBC / q) := by
    intro X; field_simp
  constructor
  · intro h
    obtain ⟨h1, h2⟩ := h 1 one_pos
    rw [e1, one_mul, div_le_one hP] at h1
    rw [e2, one_mul, div_le_one hq] at h2
    exact ⟨h2, h1⟩
  · rintro ⟨h1, h2⟩ X hX
    rw [e1, e2]
    have k1 : q / (aAB * aBC) ≤ 1 := (div_le_one hP).2 h2
    have k2 : bAB * bBC / q ≤ 1 := (div_le_one hq).2 h1
    exact ⟨by nlinarith, by nlinarith⟩

/-- **Exactly one direction wins.** When the quoted cross `q` differs from the product of the
legs, exactly one of the two loops round the triangle (forward growth `sAB * sBC / q`, reverse
growth `q / sBC / sAB`) brings back more than the one unit it started with. -/
theorem exactly_one_direction_pays (sAB sBC q : ℝ)
    (hAB : 0 < sAB) (hBC : 0 < sBC) (hq : 0 < q) (hne : q ≠ sAB * sBC) :
    Xor (1 < sAB * sBC / q) (1 < q / sBC / sAB) := by
  have e : q / sBC / sAB = q / (sAB * sBC) := by rw [div_div, mul_comm sBC sAB]
  have hP : 0 < sAB * sBC := mul_pos hAB hBC
  rw [e, one_lt_div hq, one_lt_div hP]
  rcases lt_or_gt_of_ne hne with h | h
  · exact Or.inl ⟨h, not_lt.2 h.le⟩
  · exact Or.inr ⟨h, not_lt.2 h.le⟩

/-! The card's worked numbers, as exact fractions: EURUSD 1.1000 = 11/10, USDJPY 150,
GBPUSD 1.2500 = 5/4, broker EURJPY 165.50 = 331/2. -/

-- Flip: USDEUR = 1 / 1.1000 = 10/11 (0.909091 rounded).
example : (1 : ℚ) / (11 / 10) = 10 / 11 := by norm_num
-- Cross: EURJPY = 1.1000 × 150.00 = 165.00.
example : (11 / 10 : ℚ) * 150 = 165 := by norm_num
-- Division shape: EURGBP = 1.1000 / 1.2500 = 0.8800.
example : (11 / 10 : ℚ) / (5 / 4) = 22 / 25 := by norm_num
-- Broker's excess: 165.50 − 165.00 = 0.50 yen = 50 pips of 0.01.
example : ((331 / 2 : ℚ) - 165) / (1 / 100) = 50 := by norm_num
-- The edge: 165.50 / 165.00 − 1 = 1/330 (0.3030%).
example : (331 / 2 : ℚ) / 165 - 1 = 1 / 330 := by norm_num
-- The loop: 16,500,000 JPY → 110,000 USD → 100,000 EUR → 16,550,000 JPY, keeping 50,000 JPY.
example : (16500000 : ℚ) / 150 = 110000 := by norm_num
example : (110000 : ℚ) / (11 / 10) = 100000 := by norm_num
example : (100000 : ℚ) * (331 / 2) = 16550000 := by norm_num
example : (16550000 : ℚ) - 16500000 = 50000 := by norm_num
-- Same profit counted in pips: 50 pips × 0.01 × 100,000 euros = 50,000 JPY.
example : (50 : ℚ) * (1 / 100) * 100000 = 50000 := by norm_num
-- The band from the two-pip legs: 1.0999 × 149.99 = 164.974001 and 1.1001 × 150.01 = 165.026001.
example : (10999 / 10000 : ℚ) * (14999 / 100) = 164974001 / 1000000 := by norm_num
example : (11001 / 10000 : ℚ) * (15001 / 100) = 165026001 / 1000000 := by norm_num
-- Broker at 165.50 sits above the band; a 165.00/166.00 broker's bid is below the band's top
-- and its ask above the band's bottom, so no loop pays.
example : (165026001 / 1000000 : ℚ) < 331 / 2 := by norm_num
example : (165 : ℚ) < 165026001 / 1000000 ∧ (164974001 / 1000000 : ℚ) < 166 := by norm_num
-- Mistake: multiplying EURUSD by GBPUSD gives 1.3750, not 0.8800.
example : (11 / 10 : ℚ) * (5 / 4) = 11 / 8 := by norm_num

#print axioms no_free_loop_iff_cross_eq_product
#print axioms no_free_loop_iff_cross_in_band
#print axioms exactly_one_direction_pays
