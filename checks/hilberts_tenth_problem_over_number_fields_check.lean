-- Hilbert's tenth problem beyond the integers: four squares pick out the integers 0 or more inside ℤ, the same test lets the non-integer 3 + 2√2 through in ℤ[√2], the integers of ℤ[√2] are exactly the elements the swap √2 ↦ −√2 leaves alone, and the card's small worked numbers check exactly.
import Mathlib.NumberTheory.SumFourSquares
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Data.Int.Interval
import Mathlib.Data.Rat.Defs

/-- Lagrange's theorem as a Diophantine definition: an integer t is zero or more
exactly when it is a sum of four integer squares. -/
theorem nonneg_iff_sum_four_squares (t : ℤ) :
    0 ≤ t ↔ ∃ a b c d : ℤ, t = a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 := by
  constructor
  · intro ht
    obtain ⟨a, b, c, d, h⟩ := Nat.sum_four_squares t.toNat
    refine ⟨a, b, c, d, ?_⟩
    have h' : ((a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 : ℕ) : ℤ) = (t.toNat : ℤ) := by rw [h]
    push_cast at h'
    rw [h', Int.toNat_of_nonneg ht]
  · rintro ⟨a, b, c, d, rfl⟩
    positivity

/-- In ℤ[√2] the four-square test no longer picks out integers: 3 + 2√2 is a sum
of four squares there (it is (1 + √2)²), but it is not an ordinary integer. -/
theorem four_squares_pass_non_integer_in_zsqrt2 :
    (∃ a b c d : ℤ√2, (⟨3, 2⟩ : ℤ√2) = a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2) ∧
      ∀ n : ℤ, (⟨3, 2⟩ : ℤ√2) ≠ (n : ℤ√2) := by
  refine ⟨⟨⟨1, 1⟩, 0, 0, 0, ?_⟩, ?_⟩
  · ext <;> simp [sq, Zsqrtd.re_mul, Zsqrtd.im_mul]
  · intro n h
    have := congrArg Zsqrtd.im h
    simp at this

/-- The ordinary integers inside ℤ[√2] are exactly the elements that the swap σ,
sending √2 to −√2, leaves alone. -/
theorem swap_fixed_iff_integer (x : ℤ√2) : star x = x ↔ ∃ n : ℤ, x = (n : ℤ√2) := by
  constructor
  · intro h
    refine ⟨x.re, ?_⟩
    have := congrArg Zsqrtd.im h
    simp at this
    ext <;> simp
    omega
  · rintro ⟨n, rfl⟩
    ext <;> simp

-- Seven is a sum of four squares, 7 = 4 + 1 + 1 + 1, and no three squares make 7.
example : (7 : ℤ) = 2 ^ 2 + 1 ^ 2 + 1 ^ 2 + 1 ^ 2 := by norm_num
example : ¬ ∃ a b c : ℤ, a ^ 2 + b ^ 2 + c ^ 2 = 7 := by
  rintro ⟨a, b, c, h⟩
  have ha1 : a ≤ 2 := by nlinarith [sq_nonneg b, sq_nonneg c, sq_nonneg (a - 3)]
  have ha2 : -2 ≤ a := by nlinarith [sq_nonneg b, sq_nonneg c, sq_nonneg (a + 3)]
  have hb1 : b ≤ 2 := by nlinarith [sq_nonneg a, sq_nonneg c, sq_nonneg (b - 3)]
  have hb2 : -2 ≤ b := by nlinarith [sq_nonneg a, sq_nonneg c, sq_nonneg (b + 3)]
  have hc1 : c ≤ 2 := by nlinarith [sq_nonneg b, sq_nonneg a, sq_nonneg (c - 3)]
  have hc2 : -2 ≤ c := by nlinarith [sq_nonneg b, sq_nonneg a, sq_nonneg (c + 3)]
  interval_cases a <;> interval_cases b <;> interval_cases c <;> omega

-- Seven has 64 signed, ordered ways as four squares (every entry lies in −2..2).
example : ((Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2 ×ˢ
    Finset.Icc (-2 : ℤ) 2).filter
      (fun p => p.1 ^ 2 + p.2.1 ^ 2 + p.2.2.1 ^ 2 + p.2.2.2 ^ 2 = 7)).card = 64 := by decide +kernel

-- Up to 60, the numbers that are not a sum of three squares (roots 0..7 suffice, as 8² > 60).
example : (List.range 61).filter (fun n => ∀ a ∈ List.range 8, ∀ b ∈ List.range 8,
    ∀ c ∈ List.range 8, a ^ 2 + b ^ 2 + c ^ 2 ≠ n) = [7, 15, 23, 28, 31, 39, 47, 55, 60] := by
  decide +kernel

-- (1 + √2)² = 3 + 2√2 in ℤ[√2], and its norm 3² − 2 × 2² is 1.
example : ((⟨1, 1⟩ : ℤ√2)) ^ 2 = ⟨3, 2⟩ := by
  ext <;> simp [sq, Zsqrtd.re_mul, Zsqrtd.im_mul]
example : Zsqrtd.norm (⟨3, 2⟩ : ℤ√2) = 1 := by simp [Zsqrtd.norm_def]

-- P = (−4, 6) lies on E5: y² = x³ − 25x.
example : (6 : ℤ) ^ 2 = (-4) ^ 3 - 25 * (-4) := by norm_num

-- The tangent at P has slope 23/12, and 2P = (1681/144, −62279/1728), not whole.
example : ((3 * (-4) ^ 2 - 25) / (2 * 6) : ℚ) = 23 / 12 := by norm_num
example : ((23 / 12) ^ 2 - 2 * (-4) : ℚ) = 1681 / 144 := by norm_num
example : ((23 / 12) * (-4 - 1681 / 144) - 6 : ℚ) = -62279 / 1728 := by norm_num
example : ((1681 : ℚ) / 144).den = 144 := by decide +kernel

-- Denominators of kP: d_2 = 12 divides d_4 = 1494696, and d_3 = 2257 does not.
example : (12 : ℕ) ∣ 1494696 ∧ ¬ (2257 : ℕ) ∣ 1494696 := by decide

-- Tunnell's counts for E10 (n/2 = 5): A counts x² + 4y² + 8z² = 5, B counts x² + 4y² + 32z² = 5.
example : ((Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2).filter
    (fun p => p.1 ^ 2 + 4 * p.2.1 ^ 2 + 8 * p.2.2 ^ 2 = 5)).card = 4 := by decide +kernel
example : ((Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2 ×ˢ Finset.Icc (-2 : ℤ) 2).filter
    (fun p => p.1 ^ 2 + 4 * p.2.1 ^ 2 + 32 * p.2.2 ^ 2 = 5)).card = 4 := by decide +kernel

-- Tunnell's counts for E3 (odd n = 3): A counts x² + 2y² + 8z² = 3, B counts x² + 2y² + 32z² = 3.
example : ((Finset.Icc (-1 : ℤ) 1 ×ˢ Finset.Icc (-1 : ℤ) 1 ×ˢ Finset.Icc (-1 : ℤ) 1).filter
    (fun p => p.1 ^ 2 + 2 * p.2.1 ^ 2 + 8 * p.2.2 ^ 2 = 3)).card = 4 := by decide +kernel
example : ((Finset.Icc (-1 : ℤ) 1 ×ˢ Finset.Icc (-1 : ℤ) 1 ×ˢ Finset.Icc (-1 : ℤ) 1).filter
    (fun p => p.1 ^ 2 + 2 * p.2.1 ^ 2 + 32 * p.2.2 ^ 2 = 3)).card = 4 := by decide +kernel

-- What breaks: E3: y² = x³ − 9x gains (−3/2, (9/4)√2) over ℚ(√2); both sides are 81/8.
example : ((9 / 4 : ℝ) * Real.sqrt 2) ^ 2 = (-3 / 2 : ℝ) ^ 3 - 9 * (-3 / 2) := by
  rw [mul_pow, Real.sq_sqrt (by norm_num)]; norm_num
example : ((-3 / 2 : ℚ)) ^ 3 - 9 * (-3 / 2) = 81 / 8 := by norm_num

-- The twist E6: y² = x³ − 36x has (−3, 9), and 2(−3, 9) has x = 25/4, not whole.
example : (9 : ℤ) ^ 2 = (-3) ^ 3 - 36 * (-3) := by norm_num
example : (((3 * (-3) ^ 2 - 36) / (2 * 9)) ^ 2 - 2 * (-3) : ℚ) = 25 / 4 := by norm_num

#print axioms nonneg_iff_sum_four_squares
#print axioms four_squares_pass_non_integer_in_zsqrt2
#print axioms swap_fixed_iff_integer
