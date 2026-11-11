-- The gamma function: Euler's integral, continued by its recurrence, is holomorphic off 0, -1, -2, ... with simple poles of residue (-1)^n/n! there, and satisfies Γ(z+1) = zΓ(z), Γ(n+1) = n!, Γ(1/2) = √π and the reflection formula.
import Mathlib.Analysis.SpecialFunctions.Gamma.Beta
import Mathlib.Analysis.SpecialFunctions.Gamma.Deriv
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.Normed.Module.Connected
import Mathlib.LinearAlgebra.Complex.FiniteDimensional

open Complex Filter Topology MeasureTheory Set
open scoped Nat


/-- Euler's integral form of gamma for positive real part. -/
theorem gammaAux_integral (z : ℂ) (hz : 0 < z.re) :
    Gamma z = ∫ t in Ioi (0 : ℝ), (t : ℂ) ^ (z - 1) * Complex.exp (-(t : ℂ)) := by
  rw [Gamma_eq_integral hz, GammaIntegral]
  refine setIntegral_congr_fun measurableSet_Ioi fun t _ => ?_
  push_cast
  ring

/-- The recurrence run backwards m times. -/
theorem gammaAux_prod (m : ℕ) (z : ℂ) (hz : ∀ k : ℕ, k < m → z ≠ -(k : ℂ)) :
    Gamma z * ∏ k ∈ Finset.range m, (z + k) = Gamma (z + m) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [Finset.prod_range_succ, ← mul_assoc, ih (fun k hk => hz k (by omega))]
    have hne : z + m ≠ 0 := by
      intro h
      apply hz m (by omega)
      linear_combination h
    rw [mul_comm, ← Gamma_add_one _ hne]
    push_cast
    ring_nf

/-- The product (-n)(-n+1)⋯(-1) equals (-1)^n n!. -/
theorem gammaAux_prod_neg (n : ℕ) :
    ∏ k ∈ Finset.range n, (-(n : ℂ) + k) = (-1) ^ n * (n ! : ℂ) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.prod_range_succ']
    have : ∏ k ∈ Finset.range n, (-((n + 1 : ℕ) : ℂ) + ((k + 1 : ℕ) : ℂ)) =
        ∏ k ∈ Finset.range n, (-(n : ℂ) + k) := by
      refine Finset.prod_congr rfl fun k _ => ?_
      push_cast
      ring
    rw [this, ih, Nat.factorial_succ]
    push_cast
    ring

/-- Euler's integral defines gamma where the real part is positive. The recurrence, run
backwards m times, continues it to Re z > -m:
Γ(z) = (Euler's integral at z + m) / (z (z+1) ⋯ (z+m-1)) for z off 0, -1, ..., -(m-1).
The continued gamma is holomorphic on the whole plane except 0, -1, -2, ...; at each -n it has
a simple pole with residue (-1)^n/n!; and any other holomorphic extension of the integral to
that region equals it. -/
theorem euler_integral_continues_to_plane_with_simple_poles :
    (∀ z : ℂ, 0 < z.re →
      Gamma z = ∫ t in Ioi (0 : ℝ), (t : ℂ) ^ (z - 1) * Complex.exp (-(t : ℂ))) ∧
    (∀ m : ℕ, 1 ≤ m → ∀ z : ℂ, -(m : ℝ) < z.re → (∀ k : ℕ, k < m → z ≠ -(k : ℂ)) →
      Gamma z = (∫ t in Ioi (0 : ℝ), (t : ℂ) ^ (z + m - 1) * Complex.exp (-(t : ℂ))) /
        ∏ k ∈ Finset.range m, (z + k)) ∧
    (∀ z : ℂ, (∀ n : ℕ, z ≠ -(n : ℂ)) → DifferentiableAt ℂ Gamma z) ∧
    (∀ n : ℕ, Tendsto (fun z : ℂ => (z + n) * Gamma z) (𝓝[≠] (-(n : ℂ)))
      (𝓝 ((-1 : ℂ) ^ n / (n ! : ℂ)))) ∧
    (∀ F : ℂ → ℂ, DifferentiableOn ℂ F {z : ℂ | ∀ n : ℕ, z ≠ -(n : ℂ)} →
      (∀ z : ℂ, 0 < z.re →
        F z = ∫ t in Ioi (0 : ℝ), (t : ℂ) ^ (z - 1) * Complex.exp (-(t : ℂ))) →
      ∀ z : ℂ, (∀ n : ℕ, z ≠ -(n : ℂ)) → F z = Gamma z) := by
  refine ⟨gammaAux_integral, ?_, ?_, ?_, ?_⟩
  · intro m _ z hre hz
    have hprod : ∏ k ∈ Finset.range m, (z + k) ≠ 0 := by
      rw [Finset.prod_ne_zero_iff]
      intro k hk h
      exact hz k (Finset.mem_range.1 hk) (by linear_combination h)
    rw [← gammaAux_integral (z + m) (by simp; linarith), ← gammaAux_prod m z hz]
    field_simp
  · intro z hz
    exact differentiableAt_Gamma z hz
  · intro n
    have hev : (fun z : ℂ => (z + n) * Gamma z) =ᶠ[𝓝[≠] (-(n : ℂ))]
        (fun z : ℂ => Gamma (z + ((n + 1 : ℕ) : ℂ)) / ∏ k ∈ Finset.range n, (z + k)) := by
      have h1 : ∀ᶠ z in 𝓝 (-(n : ℂ)), ∀ k ∈ Finset.range n, z ≠ -(k : ℂ) := by
        rw [Filter.eventually_all_finset]
        intro k hk
        apply eventually_ne_nhds
        intro h
        have h2 : n = k := by exact_mod_cast neg_inj.1 h
        have := Finset.mem_range.1 hk
        omega
      filter_upwards [nhdsWithin_le_nhds h1, self_mem_nhdsWithin] with z hz hzn
      have hall : ∀ k : ℕ, k < n + 1 → z ≠ -(k : ℂ) := by
        intro k hk
        rcases Nat.lt_succ_iff_lt_or_eq.1 hk with h | h
        · exact hz k (Finset.mem_range.2 h)
        · subst h; exact hzn
      have hprod : ∏ k ∈ Finset.range n, (z + k) ≠ 0 := by
        rw [Finset.prod_ne_zero_iff]
        intro k hk h
        exact hz k hk (by linear_combination h)
      rw [← gammaAux_prod (n + 1) z hall, Finset.prod_range_succ]
      field_simp
    refine Tendsto.congr' hev.symm ?_
    apply tendsto_nhdsWithin_of_tendsto_nhds
    have hc : ContinuousAt (fun z : ℂ => Gamma (z + ((n + 1 : ℕ) : ℂ)) /
        ∏ k ∈ Finset.range n, (z + k)) (-(n : ℂ)) := by
      apply ContinuousAt.div
      · apply ContinuousAt.comp (g := Gamma)
        · have : -(n : ℂ) + ((n + 1 : ℕ) : ℂ) = 1 := by push_cast; ring
          rw [this]
          exact differentiableAt_Gamma_one.continuousAt
        · exact (continuous_id.add continuous_const).continuousAt
      · fun_prop
      · rw [gammaAux_prod_neg]
        exact mul_ne_zero (pow_ne_zero _ (by norm_num)) (by exact_mod_cast n.factorial_ne_zero)
    have hv : Gamma (-(n : ℂ) + ((n + 1 : ℕ) : ℂ)) / ∏ k ∈ Finset.range n, (-(n : ℂ) + k) =
        (-1 : ℂ) ^ n / (n ! : ℂ) := by
      have : -(n : ℂ) + ((n + 1 : ℕ) : ℂ) = 1 := by push_cast; ring
      rw [this, Gamma_one, gammaAux_prod_neg]
      have hf : (n ! : ℂ) ≠ 0 := by exact_mod_cast n.factorial_ne_zero
      have hs : ((-1 : ℂ) ^ n) * (-1) ^ n = 1 := by
        rw [← mul_pow]; norm_num
      rw [div_eq_div_iff (mul_ne_zero (pow_ne_zero _ (by norm_num)) hf) hf]
      linear_combination -(n ! : ℂ) * hs
    rw [← hv]
    exact hc.tendsto
  · intro F hF hFint z hz
    set U : Set ℂ := {z : ℂ | ∀ n : ℕ, z ≠ -(n : ℂ)} with hUdef
    have hUeq : U = {z : ℂ | (Gamma z)⁻¹ ≠ 0} := by
      ext w
      simp [hUdef, Gamma_eq_zero_iff]
    have hUo : IsOpen U := by
      rw [hUeq]
      exact isOpen_ne_fun differentiable_one_div_Gamma.continuous continuous_const
    have hUc : IsPreconnected U := by
      have : U = (Set.range fun n : ℕ => -(n : ℂ))ᶜ := by
        ext w
        simp [hUdef, eq_comm]
      rw [this]
      exact ((countable_range _).isConnected_compl_of_one_lt_rank
        (by rw [Complex.rank_real_complex]; norm_num)).isPreconnected
    have hGd : DifferentiableOn ℂ Gamma U := fun w hw =>
      (differentiableAt_Gamma w hw).differentiableWithinAt
    have h1 : (1 : ℂ) ∈ U := by
      intro n h
      have := congrArg Complex.re h
      simp at this
      have : (0 : ℝ) ≤ n := n.cast_nonneg
      linarith
    have hev : F =ᶠ[𝓝 (1 : ℂ)] Gamma := by
      have hopen : IsOpen {w : ℂ | 0 < w.re} := isOpen_lt continuous_const continuous_re
      filter_upwards [hopen.mem_nhds (by simp : (0 : ℝ) < (1 : ℂ).re)] with w hw
      rw [hFint w hw, gammaAux_integral w hw]
    exact (hF.analyticOnNhd hUo).eqOn_of_preconnected_of_eventuallyEq (hGd.analyticOnNhd hUo)
      hUc h1 hev hz

/-- For Re z > 0, Γ(z + 1) = z Γ(z); so Γ(n + 1) = n! for every whole number n; and
Γ(1/2) = √π. -/
theorem gamma_recurrence_factorial_and_half :
    (∀ z : ℂ, 0 < z.re → Gamma (z + 1) = z * Gamma z) ∧
    (∀ n : ℕ, Gamma (n + 1) = (n ! : ℂ)) ∧
    Gamma (1 / 2) = (Real.sqrt Real.pi : ℂ) := by
  refine ⟨?_, ?_, ?_⟩
  · intro z hz
    have : z ≠ 0 := by
      rintro rfl
      simp at hz
    exact Gamma_add_one z this
  · intro n
    exact Gamma_nat_eq_factorial n
  · rw [show (1 / 2 : ℂ) = ((1 / 2 : ℝ) : ℂ) by push_cast; ring, Gamma_ofReal,
      Real.Gamma_one_half_eq]

/-- Reflection: for z off the whole numbers, Γ(z) Γ(1 - z) = π / sin(πz); so gamma has no
zeros off its poles. -/
theorem gamma_reflection_and_no_zeros :
    (∀ z : ℂ, (∀ n : ℤ, z ≠ (n : ℂ)) →
      Gamma z * Gamma (1 - z) = (Real.pi : ℂ) / Complex.sin (Real.pi * z)) ∧
    (∀ z : ℂ, (∀ n : ℕ, z ≠ -(n : ℂ)) → Gamma z ≠ 0) := by
  exact ⟨fun z _ => Gamma_mul_Gamma_one_sub z, fun z hz => Gamma_ne_zero hz⟩

-- The card's worked numbers, exactly.
example : Gamma 5 = 24 := by
  rw [show (5 : ℂ) = ((4 : ℕ) : ℂ) + 1 by norm_num, Gamma_nat_eq_factorial]
  norm_num [Nat.factorial]
example : (4 ! : ℕ) = 24 := by decide
example : (5 ! : ℕ) = 120 := by decide
example : Real.Gamma (5 / 2) = 3 * Real.sqrt Real.pi / 4 := by
  rw [show (5 / 2 : ℝ) = 1 / 2 + 1 + 1 by norm_num, Real.Gamma_add_one (by norm_num),
    Real.Gamma_add_one (by norm_num), Real.Gamma_one_half_eq]
  ring
example : Real.Gamma (-1 / 2) = -2 * Real.sqrt Real.pi := by
  have h := Real.Gamma_add_one (s := -1 / 2) (by norm_num)
  rw [show (-1 / 2 : ℝ) + 1 = 1 / 2 by norm_num, Real.Gamma_one_half_eq] at h
  linarith
example : Real.pi ^ ((3 : ℝ) / 2) / Real.Gamma (3 / 2 + 1) = 4 * Real.pi / 3 := by
  have hg : Real.Gamma (3 / 2 + 1) = 3 * Real.sqrt Real.pi / 4 := by
    rw [show (3 / 2 + 1 : ℝ) = 1 / 2 + 1 + 1 by norm_num, Real.Gamma_add_one (by norm_num),
      Real.Gamma_add_one (by norm_num), Real.Gamma_one_half_eq]
    ring
  have hp : Real.pi ^ ((3 : ℝ) / 2) = Real.pi * Real.sqrt Real.pi := by
    rw [show (3 : ℝ) / 2 = 1 + 1 / 2 by norm_num, Real.rpow_add Real.pi_pos, Real.rpow_one,
      Real.sqrt_eq_rpow]
  have hs : 0 < Real.sqrt Real.pi := Real.sqrt_pos.2 Real.pi_pos
  rw [hg, hp]
  field_simp
example : ((-1 : ℚ) ^ 0 / (0 ! : ℚ), (-1 : ℚ) ^ 1 / (1 ! : ℚ), (-1 : ℚ) ^ 2 / (2 ! : ℚ),
    (-1 : ℚ) ^ 3 / (3 ! : ℚ)) = (1, -1, 1 / 2, -1 / 6) := by norm_num [Nat.factorial]

#print axioms gammaAux_integral
#print axioms gammaAux_prod
#print axioms gammaAux_prod_neg
#print axioms euler_integral_continues_to_plane_with_simple_poles
#print axioms gamma_recurrence_factorial_and_half
#print axioms gamma_reflection_and_no_zeros
