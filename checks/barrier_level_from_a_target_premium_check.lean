-- Solving for the barrier: a price that moves continuously and strictly one way as its level moves has exactly one level for each target strictly inside its price range and none outside it, while the digital's volatility equation has two roots, one or none.
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open Filter Topology Set

/-! The pricing formulas themselves (Garman–Kohlhagen, the mirror term, the bell-curve
area) are model prices with decimal inputs, so this file states the exact parts of the card:

* Step 0 with Step 1's edges: the knock-out price `f` on barriers `H` in `(0, S)` is
  continuous, strictly falling, tends to the vanilla price `C` as `H → 0` and to `0` as
  `H → S`. Then a target `P` names exactly one barrier if and only if `0 < P < C`.
* Step 2: the up one-touch price `f` on levels `H > S` is continuous, strictly falling,
  tends to the discounted dollar `D` as `H → S` and to `0` as `H → ∞`. Then a quote `P`
  names exactly one level if and only if `0 < P < D`.
* Step 4: with `a = ln (F / k) < 0` (strike above the forward), `z < 0` the bell-curve
  point fixed by the price, and `u = σ √T > 0`, the equation `d₂ = a / u - u / 2 = z` has
  two positive roots `-z ∓ √(z² + 2a)` with product `-2a` when `z² + 2a > 0`, the single
  root `-z` at the peak `z² + 2a = 0`, and no root when `z² + 2a < 0`. -/

/-- Knock-out level from a target premium: if the knock-out's price `f H` is continuous
and strictly decreasing for barriers `H` between `0` and spot `S`, rises to the vanilla
price `C` as the barrier falls to zero, and falls to zero as the barrier rises to spot,
then a target premium `P` names exactly one barrier below spot exactly when `P` lies
strictly between `0` and `C`; outside that range there is no barrier. -/
theorem knock_out_level_exists_unique_iff (S C : ℝ) (hS : 0 < S) (f : ℝ → ℝ)
    (hcont : ContinuousOn f (Ioo 0 S)) (hanti : StrictAntiOn f (Ioo 0 S))
    (hlow : Tendsto f (𝓝[>] 0) (𝓝 C)) (hhigh : Tendsto f (𝓝[<] S) (𝓝 0)) (P : ℝ) :
    (∃! H, H ∈ Ioo 0 S ∧ f H = P) ↔ P ∈ Ioo 0 C := by
  constructor
  · rintro ⟨H, ⟨hH, hfH⟩, -⟩
    subst hfH
    constructor
    · have hy : (H + S) / 2 ∈ Ioo 0 S := by
        constructor <;> linarith [hH.1, hH.2]
      have hlt : f ((H + S) / 2) < f H := hanti hH hy (by linarith [hH.2])
      have h0 : (0 : ℝ) ≤ f ((H + S) / 2) := by
        refine le_of_tendsto hhigh ?_
        filter_upwards [Ioo_mem_nhdsLT hy.2] with w hw
        exact (hanti hy ⟨by linarith [hy.1, hw.1], hw.2⟩ hw.1).le
      linarith
    · have hy : H / 2 ∈ Ioo 0 S := by
        constructor <;> linarith [hH.1, hH.2]
      have hlt : f H < f (H / 2) := hanti hy hH (by linarith [hH.1])
      have hC : f (H / 2) ≤ C := by
        refine ge_of_tendsto hlow ?_
        filter_upwards [Ioo_mem_nhdsGT hy.1] with w hw
        exact (hanti ⟨hw.1, by linarith [hy.2, hw.2]⟩ hy hw.2).le
      linarith
  · rintro ⟨hP0, hPC⟩
    obtain ⟨a, ha, hfa⟩ : ∃ a, a ∈ Ioo 0 S ∧ P < f a :=
      (Filter.Eventually.and (Ioo_mem_nhdsGT hS) (hlow.eventually (lt_mem_nhds hPC))).exists
    obtain ⟨b, hb, hfb⟩ : ∃ b, b ∈ Ioo a S ∧ f b < P :=
      (Filter.Eventually.and (Ioo_mem_nhdsLT ha.2) (hhigh.eventually (gt_mem_nhds hP0))).exists
    have hab : a ≤ b := hb.1.le
    have hsub : Icc a b ⊆ Ioo 0 S := fun x hx => ⟨by linarith [ha.1, hx.1], by linarith [hb.2, hx.2]⟩
    obtain ⟨H, hH, hfH⟩ := intermediate_value_Icc' hab (hcont.mono hsub) ⟨hfb.le, hfa.le⟩
    refine ⟨H, ⟨hsub hH, hfH⟩, ?_⟩
    rintro y ⟨hy, hfy⟩
    exact hanti.injOn hy (hsub hH) (hfy.trans hfH.symm)

/-- Touch level from a quote: if the up one-touch's price `f H` is continuous and strictly
decreasing for levels `H` above spot `S`, tends to the discounted dollar `D` as the level
comes down to spot, and tends to zero as the level moves far away, then a quote `P` names
exactly one level above spot exactly when `P` lies strictly between `0` and `D`. -/
theorem one_touch_level_exists_unique_iff (S D : ℝ) (f : ℝ → ℝ)
    (hcont : ContinuousOn f (Ioi S)) (hanti : StrictAntiOn f (Ioi S))
    (hnear : Tendsto f (𝓝[>] S) (𝓝 D)) (hfar : Tendsto f atTop (𝓝 0)) (P : ℝ) :
    (∃! H, H ∈ Ioi S ∧ f H = P) ↔ P ∈ Ioo 0 D := by
  constructor
  · rintro ⟨H, ⟨hH, hfH⟩, -⟩
    subst hfH
    have hH' : S < H := hH
    constructor
    · have hy : H + 1 ∈ Ioi S := by show S < H + 1; linarith
      have hlt : f (H + 1) < f H := hanti hH hy (by linarith)
      have h0 : (0 : ℝ) ≤ f (H + 1) := by
        refine le_of_tendsto hfar ?_
        filter_upwards [eventually_gt_atTop (H + 1)] with w hw
        exact (hanti hy (show S < w by linarith) hw).le
      linarith
    · have hy : (S + H) / 2 ∈ Ioi S := by show S < (S + H) / 2; linarith
      have hlt : f H < f ((S + H) / 2) := hanti hy hH (by linarith)
      have hD : f ((S + H) / 2) ≤ D := by
        refine ge_of_tendsto hnear ?_
        filter_upwards [Ioo_mem_nhdsGT (show S < (S + H) / 2 by linarith)] with w hw
        exact (hanti hw.1 hy hw.2).le
      linarith
  · rintro ⟨hP0, hPD⟩
    obtain ⟨a, ha, hfa⟩ : ∃ a, a ∈ Ioi S ∧ P < f a :=
      (Filter.Eventually.and (self_mem_nhdsWithin : Ioi S ∈ 𝓝[>] S)
        (hnear.eventually (lt_mem_nhds hPD))).exists
    obtain ⟨b, hb, hfb⟩ : ∃ b, a < b ∧ f b < P :=
      ((eventually_gt_atTop a).and (hfar.eventually (gt_mem_nhds hP0))).exists
    have hsub : Icc a b ⊆ Ioi S := fun x hx => lt_of_lt_of_le ha hx.1
    obtain ⟨H, hH, hfH⟩ := intermediate_value_Icc' hb.le (hcont.mono hsub) ⟨hfb.le, hfa.le⟩
    refine ⟨H, ⟨hsub hH, hfH⟩, ?_⟩
    rintro y ⟨hy, hfy⟩
    exact hanti.injOn hy (hsub hH) (hfy.trans hfH.symm)

/-- The digital's volatility does not invert uniquely: with the strike above the forward
(`a = ln (F / k) < 0`) and `z < 0`, the positive swings `u = σ √T` solving
`a / u - u / 2 = z` are the two roots `-z - √(z² + 2a)` and `-z + √(z² + 2a)`, both
positive with product `-2a`, when `z² + 2a > 0`; the single root `-z` at the peak
`z² + 2a = 0`; and none at all when `z² + 2a < 0`. -/
theorem digital_vol_two_roots_or_none (a z : ℝ) (ha : a < 0) (hz : z < 0) :
    (0 < z ^ 2 + 2 * a →
        {u : ℝ | 0 < u ∧ a / u - u / 2 = z} =
          {-z - Real.sqrt (z ^ 2 + 2 * a), -z + Real.sqrt (z ^ 2 + 2 * a)} ∧
        0 < -z - Real.sqrt (z ^ 2 + 2 * a) ∧
        (-z - Real.sqrt (z ^ 2 + 2 * a)) * (-z + Real.sqrt (z ^ 2 + 2 * a)) = -2 * a) ∧
    (z ^ 2 + 2 * a = 0 → {u : ℝ | 0 < u ∧ a / u - u / 2 = z} = {-z}) ∧
    (z ^ 2 + 2 * a < 0 → {u : ℝ | 0 < u ∧ a / u - u / 2 = z} = ∅) := by
  -- key reformulation for positive `u`
  have key : ∀ u : ℝ, 0 < u → (a / u - u / 2 = z ↔ (u + z) ^ 2 = z ^ 2 + 2 * a) := by
    intro u hu
    have hu0 : u ≠ 0 := hu.ne'
    constructor
    · intro h
      have h2 : a = (z + u / 2) * u := by
        have h3 : a / u = z + u / 2 := by linarith
        rw [div_eq_iff hu0] at h3
        linarith
      rw [h2]; ring
    · intro h
      have h2 : a = (z + u / 2) * u := by nlinarith
      rw [h2]; field_simp; ring
  refine ⟨?_, ?_, ?_⟩
  · intro hd
    set s := Real.sqrt (z ^ 2 + 2 * a) with hs
    have hs2 : s ^ 2 = z ^ 2 + 2 * a := Real.sq_sqrt hd.le
    have hs0 : 0 ≤ s := Real.sqrt_nonneg _
    have hpos1 : 0 < -z - s := by nlinarith
    have hpos2 : 0 < -z + s := by linarith
    refine ⟨?_, hpos1, by nlinarith⟩
    ext u
    simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
    constructor
    · rintro ⟨hu, h⟩
      have h' := (key u hu).1 h
      have : (u - (-z - s)) * (u - (-z + s)) = 0 := by nlinarith
      rcases mul_eq_zero.1 this with h1 | h1
      · left; linarith
      · right; linarith
    · rintro (rfl | rfl)
      · exact ⟨hpos1, (key _ hpos1).2 (by nlinarith)⟩
      · exact ⟨hpos2, (key _ hpos2).2 (by nlinarith)⟩
  · intro hd
    ext u
    simp only [Set.mem_ofPred_eq, Set.mem_singleton_iff]
    constructor
    · rintro ⟨hu, h⟩
      have h' := (key u hu).1 h
      rw [hd] at h'
      have : u + z = 0 := by nlinarith
      linarith
    · rintro rfl
      have hu : 0 < -z := by linarith
      exact ⟨hu, (key _ hu).2 (by rw [hd]; ring)⟩
  · intro hd
    ext u
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_and]
    intro hu h
    have h' := (key u hu).1 h
    nlinarith [sq_nonneg (u + z)]

/-- The card's mirror exponent: `α = 2 (r_d - r_f - σ²/2) / σ²` with `r_d = 5%`,
`r_f = 3%`, `σ = 10%` is exactly `3`. -/
example : 2 * ((5 : ℚ) / 100 - 3 / 100 - 1 / 2 * (1 / 10) ^ 2) / (1 / 10) ^ 2 = 3 := by
  norm_num

/-- The card's first bisection midpoints on the bracket `[1.00, 1.10]`. -/
example : ((1 : ℚ) + 11 / 10) / 2 = 105 / 100 ∧ ((105 : ℚ) / 100 + 11 / 10) / 2 = 1075 / 1000 ∧
    ((105 : ℚ) / 100 + 1075 / 1000) / 2 = 10625 / 10000 := by
  norm_num

#print axioms knock_out_level_exists_unique_iff
#print axioms one_touch_level_exists_unique_iff
#print axioms digital_vol_two_roots_or_none
