-- Finite differences: the three-point grid solution of y'' = f with y(0) = y(1) = 0 is within h^2 M / 96 of the true curve, the centred difference misses y'' by (h^2/12) y''''(ξ), and the sweep's pivots are -(i+1)/i.
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.Taylor

open Set

lemma fd_iteratedDerivWithin_subset {y : ℝ → ℝ} {s t : Set ℝ} {x : ℝ} {n k : ℕ} (hk : k ≤ n)
    (st : s ⊆ t) (hs : UniqueDiffOn ℝ s) (ht : UniqueDiffOn ℝ t) (h : ContDiffOn ℝ n y t)
    (hx : x ∈ s) : iteratedDerivWithin k y s x = iteratedDerivWithin k y t x := by
  simp only [iteratedDerivWithin_eq_iteratedFDerivWithin]
  rw [iteratedFDerivWithin_subset st hs ht (h.of_le (by exact_mod_cast hk)) hx]

lemma fd_taylor3 (y : ℝ → ℝ) (x z : ℝ) (S : Set ℝ) (hxz : x ≠ z) (hsub : uIcc x z ⊆ S)
    (hS : UniqueDiffOn ℝ S) (hy : ContDiffOn ℝ 4 y S) :
    ∃ ξ ∈ uIcc x z, y z = y x + iteratedDerivWithin 1 y S x * (z - x)
      + iteratedDerivWithin 2 y S x / 2 * (z - x) ^ 2
      + iteratedDerivWithin 3 y S x / 6 * (z - x) ^ 3
      + iteratedDerivWithin 4 y S ξ / 24 * (z - x) ^ 4 := by
  have hu : UniqueDiffOn ℝ (uIcc x z) := uniqueDiffOn_uIcc hxz
  have hc : ContDiffOn ℝ 4 y (uIcc x z) := hy.mono hsub
  obtain ⟨ξ, hξ, hT⟩ := taylor_mean_remainder_lagrange (n := 3) hxz
    (hc.of_le (by norm_num))
    ((hc.differentiableOn_iteratedDerivWithin (by norm_num) hu).mono uIoo_subset_uIcc_self)
  have hξ' : ξ ∈ uIcc x z := uIoo_subset_uIcc_self hξ
  have hx : x ∈ uIcc x z := left_mem_uIcc
  refine ⟨ξ, hξ', ?_⟩
  rw [taylor_within_apply] at hT
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, smul_eq_mul] at hT
  rw [fd_iteratedDerivWithin_subset (n := 4) (by norm_num) hsub hu hS hy hx,
    fd_iteratedDerivWithin_subset (n := 4) (k := 1) (by norm_num) hsub hu hS hy hx,
    fd_iteratedDerivWithin_subset (n := 4) (k := 2) (by norm_num) hsub hu hS hy hx,
    fd_iteratedDerivWithin_subset (n := 4) (k := 3) (by norm_num) hsub hu hS hy hx,
    fd_iteratedDerivWithin_subset (n := 4) (k := 3 + 1) (by norm_num) hsub hu hS hy hξ'] at hT
  simp only [iteratedDerivWithin_zero] at hT
  norm_num [Nat.factorial] at hT
  rw [iteratedDerivWithin_one]
  linear_combination hT

lemma fd_convex_nonpos (u : ℕ → ℝ) (N : ℕ) (h0 : u 0 = 0) (hN : u (N + 1) = 0)
    (hc : ∀ i : ℕ, 1 ≤ i → i ≤ N → 0 ≤ u (i - 1) - 2 * u i + u (i + 1)) :
    ∀ i : ℕ, i ≤ N + 1 → u i ≤ 0 := by
  have mono : ∀ i : ℕ, i + 1 ≤ N → u (i + 1) - u i ≤ u (i + 1 + 1) - u (i + 1) := by
    intro i hi
    have := hc (i + 1) (by omega) hi
    simp only [Nat.add_sub_cancel] at this
    linarith
  have A : ∀ i : ℕ, i ≤ N → u i ≤ (i : ℝ) * (u (i + 1) - u i) := by
    intro i
    induction i with
    | zero => intro _; simp [h0]
    | succ k ih =>
      intro hk
      have h1 := ih (by omega)
      have h2 := mono k hk
      push_cast
      have hk0 : (0 : ℝ) ≤ (k : ℝ) + 1 := by positivity
      nlinarith
  have B : ∀ k : ℕ, k ≤ N → u (N - k) + ((k : ℝ) + 1) * (u (N - k + 1) - u (N - k)) ≤ 0 := by
    intro k
    induction k with
    | zero =>
      intro _
      simp [hN]
    | succ k ih =>
      intro hk
      have h1 := ih (by omega)
      obtain ⟨j, hj⟩ : ∃ j, N - k = j + 1 := ⟨N - k - 1, by omega⟩
      have hj2 : N - (k + 1) = j := by omega
      rw [hj] at h1
      rw [hj2]
      have h2 := mono j (by omega)
      push_cast
      have hk0 : (0 : ℝ) ≤ (k : ℝ) + 1 := by positivity
      nlinarith
  intro i hi
  rcases Nat.lt_or_ge i (N + 1) with hlt | hge
  · have hA := A i (by omega)
    have hB := B (N - i) (by omega)
    have hNi : N - (N - i) = i := by omega
    rw [hNi] at hB
    have hcast : ((N - i : ℕ) : ℝ) + 1 > 0 := by positivity
    rcases le_total 0 (u (i + 1) - u i) with hd | hd
    · nlinarith
    · have : (0 : ℝ) ≤ i := by positivity
      nlinarith
  · have : i = N + 1 := by omega
    rw [this, hN]

lemma fd_centred
    (y : ℝ → ℝ) (x h : ℝ) (hh : 0 < h)
    (hy : ContDiffOn ℝ 4 y (Icc (x - h) (x + h))) :
    ∃ ξ ∈ Icc (x - h) (x + h),
      (y (x - h) - 2 * y x + y (x + h)) / h ^ 2 =
        iteratedDerivWithin 2 y (Icc (x - h) (x + h)) x
          + h ^ 2 / 12 * iteratedDerivWithin 4 y (Icc (x - h) (x + h)) ξ := by
  set S := Icc (x - h) (x + h) with hSdef
  have hS : UniqueDiffOn ℝ S := uniqueDiffOn_Icc (by linarith)
  have s1 : uIcc x (x + h) ⊆ S := by
    rw [uIcc_of_le (by linarith)]; exact Icc_subset_Icc (by linarith) le_rfl
  have s2 : uIcc x (x - h) ⊆ S := by
    rw [uIcc_of_ge (by linarith)]; exact Icc_subset_Icc le_rfl (by linarith)
  obtain ⟨a, ha, hA⟩ := fd_taylor3 y x (x + h) S (by linarith) s1 hS hy
  obtain ⟨b, hb, hB⟩ := fd_taylor3 y x (x - h) S (by linarith) s2 hS hy
  have haS := s1 ha
  have hbS := s2 hb
  have hcont : ContinuousOn (iteratedDerivWithin 4 y S) S :=
    hy.continuousOn_iteratedDerivWithin (by norm_num) hS
  have hab : uIcc a b ⊆ S := uIcc_subset_Icc haS hbS
  have hmid : (iteratedDerivWithin 4 y S a + iteratedDerivWithin 4 y S b) / 2 ∈
      uIcc (iteratedDerivWithin 4 y S a) (iteratedDerivWithin 4 y S b) := by
    rw [mem_uIcc]
    rcases le_total (iteratedDerivWithin 4 y S a) (iteratedDerivWithin 4 y S b) with hle | hle
    · left; constructor <;> linarith
    · right; constructor <;> linarith
  obtain ⟨ξ, hξ, hξeq⟩ := intermediate_value_uIcc (hcont.mono hab) hmid
  refine ⟨ξ, hab hξ, ?_⟩
  rw [hξeq]
  have hh2 : h ^ 2 ≠ 0 := by positivity
  rw [div_eq_iff hh2, hA, hB]
  ring

#print axioms fd_iteratedDerivWithin_subset
#print axioms fd_taylor3
#print axioms fd_convex_nonpos
#print axioms fd_centred

/-- The error bound for finite differences. Let `y` be four times continuously differentiable on
the span `[0, 1]`, solve `y'' = f` there with both ends pinned, `y 0 = y 1 = 0`, and let the
fourth derivative have size at most `M` over the span. Put `N` marks inside at even spacing
`h = 1/(N+1)`, so mark `i` sits at `i h`. If the grid values `v` are pinned at zero at both ends
and satisfy `(v (i-1) - 2 v i + v (i+1)) / h^2 = f (i h)` at every inside mark, then at every
mark the grid is within `h^2 M / 96` of the true curve. -/
theorem finite_difference_error_le_h_sq_mul_M_div_96
    (y f : ℝ → ℝ) (M h : ℝ) (N : ℕ) (v : ℕ → ℝ)
    (hy : ContDiffOn ℝ 4 y (Icc 0 1))
    (hode : ∀ x ∈ Icc (0 : ℝ) 1, iteratedDerivWithin 2 y (Icc 0 1) x = f x)
    (hy0 : y 0 = 0) (hy1 : y 1 = 0)
    (hM : ∀ x ∈ Icc (0 : ℝ) 1, |iteratedDerivWithin 4 y (Icc 0 1) x| ≤ M)
    (hh : h = 1 / ((N : ℝ) + 1))
    (hv0 : v 0 = 0) (hvN : v (N + 1) = 0)
    (hgrid : ∀ i : ℕ, 1 ≤ i → i ≤ N →
      (v (i - 1) - 2 * v i + v (i + 1)) / h ^ 2 = f (i * h)) :
    ∀ i : ℕ, i ≤ N + 1 → |v i - y (i * h)| ≤ h ^ 2 * M / 96 := by
  have hN1 : (0 : ℝ) < (N : ℝ) + 1 := by positivity
  have hpos : 0 < h := by rw [hh]; positivity
  have hhN : h * ((N : ℝ) + 1) = 1 := by rw [hh]; field_simp
  have hM0 : 0 ≤ M := le_trans (abs_nonneg _) (hM 0 ⟨le_rfl, zero_le_one⟩)
  have hU : UniqueDiffOn ℝ (Icc (0 : ℝ) 1) := uniqueDiffOn_Icc zero_lt_one
  set e : ℕ → ℝ := fun j => v j - y (j * h) with he
  -- the local truncation error
  have trunc : ∀ j : ℕ, 1 ≤ j → j ≤ N →
      |e (j - 1) - 2 * e j + e (j + 1)| ≤ h ^ 4 * M / 12 := by
    intro j hj1 hjN
    have hj1' : (1 : ℝ) ≤ j := by exact_mod_cast hj1
    have hjN' : (j : ℝ) ≤ N := by exact_mod_cast hjN
    set x : ℝ := j * h with hx
    have hsub : Icc (x - h) (x + h) ⊆ Icc 0 1 := by
      apply Icc_subset_Icc
      · rw [hx]; nlinarith
      · rw [hx]; nlinarith
    have hxS : x ∈ Icc (x - h) (x + h) := ⟨by linarith, by linarith⟩
    obtain ⟨ξ, hξ, hT⟩ :=
      fd_centred y x h hpos (hy.mono hsub)
    have hs : UniqueDiffOn ℝ (Icc (x - h) (x + h)) := uniqueDiffOn_Icc (by linarith)
    rw [fd_iteratedDerivWithin_subset (n := 4) (by norm_num) hsub hs hU hy hxS,
      fd_iteratedDerivWithin_subset (n := 4) (by norm_num) hsub hs hU hy hξ,
      hode x (hsub hxS)] at hT
    have hG := hgrid j hj1 hjN
    have hcm : ((j - 1 : ℕ) : ℝ) * h = x - h := by
      rw [Nat.cast_sub hj1, hx]; push_cast; ring
    have hcp : ((j + 1 : ℕ) : ℝ) * h = x + h := by
      rw [hx]; push_cast; ring
    have hD := hM ξ (hsub hξ)
    rw [abs_le] at hD
    have hh2 : h ^ 2 ≠ 0 := by positivity
    rw [div_eq_iff hh2] at hT hG
    have hval : e (j - 1) - 2 * e j + e (j + 1)
        = -(h ^ 4 / 12) * iteratedDerivWithin 4 y (Icc 0 1) ξ := by
      simp only [he, hcm, hcp]
      rw [← hx]
      linear_combination hG - hT
    rw [hval, abs_le]
    have h4 : 0 ≤ h ^ 4 := by positivity
    constructor <;> nlinarith
  -- the comparison grid
  set w : ℕ → ℝ := fun j => h ^ 4 * M / 24 * ((j : ℝ) * ((N : ℝ) + 1 - j)) with hw
  have wdiff : ∀ j : ℕ, 1 ≤ j → w (j - 1) - 2 * w j + w (j + 1) = -(h ^ 4 * M / 12) := by
    intro j hj
    simp only [hw]
    rw [Nat.cast_sub hj]
    push_cast
    ring
  have e0 : e 0 = 0 := by simp [he, hv0, hy0]
  have eN : e (N + 1) = 0 := by
    simp only [he]
    push_cast
    rw [mul_comm, hhN, hvN, hy1]; ring
  have w0 : w 0 = 0 := by simp [hw]
  have wN : w (N + 1) = 0 := by simp [hw]
  have up := fd_convex_nonpos (fun j => e j - w j) N (by simp [e0, w0]) (by simp [eN, wN])
    (by
      intro j hj1 hjN
      have h1 := trunc j hj1 hjN
      have h2 := wdiff j hj1
      rw [abs_le] at h1
      linarith [h1.1])
  have lo := fd_convex_nonpos (fun j => -e j - w j) N (by simp [e0, w0]) (by simp [eN, wN])
    (by
      intro j hj1 hjN
      have h1 := trunc j hj1 hjN
      have h2 := wdiff j hj1
      rw [abs_le] at h1
      linarith [h1.2])
  intro i hi
  have hu := up i hi
  have hl := lo i hi
  have hwi : w i ≤ h ^ 2 * M / 96 := by
    simp only [hw]
    have key : (i : ℝ) * ((N : ℝ) + 1 - i) ≤ ((N : ℝ) + 1) ^ 2 / 4 := by
      nlinarith [sq_nonneg ((N : ℝ) + 1 - 2 * i)]
    have hK : 0 ≤ h ^ 4 * M / 24 := by positivity
    calc h ^ 4 * M / 24 * ((i : ℝ) * ((N : ℝ) + 1 - i))
        ≤ h ^ 4 * M / 24 * (((N : ℝ) + 1) ^ 2 / 4) := mul_le_mul_of_nonneg_left key hK
      _ = h ^ 2 * M / 96 * (h * ((N : ℝ) + 1)) ^ 2 := by ring
      _ = h ^ 2 * M / 96 := by rw [hhN]; ring
  show |e i| ≤ _
  rw [abs_le]
  constructor <;> linarith

/-- The centred difference and what it misses (Step 1). If `y` is four times continuously
differentiable on the stretch from `x - h` to `x + h`, with `h > 0`, then the neighbours minus
twice the middle, over `h^2`, equals `y''(x)` plus `(h^2/12) y''''(ξ)` for some point `ξ` within
one step of `x`. -/
theorem centred_difference_eq_second_deriv_add_truncation
    (y : ℝ → ℝ) (x h : ℝ) (hh : 0 < h)
    (hy : ContDiffOn ℝ 4 y (Icc (x - h) (x + h))) :
    ∃ ξ ∈ Icc (x - h) (x + h),
      (y (x - h) - 2 * y x + y (x + h)) / h ^ 2 =
        iteratedDerivWithin 2 y (Icc (x - h) (x + h)) x
          + h ^ 2 / 12 * iteratedDerivWithin 4 y (Icc (x - h) (x + h)) ξ := by
  exact fd_centred y x h hh hy

/-- The Thomas sweep's pivots for the matrix with -2 down the diagonal and 1 on either side:
starting from `p 1 = -2` and stepping `p (i+1) = -2 - 1 / p i`, every pivot is `-(i+1)/i`, and
each has size at least 1, so the sweep never divides by zero. -/
theorem thomas_pivot_eq_neg_succ_div_and_one_le_abs
    (p : ℕ → ℝ) (hp1 : p 1 = -2) (hstep : ∀ i : ℕ, 1 ≤ i → p (i + 1) = -2 - 1 / p i) :
    ∀ i : ℕ, 1 ≤ i → p i = -((i : ℝ) + 1) / i ∧ 1 ≤ |p i| := by
  have key : ∀ i : ℕ, 1 ≤ i → p i = -((i : ℝ) + 1) / i := by
    intro i hi
    induction i, hi using Nat.le_induction with
    | base => rw [hp1]; norm_num
    | succ n hn ih =>
      rw [hstep n hn, ih]
      have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
      push_cast
      field_simp
      ring
  intro i hi
  refine ⟨key i hi, ?_⟩
  rw [key i hi]
  have hi' : (1 : ℝ) ≤ i := by exact_mod_cast hi
  rw [abs_div, abs_neg, abs_of_pos (by linarith), abs_of_pos (by linarith), le_div_iff₀ (by linarith)]
  linarith

-- The even shelf, N = 9, h = 1/10, f = -1: the grid values i(10 - i)/200 meet both pins and
-- every grid equation, and the middle sags 1/8 m = 0.125 m.
example : let v : ℕ → ℚ := fun i => i * (10 - i) / 200
    v 0 = 0 ∧ v 10 = 0 ∧ v 5 = 1 / 8 ∧
    ∀ i ∈ Finset.Icc 1 9, (v (i - 1) - 2 * v i + v (i + 1)) / (1 / 10) ^ 2 = -1 := by
  intro v
  refine ⟨by norm_num [v], by norm_num [v], by norm_num [v], ?_⟩
  intro i hi
  obtain ⟨h1, h2⟩ := Finset.mem_Icc.mp hi
  interval_cases i <;> norm_num [v]

-- The exact sag x(1 - x)/2 at the middle is also 1/8 m.
example : (1 / 2 : ℚ) * (1 - 1 / 2) / 2 = 1 / 8 := by norm_num

-- The sweep's pivots: p2 = -3/2, p3 = -4/3, and p9 = -10/9 (the table's -1.1111).
example : (-2 : ℚ) - 1 / (-2) = -3 / 2 ∧ (-2 : ℚ) - 1 / (-3 / 2) = -4 / 3 ∧
    (fun q : ℚ => -2 - 1 / q)^[8] (-2) = -10 / 9 := by
  norm_num [Function.iterate_succ]

-- The right sides r_i = -(i+1)/200 (the table's -0.0100, -0.0150, ..., -0.0500):
-- r1 = -1/100 and r_{i+1} = -1/100 - r_i / p_i with p_i = -(i+1)/i.
example : ∀ i ∈ Finset.Icc (1 : ℕ) 8,
    (-1 / 100 : ℚ) - (-((i : ℚ) + 1) / 200) / (-((i : ℚ) + 1) / i) = -((i : ℚ) + 2) / 200 := by
  intro i hi
  obtain ⟨h1, h2⟩ := Finset.mem_Icc.mp hi
  interval_cases i <;> norm_num

-- Back sweep: mark 9 is (-1/20)/(-10/9) = 9/200 m (0.045000); mark 5 is (-3/100 - 3/25)/(-6/5) = 1/8 m.
example : (-1 / 20 : ℚ) / (-10 / 9) = 9 / 200 ∧
    ((-3 / 100 : ℚ) - 3 / 25) / (-6 / 5) = 1 / 8 := by norm_num

-- Mistake 1: spacing 1/9 for nine inside marks. The grid i(10 - i)/162 solves the wrong
-- equations, and its middle is 25/162 m (0.154321) instead of 1/8.
example : let v : ℕ → ℚ := fun i => i * (10 - i) / 162
    v 0 = 0 ∧ v 10 = 0 ∧ v 5 = 25 / 162 ∧
    ∀ i ∈ Finset.Icc 1 9, (v (i - 1) - 2 * v i + v (i + 1)) / (1 / 9) ^ 2 = -1 := by
  intro v
  refine ⟨by norm_num [v], by norm_num [v], by norm_num [v], ?_⟩
  intro i hi
  obtain ⟨h1, h2⟩ := Finset.mem_Icc.mp hi
  interval_cases i <;> norm_num [v]

-- Mistake 2: dividing by h, not h^2, is the load -1/h = -10 over h^2. The grid i(10 - i)/20
-- solves it, and its middle is 5/4 m (1.250000), ten times too deep.
example : let v : ℕ → ℚ := fun i => i * (10 - i) / 20
    v 0 = 0 ∧ v 10 = 0 ∧ v 5 = 5 / 4 ∧
    ∀ i ∈ Finset.Icc 1 9, (v (i - 1) - 2 * v i + v (i + 1)) / (1 / 10) ^ 2 = -10 := by
  intro v
  refine ⟨by norm_num [v], by norm_num [v], by norm_num [v], ?_⟩
  intro i hi
  obtain ⟨h1, h2⟩ := Finset.mem_Icc.mp hi
  interval_cases i <;> norm_num [v]

#print axioms finite_difference_error_le_h_sq_mul_M_div_96
#print axioms centred_difference_eq_second_deriv_add_truncation
#print axioms thomas_pivot_eq_neg_succ_div_and_one_le_abs
