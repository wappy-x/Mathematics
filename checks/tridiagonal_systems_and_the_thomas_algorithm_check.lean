-- The Thomas algorithm: under diagonal dominance every pivot of the sweep stays above its margin and is nonzero, the factors do not grow, the sweep is A = LU and returns the exact solution, and it costs 8n - 7 flops.
import Mathlib.Data.Matrix.Mul
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp

open Matrix

/-! Rows are numbered `1, …, n` as on the card. Row `i` reads
`a i * x (i - 1) + b i * x i + c i * x (i + 1) = d i`; row 1 has no `a 1` and row `n` has
no `c n`, so those two values are never read. In the `Fin n`-indexed matrices, index `i`
is the card's row `i + 1`. -/

/-- The card's pivots: `p 1 = b 1` and `p i = b i - l i * c (i - 1)` with the multiplier
`l i = a i / p (i - 1)`. -/
noncomputable def pivot (a b c : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | 1 => b 1
  | (i + 2) => b (i + 2) - a (i + 2) / pivot a b c (i + 1) * c (i + 1)

/-- The sweep down's right side: `y 1 = d 1` and `y i = d i - l i * y (i - 1)`. -/
noncomputable def swept (a b c d : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | 1 => d 1
  | (i + 2) => d (i + 2) - a (i + 2) / pivot a b c (i + 1) * swept a b c d (i + 1)

/-- The sweep back, counted in steps `k` from the last row: step 0 gives `x n = y n / p n`,
step `k + 1` gives `x i = (y i - c i * x (i + 1)) / p i` for `i = n - (k + 1)`. -/
noncomputable def backStep (n : ℕ) (a b c d : ℕ → ℝ) : ℕ → ℝ
  | 0 => swept a b c d n / pivot a b c n
  | (k + 1) => (swept a b c d (n - (k + 1)) - c (n - (k + 1)) * backStep n a b c d k) /
      pivot a b c (n - (k + 1))

/-- The Thomas algorithm's answer `x i` for row `i`. -/
noncomputable def thomasSol (n : ℕ) (a b c d : ℕ → ℝ) (i : ℕ) : ℝ :=
  backStep n a b c d (n - i)

/-- The tridiagonal matrix `A`: `b` on the diagonal, `a` just below it, `c` just above it. -/
def tridiag (n : ℕ) (a b c : ℕ → ℝ) : Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j =>
    if (j : ℕ) = i then b (i + 1)
    else if (j : ℕ) + 1 = i then a (i + 1)
    else if (i : ℕ) + 1 = j then c (i + 1)
    else 0

/-- The factor `L`: ones on the diagonal, the multipliers `l i = a i / p (i - 1)` just below. -/
noncomputable def lowerFactor (n : ℕ) (a b c : ℕ → ℝ) : Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j =>
    if (j : ℕ) = i then 1
    else if (j : ℕ) + 1 = i then a (i + 1) / pivot a b c i
    else 0

/-- The factor `U`: the pivots `p i` on the diagonal, the original `c i` just above. -/
noncomputable def upperFactor (n : ℕ) (a b c : ℕ → ℝ) : Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j =>
    if (j : ℕ) = i then pivot a b c (i + 1)
    else if (i : ℕ) + 1 = j then c (i + 1)
    else 0

lemma td_sum_below (n i : ℕ) (hi : i < n) (f : ℕ → ℝ)
    (hf : ∀ k, k ≠ i → k + 1 ≠ i → f k = 0) :
    ∑ k ∈ Finset.range n, f k = f i + (if 1 ≤ i then f (i - 1) else 0) := by
  rcases Nat.eq_zero_or_pos i with rfl | hpos
  · rw [Finset.sum_eq_single 0]
    · simp
    · intro k _ hk; exact hf k hk (by omega)
    · intro h; simp at h; omega
  · rw [Finset.sum_eq_add_of_mem i (i - 1) (by simp; omega) (by simp; omega) (by omega)]
    · simp [show 1 ≤ i by omega]
    · rintro k _ ⟨h1, h2⟩; exact hf k h1 (by omega)

#print axioms td_sum_below

lemma td_sum_above (n i : ℕ) (hi : i < n) (f : ℕ → ℝ)
    (hf : ∀ k, k ≠ i → k ≠ i + 1 → f k = 0) :
    ∑ k ∈ Finset.range n, f k = f i + (if i + 1 < n then f (i + 1) else 0) := by
  by_cases h : i + 1 < n
  · rw [Finset.sum_eq_add_of_mem i (i + 1) (by simp; omega) (by simp; omega) (by omega)]
    · simp [h]
    · rintro k _ ⟨h1, h2⟩; exact hf k h1 h2
  · rw [Finset.sum_eq_single i]
    · simp [h]
    · intro k hk hki; simp at hk; exact hf k hki (by omega)
    · intro h'; simp at h'; omega

#print axioms td_sum_above

lemma td_pivot_succ (a b c : ℕ → ℝ) (i : ℕ) (hi : 1 ≤ i) :
    pivot a b c (i + 1) = b (i + 1) - a (i + 1) / pivot a b c i * c i := by
  obtain ⟨m, rfl⟩ : ∃ m, i = m + 1 := ⟨i - 1, by omega⟩
  rfl

#print axioms td_pivot_succ

lemma td_swept_succ (a b c d : ℕ → ℝ) (i : ℕ) (hi : 1 ≤ i) :
    swept a b c d (i + 1) = d (i + 1) - a (i + 1) / pivot a b c i * swept a b c d i := by
  obtain ⟨m, rfl⟩ : ∃ m, i = m + 1 := ⟨i - 1, by omega⟩
  rfl

#print axioms td_swept_succ

lemma td_pivot_inv (n : ℕ) (a b c : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) :
    ∀ i, 1 ≤ i → i ≤ n → (if i < n then |c i| else 0) < |pivot a b c i| := by
  intro i hi hin
  induction i with
  | zero => omega
  | succ m ih =>
    rcases Nat.eq_zero_or_pos m with rfl | hm
    · simpa [pivot] using hfirst
    · have ih' := ih hm (by omega)
      have hlt : |c m| < |pivot a b c m| := by simpa [show m < n by omega] using ih'
      have hp : 0 < |pivot a b c m| := lt_of_le_of_lt (abs_nonneg _) hlt
      have hapos : 0 < |a (m + 1)| := abs_pos.mpr (ha (m + 1) (by omega) (by omega))
      rw [td_pivot_succ a b c m hm]
      have h1 : |a (m + 1) / pivot a b c m * c m| < |a (m + 1)| := by
        rw [abs_mul, abs_div, div_mul_eq_mul_div, div_lt_iff₀ hp]
        exact mul_lt_mul_of_pos_left hlt hapos
      have h2 := abs_sub_abs_le_abs_sub (b (m + 1)) (a (m + 1) / pivot a b c m * c m)
      have hd := hdom (m + 1) (by omega) (by omega)
      simp only [show 2 ≤ m + 1 by omega, ite_true] at hd
      linarith

#print axioms td_pivot_inv

lemma td_pivot_ne (n : ℕ) (a b c : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) :
    ∀ i, 1 ≤ i → i ≤ n → pivot a b c i ≠ 0 := by
  intro i hi hin
  have h := td_pivot_inv n a b c hdom hfirst ha i hi hin
  have h0 : (0:ℝ) ≤ (if i < n then |c i| else 0) := by split_ifs <;> simp
  exact abs_pos.mp (lt_of_le_of_lt h0 h)

#print axioms td_pivot_ne

lemma td_step_small (n : ℕ) (a b c : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) (m : ℕ) (hm : 1 ≤ m) (hmn : m + 1 ≤ n) :
    |a (m + 1)| / |pivot a b c m| * |c m| < |a (m + 1)| := by
  have ih' := td_pivot_inv n a b c hdom hfirst ha m hm (by omega)
  have hlt : |c m| < |pivot a b c m| := by simpa [show m < n by omega] using ih'
  have hp : 0 < |pivot a b c m| := lt_of_le_of_lt (abs_nonneg _) hlt
  have hapos : 0 < |a (m + 1)| := abs_pos.mpr (ha (m + 1) (by omega) (by omega))
  rw [div_mul_eq_mul_div, div_lt_iff₀ hp]
  exact mul_lt_mul_of_pos_left hlt hapos

#print axioms td_step_small

noncomputable def lfN (a b c : ℕ → ℝ) (i k : ℕ) : ℝ :=
  if k = i then 1 else if k + 1 = i then a (i + 1) / pivot a b c i else 0

#print axioms lfN

noncomputable def ufN (a b c : ℕ → ℝ) (k j : ℕ) : ℝ :=
  if j = k then pivot a b c (k + 1) else if k + 1 = j then c (k + 1) else 0

#print axioms ufN

noncomputable def tdN (a b c : ℕ → ℝ) (i j : ℕ) : ℝ :=
  if j = i then b (i + 1) else if j + 1 = i then a (i + 1)
  else if i + 1 = j then c (i + 1) else 0

#print axioms tdN

lemma td_abs_entry (n : ℕ) (a b c : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) (i j : ℕ) (hi : i < n) (hj : j < n) :
    |lfN a b c i i| * |ufN a b c i j| +
      (if 1 ≤ i then |lfN a b c i (i - 1)| * |ufN a b c (i - 1) j| else 0) ≤
      3 * |tdN a b c i j| := by
  rcases i with _ | m
  · rcases j with _ | j
    · simp [lfN, ufN, tdN, pivot]
      linarith [abs_nonneg (b 1)]
    · rcases j with _ | j
      · simp [lfN, ufN, tdN]
        linarith [abs_nonneg (c 1)]
      · simp [lfN, ufN, tdN]
  · by_cases hjm : j = m + 1
    · subst hjm
      have hs := td_step_small n a b c hdom hfirst ha (m + 1) (by omega) (by omega)
      have hd := hdom (m + 2) (by omega) (by omega)
      simp only [show 2 ≤ m + 2 by omega, ite_true] at hd
      have hc : 0 ≤ (if m + 2 < n then |c (m + 2)| else 0) := by split_ifs <;> simp
      have h2 := abs_sub (b (m + 2)) (a (m + 2) / pivot a b c (m + 1) * c (m + 1))
      rw [abs_mul (a (m + 2) / pivot a b c (m + 1)), abs_div] at h2
      simp [lfN, ufN, tdN, td_pivot_succ a b c (m + 1) (by omega), abs_div]
      linarith
    · by_cases hj2 : j = m + 2
      · subst hj2
        simp [lfN, ufN, tdN]
        linarith [abs_nonneg (c (m + 2))]
      · by_cases hj0 : j = m
        · rw [hj0]
          have hp := td_pivot_ne n a b c hdom hfirst ha (m + 1) (by omega) (by omega)
          have hp' : |pivot a b c (m + 1)| ≠ 0 := abs_ne_zero.mpr hp
          simp [lfN, ufN, tdN, abs_div, hp', show m + 1 + 1 ≠ m by omega]
          linarith [abs_nonneg (a (m + 2))]
        · have e1 : m + 1 + 1 ≠ j := by omega
          have e2 : m + 1 ≠ j := by omega
          simp [lfN, ufN, tdN, hjm, hj0, e1, e2]

#print axioms td_abs_entry

lemma td_lu_entry (n : ℕ) (a b c : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) (i j : ℕ) (hi : i < n) :
    lfN a b c i i * ufN a b c i j +
      (if 1 ≤ i then lfN a b c i (i - 1) * ufN a b c (i - 1) j else 0) = tdN a b c i j := by
  rcases i with _ | m
  · rcases j with _ | j
    · simp [lfN, ufN, tdN, pivot]
    · rcases j with _ | j
      · simp [lfN, ufN, tdN]
      · simp [lfN, ufN, tdN]
  · have hp := td_pivot_ne n a b c hdom hfirst ha (m + 1) (by omega) (by omega)
    by_cases hjm : j = m + 1
    · subst hjm
      simp [lfN, ufN, tdN, td_pivot_succ a b c (m + 1) (by omega)]
    · by_cases hj2 : j = m + 2
      · subst hj2
        simp [lfN, ufN, tdN]
      · by_cases hj0 : j = m
        · rw [hj0]
          simp [lfN, ufN, tdN, hp, show m + 1 + 1 ≠ m by omega]
        · have e1 : m + 1 + 1 ≠ j := by omega
          have e2 : m + 1 ≠ j := by omega
          simp [lfN, ufN, tdN, hjm, hj0, e1, e2]

#print axioms td_lu_entry

lemma td_sol_last (n : ℕ) (a b c d : ℕ → ℝ) :
    thomasSol n a b c d n = swept a b c d n / pivot a b c n := by
  simp [thomasSol, backStep]

#print axioms td_sol_last

lemma td_sol_lt (n : ℕ) (a b c d : ℕ → ℝ) (i : ℕ) (h : i < n) :
    thomasSol n a b c d i =
      (swept a b c d i - c i * thomasSol n a b c d (i + 1)) / pivot a b c i := by
  unfold thomasSol
  obtain ⟨k, hk⟩ : ∃ k, n - i = k + 1 := ⟨n - i - 1, by omega⟩
  rw [hk, backStep, show n - (k + 1) = i by omega, show n - (i + 1) = k by omega]

#print axioms td_sol_lt

lemma td_U_row (n : ℕ) (a b c d : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) (i : ℕ) (hi : i < n) :
    ufN a b c i i * thomasSol n a b c d (i + 1) +
      (if i + 1 < n then ufN a b c i (i + 1) * thomasSol n a b c d (i + 1 + 1) else 0) =
      swept a b c d (i + 1) := by
  have hp := td_pivot_ne n a b c hdom hfirst ha (i + 1) (by omega) (by omega)
  by_cases h : i + 1 < n
  · simp only [ufN, h, ite_true, show i + 1 ≠ i by omega, ite_false]
    rw [td_sol_lt n a b c d (i + 1) h]
    field_simp
    ring
  · have hn : i + 1 = n := by omega
    simp only [ufN, h, ite_true, ite_false, add_zero]
    rw [hn, td_sol_last]
    rw [hn] at hp
    field_simp

#print axioms td_U_row

lemma td_L_row (a b c d : ℕ → ℝ) (i : ℕ) :
    lfN a b c i i * swept a b c d (i + 1) +
      (if 1 ≤ i then lfN a b c i (i - 1) * swept a b c d (i - 1 + 1) else 0) = d (i + 1) := by
  rcases i with _ | m
  · simp [lfN, swept]
  · simp [lfN, td_swept_succ a b c d (m + 1) (by omega)]

#print axioms td_L_row

/-- Diagonal dominance keeps every pivot away from zero and the factors from growing.
Suppose each `|b i|` is at least `|a i| + |c i|` (leaving out the absent `a 1` and `c n`),
strictly bigger than `|c 1|` in row 1, and no `a i` below the diagonal is zero. Then every
pivot after the first is bigger in size than the margin `|b i| - |a i|`, no pivot is zero,
and `|L| |U| ≤ 3 |A|` entry by entry. -/
theorem thomas_pivots_exceed_margin_of_diag_dominant (n : ℕ) (a b c : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) :
    (∀ i, 2 ≤ i → i ≤ n → |b i| - |a i| < |pivot a b c i|) ∧
    (∀ i, 1 ≤ i → i ≤ n → pivot a b c i ≠ 0) ∧
    (∀ i j : Fin n, ((lowerFactor n a b c).map abs * (upperFactor n a b c).map abs) i j ≤
      3 * |tridiag n a b c i j|) := by
  refine ⟨?_, td_pivot_ne n a b c hdom hfirst ha, ?_⟩
  · intro i hi hin
    obtain ⟨m, rfl⟩ : ∃ m, i = m + 1 := ⟨i - 1, by omega⟩
    have hs := td_step_small n a b c hdom hfirst ha m (by omega) hin
    have h2 := abs_sub_abs_le_abs_sub (b (m + 1)) (a (m + 1) / pivot a b c m * c m)
    rw [abs_mul (a (m + 1) / pivot a b c m), abs_div] at h2
    rw [td_pivot_succ a b c m (by omega)]
    linarith
  · intro i j
    have hs : ((lowerFactor n a b c).map abs * (upperFactor n a b c).map abs) i j
        = ∑ k ∈ Finset.range n, |lfN a b c i k| * |ufN a b c k j| := by
      simp only [Matrix.mul_apply, Matrix.map_apply]
      exact Fin.sum_univ_eq_sum_range (fun k => |lfN a b c i k| * |ufN a b c k j|) n
    rw [hs, td_sum_below n i i.isLt _ (fun k hk1 hk2 => by simp [lfN, hk1, hk2])]
    exact td_abs_entry n a b c hdom hfirst ha i j i.isLt j.isLt

/-- The sweep is LU on a band: under the same dominance, `A = L U` exactly, and the
numbers the sweep down and the sweep back produce solve `A x = d`. -/
theorem thomas_sweep_is_lu_and_solves (n : ℕ) (a b c d : ℕ → ℝ)
    (hdom : ∀ i, 1 ≤ i → i ≤ n →
      (if 2 ≤ i then |a i| else 0) + (if i < n then |c i| else 0) ≤ |b i|)
    (hfirst : (if 1 < n then |c 1| else 0) < |b 1|)
    (ha : ∀ i, 2 ≤ i → i ≤ n → a i ≠ 0) :
    tridiag n a b c = lowerFactor n a b c * upperFactor n a b c ∧
    tridiag n a b c *ᵥ (fun i : Fin n => thomasSol n a b c d (i + 1)) =
      fun i : Fin n => d (i + 1) := by
  have hLU : tridiag n a b c = lowerFactor n a b c * upperFactor n a b c := by
    ext i j
    have hs : (lowerFactor n a b c * upperFactor n a b c) i j
        = ∑ k ∈ Finset.range n, lfN a b c i k * ufN a b c k j := by
      simp only [Matrix.mul_apply]
      exact Fin.sum_univ_eq_sum_range (fun k => lfN a b c i k * ufN a b c k j) n
    rw [hs, td_sum_below n i i.isLt _ (fun k hk1 hk2 => by simp [lfN, hk1, hk2])]
    exact (td_lu_entry n a b c hdom hfirst ha i j i.isLt).symm
  refine ⟨hLU, ?_⟩
  rw [hLU, ← Matrix.mulVec_mulVec]
  have hU : upperFactor n a b c *ᵥ (fun i : Fin n => thomasSol n a b c d (i + 1)) =
      fun i : Fin n => swept a b c d (i + 1) := by
    funext i
    have hs : (upperFactor n a b c *ᵥ (fun i : Fin n => thomasSol n a b c d (i + 1))) i
        = ∑ k ∈ Finset.range n, ufN a b c i k * thomasSol n a b c d (k + 1) := by
      simp only [Matrix.mulVec, dotProduct]
      exact Fin.sum_univ_eq_sum_range (fun k => ufN a b c i k * thomasSol n a b c d (k + 1)) n
    rw [hs, td_sum_above n i i.isLt _
      (fun k hk1 hk2 => by simp [ufN, hk1, Ne.symm hk2])]
    exact td_U_row n a b c d hdom hfirst ha i i.isLt
  rw [hU]
  funext i
  have hs : (lowerFactor n a b c *ᵥ (fun i : Fin n => swept a b c d (i + 1))) i
      = ∑ k ∈ Finset.range n, lfN a b c i k * swept a b c d (k + 1) := by
    simp only [Matrix.mulVec, dotProduct]
    exact Fin.sum_univ_eq_sum_range (fun k => lfN a b c i k * swept a b c d (k + 1)) n
  rw [hs, td_sum_below n i i.isLt _ (fun k hk1 hk2 => by simp [lfN, hk1, hk2])]
  exact td_L_row a b c d i

/-- The sweep's flops, line by line as in the card's count: for rows `2, …, n` one divide
for the multiplier, a multiply and a subtract for the pivot, a multiply and a subtract for
the right side; one divide for `x n`; then a multiply, a subtract and a divide for each of
the rows `1, …, n - 1` on the way back. -/
def thomasFlops (n : ℕ) : ℕ :=
  (∑ _i ∈ Finset.Icc 2 n, (1 + 2 + 2)) + 1 + ∑ _i ∈ Finset.Icc 1 (n - 1), 3

/-- A chain of `n ≥ 1` unknowns is solved in exactly `8n - 7` flops. -/
theorem thomas_flop_count (n : ℕ) (hn : 1 ≤ n) : thomasFlops n = 8 * n - 7 := by
  simp only [thomasFlops, Finset.sum_const, Nat.card_Icc, smul_eq_mul]
  omega

/-! The card's exact worked numbers. -/

-- The rod, n = 199: the sweep costs 1,585 flops; dense elimination E(199) = 5,312,902.
example : thomasFlops 199 = 1585 := by simp [thomasFlops]
example : (4 * 199 ^ 3 + 9 * 199 ^ 2 - 7 * 199) / 6 = 5312902 := by norm_num
-- Storage: 4n = 796 numbers for the sweep against n^2 = 39,601 for the full matrix.
example : 4 * 199 = 796 ∧ 199 ^ 2 = 39601 := by norm_num
-- Rod pivots (a = c = -1, b = 2): 2, 3/2, 4/3, ...
example : pivot (fun _ => -1) (fun _ => 2) (fun _ => -1) 1 = 2 := by norm_num [pivot]
example : pivot (fun _ => -1) (fun _ => 2) (fun _ => -1) 2 = 3 / 2 := by norm_num [pivot]
example : pivot (fun _ => -1) (fun _ => 2) (fun _ => -1) 3 = 4 / 3 := by norm_num [pivot]
-- Spline rows 1, 4, 1: pivots 4, 15/4, 56/15.
example : pivot (fun _ => 1) (fun _ => 4) (fun _ => 1) 2 = 15 / 4 := by norm_num [pivot]
example : pivot (fun _ => 1) (fun _ => 4) (fun _ => 1) 3 = 56 / 15 := by norm_num [pivot]
-- The exact parabola T(s) = 20 + 40 s + 200 s (1 - s): ends 20 and 60, 90 in the middle,
-- 92 at s = 3/5 m.
example : (20 : ℚ) + 40 * 0 + 200 * 0 * (1 - 0) = 20 := by norm_num
example : (20 : ℚ) + 40 * 1 + 200 * 1 * (1 - 1) = 60 := by norm_num
example : (20 : ℚ) + 40 * (1 / 2) + 200 * (1 / 2) * (1 - 1 / 2) = 90 := by norm_num
example : (20 : ℚ) + 40 * (3 / 5) + 200 * (3 / 5) * (1 - 3 / 5) = 92 := by norm_num
-- Not dominant: b = (1, 1 + 10^-12, 1), a = c = 1. The second pivot is exactly 10^-12.
example : pivot (fun _ => 1) (fun i => if i = 2 then 1 + 1 / 10 ^ 12 else 1) (fun _ => 1) 2
    = 1 / 10 ^ 12 := by norm_num [pivot]

#print axioms thomas_pivots_exceed_margin_of_diag_dominant
#print axioms thomas_sweep_is_lu_and_solves
#print axioms thomas_flop_count
