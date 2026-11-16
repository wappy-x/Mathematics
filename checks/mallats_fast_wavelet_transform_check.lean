-- Mallat's algorithm: filtering and halving with an orthonormal filter pair and wrap-around ends rebuilds the record exactly, keeps its energy, and costs 2L(N - 1) multiplies.
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.Linarith
import Mathlib.Data.Int.Interval
import Mathlib.LinearAlgebra.Matrix.SemiringInverse

open Finset

namespace MallatFWT

/-- The high-pass filter made from a low-pass filter `h` with `L` taps:
`g[m] = (-1)^m h[L-1-m]` for `m < L`, and `0` past the last tap. -/
def highpass (L : ℕ) (h : ℕ → ℝ) (m : ℕ) : ℝ :=
  if m < L then (-1) ^ m * h (L - 1 - m) else 0

/-- One level down for one filter `f` with `L` taps, on a level of length `n` with
wrap-around ends: output `k` is `∑_m f[m] s[(2k + m) mod n]` (filter, keep every second). -/
def down (L : ℕ) (f : ℕ → ℝ) (n : ℕ) (s : ℕ → ℝ) (k : ℕ) : ℝ :=
  ∑ m ∈ range L, f m * s ((2 * k + m) % n)

/-- One level up, onto a level of length `n` with wrap-around ends: each coarse number
`lo k` and detail `hi k` hands `h[m] lo[k] + g[m] hi[k]` back to position `(2k + m) mod n`. -/
def up (L : ℕ) (h g : ℕ → ℝ) (n : ℕ) (lo hi : ℕ → ℝ) (i : ℕ) : ℝ :=
  ∑ k ∈ range (n / 2), ∑ m ∈ range L,
    if (2 * k + m) % n = i then h m * lo k + g m * hi k else 0

/-- The cascade taken `J` levels down from a record of length `n`: it returns the final
coarse part and the list of details `d_1, d_2, …, d_J`, finest first. Only the coarse part
goes down again, on a level half as long. -/
def forward (L : ℕ) (h g : ℕ → ℝ) : ℕ → ℕ → (ℕ → ℝ) → (ℕ → ℝ) × List (ℕ → ℝ)
  | 0, _, s => (s, [])
  | J + 1, n, s =>
      let rest := forward L h g J (n / 2) (down L h n s)
      (rest.1, down L g n s :: rest.2)

/-- The cascade run backwards: from the coarse part and the details, finest first, rebuild a
record of length `n` one level up at a time. -/
def inverse (L : ℕ) (h g : ℕ → ℝ) : ℕ → (ℕ → ℝ) → List (ℕ → ℝ) → (ℕ → ℝ)
  | _, c, [] => c
  | n, c, d :: ds => up L h g n (inverse L h g (n / 2) c ds) d

/-- Multiplies used by the cascade taken `J` levels down from a record of length `n`: a level
taking in `n` numbers makes `n/2` coarse and `n/2` detail numbers, `L` multiplies each. -/
def cascadeCost (L : ℕ) : ℕ → ℕ → ℕ
  | 0, _ => 0
  | J + 1, n => 2 * L * (n / 2) + cascadeCost L J (n / 2)

/-- Autocorrelation of the filter at a nonnegative even shift. -/
theorem corr_nat (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (q : ℕ) :
    ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
      (if (m' : ℤ) = m + 2 * q then h m * h m' else 0) = if q = 0 then 1 else 0 := by
  rw [← h_orth q]
  apply sum_congr rfl
  intro m _
  have : ∀ m' : ℕ, ((m' : ℤ) = m + 2 * q) ↔ m' = m + 2 * q := fun m' => by omega
  simp_rw [this]
  rw [sum_ite_eq']
  split_ifs with hm
  · rfl
  · rw [h_taps (m + 2 * q) (by simp at hm; omega), mul_zero]

theorem corr_int (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (r : ℤ) :
    ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
      (if (m' : ℤ) - m = 2 * r then h m * h m' else 0) = if r = 0 then 1 else 0 := by
  rcases le_or_gt 0 r with hr | hr
  · lift r to ℕ using hr
    have := corr_nat M h h_taps h_orth r
    simp only [Nat.cast_eq_zero]
    rw [← this]
    apply sum_congr rfl; intro m _; apply sum_congr rfl; intro m' _
    congr 1; apply propext; omega
  · obtain ⟨q, hq⟩ : ∃ q : ℕ, r = -(q : ℤ) := ⟨(-r).toNat, by omega⟩
    have hq0 : q ≠ 0 := by omega
    have := corr_nat M h h_taps h_orth q
    rw [ite_eq_right hq0] at this
    rw [ite_eq_right (by omega), sum_comm]
    refine Eq.trans ?_ this
    apply sum_congr rfl; intro m _; apply sum_congr rfl; intro m' _
    by_cases hc : (m' : ℤ) = m + 2 * q
    · rw [ite_eq_left hc, ite_eq_left (by omega), mul_comm]
    · rw [ite_eq_right hc, ite_eq_right (by omega)]

theorem corr_mod (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (K : ℕ) (hK : 0 < K) (d : ℤ) (hd1 : -(K : ℤ) < d) (hd2 : d < K) :
    ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
      (if (2 * (K : ℤ)) ∣ ((m' : ℤ) - m) - 2 * d then h m * h m' else 0)
      = if d = 0 then 1 else 0 := by
  have hK1 : (1 : ℤ) ≤ K := by exact_mod_cast hK
  have step : ∀ m ∈ range (2 * M), ∀ m' ∈ range (2 * M),
      (if (2 * (K : ℤ)) ∣ ((m' : ℤ) - m) - 2 * d then h m * h m' else 0)
      = ∑ t ∈ Icc (-((M : ℤ) + K)) ((M : ℤ) + K),
          (if (m' : ℤ) - m = 2 * (d + K * t) then h m * h m' else 0) := by
    intro m hm m' hm'
    simp only [mem_range] at hm hm'
    have hm1 : (m : ℤ) < 2 * M := by exact_mod_cast hm
    have hm2 : (m' : ℤ) < 2 * M := by exact_mod_cast hm'
    have hm3 : (0 : ℤ) ≤ m := Nat.cast_nonneg m
    have hm4 : (0 : ℤ) ≤ m' := Nat.cast_nonneg m'
    by_cases hdv : (2 * (K : ℤ)) ∣ ((m' : ℤ) - m) - 2 * d
    · rw [ite_eq_left hdv]
      obtain ⟨t0, ht0⟩ := hdv
      have hb1 : -((M : ℤ) + K) ≤ t0 := by
        by_contra hc
        push Not at hc
        nlinarith
      have hb2 : t0 ≤ (M : ℤ) + K := by
        by_contra hc
        push Not at hc
        nlinarith
      rw [sum_eq_single t0]
      · rw [ite_eq_left (by linarith)]
      · intro t _ htt
        rw [ite_eq_right]
        intro hc
        apply htt
        have : (2 * (K : ℤ)) * (t - t0) = 0 := by linarith
        rcases mul_eq_zero.1 this with h0 | h0
        · omega
        · linarith
      · intro hn
        exact absurd (mem_Icc.2 ⟨hb1, hb2⟩) hn
    · rw [ite_eq_right hdv]
      symm
      apply sum_eq_zero
      intro t _
      rw [ite_eq_right]
      intro hc
      exact hdv ⟨t, by linarith⟩
  calc _ = ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
        ∑ t ∈ Icc (-((M : ℤ) + K)) ((M : ℤ) + K),
          (if (m' : ℤ) - m = 2 * (d + K * t) then h m * h m' else 0) :=
        sum_congr rfl (fun m hm => sum_congr rfl (fun m' hm' => step m hm m' hm'))
    _ = ∑ m ∈ range (2 * M), ∑ t ∈ Icc (-((M : ℤ) + K)) ((M : ℤ) + K),
          ∑ m' ∈ range (2 * M),
          (if (m' : ℤ) - m = 2 * (d + K * t) then h m * h m' else 0) :=
        sum_congr rfl (fun m _ => sum_comm)
    _ = ∑ t ∈ Icc (-((M : ℤ) + K)) ((M : ℤ) + K), ∑ m ∈ range (2 * M),
          ∑ m' ∈ range (2 * M),
          (if (m' : ℤ) - m = 2 * (d + K * t) then h m * h m' else 0) := sum_comm
    _ = ∑ t ∈ Icc (-((M : ℤ) + K)) ((M : ℤ) + K), (if d + K * t = 0 then (1 : ℝ) else 0) :=
        sum_congr rfl (fun t _ => corr_int M h h_taps h_orth (d + K * t))
    _ = if d = 0 then 1 else 0 := by
        rw [sum_eq_single 0]
        · simp
        · intro t _ ht
          rw [ite_eq_right]
          intro h0
          rcases lt_or_gt_of_ne ht with h1 | h1
          · nlinarith
          · nlinarith
        · intro h0
          exact absurd (mem_Icc.2 ⟨by omega, by omega⟩) h0

/-- Row `k` of the one-level matrix for filter `f`, entry at column `j`. -/
def rowF (L : ℕ) (f : ℕ → ℝ) (n k j : ℕ) : ℝ :=
  ∑ m ∈ range L, if (2 * k + m) % n = j then f m else 0

theorem row_inner (L : ℕ) (f f' : ℕ → ℝ) (n k k' : ℕ) (hn : 0 < n) :
    ∑ j ∈ range n, rowF L f n k j * rowF L f' n k' j =
      ∑ m ∈ range L, ∑ m' ∈ range L,
        (if (2 * k + m) % n = (2 * k' + m') % n then f m * f' m' else 0) := by
  simp only [rowF, sum_mul_sum]
  rw [sum_comm]
  apply sum_congr rfl
  intro m _
  rw [sum_comm]
  apply sum_congr rfl
  intro m' _
  simp only [ite_mul, zero_mul]
  rw [sum_ite_eq]
  have : (2 * k + m) % n ∈ range n := mem_range.2 (Nat.mod_lt _ hn)
  simp only [this, ite_true]
  by_cases hc : (2 * k + m) % n = (2 * k' + m') % n
  · simp [hc]
  · simp [hc, Ne.symm hc]

theorem sgn_same (a b : ℕ) (hab : (a + b) % 2 = 0) : (-1 : ℝ) ^ a * (-1) ^ b = 1 := by
  rw [← pow_add]
  exact Even.neg_one_pow (Nat.even_iff.mpr hab)

theorem sgn_opp (a b : ℕ) (hab : (a + b) % 2 = 1) : (-1 : ℝ) ^ a = -(-1) ^ b := by
  rcases Nat.even_or_odd b with hb | hb
  · have ha : Odd a := Nat.odd_iff.mpr (by have := Nat.even_iff.mp hb; omega)
    rw [ha.neg_one_pow, hb.neg_one_pow]
  · have ha : Even a := Nat.even_iff.mpr (by have := Nat.odd_iff.mp hb; omega)
    rw [ha.neg_one_pow, hb.neg_one_pow]; norm_num

theorem modeq_int (n a b : ℕ) : a % n = b % n ↔ (n : ℤ) ∣ (b : ℤ) - a := Nat.modEq_iff_dvd

theorem pair_hh (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (K : ℕ) (k k' : ℕ) (hk : k < K) (hk' : k' < K) :
    ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
      (if (2 * k + m) % (2 * K) = (2 * k' + m') % (2 * K) then h m * h m' else 0)
      = if k = k' then 1 else 0 := by
  have hK : 0 < K := by omega
  have := corr_mod M h h_taps h_orth K hK ((k : ℤ) - k') (by omega) (by omega)
  have e : ((k : ℤ) - k' = 0) ↔ k = k' := by omega
  simp only [e] at this
  rw [← this]
  apply sum_congr rfl; intro m _; apply sum_congr rfl; intro m' _
  congr 1
  apply propext
  rw [modeq_int]
  push_cast
  constructor <;> intro hd <;> (convert hd using 1; ring)

theorem pair_gg (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (K : ℕ) (k k' : ℕ) (hk : k < K) (hk' : k' < K) :
    ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
      (if (2 * k + m) % (2 * K) = (2 * k' + m') % (2 * K)
        then highpass (2 * M) h m * highpass (2 * M) h m' else 0)
      = if k = k' then 1 else 0 := by
  have hK : 0 < K := by omega
  have := corr_mod M h h_taps h_orth K hK ((k' : ℤ) - k) (by omega) (by omega)
  have e : ((k' : ℤ) - k = 0) ↔ k = k' := by omega
  simp only [e] at this
  rw [← this, ← sum_range_reflect]
  apply sum_congr rfl; intro p hp
  rw [← sum_range_reflect]
  apply sum_congr rfl; intro p' hp'
  simp only [mem_range] at hp hp'
  have h1 : 2 * M - 1 - p < 2 * M := by omega
  have h2 : 2 * M - 1 - p' < 2 * M := by omega
  have h3 : 2 * M - 1 - (2 * M - 1 - p) = p := by omega
  have h4 : 2 * M - 1 - (2 * M - 1 - p') = p' := by omega
  simp only [highpass, h1, h2, ite_true, h3, h4]
  have hc : (2 * k + (2 * M - 1 - p)) % (2 * K) = (2 * k' + (2 * M - 1 - p')) % (2 * K) ↔
      (2 * (K : ℤ)) ∣ ((p' : ℤ) - p) - 2 * ((k' : ℤ) - k) := by
    rw [modeq_int]
    have e1 : (((2 * k' + (2 * M - 1 - p')) : ℕ) : ℤ) - ((2 * k + (2 * M - 1 - p) : ℕ) : ℤ)
        = -(((p' : ℤ) - p) - 2 * ((k' : ℤ) - k)) := by omega
    rw [e1, dvd_neg]
    push_cast
    rfl
  by_cases hd : (2 * (K : ℤ)) ∣ ((p' : ℤ) - p) - 2 * ((k' : ℤ) - k)
  · rw [ite_eq_left (hc.2 hd), ite_eq_left hd]
    have h2d : (2 : ℤ) ∣ ((p' : ℤ) - p) - 2 * ((k' : ℤ) - k) :=
      dvd_trans (dvd_mul_right 2 (K : ℤ)) hd
    have hs := sgn_same (2 * M - 1 - p) (2 * M - 1 - p') (by omega)
    calc (-1 : ℝ) ^ (2 * M - 1 - p) * h p * ((-1) ^ (2 * M - 1 - p') * h p')
        = ((-1 : ℝ) ^ (2 * M - 1 - p) * (-1) ^ (2 * M - 1 - p')) * (h p * h p') := by ring
      _ = h p * h p' := by rw [hs, one_mul]
  · rw [ite_eq_right (fun hh => hd (hc.1 hh)), ite_eq_right hd]

theorem pair_gh (M : ℕ) (h : ℕ → ℝ) (K k k' : ℕ) :
    ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
      (if (2 * k + m) % (2 * K) = (2 * k' + m') % (2 * K)
        then h m * highpass (2 * M) h m' else 0) = 0 := by
  have step1 : ∑ m ∈ range (2 * M), ∑ m' ∈ range (2 * M),
      (if (2 * k + m) % (2 * K) = (2 * k' + m') % (2 * K)
        then h m * highpass (2 * M) h m' else 0) =
      ∑ m ∈ range (2 * M), ∑ p ∈ range (2 * M),
        (if (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p)
          then (-1 : ℝ) ^ (2 * M - 1 - p) * (h m * h p) else 0) := by
    apply sum_congr rfl; intro m hm
    rw [← sum_range_reflect]
    apply sum_congr rfl; intro p hp
    simp only [mem_range] at hm hp
    have h1 : 2 * M - 1 - p < 2 * M := by omega
    have h3 : 2 * M - 1 - (2 * M - 1 - p) = p := by omega
    simp only [highpass, h1, ite_true, h3]
    have hc : (2 * k + m) % (2 * K) = (2 * k' + (2 * M - 1 - p)) % (2 * K) ↔
        (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p) := by
      rw [modeq_int]
      have e1 : (((2 * k' + (2 * M - 1 - p)) : ℕ) : ℤ) - ((2 * k + m : ℕ) : ℤ)
          = (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p) := by omega
      rw [e1]
      push_cast
      rfl
    by_cases hd : (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p)
    · rw [ite_eq_left (hc.2 hd), ite_eq_left hd]; ring
    · rw [ite_eq_right (fun hh => hd (hc.1 hh)), ite_eq_right hd]
  have step2 : ∑ m ∈ range (2 * M), ∑ p ∈ range (2 * M),
        (if (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p)
          then (-1 : ℝ) ^ (2 * M - 1 - p) * (h m * h p) else 0) =
      -∑ m ∈ range (2 * M), ∑ p ∈ range (2 * M),
        (if (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p)
          then (-1 : ℝ) ^ (2 * M - 1 - p) * (h m * h p) else 0) := by
    conv_lhs => rw [sum_comm]
    simp only [← sum_neg_distrib]
    apply sum_congr rfl; intro p hp
    apply sum_congr rfl; intro m hm
    simp only [mem_range] at hm hp
    by_cases hd : (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p)
    · have hd' : (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (p + m) := by
        rw [add_comm (p : ℤ)]; exact hd
      rw [ite_eq_left hd, ite_eq_left hd']
      have h2d : (2 : ℤ) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (m + p) :=
        dvd_trans (dvd_mul_right 2 (K : ℤ)) hd
      have hs := sgn_opp (2 * M - 1 - m) (2 * M - 1 - p) (by omega)
      rw [hs]; ring
    · have hd' : ¬ (2 * (K : ℤ)) ∣ (2 * (k' : ℤ) - 2 * k + 2 * M - 1) - (p + m) := by
        rw [add_comm (p : ℤ)]; exact hd
      rw [ite_eq_right hd, ite_eq_right hd', neg_zero]
  rw [step1]
  linarith

theorem cols_orthonormal (K : ℕ) (A B : ℕ → ℕ → ℝ)
    (hAA : ∀ k < K, ∀ k' < K, ∑ j ∈ range (2 * K), A k j * A k' j = if k = k' then 1 else 0)
    (hBB : ∀ k < K, ∀ k' < K, ∑ j ∈ range (2 * K), B k j * B k' j = if k = k' then 1 else 0)
    (hAB : ∀ k < K, ∀ k' < K, ∑ j ∈ range (2 * K), A k j * B k' j = 0) :
    ∀ i < 2 * K, ∀ j < 2 * K,
      ∑ k ∈ range K, (A k i * A k j + B k i * B k j) = if i = j then 1 else 0 := by
  let W : Matrix (Fin K ⊕ Fin K) (Fin (2 * K)) ℝ :=
    Matrix.of fun r j => Sum.elim (fun k : Fin K => A k j) (fun k : Fin K => B k j) r
  have h1 : W * W.transpose = 1 := by
    ext r r'
    rcases r with k | k <;> rcases r' with k' | k'
    · simp only [W, Matrix.mul_apply, Matrix.transpose_apply, Matrix.of_apply, Sum.elim_inl,
        Matrix.one_apply, Sum.inl.injEq]
      rw [Fin.sum_univ_eq_sum_range (fun j => A k j * A k' j), hAA k k.2 k' k'.2]
      simp [Fin.ext_iff]
    · simp only [W, Matrix.mul_apply, Matrix.transpose_apply, Matrix.of_apply, Sum.elim_inl,
        Sum.elim_inr, Matrix.one_apply]
      rw [Fin.sum_univ_eq_sum_range (fun j => A k j * B k' j), hAB k k.2 k' k'.2]
      simp
    · simp only [W, Matrix.mul_apply, Matrix.transpose_apply, Matrix.of_apply, Sum.elim_inl,
        Sum.elim_inr, Matrix.one_apply]
      rw [Fin.sum_univ_eq_sum_range (fun j => B k j * A k' j)]
      simp_rw [mul_comm (B _ _)]
      rw [hAB k' k'.2 k k.2]
      simp
    · simp only [W, Matrix.mul_apply, Matrix.transpose_apply, Matrix.of_apply, Sum.elim_inr,
        Matrix.one_apply, Sum.inr.injEq]
      rw [Fin.sum_univ_eq_sum_range (fun j => B k j * B k' j), hBB k k.2 k' k'.2]
      simp [Fin.ext_iff]
  have h2 : W.transpose * W = 1 :=
    (Matrix.mul_eq_one_comm_of_equiv (finSumFinEquiv.trans (finCongr (two_mul K).symm))).mp h1
  intro i hi j hj
  have := congrFun (congrFun h2 ⟨i, hi⟩) ⟨j, hj⟩
  simp only [W, Matrix.mul_apply, Matrix.transpose_apply, Matrix.of_apply, Fintype.sum_sum_type,
    Sum.elim_inl, Sum.elim_inr, Matrix.one_apply, Fin.mk.injEq] at this
  rw [sum_add_distrib, ← Fin.sum_univ_eq_sum_range (fun k => A k i * A k j),
    ← Fin.sum_univ_eq_sum_range (fun k => B k i * B k j)]
  exact this


theorem down_eq_rows (L : ℕ) (f : ℕ → ℝ) (n : ℕ) (s : ℕ → ℝ) (k : ℕ) (hn : 0 < n) :
    down L f n s k = ∑ j ∈ range n, rowF L f n k j * s j := by
  simp only [down, rowF, sum_mul]
  rw [sum_comm]
  apply sum_congr rfl
  intro m _
  simp only [ite_mul, zero_mul]
  rw [sum_ite_eq]
  simp [Nat.mod_lt _ hn]

theorem up_eq_rows (L : ℕ) (h g : ℕ → ℝ) (n : ℕ) (lo hi : ℕ → ℝ) (i : ℕ) :
    up L h g n lo hi i =
      ∑ k ∈ range (n / 2), (rowF L h n k i * lo k + rowF L g n k i * hi k) := by
  simp only [up, rowF, sum_mul, ← sum_add_distrib]
  apply sum_congr rfl; intro k _
  apply sum_congr rfl; intro m _
  split_ifs <;> simp

theorem up_congr (L : ℕ) (h g : ℕ → ℝ) (n : ℕ) (lo lo' hi : ℕ → ℝ)
    (hlo : ∀ k < n / 2, lo k = lo' k) : up L h g n lo hi = up L h g n lo' hi := by
  funext i
  simp only [up]
  apply sum_congr rfl; intro k hk
  rw [hlo k (mem_range.1 hk)]

theorem level_rebuild (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (K : ℕ) (hK : 0 < K) (s : ℕ → ℝ) :
    ∀ i < 2 * K, up (2 * M) h (highpass (2 * M) h) (2 * K) (down (2 * M) h (2 * K) s)
      (down (2 * M) (highpass (2 * M) h) (2 * K) s) i = s i := by
  intro i hi
  have hn : 0 < 2 * K := by omega
  have cols := cols_orthonormal K (rowF (2 * M) h (2 * K)) (rowF (2 * M) (highpass (2 * M) h) (2 * K))
    (fun k hk k' hk' => by
      rw [row_inner _ _ _ _ _ _ hn]; exact pair_hh M h h_taps h_orth K k k' hk hk')
    (fun k hk k' hk' => by
      rw [row_inner _ _ _ _ _ _ hn]; exact pair_gg M h h_taps h_orth K k k' hk hk')
    (fun k _ k' _ => by
      rw [row_inner _ _ _ _ _ _ hn]; exact pair_gh M h K k k') i hi
  rw [up_eq_rows, Nat.mul_div_cancel_left K two_pos]
  simp only [down_eq_rows _ _ _ s _ hn]
  simp_rw [mul_sum, ← sum_add_distrib]
  rw [sum_comm]
  have key : ∀ j ∈ range (2 * K),
      ∑ k ∈ range K, (rowF (2 * M) h (2 * K) k i * (rowF (2 * M) h (2 * K) k j * s j) +
        rowF (2 * M) (highpass (2 * M) h) (2 * K) k i *
          (rowF (2 * M) (highpass (2 * M) h) (2 * K) k j * s j))
      = (if i = j then 1 else 0) * s j := by
    intro j hj
    rw [← cols j (mem_range.1 hj), sum_mul]
    apply sum_congr rfl; intro k _; ring
  rw [sum_congr rfl key]
  simp [hi]

theorem adjoint (L : ℕ) (h g : ℕ → ℝ) (n : ℕ) (lo hi s : ℕ → ℝ) (hn : 0 < n) :
    ∑ i ∈ range n, s i * up L h g n lo hi i =
      ∑ k ∈ range (n / 2), (lo k * down L h n s k + hi k * down L g n s k) := by
  simp only [down_eq_rows _ _ _ s _ hn, up_eq_rows, mul_sum, ← sum_add_distrib]
  rw [sum_comm]
  apply sum_congr rfl; intro k _
  apply sum_congr rfl; intro j _
  ring

theorem cascade (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (J : ℕ) : ∀ (K : ℕ) (x : ℕ → ℝ), ∀ i < 2 ^ J * K,
      inverse (2 * M) h (highpass (2 * M) h) (2 ^ J * K)
        (forward (2 * M) h (highpass (2 * M) h) J (2 ^ J * K) x).1
        (forward (2 * M) h (highpass (2 * M) h) J (2 ^ J * K) x).2 i = x i := by
  induction J with
  | zero => intro K x i _; simp [forward, inverse]
  | succ J ih =>
    intro K x i hi
    have hN : 2 ^ (J + 1) * K = 2 * (2 ^ J * K) := by ring
    rw [hN] at hi ⊢
    have hK : 0 < 2 ^ J * K := by omega
    simp only [forward, inverse]
    rw [Nat.mul_div_cancel_left _ two_pos]
    rw [up_congr _ _ _ _ _ (down (2 * M) h (2 * (2 ^ J * K)) x) _
      (fun k hk => ih K _ k (by rwa [Nat.mul_div_cancel_left _ two_pos] at hk))]
    exact level_rebuild M h h_taps h_orth _ hK x i hi

/-- Mallat's algorithm inverts exactly. Let the low-pass filter `h` have an even number
`L = 2M` of taps (positions `0` to `L - 1`), satisfy `∑_m h[m] h[m + 2r] = 1` for `r = 0` and
`0` for every other shift `r`, and let the high-pass filter be `g[m] = (-1)^m h[L-1-m]`.
Take a record `x` whose length `N` is a multiple of `2^J`, with wrap-around ends. Then going
`J` levels down by filtering and halving, and running the same filters back up, returns every
sample of `x` exactly. -/
theorem mallat_cascade_rebuilds_exactly (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (J K : ℕ) (x : ℕ → ℝ) :
    let L := 2 * M
    let g := highpass L h
    let N := 2 ^ J * K
    let c := forward L h g J N x
    ∀ i < N, inverse L h g N c.1 c.2 i = x i := by
  intro L g N c i hi
  exact cascade M h h_taps h_orth J K x i hi

/-- Each level keeps energy (it is an orthogonal matrix): under the same filter conditions,
for a level of even length `n = 2K` with wrap-around ends, the sum of squares of its `2K`
numbers equals the sum of squares of its `K` coarse numbers and `K` details. -/
theorem mallat_level_keeps_energy (M : ℕ) (h : ℕ → ℝ)
    (h_taps : ∀ m, 2 * M ≤ m → h m = 0)
    (h_orth : ∀ r : ℕ, ∑ m ∈ range (2 * M), h m * h (m + 2 * r) = if r = 0 then 1 else 0)
    (K : ℕ) (s : ℕ → ℝ) :
    ∑ i ∈ range (2 * K), s i ^ 2 =
      ∑ k ∈ range K, (down (2 * M) h (2 * K) s k ^ 2
        + down (2 * M) (highpass (2 * M) h) (2 * K) s k ^ 2) := by
  rcases Nat.eq_zero_or_pos K with rfl | hK
  · simp
  have hn : 0 < 2 * K := by omega
  calc ∑ i ∈ range (2 * K), s i ^ 2
      = ∑ i ∈ range (2 * K), s i * up (2 * M) h (highpass (2 * M) h) (2 * K)
          (down (2 * M) h (2 * K) s) (down (2 * M) (highpass (2 * M) h) (2 * K) s) i := by
        apply sum_congr rfl; intro i hi
        rw [level_rebuild M h h_taps h_orth K hK s i (mem_range.1 hi)]; ring
    _ = ∑ k ∈ range (2 * K / 2), (down (2 * M) h (2 * K) s k * down (2 * M) h (2 * K) s k
          + down (2 * M) (highpass (2 * M) h) (2 * K) s k
            * down (2 * M) (highpass (2 * M) h) (2 * K) s k) := adjoint _ _ _ _ _ _ _ hn
    _ = _ := by
        rw [Nat.mul_div_cancel_left K two_pos]
        apply sum_congr rfl; intro k _; ring

/-- The work is linear: the cascade taken `J` levels down from a record of `N = 2^J K`
samples, with filters of `L` taps, costs `2 L K (2^J - 1) = 2 L N (1 - 2^(-J))` multiplies;
taken all the way down (`K = 1`, so `N = 2^J`) that is `2 L (N - 1)`. -/
theorem mallat_cascade_multiplies (L J K : ℕ) :
    cascadeCost L J (2 ^ J * K) = 2 * L * K * (2 ^ J - 1) := by
  induction J with
  | zero => simp [cascadeCost]
  | succ J ih =>
    have h2 : 2 ^ (J + 1) * K / 2 = 2 ^ J * K := by
      rw [pow_succ]; rw [show 2 ^ J * 2 * K = 2 * (2 ^ J * K) by ring]; omega
    rw [cascadeCost, h2, ih]
    obtain ⟨p, hp⟩ : ∃ p, 2 ^ J = p + 1 := ⟨2 ^ J - 1, by have := Nat.one_le_two_pow (n := J); omega⟩
    rw [pow_succ, hp]
    rw [show (p + 1) * 2 - 1 = 2 * p + 1 by omega, show p + 1 - 1 = p by omega]
    ring

-- The card's whole-number examples.
-- D4 (L = 4), N = 1024, ten levels: 8,184 multiplies, which is 2 × 4 × (1024 − 1).
example : cascadeCost 4 10 1024 = 8184 := by decide
example : 2 * 4 * (1024 - 1) = 8184 := by norm_num
-- Multiplies per level, L × length in: 4,096, 2,048, …, 8, adding to 8,184.
example : (List.range 10).map (fun j => 4 * (1024 / 2 ^ j)) =
    [4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8] := by decide
-- Numbers kept: 512 + 256 + … + 1 details plus 1 coarse number make 1,024.
example : (∑ j ∈ range 10, 1024 / 2 ^ (j + 1)) + 1 = 1024 := by decide
-- The dense matrix costs 1024 × 1024 = 1,048,576 multiplies; at 15.625 blocks a second the
-- cascade costs 127,875 a second and the matrix 16,384,000.
example : 1024 * 1024 = 1048576 := by norm_num
-- (16000 / 1024 blocks a second, written without the fraction.)
example : 16000 * 8184 = 127875 * 1024 ∧ 16000 * 1048576 = 16384000 * 1024 := by norm_num
-- The cost table: N = 256, 1024, 4096, 16384 taken all the way down with D4.
example : cascadeCost 4 8 256 = 2040 ∧ cascadeCost 4 10 1024 = 8184 ∧
    cascadeCost 4 12 4096 = 32760 ∧ cascadeCost 4 14 16384 = 131064 := by decide
-- Haar (L = 2) on 1,024 samples: 4,092 multiplies.
example : cascadeCost 2 10 1024 = 4092 := by decide
-- A record of 1,000 samples is 8 × 125: three halvings, then an odd length.
example : 1000 = 2 ^ 3 * 125 ∧ 125 % 2 = 1 := by norm_num
-- No halving: 2LNJ = 81,920 multiplies and N(J + 1) = 11,264 numbers.
example : 2 * 4 * 1024 * 10 = 81920 ∧ 1024 * (10 + 1) = 11264 := by norm_num

#print axioms corr_nat
#print axioms corr_int
#print axioms corr_mod
#print axioms row_inner
#print axioms sgn_same
#print axioms sgn_opp
#print axioms modeq_int
#print axioms pair_hh
#print axioms pair_gg
#print axioms pair_gh
#print axioms cols_orthonormal
#print axioms down_eq_rows
#print axioms up_eq_rows
#print axioms up_congr
#print axioms level_rebuild
#print axioms adjoint
#print axioms cascade
#print axioms mallat_cascade_rebuilds_exactly
#print axioms mallat_level_keeps_energy
#print axioms mallat_cascade_multiplies

end MallatFWT
