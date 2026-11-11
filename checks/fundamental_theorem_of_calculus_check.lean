-- Fundamental theorem of calculus: the integral of a rate over an interval equals the change in any function with that rate, and the running total of a continuous rate has that rate as its derivative.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Set intervalIntegral MeasureTheory

/-- **Accumulation gives the change (the second half).** Let a ≤ b. If G is continuous on the
closed interval from a to b, has rate f at every inside point, and the rate f has an integral
over the interval, then adding up f from a to b gives G at the end minus G at the start:
∫_a^b f(t) dt = G(b) − G(a). Continuity of f is not needed. -/
theorem integral_of_rate_eq_change (f G : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hG : ContinuousOn G (Icc a b))
    (hderiv : ∀ x ∈ Ioo a b, HasDerivAt G (f x) x)
    (hint : IntervalIntegrable f volume a b) :
    ∫ t in a..b, f t = G b - G a := by
  exact integral_eq_sub_of_hasDerivAt_of_le hab hG hderiv hint

/-- **The running total grows at the rate (the first half).** If the rate f is continuous on the
closed interval from a to b, then the running total A(x) = ∫_a^x f(t) dt has derivative f(x) at
every x in the interval. The derivative is taken within the interval, so at a and b it is the
one-sided derivative from the inside. -/
theorem running_total_has_derivative_rate (f : ℝ → ℝ) (a b : ℝ)
    (hf : ContinuousOn f (Icc a b)) (x : ℝ) (hx : x ∈ Icc a b) :
    HasDerivWithinAt (fun u => ∫ t in a..u, f t) (f x) (Icc a b) x := by
  have hab : a ≤ b := hx.1.trans hx.2
  have hsub : uIcc a x ⊆ Icc a b := by
    rw [uIcc_of_le hx.1]; exact Icc_subset_Icc le_rfl hx.2
  have : Fact (x ∈ Icc a b) := ⟨hx⟩
  exact integral_hasDerivWithinAt_right ((hf.mono hsub).intervalIntegrable)
    (hf.stronglyMeasurableAtFilter_nhdsWithin measurableSet_Icc x) (hf x hx)

/-- **Two antiderivatives differ by a constant.** If G₁ and G₂ are both continuous on the closed
interval from a to b and both have rate f at every inside point, then there is one constant C with
G₁(x) = G₂(x) + C for every x in the interval; so C cancels in G(b) − G(a). -/
theorem antiderivatives_differ_by_constant (f G₁ G₂ : ℝ → ℝ) (a b : ℝ)
    (h₁ : ContinuousOn G₁ (Icc a b)) (h₂ : ContinuousOn G₂ (Icc a b))
    (hd₁ : ∀ x ∈ Ioo a b, HasDerivAt G₁ (f x) x)
    (hd₂ : ∀ x ∈ Ioo a b, HasDerivAt G₂ (f x) x) :
    ∃ C : ℝ, ∀ x ∈ Icc a b, G₁ x = G₂ x + C := by
  refine ⟨G₁ a - G₂ a, fun x hx => ?_⟩
  rcases eq_or_lt_of_le hx.1 with h | h
  · subst h; ring
  · have hc : ContinuousOn (fun y => G₁ y - G₂ y) (Icc a x) :=
      (h₁.mono (Icc_subset_Icc le_rfl hx.2)).sub (h₂.mono (Icc_subset_Icc le_rfl hx.2))
    have hd : ∀ y ∈ Ioo a x, HasDerivAt (fun y => G₁ y - G₂ y) ((fun _ => (0:ℝ)) y) y := by
      intro y hy
      have hy' : y ∈ Ioo a b := ⟨hy.1, hy.2.trans_le hx.2⟩
      have h3 := (hd₁ y hy').sub (hd₂ y hy')
      rw [sub_self] at h3
      exact h3
    obtain ⟨c, _, hc'⟩ := exists_hasDerivAt_eq_slope (fun y => G₁ y - G₂ y) (fun _ => (0:ℝ)) h hc hd
    have hne : x - a ≠ 0 := sub_ne_zero.mpr (ne_of_gt h)
    have := hc'.symm
    rw [div_eq_zero_iff] at this
    rcases this with h0 | h0
    · linarith
    · exact absurd h0 hne

-- The tank: G(t) = 3t + t², read at the ends. G(10) = 30 + 100 = 130, G(0) = 0.
example : (3 * 10 + 10 ^ 2 : ℤ) = 130 := by norm_num
example : (3 * 0 + 0 ^ 2 : ℤ) = 0 := by norm_num
example : (3 * 10 + 10 ^ 2 : ℤ) - (3 * 0 + 0 ^ 2) = 130 := by norm_num

-- The rate at minute 4: f(4) = 3 + 2·4 = 11 litres a minute.
example : (3 + 2 * 4 : ℤ) = 11 := by norm_num

-- Minutes 2 to 10 only: G(10) − G(2) = 130 − 10 = 120.
example : (3 * 10 + 10 ^ 2 : ℤ) - (3 * 2 + 2 ^ 2) = 120 := by norm_num

-- Minute by minute: the ten changes 4, 6, …, 22 add to 130.
example : ∑ k ∈ Finset.range 10, (2 * (k + 1) + 2) = 130 := by decide

-- Each one-minute change G(k) − G(k − 1) is 2k + 2, the flow at the half minute, f(k − 1/2).
example : ∀ k ∈ Finset.Icc (1 : ℕ) 10,
    ((3 * k + k ^ 2 : ℚ) - (3 * (k - 1) + (k - 1) ^ 2) = 2 * k + 2 ∧
     (3 + 2 * ((k : ℚ) - 1/2)) = 2 * k + 2) := by
  intro k _; constructor <;> ring

-- The level G(k) at each whole minute: 0, 4, 10, 18, 28, 40, 54, 70, 88, 108, 130.
example : (List.range 11).map (fun t => 3 * t + t ^ 2) = [0, 4, 10, 18, 28, 40, 54, 70, 88, 108, 130] := by
  decide

-- One-minute left rectangles fall 10 litres short: 3 + 5 + … + 21 = 120.
example : ∑ k ∈ Finset.range 10, (3 + 2 * k) = 120 := by decide

-- The tank's integral itself: ∫₀¹⁰ (3 + 2t) dt = 130.
example : ∫ t in (0 : ℝ)..10, (3 + 2 * t) = 130 := by
  rw [integral_add (by simp) ((by fun_prop : Continuous fun t : ℝ => 2 * t).intervalIntegrable 0 10),
    intervalIntegral.integral_const_mul, integral_id]
  norm_num

-- One arch of sin: ∫₀^π sin t dt = −cos π + cos 0 = 2.
example : ∫ t in (0 : ℝ)..Real.pi, Real.sin t = 2 := by
  norm_num [integral_sin]

#print axioms integral_of_rate_eq_change
#print axioms running_total_has_derivative_rate
#print axioms antiderivatives_differ_by_constant
