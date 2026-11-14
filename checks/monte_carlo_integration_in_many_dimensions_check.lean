-- Monte Carlo integration: for independent darts spread evenly over the box [-1, 1]^d, the average score has standard error σ/√N in every dimension d and the darts' estimate 2^d·K/N aims exactly at the ball's volume, while the darts' rate N^(-1/2) beats every midpoint grid N^(-2/d) exactly when d > 4 and every Simpson grid N^(-4/d) exactly when d > 8.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Distributions.Uniform
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum

namespace MonteCarloIntegrationInManyDimensions

open MeasureTheory ProbabilityTheory Filter

lemma rate_beats_iff (a b : ℝ) :
    (∀ σ C : ℝ, 0 < σ → 0 < C →
        ∀ᶠ N : ℕ in atTop, σ * (N : ℝ) ^ (-a) < C * (N : ℝ) ^ (-b)) ↔ b < a := by
  constructor
  · intro h
    by_contra hba
    push Not at hba
    obtain ⟨N, hN⟩ := ((h 1 1 one_pos one_pos).and (eventually_ge_atTop 1)).exists
    have h1 : (1 : ℝ) ≤ N := by exact_mod_cast hN.2
    have := Real.rpow_le_rpow_of_exponent_le h1 (neg_le_neg hba)
    linarith [hN.1]
  · intro hba σ C hσ hC
    have ht : Tendsto (fun N : ℕ => (N : ℝ) ^ (a - b)) atTop atTop :=
      (tendsto_rpow_atTop (sub_pos.mpr hba)).comp tendsto_natCast_atTop_atTop
    filter_upwards [ht.eventually_gt_atTop (σ / C), eventually_ge_atTop 1] with N hN hN1
    have hpos : (0 : ℝ) < N := by exact_mod_cast hN1
    have hsplit : (N : ℝ) ^ (-b) = (N : ℝ) ^ (a - b) * (N : ℝ) ^ (-a) := by
      rw [← Real.rpow_add hpos]; ring_nf
    rw [hsplit]
    have hp : 0 < (N : ℝ) ^ (-a) := Real.rpow_pos_of_pos hpos _
    have : σ < C * (N : ℝ) ^ (a - b) := by
      rw [div_lt_iff₀ hC] at hN; linarith
    nlinarith

#print axioms rate_beats_iff

/-- The card's main claim, Steps 1 and 2: a dart is one point of the box [-1, 1]^d (a list
of d coordinates), and its score is any measurable function `g` of the point (for the
volume of the ball, `g` is 2^d inside the ball and 0 outside). If the darts are independent
and each is spread evenly over the box, and one dart's score has finite spread σ (finite
variance), then the average score of N darts has standard error exactly σ/√N.
Nothing in the answer counts the dimension d: it enters only through σ. -/
theorem dart_average_standard_error_eq_sigma_div_sqrt {d : ℕ} {Ω : Type*} [MeasurableSpace Ω]
    {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → (Fin d → ℝ))
    (hind : iIndepFun X P)
    (hunif : ∀ i, pdf.IsUniform (X i) (Set.Icc (-1 : Fin d → ℝ) 1) P volume)
    (g : (Fin d → ℝ) → ℝ) (hg : Measurable g)
    (hσ : MemLp (fun ω => g (X 0 ω)) 2 P)
    (N : ℕ) (hN : 0 < N) :
    Real.sqrt (variance (fun ω => (∑ i ∈ Finset.range N, g (X i ω)) / N) P)
      = Real.sqrt (variance (fun ω => g (X 0 ω)) P) / Real.sqrt N := by
  set Y : ℕ → Ω → ℝ := fun i => g ∘ X i with hY
  have hident : ∀ i, IdentDistrib (Y i) (Y 0) P P := fun i =>
    (HasLaw.identDistrib (hunif i) (hunif 0)).comp hg
  have hmem : ∀ i, MemLp (Y i) 2 P := fun i => (hident i).symm.memLp_snd hσ
  have hindY : iIndepFun Y P := hind.comp (fun _ => g) (fun _ => hg)
  have hfun : (fun ω => (∑ i ∈ Finset.range N, g (X i ω)) / N)
      = fun ω => (N : ℝ)⁻¹ * (∑ i ∈ Finset.range N, Y i) ω := by
    funext ω; simp [hY, Finset.sum_apply, div_eq_inv_mul]
  rw [hfun, variance_const_mul, IndepFun.variance_sum (fun i _ => hmem i)
    (fun i _ j _ hij => hindY.indepFun hij)]
  have hv : ∀ i, variance (Y i) P = variance (fun ω => g (X 0 ω)) P := fun i =>
    (hident i).variance_eq
  simp only [hv, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  have hNR : (0 : ℝ) < N := by exact_mod_cast hN
  rw [eq_div_iff (Real.sqrt_pos.mpr hNR).ne', ← Real.sqrt_mul (by have := variance_nonneg (fun ω => g (X 0 ω)) P; positivity)]
  congr 1
  field_simp

/-- The estimate aims at the true volume (Step 1, and the first line of When it holds).
Score each dart 2^d if it lands in the unit ball {x : x₁² + ... + x_d² ≤ 1} and 0 if not.
If every dart is spread evenly over the box [-1, 1]^d, the estimate 2^d × K / N, where K is
the number of the first N darts inside the ball, has mean exactly the ball's volume. -/
theorem dart_estimate_mean_eq_ball_volume {d : ℕ} {Ω : Type*} [MeasurableSpace Ω]
    {P : Measure Ω} [IsProbabilityMeasure P]
    (X : ℕ → Ω → (Fin d → ℝ))
    (hunif : ∀ i, pdf.IsUniform (X i) (Set.Icc (-1 : Fin d → ℝ) 1) P volume)
    (N : ℕ) (hN : 0 < N) :
    ∫ ω, (2 : ℝ) ^ d * (∑ i ∈ Finset.range N,
        Set.indicator {x : Fin d → ℝ | ∑ j, x j ^ 2 ≤ 1} (fun _ => (1 : ℝ)) (X i ω)) / N ∂P
      = (volume {x : Fin d → ℝ | ∑ j, x j ^ 2 ≤ 1}).toReal := by
  set B : Set (Fin d → ℝ) := {x : Fin d → ℝ | ∑ j, x j ^ 2 ≤ 1} with hB
  have hBm : MeasurableSet B := measurableSet_le (by fun_prop) measurable_const
  have hBsub : B ⊆ Set.Icc (-1 : Fin d → ℝ) 1 := by
    intro x hx
    simp only [hB, Set.mem_ofPred_eq] at hx
    refine ⟨fun j => ?_, fun j => ?_⟩ <;>
    · have h1 : x j ^ 2 ≤ ∑ k, x k ^ 2 :=
        Finset.single_le_sum (f := fun k => x k ^ 2) (fun k _ => sq_nonneg _) (Finset.mem_univ j)
      simp only [Pi.neg_apply, Pi.one_apply]
      nlinarith [sq_nonneg (x j - 1), sq_nonneg (x j + 1)]
  have hvol : (volume (Set.Icc (-1 : Fin d → ℝ) 1)) = 2 ^ d := by
    rw [Real.volume_Icc_pi]
    simp only [Pi.one_apply, Pi.neg_apply, sub_neg_eq_add]
    norm_num
  have hf : ∀ i, AEStronglyMeasurable (B.indicator (fun _ => (1 : ℝ))) (Measure.map (X i) P) :=
    fun i => (stronglyMeasurable_const.indicator hBm).aestronglyMeasurable
  have hint : ∀ i, ∫ ω, Set.indicator B (fun _ => (1 : ℝ)) (X i ω) ∂P
      = (volume B).toReal / 2 ^ d := by
    intro i
    rw [← integral_map (hunif i).aemeasurable (hf i), integral_indicator_const _ hBm,
      (hunif i).map_eq, measureReal_def, cond_apply measurableSet_Icc, hvol,
      Set.inter_eq_right.mpr hBsub]
    simp [ENNReal.toReal_mul, div_eq_inv_mul]
  have hI : ∀ i, Integrable (fun ω => Set.indicator B (fun _ => (1 : ℝ)) (X i ω)) P := by
    intro i
    have : Integrable (B.indicator (fun _ => (1 : ℝ))) (Measure.map (X i) P) :=
      (integrable_const (1 : ℝ)).indicator hBm
    exact (integrable_map_measure (hf i) (hunif i).aemeasurable).mp this
  have hNR : (0 : ℝ) < N := by exact_mod_cast hN
  simp_rw [mul_div_assoc]
  rw [integral_const_mul, integral_div, integral_finsetSum _ (fun i _ => hI i)]
  simp only [hint, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  field_simp

/-- Step 5, comparing the powers. In dimension d ≥ 1 the darts' error is σ N^(-1/2), the
midpoint grid's is C N^(-2/d) and the Simpson grid's is C N^(-4/d). The darts win for all
large enough N, whatever the constants σ and C, exactly when d > 4 against the midpoint
grid and exactly when d > 8 against the Simpson grid. -/
theorem darts_beat_grid_iff_dimension_passes {d : ℕ} (hd : 0 < d) :
    ((∀ σ C : ℝ, 0 < σ → 0 < C →
        ∀ᶠ N : ℕ in atTop, σ * (N : ℝ) ^ (-(1 / 2 : ℝ)) < C * (N : ℝ) ^ (-(2 / (d : ℝ))))
      ↔ 4 < d) ∧
    ((∀ σ C : ℝ, 0 < σ → 0 < C →
        ∀ᶠ N : ℕ in atTop, σ * (N : ℝ) ^ (-(1 / 2 : ℝ)) < C * (N : ℝ) ^ (-(4 / (d : ℝ))))
      ↔ 8 < d) := by
  have hdR : (0 : ℝ) < d := by exact_mod_cast hd
  refine ⟨(rate_beats_iff _ _).trans ?_, (rate_beats_iff _ _).trans ?_⟩
  · rw [div_lt_iff₀ hdR]
    constructor
    · intro h; have : (4 : ℝ) < d := by linarith
      exact_mod_cast this
    · intro h; have : (4 : ℝ) < d := by exact_mod_cast h
      linarith
  · rw [div_lt_iff₀ hdR]
    constructor
    · intro h; have : (8 : ℝ) < d := by linarith
      exact_mod_cast this
    · intro h; have : (8 : ℝ) < d := by exact_mod_cast h
      linarith

/-! ### The card's whole-number worked examples -/

-- The box [-1, 1]^10 has volume 2^10 = 1,024.
example : (2 : ℕ) ^ 10 = 1024 := by norm_num

-- Grids of 3, 4, 5 and 6 points per axis in 10 dimensions.
example : (3 : ℕ) ^ 10 = 59049 := by norm_num
example : (4 : ℕ) ^ 10 = 1048576 := by norm_num
example : (5 : ℕ) ^ 10 = 9765625 := by norm_num
example : (6 : ℕ) ^ 10 = 60466176 := by norm_num

-- The 6-per-axis grid costs about 605 times the darts' budget of 100,000.
example : 604 * 100000 < (60466176 : ℕ) ∧ (60466176 : ℕ) < 605 * 100000 := by norm_num

-- The estimate's numerator: 1,024 × 268 darts inside.
example : (1024 * 268 : ℕ) = 274432 := by norm_num

-- Step 5: the crossovers 2/d = 1/2 at d = 4 and 4/d = 1/2 at d = 8; in 10 dimensions
-- both grid powers fall below the darts' 1/2.
example : (2 : ℚ) / 4 = 1 / 2 ∧ (4 : ℚ) / 8 = 1 / 2 := by norm_num
example : (2 : ℚ) / 10 < 1 / 2 ∧ (4 : ℚ) / 10 < 1 / 2 := by norm_num

-- Step 6: with 4 points per axis every coordinate is ±1/4 or ±3/4. The 2^10 = 1,024 points
-- with all coordinates ±1/4 have squared distance 10/16 ≤ 1 (inside); the next shell,
-- one coordinate ±3/4, has squared distance 18/16 > 1 (outside).
example : 10 * (1 / 4 : ℚ) ^ 2 = 10 / 16 ∧ 10 * (1 / 4 : ℚ) ^ 2 ≤ 1 := by norm_num
example : 9 * (1 / 4 : ℚ) ^ 2 + (3 / 4 : ℚ) ^ 2 = 18 / 16 ∧ 1 < 9 * (1 / 4 : ℚ) ^ 2 + (3 / 4 : ℚ) ^ 2 := by
  norm_num

-- Step 5 in costs: a tenth of the error in 10 dimensions takes 10^2 = 100 times the darts
-- and 10^(10/2) = 100,000 times the midpoint points.
example : (10 : ℕ) ^ 2 = 100 ∧ (10 : ℕ) ^ (10 / 2) = 100000 := by norm_num

#print axioms dart_average_standard_error_eq_sigma_div_sqrt
#print axioms dart_estimate_mean_eq_ball_volume
#print axioms darts_beat_grid_iff_dimension_passes

end MonteCarloIntegrationInManyDimensions
