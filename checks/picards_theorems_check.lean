-- Picard's theorems are not in Mathlib yet, so this file proves the card's examples exactly: e^z = −1 exactly at z = iπ(2k + 1), e^(1/z) = −1 exactly at z_k = 1/(iπ(2k + 1)), e^(1/z) takes every nonzero value infinitely often in every punctured disc round 0 and never takes 0, e^z misses only 0, tan misses i and −i, and a nonconstant polynomial misses nothing.
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Analysis.Complex.Polynomial.Basic

open Complex Polynomial
open scoped Real

/-- e^z = −1 exactly when z = iπ(2k + 1) for a whole number k: one solution per whole turn. -/
theorem exp_eq_neg_one_iff (z : ℂ) : exp z = -1 ↔ ∃ k : ℤ, z = π * I * (2 * k + 1) := by
  rw [← exp_pi_mul_I, exp_eq_exp_iff_exists_int]
  constructor
  · rintro ⟨k, hk⟩
    exact ⟨k, by rw [hk]; ring⟩
  · rintro ⟨k, rfl⟩
    exact ⟨k, by ring⟩

/-- e^(1/z) = −1 exactly at z_k = 1/(iπ(2k + 1)), one point for each whole number k. -/
theorem exp_inv_eq_neg_one_iff (z : ℂ) : exp z⁻¹ = -1 ↔ ∃ k : ℤ, z = (π * I * (2 * k + 1))⁻¹ := by
  rw [exp_eq_neg_one_iff]
  constructor
  · rintro ⟨k, hk⟩
    exact ⟨k, by rw [← hk, inv_inv]⟩
  · rintro ⟨k, rfl⟩
    exact ⟨k, inv_inv _⟩

/-- e^(1/z) never equals 0: the one value it misses. -/
theorem exp_inv_ne_zero (z : ℂ) : exp z⁻¹ ≠ 0 := exp_ne_zero _

/-- Great Picard for e^(1/z): every nonzero value w is taken infinitely often in the punctured
disc 0 < |z| < r, however small r is. -/
theorem exp_inv_takes_value_infinitely_often {w : ℂ} (hw : w ≠ 0) {r : ℝ} (hr : 0 < r) :
    {z : ℂ | 0 < ‖z‖ ∧ ‖z‖ < r ∧ exp z⁻¹ = w}.Infinite := by
  obtain ⟨K, hK⟩ := exists_nat_gt ((‖log w‖ + r⁻¹) / (2 * π))
  set u : ℕ → ℂ := fun n => log w + ((n + K : ℕ) : ℂ) * (2 * π * I) with hu
  have hbig : ∀ n, r⁻¹ < ‖u n‖ := by
    intro n
    have h2 : ‖((n + K : ℕ) : ℂ) * (2 * π * I)‖ = (n + K : ℕ) * (2 * π) := by
      rw [norm_mul, Complex.norm_natCast, norm_mul, norm_mul, Complex.norm_I, Complex.norm_real,
        Complex.norm_ofNat, Real.norm_of_nonneg Real.pi_pos.le, mul_one]
    have h3 : ‖((n + K : ℕ) : ℂ) * (2 * π * I)‖ ≤ ‖u n‖ + ‖log w‖ := by
      have := norm_sub_le (u n) (log w)
      simpa [hu] using this
    have h4 : (K : ℝ) * (2 * π) ≤ (n + K : ℕ) * (2 * π) := by
      have : (K : ℝ) ≤ (n + K : ℕ) := by exact_mod_cast Nat.le_add_left K n
      nlinarith [Real.pi_pos]
    have h5 : ‖log w‖ + r⁻¹ < K * (2 * π) := by
      rwa [div_lt_iff₀ (by positivity)] at hK
    linarith
  have hne : ∀ n, u n ≠ 0 := by
    intro n h
    have := hbig n
    rw [h, norm_zero] at this
    exact absurd this (not_lt.2 (inv_pos.2 hr).le)
  have hinj : Function.Injective (fun n => (u n)⁻¹) := by
    intro n m h
    have h1 : u n = u m := inv_injective h
    simp only [hu, add_right_inj] at h1
    have h2 : ((n + K : ℕ) : ℂ) = ((m + K : ℕ) : ℂ) :=
      mul_right_cancel₀ (by simp [Real.pi_ne_zero, I_ne_zero]) h1
    have h3 : n + K = m + K := by exact_mod_cast h2
    omega
  refine Set.infinite_of_injective_forall_mem hinj fun n => ?_
  refine ⟨?_, ?_, ?_⟩
  · simpa using hne n
  · rw [norm_inv]
    exact inv_lt_of_inv_lt₀ hr (hbig n)
  · simp only [inv_inv, hu, exp_add, exp_log hw, exp_nat_mul_two_pi_mul_I, mul_one]

/-- e^z misses only 0: it takes the value w exactly when w ≠ 0. -/
theorem exp_misses_only_zero (w : ℂ) : (∃ z, exp z = w) ↔ w ≠ 0 :=
  ⟨by rintro ⟨z, rfl⟩; exact exp_ne_zero z, fun hw => ⟨log w, exp_log hw⟩⟩

/-- tan misses both i and −i, so tan (holomorphic except at its poles) misses two values. -/
theorem tan_misses_I_and_neg_I (z : ℂ) : tan z ≠ I ∧ tan z ≠ -I := by
  rw [tan]
  by_cases hc : cos z = 0
  · rw [hc, div_zero]
    exact ⟨I_ne_zero.symm, (neg_ne_zero.2 I_ne_zero).symm⟩
  constructor
  · intro h
    have hs : sin z = I * cos z := by rw [div_eq_iff hc] at h; exact h
    exact exp_ne_zero (z * I) (by linear_combination exp_mul_I z + I * hs + cos z * I_sq)
  · intro h
    have hs : sin z = -I * cos z := by rw [div_eq_iff hc] at h; exact h
    have he := exp_mul_I (-z)
    rw [cos_neg, sin_neg] at he
    exact exp_ne_zero (-z * I) (by linear_combination he - I * hs + cos z * I_sq)

/-- A nonconstant polynomial misses nothing: p(z) = w has a root for every w. -/
theorem polynomial_misses_nothing (p : ℂ[X]) (hp : 0 < p.degree) (w : ℂ) : ∃ z, p.eval z = w := by
  obtain ⟨z, hz⟩ := Complex.exists_root (f := p - C w) (by rwa [degree_sub_C hp])
  exact ⟨z, by simpa [sub_eq_zero] using hz⟩

/-- z^2 misses nothing, and z^2 = −1 at z = i and z = −i. -/
theorem sq_misses_nothing (w : ℂ) : (∃ z : ℂ, z ^ 2 = w) ∧ I ^ 2 = -1 ∧ (-I) ^ 2 = -1 := by
  refine ⟨?_, I_sq, by rw [neg_sq, I_sq]⟩
  obtain ⟨z, hz⟩ := polynomial_misses_nothing (X ^ 2) (by simp) w
  exact ⟨z, by simpa using hz⟩

#print axioms exp_eq_neg_one_iff
#print axioms exp_inv_eq_neg_one_iff
#print axioms exp_inv_ne_zero
#print axioms exp_inv_takes_value_infinitely_often
#print axioms exp_misses_only_zero
#print axioms tan_misses_I_and_neg_I
#print axioms polynomial_misses_nothing
#print axioms sq_misses_nothing
