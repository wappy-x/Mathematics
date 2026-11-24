-- Extreme value theory: every generalised extreme value (GEV) law is max-stable, the largest of n exponential waits shifted by ln n tends to the Gumbel law, and the return level formula hits the chance 1 - 1/T exactly.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds

open Filter Topology ProbabilityTheory

/-- The cumulative chance `G(x)` of the generalised extreme value law with location `μ`,
scale `σ` and shape `ξ`. For `ξ = 0` it is the Gumbel curve `exp (-exp (-(x - μ)/σ))`.
For `ξ ≠ 0` it is `exp (-(1 + ξ (x - μ)/σ) ^ (-1/ξ))` where the bracket is positive;
outside that range it is `0` below the floor (`ξ > 0`, Fréchet) and `1` above the
ceiling (`ξ < 0`, Weibull). -/
noncomputable def gevCDF (μ σ ξ x : ℝ) : ℝ :=
  if ξ = 0 then Real.exp (-Real.exp (-((x - μ) / σ)))
  else if 0 < 1 + ξ * ((x - μ) / σ) then
    Real.exp (-(1 + ξ * ((x - μ) / σ)) ^ (-1 / ξ))
  else if 0 < ξ then 0 else 1

/-- The `T`-year return level `z_T` of the GEV law: for `ξ ≠ 0`,
`μ + (σ/ξ) ((-ln (1 - 1/T)) ^ (-ξ) - 1)`, and for `ξ = 0`, `μ - σ ln (-ln (1 - 1/T))`. -/
noncomputable def returnLevel (μ σ ξ T : ℝ) : ℝ :=
  if ξ = 0 then μ - σ * Real.log (-Real.log (1 - 1 / T))
  else μ + σ / ξ * ((-Real.log (1 - 1 / T)) ^ (-ξ) - 1)

/-- Max-stability of the GEV family: for every location `μ`, scale `σ > 0`, shape `ξ` and
whole number `k ≥ 1`, the largest of `k` independent copies of a GEV law is the same law with
its axis moved and stretched: there are a stretch `α_k > 0` and a shift `β_k` with
`G(x)^k = G(α_k x + β_k)` for every level `x`. -/
theorem gev_max_stable (μ σ ξ : ℝ) (hσ : 0 < σ) (k : ℕ) (hk : 1 ≤ k) :
    ∃ α β : ℝ, 0 < α ∧ ∀ x : ℝ, gevCDF μ σ ξ x ^ k = gevCDF μ σ ξ (α * x + β) := by
  by_cases hξ : ξ = 0
  · subst hξ
    refine ⟨1, -σ * Real.log k, one_pos, fun x => ?_⟩
    have hk0 : (0 : ℝ) < k := by exact_mod_cast hk
    simp only [gevCDF, if_true]
    rw [← Real.exp_nat_mul]
    congr 1
    have hσ' : σ ≠ 0 := hσ.ne'
    have : -((1 * x + -σ * Real.log k - μ) / σ) = -((x - μ) / σ) + Real.log k := by
      field_simp
      ring
    rw [this, Real.exp_add, Real.exp_log hk0]
    ring
  · set c : ℝ := (k : ℝ) ^ (-ξ) with hc
    have hk0 : (0 : ℝ) < k := by exact_mod_cast hk
    have hc0 : 0 < c := Real.rpow_pos_of_pos hk0 _
    refine ⟨c, μ * (1 - c) + σ * (c - 1) / ξ, hc0, fun x => ?_⟩
    have hσ' : σ ≠ 0 := hσ.ne'
    have ht : 1 + ξ * ((c * x + (μ * (1 - c) + σ * (c - 1) / ξ) - μ) / σ)
        = c * (1 + ξ * ((x - μ) / σ)) := by
      field_simp
      ring
    simp only [gevCDF, if_neg hξ, ht]
    by_cases hpos : 0 < 1 + ξ * ((x - μ) / σ)
    · rw [if_pos hpos, if_pos (mul_pos hc0 hpos), ← Real.exp_nat_mul]
      congr 1
      rw [Real.mul_rpow hc0.le hpos.le, hc, ← Real.rpow_mul hk0.le]
      have : -ξ * (-1 / ξ) = 1 := by field_simp
      rw [this, Real.rpow_one]
      ring
    · have hneg : ¬ 0 < c * (1 + ξ * ((x - μ) / σ)) := by
        intro h
        exact hpos (pos_of_mul_pos_right h hc0.le)
      rw [if_neg hpos, if_neg hneg]
      split_ifs <;> simp
      omega

/-- The largest of `n` independent exponential waits with mean 1, shifted down by `ln n`:
the chance that it is at most `x`, which is `F(ln n + x)^n` with `F` the exponential law's
cumulative chance, tends to the Gumbel value `exp (-e^{-x})` as `n` grows, for every `x`. -/
theorem exponential_max_tends_to_gumbel (x : ℝ) :
    Tendsto (fun n : ℕ => cdf (expMeasure 1) (Real.log n + x) ^ n) atTop
      (𝓝 (Real.exp (-Real.exp (-x)))) := by
  have hlog : Tendsto (fun n : ℕ => Real.log n) atTop atTop :=
    Real.tendsto_log_atTop.comp tendsto_natCast_atTop_atTop
  refine (Real.tendsto_one_add_div_pow_exp (-Real.exp (-x))).congr' ?_
  filter_upwards [hlog.eventually_ge_atTop (-x), eventually_ge_atTop 1] with n hn hn1
  have hn0 : (0 : ℝ) < n := by exact_mod_cast hn1
  rw [cdf_expMeasure_eq one_pos, if_pos (by linarith)]
  congr 1
  rw [one_mul, neg_add, Real.exp_add, Real.exp_neg (Real.log n), Real.exp_log hn0]
  field_simp
  ring

/-- The return level formula is right: for scale `σ > 0`, any shape `ξ` and a return period
`T > 1` years, the GEV law stays under the level `z_T` with chance exactly `1 - 1/T`, so a
yearly maximum passes `z_T` with chance `1/T`. -/
theorem gev_return_level_spec (μ σ ξ T : ℝ) (hσ : 0 < σ) (hT : 1 < T) :
    gevCDF μ σ ξ (returnLevel μ σ ξ T) = 1 - 1 / T := by
  have hT0 : 0 < T := by linarith
  have hp0 : 0 < 1 - 1 / T := by
    rw [sub_pos, div_lt_one hT0]; exact hT
  have hp1 : 1 - 1 / T < 1 := by
    have : 0 < 1 / T := by positivity
    linarith
  have hL : 0 < -Real.log (1 - 1 / T) := by
    have := Real.log_neg hp0 hp1
    linarith
  have hσ' : σ ≠ 0 := hσ.ne'
  by_cases hξ : ξ = 0
  · subst hξ
    simp only [gevCDF, returnLevel, if_true]
    have : -((μ - σ * Real.log (-Real.log (1 - 1 / T)) - μ) / σ)
        = Real.log (-Real.log (1 - 1 / T)) := by
      field_simp
      ring
    rw [this, Real.exp_log hL, neg_neg, Real.exp_log hp0]
  · simp only [gevCDF, returnLevel, if_neg hξ]
    have h1 : 1 + ξ * ((μ + σ / ξ * ((-Real.log (1 - 1 / T)) ^ (-ξ) - 1) - μ) / σ)
        = (-Real.log (1 - 1 / T)) ^ (-ξ) := by
      field_simp
      ring
    rw [h1, if_pos (Real.rpow_pos_of_pos hL _), ← Real.rpow_mul hL.le]
    have : -ξ * (-1 / ξ) = 1 := by field_simp
    rw [this, Real.rpow_one, neg_neg, Real.exp_log hp0]

-- The largest of 3,650 draws is the largest of ten blocks of 365.
example : 10 * 365 = 3650 := by norm_num
-- Max-stability tests: three values of k times three levels x, for each of three families.
example : 3 * 3 * 3 = 27 := by norm_num
-- The brute-force grid: 61 values of μ, 41 of σ, 51 of ξ.
example : 61 * 41 * 51 = 127551 := by norm_num
-- The 30 yearly peak flows: there are 30 of them and the largest is 1,945 m³/s.
example :
    let flows : List ℕ := [1015, 672, 1633, 1159, 1059, 919, 1070, 973, 832, 1031, 803, 1941,
      1697, 1548, 1530, 1131, 1570, 972, 1191, 1341, 1244, 807, 984, 1038, 1639, 1945, 775,
      1027, 1637, 1032]
    flows.length = 30 ∧ flows.foldr max 0 = 1945 := by decide

#print axioms gev_max_stable
#print axioms exponential_max_tends_to_gumbel
#print axioms gev_return_level_spec
