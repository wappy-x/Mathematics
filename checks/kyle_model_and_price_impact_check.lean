-- Kyle's model: the only straight-line equilibrium of the one-auction market has lambda = σv / (2 σu) and beta = σu / σv, it closes half the price gap, and a book whose depth grows linearly with distance gives square-root impact.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

/-- Kyle's one-auction market. The insider's rule `x = β w` (with `w = v - p₀`) is a best
response to the dealer's rule `P = p₀ + λ y` when, for every mispricing `w`, it maximizes the
insider's average profit `x (w - λ x)`; the dealer's rule is fair when `λ` is the regression slope
`β σv² / (β² σv² + σu²)` of value on total flow. With positive standard deviations `σv`, `σu`,
the pair `(λ, β)` is such a straight-line equilibrium exactly when `λ = σv / (2 σu)` and
`β = σu / σv`: it exists and it is the only one. -/
theorem kyle_lambda_unique_linear_equilibrium (σv σu lam β : ℝ) (hv : 0 < σv) (hu : 0 < σu) :
    ((∀ w x : ℝ, x * (w - lam * x) ≤ (β * w) * (w - lam * (β * w))) ∧
        lam = β * σv ^ 2 / (β ^ 2 * σv ^ 2 + σu ^ 2)) ↔
      (lam = σv / (2 * σu) ∧ β = σu / σv) := by
  constructor
  · rintro ⟨h, hl⟩
    have h0 := h 0 1
    have hlam0 : 0 ≤ lam := by nlinarith
    have hlam : 0 < lam := by
      rcases hlam0.lt_or_eq with h' | h'
      · exact h'
      · exfalso
        have := h 1 (β + 1)
        rw [← h'] at this
        nlinarith
    have h1 := h 1 (1 / (2 * lam))
    have hb : 2 * lam * β = 1 := by
      have e : 1 / (2 * lam) * (1 - lam * (1 / (2 * lam))) = 1 / (4 * lam) := by
        field_simp; ring
      rw [e] at h1
      have : lam * (β - 1 / (2 * lam)) ^ 2 ≤ 0 := by
        have e2 : lam * (β - 1 / (2 * lam)) ^ 2 = 1 / (4 * lam) - β * 1 * (1 - lam * (β * 1)) := by
          field_simp; ring
        rw [e2]; linarith
      have hsq : (β - 1 / (2 * lam)) ^ 2 = 0 := by
        have := mul_nonpos_iff.mp this
        rcases this with ⟨_, h2⟩ | ⟨h2, _⟩
        · exact le_antisymm h2 (sq_nonneg _)
        · linarith
      have : β = 1 / (2 * lam) := by
        have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp hsq
        linarith
      rw [this]; field_simp
    have hden : 0 < β ^ 2 * σv ^ 2 + σu ^ 2 := by positivity
    rw [eq_div_iff hden.ne'] at hl
    have hq : (2 * σu * lam) ^ 2 = σv ^ 2 := by
      have hb' : β = 1 / (2 * lam) := by field_simp; linarith
      subst hb'
      field_simp at hl
      nlinarith [hl]
    have hl2 : 2 * σu * lam = σv := by
      have := (sq_eq_sq₀ (by positivity) hv.le).mp hq
      exact this
    refine ⟨?_, ?_⟩
    · field_simp; linarith
    · field_simp
      nlinarith
  · rintro ⟨rfl, rfl⟩
    refine ⟨?_, ?_⟩
    · intro w x
      have key : (σu / σv * w) * (w - σv / (2 * σu) * (σu / σv * w)) - x * (w - σv / (2 * σu) * x)
          = σv / (2 * σu) * (x - σu / σv * w) ^ 2 := by
        field_simp; ring
      have : 0 ≤ σv / (2 * σu) * (x - σu / σv * w) ^ 2 := by positivity
      linarith
    · field_simp; ring

/-- What Kyle's auction reveals and who pays for it. At the equilibrium `λ = σv / (2 σu)`,
`β = σu / σv`: the insider's order moves the price by half the gap, `λ β w = w / 2`; the value
variance left after the auction is half of `σv²`; the insider's average profit `σv² / (4 λ)` and
the unrelated traders' average loss `λ σu²` both equal `σv σu / 2`. -/
theorem kyle_equilibrium_half_revealed_and_crowd_pays (σv σu : ℝ) (hv : 0 < σv) (hu : 0 < σu) :
    (∀ w : ℝ, σv / (2 * σu) * (σu / σv * w) = w / 2) ∧
      σv ^ 2 - (σu / σv * σv ^ 2) ^ 2 / ((σu / σv) ^ 2 * σv ^ 2 + σu ^ 2) = σv ^ 2 / 2 ∧
      σv ^ 2 / (4 * (σv / (2 * σu))) = σv * σu / 2 ∧
      σv / (2 * σu) * σu ^ 2 = σv * σu / 2 := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro w; field_simp
  · field_simp; ring
  · field_simp; ring
  · field_simp

/-- A book whose depth at distance `d` dollars from the price is `L d` shares per dollar
(`L > 0`): selling `Q ≥ 0` shares eats the book down to a fall `Δ ≥ 0` where the shares consumed,
`∫₀^Δ L d dd`, add up to `Q`. That happens exactly when `Δ = √(2 Q / L)`: square-root impact. -/
theorem square_root_impact_of_linear_depth (L Q Δ : ℝ) (hL : 0 < L) (hQ : 0 ≤ Q) (hΔ : 0 ≤ Δ) :
    (∫ d in (0 : ℝ)..Δ, L * d) = Q ↔ Δ = Real.sqrt (2 * Q / L) := by
  rw [intervalIntegral.integral_const_mul, integral_id]
  constructor
  · intro h
    rw [eq_comm, Real.sqrt_eq_iff_mul_self_eq (by positivity) hΔ]
    rw [← h]; field_simp; ring
  · intro h
    have h2 : Δ ^ 2 = 2 * Q / L := by rw [h]; exact Real.sq_sqrt (by positivity)
    field_simp at h2 ⊢
    nlinarith [h2]

-- The card's worked numbers: σv = 6/5 dollars, σu = 200,000 shares, p₀ = 100, a sale of 100,000.
-- lambda = 3 dollars per million shares
example : (6 / 5 : ℚ) / (2 * 200000) = 3 / 1000000 := by norm_num
-- depth 1 / lambda = 333,333 1/3 shares per dollar
example : 1 / ((6 / 5 : ℚ) / (2 * 200000)) = 1000000 / 3 := by norm_num
-- beta = 166,666 2/3 shares per dollar of mispricing
example : (200000 : ℚ) / (6 / 5) = 500000 / 3 := by norm_num
-- the value that makes the insider sell 100,000 shares: $99.40
example : 100 - 100000 / ((200000 : ℚ) / (6 / 5)) = 497 / 5 := by norm_num
-- the price after the sale with noise at zero: $99.70, a move of -0.30 percent
example : 100 + (6 / 5 : ℚ) / (2 * 200000) * (-100000) = 997 / 10 := by norm_num
example : ((997 / 10 : ℚ) - 100) / 100 * 100 = -3 / 10 := by norm_num
-- the insider's average profit per auction: $120,000
example : (6 / 5 : ℚ) * 200000 / 2 = 120000 := by norm_num
-- the insider's average profit on this sale, x (w - λ x) with x = -100,000, w = -3/5: $30,000
example : (-100000 : ℚ) * (-3 / 5 - 3 / 1000000 * (-100000)) = 30000 := by norm_num
-- dropping the 2 doubles the move to -0.60 percent
example : -100 * ((6 / 5 : ℚ) / 200000) * 100000 / 100 = -3 / 5 := by norm_num
-- doubling the unrelated flow halves the move to -0.15 percent
example : -100 * ((6 / 5 : ℚ) / (4 * 200000)) * 100000 / 100 = -3 / 20 := by norm_num
-- the book slope that makes the walk agree with the square-root law at 10 percent: 2,000,000
example : (2 : ℚ) * 100000 / (1 / 10) = 2000000 := by norm_num
-- 40 percent of volume moves the price twice as far as 10 percent, not four times
example : Real.sqrt (4 / 10) = 2 * Real.sqrt (1 / 10) := by
  rw [show (4 / 10 : ℝ) = 2 ^ 2 * (1 / 10) by norm_num, Real.sqrt_mul' _ (by norm_num),
    Real.sqrt_sq (by norm_num)]

#print axioms kyle_lambda_unique_linear_equilibrium
#print axioms kyle_equilibrium_half_revealed_and_crowd_pays
#print axioms square_root_impact_of_linear_depth
