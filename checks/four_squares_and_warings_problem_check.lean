-- Four squares and beyond: every whole number is a sum of four squares, no number 4^e(8t + 7) is a sum of three squares, and the number 2^k ⌊(3/2)^k⌋ − 1 needs at least 2^k + ⌊(3/2)^k⌋ − 2 k-th powers.
import Mathlib.NumberTheory.SumFourSquares
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Data.Rat.Floor
import Mathlib.Data.Multiset.Basic
import Mathlib.NumberTheory.Divisors

/-- Squares leave remainder 0, 1 or 4 mod 8. -/
theorem sq_mod_eight (a : ℕ) : a ^ 2 % 8 = 0 ∨ a ^ 2 % 8 = 1 ∨ a ^ 2 % 8 = 4 := by
  have h : a % 8 < 8 := Nat.mod_lt _ (by norm_num)
  have : a ^ 2 % 8 = (a % 8) ^ 2 % 8 := by rw [Nat.pow_mod]
  rw [this]
  interval_cases (a % 8) <;> simp

#print axioms sq_mod_eight

/-- If three squares add to a multiple of 4, all three numbers are even. -/
theorem three_sq_mod_four_zero (a b c : ℕ) (h : (a ^ 2 + b ^ 2 + c ^ 2) % 4 = 0) :
    2 ∣ a ∧ 2 ∣ b ∧ 2 ∣ c := by
  have ha : a ^ 2 % 4 = (a % 4) ^ 2 % 4 := by rw [Nat.pow_mod]
  have hb : b ^ 2 % 4 = (b % 4) ^ 2 % 4 := by rw [Nat.pow_mod]
  have hc : c ^ 2 % 4 = (c % 4) ^ 2 % 4 := by rw [Nat.pow_mod]
  have h' : (a ^ 2 % 4 + b ^ 2 % 4 + c ^ 2 % 4) % 4 = 0 := by omega
  rw [ha, hb, hc] at h'
  have h1 : a % 4 < 4 := Nat.mod_lt _ (by norm_num)
  have h2 : b % 4 < 4 := Nat.mod_lt _ (by norm_num)
  have h3 : c % 4 < 4 := Nat.mod_lt _ (by norm_num)
  refine ⟨?_, ?_, ?_⟩ <;> rw [Nat.dvd_iff_mod_eq_zero] <;>
  · interval_cases ha4 : a % 4 <;> interval_cases hb4 : b % 4 <;> interval_cases hc4 : c % 4 <;>
      simp_all <;> omega

#print axioms three_sq_mod_four_zero

/-- Lagrange's four-square theorem: every whole number n from 0 up is the sum of the squares
of four whole numbers, zero allowed. -/
theorem every_nat_is_sum_of_four_squares (n : ℕ) :
    ∃ a b c d : ℕ, n = a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 := by
  obtain ⟨a, b, c, d, h⟩ := Nat.sum_four_squares n
  exact ⟨a, b, c, d, h.symm⟩

/-- The half of Legendre's three-square theorem proved on the card: a number of the form
4^e(8t + 7) is never the sum of three squares of whole numbers. -/
theorem not_sum_of_three_squares_of_four_pow_mul_eight_mul_add_seven (e t : ℕ) :
    ¬ ∃ a b c : ℕ, a ^ 2 + b ^ 2 + c ^ 2 = 4 ^ e * (8 * t + 7) := by
  induction e with
  | zero =>
    rintro ⟨a, b, c, h⟩
    have h8 : (a ^ 2 + b ^ 2 + c ^ 2) % 8 = 7 := by rw [h]; omega
    rcases sq_mod_eight a with ha | ha | ha <;> rcases sq_mod_eight b with hb | hb | hb <;>
      rcases sq_mod_eight c with hc | hc | hc <;> omega
  | succ e ih =>
    rintro ⟨a, b, c, h⟩
    have h4 : (a ^ 2 + b ^ 2 + c ^ 2) % 4 = 0 := by
      rw [h, pow_succ]; simp [Nat.mul_mod, Nat.mul_assoc, Nat.mul_comm 4]
    obtain ⟨⟨a', rfl⟩, ⟨b', rfl⟩, ⟨c', rfl⟩⟩ := three_sq_mod_four_zero a b c h4
    apply ih
    refine ⟨a', b', c', ?_⟩
    have : 4 * (a' ^ 2 + b' ^ 2 + c' ^ 2) = 4 * (4 ^ e * (8 * t + 7)) := by
      rw [show 4 * (4 ^ e * (8 * t + 7)) = 4 ^ (e + 1) * (8 * t + 7) by ring, ← h]; ring
    omega

/-- The lower bound for Waring's g(k): the number n = 2^k ⌊(3/2)^k⌋ − 1 cannot be written as a
sum of fewer than 2^k + ⌊(3/2)^k⌋ − 2 non-negative k-th powers. Any collection s of whole numbers
whose k-th powers add to n has at least that many members, so g(k) ≥ 2^k + ⌊(3/2)^k⌋ − 2. -/
theorem waring_lower_bound_witness (k : ℕ) (s : Multiset ℕ)
    (hs : (s.map (· ^ k)).sum = 2 ^ k * ⌊((3 : ℚ) / 2) ^ k⌋₊ - 1) :
    2 ^ k + ⌊((3 : ℚ) / 2) ^ k⌋₊ - 2 ≤ Multiset.card s := by
  rcases Nat.eq_zero_or_pos k with rfl | hk
  · simp
  set q := ⌊((3 : ℚ) / 2) ^ k⌋₊ with hq
  set n := (s.map (· ^ k)).sum with hn
  have hq1 : 1 ≤ q := Nat.le_floor (by push_cast; exact one_le_pow₀ (by norm_num))
  have hq3 : 2 ^ k * q ≤ 3 ^ k := by
    have h1 : (q : ℚ) ≤ ((3 : ℚ) / 2) ^ k := Nat.floor_le (by positivity)
    have h2 : ((2 ^ k * q : ℕ) : ℚ) ≤ ((3 ^ k : ℕ) : ℚ) := by
      push_cast
      calc (2 : ℚ) ^ k * q ≤ 2 ^ k * ((3 : ℚ) / 2) ^ k := by gcongr
        _ = 3 ^ k := by rw [← mul_pow]; norm_num
    exact_mod_cast h2
  have hP : 2 ≤ 2 ^ k := by
    calc 2 = 2 ^ 1 := by norm_num
      _ ≤ 2 ^ k := Nat.pow_le_pow_right (by norm_num) hk
  have hPq : 1 ≤ 2 ^ k * q := le_trans (by omega) (Nat.mul_le_mul hP hq1)
  have hn3 : n < 3 ^ k := by omega
  have hle2 : ∀ x ∈ s, x ≤ 2 := by
    intro x hx
    have : x ^ k ≤ n := Multiset.le_sum_of_mem (Multiset.mem_map_of_mem (fun x => x ^ k) hx)
    have : x ^ k < 3 ^ k := lt_of_le_of_lt this hn3
    have := (Nat.pow_lt_pow_iff_left (by omega)).mp this
    omega
  set a := (s.map (fun x => if x = 2 then 1 else 0)).sum with ha
  have hup : n ≤ Multiset.card s + (2 ^ k - 1) * a := by
    have : n ≤ (s.map (fun x => 1 + (2 ^ k - 1) * (if x = 2 then 1 else 0))).sum := by
      apply Multiset.sum_map_le_sum_map
      intro x hx
      have := hle2 x hx
      interval_cases x
      · rw [zero_pow (by omega)]; simp
      · simp
      · simp; omega
    rw [Multiset.sum_map_add, Multiset.map_const', Multiset.sum_replicate,
      Multiset.sum_map_mul_left] at this
    simpa [ha] using this
  have hlow : 2 ^ k * a ≤ n := by
    have : (s.map (fun x => 2 ^ k * (if x = 2 then 1 else 0))).sum ≤ n := by
      apply Multiset.sum_map_le_sum_map
      intro x hx
      split_ifs with h
      · subst h; simp
      · simp
    rw [Multiset.sum_map_mul_left] at this
    exact this
  have haq : a + 1 ≤ q := by
    have : 2 ^ k * a < 2 ^ k * q := by omega
    have := Nat.lt_of_mul_lt_mul_left this
    omega
  have hm : (2 ^ k - 1) * a ≤ (2 ^ k - 1) * (q - 1) := Nat.mul_le_mul_left _ (by omega)
  have hexp : (2 ^ k - 1) * (q - 1) + (2 ^ k + q - 2) = 2 ^ k * q - 1 := by
    obtain ⟨P, hP'⟩ : ∃ P, 2 ^ k = P + 2 := ⟨2 ^ k - 2, by omega⟩
    obtain ⟨r, hr⟩ : ∃ r, q = r + 1 := ⟨q - 1, by omega⟩
    rw [hP', hr, show P + 2 - 1 = P + 1 by omega, show r + 1 - 1 = r by omega,
      show P + 2 + (r + 1) - 2 = P + r + 1 by omega,
      show (P + 2) * (r + 1) = (P * r + P + 2 * r + 1) + 1 by ring, Nat.add_sub_cancel]
    ring
  omega

-- 7 = 4 + 1 + 1 + 1.
example : 2 ^ 2 + 1 ^ 2 + 1 ^ 2 + 1 ^ 2 = 7 := by norm_num

-- 7 is not three squares: only 0, 1 and 4 fit below 7.
example : ∀ a < 3, ∀ b < 3, ∀ c < 3, a ^ 2 + b ^ 2 + c ^ 2 ≠ 7 := by decide

-- Squares leave remainder 0, 1 or 4 mod 8.
example : ∀ a < 8, a ^ 2 % 8 = 0 ∨ a ^ 2 % 8 = 1 ∨ a ^ 2 % 8 = 4 := by decide

-- 7 and 28 are of the form 4^e(8t + 7).
example : (7 : ℕ) = 4 ^ 0 * (8 * 0 + 7) ∧ (28 : ℕ) = 4 ^ 1 * (8 * 0 + 7) := by norm_num

-- Euler's identity on 7 = 4 + 1 + 1 + 1 and 3 = 1 + 1 + 1 + 0: mixtures 4, 0, 2, −1 give 21.
example : ((2 : ℤ) ^ 2 + 1 ^ 2 + 1 ^ 2 + 1 ^ 2) * (1 ^ 2 + 1 ^ 2 + 1 ^ 2 + 0 ^ 2)
    = 4 ^ 2 + 0 ^ 2 + 2 ^ 2 + (-1) ^ 2 ∧ (4 : ℤ) ^ 2 + 0 ^ 2 + 2 ^ 2 + (-1) ^ 2 = 21 := by norm_num

-- Pigeonhole for p = 7: 4 + 9 + 1 + 0 = 14 = 2 × 7; halving gives (1, 1, 2, 1).
example : 2 ^ 2 + 3 ^ 2 + 1 ^ 2 + 0 ^ 2 = 2 * 7 ∧ 1 ^ 2 + 1 ^ 2 + 2 ^ 2 + 1 ^ 2 = 7 := by norm_num

-- Descent for p = 23: (2, 8, 1, 0) is 3 × 23, remainders (−1, −1, 1, 0) give 3, mixtures
-- (−9, 6, 3, 9) give 207 = 9 × 23, and dividing by 3 gives (−3, 2, 1, 3), which sums to 23.
example : (2 : ℤ) ^ 2 + 8 ^ 2 + 1 ^ 2 + 0 ^ 2 = 3 * 23 ∧ (-1 : ℤ) ^ 2 + (-1) ^ 2 + 1 ^ 2 + 0 ^ 2 = 3 * 1
    ∧ (-9 : ℤ) ^ 2 + 6 ^ 2 + 3 ^ 2 + 9 ^ 2 = 207 ∧ (207 : ℤ) = 9 * 23
    ∧ (-3 : ℤ) ^ 2 + 2 ^ 2 + 1 ^ 2 + 3 ^ 2 = 23 := by norm_num

-- Jacobi's formula at 7: 8 times the divisors of 7 not divisible by 4 gives 64.
example : 8 * ((Nat.divisors 7).filter (fun d => ¬ 4 ∣ d)).sum id = 64 := by decide

-- The lower-bound witnesses for k = 2 to 6: n = 7, 23, 79, 223, 703, and bounds 4, 9, 19, 37, 73.
example : [2, 3, 4, 5, 6].map (fun k => (2 ^ k * (3 ^ k / 2 ^ k) - 1, 2 ^ k + 3 ^ k / 2 ^ k - 2))
    = [(7, 4), (23, 9), (79, 19), (223, 37), (703, 73)] := by decide

-- 23 = 8 + 8 + 7 × 1, and with a negative cube allowed, 23 = 8 + 8 + 8 − 1.
example : 2 ^ 3 + 2 ^ 3 + 7 * 1 ^ 3 = 23 ∧ (2 : ℤ) ^ 3 + 2 ^ 3 + 2 ^ 3 + (-1) ^ 3 = 23 := by norm_num

-- Cubes leave remainder 0, 1 or 8 mod 9, and three of them never make 4 or 5 mod 9.
example : ∀ b < 9, b ^ 3 % 9 = 0 ∨ b ^ 3 % 9 = 1 ∨ b ^ 3 % 9 = 8 := by decide
example : ∀ x ∈ ({0, 1, 8} : Finset ℕ), ∀ y ∈ ({0, 1, 8} : Finset ℕ), ∀ z ∈ ({0, 1, 8} : Finset ℕ),
    (x + y + z) % 9 ≠ 4 ∧ (x + y + z) % 9 ≠ 5 := by decide

#print axioms every_nat_is_sum_of_four_squares
#print axioms not_sum_of_three_squares_of_four_pow_mul_eight_mul_add_seven
#print axioms waring_lower_bound_witness
