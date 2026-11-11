-- The complex logarithm: every nonzero z has the logarithms ln|z| + i(Arg z + 2πk), one per whole number k, the one with angle in (−π, π] is Log z, Log has derivative 1/z off the negative real axis, and Log(zw) = Log z + Log w + 2πiN with N in {−1, 0, 1}.
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv

open Complex Real

/-- Every nonzero z has infinitely many logarithms (solutions w of e^w = z): exactly the numbers
ln|z| + i(Arg z + 2πk), one for each whole number k. The one whose imaginary part (its angle) lies
in (−π, π] is the principal logarithm Log z. -/
theorem logarithms_of_nonzero (z : ℂ) (hz : z ≠ 0) :
    {w : ℂ | exp w = z} =
        Set.range (fun k : ℤ => (Real.log ‖z‖ : ℂ) + ((arg z : ℂ) + 2 * π * k) * I) ∧
      {w : ℂ | exp w = z}.Infinite ∧
      ∀ w : ℂ, (exp w = z ∧ w.im ∈ Set.Ioc (-π) π) ↔ w = Complex.log z := by
  have hset : {w : ℂ | exp w = z} =
        Set.range (fun k : ℤ => (Real.log ‖z‖ : ℂ) + ((arg z : ℂ) + 2 * π * k) * I) := by
    ext w
    simp only [Set.mem_ofPred_eq, Set.mem_range]
    conv_lhs => rw [← exp_log hz, exp_eq_exp_iff_exists_int]
    constructor
    · rintro ⟨n, hn⟩
      refine ⟨n, ?_⟩
      rw [hn, Complex.log]
      ring
    · rintro ⟨n, hn⟩
      refine ⟨n, ?_⟩
      rw [← hn, Complex.log]
      ring
  refine ⟨hset, ?_, ?_⟩
  · rw [hset]
    apply Set.infinite_range_of_injective
    intro a b hab
    have h := congrArg Complex.im hab
    simpa [Real.pi_ne_zero] using h
  · intro w
    constructor
    · rintro ⟨hw, h1, h2⟩
      rw [← hw, log_exp h1 h2]
    · rintro rfl
      exact ⟨exp_log hz, by rw [log_im]; exact neg_pi_lt_arg z, by rw [log_im]; exact arg_le_pi z⟩

/-- Off the negative real axis (and off 0), the principal logarithm Log has complex derivative 1/z. -/
theorem log_hasDerivAt_inv_off_cut (z : ℂ) (hz : 0 < z.re ∨ z.im ≠ 0) :
    HasDerivAt Complex.log z⁻¹ z := by
  exact hasDerivAt_log (mem_slitPlane_iff.mpr hz)

/-- For nonzero z and w, Log(zw) = Log z + Log w + 2πiN for some N in {−1, 0, 1}; and when
Arg z + Arg w stays in (−π, π], N = 0, so Log(zw) = Log z + Log w exactly. -/
theorem log_mul_up_to_full_turn (z w : ℂ) (hz : z ≠ 0) (hw : w ≠ 0) :
    (∃ N : ℤ, N ∈ ({-1, 0, 1} : Set ℤ) ∧ Complex.log (z * w) = Complex.log z + Complex.log w + 2 * π * I * N) ∧
      (arg z + arg w ∈ Set.Ioc (-π) π → Complex.log (z * w) = Complex.log z + Complex.log w) := by
  refine ⟨?_, fun h => log_mul hz hw h⟩
  have he : exp (Complex.log (z * w)) = exp (Complex.log z + Complex.log w) := by
    rw [Complex.exp_add, exp_log hz, exp_log hw, exp_log (mul_ne_zero hz hw)]
  obtain ⟨n, hn⟩ := exp_eq_exp_iff_exists_int.mp he
  refine ⟨n, ?_, by rw [hn]; ring⟩
  have him := congrArg Complex.im hn
  simp only [add_im, log_im, mul_im, intCast_re, intCast_im, mul_re, ofReal_re, ofReal_im,
    re_ofNat, im_ofNat, I_re, I_im] at him
  have a1 := neg_pi_lt_arg z
  have a2 := arg_le_pi z
  have a3 := neg_pi_lt_arg w
  have a4 := arg_le_pi w
  have a5 := neg_pi_lt_arg (z * w)
  have a6 := arg_le_pi (z * w)
  have hp := Real.pi_pos
  have hlt : (n : ℝ) < 2 := by nlinarith
  have hgt : (-2 : ℝ) < n := by nlinarith
  have h1 : n < 2 := by exact_mod_cast hlt
  have h2 : -2 < n := by exact_mod_cast hgt
  simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
  omega

-- The floors k = −1, 0, 1 for z = −1: −iπ, iπ, 3iπ are all logarithms of −1.
example : exp (-(π * I)) = -1 ∧ exp (π * I) = -1 ∧ exp (3 * π * I) = -1 := by
  refine ⟨?_, exp_pi_mul_I, ?_⟩
  · rw [Complex.exp_neg, exp_pi_mul_I]; norm_num
  · have : 3 * π * I = π * I + (1 : ℤ) * (2 * π * I) := by push_cast; ring
    rw [this, Complex.exp_add, exp_int_mul_two_pi_mul_I, exp_pi_mul_I, mul_one]

-- The ground floor: Log(−1) = iπ.
example : Complex.log (-1) = π * I := by exact log_neg_one

-- The slip: Log((−1)(−1)) = Log 1 = 0, yet 2 Log(−1) = 2πi, so N = −1.
example : Complex.log ((-1) * (-1)) = 0 ∧ 2 * Complex.log (-1) = 2 * π * I ∧
    Complex.log ((-1) * (-1)) = Complex.log (-1) + Complex.log (-1) + 2 * π * I * (-1 : ℤ) := by
  refine ⟨by norm_num, by rw [log_neg_one]; ring, ?_⟩
  rw [log_neg_one]; norm_num; ring

-- Log i = iπ/2.
example : Complex.log I = π / 2 * I := by exact log_I

-- Log(e^(3iπ)) is iπ, not 3iπ.
example : Complex.log (exp (3 * π * I)) = π * I := by
  have : 3 * π * I = π * I + (1 : ℤ) * (2 * π * I) := by push_cast; ring
  rw [this, Complex.exp_add, exp_int_mul_two_pi_mul_I, exp_pi_mul_I, mul_one, log_neg_one]

#print axioms logarithms_of_nonzero
#print axioms log_hasDerivAt_inv_off_cut
#print axioms log_mul_up_to_full_turn
