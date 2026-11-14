-- The DFT and the FFT: for a block of N = 2^(L+1) samples the DFT splits exactly into the half-size DFTs of the even and odd samples, the repeated split costs (N/2) log2 N multiplications, and for real samples bin N - k holds the conjugate of bin k.
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Log
import Mathlib.Tactic.NormNum

open Complex Finset

/-- One step of 1/N of a circle clockwise: w = e^(-j2π/N) (Lean writes `I` for j). -/
noncomputable def twiddle (N : ℕ) : ℂ := Complex.exp (-2 * Real.pi * I / N)

/-- The DFT of the N samples x[0], ..., x[N-1]: X[k] = ∑_{n=0}^{N-1} x[n] w^(kn), w = e^(-j2π/N). -/
noncomputable def dft (N : ℕ) (x : ℕ → ℂ) (k : ℕ) : ℂ :=
  ∑ n ∈ range N, x n * twiddle N ^ (k * n)

/-- A sum over 0, ..., 2m-1 splits into the even and odd terms. -/
theorem sum_range_two_mul_even_odd (f : ℕ → ℂ) (m : ℕ) :
    ∑ n ∈ range (2 * m), f n = ∑ i ∈ range m, (f (2 * i) + f (2 * i + 1)) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [show 2 * (m + 1) = 2 * m + 1 + 1 by ring, sum_range_succ, sum_range_succ, ih,
      sum_range_succ]
    ring

#print axioms sum_range_two_mul_even_odd

/-- The square of the N-point twiddle for N = 2^(L+1) is the 2^L-point twiddle. -/
theorem twiddle_sq (L : ℕ) : twiddle (2 ^ (L + 1)) ^ 2 = twiddle (2 ^ L) := by
  unfold twiddle
  rw [← Complex.exp_nat_mul]
  congr 1
  push_cast
  rw [pow_succ]
  field_simp

#print axioms twiddle_sq

/-- The 2^(L+1)-point twiddle to the power 2^L is -1. -/
theorem twiddle_pow_half (L : ℕ) : twiddle (2 ^ (L + 1)) ^ (2 ^ L) = -1 := by
  unfold twiddle
  rw [← Complex.exp_nat_mul]
  rw [show ((2 ^ L : ℕ) : ℂ) * (-2 * ↑Real.pi * I / ((2 ^ (L + 1) : ℕ) : ℂ)) = -(↑Real.pi * I) by
    push_cast
    rw [pow_succ]
    field_simp]
  exact Complex.exp_neg_pi_mul_I

#print axioms twiddle_pow_half

/-- The N-point twiddle to the power N is 1 when N > 0. -/
theorem twiddle_pow_self (N : ℕ) (hN : N ≠ 0) : twiddle N ^ N = 1 := by
  unfold twiddle
  rw [← Complex.exp_nat_mul]
  have : (N : ℂ) ≠ 0 := by exact_mod_cast hN
  rw [show (N : ℂ) * (-2 * ↑Real.pi * I / N) = -(2 * ↑Real.pi * I) by field_simp]
  rw [Complex.exp_neg, Complex.exp_two_pi_mul_I, inv_one]

#print axioms twiddle_pow_self

/-- The twiddle times its conjugate is 1. -/
theorem twiddle_mul_conj (N : ℕ) : twiddle N * (starRingEnd ℂ) (twiddle N) = 1 := by
  unfold twiddle
  rw [← Complex.exp_conj, ← Complex.exp_add]
  simp only [map_div₀, map_mul, map_neg, map_ofNat, Complex.conj_ofReal, Complex.conj_I,
    map_natCast]
  rw [show -2 * (↑Real.pi : ℂ) * I / N + -2 * ↑Real.pi * -I / N = 0 by ring, Complex.exp_zero]

#print axioms twiddle_mul_conj

/-- **The even–odd split (the butterfly).** Let N = 2^(L+1) be a power of 2, at least 2, and
w = e^(-j2π/N). Let E[k] be the DFT of the even-numbered samples x[0], x[2], x[4], ... and O[k]
the DFT of the odd-numbered samples x[1], x[3], ..., each N/2 = 2^L long. Then for every bin
k from 0 to N/2 - 1, X[k] = E[k] + w^k O[k] and X[k + N/2] = E[k] - w^k O[k]: one product
w^k O[k] serves two outputs. -/
theorem dft_even_odd_split (L : ℕ) (x : ℕ → ℂ) (k : ℕ) (hk : k < 2 ^ L) :
    dft (2 ^ (L + 1)) x k =
        dft (2 ^ L) (fun m => x (2 * m)) k +
          twiddle (2 ^ (L + 1)) ^ k * dft (2 ^ L) (fun m => x (2 * m + 1)) k ∧
      dft (2 ^ (L + 1)) x (k + 2 ^ L) =
        dft (2 ^ L) (fun m => x (2 * m)) k -
          twiddle (2 ^ (L + 1)) ^ k * dft (2 ^ L) (fun m => x (2 * m + 1)) k := by
  have hw2 := twiddle_sq L
  have hwh := twiddle_pow_half L
  have hw'1 : twiddle (2 ^ L) ^ (2 ^ L) = 1 := by
    rw [← hw2, ← pow_mul, mul_comm, pow_mul, hwh]; norm_num
  unfold dft
  generalize twiddle (2 ^ (L + 1)) = w at *
  generalize twiddle (2 ^ L) = w' at *
  subst hw2
  rw [show range (2 ^ (L + 1)) = range (2 * 2 ^ L) by rw [pow_succ, mul_comm],
    sum_range_two_mul_even_odd, sum_range_two_mul_even_odd]
  constructor
  · rw [mul_sum, ← sum_add_distrib]
    refine sum_congr rfl fun i _ => ?_
    rw [show k * (2 * i) = 2 * (k * i) by ring, show k * (2 * i + 1) = k + 2 * (k * i) by ring,
      pow_add, pow_mul, pow_mul]
    ring
  · rw [mul_sum, ← sum_sub_distrib]
    refine sum_congr rfl fun i _ => ?_
    rw [show (k + 2 ^ L) * (2 * i) = 2 * (k * i) + 2 * (2 ^ L * i) by ring,
      show (k + 2 ^ L) * (2 * i + 1) = k + 2 ^ L + 2 * (k * i) + 2 * (2 ^ L * i) by ring]
    simp only [pow_add]
    rw [pow_mul w 2 (k * i), pow_mul w 2 (2 ^ L * i), pow_mul (w ^ 2) (2 ^ L) i, hw'1, hwh,
      one_pow]
    ring

/-- **The FFT's cost.** If a block of 1 sample costs no multiplications, M(1) = 0, and a block of
2n costs two half-size transforms plus n turns, M(2n) = 2 M(n) + n, then every power of 2,
N = 2^L, costs exactly M(N) = (N/2) log2 N multiplications. -/
theorem fft_multiplications_eq_half_n_log2_n (M : ℕ → ℕ) (h1 : M 1 = 0)
    (hM : ∀ n, 1 ≤ n → M (2 * n) = 2 * M n + n) (L : ℕ) :
    M (2 ^ L) = 2 ^ L / 2 * Nat.log 2 (2 ^ L) := by
  rw [Nat.log_pow (by norm_num)]
  induction L with
  | zero => simp [h1]
  | succ L ih =>
    rw [pow_succ, mul_comm (2 ^ L) 2, hM _ Nat.one_le_two_pow, ih,
      Nat.mul_div_cancel_left _ (by norm_num)]
    cases L with
    | zero => simp
    | succ L =>
      rw [pow_succ, Nat.mul_div_cancel _ (by norm_num)]
      ring

/-- **Bins above N/2 are mirrors.** For real samples x[0], ..., x[N-1], bin N - k holds the
conjugate of bin k (the same complex number with the sign of its j part flipped), for every
bin k from 0 to N. -/
theorem dft_real_samples_mirror (N : ℕ) (x : ℕ → ℝ) (k : ℕ) (hk : k ≤ N) :
    dft N (fun n => (x n : ℂ)) (N - k) = (starRingEnd ℂ) (dft N (fun n => (x n : ℂ)) k) := by
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp [dft]
  unfold dft
  rw [map_sum]
  refine sum_congr rfl fun n _ => ?_
  rw [map_mul, Complex.conj_ofReal, map_pow]
  congr 1
  have h1 := twiddle_pow_self N hN.ne'
  have h2 := twiddle_mul_conj N
  calc twiddle N ^ ((N - k) * n)
      = twiddle N ^ ((N - k) * n) * (twiddle N * (starRingEnd ℂ) (twiddle N)) ^ (k * n) := by
        rw [h2, one_pow, mul_one]
    _ = (twiddle N ^ N) ^ n * (starRingEnd ℂ) (twiddle N) ^ (k * n) := by
        rw [mul_pow, ← mul_assoc, ← pow_add, ← pow_mul, ← add_mul, Nat.sub_add_cancel hk]
    _ = (starRingEnd ℂ) (twiddle N) ^ (k * n) := by rw [h1, one_pow, one_mul]

-- The short block: 1024 = 2^10 samples, ten halvings, and the top useful bin is 1024 / 2 = 512.
example : (1024 : ℕ) = 2 ^ 10 ∧ Nat.log 2 1024 = 10 ∧ 1024 / 2 = 512 := by
  refine ⟨by norm_num, ?_, by norm_num⟩
  rw [show (1024 : ℕ) = 2 ^ 10 by norm_num, Nat.log_pow (by norm_num)]
-- The sum costs 1024 × 1024 = 1,048,576 products; the FFT costs 512 × 10 = 5,120.
example : 1024 * 1024 = 1048576 ∧ 1024 / 2 * 10 = 5120 := by norm_num
-- Speed-up 1,048,576 / 5,120 = 204.8 = 1024/5.
example : (1048576 : ℚ) / 5120 = 1024 / 5 := by norm_num
-- One split by hand: two 512-point sums, 524,288 products, plus 512 turns, 524,800 in all.
example : 2 * (512 * 512) = 524288 ∧ 2 * (512 * 512) + 512 = 524800 := by norm_num
-- The long block: 16,384 = 2^14 samples; FFT 8,192 × 14 = 114,688 against 16,384^2 = 268,435,456.
example : (16384 : ℕ) = 2 ^ 14 ∧ 16384 / 2 * 14 = 114688 ∧ 16384 * 16384 = 268435456 := by
  norm_num
-- The ten-second recording padded to 2^19 = 524,288: the sum 274,877,906,944, the FFT 4,980,736.
example : (2 : ℕ) ^ 19 = 524288 ∧ 524288 * 524288 = 274877906944 ∧ 524288 / 2 * 19 = 4980736 := by
  norm_num
-- The mirror: bin 1016 of 1024 is the mirror of bin 1024 - 1016 = 8.
example : 1024 - 1016 = 8 := by norm_num

#print axioms dft_even_odd_split
#print axioms fft_multiplications_eq_half_n_log2_n
#print axioms dft_real_samples_mirror
