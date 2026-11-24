-- Gaussian processes: for the Brownian kernel min(s, t) on one second, the waves sqrt 2 sin((j - 1/2) pi t) are unit eigenfunctions with eigenvalues 1/((j - 1/2) pi)^2, these eigenvalues add up to the total variance 1/2 so the first wave's share is 8/pi^2, and min(s, t) is a valid (positive semidefinite) kernel.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.NumberTheory.ZetaValues
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real

/-! The card's Karhunen-Loeve waves for Brownian motion on `[0, 1]`, numbered from `j = 1`:
the frequency is `ω_j = (j - 1/2) π`, the wave is `e_j(t) = √2 sin(ω_j t)` and the eigenvalue is
`λ_j = 1 / ω_j ^ 2`. The kernel is `k(s, t) = min s t`. -/

theorem odd_inv_sq_hasSum : HasSum (fun k : ℕ => (1 : ℝ) / ((2 * k + 1 : ℕ) : ℝ) ^ 2) (π ^ 2 / 8) := by
  have hz := hasSum_zeta_two
  have hinj : Function.Injective (fun k : ℕ => 2 * k + 1) := by
    intro a b h
    simp only at h
    omega
  have hs : Summable (fun k : ℕ => (1 : ℝ) / ((2 * k + 1 : ℕ) : ℝ) ^ 2) :=
    hz.summable.comp_injective hinj
  have he : HasSum (fun k : ℕ => (1 : ℝ) / ((2 * k : ℕ) : ℝ) ^ 2) (π ^ 2 / 24) := by
    have h4 := hz.mul_left (1 / 4)
    have hf : (fun k : ℕ => (1 : ℝ) / ((2 * k : ℕ) : ℝ) ^ 2) =
        fun k : ℕ => 1 / 4 * (1 / (k : ℝ) ^ 2) := by
      funext k; push_cast; ring
    rw [hf, show π ^ 2 / 24 = 1 / 4 * (π ^ 2 / 6) by ring]
    exact h4
  have htot := HasSum.even_add_odd (f := fun n : ℕ => (1 : ℝ) / (n : ℝ) ^ 2) he hs.hasSum
  have hu := htot.unique hz
  have hv : ∑' k : ℕ, (1 : ℝ) / ((2 * k + 1 : ℕ) : ℝ) ^ 2 = π ^ 2 / 8 := by linarith
  rw [← hv]
  exact hs.hasSum

#print axioms odd_inv_sq_hasSum

theorem min_quad_nonneg_aux {ι : Type*} [DecidableEq ι] (n : ℕ) :
    ∀ (s : Finset ι), s.card = n → ∀ (t : ι → ℝ), (∀ i ∈ s, 0 ≤ t i) → ∀ x : ι → ℝ,
      0 ≤ ∑ i ∈ s, ∑ j ∈ s, x i * x j * min (t i) (t j) := by
  induction n with
  | zero =>
    intro s hs t ht x
    rw [Finset.card_eq_zero.mp hs]
    simp
  | succ n ih =>
    intro s hs t ht x
    have hne : s.Nonempty := Finset.card_pos.mp (by omega)
    obtain ⟨i0, hi0, hmin⟩ := Finset.exists_min_image s t hne
    set m := t i0 with hm
    have hm0 : 0 ≤ m := ht i0 hi0
    set t' : ι → ℝ := fun i => t i - m with ht'
    have hsplit : ∀ i j, x i * x j * min (t i) (t j) =
        m * (x i * x j) + x i * x j * min (t' i) (t' j) := by
      intro i j
      simp only [ht', min_sub_sub_right]
      ring
    simp_rw [hsplit, Finset.sum_add_distrib]
    have h1 : ∑ i ∈ s, ∑ j ∈ s, m * (x i * x j) = m * (∑ i ∈ s, x i) ^ 2 := by
      rw [sq, Finset.sum_mul_sum, Finset.mul_sum]
      simp_rw [Finset.mul_sum]
    have h2 : ∑ i ∈ s, ∑ j ∈ s, x i * x j * min (t' i) (t' j) =
        ∑ i ∈ s.erase i0, ∑ j ∈ s.erase i0, x i * x j * min (t' i) (t' j) := by
      have hz : ∀ i ∈ s, min (t' i) (t' i0) = 0 ∧ min (t' i0) (t' i) = 0 := by
        intro i hi
        have : 0 ≤ t' i := by simp only [ht']; linarith [hmin i hi]
        have h0 : t' i0 = 0 := by simp [ht', hm]
        rw [h0]
        exact ⟨min_eq_right this, min_eq_left this⟩
      rw [← Finset.sum_erase s (a := i0)]
      · apply Finset.sum_congr rfl
        intro i hi
        rw [← Finset.sum_erase s (a := i0)]
        rw [(hz i (Finset.mem_of_mem_erase hi)).1, mul_zero]
      · apply Finset.sum_eq_zero
        intro j hj
        rw [(hz j hj).2, mul_zero]
    rw [h1, h2]
    have hcard : (s.erase i0).card = n := by
      rw [Finset.card_erase_of_mem hi0]; omega
    have := ih (s.erase i0) hcard t' (by
      intro i hi
      simp only [ht']
      linarith [hmin i (Finset.mem_of_mem_erase hi)]) x
    positivity

#print axioms min_quad_nonneg_aux

/-- Karhunen-Loeve waves of Brownian motion: for every `j ≥ 1` and every time `t` in `[0, 1]`,
feeding the wave `e_j(s) = √2 sin((j - 1/2) π s)` through the kernel `min(s, t)` gives back the
same wave scaled by `λ_j = 1 / ((j - 1/2) π)^2`, and the wave has total square 1 over the
second. -/
theorem brownian_karhunen_loeve_eigenfunction (j : ℕ) (hj : 1 ≤ j) (t : ℝ)
    (ht : t ∈ Set.Icc (0 : ℝ) 1) :
    (∫ s in (0 : ℝ)..1, min s t * (√2 * sin (((j : ℝ) - 1 / 2) * π * s))) =
        1 / (((j : ℝ) - 1 / 2) * π) ^ 2 * (√2 * sin (((j : ℝ) - 1 / 2) * π * t)) ∧
      (∫ s in (0 : ℝ)..1, (√2 * sin (((j : ℝ) - 1 / 2) * π * s)) ^ 2) = 1 := by
  set ω : ℝ := ((j : ℝ) - 1 / 2) * π with hω
  have hj' : (1 : ℝ) ≤ j := by exact_mod_cast hj
  have hωpos : 0 < ω := by
    rw [hω]; exact mul_pos (by linarith) Real.pi_pos
  have hω0 : ω ≠ 0 := hωpos.ne'
  have hcos : cos ω = 0 := by
    have : ω = ((j - 1 : ℕ) : ℝ) * π + π / 2 := by
      rw [hω, Nat.cast_sub hj]; push_cast; ring
    rw [this, Real.cos_add_pi_div_two, Real.sin_nat_mul_pi, neg_zero]
  have hsin : ∀ s : ℝ, HasDerivAt (fun x => sin (ω * x)) (cos (ω * s) * ω) s := by
    intro s
    have := ((hasDerivAt_id' s).const_mul ω).sin
    simpa using this
  have hcosd : ∀ s : ℝ, HasDerivAt (fun x => cos (ω * x)) (-sin (ω * s) * ω) s := by
    intro s
    have := ((hasDerivAt_id' s).const_mul ω).cos
    simpa using this
  have hs2 : (√2) ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  refine ⟨?_, ?_⟩
  · obtain ⟨ht0, ht1⟩ := ht
    have hcont : Continuous (fun s => min s t * (√2 * sin (ω * s))) := by fun_prop
    rw [← intervalIntegral.integral_add_adjacent_intervals (b := t)
      (hcont.intervalIntegrable _ _) (hcont.intervalIntegrable _ _)]
    have e1 : (∫ s in (0 : ℝ)..t, min s t * (√2 * sin (ω * s))) =
        ∫ s in (0 : ℝ)..t, s * (√2 * sin (ω * s)) := by
      apply intervalIntegral.integral_congr
      intro s hs
      rw [Set.uIcc_of_le ht0] at hs
      simp only
      rw [min_eq_left hs.2]
    have e2 : (∫ s in t..1, min s t * (√2 * sin (ω * s))) =
        ∫ s in t..1, t * (√2 * sin (ω * s)) := by
      apply intervalIntegral.integral_congr
      intro s hs
      rw [Set.uIcc_of_le ht1] at hs
      simp only
      rw [min_eq_right hs.1]
    rw [e1, e2]
    have F1 : ∀ s : ℝ, HasDerivAt (fun x => √2 * (sin (ω * x) / ω ^ 2 - x * cos (ω * x) / ω))
        (s * (√2 * sin (ω * s))) s := by
      intro s
      have := (((hsin s).div_const (ω ^ 2)).sub (((hasDerivAt_id' s).mul (hcosd s)).div_const ω)).const_mul √2
      convert this using 1
      field_simp
      ring
    have F2 : ∀ s : ℝ, HasDerivAt (fun x => -(t * √2) * (cos (ω * x) / ω))
        (t * (√2 * sin (ω * s))) s := by
      intro s
      have := ((hcosd s).div_const ω).const_mul (-(t * √2))
      convert this using 1
      field_simp
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun s _ => F1 s) (by
        apply Continuous.intervalIntegrable; fun_prop),
      intervalIntegral.integral_eq_sub_of_hasDerivAt (fun s _ => F2 s) (by
        apply Continuous.intervalIntegrable; fun_prop)]
    simp only [mul_one, mul_zero, sin_zero, cos_zero, hcos]
    field_simp
    ring
  · have F3 : ∀ s : ℝ, HasDerivAt (fun x => x - sin (ω * x) * cos (ω * x) / ω)
        ((√2 * sin (ω * s)) ^ 2) s := by
      intro s
      have := (hasDerivAt_id' s).sub (((hsin s).mul (hcosd s)).div_const ω)
      convert this using 1
      have hpy := sin_sq_add_cos_sq (ω * s)
      rw [mul_pow, hs2]
      field_simp
      linear_combination hpy
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun s _ => F3 s) (by
        apply Continuous.intervalIntegrable; fun_prop)]
    simp [hcos]

/-- The eigenvalues share out the total variance: `λ_1 + λ_2 + ⋯ = ∫₀¹ t dt = 1/2`, where
`λ_j = 1 / ((j - 1/2) π)^2` (written here with `j + 1` for `j = 0, 1, 2, …`), and the first
wave's share of that total is `λ_1 / (1/2) = 8 / π^2`. -/
theorem brownian_eigenvalues_sum_to_half :
    HasSum (fun j : ℕ => 1 / ((((j + 1 : ℕ) : ℝ) - 1 / 2) * π) ^ 2) (∫ t in (0 : ℝ)..1, t) ∧
      (∫ t in (0 : ℝ)..1, t) = 1 / 2 ∧
      (1 / (((1 : ℝ) - 1 / 2) * π) ^ 2) / (1 / 2) = 8 / π ^ 2 := by
  have hi : (∫ t in (0 : ℝ)..1, t) = 1 / 2 := by
    rw [integral_id]; norm_num
  have hpi : π ≠ 0 := Real.pi_ne_zero
  refine ⟨?_, hi, ?_⟩
  · rw [hi]
    have h := odd_inv_sq_hasSum.mul_left (4 / π ^ 2)
    have hf : (fun j : ℕ => 1 / ((((j + 1 : ℕ) : ℝ) - 1 / 2) * π) ^ 2) =
        fun k : ℕ => 4 / π ^ 2 * (1 / ((2 * k + 1 : ℕ) : ℝ) ^ 2) := by
      funext k
      have hk : (2 * (k : ℝ) + 1) ≠ 0 := by positivity
      have hc : (((k + 1 : ℕ) : ℝ) - 1 / 2) = (2 * (k : ℝ) + 1) / 2 := by push_cast; ring
      rw [hc]
      push_cast
      field_simp
      ring
    rw [hf, show (1 / 2 : ℝ) = 4 / π ^ 2 * (π ^ 2 / 8) by field_simp; ring]
    exact h
  · field_simp; ring

/-- `min(s, t)` is a valid covariance kernel: at any list of times `t_1, …, t_n ≥ 0` the matrix
`K_ij = min(t_i, t_j)` is symmetric and positive semidefinite, so no weighted mix of the values
of Brownian motion gets a negative variance. -/
theorem min_kernel_posSemidef (n : ℕ) (t : Fin n → ℝ) (ht : ∀ i, 0 ≤ t i) :
    (Matrix.of fun i j => min (t i) (t j)).PosSemidef := by
  rw [Matrix.posSemidef_iff_dotProduct_mulVec]
  refine ⟨?_, ?_⟩
  · ext i j
    simp [Matrix.conjTranspose_apply, min_comm]
  · intro x
    have := min_quad_nonneg_aux n Finset.univ (by simp) t (fun i _ => ht i) x
    simp only [star_trivial, dotProduct, Matrix.mulVec, Matrix.of_apply, Finset.mul_sum]
    refine this.trans_eq (Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_)
    ring

/-! Whole-number checks from the card. -/

/-- The Cholesky factor of `min(i, j)` at times 1, 2, 3, 4 s is the triangle of ones. -/
example :
    (Matrix.of fun i j : Fin 4 => if j ≤ i then (1 : ℤ) else 0) *
        (Matrix.of fun i j : Fin 4 => if j ≤ i then (1 : ℤ) else 0).transpose =
      Matrix.of fun i j : Fin 4 => min ((i : ℤ) + 1) ((j : ℤ) + 1) := by
  decide

/-- `max(s, t)` fails: weights −1 and 1 at 1 s and 2 s give `1 + 2 - 2 × 2 = -1`. -/
example :
    (∑ i : Fin 2, ∑ j : Fin 2, ![(-1 : ℤ), 1] i * ![(-1 : ℤ), 1] j * max (![(1 : ℤ), 2] i) (![(1 : ℤ), 2] j)) = -1 := by
  decide

/-- With `min(s, t)` the same mix has variance `1 + 2 - 2 × 1 = 1`, which is fine. -/
example :
    (∑ i : Fin 2, ∑ j : Fin 2, ![(-1 : ℤ), 1] i * ![(-1 : ℤ), 1] j * min (![(1 : ℤ), 2] i) (![(1 : ℤ), 2] j)) = 1 := by
  decide

#print axioms brownian_karhunen_loeve_eigenfunction
#print axioms brownian_eigenvalues_sum_to_half
#print axioms min_kernel_posSemidef
