-- Distance to default: when log asset value is a bell curve, the default chance is the normal tail beyond the distance to default, and the real-world distance exceeds Merton's d2 by exactly lambda times the square root of T.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory

/-- Distance to default and EDF. Assets start at `V > 0` and follow the geometric
Brownian motion with real drift `μ` and volatility `σ > 0`, so on the due date `T > 0`
they are `V_T = V · exp((μ - σ²/2) T + σ √T Z)` with `Z` a standard bell-curve draw.
Then the chance of default, `P(V_T < D)` for a debt `D > 0`, equals `N(-DD)`, where
`DD = (ln(V/D) + (μ - σ²/2) T) / (σ √T)` and `N` is the standard normal CDF. -/
theorem default_probability_eq_normal_cdf_neg_distance_to_default
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (Z : Ω → ℝ) (hZ : HasLaw Z (gaussianReal 0 1) P)
    (V D T σ μ : ℝ) (hV : 0 < V) (hD : 0 < D) (hT : 0 < T) (hσ : 0 < σ) :
    P.real {ω | V * Real.exp ((μ - σ ^ 2 / 2) * T + σ * Real.sqrt T * Z ω) < D}
      = cdf (gaussianReal 0 1)
          (-((Real.log (V / D) + (μ - σ ^ 2 / 2) * T) / (σ * Real.sqrt T))) := by
  set c := -((Real.log (V / D) + (μ - σ ^ 2 / 2) * T) / (σ * Real.sqrt T)) with hc
  have hb : 0 < σ * Real.sqrt T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have key : ∀ z : ℝ, V * Real.exp ((μ - σ ^ 2 / 2) * T + σ * Real.sqrt T * z) < D ↔ z < c := by
    intro z
    rw [← lt_div_iff₀' hV, ← Real.lt_log_iff_exp_lt (div_pos hD hV), hc, ← neg_div,
      lt_div_iff₀ hb, Real.log_div hD.ne' hV.ne', Real.log_div hV.ne' hD.ne']
    constructor <;> intro h <;> linarith
  have hset : {ω | V * Real.exp ((μ - σ ^ 2 / 2) * T + σ * Real.sqrt T * Z ω) < D}
      = {ω | Z ω < c} := by
    ext ω; exact key (Z ω)
  rw [hset, hZ.measureReal_eq (p := fun z => z < c) measurableSet_Iio, cdf_eq_real]
  exact measureReal_congr
    (Iio_ae_eq_Iic' (gaussianReal_absolutelyContinuous 0 one_ne_zero (measure_singleton c)))

/-- The real-world distance to default `DD` (drift `μ`) and Merton's pricing distance
`d₂` (drift `r`) differ by exactly `λ √T`, where `λ = (μ - r)/σ` is the market price of risk. -/
theorem distance_to_default_sub_d2_eq_market_price_of_risk_mul_sqrt
    (V D T σ μ r : ℝ) (hT : 0 < T) (hσ : 0 < σ) :
    (Real.log (V / D) + (μ - σ ^ 2 / 2) * T) / (σ * Real.sqrt T)
      - (Real.log (V / D) + (r - σ ^ 2 / 2) * T) / (σ * Real.sqrt T)
      = (μ - r) / σ * Real.sqrt T := by
  have hs : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hsq : Real.sqrt T * Real.sqrt T = T := Real.mul_self_sqrt hT.le
  rw [← sub_div]
  field_simp
  rw [Real.sq_sqrt hT.le]
  ring

/-- The expected default frequency `N(-DD)` and the pricing default chance `N(-d₂)` are
equal exactly when the real expected growth `μ` equals the riskless rate `r`. -/
theorem edf_eq_pricing_default_chance_iff
    (V D T σ μ r : ℝ) (hT : 0 < T) (hσ : 0 < σ) :
    cdf (gaussianReal 0 1) (-((Real.log (V / D) + (μ - σ ^ 2 / 2) * T) / (σ * Real.sqrt T)))
        = cdf (gaussianReal 0 1) (-((Real.log (V / D) + (r - σ ^ 2 / 2) * T) / (σ * Real.sqrt T)))
      ↔ μ = r := by
  have hmono : StrictMono (cdf (gaussianReal 0 1)) := by
    intro x y hxy
    rw [cdf_eq_real, cdf_eq_real]
    have hpos : 0 < (gaussianReal 0 1) (Set.Ioc x y) := by
      rw [pos_iff_ne_zero]
      intro h0
      have := gaussianReal_absolutelyContinuous' 0 one_ne_zero h0
      rw [Real.volume_Ioc] at this
      simp [ENNReal.ofReal_eq_zero] at this
      linarith
    have hU : Set.Iic y = Set.Iic x ∪ Set.Ioc x y := (Set.Iic_union_Ioc_eq_Iic hxy.le).symm
    rw [hU, measureReal_union (Set.disjoint_left.mpr fun a ha hb => by
      simp only [Set.mem_Iic, Set.mem_Ioc] at ha hb; linarith) measurableSet_Ioc]
    have : 0 < (gaussianReal 0 1).real (Set.Ioc x y) :=
      ENNReal.toReal_pos hpos.ne' (measure_ne_top _ _)
    linarith
  have hs : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  rw [hmono.injective.eq_iff, neg_inj, ← sub_eq_zero,
    distance_to_default_sub_d2_eq_market_price_of_risk_mul_sqrt V D T σ μ r hT hσ,
    mul_eq_zero, div_eq_zero_iff, sub_eq_zero]
  constructor
  · rintro ((h | h) | h)
    · exact h
    · exact absurd h hσ.ne'
    · exact absurd h hs.ne'
  · intro h; exact Or.inl (Or.inl h)

-- Kestrel Freight, exact parts of the worked numbers (percentages written as fractions).
-- Real log-drift: μ - σ²/2 = 8% - (20%)²/2 = 6%.
example : (8 / 100 : ℝ) - (20 / 100) ^ 2 / 2 = 6 / 100 := by norm_num
-- Market price of risk: λ = (8% - 5%) / 20% = 0.15.
example : ((8 / 100 : ℝ) - 5 / 100) / (20 / 100) = 15 / 100 := by norm_num
-- Pricing log-drift: r - σ²/2 = 5% - 2% = 3%.
example : (5 / 100 : ℝ) - (20 / 100) ^ 2 / 2 = 3 / 100 := by norm_num
-- Practitioner's shortcut: (V - D) / (σ V) = (100 - 80) / (20% × 100) = 1.
example : ((100 : ℝ) - 80) / (20 / 100 * 100) = 1 := by norm_num

#print axioms default_probability_eq_normal_cdf_neg_distance_to_default
#print axioms distance_to_default_sub_d2_eq_market_price_of_risk_mul_sqrt
#print axioms edf_eq_pricing_default_chance_iff
