-- Divide-and-conquer recurrences: on sizes that are exact powers of the split, the cost rule T(n) = a T(n/b) + n^d with T(1) = 0 adds up level by level, and its total grows like n^(log_b a), n^d log_b n or n^d as d is below, equal to or above log_b a.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.Asymptotics.Theta
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Filter Asymptotics

/-! The cost rule. `T n` is the cost of the job on `n` items. One call on `n` items makes `a`
smaller jobs, each `b` times smaller, and pays `n ^ d` to split and join. The rule is only used
where `n` is an exact power of `b` bigger than 1, so `n / b` is a whole piece. One item costs
nothing: `T 1 = 0`. Sizes are written `b ^ k`, so `k` is the number of levels, `log_b n`. -/

lemma dcr_cast_rpow (b : ℕ) (d : ℝ) (k : ℕ) :
    ((b ^ k : ℕ) : ℝ) ^ d = ((b : ℝ) ^ d) ^ k := by
  rw [Nat.cast_pow, ← Real.rpow_natCast_mul (Nat.cast_nonneg _), mul_comm,
    Real.rpow_mul_natCast (Nat.cast_nonneg _)]

lemma dcr_step (a b : ℕ) (d : ℝ) (T : ℕ → ℝ) (hb : 2 ≤ b)
    (hT : ∀ n : ℕ, 1 < n → (∃ k : ℕ, n = b ^ k) → T n = a * T (n / b) + (n : ℝ) ^ d)
    (k : ℕ) : T (b ^ (k + 1)) = a * T (b ^ k) + ((b : ℝ) ^ d) ^ (k + 1) := by
  have h1 : 1 < b ^ (k + 1) := Nat.one_lt_pow (Nat.succ_ne_zero k) (by omega)
  rw [hT _ h1 ⟨k + 1, rfl⟩, ← dcr_cast_rpow, pow_succ, Nat.mul_div_cancel _ (by omega)]

lemma dcr_closed (a b : ℕ) (d : ℝ) (T : ℕ → ℝ) (hb : 2 ≤ b) (hT1 : T 1 = 0)
    (hT : ∀ n : ℕ, 1 < n → (∃ k : ℕ, n = b ^ k) → T n = a * T (n / b) + (n : ℝ) ^ d)
    (k : ℕ) :
    T (b ^ k) = ((b : ℝ) ^ d) ^ k * ∑ j ∈ Finset.range k, ((a : ℝ) / (b : ℝ) ^ d) ^ j := by
  have hb0 : (0 : ℝ) < b := by exact_mod_cast (by omega : 0 < b)
  have hB : 0 < (b : ℝ) ^ d := Real.rpow_pos_of_pos hb0 d
  induction k with
  | zero => simp [hT1]
  | succ k ih =>
    rw [dcr_step a b d T hb hT k, ih, Finset.sum_range_succ']
    simp_rw [pow_succ _ (_ : ℕ)]
    rw [← Finset.sum_mul, pow_zero]
    field_simp

lemma dcr_levels (a b : ℕ) (d : ℝ) (T : ℕ → ℝ) (hb : 2 ≤ b) (hT1 : T 1 = 0)
    (hT : ∀ n : ℕ, 1 < n → (∃ k : ℕ, n = b ^ k) → T n = a * T (n / b) + (n : ℝ) ^ d)
    (k : ℕ) :
    T (b ^ k) = ∑ j ∈ Finset.range k, (a : ℝ) ^ j * ((b ^ k / b ^ j : ℕ) : ℝ) ^ d := by
  induction k with
  | zero => simp [hT1]
  | succ k ih =>
    have e : ∀ j : ℕ, b ^ (k + 1) / b ^ (j + 1) = b ^ k / b ^ j := by
      intro j
      rw [pow_succ, pow_succ, Nat.mul_div_mul_right _ _ (by omega)]
    rw [dcr_step a b d T hb hT k, ih, Finset.sum_range_succ']
    simp_rw [e]
    simp only [pow_zero, Nat.div_one, one_mul]
    rw [dcr_cast_rpow, Finset.mul_sum]
    congr 1
    refine Finset.sum_congr rfl fun j _ => ?_
    ring

#print axioms dcr_cast_rpow
#print axioms dcr_step
#print axioms dcr_closed
#print axioms dcr_levels

/-- The master theorem, on sizes that are exact powers of the split. Let `a ≥ 1` jobs per call,
each `b ≥ 2` times smaller, with joining cost `n ^ d`, and `T(1) = 0`. Compare `d` with the
watershed power `log_b a`:
* `d < log_b a`: the work sits at the bottom, and `T(n)` grows like `n ^ (log_b a)`;
* `d = log_b a`: every level costs the same, and `T(n) = n ^ d · log_b n` exactly;
* `d > log_b a`: the work sits at the top, and `T(n)` grows like `n ^ d`.
"Grows like" means: between two fixed positive multiples, for all large sizes (`=Θ`). -/
theorem master_theorem_exact_powers (a b : ℕ) (d : ℝ) (T : ℕ → ℝ)
    (ha : 1 ≤ a) (hb : 2 ≤ b) (hT1 : T 1 = 0)
    (hT : ∀ n : ℕ, 1 < n → (∃ k : ℕ, n = b ^ k) → T n = a * T (n / b) + (n : ℝ) ^ d) :
    (d < Real.logb b a →
      (fun k : ℕ => T (b ^ k)) =Θ[atTop] fun k : ℕ => ((b ^ k : ℕ) : ℝ) ^ Real.logb b a) ∧
    (d = Real.logb b a →
      ∀ k : ℕ, T (b ^ k) = ((b ^ k : ℕ) : ℝ) ^ d * Real.logb b ((b ^ k : ℕ) : ℝ)) ∧
    (Real.logb b a < d →
      (fun k : ℕ => T (b ^ k)) =Θ[atTop] fun k : ℕ => ((b ^ k : ℕ) : ℝ) ^ d) := by
  have hb0 : (0 : ℝ) < b := by exact_mod_cast (by omega : 0 < b)
  have hb1 : (1 : ℝ) < b := by exact_mod_cast (by omega : 1 < b)
  have ha0 : (0 : ℝ) < a := by exact_mod_cast (by omega : 0 < a)
  obtain ⟨B, hBdef⟩ : ∃ B : ℝ, B = (b : ℝ) ^ d := ⟨_, rfl⟩
  have hB : 0 < B := hBdef ▸ Real.rpow_pos_of_pos hb0 d
  have hcl : ∀ k : ℕ, T (b ^ k) = B ^ k * ∑ j ∈ Finset.range k, ((a : ℝ) / B) ^ j := by
    intro k; rw [hBdef]; exact dcr_closed a b d T hb hT1 hT k
  have hg : ∀ k : ℕ, ((b ^ k : ℕ) : ℝ) ^ d = B ^ k := by
    intro k; rw [hBdef]; exact dcr_cast_rpow b d k
  have hL : (b : ℝ) ^ Real.logb b a = a := Real.rpow_logb hb0 hb1.ne' ha0
  refine ⟨fun hd => ?_, fun hd k => ?_, fun hd => ?_⟩
  · have hBa : B < a := by
      rw [hBdef, ← hL]; exact Real.rpow_lt_rpow_of_exponent_lt hb1 hd
    obtain ⟨r, hrdef⟩ : ∃ r : ℝ, r = (a : ℝ) / B := ⟨_, rfl⟩
    have hr : 1 < r := hrdef ▸ (one_lt_div hB).2 hBa
    have hr0 : 0 ≤ r := by linarith
    have hrB : B * r = a := by rw [hrdef]; field_simp
    have hgl : ∀ k : ℕ, ((b ^ k : ℕ) : ℝ) ^ Real.logb b a = (a : ℝ) ^ k := by
      intro k; rw [dcr_cast_rpow, hL]
    have hTnn : ∀ k : ℕ, 0 ≤ T (b ^ k) := by
      intro k; rw [hcl, ← hrdef]
      exact mul_nonneg (pow_nonneg hB.le _) (Finset.sum_nonneg fun j _ => pow_nonneg hr0 _)
    refine ⟨IsBigO.of_bound (1 / (r - 1)) (Eventually.of_forall fun k => ?_),
      IsBigO.of_bound r ((eventually_ge_atTop 1).mono fun k hk => ?_)⟩
    · rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (hTnn k), hgl,
        abs_of_nonneg (by positivity), hcl, ← hrdef, ← hrB, mul_pow]
      have hS := geom_sum_mul r k
      have h1 : ∑ j ∈ Finset.range k, r ^ j ≤ r ^ k / (r - 1) := by
        rw [le_div_iff₀ (by linarith)]; linarith
      calc B ^ k * ∑ j ∈ Finset.range k, r ^ j ≤ B ^ k * (r ^ k / (r - 1)) :=
            mul_le_mul_of_nonneg_left h1 (by positivity)
        _ = 1 / (r - 1) * (B ^ k * r ^ k) := by ring
    · obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
      rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (hTnn _), hgl,
        abs_of_nonneg (by positivity), hcl, ← hrdef, ← hrB, mul_pow]
      have h1 : r ^ m ≤ ∑ j ∈ Finset.range (m + 1), r ^ j :=
        Finset.single_le_sum (f := fun j => r ^ j) (fun j _ => pow_nonneg hr0 _)
          (Finset.mem_range.2 (by omega))
      have h2 : B ^ (m + 1) * r ^ (m + 1) = r * (B ^ (m + 1) * r ^ m) := by ring
      rw [h2]
      exact mul_le_mul_of_nonneg_left (mul_le_mul_of_nonneg_left h1 (by positivity))
        (by positivity)
  · have hBa : B = a := by rw [hBdef, hd, hL]
    rw [hcl, hg, hBa, div_self ha0.ne', Nat.cast_pow, Real.logb_pow,
      Real.logb_self_eq_one hb1]
    simp
  · have hBa : (a : ℝ) < B := by
      rw [hBdef, ← hL]; exact Real.rpow_lt_rpow_of_exponent_lt hb1 hd
    obtain ⟨r, hrdef⟩ : ∃ r : ℝ, r = (a : ℝ) / B := ⟨_, rfl⟩
    have hr : r < 1 := hrdef ▸ (div_lt_one hB).2 hBa
    have hr0 : 0 ≤ r := hrdef ▸ div_nonneg ha0.le hB.le
    have hTnn : ∀ k : ℕ, 0 ≤ T (b ^ k) := by
      intro k; rw [hcl, ← hrdef]
      exact mul_nonneg (pow_nonneg hB.le _) (Finset.sum_nonneg fun j _ => pow_nonneg hr0 _)
    refine ⟨IsBigO.of_bound (1 / (1 - r)) (Eventually.of_forall fun k => ?_),
      IsBigO.of_bound 1 ((eventually_ge_atTop 1).mono fun k hk => ?_)⟩
    · rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (hTnn k), hg,
        abs_of_nonneg (by positivity), hcl, ← hrdef]
      have hS := mul_neg_geom_sum r k
      have hrk : 0 ≤ r ^ k := by positivity
      have h1 : ∑ j ∈ Finset.range k, r ^ j ≤ 1 / (1 - r) := by
        rw [le_div_iff₀ (by linarith)]; linarith
      calc B ^ k * ∑ j ∈ Finset.range k, r ^ j ≤ B ^ k * (1 / (1 - r)) :=
            mul_le_mul_of_nonneg_left h1 (by positivity)
        _ = 1 / (1 - r) * B ^ k := by ring
    · obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
      rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (hTnn _), hg,
        abs_of_nonneg (by positivity), hcl, ← hrdef, one_mul]
      have h1 : r ^ 0 ≤ ∑ j ∈ Finset.range (m + 1), r ^ j :=
        Finset.single_le_sum (f := fun j => r ^ j) (fun j _ => pow_nonneg hr0 _)
          (Finset.mem_range.2 (by omega))
      rw [pow_zero] at h1
      calc B ^ (m + 1) = B ^ (m + 1) * 1 := (mul_one _).symm
        _ ≤ B ^ (m + 1) * ∑ j ∈ Finset.range (m + 1), r ^ j :=
            mul_le_mul_of_nonneg_left h1 (by positivity)

/-- Add the work up one level at a time. With `T(1) = 0`, on `n = b ^ k` items level `j` holds
`a ^ j` jobs of size `n / b ^ j`, each costing `(n / b ^ j) ^ d`, and the total is the sum of the
`k` levels. Each level costs `r = a / b ^ d` times the one above, so the total is also
`n ^ d · (1 + r + ... + r ^ (k - 1))`. -/
theorem total_work_is_the_sum_of_the_levels (a b : ℕ) (d : ℝ) (T : ℕ → ℝ)
    (hb : 2 ≤ b) (hT1 : T 1 = 0)
    (hT : ∀ n : ℕ, 1 < n → (∃ k : ℕ, n = b ^ k) → T n = a * T (n / b) + (n : ℝ) ^ d)
    (k : ℕ) :
    T (b ^ k) = ∑ j ∈ Finset.range k, (a : ℝ) ^ j * ((b ^ k / b ^ j : ℕ) : ℝ) ^ d ∧
    T (b ^ k) = ((b ^ k : ℕ) : ℝ) ^ d *
      ∑ j ∈ Finset.range k, ((a : ℝ) / (b : ℝ) ^ d) ^ j := by
  refine ⟨dcr_levels a b d T hb hT1 hT k, ?_⟩
  rw [dcr_closed a b d T hb hT1 hT k, dcr_cast_rpow]

/-- The log law that turns the piece count at the bottom into a power of the size:
`a ^ (log_b n) = n ^ (log_b a)`, for positive `a` and `n` and a base `b > 0` other than 1. -/
theorem pieces_at_the_bottom_as_a_power (a b n : ℝ) (ha : 0 < a) (hb : 0 < b) (hb1 : b ≠ 1)
    (hn : 0 < n) :
    a ^ Real.logb b n = n ^ Real.logb b a := by
  rw [Real.rpow_def_of_pos ha, Real.rpow_def_of_pos hn, Real.logb, Real.logb]
  congr 1
  ring

/-! The card's worked numbers on a deck of 1,024 cards, level by level: level `j` holds `a ^ j`
piles of `1024 / 2 ^ j` cards. -/

-- Ten halvings take 1,024 cards down to 1.
example : 2 ^ 10 = 1024 := by norm_num

-- Merging, T(n) = 2 T(n/2) + n: every level costs 1,024, and the ten levels total 10,240.
example : ∀ j < 10, 2 ^ j * (1024 / 2 ^ j) = 1024 := by decide
example : ∑ j ∈ Finset.range 10, 2 ^ j * (1024 / 2 ^ j) = 10240 := by decide
example : 10 * 1024 = 10240 := by norm_num

-- Searching, T(n) = T(n/2) + 1: one look per level, ten looks.
example : ∑ j ∈ Finset.range 10, 1 ^ j * (1024 / 2 ^ j) ^ 0 = 10 := by decide

-- Three half-sized pieces, T(n) = 3 T(n/2) + n: the level costs, and the total 116,050.
example : (List.range 10).map (fun j => 3 ^ j * (1024 / 2 ^ j)) =
    [1024, 1536, 2304, 3456, 5184, 7776, 11664, 17496, 26244, 39366] := by decide
example : ∑ j ∈ Finset.range 10, 3 ^ j * (1024 / 2 ^ j) = 116050 := by decide
example : 2 * (3 ^ 10 - 2 ^ 10) = 116050 := by norm_num

-- A quadratic join, T(n) = 2 T(n/2) + n^2: top level 1,048,576, level 9 2,048, total 2,095,104.
example : 2 ^ 0 * (1024 / 2 ^ 0) ^ 2 = 1048576 ∧ 2 ^ 9 * (1024 / 2 ^ 9) ^ 2 = 2048 := by norm_num
example : ∑ j ∈ Finset.range 10, 2 ^ j * (1024 / 2 ^ j) ^ 2 = 2095104 := by decide
example : 2 * 1024 * 1023 = 2095104 := by norm_num

-- The mistakes: the top merge alone, and the bottom level times the level count.
example : 2 ^ 9 * (1024 / 2 ^ 9) + 9 * 1024 = 10240 := by norm_num
example : 3 ^ 10 = 59049 ∧ 3 ^ 10 * 10 = 590490 := by norm_num

#print axioms master_theorem_exact_powers
#print axioms total_work_is_the_sum_of_the_levels
#print axioms pieces_at_the_bottom_as_a_power
