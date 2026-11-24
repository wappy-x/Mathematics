-- SSVI: if the at-the-money total variance never falls and θφ(θ) rises with θ but not too fast, the SSVI total variance at every log-moneyness never falls with expiry, so no two expiries cross.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Set

/-- The SSVI total variance at log-moneyness `k` on the slice with at-the-money total variance
`θ`, skew `ρ` and curvature rule `φ`:
`w(k, θ) = θ/2 · (1 + ρ φ(θ) k + √((φ(θ) k + ρ)² + 1 − ρ²))`. -/
noncomputable def ssviW (ρ : ℝ) (φ : ℝ → ℝ) (k θ : ℝ) : ℝ :=
  θ / 2 * (1 + ρ * (φ θ * k) + Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2))

lemma ssvi_slope_nonneg_aux (ρ f D k : ℝ) (hρ : ρ ^ 2 < 1) (hf : 0 < f) (hP : 0 ≤ f + D)
    (hslow : ρ ^ 2 * (f + D) ≤ (1 + Real.sqrt (1 - ρ ^ 2)) * f) :
    0 ≤ 1 + ρ * (f * k) + Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2) +
      D * k * (ρ + (f * k + ρ) / Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2)) := by
  have hpos : 0 < (f * k + ρ) ^ 2 + 1 - ρ ^ 2 := by nlinarith [sq_nonneg (f * k + ρ)]
  have hRpos : 0 < Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2) := Real.sqrt_pos.mpr hpos
  have hR2 : Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2) ^ 2 = (f * k + ρ) ^ 2 + 1 - ρ ^ 2 :=
    Real.sq_sqrt hpos.le
  have hRs : Real.sqrt (1 - ρ ^ 2) ≤ Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2) :=
    Real.sqrt_le_sqrt (by nlinarith [sq_nonneg (f * k + ρ)])
  have hs2 : Real.sqrt (1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt (by linarith)
  have hs0 : 0 ≤ Real.sqrt (1 - ρ ^ 2) := Real.sqrt_nonneg _
  have hq : (f * k + ρ) / Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2) *
      Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2) = f * k + ρ := div_mul_cancel₀ _ hRpos.ne'
  generalize Real.sqrt ((f * k + ρ) ^ 2 + 1 - ρ ^ 2) = R at *
  generalize Real.sqrt (1 - ρ ^ 2) = s at *
  generalize (f * k + ρ) / R = q at *
  have h1 : 0 ≤ 1 + ρ * (f * k) + R := by
    have : (1 + ρ * (f * k)) ^ 2 ≤ R ^ 2 := by
      rw [hR2]; nlinarith [mul_nonneg (sq_nonneg (f * k)) (by linarith : (0:ℝ) ≤ 1 - ρ ^ 2)]
    linarith [(abs_le_of_sq_le_sq' this hRpos.le).1]
  have hPs : (1 - s) * (f + D) ≤ f := by
    have h' : (1 + s) * ((1 - s) * (f + D)) ≤ (1 + s) * f := by
      have : ρ ^ 2 = (1 + s) * (1 - s) := by nlinarith
      nlinarith
    exact le_of_mul_le_mul_left h' (by linarith)
  have h2 : 0 ≤ f + (f + D) * (R - 1) := by nlinarith
  have hkey : f * R * (1 + ρ * (f * k) + R + D * k * (ρ + q)) =
      (1 + ρ * (f * k) + R) * (f + (f + D) * (R - 1)) := by
    linear_combination (f * D * k) * hq - D * hR2
  have : 0 ≤ f * R * (1 + ρ * (f * k) + R + D * k * (ρ + q)) := by
    rw [hkey]; exact mul_nonneg h1 h2
  exact (mul_nonneg_iff_of_pos_left (mul_pos hf hRpos)).mp this

#print axioms ssvi_slope_nonneg_aux

lemma ssviW_hasDerivAt_theta (ρ : ℝ) (φ : ℝ → ℝ) (k θ φ' : ℝ) (hρ : ρ ^ 2 < 1)
    (hφ : HasDerivAt φ φ' θ) :
    HasDerivAt (fun x => ssviW ρ φ k x)
      (1 / 2 * (1 + ρ * (φ θ * k) + Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2) +
        θ * φ' * k * (ρ + (φ θ * k + ρ) / Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2)))) θ := by
  have hpos : 0 < (φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2 := by nlinarith [sq_nonneg (φ θ * k + ρ)]
  have hRpos : 0 < Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2) := Real.sqrt_pos.mpr hpos
  have hA : HasDerivAt (fun x => φ x * k) (φ' * k) θ := hφ.mul_const k
  have hS : HasDerivAt (fun x => Real.sqrt ((φ x * k + ρ) ^ 2 + 1 - ρ ^ 2))
      ((↑2 * (φ θ * k + ρ) ^ (2 - 1) * (φ' * k)) /
        (2 * Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2))) θ :=
    ((((hA.add_const ρ).pow 2).add_const 1).sub_const (ρ ^ 2)).sqrt hpos.ne'
  have hH : HasDerivAt (fun x => 1 + ρ * (φ x * k) + Real.sqrt ((φ x * k + ρ) ^ 2 + 1 - ρ ^ 2))
      (ρ * (φ' * k) + (↑2 * (φ θ * k + ρ) ^ (2 - 1) * (φ' * k)) /
        (2 * Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2))) θ :=
    ((hA.const_mul ρ).const_add 1).add hS
  have h : HasDerivAt (fun x => x / 2 * (1 + ρ * (φ x * k) +
      Real.sqrt ((φ x * k + ρ) ^ 2 + 1 - ρ ^ 2)))
      (1 / 2 * (1 + ρ * (φ θ * k) + Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2)) +
        θ / 2 * (ρ * (φ' * k) + (↑2 * (φ θ * k + ρ) ^ (2 - 1) * (φ' * k)) /
        (2 * Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2)))) θ :=
    ((hasDerivAt_id θ).div_const 2).mul hH
  refine h.congr_deriv ?_
  field_simp
  ring

#print axioms ssviW_hasDerivAt_theta

/-- **SSVI has no calendar arbitrage (Gatheral and Jacquier, Theorem 4.1, sufficient half).**
Take a skew `ρ` strictly between −1 and 1, a curvature rule `φ` that is positive and
differentiable for `θ > 0`, and an at-the-money total variance `θ_t > 0` that never falls as the
expiry `t > 0` grows. Suppose `θ φ(θ)` rises with `θ`, but not too fast:
`0 ≤ ∂θ(θφ) ≤ (1 + √(1 − ρ²)) / ρ² · φ`, written here as `ρ² ∂θ(θφ) ≤ (1 + √(1 − ρ²)) φ` so
that `ρ = 0` puts no upper limit. Then at every log-moneyness `k` the SSVI total variance
`w(k, θ_t)` never falls as `t` grows: no two expiries of the surface cross. -/
theorem ssvi_surface_has_no_calendar_arbitrage (ρ : ℝ) (φ atm : ℝ → ℝ)
    (hρ : |ρ| < 1)
    (hφpos : ∀ θ, 0 < θ → 0 < φ θ)
    (hφdiff : DifferentiableOn ℝ φ (Ioi 0))
    (hrise : ∀ θ, 0 < θ → 0 ≤ deriv (fun s => s * φ s) θ)
    (hslow : ∀ θ, 0 < θ →
      ρ ^ 2 * deriv (fun s => s * φ s) θ ≤ (1 + Real.sqrt (1 - ρ ^ 2)) * φ θ)
    (hatm_pos : ∀ t, 0 < t → 0 < atm t)
    (hatm_mono : MonotoneOn atm (Ioi 0)) (k : ℝ) :
    MonotoneOn (fun t => ssviW ρ φ k (atm t)) (Ioi 0) := by
  have hρ2 : ρ ^ 2 < 1 := by
    have := abs_lt.mp hρ; nlinarith
  have hd : ∀ θ ∈ Ioi (0 : ℝ), HasDerivAt (fun x => ssviW ρ φ k x)
      (1 / 2 * (1 + ρ * (φ θ * k) + Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2) +
        θ * deriv φ θ * k * (ρ + (φ θ * k + ρ) / Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2)))) θ :=
    fun θ hθ => ssviW_hasDerivAt_theta ρ φ k θ (deriv φ θ) hρ2
      (hφdiff.differentiableAt (Ioi_mem_nhds hθ)).hasDerivAt
  have hg : MonotoneOn (fun x => ssviW ρ φ k x) (Ioi 0) := by
    apply monotoneOn_of_deriv_nonneg (convex_Ioi 0)
    · exact fun θ hθ => (hd θ hθ).continuousAt.continuousWithinAt
    · rw [interior_Ioi]
      exact fun θ hθ => (hd θ hθ).differentiableAt.differentiableWithinAt
    · rw [interior_Ioi]
      intro θ hθ
      rw [(hd θ hθ).deriv]
      have hψ : deriv (fun s => s * φ s) θ = φ θ + θ * deriv φ θ := by
        have h : HasDerivAt (fun s => s * φ s) (1 * φ θ + θ * deriv φ θ) θ :=
          (hasDerivAt_id' θ).mul (hφdiff.differentiableAt (Ioi_mem_nhds hθ)).hasDerivAt
        rw [h.deriv]; ring
      have hr := hrise θ hθ
      have hs := hslow θ hθ
      rw [hψ] at hr hs
      exact mul_nonneg (by norm_num)
        (ssvi_slope_nonneg_aux ρ (φ θ) (θ * deriv φ θ) k hρ2 (hφpos θ hθ) hr hs)
  intro a ha b hb hab
  exact hg (hatm_pos a ha) (hatm_pos b hb) (hatm_mono ha hb hab)

/-- **The power law: total variance rises with θ at every strike (the card's Step 2).** With the
curvature rule `φ(θ) = η θ^(−γ)`, `η > 0` and `0 ≤ γ ≤ 1` (so `θφ = η θ^(1−γ)` rises, with
calendar ratio `u = 1 − γ` between 0 and 1), and skew `|ρ| < 1`, the SSVI total variance
`w(k, θ)` never falls as `θ > 0` grows, at every log-moneyness `k`. -/
theorem power_law_ssvi_total_variance_rises_with_theta (ρ η γ : ℝ) (hρ : |ρ| < 1)
    (hη : 0 < η) (hγ0 : 0 ≤ γ) (hγ1 : γ ≤ 1) (k : ℝ) :
    MonotoneOn (fun θ => ssviW ρ (fun s => η * s ^ (-γ)) k θ) (Ioi 0) := by
  have hd : ∀ θ : ℝ, 0 < θ → deriv (fun s => s * (η * s ^ (-γ))) θ = η * (1 - γ) * θ ^ (-γ) := by
    intro θ hθ
    have h : HasDerivAt (fun s => s * (η * s ^ (-γ)))
        (1 * (η * θ ^ (-γ)) + θ * (η * (-γ * θ ^ (-γ - 1)))) θ :=
      (hasDerivAt_id' θ).mul ((Real.hasDerivAt_rpow_const (p := -γ) (Or.inl hθ.ne')).const_mul η)
    rw [h.deriv, Real.rpow_sub_one hθ.ne']
    field_simp
    ring
  refine ssvi_surface_has_no_calendar_arbitrage ρ (fun s => η * s ^ (-γ)) (fun t => t) hρ
    (fun θ hθ => mul_pos hη (Real.rpow_pos_of_pos hθ _)) ?_ ?_ ?_ (fun t ht => ht)
    (fun a _ b _ h => h) k
  · intro θ hθ
    exact ((Real.hasDerivAt_rpow_const (p := -γ) (Or.inl (ne_of_gt hθ))).const_mul
      η).differentiableAt.differentiableWithinAt
  · intro θ hθ
    rw [hd θ hθ]
    exact mul_nonneg (mul_nonneg hη.le (by linarith)) (Real.rpow_nonneg hθ.le _)
  · intro θ hθ
    rw [hd θ hθ]
    have hc : 0 < η * θ ^ (-γ) := mul_pos hη (Real.rpow_pos_of_pos hθ _)
    have hρ2 : ρ ^ 2 ≤ 1 := by
      have := abs_lt.mp hρ; nlinarith
    have hs : 0 ≤ Real.sqrt (1 - ρ ^ 2) := Real.sqrt_nonneg _
    have hu : ρ ^ 2 * (1 - γ) ≤ 1 + Real.sqrt (1 - ρ ^ 2) := by
      nlinarith [sq_nonneg ρ]
    calc ρ ^ 2 * (η * (1 - γ) * θ ^ (-γ)) = (ρ ^ 2 * (1 - γ)) * (η * θ ^ (-γ)) := by ring
      _ ≤ (1 + Real.sqrt (1 - ρ ^ 2)) * (η * θ ^ (-γ)) := mul_le_mul_of_nonneg_right hu hc.le

/-- **At the money: the surface passes through θ, and its slope there gives ρ.** For any skew
`ρ`, curvature rule `φ` and level `θ`, the SSVI total variance at `k = 0` is `θ` itself, and its
slope in `k` there is `ρ θ φ(θ)`, so one at-the-money skew reading fixes `ρ`. -/
theorem ssvi_at_the_money_value_and_skew (ρ : ℝ) (φ : ℝ → ℝ) (θ : ℝ) :
    ssviW ρ φ 0 θ = θ ∧
      HasDerivAt (fun k => ssviW ρ φ k θ) (ρ * θ * φ θ) 0 := by
  have h1 : (φ θ * 0 + ρ) ^ 2 + 1 - ρ ^ 2 = 1 := by ring
  constructor
  · unfold ssviW
    rw [h1, Real.sqrt_one]; ring
  · have hA : HasDerivAt (fun k => φ θ * k) (φ θ * 1) 0 := (hasDerivAt_id' 0).const_mul (φ θ)
    have hS : HasDerivAt (fun k => Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2))
        ((↑2 * (φ θ * 0 + ρ) ^ (2 - 1) * (φ θ * 1)) /
          (2 * Real.sqrt ((φ θ * 0 + ρ) ^ 2 + 1 - ρ ^ 2))) 0 :=
      ((((hA.add_const ρ).pow 2).add_const 1).sub_const (ρ ^ 2)).sqrt (by simp only [Pi.pow_apply]; rw [h1]; norm_num)
    have h : HasDerivAt (fun k => θ / 2 * (1 + ρ * (φ θ * k) +
        Real.sqrt ((φ θ * k + ρ) ^ 2 + 1 - ρ ^ 2)))
        (θ / 2 * (ρ * (φ θ * 1) + (↑2 * (φ θ * 0 + ρ) ^ (2 - 1) * (φ θ * 1)) /
          (2 * Real.sqrt ((φ θ * 0 + ρ) ^ 2 + 1 - ρ ^ 2)))) 0 :=
      (((hA.const_mul ρ).const_add 1).add hS).const_mul (θ / 2)
    refine h.congr_deriv ?_
    rw [h1, Real.sqrt_one]
    ring

-- Headline butterfly test on the stylized surface: η (1 + |ρ|) = 1 × 1.7 = 17/10 ≤ 2.
example : (1 : ℚ) * (1 + |(-7 / 10 : ℚ)|) = 17 / 10 ∧ (17 / 10 : ℚ) ≤ 2 := by norm_num
-- With γ = 1/2, θ φ² (1 + |ρ|) = η² × 1.7 = 17/10 ≤ 4.
example : (1 : ℚ) ^ 2 * (1 + |(-7 / 10 : ℚ)|) ≤ 4 := by norm_num
-- 1-year slice: φ(0.04) = 1/√(1/25) = 5.
example : 1 / Real.sqrt (1 / 25) = 5 := by
  rw [show (1 / 25 : ℝ) = (1 / 5) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]; norm_num
-- 1-year at-the-money skew ρ θ φ = (−7/10)(1/25)(5) = −7/50 (−0.14).
example : (-7 / 10 : ℚ) * (1 / 25) * 5 = -7 / 50 := by norm_num
-- 1-year wing slopes θφ(1 − ρ)/2 and θφ(1 + ρ)/2 with θφ = 1/5: 17/100 and 3/100.
example : (1 / 5 : ℚ) * (1 - (-7 / 10)) / 2 = 17 / 100 ∧
    (1 / 5 : ℚ) * (1 + (-7 / 10)) / 2 = 3 / 100 := by norm_num
-- Horizon of the pure power law: at θ = (4/1.7)² = 1600/289, √θ × 1.7 = 4 exactly,
-- which is 40000/289 years (138.4) on θ_t = t/25.
example : Real.sqrt (1600 / 289) * (17 / 10) = 4 := by
  rw [show (1600 / 289 : ℝ) = (40 / 17) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]; norm_num
example : (1600 / 289 : ℚ) / (1 / 25) = 40000 / 289 := by norm_num
-- Calendar ratio u = 1 − γ = 1/2 lies inside [0, (1 + √(1 − ρ²))/ρ²]: ρ² u ≤ 1 + √(51/100).
example : (0 : ℝ) ≤ 1 - 1 / 2 ∧
    (-7 / 10 : ℝ) ^ 2 * (1 - 1 / 2) ≤ 1 + Real.sqrt (1 - (-7 / 10) ^ 2) := by
  constructor
  · norm_num
  · nlinarith [Real.sqrt_nonneg (1 - (-7 / 10 : ℝ) ^ 2)]
-- What breaks: η = 3 gives θ φ² (1 + |ρ|) = 9 × 1.7 = 153/10 (15.30) > 4;
-- γ = 1.2 gives u = 1 − 6/5 = −1/5 < 0.
example : (3 : ℚ) ^ 2 * (1 + |(-7 / 10 : ℚ)|) = 153 / 10 ∧ (4 : ℚ) < 153 / 10 := by norm_num
example : (1 : ℚ) - 6 / 5 = -1 / 5 := by norm_num
-- Try η = 1.5: η (1 + |ρ|) = 51/20 (2.55) > 2, yet η² (1 + |ρ|) = 153/40 (3.825) ≤ 4.
example : (3 / 2 : ℚ) * (17 / 10) = 51 / 20 ∧ (3 / 2 : ℚ) ^ 2 * (17 / 10) = 153 / 40 ∧
    (153 / 40 : ℚ) ≤ 4 := by norm_num

#print axioms ssvi_surface_has_no_calendar_arbitrage
#print axioms power_law_ssvi_total_variance_rises_with_theta
#print axioms ssvi_at_the_money_value_and_skew
