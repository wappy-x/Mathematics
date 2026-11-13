-- Barrier inverses: a continuous price that falls strictly as the barrier rises, from the plain call's price to zero, hits every premium strictly between them at exactly one barrier level and no other premium at all, while a continuous price that starts at a floor, peaks and dies away hits every quote between the floor and the peak at two volatilities at least and no quote above the peak.
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Algebra.Order.LiminfLimsup
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real Filter Topology ProbabilityTheory

/-- The level inverse. Let `C_do(H)` be the down-and-out call's price as a function of the barrier
`H` on `(0, S)`, with `S > 0` today's share price. Step 1 of the card shows it is continuous,
strictly decreasing, tends to the plain call's price `C` as the barrier sinks to zero, and tends
to zero as the barrier climbs to `S`. Then for every target premium `P` with `0 < P < C` there is
exactly one barrier level `H` in `(0, S)` with `C_do(H) = P`, and for any other `P` there is none. -/
theorem barrier_level_from_premium_unique (Cdo : ℝ → ℝ) (S C : ℝ) (hS : 0 < S)
    (hcont : ContinuousOn Cdo (Set.Ioo 0 S))
    (hanti : StrictAntiOn Cdo (Set.Ioo 0 S))
    (hlow : Tendsto Cdo (𝓝[>] 0) (𝓝 C))
    (hhigh : Tendsto Cdo (𝓝[<] S) (𝓝 0)) (P : ℝ) :
    ((0 < P ∧ P < C) → ∃! H, H ∈ Set.Ioo 0 S ∧ Cdo H = P) ∧
    (¬ (0 < P ∧ P < C) → ∀ H ∈ Set.Ioo 0 S, Cdo H ≠ P) := by
  have hbound : ∀ H ∈ Set.Ioo 0 S, 0 < Cdo H ∧ Cdo H < C := by
    intro H hH
    obtain ⟨h0, hHS⟩ := hH
    constructor
    · have hH' : (H + S) / 2 ∈ Set.Ioo 0 S := ⟨by linarith, by linarith⟩
      have h1 : Cdo ((H + S) / 2) < Cdo H := hanti ⟨h0, hHS⟩ hH' (by linarith)
      have h2 : 0 ≤ Cdo ((H + S) / 2) := by
        apply le_of_tendsto hhigh
        filter_upwards [Ioo_mem_nhdsLT (show (H + S) / 2 < S by linarith)] with x hx
        exact (hanti hH' ⟨by linarith [hx.1], hx.2⟩ hx.1).le
      linarith
    · have hH' : H / 2 ∈ Set.Ioo 0 S := ⟨by linarith, by linarith⟩
      have h1 : Cdo H < Cdo (H / 2) := hanti hH' ⟨h0, hHS⟩ (by linarith)
      have h2 : Cdo (H / 2) ≤ C := by
        apply ge_of_tendsto hlow
        filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < H / 2 by linarith)] with x hx
        exact (hanti ⟨hx.1, by linarith [hx.2]⟩ hH' hx.2).le
      linarith
  refine ⟨?_, ?_⟩
  · rintro ⟨hP0, hPC⟩
    obtain ⟨a, ha, haS⟩ := ((hlow.eventually (lt_mem_nhds hPC)).and
      (Ioo_mem_nhdsGT hS)).exists
    obtain ⟨b, hb, hbS⟩ := ((hhigh.eventually (gt_mem_nhds hP0)).and
      (Ioo_mem_nhdsLT hS)).exists
    have hab : a ≤ b := by
      by_contra h
      rw [not_le] at h
      have := hanti hbS haS h
      linarith
    have hsub : Set.Icc a b ⊆ Set.Ioo 0 S := fun x hx => ⟨by linarith [haS.1, hx.1],
      by linarith [hbS.2, hx.2]⟩
    obtain ⟨H, hH, hHP⟩ := intermediate_value_Icc' hab (hcont.mono hsub) ⟨hb.le, ha.le⟩
    refine ⟨H, ⟨hsub hH, hHP⟩, ?_⟩
    rintro y ⟨hy, hyP⟩
    exact hanti.injOn hy (hsub hH) (hyP.trans hHP.symm)
  · intro hP H hH hHP
    exact hP ⟨hHP ▸ (hbound H hH).1, hHP ▸ (hbound H hH).2⟩

/-- The volatility inverse can fail both ways. Let `U(σ)` be the up-and-out call's price as a
function of the volatility `σ > 0`: continuous, tending to the zero-volatility floor `F` as
`σ → 0`, tending to zero as `σ → ∞`, and reaching its largest value at the peak volatility `σₚ`.
Then a positive quote `P` above the floor and under the peak is hit at least twice, once below
the peak and once above it; and a quote above the peak is hit by no volatility. -/
theorem knockout_implied_vol_two_roots_or_none (U : ℝ → ℝ) (F σₚ : ℝ) (hσₚ : 0 < σₚ)
    (hcont : ContinuousOn U (Set.Ioi 0))
    (hfloor : Tendsto U (𝓝[>] 0) (𝓝 F))
    (hinf : Tendsto U atTop (𝓝 0))
    (hpeak : IsMaxOn U (Set.Ioi 0) σₚ) (P : ℝ) :
    ((F < P ∧ 0 < P ∧ P < U σₚ) →
      ∃ σ₁ σ₂, 0 < σ₁ ∧ σ₁ < σₚ ∧ σₚ < σ₂ ∧ U σ₁ = P ∧ U σ₂ = P) ∧
    (U σₚ < P → ∀ σ ∈ Set.Ioi 0, U σ ≠ P) := by
  refine ⟨?_, ?_⟩
  · rintro ⟨hFP, hP0, hPp⟩
    obtain ⟨a, ha, haS⟩ := ((hfloor.eventually (gt_mem_nhds hFP)).and
      (Ioo_mem_nhdsGT hσₚ)).exists
    obtain ⟨b, hb, hbS⟩ := ((hinf.eventually (gt_mem_nhds hP0)).and
      (eventually_gt_atTop σₚ)).exists
    have hsub1 : Set.Icc a σₚ ⊆ Set.Ioi 0 := fun x hx => lt_of_lt_of_le haS.1 hx.1
    have hsub2 : Set.Icc σₚ b ⊆ Set.Ioi 0 := fun x hx => lt_of_lt_of_le hσₚ hx.1
    obtain ⟨s1, hs1, hU1⟩ := intermediate_value_Icc haS.2.le (hcont.mono hsub1)
      ⟨ha.le, hPp.le⟩
    obtain ⟨s2, hs2, hU2⟩ := intermediate_value_Icc' hbS.le (hcont.mono hsub2)
      ⟨hb.le, hPp.le⟩
    refine ⟨s1, s2, lt_of_lt_of_le haS.1 hs1.1, ?_, ?_, hU1, hU2⟩
    · rcases hs1.2.lt_or_eq with h | h
      · exact h
      · subst h; linarith
    · rcases hs2.1.lt_or_eq with h | h
      · exact h
      · subst h; linarith
  · intro hP σ hσ hUσ
    have := hpeak hσ
    change U σ ≤ U σₚ at this
    linarith

/-- The high-volatility limit. The up-and-out call (barrier `H` over strike `K`) pays at most
`H - K`, and only when the share ends above `K`, so its price is at most
`(H - K) e^(-rT) N((ln(S/K) + (r - q - σ²/2) T) / (σ√T))`, with `N` the standard normal CDF.
That bound tends to zero as the volatility `σ` grows without limit. -/
theorem up_out_bound_tends_to_zero_high_vol (S K H r q T : ℝ) (hS : 0 < S) (hK : 0 < K)
    (hT : 0 < T) :
    Tendsto (fun σ : ℝ => (H - K) * exp (-r * T) *
      cdf (gaussianReal 0 1) ((log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T)))
      atTop (𝓝 0) := by
  have hc : 0 < √T := Real.sqrt_pos.mpr hT
  set A := log (S / K) + (r - q) * T with hA
  have harg : Tendsto (fun σ : ℝ => (log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T))
      atTop atBot := by
    have h1 : Tendsto (fun σ : ℝ => A / √T * σ⁻¹ + -((T / (2 * √T)) * σ)) atTop atBot := by
      apply Tendsto.add_atBot (C := A / √T * 0)
      · exact tendsto_inv_atTop_zero.const_mul _
      · apply tendsto_neg_atTop_atBot.comp
        exact Tendsto.const_mul_atTop (by positivity) tendsto_id
    apply h1.congr'
    filter_upwards [eventually_gt_atTop (0:ℝ)] with σ hσ
    rw [hA]
    field_simp
    ring
  have h2 := (tendsto_cdf_atBot (μ := gaussianReal 0 1)).comp harg
  have h3 := h2.const_mul ((H - K) * exp (-r * T))
  simpa using h3

-- The card's bisection for the $8.00 level, from the interval 50 to 100: the seven midpoints
-- 75, 87.5, 93.75, 90.625, 89.0625, 88.28125, 88.671875, written as fractions.
example : ((50 : ℚ) + 100) / 2 = 75 := by norm_num
example : ((75 : ℚ) + 100) / 2 = 175 / 2 := by norm_num
example : ((175 / 2 : ℚ) + 100) / 2 = 375 / 4 := by norm_num
example : ((175 / 2 : ℚ) + 375 / 4) / 2 = 725 / 8 := by norm_num
example : ((175 / 2 : ℚ) + 725 / 8) / 2 = 1425 / 16 := by norm_num
example : ((175 / 2 : ℚ) + 1425 / 16) / 2 = 2825 / 32 := by norm_num
example : ((2825 / 32 : ℚ) + 1425 / 16) / 2 = 5675 / 64 := by norm_num
-- After seven halvings the interval 50 to 100 has width 50/2^7 = 25/64.
example : (50 : ℚ) / 2 ^ 7 = 25 / 64 := by norm_num
-- The helper λ = (r - q + σ²/2)/σ² at r = 5%, q = 2%, σ = 20% is 1.25 = 5/4.
example : ((5 / 100 : ℚ) - 2 / 100 + (20 / 100) ^ 2 / 2) / (20 / 100) ^ 2 = 5 / 4 := by norm_num

#print axioms barrier_level_from_premium_unique
#print axioms knockout_implied_vol_two_roots_or_none
#print axioms up_out_bound_tends_to_zero_high_vol
