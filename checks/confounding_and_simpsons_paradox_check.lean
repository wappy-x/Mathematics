-- Confounding: a group's pooled rate is its stratum rates averaged with its own mix as weights, a sex-blind process with two kinds of stratum still shows a gap equal to the mix difference times the rate difference, reweighting applicants gives the standardised rate, and the Berkeley 1973 counts reverse exactly as the card says.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Finset

/-- The pooled-rate identity (the law of total probability in counts). For one group, let
`n d` be its applicants in stratum `d` and `a d` the number of them admitted. The group's pooled
rate, all admitted over all applicants, equals the average of its stratum rates `a d / n d`,
weighted by its own mix `n d / (total applicants)`. -/
theorem pooled_rate_eq_mix_weighted_average {ι : Type*} (s : Finset ι) (n a : ι → ℕ)
    (ha : ∀ d ∈ s, a d ≤ n d) :
    (∑ d ∈ s, (a d : ℝ)) / (∑ d ∈ s, (n d : ℝ)) =
      ∑ d ∈ s, ((n d : ℝ) / (∑ e ∈ s, (n e : ℝ))) * ((a d : ℝ) / (n d : ℝ)) := by
  rw [Finset.sum_div]
  apply Finset.sum_congr rfl
  intro d hd
  by_cases h : (n d : ℝ) = 0
  · have hn : n d = 0 := by exact_mod_cast h
    have : a d = 0 := by have := ha d hd; omega
    simp [h, this]
  · rw [div_mul_div_comm, mul_comm (n d : ℝ) (a d : ℝ), mul_div_mul_right _ _ h]

/-- A confounder makes a gap from nothing. With two kinds of stratum, open and selective, each
group's mix adds to one. If both groups have the same rate inside each kind (`rO` open, `rS`
selective), the pooled gap, women's pooled rate minus men's, is the difference in selective
shares times the difference in the two kinds' rates. -/
theorem confounder_gap_two_kinds (wWO wWS wMO wMS rO rS : ℝ)
    (hW : wWO + wWS = 1) (hM : wMO + wMS = 1) :
    (wWO * rO + wWS * rS) - (wMO * rO + wMS * rS) = (wWS - wMS) * (rS - rO) := by
  obtain rfl : wWO = 1 - wWS := by linarith
  obtain rfl : wMO = 1 - wMS := by linarith
  ring

/-- Reweighting applicants gives the standardised rate. Take any common mix `w` that adds to one,
and a group with `n d > 0` applicants in every stratum, `a d` of them admitted. Give each of its
applicants in stratum `d` the weight `w d / (n d / N)`, where `N` is the group's total. Then the
group's weighted admission rate equals its standardised rate, the sum of `w d` times `a d / n d`. -/
theorem reweighted_rate_eq_standardised_rate {ι : Type*} (s : Finset ι) (w : ι → ℝ)
    (n a : ι → ℕ) (hw : ∑ d ∈ s, w d = 1) (hn : ∀ d ∈ s, 0 < n d) :
    let N : ℝ := ∑ d ∈ s, (n d : ℝ)
    let wt : ι → ℝ := fun d => w d / ((n d : ℝ) / N)
    (∑ d ∈ s, (a d : ℝ) * wt d) / (∑ d ∈ s, (n d : ℝ) * wt d) =
      ∑ d ∈ s, w d * ((a d : ℝ) / (n d : ℝ)) := by
  intro N wt
  have hne : s.Nonempty := by
    rcases Finset.eq_empty_or_nonempty s with h | h
    · rw [h, Finset.sum_empty] at hw; norm_num at hw
    · exact h
  have hNpos : 0 < N := by
    obtain ⟨d0, hd0⟩ := hne
    have h0 : (n d0 : ℝ) ≤ N :=
      Finset.single_le_sum (f := fun d => (n d : ℝ)) (fun d _ => Nat.cast_nonneg _) hd0
    have h1 : (0 : ℝ) < n d0 := by exact_mod_cast hn d0 hd0
    linarith
  have hN : N ≠ 0 := hNpos.ne'
  have h1 : ∑ d ∈ s, (a d : ℝ) * wt d = N * ∑ d ∈ s, w d * ((a d : ℝ) / (n d : ℝ)) := by
    rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro d hd
    have : (n d : ℝ) ≠ 0 := by have := hn d hd; positivity
    simp only [wt]
    field_simp
  have h2 : ∑ d ∈ s, (n d : ℝ) * wt d = N := by
    rw [← mul_one N, ← hw, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro d hd
    have : (n d : ℝ) ≠ 0 := by have := hn d hd; positivity
    simp only [wt]
    field_simp
  rw [h1, h2, mul_div_cancel_left₀ _ hN]

/-! ### The card's worked numbers, as exact fractions of the Berkeley 1973 counts
Counts are (men admitted / men applied, women admitted / women applied).
Departments A 512/825, 89/108; B 353/560, 17/25; C 120/325, 202/593; D 138/417, 131/375;
E 53/191, 94/393; F 22/373, 24/341. Open = A and B; selective = C to F. -/

-- The two kinds and the pool add up from the six departments; 4,526 applicants in all.
example :
    512 + 353 = 865 ∧ 825 + 560 = 1385 ∧ 89 + 17 = 106 ∧ 108 + 25 = 133 ∧
    120 + 138 + 53 + 22 = 333 ∧ 325 + 417 + 191 + 373 = 1306 ∧
    202 + 131 + 94 + 24 = 451 ∧ 593 + 375 + 393 + 341 = 1702 ∧
    865 + 333 = 1198 ∧ 1385 + 1306 = 2691 ∧ 106 + 451 = 557 ∧ 133 + 1702 = 1835 ∧
    2691 + 1835 = 4526 := by
  norm_num

-- Simpson's paradox at Berkeley: women ahead in the open kind and in the selective kind,
-- yet behind overall.
example :
    (865 : ℚ) / 1385 < 106 / 133 ∧ (333 : ℚ) / 1306 < 451 / 1702 ∧
    (557 : ℚ) / 1835 < 1198 / 2691 := by
  norm_num

-- Step 1: each pooled rate is the mix-weighted average of the two kinds' rates.
example :
    (1385 : ℚ) / 2691 * (865 / 1385) + 1306 / 2691 * (333 / 1306) = 1198 / 2691 ∧
    (133 : ℚ) / 1835 * (106 / 133) + 1702 / 1835 * (451 / 1702) = 557 / 1835 := by
  norm_num

-- Step 3: the pooled gap splits exactly into an inside-departments part, which favours
-- women, and a mix part, which is negative.
example :
    (557 : ℚ) / 1835 - 1198 / 2691 =
      (133 / 1835 * (106 / 133 - 865 / 1385) + 1702 / 1835 * (451 / 1702 - 333 / 1306)) +
      ((133 / 1835 - 1385 / 2691) * (865 / 1385) + (1702 / 1835 - 1306 / 2691) * (333 / 1306)) ∧
    0 < (133 : ℚ) / 1835 * (106 / 133 - 865 / 1385) + 1702 / 1835 * (451 / 1702 - 333 / 1306) ∧
    (133 / 1835 - 1385 / 2691) * (865 / 1385) + (1702 / 1835 - 1306 / 2691) * (333 / 1306) < (0 : ℚ) := by
  norm_num

-- Step 2: in a sex-blind world with Berkeley's department rates (open 971/1518, selective
-- 784/3008) and Berkeley's application patterns, women would trail.
example :
    (1702 / 1835 - 1306 / 2691) * ((784 : ℚ) / 3008 - 971 / 1518) < 0 := by
  norm_num

-- Step 4: on the pool's mix (1518 open, 3008 selective, of 4526) women are ahead, on two kinds
-- and on all six departments.
example :
    0 < (1518 : ℚ) / 4526 * (106 / 133 - 865 / 1385) + 3008 / 4526 * (451 / 1702 - 333 / 1306) ∧
    0 < (933 : ℚ) / 4526 * (89 / 108 - 512 / 825) + 585 / 4526 * (17 / 25 - 353 / 560) +
      918 / 4526 * (202 / 593 - 120 / 325) + 792 / 4526 * (131 / 375 - 138 / 417) +
      584 / 4526 * (94 / 393 - 53 / 191) + 714 / 4526 * (24 / 341 - 22 / 373) := by
  norm_num

-- What breaks: the plain average of the six department gaps is smaller than the
-- six-department standardised gap.
example :
    ((89 : ℚ) / 108 - 512 / 825 + (17 / 25 - 353 / 560) + (202 / 593 - 120 / 325) +
      (131 / 375 - 138 / 417) + (94 / 393 - 53 / 191) + (24 / 341 - 22 / 373)) / 6 <
    (933 : ℚ) / 4526 * (89 / 108 - 512 / 825) + 585 / 4526 * (17 / 25 - 353 / 560) +
      918 / 4526 * (202 / 593 - 120 / 325) + 792 / 4526 * (131 / 375 - 138 / 417) +
      584 / 4526 * (94 / 393 - 53 / 191) + 714 / 4526 * (24 / 341 - 22 / 373) := by
  norm_num

-- Step 5: a second world with the same pooled table (women 400/800 open, 157/1035 selective)
-- has women behind inside both kinds.
example :
    400 + 157 = 557 ∧ 800 + 1035 = 1835 ∧
    (400 : ℚ) / 800 < 865 / 1385 ∧ (157 : ℚ) / 1035 < 333 / 1306 := by
  norm_num

-- Try changing: move B into the selective kind (men 686/1866, women 468/1727 there).
-- Women now trail inside the selective kind, and the standardised gap turns negative.
example :
    353 + 333 = 686 ∧ 560 + 1306 = 1866 ∧ 17 + 451 = 468 ∧ 25 + 1702 = 1727 ∧
    (468 : ℚ) / 1727 < 686 / 1866 ∧
    (933 : ℚ) / 4526 * (89 / 108 - 512 / 825) + 3593 / 4526 * (468 / 1727 - 686 / 1866) < 0 := by
  norm_num

#print axioms pooled_rate_eq_mix_weighted_average
#print axioms confounder_gap_two_kinds
#print axioms reweighted_rate_eq_standardised_rate
