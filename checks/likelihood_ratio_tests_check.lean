-- Likelihood ratio tests: for two exact laws on finitely many outcomes the likelihood ratio rule is the most powerful test of its size, the two-arm fit gain W is never negative, and Pearson's X² equals z² for the two-proportion test.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.Powerset
import Mathlib.Tactic.NormNum

open Finset

/-- The four-cell likelihood ratio statistic of the card, `W = 2 Σ O ln(O/E)`, for `x₁`
recoveries in `n₁` patients against `x₂` in `n₂`. The expected counts `E` come from the
one shared rate `p̂₀ = (x₁ + x₂)/(n₁ + n₂)`. A cell with `O = 0` contributes 0. -/
noncomputable def lrStat (x₁ n₁ x₂ n₂ : ℕ) : ℝ :=
  let p₀ : ℝ := ((x₁ : ℝ) + x₂) / ((n₁ : ℝ) + n₂)
  let cell : ℝ → ℝ → ℝ := fun O E => O * Real.log (O / E)
  2 * (cell x₁ (n₁ * p₀) + cell ((n₁ : ℝ) - x₁) (n₁ * (1 - p₀)) +
       cell x₂ (n₂ * p₀) + cell ((n₂ : ℝ) - x₂) (n₂ * (1 - p₀)))

/-- Pearson's `X² = Σ (O - E)² / E` over the same four cells, with `E` from the shared rate. -/
noncomputable def pearsonX2 (x₁ n₁ x₂ n₂ : ℕ) : ℝ :=
  let p₀ : ℝ := ((x₁ : ℝ) + x₂) / ((n₁ : ℝ) + n₂)
  ((x₁ : ℝ) - n₁ * p₀) ^ 2 / (n₁ * p₀) +
  (((n₁ : ℝ) - x₁) - n₁ * (1 - p₀)) ^ 2 / (n₁ * (1 - p₀)) +
  ((x₂ : ℝ) - n₂ * p₀) ^ 2 / (n₂ * p₀) +
  (((n₂ : ℝ) - x₂) - n₂ * (1 - p₀)) ^ 2 / (n₂ * (1 - p₀))

/-- The square of the two-proportion statistic
`z = (p̂₁ - p̂₂) / √(p̂₀(1 - p̂₀)(1/n₁ + 1/n₂))`, written without the square root. -/
noncomputable def twoPropZSq (x₁ n₁ x₂ n₂ : ℕ) : ℝ :=
  let p₁ : ℝ := (x₁ : ℝ) / n₁
  let p₂ : ℝ := (x₂ : ℝ) / n₂
  let p₀ : ℝ := ((x₁ : ℝ) + x₂) / ((n₁ : ℝ) + n₂)
  (p₁ - p₂) ^ 2 / (p₀ * (1 - p₀) * (1 / (n₁ : ℝ) + 1 / n₂))

/-- Each likelihood-ratio cell is at least its gap `O - E` (from `log x ≤ x - 1`). -/
theorem lr_cell_ge (O E : ℝ) (hO : 0 ≤ O) (hE : 0 ≤ E) (h : 0 < O → 0 < E) :
    O - E ≤ O * Real.log (O / E) := by
  rcases hO.lt_or_eq with hO | hO
  · have hE' := h hO
    have hl := Real.log_le_sub_one_of_pos (div_pos hE' hO)
    have heq : Real.log (O / E) = - Real.log (E / O) := by
      rw [← Real.log_inv, inv_div]
    have hm : O * (E / O) = E := by field_simp
    rw [heq]
    nlinarith [mul_le_mul_of_nonneg_left hl hO.le]
  · subst hO; simp; linarith

#print axioms lr_cell_ge

/-- **Neyman–Pearson lemma.** Take two simple hypotheses: two exact laws `L₀` (the null) and
`L₁` (the alternative) on a finite set of outcomes. Let `R*` be the set of outcomes where
`L₁ ≥ c · L₀`, for a threshold `c ≥ 0`. Then any other rejection set `R` whose false-alarm
chance `P₀(R)` is no larger than that of `R*` has power `P₁(R)` no larger than that of `R*`. -/
theorem neyman_pearson_most_powerful {Ω : Type*} [Fintype Ω]
    (L₀ L₁ : Ω → ℝ) (hL₀ : ∀ ω, 0 ≤ L₀ ω) (hL₁ : ∀ ω, 0 ≤ L₁ ω)
    (hsum₀ : ∑ ω, L₀ ω = 1) (hsum₁ : ∑ ω, L₁ ω = 1)
    (c : ℝ) (hc : 0 ≤ c) (R : Finset Ω)
    (hR : ∑ ω ∈ R, L₀ ω ≤
      ∑ ω ∈ (univ.filter fun ω => c * L₀ ω ≤ L₁ ω), L₀ ω) :
    ∑ ω ∈ R, L₁ ω ≤ ∑ ω ∈ (univ.filter fun ω => c * L₀ ω ≤ L₁ ω), L₁ ω := by
  classical
  set S := univ.filter fun ω => c * L₀ ω ≤ L₁ ω with hS
  have key : ∑ ω ∈ R, (L₁ ω - c * L₀ ω) ≤ ∑ ω ∈ S, (L₁ ω - c * L₀ ω) := by
    have hRe : ∑ ω ∈ R, (L₁ ω - c * L₀ ω) = ∑ ω, if ω ∈ R then L₁ ω - c * L₀ ω else 0 := by
      rw [Finset.sum_ite_mem, Finset.univ_inter]
    rw [hS, Finset.sum_filter, hRe]
    · apply Finset.sum_le_sum
      intro ω _
      split_ifs with h1 h2 h2 <;> linarith
  rw [Finset.sum_sub_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, ← Finset.mul_sum] at key
  nlinarith [mul_le_mul_of_nonneg_left hR hc]

/-- **The bigger model always fits at least as well.** For any trial with `x₁` of `n₁`
recoveries on the drug and `x₂` of `n₂` on placebo, the likelihood ratio statistic
`W = 2 Σ O ln(O/E)` is never negative. -/
theorem lr_stat_nonneg (x₁ n₁ x₂ n₂ : ℕ) (h₁ : x₁ ≤ n₁) (h₂ : x₂ ≤ n₂) :
    0 ≤ lrStat x₁ n₁ x₂ n₂ := by
  have ha : (0 : ℝ) ≤ x₁ := Nat.cast_nonneg _
  have hc : (0 : ℝ) ≤ x₂ := Nat.cast_nonneg _
  have hab : (x₁ : ℝ) ≤ n₁ := by exact_mod_cast h₁
  have hcd : (x₂ : ℝ) ≤ n₂ := by exact_mod_cast h₂
  unfold lrStat
  dsimp only
  set a : ℝ := ((x₁ : ℕ) : ℝ) with ha_def
  set b : ℝ := ((n₁ : ℕ) : ℝ) with hb_def
  set c : ℝ := ((x₂ : ℕ) : ℝ) with hc_def
  set d : ℝ := ((n₂ : ℕ) : ℝ) with hd_def
  set p : ℝ := (a + c) / (b + d) with hp
  have hp0 : 0 ≤ p := div_nonneg (by linarith) (by linarith)
  have hp1 : p ≤ 1 := div_le_one_of_le₀ (by linarith) (by linarith)
  have hb : 0 ≤ b := by linarith
  have hd : 0 ≤ d := by linarith
  have c1 := lr_cell_ge a (b * p) ha (mul_nonneg hb hp0) (fun h => by
    have : 0 < p := div_pos (by linarith) (by linarith)
    exact mul_pos (by linarith) this)
  have c2 := lr_cell_ge (b - a) (b * (1 - p)) (by linarith) (mul_nonneg hb (by linarith))
    (fun h => by
      have : p < 1 := (div_lt_one (by linarith)).mpr (by linarith)
      exact mul_pos (by linarith) (by linarith))
  have c3 := lr_cell_ge c (d * p) hc (mul_nonneg hd hp0) (fun h => by
    have : 0 < p := div_pos (by linarith) (by linarith)
    exact mul_pos (by linarith) this)
  have c4 := lr_cell_ge (d - c) (d * (1 - p)) (by linarith) (mul_nonneg hd (by linarith))
    (fun h => by
      have : p < 1 := (div_lt_one (by linarith)).mpr (by linarith)
      exact mul_pos (by linarith) (by linarith))
  nlinarith [c1, c2, c3, c4]

/-- **Pearson's `X²` is `z²`.** With two arms, the four-cell sum of squared gaps over expected
counts equals the square of the two-proportion `z` statistic. -/
theorem pearson_x2_eq_z_sq (x₁ n₁ x₂ n₂ : ℕ) (hn₁ : 0 < n₁) (hn₂ : 0 < n₂)
    (h₁ : x₁ ≤ n₁) (h₂ : x₂ ≤ n₂) :
    pearsonX2 x₁ n₁ x₂ n₂ = twoPropZSq x₁ n₁ x₂ n₂ := by
  by_cases hz : x₁ + x₂ = 0
  · obtain ⟨rfl, rfl⟩ : x₁ = 0 ∧ x₂ = 0 := by omega
    simp [pearsonX2, twoPropZSq]
  by_cases ho : x₁ + x₂ = n₁ + n₂
  · obtain ⟨rfl, rfl⟩ : x₁ = n₁ ∧ x₂ = n₂ := by omega
    have h1 : (x₁ : ℝ) ≠ 0 := by positivity
    have h2 : (x₂ : ℝ) ≠ 0 := by positivity
    have h3 : (x₁ : ℝ) + x₂ ≠ 0 := by positivity
    simp [pearsonX2, twoPropZSq, div_self h1, div_self h2, div_self h3]
  have hb : (0 : ℝ) < n₁ := by exact_mod_cast hn₁
  have hd : (0 : ℝ) < n₂ := by exact_mod_cast hn₂
  have hac : (0 : ℝ) < (x₁ : ℝ) + x₂ := by
    have : 0 < x₁ + x₂ := Nat.pos_of_ne_zero hz
    exact_mod_cast this
  have hlt : (x₁ : ℝ) + x₂ < (n₁ : ℝ) + n₂ := by
    have : x₁ + x₂ < n₁ + n₂ := by omega
    exact_mod_cast this
  unfold pearsonX2 twoPropZSq
  dsimp only
  set a : ℝ := ((x₁ : ℕ) : ℝ) with ha_def
  set b : ℝ := ((n₁ : ℕ) : ℝ) with hb_def
  set c : ℝ := ((x₂ : ℕ) : ℝ) with hc_def
  set d : ℝ := ((n₂ : ℕ) : ℝ) with hd_def
  have hbd : b + d ≠ 0 := by positivity
  have hq : b + d - (a + c) ≠ 0 := by linarith
  have hq' : 1 - (a + c) / (b + d) = (b + d - (a + c)) / (b + d) := by field_simp
  rw [hq']
  have hb' : b ≠ 0 := hb.ne'
  have hd' : d ≠ 0 := hd.ne'
  have hac' : a + c ≠ 0 := hac.ne'
  field_simp
  ring

-- The card's whole-number worked examples, checked exactly.
-- Shared rate: 80 recoveries in 200 patients is 2/5 (0.40).
example : ((45 : ℚ) + 35) / (100 + 100) = 2 / 5 := by norm_num
-- Expected counts 40, 60, 40, 60.
example : (100 : ℚ) * (2 / 5) = 40 ∧ (100 : ℚ) * (1 - 2 / 5) = 60 := by norm_num
-- Every gap O - E is 5 in size: 45 - 40, 55 - 60, 35 - 40, 65 - 60.
example : (45 : ℤ) - 40 = 5 ∧ (55 : ℤ) - 60 = -5 ∧ (35 : ℤ) - 40 = -5 ∧ (65 : ℤ) - 60 = 5 := by
  decide
-- Pearson's X² by hand: 25 (1/40 + 1/60 + 1/40 + 1/60) = 25/12 (2.083333).
example : (25 : ℚ) * (1 / 40 + 1 / 60 + 1 / 40 + 1 / 60) = 25 / 12 := by norm_num
-- z² = 0.10² / (0.24 × 0.02) = 25/12, the same number.
example : ((1 / 10 : ℚ)) ^ 2 / ((6 / 25) * (2 / 100)) = 25 / 12 := by norm_num
-- Both definitions give 25/12 on the drug trial.
example : pearsonX2 45 100 35 100 = 25 / 12 := by norm_num [pearsonX2]
example : twoPropZSq 45 100 35 100 = 25 / 12 := by norm_num [twoPropZSq]
-- Degrees of freedom: 2 parameters minus 1.
example : (2 : ℕ) - 1 = 1 := by decide
-- Exact enumeration covers 101 × 101 = 10,201 pairs of counts.
example : (101 : ℕ) * 101 = 10201 := by decide
-- A 10-patient arm has outcomes 0..10, so there are 2^11 = 2,048 rejection sets.
example : Fintype.card (Finset (Fin 11)) = 2048 := by simp

#print axioms neyman_pearson_most_powerful
#print axioms lr_stat_nonneg
#print axioms pearson_x2_eq_z_sq
