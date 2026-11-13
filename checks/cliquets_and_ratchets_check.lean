-- Cliquets: in any pricing model the uncapped cliquet is worth the sum of its forward-start legs, each clipped coupon is the return minus a call above the cap plus a put below the floor, and the globally floored cliquet's price lies between the price of its coupons alone and the price with each quarter floored at zero.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Probability.Notation

open Real MeasureTheory

/-- The uncapped identity, in every model. Acme's price on the reset dates t₀, t₁, …, tₙ is S 0, S 1,
…, S n (random amounts on the pretend, risk-neutral world μ). The uncapped cliquet pays at year end T
the sum over the n periods of 100 · max(S(i+1)/S(i) − 1, 0). If each leg's payout has a finite average
(is integrable), then the cliquet's price today, e^(−rT) times the average payout, equals the sum of
the n forward-start legs' prices, each e^(−rT) times the average of its own payout: averages add. -/
theorem uncapped_cliquet_price_eq_sum_of_forward_start_legs
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (S : ℕ → Ω → ℝ) (n : ℕ) (r T : ℝ)
    (hleg : ∀ i ∈ Finset.range n, Integrable (fun ω => 100 * max (S (i + 1) ω / S i ω - 1) 0) μ) :
    exp (-r * T) * ∫ ω, ∑ i ∈ Finset.range n, 100 * max (S (i + 1) ω / S i ω - 1) 0 ∂μ
      = ∑ i ∈ Finset.range n, exp (-r * T) * ∫ ω, 100 * max (S (i + 1) ω / S i ω - 1) 0 ∂μ := by
  rw [integral_finsetSum _ hleg, Finset.mul_sum]

/-- Each clipped coupon is a forward plus a put minus a call. With a local floor f no higher than the
local cap c, the return R clipped to between f and c equals R, minus a call on R struck at c, plus a
put on R struck at f: min(max(R, f), c) = R − max(R − c, 0) + max(f − R, 0). -/
theorem clipped_coupon_eq_return_sub_call_add_put (R f c : ℝ) (hfc : f ≤ c) :
    min (max R f) c = R - max (R - c) 0 + max (f - R) 0 := by
  rcases le_total R f with h1 | h1
  · rw [max_eq_right h1, min_eq_left hfc, max_eq_right (by linarith : R - c ≤ 0),
      max_eq_left (by linarith : 0 ≤ f - R)]
    ring
  · rw [max_eq_left h1, max_eq_right (by linarith : f - R ≤ 0)]
    rcases le_total R c with h2 | h2
    · rw [min_eq_left h2, max_eq_right (by linarith : R - c ≤ 0)]
      ring
    · rw [min_eq_right h2, max_eq_left (by linarith : 0 ≤ R - c)]
      ring

/-- The global floor's price bounds. On every path the floored total max(Σ cᵢ, 0) lies between the sum
of the clipped coupons Σ cᵢ and the sum of the coupons each floored at zero Σ max(cᵢ, 0). So, for
prices S 0, …, S n that are random amounts on the risk-neutral world μ, the globally floored cliquet's
price lies between the price of its coupons alone (no global floor) and the price of the same strip
with each quarter floored at zero instead of at f. -/
theorem cliquet_price_between_coupons_alone_and_local_floor_zero
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (S : ℕ → Ω → ℝ) (n : ℕ) (r T f c : ℝ) (hS : ∀ i, Measurable (S i)) :
    exp (-r * T) * ∫ ω, 100 * ∑ i ∈ Finset.range n, min (max (S (i + 1) ω / S i ω - 1) f) c ∂μ
      ≤ exp (-r * T) * ∫ ω, 100 * max (∑ i ∈ Finset.range n, min (max (S (i + 1) ω / S i ω - 1) f) c) 0 ∂μ
    ∧ exp (-r * T) * ∫ ω, 100 * max (∑ i ∈ Finset.range n, min (max (S (i + 1) ω / S i ω - 1) f) c) 0 ∂μ
      ≤ exp (-r * T) * ∫ ω, 100 * ∑ i ∈ Finset.range n, max (min (max (S (i + 1) ω / S i ω - 1) f) c) 0 ∂μ := by
  set g : ℕ → Ω → ℝ := fun i ω => min (max (S (i + 1) ω / S i ω - 1) f) c with hg
  have hgm : ∀ i, Measurable (g i) := fun i =>
    ((((hS (i + 1)).div (hS i)).sub_const 1).max measurable_const).min measurable_const
  have hgb : ∀ i ω, |g i ω| ≤ |f| + |c| := by
    intro i ω
    simp only [hg]
    rw [abs_le]
    constructor
    · rcases le_total (max (S (i + 1) ω / S i ω - 1) f) c with h | h
      · rw [min_eq_left h]
        have := le_max_right (S (i + 1) ω / S i ω - 1) f
        have := neg_abs_le f
        have := abs_nonneg c
        linarith
      · rw [min_eq_right h]
        have := neg_abs_le c
        have := abs_nonneg f
        linarith
    · have := min_le_right (max (S (i + 1) ω / S i ω - 1) f) c
      have := le_abs_self c
      have := abs_nonneg f
      linarith
  have hgi : ∀ i, Integrable (g i) μ := fun i =>
    Integrable.of_bound (hgm i).aestronglyMeasurable (|f| + |c|)
      (Filter.Eventually.of_forall (fun ω => by simpa [Real.norm_eq_abs] using hgb i ω))
  have hsum : Integrable (fun ω => ∑ i ∈ Finset.range n, g i ω) μ :=
    integrable_finsetSum _ (fun i _ => hgi i)
  have h1 : Integrable (fun ω => 100 * ∑ i ∈ Finset.range n, g i ω) μ := hsum.const_mul 100
  have h2 : Integrable (fun ω => 100 * max (∑ i ∈ Finset.range n, g i ω) 0) μ :=
    (hsum.sup (integrable_const (0 : ℝ))).const_mul 100
  have h3 : Integrable (fun ω => 100 * ∑ i ∈ Finset.range n, max (g i ω) 0) μ :=
    (integrable_finsetSum _ (fun i _ => (hgi i).sup (integrable_const (0 : ℝ)))).const_mul 100
  have hexp : 0 ≤ exp (-r * T) := (exp_pos _).le
  constructor
  · apply mul_le_mul_of_nonneg_left _ hexp
    apply integral_mono h1 h2
    intro ω
    have := le_max_left (∑ i ∈ Finset.range n, g i ω) 0
    simp only
    linarith
  · apply mul_le_mul_of_nonneg_left _ hexp
    apply integral_mono h2 h3
    intro ω
    simp only
    have hA : ∑ i ∈ Finset.range n, g i ω ≤ ∑ i ∈ Finset.range n, max (g i ω) 0 :=
      Finset.sum_le_sum (fun i _ => le_max_left _ _)
    have hB : 0 ≤ ∑ i ∈ Finset.range n, max (g i ω) 0 :=
      Finset.sum_nonneg (fun i _ => le_max_right _ _)
    have := max_le hA hB
    linarith

-- The card's sample path, in whole percent: returns +8, −3, +2, −7 clip to +5, −3, +2, −5.
example : [(8 : ℤ), -3, 2, -7].map (fun x => min (max x (-5)) 5) = [5, -3, 2, -5] := by decide
-- The coupons add to −1%, so the holder is paid max(−1, 0) = 0.
example : ([(8 : ℤ), -3, 2, -7].map (fun x => min (max x (-5)) 5)).sum = -1 := by decide
example : max (-1 : ℤ) 0 = 0 := by decide
-- Without caps and floors, counting only the gains: 8% + 2% = 10%.
example : ([(8 : ℤ), -3, 2, -7].map (fun x => max x 0)).sum = 10 := by decide
-- Step 2's three checks: at +8%: 8 − 3 + 0 = 5; at −7%: −7 − 0 + 2 = −5; at +2%: 2 − 0 + 0 = 2.
example : (8 : ℤ) - max (8 - 5) 0 + max (-5 - 8) 0 = 5 := by decide
example : (-7 : ℤ) - max (-7 - 5) 0 + max (-5 - (-7)) 0 = -5 := by decide
example : (2 : ℤ) - max (2 - 5) 0 + max (-5 - 2) 0 = 2 := by decide
-- Step 3's global floor as a put, on the sample total −1%: max(−1, 0) = −1 + max(1, 0).
example : max (-1 : ℤ) 0 = -1 + max (-(-1)) 0 := by decide
-- Step 1's discount: for every quarter i of 4, the wait after it plus the wait before it is 3 quarters.
example : ∀ i ∈ Finset.Icc 1 4, (4 - i) + (i - 1) = 3 := by decide

#print axioms uncapped_cliquet_price_eq_sum_of_forward_start_legs
#print axioms clipped_coupon_eq_return_sub_call_add_put
#print axioms cliquet_price_between_coupons_alone_and_local_floor_zero
