-- Wavelets: the Haar ladder rebuilds every row exactly and keeps its energy, independent pixel noise of one size stays that size in every coefficient, and flat stretches give zero detail.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.Interval.Finset.SuccPred

open Finset MeasureTheory ProbabilityTheory

/-- One rung, the coarse half: s[k] = (x[2k] + x[2k+1]) / √2. -/
noncomputable def haarSum (x : ℕ → ℝ) (k : ℕ) : ℝ := (x (2 * k) + x (2 * k + 1)) / Real.sqrt 2

/-- One rung, the detail half: d[k] = (x[2k] - x[2k+1]) / √2. -/
noncomputable def haarDiff (x : ℕ → ℝ) (k : ℕ) : ℝ := (x (2 * k) - x (2 * k + 1)) / Real.sqrt 2

/-- The coarse picture at level j: s_0 = x, and s_j is the pair sums of s_(j-1). -/
noncomputable def coarse (x : ℕ → ℝ) : ℕ → ℕ → ℝ
  | 0 => x
  | j + 1 => haarSum (coarse x j)

/-- The detail at level j (j = 1 is the finest): d_j is the pair differences of s_(j-1). -/
noncomputable def detail (x : ℕ → ℝ) (j : ℕ) : ℕ → ℝ := haarDiff (coarse x (j - 1))

/-- Run one rung backwards: s_(j-1)[2k] = (s_j[k] + d_j[k]) / √2 and
s_(j-1)[2k+1] = (s_j[k] - d_j[k]) / √2. -/
noncomputable def haarMerge (s d : ℕ → ℝ) (n : ℕ) : ℝ :=
  if n % 2 = 0 then (s (n / 2) + d (n / 2)) / Real.sqrt 2
  else (s (n / 2) - d (n / 2)) / Real.sqrt 2

/-- Rebuild from the level-J coarse picture s and the details d_J, ..., d_1, coarsest first. -/
noncomputable def rebuild (d : ℕ → ℕ → ℝ) : ℕ → (ℕ → ℝ) → (ℕ → ℝ)
  | 0, s => s
  | J + 1, s => rebuild d J (haarMerge s (d (J + 1)))


lemma haar_merge_inverse (c : ℕ → ℝ) : haarMerge (haarSum c) (haarDiff c) = c := by
  funext n
  have h2 : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
  unfold haarMerge haarSum haarDiff
  rcases Nat.even_or_odd' n with ⟨k, rfl | rfl⟩
  · have h1 : (2 * k) % 2 = 0 := by omega
    have h3 : 2 * k / 2 = k := by omega
    simp only [h1, h3, ↓reduceIte]
    rw [← add_div, div_div, h2]
    ring
  · have h1 : ¬ (2 * k + 1) % 2 = 0 := by omega
    have h3 : (2 * k + 1) / 2 = k := by omega
    simp only [h1, h3, ↓reduceIte]
    rw [← sub_div, div_div, h2]
    ring

lemma haar_pair_energy (c : ℕ → ℝ) (M : ℕ) :
    ∑ n ∈ range (2 * M), c n ^ 2 =
      ∑ k ∈ range M, haarSum c k ^ 2 + ∑ k ∈ range M, haarDiff c k ^ 2 := by
  induction M with
  | zero => simp
  | succ M ih =>
    rw [show 2 * (M + 1) = 2 * M + 1 + 1 by ring, sum_range_succ, sum_range_succ, ih,
      sum_range_succ, sum_range_succ]
    have : haarSum c M ^ 2 + haarDiff c M ^ 2 = c (2 * M) ^ 2 + c (2 * M + 1) ^ 2 := by
      unfold haarSum haarDiff
      rw [div_pow, div_pow, Real.sq_sqrt (by norm_num)]
      ring
    linarith

lemma haar_energy (x : ℕ → ℝ) (J : ℕ) : ∀ m : ℕ, ∑ n ∈ range (2 ^ J * m), x n ^ 2 =
    ∑ k ∈ range m, coarse x J k ^ 2 +
      ∑ j ∈ Icc 1 J, ∑ k ∈ range (2 ^ (J - j) * m), detail x j k ^ 2 := by
  induction J with
  | zero => intro m; simp [coarse]
  | succ J ih =>
    intro m
    rw [show 2 ^ (J + 1) * m = 2 ^ J * (2 * m) by ring, ih (2 * m), haar_pair_energy,
      ← Finset.insert_Icc_right_eq_Icc_add_one (by omega : 1 ≤ J + 1),
      sum_insert (by simp)]
    have hd : detail x (J + 1) = haarDiff (coarse x J) := rfl
    have hc : coarse x (J + 1) = haarSum (coarse x J) := rfl
    have hsum : ∑ j ∈ Icc 1 J, ∑ k ∈ range (2 ^ (J - j) * (2 * m)), detail x j k ^ 2 =
        ∑ j ∈ Icc 1 J, ∑ k ∈ range (2 ^ (J + 1 - j) * m), detail x j k ^ 2 := by
      apply sum_congr rfl
      intro j hj
      rw [mem_Icc] at hj
      have : 2 ^ (J - j) * (2 * m) = 2 ^ (J + 1 - j) * m := by
        rw [show J + 1 - j = (J - j) + 1 by omega, pow_succ]; ring
      rw [this]
    rw [hsum, hd, hc, Nat.sub_self, pow_zero, one_mul]
    ring

lemma haar_rebuild (x : ℕ → ℝ) (J : ℕ) : rebuild (detail x) J (coarse x J) = x := by
  induction J with
  | zero => rfl
  | succ J ih =>
    show rebuild (detail x) J (haarMerge (haarSum (coarse x J)) (haarDiff (coarse x J))) = x
    rw [haar_merge_inverse, ih]

lemma coarse_flat (x : ℕ → ℝ) (c : ℝ) (i : ℕ) : ∀ k,
    (∀ n, 2 ^ i * k ≤ n → n < 2 ^ i * (k + 1) → x n = c) → coarse x i k = c * Real.sqrt 2 ^ i := by
  induction i with
  | zero => intro k h; simpa [coarse] using h k (by simp) (by simp)
  | succ i ih =>
    intro k h
    have e1 : 2 ^ (i + 1) * k = 2 ^ i * (2 * k) := by ring
    have e2 : 2 ^ (i + 1) * (k + 1) = 2 ^ i * (2 * k + 1 + 1) := by ring
    rw [e1, e2] at h
    have h0 := ih (2 * k) (fun n h1 h2 => h n h1
      (Nat.lt_of_lt_of_le h2 (Nat.mul_le_mul_left _ (by omega))))
    have h1 := ih (2 * k + 1) (fun n h1 h2 => h n
      (le_trans (Nat.mul_le_mul_left _ (by omega)) h1) h2)
    show (coarse x i (2 * k) + coarse x i (2 * k + 1)) / Real.sqrt 2 = _
    rw [h0, h1, pow_succ]
    have hs : Real.sqrt 2 ≠ 0 := by positivity
    have h2 : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
    have e : c * (Real.sqrt 2 ^ i * Real.sqrt 2) * Real.sqrt 2 =
        c * Real.sqrt 2 ^ i * (Real.sqrt 2 * Real.sqrt 2) := by ring
    rw [div_eq_iff hs, e, h2]
    ring

lemma coarse_formula (x : ℕ → ℝ) (i : ℕ) : ∀ k,
    coarse x i k = (∑ n ∈ range (2 ^ i), x (2 ^ i * k + n)) / Real.sqrt 2 ^ i := by
  induction i with
  | zero => intro k; simp [coarse]
  | succ i ih =>
    intro k
    show (coarse x i (2 * k) + coarse x i (2 * k + 1)) / Real.sqrt 2 = _
    rw [ih, ih, show 2 ^ (i + 1) = 2 ^ i + 2 ^ i by ring, sum_range_add, pow_succ]
    have hA : ∑ n ∈ range (2 ^ i), x (2 ^ i * (2 * k) + n) =
        ∑ n ∈ range (2 ^ i), x ((2 ^ i + 2 ^ i) * k + n) := by
      apply sum_congr rfl; intro n _; congr 1; ring
    have hB : ∑ n ∈ range (2 ^ i), x (2 ^ i * (2 * k + 1) + n) =
        ∑ n ∈ range (2 ^ i), x ((2 ^ i + 2 ^ i) * k + (2 ^ i + n)) := by
      apply sum_congr rfl; intro n _; congr 1; ring
    rw [hA, hB]
    have hs : Real.sqrt 2 ≠ 0 := by positivity
    field_simp

lemma detail_formula (x : ℕ → ℝ) (i k : ℕ) :
    detail x (i + 1) k = ∑ n ∈ range (2 ^ (i + 1)),
      ((if n < 2 ^ i then 1 else -1) / Real.sqrt 2 ^ (i + 1)) * x (2 ^ (i + 1) * k + n) := by
  show (coarse x i (2 * k) - coarse x i (2 * k + 1)) / Real.sqrt 2 = _
  rw [coarse_formula, coarse_formula, show 2 ^ (i + 1) = 2 ^ i + 2 ^ i by ring, sum_range_add]
  have hA : ∑ n ∈ range (2 ^ i),
      ((if n < 2 ^ i then 1 else -1) / Real.sqrt 2 ^ (i + 1)) * x ((2 ^ i + 2 ^ i) * k + n) =
      (∑ n ∈ range (2 ^ i), x (2 ^ i * (2 * k) + n)) / Real.sqrt 2 ^ (i + 1) := by
    rw [sum_div]
    apply sum_congr rfl; intro n hn
    rw [mem_range] at hn
    simp only [hn, ↓reduceIte]
    rw [show (2 ^ i + 2 ^ i) * k + n = 2 ^ i * (2 * k) + n by ring]
    ring
  have hB : ∑ n ∈ range (2 ^ i), ((if 2 ^ i + n < 2 ^ i then 1 else -1) /
      Real.sqrt 2 ^ (i + 1)) * x ((2 ^ i + 2 ^ i) * k + (2 ^ i + n)) =
      -((∑ n ∈ range (2 ^ i), x (2 ^ i * (2 * k + 1) + n)) / Real.sqrt 2 ^ (i + 1)) := by
    rw [sum_div, ← sum_neg_distrib]
    apply sum_congr rfl; intro n _
    have hn' : ¬ 2 ^ i + n < 2 ^ i := by omega
    simp only [hn', ↓reduceIte]
    rw [show (2 ^ i + 2 ^ i) * k + (2 ^ i + n) = 2 ^ i * (2 * k + 1) + n by ring]
    ring
  rw [hA, hB, pow_succ]
  ring

lemma variance_lin {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ℝ) (σ : ℝ) (hind : iIndepFun X μ) (hL2 : ∀ n, MemLp (X n) 2 μ)
    (hvar : ∀ n, variance (X n) μ = σ ^ 2) (a : ℕ → ℝ) (b M : ℕ) :
    variance (fun ω => ∑ n ∈ range M, a n * X (b + n) ω) μ = σ ^ 2 * ∑ n ∈ range M, a n ^ 2 := by
  have : (fun ω => ∑ n ∈ range M, a n * X (b + n) ω) =
      ∑ n ∈ range M, (fun ω => a n * X (b + n) ω) := by
    funext ω; simp [Finset.sum_apply]
  rw [this, IndepFun.variance_sum]
  · rw [mul_sum]
    apply sum_congr rfl; intro n _
    rw [variance_const_mul, hvar]; ring
  · intro n _; exact (hL2 _).const_mul (a n)
  · intro n _ m _ hnm
    have := hind.indepFun (show b + n ≠ b + m by omega)
    exact this.comp (measurable_const_mul (a n)) (measurable_const_mul (a m))

lemma sqrt2_pow_sq (i : ℕ) : (Real.sqrt 2 ^ i) ^ 2 = 2 ^ i := by
  rw [← pow_mul, mul_comm, pow_mul, Real.sq_sqrt (by norm_num)]

/-- **The Haar ladder rebuilds the row exactly and keeps its energy.** Take any row x of
N pixels with N a multiple of 2^J, N = 2^J m. Run J rungs of the ladder: the coarse picture
s_J (m numbers) and the details d_1, ..., d_J (2^(J-j) m numbers at level j). Running the
pairing backwards from s_J and the details returns every pixel of x exactly, and the sum of
squares of the N pixels equals the sum of squares of the N coefficients. -/
theorem haar_ladder_rebuilds_exactly_and_keeps_energy (x : ℕ → ℝ) (J m N : ℕ)
    (hN : N = 2 ^ J * m) :
    rebuild (detail x) J (coarse x J) = x ∧
      ∑ n ∈ range N, x n ^ 2 =
        ∑ k ∈ range m, coarse x J k ^ 2 +
          ∑ j ∈ Icc 1 J, ∑ k ∈ range (2 ^ (J - j) * m), detail x j k ^ 2 := by
  subst hN
  exact ⟨haar_rebuild x J, haar_energy x J m⟩

/-- **The noise is the same size in every coefficient.** If the pixel noise values X_0, X_1, ...
are independent, each with standard deviation σ (variance σ^2, finite), then every detail
coefficient d_j[k] (j ≥ 1) and every coarse coefficient s_j[k] of the noise also has
variance σ^2: the √2 keeps the noise from shrinking from rung to rung. -/
theorem haar_noise_same_size_every_coefficient {Ω : Type*} [MeasurableSpace Ω]
    {μ : Measure Ω} [IsProbabilityMeasure μ] (X : ℕ → Ω → ℝ) (σ : ℝ)
    (hind : iIndepFun X μ) (hL2 : ∀ n, MemLp (X n) 2 μ) (hvar : ∀ n, variance (X n) μ = σ ^ 2)
    (j k : ℕ) :
    (1 ≤ j → variance (fun ω => detail (fun n => X n ω) j k) μ = σ ^ 2) ∧
      variance (fun ω => coarse (fun n => X n ω) j k) μ = σ ^ 2 := by
  constructor
  · intro hj
    obtain ⟨i, rfl⟩ : ∃ i, j = i + 1 := ⟨j - 1, by omega⟩
    simp_rw [detail_formula]
    rw [variance_lin X σ hind hL2 hvar]
    have : ∀ n ∈ range (2 ^ (i + 1)),
        ((if n < 2 ^ i then (1 : ℝ) else -1) / Real.sqrt 2 ^ (i + 1)) ^ 2 = 1 / 2 ^ (i + 1) := by
      intro n _
      rw [div_pow, sqrt2_pow_sq]
      split_ifs <;> norm_num
    rw [sum_congr rfl this, sum_const, card_range, nsmul_eq_mul]
    push_cast
    field_simp
  · have hf : (fun ω => coarse (fun n => X n ω) j k) =
        fun ω => ∑ n ∈ range (2 ^ j), (1 / Real.sqrt 2 ^ j) * X (2 ^ j * k + n) ω := by
      funext ω
      rw [coarse_formula, sum_div]
      apply sum_congr rfl; intro n _; ring
    rw [hf, variance_lin X σ hind hL2 hvar, sum_const, card_range, nsmul_eq_mul, div_pow,
      sqrt2_pow_sq]
    push_cast
    field_simp

/-- **Flat paper has no detail at any level.** If the row is constant across the 2^j pixels
2^j k, ..., 2^j k + 2^j - 1 that the level-j detail d_j[k] looks at, then d_j[k] = 0. -/
theorem haar_detail_zero_on_flat_stretch (x : ℕ → ℝ) (c : ℝ) (j k : ℕ) (hj : 1 ≤ j)
    (hflat : ∀ n, 2 ^ j * k ≤ n → n < 2 ^ j * (k + 1) → x n = c) :
    detail x j k = 0 := by
  obtain ⟨i, rfl⟩ : ∃ i, j = i + 1 := ⟨j - 1, by omega⟩
  have e1 : 2 ^ (i + 1) * k = 2 ^ i * (2 * k) := by ring
  have e2 : 2 ^ (i + 1) * (k + 1) = 2 ^ i * (2 * k + 1 + 1) := by ring
  rw [e1, e2] at hflat
  have h0 := coarse_flat x c i (2 * k) (fun n h1 h2 => hflat n h1
    (Nat.lt_of_lt_of_le h2 (Nat.mul_le_mul_left _ (by omega))))
  have h1 := coarse_flat x c i (2 * k + 1) (fun n h1 h2 => hflat n
    (le_trans (Nat.mul_le_mul_left _ (by omega)) h1) h2)
  show (coarse x i (2 * k) - coarse x i (2 * k + 1)) / Real.sqrt 2 = 0
  rw [h0, h1, sub_self, zero_div]

-- The row: 512 pixels = 64 × 8 = 64 × 2^3, so three rungs fit with no padding.
example : (512 : ℕ) = 2 ^ 3 * 64 := by norm_num
-- The ladder's boxes: 256, 128 and 64 details plus 64 coarse numbers make the 512 pixels.
example : 512 / 2 = 256 ∧ 512 / 4 = 128 ∧ 512 / 8 = 64 ∧ 64 + 64 + 128 + 256 = 512 := by norm_num
-- Energy of one pair, pixels 40 and 41 (239 and 34): (a+b)^2 + (a-b)^2 = 2(a^2 + b^2).
example : (239 + 34) ^ 2 + (239 - 34) ^ 2 = 2 * (239 ^ 2 + 34 ^ 2) := by norm_num
-- A paper pixel next to an ink pixel differ by 215 - 50 = 165 grey levels.
example : 215 - 50 = 165 := by norm_num
-- The flat pair 52, 45: zero its detail and rebuild; both pixels come back as 97/2 = 48.5.
example : ((52 + 45) / Real.sqrt 2 + 0) / Real.sqrt 2 = 97 / 2 := by
  rw [add_zero, div_div, Real.mul_self_sqrt (by norm_num)]; norm_num
-- The flat pair 225, 220 comes back as 445/2 = 222.5 twice.
example : ((225 + 220) / Real.sqrt 2 + 0) / Real.sqrt 2 = 445 / 2 := by
  rw [add_zero, div_div, Real.mul_self_sqrt (by norm_num)]; norm_num
-- Details kept: 14 + 26 + 21 = 61 of the 256 + 128 + 64 = 448.
example : 14 + 26 + 21 = 61 ∧ 256 + 128 + 64 = 448 := by norm_num
-- The pencil line should read 215 - 40 = 175.
example : 215 - 40 = 175 := by norm_num

#print axioms haar_merge_inverse
#print axioms haar_pair_energy
#print axioms haar_energy
#print axioms haar_rebuild
#print axioms coarse_flat
#print axioms coarse_formula
#print axioms detail_formula
#print axioms variance_lin
#print axioms sqrt2_pow_sq
#print axioms haar_ladder_rebuilds_exactly_and_keeps_energy
#print axioms haar_noise_same_size_every_coefficient
#print axioms haar_detail_zero_on_flat_stretch
