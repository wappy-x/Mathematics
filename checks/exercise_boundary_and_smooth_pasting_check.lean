-- The exercise boundary and smooth pasting: an American put's value meets its payoff on the exercise line with slope exactly -1, which forces half sigma squared B squared times gamma to equal rK - qB there, and the pricing operator applied to the payoff is the positive carry rK - qS.
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Order.Filter.Basic
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Topology.Order.LeftRight

open Filter Topology Set

/-- Smooth pasting, the squeeze at the heart of the card's detailed proof.
Fix the years left and let `V x` be the put's value at share price `x`, with strike `K`
and exercise boundary `B`.
* The holder may exercise at every instant, so the value is never below the payoff:
  `K - x ≤ V x` for every `x`.
* On and below the line the holder exercises: `V x = K - x` for `x ≤ B`.
* Copying, from `B`, the best rule for a start at `B + h` gives
  `V (B + h) - V B ≤ -h * m h`, where `m h` is the discounted average growth of the share
  until exercise; because the share moves without jumps the path hits the line almost at once,
  so `m h → 1` as `h → 0` from above.
Then the value has slope exactly `-1` on the line: it meets the payoff at the same height and
the same slope, with no corner. -/
theorem smooth_pasting {V m : ℝ → ℝ} {K B : ℝ}
    (hfloor : ∀ x, K - x ≤ V x)
    (hexercise : ∀ x ≤ B, V x = K - x)
    (hcopy : ∀ h > 0, V (B + h) - V B ≤ -h * m h)
    (hm : Tendsto m (𝓝[>] 0) (𝓝 1)) :
    HasDerivAt V (-1) B := by
  have hVB : V B = K - B := hexercise B le_rfl
  rw [hasDerivAt_iff_tendsto_slope, ← nhdsLT_sup_nhdsGT, tendsto_sup]
  constructor
  · apply tendsto_const_nhds.congr'
    filter_upwards [self_mem_nhdsWithin] with x hx
    have hx' : x - B ≠ 0 := sub_ne_zero.mpr (ne_of_lt (mem_Iio.mp hx))
    rw [slope_def_field, hexercise x (le_of_lt (mem_Iio.mp hx)), hVB]
    field_simp
    ring
  · have hm' : Tendsto (fun x => -m (x - B)) (𝓝[>] B) (𝓝 (-1)) := by
      have h1 : Tendsto (fun x => x - B) (𝓝[>] B) (𝓝[>] 0) := by
        apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
        · have : Tendsto (fun x => x - B) (𝓝 B) (𝓝 (B - B)) :=
            (continuous_id.sub continuous_const).tendsto B
          rw [sub_self] at this
          exact this.mono_left nhdsWithin_le_nhds
        · filter_upwards [self_mem_nhdsWithin] with x hx
          exact sub_pos.mpr (mem_Ioi.mp hx)
      exact (hm.comp h1).neg
    apply tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hm'
    · filter_upwards [self_mem_nhdsWithin] with x hx
      have hx' : 0 < x - B := sub_pos.mpr (mem_Ioi.mp hx)
      rw [slope_def_field, hVB, le_div_iff₀ hx']
      linarith [hfloor x]
    · filter_upwards [self_mem_nhdsWithin] with x hx
      have hx' : 0 < x - B := sub_pos.mpr (mem_Ioi.mp hx)
      have := hcopy (x - B) hx'
      rw [add_sub_cancel] at this
      rw [slope_def_field, div_le_iff₀ hx']
      linarith

/-- The balance on the line (Step 5). Let `V S τ` be the put's value at share price `S` with
`τ` years left, and `B τ` the exercise boundary. Suppose the value is differentiable at the
point on the line, the line moves differentiably, the value matches the payoff along the line
(`V (B t) t = K - B t` for times near `τ`), smooth pasting holds (`∂V/∂S = -1` on the line),
and the Black–Scholes equation holds on the line with `Γ` the gamma just above it.
Then `∂V/∂τ = 0` on the line, and everything cancels except
`½ σ² B² Γ = r K - q B`: the value of the wobble exactly pays the carry of exercising. -/
theorem gamma_balance_on_boundary {V : ℝ → ℝ → ℝ} {B : ℝ → ℝ} {σ r q K τ : ℝ}
    (hV : DifferentiableAt ℝ (Function.uncurry V) (B τ, τ))
    (hB : DifferentiableAt ℝ B τ)
    (hvalue : ∀ᶠ t in 𝓝 τ, V (B t) t = K - B t)
    (hslope : deriv (fun x => V x τ) (B τ) = -1)
    (hpde : deriv (fun t => V (B τ) t) τ =
      1 / 2 * σ ^ 2 * B τ ^ 2 *
          derivWithin (fun x => deriv (fun y => V y τ) x) (Ici (B τ)) (B τ) +
        (r - q) * B τ * deriv (fun x => V x τ) (B τ) - r * V (B τ) τ) :
    deriv (fun t => V (B τ) t) τ = 0 ∧
      1 / 2 * σ ^ 2 * B τ ^ 2 *
          derivWithin (fun x => deriv (fun y => V y τ) x) (Ici (B τ)) (B τ) =
        r * K - q * B τ := by
  set L := fderiv ℝ (Function.uncurry V) (B τ, τ) with hL
  have hVd : HasFDerivAt (Function.uncurry V) L (B τ, τ) := hV.hasFDerivAt
  -- partial derivative in S
  have hS : HasDerivAt (fun x => V x τ) (L (1, 0)) (B τ) := by
    have hp : HasDerivAt (fun x : ℝ => (x, τ)) ((1 : ℝ), (0 : ℝ)) (B τ) :=
      (hasDerivAt_id _).prodMk (hasDerivAt_const _ _)
    exact hVd.comp_hasDerivAt (B τ) hp
  -- partial derivative in τ
  have hT : HasDerivAt (fun t => V (B τ) t) (L (0, 1)) τ := by
    have hp : HasDerivAt (fun t : ℝ => (B τ, t)) ((0 : ℝ), (1 : ℝ)) τ :=
      (hasDerivAt_const _ _).prodMk (hasDerivAt_id _)
    exact hVd.comp_hasDerivAt τ hp
  have hS1 : L (1, 0) = -1 := by rw [← hS.deriv]; exact hslope
  -- along the boundary
  have hC : HasDerivAt (fun t => V (B t) t) (L (deriv B τ, 1)) τ := by
    have hp : HasDerivAt (fun t : ℝ => (B t, t)) (deriv B τ, (1 : ℝ)) τ :=
      hB.hasDerivAt.prodMk (hasDerivAt_id _)
    exact HasFDerivAt.comp_hasDerivAt (f := fun t : ℝ => (B t, t)) τ hVd hp
  have hC' : HasDerivAt (fun t => V (B t) t) (-deriv B τ) τ := by
    have hK : HasDerivAt (fun t => K - B t) (-deriv B τ) τ := by
      exact hB.hasDerivAt.const_sub K
    exact hK.congr_of_eventuallyEq hvalue
  have hEq : L (deriv B τ, 1) = -deriv B τ := hC.unique hC'
  have hsplit : L (deriv B τ, 1) = deriv B τ * L (1, 0) + L (0, 1) := by
    have : ((deriv B τ, (1 : ℝ)) : ℝ × ℝ) = deriv B τ • ((1 : ℝ), (0 : ℝ)) + ((0 : ℝ), (1 : ℝ)) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul]
  have hT0 : deriv (fun t => V (B τ) t) τ = 0 := by
    rw [hT.deriv]
    rw [hsplit, hS1] at hEq
    linarith
  refine ⟨hT0, ?_⟩
  have hVB : V (B τ) τ = K - B τ := hvalue.self_of_nhds
  rw [hT0, hslope, hVB] at hpde
  linarith

/-- The complementarity form (Step 6). Apply the pricing operator
`L V = ∂V/∂τ - (½ σ² S² ∂²V/∂S² + (r - q) S ∂V/∂S - r V)` to the payoff `K - S`:
the result is the net carry of exercising, `r K - q S`. Below the strike, with the rate above
the (nonnegative) dividend yield and a positive share price, this carry is positive, so on the
exercise region `L V ≥ 0` holds strictly. -/
theorem pricing_operator_on_payoff {σ r q K S τ : ℝ}
    (hS : 0 < S) (hSK : S < K) (hrq : q < r) (hq : 0 ≤ q) :
    (deriv (fun _t : ℝ => K - S) τ -
        (1 / 2 * σ ^ 2 * S ^ 2 * deriv (deriv (fun x : ℝ => K - x)) S +
          (r - q) * S * deriv (fun x : ℝ => K - x) S - r * (K - S)) = r * K - q * S) ∧
      0 < r * K - q * S := by
  have h1 : deriv (fun x : ℝ => K - x) = fun _ => -1 := by
    funext x
    simp
  refine ⟨?_, ?_⟩
  · rw [h1]
    simp only [deriv_const]
    ring
  · have hr : 0 < r := lt_of_le_of_lt hq hrq
    nlinarith

#print axioms smooth_pasting
#print axioms gamma_balance_on_boundary
#print axioms pricing_operator_on_payoff
