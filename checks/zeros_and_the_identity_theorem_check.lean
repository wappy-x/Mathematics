-- Zeros and the identity theorem: two holomorphic functions that agree at points closing in on a point of a connected open region agree on all of it, and near a zero a holomorphic function that is not zero everywhere is (z − a)^m times a factor not zero at a, so its zeros stand apart.
import Mathlib.Analysis.Analytic.IsolatedZeros
import Mathlib.Analysis.Analytic.Order
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Complex Filter Topology Metric Finset

/-- **The identity theorem.** Let D be a domain (an open, connected set of complex numbers)
and let f₁, f₂ be holomorphic on D (complex-differentiable at every point of D). If the points
z₁, z₂, z₃, … all lie in D, none of them equals a, they close in on a point a that lies inside D,
and f₁(zₙ) = f₂(zₙ) for every n, then f₁ = f₂ at every point of D. -/
theorem identity_theorem {D : Set ℂ} (hD : IsOpen D) (hDc : IsConnected D) {f₁ f₂ : ℂ → ℂ}
    (hf₁ : DifferentiableOn ℂ f₁ D) (hf₂ : DifferentiableOn ℂ f₂ D) {a : ℂ} (ha : a ∈ D)
    {z : ℕ → ℂ} (hzD : ∀ n, z n ∈ D) (hza : ∀ n, z n ≠ a) (hlim : Tendsto z atTop (𝓝 a))
    (heq : ∀ n, f₁ (z n) = f₂ (z n)) :
    Set.EqOn f₁ f₂ D := by
  have h₁ : AnalyticOnNhd ℂ f₁ D := (analyticOnNhd_iff_differentiableOn hD).mpr hf₁
  have h₂ : AnalyticOnNhd ℂ f₂ D := (analyticOnNhd_iff_differentiableOn hD).mpr hf₂
  have ht : Tendsto z atTop (𝓝[≠] a) :=
    tendsto_nhdsWithin_iff.mpr ⟨hlim, Eventually.of_forall hza⟩
  have hfr : ∃ᶠ w in 𝓝[≠] a, f₁ w = f₂ w :=
    ht.frequently (Frequently.of_forall heq)
  exact h₁.eqOn_of_preconnected_of_frequently_eq h₂ hDc.isPreconnected ha hfr

/-- **A zero factors out.** Let f be holomorphic on a domain D and not zero everywhere on D,
and let a be a point of D with f(a) = 0. Then the zero has a finite order m ≥ 1: the derivatives
f(a), f′(a), …, f^(m−1)(a) are all 0, and near a, f(z) = (z − a)^m · g(z) for a function g that
is holomorphic near a with g(a) = f^(m)(a)/m!, the m-th Taylor coefficient c_m, and g(a) ≠ 0. -/
theorem zero_factors_as_power_times_nonzero {D : Set ℂ} (hD : IsOpen D) (hDc : IsConnected D)
    {f : ℂ → ℂ} (hf : DifferentiableOn ℂ f D) (hne : ∃ w ∈ D, f w ≠ 0) {a : ℂ} (ha : a ∈ D)
    (hfa : f a = 0) :
    ∃ m : ℕ, 0 < m ∧ (∀ k < m, iteratedDeriv k f a = 0) ∧
      ∃ g : ℂ → ℂ, AnalyticAt ℂ g a ∧ g a = iteratedDeriv m f a / (m.factorial : ℂ) ∧
        g a ≠ 0 ∧ ∀ᶠ z in 𝓝 a, f z = (z - a) ^ m * g z := by
  have hA : AnalyticOnNhd ℂ f D := (analyticOnNhd_iff_differentiableOn hD).mpr hf
  have hfa' : AnalyticAt ℂ f a := hA a ha
  have htop : analyticOrderAt f a ≠ ⊤ := by
    obtain ⟨w, hw, hfw⟩ := hne
    refine hA.analyticOrderAt_ne_top_of_isPreconnected hDc.isPreconnected hw ha ?_
    rw [(hA w hw).analyticOrderAt_eq_zero.mpr hfw]
    exact ENat.zero_ne_top
  set m := analyticOrderNatAt f a with hmdef
  have hm : analyticOrderAt f a = m := (Nat.cast_analyticOrderNatAt htop).symm
  obtain ⟨hlow, hmne⟩ := (analyticOrderAt_eq_nat_iff_iteratedDeriv_eq_zero hfa').mp hm
  have hpos : 0 < m := by
    rcases Nat.eq_zero_or_pos m with h | h
    · exfalso
      rw [h] at hmne
      simp [hfa] at hmne
    · exact h
  have hf'a : AnalyticAt ℂ (fun w => f (w + a)) 0 := by
    have hs : AnalyticAt ℂ (fun w : ℂ => w + a) 0 := by fun_prop
    exact AnalyticAt.comp_of_eq hfa' hs (by simp)
  obtain ⟨F, hF, hFeq⟩ := hf'a.exists_eventuallyEq_sum_add_pow_mul (m + 1)
  have hder : ∀ i, iteratedDeriv i (fun w => f (w + a)) 0 = iteratedDeriv i f a := fun i => by
    simp [iteratedDeriv_comp_add_const]
  have hFa : AnalyticAt ℂ (fun z => F (z - a)) a := by
    have hs : AnalyticAt ℂ (fun z : ℂ => z - a) a := by fun_prop
    exact AnalyticAt.comp_of_eq hF hs (by simp)
  refine ⟨m, hpos, hlow, fun z => iteratedDeriv m f a / (m.factorial : ℂ) + (z - a) * F (z - a),
    ?_, ?_, ?_, ?_⟩
  · exact analyticAt_const.add ((analyticAt_id.sub analyticAt_const).mul hFa)
  · simp
  · simp only [sub_self, zero_mul, add_zero]
    exact div_ne_zero hmne (Nat.cast_ne_zero.mpr (Nat.factorial_ne_zero m))
  · have ht : Tendsto (fun z => z - a) (𝓝 a) (𝓝 0) := by
      simpa using (continuous_sub_right a).tendsto a
    filter_upwards [ht.eventually hFeq] with z hz
    simp only [sub_add_cancel, hder, Finset.sum_range_succ, smul_eq_mul] at hz
    have hs : ∑ x ∈ Finset.range m, (z - a) ^ x / (x.factorial : ℂ) * iteratedDeriv x f a = 0 :=
      Finset.sum_eq_zero fun i hi => by rw [hlow i (Finset.mem_range.mp hi), mul_zero]
    rw [hz, hs]
    ring

/-- **Zeros stand apart.** Let f be holomorphic on a domain D and not zero everywhere on D,
and let a be a point of D with f(a) = 0. Then some small disc round a holds no other zero of f. -/
theorem zeros_are_isolated {D : Set ℂ} (hD : IsOpen D) (hDc : IsConnected D)
    {f : ℂ → ℂ} (hf : DifferentiableOn ℂ f D) (hne : ∃ w ∈ D, f w ≠ 0) {a : ℂ} (ha : a ∈ D)
    (hfa : f a = 0) :
    ∃ r > 0, ∀ z ∈ ball a r, z ≠ a → f z ≠ 0 := by
  obtain ⟨m, hm, -, g, hg, -, hga, hfg⟩ :=
    zero_factors_as_power_times_nonzero hD hDc hf hne ha hfa
  have hev : ∀ᶠ z in 𝓝 a, f z = (z - a) ^ m * g z ∧ g z ≠ 0 :=
    hfg.and (hg.continuousAt.eventually_ne hga)
  obtain ⟨r, hr, hball⟩ := Metric.eventually_nhds_iff_ball.mp hev
  refine ⟨r, hr, fun z hz hza => ?_⟩
  obtain ⟨h1, h2⟩ := hball z hz
  rw [h1]
  exact mul_ne_zero (pow_ne_zero _ (sub_ne_zero.mpr hza)) h2

-- The cubic multiplied out: z^2(z − 1) = −z^2 + z^3, so its coefficients at 0 are 0, 0, −1, 1.
example (z : ℂ) : z ^ 2 * (z - 1) = -z ^ 2 + z ^ 3 := by ring
-- The order is the place of the first non-zero coefficient: 2 for the cubic, not its top power 3.
example : List.findIdx (· ≠ 0) [(0 : ℤ), 0, -1, 1] = 2 := by decide
-- Sine's coefficients at 0 are 0, 1, 0, −1/6 (the card's −0.166667), so its zero has order 1.
example : (List.range 4).map (fun k => if k % 2 = 0 then (0 : ℚ)
    else (-1) ^ (k / 2) / (k.factorial : ℚ)) = [0, 1, 0, -1 / 6] := by norm_num [List.range_succ, Nat.factorial]
example : List.findIdx (· ≠ 0) [(0 : ℚ), 1, 0, -1 / 6] = 1 := by decide
-- n! times the coefficient of z^n in sin^2 z + cos^2 z, n = 0 to 10: 1, then ten zeros.
example : (List.range 11).map (fun n => ∑ k ∈ range (n + 1), (Nat.choose n k : ℤ) *
    ([0, 1, 0, -1].getD (k % 4) 0 * [0, 1, 0, -1].getD ((n - k) % 4) 0 +
     [1, 0, -1, 0].getD (k % 4) 0 * [1, 0, -1, 0].getD ((n - k) % 4) 0)) =
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] := by decide
-- The identity carried off the real line: sin^2 + cos^2 = 1 at 1 + 2i.
example : Complex.sin (1 + 2 * I) ^ 2 + Complex.cos (1 + 2 * I) ^ 2 = 1 :=
  Complex.sin_sq_add_cos_sq _

#print axioms identity_theorem
#print axioms zero_factors_as_power_times_nonzero
#print axioms zeros_are_isolated
