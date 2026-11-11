-- Limits and regions in the plane: a complex sequence converges exactly when its real and imaginary parts converge, the complex geometric series sums to 1/(1 - q) inside the unit disc and has no limit for |q| ≥ 1, and absolutely convergent complex series converge.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Normed.Group.InfiniteSum
import Mathlib.Tactic.NormNum

open Filter Topology Finset

/-- A sequence of complex numbers tends to `L` exactly when its real parts tend to
the real part of `L` and its imaginary parts tend to the imaginary part of `L`. -/
theorem complex_tendsto_iff_re_and_im_tendsto (z : ℕ → ℂ) (L : ℂ) :
    Tendsto z atTop (𝓝 L) ↔
      Tendsto (fun n => (z n).re) atTop (𝓝 L.re) ∧
      Tendsto (fun n => (z n).im) atTop (𝓝 L.im) := by
  constructor
  · intro h
    exact ⟨(Complex.continuous_re.tendsto L).comp h, (Complex.continuous_im.tendsto L).comp h⟩
  · rintro ⟨hre, him⟩
    have h := (hre.ofReal).add (him.ofReal.mul_const Complex.I)
    simpa only [Complex.re_add_im] using h

/-- The geometric series with complex ratio `q`: for every `q` in the open unit disc
the partial sums `1 + q + ... + q^(N-1)` tend to `1/(1 - q)`; for `|q| ≥ 1`
(on the boundary circle or outside it) the partial sums have no limit. -/
theorem complex_geometric_series_sum_iff_in_open_unit_disc :
    (∀ q : ℂ, ‖q‖ < 1 →
      Tendsto (fun N => ∑ n ∈ range N, q ^ n) atTop (𝓝 (1 - q)⁻¹)) ∧
    (∀ q : ℂ, 1 ≤ ‖q‖ →
      ¬ ∃ S : ℂ, Tendsto (fun N => ∑ n ∈ range N, q ^ n) atTop (𝓝 S)) := by
  refine ⟨fun q hq => (hasSum_geometric_of_norm_lt_one hq).tendsto_sum_nat, ?_⟩
  rintro q hq ⟨S, hS⟩
  have h1 : Tendsto (fun N => ∑ n ∈ range (N + 1), q ^ n) atTop (𝓝 S) :=
    hS.comp (tendsto_add_atTop_nat 1)
  have h2 : Tendsto (fun N => q ^ N) atTop (𝓝 (S - S)) := by
    have := h1.sub hS
    refine this.congr (fun N => ?_)
    simp [Finset.sum_range_succ]
  rw [sub_self] at h2
  have h3 : Tendsto (fun N => ‖q ^ N‖) atTop (𝓝 0) := by
    simpa using h2.norm
  have h4 : ∀ N : ℕ, 1 ≤ ‖q ^ N‖ := fun N => by
    rw [norm_pow]; exact one_le_pow₀ hq
  have h5 : (1 : ℝ) ≤ 0 := ge_of_tendsto' h3 h4
  norm_num at h5

/-- Absolute convergence: if the lengths `|a n|` of a complex series have a finite total,
the partial sums of the series converge to some `S`, and `|S|` is at most that total. -/
theorem complex_absolutely_convergent_series_converges (a : ℕ → ℂ)
    (h : Summable (fun n => ‖a n‖)) :
    ∃ S : ℂ, Tendsto (fun N => ∑ n ∈ range N, a n) atTop (𝓝 S) ∧
      ‖S‖ ≤ ∑' n, ‖a n‖ := by
  refine ⟨∑' n, a n, (Summable.of_norm h).hasSum.tendsto_sum_nat, norm_tsum_le_tsum_norm h⟩

-- The card's path length: tread lengths 1, 0.8, 0.8^2, ... add to 1/(1 - 0.8) = 5 metres.
example : (1 - (4 / 5 : ℝ))⁻¹ = 5 := by norm_num

#print axioms complex_tendsto_iff_re_and_im_tendsto
#print axioms complex_geometric_series_sum_iff_in_open_unit_disc
#print axioms complex_absolutely_convergent_series_converges
