-- Paraproducts: Bony's split of a product of two band sums into low-high, high-low and high-high piles is exact, and a low-high term stays within one band of its high factor.
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.Field.Power
import Mathlib.Basic.Complex.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
import Mathlib.Tactic.Linarith

open Finset

/-- Bony's split is exact. Cut two signals `f` and `g` into octave pieces,
`f = ∑ Δf j` and `g = ∑ Δg k` (index `i` stands for band `i - 1`, so index 0 is
the constant part). Then `f g` is the low-high pile `∑ₖ S_{k-2} f · Δ_k g`, plus
the high-low pile `∑ⱼ Δ_j f · S_{j-2} g`, plus the high-high pile of all pairs of
bands at most one octave apart; here `S_{k-2} f` is the sum of `f`'s bands `j`
with `j + 2 ≤ k`. No pair of bands is missed or counted twice. -/
theorem bony_split_exact (n : ℕ) (Δf Δg : ℕ → ℝ → ℂ) (f g : ℝ → ℂ)
    (hf : f = ∑ j ∈ range n, Δf j) (hg : g = ∑ k ∈ range n, Δg k) :
    f * g =
      (∑ k ∈ range n, (∑ j ∈ (range n).filter (fun j => j + 2 ≤ k), Δf j) * Δg k)
      + (∑ j ∈ range n, Δf j * (∑ k ∈ (range n).filter (fun k => k + 2 ≤ j), Δg k))
      + (∑ j ∈ range n, ∑ k ∈ (range n).filter (fun k => k ≤ j + 1 ∧ j ≤ k + 1),
          Δf j * Δg k) := by
  subst hf hg
  rw [Finset.sum_mul_sum]
  simp_rw [Finset.sum_mul, Finset.mul_sum, Finset.sum_filter]
  rw [Finset.sum_comm (s := range n) (t := range n) (f := fun k j => if j + 2 ≤ k then Δf j * Δg k else 0)]
  rw [← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun k _ => ?_
  split_ifs <;> first | omega | simp

/-- Where a low-high term lives. If the high factor's frequency `η` is in octave
band `j` (`2^j ≤ |η| < 2^(j+1)` Hz) and the low factor's frequency `ξ` is below
`2^(j-1)` Hz (bands up to `j - 2`), then the product's frequency `ξ + η` satisfies
`2^(j-1) < |ξ + η| < 2^(j+1) + 2^(j-1)`, so it lies in bands `j - 1` to `j + 1`. -/
theorem low_high_term_stays_near_band (j : ℤ) (ξ η : ℝ)
    (hη₁ : (2 : ℝ) ^ j ≤ |η|) (hη₂ : |η| < (2 : ℝ) ^ (j + 1))
    (hξ : |ξ| < (2 : ℝ) ^ (j - 1)) :
    (2 : ℝ) ^ (j - 1) < |ξ + η| ∧ |ξ + η| < (2 : ℝ) ^ (j + 1) + (2 : ℝ) ^ (j - 1) := by
  have h2 : (2 : ℝ) ^ j = 2 * (2 : ℝ) ^ (j - 1) := by
    rw [← zpow_one_add₀ (by norm_num : (2:ℝ) ≠ 0)]; ring_nf
  constructor
  · have := abs_sub_abs_le_abs_sub η (-ξ)
    rw [sub_neg_eq_add, add_comm η ξ, abs_neg] at this
    linarith
  · have := abs_add_le ξ η
    linarith

/-- Where a high-high term lives. If `|ξ| < 2^(j+1)` and `|η| < 2^(k+1)` with
`k ≤ j ≤ k + 1`, then `|ξ + η| < 2^(j+1) + 2^(k+1) ≤ 2^(j+2)`: the output rises at
most one band, and there is no lower limit. -/
theorem high_high_term_upper_band (j k : ℤ) (ξ η : ℝ)
    (hkj : k ≤ j) (hjk : j ≤ k + 1)
    (hξ : |ξ| < (2 : ℝ) ^ (j + 1)) (hη : |η| < (2 : ℝ) ^ (k + 1)) :
    |ξ + η| < (2 : ℝ) ^ (j + 1) + (2 : ℝ) ^ (k + 1) ∧
      (2 : ℝ) ^ (j + 1) + (2 : ℝ) ^ (k + 1) ≤ (2 : ℝ) ^ (j + 2) := by
  refine ⟨lt_of_le_of_lt (abs_add_le ξ η) (add_lt_add hξ hη), ?_⟩
  have h2 : (2 : ℝ) ^ (j + 2) = 2 * (2 : ℝ) ^ (j + 1) := by
    rw [← zpow_one_add₀ (by norm_num : (2:ℝ) ≠ 0)]; ring_nf
  have h3 : (2 : ℝ) ^ (k + 1) ≤ (2 : ℝ) ^ (j + 1) :=
    zpow_le_zpow_right₀ (by norm_num) (by omega)
  linarith

-- Worked numbers: the whistle (3,500 Hz) is in band 11 and the bass (55 Hz) in band 5.
example : 2 ^ 11 ≤ 3500 ∧ 3500 < 2 ^ 12 := by norm_num
example : 2 ^ 5 ≤ 55 ∧ 55 < 2 ^ 6 := by norm_num
-- 11 ≥ 5 + 2: the whistle is the high factor, so the product is in the high-low pile.
example : 5 + 2 ≤ 11 := by norm_num
-- The product's lines, 3,500 - 55 and 3,500 + 55 Hz, both lie in band 11.
example : 3500 - 55 = 3445 ∧ 3500 + 55 = 3555 := by norm_num
example : 2 ^ 11 ≤ 3445 ∧ 3555 < 2 ^ 12 := by norm_num
-- Each line has height 1/4 V² and mean square (1/4)²/2 = 1/32; the product's is 1/16.
example : ((1 : ℚ) / 2 * 1 / 2) ^ 2 / 2 = 1 / 32 := by norm_num
example : (1 : ℚ) / 32 + 1 / 32 = 1 / 16 := by norm_num
-- Two tracks: the bass (band 5) times the A (440 Hz, band 8) gives 385 and 495 Hz, in band 8.
example : 2 ^ 8 ≤ 440 ∧ 440 < 2 ^ 9 := by norm_num
example : 440 - 55 = 385 ∧ 440 + 55 = 495 ∧ 2 ^ 8 ≤ 385 ∧ 495 < 2 ^ 9 := by norm_num
-- 3,500 and 3,000 Hz are both band 11; they give 500 Hz (band 8) and 6,500 Hz (band 12).
example : 2 ^ 11 ≤ 3000 ∧ 3000 < 2 ^ 12 := by norm_num
example : 3500 - 3000 = 500 ∧ 2 ^ 8 ≤ 500 ∧ 500 < 2 ^ 9 := by norm_num
example : 3500 + 3000 = 6500 ∧ 2 ^ 12 ≤ 6500 ∧ 6500 < 2 ^ 13 := by norm_num
-- Line mean squares: bass x A gives (1 · 3/5 / 2)²/2 = 9/200 V⁴ per line.
example : ((1 : ℚ) * (3 / 5) / 2) ^ 2 / 2 = 9 / 200 := by norm_num
example : ((1 : ℚ) * (2 / 5) / 2) ^ 2 / 2 = 1 / 50 := by norm_num
example : ((1 : ℚ) / 2 * (3 / 5) / 2) ^ 2 / 2 = 9 / 800 := by norm_num
example : ((1 : ℚ) / 2 * (2 / 5) / 2) ^ 2 / 2 = 1 / 200 := by norm_num
-- The piles hold 13/100, 9/400 and 1/100 V⁴, adding to the total 13/80 V⁴.
example : (2 : ℚ) * (9 / 200) + 2 * (1 / 50) = 13 / 100 := by norm_num
example : (2 : ℚ) * (9 / 800) = 9 / 400 ∧ (2 : ℚ) * (1 / 200) = 1 / 100 := by norm_num
example : (13 : ℚ) / 100 + 9 / 400 + 1 / 100 = 13 / 80 := by norm_num
-- Dropping the high-high pile keeps 61/400 of 13/80 V⁴.
example : (13 : ℚ) / 100 + 9 / 400 = 61 / 400 ∧ (13 : ℚ) / 80 - 61 / 400 = 1 / 100 := by norm_num

#print axioms bony_split_exact
#print axioms low_high_term_stays_near_band
#print axioms high_high_term_upper_band
