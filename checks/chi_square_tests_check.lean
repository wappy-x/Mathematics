-- Chi-square tests: under a fully named model for n independent observations in k boxes, Pearson's statistic averages exactly k - 1, and for a 2 × 2 table it equals n(ad - bc)²/(R₁R₂C₁C₂), the square of the two-proportion z-score.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- The count of box `j`: how many of the `n` observations landed in box `j`. -/
def boxCount {Ω : Type*} {n k : ℕ} (X : Fin n → Ω → Fin k) (j : Fin k) (ω : Ω) : ℕ :=
  (Finset.univ.filter (fun t => X t ω = j)).card

/-- Helper: any real function of the whole vector of observations is integrable. -/
lemma chi_integrable_of_vec {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n k : ℕ} (X : Fin n → Ω → Fin k) (hmeas : ∀ t, Measurable (X t))
    (g : (Fin n → Fin k) → ℝ) : Integrable (fun ω => g (fun t => X t ω)) P := by
  have hY : Measurable (fun ω => fun t => X t ω) := Measurable.of_eval hmeas
  exact (Integrable.of_finite (μ := P.map (fun ω => fun t => X t ω)) (f := g)).comp_measurable hY

#print axioms chi_integrable_of_vec

/-- The exact average of Pearson's statistic. Take `n ≥ 1` independent observations
`X 0, ..., X (n-1)`, each landing in exactly one of `k` boxes fixed in advance, each with the
same chance `p j > 0` of landing in box `j` (the model, named before the data). With expected
count `E_j = n p_j`, Pearson's statistic is `Q = Σ_j (O_j - E_j)² / E_j`. Its average is exactly
`k - 1`, for any number of observations: the same average as a chi-square law with `k - 1`
degrees of freedom. -/
theorem pearson_statistic_mean_eq_boxes_sub_one {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] {n k : ℕ} (hn : 0 < n)
    (X : Fin n → Ω → Fin k) (p : Fin k → ℝ)
    (hmeas : ∀ t, Measurable (X t)) (hindep : iIndepFun X P)
    (hsame : ∀ t j, P.real (X t ⁻¹' {j}) = p j) (hpos : ∀ j, 0 < p j) :
    ∫ ω, (∑ j, ((boxCount X j ω : ℝ) - n * p j) ^ 2 / (n * p j)) ∂P = (k : ℝ) - 1 := by
  classical
  have hInt := chi_integrable_of_vec P X hmeas
  set ind : Fin n → Fin k → Ω → ℝ := fun t j ω => if X t ω = j then 1 else 0 with hind
  have hIndInt : ∀ t j, Integrable (ind t j) P := fun t j =>
    hInt (fun v => if v t = j then 1 else 0)
  have h1 : ∀ t j, ∫ ω, ind t j ω ∂P = p j := by
    intro t j
    have : (fun ω => ind t j ω) = (X t ⁻¹' {j}).indicator 1 := by
      ext ω; simp [ind, Set.indicator_apply]
    rw [this, integral_indicator_one ((hmeas t) (measurableSet_singleton j)), hsame]
  have hsum : ∑ j, p j = 1 := by
    let t : Fin n := ⟨0, hn⟩
    simp_rw [← h1 t]
    rw [← integral_finsetSum _ (fun j _ => hIndInt t j)]
    have : (fun ω => ∑ j, ind t j ω) = fun _ => (1 : ℝ) := by
      ext ω; simp [ind]
    rw [this]; simp
  have hcen : ∀ t j, ∫ ω, (ind t j ω - p j) ∂P = 0 := by
    intro t j
    rw [integral_sub (hIndInt t j) (integrable_const _), h1]; simp
  have hcov : ∀ j t s, ∫ ω, (ind t j ω - p j) * (ind s j ω - p j) ∂P
      = if t = s then p j - p j ^ 2 else 0 := by
    intro j t s
    by_cases hts : t = s
    · subst hts
      have : (fun ω => (ind t j ω - p j) * (ind t j ω - p j))
          = fun ω => (1 - 2 * p j) * ind t j ω + p j ^ 2 := by
        ext ω; simp only [ind]; split_ifs <;> ring
      rw [this, integral_add ((hIndInt t j).const_mul _) (integrable_const _),
        integral_const_mul, h1]
      simp; ring
    · simp only [hts, ↓reduceIte]
      have hφ : Measurable (fun x : Fin k => (if x = j then (1 : ℝ) else 0) - p j) :=
        measurable_of_finite _
      have hI := (hindep.indepFun hts).comp hφ hφ
      have := hI.integral_fun_mul_eq_mul_integral
        ((hInt (fun v => (if v t = j then (1 : ℝ) else 0) - p j)).aestronglyMeasurable)
        ((hInt (fun v => (if v s = j then (1 : ℝ) else 0) - p j)).aestronglyMeasurable)
      simp only [Function.comp_apply] at this
      rw [this]
      have h0 := hcen t j
      simp only [ind] at h0
      simp [h0]
  have hO : ∀ j ω, ((boxCount X j ω : ℝ) - n * p j) = ∑ t, (ind t j ω - p j) := by
    intro j ω
    simp [boxCount, ind, Finset.sum_sub_distrib, Finset.sum_boole]
  have hj : ∀ j, Integrable (fun ω => ((boxCount X j ω : ℝ) - n * p j) ^ 2 / (n * p j)) P :=
    fun j => hInt (fun v =>
    (((Finset.univ.filter (fun t => v t = j)).card : ℝ) - n * p j) ^ 2 / (n * p j))
  rw [integral_finsetSum (f := fun j ω => ((boxCount X j ω : ℝ) - n * p j) ^ 2 / (n * p j))
    _ (fun j _ => hj j)]
  have hterm : ∀ j, ∫ ω, ((boxCount X j ω : ℝ) - n * p j) ^ 2 / (n * p j) ∂P = 1 - p j := by
    intro j
    have hfun : (fun ω => ((boxCount X j ω : ℝ) - n * p j) ^ 2 / (n * p j))
        = fun ω => (∑ t, ∑ s, (ind t j ω - p j) * (ind s j ω - p j)) / (n * p j) := by
      ext ω; rw [hO, sq, Finset.sum_mul_sum]
    have hprod : ∀ t s, Integrable (fun ω => (ind t j ω - p j) * (ind s j ω - p j)) P :=
      fun t s => hInt (fun v => ((if v t = j then (1 : ℝ) else 0) - p j)
        * ((if v s = j then (1 : ℝ) else 0) - p j))
    rw [hfun, integral_div, integral_finsetSum _ (fun t _ => integrable_finsetSum _
      (fun s _ => hprod t s))]
    rw [Finset.sum_congr rfl (fun t _ => integral_finsetSum _ (fun s _ => hprod t s))]
    simp_rw [hcov, Finset.sum_ite_eq, Finset.mem_univ, ite_true, Finset.sum_const,
      Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    have hp := hpos j
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    field_simp
  rw [Finset.sum_congr rfl (fun j _ => hterm j), Finset.sum_sub_distrib, hsum]
  simp

/-- The 2 × 2 shortcut. For a table with cells `a, b` in the first row and `c, d` in the second,
row totals `R₁ = a + b`, `R₂ = c + d`, column totals `C₁ = a + c`, `C₂ = b + d` and grand total
`n`, all totals positive, Pearson's statistic with expected counts `E_ij = R_i C_j / n` equals
`n (ad - bc)² / (R₁ R₂ C₁ C₂)`. -/
theorem pearson_two_by_two_shortcut (a b c d : ℕ)
    (hR₁ : 0 < a + b) (hR₂ : 0 < c + d) (hC₁ : 0 < a + c) (hC₂ : 0 < b + d) :
    let n : ℝ := a + b + c + d
    let R₁ : ℝ := a + b
    let R₂ : ℝ := c + d
    let C₁ : ℝ := a + c
    let C₂ : ℝ := b + d
    ((a : ℝ) - R₁ * C₁ / n) ^ 2 / (R₁ * C₁ / n) + ((b : ℝ) - R₁ * C₂ / n) ^ 2 / (R₁ * C₂ / n)
      + ((c : ℝ) - R₂ * C₁ / n) ^ 2 / (R₂ * C₁ / n) + ((d : ℝ) - R₂ * C₂ / n) ^ 2 / (R₂ * C₂ / n)
      = n * ((a : ℝ) * d - b * c) ^ 2 / (R₁ * R₂ * C₁ * C₂) := by
  intro n R₁ R₂ C₁ C₂
  have h1 : (0 : ℝ) < R₁ := by simp only [R₁]; exact_mod_cast hR₁
  have h2 : (0 : ℝ) < R₂ := by simp only [R₂]; exact_mod_cast hR₂
  have h3 : (0 : ℝ) < C₁ := by simp only [C₁]; exact_mod_cast hC₁
  have h4 : (0 : ℝ) < C₂ := by simp only [C₂]; exact_mod_cast hC₂
  have hn : (0 : ℝ) < n := by simp only [n]; positivity
  simp only [n, R₁, R₂, C₁, C₂] at *
  field_simp
  ring

/-- The 2 × 2 test is the two-proportion z-test, squared. In the same table, with all totals
positive, the first row's rate `a / R₁`, the second row's rate `c / R₂` and the pooled rate
`π = C₁ / n`, the z-score `z = (a/R₁ - c/R₂) / √(π (1 - π) (1/R₁ + 1/R₂))` satisfies
`z² = Q`, Pearson's statistic for the table. -/
theorem pearson_two_by_two_eq_z_sq (a b c d : ℕ)
    (hR₁ : 0 < a + b) (hR₂ : 0 < c + d) (hC₁ : 0 < a + c) (hC₂ : 0 < b + d) :
    let n : ℝ := a + b + c + d
    let R₁ : ℝ := a + b
    let R₂ : ℝ := c + d
    let C₁ : ℝ := a + c
    let C₂ : ℝ := b + d
    let π : ℝ := C₁ / n
    let z : ℝ := ((a : ℝ) / R₁ - c / R₂) / Real.sqrt (π * (1 - π) * (1 / R₁ + 1 / R₂))
    z ^ 2 = ((a : ℝ) - R₁ * C₁ / n) ^ 2 / (R₁ * C₁ / n) + ((b : ℝ) - R₁ * C₂ / n) ^ 2 / (R₁ * C₂ / n)
      + ((c : ℝ) - R₂ * C₁ / n) ^ 2 / (R₂ * C₁ / n) + ((d : ℝ) - R₂ * C₂ / n) ^ 2 / (R₂ * C₂ / n) := by
  intro n R₁ R₂ C₁ C₂ π z
  have h1 : (0 : ℝ) < R₁ := by simp only [R₁]; exact_mod_cast hR₁
  have h2 : (0 : ℝ) < R₂ := by simp only [R₂]; exact_mod_cast hR₂
  have h3 : (0 : ℝ) < C₁ := by simp only [C₁]; exact_mod_cast hC₁
  have h4 : (0 : ℝ) < C₂ := by simp only [C₂]; exact_mod_cast hC₂
  have hn : (0 : ℝ) < n := by simp only [n]; positivity
  have hπ : 1 - π = C₂ / n := by
    rw [eq_div_iff hn.ne', sub_mul, one_mul]
    simp only [π]
    rw [div_mul_cancel₀ _ hn.ne']
    simp only [n, C₁, C₂]; ring
  have hpos : 0 ≤ π * (1 - π) * (1 / R₁ + 1 / R₂) := by
    rw [hπ]; simp only [π]; positivity
  have hz : z ^ 2 = ((a : ℝ) / R₁ - c / R₂) ^ 2 / (π * (1 - π) * (1 / R₁ + 1 / R₂)) := by
    simp only [z]; rw [div_pow, Real.sq_sqrt hpos]
  rw [hz, hπ]
  simp only [π, n, R₁, R₂, C₁, C₂] at *
  field_simp
  ring

/-! The card's worked numbers, as exact fractions. -/

-- Dice: 60 rolls, expected 60 × 1/6 = 10 per face.
example : (60 : ℚ) * (1 / 6) = 10 := by norm_num
-- Gaps 5 − 10, ..., 18 − 10 are −5, −3, −2, 0, 2, 8.
example : ([5, 7, 8, 10, 12, 18] : List ℤ).map (· - 10) = [-5, -3, -2, 0, 2, 8] := by decide
-- Squared gaps over 10: 2.5, 0.9, 0.4, 0, 0.4, 6.4.
example : ([5, 7, 8, 10, 12, 18] : List ℚ).map (fun o => (o - 10) ^ 2 / 10)
    = [5 / 2, 9 / 10, 2 / 5, 0, 2 / 5, 32 / 5] := by norm_num
-- Q for the dice is 10.6 = 53/5; faces 1 and 6 give 2.5 + 6.4 of it.
example : List.sum (([5, 7, 8, 10, 12, 18] : List ℚ).map (fun o => (o - 10) ^ 2 / 10)) = 53 / 5 := by
  norm_num
-- Degrees of freedom: 6 boxes less 1 for the total.
example : 6 - 1 = 5 := by decide
-- The exact average of Q for the die: Σ (1 − 1/6) over six faces = 5.
example : (6 : ℚ) * (1 - 1 / 6) = 5 := by norm_num
-- The variance the card reports, 2 × 5 × 59/60 = 59/6 (9.833333...).
example : (2 : ℚ) * 5 * 59 / 60 = 59 / 6 := by norm_num
-- One roll: expected 1/6 per face, and Q is 5 on every outcome.
example : (1 - 1 / 6 : ℚ) ^ 2 / (1 / 6) + 5 * ((0 - 1 / 6) ^ 2 / (1 / 6)) = 5 := by norm_num
-- Every roll written down twice: Q doubles to 21.2 = 106/5.
example : List.sum (([10, 14, 16, 20, 24, 36] : List ℚ).map (fun o => (o - 20) ^ 2 / 20)) = 106 / 5 := by
  norm_num
-- Proportions fed in instead of counts: Q shrinks to 53/300 (0.176667).
example : List.sum (([5, 7, 8, 10, 12, 18] : List ℚ).map (fun o => (o / 60 - 1 / 6) ^ 2 / (1 / 6)))
    = 53 / 300 := by norm_num
-- A worse die, 3, 7, 8, 10, 12, 20: Q rises to 16.6 = 83/5.
example : List.sum (([3, 7, 8, 10, 12, 20] : List ℚ).map (fun o => (o - 10) ^ 2 / 10)) = 83 / 5 := by
  norm_num

-- Trial: pooled recovery rate 80/200 = 2/5; each arm of 100 expects 40 and 60.
example : (80 : ℚ) / 200 = 2 / 5 := by norm_num
example : (100 : ℚ) * 80 / 200 = 40 ∧ (100 : ℚ) * 120 / 200 = 60 := by norm_num
-- Gaps, observed minus expected: [[5, −5], [−5, 5]].
example : (45 - 40 : ℤ) = 5 ∧ (55 - 60 : ℤ) = -5 ∧ (35 - 40 : ℤ) = -5 ∧ (65 - 60 : ℤ) = 5 := by
  decide
-- Q for the trial: 25/40 + 25/60 + 25/40 + 25/60 = 25/12 (2.083333).
example : (25 : ℚ) / 40 + 25 / 60 + 25 / 40 + 25 / 60 = 25 / 12 := by norm_num
-- The shortcut: ad − bc = 45 × 65 − 55 × 35 = 1,000.
example : (45 * 65 - 55 * 35 : ℤ) = 1000 := by decide
-- 200 × 1,000,000 / (100 × 100 × 80 × 120) = 200,000,000 / 96,000,000 = 25/12.
example : (100 * 100 * 80 * 120 : ℕ) = 96000000 := by decide
example : (200 : ℚ) * 1000 ^ 2 / (100 * 100 * 80 * 120) = 25 / 12 := by norm_num
-- Reciprocals of the expected counts: n (1/R₁ + 1/R₂)(1/C₁ + 1/C₂) = n³/(R₁ R₂ C₁ C₂).
example : (200 : ℚ) * (1 / 100 + 1 / 100) * (1 / 80 + 1 / 120)
    = 200 ^ 3 / (100 * 100 * 80 * 120) := by norm_num
-- Two-proportion z squared: (0.45 − 0.35)² / (0.4 × 0.6 × (1/100 + 1/100)) = 25/12.
example : ((45 : ℚ) / 100 - 35 / 100) ^ 2 / (2 / 5 * (1 - 2 / 5) * (1 / 100 + 1 / 100))
    = 25 / 12 := by norm_num
-- Degrees of freedom: (2 − 1)(2 − 1) = 1, and 4 cells − 1 − (2 − 1) − (2 − 1) = 1, not 3.
example : (2 - 1) * (2 - 1) = 1 ∧ 4 - 1 - (2 - 1) - (2 - 1) = 1 := by decide

#print axioms pearson_statistic_mean_eq_boxes_sub_one
#print axioms pearson_two_by_two_shortcut
#print axioms pearson_two_by_two_eq_z_sq
