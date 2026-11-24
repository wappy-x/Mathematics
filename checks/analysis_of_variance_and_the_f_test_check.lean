-- Analysis of variance: the total sum of squares round the grand mean splits exactly into the between-groups and within-groups sums of squares, these are the misses of the one-mean and one-mean-per-group least-squares fits, and with two groups the F ratio is the square of the pooled t ratio.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Order.Bounds.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

/-! Notation as on the card. There are `k` groups, indexed by a finite type `G`; group `g` has
`n g` plots, and `y g i` is the yield of plot `i` under fertiliser `g`. A bar is an average:
`ȳ_g` is group `g`'s average and `ȳ` the grand mean of all plots. `SST`, `SSB` and `SSW` are the
total, between-groups and within-groups sums of squares. The F ratio is
`(SSB / (k − 1)) / (SSW / (n − k))`, with `n` the number of plots in all. The F law of this ratio
under equal true means needs a distribution Mathlib does not have, so it is not stated here. -/

open Finset

noncomputable section

namespace OneWayANOVA

variable {G : Type*} [Fintype G] {n : G → ℕ}

/-- `n`, the number of plots in all: `∑ n_g`, as a real number. -/
def plots (n : G → ℕ) : ℝ := ∑ g, (n g : ℝ)

/-- Group `g`'s average, `ȳ_g = (∑ᵢ y_{gi}) / n_g`. -/
def groupMean (y : (g : G) → Fin (n g) → ℝ) (g : G) : ℝ := (∑ i, y g i) / n g

/-- The grand mean, `ȳ = (∑_g ∑ᵢ y_{gi}) / n`, the average of all plots. -/
def grandMean (y : (g : G) → Fin (n g) → ℝ) : ℝ := (∑ g, ∑ i, y g i) / plots n

/-- `SST = ∑_g ∑ᵢ (y_{gi} − ȳ)²`, the total squared spread round the grand mean. -/
def SST (y : (g : G) → Fin (n g) → ℝ) : ℝ := ∑ g, ∑ i, (y g i - grandMean y) ^ 2

/-- `SSB = ∑_g n_g (ȳ_g − ȳ)²`, the squared spread of the group averages, once per plot. -/
def SSB (y : (g : G) → Fin (n g) → ℝ) : ℝ := ∑ g, (n g : ℝ) * (groupMean y g - grandMean y) ^ 2

/-- `SSW = ∑_g ∑ᵢ (y_{gi} − ȳ_g)²`, the squared spread of plots round their own group's average. -/
def SSW (y : (g : G) → Fin (n g) → ℝ) : ℝ := ∑ g, ∑ i, (y g i - groupMean y g) ^ 2

/-- The F ratio `MSB / MSW = (SSB / (k − 1)) / (SSW / (n − k))`, with `k` groups. -/
def Fstat (y : (g : G) → Fin (n g) → ℝ) : ℝ :=
  (SSB y / ((Fintype.card G : ℝ) - 1)) / (SSW y / (plots n - Fintype.card G))

/-- The pooled t ratio for two groups, `0` and `1`:
`(ȳ₁ − ȳ₀) / √(s_p² (1/n₀ + 1/n₁))`, where `s_p² = SSW / (n − 2)` is the pooled spread. -/
def pooledT {m : Fin 2 → ℕ} (y : (g : Fin 2) → Fin (m g) → ℝ) : ℝ :=
  (groupMean y 1 - groupMean y 0) /
    Real.sqrt (SSW y / (plots m - 2) * (1 / (m 0 : ℝ) + 1 / (m 1 : ℝ)))

/-- Expanding a sum of squared misses from a constant `c`. -/
lemma expand_sq {ι : Type*} (s : Finset ι) (f : ι → ℝ) (c : ℝ) :
    ∑ i ∈ s, (f i - c) ^ 2 = ∑ i ∈ s, f i ^ 2 - 2 * c * ∑ i ∈ s, f i + (s.card : ℝ) * c ^ 2 := by
  simp only [sub_sq, sum_add_distrib, sum_sub_distrib, sum_const, nsmul_eq_mul, mul_sum]
  congr 1; congr 1; apply sum_congr rfl; intro i _; ring

/-- Squared misses from any constant `c` = squared misses from the average + `card · (avg − c)²`. -/
lemma split_sq {ι : Type*} (s : Finset ι) (f : ι → ℝ) (c : ℝ) :
    ∑ i ∈ s, (f i - c) ^ 2 = ∑ i ∈ s, (f i - (∑ j ∈ s, f j) / s.card) ^ 2
      + (s.card : ℝ) * ((∑ j ∈ s, f j) / s.card - c) ^ 2 := by
  rw [expand_sq, expand_sq]
  rcases Nat.eq_zero_or_pos s.card with h | h
  · have : s = ∅ := Finset.card_eq_zero.mp h
    subst this; simp
  · have : (s.card : ℝ) ≠ 0 := by positivity
    field_simp; ring

omit [Fintype G] in
/-- Within one group, squared misses from `c` split round the group average. -/
lemma group_split (y : (g : G) → Fin (n g) → ℝ) (g : G) (c : ℝ) :
    ∑ i, (y g i - c) ^ 2 = ∑ i, (y g i - groupMean y g) ^ 2 + (n g : ℝ) * (groupMean y g - c) ^ 2 := by
  have h := split_sq (univ : Finset (Fin (n g))) (y g) c
  simpa [groupMean, Finset.card_univ, Fintype.card_fin] using h

/-- Over all plots, squared misses from `c` split round the grand mean. -/
lemma grand_split (y : (g : G) → Fin (n g) → ℝ) (c : ℝ) :
    ∑ g, ∑ i, (y g i - c) ^ 2 = SST y + plots n * (grandMean y - c) ^ 2 := by
  have hs : ∀ f : (g : G) → Fin (n g) → ℝ, ∑ g, ∑ i, f g i =
      ∑ x ∈ (univ : Finset G).sigma (fun g => (univ : Finset (Fin (n g)))), f x.1 x.2 := fun f => by
    rw [Finset.sum_sigma]
  have hc : plots n = (((univ : Finset G).sigma (fun g => (univ : Finset (Fin (n g))))).card : ℝ) := by
    simp [plots]
  have h := split_sq ((univ : Finset G).sigma (fun g => (univ : Finset (Fin (n g)))))
    (fun x => y x.1 x.2) c
  rw [SST, grandMean, hs, hs, hs (fun g i => y g i), hc]
  exact h

#print axioms expand_sq
#print axioms split_sq
#print axioms group_split
#print axioms grand_split

/-- **The split is Pythagoras.** For any yields in any number of groups, the total squared
spread round the grand mean equals the squared spread of the group averages, counted once per
plot, plus the squared spread of plots round their own group's average:
`SST = SSB + SSW`. -/
theorem total_ss_eq_between_ss_add_within_ss (y : (g : G) → Fin (n g) → ℝ) :
    SST y = SSB y + SSW y := by
  rw [SST, SSB, SSW, ← sum_add_distrib]
  refine sum_congr rfl fun g _ => ?_
  rw [group_split y g (grandMean y), add_comm]

/-- **One-way ANOVA is the nested-model test.** Fitting one constant per group by least squares
leaves squared misses `RSS₁ = SSW` (the smallest possible, reached at the group averages);
fitting one constant for everyone leaves `RSS₀ = SST` (reached at the grand mean). So the F ratio
is the general test `((RSS₀ − RSS₁) / q) / (RSS₁ / (n − p))` with `p = k` coefficients in the
full model and `q = k − 1` dropped. -/
theorem anova_F_eq_nested_model_F (y : (g : G) → Fin (n g) → ℝ) :
    IsLeast {r | ∃ c : G → ℝ, r = ∑ g, ∑ i, (y g i - c g) ^ 2} (SSW y) ∧
      IsLeast {r | ∃ c : ℝ, r = ∑ g, ∑ i, (y g i - c) ^ 2} (SST y) ∧
      Fstat y = ((SST y - SSW y) / ((Fintype.card G : ℝ) - 1)) /
        (SSW y / (plots n - Fintype.card G)) := by
  refine ⟨⟨⟨groupMean y, rfl⟩, ?_⟩, ⟨⟨grandMean y, rfl⟩, ?_⟩, ?_⟩
  · rintro r ⟨c, rfl⟩
    rw [SSW]
    refine sum_le_sum fun g _ => ?_
    rw [group_split y g (c g)]
    have : 0 ≤ (n g : ℝ) * (groupMean y g - c g) ^ 2 := by positivity
    linarith
  · rintro r ⟨c, rfl⟩
    rw [grand_split y c]
    have : 0 ≤ plots n * (grandMean y - c) ^ 2 :=
      mul_nonneg (sum_nonneg fun g _ => Nat.cast_nonneg _) (sq_nonneg _)
    linarith
  · rw [Fstat, total_ss_eq_between_ss_add_within_ss]
    ring

/-- **With two groups, F is the pooled t ratio squared.** If both groups have at least one plot,
the F ratio on `(1, n − 2)` equals the square of the pooled two-sample t ratio. -/
theorem two_group_F_eq_pooled_t_sq {m : Fin 2 → ℕ} (y : (g : Fin 2) → Fin (m g) → ℝ)
    (h0 : 0 < m 0) (h1 : 0 < m 1) :
    Fstat y = pooledT y ^ 2 := by
  have hm0 : (1 : ℝ) ≤ m 0 := by exact_mod_cast h0
  have hm1 : (1 : ℝ) ≤ m 1 := by exact_mod_cast h1
  have hp : plots m = (m 0 : ℝ) + m 1 := by simp [plots, Fin.sum_univ_two]
  have hW : 0 ≤ SSW y := by
    exact sum_nonneg fun g _ => sum_nonneg fun i _ => sq_nonneg _
  have hm0' : (0 : ℝ) < m 0 := by linarith
  have hm1' : (0 : ℝ) < m 1 := by linarith
  have hnn : 0 ≤ SSW y / (plots m - 2) * (1 / (m 0 : ℝ) + 1 / (m 1 : ℝ)) := by
    rw [hp]
    have : 0 ≤ (m 0 : ℝ) + m 1 - 2 := by linarith
    positivity
  have hB : SSB y = (groupMean y 1 - groupMean y 0) ^ 2 / (1 / (m 0 : ℝ) + 1 / (m 1 : ℝ)) := by
    have hg : grandMean y = (m 0 * groupMean y 0 + m 1 * groupMean y 1) / ((m 0 : ℝ) + m 1) := by
      have e0 : (m 0 : ℝ) * groupMean y 0 = ∑ i, y 0 i := by
        unfold groupMean; field_simp
      have e1 : (m 1 : ℝ) * groupMean y 1 = ∑ i, y 1 i := by
        unfold groupMean; field_simp
      rw [grandMean, hp, Fin.sum_univ_two, e0, e1]
    rw [SSB, Fin.sum_univ_two, hg]
    have : (m 0 : ℝ) ≠ 0 := by positivity
    have : (m 1 : ℝ) ≠ 0 := by positivity
    have : (m 0 : ℝ) + m 1 ≠ 0 := by positivity
    field_simp
    ring
  rw [pooledT, div_pow, Real.sq_sqrt hnn, Fstat, hB]
  simp only [Fintype.card_fin]
  norm_num
  rw [div_div, mul_comm]

/-! The card's trial: three fertilisers, four plots each, yields in kilograms.
A: 20, 22, 19, 23; B: 25, 27, 24, 28; C: 22, 21, 23, 22. -/

/-- The card's yields, group `0` = A, `1` = B, `2` = C. -/
def trial : (g : Fin 3) → Fin ((fun _ => 4) g) → ℝ :=
  ![![20, 22, 19, 23], ![25, 27, 24, 28], ![22, 21, 23, 22]]

-- Group averages 21, 26, 22 and grand mean 23.
example : groupMean trial 0 = 21 ∧ groupMean trial 1 = 26 ∧ groupMean trial 2 = 22 := by
  simp [groupMean, trial, Fin.sum_univ_succ]
  norm_num
example : grandMean trial = 23 := by
  simp [grandMean, plots, trial, Fin.sum_univ_succ]
  norm_num
-- SSB = 56, SSW = 22, SST = 78 = 56 + 22.
example : SSB trial = 56 := by
  simp [SSB, groupMean, grandMean, plots, trial, Fin.sum_univ_succ]
  norm_num
example : SSW trial = 22 := by
  simp [SSW, groupMean, trial, Fin.sum_univ_succ]
  norm_num
example : SST trial = 78 := by
  simp [SST, grandMean, plots, trial, Fin.sum_univ_succ]
  norm_num
-- F = 28 / (22 / 9) = 126 / 11, about 11.4545.
example : Fstat trial = 126 / 11 := by
  simp [Fstat, SSB, SSW, groupMean, grandMean, plots, trial, Fin.sum_univ_succ]
  norm_num
-- The hand arithmetic, in whole numbers: between pieces 16, 36, 4; within pieces 10, 10, 2.
example : 4 * (21 - 23) ^ 2 + 4 * (26 - 23) ^ 2 + 4 * (22 - 23) ^ 2 = (56 : ℤ) := by norm_num
example : ((1 + 1 + 4 + 4) + (1 + 1 + 4 + 4) + (0 + 1 + 1 + 0) : ℤ) = 22 := by norm_num
example : (56 : ℤ) + 22 = 78 := by norm_num
-- A against B alone: pooled t² = F = 15.
example : (5 : ℚ) ^ 2 / ((20 / 6) * (1 / 4 + 1 / 4)) = 15 := by norm_num

#print axioms total_ss_eq_between_ss_add_within_ss
#print axioms anova_F_eq_nested_model_F
#print axioms two_group_F_eq_pooled_t_sq

end OneWayANOVA
