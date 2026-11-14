-- Market making: in the Avellaneda-Stoikov model the dealer's reservation prices for buying and selling one lot centre on S - q*gamma*sigma^2*tau, and each side's best quote distance is the concession c minus the fill's change in value.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory

/-! Notation, following the card. The mid of one lot is `S`, the position is `q` lots
(positive = long), the risk aversion is `γ > 0`, the volatility of the mid is `σ`,
and the time left to the close is `τ ≥ 0`. The mid at the close is `S + σ * √τ * Z`
with `Z` a standard bell-curve draw, Mathlib's `gaussianReal 0 1`.
A dealer with exponential utility `-exp (-γ W)` rates a frozen position of `x` lots,
marked at the close, as worth for certain
`CE x = -(1/γ) * log E[exp (-γ * x * (S + σ * √τ * Z))]` (its certainty equivalent).
The reservation bid is what one more lot adds, `r^b = CE (q+1) - CE q`; the
reservation ask is what one lot fewer removes, `r^a = CE q - CE (q-1)`. -/

lemma gauss_mgf_std (t : ℝ) :
    ∫ z, Real.exp (t * z) ∂(gaussianReal 0 1) = Real.exp (t ^ 2 / 2) := by
  have h := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) t
  simp only [mgf, id] at h
  rw [h]
  congr 1
  push_cast
  ring

lemma ce_frozen_aux (S σ γ τ x : ℝ) (hγ : 0 < γ) (hτ : 0 ≤ τ) :
    -(1 / γ) * Real.log (∫ z, Real.exp (-γ * (x * (S + σ * Real.sqrt τ * z))) ∂(gaussianReal 0 1))
      = x * S - 1 / 2 * γ * x ^ 2 * σ ^ 2 * τ := by
  have hfun : (fun z => Real.exp (-γ * (x * (S + σ * Real.sqrt τ * z))))
      = fun z => Real.exp (-γ * x * S) * Real.exp ((-γ * x * σ * Real.sqrt τ) * z) := by
    funext z
    rw [← Real.exp_add]
    congr 1
    ring
  rw [hfun, integral_const_mul, gauss_mgf_std, ← Real.exp_add, Real.log_exp]
  have hs : Real.sqrt τ ^ 2 = τ := Real.sq_sqrt hτ
  have : (-γ * x * σ * Real.sqrt τ) ^ 2 = γ ^ 2 * x ^ 2 * σ ^ 2 * τ := by
    rw [mul_pow, hs]; ring
  rw [this]
  field_simp
  ring

#print axioms gauss_mgf_std
#print axioms ce_frozen_aux

lemma gain_ineq (k γ h : ℝ) (hγ : 0 < γ) (hk : 0 < k) (hh : h ≠ 0) :
    (k + γ) * Real.exp (-k * h) < k * Real.exp (-(k + γ) * h) + γ := by
  have hkg : 0 < k + γ := by linarith
  have hx : -(k + γ) * h ≠ 0 := by
    intro h0
    rcases mul_eq_zero.1 h0 with h1 | h1
    · linarith
    · exact hh h1
  have key := strictConvexOn_exp.2 (Set.mem_univ (-(k + γ) * h)) (Set.mem_univ 0) hx
    (div_pos hk hkg) (div_pos hγ hkg) (by field_simp)
  simp only [smul_eq_mul, mul_zero, add_zero, Real.exp_zero, mul_one] at key
  have e1 : k / (k + γ) * (-(k + γ) * h) = -k * h := by field_simp
  rw [e1] at key
  have := mul_lt_mul_of_pos_left key hkg
  have e2 : (k + γ) * (k / (k + γ) * Real.exp (-(k + γ) * h) + γ / (k + γ))
      = k * Real.exp (-(k + γ) * h) + γ := by field_simp
  linarith

#print axioms gain_ineq

/-- Step 1 of the card: a frozen position of `x` lots, marked at the mid at the close,
is worth for certain `x * S - (1/2) * γ * x^2 * σ^2 * τ` to a dealer with exponential
dislike of risk: the position at today's mid, less a risk discount that grows with the
square of the position. -/
theorem certainty_equivalent_of_frozen_position (S σ γ τ x : ℝ) (hγ : 0 < γ) (hτ : 0 ≤ τ) :
    -(1 / γ) * Real.log (∫ z, Real.exp (-γ * (x * (S + σ * Real.sqrt τ * z))) ∂(gaussianReal 0 1))
      = x * S - 1 / 2 * γ * x ^ 2 * σ ^ 2 * τ := by
  exact ce_frozen_aux S σ γ τ x hγ hτ

/-- The card's main claim (Step 2): the reservation bid and ask are
`r^b = S - γ σ² τ (q + 1/2)` and `r^a = S - γ σ² τ (q - 1/2)`. Their midpoint, the
reservation price the quotes centre on, is `r = S - q γ σ² τ`: it sits below the mid
whenever the dealer is long (and the price moves and time is left), by an amount that
grows with the position, the variance and the time left. -/
theorem reservation_price_centre (S σ γ τ : ℝ) (q : ℤ) (hγ : 0 < γ) (hτ : 0 ≤ τ) :
    let CE : ℝ → ℝ := fun x =>
      -(1 / γ) * Real.log (∫ z, Real.exp (-γ * (x * (S + σ * Real.sqrt τ * z))) ∂(gaussianReal 0 1))
    let rb := CE ((q : ℝ) + 1) - CE (q : ℝ)
    let ra := CE (q : ℝ) - CE ((q : ℝ) - 1)
    rb = S - γ * σ ^ 2 * τ * ((q : ℝ) + 1 / 2) ∧
    ra = S - γ * σ ^ 2 * τ * ((q : ℝ) - 1 / 2) ∧
    (ra + rb) / 2 = S - (q : ℝ) * γ * σ ^ 2 * τ ∧
    ((0 < q ∧ σ ≠ 0 ∧ 0 < τ) → (ra + rb) / 2 < S) := by
  intro CE rb ra
  have hCE : ∀ x, CE x = x * S - 1 / 2 * γ * x ^ 2 * σ ^ 2 * τ :=
    fun x => ce_frozen_aux S σ γ τ x hγ hτ
  have hrb : rb = S - γ * σ ^ 2 * τ * ((q : ℝ) + 1 / 2) := by
    simp only [rb, hCE]; ring
  have hra : ra = S - γ * σ ^ 2 * τ * ((q : ℝ) - 1 / 2) := by
    simp only [ra, hCE]; ring
  have hmid : (ra + rb) / 2 = S - (q : ℝ) * γ * σ ^ 2 * τ := by
    rw [hra, hrb]; ring
  refine ⟨hrb, hra, hmid, ?_⟩
  rintro ⟨hq, hσ, hτ'⟩
  rw [hmid]
  have hq' : (0 : ℝ) < q := by exact_mod_cast hq
  have : 0 < (q : ℝ) * γ * σ ^ 2 * τ := by positivity
  linarith

/-- Step 3 of the card: with fills at rate `A e^{-kδ}` and a fill changing the value
adjustment by `d`, one side's contribution `(A/γ) e^{-kδ} (1 - e^{-γ(δ + d)})` has exactly
one global maximum, at distance `δ* = c - d` where `c = ln(1 + γ/k)/γ` is the concession:
every other distance gives strictly less. -/
theorem best_quote_distance_is_concession_minus_d (A γ k d : ℝ) (hA : 0 < A) (hγ : 0 < γ)
    (hk : 0 < k) :
    let gain : ℝ → ℝ := fun δ => A / γ * Real.exp (-k * δ) * (1 - Real.exp (-γ * (δ + d)))
    let c := Real.log (1 + γ / k) / γ
    ∀ δ : ℝ, δ ≠ c - d → gain δ < gain (c - d) := by
  intro gain c δ hδ
  set h := δ - (c - d) with hh_def
  have hh : h ≠ 0 := sub_ne_zero.2 hδ
  have hkg : 0 < k + γ := by linarith
  have hEc : Real.exp (-γ * c) = k / (k + γ) := by
    have : -γ * c = -Real.log (1 + γ / k) := by
      simp only [c]; field_simp
    rw [this, Real.exp_neg, Real.exp_log (by positivity)]
    field_simp
  have hδeq : δ = (c - d) + h := by simp [hh_def]
  have key := gain_ineq k γ h hγ hk hh
  simp only [gain]
  rw [hδeq]
  have e1 : Real.exp (-k * (c - d + h)) = Real.exp (-k * (c - d)) * Real.exp (-k * h) := by
    rw [← Real.exp_add]; ring_nf
  have e2 : Real.exp (-γ * (c - d + h + d)) = Real.exp (-γ * c) * Real.exp (-γ * h) := by
    rw [← Real.exp_add]; ring_nf
  have e3 : Real.exp (-γ * (c - d + d)) = Real.exp (-γ * c) := by ring_nf
  have e4 : Real.exp (-(k + γ) * h) = Real.exp (-k * h) * Real.exp (-γ * h) := by
    rw [← Real.exp_add]; ring_nf
  rw [e1, e2, e3, hEc]
  rw [e4] at key
  have hpos : 0 < A / γ * Real.exp (-k * (c - d)) := by positivity
  have inner : Real.exp (-k * h) * (1 - k / (k + γ) * Real.exp (-γ * h)) < 1 - k / (k + γ) := by
    rw [div_mul_eq_mul_div, one_sub_div hkg.ne', one_sub_div hkg.ne', mul_div_assoc']
    rw [div_lt_div_iff_of_pos_right hkg]
    nlinarith
  have := mul_lt_mul_of_pos_left inner hpos
  calc A / γ * (Real.exp (-k * (c - d)) * Real.exp (-k * h)) * (1 - k / (k + γ) * Real.exp (-γ * h))
      = A / γ * Real.exp (-k * (c - d)) * (Real.exp (-k * h) * (1 - k / (k + γ) * Real.exp (-γ * h))) := by ring
    _ < A / γ * Real.exp (-k * (c - d)) * (1 - k / (k + γ)) := this

/-! The card's worked numbers, by hand: `S = 10000`, `q = 5`, `γ = 1/1000`, `σ = 20`,
`τ = 1` (prices in dollars per lot). Exact fractions, no decimals. -/

-- Risk of one lot to the close: γ σ² τ = 0.40.
example : (1 / 1000 : ℝ) * 20 ^ 2 * 1 = 2 / 5 := by norm_num
-- Skew: q γ σ² τ = $2.00 a lot.
example : (5 : ℝ) * (1 / 1000) * 20 ^ 2 * 1 = 2 := by norm_num
-- Reservation centre: r = 10000 - 2 = $9,998.00.
example : (10000 : ℝ) - 5 * (1 / 1000) * 20 ^ 2 * 1 = 9998 := by norm_num
-- Reservation bid: r^b = $9,997.80.
example : (10000 : ℝ) - (1 / 1000) * 20 ^ 2 * 1 * (5 + 1 / 2) = 9997 + 4 / 5 := by norm_num
-- Reservation ask: r^a = $9,998.20.
example : (10000 : ℝ) - (1 / 1000) * 20 ^ 2 * 1 * (5 - 1 / 2) = 9998 + 1 / 5 := by norm_num
-- A tenth of the day left, long 5 lots: the centre is $9,999.80 a lot ($99.9980 a share).
example : (10000 : ℝ) - 5 * (1 / 1000) * 20 ^ 2 * (1 / 10) = 9999 + 4 / 5 := by norm_num

#print axioms certainty_equivalent_of_frozen_position
#print axioms reservation_price_centre
#print axioms best_quote_distance_is_concession_minus_d
