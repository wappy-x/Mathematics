-- Fourier coefficients: the waves e^(inx) are orthonormal for the inner product (1/2π) ∫ f ḡ over one cycle, so the coefficient of a finite sum of waves reads off exactly that wave's share, and the 25% pulse has coefficients -1/2 at n = 0 and (1 - e^(-iπn/2))/(iπn) otherwise.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory Complex Real

/-! Conventions, as on the card.
* One cycle is `-π ≤ x ≤ π`; the wave that turns `n` times per cycle is `e_n(x) = e^(inx)`.
* Inner product on the circle: `⟨f, g⟩ = (1/(2π)) ∫ f(x) * conj (g x) dx` over `[-π, π]`.
* Fourier coefficient: `f̂(n) = ⟨f, e_n⟩ = (1/(2π)) ∫ f(x) e^(-inx) dx`.
* The 25% pulse is `+1` for `0 ≤ x < π/2` and `-1` on the rest of the cycle. -/


/-- Helper: `e^(kπi) = e^(-kπi)` for every whole number `k`. -/
lemma fourier_exp_int_pi_symm (k : ℤ) :
    cexp ((k : ℂ) * I * π) = cexp ((k : ℂ) * I * (-π : ℝ)) := by
  have h := exp_int_mul_two_pi_mul_I k
  rw [show (k : ℂ) * I * π = (k : ℂ) * I * ((-π : ℝ) : ℂ) + k * (2 * π * I) by push_cast; ring,
    Complex.exp_add, h, mul_one]

/-- Helper: `∫_{-π}^{π} e^(ikx) dx` is `2π` when `k = 0` and `0` otherwise. -/
lemma fourier_integral_exp_int (k : ℤ) :
    (∫ x in (-π)..π, cexp ((k : ℂ) * x * I)) = if k = 0 then (2 * π : ℂ) else 0 := by
  split_ifs with hk
  · subst hk
    simp only [Int.cast_zero, zero_mul, Complex.exp_zero, intervalIntegral.integral_const,
      sub_neg_eq_add, real_smul]
    push_cast; ring
  · have hc : (k : ℂ) * I ≠ 0 := mul_ne_zero (by exact_mod_cast hk) I_ne_zero
    have := integral_exp_mul_complex (a := -π) (b := π) hc
    simp only [mul_right_comm _ _ I] at this ⊢
    rw [this, fourier_exp_int_pi_symm, sub_self, zero_div]

/-- Helper: a wave times the conjugate of another is the wave of the difference. -/
lemma fourier_wave_mul_conj (m n : ℤ) (x : ℝ) :
    cexp ((m : ℂ) * x * I) * (starRingEnd ℂ) (cexp ((n : ℂ) * x * I)) =
      cexp (((m - n : ℤ) : ℂ) * x * I) := by
  rw [← Complex.exp_conj, ← Complex.exp_add]
  congr 1
  simp only [map_mul, map_intCast, Complex.conj_ofReal, Complex.conj_I]
  push_cast; ring

/-- Isolation: if a signal is a finite sum of waves, `g = Σ_{m ∈ s} c_m e^(imx)`, then its inner
product with the wave `e_n` over one cycle, `(1/(2π)) ∫ g(x) conj(e^(inx)) dx`, is exactly the
share `c_n` of that wave (and `0` if `e_n` is not in the sum): every other wave contributes 0. -/
theorem inner_product_reads_off_share (s : Finset ℤ) (c : ℤ → ℂ) (n : ℤ) :
    (1 / (2 * π) * ∫ x in (-π)..π,
        (∑ m ∈ s, c m * cexp ((m : ℂ) * x * I)) * (starRingEnd ℂ) (cexp ((n : ℂ) * x * I))) =
      if n ∈ s then c n else 0 := by
  have hint : ∀ m ∈ s, IntervalIntegrable
      (fun x : ℝ => c m * cexp (((m - n : ℤ) : ℂ) * x * I)) volume (-π) π := by
    intro m _
    apply Continuous.intervalIntegrable
    fun_prop
  have hfun : (fun x : ℝ => (∑ m ∈ s, c m * cexp ((m : ℂ) * x * I)) *
      (starRingEnd ℂ) (cexp ((n : ℂ) * x * I))) =
      fun x : ℝ => ∑ m ∈ s, c m * cexp (((m - n : ℤ) : ℂ) * x * I) := by
    funext x
    rw [Finset.sum_mul]
    refine Finset.sum_congr rfl fun m _ => ?_
    rw [mul_assoc, fourier_wave_mul_conj]
  rw [hfun]
  rw [intervalIntegral.integral_finsetSum hint]
  simp_rw [intervalIntegral.integral_const_mul, fourier_integral_exp_int, sub_eq_zero,
    mul_ite, mul_zero]
  rw [Finset.sum_ite_eq']
  have hpi : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  split_ifs
  · field_simp
  · simp

/-- Orthonormality: for whole numbers `m` and `n`, the inner product of the waves `e^(imx)` and
`e^(inx)` over one cycle is `1` when `m = n` and `0` when `m ≠ n`. -/
theorem waves_orthonormal (m n : ℤ) :
    (1 / (2 * π) * ∫ x in (-π)..π,
        cexp ((m : ℂ) * x * I) * (starRingEnd ℂ) (cexp ((n : ℂ) * x * I))) =
      if m = n then 1 else 0 := by
  simp_rw [fourier_wave_mul_conj, fourier_integral_exp_int, sub_eq_zero]
  have hpi : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  split_ifs
  · field_simp
  · simp

/-- The 25% pulse, `+1` for `0 ≤ x < π/2` and `-1` on the rest of the cycle `[-π, π]`, has
average `f̂(0) = -1/2` and coefficient `f̂(n) = (1 - e^(-iπn/2))/(iπn)` for every `n ≠ 0`. -/
theorem quarter_pulse_coeff (n : ℤ) :
    (1 / (2 * π) * ∫ x in (-π)..π,
        ((if 0 ≤ x ∧ x < π / 2 then 1 else -1 : ℝ) : ℂ) * cexp (-((n : ℂ) * x) * I)) =
      if n = 0 then -1 / 2 else (1 - cexp (-((π : ℂ) * n / 2) * I)) / (I * π * n) := by
  set E : ℝ → ℂ := fun x => cexp (-((n : ℂ) * x) * I) with hE
  set f : ℝ → ℂ := fun x =>
    ((if 0 ≤ x ∧ x < π / 2 then 1 else -1 : ℝ) : ℂ) * cexp (-((n : ℂ) * x) * I) with hf
  have hEc : Continuous E := by rw [hE]; fun_prop
  have hpi := Real.pi_pos
  have h1 : Set.EqOn f (fun x => -E x) (Set.Ioo (-π) 0) := by
    intro x hx
    simp only [hf, hE]
    have hcond : ¬(0 ≤ x ∧ x < π / 2) := by intro h; linarith [h.1, hx.2]
    simp only [hcond, ↓reduceIte]
    push_cast; ring
  have h2 : Set.EqOn f E (Set.Ioo 0 (π / 2)) := by
    intro x hx
    simp only [hf, hE]
    have hcond : 0 ≤ x ∧ x < π / 2 := ⟨hx.1.le, hx.2⟩
    simp only [hcond, and_self, ↓reduceIte]
    push_cast; ring
  have h3 : Set.EqOn f (fun x => -E x) (Set.Ioo (π / 2) π) := by
    intro x hx
    simp only [hf, hE]
    have hcond : ¬(0 ≤ x ∧ x < π / 2) := by intro h; linarith [h.2, hx.1]
    simp only [hcond, ↓reduceIte]
    push_cast; ring
  have le1 : -π ≤ 0 := by linarith
  have le2 : (0 : ℝ) ≤ π / 2 := by linarith
  have le3 : π / 2 ≤ π := by linarith
  have i1 : IntervalIntegrable f volume (-π) 0 := by
    refine (hEc.neg.intervalIntegrable (-π) 0).congr_uIoo ?_
    rw [Set.uIoo_of_le le1]; exact fun x hx => (h1 hx).symm
  have i2 : IntervalIntegrable f volume 0 (π / 2) := by
    refine (hEc.intervalIntegrable 0 (π / 2)).congr_uIoo ?_
    rw [Set.uIoo_of_le le2]; exact fun x hx => (h2 hx).symm
  have i3 : IntervalIntegrable f volume (π / 2) π := by
    refine (hEc.neg.intervalIntegrable (π / 2) π).congr_uIoo ?_
    rw [Set.uIoo_of_le le3]; exact fun x hx => (h3 hx).symm
  have hsplit : (∫ x in (-π)..π, f x) =
      -(∫ x in (-π)..0, E x) + (∫ x in (0 : ℝ)..(π / 2), E x) - ∫ x in (π / 2)..π, E x := by
    rw [← intervalIntegral.integral_add_adjacent_intervals (i1.trans i2) i3,
      ← intervalIntegral.integral_add_adjacent_intervals i1 i2,
      intervalIntegral.integral_congr_Ioo_of_le le1 h1,
      intervalIntegral.integral_congr_Ioo_of_le le2 h2,
      intervalIntegral.integral_congr_Ioo_of_le le3 h3,
      intervalIntegral.integral_neg, intervalIntegral.integral_neg]
    ring
  rw [hsplit]
  have hpiC : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  split_ifs with hn
  · subst hn
    simp only [hE, Int.cast_zero, zero_mul, neg_zero, Complex.exp_zero,
      intervalIntegral.integral_const, real_smul]
    push_cast
    field_simp
    ring
  · set c : ℂ := -((n : ℂ) * I) with hc
    have hc0 : c ≠ 0 := neg_ne_zero.mpr (mul_ne_zero (by exact_mod_cast hn) I_ne_zero)
    have hEx : E = fun x : ℝ => cexp (c * x) := by
      funext x; simp only [hE, hc]; ring_nf
    have hsym : cexp (c * (π : ℝ)) = cexp (c * ((-π : ℝ) : ℂ)) := by
      convert fourier_exp_int_pi_symm (-n) using 2 <;> simp only [hc] <;> push_cast <;> ring
    have hh : c * ((π / 2 : ℝ) : ℂ) = -((π : ℂ) * n / 2) * I := by
      simp only [hc]; push_cast; ring
    rw [hEx, integral_exp_mul_complex hc0, integral_exp_mul_complex hc0,
      integral_exp_mul_complex hc0, hh, ← hsym]
    simp only [Complex.ofReal_zero, mul_zero, Complex.exp_zero]
    have hn' : (n : ℂ) ≠ 0 := by exact_mod_cast hn
    simp only [hc]
    field_simp
    ring_nf

/-- The tones are whole multiples of 220 Hz: the siren's 440 flips a second are 220 cycles,
and the missing tones of the 25% pulse, `n = 4` and `n = 8`, sit at 880 Hz and 1760 Hz. -/
example : 440 / 2 = 220 ∧ 2 * 220 = 440 ∧ 4 * 220 = 880 ∧ 8 * 220 = 1760 := by
  norm_num

/-- Among `n = 1, ..., 8`, the multiples of 4 (where `e^(-iπn/2) = 1`, so the pulse's share
is 0) are exactly `4` and `8`; the check's orthonormality table for `m, n` from `-3` to `3`
has `7 × 7 = 49` entries. -/
example : (Finset.Icc 1 8).filter (fun n => n % 4 = 0) = {4, 8} ∧ 7 * 7 = 49 := by
  decide

#print axioms fourier_exp_int_pi_symm
#print axioms fourier_integral_exp_int
#print axioms fourier_wave_mul_conj
#print axioms inner_product_reads_off_share
#print axioms waves_orthonormal
#print axioms quarter_pulse_coeff
