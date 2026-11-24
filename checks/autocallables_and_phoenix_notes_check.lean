-- Autocallables: a note's model value is a straight line in its coupon, so a positive coupon value gives exactly one fair coupon, (target - A) / B.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability

open MeasureTheory

/-- The note's value is a straight line in its coupon. Fix the pricing-world probability
measure `μ` on paths. On each path `ω` the coupon is a fixed number per date, so the
discounted payment is `a ω + c * s ω`: a redemption part `a ω` (the intercept) plus the
coupon `c` times the discounted coupon count `s ω` (the slope); neither depends on `c`.
Then the price, the average payment, is `V(c) = A + c * B`, where `A` is the average
intercept (the redemption value) and `B` the average slope (the value of one unit of coupon). -/
theorem note_value_affine_in_coupon {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (a s : Ω → ℝ)
    (ha : Integrable a μ) (hs : Integrable s μ) (c : ℝ) :
    ∫ ω, (a ω + c * s ω) ∂μ = (∫ ω, a ω ∂μ) + c * ∫ ω, s ω ∂μ := by
  rw [integral_add ha (hs.const_mul c), integral_const_mul]

/-- The fair coupon is one division. If one unit of coupon has positive value `B`, the
note's value `V(c) = ∫ (a + c s) dμ` rises strictly in `c`, and it equals the target `V*`
at exactly one coupon, `c* = (V* - A) / B`. -/
theorem fair_coupon_unique {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (a s : Ω → ℝ)
    (ha : Integrable a μ) (hs : Integrable s μ)
    (hB : 0 < ∫ ω, s ω ∂μ) (Vstar : ℝ) :
    StrictMono (fun c : ℝ => ∫ ω, (a ω + c * s ω) ∂μ) ∧
      ∀ c : ℝ, (∫ ω, (a ω + c * s ω) ∂μ = Vstar ↔
        c = (Vstar - ∫ ω, a ω ∂μ) / ∫ ω, s ω ∂μ) := by
  have h1 : ∀ c : ℝ, ∫ ω, (a ω + c * s ω) ∂μ = (∫ ω, a ω ∂μ) + c * ∫ ω, s ω ∂μ := fun c =>
    note_value_affine_in_coupon μ a s ha hs c
  refine ⟨fun x y hxy => ?_, fun c => ?_⟩
  · simp only [h1]
    have := mul_lt_mul_of_pos_right hxy hB
    linarith
  · rw [h1, eq_div_iff hB.ne']
    constructor <;> intro h <;> linarith

/-- The value of one unit of coupon is positive: the discounted coupon count is never
negative, and it is positive on an event of positive chance (a year-1 call). -/
theorem coupon_value_pos {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (s : Ω → ℝ) (hs : Integrable s μ)
    (hnn : ∀ ω, 0 ≤ s ω) (E : Set Ω) (hE : 0 < μ E) (hpos : ∀ ω ∈ E, 0 < s ω) :
    0 < ∫ ω, s ω ∂μ := by
  rw [integral_pos_iff_support_of_nonneg (fun ω => hnn ω) hs]
  refine lt_of_lt_of_le hE (measure_mono fun ω hω => ?_)
  exact (hpos ω hω).ne'

#print axioms note_value_affine_in_coupon
#print axioms fair_coupon_unique
#print axioms coupon_value_pos
