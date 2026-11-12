-- The fast Fourier transform: an N-point DFT with N a power of 2 splits exactly into the half-size DFTs of the even and odd samples, the repeated split costs exactly 5 N log2 N flops, and zero padding to N ≥ 2n - 1 makes the inverse transform of the product of two transforms give the ordinary convolution.
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Log
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.RingTheory.RootsOfUnity.Complex

open Complex Finset

/-- The twiddle of size N: w = e^(-2πi/N), one N-th of a turn round the unit circle. -/
noncomputable def twiddle (N : ℕ) : ℂ := Complex.exp (-2 * Real.pi * I / N)

/-- The discrete Fourier transform of N samples: X_k = ∑_{j=0}^{N-1} x_j w^(jk), w = e^(-2πi/N). -/
noncomputable def dft (N : ℕ) (x : ℕ → ℂ) (k : ℕ) : ℂ :=
  ∑ j ∈ range N, x j * twiddle N ^ (j * k)

theorem fft_sum_range_two_mul (M : ℕ) (f : ℕ → ℂ) :
    ∑ j ∈ range (2 * M), f j = ∑ m ∈ range M, f (2 * m) + ∑ m ∈ range M, f (2 * m + 1) := by
  induction M with
  | zero => simp
  | succ M ih =>
    rw [show 2 * (M + 1) = 2 * M + 1 + 1 by ring, sum_range_succ, sum_range_succ, ih,
      sum_range_succ, sum_range_succ]
    ring

theorem twiddle_sq (L : ℕ) : twiddle (2 ^ (L + 1)) ^ 2 = twiddle (2 ^ L) := by
  unfold twiddle
  rw [← Complex.exp_nat_mul]
  congr 1
  push_cast
  field_simp
  ring

theorem twiddle_pow_half (L : ℕ) : twiddle (2 ^ (L + 1)) ^ (2 ^ L) = -1 := by
  unfold twiddle
  rw [← Complex.exp_nat_mul]
  have h : ((2 ^ L : ℕ) : ℂ) * (-2 * Real.pi * I / ((2 ^ (L + 1) : ℕ) : ℂ)) = -(Real.pi * I) := by
    push_cast
    field_simp
    ring
  rw [h, Complex.exp_neg, Complex.exp_pi_mul_I]
  norm_num

theorem twiddle_pow_self (L : ℕ) : twiddle (2 ^ L) ^ (2 ^ L) = 1 := by
  unfold twiddle
  rw [← Complex.exp_nat_mul]
  have h : ((2 ^ L : ℕ) : ℂ) * (-2 * Real.pi * I / ((2 ^ L : ℕ) : ℂ)) = -(2 * Real.pi * I) := by
    push_cast
    field_simp
  rw [h, Complex.exp_neg, Complex.exp_two_pi_mul_I]
  norm_num

/-- The radix-2 split. Let N = 2^(L+1) be a power of 2 (at least 2) and w = e^(-2πi/N).
Let E_k and O_k be the half-size DFTs (size N/2 = 2^L) of the even-numbered samples x_0, x_2, ...
and of the odd-numbered samples x_1, x_3, .... Then for 0 ≤ k < N/2 the butterfly gives two
outputs from one product w^k O_k: X_k = E_k + w^k O_k and X_(k+N/2) = E_k - w^k O_k. -/
theorem dft_even_odd_split (L : ℕ) (x : ℕ → ℂ) (k : ℕ) (hk : k < 2 ^ L) :
    dft (2 ^ (L + 1)) x k =
        dft (2 ^ L) (fun m => x (2 * m)) k +
          twiddle (2 ^ (L + 1)) ^ k * dft (2 ^ L) (fun m => x (2 * m + 1)) k ∧
      dft (2 ^ (L + 1)) x (k + 2 ^ L) =
        dft (2 ^ L) (fun m => x (2 * m)) k -
          twiddle (2 ^ (L + 1)) ^ k * dft (2 ^ L) (fun m => x (2 * m + 1)) k := by
  have hs : ∀ f : ℕ → ℂ, ∑ j ∈ range (2 ^ (L + 1)), f j =
      ∑ m ∈ range (2 ^ L), f (2 * m) + ∑ m ∈ range (2 ^ L), f (2 * m + 1) := by
    intro f
    rw [pow_succ']
    exact fft_sum_range_two_mul _ f
  have hw := twiddle_sq L
  have hh := twiddle_pow_half L
  have h1 := twiddle_pow_self L
  constructor
  · simp only [dft]
    rw [hs, mul_sum]
    congr 1
    · apply sum_congr rfl
      intro m _
      rw [← hw]
      ring
    · apply sum_congr rfl
      intro m _
      rw [← hw]
      ring
  · simp only [dft]
    rw [hs, mul_sum, sub_eq_add_neg, ← sum_neg_distrib]
    congr 1
    · apply sum_congr rfl
      intro m _
      have : x (2 * m) * twiddle (2 ^ (L + 1)) ^ (2 * m * (k + 2 ^ L)) =
          x (2 * m) * (twiddle (2 ^ (L + 1)) ^ 2) ^ (m * k) *
            ((twiddle (2 ^ (L + 1)) ^ 2) ^ (2 ^ L)) ^ m := by ring
      rw [this, hw, h1]
      ring
    · apply sum_congr rfl
      intro m _
      have : x (2 * m + 1) * twiddle (2 ^ (L + 1)) ^ ((2 * m + 1) * (k + 2 ^ L)) =
          twiddle (2 ^ (L + 1)) ^ (2 ^ L) * (twiddle (2 ^ (L + 1)) ^ k *
            (x (2 * m + 1) * (twiddle (2 ^ (L + 1)) ^ 2) ^ (m * k))) *
              ((twiddle (2 ^ (L + 1)) ^ 2) ^ (2 ^ L)) ^ m := by
        ring
      rw [this, hh, hw, h1]
      ring

/-- The flop count. If one transform of size 1 costs nothing, F(1) = 0, and a transform of size
2M costs two transforms of size M plus M butterflies of 10 flops each,
F(2M) = 2 F(M) + 5 (2M), then for every power of 2, N = 2^L, F(N) = 5 N log2 N exactly. -/
theorem fft_flops_eq_five_n_log2_n (F : ℕ → ℕ) (h1 : F 1 = 0)
    (hF : ∀ M, 1 ≤ M → F (2 * M) = 2 * F M + 5 * (2 * M)) (L : ℕ) :
    F (2 ^ L) = 5 * 2 ^ L * Nat.log 2 (2 ^ L) := by
  rw [Nat.log_pow (by norm_num)]
  induction L with
  | zero => simpa using h1
  | succ L ih =>
    rw [pow_succ', hF _ Nat.one_le_two_pow, ih]
    ring

/-- Convolution through the transform, with zero padding. Let a and b be two signals of n samples
(zero from index n on) and pad both to a transform size N = 2^L ≥ 2n - 1. Transform both, multiply
the spectra frequency by frequency, transform back with the conjugate twiddle e^(+2πi/N) and
divide by N. Output j, for every 0 ≤ j < N, is then exactly the ordinary convolution
c_j = ∑_{i=0}^{j} a_i b_(j-i): nothing wraps round. -/
theorem fft_convolution_with_zero_padding (n L : ℕ) (a b : ℕ → ℂ)
    (ha : ∀ j, n ≤ j → a j = 0) (hb : ∀ j, n ≤ j → b j = 0) (hN : 2 * n - 1 ≤ 2 ^ L)
    (j : ℕ) (hj : j < 2 ^ L) :
    ∑ i ∈ range (j + 1), a i * b (j - i) =
      (1 / (2 ^ L : ℂ)) * ∑ k ∈ range (2 ^ L),
        dft (2 ^ L) a k * dft (2 ^ L) b k *
          Complex.exp (2 * Real.pi * I / (2 ^ L : ℕ)) ^ (j * k) := by
  have hNc : ((2 ^ L : ℕ) : ℂ) = (2 : ℂ) ^ L := by push_cast; rfl
  rw [← hNc]
  set N := 2 ^ L with hNdef
  have hN0 : N ≠ 0 := by positivity
  have hv := Complex.isPrimitiveRoot_exp N hN0
  set v := Complex.exp (2 * Real.pi * I / (N : ℕ))
  have hv0 : v ≠ 0 := Complex.exp_ne_zero _
  have hw : twiddle N = v⁻¹ := by
    unfold twiddle
    rw [← Complex.exp_neg]
    congr 1
    ring
  have orth : ∀ d : ℤ, ∑ k ∈ range N, (v ^ d) ^ k = if (N : ℤ) ∣ d then (N : ℂ) else 0 := by
    intro d
    by_cases h : (N : ℤ) ∣ d
    · simp only [h, (hv.zpow_eq_one_iff_dvd d).2 h, one_pow, sum_const, card_range, ↓reduceIte,
        nsmul_eq_mul, mul_one]
    · simp only [h, ↓reduceIte]
      have hu : v ^ d ≠ 1 := fun e => h ((hv.zpow_eq_one_iff_dvd d).1 e)
      have hN1 : (v ^ d) ^ N = 1 := by
        rw [← zpow_natCast, ← zpow_mul, mul_comm, zpow_mul, zpow_natCast, hv.pow_eq_one, one_zpow]
      rw [geom_sum_eq hu, hN1, sub_self, zero_div]
  have term : ∀ p q k : ℕ, v⁻¹ ^ (p * k) * v⁻¹ ^ (q * k) * v ^ (j * k) =
      (v ^ ((j : ℤ) - p - q)) ^ k := by
    intro p q k
    rw [← zpow_natCast (v ^ ((j : ℤ) - p - q)), ← zpow_mul, inv_pow, inv_pow, ← zpow_natCast,
      ← zpow_natCast, ← zpow_natCast, ← zpow_neg, ← zpow_neg, ← zpow_add₀ hv0, ← zpow_add₀ hv0]
    congr 1
    push_cast
    ring
  simp only [dft, hw]
  have expand : ∑ k ∈ range N, (∑ p ∈ range N, a p * v⁻¹ ^ (p * k)) *
      (∑ q ∈ range N, b q * v⁻¹ ^ (q * k)) * v ^ (j * k) =
      ∑ p ∈ range N, ∑ q ∈ range N, a p * b q * ∑ k ∈ range N, (v ^ ((j : ℤ) - p - q)) ^ k := by
    simp only [sum_mul, mul_sum]
    conv_lhs => rw [sum_comm]
    conv_lhs => arg 2; ext q; rw [sum_comm]
    conv_lhs => rw [sum_comm]
    apply sum_congr rfl
    intro p _
    apply sum_congr rfl
    intro q _
    apply sum_congr rfl
    intro k _
    rw [← term p q k]
    ring
  rw [expand]
  simp only [orth]
  have key : ∀ p ∈ range N, ∀ q ∈ range N,
      a p * b q * (if (N : ℤ) ∣ ((j : ℤ) - p - q) then (N : ℂ) else 0) =
        (N : ℂ) * (if p + q = j then a p * b q else 0) := by
    intro p _ q _
    by_cases hap : a p = 0
    · simp [hap]
    by_cases hbq : b q = 0
    · simp [hbq]
    have hp : p < n := by
      by_contra h
      exact hap (ha p (by omega))
    have hq : q < n := by
      by_contra h
      exact hbq (hb q (by omega))
    by_cases hpq : p + q = j
    · have hd : (N : ℤ) ∣ ((j : ℤ) - p - q) := ⟨0, by omega⟩
      simp only [hd, hpq, ↓reduceIte]
      ring
    · have hd : ¬ (N : ℤ) ∣ ((j : ℤ) - p - q) := by
        intro hd
        have h0 := Int.eq_zero_of_abs_lt_dvd hd (by rw [abs_lt]; constructor <;> omega)
        omega
      simp only [hd, hpq, ↓reduceIte]
      ring
  rw [sum_congr rfl (fun p hp => sum_congr rfl (fun q hq => key p hp q hq))]
  simp only [← mul_sum]
  rw [← mul_assoc, one_div, inv_mul_cancel₀ (by exact_mod_cast hN0), one_mul]
  have inner : ∀ p, ∑ q ∈ range N, (if p + q = j then a p * b q else 0) =
      if p ≤ j then a p * b (j - p) else 0 := by
    intro p
    by_cases hp : p ≤ j
    · simp only [hp, ↓reduceIte]
      rw [sum_eq_single (j - p)]
      · simp only [show p + (j - p) = j by omega, ↓reduceIte]
      · intro q _ hq
        simp only [show ¬ p + q = j by omega, ↓reduceIte]
      · intro h
        exact absurd (mem_range.2 (by omega)) h
    · simp only [hp, ↓reduceIte]
      apply sum_eq_zero
      intro q _
      simp only [show ¬ p + q = j by omega, ↓reduceIte]
  simp only [inner]
  rw [← sum_filter]
  apply sum_congr _ (fun _ _ => rfl)
  ext p
  simp only [mem_range, mem_filter]
  omega

-- The hand product (1 + 2x + 3x²)(4 + 5x): the convolution of 1, 2, 3 with 4, 5 is 4, 13, 22, 15.
example : (List.range 4).map (fun j => ∑ i ∈ range (j + 1),
    [1, 2, 3].getD i 0 * [4, 5].getD (j - i) 0) = [4, 13, 22, 15] := by decide
-- The hand spectra at N = 4 (w = -i): A = 6, -2 - 2i, 2, -2 + 2i and B = 9, 4 - 5i, -1, 4 + 5i.
example : (1 + 2 * (-I) + 3 * (-I) ^ 2 : ℂ) = -2 - 2 * I ∧ (4 + 5 * (-I) : ℂ) = 4 - 5 * I ∧
    (1 + 2 * (-1) + 3 * (-1) ^ 2 : ℂ) = 2 ∧ (1 + 2 * I + 3 * I ^ 2 : ℂ) = -2 + 2 * I := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> ring_nf <;> simp [I_sq] <;> ring
-- One product of spectra: (-2 - 2i)(4 - 5i) = -8 + 10i - 8i - 10 = -18 + 2i; and 6 × 9 = 54.
example : ((-2 - 2 * I) * (4 - 5 * I) : ℂ) = -18 + 2 * I := by ring_nf; simp [I_sq]; ring
-- Back: c_0 = (54 + (-18 + 2i) + (-2) + (-18 - 2i)) / 4 = 4.
example : ((54 + (-18 + 2 * I) + (-2) + (-18 - 2 * I)) / 4 : ℂ) = 4 := by ring
-- The sum written out at n = 4096: 4096 × 4096 + 4095 × 4095 = 33,546,241 flops.
example : 4096 * 4096 + 4095 * 4095 = 33546241 := by norm_num
-- N = 8192 = 2^13 is the first power of 2 at or above 2 × 4096 - 1 = 8191, and log2 8192 = 13.
example : 2 * 4096 - 1 = 8191 ∧ 2 ^ 12 < 8191 ∧ 8191 ≤ 2 ^ 13 ∧ Nat.log 2 8192 = 13 := by
  refine ⟨by norm_num, by norm_num, by norm_num, ?_⟩
  rw [show (8192 : ℕ) = 2 ^ 13 by norm_num, Nat.log_pow (by norm_num)]
-- One transform: 5 × 8192 × 13 = 532,480; three of them 1,597,440; plus 6N + N = 57,344.
example : 5 * 8192 * 13 = 532480 ∧ 3 * 532480 = 1597440 ∧ 6 * 8192 + 8192 = 57344 ∧
    1597440 + 57344 = 1654784 ∧ 15 * 8192 * 13 + 7 * 8192 = 1654784 := by norm_num
-- The saving: 33,546,241 / 1,654,784 lies between 20.27 and 20.28.
example : (2027 : ℚ) / 100 < 33546241 / 1654784 ∧ (33546241 : ℚ) / 1654784 < 2028 / 100 := by
  norm_num
-- Packed real input: 10 N log2 N + 15 N = 1,187,840 at N = 8192.
example : 10 * 8192 * 13 + 15 * 8192 = 1187840 := by norm_num
-- Split radix at N = 8192: 4 N log2 N - 6N + 8 = 376,840.
example : 4 * 8192 * 13 - 6 * 8192 + 8 = 376840 := by norm_num
-- Skipping the 8191 multiplications by w^0 = 1 (6 flops each): 532,480 - 6 × 8191 = 483,334.
example : 532480 - 6 * 8191 = 483334 := by norm_num
-- At n = 128 (N = 256, log2 N = 8) the route wins by one flop: 32,512 against 32,513.
example : 15 * 256 * 8 + 7 * 256 = 32512 ∧ 128 * 128 + 127 * 127 = 32513 := by norm_num
-- Without the 1/N: 19,345,708,798 × 8192 = 158,480,046,473,216.
example : 19345708798 * 8192 = 158480046473216 := by norm_num
-- Complex multiplications miscounted as flops: 4096 + 3 × (8192 / 2) × 13 = 167,936.
example : 8192 + 3 * (8192 / 2) * 13 = 167936 := by norm_num

#print axioms fft_sum_range_two_mul
#print axioms twiddle_sq
#print axioms twiddle_pow_half
#print axioms twiddle_pow_self
#print axioms dft_even_odd_split
#print axioms fft_flops_eq_five_n_log2_n
#print axioms fft_convolution_with_zero_padding
