-- The stochastic block model: on the branching tree around one person, the census signal-to-noise ratio r_t equals (λ - 1)/(1 - λ^(-t)) with λ = c θ², so it settles at λ - 1 above the Kesten–Stigum line λ > 1 and dies to 0 below it, and λ > 1 is the same as (c_in - c_out)² > 2(c_in + c_out).
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

namespace StochasticBlockModelAndDetectability

open Filter Topology

/-! Setting. On the tree around one person, each person has on average `c` further friends
(`c` is the mean degree), and `θ` is the chance that a friend is on your side minus the chance
that they are not. `m t` is the average census at depth `t` (the sum of labels at depth `t`,
root label `+1`) and `M t` the average of its square; they obey the card's two rules
`m (t+1) = c θ m t`, `M (t+1) = c M t + (c θ m t)²`, starting from `m 0 = M 0 = 1`.
The census signal-to-noise ratio is `r t = m t ^ 2 / (M t - m t ^ 2)`, and `λ = c θ²`. -/

/-- The average census at depth `t` is `(c θ)^t`. -/
theorem census_mean_eq (c θ : ℝ) (m : ℕ → ℝ) (hm0 : m 0 = 1)
    (hm : ∀ t, m (t + 1) = c * θ * m t) (t : ℕ) : m t = (c * θ) ^ t := by
  induction t with
  | zero => simp [hm0]
  | succ n ih => rw [hm, ih, pow_succ]; ring

/-- The census variance times `λ - 1` is `(c θ)^(2t) - c^t`. -/
theorem census_var_mul (c θ : ℝ) (m M : ℕ → ℝ)
    (hm0 : m 0 = 1) (hM0 : M 0 = 1)
    (hm : ∀ t, m (t + 1) = c * θ * m t)
    (hM : ∀ t, M (t + 1) = c * M t + (c * θ * m t) ^ 2) (t : ℕ) :
    (M t - m t ^ 2) * (c * θ ^ 2 - 1) = (c * θ) ^ (2 * t) - c ^ t := by
  induction t with
  | zero => simp [hm0, hM0]
  | succ n ih =>
    have hmn := census_mean_eq c θ m hm0 hm n
    have key : M (n + 1) - m (n + 1) ^ 2 = c * ((M n - m n ^ 2) + m n ^ 2) := by
      rw [hM, hm]; ring
    rw [key, mul_assoc, add_mul, ih, hmn]
    rw [show 2 * (n + 1) = 2 * n + 2 by ring, pow_add, pow_succ c n, ← pow_mul]
    ring

/-- The average squared census is at least `c^t`. -/
theorem census_sq_ge (c θ : ℝ) (hc : 0 < c) (m M : ℕ → ℝ) (hM0 : M 0 = 1)
    (hM : ∀ t, M (t + 1) = c * M t + (c * θ * m t) ^ 2) (t : ℕ) : c ^ t ≤ M t := by
  induction t with
  | zero => simp [hM0]
  | succ n ih =>
    rw [hM, pow_succ]
    nlinarith [sq_nonneg (c * θ * m n)]

/-- For `λ ≠ 1`, the census ratio is `λ^t (λ - 1)/(λ^t - 1)` at every depth. -/
theorem census_ratio_eq (c θ : ℝ) (hc : 0 < c) (hlam : c * θ ^ 2 ≠ 1) (m M : ℕ → ℝ)
    (hm0 : m 0 = 1) (hM0 : M 0 = 1)
    (hm : ∀ t, m (t + 1) = c * θ * m t)
    (hM : ∀ t, M (t + 1) = c * M t + (c * θ * m t) ^ 2) (t : ℕ) :
    m t ^ 2 / (M t - m t ^ 2) =
      (c * θ ^ 2) ^ t * (c * θ ^ 2 - 1) / ((c * θ ^ 2) ^ t - 1) := by
  have hl : c * θ ^ 2 - 1 ≠ 0 := sub_ne_zero.mpr hlam
  have hv := census_var_mul c θ m M hm0 hM0 hm hM t
  have e : (c * θ) ^ (2 * t) = c ^ t * (c * θ ^ 2) ^ t := by
    rw [pow_mul, show (c * θ) ^ 2 = c * (c * θ ^ 2) by ring, mul_pow]
  have hV : M t - m t ^ 2 = c ^ t * (((c * θ ^ 2) ^ t - 1) / (c * θ ^ 2 - 1)) := by
    rw [mul_div_assoc', eq_div_iff hl, hv, e]
    ring
  have hsq : m t ^ 2 = c ^ t * (c * θ ^ 2) ^ t := by
    rw [census_mean_eq c θ m hm0 hm t, ← pow_mul, mul_comm t 2, e]
  have hct : c ^ t ≠ 0 := pow_ne_zero _ hc.ne'
  rw [hV, hsq, mul_div_mul_left _ _ hct, div_div_eq_mul_div]

#print axioms census_mean_eq
#print axioms census_var_mul
#print axioms census_sq_ge
#print axioms census_ratio_eq

/-- The Kesten–Stigum line for the tree census: if the mean degree `c` is positive and the
average census `m` and average squared census `M` follow the card's rules, then above the line
(`c θ² > 1`) the census signal-to-noise ratio settles at `c θ² - 1`, and below the line
(`c θ² < 1`) it falls to 0, so a deep census says nothing about the root. -/
theorem census_threshold (c θ : ℝ) (hc : 0 < c) (m M : ℕ → ℝ)
    (hm0 : m 0 = 1) (hM0 : M 0 = 1)
    (hm : ∀ t, m (t + 1) = c * θ * m t)
    (hM : ∀ t, M (t + 1) = c * M t + (c * θ * m t) ^ 2) :
    (1 < c * θ ^ 2 →
      Tendsto (fun t => m t ^ 2 / (M t - m t ^ 2)) atTop (𝓝 (c * θ ^ 2 - 1))) ∧
    (c * θ ^ 2 < 1 →
      Tendsto (fun t => m t ^ 2 / (M t - m t ^ 2)) atTop (𝓝 0)) := by
  have hl0 : 0 ≤ c * θ ^ 2 := by positivity
  constructor
  · intro h1
    have hne : c * θ ^ 2 ≠ 1 := ne_of_gt h1
    set l := c * θ ^ 2 with hl
    have hinv : Tendsto (fun t : ℕ => (l⁻¹) ^ t) atTop (𝓝 0) :=
      tendsto_pow_atTop_nhds_zero_of_lt_one (inv_nonneg.mpr hl0) (inv_lt_one_of_one_lt₀ h1)
    have hlim : Tendsto (fun t : ℕ => (l - 1) / (1 - (l⁻¹) ^ t)) atTop (𝓝 ((l - 1) / (1 - 0))) :=
      tendsto_const_nhds.div (tendsto_const_nhds.sub hinv) (by norm_num)
    rw [sub_zero, div_one] at hlim
    refine hlim.congr (fun t => ?_)
    rw [census_ratio_eq c θ hc hne m M hm0 hM0 hm hM t]
    have hx : 0 < l ^ t := pow_pos (by linarith) t
    rw [inv_pow, show 1 - (l ^ t)⁻¹ = (l ^ t - 1) / l ^ t by field_simp, div_div_eq_mul_div,
      mul_comm]
  · intro h1
    have hne : c * θ ^ 2 ≠ 1 := ne_of_lt h1
    set l := c * θ ^ 2 with hl
    have hp : Tendsto (fun t : ℕ => l ^ t) atTop (𝓝 0) :=
      tendsto_pow_atTop_nhds_zero_of_lt_one hl0 h1
    have hlim : Tendsto (fun t : ℕ => l ^ t * (l - 1) / (l ^ t - 1)) atTop
        (𝓝 (0 * (l - 1) / (0 - 1))) :=
      (hp.mul tendsto_const_nhds).div (hp.sub tendsto_const_nhds) (by norm_num)
    rw [zero_mul, zero_div] at hlim
    refine hlim.congr (fun t => ?_)
    rw [census_ratio_eq c θ hc hne m M hm0 hM0 hm hM t]

/-- The census rules solved exactly: with `c > 0`, `θ ≠ 0` and `λ = c θ² ≠ 1`, at every depth
`t ≥ 1` the census variance is `M t - m t² = ((c θ)^(2t) - c^t)/(λ - 1)`, which is not zero,
and the census signal-to-noise ratio is `r t = (λ - 1)/(1 - λ^(-t))`. -/
theorem census_snr_closed_form (c θ : ℝ) (hc : 0 < c) (hθ : θ ≠ 0) (hlam : c * θ ^ 2 ≠ 1)
    (m M : ℕ → ℝ)
    (hm0 : m 0 = 1) (hM0 : M 0 = 1)
    (hm : ∀ t, m (t + 1) = c * θ * m t)
    (hM : ∀ t, M (t + 1) = c * M t + (c * θ * m t) ^ 2)
    (t : ℕ) (ht : 1 ≤ t) :
    M t - m t ^ 2 = ((c * θ) ^ (2 * t) - c ^ t) / (c * θ ^ 2 - 1) ∧
    M t - m t ^ 2 ≠ 0 ∧
    m t ^ 2 / (M t - m t ^ 2) = (c * θ ^ 2 - 1) / (1 - (c * θ ^ 2)⁻¹ ^ t) := by
  have hl : c * θ ^ 2 - 1 ≠ 0 := sub_ne_zero.mpr hlam
  have hv := census_var_mul c θ m M hm0 hM0 hm hM t
  have hpos : 0 < M t - m t ^ 2 := by
    obtain ⟨n, rfl⟩ : ∃ n, t = n + 1 := ⟨t - 1, by omega⟩
    have h1 : M (n + 1) - m (n + 1) ^ 2 = c * M n := by rw [hM, hm]; ring
    rw [h1]
    exact mul_pos hc (lt_of_lt_of_le (pow_pos hc n) (census_sq_ge c θ hc m M hM0 hM n))
  refine ⟨by rw [eq_div_iff hl, hv], hpos.ne', ?_⟩
  rw [census_ratio_eq c θ hc hlam m M hm0 hM0 hm hM t]
  have hl0 : c * θ ^ 2 ≠ 0 := mul_ne_zero hc.ne' (pow_ne_zero 2 hθ)
  have hx : (c * θ ^ 2) ^ t ≠ 0 := pow_ne_zero t hl0
  rw [inv_pow, show 1 - ((c * θ ^ 2) ^ t)⁻¹ = ((c * θ ^ 2) ^ t - 1) / (c * θ ^ 2) ^ t by
    field_simp, div_div_eq_mul_div, mul_comm]

/-- The threshold arithmetic: with positive total rate `c_in + c_out`, the signal-to-noise
ratio `λ = (c_in - c_out)² / (2 (c_in + c_out))` equals `c θ²` with mean degree
`c = (c_in + c_out)/2` and `θ = (c_in - c_out)/(c_in + c_out)`, and `λ > 1` exactly when the
squared gap `(c_in - c_out)²` beats twice the sum `2 (c_in + c_out)`. -/
theorem detectable_iff_gap_sq_gt_twice_sum (cin cout : ℝ) (h : 0 < cin + cout) :
    (cin - cout) ^ 2 / (2 * (cin + cout)) = (cin + cout) / 2 * ((cin - cout) / (cin + cout)) ^ 2 ∧
    (1 < (cin - cout) ^ 2 / (2 * (cin + cout)) ↔ 2 * (cin + cout) < (cin - cout) ^ 2) := by
  have h2 : (0 : ℝ) < 2 * (cin + cout) := by linarith
  refine ⟨?_, one_lt_div h2⟩
  field_simp

/-! The card's own whole-number and exact-fraction numbers. -/

-- Rates 5 and 1: (5 - 1)² = 16 beats 2(5 + 1) = 12, so the towns are detectable.
example : (5 - 1) ^ 2 = 16 ∧ 2 * (5 + 1) = 12 ∧ 12 < 16 := by decide
-- Rates 4 and 2: (4 - 2)² = 4 is below 2(4 + 2) = 12, so nothing beats a coin.
example : (4 - 2) ^ 2 = 4 ∧ 2 * (4 + 2) = 12 ∧ 4 < 12 := by decide
-- λ for the two networks: 16/12 = 4/3 and 4/12 = 1/3; mean degree 3 in both.
example : ((5 : ℚ) - 1) ^ 2 / (2 * (5 + 1)) = 4 / 3 ∧ ((4 : ℚ) - 2) ^ 2 / (2 * (4 + 2)) = 1 / 3 := by
  norm_num
-- Mean degree 3 and θ = 4/6 for rates 5 and 1; c θ² = 4/3, and the group signal c θ = 2.
example : ((5 : ℚ) + 1) / 2 = 3 ∧ ((5 : ℚ) - 1) / (5 + 1) = 4 / 6 ∧
    (3 : ℚ) * (4 / 6) ^ 2 = 4 / 3 ∧ (3 : ℚ) * (4 / 6) = 2 := by
  norm_num
-- Rates 4 and 2: θ = 1/3, c θ² = 1/3, group signal c θ = 1.
example : ((4 : ℚ) - 2) / (4 + 2) = 1 / 3 ∧ (3 : ℚ) * (1 / 3) ^ 2 = 1 / 3 ∧ (3 : ℚ) * (1 / 3) = 1 := by
  norm_num
-- The census ratio at λ = 4/3: r₁ = 4/3 and r₂ = 16/21 (the card's 1.3333 and 0.7619).
example : ((4 : ℚ) / 3 - 1) / (1 - (4 / 3 : ℚ)⁻¹ ^ 1) = 4 / 3 ∧
    ((4 : ℚ) / 3 - 1) / (1 - (4 / 3 : ℚ)⁻¹ ^ 2) = 16 / 21 := by
  norm_num
-- The census ratio at λ = 1/3: r₁ = 1/3 and r₂ = 1/12 (the card's 0.3333 and 0.0833).
example : ((1 : ℚ) / 3 - 1) / (1 - (1 / 3 : ℚ)⁻¹ ^ 1) = 1 / 3 ∧
    ((1 : ℚ) / 3 - 1) / (1 - (1 / 3 : ℚ)⁻¹ ^ 2) = 1 / 12 := by
  norm_num

#print axioms census_threshold
#print axioms census_snr_closed_form
#print axioms detectable_iff_gap_sq_gt_twice_sum

end StochasticBlockModelAndDetectability
