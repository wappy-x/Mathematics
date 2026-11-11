-- Continuity: sums, products and chains of real functions continuous at a point stay continuous there, every polynomial is continuous, and the stepped taxi fare 3 + 2⌈d⌉ jumps from 3 + 2n to 5 + 2n at every whole kilometre n, so it is continuous from the left there but not continuous.
import Mathlib.Topology.Algebra.Polynomial
import Mathlib.Topology.Algebra.Order.Floor
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum

open Filter Topology

/-- Sums, products and chains of continuous functions stay continuous. If f and g are continuous
at a point a, so are f + g and f · g. For a chain f(g(t)), g must be continuous at a and the outer
function f continuous where g lands, at g(a). -/
theorem sum_product_chain_stay_continuous (f g : ℝ → ℝ) (a : ℝ) :
    (ContinuousAt f a → ContinuousAt g a →
        ContinuousAt (fun x => f x + g x) a ∧ ContinuousAt (fun x => f x * g x) a) ∧
      (ContinuousAt g a → ContinuousAt f (g a) → ContinuousAt (fun x => f (g x)) a) := by
  refine ⟨fun hf hg => ⟨hf.add hg, hf.mul hg⟩, fun hg hf => ?_⟩
  exact hf.comp hg

/-- The stepped fare S(d) = 3 + 2⌈d⌉ (3 dollars at the kerb, 2 for every kilometre started)
jumps at every whole kilometre n. At n it shows 3 + 2n; from below it heads for that same value,
from above it heads for 5 + 2n, 2 dollars more. So it is continuous from the left at n, and not
continuous at n. -/
theorem stepped_fare_jumps_at_every_whole_km (n : ℕ) :
    let S : ℝ → ℝ := fun d => 3 + 2 * (⌈d⌉ : ℝ)
    S n = 3 + 2 * n ∧
      Tendsto S (𝓝[<] (n : ℝ)) (𝓝 (3 + 2 * n)) ∧
      Tendsto S (𝓝[>] (n : ℝ)) (𝓝 (5 + 2 * n)) ∧
      ContinuousWithinAt S (Set.Iic (n : ℝ)) n ∧
      ¬ ContinuousAt S n := by
  intro S
  have hSn : S n = 3 + 2 * n := by
    simp only [S, Int.ceil_natCast, Int.cast_natCast]
  have hL : ∀ᶠ d in 𝓝[≤] (n : ℝ), S d = 3 + 2 * n := by
    filter_upwards [Ioc_mem_nhdsLE (show (n : ℝ) - 1 < n by linarith)] with d hd
    have hc : ⌈d⌉ = (n : ℤ) := by
      rw [Int.ceil_eq_iff]
      push_cast
      exact ⟨hd.1, hd.2⟩
    simp only [S, hc, Int.cast_natCast]
  have hR : ∀ᶠ d in 𝓝[>] (n : ℝ), S d = 5 + 2 * n := by
    filter_upwards [Ioo_mem_nhdsGT (show (n : ℝ) < n + 1 by linarith)] with d hd
    have hc : ⌈d⌉ = (n : ℤ) + 1 := by
      rw [Int.ceil_eq_iff]
      push_cast
      exact ⟨by linarith [hd.1], hd.2.le⟩
    simp only [S, hc]
    push_cast
    ring
  have hLim : Tendsto S (𝓝[≤] (n : ℝ)) (𝓝 (3 + 2 * n)) :=
    tendsto_const_nhds.congr' (hL.mono fun d hd => hd.symm)
  have hRlim : Tendsto S (𝓝[>] (n : ℝ)) (𝓝 (5 + 2 * n)) :=
    tendsto_const_nhds.congr' (hR.mono fun d hd => hd.symm)
  refine ⟨hSn, hLim.mono_left (nhdsWithin_mono _ Set.Iio_subset_Iic_self), hRlim, ?_, ?_⟩
  · show Tendsto S (𝓝[≤] (n : ℝ)) (𝓝 (S n))
    rw [hSn]
    exact hLim
  · intro hc
    have h1 : Tendsto S (𝓝[>] (n : ℝ)) (𝓝 (3 + 2 * n)) := by
      rw [← hSn]
      exact hc.tendsto.mono_left nhdsWithin_le_nhds
    have := tendsto_nhds_unique h1 hRlim
    linarith

/-- Every polynomial is continuous everywhere: it is built from constants and the function that
returns its own input by sums and products. -/
theorem every_polynomial_is_continuous (p : Polynomial ℝ) : Continuous fun x : ℝ => p.eval x := by
  exact p.continuous

-- Stepped fare by formula at 0, 4/10, 1, 1001/1000, 2, 5/2 and 32/10 km: 3, 5, 5, 7, 7, 9, 11 dollars.
example : (3 + 2 * ⌈(0 : ℚ)⌉, 3 + 2 * ⌈(4 / 10 : ℚ)⌉, 3 + 2 * ⌈(1 : ℚ)⌉, 3 + 2 * ⌈(1001 / 1000 : ℚ)⌉)
    = (3, 5, 5, 7) := by norm_num
example : (3 + 2 * ⌈(2 : ℚ)⌉, 3 + 2 * ⌈(5 / 2 : ℚ)⌉, 3 + 2 * ⌈(32 / 10 : ℚ)⌉) = (7, 9, 11) := by
  norm_num
-- Worked numbers at 1 km: 5 dollars at and just below, 7 just above, a jump of 2.
example : (3 + 2 * 1 : ℤ) = 5 ∧ (3 + 2 * 2 : ℤ) = 7 ∧ (7 - 5 : ℤ) = 2 := by decide
-- Metered fare M(d) = 3 + 2d: 7 dollars at 2 km; window for one cent at 2 km is 1/100 ÷ 2 = 5/1000 km.
example : (3 + 2 * 2 : ℚ) = 7 ∧ (1 / 100 : ℚ) / 2 = 5 / 1000 := by norm_num
-- Metered price per km M(d)/d at 1/10, 1/100, 1/1000 km: 32, 302, 3002 dollars.
example : (3 + 2 * (1 / 10 : ℚ)) / (1 / 10) = 32 ∧ (3 + 2 * (1 / 100 : ℚ)) / (1 / 100) = 302 ∧
    (3 + 2 * (1 / 1000 : ℚ)) / (1 / 1000) = 3002 := by norm_num
-- At 4 minutes: fare 3 + 4 = 7, waiting total 3 + (5/4)·4 = 8, surge 1 + (5/100)·4 = 6/5,
-- surge charge 7 · 6/5 = 42/5 dollars; chain window 5/1000 ÷ (1/2) = 1/100 minute.
example : (3 + 4 : ℚ) = 7 ∧ (3 + 5 / 4 * 4 : ℚ) = 8 ∧ (1 + 5 / 100 * 4 : ℚ) = 6 / 5 ∧
    (7 * (6 / 5) : ℚ) = 42 / 5 ∧ (5 / 1000 : ℚ) / (1 / 2) = 1 / 100 := by norm_num
-- Stepped fare over time: at 4 minutes the cab is at 2 km and the fare is 7; a moment later, 9.
example : 3 + 2 * ⌈(1 / 2 * 4 : ℚ)⌉ = 7 ∧ 3 + 2 * ⌈(1 / 2 * (4000001 / 1000000) : ℚ)⌉ = 9 := by
  norm_num

#print axioms sum_product_chain_stay_continuous
#print axioms stepped_fare_jumps_at_every_whole_km
#print axioms every_polynomial_is_continuous
