-- Smile-adjusted delta: the hedge ratio is the Black-Scholes delta plus vega times the option's volatility slope, the three smile rules give that slope as 0, +β and -β, and the minimum-variance hedge is Cov/Var.
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Probability.Moments.Variance

open ProbabilityTheory MeasureTheory

/-- Variance of `X - c Y` expanded in `c`. -/
lemma variance_sub_const_mul_expand {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ) (c : ℝ) :
    Var[fun ω => X ω - c * Y ω; μ] =
      Var[X; μ] - 2 * c * cov[X, Y; μ] + c ^ 2 * Var[Y; μ] := by
  rw [variance_fun_sub hX (hY.const_mul c), covariance_const_mul_right]
  rw [show (fun ω => c * Y ω) = c • Y from rfl, variance_smul]
  ring

#print axioms variance_sub_const_mul_expand

/-- The smile-adjusted delta. The call is marked at `V (S, σ S)`: the share price enters once
directly and once through the volatility the smile assigns. If `V` is differentiable at
`(S, σ S)` with derivative `L` (so the Black-Scholes delta is `L (1, 0) = ∂V/∂S` and vega is
`L (0, 1) = ∂V/∂σ`) and the option's own volatility has slope `σ'` in the share price, then the
hedge ratio `dV/dS` is the Black-Scholes delta plus vega times `σ'`. -/
theorem smile_adjusted_delta_eq_bs_delta_add_vega_mul_vol_slope
    (V : ℝ × ℝ → ℝ) (L : ℝ × ℝ →L[ℝ] ℝ) (σ : ℝ → ℝ) (S σ' : ℝ)
    (hV : HasFDerivAt V L (S, σ S)) (hσ : HasDerivAt σ σ' S) :
    HasDerivAt (fun s => V (s, σ s)) (L (1, 0) + L (0, 1) * σ') S := by
  have h := hV.comp_hasDerivAt (f := fun s => (s, σ s)) S ((hasDerivAt_id S).prodMk hσ)
  have hL : L (1, σ') = L (1, 0) + L (0, 1) * σ' := by
    have : ((1 : ℝ), σ') = (1, 0) + σ' • ((0 : ℝ), (1 : ℝ)) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul, mul_comm]
  rw [← hL]
  exact h

/-- Today's skew gives the size, the rule gives the sign. Today the share sits at `S₀ ≠ 0`,
the at-the-money volatility is `σ₀`, and the skew falls `β` per dollar of strike. For the
at-the-money strike `K = S₀`, the option's volatility as a function of the share price `S` is
`σ₀ - β (K - S₀)` under sticky strike, `σ₀ - β S₀ (K / S - 1)` under sticky moneyness, and
`σ₀ - β (K + S - 2 S₀)` under the local-volatility rule. Their slopes at `S₀` are `0`, `+β`
and `-β`. -/
theorem smile_rule_vol_slopes (σ₀ β S₀ : ℝ) (hS₀ : S₀ ≠ 0) :
    HasDerivAt (fun _ : ℝ => σ₀ - β * (S₀ - S₀)) 0 S₀ ∧
    HasDerivAt (fun S : ℝ => σ₀ - β * S₀ * (S₀ / S - 1)) β S₀ ∧
    HasDerivAt (fun S : ℝ => σ₀ - β * (S₀ + S - 2 * S₀)) (-β) S₀ := by
  refine ⟨hasDerivAt_const _ _, ?_, ?_⟩
  · have h1 : HasDerivAt (fun S : ℝ => S₀ * S⁻¹ - 1) (S₀ * -(S₀ ^ 2)⁻¹) S₀ :=
      ((hasDerivAt_inv hS₀).const_mul S₀).sub_const 1
    have h2 := (h1.const_mul (β * S₀)).const_sub σ₀
    have hf : (fun S : ℝ => σ₀ - β * S₀ * (S₀ / S - 1)) =
        (fun S : ℝ => σ₀ - β * S₀ * (S₀ * S⁻¹ - 1)) := by
      funext S; rw [div_eq_mul_inv]
    rw [hf]
    refine h2.congr_deriv ?_
    field_simp
  · have h1 : HasDerivAt (fun S : ℝ => S₀ + S - 2 * S₀) 1 S₀ :=
      ((hasDerivAt_id S₀).const_add S₀).sub_const _
    exact ((h1.const_mul β).const_sub σ₀).congr_deriv (by ring)

/-- The minimum-variance delta. A day's option move `δV` and share move `δS` are random
variables with finite variance, and `Var(δS) > 0`. Write `h* = Cov(δV, δS) / Var(δS)`.
For every hedge ratio `h`, the variance of `δV - h δS` equals the variance at `h*` plus
`Var(δS) (h - h*)²`; so `h*` gives the least variance, and it is the only hedge that does. -/
theorem min_variance_delta_eq_cov_div_var {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (δV δS : Ω → ℝ) (hV : MemLp δV 2 μ) (hS : MemLp δS 2 μ)
    (hv : 0 < Var[δS; μ]) (h : ℝ) :
    Var[fun ω => δV ω - h * δS ω; μ] =
        Var[fun ω => δV ω - (cov[δV, δS; μ] / Var[δS; μ]) * δS ω; μ]
          + Var[δS; μ] * (h - cov[δV, δS; μ] / Var[δS; μ]) ^ 2 ∧
      (Var[fun ω => δV ω - h * δS ω; μ] =
          Var[fun ω => δV ω - (cov[δV, δS; μ] / Var[δS; μ]) * δS ω; μ] ↔
        h = cov[δV, δS; μ] / Var[δS; μ]) := by
  set v := Var[δS; μ]
  set c := cov[δV, δS; μ]
  have hv0 : v ≠ 0 := hv.ne'
  rw [variance_sub_const_mul_expand δV δS hV hS h,
    variance_sub_const_mul_expand δV δS hV hS (c / v)]
  have key : Var[δV; μ] - 2 * h * c + h ^ 2 * v =
      Var[δV; μ] - 2 * (c / v) * c + (c / v) ^ 2 * v + v * (h - c / v) ^ 2 := by
    field_simp
    ring
  refine ⟨key, ?_⟩
  rw [key]
  constructor
  · intro heq
    have h0 : v * (h - c / v) ^ 2 = 0 := by linarith
    rcases mul_eq_zero.mp h0 with h0 | h0
    · exact absurd h0 hv0
    · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h0
      linarith
  · intro heq
    rw [heq]
    ring

#print axioms smile_adjusted_delta_eq_bs_delta_add_vega_mul_vol_slope
#print axioms smile_rule_vol_slopes
#print axioms min_variance_delta_eq_cov_div_var
