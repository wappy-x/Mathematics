-- Spectrograms: the ridge thickness of a swept whistle is smallest at one slice length and grows on both sides, no real window gets below the floor sqrt(c/(2π)), and half-overlapping Hann windows add up to exactly 1.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Tactic.NormNum

open Real

/-! A whistle's pitch climbs at `c` hertz per second. A window of length `T` seconds has
time spread `Δt_w = b * T` and frequency spread `Δf_w = a / T`, where `a` and `b` are the
two positive numbers fixed by the window's shape (Hann: `a = 1/√3`, `b ≈ 0.14145`).
The ridge thickness is `B = sqrt (Δf_w ^ 2 + c ^ 2 * Δt_w ^ 2)` (Step 3 of the card), so as a
function of the slice length it is `B T = sqrt ((a / T) ^ 2 + c ^ 2 * (b * T) ^ 2)`.

The Hann window of length `L`, as a function on all sample numbers, is
`1/2 - 1/2 * cos (2 π n / L)` for `0 ≤ n < L` and `0` elsewhere. -/

/-- The Hann window of length `L`, zero outside samples `0, …, L - 1`. -/
noncomputable def hannWin (L : ℕ) (n : ℤ) : ℝ :=
  if 0 ≤ n ∧ n < (L : ℤ) then 1 / 2 - 1 / 2 * Real.cos (2 * π * n / L) else 0

/-- The trade-off has a best slice length. With `Δt_w = b T` and `Δf_w = a / T`, the ridge
thickness `B(T) = sqrt (a² / T² + c² b² T²)` strictly falls as the slice grows up to
`T* = sqrt (a / (b c))` and strictly rises after it, so a short slice and a long slice both
blur the ridge; at `T*` the thickness is `sqrt (2 a b c)`. -/
theorem ridge_thickness_least_at_best_slice (a b c : ℝ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) :
    StrictAntiOn (fun T : ℝ => Real.sqrt ((a / T) ^ 2 + c ^ 2 * (b * T) ^ 2))
        (Set.Ioc 0 (Real.sqrt (a / (b * c)))) ∧
      StrictMonoOn (fun T : ℝ => Real.sqrt ((a / T) ^ 2 + c ^ 2 * (b * T) ^ 2))
        (Set.Ici (Real.sqrt (a / (b * c)))) ∧
      Real.sqrt ((a / Real.sqrt (a / (b * c))) ^ 2 + c ^ 2 * (b * Real.sqrt (a / (b * c))) ^ 2)
        = Real.sqrt (2 * a * b * c) := by
  have hab : 0 < a / (b * c) := by positivity
  set S := Real.sqrt (a / (b * c)) with hS
  have hSpos : 0 < S := Real.sqrt_pos.mpr hab
  have hS2 : S ^ 2 = a / (b * c) := Real.sq_sqrt hab.le
  have key : ∀ x y : ℝ, 0 < x → 0 < y →
      (a / x) ^ 2 + c ^ 2 * (b * x) ^ 2 - ((a / y) ^ 2 + c ^ 2 * (b * y) ^ 2)
        = (y ^ 2 - x ^ 2) * (a ^ 2 - (c * b * x * y) ^ 2) / (x ^ 2 * y ^ 2) := by
    intro x y hx hy
    field_simp
    ring
  have hbcS : b * c * S ^ 2 = a := by rw [hS2]; field_simp
  refine ⟨?_, ?_, ?_⟩
  · intro x hx y hy hxy
    obtain ⟨hx0, hxS⟩ := hx
    obtain ⟨hy0, hyS⟩ := hy
    apply Real.sqrt_lt_sqrt (by positivity)
    have hxy2 : x * y < S ^ 2 := by nlinarith
    have h1 : c * b * x * y < a := by
      have : b * c * (x * y) < b * c * S ^ 2 := by
        apply mul_lt_mul_of_pos_left hxy2 (by positivity)
      nlinarith
    have h2 : 0 < c * b * x * y := by positivity
    have h3 : 0 < a ^ 2 - (c * b * x * y) ^ 2 := by nlinarith
    have h4 : 0 < y ^ 2 - x ^ 2 := by nlinarith
    have := key x y hx0 hy0
    have h5 : 0 < (y ^ 2 - x ^ 2) * (a ^ 2 - (c * b * x * y) ^ 2) / (x ^ 2 * y ^ 2) := by
      positivity
    linarith
  · intro x hx y hy hxy
    simp only [Set.mem_Ici] at hx hy
    have hx0 : 0 < x := lt_of_lt_of_le hSpos hx
    have hy0 : 0 < y := by linarith
    apply Real.sqrt_lt_sqrt (by positivity)
    have hxy2 : S ^ 2 < x * y := by nlinarith
    have h1 : a < c * b * x * y := by
      have : b * c * S ^ 2 < b * c * (x * y) := by
        apply mul_lt_mul_of_pos_left hxy2 (by positivity)
      nlinarith
    have h3 : 0 < (c * b * x * y) ^ 2 - a ^ 2 := by nlinarith
    have h4 : 0 < y ^ 2 - x ^ 2 := by nlinarith
    have := key x y hx0 hy0
    have h5 : 0 < (y ^ 2 - x ^ 2) * ((c * b * x * y) ^ 2 - a ^ 2) / (x ^ 2 * y ^ 2) := by
      positivity
    have h6 : (y ^ 2 - x ^ 2) * (a ^ 2 - (c * b * x * y) ^ 2) / (x ^ 2 * y ^ 2)
        = -((y ^ 2 - x ^ 2) * ((c * b * x * y) ^ 2 - a ^ 2) / (x ^ 2 * y ^ 2)) := by ring
    linarith
  · congr 1
    rw [div_pow, mul_pow, hS2]
    field_simp
    ring

/-- The floor under every real window. If the window's spreads obey Gabor's inequality
`Δt_w * Δf_w ≥ 1 / (4π)` (proved on the Uncertainty card), then a whistle climbing at `c`
hertz per second has ridge thickness `sqrt (Δf_w² + c² Δt_w²)` at least `sqrt (c / (2π))`,
whatever the window's shape or length. -/
theorem ridge_thickness_ge_gabor_floor (c dt df : ℝ) (hc : 0 < c)
    (hgabor : 1 / (4 * π) ≤ dt * df) :
    Real.sqrt (c / (2 * π)) ≤ Real.sqrt (df ^ 2 + c ^ 2 * dt ^ 2) := by
  apply Real.sqrt_le_sqrt
  have h1 : 0 ≤ (df - c * dt) ^ 2 := sq_nonneg _
  have h2 : c / (2 * π) = 2 * c * (1 / (4 * π)) := by
    field_simp
    ring
  have h3 : 2 * c * (1 / (4 * π)) ≤ 2 * c * (dt * df) :=
    mul_le_mul_of_nonneg_left hgabor (by positivity)
  nlinarith

/-- Half-overlapping Hann slices lose nothing: Hann windows of length `L = 2M`, placed every
`M = L/2` samples, add up to exactly 1 at every sample. -/
theorem hann_half_overlap_sums_to_one (M : ℕ) (hM : 0 < M) (n : ℤ) :
    ∑ᶠ m : ℤ, hannWin (2 * M) (n - m * M) = 1 := by
  have hMz : (0:ℤ) < M := by exact_mod_cast hM
  set q := n / (M:ℤ) with hq
  set r := n % (M:ℤ) with hr
  have hr0 : 0 ≤ r := Int.emod_nonneg _ hMz.ne'
  have hrM : r < M := Int.emod_lt_of_pos _ hMz
  have hn : n = r + q * M := (Int.emod_add_ediv_mul n M).symm
  rw [finsum_eq_sum_of_support_subset _ (s := {q - 1, q}) ?_]
  · rw [Finset.sum_pair (by omega)]
    have e1 : n - (q - 1) * M = r + M := by rw [hn]; ring
    have e2 : n - q * M = r := by rw [hn]; ring
    rw [e1, e2]
    simp only [hannWin]
    rw [if_pos (by push_cast; omega), if_pos (by push_cast; omega)]
    have hMr : (0:ℝ) < M := by exact_mod_cast hM
    have : 2 * π * ((r + M : ℤ) : ℝ) / ((2 * M : ℕ) : ℝ)
        = 2 * π * (r : ℝ) / ((2 * M : ℕ) : ℝ) + π := by
      push_cast
      field_simp
    rw [this, Real.cos_add_pi]
    ring
  · intro m hm
    simp only [Function.mem_support, hannWin] at hm
    simp only [Finset.coe_insert, Finset.coe_singleton, Set.mem_insert_iff,
      Set.mem_singleton_iff]
    by_contra h
    push_neg at h
    apply hm
    rw [if_neg]
    rintro ⟨h1, h2⟩
    push_cast at h2
    have e : n - m * M = r + (q - m) * M := by rw [hn]; ring
    rw [e] at h1 h2
    rcases le_or_gt (q - m) (-1) with hk | hk
    · have : (q - m) * M ≤ -1 * M := by nlinarith
      omega
    · have hk2 : 2 ≤ q - m := by omega
      have : 2 * M ≤ (q - m) * M := by nlinarith
      omega

/-! The card's exact worked numbers (times in seconds, as fractions). -/

-- Sweep rate: (4000 - 2000) Hz over half a second is 4000 Hz per second.
example : ((4000 : ℚ) - 2000) / (1 / 2) = 4000 := by norm_num
-- 8000 samples at 16000 per second is half a second.
example : (8000 : ℚ) / 16000 = 1 / 2 := by norm_num
-- Window 512 samples, hop 256: 30 slices fit in 8000 samples.
example : (8000 - 512) / 256 + 1 = 30 := by decide
example : 512 / 2 = 256 := by decide
-- Slice length 512 / 16000 s = 32 ms; hop 256 / 16000 s = 16 ms.
example : (512 : ℚ) / 16000 = 32 / 1000 := by norm_num
example : (256 : ℚ) / 16000 = 16 / 1000 := by norm_num
-- Bins 16000 / 512 = 31.25 Hz apart.
example : (16000 : ℚ) / 512 = 3125 / 100 := by norm_num
-- Slice 15's centre: (15 * 256 + 256) / 16000 s = 256 ms, where the whistle is at 3024 Hz.
example : ((15 * 256 + 256 : ℚ)) / 16000 = 256 / 1000 := by norm_num
example : (2000 : ℚ) + 4000 * (256 / 1000) = 3024 := by norm_num
-- The ridge, slice by slice: slices 0, 5, 10, 20, 25, 29 sit at 2064, 2384, 2704, 3344, 3664, 3920 Hz.
example : (2000 : ℚ) + 4000 * ((0 * 256 + 256) / 16000) = 2064 := by norm_num
example : (2000 : ℚ) + 4000 * ((5 * 256 + 256) / 16000) = 2384 := by norm_num
example : (2000 : ℚ) + 4000 * ((10 * 256 + 256) / 16000) = 2704 := by norm_num
example : (2000 : ℚ) + 4000 * ((20 * 256 + 256) / 16000) = 3344 := by norm_num
example : (2000 : ℚ) + 4000 * ((25 * 256 + 256) / 16000) = 3664 := by norm_num
example : (2000 : ℚ) + 4000 * ((29 * 256 + 256) / 16000) = 3920 := by norm_num
-- The slice centred on 250 ms: the whistle is at exactly 3000 Hz there.
example : (2000 : ℚ) + 4000 * (250 / 1000) = 3000 := by norm_num
-- Mistake, label by start: slice 15 starts at 240 ms, when the whistle was at 2960 Hz.
example : ((15 * 256 : ℚ)) / 16000 = 240 / 1000 := by norm_num
example : (2000 : ℚ) + 4000 * (240 / 1000) = 2960 := by norm_num
-- Mistake, hop of the full window: the Hann window is 0 at its first sample.
example : hannWin 512 0 = 0 := by norm_num [hannWin]

#print axioms ridge_thickness_least_at_best_slice
#print axioms ridge_thickness_ge_gabor_floor
#print axioms hann_half_overlap_sums_to_one
