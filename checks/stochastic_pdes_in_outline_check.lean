-- Stochastic PDEs in outline: the stationary mode variances σ²/(2k²) of the stochastic heat equation on a rod sum to π²σ²/12 and give the point variance σ²x(π − x)/(2π), while the same sum over a square diverges.
import Mathlib.NumberTheory.ZetaValues
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Analysis.PSeries

open Real

theorem hasSum_inv_succ_sq :
    HasSum (fun k : ℕ => 1 / ((k : ℝ) + 1) ^ 2) (π ^ 2 / 6) := by
  have h := (hasSum_nat_add_iff' 1).mpr hasSum_zeta_two
  simpa using h

theorem hasSum_cos_succ_div_sq {x : ℝ} (hx : x ∈ Set.Icc 0 π) :
    HasSum (fun k : ℕ => 1 / ((k : ℝ) + 1) ^ 2 * Real.cos (2 * (((k : ℝ) + 1) * x)))
      (π ^ 2 / 6 - π * x + x ^ 2) := by
  have hpi := Real.pi_pos
  have hx' : x / π ∈ Set.Icc (0 : ℝ) 1 := by
    obtain ⟨h0, h1⟩ := hx
    constructor
    · positivity
    · rw [div_le_one hpi]; exact h1
  have h := hasSum_one_div_nat_pow_mul_cos one_ne_zero hx'
  have h2 := (hasSum_nat_add_iff' 1).mpr h
  have hb : (Polynomial.map (algebraMap ℚ ℝ) (Polynomial.bernoulli (2 * 1))).eval (x / π)
      = (x / π) ^ 2 - x / π + 6⁻¹ := bernoulliFun_two (x / π)
  rw [hb] at h2
  convert h2 using 1
  · funext k
    push_cast
    congr 2
    field_simp
  · simp [Nat.factorial]
    field_simp
    ring

/-- On the rod (0, π) with ends held at 0, mode k (k = 1, 2, 3, …) of the stochastic heat
equation with noise strength σ is an Ornstein-Uhlenbeck process with pull k² and stationary
variance σ²/(2k²). These variances add up to a finite total: the sum over all modes is
π²σ²/12. -/
theorem stationary_mode_variances_sum_to_pi_sq_div_twelve (σ : ℝ) :
    HasSum (fun k : ℕ => σ ^ 2 / (2 * ((k : ℝ) + 1) ^ 2)) (π ^ 2 / 12 * σ ^ 2) := by
  convert hasSum_inv_succ_sq.mul_left (σ ^ 2 / 2) using 1
  · funext k
    field_simp
  · ring

/-- The stationary variance at a point x of the rod, the sum over modes of each mode's variance
σ²/(2k²) times the squared mode shape e_k(x)² = (√(2/π) sin(kx))², equals σ²x(π − x)/(2π). -/
theorem stationary_point_variance_eq (σ : ℝ) {x : ℝ} (hx : x ∈ Set.Icc 0 π) :
    HasSum
      (fun k : ℕ => σ ^ 2 / (2 * ((k : ℝ) + 1) ^ 2) *
        (Real.sqrt (2 / π) * Real.sin (((k : ℝ) + 1) * x)) ^ 2)
      (σ ^ 2 * x * (π - x) / (2 * π)) := by
  have hpi := Real.pi_pos
  have h := (hasSum_inv_succ_sq.sub (hasSum_cos_succ_div_sq hx)).mul_left (σ ^ 2 / (2 * π))
  convert h using 1
  · funext k
    rw [mul_pow, Real.sq_sqrt (by positivity), Real.sin_sq, Real.cos_sq]
    field_simp
    ring
  · field_simp
    ring

/-- On a square of side π held at 0 on all four edges, mode (j, k) (j, k = 1, 2, 3, …) has pull
j² + k² and stationary variance σ²/(2(j² + k²)). With nonzero noise these variances do not add
up to a finite total: their sum diverges. -/
theorem square_mode_variances_not_summable (σ : ℝ) (hσ : σ ≠ 0) :
    ¬ Summable (fun p : ℕ × ℕ =>
      σ ^ 2 / (2 * (((p.1 : ℝ) + 1) ^ 2 + ((p.2 : ℝ) + 1) ^ 2))) := by
  intro hs
  set f : ℕ × ℕ → ℝ := fun p => σ ^ 2 / (2 * (((p.1 : ℝ) + 1) ^ 2 + ((p.2 : ℝ) + 1) ^ 2))
    with hf
  have hσ2 : 0 < σ ^ 2 := by positivity
  have fnn : ∀ p, 0 ≤ f p := fun p => by positivity
  have key : ∀ N : ℕ, ∑ k ∈ Finset.range N, σ ^ 2 / 4 * (1 / ((k : ℝ) + 1)) ≤ ∑' p, f p := by
    intro N
    calc ∑ k ∈ Finset.range N, σ ^ 2 / 4 * (1 / ((k : ℝ) + 1))
        ≤ ∑ k ∈ Finset.range N, ∑ j ∈ Finset.range (k + 1), f (j, k) := by
          apply Finset.sum_le_sum
          intro k _
          have hle : ∀ j ∈ Finset.range (k + 1), σ ^ 2 / (4 * ((k : ℝ) + 1) ^ 2) ≤ f (j, k) := by
            intro j hj
            have hj' : (j : ℝ) ≤ k := by
              exact_mod_cast Nat.lt_succ_iff.mp (Finset.mem_range.mp hj)
            simp only [hf]
            apply div_le_div_of_nonneg_left hσ2.le (by positivity)
            have : ((j : ℝ) + 1) ^ 2 ≤ ((k : ℝ) + 1) ^ 2 := by
              gcongr
            nlinarith
          calc σ ^ 2 / 4 * (1 / ((k : ℝ) + 1))
              = ∑ j ∈ Finset.range (k + 1), σ ^ 2 / (4 * ((k : ℝ) + 1) ^ 2) := by
                rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
                push_cast
                field_simp
            _ ≤ _ := Finset.sum_le_sum hle
      _ ≤ ∑ k ∈ Finset.range N, ∑ j ∈ Finset.range N, f (j, k) := by
          apply Finset.sum_le_sum
          intro k hk
          apply Finset.sum_le_sum_of_subset_of_nonneg
          · intro j hj
            simp only [Finset.mem_range] at hj hk ⊢
            omega
          · intro i _ _; exact fnn _
      _ = ∑ p ∈ Finset.range N ×ˢ Finset.range N, f p := by
          rw [Finset.sum_product_right]
      _ ≤ ∑' p, f p := hs.sum_le_tsum _ (fun i _ => fnn i)
  have hsum : Summable (fun k : ℕ => σ ^ 2 / 4 * (1 / ((k : ℝ) + 1))) :=
    summable_of_sum_range_le (fun k => by positivity) key
  have h2 : Summable (fun k : ℕ => 1 / ((k : ℝ) + 1)) := by
    have := hsum.mul_left (4 / σ ^ 2)
    convert this using 1
    funext k
    field_simp
  have h3 : Summable (fun k : ℕ => 1 / ((k + 1 : ℕ) : ℝ)) := by
    simpa using h2
  exact Real.not_summable_one_div_natCast ((summable_nat_add_iff 1).mp h3)

/-- The card's table: modes 1, 2, 3 have pulls 1, 4, 9 and stationary variances 1/2, 1/8, 1/18
(noise strength 1). -/
example : (1 : ℕ) ^ 2 = 1 ∧ (2 : ℕ) ^ 2 = 4 ∧ (3 : ℕ) ^ 2 = 9 ∧ (4 : ℕ) ^ 2 = 16 ∧
    (5 : ℕ) ^ 2 = 25 := by decide

example : (1 : ℚ) / (2 * 1 ^ 2) = 1 / 2 ∧ (1 : ℚ) / (2 * 2 ^ 2) = 1 / 8 ∧
    (1 : ℚ) / (2 * 3 ^ 2) = 1 / 18 := by norm_num

/-- The first ten modes' variances add to 1968329/2540160 (the card's 0.774884). -/
example : ∑ k ∈ Finset.range 10, (1 : ℚ) / (2 * ((k : ℚ) + 1) ^ 2) = 1968329 / 2540160 := by
  norm_num [Finset.sum_range_succ]

/-- The point variance at the middle is π/8, and a quarter of the way along it is 3π/32. -/
example : (π / 2) * (π - π / 2) / (2 * π) = π / 8 := by
  have := Real.pi_pos
  field_simp
  ring

example : (π / 4) * (π - π / 4) / (2 * π) = 3 * π / 32 := by
  have := Real.pi_pos
  field_simp
  ring

#print axioms stationary_mode_variances_sum_to_pi_sq_div_twelve
#print axioms stationary_point_variance_eq
#print axioms square_mode_variances_not_summable
#print axioms hasSum_inv_succ_sq
#print axioms hasSum_cos_succ_div_sq
