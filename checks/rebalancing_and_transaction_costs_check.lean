-- Rebalancing: the cube-root half-width is the unique minimiser of the band's yearly loss, the one-shot band is the clamp to the target plus or minus c over kappa, and the shortfall from Merton's peak is a square.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-- The no-trade band's half-width. A band of half-width `h` loses
`L(h) = (γσ²/2)(h²/3) + c s²/(2h)` of the fund a year (drift loss plus trading bill),
where `s = π*(1-π*)σ` is how fast the weight wanders. For a cost `c > 0`, risk
aversion `γ > 0`, share spread `σ > 0` and a target weight `π*` strictly between
0 and 1, the half-width `h = ((3c/(2γ)) π*² (1-π*)²)^(1/3)` is positive and every
other positive half-width has a strictly larger yearly loss. -/
theorem no_trade_band_cube_root_half_width_minimises_loss
    (c γ σ πs : ℝ) (hc : 0 < c) (hγ : 0 < γ) (hσ : 0 < σ)
    (hπ0 : 0 < πs) (hπ1 : πs < 1) :
    let s := πs * (1 - πs) * σ
    let L : ℝ → ℝ := fun h => γ * σ ^ 2 / 2 * (h ^ 2 / 3) + c * s ^ 2 / (2 * h)
    let hstar := (3 * c / (2 * γ) * πs ^ 2 * (1 - πs) ^ 2) ^ ((1 : ℝ) / 3)
    0 < hstar ∧ ∀ h : ℝ, 0 < h → h ≠ hstar → L hstar < L h := by
  intro s L hstar
  have hA : 0 < 3 * c / (2 * γ) * πs ^ 2 * (1 - πs) ^ 2 := by
    have : 0 < 1 - πs := by linarith
    positivity
  have ht : 0 < hstar := Real.rpow_pos_of_pos hA _
  have ht3 : hstar ^ 3 = 3 * c / (2 * γ) * πs ^ 2 * (1 - πs) ^ 2 := by
    show ((3 * c / (2 * γ) * πs ^ 2 * (1 - πs) ^ 2) ^ ((1 : ℝ) / 3)) ^ 3 = _
    rw [← Real.rpow_natCast, ← Real.rpow_mul hA.le]
    norm_num
  refine ⟨ht, fun h hh hne => ?_⟩
  have hb : c * s ^ 2 = 2 * γ * σ ^ 2 / 3 * hstar ^ 3 := by
    rw [ht3]; simp only [s]; field_simp
  have key : L h - L hstar = γ * σ ^ 2 / 6 * ((h - hstar) ^ 2 * (h + 2 * hstar)) / h := by
    simp only [L]
    rw [hb]
    field_simp
    ring
  have hpos : 0 < γ * σ ^ 2 / 6 * ((h - hstar) ^ 2 * (h + 2 * hstar)) / h := by
    have : 0 < (h - hstar) ^ 2 := by
      have : h - hstar ≠ 0 := sub_ne_zero.mpr hne
      positivity
    have : 0 < h + 2 * hstar := by linarith
    positivity
  linarith

/-- The one-shot band. If a gap left now costs `(κ/2)(z - π*)²` and moving the weight
from `x` to `z` costs `c|z - x|`, with `κ > 0` and `c > 0`, then the unique best
weight after trading is the clamp `min(π* + c/κ, max(π* - c/κ, x))`: keep `x`
inside the band, otherwise move to its nearest edge. -/
theorem one_shot_band_is_clamp
    (κ c πs x : ℝ) (hκ : 0 < κ) (hc : 0 < c) :
    let f : ℝ → ℝ := fun z => κ / 2 * (z - πs) ^ 2 + c * |z - x|
    let zstar := min (πs + c / κ) (max (πs - c / κ) x)
    ∀ z : ℝ, z ≠ zstar → f zstar < f z := by
  intro f zstar z hz
  obtain ⟨d, hd, rfl⟩ : ∃ d, 0 < d ∧ c = κ * d := ⟨c / κ, div_pos hc hκ, by field_simp⟩
  have hdd : κ * d / κ = d := by field_simp
  have hsq : 0 < (z - zstar) ^ 2 := by
    have : z - zstar ≠ 0 := sub_ne_zero.mpr hz
    positivity
  have h1 : 0 < κ * (z - zstar) ^ 2 := mul_pos hκ hsq
  have hzs : zstar = min (πs + d) (max (πs - d) x) := by simp only [zstar, hdd]
  clear_value zstar
  subst hzs
  simp only [f]
  have hab := abs_nonneg (z - x)
  have hle := le_abs_self (z - x)
  have hle' := neg_abs_le (z - x)
  rcases le_total x (πs - d) with hx | hx
  · rw [max_eq_left hx, min_eq_right (by linarith)] at *
    rw [abs_of_nonneg (by linarith : (0:ℝ) ≤ πs - d - x)]
    nlinarith [mul_le_mul_of_nonneg_left (show x - z ≤ |z - x| by linarith) (le_of_lt (mul_pos hκ hd))]
  · rw [max_eq_right hx] at *
    rcases le_total x (πs + d) with hx2 | hx2
    · rw [min_eq_right hx2] at *
      rw [sub_self, abs_zero]
      nlinarith [mul_le_mul_of_nonneg_left (show x - z ≤ |z - x| by linarith) (le_of_lt (mul_pos hκ hd)),
        mul_le_mul_of_nonneg_left (show z - x ≤ |z - x| by linarith) (le_of_lt (mul_pos hκ hd)),
        mul_nonneg hκ.le (sub_nonneg.mpr hx), mul_nonneg hκ.le (sub_nonneg.mpr hx2)]
    · rw [min_eq_left hx2] at *
      rw [abs_of_nonpos (by linarith : πs + d - x ≤ 0)]
      nlinarith [mul_le_mul_of_nonneg_left (show z - x ≤ |z - x| by linarith) (le_of_lt (mul_pos hκ hd))]

/-- The price of being off target. With `γ > 0`, `σ > 0` and Merton's fraction
`π* = (μ - r)/(γσ²)`, the certainty-equivalent return `r + z(μ - r) - ½γσ²z²`
falls short of its value at `π*` by exactly `½γσ²(z - π*)²`. -/
theorem certainty_equivalent_shortfall_eq_square
    (r μ γ σ z : ℝ) (hγ : 0 < γ) (hσ : 0 < σ) :
    let πs := (μ - r) / (γ * σ ^ 2)
    let CE : ℝ → ℝ := fun w => r + w * (μ - r) - 1 / 2 * γ * σ ^ 2 * w ^ 2
    CE πs - CE z = 1 / 2 * γ * σ ^ 2 * (z - πs) ^ 2 := by
  intro πs CE
  simp only [πs, CE]
  field_simp
  ring

-- The card's worked numbers, as exact fractions:
-- μ - r = 6/100, γ = 5/2, σ = 1/5, c = 1/1000, π* = 3/5, x = 13/20, W = 100000.

-- Merton's fraction: (μ - r)/(γσ²) = 0.06/0.1 = 0.60.
example : ((6 : ℚ) / 100) / (5 / 2 * (1 / 5) ^ 2) = 3 / 5 := by norm_num

-- Loss rate at 65%: (γσ²/2)(0.05)² × 100,000 = $12.50 a year.
example : (5 / 2 * (1 / 5 : ℚ) ^ 2) / 2 * (13 / 20 - 3 / 5) ^ 2 * 100000 = 25 / 2 := by norm_num

-- One-shot band at 65%: c/κ = 0.01, so the clamp lands on 61%.
example : min ((3 : ℚ) / 5 + 1 / 100) (max (3 / 5 - 1 / 100) (13 / 20)) = 61 / 100 := by
  norm_num

-- One-shot losses per $100,000: wait $12.50, sell to 60% $5.00, sell to 61% $4.50.
example : ((1 : ℚ) / 10 / 2 * (13 / 20 - 3 / 5) ^ 2 + 1 / 1000 * |13 / 20 - 13 / 20|) * 100000
    = 25 / 2 := by norm_num
example : ((1 : ℚ) / 10 / 2 * (3 / 5 - 3 / 5) ^ 2 + 1 / 1000 * |3 / 5 - 13 / 20|) * 100000
    = 5 := by norm_num
example : ((1 : ℚ) / 10 / 2 * (61 / 100 - 3 / 5) ^ 2 + 1 / 1000 * |61 / 100 - 13 / 20|) * 100000
    = 9 / 2 := by norm_num

-- The weight's spread: s = 0.6 × 0.4 × 0.20 = 0.048, and π*²(1-π*)² = 0.0576.
example : (3 / 5 : ℚ) * (2 / 5) * (1 / 5) = 48 / 1000 := by norm_num
example : (3 / 5 : ℚ) ^ 2 * (2 / 5) ^ 2 = 576 / 10000 := by norm_num

-- h³ = 1.5 × 0.001 × 0.0576 / 2.5 = 0.00003456.
example : (3 : ℚ) * (1 / 1000) / (2 * (5 / 2)) * (3 / 5) ^ 2 * (2 / 5) ^ 2 = 3456 / 100000000 := by
  norm_num

#print axioms no_trade_band_cube_root_half_width_minimises_loss
#print axioms one_shot_band_is_clamp
#print axioms certainty_equivalent_shortfall_eq_square
