-- Differential entropy and water-filling: filling the slots with power up to one water level gives the largest total capacity for a fixed power budget, the bell curve has the largest differential entropy ½ log₂(2πeσ²) for its variance, and changing units by a factor a adds log₂ |a| to the differential entropy.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Measure.Haar.NormedSpace
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Real Finset
open scoped NNReal

/-- The differential entropy in bits of a density `f` on the line:
`h = -∫ f(x) log₂ f(x) dx`. -/
noncomputable def diffEntropyBits (f : ℝ → ℝ) : ℝ :=
  -∫ x, f x * Real.logb 2 (f x)

/-- One slot: concavity of the logarithm against the water level. -/
lemma water_filling_slot (N p ν : ℝ) (hN : 0 < N) (hp : 0 ≤ p) (hν : 0 < ν) :
    Real.log (1 + p / N) ≤ Real.log (1 + max 0 (ν - N) / N) + (p - max 0 (ν - N)) / ν := by
  set q := max 0 (ν - N) with hq
  have hq0 : 0 ≤ q := le_max_left _ _
  have ha : 0 < 1 + p / N := by positivity
  have hb : 0 < 1 + q / N := by positivity
  have hb' : 0 < N + q := by linarith
  have h1 : Real.log (1 + p / N) - Real.log (1 + q / N) ≤ (p - q) / (N + q) := by
    rw [← Real.log_div ha.ne' hb.ne']
    refine (Real.log_le_sub_one_of_pos (div_pos ha hb)).trans (le_of_eq ?_)
    field_simp
    ring
  have h2 : (p - q) / (N + q) ≤ (p - q) / ν := by
    rcases le_or_gt ν N with h | h
    · have : q = 0 := max_eq_left (by linarith)
      rw [this, add_zero, sub_zero]
      exact div_le_div_of_nonneg_left hp hν h
    · have : q = ν - N := max_eq_right (by linarith)
      rw [this, show N + (ν - N) = ν by ring]
  linarith

#print axioms water_filling_slot

/-- The logarithm of the bell curve, written out. -/
lemma log_gaussianPDFReal (μ : ℝ) (v : ℝ≥0) (hv : v ≠ 0) (x : ℝ) :
    Real.log (gaussianPDFReal μ v x)
      = -(1 / 2 * Real.log (2 * π * v)) - 1 / (2 * v) * (x - μ) ^ 2 := by
  have hv' : (0 : ℝ) < v := lt_of_le_of_ne v.2 (by exact_mod_cast hv.symm)
  rw [gaussianPDFReal, Real.log_mul (by positivity) (Real.exp_pos _).ne', Real.log_inv,
    Real.log_sqrt (by positivity), Real.log_exp]
  ring

#print axioms log_gaussianPDFReal

/-- For a density with variance `v` about `μ`, the average of the log of the bell curve. -/
lemma integral_mul_log_gaussianPDFReal (f : ℝ → ℝ) (μ : ℝ) (v : ℝ≥0) (hv : v ≠ 0)
    (hfi : Integrable f) (hf1 : ∫ x, f x = 1)
    (hvi : Integrable (fun x => (x - μ) ^ 2 * f x)) (hvar : ∫ x, (x - μ) ^ 2 * f x = v) :
    Integrable (fun x => f x * Real.log (gaussianPDFReal μ v x)) ∧
      ∫ x, f x * Real.log (gaussianPDFReal μ v x) = -(1 / 2 * Real.log (2 * π * exp 1 * v)) := by
  have hv' : (0 : ℝ) < v := lt_of_le_of_ne v.2 (by exact_mod_cast hv.symm)
  have hpt : (fun x => f x * Real.log (gaussianPDFReal μ v x))
      = fun x => -(1 / 2 * Real.log (2 * π * v)) * f x - 1 / (2 * v) * ((x - μ) ^ 2 * f x) := by
    ext x
    rw [log_gaussianPDFReal μ v hv x]
    ring
  rw [hpt]
  refine ⟨(hfi.const_mul _).sub (hvi.const_mul _), ?_⟩
  rw [integral_sub (hfi.const_mul _) (hvi.const_mul _), integral_const_mul, integral_const_mul,
    hf1, hvar, show (2 : ℝ) * π * exp 1 * v = (2 * π * v) * exp 1 by ring,
    Real.log_mul (by positivity) (Real.exp_pos _).ne', Real.log_exp]
  field_simp
  ring

#print axioms integral_mul_log_gaussianPDFReal

/-- The bell curve's own moments: total area 1 and variance `v` about `μ`. -/
lemma gaussianPDFReal_moments (μ : ℝ) (v : ℝ≥0) (hv : v ≠ 0) :
    Integrable (fun x => (x - μ) ^ 2 * gaussianPDFReal μ v x) ∧
      ∫ x, (x - μ) ^ 2 * gaussianPDFReal μ v x = v := by
  have hv' : (0 : ℝ) < v := lt_of_le_of_ne v.2 (by exact_mod_cast hv.symm)
  have h : ∫ x, (x - μ) ^ 2 * gaussianPDFReal μ v x = v := by
    have h1 := variance_fun_id_gaussianReal (μ := μ) (v := v)
    rw [variance_eq_integral measurable_id'.aemeasurable, integral_id_gaussianReal,
      integral_gaussianReal_eq_integral_smul hv] at h1
    simp only [smul_eq_mul] at h1
    rw [← h1]
    congr 1
    ext x
    ring
  refine ⟨?_, h⟩
  by_contra hni
  rw [integral_undef hni] at h
  exact hv'.ne' h.symm

#print axioms gaussianPDFReal_moments

/-- **Water-filling is the best split of power.** Take independent slots `i` with bell-curve
noise of power `N_i > 0`, so that slot `i` given power `p_i ≥ 0` carries `½ log₂(1 + p_i / N_i)`
bits per use, and a total power budget `P`. Pick the water level `ν` whose poured power
`Σ_i max(0, ν - N_i)` is exactly `P`. Then giving each slot `P_i = max(0, ν - N_i)` is a split of
the budget, and no other split of `P` into non-negative powers carries more bits in total. -/
theorem water_filling_is_best_split {ι : Type*} [Fintype ι] (N : ι → ℝ) (hN : ∀ i, 0 < N i)
    (P ν : ℝ) (hν : ∑ i, max 0 (ν - N i) = P) :
    IsGreatest
      {C : ℝ | ∃ p : ι → ℝ, (∀ i, 0 ≤ p i) ∧ ∑ i, p i = P ∧
          C = ∑ i, 1 / 2 * Real.logb 2 (1 + p i / N i)}
      (∑ i, 1 / 2 * Real.logb 2 (1 + max 0 (ν - N i) / N i)) := by
  constructor
  · exact ⟨fun i => max 0 (ν - N i), fun i => le_max_left _ _, hν, rfl⟩
  · rintro C ⟨p, hp0, hpP, rfl⟩
    by_cases hνpos : ν ≤ 0
    · have hmax : ∀ i, max 0 (ν - N i) = 0 := fun i => max_eq_left (by linarith [hN i])
      have hP : P = 0 := by rw [← hν]; simp [hmax]
      have hp : ∀ i, p i = 0 := by
        have := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => hp0 i)).1 (hpP.trans hP)
        intro i; exact this i (Finset.mem_univ i)
      simp [hp, hmax]
    · replace hνpos := not_le.mp hνpos
      have h2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
      calc ∑ i, 1 / 2 * Real.logb 2 (1 + p i / N i)
          ≤ ∑ i, (1 / 2 * Real.logb 2 (1 + max 0 (ν - N i) / N i)
              + 1 / 2 * ((p i - max 0 (ν - N i)) / ν / Real.log 2)) := by
            refine Finset.sum_le_sum (fun i _ => ?_)
            have := div_le_div_of_nonneg_right
              (water_filling_slot (N i) (p i) ν (hN i) (hp0 i) hνpos) h2.le
            rw [add_div] at this
            unfold Real.logb
            linarith
        _ = ∑ i, 1 / 2 * Real.logb 2 (1 + max 0 (ν - N i) / N i)
              + 1 / 2 * ((∑ i, p i - ∑ i, max 0 (ν - N i)) / ν / Real.log 2) := by
            rw [Finset.sum_add_distrib]
            congr 1
            rw [← Finset.mul_sum, ← Finset.sum_div, ← Finset.sum_div, Finset.sum_sub_distrib]
        _ = ∑ i, 1 / 2 * Real.logb 2 (1 + max 0 (ν - N i) / N i) := by
            rw [hpP, hν, sub_self]; simp

/-- **The bell curve has the most differential entropy for its variance.** Let `f` be a density
on the line (non-negative, total area 1) with mean `μ` and variance `σ² = v > 0`, whose
differential entropy is defined. Then its differential entropy is at most `½ log₂(2πe σ²)`, and
the bell curve with that mean and variance has exactly `½ log₂(2πe σ²)`. -/
theorem bell_curve_has_most_differential_entropy (f : ℝ → ℝ) (μ : ℝ) (v : ℝ≥0) (hv : v ≠ 0)
    (hf0 : ∀ x, 0 ≤ f x) (hfi : Integrable f) (hf1 : ∫ x, f x = 1)
    (hmi : Integrable (fun x => x * f x)) (hmean : ∫ x, x * f x = μ)
    (hvi : Integrable (fun x => (x - μ) ^ 2 * f x)) (hvar : ∫ x, (x - μ) ^ 2 * f x = v)
    (hhi : Integrable (fun x => f x * Real.logb 2 (f x))) :
    diffEntropyBits f ≤ 1 / 2 * Real.logb 2 (2 * π * exp 1 * v) ∧
      diffEntropyBits (gaussianPDFReal μ v) = 1 / 2 * Real.logb 2 (2 * π * exp 1 * v) := by
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  -- In bits: divide the natural-log version by `log 2`.
  have hbits : ∀ g : ℝ → ℝ, diffEntropyBits g = -(∫ x, g x * Real.log (g x)) / Real.log 2 := by
    intro g
    unfold diffEntropyBits
    simp_rw [Real.logb, ← mul_div_assoc]
    rw [integral_div, neg_div]
  have htarget : 1 / 2 * Real.logb 2 (2 * π * exp 1 * v)
      = (1 / 2 * Real.log (2 * π * exp 1 * v)) / Real.log 2 := by
    rw [Real.logb]; ring
  obtain ⟨hgi, hgint⟩ := integral_mul_log_gaussianPDFReal f μ v hv hfi hf1 hvi hvar
  refine ⟨?_, ?_⟩
  · rw [hbits, htarget]
    refine div_le_div_of_nonneg_right ?_ hl2.le
    -- Gibbs: `f log f - f log g ≥ f - g` at every point.
    have hhi' : Integrable (fun x => f x * Real.log (f x)) := by
      have := hhi.mul_const (Real.log 2)
      refine this.congr (ae_of_all _ (fun x => ?_))
      simp only [Real.logb]
      field_simp
    have hgibbs : ∀ x, f x - gaussianPDFReal μ v x
        ≤ f x * Real.log (f x) - f x * Real.log (gaussianPDFReal μ v x) := by
      intro x
      have hg := gaussianPDFReal_pos μ v x hv
      rcases (hf0 x).eq_or_lt with h | h
      · rw [← h]; simp [hg.le]
      · have hl := Real.log_le_sub_one_of_pos (div_pos hg h)
        rw [Real.log_div hg.ne' h.ne'] at hl
        have : f x * (Real.log (gaussianPDFReal μ v x) - Real.log (f x))
            ≤ f x * (gaussianPDFReal μ v x / f x - 1) := mul_le_mul_of_nonneg_left hl h.le
        rw [mul_sub, mul_sub, mul_div_cancel₀ _ h.ne', mul_one] at this
        linarith
    have hint : ∫ x, (f x - gaussianPDFReal μ v x)
        ≤ ∫ x, (f x * Real.log (f x) - f x * Real.log (gaussianPDFReal μ v x)) :=
      integral_mono (hfi.sub (integrable_gaussianPDFReal μ v)) (hhi'.sub hgi) hgibbs
    rw [integral_sub hfi (integrable_gaussianPDFReal μ v), integral_sub hhi' hgi, hf1,
      integral_gaussianPDFReal_eq_one μ hv, hgint] at hint
    linarith
  · obtain ⟨hgvi, hgvar⟩ := gaussianPDFReal_moments μ v hv
    obtain ⟨-, hself⟩ := integral_mul_log_gaussianPDFReal (gaussianPDFReal μ v) μ v hv
      (integrable_gaussianPDFReal μ v) (integral_gaussianPDFReal_eq_one μ hv) hgvi hgvar
    rw [hbits, htarget, hself, neg_neg]

/-- **Changing units shifts differential entropy.** If a measured value `X` has density `f`
with defined differential entropy, then `aX` (the same value in units scaled by `a ≠ 0`) has
density `x ↦ f(x / a) / |a|`, and `h(aX) = h(X) + log₂ |a|`. -/
theorem differential_entropy_change_of_units (f : ℝ → ℝ) (a : ℝ) (ha : a ≠ 0)
    (hf0 : ∀ x, 0 ≤ f x) (hfi : Integrable f) (hf1 : ∫ x, f x = 1)
    (hhi : Integrable (fun x => f x * Real.logb 2 (f x))) :
    diffEntropyBits (fun x => f (x / a) / |a|) = diffEntropyBits f + Real.logb 2 |a| := by
  have hA : |a| ≠ 0 := abs_ne_zero.mpr ha
  unfold diffEntropyBits
  rw [Measure.integral_comp_div (fun y => f y / |a| * Real.logb 2 (f y / |a|)) a, smul_eq_mul,
    ← integral_const_mul]
  have hpt : ∀ y, |a| * (f y / |a| * Real.logb 2 (f y / |a|))
      = f y * Real.logb 2 (f y) - f y * Real.logb 2 |a| := by
    intro y
    by_cases hy : f y = 0
    · simp [hy]
    · rw [Real.logb_div hy hA]
      field_simp
  simp_rw [hpt]
  rw [integral_sub hhi (hfi.mul_const _), integral_mul_const, hf1]
  ring

-- The radio: noise 1, 2 and 4 and total power 5. The water level 4 pours exactly 5 units.
example : ∑ i, max 0 ((4 : ℝ) - ![1, 2, 4] i) = 5 := by
  simp [Fin.sum_univ_three]; norm_num
-- The water-filled powers are 3, 2 and 0.
example : max 0 ((4 : ℝ) - 1) = 3 ∧ max 0 ((4 : ℝ) - 2) = 2 ∧ max 0 ((4 : ℝ) - 4) = 0 := by
  norm_num
-- Capacity: ½ log₂(1 + 3/1) + ½ log₂(1 + 2/2) + ½ log₂(1 + 0/4) = 1 + ½ + 0 = 1.5 bits per use.
example : (1 / 2 : ℝ) * Real.logb 2 (1 + 3 / 1) + 1 / 2 * Real.logb 2 (1 + 2 / 2) +
    1 / 2 * Real.logb 2 (1 + 0 / 4) = 3 / 2 := by
  rw [show (1 : ℝ) + 3 / 1 = 2 ^ (2 : ℕ) by norm_num, show (1 : ℝ) + 2 / 2 = 2 by norm_num,
    show (1 : ℝ) + 0 / 4 = 1 by norm_num, Real.logb_pow, Real.logb_self_eq_one (by norm_num),
    Real.logb_one]
  norm_num
-- The grid search tries every split of 500 hundredths over three slots: 125,751 splits.
example : ∑ i ∈ Finset.range 501, (501 - i) = 125751 := by decide +kernel
-- Try changing: budget 12 raises the level to 19/3, above every floor.
example : ∑ i, max 0 ((19 / 3 : ℝ) - ![1, 2, 4] i) = 12 := by
  simp [Fin.sum_univ_three]; norm_num
-- Try changing: budget 1 fills only slot 1 (level 2), carrying ½ log₂ 2 = ½ bit.
example : ∑ i, max 0 ((2 : ℝ) - ![1, 2, 4] i) = 1 ∧
    (1 / 2 : ℝ) * Real.logb 2 (1 + 1 / 1) = 1 / 2 := by
  refine ⟨by simp [Fin.sum_univ_three]; norm_num, ?_⟩
  rw [show (1 : ℝ) + 1 / 1 = 2 by norm_num, Real.logb_self_eq_one (by norm_num)]
  norm_num
-- Try changing: slot 3's noise falls to 3, and the level drops to 11/3.
example : ∑ i, max 0 ((11 / 3 : ℝ) - ![1, 2, 3] i) = 5 := by
  simp [Fin.sum_univ_three]; norm_num
-- Doubling the spread from 2 to 4 raises the bell curve's h by exactly 1 bit.
example : (1 / 2 : ℝ) * Real.logb 2 (2 * π * exp 1 * 4 ^ 2) -
    1 / 2 * Real.logb 2 (2 * π * exp 1 * 2 ^ 2) = 1 := by
  have h : (0 : ℝ) < 2 * π * exp 1 := by positivity
  rw [show (2 : ℝ) * π * exp 1 * 4 ^ 2 = 2 ^ (2 : ℕ) * (2 * π * exp 1 * 2 ^ 2) by ring,
    Real.logb_mul (by positivity) (by positivity), Real.logb_pow,
    Real.logb_self_eq_one (by norm_num)]
  ring
-- A value flat on 0 to 0.5 has h = log₂ ½ = -1 bit: differential entropy can be negative.
example : Real.logb 2 (1 / 2) = -1 := by
  rw [one_div, Real.logb_inv, Real.logb_self_eq_one (by norm_num)]

#print axioms water_filling_is_best_split
#print axioms bell_curve_has_most_differential_entropy
#print axioms differential_entropy_change_of_units
