-- Compression by wavelets: keeping the N largest coefficients in an orthonormal basis leaves a squared error equal to the sum of the dropped squares, no other N-term choice does better, and a 1/k decay of the sorted sizes bounds that error by C²/N.
import Mathlib.Analysis.InnerProductSpace.PiL2

open Finset RealInnerProductSpace

theorem wavelet_coeff_of_partial_sum
    {ι E : Type*} [Fintype ι] [DecidableEq ι]
    [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (b : OrthonormalBasis ι ℝ E) (f : E) (J : Finset ι) (a : ι → ℝ) (i : ι) :
    ⟪b i, f - ∑ n ∈ J, a n • b n⟫ = ⟪b i, f⟫ - if i ∈ J then a i else 0 := by
  rw [inner_sub_right]
  congr 1
  simp [inner_sum, inner_smul_right, orthonormal_iff_ite.mp b.orthonormal]

#print axioms wavelet_coeff_of_partial_sum

theorem wavelet_error_eq_sum
    {ι E : Type*} [Fintype ι] [DecidableEq ι]
    [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (b : OrthonormalBasis ι ℝ E) (f : E) (J : Finset ι) (a : ι → ℝ) :
    ‖f - ∑ n ∈ J, a n • b n‖ ^ 2 =
      ∑ i ∈ J, (⟪b i, f⟫ - a i) ^ 2 + ∑ i ∈ Jᶜ, ⟪b i, f⟫ ^ 2 := by
  rw [← b.sum_sq_inner_right, ← Finset.sum_add_sum_compl J]
  congr 1
  · refine Finset.sum_congr rfl fun i hi => ?_
    simp [wavelet_coeff_of_partial_sum, hi]
  · refine Finset.sum_congr rfl fun i hi => ?_
    simp [wavelet_coeff_of_partial_sum, Finset.mem_compl.mp hi]

#print axioms wavelet_error_eq_sum

theorem wavelet_dropped_squares
    {ι E : Type*} [Fintype ι] [DecidableEq ι]
    [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (b : OrthonormalBasis ι ℝ E) (f : E) (I : Finset ι) :
    ‖f - ∑ n ∈ I, ⟪b n, f⟫ • b n‖ ^ 2 = ∑ n ∈ Iᶜ, ⟪b n, f⟫ ^ 2 := by
  rw [wavelet_error_eq_sum]
  simp

#print axioms wavelet_dropped_squares

theorem wavelet_sum_sdiff_le
    {ι : Type*} [DecidableEq ι] (c : ι → ℝ) (I J : Finset ι) (hcard : J.card = I.card)
    (hI : ∀ n ∈ I, ∀ m ∉ I, |c m| ≤ |c n|) :
    ∑ n ∈ J \ I, c n ^ 2 ≤ ∑ n ∈ I \ J, c n ^ 2 := by
  have hk : (J \ I).card = (I \ J).card := Finset.card_sdiff_comm hcard
  have key : ∀ x ∈ J \ I, ∀ y ∈ I \ J, c x ^ 2 ≤ c y ^ 2 := by
    intro x hx y hy
    rw [Finset.mem_sdiff] at hx hy
    have := hI y hy.1 x hx.2
    nlinarith [abs_nonneg (c x), sq_abs (c x), sq_abs (c y)]
  have h2 : ((I \ J).card : ℝ) * ∑ x ∈ J \ I, c x ^ 2 ≤ ((J \ I).card : ℝ) * ∑ y ∈ I \ J, c y ^ 2 := by
    have e1 : ((I \ J).card : ℝ) * ∑ x ∈ J \ I, c x ^ 2 = ∑ x ∈ J \ I, ∑ y ∈ I \ J, c x ^ 2 := by
      simp [Finset.mul_sum]
    have e2 : ((J \ I).card : ℝ) * ∑ y ∈ I \ J, c y ^ 2 = ∑ x ∈ J \ I, ∑ y ∈ I \ J, c y ^ 2 := by
      simp [Finset.mul_sum]
    rw [e1, e2]
    exact Finset.sum_le_sum fun x hx => Finset.sum_le_sum fun y hy => key x hx y hy
  rcases Nat.eq_zero_or_pos (I \ J).card with h0 | hpos
  · rw [h0] at hk
    rw [Finset.card_eq_zero.mp hk, Finset.card_eq_zero.mp h0]
  · rw [hk] at h2
    exact le_of_mul_le_mul_left h2 (by exact_mod_cast hpos)

#print axioms wavelet_sum_sdiff_le

theorem wavelet_tail_inv_sq_le (N : ℕ) (hN : 0 < N) (M : ℕ) :
    ∑ i ∈ range M, (if N ≤ i then 1 / ((i : ℝ) + 1) ^ 2 else 0)
      ≤ 1 / (N : ℝ) - 1 / (max M N : ℕ) := by
  induction M with
  | zero => simp
  | succ M ih =>
    rw [Finset.sum_range_succ]
    by_cases h : N ≤ M
    · rw [ite_eq_left h, max_eq_left h] at *
      rw [max_eq_left (by omega : N ≤ M + 1)]
      have hM : (0 : ℝ) < M := by exact_mod_cast (lt_of_lt_of_le hN h)
      have key : 1 / ((M : ℝ) + 1) ^ 2 ≤ 1 / (M : ℝ) - 1 / ((M + 1 : ℕ) : ℝ) := by
        push_cast
        rw [div_sub_div _ _ hM.ne' (by positivity), div_le_div_iff₀ (by positivity) (by positivity)]
        nlinarith
      linarith
    · rw [ite_eq_right h, max_eq_right (by omega : M ≤ N)] at *
      rw [max_eq_right (by omega : M + 1 ≤ N)]
      linarith

#print axioms wavelet_tail_inv_sq_le

/-- Keep the `N` largest coefficients `c n = ⟪b n, f⟫` of a photo `f` in an orthonormal basis `b`
(the kept places `I` hold coefficients at least as large in size as every dropped one).
Then the squared error of the rebuilt photo is exactly the sum of the squares thrown away,
and no other choice of `N` places `J`, with any weights `a n` on them, gives a smaller error:
keeping the largest is the best `N`-term approximation. -/
theorem keep_largest_error_eq_sum_dropped_squares_and_is_best
    {ι E : Type*} [Fintype ι] [DecidableEq ι]
    [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (b : OrthonormalBasis ι ℝ E) (f : E) (I : Finset ι)
    (hI : ∀ n ∈ I, ∀ m ∉ I, |⟪b m, f⟫| ≤ |⟪b n, f⟫|) :
    ‖f - ∑ n ∈ I, ⟪b n, f⟫ • b n‖ ^ 2 = ∑ n ∈ Iᶜ, ⟪b n, f⟫ ^ 2 ∧
    ∀ (J : Finset ι), J.card = I.card → ∀ a : ι → ℝ,
      ‖f - ∑ n ∈ I, ⟪b n, f⟫ • b n‖ ^ 2 ≤ ‖f - ∑ n ∈ J, a n • b n‖ ^ 2 := by
  refine ⟨wavelet_dropped_squares b f I, fun J hJ a => ?_⟩
  rw [wavelet_dropped_squares, wavelet_error_eq_sum]
  set c : ι → ℝ := fun n => ⟪b n, f⟫ with hc
  have hsd := wavelet_sum_sdiff_le c I J hJ hI
  have hA : ∑ n ∈ Iᶜ, c n ^ 2 + ∑ n ∈ I, c n ^ 2 = ∑ n, c n ^ 2 := by
    rw [add_comm]; exact Finset.sum_add_sum_compl I _
  have hB : ∑ n ∈ Jᶜ, c n ^ 2 + ∑ n ∈ J, c n ^ 2 = ∑ n, c n ^ 2 := by
    rw [add_comm]; exact Finset.sum_add_sum_compl J _
  have hI' : ∑ n ∈ I ∩ J, c n ^ 2 + ∑ n ∈ I \ J, c n ^ 2 = ∑ n ∈ I, c n ^ 2 :=
    Finset.sum_inter_add_sum_sdiff _ _ _
  have hJ' : ∑ n ∈ J ∩ I, c n ^ 2 + ∑ n ∈ J \ I, c n ^ 2 = ∑ n ∈ J, c n ^ 2 :=
    Finset.sum_inter_add_sum_sdiff _ _ _
  rw [Finset.inter_comm] at hJ'
  have hnn : 0 ≤ ∑ i ∈ J, (c i - a i) ^ 2 := Finset.sum_nonneg fun _ _ => sq_nonneg _
  show ∑ n ∈ Iᶜ, c n ^ 2 ≤ ∑ i ∈ J, (c i - a i) ^ 2 + ∑ i ∈ Jᶜ, c i ^ 2
  linarith

/-- For any set `I` of kept places in an orthonormal basis, the squared error of the
rebuilt photo is the sum of the squares of the dropped coefficients (Parseval). -/
theorem nterm_error_eq_sum_dropped_squares
    {ι E : Type*} [Fintype ι] [DecidableEq ι]
    [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (b : OrthonormalBasis ι ℝ E) (f : E) (I : Finset ι) :
    ‖f - ∑ n ∈ I, ⟪b n, f⟫ • b n‖ ^ 2 = ∑ n ∈ Iᶜ, ⟪b n, f⟫ ^ 2 := by
  rw [wavelet_error_eq_sum]
  simp

/-- Rank the coefficients `c n = ⟪b n, f⟫` from largest down, so the coefficient of rank
`r n` (counting from 0) is the `k`-th largest with `k = r n + 1`. If the `k`-th largest size is
at most `C / k` for every `k > N`, then the squared error after keeping the `N` largest is at
most `C² / N`. -/
theorem nterm_error_le_of_one_over_k_decay
    {ι E : Type*} [Fintype ι] [DecidableEq ι]
    [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (b : OrthonormalBasis ι ℝ E) (f : E) (r : ι ≃ Fin (Fintype.card ι))
    (hsorted : ∀ n m, r n ≤ r m → |⟪b m, f⟫| ≤ |⟪b n, f⟫|)
    (N : ℕ) (hN : 0 < N) (C : ℝ)
    (hdecay : ∀ n, N < (r n : ℕ) + 1 → |⟪b n, f⟫| ≤ C / ((r n : ℕ) + 1 : ℝ)) :
    ‖f - ∑ n ∈ univ.filter (fun n => (r n : ℕ) < N), ⟪b n, f⟫ • b n‖ ^ 2 ≤ C ^ 2 / N := by
  rw [nterm_error_eq_sum_dropped_squares, Finset.compl_filter, Finset.sum_filter]
  set h : ℕ → ℝ := fun i => if N ≤ i then 1 / ((i : ℝ) + 1) ^ 2 else 0 with hh
  have hterm : ∀ n, (if ¬ (r n : ℕ) < N then ⟪b n, f⟫ ^ 2 else 0) ≤ C ^ 2 * h (r n) := by
    intro n
    by_cases hn : (r n : ℕ) < N
    · simp [hh, hn, not_le.mpr hn]
    · have hle : N ≤ (r n : ℕ) := not_lt.mp hn
      simp only [hn, not_false_eq_true, ite_true, hh, hle]
      have hd := hdecay n (by omega)
      have hpos : (0 : ℝ) < ((r n : ℕ) : ℝ) + 1 := by positivity
      have h0 : 0 ≤ C / (((r n : ℕ) : ℝ) + 1) := le_trans (abs_nonneg _) hd
      have : ⟪b n, f⟫ ^ 2 ≤ (C / (((r n : ℕ) : ℝ) + 1)) ^ 2 := by
        rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) hd 2
      calc ⟪b n, f⟫ ^ 2 ≤ (C / (((r n : ℕ) : ℝ) + 1)) ^ 2 := this
        _ = C ^ 2 * (1 / (((r n : ℕ) : ℝ) + 1) ^ 2) := by rw [div_pow]; ring
  calc ∑ n, (if ¬ (r n : ℕ) < N then ⟪b n, f⟫ ^ 2 else 0)
      ≤ ∑ n, C ^ 2 * h (r n) := Finset.sum_le_sum fun n _ => hterm n
    _ = C ^ 2 * ∑ i : Fin (Fintype.card ι), h i := by
        rw [← Finset.mul_sum]
        congr 1
        exact Equiv.sum_comp r (fun i : Fin (Fintype.card ι) => h i)
    _ = C ^ 2 * ∑ i ∈ range (Fintype.card ι), h i := by
        rw [Fin.sum_univ_eq_sum_range]
    _ ≤ C ^ 2 * (1 / (N : ℝ)) := by
        apply mul_le_mul_of_nonneg_left _ (sq_nonneg C)
        have := wavelet_tail_inv_sq_le N hN (Fintype.card ι)
        have hpos : (0 : ℝ) < ((max (Fintype.card ι) N : ℕ) : ℝ) := by
          exact_mod_cast (lt_of_lt_of_le hN (le_max_right _ _))
        have : 0 < 1 / ((max (Fintype.card ι) N : ℕ) : ℝ) := by positivity
        linarith
    _ = C ^ 2 / N := by ring

-- The photo: 128 by 128 pixels, and one twentieth of them kept.
example : 128 * 128 = 16384 := by norm_num
example : 16384 / 20 = 819 := by norm_num
example : 16384 - 819 = 15565 := by norm_num
-- Five Mallat steps: coefficients per level plus the 4 by 4 average picture fill the photo.
example : 3 * 64 ^ 2 + 3 * 32 ^ 2 + 3 * 16 ^ 2 + 3 * 8 ^ 2 + 3 * 4 ^ 2 + 4 ^ 2 = 16384 := by norm_num
-- Where the 819 D4 numbers went, by level.
example : 16 + 47 + 132 + 193 + 168 + 263 = 819 := by norm_num
-- Cosine blocks: 256 averages, 304 details in the 27 edge blocks, 259 in the other 229.
example : (128 / 8) * (128 / 8) = 256 := by norm_num
example : 256 + 304 + 259 = 819 := by norm_num
example : 256 - 27 = 229 := by norm_num

#print axioms keep_largest_error_eq_sum_dropped_squares_and_is_best
#print axioms nterm_error_eq_sum_dropped_squares
#print axioms nterm_error_le_of_one_over_k_decay
