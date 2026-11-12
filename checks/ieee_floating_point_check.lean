-- IEEE 754: a real number inside the range of doubles, rounded to a nearest double, moves by at most half an ulp, so by a relative 2^-53 in the normal range, and with subnormals the computed difference of two different doubles is never zero.
import Mathlib.Data.Int.Log
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic

namespace IEEEFloatingPoint

/-- The value of the bit pattern with sign bit `s`, exponent field `e` and fraction field `f`,
as the card's formula reads it: `(-1)^s × (1 + f/2^52) × 2^(e - 1023)` for a normal pattern
(`1 ≤ e ≤ 2046`), and `(-1)^s × (f/2^52) × 2^(-1022)` when `e = 0` (zero or subnormal). -/
noncomputable def doubleValue (s e f : ℕ) : ℝ :=
  if e = 0 then (-1 : ℝ) ^ s * ((f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ (-1022 : ℤ)
  else (-1 : ℝ) ^ s * (1 + (f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ ((e : ℤ) - 1023)

/-- `y` is a finite double: the value of some sign bit, an exponent field from 0 to 2046 and a
52-bit fraction field. (Field 2047 holds infinity and NaN, which are not real numbers.) -/
def IsFiniteDouble (y : ℝ) : Prop :=
  ∃ s e f : ℕ, s ≤ 1 ∧ e ≤ 2046 ∧ f < 2 ^ 52 ∧ y = doubleValue s e f

/-- The largest double, `(2^53 - 1) × 2^971`, about 1.7976931348623157e308. -/
noncomputable def largestDouble : ℝ := (2 ^ 53 - 1) * (2 : ℝ) ^ (971 : ℤ)

/-- The unit in the last place: `ulp(x) = 2^(max(E, -1022) - 52)`, where `E` is the power of
two with `2^E ≤ |x| < 2^(E+1)`. -/
noncomputable def ulp (x : ℝ) : ℝ := (2 : ℝ) ^ (max (Int.log 2 |x|) (-1022) - 52)

/-- `xhat` is a nearest double to `x`: a finite double no further from `x` than any other.
Round to nearest returns one of these (ties to even only chooses which one at a tie). -/
def IsNearestDouble (xhat x : ℝ) : Prop :=
  IsFiniteDouble xhat ∧ ∀ d : ℝ, IsFiniteDouble d → |xhat - x| ≤ |d - x|

/-- A whole number `m` below `2^53` times `2^(E-52)` is a double, when the exponent `E` is in
range and either `m` has its top bit set (normal) or `E = -1022` (subnormal). -/
lemma isFiniteDouble_of_sig (s : ℕ) (hs : s ≤ 1) (E : ℤ) (hE1 : -1022 ≤ E) (hE2 : E ≤ 1023)
    (m : ℕ) (hm : m < 2 ^ 53) (hcase : 2 ^ 52 ≤ m ∨ E = -1022) :
    IsFiniteDouble ((-1 : ℝ) ^ s * (m : ℝ) * (2 : ℝ) ^ (E - 52)) := by
  by_cases h52 : 2 ^ 52 ≤ m
  · refine ⟨s, (E + 1023).toNat, m - 2 ^ 52, hs, by omega, by omega, ?_⟩
    have hne : (E + 1023).toNat ≠ 0 := by omega
    have hcast : (((E + 1023).toNat : ℕ) : ℤ) - 1023 = E := by omega
    simp only [doubleValue, hne, ↓reduceIte, hcast]
    rw [Nat.cast_sub h52, zpow_sub₀ (by norm_num : (2 : ℝ) ≠ 0)]
    push_cast
    field_simp
    ring
  · have hE : E = -1022 := hcase.resolve_left h52
    subst hE
    refine ⟨s, 0, m, hs, by norm_num, by omega, ?_⟩
    simp only [doubleValue, ↓reduceIte]
    rw [zpow_sub₀ (by norm_num : (2 : ℝ) ≠ 0)]
    field_simp

/-- Every double is a whole number of the smallest subnormal `2^(-1074)`. -/
lemma isFiniteDouble_int_mul {y : ℝ} (hy : IsFiniteDouble y) :
    ∃ k : ℤ, y = (k : ℝ) * (2 : ℝ) ^ (-1074 : ℤ) := by
  obtain ⟨s, e, f, -, -, -, rfl⟩ := hy
  by_cases he : e = 0
  · refine ⟨(-1) ^ s * f, ?_⟩
    simp only [doubleValue, he, ↓reduceIte]
    rw [show (-1074 : ℤ) = -1022 - 52 by norm_num, zpow_sub₀ (by norm_num : (2 : ℝ) ≠ 0)]
    push_cast
    field_simp
  · refine ⟨(-1) ^ s * (2 ^ 52 + f) * 2 ^ (e - 1), ?_⟩
    simp only [doubleValue, he, ↓reduceIte]
    have h : (2 : ℝ) ^ ((e : ℤ) - 1023) = (2 : ℝ) ^ (e - 1) * 2 ^ 52 * (2 : ℝ) ^ (-1074 : ℤ) := by
      rw [← zpow_natCast, ← zpow_natCast, ← zpow_add₀ (by norm_num), ← zpow_add₀ (by norm_num)]
      congr 1
      push_cast [Nat.cast_sub (Nat.one_le_iff_ne_zero.mpr he)]
      ring
    rw [h]
    push_cast
    field_simp
    norm_num


#print axioms isFiniteDouble_of_sig
#print axioms isFiniteDouble_int_mul

/-- Round to nearest costs at most half a gap: for a real number `x` inside the range of the
doubles, the stored double `x̂` picked by rounding to nearest satisfies
`|x̂ - x| ≤ ulp(x) / 2`. -/
theorem round_to_nearest_error_le_half_ulp (x xhat : ℝ) (hx : |x| ≤ largestDouble)
    (hxhat : IsNearestDouble xhat x) : |xhat - x| ≤ ulp x / 2 := by
  obtain ⟨-, hmin⟩ := hxhat
  suffices h : ∃ d, IsFiniteDouble d ∧ |d - x| ≤ ulp x / 2 by
    obtain ⟨d, hd, hdx⟩ := h
    exact (hmin d hd).trans hdx
  by_cases hx0 : x = 0
  · refine ⟨0, ⟨0, 0, 0, by norm_num, by norm_num, by norm_num, by simp [doubleValue]⟩, ?_⟩
    simp only [hx0, sub_zero, abs_zero, ulp]
    positivity
  have hapos : 0 < |x| := abs_pos.mpr hx0
  set a := |x| with ha
  set E := max (Int.log 2 a) (-1022) with hE
  set q := (2 : ℝ) ^ (E - 52) with hq
  have hulp : ulp x = q := rfl
  have hqpos : 0 < q := zpow_pos (by norm_num) _
  have hE1 : -1022 ≤ E := le_max_right _ _
  have hlt : a < (2 : ℝ) ^ (E + 1) := by
    have h1 := Int.lt_zpow_succ_log_self (b := 2) (by norm_num) a
    push_cast at h1
    calc a < (2 : ℝ) ^ (Int.log 2 a + 1) := h1
      _ ≤ (2 : ℝ) ^ (E + 1) :=
        zpow_le_zpow_right₀ (by norm_num) (by have := le_max_left (Int.log 2 a) (-1022); omega)
  have hL : largestDouble < (2 : ℝ) ^ (1024 : ℤ) := by
    unfold largestDouble
    rw [show (1024 : ℤ) = 53 + 971 by norm_num, zpow_add₀ (by norm_num)]
    have : (0 : ℝ) < 2 ^ (971 : ℤ) := zpow_pos (by norm_num) _
    norm_num
  have hlog_le : Int.log 2 a ≤ 1023 := by
    have h1 : a < ((2 : ℕ) : ℝ) ^ (1024 : ℤ) := by push_cast; linarith
    have := (Int.lt_zpow_iff_log_lt (by norm_num) hapos).mp h1
    omega
  have hE2 : E ≤ 1023 := max_le hlog_le (by norm_num)
  have hq53 : (2 : ℝ) ^ (E + 1) = 2 ^ 53 * q := by
    rw [hq, ← zpow_natCast, ← zpow_add₀ (by norm_num)]
    congr 1
    push_cast
    ring
  set r := a / q with hr
  have hr0 : 0 ≤ r := div_nonneg hapos.le hqpos.le
  have hr53 : r < 2 ^ 53 := by
    rw [hr, div_lt_iff₀ hqpos, ← hq53]
    exact hlt
  set n := round r with hn
  have hn1 : |r - n| ≤ 1 / 2 := abs_sub_round r
  have hn0 : 0 ≤ n := by
    have h1 := sub_half_lt_round r
    have h2 : (-1 : ℝ) < n := by linarith
    have h3 : (-1 : ℤ) < n := by exact_mod_cast h2
    omega
  have hn53 : n ≤ 2 ^ 53 := by
    have h1 := round_le_add_half r
    have h2 : (n : ℝ) < 2 ^ 53 + 1 := by linarith
    have h3 : n < 2 ^ 53 + 1 := by exact_mod_cast h2
    omega
  have hdist : |(n : ℝ) * q - a| ≤ q / 2 := by
    have h1 : (n : ℝ) * q - a = -(q * (r - n)) := by
      rw [hr]; field_simp; ring
    rw [h1, abs_neg, abs_mul, abs_of_pos hqpos]
    nlinarith
  -- the nearby double, before its sign
  obtain ⟨m, E', hE'1, hE'2, hm, hcase, hval⟩ : ∃ (m : ℕ) (E' : ℤ), -1022 ≤ E' ∧ E' ≤ 1023 ∧
      m < 2 ^ 53 ∧ (2 ^ 52 ≤ m ∨ E' = -1022) ∧ (m : ℝ) * (2 : ℝ) ^ (E' - 52) = n * q := by
    by_cases hbig : n = 2 ^ 53
    · refine ⟨2 ^ 52, E + 1, by omega, ?_, by norm_num, Or.inl le_rfl, ?_⟩
      · by_contra hc
        have hE3 : E = 1023 := by omega
        have hq' : q = (2 : ℝ) ^ (971 : ℤ) := by rw [hq, hE3]; norm_num
        have h1 : r ≤ 2 ^ 53 - 1 := by
          rw [hr, div_le_iff₀ hqpos, hq']
          have : a ≤ largestDouble := hx
          unfold largestDouble at this
          linarith
        have h2 := round_le_add_half r
        rw [← hn, hbig] at h2
        push_cast at h2
        linarith
      · rw [hbig, hq, show E + 1 - 52 = (E - 52) + 1 by ring, zpow_add_one₀ (by norm_num)]
        push_cast
        ring
    · refine ⟨n.toNat, E, hE1, hE2, by omega, ?_, ?_⟩
      · by_cases hEeq : E = -1022
        · exact Or.inr hEeq
        left
        have hElog : E = Int.log 2 a := by
          rcases max_choice (Int.log 2 a) (-1022) with h | h
          · rw [hE, h]
          · exact absurd (hE.trans h) hEeq
        have hpow : (2 : ℝ) ^ E ≤ a := by
          have := Int.zpow_log_le_self (b := 2) (by norm_num) hapos
          push_cast at this
          rw [hElog]; exact this
        have h52 : (2 : ℝ) ^ 52 ≤ r := by
          rw [hr, le_div_iff₀ hqpos]
          calc (2 : ℝ) ^ 52 * q = 2 ^ E := by
                rw [hq, ← zpow_natCast, ← zpow_add₀ (by norm_num)]
                congr 1
                push_cast
                ring
            _ ≤ a := hpow
        have h1 := sub_half_lt_round r
        have h2 : (2 : ℝ) ^ 52 - 1 < n := by linarith
        have h3 : (2 : ℤ) ^ 52 - 1 < n := by exact_mod_cast h2
        omega
      · have : ((n.toNat : ℕ) : ℝ) = (n : ℝ) := by exact_mod_cast Int.toNat_of_nonneg hn0
        rw [this]
  -- now the sign
  by_cases hxs : 0 ≤ x
  · refine ⟨(-1 : ℝ) ^ 0 * (m : ℝ) * (2 : ℝ) ^ (E' - 52),
      isFiniteDouble_of_sig 0 (by norm_num) E' hE'1 hE'2 m hm hcase, ?_⟩
    rw [pow_zero, one_mul, hval, hulp]
    have : a = x := abs_of_nonneg hxs
    rw [← this]
    exact hdist
  · refine ⟨(-1 : ℝ) ^ 1 * (m : ℝ) * (2 : ℝ) ^ (E' - 52),
      isFiniteDouble_of_sig 1 le_rfl E' hE'1 hE'2 m hm hcase, ?_⟩
    rw [pow_one, mul_assoc, hval, hulp]
    have : a = -x := abs_of_neg (lt_of_not_ge hxs)
    rw [show -1 * ((n : ℝ) * q) - x = -((n : ℝ) * q - a) by rw [this]; ring, abs_neg]
    exact hdist

/-- In the normal range, `2^(-1022) ≤ |x| ≤` the largest double, rounding to nearest has
relative error at most the unit roundoff: `|x̂ - x| / |x| ≤ u = 2^(-53)`. -/
theorem relative_error_le_unit_roundoff (x xhat : ℝ)
    (hlo : (2 : ℝ) ^ (-1022 : ℤ) ≤ |x|) (hhi : |x| ≤ largestDouble)
    (hxhat : IsNearestDouble xhat x) : |xhat - x| / |x| ≤ (2 : ℝ) ^ (-53 : ℤ) := by
  have h1 := round_to_nearest_error_le_half_ulp x xhat hhi hxhat
  have hapos : 0 < |x| := lt_of_lt_of_le (zpow_pos (by norm_num) _) hlo
  have hlog : -1022 ≤ Int.log 2 |x| :=
    (Int.zpow_le_iff_le_log (b := 2) (by norm_num) hapos).mp (by push_cast; exact hlo)
  have hpow : (2 : ℝ) ^ (Int.log 2 |x|) ≤ |x| := by
    have := Int.zpow_log_le_self (b := 2) (by norm_num) hapos
    push_cast at this
    exact this
  rw [div_le_iff₀ hapos]
  calc |xhat - x| ≤ ulp x / 2 := h1
    _ = (2 : ℝ) ^ (-53 : ℤ) * (2 : ℝ) ^ (Int.log 2 |x|) := by
        rw [ulp, max_eq_left hlog, ← zpow_add₀ (by norm_num),
          show -53 + Int.log 2 |x| = (Int.log 2 |x| - 52) - 1 by ring,
          zpow_sub_one₀ (by norm_num)]
        ring
    _ ≤ (2 : ℝ) ^ (-53 : ℤ) * |x| :=
        mul_le_mul_of_nonneg_left hpow (zpow_pos (by norm_num) _).le

/-- Gradual underflow: with subnormals, `x - y` computes to zero only when `x = y`. For two
different doubles, the double that rounding to nearest gives for their exact difference is
never zero. -/
theorem sub_rounds_to_zero_only_if_eq (x y z : ℝ) (hx : IsFiniteDouble x)
    (hy : IsFiniteDouble y) (hne : x ≠ y) (hz : IsNearestDouble z (x - y)) : z ≠ 0 := by
  intro hz0
  obtain ⟨a, rfl⟩ := isFiniteDouble_int_mul hx
  obtain ⟨b, rfl⟩ := isFiniteDouble_int_mul hy
  set u := (2 : ℝ) ^ (-1074 : ℤ) with hu
  have hupos : 0 < u := zpow_pos (by norm_num) _
  have hab : a ≠ b := by
    intro h; exact hne (by rw [h])
  have key : ∀ s : ℕ, s ≤ 1 → |((a - b : ℤ) : ℝ)| ≤ |(-1 : ℝ) ^ s - ((a - b : ℤ) : ℝ)| := by
    intro s hs
    have hd : IsFiniteDouble ((-1 : ℝ) ^ s * u) := by
      refine ⟨s, 0, 1, hs, by norm_num, by norm_num, ?_⟩
      simp only [doubleValue, ↓reduceIte, hu]
      rw [show (-1074 : ℤ) = -1022 - 52 by norm_num, zpow_sub₀ (by norm_num : (2 : ℝ) ≠ 0)]
      push_cast
      field_simp
    have h1 := hz.2 _ hd
    rw [hz0] at h1
    have e1 : (0 : ℝ) - ((a : ℝ) * u - (b : ℝ) * u) = -(((a - b : ℤ) : ℝ) * u) := by push_cast; ring
    have e2 : (-1 : ℝ) ^ s * u - ((a : ℝ) * u - (b : ℝ) * u)
        = ((-1 : ℝ) ^ s - ((a - b : ℤ) : ℝ)) * u := by push_cast; ring
    rw [e1, e2, abs_neg, abs_mul, abs_mul, abs_of_pos hupos] at h1
    exact le_of_mul_le_mul_right h1 hupos
  rcases lt_or_gt_of_ne (sub_ne_zero.mpr hab) with hk | hk
  · have h := key 1 le_rfl
    have h' : |a - b| ≤ |-1 - (a - b)| := by exact_mod_cast h
    rw [abs_of_neg hk] at h'
    rw [abs_of_nonneg (by omega)] at h'
    omega
  · have h := key 0 (by norm_num)
    have h' : |a - b| ≤ |1 - (a - b)| := by exact_mod_cast h
    rw [abs_of_pos hk] at h'
    rw [abs_of_nonpos (by omega)] at h'
    omega

-- The card's whole-number worked examples.

-- 0.1 + 0.2: exponent field 01111111101 is 1021, so E = 1021 - 1023 = -2.
example : 0b01111111101 = 1021 ∧ (1021 : ℤ) - 1023 = -2 := by decide
-- Putting the hidden bit back: 2^52 + 900719925474100 = 5404319552844596.
example : 2 ^ 52 + 900719925474100 = 5404319552844596 := by norm_num
-- The fields of 0.1 + 0.2 decode to 5404319552844596 / 2^54.
example : doubleValue 0 1021 900719925474100 = 5404319552844596 / 2 ^ 54 := by
  norm_num [doubleValue]
-- The stored 0.3 has the same exponent and fraction field one less, one gap below.
example : doubleValue 0 1021 900719925474100 - doubleValue 0 1021 900719925474099
    = (2 : ℝ) ^ (-54 : ℤ) := by
  norm_num [doubleValue]
-- One tenth times 2^56 falls between 7205759403792793 and 7205759403792794,
-- 0.6 of a gap above the lower one (2^56 - 10 × 7205759403792793 = 6).
example : 10 * 7205759403792793 < 2 ^ 56 ∧ 2 ^ 56 < 10 * 7205759403792794 ∧
    2 ^ 56 - 10 * 7205759403792793 = 6 := by norm_num
-- The stored 0.1 and 0.2, over 2^56, add to 21617278211378382; its last 2 bits are 2 of 4: a tie.
example : 7205759403792794 + 2 * 7205759403792794 = 21617278211378382 ∧
    21617278211378382 % 4 = 2 := by norm_num
-- The tie lies between 5404319552844595 and 5404319552844596; ties to even picks the even one,
-- the stored 0.1 + 0.2.
example : 21617278211378382 = 4 * 5404319552844595 + 2 ∧ 5404319552844596 % 2 = 0 := by norm_num
-- 2^53 + 1 is halfway between 2^53 and 2^53 + 2; the even significand is 2^53 = 9007199254740992.
example : 2 ^ 53 = 9007199254740992 ∧ (2 ^ 53 + 1) - 2 ^ 53 = (2 ^ 53 + 2) - (2 ^ 53 + 1) := by
  norm_num
-- 0.1 × 2^-1060 keeps fraction field 1638, a number with 11 bits.
example : 2 ^ 10 ≤ 1638 ∧ 1638 < 2 ^ 11 := by norm_num
-- The largest double is exponent field 2046 with every fraction bit set.
example : doubleValue 0 2046 (2 ^ 52 - 1) = largestDouble := by
  have h : (2 : ℝ) ^ ((2046 : ℕ) - 1023 : ℤ) = 2 ^ (52 : ℤ) * 2 ^ (971 : ℤ) := by
    rw [← zpow_add₀ (by norm_num)]; norm_num
  simp only [doubleValue, largestDouble, h]
  norm_num
  field_simp
-- 1.5 × 2^-1022 - 2^-1022 = 2^-1023, which is the subnormal with fraction field 2^51.
example : doubleValue 0 1 (2 ^ 51) - doubleValue 0 1 0 = doubleValue 0 0 (2 ^ 51) := by
  simp only [doubleValue]
  norm_num
  ring

#print axioms round_to_nearest_error_le_half_ulp
#print axioms relative_error_le_unit_roundoff
#print axioms sub_rounds_to_zero_only_if_eq

end IEEEFloatingPoint
