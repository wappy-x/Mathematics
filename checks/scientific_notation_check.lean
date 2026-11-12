-- Scientific notation: every positive number can be written in exactly one way as a front number from 1 up to, not including, 10 times a whole power of ten, and multiplying or dividing such numbers multiplies or divides the front numbers while the powers add or subtract.
import Mathlib.Data.Real.Basic
import Mathlib.Data.Int.Log
import Mathlib.Algebra.Order.Field.Power
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Data.Real.Archimedean

/-- The card's claim: any positive number can be split into a front number from 1 up to, not
including, 10, times ten to a whole power, and the split is the only one, so nothing is lost. The
pair is (front number, power): 150,000,000 is (1.5, 8) and 0.000007 is (7, -6). -/
theorem scientific_notation_exists_unique (x : ℝ) (hx : 0 < x) :
    ∃! p : ℝ × ℤ, 1 ≤ p.1 ∧ p.1 < 10 ∧ x = p.1 * (10 : ℝ) ^ p.2 := by
  have key : ∀ (a b : ℝ) (m n : ℤ), 1 ≤ a → a < 10 → 1 ≤ b → b < 10 →
      a * (10 : ℝ) ^ m = b * (10 : ℝ) ^ n → n ≤ m := by
    intro a b m n ha ha' hb hb' h
    by_contra hlt
    push_neg at hlt
    have h1 : m + 1 ≤ n := hlt
    have hp : (0 : ℝ) < (10 : ℝ) ^ m := zpow_pos (by norm_num) m
    have h2 : a * (10 : ℝ) ^ m < (10 : ℝ) ^ (m + 1) := by
      rw [zpow_add_one₀ (by norm_num)]
      nlinarith
    have h3 : (10 : ℝ) ^ (m + 1) ≤ (10 : ℝ) ^ n :=
      zpow_le_zpow_right₀ (by norm_num) h1
    have hq : (0 : ℝ) < (10 : ℝ) ^ n := zpow_pos (by norm_num) n
    have h4 : (10 : ℝ) ^ n ≤ b * (10 : ℝ) ^ n := by nlinarith [mul_nonneg (sub_nonneg.2 hb) hq.le]
    linarith
  have hk0 : (0 : ℝ) < (10 : ℝ) ^ (Int.log 10 x) := zpow_pos (by norm_num) _
  have e1 : 1 ≤ x / (10 : ℝ) ^ (Int.log 10 x) := by
    have := Int.zpow_log_le_self (b := 10) (by norm_num) hx
    push_cast at this
    rw [le_div_iff₀ hk0]
    linarith
  have e2 : x / (10 : ℝ) ^ (Int.log 10 x) < 10 := by
    have := Int.lt_zpow_succ_log_self (b := 10) (by norm_num) x
    rw [div_lt_iff₀ hk0]
    rw [zpow_add_one₀ (by norm_num)] at this
    push_cast at this
    linarith
  have e3 : x = x / (10 : ℝ) ^ (Int.log 10 x) * (10 : ℝ) ^ (Int.log 10 x) := by
    field_simp
  refine ⟨(x / (10 : ℝ) ^ (Int.log 10 x), Int.log 10 x), ⟨e1, e2, e3⟩, ?_⟩
  rintro ⟨a, m⟩ ⟨ha, ha', hxa⟩
  simp only at ha ha' hxa
  have hm : m = Int.log 10 x := by
    have k1 := key _ _ m _ ha ha' e1 e2 (hxa.symm.trans e3)
    have k2 := key _ _ _ m e1 e2 ha ha' (e3.symm.trans hxa)
    omega
  rw [hm] at hxa
  have : a = x / (10 : ℝ) ^ (Int.log 10 x) := by
    rw [eq_div_iff hk0.ne']
    exact hxa.symm
  rw [this, hm]

/-- Multiplying piles the tens up: multiply the front numbers and add the powers. Changing
kilometres to metres is the case of multiplying by 10^3, so the power 8 becomes 11. -/
theorem sci_mul_powers_add (a b : ℝ) (m n : ℤ) :
    (a * (10 : ℝ) ^ m) * (b * (10 : ℝ) ^ n) = (a * b) * (10 : ℝ) ^ (m + n) := by
  rw [zpow_add₀ (by norm_num)]
  ring

/-- Comparing is subtracting: to divide, divide the front numbers and subtract the powers. -/
theorem sci_div_powers_subtract (a b : ℝ) (m n : ℤ) :
    (a * (10 : ℝ) ^ m) / (b * (10 : ℝ) ^ n) = (a / b) * (10 : ℝ) ^ (m - n) := by
  rw [zpow_sub₀ (by norm_num)]
  field_simp

-- The Sun: 150,000,000 km is 1.5 x 10^8 km, with 1.5 written as 3/2.
example : (3 / 2 : ℝ) * (10 : ℝ) ^ (8 : ℤ) = 150000000 := by norm_num
-- 150,000,000 has seven zeros, but the power is 8: it sits from 10^8 up to 10^9.
example : (10 : ℕ) ^ 8 ≤ 150000000 ∧ 150000000 < (10 : ℕ) ^ 9 := by norm_num
-- One kilometre is 1000 m, which is 10^3 m; the powers add, 8 + 3 = 11.
example : (1000 : ℝ) = (10 : ℝ) ^ (3 : ℤ) := by norm_num
example : (8 : ℤ) + 3 = 11 := by norm_num
example : (3 / 2 : ℝ) * (10 : ℝ) ^ (11 : ℤ) = 150000000000 := by norm_num
-- The cell: 0.000007 m, seven millionths, is 7 x 10^-6 m.
example : (7 : ℝ) * (10 : ℝ) ^ (-6 : ℤ) = 7 / 1000000 := by norm_num
-- Comparing: 11 - (-6) = 17, and the Sun over the cell is (1.5 / 7) x 10^17, which is (15 / 7) x 10^16.
example : (11 : ℤ) - (-6) = 17 := by norm_num
example : (150000000000 : ℝ) / (7 / 1000000) = (3 / 2 / 7) * (10 : ℝ) ^ (17 : ℤ) := by norm_num
example : (3 / 2 / 7 : ℝ) * (10 : ℝ) ^ (17 : ℤ) = (15 / 7) * (10 : ℝ) ^ (16 : ℤ) := by norm_num
-- The front number 15/7 is from 1 up to 10, and is 2.142857 to six places after the dot.
example : (1 : ℝ) ≤ 15 / 7 ∧ (15 / 7 : ℝ) < 10 := by norm_num
example : (2142857 / 1000000 : ℝ) < 15 / 7 ∧ (15 / 7 : ℝ) < 2142858 / 1000000 := by norm_num
-- The mistakes: 7 x 10^-5 is 0.000070, ten times too wide; adding the powers gives 11 + (-6) = 5,
-- that is (1.5 / 7) x 10^5 = (15 / 7) x 10^4.
example : (7 : ℝ) * (10 : ℝ) ^ (-5 : ℤ) = 70 / 1000000 := by norm_num
example : (11 : ℤ) + (-6) = 5 := by norm_num
example : (3 / 2 / 7 : ℝ) * (10 : ℝ) ^ (5 : ℤ) = (15 / 7) * (10 : ℝ) ^ (4 : ℤ) := by norm_num

#print axioms scientific_notation_exists_unique
#print axioms sci_mul_powers_add
#print axioms sci_div_powers_subtract
