-- Roots: for a base of zero or more, the power with exponent 1/n is the one number of zero or more whose n-th power is the base, a positive base has exactly two square roots and a negative one none, every real number has exactly one cube root, and the card's bed and tank numbers come out exactly as it says.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

/-- A root is a power run backwards. For a base `a` of zero or more and a count `n` of
copies (1 or more), the power `a ^ (1/n)` is zero or more, its `n` copies multiply back to
`a`, and it is the only number of zero or more that does: the plus answer. With `n = 2`
this is the square root, with `n = 3` the cube root. -/
theorem root_is_power_run_backwards (a : ℝ) (ha : 0 ≤ a) (n : ℕ) (hn : 1 ≤ n) :
    0 ≤ a ^ ((1 : ℝ) / n) ∧ (a ^ ((1 : ℝ) / n)) ^ n = a ∧
      ∀ x : ℝ, 0 ≤ x → x ^ n = a → x = a ^ ((1 : ℝ) / n) := by
  have hn0 : n ≠ 0 := by omega
  have hinv : ((1 : ℝ) / n) = (n : ℝ)⁻¹ := one_div _
  rw [hinv]
  refine ⟨Real.rpow_nonneg ha _, ?_, ?_⟩
  · exact Real.rpow_inv_natCast_pow ha hn0
  · intro x hx hxa
    rw [← hxa]
    exact (Real.pow_rpow_inv_natCast hx hn0).symm

/-- The minus twin, and no root for a minus. For a base `a` of zero or more, the numbers
that times themselves give `a` are exactly `a ^ (1/2)` and its negative. For a negative base,
no number times itself gives it. -/
theorem square_root_has_minus_twin (a : ℝ) :
    (0 ≤ a → ∀ x : ℝ, x * x = a ↔ x = a ^ ((1 : ℝ) / 2) ∨ x = -a ^ ((1 : ℝ) / 2)) ∧
      (a < 0 → ∀ x : ℝ, x * x ≠ a) := by
  have key : ∀ b : ℝ, 0 ≤ b → b ^ ((1 : ℝ) / 2) * b ^ ((1 : ℝ) / 2) = b := by
    intro b hb
    rw [← Real.sqrt_eq_rpow]
    exact Real.mul_self_sqrt hb
  refine ⟨fun ha x => ?_, fun ha x hx => ?_⟩
  · constructor
    · intro h
      have h2 := key a ha
      have : (x - a ^ ((1 : ℝ) / 2)) * (x + a ^ ((1 : ℝ) / 2)) = 0 := by nlinarith
      rcases mul_eq_zero.mp this with h3 | h3
      · left; linarith
      · right; linarith
    · rintro (h | h)
      · rw [h]; exact key a ha
      · rw [h]; have := key a ha; nlinarith
  · nlinarith [mul_self_nonneg x]

/-- A cube keeps the sign of its side, so every number, plus or minus, has exactly one
cube root: exactly one number whose three copies multiply to it. -/
theorem every_number_has_one_cube_root (a : ℝ) : ∃! x : ℝ, x * x * x = a := by
  have inj : ∀ x y : ℝ, x * x * x = y * y * y → x = y := by
    intro x y h
    have h1 : x ^ 3 = y ^ 3 := by nlinarith
    exact (Odd.strictMono_pow (by decide : Odd 3)).injective h1
  have ex0 : ∀ b : ℝ, 0 ≤ b → ∃ x : ℝ, x * x * x = b := by
    intro b hb
    refine ⟨b ^ (((3 : ℕ) : ℝ)⁻¹), ?_⟩
    have := Real.rpow_inv_natCast_pow hb (n := 3) (by norm_num)
    calc b ^ (((3 : ℕ) : ℝ)⁻¹) * b ^ (((3 : ℕ) : ℝ)⁻¹) * b ^ (((3 : ℕ) : ℝ)⁻¹)
        = (b ^ (((3 : ℕ) : ℝ)⁻¹)) ^ 3 := by ring
      _ = b := this
  have ex : ∃ x : ℝ, x * x * x = a := by
    rcases le_or_gt 0 a with h | h
    · exact ex0 a h
    · obtain ⟨x, hx⟩ := ex0 (-a) (by linarith)
      exact ⟨-x, by nlinarith⟩
  obtain ⟨x, hx⟩ := ex
  exact ⟨x, hx, fun y hy => inj y x (by rw [hy, hx])⟩

-- The picture: squares of sides 4 to 8 metres, and 50 falls between 7 and 8 metres a side.
example : ((4 : ℕ) * 4, 5 * 5, 6 * 6, 7 * 7, 8 * 8) = (16, 25, 36, 49, 64) := by decide
example : 7 * 7 < 50 ∧ 50 < 8 * 8 := by decide
-- Divide and average, from the guess 7, in exact fractions: 7.071428571429 and 7.071067821068.
example : ((7 : ℚ) + 50 / 7) / 2 = 99 / 14 := by norm_num
example : ((99 / 14 : ℚ) + 50 / (99 / 14)) / 2 = 19601 / 2772 := by norm_num
-- Round two squares to just over 50.
example : (19601 / 2772 : ℚ) * (19601 / 2772) = 50 + 1 / (2772 * 2772) := by norm_num
-- The tank: 8,000 litres is 8 cubic metres; 20 litre cubes to an edge is 2 metres.
example : (8000 : ℚ) / 1000 = 8 := by norm_num
example : 20 * 20 * 20 = 8000 := by decide
example : (20 : ℚ) / 10 = 2 := by norm_num
example : 2 * 2 * 2 = 8 := by decide
-- The tank side as a root, and one face as 8 to the 2/3.
example : (8 : ℝ) ^ ((1 : ℝ) / 3) = 2 := by
  have h : (8 : ℝ) = 2 ^ 3 := by norm_num
  rw [h, show ((1 : ℝ) / 3) = ((3 : ℕ) : ℝ)⁻¹ by norm_num]
  exact Real.pow_rpow_inv_natCast (by norm_num) (by norm_num)
example : (8 : ℝ) ^ ((2 : ℝ) / 3) = 4 := by
  have h : (8 : ℝ) = 2 ^ (3 : ℕ) := by norm_num
  have h1 : (8 : ℝ) ^ ((1 : ℝ) / 3) = 2 := by
    rw [h, show ((1 : ℝ) / 3) = ((3 : ℕ) : ℝ)⁻¹ by norm_num]
    exact Real.pow_rpow_inv_natCast (by norm_num) (by norm_num)
  have h2 : (8 : ℝ) ^ ((2 : ℝ) / 3) = (8 : ℝ) ^ ((1 : ℝ) / 3 * 2) := by norm_num
  rw [h2, Real.rpow_mul (by norm_num), h1]
  norm_num
example : 2 * 2 = 4 := by decide
-- The mistakes: halving 50 gives a 25-metre bed covering 625; 8,000 read as cubic metres gives 20.
example : (50 : ℚ) / 2 = 25 ∧ (25 : ℚ) * 25 = 625 := by norm_num
-- A bed of 49: the first guess 7 is exact, and the minus twin squares to the same.
example : (7 : ℤ) * 7 = 49 ∧ (-7 : ℤ) * (-7) = 49 := by decide

#print axioms root_is_power_run_backwards
#print axioms square_root_has_minus_twin
#print axioms every_number_has_one_cube_root
