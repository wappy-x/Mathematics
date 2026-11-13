-- American Greeks and implied volatility: a price that rises strictly with volatility where the put is held has exactly one implied volatility for every quote in the range, delta is -1 and gamma 0 where the put equals its payoff, and the Black-Scholes equation forces gamma's limit at the boundary to 2(rK - qS*)/(sigma^2 S*^2).
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas

open Filter Topology Set

/-- Unique implied volatility (Steps 5 and 6). Let `P σ` be the American put's price at
volatility `σ > 0`, with share price `S` and strike `K`. Suppose the price is continuous in
volatility, tends to `P(0+) = p0` as volatility falls to zero and to the strike `K` as volatility
grows without limit, and rises strictly with volatility wherever the put is held (its price is
above the exercise value `K - S`). Then every quote `Q` with `max (K - S) p0 < Q < K` is
reproduced by exactly one volatility. -/
theorem american_put_implied_vol_exists_unique
    (P : ℝ → ℝ) (K S p0 : ℝ)
    (hcont : ContinuousOn P (Ioi 0))
    (hheld : ∀ σ₁ σ₂ : ℝ, 0 < σ₁ → σ₁ < σ₂ → K - S < P σ₁ → P σ₁ < P σ₂)
    (hlow : Tendsto P (𝓝[>] 0) (𝓝 p0))
    (hhigh : Tendsto P atTop (𝓝 K))
    (Q : ℝ) (hQlow : max (K - S) p0 < Q) (hQhigh : Q < K) :
    ∃! σ : ℝ, 0 < σ ∧ P σ = Q := by
  have hQp0 : p0 < Q := lt_of_le_of_lt (le_max_right _ _) hQlow
  have hQKS : K - S < Q := lt_of_le_of_lt (le_max_left _ _) hQlow
  have hexists : ∃ σ : ℝ, 0 < σ ∧ P σ = Q := by
    have h1 : ∀ᶠ σ in 𝓝[>] (0:ℝ), P σ < Q := hlow (Iio_mem_nhds hQp0)
    have h1' : ∀ᶠ σ in 𝓝[>] (0:ℝ), 0 < σ := self_mem_nhdsWithin
    obtain ⟨a, ha, ha0⟩ := (h1.and h1').exists
    have h2 : ∀ᶠ σ in atTop, Q < P σ := hhigh (Ioi_mem_nhds hQhigh)
    have h2' : ∀ᶠ σ in atTop, a < σ := eventually_gt_atTop a
    obtain ⟨b, hb, hab⟩ := (h2.and h2').exists
    have hc : ContinuousOn P (Icc a b) :=
      hcont.mono (fun x hx => lt_of_lt_of_le ha0 hx.1)
    obtain ⟨c, hcI, hcQ⟩ := intermediate_value_Icc hab.le hc ⟨ha.le, hb.le⟩
    exact ⟨c, lt_of_lt_of_le ha0 hcI.1, hcQ⟩
  obtain ⟨x, hx0, hxQ⟩ := hexists
  refine ⟨x, ⟨hx0, hxQ⟩, ?_⟩
  rintro y ⟨hy0, hyQ⟩
  by_contra hne
  rcases lt_or_gt_of_ne hne with h | h
  · have := hheld y x hy0 h (by rw [hyQ]; exact hQKS)
    rw [hxQ, hyQ] at this
    exact lt_irrefl _ this
  · have := hheld x y hx0 h (by rw [hxQ]; exact hQKS)
    rw [hxQ, hyQ] at this
    exact lt_irrefl _ this

/-- Delta -1 and gamma 0 in the exercise region (Step 3). If the put's price equals its payoff
`K - S` at every share price near `S`, then its delta at `S` is exactly -1 and its gamma
(second derivative in the share price) is exactly 0. -/
theorem american_put_delta_neg_one_in_exercise_region
    (P : ℝ → ℝ) (K S : ℝ)
    (hex : ∀ᶠ x in 𝓝 S, P x = K - x) :
    deriv P S = -1 ∧ iteratedDeriv 2 P S = 0 := by
  have hEq : P =ᶠ[𝓝 S] fun x => K - x := hex
  have hd : deriv P =ᶠ[𝓝 S] deriv (fun x : ℝ => K - x) := hEq.deriv
  have hd' : deriv P =ᶠ[𝓝 S] fun _ => (-1 : ℝ) := by
    refine hd.trans (Eventually.of_forall fun x => ?_)
    simp
  refine ⟨?_, ?_⟩
  · exact hd'.eq_of_nhds
  · rw [iteratedDeriv_succ, iteratedDeriv_one, hd'.deriv_eq]
    simp

/-- The gamma jump at the exercise boundary (Step 4). Just above the boundary `Sstar > 0` the
put is held, so its price, delta, theta and gamma satisfy the Black-Scholes equation
`Θ + (r - q) S Δ + (1/2) σ² S² Γ = r P`. If, as the share price falls to the boundary, the price
tends to `K - Sstar`, delta tends to -1 (smooth pasting) and theta tends to 0, and `σ ≠ 0`, then
gamma tends to `2 (r K - q Sstar) / (σ² Sstar²)`. -/
theorem american_put_gamma_jump_at_boundary
    (P Δ Θ Γ : ℝ → ℝ) (K r q σ Sstar : ℝ)
    (hσ : σ ≠ 0) (hS : 0 < Sstar)
    (hpde : ∀ S, Sstar < S →
      Θ S + (r - q) * S * Δ S + 1 / 2 * σ ^ 2 * S ^ 2 * Γ S = r * P S)
    (hP : Tendsto P (𝓝[>] Sstar) (𝓝 (K - Sstar)))
    (hΔ : Tendsto Δ (𝓝[>] Sstar) (𝓝 (-1)))
    (hΘ : Tendsto Θ (𝓝[>] Sstar) (𝓝 0)) :
    Tendsto Γ (𝓝[>] Sstar) (𝓝 (2 * (r * K - q * Sstar) / (σ ^ 2 * Sstar ^ 2))) := by
  have hev : ∀ᶠ S in 𝓝[>] Sstar,
      (r * P S - Θ S - (r - q) * S * Δ S) / (1 / 2 * σ ^ 2 * S ^ 2) = Γ S := by
    filter_upwards [self_mem_nhdsWithin] with S hS'
    have hSpos : 0 < S := lt_trans hS hS'
    have hden : (1 / 2 * σ ^ 2 * S ^ 2) ≠ 0 := by positivity
    rw [div_eq_iff hden]
    have := hpde S hS'
    linarith
  have hid : Tendsto (fun S : ℝ => S) (𝓝[>] Sstar) (𝓝 Sstar) :=
    tendsto_nhdsWithin_of_tendsto_nhds tendsto_id
  have hden0 : (1 / 2 * σ ^ 2 * Sstar ^ 2) ≠ 0 := by
    have := hS.ne'
    positivity
  have hlim : Tendsto (fun S => (r * P S - Θ S - (r - q) * S * Δ S) / (1 / 2 * σ ^ 2 * S ^ 2))
      (𝓝[>] Sstar)
      (𝓝 ((r * (K - Sstar) - 0 - (r - q) * Sstar * (-1)) / (1 / 2 * σ ^ 2 * Sstar ^ 2))) := by
    refine Tendsto.div ?_ ?_ hden0
    · exact ((tendsto_const_nhds.mul hP).sub hΘ).sub ((tendsto_const_nhds.mul hid).mul hΔ)
    · exact tendsto_const_nhds.mul (hid.pow 2)
  have hval : (r * (K - Sstar) - 0 - (r - q) * Sstar * (-1)) / (1 / 2 * σ ^ 2 * Sstar ^ 2)
      = 2 * (r * K - q * Sstar) / (σ ^ 2 * Sstar ^ 2) := by
    have := hS.ne'
    field_simp
    ring
  rw [hval] at hlim
  exact hlim.congr' hev

#print axioms american_put_implied_vol_exists_unique
#print axioms american_put_delta_neg_one_in_exercise_region
#print axioms american_put_gamma_jump_at_boundary
