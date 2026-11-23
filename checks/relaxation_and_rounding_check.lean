-- Relaxation and rounding: rounding a fractional covering solution up keeps every limit met and costs at most the floor plus one per fractional value, coin-flip rounding fails each limit with chance at most e^(-t) after t rounds, and dual prices certify the floor.
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.FinCases

open Finset

/-- Round-up band. Take "at least" limits `∑ j, a i j * x j ≥ d i` with no negative
coefficients `a i j`. Let `x` be a best fractional solution, with cost `LP = ∑ j, x j`, and let
`OPT` be the fewest whole units that meet every limit. Then rounding every `x j` up still meets
every limit, and `⌈LP⌉ ≤ OPT ≤ ALG_up ≤ LP + k`, where `ALG_up = ∑ j, ⌈x j⌉` and `k` counts the
`x j` that are not whole numbers. -/
theorem round_up_band {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → κ → ℝ) (d : ι → ℝ) (ha : ∀ i j, 0 ≤ a i j)
    (x : κ → ℝ) (hx0 : ∀ j, 0 ≤ x j) (hxcov : ∀ i, d i ≤ ∑ j, a i j * x j)
    (hxopt : ∀ x' : κ → ℝ, (∀ j, 0 ≤ x' j) → (∀ i, d i ≤ ∑ j, a i j * x' j) →
      ∑ j, x j ≤ ∑ j, x' j)
    (OPT : ℕ)
    (hopt : IsLeast {c : ℕ | ∃ z : κ → ℕ, (∀ i, d i ≤ ∑ j, a i j * (z j : ℝ)) ∧ ∑ j, z j = c} OPT) :
    (∀ i, d i ≤ ∑ j, a i j * (⌈x j⌉ : ℝ)) ∧
    ⌈∑ j, x j⌉ ≤ (OPT : ℤ) ∧
    (OPT : ℤ) ≤ ∑ j, ⌈x j⌉ ∧
    ((∑ j, ⌈x j⌉ : ℤ) : ℝ) ≤ ∑ j, x j + (univ.filter (fun j => Int.fract (x j) ≠ 0)).card := by
  have hceil0 : ∀ j, (0 : ℤ) ≤ ⌈x j⌉ := fun j => Int.ceil_nonneg (hx0 j)
  obtain ⟨⟨z, hzcov, hzsum⟩, hlow⟩ := hopt
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro i
    refine (hxcov i).trans (Finset.sum_le_sum fun j _ => ?_)
    exact mul_le_mul_of_nonneg_left (Int.le_ceil (x j)) (ha i j)
  · rw [Int.ceil_le]
    have h := hxopt (fun j => (z j : ℝ)) (fun j => Nat.cast_nonneg _) hzcov
    have hz : (∑ j, (z j : ℝ)) = (OPT : ℝ) := by rw [← hzsum]; push_cast; rfl
    rw [hz] at h
    exact_mod_cast h
  · have hmem : (∑ j, (⌈x j⌉).toNat) ∈
        {c : ℕ | ∃ z : κ → ℕ, (∀ i, d i ≤ ∑ j, a i j * (z j : ℝ)) ∧ ∑ j, z j = c} := by
      refine ⟨fun j => (⌈x j⌉).toNat, fun i => ?_, rfl⟩
      refine (hxcov i).trans (Finset.sum_le_sum fun j _ => ?_)
      refine mul_le_mul_of_nonneg_left ?_ (ha i j)
      have h1 : (((⌈x j⌉).toNat : ℤ) : ℝ) = ((⌈x j⌉ : ℤ) : ℝ) := by
        rw [Int.toNat_of_nonneg (hceil0 j)]
      have h2 : (((⌈x j⌉).toNat : ℕ) : ℝ) = (((⌈x j⌉).toNat : ℤ) : ℝ) := by push_cast; rfl
      rw [h2, h1]
      exact Int.le_ceil (x j)
    have h := hlow hmem
    have h' : ((∑ j, (⌈x j⌉).toNat : ℕ) : ℤ) = ∑ j, ⌈x j⌉ := by
      push_cast
      exact Finset.sum_congr rfl fun j _ => Int.toNat_of_nonneg (hceil0 j)
    rw [← h']
    exact_mod_cast h
  · rw [Finset.card_filter]
    push_cast
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_le_sum fun j _ => ?_
    by_cases hf : Int.fract (x j) = 0
    · simp only [hf, ne_eq, not_true_eq_false, ite_false, add_zero]
      rw [Int.fract_eq_iff] at hf
      obtain ⟨_, _, n, hn⟩ := hf
      have hxn : x j = (n : ℝ) := by linarith
      rw [hxn, Int.ceil_intCast]
    · simp only [hf, ne_eq, not_false_eq_true, ite_true]
      exact (Int.ceil_lt_add_one (x j)).le

/-- Coin-flip rounding, one limit. If the leftover fractions `p m` (each a chance between 0 and 1)
of the patterns that can meet a limit add up to at least 1, then the chance that `t` independent
rounds all leave the limit unmet, `(∏ m, (1 - p m)) ^ t`, is at most `e^(-t)`. -/
theorem coin_rounds_failure_le_exp {ι : Type*} (s : Finset ι) (p : ι → ℝ)
    (hp0 : ∀ m ∈ s, 0 ≤ p m) (hp1 : ∀ m ∈ s, p m ≤ 1) (hsum : 1 ≤ ∑ m ∈ s, p m) (t : ℕ) :
    (∏ m ∈ s, (1 - p m)) ^ t ≤ Real.exp (-(t : ℝ)) := by
  have hprod0 : 0 ≤ ∏ m ∈ s, (1 - p m) :=
    Finset.prod_nonneg fun m hm => by linarith [hp1 m hm]
  have hle : ∏ m ∈ s, (1 - p m) ≤ Real.exp (-1) := by
    calc ∏ m ∈ s, (1 - p m) ≤ ∏ m ∈ s, Real.exp (-p m) := by
          refine Finset.prod_le_prod₀ (fun m hm => by linarith [hp1 m hm]) fun m _ => ?_
          have := Real.add_one_le_exp (-p m)
          linarith
      _ = Real.exp (-∑ m ∈ s, p m) := by
          rw [← Real.exp_sum, Finset.sum_neg_distrib]
      _ ≤ Real.exp (-1) := Real.exp_le_exp.mpr (by linarith)
  calc (∏ m ∈ s, (1 - p m)) ^ t ≤ Real.exp (-1) ^ t := pow_le_pow_left₀ hprod0 hle t
    _ = Real.exp (-(t : ℝ)) := by rw [← Real.exp_nat_mul]; ring_nf

/-- Dual prices certify the floor. For "at least" limits, if prices `y i ≥ 0` charge at most 1
per unit of every pattern (`∑ i, a i j * y i ≤ 1`), then every solution meeting the limits,
fractional or whole, costs at least `∑ i, d i * y i`. -/
theorem dual_prices_bound_floor {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → κ → ℝ) (d : ι → ℝ) (y : ι → ℝ) (hy0 : ∀ i, 0 ≤ y i)
    (hy : ∀ j, ∑ i, a i j * y i ≤ 1)
    (x : κ → ℝ) (hx0 : ∀ j, 0 ≤ x j) (hxcov : ∀ i, d i ≤ ∑ j, a i j * x j) :
    ∑ i, d i * y i ≤ ∑ j, x j := by
  calc ∑ i, d i * y i ≤ ∑ i, (∑ j, a i j * x j) * y i :=
        Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_right (hxcov i) (hy0 i)
    _ = ∑ j, x j * ∑ i, a i j * y i := by
        simp_rw [Finset.sum_mul, Finset.mul_sum]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun i _ => by ring
    _ ≤ ∑ j, x j * 1 :=
        Finset.sum_le_sum fun j _ => mul_le_mul_of_nonneg_left (hy j) (hx0 j)
    _ = ∑ j, x j := by simp

/-! The ward: days and patterns are numbered 0 = Mon to 6 = Sun; pattern `j` starts on day `j`
and works five days in a row, so it works day `i` exactly when `(i - j) mod 7 < 5`. -/

/-- 1 if the pattern starting on day `j` works day `i`, else 0. -/
def works (i j : Fin 7) : ℕ := if (i.val + 7 - j.val) % 7 < 5 then 1 else 0

/-- Nurses needed, Mon to Sun. -/
def need : Fin 7 → ℕ := ![12, 11, 11, 10, 12, 8, 7]

/-- Nurses on duty on day `i` under the whole rota `z`. -/
def onDuty (z : Fin 7 → ℕ) (i : Fin 7) : ℕ := ∑ j, works i j * z j

-- Rounding every pattern up: 7 + 1 + 2 + 2 + 2 + 3 + 0 = 17 nurses, every day covered.
example : (∀ i, need i ≤ onDuty ![7, 1, 2, 2, 2, 3, 0] i) ∧ ∑ j, (![7, 1, 2, 2, 2, 3, 0] : Fin 7 → ℕ) j = 17 := by
  decide

-- Trimming Mon–Fri from 7 to 5: 15 nurses, every day covered.
example : (∀ i, need i ≤ onDuty ![5, 1, 2, 2, 2, 3, 0] i) ∧ ∑ j, (![5, 1, 2, 2, 2, 3, 0] : Fin 7 → ℕ) j = 15 := by
  decide

-- Rounding to nearest (here, down): 13 nurses, Mon to Sat each exactly one short, Sunday covered.
example : (∀ i : Fin 7, i.val < 6 → onDuty ![6, 0, 2, 1, 2, 2, 0] i + 1 = need i) ∧
    need 6 ≤ onDuty ![6, 0, 2, 1, 2, 2, 0] 6 ∧ ∑ j, (![6, 0, 2, 1, 2, 2, 0] : Fin 7 → ℕ) j = 13 := by
  decide

-- Any five days in a row contain at most three of Mon, Wed, Fri, Sat (days 0, 2, 4, 5),
-- and those four days need 12 + 11 + 12 + 8 = 43 nurse-days.
example : (∀ j : Fin 7, works 0 j + works 2 j + works 4 j + works 5 j ≤ 3) ∧
    need 0 + need 2 + need 4 + need 5 = 43 := by
  decide

-- Hence no whole rota of 14 nurses covers the ward: every covering rota has at least 15.
example (z : Fin 7 → ℕ) (hz : ∀ i, need i ≤ onDuty z i) : 15 ≤ ∑ j, z j := by
  have h0 := hz 0; have h2 := hz 2; have h4 := hz 4; have h5 := hz 5
  simp [onDuty, works, need, Fin.sum_univ_succ] at h0 h2 h4 h5 ⊢
  omega

-- The relaxed rota 19/3, 1/3, 2, 4/3, 2, 7/3, 0 covers every day and costs exactly 43/3.
example : (∀ i : Fin 7, (need i : ℚ) ≤ ∑ j, (works i j : ℚ) * (![19/3, 1/3, 2, 4/3, 2, 7/3, 0] : Fin 7 → ℚ) j) ∧
    ∑ j, (![19/3, 1/3, 2, 4/3, 2, 7/3, 0] : Fin 7 → ℚ) j = 43 / 3 := by
  refine ⟨fun i => ?_, ?_⟩
  · fin_cases i <;> simp [works, need, Fin.sum_univ_succ] <;> norm_num
  · simp [Fin.sum_univ_succ]; norm_num

-- Rounding it up gives 7, 1, 2, 2, 2, 3, 0, with four fractional patterns: ceiling 43/3 + 4.
example : (fun j => ⌈(![19/3, 1/3, 2, 4/3, 2, 7/3, 0] : Fin 7 → ℚ) j⌉) = ![7, 1, 2, 2, 2, 3, 0] := by
  funext j; fin_cases j <;> simp <;> norm_num [Int.ceil_eq_iff]

-- Bases tried in the corner search, and placements of 14 nurses on 7 patterns.
example : Nat.choose 14 7 = 3432 ∧ Nat.choose 20 6 = 38760 := by
  decide

#print axioms round_up_band
#print axioms coin_rounds_failure_le_exp
#print axioms dual_prices_bound_floor
