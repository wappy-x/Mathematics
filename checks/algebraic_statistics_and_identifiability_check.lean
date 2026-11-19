-- Algebraic statistics: the two-coin mixture's chances always add to 1 and make the 3-by-3 Hankel determinant zero, and off the bad set the only parameter points giving the same chances are the true coins and the same coins with labels swapped.
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Data.Fin.VecNotation

namespace AlgebraicStatisticsAndIdentifiability

open Matrix

/-! Setting. A parameter point is `θ = (π, a, b)`: with chance `π` the dealer picks coin A
(heads chance `a`), otherwise coin B (heads chance `b`), and flips it `n` times.
`seqChance n θ k` is the chance of one given sequence with `k` heads (the card's `q_k`), and
`twoCoinMap n θ k = (n choose k) * seqChance n θ k` is the chance of exactly `k` heads (the
card's `p_k`). `twoCoinMap n` is the parametrisation `φ`. -/

/-- The chance of one given sequence of `n` flips with `k` heads: the card's `q_k`. -/
def seqChance {R : Type*} [CommRing R] (n : ℕ) (θ : R × R × R) (k : ℕ) : R :=
  θ.1 * θ.2.1 ^ k * (1 - θ.2.1) ^ (n - k) + (1 - θ.1) * θ.2.2 ^ k * (1 - θ.2.2) ^ (n - k)

/-- The parametrisation `φ`: the chance of exactly `k` heads in `n` flips, the card's `p_k`. -/
def twoCoinMap {R : Type*} [CommRing R] (n : ℕ) (θ : R × R × R) : Fin (n + 1) → R :=
  fun k => (n.choose k : R) * seqChance n θ k

/-- The card's Hankel matrix `H` of the sequence chances `q_0, …, q_4`. -/
def hankel {R : Type*} [CommRing R] (q : ℕ → R) : Matrix (Fin 3) (Fin 3) R :=
  !![q 0, q 1, q 2; q 1, q 2, q 3; q 2, q 3, q 4]

/-- The model's equations hold everywhere on the model: for every parameter point
`(π, a, b)`, the five chances of 0 to 4 heads add to 1, and the 3-by-3 Hankel determinant
of the sequence chances `q_k = p_k / (4 choose k)` is zero. -/
theorem model_satisfies_sum_rule_and_hankel_det {R : Type*} [CommRing R] (θ : R × R × R) :
    (∑ k : Fin 5, twoCoinMap 4 θ k = 1) ∧ (hankel (seqChance 4 θ)).det = 0 := by
  refine ⟨?_, ?_⟩
  · simp only [Fin.sum_univ_five, twoCoinMap, seqChance]
    simp [Nat.choose]
    ring
  · simp [hankel, det_fin_three, seqChance]
    ring

/-- Identifiability up to label swapping: if the parameters avoid the bad set (`a ≠ b`,
`π ≠ 0`, `π ≠ 1`, `a ≠ 1`, `b ≠ 1`), then the fibre of the 4-flip two-coin map over the
chances of `(π, a, b)` has exactly two points: the true coins `(π, a, b)` and the same coins
with their labels swapped, `(1 - π, b, a)`. -/
theorem two_coin_mixture_identifiable_up_to_label_swap (π a b : ℚ) (hab : a ≠ b)
    (hπ0 : π ≠ 0) (hπ1 : π ≠ 1) (ha : a ≠ 1) (hb : b ≠ 1) :
    twoCoinMap 4 ⁻¹' {twoCoinMap 4 (π, a, b)} = {(π, a, b), (1 - π, b, a)} := by
  ext ⟨p', a', b'⟩
  simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_insert_iff, Prod.mk.injEq]
  constructor
  · intro h
    have h0 := congrFun h 0
    have h1 := congrFun h 1
    have h2 := congrFun h 2
    have h3 := congrFun h 3
    have h4 := congrFun h 4
    simp [twoCoinMap, seqChance, Nat.choose] at h0 h1 h2 h3 h4
    have hm1 : p' * a' + (1 - p') * b' = π * a + (1 - π) * b := by
      linear_combination h1 + 3 * h2 + 3 * h3 + h4
    have hm2 : p' * a' ^ 2 + (1 - p') * b' ^ 2 = π * a ^ 2 + (1 - π) * b ^ 2 := by
      linear_combination h2 + 2 * h3 + h4
    have hm3 : p' * a' ^ 3 + (1 - p') * b' ^ 3 = π * a ^ 3 + (1 - π) * b ^ 3 := by
      linear_combination h3 + h4
    have ka : π * ((a - b) * ((a - a') * (a - b'))) = 0 := by
      linear_combination (-1 : ℚ) * hm3 + (a' + b' + b) * hm2 - (a' * b' + a' * b + b' * b) * hm1
    have kb : (1 - π) * ((b - a) * ((b - a') * (b - b'))) = 0 := by
      linear_combination (-1 : ℚ) * hm3 + (a' + b' + a) * hm2 - (a' * b' + a' * a + b' * a) * hm1
    have hπ1' : (1 - π) ≠ 0 := sub_ne_zero.mpr (Ne.symm hπ1)
    have hab' : a - b ≠ 0 := sub_ne_zero.mpr hab
    have hba' : b - a ≠ 0 := sub_ne_zero.mpr (Ne.symm hab)
    rcases mul_eq_zero.mp ka with h | h
    · exact absurd h hπ0
    rcases mul_eq_zero.mp h with h | h
    · exact absurd h hab'
    rcases mul_eq_zero.mp kb with h' | h'
    · exact absurd h' hπ1'
    rcases mul_eq_zero.mp h' with h' | h'
    · exact absurd h' hba'
    rcases mul_eq_zero.mp h with ha' | hb'
    · have ea : a' = a := (sub_eq_zero.mp ha').symm
      rcases mul_eq_zero.mp h' with hb1 | hb1
      · exact absurd ((sub_eq_zero.mp hb1).trans ea) (Ne.symm hab)
      have eb : b' = b := (sub_eq_zero.mp hb1).symm
      left
      rw [ea, eb] at hm1
      refine ⟨?_, ea, eb⟩
      have : (p' - π) * (a - b) = 0 := by linear_combination hm1
      rcases mul_eq_zero.mp this with h5 | h5
      · exact sub_eq_zero.mp h5
      · exact absurd h5 hab'
    · have eb : b' = a := (sub_eq_zero.mp hb').symm
      rcases mul_eq_zero.mp h' with hb1 | hb1
      · have ea : a' = b := (sub_eq_zero.mp hb1).symm
        right
        rw [ea, eb] at hm1
        refine ⟨?_, ea, eb⟩
        have : (p' - (1 - π)) * (b - a) = 0 := by linear_combination hm1
        rcases mul_eq_zero.mp this with h5 | h5
        · exact sub_eq_zero.mp h5
        · exact absurd h5 hba'
      · exact absurd ((sub_eq_zero.mp hb1).trans eb).symm hab
  · rintro (⟨rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl⟩)
    · rfl
    · funext k
      fin_cases k <;> simp [twoCoinMap, seqChance, Nat.choose] <;> ring

/-- The equations alone are not enough: the chances `(1, 12, 48, 72, 28) / 161` add to 1 and
make the Hankel determinant zero, yet no real parameter point produces them. -/
theorem complex_coins_point_not_in_real_model :
    ∀ θ : ℝ × ℝ × ℝ, twoCoinMap 4 θ ≠ ![1 / 161, 12 / 161, 48 / 161, 72 / 161, 28 / 161] := by
  rintro ⟨π, a, b⟩ h
  have h0 := congrFun h 0
  have h1 := congrFun h 1
  have h2 := congrFun h 2
  have h3 := congrFun h 3
  have h4 := congrFun h 4
  simp [twoCoinMap, seqChance, Nat.choose] at h0 h1 h2 h3 h4
  have hm1 : π * a + (1 - π) * b = 109 / 161 := by
    linear_combination h1 / 4 + h2 / 2 + 3 * h3 / 4 + h4
  have hm2 : π * a ^ 2 + (1 - π) * b ^ 2 = 72 / 161 := by
    linear_combination h2 / 6 + h3 / 2 + h4
  have hm3 : π * a ^ 3 + (1 - π) * b ^ 3 = 46 / 161 := by
    linear_combination h3 / 4 + h4
  have e1 : 72 - 109 * (a + b) + 161 * (a * b) = 0 := by
    linear_combination (-161 : ℝ) * hm2 + 161 * (a + b) * hm1
  have e2 : 46 - 72 * (a + b) + 109 * (a * b) = 0 := by
    linear_combination (-161 : ℝ) * hm3 + 161 * (a + b) * hm2 - 161 * (a * b) * hm1
  have hs : a + b = 26 / 17 := by linear_combination (-(109 : ℝ) / 289) * e1 + 161 / 289 * e2
  have hr : a * b = 10 / 17 := by linear_combination (-(72 : ℝ) / 289) * e1 + 109 / 289 * e2
  have : (17 * a - 13) ^ 2 + 1 = 0 := by linear_combination 289 * a * hs - 289 * hr
  nlinarith [sq_nonneg (17 * a - 13)]

/-! The card's worked numbers. -/

-- The dealer's chances: π = 2/5, a = 4/5, b = 1/2, 4 flips.
example : twoCoinMap 4 ((2 / 5 : ℚ), 4 / 5, 1 / 2)
    = ![1907 / 50000, 2003 / 12500, 7161 / 25000, 3923 / 12500, 10067 / 50000] := by
  funext k
  fin_cases k <;> simp [twoCoinMap, seqChance, Nat.choose] <;> norm_num

-- The sequence chances q_0, …, q_4 in units of 1/50000.
example : (List.range 5).map (fun k => seqChance 4 ((2 / 5 : ℚ), 4 / 5, 1 / 2) k * 50000)
    = [1907, 2003, 2387, 3923, 10067] := by
  simp [List.range_succ, seqChance]
  norm_num

-- The label swap gives the same chances.
example : twoCoinMap 4 ((3 / 5 : ℚ), 1 / 2, 4 / 5) = twoCoinMap 4 ((2 / 5 : ℚ), 4 / 5, 1 / 2) := by
  funext k
  fin_cases k <;> simp [twoCoinMap, seqChance] <;> norm_num

-- Worked numbers by hand, in units of 1/50000: the 2-by-2 system, s = 5, r = 4, third equation 0.
example : 1907 * 2387 - 2003 ^ 2 = 540000 ∧ 1907 * 3923 - 2003 * 2387 = 2700000 ∧
    2003 * 3923 - 2387 ^ 2 = 2160000 ∧ 5 * 3923 - 4 * 2387 - 10067 = 0 := by
  norm_num

-- The Hankel determinant at the dealer's point is 0.
example : (hankel (seqChance 4 ((2 / 5 : ℚ), 4 / 5, 1 / 2))).det = 0 := by
  simp [hankel, det_fin_three, seqChance]
  norm_num

-- The eliminant 10 a^2 - 13 a + 4 has discriminant 9 and roots 4/5 and 1/2.
example : (13 : ℤ) ^ 2 - 4 * 10 * 4 = 9 ∧ 10 * (4 / 5 : ℚ) ^ 2 - 13 * (4 / 5) + 4 = 0 ∧
    10 * (1 / 2 : ℚ) ^ 2 - 13 * (1 / 2) + 4 = 0 := by
  norm_num

-- π back from α: (2/3125) * 5^4 = 2/5, and for the other point (3/80) * 2^4 = 3/5.
example : (2 / 3125 : ℚ) * 5 ^ 4 = 2 / 5 ∧ (3 / 80 : ℚ) * 2 ^ 4 = 3 / 5 := by
  norm_num

-- What breaks, 2 flips: (27/125, 9/10, 19/35) gives the dealer's 83/500, 107/250, 203/500.
example : twoCoinMap 2 ((27 / 125 : ℚ), 9 / 10, 19 / 35) = ![83 / 500, 107 / 250, 203 / 500] ∧
    twoCoinMap 2 ((2 / 5 : ℚ), 4 / 5, 1 / 2) = ![83 / 500, 107 / 250, 203 / 500] := by
  refine ⟨?_, ?_⟩ <;> (funext k; fin_cases k <;> simp [twoCoinMap, seqChance, Nat.choose] <;> norm_num)

-- What breaks, complex coins: (1, 12, 48, 72, 28)/161 adds to 1 and gives det H = 0;
-- the odds equation t^2 - 6 t + 10 has discriminant -4.
example : (1 + 12 + 48 + 72 + 28 : ℚ) / 161 = 1 ∧
    (hankel (fun k => ([1, 3, 8, 18, 28] : List ℚ).getD k 0 / 161)).det = 0 ∧
    (6 : ℤ) ^ 2 - 4 * 10 = -4 := by
  refine ⟨by norm_num, ?_, by norm_num⟩
  simp [hankel, det_fin_three]
  norm_num

-- What breaks, binomials left in: the Hankel determinant of the p_k is not 0.
example : (hankel (fun k => if h : k < 5 then twoCoinMap 4 ((2 / 5 : ℚ), 4 / 5, 1 / 2) ⟨k, h⟩
    else 0)).det = -3546530603 / 2500000000000 := by
  simp [hankel, det_fin_three, twoCoinMap, seqChance, Nat.choose]
  norm_num

#print axioms model_satisfies_sum_rule_and_hankel_det
#print axioms two_coin_mixture_identifiable_up_to_label_swap
#print axioms complex_coins_point_not_in_real_model

end AlgebraicStatisticsAndIdentifiability
