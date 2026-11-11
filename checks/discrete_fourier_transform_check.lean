-- The discrete Fourier transform: for every N and every N complex samples, the conjugate matrix divided by N undoes the transform, the matrix divided by the square root of N is unitary, and Parseval's energy identity holds; with the card's eight temperature readings as examples.
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Matrix.ConjTranspose
import Mathlib.Tactic.NormNum
import Mathlib.RingTheory.RootsOfUnity.Complex

open Complex ComplexConjugate Matrix
open Real (pi sqrt)

lemma dft_w_eq (N : ℕ) :
    Complex.exp (-2 * pi * I / N) = (Complex.exp (2 * pi * I / N))⁻¹ := by
  rw [← Complex.exp_neg]; congr 1; ring

lemma dft_conj_w (N : ℕ) :
    conj (Complex.exp (-2 * pi * I / N)) = Complex.exp (2 * pi * I / N) := by
  rw [← Complex.exp_conj]; congr 1
  simp [map_div₀, Complex.conj_ofReal, map_ofNat]

lemma dft_orth (N : ℕ) (a b : Fin N) :
    ∑ k : Fin N, Complex.exp (-2 * pi * I / N) ^ (k.val * a.val) *
      conj (Complex.exp (-2 * pi * I / N)) ^ (k.val * b.val) = if a = b then (N : ℂ) else 0 := by
  have hN : N ≠ 0 := by have := a.pos; omega
  set ζ := Complex.exp (2 * pi * I / N) with hζ
  have hp : IsPrimitiveRoot ζ N := Complex.isPrimitiveRoot_exp N hN
  have hζ0 : ζ ≠ 0 := Complex.exp_ne_zero _
  rw [dft_conj_w, dft_w_eq, ← hζ]
  set z : ℂ := ζ ^ ((b.val : ℤ) - a.val) with hz
  have hterm : ∀ k : Fin N, ζ⁻¹ ^ (k.val * a.val) * ζ ^ (k.val * b.val) = z ^ k.val := by
    intro k
    rw [hz, ← zpow_natCast, ← zpow_natCast, ← zpow_natCast, inv_zpow', ← zpow_add₀ hζ0,
      ← zpow_mul]
    congr 1; push_cast; ring
  simp_rw [hterm]
  rw [Fin.sum_univ_eq_sum_range (fun k => z ^ k)]
  split_ifs with hab
  · subst hab; simp [hz]
  · have hzN : z ^ N = 1 := by
      rw [hz, ← zpow_natCast, ← zpow_mul, mul_comm, zpow_mul, zpow_natCast, hp.pow_eq_one, one_zpow]
    have hz1 : z ≠ 1 := by
      rw [hz, Ne, hp.zpow_eq_one_iff_dvd]
      intro hd
      apply hab
      have := Int.eq_zero_of_abs_lt_dvd hd (by have := a.isLt; have := b.isLt; rw [abs_lt]; constructor <;> omega)
      ext; omega
    have := geom_sum_mul z N
    rw [hzN, sub_self] at this
    exact (mul_eq_zero.mp this).resolve_right (sub_ne_zero.mpr hz1)

lemma dft_w8 : Complex.exp (-2 * pi * I / 8) =
    ((sqrt 2 / 2 : ℝ) : ℂ) - ((sqrt 2 / 2 : ℝ) : ℂ) * I := by
  have : -2 * (pi : ℂ) * I / 8 = ((-(pi / 4) : ℝ) : ℂ) * I := by push_cast; ring
  rw [this, Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin, Real.cos_neg,
    Real.sin_neg, Real.cos_pi_div_four, Real.sin_pi_div_four]
  push_cast; ring

#print axioms dft_w_eq
#print axioms dft_conj_w
#print axioms dft_orth
#print axioms dft_w8

/-- **The conjugate matrix divided by N undoes the transform.** Let N be any whole number, let
w = e^(−2πi/N), and let x_0, …, x_(N−1) be any N complex numbers. Write
X_k = ∑_n x_n w^(kn) for the transform. Then turning the other way, adding and dividing by N
gives every sample back: x_n = (1/N) ∑_k X_k (conj w)^(kn) for every slot n. -/
theorem dft_inversion (N : ℕ) (x : Fin N → ℂ) (n : Fin N) :
    (1 / (N : ℂ)) * ∑ k : Fin N,
        (∑ m : Fin N, x m * Complex.exp (-2 * pi * I / N) ^ (k.val * m.val)) *
          conj (Complex.exp (-2 * pi * I / N)) ^ (k.val * n.val) = x n := by
  have hN : (N : ℂ) ≠ 0 := by have := n.pos; exact_mod_cast (by omega : N ≠ 0)
  simp_rw [Finset.sum_mul]
  rw [Finset.sum_comm]
  have h : ∀ m : Fin N, ∑ k : Fin N, x m * Complex.exp (-2 * pi * I / N) ^ (k.val * m.val) *
      conj (Complex.exp (-2 * pi * I / N)) ^ (k.val * n.val) =
      x m * (if m = n then (N : ℂ) else 0) := by
    intro m
    rw [← dft_orth N m n, Finset.mul_sum]
    exact Finset.sum_congr rfl fun k _ => by ring
  rw [Finset.sum_congr rfl fun m _ => h m]
  simp
  field_simp

/-- **The matrix divided by the square root of N is unitary.** Let U be the N by N matrix with
w^(kn) / √N in row k, column n, where w = e^(−2πi/N). Then the conjugate transpose of U times U
is the identity matrix. -/
theorem dft_matrix_div_sqrt_unitary (N : ℕ) :
    (Matrix.of fun k n : Fin N =>
        Complex.exp (-2 * pi * I / N) ^ (k.val * n.val) / (sqrt N : ℂ))ᴴ *
      (Matrix.of fun k n : Fin N =>
        Complex.exp (-2 * pi * I / N) ^ (k.val * n.val) / (sqrt N : ℂ)) = 1 := by
  ext a b
  have hN : (N : ℂ) ≠ 0 := by have := a.pos; exact_mod_cast (by omega : N ≠ 0)
  have hs : (sqrt N : ℂ) * (sqrt N : ℂ) = N := by
    rw [← Complex.ofReal_mul, Real.mul_self_sqrt (Nat.cast_nonneg N)]; simp
  simp only [Matrix.mul_apply, Matrix.conjTranspose_apply, Matrix.of_apply, star_div₀,
    Complex.star_def, map_pow, Complex.conj_ofReal]
  have : ∀ k : Fin N, conj (Complex.exp (-2 * pi * I / N)) ^ (k.val * a.val) / (sqrt N : ℂ) *
      (Complex.exp (-2 * pi * I / N) ^ (k.val * b.val) / (sqrt N : ℂ)) =
      (1 / (N : ℂ)) * (Complex.exp (-2 * pi * I / N) ^ (k.val * b.val) *
        conj (Complex.exp (-2 * pi * I / N)) ^ (k.val * a.val)) := by
    intro k; rw [← hs]; field_simp
  simp_rw [this, ← Finset.mul_sum, dft_orth, Matrix.one_apply]
  split_ifs with h1 h2 h2 <;> first | (subst h1; simp [hN] at *) | simp_all [eq_comm]

/-- **Parseval: energy is kept up to the factor N.** For any N complex samples x_n, with
X_k = ∑_n x_n w^(kn) and w = e^(−2πi/N), the sum of the squared sizes of the samples equals
the sum of the squared sizes of the outputs divided by N. -/
theorem dft_parseval (N : ℕ) (x : Fin N → ℂ) :
    ∑ n : Fin N, ‖x n‖ ^ 2 =
      (1 / (N : ℝ)) * ∑ k : Fin N,
        ‖∑ m : Fin N, x m * Complex.exp (-2 * pi * I / N) ^ (k.val * m.val)‖ ^ 2 := by
  rcases Nat.eq_zero_or_pos N with h0 | hpos
  · subst h0; simp
  have hN : (N : ℂ) ≠ 0 := by exact_mod_cast hpos.ne'
  have horth : ∀ i j : Fin N, ∑ k : Fin N, x i * Complex.exp (-2 * pi * I / N) ^ (k.val * i.val) *
      (conj (x j) * conj (Complex.exp (-2 * pi * I / N)) ^ (k.val * j.val)) =
      x i * conj (x j) * (if i = j then (N : ℂ) else 0) := by
    intro i j
    rw [← dft_orth N i j, Finset.mul_sum]
    exact Finset.sum_congr rfl fun k _ => by ring
  have key : ∑ k : Fin N,
      (∑ m : Fin N, x m * Complex.exp (-2 * pi * I / N) ^ (k.val * m.val)) *
        conj (∑ m : Fin N, x m * Complex.exp (-2 * pi * I / N) ^ (k.val * m.val)) =
      (N : ℂ) * ∑ n : Fin N, x n * conj (x n) := by
    simp_rw [map_sum, map_mul, map_pow, Finset.sum_mul, Finset.mul_sum]
    rw [Finset.sum_comm]
    rw [Finset.sum_congr rfl fun i _ => Finset.sum_comm]
    simp_rw [horth]
    simp [mul_comm]
  apply Complex.ofReal_injective
  push_cast
  simp_rw [← Complex.mul_conj']
  rw [key]
  field_simp

-- The eight readings: X_0 is their plain sum, 120, and the mean is 120 / 8 = 15.
example : (11 + 9 + 10 + 15 + 20 + 22 + 19 + 14 : ℤ) = 120 ∧ (120 : ℚ) / 8 = 15 := by norm_num
-- The energy check: 11^2 + 9^2 + … + 14^2 = 1968, and 15744 / 8 = 1968.
example : (11 ^ 2 + 9 ^ 2 + 10 ^ 2 + 15 ^ 2 + 20 ^ 2 + 22 ^ 2 + 19 ^ 2 + 14 ^ 2 : ℤ) = 1968 ∧
    (15744 : ℚ) / 8 = 1968 := by norm_num
-- X_0 from the transform itself: with N = 8, the k = 0 output of the readings is 120.
example : ∑ m : Fin 8, (![11, 9, 10, 15, 20, 22, 19, 14] : Fin 8 → ℂ) m *
    Complex.exp (-2 * pi * I / 8) ^ ((0 : Fin 8).val * m.val) = 120 := by
  norm_num [Fin.sum_univ_eight]
-- X_1 exactly: the k = 1 output of the readings is (−9 − 7√2) + (9 + 6√2)i,
-- that is −18.899495 + 17.485281i.
example : ∑ m : Fin 8, (![11, 9, 10, 15, 20, 22, 19, 14] : Fin 8 → ℂ) m *
    Complex.exp (-2 * pi * I / 8) ^ ((1 : Fin 8).val * m.val) =
      ((-9 - 7 * sqrt 2 : ℝ) : ℂ) + ((9 + 6 * sqrt 2 : ℝ) : ℂ) * I := by
  have hs : ((sqrt 2 : ℝ) : ℂ) ^ 2 = 2 := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; simp
  set w := Complex.exp (-2 * pi * I / 8) with hwdef
  have hw2 : w ^ 2 = -I := by
    rw [hwdef, dft_w8]; push_cast
    linear_combination (1 / 4 - I / 2 + I ^ 2 / 4) * hs + (1 / 2 : ℂ) * Complex.I_sq
  have h3 : w ^ 3 = -I * w := by rw [pow_succ, hw2]
  have h4 : w ^ 4 = -1 := by rw [show w ^ 4 = (w ^ 2) ^ 2 by ring, hw2]; simp
  have h5 : w ^ 5 = -w := by rw [pow_succ, h4]; ring
  have h6 : w ^ 6 = I := by rw [show w ^ 6 = w ^ 4 * w ^ 2 by ring, h4, hw2]; ring
  have h7 : w ^ 7 = I * w := by rw [pow_succ, h6]
  simp only [Fin.sum_univ_eight]
  simp [h3, h4, h5, h6, h7, hw2]
  rw [hwdef, dft_w8]
  push_cast
  linear_combination ((sqrt 2 : ℂ) / 2) * Complex.I_sq
-- The outputs' energy: the squared sizes of the eight outputs add to 15744.
example : ∑ k : Fin 8, ‖∑ m : Fin 8, (![11, 9, 10, 15, 20, 22, 19, 14] : Fin 8 → ℂ) m *
    Complex.exp (-2 * pi * I / 8) ^ (k.val * m.val)‖ ^ 2 = 15744 := by
  have h := dft_parseval 8 ![11, 9, 10, 15, 20, 22, 19, 14]
  push_cast at h
  have h2 : ∑ n : Fin 8, ‖(![11, 9, 10, 15, 20, 22, 19, 14] : Fin 8 → ℂ) n‖ ^ 2 = 1968 := by
    simp [Fin.sum_univ_eight]
    norm_num
  rw [h2] at h
  linarith

#print axioms dft_inversion
#print axioms dft_matrix_div_sqrt_unitary
#print axioms dft_parseval
