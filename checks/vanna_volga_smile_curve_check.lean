-- The vanna-volga smile: the vanna-volga hedge weights for a call are the log-strike weights, those weights add up to one, and the second-order smile passes through all three pillar quotes.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

namespace VannaVolgaSmile

/-! The model, as on the card. Spot `S` (dollars per euro), dollar rate `rd`, euro rate `rf`,
years to expiry `T`, forward `F = S e^{(rd - rf) T}`. Every Black-Scholes distance is taken at
one flat vol `σ` (the at-the-money vol `σ₂`):
`d₁(x) = (ln(F/x) + σ²T/2) / (σ√T)`, `d₂(x) = d₁(x) - σ√T`.
Vega `ν(x) = S e^{-rf T} φ(d₁(x)) √T`, vanna `= -ν d₂ / (S σ √T)`, volga `= ν d₁ d₂ / σ`. -/

/-- The forward rate `F = S e^{(rd - rf) T}`. -/
noncomputable def fwd (S rd rf T : ℝ) : ℝ := S * Real.exp ((rd - rf) * T)

/-- Black-Scholes distance `d₁(x) = (ln(F/x) + σ²T/2) / (σ√T)` at the flat vol `σ`. -/
noncomputable def d1 (S rd rf σ T x : ℝ) : ℝ :=
  (Real.log (fwd S rd rf T / x) + σ ^ 2 * T / 2) / (σ * Real.sqrt T)

/-- Black-Scholes distance `d₂(x) = d₁(x) - σ√T`. -/
noncomputable def d2 (S rd rf σ T x : ℝ) : ℝ :=
  d1 S rd rf σ T x - σ * Real.sqrt T

/-- Height of the standard bell curve, `φ(u) = e^{-u²/2} / √(2π)`. -/
noncomputable def φ (u : ℝ) : ℝ :=
  Real.exp (-(u ^ 2) / 2) / Real.sqrt (2 * Real.pi)

/-- Vega of a call at strike `x`: `S e^{-rf T} φ(d₁) √T`. -/
noncomputable def vega (S rd rf σ T x : ℝ) : ℝ :=
  S * Real.exp (-(rf * T)) * φ (d1 S rd rf σ T x) * Real.sqrt T

/-- Vanna of a call at strike `x`: `-ν d₂ / (S σ √T)`. -/
noncomputable def vanna (S rd rf σ T x : ℝ) : ℝ :=
  -(vega S rd rf σ T x * d2 S rd rf σ T x) / (S * σ * Real.sqrt T)

/-- Volga of a call at strike `x`: `ν d₁ d₂ / σ`. -/
noncomputable def volga (S rd rf σ T x : ℝ) : ℝ :=
  vega S rd rf σ T x * d1 S rd rf σ T x * d2 S rd rf σ T x / σ

/-- The log-strike weight `y₁(K) = ln(K₂/K) ln(K₃/K) / (ln(K₂/K₁) ln(K₃/K₁))`. -/
noncomputable def y1 (K₁ K₂ K₃ K : ℝ) : ℝ :=
  Real.log (K₂ / K) * Real.log (K₃ / K) / (Real.log (K₂ / K₁) * Real.log (K₃ / K₁))

/-- The log-strike weight `y₂(K) = ln(K/K₁) ln(K₃/K) / (ln(K₂/K₁) ln(K₃/K₂))`. -/
noncomputable def y2 (K₁ K₂ K₃ K : ℝ) : ℝ :=
  Real.log (K / K₁) * Real.log (K₃ / K) / (Real.log (K₂ / K₁) * Real.log (K₃ / K₂))

/-- The log-strike weight `y₃(K) = ln(K/K₁) ln(K/K₂) / (ln(K₃/K₁) ln(K₃/K₂))`. -/
noncomputable def y3 (K₁ K₂ K₃ K : ℝ) : ℝ :=
  Real.log (K / K₁) * Real.log (K / K₂) / (Real.log (K₃ / K₁) * Real.log (K₃ / K₂))

/-- The second-order vanna-volga smile `σ(K)` of the card. With `D₁ = y₁σ₁ + y₂σ₂ + y₃σ₃ - σ₂`,
`D₂ = y₁ d₁d₂(K₁)(σ₁-σ₂)² + y₃ d₁d₂(K₃)(σ₃-σ₂)²` and `P = d₁d₂(K)`, all `d`'s at `σ₂`:
`σ(K) = σ₂ + (-σ₂ + √(σ₂² + P(2σ₂D₁ + D₂))) / P`, and where `P = 0` (the 0/0 point) its limit
`σ₂ + D₁ + D₂/(2σ₂)`. -/
noncomputable def smile (S rd rf T K₁ K₂ K₃ σ₁ σ₂ σ₃ K : ℝ) : ℝ :=
  let dd : ℝ → ℝ := fun x => d1 S rd rf σ₂ T x * d2 S rd rf σ₂ T x
  let D1 := y1 K₁ K₂ K₃ K * σ₁ + y2 K₁ K₂ K₃ K * σ₂ + y3 K₁ K₂ K₃ K * σ₃ - σ₂
  let D2 := y1 K₁ K₂ K₃ K * dd K₁ * (σ₁ - σ₂) ^ 2 + y3 K₁ K₂ K₃ K * dd K₃ * (σ₃ - σ₂) ^ 2
  let P := dd K
  if P = 0 then σ₂ + D1 + D2 / (2 * σ₂)
  else σ₂ + (-σ₂ + Real.sqrt (σ₂ ^ 2 + P * (2 * σ₂ * D1 + D2))) / P

/-- Three-point interpolation: a weighted sum reproduces `1`, `e` and `e²` exactly when the
weights are the Lagrange weights at the distinct nodes `e₁, e₂, e₃`. -/
theorem lagrange_three_weights (w₁ w₂ w₃ e₁ e₂ e₃ e ν : ℝ)
    (h12 : e₁ ≠ e₂) (h13 : e₁ ≠ e₃) (h23 : e₂ ≠ e₃) :
    (w₁ + w₂ + w₃ = ν ∧ w₁ * e₁ + w₂ * e₂ + w₃ * e₃ = ν * e ∧
        w₁ * e₁ ^ 2 + w₂ * e₂ ^ 2 + w₃ * e₃ ^ 2 = ν * e ^ 2) ↔
      (w₁ = ν * ((e - e₂) * (e - e₃) / ((e₁ - e₂) * (e₁ - e₃))) ∧
        w₂ = ν * ((e - e₁) * (e - e₃) / ((e₂ - e₁) * (e₂ - e₃))) ∧
        w₃ = ν * ((e - e₁) * (e - e₂) / ((e₃ - e₁) * (e₃ - e₂)))) := by
  have d12 : e₁ - e₂ ≠ 0 := sub_ne_zero.mpr h12
  have d13 : e₁ - e₃ ≠ 0 := sub_ne_zero.mpr h13
  have d23 : e₂ - e₃ ≠ 0 := sub_ne_zero.mpr h23
  have d21 : e₂ - e₁ ≠ 0 := sub_ne_zero.mpr h12.symm
  have d31 : e₃ - e₁ ≠ 0 := sub_ne_zero.mpr h13.symm
  have d32 : e₃ - e₂ ≠ 0 := sub_ne_zero.mpr h23.symm
  constructor
  · rintro ⟨h1, h2, h3⟩
    refine ⟨?_, ?_, ?_⟩
    · rw [mul_div_assoc', eq_div_iff (mul_ne_zero d12 d13)]
      linear_combination h3 - (e₂ + e₃) * h2 + e₂ * e₃ * h1
    · rw [mul_div_assoc', eq_div_iff (mul_ne_zero d21 d23)]
      linear_combination h3 - (e₁ + e₃) * h2 + e₁ * e₃ * h1
    · rw [mul_div_assoc', eq_div_iff (mul_ne_zero d31 d32)]
      linear_combination h3 - (e₁ + e₂) * h2 + e₁ * e₂ * h1
  · rintro ⟨rfl, rfl, rfl⟩
    refine ⟨?_, ?_, ?_⟩
    · field_simp
      ring
    · field_simp
      ring
    · field_simp
      ring

/-- The difference of two `d₂` values is a log-strike difference over `σ√T`. -/
theorem d2_sub_d2 (S rd rf σ T x y : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T)
    (hx : 0 < x) (hy : 0 < y) :
    d2 S rd rf σ T x - d2 S rd rf σ T y = (Real.log y - Real.log x) / (σ * Real.sqrt T) := by
  have hF : 0 < fwd S rd rf T := by unfold fwd; positivity
  have hr : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  unfold d2 d1
  rw [Real.log_div hF.ne' hx.ne', Real.log_div hF.ne' hy.ne']
  field_simp
  ring

/-- Logs of distinct positive numbers are distinct. -/
theorem log_ne_log_of_ne {a b : ℝ} (ha : 0 < a) (hb : 0 < b) (h : a ≠ b) :
    Real.log a ≠ Real.log b := fun e => h (Real.log_injOn_pos ha hb e)

#print axioms lagrange_three_weights
#print axioms d2_sub_d2
#print axioms log_ne_log_of_ne

/-- **The hedge weights are log-strike weights** (Step 1). With a positive spot, flat vol and
time, and three distinct positive pillar strikes `K₁, K₂, K₃`, amounts `x₁, x₂, x₃` of the three
pillar calls match the vega, vanna and volga of a call at any positive strike `K` (all at the
flat vol) exactly when `xᵢ = ν(K)/ν(Kᵢ) · yᵢ(K)`: the log-strike weights scaled by vegas, and
no other amounts do. -/
theorem vanna_volga_hedge_weights_are_log_strike_weights
    (S rd rf σ T K₁ K₂ K₃ K x₁ x₂ x₃ : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T)
    (hK₁ : 0 < K₁) (hK₂ : 0 < K₂) (hK₃ : 0 < K₃) (hK : 0 < K)
    (h₁₂ : K₁ ≠ K₂) (h₁₃ : K₁ ≠ K₃) (h₂₃ : K₂ ≠ K₃) :
    (x₁ * vega S rd rf σ T K₁ + x₂ * vega S rd rf σ T K₂ + x₃ * vega S rd rf σ T K₃
          = vega S rd rf σ T K ∧
        x₁ * vanna S rd rf σ T K₁ + x₂ * vanna S rd rf σ T K₂ + x₃ * vanna S rd rf σ T K₃
          = vanna S rd rf σ T K ∧
        x₁ * volga S rd rf σ T K₁ + x₂ * volga S rd rf σ T K₂ + x₃ * volga S rd rf σ T K₃
          = volga S rd rf σ T K) ↔
      (x₁ = vega S rd rf σ T K / vega S rd rf σ T K₁ * y1 K₁ K₂ K₃ K ∧
        x₂ = vega S rd rf σ T K / vega S rd rf σ T K₂ * y2 K₁ K₂ K₃ K ∧
        x₃ = vega S rd rf σ T K / vega S rd rf σ T K₃ * y3 K₁ K₂ K₃ K) := by
  have hr : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hs : 0 < σ * Real.sqrt T := mul_pos hσ hr
  have hvpos : ∀ x, 0 < vega S rd rf σ T x := by
    intro x; unfold vega φ; positivity
  set κ : ℝ := -1 / (S * σ * Real.sqrt T) with hκdef
  have hκ : κ ≠ 0 := by rw [hκdef]; exact div_ne_zero (by norm_num) (by positivity)
  set μ : ℝ := 1 / σ with hμdef
  have hμ : μ ≠ 0 := by rw [hμdef]; exact div_ne_zero one_ne_zero hσ.ne'
  have hvanna : ∀ x, vanna S rd rf σ T x = κ * (vega S rd rf σ T x * d2 S rd rf σ T x) := by
    intro x; unfold vanna; rw [hκdef]; ring
  have hvolga : ∀ x, volga S rd rf σ T x = μ * (vega S rd rf σ T x *
      (d2 S rd rf σ T x ^ 2 + σ * Real.sqrt T * d2 S rd rf σ T x)) := by
    intro x
    have : d1 S rd rf σ T x = d2 S rd rf σ T x + σ * Real.sqrt T := by unfold d2; ring
    unfold volga; rw [this, hμdef]; ring
  have hl : ∀ {a b : ℝ}, 0 < a → 0 < b → a ≠ b →
      d2 S rd rf σ T a ≠ d2 S rd rf σ T b := by
    intro a b ha hb hab h
    have h0 := d2_sub_d2 S rd rf σ T a b hS hσ hT ha hb
    rw [h, sub_self, eq_comm, div_eq_zero_iff] at h0
    rcases h0 with h0 | h0
    · exact log_ne_log_of_ne ha hb hab (sub_eq_zero.mp h0).symm
    · exact hs.ne' h0
  have e12 := hl hK₁ hK₂ h₁₂
  have e13 := hl hK₁ hK₃ h₁₃
  have e23 := hl hK₂ hK₃ h₂₃
  have a12 := sub_ne_zero.mpr (log_ne_log_of_ne hK₁ hK₂ h₁₂)
  have a13 := sub_ne_zero.mpr (log_ne_log_of_ne hK₁ hK₃ h₁₃)
  have a23 := sub_ne_zero.mpr (log_ne_log_of_ne hK₂ hK₃ h₂₃)
  have a21 := sub_ne_zero.mpr (log_ne_log_of_ne hK₂ hK₁ h₁₂.symm)
  have a31 := sub_ne_zero.mpr (log_ne_log_of_ne hK₃ hK₁ h₁₃.symm)
  have a32 := sub_ne_zero.mpr (log_ne_log_of_ne hK₃ hK₂ h₂₃.symm)
  have l : ∀ x y : ℝ, 0 < x → 0 < y → Real.log (x / y) = Real.log x - Real.log y :=
    fun x y hx hy => Real.log_div hx.ne' hy.ne'
  have dd : ∀ x y : ℝ, 0 < x → 0 < y →
      d2 S rd rf σ T x - d2 S rd rf σ T y = (Real.log y - Real.log x) / (σ * Real.sqrt T) :=
    fun x y hx hy => d2_sub_d2 S rd rf σ T x y hS hσ hT hx hy
  have L1 : y1 K₁ K₂ K₃ K = (d2 S rd rf σ T K - d2 S rd rf σ T K₂) *
      (d2 S rd rf σ T K - d2 S rd rf σ T K₃) /
      ((d2 S rd rf σ T K₁ - d2 S rd rf σ T K₂) * (d2 S rd rf σ T K₁ - d2 S rd rf σ T K₃)) := by
    unfold y1
    rw [dd K K₂ hK hK₂, dd K K₃ hK hK₃, dd K₁ K₂ hK₁ hK₂, dd K₁ K₃ hK₁ hK₃,
      l K₂ K hK₂ hK, l K₃ K hK₃ hK, l K₂ K₁ hK₂ hK₁, l K₃ K₁ hK₃ hK₁]
    field_simp
  have L2 : y2 K₁ K₂ K₃ K = (d2 S rd rf σ T K - d2 S rd rf σ T K₁) *
      (d2 S rd rf σ T K - d2 S rd rf σ T K₃) /
      ((d2 S rd rf σ T K₂ - d2 S rd rf σ T K₁) * (d2 S rd rf σ T K₂ - d2 S rd rf σ T K₃)) := by
    unfold y2
    rw [dd K K₁ hK hK₁, dd K K₃ hK hK₃, dd K₂ K₁ hK₂ hK₁, dd K₂ K₃ hK₂ hK₃,
      l K K₁ hK hK₁, l K₃ K hK₃ hK, l K₂ K₁ hK₂ hK₁, l K₃ K₂ hK₃ hK₂]
    field_simp
    ring
  have L3 : y3 K₁ K₂ K₃ K = (d2 S rd rf σ T K - d2 S rd rf σ T K₁) *
      (d2 S rd rf σ T K - d2 S rd rf σ T K₂) /
      ((d2 S rd rf σ T K₃ - d2 S rd rf σ T K₁) * (d2 S rd rf σ T K₃ - d2 S rd rf σ T K₂)) := by
    unfold y3
    rw [dd K K₁ hK hK₁, dd K K₂ hK hK₂, dd K₃ K₁ hK₃ hK₁, dd K₃ K₂ hK₃ hK₂,
      l K K₁ hK hK₁, l K K₂ hK hK₂, l K₃ K₁ hK₃ hK₁, l K₃ K₂ hK₃ hK₂]
    field_simp
    ring
  rw [L1, L2, L3]
  simp only [hvanna, hvolga]
  have hv₁ := (hvpos K₁).ne'
  have hv₂ := (hvpos K₂).ne'
  have hv₃ := (hvpos K₃).ne'
  generalize vega S rd rf σ T K₁ = ν₁ at *
  generalize vega S rd rf σ T K₂ = ν₂ at *
  generalize vega S rd rf σ T K₃ = ν₃ at *
  generalize vega S rd rf σ T K = ν at *
  generalize d2 S rd rf σ T K₁ = f₁ at *
  generalize d2 S rd rf σ T K₂ = f₂ at *
  generalize d2 S rd rf σ T K₃ = f₃ at *
  generalize d2 S rd rf σ T K = f at *
  generalize σ * Real.sqrt T = s at *
  have key := lagrange_three_weights (x₁ * ν₁) (x₂ * ν₂) (x₃ * ν₃) f₁ f₂ f₃ f ν e12 e13 e23
  constructor
  · rintro ⟨h1, h2, h3⟩
    have h2' : x₁ * ν₁ * f₁ + x₂ * ν₂ * f₂ + x₃ * ν₃ * f₃ = ν * f :=
      mul_left_cancel₀ hκ (by linear_combination h2)
    have h3'' : μ * (x₁ * ν₁ * (f₁ ^ 2 + s * f₁) + x₂ * ν₂ * (f₂ ^ 2 + s * f₂) +
        x₃ * ν₃ * (f₃ ^ 2 + s * f₃)) = μ * (ν * (f ^ 2 + s * f)) := by
      linear_combination h3
    have h3' : x₁ * ν₁ * f₁ ^ 2 + x₂ * ν₂ * f₂ ^ 2 + x₃ * ν₃ * f₃ ^ 2 = ν * f ^ 2 := by
      linear_combination mul_left_cancel₀ hμ h3'' - s * h2'
    obtain ⟨b1, b2, b3⟩ := key.mp ⟨by linear_combination h1, h2', h3'⟩
    refine ⟨?_, ?_, ?_⟩
    · rw [div_mul_eq_mul_div, eq_div_iff hv₁]; linear_combination b1
    · rw [div_mul_eq_mul_div, eq_div_iff hv₂]; linear_combination b2
    · rw [div_mul_eq_mul_div, eq_div_iff hv₃]; linear_combination b3
  · rintro ⟨rfl, rfl, rfl⟩
    obtain ⟨b1, b2, b3⟩ := key.mpr ⟨by field_simp, by field_simp, by field_simp⟩
    refine ⟨?_, ?_, ?_⟩
    · linear_combination b1
    · linear_combination κ * b2
    · linear_combination μ * (b3 + s * b2)

/-- **The weights always add up to 1.** For three distinct positive pillar strikes and any
positive strike `K`, `y₁(K) + y₂(K) + y₃(K) = 1`; so the first-order reading
`y₁σ₁ + y₂σ₂ + y₃σ₃` is a weighted average of the three pillar vols. -/
theorem log_strike_weights_sum_to_one (K₁ K₂ K₃ K : ℝ)
    (hK₁ : 0 < K₁) (hK₂ : 0 < K₂) (hK₃ : 0 < K₃) (hK : 0 < K)
    (h₁₂ : K₁ ≠ K₂) (h₁₃ : K₁ ≠ K₃) (h₂₃ : K₂ ≠ K₃) :
    y1 K₁ K₂ K₃ K + y2 K₁ K₂ K₃ K + y3 K₁ K₂ K₃ K = 1 := by
  have l : ∀ x y : ℝ, 0 < x → 0 < y → Real.log (x / y) = Real.log x - Real.log y :=
    fun x y hx hy => Real.log_div hx.ne' hy.ne'
  have a12 := sub_ne_zero.mpr (log_ne_log_of_ne hK₁ hK₂ h₁₂)
  have a13 := sub_ne_zero.mpr (log_ne_log_of_ne hK₁ hK₃ h₁₃)
  have a23 := sub_ne_zero.mpr (log_ne_log_of_ne hK₂ hK₃ h₂₃)
  have a21 := sub_ne_zero.mpr (log_ne_log_of_ne hK₂ hK₁ h₁₂.symm)
  have a31 := sub_ne_zero.mpr (log_ne_log_of_ne hK₃ hK₁ h₁₃.symm)
  have a32 := sub_ne_zero.mpr (log_ne_log_of_ne hK₃ hK₂ h₂₃.symm)
  unfold y1 y2 y3
  rw [l K₂ K hK₂ hK, l K₃ K hK₃ hK, l K₂ K₁ hK₂ hK₁, l K₃ K₁ hK₃ hK₁, l K K₁ hK hK₁,
    l K₃ K₂ hK₃ hK₂, l K K₂ hK hK₂]
  field_simp
  ring

/-- **The curve passes through all three quotes exactly.** With a positive at-the-money vol
`σ₂`, three distinct positive pillar strikes, and a moderate skew in the sense that the plus
root is the sensible root at the outer pillars (`σ₂ + d₁d₂(Kᵢ)(σᵢ - σ₂) ≥ 0` for `i = 1, 3`),
the second-order vanna-volga smile reads `σ₁` at `K₁`, `σ₂` at `K₂` and `σ₃` at `K₃`. -/
theorem vanna_volga_smile_passes_through_pillars
    (S rd rf T K₁ K₂ K₃ σ₁ σ₂ σ₃ : ℝ) (hσ₂ : 0 < σ₂)
    (hK₁ : 0 < K₁) (hK₂ : 0 < K₂) (hK₃ : 0 < K₃)
    (h₁₂ : K₁ ≠ K₂) (h₁₃ : K₁ ≠ K₃) (h₂₃ : K₂ ≠ K₃)
    (hm₁ : 0 ≤ σ₂ + d1 S rd rf σ₂ T K₁ * d2 S rd rf σ₂ T K₁ * (σ₁ - σ₂))
    (hm₃ : 0 ≤ σ₂ + d1 S rd rf σ₂ T K₃ * d2 S rd rf σ₂ T K₃ * (σ₃ - σ₂)) :
    smile S rd rf T K₁ K₂ K₃ σ₁ σ₂ σ₃ K₁ = σ₁ ∧
      smile S rd rf T K₁ K₂ K₃ σ₁ σ₂ σ₃ K₂ = σ₂ ∧
      smile S rd rf T K₁ K₂ K₃ σ₁ σ₂ σ₃ K₃ = σ₃ := by
  have lnz : ∀ {a b : ℝ}, 0 < a → 0 < b → a ≠ b → Real.log (a / b) ≠ 0 := by
    intro a b ha hb hab h
    rw [Real.log_div ha.ne' hb.ne', sub_eq_zero] at h
    exact log_ne_log_of_ne ha hb hab h
  have y1₁ : y1 K₁ K₂ K₃ K₁ = 1 := by
    unfold y1; exact div_self (mul_ne_zero (lnz hK₂ hK₁ h₁₂.symm) (lnz hK₃ hK₁ h₁₃.symm))
  have y2₁ : y2 K₁ K₂ K₃ K₁ = 0 := by unfold y2; simp [div_self hK₁.ne']
  have y3₁ : y3 K₁ K₂ K₃ K₁ = 0 := by unfold y3; simp [div_self hK₁.ne']
  have y1₂ : y1 K₁ K₂ K₃ K₂ = 0 := by unfold y1; simp [div_self hK₂.ne']
  have y2₂ : y2 K₁ K₂ K₃ K₂ = 1 := by
    unfold y2; exact div_self (mul_ne_zero (lnz hK₂ hK₁ h₁₂.symm) (lnz hK₃ hK₂ h₂₃.symm))
  have y3₂ : y3 K₁ K₂ K₃ K₂ = 0 := by unfold y3; simp [div_self hK₂.ne']
  have y1₃ : y1 K₁ K₂ K₃ K₃ = 0 := by unfold y1; simp [div_self hK₃.ne']
  have y2₃ : y2 K₁ K₂ K₃ K₃ = 0 := by unfold y2; simp [div_self hK₃.ne']
  have y3₃ : y3 K₁ K₂ K₃ K₃ = 1 := by
    unfold y3; exact div_self (mul_ne_zero (lnz hK₃ hK₁ h₁₃.symm) (lnz hK₃ hK₂ h₂₃.symm))
  unfold smile
  simp only [y1₁, y2₁, y3₁, y1₂, y2₂, y3₂, y1₃, y2₃, y3₃]
  generalize d1 S rd rf σ₂ T K₁ * d2 S rd rf σ₂ T K₁ = p₁ at *
  generalize d1 S rd rf σ₂ T K₂ * d2 S rd rf σ₂ T K₂ = p₂ at *
  generalize d1 S rd rf σ₂ T K₃ * d2 S rd rf σ₂ T K₃ = p₃ at *
  have hσ₂' := hσ₂.ne'
  refine ⟨?_, ?_, ?_⟩
  · split_ifs with hP
    · subst hP; field_simp; ring
    · rw [show σ₂ ^ 2 + p₁ * (2 * σ₂ * (1 * σ₁ + 0 * σ₂ + 0 * σ₃ - σ₂) +
          (1 * p₁ * (σ₁ - σ₂) ^ 2 + 0 * p₃ * (σ₃ - σ₂) ^ 2)) =
          (σ₂ + p₁ * (σ₁ - σ₂)) ^ 2 by ring, Real.sqrt_sq hm₁]
      field_simp; ring
  · split_ifs with hP
    · ring
    · rw [show σ₂ ^ 2 + p₂ * (2 * σ₂ * (0 * σ₁ + 1 * σ₂ + 0 * σ₃ - σ₂) +
          (0 * p₁ * (σ₁ - σ₂) ^ 2 + 0 * p₃ * (σ₃ - σ₂) ^ 2)) = σ₂ ^ 2 by ring,
        Real.sqrt_sq hσ₂.le]
      ring
  · split_ifs with hP
    · subst hP; field_simp; ring
    · rw [show σ₂ ^ 2 + p₃ * (2 * σ₂ * (0 * σ₁ + 0 * σ₂ + 1 * σ₃ - σ₂) +
          (0 * p₁ * (σ₁ - σ₂) ^ 2 + 1 * p₃ * (σ₃ - σ₂) ^ 2)) =
          (σ₂ + p₃ * (σ₃ - σ₂)) ^ 2 by ring, Real.sqrt_sq hm₃]
      field_simp; ring

#print axioms vanna_volga_hedge_weights_are_log_strike_weights
#print axioms log_strike_weights_sum_to_one
#print axioms vanna_volga_smile_passes_through_pillars

end VannaVolgaSmile
