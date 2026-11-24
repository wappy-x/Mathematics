-- Robustness: a degree list has mean excess degree above 1 exactly when its Molloy–Reed sum is positive, random failure keeps the branching slope above 1 exactly while the share removed is below 1 − 1/κ, and the Poisson giant-component equation S = 1 − e^(−cS) has a positive root exactly when c > 1.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Field.Basic

open Finset

/-- **The Molloy–Reed condition, as arithmetic on the degree list.** Let `p k` be the share of
people with exactly `k` friends, nobody having more than `K`, and write
`⟨k⟩ = ∑ k p_k` and `⟨k²⟩ = ∑ k² p_k`, with `⟨k⟩ > 0`. Then the mean excess degree
`κ = (⟨k²⟩ − ⟨k⟩)/⟨k⟩` is above 1 exactly when `⟨k²⟩ − 2⟨k⟩ > 0`, and that holds exactly when
`∑ k (k − 2) p_k > 0`. -/
theorem molloy_reed_condition (p : ℕ → ℝ) (K : ℕ)
    (hmean : 0 < ∑ k ∈ range (K + 1), (k : ℝ) * p k) :
    (1 < ((∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k) - ∑ k ∈ range (K + 1), (k : ℝ) * p k) /
          ∑ k ∈ range (K + 1), (k : ℝ) * p k ↔
        0 < (∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k) - 2 * ∑ k ∈ range (K + 1), (k : ℝ) * p k) ∧
    (0 < (∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k) - 2 * ∑ k ∈ range (K + 1), (k : ℝ) * p k ↔
        0 < ∑ k ∈ range (K + 1), (k : ℝ) * ((k : ℝ) - 2) * p k) := by
  set A := ∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k
  set B := ∑ k ∈ range (K + 1), (k : ℝ) * p k
  have hsum : ∑ k ∈ range (K + 1), (k : ℝ) * ((k : ℝ) - 2) * p k = A - 2 * B := by
    simp only [A, B, mul_sum, ← sum_sub_distrib]
    refine sum_congr rfl fun k _ => ?_
    ring
  refine ⟨?_, ?_⟩
  · rw [lt_div_iff₀ hmean]
    constructor <;> intro h <;> linarith
  · rw [hsum]

/-- **Random failure: the threshold `f_c = 1 − 1/κ`.** Every person stays with the same chance
`φ = 1 − f`. The branching slope of the survivors, `F₁'(1) = (1/⟨k⟩) ∑ k (k − 1) p_k φ`, equals
`φ κ`; and when `⟨k⟩ > 0` and `κ > 0` it is above 1 exactly when the share removed `f` is below
`1 − 1/κ`. -/
theorem random_failure_threshold (p : ℕ → ℝ) (K : ℕ) (f : ℝ)
    (hmean : 0 < ∑ k ∈ range (K + 1), (k : ℝ) * p k)
    (hkappa : 0 < ((∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k) - ∑ k ∈ range (K + 1), (k : ℝ) * p k) /
          ∑ k ∈ range (K + 1), (k : ℝ) * p k) :
    (∑ k ∈ range (K + 1), (k : ℝ) * ((k : ℝ) - 1) * p k * (1 - f)) /
          ∑ k ∈ range (K + 1), (k : ℝ) * p k =
        (1 - f) * (((∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k) - ∑ k ∈ range (K + 1), (k : ℝ) * p k) /
          ∑ k ∈ range (K + 1), (k : ℝ) * p k) ∧
    (1 < (∑ k ∈ range (K + 1), (k : ℝ) * ((k : ℝ) - 1) * p k * (1 - f)) /
          ∑ k ∈ range (K + 1), (k : ℝ) * p k ↔
        f < 1 - 1 / (((∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k) - ∑ k ∈ range (K + 1), (k : ℝ) * p k) /
          ∑ k ∈ range (K + 1), (k : ℝ) * p k)) := by
  set A := ∑ k ∈ range (K + 1), (k : ℝ) ^ 2 * p k
  set B := ∑ k ∈ range (K + 1), (k : ℝ) * p k
  have hsum : ∑ k ∈ range (K + 1), (k : ℝ) * ((k : ℝ) - 1) * p k * (1 - f) =
      (1 - f) * (A - B) := by
    simp only [A, B, mul_sum, ← sum_sub_distrib]
    refine sum_congr rfl fun k _ => ?_
    ring
  have h1 : (∑ k ∈ range (K + 1), (k : ℝ) * ((k : ℝ) - 1) * p k * (1 - f)) / B =
      (1 - f) * ((A - B) / B) := by
    rw [hsum, mul_div_assoc]
  refine ⟨h1, ?_⟩
  rw [h1]
  set κ := (A - B) / B
  have e : 1 - 1 / κ - f = ((1 - f) * κ - 1) / κ := by
    field_simp
    ring
  constructor
  · intro h
    have : 0 < 1 - 1 / κ - f := by rw [e]; exact div_pos (by linarith) hkappa
    linarith
  · intro h
    have h2 : 0 < ((1 - f) * κ - 1) / κ := by rw [← e]; linarith
    have := (div_pos_iff_of_pos_right hkappa).1 h2
    linarith

/-- **The Poisson giant: `S = 1 − e^(−cS)` has a positive root exactly when `c > 1`.** For Poisson
degrees with mean `c`, the share `S` of people in the giant solves `S = 1 − e^(−cS)`. A root with
`S > 0` (a giant) exists exactly when `c > 1`; for `c ≤ 1` the only root is `S = 0`. -/
theorem poisson_giant_root_iff (c : ℝ) :
    (∃ S : ℝ, 0 < S ∧ S = 1 - Real.exp (-(c * S))) ↔ 1 < c := by
  constructor
  · rintro ⟨S, hS, hroot⟩
    have hcS : -(c * S) ≠ 0 := by
      intro h0
      rw [h0, Real.exp_zero] at hroot
      linarith
    have := Real.add_one_lt_exp hcS
    have hlt : S < c * S := by linarith
    by_contra hc
    have hc' : c ≤ 1 := not_lt.mp hc
    nlinarith
  · intro hc
    have hc0 : 0 < c := by linarith
    set ε := (c - 1) / (2 * c) with hε
    have hεpos : 0 < ε := div_pos (by linarith) (by linarith)
    have hεle : ε ≤ 1 := by
      rw [hε, div_le_one (by linarith)]
      linarith
    set g : ℝ → ℝ := fun S => 1 - Real.exp (-(c * S)) - S with hg
    have hgc : Continuous g := by
      simp only [hg]; fun_prop
    have hg1 : g 1 < 0 := by
      simp only [hg]
      have := Real.exp_pos (-(c * 1))
      linarith
    have hgε : 0 < g ε := by
      simp only [hg]
      have hx : 0 < c * ε := mul_pos hc0 hεpos
      have hle := Real.add_one_le_exp (c * ε)
      have hexp : Real.exp (-(c * ε)) = 1 / Real.exp (c * ε) := by
        rw [Real.exp_neg, one_div]
      have hbound : Real.exp (-(c * ε)) ≤ 1 / (c * ε + 1) := by
        rw [hexp]
        exact one_div_le_one_div_of_le (by linarith) hle
      have hcε : c * ε = (c - 1) / 2 := by
        rw [hε]; field_simp
      rw [hcε] at hbound ⊢
      have key : 1 / ((c - 1) / 2 + 1) < 1 - ε := by
        rw [hε, div_lt_iff₀ (by linarith)]
        field_simp
        nlinarith
      linarith
    obtain ⟨S, hSmem, hS0⟩ :=
      intermediate_value_Icc' hεle hgc.continuousOn ⟨hg1.le, hgε.le⟩
    refine ⟨S, lt_of_lt_of_le hεpos hSmem.1, ?_⟩
    simp only [hg] at hS0
    linarith

-- Worked numbers, by hand, Poisson with c = 4: ⟨k²⟩ = c + c² = 20, the Molloy–Reed sum
-- 20 − 2·4 = 12, κ = (20 − 4)/4 = 4, the random-failure threshold 1 − 1/4 = 3/4,
-- and with half removed the survivors' mean is 4 × 1/2 = 2.
example : (4 : ℚ) + 4 ^ 2 = 20 := by norm_num
example : (20 : ℚ) - 2 * 4 = 12 := by norm_num
example : ((20 : ℚ) - 4) / 4 = 4 := by norm_num
example : (1 : ℚ) - 1 / 4 = 3 / 4 := by norm_num
example : (4 : ℚ) * (1 / 2) = 2 := by norm_num

-- Each person adds k(k − 2): 1 friend adds −1, 2 friends add 0, 3 friends add 3.
example : (1 : ℤ) * (1 - 2) = -1 ∧ (2 : ℤ) * (2 - 2) = 0 ∧ (3 : ℤ) * (3 - 2) = 3 := by decide

-- 90% with 1 friend, 10% with 3: mean degree 6/5 (above 1) but Molloy–Reed sum −3/5.
example :
    let p : ℕ → ℚ := fun k => if k = 1 then 9 / 10 else if k = 3 then 1 / 10 else 0
    (∑ k ∈ range 4, (k : ℚ) * p k = 6 / 5) ∧
      ∑ k ∈ range 4, (k : ℚ) * ((k : ℚ) - 2) * p k = -3 / 5 := by
  norm_num [Finset.sum_range_succ]

-- The Poisson network: 9,958 friendships among 5,000 people give mean degree 2·9958/5000 = 3.9832.
example : (2 * 9958 : ℚ) / 5000 = 39832 / 10000 := by norm_num

-- The thin town's attack threshold: 81 of 5,000 people is 1.62%.
example : (81 : ℚ) / 5000 = 162 / 10000 := by norm_num

#print axioms molloy_reed_condition
#print axioms random_failure_threshold
#print axioms poisson_giant_root_iff
