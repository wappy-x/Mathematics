-- Hedging with the smile: when the smile's volatility depends on strike and spot only through strike over spot (sticky delta), a fixed strike's vol moves with spot at minus strike over spot times the smile's slope in strike, so the hedge is the Black-Scholes delta plus vega times that slope.
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Mul

/-- Helper: the slope identity, proved here so the first theorem can use it. -/
theorem vol_slope_in_spot_aux
    (σ : ℝ → ℝ → ℝ) (g : ℝ → ℝ) (K S σK : ℝ)
    (hS : 0 < S)
    (hsticky : ∀ k s : ℝ, 0 < s → σ k s = g (k / s))
    (hσK : HasDerivAt (fun k => σ k S) σK K) :
    HasDerivAt (fun s => σ K s) (-(K / S) * σK) S := by
  have hg : ∀ x, g x = σ (S * x) S := by
    intro x
    rw [hsticky _ _ hS, mul_div_cancel_left₀ _ hS.ne']
  have hgfun : g = fun x => σ (S * x) S := funext hg
  have hσK' : HasDerivAt (fun k => σ k S) σK (S * (K / S)) := by
    rwa [mul_div_cancel₀ _ hS.ne']
  have hgd : HasDerivAt g (σK * S) (K / S) := by
    rw [hgfun]
    have hm : HasDerivAt (fun x : ℝ => S * x) S (K / S) := by
      simpa using (hasDerivAt_id (K / S)).const_mul S
    exact hσK'.comp (K / S) hm
  have hinv : HasDerivAt (fun s : ℝ => K * s⁻¹) (K * (-(S ^ 2)⁻¹)) S :=
    (hasDerivAt_inv hS.ne').const_mul K
  have hcomp : HasDerivAt (fun s : ℝ => g (K * s⁻¹)) ((σK * S) * (K * (-(S ^ 2)⁻¹))) S := by
    have hgd' : HasDerivAt g (σK * S) (K * S⁻¹) := by rwa [← div_eq_mul_inv]
    exact hgd'.comp S hinv
  have heq : (σK * S) * (K * (-(S ^ 2)⁻¹)) = -(K / S) * σK := by
    field_simp
  rw [heq] at hcomp
  apply hcomp.congr_of_eventuallyEq
  filter_upwards [lt_mem_nhds hS] with s hs
  rw [hsticky _ _ hs, div_eq_mul_inv]

#print axioms vol_slope_in_spot_aux

/-- The sticky-delta hedge (the formula, Steps 0 and 2). Write `σ K S` for the smile's volatility
at strike `K` when spot is `S > 0`. Under sticky delta the smile rides with spot: there is one
function `g` with `σ K S = g (K / S)` for every strike and every positive spot. The option is
marked at `V (S, σ K S)`. If `V` is differentiable at `(S, σ K S)` with derivative `L` (so the
Black-Scholes delta is `L (1, 0) = ∂V/∂S` and vega is `L (0, 1) = ∂V/∂σ`) and today's smile has
slope `σK = ∂σ/∂K` in strike at `K`, then the hedge `dV/dS` is the Black-Scholes delta plus vega
times `-(K / S) * σK`. -/
theorem sticky_delta_hedge_eq_bs_delta_add_vega_mul_strike_slope
    (V : ℝ × ℝ → ℝ) (L : ℝ × ℝ →L[ℝ] ℝ) (σ : ℝ → ℝ → ℝ) (g : ℝ → ℝ) (K S σK : ℝ)
    (hS : 0 < S)
    (hsticky : ∀ k s : ℝ, 0 < s → σ k s = g (k / s))
    (hV : HasFDerivAt V L (S, σ K S))
    (hσK : HasDerivAt (fun k => σ k S) σK K) :
    HasDerivAt (fun s => V (s, σ K s)) (L (1, 0) + L (0, 1) * (-(K / S) * σK)) S := by
  have h2 := vol_slope_in_spot_aux σ g K S σK hS hsticky hσK
  have hp : HasDerivAt (fun s => (s, σ K s)) ((1 : ℝ), -(K / S) * σK) S :=
    (hasDerivAt_id S).prodMk h2
  have hc := hV.comp_hasDerivAt (x := S) (f := fun s => (s, σ K s)) hp
  have hL : L ((1 : ℝ), -(K / S) * σK) = L (1, 0) + L (0, 1) * (-(K / S) * σK) := by
    have : ((1 : ℝ), -(K / S) * σK) = ((1 : ℝ), (0 : ℝ)) + (-(K / S) * σK) • ((0 : ℝ), (1 : ℝ)) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul, mul_comm]
  rw [← hL]
  exact hc

/-- The slope identity (Step 2). If the smile's volatility depends only on strike over spot,
`σ K S = g (K / S)` for every strike and every positive spot, and today's smile (spot `S > 0`)
has slope `σK` in strike at `K`, then the vol at the fixed strike `K` changes with spot at
`-(K / S) * σK`: the smile's slope in strike, turned round and scaled by strike over spot. -/
theorem sticky_delta_vol_slope_in_spot
    (σ : ℝ → ℝ → ℝ) (g : ℝ → ℝ) (K S σK : ℝ)
    (hS : 0 < S)
    (hsticky : ∀ k s : ℝ, 0 < s → σ k s = g (k / s))
    (hσK : HasDerivAt (fun k => σ k S) σK K) :
    HasDerivAt (fun s => σ K s) (-(K / S) * σK) S := by
  exact vol_slope_in_spot_aux σ g K S σK hS hsticky hσK

/-- The smile depends only on strike over spot (detailed proof of Step 2). If scaling spot and
strike by the same positive factor never changes the smile's volatility,
`σ (λ K) (λ S) = σ K S` for every `λ > 0`, every strike and every positive spot, then there is
one function `g` with `σ K S = g (K / S)` for every strike and every positive spot. -/
theorem smile_depends_only_on_strike_over_spot
    (σ : ℝ → ℝ → ℝ)
    (hscale : ∀ l K S : ℝ, 0 < l → 0 < S → σ (l * K) (l * S) = σ K S) :
    ∃ g : ℝ → ℝ, ∀ K S : ℝ, 0 < S → σ K S = g (K / S) := by
  refine ⟨fun x => σ x 1, fun K S hS => ?_⟩
  have h := hscale S⁻¹ K S (inv_pos.mpr hS) hS
  rw [inv_mul_cancel₀ hS.ne', inv_mul_eq_div] at h
  exact h.symm

-- The pillar vols in basis points: ATM 1000, risk reversal -100, butterfly +25.
-- Put pillar = ATM + BF - RR/2 = 1075 (10.75%); call pillar = ATM + BF + RR/2 = 975 (9.75%).
example : (1000 : ℤ) + 25 - (-100) / 2 = 1075 := by norm_num
example : (1000 : ℤ) + 25 + (-100) / 2 = 975 := by norm_num
-- Hedges in millionths of notional: call 250000 + 1910 = 251910, put -250000 + 43731 = -206269,
-- and the risk-reversal book's extra delta 43731 - 1910 = 41821.
example : (250000 : ℤ) + 1910 = 251910 := by norm_num
example : (-250000 : ℤ) + 43731 = -206269 := by norm_num
example : (43731 : ℤ) - 1910 = 41821 := by norm_num

#print axioms sticky_delta_hedge_eq_bs_delta_add_vega_mul_strike_slope
#print axioms sticky_delta_vol_slope_in_spot
#print axioms smile_depends_only_on_strike_over_spot
