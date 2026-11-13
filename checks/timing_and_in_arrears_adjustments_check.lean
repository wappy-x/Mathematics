-- Timing adjustments: a rate paid on its fixing date has fair rate F + δ Var(L) / (1 + δ F), any payment date gives F + Cov(L, W) / E[W], and late payment lowers the fair rate.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance

open MeasureTheory ProbabilityTheory

/-- In-arrears formula. Under the U-forward odds `μ`, let the fixing `L` have finite variance
and average `F = μ[L]`. Let `P0U > 0` be today's price of \$1 at the period's end `U`, and
`P0T = P0U * (1 + δ F)` today's price of \$1 at the fixing date `T` (the forward rate's
definition, Step 1), with `P0T > 0`. The coupon `δ L` paid at `T` and deposited at `L` until `U`
is worth `P0U * μ[δ L (1 + δ L)]`; the fixed coupon `δ K` paid at `T` is worth `P0T * δ * K`.
The two are equal exactly when `K = F + δ Var(L) / (1 + δ F)`. -/
theorem in_arrears_fair_rate {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (L : Ω → ℝ) (hL : MemLp L 2 μ)
    (δ P0T P0U K : ℝ) (hδ : 0 < δ) (hP0U : 0 < P0U) (hP0T : 0 < P0T)
    (hfwd : P0T = P0U * (1 + δ * μ[L])) :
    P0U * μ[fun ω => δ * L ω * (1 + δ * L ω)] = P0T * δ * K ↔
      K = μ[L] + δ * Var[L; μ] / (1 + δ * μ[L]) := by
  have hLi : Integrable L μ := hL.integrable one_le_two
  have hL2 : Integrable (fun ω => L ω ^ 2) μ := hL.integrable_sq
  have hvar : Var[L; μ] = μ[fun ω => L ω ^ 2] - μ[L] ^ 2 := by
    rw [variance_eq_sub hL]; rfl
  have hint : μ[fun ω => δ * L ω * (1 + δ * L ω)] = δ * μ[L] + δ ^ 2 * μ[fun ω => L ω ^ 2] := by
    have : (fun ω => δ * L ω * (1 + δ * L ω)) = fun ω => δ * L ω + δ ^ 2 * L ω ^ 2 := by
      ext ω; ring
    rw [this, integral_add (hLi.const_mul δ) (hL2.const_mul _), integral_const_mul,
      integral_const_mul]
  have h1 : 0 < 1 + δ * μ[L] := by
    by_contra h
    have h' : 1 + δ * μ[L] ≤ 0 := not_lt.mp h
    have : P0U * (1 + δ * μ[L]) ≤ 0 := mul_nonpos_of_nonneg_of_nonpos hP0U.le h'
    linarith
  have hne1 : 1 + δ * μ[L] ≠ 0 := h1.ne'
  have hq : δ * (μ[fun ω => L ω ^ 2] - μ[L] ^ 2) / (1 + δ * μ[L]) * (1 + δ * μ[L])
      = δ * (μ[fun ω => L ω ^ 2] - μ[L] ^ 2) := div_mul_cancel₀ _ hne1
  have hne : P0U * δ ≠ 0 := by positivity
  rw [hint, hfwd, hvar]
  constructor
  · intro h
    have h2 : (1 + δ * μ[L]) * K = (1 + δ * μ[L]) *
        (μ[L] + δ * (μ[fun ω => L ω ^ 2] - μ[L] ^ 2) / (1 + δ * μ[L])) := by
      apply mul_left_cancel₀ hne
      linear_combination (-1 : ℝ) * h + (-P0U * δ) * hq
    exact mul_left_cancel₀ hne1 h2
  · intro h
    rw [h]
    linear_combination (-P0U * δ) * hq

/-- Any payment date. Let the payment's weight `W` (cash on the payment date counted in cash
on `U`) and the fixing `L` have finite variance under the U-forward odds, with `μ[W] ≠ 0`.
The swaplet paying `(L - K)` weighted by `W` is worth zero exactly when
`K = F + Cov(L, W) / E[W]`. -/
theorem fair_rate_any_payment_date {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (L W : Ω → ℝ) (hL : MemLp L 2 μ) (hW : MemLp W 2 μ)
    (hW0 : μ[W] ≠ 0) (K : ℝ) :
    μ[fun ω => (L ω - K) * W ω] = 0 ↔ K = μ[L] + cov[L, W; μ] / μ[W] := by
  have hLi : Integrable L μ := hL.integrable one_le_two
  have hWi : Integrable W μ := hW.integrable one_le_two
  have hLW : Integrable (L * W) μ := hL.integrable_mul hW
  have hcov := covariance_eq_sub hL hW
  have hint : μ[fun ω => (L ω - K) * W ω] = μ[L * W] - K * μ[W] := by
    have : (fun ω => (L ω - K) * W ω) = fun ω => (L * W) ω - K * W ω := by
      ext ω; simp only [Pi.mul_apply]; ring
    rw [this, integral_sub hLW (hWi.const_mul K), integral_const_mul]
  rw [hint, hcov]
  constructor
  · intro h
    field_simp
    linarith
  · intro h
    rw [h]
    field_simp
    ring

/-- Late payment gives a negative adjustment. Pay `y > 0` years after `U`: the weight is
`W = 1 / (1 + y L)`, the discount from the payment date back to `U` at the fixing, with
positive bond prices (`1 + y L > 0`). If the fixing has finite, nonzero variance and `W` has a
finite average, the fair rate `K` (the one making the swaplet worth zero) is below the
forward `F = μ[L]`. -/
theorem late_payment_fair_rate_lt_forward {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (L : Ω → ℝ) (hL : MemLp L 2 μ) (hVar : 0 < Var[L; μ])
    (y K : ℝ) (hy : 0 < y) (hpos : ∀ ω, 0 < 1 + y * L ω)
    (hW : Integrable (fun ω => 1 / (1 + y * L ω)) μ)
    (hK : μ[fun ω => (L ω - K) * (1 / (1 + y * L ω))] = 0) :
    K < μ[L] := by
  set F := μ[L] with hF
  set W : Ω → ℝ := fun ω => 1 / (1 + y * L ω) with hWdef
  have hLi : Integrable L μ := hL.integrable one_le_two
  have hWpos : ∀ ω, 0 < W ω := fun ω => by simp only [hWdef]; exact one_div_pos.mpr (hpos ω)
  have hWmul : ∀ ω, W ω * (1 + y * L ω) = 1 := fun ω => by
    simp only [hWdef]; exact one_div_mul_cancel (hpos ω).ne'
  have hLW : ∀ ω, L ω * W ω = (1 - W ω) / y := by
    intro ω
    rw [eq_div_iff hy.ne']
    linear_combination hWmul ω
  -- positivity of E[W] and of 1 + y F
  have hEW : 0 < μ[W] := by
    rw [integral_pos_iff_support_of_nonneg (fun ω => (hWpos ω).le) hW]
    have : Function.support W = Set.univ := by
      ext ω; simp [(hWpos ω).ne']
    rw [this]; simp
  have h1F : 0 < 1 + y * F := by
    have hi : Integrable (fun ω => 1 + y * L ω) μ := (integrable_const 1).add (hLi.const_mul y)
    have hpos' : 0 < μ[fun ω => 1 + y * L ω] := by
      rw [integral_pos_iff_support_of_nonneg (fun ω => (hpos ω).le) hi]
      have : Function.support (fun ω => 1 + y * L ω) = Set.univ := by
        ext ω; simp [(hpos ω).ne']
      rw [this]; simp
    rw [integral_add (integrable_const 1) (hLi.const_mul y), integral_const_mul] at hpos'
    simpa using hpos'
  set c := 1 / (1 + y * F) with hc
  have hc1 : c * (1 + y * F) = 1 := one_div_mul_cancel h1F.ne'
  -- the key function f = (L - F)(W - c) ≤ 0
  set f : Ω → ℝ := fun ω => (L ω - F) * (W ω - c) with hfdef
  have hf_eq : ∀ ω, f ω = (1 - W ω) / y - F * W ω - c * L ω + c * F := by
    intro ω
    simp only [hfdef]
    have := hLW ω
    linear_combination this
  have hf_mul : ∀ ω, f ω * ((1 + y * L ω) * (1 + y * F)) = -(y * (L ω - F) ^ 2) := by
    intro ω
    simp only [hfdef]
    linear_combination ((L ω - F) * (1 + y * F)) * hWmul ω - ((L ω - F) * (1 + y * L ω)) * hc1
  have hf_nonpos : ∀ ω, f ω ≤ 0 := by
    intro ω
    have hp : 0 < (1 + y * L ω) * (1 + y * F) := mul_pos (hpos ω) h1F
    have hm := hf_mul ω
    by_contra hcon
    have hfpos : 0 < f ω := lt_of_not_ge hcon
    have : 0 < f ω * ((1 + y * L ω) * (1 + y * F)) := mul_pos hfpos hp
    have : 0 ≤ y * (L ω - F) ^ 2 := by positivity
    linarith
  have hfi : Integrable f μ := by
    have : f = fun ω => (1 - W ω) / y - F * W ω - c * L ω + c * F := funext hf_eq
    rw [this]
    exact ((((integrable_const 1).sub hW).div_const y).sub (hW.const_mul F)).sub
      (hLi.const_mul c) |>.add (integrable_const _)
  have hfint : μ[f] = (1 - μ[W]) / y - F * μ[W] := by
    have : f = fun ω => (1 - W ω) / y - F * W ω - c * L ω + c * F := funext hf_eq
    rw [this, integral_add, integral_sub, integral_sub, integral_div, integral_sub,
      integral_const_mul, integral_const_mul, integral_const, integral_const]
    · simp only [probReal_univ, smul_eq_mul, one_mul]
      rw [← hF]
      ring
    · exact integrable_const 1
    · exact hW
    · exact ((integrable_const 1).sub hW).div_const y
    · exact hW.const_mul F
    · exact (((integrable_const 1).sub hW).div_const y).sub (hW.const_mul F)
    · exact hLi.const_mul c
    · exact ((((integrable_const 1).sub hW).div_const y).sub (hW.const_mul F)).sub
        (hLi.const_mul c)
    · exact integrable_const _
  -- strictness: ∫ f < 0
  have hflt : μ[f] < 0 := by
    have hle : μ[f] ≤ 0 := integral_nonpos hf_nonpos
    rcases hle.lt_or_eq with h | h
    · exact h
    exfalso
    have hnf : ∫ ω, -f ω ∂μ = 0 := by rw [integral_neg, h, neg_zero]
    have hae0 := (integral_eq_zero_iff_of_nonneg (f := fun ω => -f ω)
      (fun ω => by simp [hf_nonpos ω]) hfi.neg).mp hnf
    have hae : ∀ᵐ ω ∂μ, L ω = F := by
      filter_upwards [hae0] with ω hω
      have h0 : f ω = 0 := by simpa using hω
      have hm := hf_mul ω
      rw [h0, zero_mul] at hm
      have h2 : y * (L ω - F) ^ 2 = 0 := by linarith
      have h3 : (L ω - F) ^ 2 = 0 := by
        rcases mul_eq_zero.mp h2 with h | h
        · exact absurd h hy.ne'
        · exact h
      have h4 : L ω - F = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h3
      linarith
    have : Var[L; μ] = 0 := by
      rw [variance_eq_integral hL.aemeasurable]
      apply integral_eq_zero_of_ae
      filter_upwards [hae] with ω hω
      simp [hω, hF]
    linarith
  -- from the fair-rate condition
  have hKint : μ[fun ω => (L ω - K) * (1 / (1 + y * L ω))] = (1 - μ[W]) / y - K * μ[W] := by
    have : (fun ω => (L ω - K) * (1 / (1 + y * L ω))) = fun ω => (1 - W ω) / y - K * W ω := by
      ext ω
      have := hLW ω
      simp only [hWdef] at this ⊢
      linear_combination this
    rw [this, integral_sub, integral_div, integral_sub, integral_const, integral_const_mul]
    · simp
    · exact integrable_const 1
    · exact hW
    · exact ((integrable_const 1).sub hW).div_const y
    · exact hW.const_mul K
  rw [hKint] at hK
  rw [hfint] at hflt
  have : K * μ[W] < F * μ[W] := by linarith
  exact lt_of_mul_lt_mul_right this hEW.le

-- Three-state example: fixing 2%, 6%, 10% with U-odds 1/4, 1/2, 1/4, accrual 1/4.
-- Mean 6%.
example : (1/4 : ℚ) * (2/100) + (1/2) * (6/100) + (1/4) * (10/100) = 6/100 := by norm_num
-- Variance 0.0008.
example : (1/4 : ℚ) * (2/100 - 6/100)^2 + (1/2) * (6/100 - 6/100)^2
    + (1/4) * (10/100 - 6/100)^2 = 8/10000 := by norm_num
-- Adjustment 0.25 × 0.0008 / 1.015 = 1/5075, about 1.97 basis points.
example : (1/4 : ℚ) * (8/10000) / (1 + (1/4) * (6/100)) = 1/5075 := by norm_num
-- Re-weighted (T-forward) odds 201/812, 1/2, 205/812, about 0.2475, 0.5, 0.2525.
example : (1/4 : ℚ) * (1 + (1/4) * (2/100)) / (1 + (1/4) * (6/100)) = 201/812 := by norm_num
example : (1/4 : ℚ) * (1 + (1/4) * (10/100)) / (1 + (1/4) * (6/100)) = 205/812 := by norm_num
-- The re-weighted average is 6% plus the same 1/5075.
example : (201/812 : ℚ) * (2/100) + (1/2) * (6/100) + (205/812) * (10/100)
    = 6/100 + 1/5075 := by norm_num
-- Payoff chart: extra dollars at U, $10m × (1/4)² × fixing², for fixings 2, 4, 6, 8, 10%.
example : (10000000 : ℚ) * (1/4)^2 * (2/100)^2 = 250 := by norm_num
example : (10000000 : ℚ) * (1/4)^2 * (4/100)^2 = 1000 := by norm_num
example : (10000000 : ℚ) * (1/4)^2 * (6/100)^2 = 2250 := by norm_num
example : (10000000 : ℚ) * (1/4)^2 * (8/100)^2 = 4000 := by norm_num
example : (10000000 : ℚ) * (1/4)^2 * (10/100)^2 = 6250 := by norm_num

#print axioms in_arrears_fair_rate
#print axioms fair_rate_any_payment_date
#print axioms late_payment_fair_rate_lt_forward
