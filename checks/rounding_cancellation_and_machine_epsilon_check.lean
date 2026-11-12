-- Machine epsilon and cancellation: the gap from 1 to the next double is 2^-52, rounding a result in the normal range to a nearest double gives fl(x ∘ y) = (x ∘ y)(1 + δ) with |δ| ≤ u = 2^-53, and two positive doubles within a factor of 2 subtract exactly.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Field.Power
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Data.Int.Log
import Mathlib.Algebra.Order.Round
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.Positivity
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Tactic.LinearCombination

namespace MachineEpsilonCancellation

/-- The value of the bit pattern with sign bit `s`, exponent field `e` and fraction field `f`:
`(-1)^s × (1 + f/2^52) × 2^(e - 1023)` for a normal pattern (`1 ≤ e ≤ 2046`), and
`(-1)^s × (f/2^52) × 2^(-1022)` when `e = 0` (zero or subnormal). -/
noncomputable def doubleValue (s e f : ℕ) : ℝ :=
  if e = 0 then (-1 : ℝ) ^ s * ((f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ (-1022 : ℤ)
  else (-1 : ℝ) ^ s * (1 + (f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ ((e : ℤ) - 1023)

/-- `y` is a finite double: the value of some sign bit, an exponent field from 0 to 2046 and a
52-bit fraction field. -/
def IsFiniteDouble (y : ℝ) : Prop :=
  ∃ s e f : ℕ, s ≤ 1 ∧ e ≤ 2046 ∧ f < 2 ^ 52 ∧ y = doubleValue s e f

/-- The largest double, `(2^53 - 1) × 2^971`, about 1.8e308. -/
noncomputable def largestDouble : ℝ := (2 ^ 53 - 1) * (2 : ℝ) ^ (971 : ℤ)

/-- Machine epsilon, `ε_mach = 2^-52`. -/
noncomputable def epsMach : ℝ := (2 : ℝ) ^ (-52 : ℤ)

/-- The unit roundoff, `u = 2^-53`, half of machine epsilon. -/
noncomputable def u : ℝ := (2 : ℝ) ^ (-53 : ℤ)

/-- `r` is a nearest double to the exact value `t`: a finite double no further from `t` than any
other finite double. Round to nearest, ties to even, returns one of these; the tie rule only
chooses which one when two are equally near. -/
def IsNearestDouble (r t : ℝ) : Prop :=
  IsFiniteDouble r ∧ ∀ d : ℝ, IsFiniteDouble d → |r - t| ≤ |d - t|

/-- A normal pattern with sign bit 0 is the whole number `2^52 + f` times `2^(e - 1075)`. -/
lemma doubleValue_normal_eq (e f : ℕ) (he : e ≠ 0) :
    doubleValue 0 e f = ((2 ^ 52 + f : ℕ) : ℝ) * (2 : ℝ) ^ ((e : ℤ) - 1075) := by
  simp only [doubleValue, he, ↓reduceIte]
  have h : ((e : ℤ) - 1023) = ((e : ℤ) - 1075) + ((52 : ℕ) : ℤ) := by push_cast; ring
  rw [h, zpow_add₀ two_ne_zero, zpow_natCast]
  push_cast
  field_simp
  ring

#print axioms doubleValue_normal_eq

/-- A pattern with exponent field 0 and sign bit 0 is `f` times `2^-1074`. -/
lemma doubleValue_sub_eq (f : ℕ) : doubleValue 0 0 f = (f : ℝ) * (2 : ℝ) ^ (-1074 : ℤ) := by
  simp only [doubleValue, ↓reduceIte]
  have h : (-1022 : ℤ) = -1074 + ((52 : ℕ) : ℤ) := by norm_num
  rw [h, zpow_add₀ two_ne_zero, zpow_natCast]
  field_simp

#print axioms doubleValue_sub_eq

/-- `M × 2^Q` with `2^52 ≤ M < 2^53` and `-1074 ≤ Q ≤ 971` is a finite double (a normal one). -/
lemma double_of_normal (M : ℕ) (Q : ℤ) (h1 : 2 ^ 52 ≤ M) (h2 : M < 2 ^ 53) (hQ1 : -1074 ≤ Q)
    (hQ2 : Q ≤ 971) : IsFiniteDouble ((M : ℝ) * (2 : ℝ) ^ Q) := by
  have he : (((Q + 1075).toNat : ℕ) : ℤ) = Q + 1075 := Int.toNat_of_nonneg (by omega)
  refine ⟨0, (Q + 1075).toNat, M - 2 ^ 52, by norm_num, by omega, by omega, ?_⟩
  rw [doubleValue_normal_eq _ _ (by omega), Nat.add_sub_cancel' h1, he]
  congr 2
  ring

#print axioms double_of_normal

/-- `M × 2^Q` with `M < 2^53` and `-1074 ≤ Q ≤ 971` is a finite double, by induction on
`Q + 1074`. -/
lemma double_of_rep_aux : ∀ n : ℕ, ∀ (M : ℕ) (Q : ℤ), Q = (n : ℤ) - 1074 → M < 2 ^ 53 →
    Q ≤ 971 → IsFiniteDouble ((M : ℝ) * (2 : ℝ) ^ Q)
  | 0 => by
    intro M Q hQ hM hQ2
    by_cases h : 2 ^ 52 ≤ M
    · exact double_of_normal M Q h hM (by omega) hQ2
    · refine ⟨0, 0, M, by norm_num, by norm_num, by omega, ?_⟩
      rw [doubleValue_sub_eq, hQ]
      norm_num
  | n + 1 => by
    intro M Q hQ hM hQ2
    by_cases h : 2 ^ 52 ≤ M
    · exact double_of_normal M Q h hM (by omega) hQ2
    · have ih := double_of_rep_aux n (2 * M) (Q - 1) (by omega) (by omega) (by omega)
      convert ih using 1
      rw [zpow_sub₀ two_ne_zero]
      push_cast
      field_simp

#print axioms double_of_rep_aux

/-- `M × 2^Q` with `M < 2^53` and `-1074 ≤ Q ≤ 971` is a finite double. -/
lemma double_of_rep (M : ℕ) (Q : ℤ) (hM : M < 2 ^ 53) (hQ1 : -1074 ≤ Q) (hQ2 : Q ≤ 971) :
    IsFiniteDouble ((M : ℝ) * (2 : ℝ) ^ Q) :=
  double_of_rep_aux (Q + 1074).toNat M Q (by omega) hM hQ2

#print axioms double_of_rep

/-- A positive finite double is `M × 2^Q` with `M < 2^53` and `-1074 ≤ Q ≤ 971`. -/
lemma rep_of_double {z : ℝ} (h : IsFiniteDouble z) (hz : 0 < z) :
    ∃ M : ℕ, ∃ Q : ℤ, M < 2 ^ 53 ∧ -1074 ≤ Q ∧ Q ≤ 971 ∧ z = (M : ℝ) * (2 : ℝ) ^ Q := by
  obtain ⟨s, e, f, hs, he, hf, rfl⟩ := h
  interval_cases s
  · by_cases he0 : e = 0
    · subst he0
      exact ⟨f, -1074, by omega, by norm_num, by norm_num, doubleValue_sub_eq f⟩
    · exact ⟨2 ^ 52 + f, (e : ℤ) - 1075, by omega, by omega, by omega,
        doubleValue_normal_eq e f he0⟩
  · exfalso
    have hn : doubleValue 1 e f ≤ 0 := by
      unfold doubleValue
      split_ifs
      · have : 0 ≤ (f : ℝ) / 2 ^ 52 * (2 : ℝ) ^ (-1022 : ℤ) := by positivity
        rw [pow_one]
        linarith
      · have : 0 ≤ (1 + (f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ ((e : ℤ) - 1023) := by positivity
        rw [pow_one]
        linarith
    linarith

#print axioms rep_of_double

/-- The negative of a finite double is a finite double: flip the sign bit. -/
lemma double_neg {d : ℝ} (h : IsFiniteDouble d) : IsFiniteDouble (-d) := by
  obtain ⟨s, e, f, hs, he, hf, rfl⟩ := h
  refine ⟨1 - s, e, f, by omega, he, hf, ?_⟩
  interval_cases s <;> (unfold doubleValue; split_ifs <;> ring)

#print axioms double_neg

/-- A finite double `d` close to a number `t` in the positive normal range: `|d - t| ≤ u t`. -/
lemma exists_double_near_pos (t : ℝ) (hlo : (2 : ℝ) ^ (-1022 : ℤ) ≤ t) (hhi : t ≤ largestDouble) :
    ∃ d : ℝ, IsFiniteDouble d ∧ |d - t| ≤ u * t := by
  have ht : 0 < t := lt_of_lt_of_le (by positivity) hlo
  set E : ℤ := Int.log 2 t with hEdef
  have h1 : (2 : ℝ) ^ E ≤ t := by
    have := Int.zpow_log_le_self (b := 2) (by norm_num) ht
    simpa using this
  have h2 : t < (2 : ℝ) ^ (E + 1) := by
    have := Int.lt_zpow_succ_log_self (b := 2) (by norm_num) t
    simpa using this
  have hE1 : -1022 ≤ E :=
    (Int.zpow_le_iff_le_log (b := 2) (by norm_num) ht).1 (by simpa using hlo)
  have hE2 : E ≤ 1023 := by
    by_contra hc
    have : (2 : ℝ) ^ (1024 : ℤ) ≤ 2 ^ E := zpow_le_zpow_right₀ (by norm_num) (by omega)
    have hl : largestDouble < (2 : ℝ) ^ (1024 : ℤ) := by
      rw [largestDouble, show (971 : ℤ) = ((971 : ℕ) : ℤ) from rfl,
        show (1024 : ℤ) = ((1024 : ℕ) : ℤ) from rfl, zpow_natCast, zpow_natCast]
      have h53 : (2 : ℝ) ^ (1024 : ℕ) = 2 ^ 53 * 2 ^ (971 : ℕ) := by rw [← pow_add]
      rw [h53]
      gcongr
      norm_num
    linarith
  set s : ℝ := (2 : ℝ) ^ (E - 52) with hsdef
  have hs : 0 < s := by positivity
  have hEs : (2 : ℝ) ^ E = 2 ^ 52 * s := by
    rw [hsdef, ← zpow_natCast, ← zpow_add₀ two_ne_zero]; congr 1; push_cast; ring
  have hEs1 : (2 : ℝ) ^ (E + 1) = 2 ^ 53 * s := by
    rw [hsdef, ← zpow_natCast, ← zpow_add₀ two_ne_zero]; congr 1; push_cast; ring
  set a : ℝ := t / s with hadef
  have hat : t = a * s := by rw [hadef]; field_simp
  have ha1 : (2 : ℝ) ^ 52 ≤ a := by
    rw [hadef, le_div_iff₀ hs]; linarith
  have ha2 : a < 2 ^ 53 := by
    rw [hadef, div_lt_iff₀ hs]; linarith
  set N : ℤ := round a with hNdef
  have hN : |a - N| ≤ 1 / 2 := abs_sub_round a
  have hN' := abs_le.1 hN
  have hN1 : (2 ^ 52 : ℤ) ≤ N := by
    have : ((2 ^ 52 - 1 : ℤ) : ℝ) < N := by push_cast; linarith
    have := Int.cast_lt.1 this
    omega
  have hN2 : N ≤ 2 ^ 53 := by
    have : (N : ℝ) < ((2 ^ 53 + 1 : ℤ) : ℝ) := by push_cast; linarith
    have := Int.cast_lt.1 this
    omega
  refine ⟨(N : ℝ) * s, ?_, ?_⟩
  · rcases lt_or_eq_of_le hN2 with hlt | heq
    · have hc : ((N.toNat : ℕ) : ℝ) = (N : ℝ) := by
        have : ((N.toNat : ℕ) : ℤ) = N := Int.toNat_of_nonneg (by omega)
        exact_mod_cast this
      rw [← hc]
      exact double_of_rep N.toNat (E - 52) (by omega) (by omega) (by omega)
    · have hE3 : E ≤ 1022 := by
        by_contra hc
        have hE : E = 1023 := by omega
        have hs971 : s = (2 : ℝ) ^ (971 : ℤ) := by rw [hsdef, hE]; norm_num
        have : a ≤ 2 ^ 53 - 1 := by
          rw [hadef, div_le_iff₀ hs, hs971]
          simpa [largestDouble] using hhi
        have : (N : ℝ) = 2 ^ 53 := by rw [heq]; norm_num
        linarith
      have : (N : ℝ) * s = ((2 ^ 52 : ℕ) : ℝ) * (2 : ℝ) ^ (E - 51) := by
        rw [heq, hsdef]
        have h' : E - 51 = (E - 52) + ((1 : ℕ) : ℤ) := by push_cast; ring
        rw [h', zpow_add₀ two_ne_zero, zpow_natCast]
        push_cast
        ring
      rw [this]
      exact double_of_rep _ _ (by norm_num) (by omega) (by omega)
  · have hd : (N : ℝ) * s - t = (N - a) * s := by rw [hat]; ring
    rw [hd, abs_mul, abs_of_pos hs, abs_sub_comm]
    have hu : u * (2 : ℝ) ^ E = s / 2 := by
      rw [u, hEs]
      have : (2 : ℝ) ^ (-53 : ℤ) * 2 ^ 52 = 1 / 2 := by norm_num
      linear_combination s * this
    have hu0 : 0 < u := by rw [u]; positivity
    have : u * (2 : ℝ) ^ E ≤ u * t := mul_le_mul_of_nonneg_left h1 hu0.le
    nlinarith

#print axioms exists_double_near_pos

/-- Machine epsilon is the gap next to one: `1 + 2^-52` is a double, and no double lies
strictly between 1 and it. -/
theorem machine_epsilon_is_gap_next_to_one :
    IsFiniteDouble (1 + epsMach) ∧
      ∀ y : ℝ, IsFiniteDouble y → 1 < y → 1 + epsMach ≤ y := by
  constructor
  · exact ⟨0, 1023, 1, by norm_num, by norm_num, by norm_num, by norm_num [doubleValue, epsMach]⟩
  · rintro y ⟨s, e, f, hs, he, hf, rfl⟩ hy
    have hf' : (f : ℝ) < 2 ^ 52 := by exact_mod_cast hf
    interval_cases s
    · by_cases he0 : e = 0
      · subst he0
        exfalso
        rw [doubleValue_sub_eq] at hy
        have hp : (0 : ℝ) < 2 ^ (-1074 : ℤ) := by positivity
        have h1 : (2 : ℝ) ^ 52 * 2 ^ (-1074 : ℤ) < 1 := by
          rw [← zpow_natCast, ← zpow_add₀ two_ne_zero]
          exact zpow_lt_one_of_neg₀ (by norm_num) (by norm_num)
        have h2 := mul_lt_mul_of_pos_right hf' hp
        linarith
      · rw [doubleValue_normal_eq _ _ he0] at hy ⊢
        have hM : ((2 ^ 52 + f : ℕ) : ℝ) < 2 ^ 53 := by push_cast; linarith
        have hM0 : (2 : ℝ) ^ 52 ≤ ((2 ^ 52 + f : ℕ) : ℝ) := by push_cast; linarith [f.cast_nonneg (α := ℝ)]
        have heps : (0 : ℝ) < epsMach := by rw [epsMach]; positivity
        rcases lt_trichotomy e 1023 with hlt | heq | hgt
        · exfalso
          have hp : (2 : ℝ) ^ ((e : ℤ) - 1075) ≤ 2 ^ (-53 : ℤ) :=
            zpow_le_zpow_right₀ (by norm_num) (by omega)
          have hp0 : (0 : ℝ) < 2 ^ ((e : ℤ) - 1075) := by positivity
          have h1 : (2 : ℝ) ^ 53 * 2 ^ (-53 : ℤ) = 1 := by norm_num
          have h2 := mul_lt_mul_of_pos_right hM hp0
          have h3 : (2 : ℝ) ^ 53 * 2 ^ ((e : ℤ) - 1075) ≤ 2 ^ 53 * 2 ^ (-53 : ℤ) :=
            mul_le_mul_of_nonneg_left hp (by positivity)
          linarith
        · subst heq
          have hf1 : 1 ≤ f := by
            by_contra hc
            have : f = 0 := by omega
            subst this
            norm_num at hy
          have hf1' : (1 : ℝ) ≤ f := by exact_mod_cast hf1
          rw [epsMach]
          have h1 : (2 : ℝ) ^ 52 * 2 ^ (-52 : ℤ) = 1 := by norm_num
          have hp : (0 : ℝ) < 2 ^ (-52 : ℤ) := by positivity
          push_cast
          norm_num
          nlinarith
        · have hp : (2 : ℝ) ^ (-51 : ℤ) ≤ 2 ^ ((e : ℤ) - 1075) :=
            zpow_le_zpow_right₀ (by norm_num) (by omega)
          have h1 : (2 : ℝ) ^ 52 * 2 ^ (-51 : ℤ) = 2 := by norm_num
          have h2 : epsMach ≤ 1 := by rw [epsMach]; norm_num
          have h3 : (2 : ℝ) ^ 52 * 2 ^ (-51 : ℤ) ≤ ((2 ^ 52 + f : ℕ) : ℝ) * 2 ^ ((e : ℤ) - 1075) :=
            mul_le_mul hM0 hp (by positivity) (by positivity)
          linarith
    · exfalso
      have hn : doubleValue 1 e f ≤ 0 := by
        unfold doubleValue
        split_ifs
        · have : 0 ≤ (f : ℝ) / 2 ^ 52 * (2 : ℝ) ^ (-1022 : ℤ) := by positivity
          rw [pow_one]
          linarith
        · have : 0 ≤ (1 + (f : ℝ) / 2 ^ 52) * (2 : ℝ) ^ ((e : ℤ) - 1023) := by positivity
          rw [pow_one]
          linarith
      linarith

/-- The standard model of one rounding. Let `∘` be any operation (+, −, ×, ÷, or square root
taking one input), computed exactly and then rounded once to a nearest double, and let the exact
result lie in the ordinary (normal) range `2^-1022 ≤ |x ∘ y| ≤` the largest double. Then the
machine's answer is `fl(x ∘ y) = (x ∘ y)(1 + δ)` with `|δ| ≤ u = 2^-53`. -/
theorem standard_model_one_rounding (op : ℝ → ℝ → ℝ) (x y fl : ℝ)
    (hlo : (2 : ℝ) ^ (-1022 : ℤ) ≤ |op x y|) (hhi : |op x y| ≤ largestDouble)
    (hfl : IsNearestDouble fl (op x y)) :
    ∃ δ : ℝ, |δ| ≤ u ∧ fl = op x y * (1 + δ) := by
  have key : ∃ d : ℝ, IsFiniteDouble d ∧ |d - op x y| ≤ u * |op x y| := by
    rcases le_or_gt 0 (op x y) with h | h
    · rw [abs_of_nonneg h] at hlo hhi ⊢
      exact exists_double_near_pos _ hlo hhi
    · rw [abs_of_neg h] at hlo hhi ⊢
      obtain ⟨d, hd, hdt⟩ := exists_double_near_pos _ hlo hhi
      refine ⟨-d, double_neg hd, ?_⟩
      rw [show -d - op x y = -(d - -op x y) by ring, abs_neg]
      exact hdt
  obtain ⟨d, hd, hdt⟩ := key
  have hclose := hfl.2 d hd
  have ht0 : op x y ≠ 0 := by
    intro h0
    rw [h0, abs_zero] at hlo
    have : (0 : ℝ) < 2 ^ (-1022 : ℤ) := by positivity
    linarith
  refine ⟨(fl - op x y) / op x y, ?_, ?_⟩
  · rw [abs_div, div_le_iff₀ (abs_pos.2 ht0)]
    linarith
  · field_simp
    ring

/-- The Sterbenz lemma, a close subtraction is exact: if `x` and `y` are positive doubles with
`y/2 ≤ x ≤ y`, then `y - x` is itself a double, so rounding leaves it unchanged. -/
theorem sterbenz_close_subtraction_exact (x y : ℝ) (hx : IsFiniteDouble x)
    (hy : IsFiniteDouble y) (hx0 : 0 < x) (hy0 : 0 < y) (hle : y / 2 ≤ x) (hxy : x ≤ y) :
    IsFiniteDouble (y - x) := by
  obtain ⟨Mx, Qx, hMx, hQx1, hQx2, rfl⟩ := rep_of_double hx hx0
  obtain ⟨My, Qy, hMy, hQy1, hQy2, rfl⟩ := rep_of_double hy hy0
  rcases le_total Qx Qy with hq | hq
  · -- write y on x's scale: y = (My × 2^k) × 2^Qx
    set k := (Qy - Qx).toNat with hk
    have hk' : ((k : ℕ) : ℤ) = Qy - Qx := Int.toNat_of_nonneg (by omega)
    have hyx : (2 : ℝ) ^ Qy = 2 ^ k * 2 ^ Qx := by
      rw [← zpow_natCast, ← zpow_add₀ two_ne_zero, hk']
      ring_nf
    have hp : (0 : ℝ) < 2 ^ Qx := by positivity
    rw [hyx] at hle hxy ⊢
    have hA : (Mx : ℝ) ≤ My * 2 ^ k := by
      have : (Mx : ℝ) * 2 ^ Qx ≤ (My * 2 ^ k) * 2 ^ Qx := by linarith
      exact le_of_mul_le_mul_right this hp
    have hB : (My : ℝ) * 2 ^ k ≤ 2 * Mx := by
      have : ((My : ℝ) * 2 ^ k) * 2 ^ Qx ≤ (2 * (Mx : ℝ)) * 2 ^ Qx := by linarith
      exact le_of_mul_le_mul_right this hp
    have hA' : Mx ≤ My * 2 ^ k := by exact_mod_cast hA
    have hB' : My * 2 ^ k ≤ 2 * Mx := by exact_mod_cast hB
    have hc : ((My * 2 ^ k - Mx : ℕ) : ℝ) = My * 2 ^ k - Mx := by
      rw [Nat.cast_sub hA']
      push_cast
      ring
    have := double_of_rep (My * 2 ^ k - Mx) Qx (by omega) hQx1 hQx2
    rw [hc] at this
    convert this using 1
    ring
  · -- write x on y's scale: x = (Mx × 2^k) × 2^Qy
    set k := (Qx - Qy).toNat with hk
    have hk' : ((k : ℕ) : ℤ) = Qx - Qy := Int.toNat_of_nonneg (by omega)
    have hxy' : (2 : ℝ) ^ Qx = 2 ^ k * 2 ^ Qy := by
      rw [← zpow_natCast, ← zpow_add₀ two_ne_zero, hk']
      ring_nf
    have hp : (0 : ℝ) < 2 ^ Qy := by positivity
    rw [hxy'] at hle hxy ⊢
    have hA : (Mx : ℝ) * 2 ^ k ≤ My := by
      have : (Mx * 2 ^ k) * 2 ^ Qy ≤ (My : ℝ) * 2 ^ Qy := by linarith
      exact le_of_mul_le_mul_right this hp
    have hA' : Mx * 2 ^ k ≤ My := by exact_mod_cast hA
    have hc : ((My - Mx * 2 ^ k : ℕ) : ℝ) = My - Mx * 2 ^ k := by
      rw [Nat.cast_sub hA']
      push_cast
      ring
    have := double_of_rep (My - Mx * 2 ^ k) Qy (by omega) hQy1 hQy2
    rw [hc] at this
    convert this using 1
    ring

-- The card's whole-number worked examples.

-- c^2 as a whole number: 299792458^2 = 89875517873681764.
example : (299792458 : ℕ) ^ 2 = 89875517873681764 := by norm_num
-- The next double after 1 has exponent field 1023 and fraction field 1: it is 1 + ε_mach.
example : doubleValue 0 1023 1 = 1 + epsMach := by norm_num [doubleValue, epsMach]
-- u is half of machine epsilon.
example : u = epsMach / 2 := by
  rw [u, epsMach, show (-53 : ℤ) = -52 - 1 by norm_num, zpow_sub₀ (by norm_num : (2 : ℝ) ≠ 0)]
  norm_num
-- Ties: 1 + 3u is halfway between 1 + 2u (fraction field 1, odd) and 1 + 4u (fraction field 2,
-- even), so ties to even gives 1 + 4u.
example : doubleValue 0 1023 1 = 1 + 2 * u ∧ doubleValue 0 1023 2 = 1 + 4 * u ∧
    (1 + 3 * u) - (1 + 2 * u) = (1 + 4 * u) - (1 + 3 * u) ∧ 1 % 2 = 1 ∧ 2 % 2 = 0 := by
  refine ⟨?_, ?_, by ring, by norm_num, by norm_num⟩ <;> norm_num [doubleValue, u]
-- Near 1,000,000 the power of two at or below is 2^19, so the gap there is 2^(19 - 52).
example : (2 : ℕ) ^ 19 ≤ 1000000 ∧ 1000000 < (2 : ℕ) ^ 20 := by norm_num
-- The runner: 1 - 3u and 1 - 2u are doubles (exponent field 1022, fraction fields 2^52 - 3
-- and 2^52 - 2).
example : doubleValue 0 1022 (2 ^ 52 - 3) = 1 - 3 * u ∧
    doubleValue 0 1022 (2 ^ 52 - 2) = 1 - 2 * u := by
  constructor <;> norm_num [doubleValue, u]
-- Rounding 1 - z, with z = 25/c^2, to 1 - 3u costs under u relative (about 0.4945u).
example : |(1 - 3 * u) - (1 - 25 / 299792458 ^ 2)| ≤ u * (1 - 25 / 299792458 ^ 2) := by
  norm_num [u, abs_le]
-- Sterbenz for the runner: x = 1 - 2u and y = 1 are within a factor of 2, and the exact
-- difference 2u is the double with exponent field 971 and fraction field 0.
example : (1 : ℝ) / 2 ≤ 1 - 2 * u ∧ 1 - 2 * u ≤ 1 ∧ 1 - (1 - 2 * u) = doubleValue 0 971 0 := by
  norm_num [doubleValue, u]

#print axioms machine_epsilon_is_gap_next_to_one
#print axioms standard_model_one_rounding
#print axioms sterbenz_close_subtraction_exact

end MachineEpsilonCancellation
