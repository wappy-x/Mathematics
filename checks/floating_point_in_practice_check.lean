-- Floating point: rounding the exact answer of a basic operation on two doubles to a nearest double costs at most a relative 2^-53 in the ordinary range, whole numbers are doubles only up to 2^53, and the stored 0.1 plus the stored 0.2 lands exactly halfway between the stored 0.3 and the next double up.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Power
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Data.Int.Log
import Mathlib.Algebra.Order.Round
import Mathlib.Tactic

namespace FloatingPointInPractice

/-- The value of the bit pattern with sign bit `s`, exponent field `e` and fraction field `f`,
as the card's formula reads it: `(-1)^s × (1 + f/2^52) × 2^(e - 1023)` for an ordinary pattern
(`1 ≤ e ≤ 2046`), and `(-1)^s × (f/2^52) × 2^(-1022)` when `e = 0` (zero and the tiny numbers). -/
noncomputable def doubleValue (s e f : ℕ) : ℝ :=
  if e = 0 then (-1 : ℝ) ^ s * ((f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ (-1022 : ℤ)
  else (-1 : ℝ) ^ s * (1 + (f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ ((e : ℤ) - 1023)

/-- `y` is a finite double: the value of some sign bit, an exponent field from 0 to 2046 and a
52-bit fraction field. (Field 2047 holds `inf` and NaN, which are not real numbers.) -/
def IsFiniteDouble (y : ℝ) : Prop :=
  ∃ s e f : ℕ, s ≤ 1 ∧ e ≤ 2046 ∧ f < 2 ^ 52 ∧ y = doubleValue s e f

/-- The largest double, `(2^53 - 1) × 2^971`, printed 1.7976931348623157e308. -/
noncomputable def largestDouble : ℝ := (2 ^ 53 - 1) * (2 : ℝ) ^ (971 : ℤ)

/-- The unit roundoff, `u = 2^-53`, half of machine epsilon. -/
noncomputable def u : ℝ := (2 : ℝ) ^ (-53 : ℤ)

/-- `r` is a nearest double to the exact value `t`: a finite double no further from `t` than any
other finite double. Round to nearest, ties to even, returns one of these; the tie rule only
chooses which one when two are equally near. -/
def IsNearestDouble (r t : ℝ) : Prop :=
  IsFiniteDouble r ∧ ∀ d : ℝ, IsFiniteDouble d → |r - t| ≤ |d - t|

theorem isFiniteDouble_neg {y : ℝ} (h : IsFiniteDouble y) : IsFiniteDouble (-y) := by
  obtain ⟨s, e, f, hs, he, hf, rfl⟩ := h
  refine ⟨1 - s, e, f, by omega, he, hf, ?_⟩
  interval_cases s <;> simp [doubleValue] <;> split_ifs <;> ring

#print axioms isFiniteDouble_neg

theorem isFiniteDouble_grid (m k : ℤ) (hk1 : -1022 ≤ k) (hk2 : k ≤ 1023)
    (hm1 : 2 ^ 52 ≤ m) (hm2 : m < 2 ^ 53) :
    IsFiniteDouble ((m : ℝ) * (2 : ℝ) ^ (k - 52)) := by
  refine ⟨0, (k + 1023).toNat, (m - 2 ^ 52).toNat, by norm_num, by omega, by omega, ?_⟩
  have he : ((k + 1023).toNat : ℤ) = k + 1023 := Int.toNat_of_nonneg (by omega)
  have hf : (((m - 2 ^ 52).toNat : ℕ) : ℝ) = (m : ℝ) - 2 ^ 52 := by
    have : (((m - 2 ^ 52).toNat : ℕ) : ℤ) = m - 2 ^ 52 := Int.toNat_of_nonneg (by omega)
    exact_mod_cast this
  have hne : (k + 1023).toNat ≠ 0 := by omega
  rw [doubleValue, if_neg hne, he, hf, zpow_sub₀ (by norm_num : (2:ℝ) ≠ 0)]
  have : (k + 1023 - 1023 : ℤ) = k := by ring
  rw [this]
  field_simp
  ring

#print axioms isFiniteDouble_grid

theorem isFiniteDouble_on_grid {d : ℝ} (hd : IsFiniteDouble d) (k : ℤ) (hk : -1022 ≤ k)
    (hdk : (2 : ℝ) ^ k ≤ |d|) : ∃ N : ℤ, d = (N : ℝ) * (2 : ℝ) ^ (k - 52) := by
  obtain ⟨s, e, f, hs, he, hf, rfl⟩ := hd
  have hf' : (f : ℝ) < 2 ^ 52 := by exact_mod_cast hf
  have hs' : |(-1 : ℝ) ^ s| = 1 := by simp
  by_cases he0 : e = 0
  · exfalso
    rw [doubleValue, if_pos he0, abs_mul, abs_mul, hs', abs_of_nonneg (by positivity),
      abs_of_pos (by positivity)] at hdk
    have h1 : (2 : ℝ) ^ (-1022 : ℤ) ≤ 2 ^ k := zpow_le_zpow_right₀ (by norm_num) hk
    have h2 : (f : ℝ) / 2 ^ 52 < 1 := by rw [div_lt_one (by positivity)]; exact hf'
    have h3 : (0:ℝ) < 2 ^ (-1022 : ℤ) := by positivity
    nlinarith
  · rw [doubleValue, if_neg he0] at hdk ⊢
    set E : ℤ := (e : ℤ) - 1023 with hE
    clear_value E
    rw [abs_mul, abs_mul, hs', abs_of_pos (by positivity), abs_of_pos (by positivity)] at hdk
    have h2 : 1 + (f : ℝ) / 2 ^ 52 < 2 := by
      have : (f : ℝ) / 2 ^ 52 < 1 := by rw [div_lt_one (by positivity)]; exact hf'
      linarith
    have hlt : (2 : ℝ) ^ k < 2 ^ (E + 1) := by
      rw [zpow_add_one₀ (by norm_num)]
      have : (0:ℝ) < 2 ^ E := by positivity
      nlinarith
    rw [zpow_lt_zpow_iff_right₀ (by norm_num)] at hlt
    refine ⟨(-1) ^ s * (2 ^ 52 + f) * 2 ^ (E - k).toNat, ?_⟩
    have hp : ((2 : ℝ) ^ ((E - k).toNat : ℕ)) = (2 : ℝ) ^ (E - k) := by
      rw [← zpow_natCast, Int.toNat_of_nonneg (by omega)]
    push_cast
    rw [hp, mul_assoc _ ((2:ℝ) ^ (E - k)), ← zpow_add₀ (by norm_num : (2:ℝ) ≠ 0)]
    have : E - k + (k - 52) = E - 52 := by ring
    rw [this, zpow_sub₀ (by norm_num : (2:ℝ) ≠ 0)]
    field_simp
    ring

#print axioms isFiniteDouble_on_grid

theorem exists_double_near {y : ℝ} (hy : (2 : ℝ) ^ (-1022 : ℤ) ≤ y) (hy2 : y ≤ largestDouble) :
    ∃ d : ℝ, IsFiniteDouble d ∧ |d - y| ≤ u * y := by
  have hypos : 0 < y := lt_of_lt_of_le (by positivity) hy
  have h1 : (2 : ℝ) ^ (Int.log 2 y) ≤ y := by
    have := Int.zpow_log_le_self (b := 2) (by norm_num) hypos
    simpa using this
  have h2 : y < (2 : ℝ) ^ (Int.log 2 y + 1) := by
    have := Int.lt_zpow_succ_log_self (b := 2) (by norm_num) y
    simpa using this
  set k := Int.log 2 y with hk
  clear_value k
  have hk1 : -1022 ≤ k := by
    by_contra h
    have : (2 : ℝ) ^ (k + 1) ≤ 2 ^ (-1022 : ℤ) := zpow_le_zpow_right₀ (by norm_num) (by omega)
    linarith
  have h971 : (0 : ℝ) < 2 ^ (971 : ℤ) := by positivity
  have hL : largestDouble < (2 : ℝ) ^ (1024 : ℤ) := by
    have : (2 : ℝ) ^ (1024 : ℤ) = 2 ^ 53 * 2 ^ (971 : ℤ) := by
      rw [show (1024 : ℤ) = 53 + 971 by norm_num, zpow_add₀ two_ne_zero]; norm_num
    rw [this, largestDouble]
    exact mul_lt_mul_of_pos_right (by norm_num) h971
  have hk2 : k ≤ 1023 := by
    by_contra h
    have : (2 : ℝ) ^ (1024 : ℤ) ≤ 2 ^ k := zpow_le_zpow_right₀ (by norm_num) (by omega)
    linarith
  set g : ℝ := (2 : ℝ) ^ (k - 52) with hg
  have hgpos : 0 < g := by positivity
  have e1 : (2 : ℝ) ^ k = 2 ^ 52 * g := by
    rw [hg, ← zpow_natCast, ← zpow_add₀ two_ne_zero]; congr 1; push_cast; ring
  have e2 : (2 : ℝ) ^ (k + 1) = 2 ^ 53 * g := by
    rw [hg, ← zpow_natCast, ← zpow_add₀ two_ne_zero]; congr 1; push_cast; ring
  have hx1 : 2 ^ 52 ≤ y / g := by rw [le_div_iff₀ hgpos]; linarith
  have hx2 : y / g < 2 ^ 53 := by rw [div_lt_iff₀ hgpos]; linarith
  set m : ℤ := round (y / g) with hm
  have hmr : |y / g - m| ≤ 1 / 2 := abs_sub_round _
  rw [abs_le] at hmr
  have hm1 : (2 : ℤ) ^ 52 ≤ m := by
    have : ((2 ^ 52 - 1 : ℤ) : ℝ) < m := by push_cast; linarith
    have : (2 ^ 52 - 1 : ℤ) < m := by exact_mod_cast this
    omega
  have hm2 : m ≤ (2 : ℤ) ^ 53 := by
    have : (m : ℝ) < ((2 ^ 53 + 1 : ℤ) : ℝ) := by push_cast; linarith
    have : m < (2 ^ 53 + 1 : ℤ) := by exact_mod_cast this
    omega
  have hd : IsFiniteDouble ((m : ℝ) * g) := by
    rcases lt_or_eq_of_le hm2 with hlt | heq
    · exact isFiniteDouble_grid m k hk1 hk2 hm1 hlt
    · have hk3 : k ≤ 1022 := by
        by_contra h
        have hk' : k = 1023 := by omega
        have : (m : ℝ) = 2 ^ 53 := by rw [heq]; push_cast; ring
        have hyg : y = (y / g) * g := by field_simp
        have hg971 : g = 2 ^ (971 : ℤ) := by rw [hg, hk']; norm_num
        have hA : (2 ^ 53 - 1 / 2) * g ≤ y := by
          rw [hyg]; exact mul_le_mul_of_nonneg_right (by linarith) hgpos.le
        rw [largestDouble, ← hg971] at hy2
        have hB := mul_lt_mul_of_pos_right (show (2:ℝ) ^ 53 - 1 < 2 ^ 53 - 1 / 2 by norm_num) hgpos
        exact absurd (lt_of_le_of_lt hy2 hB) (not_lt.mpr hA)
      have := isFiniteDouble_grid (2 ^ 52) (k + 1) (by omega) (by omega) le_rfl (by norm_num)
      convert this using 1
      rw [heq, hg, show k + 1 - 52 = 1 + (k - 52) by ring, zpow_add₀ two_ne_zero]
      push_cast; ring
  refine ⟨m * g, hd, ?_⟩
  have : (m : ℝ) * g - y = - (g * (y / g - m)) := by field_simp; ring
  rw [this, abs_neg, abs_mul, abs_of_pos hgpos]
  have hu : u * 2 ^ k = g / 2 := by
    rw [u, e1]; norm_num; ring
  have : g * |y / g - m| ≤ g / 2 := by
    have : |y / g - m| ≤ 1 / 2 := abs_le.mpr hmr
    nlinarith
  have : u * 2 ^ k ≤ u * y := mul_le_mul_of_nonneg_left h1 (by rw [u]; positivity)
  linarith

#print axioms exists_double_near

theorem natCast_isFiniteDouble (n : ℕ) (hn0 : 0 < n) (hn : n ≤ 2 ^ 53) :
    IsFiniteDouble (n : ℝ) := by
  rcases lt_or_eq_of_le hn with hlt | heq
  · have hk := Nat.pow_log_le_self 2 (Nat.pos_iff_ne_zero.mp hn0)
    have hk' := Nat.lt_pow_succ_log_self (by norm_num : 1 < 2) n
    set k := Nat.log 2 n
    clear_value k
    have hk52 : k ≤ 52 := by
      by_contra h
      have : 2 ^ 53 ≤ 2 ^ k := Nat.pow_le_pow_right (by norm_num) (by omega)
      omega
    have hsplit : 2 ^ k * 2 ^ (52 - k) = 2 ^ 52 := by rw [← pow_add, Nat.add_sub_cancel' hk52]
    have hsplit' : 2 ^ (k + 1) * 2 ^ (52 - k) = 2 ^ 53 := by
      rw [← pow_add]; congr 1; omega
    have hm1 : 2 ^ 52 ≤ n * 2 ^ (52 - k) := by
      rw [← hsplit]; exact Nat.mul_le_mul_right _ hk
    have hm2 : n * 2 ^ (52 - k) < 2 ^ 53 := by
      rw [← hsplit']; exact Nat.mul_lt_mul_of_pos_right hk' (by positivity)
    have := isFiniteDouble_grid ((n * 2 ^ (52 - k) : ℕ) : ℤ) (k : ℤ) (by omega) (by omega)
      (by exact_mod_cast hm1) (by exact_mod_cast hm2)
    convert this using 1
    push_cast
    rw [mul_assoc, ← zpow_natCast, ← zpow_add₀ two_ne_zero, Nat.cast_sub hk52]
    simp
  · subst heq
    have := isFiniteDouble_grid (2 ^ 52) 53 (by norm_num) (by norm_num) le_rfl (by norm_num)
    convert this using 1
    norm_num

#print axioms natCast_isFiniteDouble

theorem abs_le_abs_of_scaled {x y c : ℝ} (hc : 0 < c) (A B : ℤ) (hx : c * x = A)
    (hy : c * y = B) (h : |A| ≤ |B|) : |x| ≤ |y| := by
  have h1 : c * |x| = |(A : ℝ)| := by rw [← hx, abs_mul, abs_of_pos hc]
  have h2 : c * |y| = |(B : ℝ)| := by rw [← hy, abs_mul, abs_of_pos hc]
  have h3 : |(A : ℝ)| ≤ |(B : ℝ)| := by exact_mod_cast h
  exact le_of_mul_le_mul_left (by linarith) hc

#print axioms abs_le_abs_of_scaled

theorem nearest_of_grid {r t : ℝ} (k : ℤ) (hk : -1022 ≤ k) (hr : IsFiniteDouble r)
    (hpos : (2 : ℝ) ^ k ≤ t - |r - t|)
    (hgrid : ∀ N : ℤ, |r - t| ≤ |(N : ℝ) * (2 : ℝ) ^ (k - 52) - t|) :
    IsNearestDouble r t := by
  refine ⟨hr, fun d hd => ?_⟩
  by_contra h
  rw [not_le] at h
  have h2k : (0 : ℝ) < 2 ^ k := by positivity
  have hdk : (2 : ℝ) ^ k ≤ |d| := by
    have := (abs_sub_lt_iff.mp h).2
    rw [abs_of_pos (by linarith)]
    linarith
  obtain ⟨N, rfl⟩ := isFiniteDouble_on_grid hd k hk hdk
  exact absurd (hgrid N) (not_le.mpr h)

#print axioms nearest_of_grid

/-- The machine's promise. Take two stored numbers `a` and `b` (finite doubles) and one basic
operation `∘`: addition, subtraction, multiplication or division. Suppose the exact answer
`a ∘ b` is of ordinary size, between `2^-1022` and the largest double in absolute value, and
the machine returns a nearest double `fl(a ∘ b)` to it, as round to nearest, ties to even does.
Then `fl(a ∘ b) = (a ∘ b)(1 + δ)` with `|δ| ≤ u = 2^-53`. -/
theorem basic_operation_rounds_within_unit_roundoff (a b : ℝ)
    (ha : IsFiniteDouble a) (hb : IsFiniteDouble b) (op : ℝ → ℝ → ℝ)
    (hop : op = (· + ·) ∨ op = (· - ·) ∨ op = (· * ·) ∨ op = (· / ·))
    (hlo : (2 : ℝ) ^ (-1022 : ℤ) ≤ |op a b|) (hhi : |op a b| ≤ largestDouble)
    (fl : ℝ) (hfl : IsNearestDouble fl (op a b)) :
    ∃ δ : ℝ, |δ| ≤ u ∧ fl = op a b * (1 + δ) := by
  set t := op a b with ht
  clear_value t
  have htpos : 0 < |t| := lt_of_lt_of_le (by positivity) hlo
  have ht0 : t ≠ 0 := abs_pos.mp htpos
  obtain ⟨d, hd, hdy⟩ := exists_double_near hlo hhi
  have : ∃ d' : ℝ, IsFiniteDouble d' ∧ |d' - t| ≤ u * |t| := by
    rcases abs_cases t with ⟨h1, _⟩ | ⟨h1, _⟩
    · refine ⟨d, hd, ?_⟩
      calc |d - t| = |d - (|t|)| := by rw [h1]
        _ ≤ u * |t| := hdy
    · refine ⟨-d, isFiniteDouble_neg hd, ?_⟩
      rw [show -d - t = -(d - -t) by ring, abs_neg, ← h1]; exact hdy
  obtain ⟨d', hd', hd'y⟩ := this
  have hfl' := hfl.2 d' hd'
  refine ⟨(fl - t) / t, ?_, ?_⟩
  · rw [abs_div, div_le_iff₀ htpos]; linarith
  · field_simp; ring

/-- Whole numbers stop being exact at `2^53`: every whole number from `-2^53` to `2^53` is a
double, but `2^53 + 1` is not. -/
theorem whole_numbers_exact_up_to_two_pow_53 :
    (∀ n : ℤ, |n| ≤ 2 ^ 53 → IsFiniteDouble (n : ℝ)) ∧
      ¬ IsFiniteDouble ((2 : ℝ) ^ 53 + 1) := by
  constructor
  · intro n hn
    have hn' := abs_le.mp hn
    rcases lt_trichotomy n 0 with h | h | h
    · have := natCast_isFiniteDouble n.natAbs (by omega) (by omega)
      have := isFiniteDouble_neg this
      convert this using 1
      have : ((n.natAbs : ℤ) : ℝ) = -n := by
        rw [Int.natCast_natAbs, abs_of_neg h]; push_cast; ring
      rw [← Int.cast_natCast, this]; ring
    · subst h
      exact ⟨0, 0, 0, by norm_num, by norm_num, by norm_num, by simp [doubleValue]⟩
    · have := natCast_isFiniteDouble n.natAbs (by omega) (by omega)
      convert this using 1
      rw [← Int.cast_natCast, Int.natCast_natAbs, abs_of_pos h]
  · rintro ⟨s, e, f, hs, he, hf, hv⟩
    have hf' : (f : ℝ) < 2 ^ 52 := by exact_mod_cast hf
    have hfd : (f : ℝ) / 2 ^ 52 < 1 := by rw [div_lt_one (by positivity)]; exact hf'
    have hf0 : (0 : ℝ) ≤ (f : ℝ) / 2 ^ 52 := by positivity
    interval_cases s
    · by_cases he0 : e = 0
      · rw [doubleValue, if_pos he0] at hv
        have : (2 : ℝ) ^ (-1022 : ℤ) ≤ 1 := zpow_le_one_of_nonpos₀ (by norm_num) (by norm_num)
        have h0 : (0 : ℝ) < 2 ^ (-1022 : ℤ) := by positivity
        simp only [pow_zero, one_mul] at hv
        nlinarith
      · rw [doubleValue, if_neg he0] at hv
        set E : ℤ := (e : ℤ) - 1023 with hE
        clear_value E
        simp only [pow_zero, one_mul] at hv
        by_cases hE52 : E ≤ 52
        · have : (2 : ℝ) ^ E ≤ 2 ^ (52 : ℤ) := zpow_le_zpow_right₀ (by norm_num) hE52
          have h0 : (0 : ℝ) < 2 ^ E := by positivity
          have : (2 : ℝ) ^ (52 : ℤ) = 2 ^ 52 := by norm_num
          nlinarith
        · have hj : (2 : ℝ) ^ E = 2 ^ 53 * 2 ^ ((E - 53).toNat) := by
            rw [← zpow_natCast, ← zpow_natCast, ← zpow_add₀ two_ne_zero,
              Int.toNat_of_nonneg (by omega)]
            congr 1; push_cast; ring
          rw [hj] at hv
          have : ((2 ^ 53 + 1 : ℕ) : ℝ) = ((2 * ((2 ^ 52 + f) * 2 ^ ((E - 53).toNat)) : ℕ) : ℝ) := by
            rw [show ((2 ^ 53 + 1 : ℕ) : ℝ) = (2 : ℝ) ^ 53 + 1 by norm_num, hv]
            push_cast; field_simp; ring
          have h2 := Nat.cast_injective this
          generalize (2 ^ 52 + f) * 2 ^ ((E - 53).toNat) = X at h2
          omega
    · have h0 : (0 : ℝ) < 2 ^ 53 + 1 := by positivity
      rw [hv, doubleValue] at h0
      split_ifs at h0
      · have : (0 : ℝ) < 2 ^ (-1022 : ℤ) := by positivity
        nlinarith
      · have : (0 : ℝ) < 2 ^ ((e : ℤ) - 1023) := by positivity
        nlinarith

/-- Why `0.1 + 0.2` is not `0.3`. The nearest doubles to one tenth, two tenths and three tenths
are `7205759403792794 / 2^56`, `7205759403792794 / 2^55` and `5404319552844595 / 2^54`.
The exact sum of the first two has exactly two nearest doubles, the stored 0.3 and the next
double up, `5404319552844596 / 2^54`: it sits on a tie, so the answer is not forced to be the
stored 0.3, and ties to even picks the one above. -/
theorem point_one_plus_point_two_is_a_tie :
    IsNearestDouble (7205759403792794 / 2 ^ 56) (1 / 10) ∧
      IsNearestDouble (7205759403792794 / 2 ^ 55) (2 / 10) ∧
      IsNearestDouble (5404319552844595 / 2 ^ 54) (3 / 10) ∧
      ∀ r : ℝ, IsNearestDouble r (7205759403792794 / 2 ^ 56 + 7205759403792794 / 2 ^ 55) ↔
        r = 5404319552844595 / 2 ^ 54 ∨ r = 5404319552844596 / 2 ^ 54 := by
  have hA : IsFiniteDouble (5404319552844595 / 2 ^ 54) := by
    have := isFiniteDouble_grid 5404319552844595 (-2) (by norm_num) (by norm_num)
      (by norm_num) (by norm_num)
    convert this using 1
    norm_num
  have hB : IsFiniteDouble (5404319552844596 / 2 ^ 54) := by
    have := isFiniteDouble_grid 5404319552844596 (-2) (by norm_num) (by norm_num)
      (by norm_num) (by norm_num)
    convert this using 1
    norm_num
  have hSA : IsNearestDouble (5404319552844595 / 2 ^ 54)
      (7205759403792794 / 2 ^ 56 + 7205759403792794 / 2 ^ 55) := by
    refine nearest_of_grid (-2) (by norm_num) hA ?_ ?_
    · rw [abs_of_neg (by norm_num)]; norm_num
    · intro N
      refine abs_le_abs_of_scaled (c := 2 ^ 56) (by positivity) (-2)
        (4 * N - 21617278211378382) (by norm_num) (by push_cast; norm_num; ring) ?_
      rw [le_abs]; norm_num; omega
  have hSB : IsNearestDouble (5404319552844596 / 2 ^ 54)
      (7205759403792794 / 2 ^ 56 + 7205759403792794 / 2 ^ 55) := by
    refine nearest_of_grid (-2) (by norm_num) hB ?_ ?_
    · rw [abs_of_pos (by norm_num)]; norm_num
    · intro N
      refine abs_le_abs_of_scaled (c := 2 ^ 56) (by positivity) 2
        (4 * N - 21617278211378382) (by norm_num) (by push_cast; norm_num; ring) ?_
      rw [le_abs]; norm_num; omega
  refine ⟨?_, ?_, ?_, ?_⟩
  · have hr : IsFiniteDouble (7205759403792794 / 2 ^ 56) := by
      have := isFiniteDouble_grid 7205759403792794 (-4) (by norm_num) (by norm_num)
        (by norm_num) (by norm_num)
      convert this using 1
      norm_num
    refine nearest_of_grid (-4) (by norm_num) hr ?_ ?_
    · rw [abs_of_pos (by norm_num)]; norm_num
    · intro N
      refine abs_le_abs_of_scaled (c := 10 * 2 ^ 56) (by positivity) 4
        (10 * N - 2 ^ 56) (by norm_num) (by push_cast; norm_num; ring) ?_
      rw [le_abs]; norm_num; omega
  · have hr : IsFiniteDouble (7205759403792794 / 2 ^ 55) := by
      have := isFiniteDouble_grid 7205759403792794 (-3) (by norm_num) (by norm_num)
        (by norm_num) (by norm_num)
      convert this using 1
      norm_num
    refine nearest_of_grid (-3) (by norm_num) hr ?_ ?_
    · rw [abs_of_pos (by norm_num)]; norm_num
    · intro N
      refine abs_le_abs_of_scaled (c := 5 * 2 ^ 55) (by positivity) 2
        (5 * N - 2 ^ 55) (by norm_num) (by push_cast; norm_num; ring) ?_
      rw [le_abs]; norm_num; omega
  · refine nearest_of_grid (-2) (by norm_num) hA ?_ ?_
    · rw [abs_of_neg (by norm_num)]; norm_num
    · intro N
      refine abs_le_abs_of_scaled (c := 10 * 2 ^ 54) (by positivity) (-2)
        (10 * N - 3 * 2 ^ 54) (by norm_num) (by push_cast; norm_num; ring) ?_
      rw [le_abs]; norm_num; omega
  · intro r
    constructor
    · intro h
      have h1 := h.2 _ hSA.1
      rw [abs_of_neg (a := (5404319552844595 / 2 ^ 54 : ℝ) -
        (7205759403792794 / 2 ^ 56 + 7205759403792794 / 2 ^ 55)) (by norm_num)] at h1
      have hrk : (2 : ℝ) ^ (-2 : ℤ) ≤ |r| := by
        have := (abs_le.mp h1).1
        rw [abs_of_pos (by norm_num at this ⊢; linarith)]
        norm_num at this ⊢; linarith
      obtain ⟨N, rfl⟩ := isFiniteDouble_on_grid h.1 (-2) (by norm_num) hrk
      have h2 : |((4 * N - 21617278211378382 : ℤ) : ℝ)| ≤ 2 := by
        have e : ((4 * N - 21617278211378382 : ℤ) : ℝ) =
            2 ^ 56 * ((N : ℝ) * 2 ^ ((-2 : ℤ) - 52) -
              (7205759403792794 / 2 ^ 56 + 7205759403792794 / 2 ^ 55)) := by
          push_cast; norm_num; ring
        rw [e, abs_mul, abs_of_pos (by positivity)]
        norm_num at h1 ⊢
        linarith
      have h3 : |4 * N - 21617278211378382| ≤ (2 : ℤ) := by exact_mod_cast h2
      rw [abs_le] at h3
      have : N = 5404319552844595 ∨ N = 5404319552844596 := by omega
      rcases this with rfl | rfl
      · left; norm_num
      · right; norm_num
    · rintro (rfl | rfl)
      · exact hSA
      · exact hSB

-- The card's whole-number worked examples.

-- The 64 bits of 0.1: exponent field 01111111011 is 1019, a scale of 2^(1019 - 1023) = 2^-4.
example : 0b01111111011 = 1019 ∧ (1019 : ℤ) - 1023 = -4 := by decide
-- The fraction field of 0.1, read as a whole number.
example : 0b1001100110011001100110011001100110011001100110011010 = 2702159776422298 := by
  norm_num
-- Putting the leading 1 back gives the 53-bit whole number of stored 0.1, over 2^(52 + 4).
example : 2 ^ 52 + 2702159776422298 = 7205759403792794 ∧
    2 ^ 52 ≤ 7205759403792794 ∧ 7205759403792794 < 2 ^ 53 := by norm_num
-- The fields of 0.1 decode to 7205759403792794 / 2^56.
example : doubleValue 0 1019 2702159776422298 = 7205759403792794 / 2 ^ 56 := by
  norm_num [doubleValue]
-- Stored 0.1 is too large: 10 × 7205759403792794 overshoots 2^56 by 4, so by 4 / (10 × 2^56).
example : 10 * 7205759403792794 - 2 ^ 56 = 4 := by norm_num
-- Stored 0.2 over 2^56 is twice stored 0.1.
example : 2 * 7205759403792794 = 14411518807585588 := by norm_num
-- Stored 0.3 is 5404319552844595 / 2^54, too small: 3 × 2^54 - 10 × 5404319552844595 = 2.
example : 3 * 2 ^ 54 - 10 * 5404319552844595 = 2 := by norm_num
-- The exact sum over 2^56 is 21617278211378382, a 55-bit number.
example : 7205759403792794 + 14411518807585588 = 21617278211378382 ∧
    2 ^ 54 ≤ 21617278211378382 ∧ 21617278211378382 < 2 ^ 55 := by norm_num
-- Dropping 2 bits leaves 2 out of 4: exactly half, a tie.
example : 21617278211378382 = 4 * 5404319552844595 + 2 := by norm_num
-- 5404319552844595 is odd, so ties to even rounds up to 5404319552844596, one step above stored 0.3.
example : 5404319552844595 % 2 = 1 ∧ 5404319552844596 % 2 = 0 ∧
    5404319552844596 - 5404319552844595 = 1 := by norm_num
-- The add's relative error is 2 / 21617278211378382, which is 2^54 / 21617278211378382 u,
-- between 0.8332 u and 0.8334 u, so under u.
example : (8332 / 10000 : ℚ) < 2 ^ 54 / 21617278211378382 ∧
    (2 ^ 54 / 21617278211378382 : ℚ) < 8334 / 10000 := by norm_num
-- Machine epsilon: the next double after 1 has exponent field 1023 and fraction field 1.
example : doubleValue 0 1023 1 = 1 + 1 / 2 ^ 52 := by norm_num [doubleValue]
-- 0.3 lies between 2^-2 and 2^-1, and 100000 between 2^16 and 2^17, which sets their gaps.
example : (1 / 4 : ℚ) ≤ 3 / 10 ∧ (3 / 10 : ℚ) < 1 / 2 ∧
    2 ^ 16 ≤ 100000 ∧ 100000 < 2 ^ 17 := by norm_num
-- At 2^53 = 9007199254740992 the gap is 2: the next double up is 2^53 + 2.
example : (2 : ℕ) ^ 53 = 9007199254740992 := by norm_num
example : doubleValue 0 1076 0 = 2 ^ 53 ∧ doubleValue 0 1076 1 = 2 ^ 53 + 2 := by
  constructor <;> norm_num [doubleValue]
-- 2^53 + 1 is halfway between 2^53 and 2^53 + 2.
example : ((2 : ℕ) ^ 53 + 1) - 2 ^ 53 = (2 ^ 53 + 2) - (2 ^ 53 + 1) := by norm_num
-- 0.1 added ten times prints 0.9999999999999999, the double (2^53 - 1) / 2^53, off by 2^-53.
example : (1 : ℚ) - (2 ^ 53 - 1) / 2 ^ 53 = 1 / 2 ^ 53 := by norm_num
-- 100 × 1.05^10 is 105^10 / 10^18 exactly.
example : (100 : ℚ) * (105 / 100) ^ 10 = 162889462677744140625 / 10 ^ 18 := by norm_num

#print axioms basic_operation_rounds_within_unit_roundoff
#print axioms whole_numbers_exact_up_to_two_pow_53
#print axioms point_one_plus_point_two_is_a_tie

end FloatingPointInPractice
