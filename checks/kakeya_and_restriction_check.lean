-- Kakeya: the Perron-tree area bound with the card's rising ratio α = 1 − log(k+1)/(2k) falls to zero, a fixed ratio stalls at 2(1 − α)/(1 + α), and the Cantor set's cover sums jump from infinite to zero at s = log 2 / log 3.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecificLimits.Basic

open Filter Topology

namespace KakeyaRestriction

/-- The card's Perron-tree bound, as a share of the starting triangle's area `|T|`: after `k`
rounds of sliding with ratio `α`, the tree's area is at most
`α^(2k) + 2(1 − α)² (1 − α^(2k)) / (1 − α²)` times `|T|`. The first term is the last main
triangle; the second adds up the sprouts each round leaves behind. -/
noncomputable def perronBound (k : ℕ) (α : ℝ) : ℝ :=
  α ^ (2 * k) + 2 * (1 - α) ^ 2 * (1 - α ^ (2 * k)) / (1 - α ^ 2)

/-- The card's rising rule for the ratio at `k` rounds: `α = 1 − log(k+1)/(2k)`. -/
noncomputable def risingRatio (k : ℕ) : ℝ :=
  1 - Real.log (k + 1) / (2 * k)

/-- One merge (`k = 1`) leaves `α² + 2(1 − α)²` of the triangle: the main triangle plus two sprouts. -/
def oneMerge (α : ℝ) : ℝ :=
  α ^ 2 + 2 * (1 - α) ^ 2

/-- The middle-thirds Cantor set's cover sum at stage `k` and trial dimension `s`: `2^k` pieces,
each of length `3^(−k)`, each weighed by its length to the power `s`. -/
noncomputable def cantorSum (k : ℕ) (s : ℝ) : ℝ :=
  (2 : ℝ) ^ k * ((3 : ℝ) ^ (-(k : ℝ))) ^ s

/-- Rewriting the bound around the floor `2(1 − α)/(1 + α)`. -/
theorem perronBound_eq (k : ℕ) (α : ℝ) (h0 : 0 < α) (h1 : α < 1) :
    perronBound k α = 2 * (1 - α) / (1 + α) + (α ^ 2) ^ k * (1 - 2 * (1 - α) / (1 + α)) := by
  unfold perronBound
  have ha : (1 : ℝ) - α ^ 2 ≠ 0 := by nlinarith
  have hb : (1 : ℝ) + α ≠ 0 := by linarith
  rw [pow_mul]
  field_simp
  ring

/-- The cantor sum as a power of a single exponential. -/
theorem cantorSum_eq (k : ℕ) (s : ℝ) :
    cantorSum k s = Real.exp (Real.log 2 - s * Real.log 3) ^ k := by
  unfold cantorSum
  rw [← Real.rpow_mul (by norm_num), ← Real.rpow_natCast,
    Real.rpow_def_of_pos (by norm_num), Real.rpow_def_of_pos (by norm_num), ← Real.exp_add,
    ← Real.exp_nat_mul]
  congr 1
  ring

#print axioms perronBound_eq
#print axioms cantorSum_eq

/-- Sliding thin triangles makes the area fall towards zero: with the rising rule
`α = 1 − log(k+1)/(2k)`, the ratio stays strictly between 1/2 and 1 for every `k ≥ 1` (so the
merge formula applies), and the Perron-tree bound `α^(2k) + 2(1 − α)²(1 − α^(2k))/(1 − α²)`
tends to 0 as the number of rounds `k` grows. -/
theorem perron_bound_tendsto_zero :
    (∀ k : ℕ, 1 ≤ k → 1 / 2 < risingRatio k ∧ risingRatio k < 1) ∧
      Tendsto (fun k : ℕ => perronBound k (risingRatio k)) atTop (𝓝 0) := by
  have hratio : ∀ k : ℕ, 1 ≤ k → 1 / 2 < risingRatio k ∧ risingRatio k < 1 := by
    intro k hk
    have hk' : (1 : ℝ) ≤ k := by exact_mod_cast hk
    have hlogpos : 0 < Real.log ((k : ℝ) + 1) := Real.log_pos (by linarith)
    have hloglt : Real.log ((k : ℝ) + 1) < k := by
      have := Real.log_lt_sub_one_of_pos (x := (k : ℝ) + 1) (by linarith) (by linarith)
      linarith
    unfold risingRatio
    constructor
    · rw [div_lt_iff₀ (by norm_num)] at *
      have : Real.log ((k : ℝ) + 1) / (2 * k) < 1 / 2 := by
        rw [div_lt_iff₀ (by positivity)]; linarith
      linarith
    · have : 0 < Real.log ((k : ℝ) + 1) / (2 * k) := by positivity
      linarith
  refine ⟨hratio, ?_⟩
  -- ε k = log(k+1)/(2k) tends to 0
  have hε : Tendsto (fun k : ℕ => Real.log ((k : ℝ) + 1) / (2 * k)) atTop (𝓝 0) := by
    have h := (Real.tendsto_pow_log_div_mul_add_atTop 2 (-2) 1 (by norm_num)).comp
      (tendsto_atTop_add_const_right atTop (1 : ℝ) tendsto_natCast_atTop_atTop)
    refine h.congr' ?_
    filter_upwards with k
    simp only [Function.comp, pow_one]
    congr 1
    ring
  have hinv : Tendsto (fun k : ℕ => ((k : ℝ) + 1)⁻¹) atTop (𝓝 0) :=
    tendsto_inv_atTop_zero.comp (tendsto_atTop_add_const_right atTop (1 : ℝ)
      tendsto_natCast_atTop_atTop)
  have hup : Tendsto (fun k : ℕ => ((k : ℝ) + 1)⁻¹ + 2 * (Real.log ((k : ℝ) + 1) / (2 * k)))
      atTop (𝓝 0) := by
    simpa using hinv.add (hε.const_mul 2)
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hup ?_ ?_
  · filter_upwards [eventually_ge_atTop 1] with k hk
    obtain ⟨h1, h2⟩ := hratio k hk
    rw [perronBound_eq k _ (by linarith) h2]
    have hp : 0 ≤ (risingRatio k ^ 2) ^ k := by positivity
    have hF : 0 ≤ 1 - 2 * (1 - risingRatio k) / (1 + risingRatio k) := by
      rw [sub_nonneg, div_le_one (by linarith)]; linarith
    have hF0 : 0 ≤ 2 * (1 - risingRatio k) / (1 + risingRatio k) := by
      apply div_nonneg <;> linarith
    have := mul_nonneg hp hF
    linarith
  · filter_upwards [eventually_ge_atTop 1] with k hk
    obtain ⟨h1, h2⟩ := hratio k hk
    have hk' : (1 : ℝ) ≤ k := by exact_mod_cast hk
    set ε := Real.log ((k : ℝ) + 1) / (2 * k) with hεdef
    have hα : risingRatio k = 1 - ε := rfl
    rw [perronBound_eq k _ (by linarith) h2]
    -- the power term is at most 1/(k+1)
    have hpow : (risingRatio k ^ 2) ^ k ≤ ((k : ℝ) + 1)⁻¹ := by
      have hle : risingRatio k ≤ Real.exp (-ε) := by
        have := Real.add_one_le_exp (-ε); rw [hα]; linarith
      have h0 : 0 ≤ risingRatio k := by linarith
      calc (risingRatio k ^ 2) ^ k ≤ (Real.exp (-ε) ^ 2) ^ k := by gcongr
        _ = Real.exp (((2 * k : ℕ) : ℝ) * (-ε)) := by rw [Real.exp_nat_mul, pow_mul]
        _ = Real.exp (-Real.log ((k : ℝ) + 1)) := by
          congr 1
          rw [hεdef]; push_cast
          field_simp
        _ = ((k : ℝ) + 1)⁻¹ := by
          rw [Real.exp_neg, Real.exp_log (by positivity)]
    have hF1 : 1 - 2 * (1 - risingRatio k) / (1 + risingRatio k) ≤ 1 := by
      have : 0 ≤ 2 * (1 - risingRatio k) / (1 + risingRatio k) := by
        apply div_nonneg <;> linarith
      linarith
    have hF0 : 0 ≤ 1 - 2 * (1 - risingRatio k) / (1 + risingRatio k) := by
      rw [sub_nonneg, div_le_one (by linarith)]; linarith
    have hfloor : 2 * (1 - risingRatio k) / (1 + risingRatio k) ≤ 2 * ε := by
      rw [div_le_iff₀ (by linarith), hα]
      have : 0 ≤ ε := by rw [hα] at h2; linarith
      nlinarith
    have hp : 0 ≤ (risingRatio k ^ 2) ^ k := by positivity
    have : (risingRatio k ^ 2) ^ k * (1 - 2 * (1 - risingRatio k) / (1 + risingRatio k)) ≤
        ((k : ℝ) + 1)⁻¹ := by
      calc _ ≤ (risingRatio k ^ 2) ^ k * 1 := by gcongr
        _ ≤ _ := by rw [mul_one]; exact hpow
    linarith

/-- A fixed ratio stalls: for a fixed `α` with `1/2 < α < 1`, the Perron-tree bound never drops
below the floor `2(1 − α)/(1 + α)`, which is positive, and it tends to that floor as `k` grows
(at `α = 2/3` the floor is 0.4). -/
theorem fixed_ratio_stalls (α : ℝ) (h1 : 1 / 2 < α) (h2 : α < 1) :
    0 < 2 * (1 - α) / (1 + α) ∧
      (∀ k : ℕ, 2 * (1 - α) / (1 + α) ≤ perronBound k α) ∧
      Tendsto (fun k : ℕ => perronBound k α) atTop (𝓝 (2 * (1 - α) / (1 + α))) := by
  have hF0 : 0 < 2 * (1 - α) / (1 + α) := by apply div_pos <;> linarith
  have hF1 : 0 ≤ 1 - 2 * (1 - α) / (1 + α) := by
    rw [sub_nonneg, div_le_one (by linarith)]; linarith
  refine ⟨hF0, ?_, ?_⟩
  · intro k
    rw [perronBound_eq k α (by linarith) h2]
    have : 0 ≤ (α ^ 2) ^ k * (1 - 2 * (1 - α) / (1 + α)) := by positivity
    linarith
  · have hq : Tendsto (fun k : ℕ => (α ^ 2) ^ k) atTop (𝓝 0) :=
      tendsto_pow_atTop_nhds_zero_of_lt_one (by positivity) (by nlinarith)
    have := (hq.mul_const (1 - 2 * (1 - α) / (1 + α))).const_add (2 * (1 - α) / (1 + α))
    simp only [zero_mul, add_zero] at this
    refine this.congr' ?_
    filter_upwards with k
    rw [perronBound_eq k α (by linarith) h2]

/-- The Cantor set's Hausdorff sums jump at `s = log 2 / log 3`: there every stage's cover sum
`2^k (3^(−k))^s` equals 1; below it the sums grow without end; above it they fall to 0. -/
theorem cantor_sums_jump_at_log2_div_log3 :
    (∀ k : ℕ, cantorSum k (Real.log 2 / Real.log 3) = 1) ∧
      (∀ s : ℝ, s < Real.log 2 / Real.log 3 →
        Tendsto (fun k : ℕ => cantorSum k s) atTop atTop) ∧
      (∀ s : ℝ, Real.log 2 / Real.log 3 < s →
        Tendsto (fun k : ℕ => cantorSum k s) atTop (𝓝 0)) := by
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hl3 : 0 < Real.log 3 := Real.log_pos (by norm_num)
  refine ⟨?_, ?_, ?_⟩
  · intro k
    rw [cantorSum_eq]
    have : Real.log 2 - Real.log 2 / Real.log 3 * Real.log 3 = 0 := by
      field_simp; ring
    rw [this, Real.exp_zero, one_pow]
  · intro s hs
    have hc : 0 < Real.log 2 - s * Real.log 3 := by
      rw [lt_div_iff₀ hl3] at hs; linarith
    simp_rw [cantorSum_eq]
    exact tendsto_pow_atTop_atTop_of_one_lt (Real.one_lt_exp_iff.mpr hc)
  · intro s hs
    have hc : Real.log 2 - s * Real.log 3 < 0 := by
      rw [div_lt_iff₀ hl3] at hs; linarith
    simp_rw [cantorSum_eq]
    exact tendsto_pow_atTop_nhds_zero_of_lt_one (Real.exp_pos _).le (Real.exp_lt_one_iff.mpr hc)

/-! The card's exact worked numbers. -/

-- One merge: no slide (α = 1) keeps the whole triangle; α = 2/3 leaves 2/3; α = 1/2 leaves 3/4.
example : oneMerge 1 = 1 ∧ oneMerge (2 / 3) = 2 / 3 ∧ oneMerge (1 / 2) = 3 / 4 := by
  norm_num [oneMerge]

-- At α = 0.4 = 2/5 the formula gives 0.88 = 22/25 (the code's sweep finds less).
example : oneMerge (2 / 5) = 22 / 25 := by
  norm_num [oneMerge]

-- The one-merge formula agrees with the bound at k = 1.
example (α : ℝ) (h : α ^ 2 ≠ 1) : perronBound 1 α = oneMerge α := by
  unfold perronBound oneMerge
  have h' : (1 : ℝ) - α ^ 2 ≠ 0 := sub_ne_zero.mpr (Ne.symm h)
  field_simp

-- The fixed ratio 2/3 stalls at the floor 2(1 − 2/3)/(1 + 2/3) = 2/5 = 0.4000.
example : 2 * (1 - (2 / 3 : ℝ)) / (1 + 2 / 3) = 2 / 5 := by
  norm_num

-- Eight rounds: 2^8 = 256 thin triangles; three trees need 3 × 256 − 1 = 767 Pál joins.
example : 2 ^ 8 = 256 ∧ 3 * 2 ^ 8 - 1 = 767 := by
  decide

#print axioms perron_bound_tendsto_zero
#print axioms fixed_ratio_stalls
#print axioms cantor_sums_jump_at_log2_div_log3

end KakeyaRestriction
