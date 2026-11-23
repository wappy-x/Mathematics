-- The September 2026 Navier-Stokes claim: for 0 < δ < 1/200 the claimed collapsing core's speed and Reynolds number become infinite while its energy goes to zero, and the model swirl's peak and energy constants are exactly as the card computes them.
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.MeasureTheory.Integral.Gamma

open Real Filter Topology MeasureTheory Set

/-- The claimed vortex core has speed `U = τ^(-(1+δ)/2)`, radius `ℓ_r = τ^(1/2)` and height
`ℓ_z = τ^((1-δ)/2)`, where `τ = 1 - t` is the time left and `0 < δ < 1/200`.
As `τ` falls to 0: the speed becomes infinite; the energy scale `U² ℓ_r² ℓ_z` equals
`τ^((1-3δ)/2)` and goes to 0; and the Reynolds number `U ℓ_r` (with `ν = 1`), which is also
the speed measured against Leray's rate `τ^(-1/2)`, equals `τ^(-δ/2)` and becomes infinite. -/
theorem core_speed_blows_up_while_energy_vanishes {δ : ℝ} (hδ0 : 0 < δ) (hδ1 : δ < 1 / 200) :
    Tendsto (fun τ : ℝ => τ ^ (-(1 + δ) / 2)) (𝓝[>] 0) atTop ∧
    (∀ τ : ℝ, 0 < τ →
      (τ ^ (-(1 + δ) / 2)) ^ 2 * (τ ^ (1 / 2 : ℝ)) ^ 2 * τ ^ ((1 - δ) / 2)
        = τ ^ ((1 - 3 * δ) / 2)) ∧
    Tendsto (fun τ : ℝ => (τ ^ (-(1 + δ) / 2)) ^ 2 * (τ ^ (1 / 2 : ℝ)) ^ 2 * τ ^ ((1 - δ) / 2))
      (𝓝[>] 0) (𝓝 0) ∧
    (∀ τ : ℝ, 0 < τ → τ ^ (-(1 + δ) / 2) * τ ^ (1 / 2 : ℝ) = τ ^ (-δ / 2)) ∧
    Tendsto (fun τ : ℝ => τ ^ (-(1 + δ) / 2) * τ ^ (1 / 2 : ℝ)) (𝓝[>] 0) atTop := by
  have key : ∀ τ : ℝ, 0 < τ → ∀ a b : ℝ, τ ^ a * τ ^ b = τ ^ (a + b) :=
    fun τ hτ a b => (Real.rpow_add hτ a b).symm
  have sq : ∀ τ : ℝ, 0 < τ → ∀ a : ℝ, (τ ^ a) ^ 2 = τ ^ (2 * a) := by
    intro τ hτ a
    rw [← Real.rpow_natCast, ← Real.rpow_mul hτ.le]
    norm_num [mul_comm]
  have hE : ∀ τ : ℝ, 0 < τ →
      (τ ^ (-(1 + δ) / 2)) ^ 2 * (τ ^ (1 / 2 : ℝ)) ^ 2 * τ ^ ((1 - δ) / 2)
        = τ ^ ((1 - 3 * δ) / 2) := by
    intro τ hτ
    rw [sq τ hτ, sq τ hτ, key τ hτ, key τ hτ]
    congr 1; ring
  have hR : ∀ τ : ℝ, 0 < τ → τ ^ (-(1 + δ) / 2) * τ ^ (1 / 2 : ℝ) = τ ^ (-δ / 2) := by
    intro τ hτ
    rw [key τ hτ]
    congr 1; ring
  refine ⟨tendsto_rpow_neg_nhdsGT_zero (by linarith), hE, ?_, hR, ?_⟩
  · have hc : 0 < (1 - 3 * δ) / 2 := by linarith
    have h0 : Tendsto (fun τ : ℝ => τ ^ ((1 - 3 * δ) / 2)) (𝓝[>] 0) (𝓝 0) := by
      have := ((Real.continuous_rpow_const hc.le).tendsto 0)
      rw [Real.zero_rpow hc.ne'] at this
      exact tendsto_nhdsWithin_of_tendsto_nhds this
    refine h0.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with τ hτ
    exact (hE τ hτ).symm
  · refine (tendsto_rpow_neg_nhdsGT_zero (by linarith : -δ / 2 < 0)).congr' ?_
    filter_upwards [self_mem_nhdsWithin] with τ hτ
    exact (hR τ hτ).symm

/-- The model swirl's radial profile `s e^(-s²)` is never larger than `e^(-1/2)/√2`, and it
reaches that value at `s = 1/√2`; so the model's top speed is `U e^(-1/2)/√2`. -/
theorem model_swirl_peak :
    IsGreatest (Set.range fun s : ℝ => s * exp (-s ^ 2)) (exp (-1 / 2) / √2) ∧
    (1 / √2) * exp (-(1 / √2) ^ 2) = exp (-1 / 2) / √2 := by
  have h2 : (0 : ℝ) < √2 := by positivity
  have hs2 : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have hval : (1 / √2) * exp (-(1 / √2) ^ 2) = exp (-1 / 2) / √2 := by
    have : (1 / √2) ^ 2 = 1 / 2 := by
      rw [div_pow, Real.sq_sqrt (by norm_num)]; norm_num
    rw [this]; ring_nf
  refine ⟨⟨⟨1 / √2, hval⟩, ?_⟩, hval⟩
  rintro _ ⟨s, rfl⟩
  simp only
  rcases le_or_gt s 0 with hs | hs
  · have : s * exp (-s ^ 2) ≤ 0 := mul_nonpos_of_nonpos_of_nonneg hs (exp_pos _).le
    exact this.trans (by positivity)
  · rw [le_div_iff₀ h2]
    -- √2 s ≤ s² + 1/2 ≤ exp (s² - 1/2)
    have h1 : √2 * s ≤ s ^ 2 + 1 / 2 := by
      nlinarith [sq_nonneg (s - 1 / √2), sq_nonneg (√2 * s - 1)]
    have h3 : s ^ 2 + 1 / 2 ≤ exp (s ^ 2 - 1 / 2) := by
      have := Real.add_one_le_exp (s ^ 2 - 1 / 2); linarith
    have h4 : exp (s ^ 2 - 1 / 2) * exp (-s ^ 2) = exp (-1 / 2) := by
      rw [← Real.exp_add]; congr 1; ring
    calc s * exp (-s ^ 2) * √2 = (√2 * s) * exp (-s ^ 2) := by ring
      _ ≤ exp (s ^ 2 - 1 / 2) * exp (-s ^ 2) :=
          mul_le_mul_of_nonneg_right (h1.trans h3) (exp_pos _).le
      _ = exp (-1 / 2) := h4

/-- The two integrals behind the model swirl's energy `½ τ^((1-3δ)/2) (π/4) √(π/2)`:
`∫₀^∞ s³ e^(-2s²) ds = 1/8` and `∫ e^(-2ζ²) dζ = √(π/2)` over the whole line. -/
theorem model_swirl_energy_integrals :
    (∫ s in Ioi (0 : ℝ), s ^ 3 * exp (-2 * s ^ 2)) = 1 / 8 ∧
    (∫ ζ : ℝ, exp (-2 * ζ ^ 2)) = √(π / 2) := by
  constructor
  · have h := integral_rpow_mul_exp_neg_mul_rpow (p := 2) (q := 3) (b := 2)
      (by norm_num) (by norm_num) (by norm_num)
    have hc : (∫ s in Ioi (0 : ℝ), s ^ 3 * exp (-2 * s ^ 2))
        = ∫ x in Ioi (0 : ℝ), x ^ (3 : ℝ) * exp (-2 * x ^ (2 : ℝ)) := by
      refine setIntegral_congr_fun measurableSet_Ioi (fun x _ => ?_)
      rw [show (3 : ℝ) = ((3 : ℕ) : ℝ) by norm_num, show (2 : ℝ) = ((2 : ℕ) : ℝ) by norm_num,
        Real.rpow_natCast, Real.rpow_natCast]
    rw [hc, h]
    have hg : (3 + 1 : ℝ) / 2 = (1 : ℕ) + 1 := by norm_num
    have hn : -((3 : ℝ) + 1) / 2 = ((-2 : ℤ) : ℝ) := by norm_num
    rw [hg, hn, Real.rpow_intCast, Real.Gamma_nat_eq_factorial]
    norm_num
  · simpa using integral_gaussian 2

-- The card's exponents at δ = 1/200, exactly.
-- Energy exponent (1 - 3δ)/2 = 0.4925.
example : ((1 : ℚ) - 3 * (1 / 200)) / 2 = 197 / 400 := by norm_num
-- Speed exponent (1 + δ)/2 = 0.5025.
example : (1 + (1 : ℚ) / 200) / 2 = 201 / 400 := by norm_num
-- Speed above Leray's rate: exponent δ/2 = 0.0025.
example : ((1 : ℚ) / 200) / 2 = 1 / 400 := by norm_num
-- What breaks: δ = 0.4 makes the energy exponent negative, so the energy grows.
example : ((1 : ℚ) - 3 * (2 / 5)) / 2 = -1 / 10 := by norm_num
-- What breaks: speed like τ^(-0.4) against Leray's τ^(-1/2) leaves τ^(1/10), which falls to 0.
example : -(2 : ℚ) / 5 + 1 / 2 = 1 / 10 := by norm_num
-- Try changing: δ = 1/3 makes the energy exponent exactly 0.
example : ((1 : ℚ) - 3 * (1 / 3)) / 2 = 0 := by norm_num

#print axioms core_speed_blows_up_while_energy_vanishes
#print axioms model_swirl_peak
#print axioms model_swirl_energy_integrals
