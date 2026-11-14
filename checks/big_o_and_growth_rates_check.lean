-- Big-O: halving's worst case on n titles is exactly floor(log2 n) + 1 comparisons, which is Θ(log n), and the six standard growth rates 1, log n, n, n log n, n², 2ⁿ rank strictly, each beaten by the next.
import Mathlib.Analysis.Asymptotics.Theta
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Nat.Log
import Mathlib.Analysis.SpecificLimits.Normed

open Asymptotics Filter

/-- Halving's worst case is exactly ⌊log2 n⌋ + 1 comparisons: if the worst-case count W on m
titles obeys W(0) = 0 and W(m) = 1 + W(⌊m/2⌋) for every m ≥ 1 (one comparison, then the larger
side of ⌊m/2⌋ titles), then W(n) = ⌊log2 n⌋ + 1 for every n ≥ 1. -/
theorem halving_worst_case_eq_floor_log2_add_one (W : ℕ → ℕ) (h0 : W 0 = 0)
    (hstep : ∀ m, 0 < m → W m = 1 + W (m / 2)) :
    ∀ n, 0 < n → W n = Nat.log 2 n + 1 := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro hn
    rw [hstep n hn]
    rcases Nat.lt_or_ge n 2 with h | h
    · have h1 : n = 1 := by omega
      subst h1
      simp [h0]
    · rw [ih (n / 2) (by omega) (by omega), Nat.log_of_one_lt_of_le (by norm_num) h]
      ring

/-- Halving is Θ(log n): its worst case ⌊log2 n⌋ + 1 lies between fixed positive multiples of
log n for all large n. -/
theorem halving_isTheta_log :
    (fun n : ℕ => ((Nat.log 2 n : ℝ) + 1)) =Θ[atTop] (fun n : ℕ => Real.log n) := by
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have key : ∀ n : ℕ, 0 < n → Real.log 2 * (Nat.log 2 n : ℝ) ≤ Real.log n ∧
      Real.log n < Real.log 2 * ((Nat.log 2 n : ℝ) + 1) := by
    intro n hn
    have h1 : ((2 ^ Nat.log 2 n : ℕ) : ℝ) ≤ n := by
      exact_mod_cast Nat.pow_log_le_self 2 hn.ne'
    have h2 : (n : ℝ) < ((2 ^ (Nat.log 2 n + 1) : ℕ) : ℝ) := by
      exact_mod_cast Nat.lt_pow_succ_log_self (by norm_num) n
    push_cast at h1 h2
    constructor
    · have h3 := Real.log_le_log (by positivity) h1
      rw [Real.log_pow] at h3
      linarith
    · have h3 := Real.log_lt_log (by positivity) h2
      rw [Real.log_pow] at h3
      push_cast at h3
      linarith
  constructor
  · apply IsBigO.of_bound (2 / Real.log 2)
    filter_upwards [eventually_ge_atTop 2] with n hn
    have hn0 : 0 < n := by omega
    have hk := (key n hn0).1
    have h2n : Real.log 2 ≤ Real.log n :=
      Real.log_le_log (by norm_num) (by exact_mod_cast hn)
    have hk0 : (0 : ℝ) ≤ (Nat.log 2 n : ℝ) + 1 := by positivity
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg hk0, abs_of_nonneg (by linarith),
      div_mul_eq_mul_div, le_div_iff₀ hl2]
    linarith
  · apply IsBigO.of_bound (Real.log 2)
    filter_upwards [eventually_ge_atTop 1] with n hn
    have hn0 : 0 < n := by omega
    have hk := (key n hn0).2
    have hlog0 : 0 ≤ Real.log n := Real.log_nonneg (by exact_mod_cast hn)
    have hk0 : (0 : ℝ) ≤ (Nat.log 2 n : ℝ) + 1 := by positivity
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg hk0, abs_of_nonneg hlog0]
    linarith

/-- The ladder of six growth rates ranks strictly: 1, log n, n, n log n, n², 2ⁿ, slowest first.
Each rung divided by the one below grows without limit, so each rate is O of the next and
never the reverse. -/
theorem growth_ladder_strict :
    (fun _ : ℕ => (1 : ℝ)) =o[atTop] (fun n : ℕ => Real.log n) ∧
    (fun n : ℕ => Real.log n) =o[atTop] (fun n : ℕ => (n : ℝ)) ∧
    (fun n : ℕ => (n : ℝ)) =o[atTop] (fun n : ℕ => (n : ℝ) * Real.log n) ∧
    (fun n : ℕ => (n : ℝ) * Real.log n) =o[atTop] (fun n : ℕ => (n : ℝ) ^ 2) ∧
    (fun n : ℕ => (n : ℝ) ^ 2) =o[atTop] (fun n : ℕ => (2 : ℝ) ^ n) := by
  have h1 : (fun _ : ℕ => (1 : ℝ)) =o[atTop] (fun n : ℕ => Real.log n) := by
    rw [isLittleO_const_left]
    right
    exact tendsto_norm_atTop_atTop.comp (Real.tendsto_log_atTop.comp tendsto_natCast_atTop_atTop)
  have h2 : (fun n : ℕ => Real.log n) =o[atTop] (fun n : ℕ => (n : ℝ)) :=
    Real.isLittleO_log_id_atTop.comp_tendsto tendsto_natCast_atTop_atTop
  refine ⟨h1, h2, ?_, ?_, ?_⟩
  · simpa using (isBigO_refl (fun n : ℕ => (n : ℝ)) atTop).mul_isLittleO h1
  · simpa [sq] using (isBigO_refl (fun n : ℕ => (n : ℝ)) atTop).mul_isLittleO h2
  · exact isLittleO_pow_const_const_pow_of_one_lt 2 (by norm_num)

-- Halving on a million tracks: 20 comparisons; on two million: 21.
example : Nat.log 2 1000000 + 1 = 20 := by decide
example : Nat.log 2 2000000 + 1 = 21 := by decide
-- Halving on 1,000 and 2,000 tracks (the doubling test): 10 and 11.
example : Nat.log 2 1000 + 1 = 10 := by decide
example : Nat.log 2 2000 + 1 = 11 := by decide
-- The scan does 50,000 times the work of halving at a million tracks.
example : 1000000 / 20 = 50000 := by norm_num
-- Scan costing 2n + 3: within 3n from n = 3, and not at n = 2 (7 against 6).
example : 2 * 3 + 3 ≤ 3 * 3 ∧ ¬ (2 * 2 + 3 ≤ 3 * 2) := by decide
-- Pair check n(n − 1)/2 against 50n: 190 against 1,000 at 20 tracks, equal (5,050) at 101.
example : 20 * 19 / 2 = 190 ∧ 50 * 20 = 1000 := by norm_num
example : 101 * 100 / 2 = 5050 ∧ 50 * 101 = 5050 := by norm_num
-- With c = 1,000, the pair check first exceeds c · n at n = 2,002.
example : 2001 * 2000 / 2 ≤ 1000 * 2001 ∧ 2002 * 2001 / 2 > 1000 * 2002 := by norm_num
-- Pair check at 1,000, 2,000 and a million tracks.
example : 1000 * 999 / 2 = 499500 ∧ 2000 * 1999 / 2 = 1999000 := by norm_num
example : 1000000 * 999999 / 2 = 499999500000 := by norm_num
example : 50 * 1000000 = 50000000 := by norm_num
-- Every subset of 10, 11, 12 tracks: 1,024, 2,048, 4,096; and 2ⁿ = n² at n = 4.
example : 2 ^ 10 = 1024 ∧ 2 ^ 11 = 2048 ∧ 2 ^ 12 = 4096 := by norm_num
example : 2 ^ 4 = 4 ^ 2 := by norm_num
-- The 2ⁿ ÷ n² rung at n = 16: 2¹⁶ = 2⁸ · 16².
example : 2 ^ 16 = 2 ^ 8 * 16 ^ 2 := by norm_num

#print axioms halving_worst_case_eq_floor_log2_add_one
#print axioms halving_isTheta_log
#print axioms growth_ladder_strict
