-- Apery's theorem: zeta of 3 is not a fraction, and Beukers' integral is a whole-number combination of 1 and zeta of 3 over the cube of lcm(1, ..., n), positive and at most 2 zeta(3) (sqrt 2 - 1)^(4n).
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.RingTheory.Polynomial.ShiftedLegendre
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.GCDMonoid.Finset
import Mathlib.Algebra.GCDMonoid.Nat
import Mathlib

open Polynomial

/-- `lcmUpTo n` is d_n = lcm(1, 2, ..., n), the smallest whole number that 1, ..., n all divide. -/
def lcmUpTo (n : ℕ) : ℕ := (Finset.Icc 1 n).lcm id

/-- Apery's number a_n = sum over k of C(n, k)^2 C(n + k, k)^2: 1, 5, 73, 1445, 33001, ... -/
def aperyNumber (n : ℕ) : ℕ :=
  ∑ k ∈ Finset.range (n + 1), n.choose k ^ 2 * (n + k).choose k ^ 2

/-- Beukers' integral I_n: the integral over the unit square of
-log(xy) / (1 - xy) times P_n(x) P_n(y), where P_n is the Legendre-type polynomial
(1/n!) (d/dx)^n [x^n (1 - x)^n] (Mathlib's `shiftedLegendre n`). -/
noncomputable def beukersIntegral (n : ℕ) : ℝ :=
  ∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1,
    -Real.log (x * y) / (1 - x * y) * aeval x (shiftedLegendre n) * aeval y (shiftedLegendre n)

section Z3Helpers

open Nat in
theorem cheb_g_ineq (m : ℕ) :
    m / 2 + m / 3 + m / 5 + (if 1 ≤ m ∧ m < 6 then 1 else 0) ≤ m + m / 30 := by
  split_ifs <;> omega

theorem cheb_div_eq (N P c : ℕ) (hc : 0 < c) : c * N / P / c = N / P := by
  rw [Nat.div_div_eq_div_mul, mul_comm P c, Nat.mul_div_mul_left _ _ hc]

theorem cheb_term (n P : ℕ) (hP : 0 < P) :
    15 * n / P + 10 * n / P + 6 * n / P + (if 5 * n < P ∧ P ≤ 30 * n then 1 else 0)
      ≤ 30 * n / P + n / P := by
  have e2 : 30 * n / P / 2 = 15 * n / P := by
    rw [show 30 * n = 2 * (15 * n) by ring]; exact cheb_div_eq _ _ _ (by norm_num)
  have e3 : 30 * n / P / 3 = 10 * n / P := by
    rw [show 30 * n = 3 * (10 * n) by ring]; exact cheb_div_eq _ _ _ (by norm_num)
  have e5 : 30 * n / P / 5 = 6 * n / P := by
    rw [show 30 * n = 5 * (6 * n) by ring]; exact cheb_div_eq _ _ _ (by norm_num)
  have e30 : 30 * n / P / 30 = n / P := by
    rw [show 30 * n = 30 * n by ring]; exact cheb_div_eq _ _ _ (by norm_num)
  have key := cheb_g_ineq (30 * n / P)
  rw [e2, e3, e5, e30] at key
  have hiff : (5 * n < P ∧ P ≤ 30 * n) ↔ (1 ≤ 30 * n / P ∧ 30 * n / P < 6) := by
    rw [Nat.one_le_div_iff hP, Nat.div_lt_iff_lt_mul hP]
    omega
  simp only [hiff]
  exact key

open Nat Finset in
theorem cheb_count (n p : ℕ) (hp : p.Prime) (hn : 0 < n) :
    p.log (30 * n) ≤ p.log (5 * n) +
      ∑ i ∈ Ico 1 (p.log (30 * n) + 1), (if 5 * n < p ^ i ∧ p ^ i ≤ 30 * n then 1 else 0) := by
  rw [Finset.sum_boole]
  have hsub : Ioc (p.log (5 * n)) (p.log (30 * n)) ⊆
      {i ∈ Ico 1 (p.log (30 * n) + 1) | 5 * n < p ^ i ∧ p ^ i ≤ 30 * n} := by
    intro i hi
    simp only [mem_Ioc] at hi
    simp only [mem_filter, mem_Ico]
    refine ⟨⟨by omega, by omega⟩, ?_, ?_⟩
    · exact Nat.lt_pow_of_log_lt hp.one_lt hi.1
    · exact Nat.pow_le_of_le_log (by omega) hi.2
  have := Finset.card_le_card hsub
  simp only [Nat.card_Ioc] at this
  push_cast
  omega

open Nat Finset in
theorem cheb_dvd (n : ℕ) (hn : 0 < n) :
    Nat.lcmUpto (30 * n) * ((15 * n)! * (10 * n)! * (6 * n)!) ∣
      Nat.lcmUpto (5 * n) * ((30 * n)! * n !) := by
  have h1 : Nat.lcmUpto (30 * n) * ((15 * n)! * (10 * n)! * (6 * n)!) ≠ 0 := by
    have := Nat.lcmUpto_ne_zero (30 * n); positivity
  have h2 : Nat.lcmUpto (5 * n) * ((30 * n)! * n !) ≠ 0 := by
    have := Nat.lcmUpto_ne_zero (5 * n); positivity
  rw [← Nat.factorization_le_iff_dvd h1 h2, Finsupp.le_def]
  intro p
  by_cases hp : p.Prime
  swap
  · simp [Nat.factorization_eq_zero_of_not_prime _ hp]
  have hl0 := Nat.lcmUpto_ne_zero (30 * n)
  have hl1 := Nat.lcmUpto_ne_zero (5 * n)
  simp only [Nat.factorization_mul hl0 (by positivity : (15 * n)! * (10 * n)! * (6 * n)! ≠ 0),
    Nat.factorization_mul hl1 (by positivity : (30 * n)! * n ! ≠ 0),
    Nat.factorization_mul (by positivity : (15 * n)! * (10 * n)! ≠ 0) (factorial_ne_zero _),
    Nat.factorization_mul (factorial_ne_zero (15 * n)) (factorial_ne_zero (10 * n)),
    Nat.factorization_mul (factorial_ne_zero (30 * n)) (factorial_ne_zero n),
    Finsupp.add_apply, Nat.factorization_lcmUpto _ hp]
  have hc := cheb_count n p hp hn
  set b := p.log (30 * n) + 1
  have hb : ∀ m ≤ 30 * n, p.log m < b := fun m hm =>
    Nat.lt_succ_of_le (Nat.log_mono_right hm)
  rw [Nat.factorization_factorial hp (hb _ (by omega)),
    Nat.factorization_factorial hp (hb _ (by omega)),
    Nat.factorization_factorial hp (hb _ (by omega)),
    Nat.factorization_factorial hp (hb _ (by omega)),
    Nat.factorization_factorial hp (hb _ (by omega))]
  have hterm : ∑ i ∈ Ico 1 b, (15 * n / p ^ i + 10 * n / p ^ i + 6 * n / p ^ i +
      (if 5 * n < p ^ i ∧ p ^ i ≤ 30 * n then 1 else 0)) ≤
      ∑ i ∈ Ico 1 b, (30 * n / p ^ i + n / p ^ i) :=
    Finset.sum_le_sum fun i _ => cheb_term n (p ^ i) (pow_pos hp.pos i)
  simp only [Finset.sum_add_distrib] at hterm
  omega

theorem cheb_up (n k : ℕ) (hk : k < n) :
    (6 * n).choose k * 5 ^ (6 * n - k) ≤ (6 * n).choose (k + 1) * 5 ^ (6 * n - (k + 1)) := by
  have e := Nat.choose_succ_right_eq (6 * n) k
  have h5 : 5 ^ (6 * n - k) = 5 * 5 ^ (6 * n - (k + 1)) := by
    rw [← pow_succ']; congr 1; omega
  rw [h5]
  refine Nat.le_of_mul_le_mul_right ?_ (by omega : 0 < k + 1)
  calc (6 * n).choose k * (5 * 5 ^ (6 * n - (k + 1))) * (k + 1)
      = (6 * n).choose k * 5 ^ (6 * n - (k + 1)) * (5 * (k + 1)) := by ring
    _ ≤ (6 * n).choose k * 5 ^ (6 * n - (k + 1)) * (6 * n - k) := by
        gcongr; omega
    _ = (6 * n).choose (k + 1) * 5 ^ (6 * n - (k + 1)) * (k + 1) := by rw [mul_right_comm, ← e]; ring

theorem cheb_down (n k : ℕ) (hk : n ≤ k) :
    (6 * n).choose (k + 1) * 5 ^ (6 * n - (k + 1)) ≤ (6 * n).choose k * 5 ^ (6 * n - k) := by
  rcases Nat.lt_or_ge k (6 * n) with hk' | hk'
  · have e := Nat.choose_succ_right_eq (6 * n) k
    have h5 : 5 ^ (6 * n - k) = 5 * 5 ^ (6 * n - (k + 1)) := by
      rw [← pow_succ']; congr 1; omega
    rw [h5]
    refine Nat.le_of_mul_le_mul_right ?_ (by omega : 0 < k + 1)
    calc (6 * n).choose (k + 1) * 5 ^ (6 * n - (k + 1)) * (k + 1)
        = (6 * n).choose k * 5 ^ (6 * n - (k + 1)) * (6 * n - k) := by
          rw [mul_right_comm, e]; ring
      _ ≤ (6 * n).choose k * 5 ^ (6 * n - (k + 1)) * (5 * (k + 1)) := by
          gcongr; omega
      _ = _ := by ring
  · rw [Nat.choose_eq_zero_of_lt (by omega)]; simp

theorem cheb_max (n k : ℕ) :
    (6 * n).choose k * 5 ^ (6 * n - k) ≤ (6 * n).choose n * 5 ^ (6 * n - n) := by
  rcases Nat.le_total k n with hk | hk
  · have : ∀ d k, k + d = n →
        (6 * n).choose k * 5 ^ (6 * n - k) ≤ (6 * n).choose n * 5 ^ (6 * n - n) := by
      intro d
      induction d with
      | zero => intro k h; subst h; simp
      | succ d ih => intro k h; exact (cheb_up n k (by omega)).trans (ih (k + 1) (by omega))
    exact this (n - k) k (by omega)
  · have : ∀ d, (6 * n).choose (n + d) * 5 ^ (6 * n - (n + d)) ≤
        (6 * n).choose n * 5 ^ (6 * n - n) := by
      intro d
      induction d with
      | zero => simp
      | succ d ih => exact (cheb_down n (n + d) (by omega)).trans ih
    have h := this (k - n)
    rwa [show n + (k - n) = k by omega] at h

theorem cheb_choose_lower (n : ℕ) : 6 ^ (6 * n) ≤ (6 * n + 1) * ((6 * n).choose n * 5 ^ (5 * n)) := by
  have hsum : (6 : ℕ) ^ (6 * n) = ∑ k ∈ Finset.range (6 * n + 1), (6 * n).choose k * 5 ^ (6 * n - k) := by
    rw [show (6 : ℕ) = 1 + 5 by norm_num, add_pow]
    refine Finset.sum_congr rfl fun k _ => by simp only [Nat.cast_id]; ring
  rw [hsum]
  have h55 : 6 * n - n = 5 * n := by omega
  calc ∑ k ∈ Finset.range (6 * n + 1), (6 * n).choose k * 5 ^ (6 * n - k)
      ≤ ∑ k ∈ Finset.range (6 * n + 1), (6 * n).choose n * 5 ^ (5 * n) :=
        Finset.sum_le_sum fun k _ => h55 ▸ cheb_max n k
    _ = _ := by simp

theorem cheb_choose_15 (n : ℕ) : (15 * n).choose (10 * n) * 2 ^ (10 * n) ≤ 3 ^ (15 * n) := by
  have hsum : (3 : ℕ) ^ (15 * n) = ∑ k ∈ Finset.range (15 * n + 1), 2 ^ k * 1 ^ (15 * n - k) * (15 * n).choose k := by
    rw [show (3 : ℕ) = 2 + 1 by norm_num, add_pow]
    simp only [Nat.cast_id]
  rw [hsum]
  have := Finset.single_le_sum (f := fun k => 2 ^ k * 1 ^ (15 * n - k) * (15 * n).choose k)
    (fun _ _ => Nat.zero_le _) (Finset.mem_range.2 (by omega : 10 * n < 15 * n + 1))
  simp only [one_pow, mul_one] at this ⊢
  linarith

open Nat in
theorem cheb_step (n : ℕ) (hn : 0 < n) :
    Nat.lcmUpto (30 * n) * 6 ^ (6 * n) * 2 ^ (10 * n) ≤
      (6 * n + 1) * Nat.lcmUpto (5 * n) * (5 ^ 5 * 2 ^ 30 * 3 ^ 15) ^ n := by
  have hd := Nat.le_of_dvd (Nat.pos_of_ne_zero (mul_ne_zero (Nat.lcmUpto_ne_zero _)
    (by positivity))) (cheb_dvd n hn)
  have f30 := Nat.choose_mul_factorial_mul_factorial (show 15 * n ≤ 30 * n by omega)
  have f15 := Nat.choose_mul_factorial_mul_factorial (show 10 * n ≤ 15 * n by omega)
  have f6 := Nat.choose_mul_factorial_mul_factorial (show n ≤ 6 * n by omega)
  rw [show 30 * n - 15 * n = 15 * n by omega] at f30
  rw [show 15 * n - 10 * n = 5 * n by omega] at f15
  rw [show 6 * n - n = 5 * n by omega] at f6
  -- d30 * C(6n,n) ≤ d5 * C(30n,15n) * C(15n,10n)
  have key : Nat.lcmUpto (30 * n) * (6 * n).choose n ≤
      Nat.lcmUpto (5 * n) * ((30 * n).choose (15 * n) * (15 * n).choose (10 * n)) := by
    rw [← f30, ← f6] at hd
    have hpos : 0 < (15 * n)! * (10 * n)! * n ! * (5 * n)! := by positivity
    refine Nat.le_of_mul_le_mul_right ?_ hpos
    calc Nat.lcmUpto (30 * n) * (6 * n).choose n * ((15 * n)! * (10 * n)! * n ! * (5 * n)!)
        = Nat.lcmUpto (30 * n) * ((15 * n)! * (10 * n)! * ((6 * n).choose n * n ! * (5 * n)!)) := by
          ring
      _ ≤ Nat.lcmUpto (5 * n) * ((30 * n).choose (15 * n) * (15 * n)! * (15 * n)! * n !) := hd
      _ = Nat.lcmUpto (5 * n) * ((30 * n).choose (15 * n) * (15 * n)! *
            ((15 * n).choose (10 * n) * (10 * n)! * (5 * n)!) * n !) := by rw [f15]
      _ = _ := by ring
  have c30 := Nat.choose_le_two_pow (30 * n) (15 * n)
  have c15 := cheb_choose_15 n
  have c6 := cheb_choose_lower n
  have e : (5 ^ 5 * 2 ^ 30 * 3 ^ 15 : ℕ) ^ n = 5 ^ (5 * n) * 2 ^ (30 * n) * 3 ^ (15 * n) := by
    rw [mul_pow, mul_pow, ← pow_mul, ← pow_mul, ← pow_mul]
  rw [e]
  set d30 := Nat.lcmUpto (30 * n)
  set d5 := Nat.lcmUpto (5 * n)
  calc d30 * 6 ^ (6 * n) * 2 ^ (10 * n)
      ≤ d30 * ((6 * n + 1) * ((6 * n).choose n * 5 ^ (5 * n))) * 2 ^ (10 * n) := by gcongr
    _ = (6 * n + 1) * 5 ^ (5 * n) * (d30 * (6 * n).choose n) * 2 ^ (10 * n) := by ring
    _ ≤ (6 * n + 1) * 5 ^ (5 * n) *
          (d5 * ((30 * n).choose (15 * n) * (15 * n).choose (10 * n))) * 2 ^ (10 * n) := by
        gcongr
    _ = (6 * n + 1) * 5 ^ (5 * n) * d5 * (30 * n).choose (15 * n) *
          ((15 * n).choose (10 * n) * 2 ^ (10 * n)) := by ring
    _ ≤ (6 * n + 1) * 5 ^ (5 * n) * d5 * 2 ^ (30 * n) * 3 ^ (15 * n) := by gcongr
    _ = _ := by ring

theorem cheb_lcm_mono {a b : ℕ} (h : a ≤ b) : (Nat.lcmUpto a : ℝ) ≤ Nat.lcmUpto b := by
  exact_mod_cast Nat.le_of_dvd (Nat.lcmUpto_pos b) (Nat.lcmUpto_dvd_lcmUpto h)

theorem cheb_step_real (n : ℕ) (hn : 0 < n) :
    (Nat.lcmUpto (30 * n) : ℝ) ≤
      (6 * n + 1) * Nat.lcmUpto (5 * n) * ((2 : ℝ) ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n := by
  have h := cheb_step n hn
  have h' : (Nat.lcmUpto (30 * n) : ℝ) * ((6 : ℝ) ^ 6 * 2 ^ 10) ^ n ≤
      ((6 * n + 1) * Nat.lcmUpto (5 * n) * ((2 : ℝ) ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n) *
        ((6 : ℝ) ^ 6 * 2 ^ 10) ^ n := by
    have hc : ((Nat.lcmUpto (30 * n) * 6 ^ (6 * n) * 2 ^ (10 * n) : ℕ) : ℝ) ≤
        (((6 * n + 1) * Nat.lcmUpto (5 * n) * (5 ^ 5 * 2 ^ 30 * 3 ^ 15) ^ n : ℕ) : ℝ) := by
      exact_mod_cast h
    push_cast at hc
    calc (Nat.lcmUpto (30 * n) : ℝ) * ((6 : ℝ) ^ 6 * 2 ^ 10) ^ n
        = (Nat.lcmUpto (30 * n) : ℝ) * 6 ^ (6 * n) * 2 ^ (10 * n) := by
          rw [mul_pow, ← pow_mul, ← pow_mul]; ring
      _ ≤ _ := hc
      _ = _ := by
          rw [mul_assoc _ _ (((6 : ℝ) ^ 6 * 2 ^ 10) ^ n), ← mul_pow]; norm_num
  exact le_of_mul_le_mul_right h' (by positivity)

theorem cheb_pow (n : ℕ) (hn : 30 ≤ n) : (6 * n + 1 : ℝ) * (16 / 5) ^ 30 ≤ 4 ^ n := by
  induction n, hn using Nat.le_induction with
  | base => norm_num
  | succ k hk ih =>
    have hk' : (30 : ℝ) ≤ k := by exact_mod_cast hk
    have hg := pow_pos (show (0 : ℝ) < 16 / 5 by norm_num) 30
    calc (6 * ((k + 1 : ℕ) : ℝ) + 1) * (16 / 5) ^ 30 ≤ 4 * ((6 * k + 1) * (16 / 5) ^ 30) := by
          push_cast; nlinarith
      _ ≤ 4 * 4 ^ k := by gcongr
      _ = 4 ^ (k + 1) := by ring

theorem cheb_growth : ∃ A : ℝ, 0 < A ∧ ∀ m : ℕ, (Nat.lcmUpto m : ℝ) ≤ A * (16 / 5) ^ m := by
  refine ⟨Nat.lcmUpto 900, by exact_mod_cast Nat.lcmUpto_pos 900, ?_⟩
  intro m
  induction m using Nat.strong_induction_on with
  | _ m ih =>
  rcases le_or_gt m 900 with hm | hm
  · calc (Nat.lcmUpto m : ℝ) ≤ Nat.lcmUpto 900 := cheb_lcm_mono hm
      _ = Nat.lcmUpto 900 * 1 := (mul_one _).symm
      _ ≤ _ := by
        gcongr
        exact one_le_pow₀ (by norm_num)
  · set n := m / 30 + 1 with hn
    have hn30 : 30 ≤ n := by omega
    have h1 : m ≤ 30 * n := by omega
    have h2 : 5 * n < m := by omega
    have h3 : 30 * n ≤ m + 30 := by omega
    have IH := ih (5 * n) h2
    set A : ℝ := (Nat.lcmUpto 900 : ℝ)
    have hA : 0 < A := Nat.cast_pos.mpr (Nat.lcmUpto_pos 900)
    set γ : ℝ := 16 / 5
    have hγ : 0 < γ := by norm_num
    have hρ : (4 : ℝ) * (2 ^ 14 * 3 ^ 9 * 5 ^ 5) ≤ γ ^ 25 := by norm_num [γ]
    have hp := cheb_pow n hn30
    have hstep := cheb_step_real n (by omega)
    -- (6n+1) ρ^n γ^(5n) ≤ γ^m
    have key : (6 * n + 1 : ℝ) * (2 ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n * γ ^ (5 * n) ≤ γ ^ m := by
      have e1 : γ ^ 30 * ((6 * n + 1 : ℝ) * (2 ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n * γ ^ (5 * n)) ≤
          γ ^ (30 * n) := by
        calc γ ^ 30 * ((6 * n + 1 : ℝ) * (2 ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n * γ ^ (5 * n))
            = ((6 * n + 1 : ℝ) * γ ^ 30) * (2 ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n * γ ^ (5 * n) := by ring
          _ ≤ 4 ^ n * (2 ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n * γ ^ (5 * n) := by gcongr
          _ = (4 * (2 ^ 14 * 3 ^ 9 * 5 ^ 5)) ^ n * γ ^ (5 * n) := by rw [← mul_pow]
          _ ≤ (γ ^ 25) ^ n * γ ^ (5 * n) := by gcongr
          _ = γ ^ (30 * n) := by rw [← pow_mul, ← pow_add]; ring_nf
      have e2 : γ ^ (30 * n) ≤ γ ^ 30 * γ ^ m := by
        rw [← pow_add]; exact pow_le_pow_right₀ (by norm_num [γ]) (by omega)
      have := e1.trans e2
      exact le_of_mul_le_mul_left this (by positivity)
    calc (Nat.lcmUpto m : ℝ) ≤ Nat.lcmUpto (30 * n) := cheb_lcm_mono h1
      _ ≤ (6 * n + 1) * Nat.lcmUpto (5 * n) * ((2 : ℝ) ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n := hstep
      _ ≤ (6 * n + 1) * (A * γ ^ (5 * n)) * ((2 : ℝ) ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n := by gcongr
      _ = A * ((6 * n + 1 : ℝ) * (2 ^ 14 * 3 ^ 9 * 5 ^ 5) ^ n * γ ^ (5 * n)) := by ring
      _ ≤ A * γ ^ m := by gcongr

open MeasureTheory Set
open scoped Nat


theorem z3_series_integral {g : ℝ → ℝ} {f : ℕ → ℝ → ℝ} {S : ℝ}
    (hf : ∀ k, IntervalIntegrable (f k) volume 0 1)
    (hnn : ∀ k, ∀ x ∈ Ioo (0 : ℝ) 1, 0 ≤ f k x)
    (hsum : ∀ x ∈ Ioo (0 : ℝ) 1, HasSum (fun k => f k x) (g x))
    (hS : HasSum (fun k => ∫ x in (0 : ℝ)..1, f k x) S) :
    IntervalIntegrable g volume 0 1 ∧ ∫ x in (0 : ℝ)..1, g x = S := by
  set μ := volume.restrict (Ioo (0 : ℝ) 1)
  have hae : ∀ᵐ x ∂μ, x ∈ Ioo (0 : ℝ) 1 := ae_restrict_mem measurableSet_Ioo
  have hfi : ∀ k, Integrable (f k) μ := fun k =>
    (intervalIntegrable_iff_integrableOn_Ioo_of_le zero_le_one).1 (hf k)
  have hint : ∀ k, ∫ x in (0 : ℝ)..1, f k x = ∫ x, f k x ∂μ := fun k => by
    rw [intervalIntegral.integral_of_le zero_le_one, integral_Ioc_eq_integral_Ioo]
  simp only [hint] at hS
  have hnorm : ∀ k, ∫ x, ‖f k x‖ ∂μ = ∫ x, f k x ∂μ := fun k =>
    integral_congr_ae (hae.mono fun x hx => Real.norm_of_nonneg (hnn k x hx))
  have h1 := hasSum_integral_of_summable_integral_norm hfi (by simp only [hnorm]; exact hS.summable)
  have h2 : ∫ x, (∑' k, f k x) ∂μ = ∫ x, g x ∂μ :=
    integral_congr_ae (hae.mono fun x hx => (hsum x hx).tsum_eq)
  rw [h2] at h1
  have hval : ∫ x, g x ∂μ = S := h1.unique hS
  have hmeas : AEStronglyMeasurable g μ := by
    refine aestronglyMeasurable_of_tendsto_ae (u := Filter.atTop)
      (f := fun (s : Finset ℕ) x => ∑ k ∈ s, f k x) ?_ ?_
    · intro s
      exact (Finset.aestronglyMeasurable_fun_sum s fun k _ => (hfi k).1)
    · exact hae.mono fun x hx => hsum x hx
  have hgnn : ∀ᵐ x ∂μ, 0 ≤ g x :=
    hae.mono fun x hx => (hsum x hx).nonneg fun k => hnn k x hx
  have hfin : HasFiniteIntegral g μ := by
    rw [hasFiniteIntegral_iff_ofReal hgnn]
    have e1 : ∫⁻ x, ENNReal.ofReal (g x) ∂μ = ∫⁻ x, ∑' k, ENNReal.ofReal (f k x) ∂μ := by
      refine lintegral_congr_ae (hae.mono fun x hx => ?_)
      show ENNReal.ofReal (g x) = ∑' k, ENNReal.ofReal (f k x)
      rw [← (hsum x hx).tsum_eq, ENNReal.ofReal_tsum_of_nonneg (fun k => hnn k x hx)
        (hsum x hx).summable]
    rw [e1, lintegral_tsum (fun k => (hfi k).1.aemeasurable.ennreal_ofReal)]
    have e2 : ∀ k, ∫⁻ x, ENNReal.ofReal (f k x) ∂μ = ENNReal.ofReal (∫ x, f k x ∂μ) := fun k =>
      (ofReal_integral_eq_lintegral_ofReal (hfi k)
        (hae.mono fun x hx => hnn k x hx)).symm
    simp only [e2]
    rw [← ENNReal.ofReal_tsum_of_nonneg (fun k => integral_nonneg_of_ae
      (hae.mono fun x hx => hnn k x hx)) hS.summable]
    exact ENNReal.ofReal_lt_top
  refine ⟨(intervalIntegrable_iff_integrableOn_Ioo_of_le zero_le_one).2 ⟨hmeas, hfin⟩, ?_⟩
  rw [intervalIntegral.integral_of_le zero_le_one, integral_Ioc_eq_integral_Ioo]
  exact hval

theorem z3_mom_pow (m : ℕ) : ∫ y in (0 : ℝ)..1, y ^ m = 1 / (m + 1) := by
  rw [integral_pow]; simp

theorem z3_mom_log (m : ℕ) : ∫ y in (0 : ℝ)..1, y ^ m * (-Real.log y) = 1 / ((m : ℝ) + 1) ^ 2 := by
  have hF : ∀ y ∈ Ioo (0 : ℝ) 1, HasDerivAt
      (fun y : ℝ => y ^ (m + 1) / ((m : ℝ) + 1) ^ 2 - y ^ (m + 1) * Real.log y / ((m : ℝ) + 1))
      (y ^ m * (-Real.log y)) y := by
    intro y hy
    have hy0 : y ≠ 0 := hy.1.ne'
    have h1 := (hasDerivAt_pow (m + 1) y).div_const (((m : ℝ) + 1) ^ 2)
    have h2 := (((hasDerivAt_pow (m + 1) y).mul (Real.hasDerivAt_log hy0))).div_const ((m : ℝ) + 1)
    convert h1.sub h2 using 1
    push_cast
    field_simp
    ring
  have hcont : ContinuousOn
      (fun y : ℝ => y ^ (m + 1) / ((m : ℝ) + 1) ^ 2 - y ^ (m + 1) * Real.log y / ((m : ℝ) + 1))
      (Icc 0 1) := by
    have : (fun y : ℝ => y ^ (m + 1) * Real.log y) = fun y => y ^ m * (y * Real.log y) := by
      ext y; ring
    refine Continuous.continuousOn ?_
    refine ((continuous_pow _).div_const _).sub ?_
    have hc : Continuous (fun y : ℝ => y ^ (m + 1) * Real.log y) := by
      rw [this]; exact (continuous_pow m).mul Real.continuous_mul_log
    exact hc.div_const _
  have hint : IntervalIntegrable (fun y : ℝ => y ^ m * (-Real.log y)) volume 0 1 := by
    have := (intervalIntegral.intervalIntegrable_log' (a := 0) (b := 1)).neg
    exact this.continuousOn_mul (continuous_pow m).continuousOn
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le zero_le_one hcont hF hint]
  simp

theorem z3_int_powlog (m : ℕ) :
    IntervalIntegrable (fun y : ℝ => y ^ m * (-Real.log y)) volume 0 1 :=
  (intervalIntegral.intervalIntegrable_log' (a := 0) (b := 1)).neg.continuousOn_mul
    (continuous_pow m).continuousOn

theorem z3_summable_inner (j : ℕ) {x : ℝ} (hx : x ∈ Ioo (0 : ℝ) 1) :
    Summable (fun k : ℕ => x ^ k * (-Real.log x / ((j : ℝ) + k + 1) + 1 / ((j : ℝ) + k + 1) ^ 2)) := by
  have hl : 0 ≤ -Real.log x := neg_nonneg.2 (Real.log_nonpos hx.1.le hx.2.le)
  refine Summable.of_nonneg_of_le (fun k => ?_) (fun k => ?_)
    ((summable_geometric_of_lt_one hx.1.le hx.2).mul_right (-Real.log x + 1))
  · have : (0 : ℝ) < (j : ℝ) + k + 1 := by positivity
    have := pow_pos hx.1 k
    positivity
  · have h1 : (1 : ℝ) ≤ (j : ℝ) + k + 1 := le_add_of_nonneg_left (by positivity)
    have hk := pow_pos hx.1 k
    gcongr
    · exact div_le_self hl h1
    · rw [div_le_one (by positivity)]; nlinarith

theorem z3_inner (j : ℕ) {x : ℝ} (hx : x ∈ Ioo (0 : ℝ) 1) :
    IntervalIntegrable (fun y => -Real.log (x * y) / (1 - x * y) * y ^ j) volume 0 1 ∧
      ∫ y in (0 : ℝ)..1, -Real.log (x * y) / (1 - x * y) * y ^ j =
        ∑' k : ℕ, x ^ k * (-Real.log x / ((j : ℝ) + k + 1) + 1 / ((j : ℝ) + k + 1) ^ 2) := by
  have hl : 0 ≤ -Real.log x := neg_nonneg.2 (Real.log_nonpos hx.1.le hx.2.le)
  refine z3_series_integral
    (f := fun k y => x ^ k * (-Real.log x) * y ^ (j + k) + x ^ k * (y ^ (j + k) * (-Real.log y)))
    (fun k => ?_) (fun k y hy => ?_) (fun y hy => ?_) ?_
  · exact ((intervalIntegrable_const.mul_continuousOn (continuous_pow _).continuousOn)).add
      ((z3_int_powlog (j + k)).const_mul _)
  · have := pow_pos hx.1 k
    have := pow_pos hy.1 (j + k)
    have : 0 ≤ -Real.log y := neg_nonneg.2 (Real.log_nonpos hy.1.le hy.2.le)
    positivity
  · have hxy0 : 0 ≤ x * y := mul_nonneg hx.1.le hy.1.le
    have hxy1 : x * y < 1 := by nlinarith [hx.1, hx.2, hy.1, hy.2]
    have hg := (hasSum_geometric_of_lt_one hxy0 hxy1).mul_left (y ^ j * (-Real.log x - Real.log y))
    convert hg using 1
    · ext k; rw [mul_pow, pow_add]; ring
    · rw [Real.log_mul hx.1.ne' hy.1.ne']; field_simp; ring
  · have hint : ∀ k : ℕ, ∫ y in (0 : ℝ)..1,
        x ^ k * (-Real.log x) * y ^ (j + k) + x ^ k * (y ^ (j + k) * (-Real.log y)) =
        x ^ k * (-Real.log x / ((j : ℝ) + k + 1) + 1 / ((j : ℝ) + k + 1) ^ 2) := by
      intro k
      rw [intervalIntegral.integral_add
        (intervalIntegrable_const.mul_continuousOn (continuous_pow _).continuousOn)
        ((z3_int_powlog (j + k)).const_mul _),
        intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
        z3_mom_pow, z3_mom_log]
      push_cast
      ring
    simp only [hint]
    exact (z3_summable_inner j hx).hasSum

theorem z3_summable_outer (i j : ℕ) :
    Summable (fun k : ℕ => 1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
      1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) := by
  have hs : Summable (fun k : ℕ => 2 * (1 / ((k : ℝ) + 1) ^ 2)) := by
    refine Summable.mul_left 2 ?_
    have := (summable_nat_add_iff 1).2 (Real.summable_one_div_nat_pow.2 (by norm_num : 1 < 2))
    simpa using this
  refine Summable.of_nonneg_of_le (fun k => by positivity) (fun k => ?_) hs
  have hk : (1 : ℝ) ≤ (k : ℝ) + 1 := le_add_of_nonneg_left (by positivity)
  have hi : (k : ℝ) + 1 ≤ (i : ℝ) + k + 1 := by linarith [Nat.cast_nonneg (α := ℝ) i]
  have hj : (k : ℝ) + 1 ≤ (j : ℝ) + k + 1 := by linarith [Nat.cast_nonneg (α := ℝ) j]
  have a1 : 1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) ≤ 1 / ((k : ℝ) + 1) ^ 2 := by
    apply one_div_le_one_div_of_le (by positivity)
    calc ((k : ℝ) + 1) ^ 2 = ((k : ℝ) + 1) ^ 2 * 1 := by ring
      _ ≤ ((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1) := by gcongr; linarith
  have a2 : 1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2) ≤ 1 / ((k : ℝ) + 1) ^ 2 := by
    apply one_div_le_one_div_of_le (by positivity)
    calc ((k : ℝ) + 1) ^ 2 = 1 * ((k : ℝ) + 1) ^ 2 := by ring
      _ ≤ ((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2 := by gcongr; linarith
  linarith

theorem z3_outer (i j : ℕ) :
    IntervalIntegrable (fun x : ℝ => x ^ i *
        ∑' k : ℕ, x ^ k * (-Real.log x / ((j : ℝ) + k + 1) + 1 / ((j : ℝ) + k + 1) ^ 2))
        volume 0 1 ∧
      ∫ x in (0 : ℝ)..1, x ^ i *
        ∑' k : ℕ, x ^ k * (-Real.log x / ((j : ℝ) + k + 1) + 1 / ((j : ℝ) + k + 1) ^ 2) =
      ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) := by
  refine z3_series_integral
    (f := fun k x => (x ^ (i + k) * (-Real.log x)) * (1 / ((j : ℝ) + k + 1)) +
      x ^ (i + k) * (1 / ((j : ℝ) + k + 1) ^ 2))
    (fun k => ?_) (fun k x hx => ?_) (fun x hx => ?_) ?_
  · exact ((z3_int_powlog (i + k)).mul_const _).add
      ((continuous_pow _).intervalIntegrable 0 1 |>.mul_const _)
  · have := pow_pos hx.1 (i + k)
    have : 0 ≤ -Real.log x := neg_nonneg.2 (Real.log_nonpos hx.1.le hx.2.le)
    positivity
  · have h := ((z3_summable_inner j hx).hasSum).mul_left (x ^ i)
    convert h using 1
    ext k; rw [pow_add]; ring
  · have hint : ∀ k : ℕ, ∫ x in (0 : ℝ)..1, (x ^ (i + k) * (-Real.log x)) * (1 / ((j : ℝ) + k + 1)) +
        x ^ (i + k) * (1 / ((j : ℝ) + k + 1) ^ 2) =
        1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
          1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2) := by
      intro k
      rw [intervalIntegral.integral_add ((z3_int_powlog (i + k)).mul_const _)
        ((continuous_pow _).intervalIntegrable 0 1 |>.mul_const _),
        intervalIntegral.integral_mul_const, intervalIntegral.integral_mul_const,
        z3_mom_pow, z3_mom_log]
      push_cast
      field_simp
    simp only [hint]
    exact (z3_summable_outer i j).hasSum

theorem z3_congr01 {f g : ℝ → ℝ} (h : ∀ x ∈ Ioo (0 : ℝ) 1, f x = g x) :
    ∫ x in (0 : ℝ)..1, f x = ∫ x in (0 : ℝ)..1, g x := by
  rw [intervalIntegral.integral_of_le zero_le_one, intervalIntegral.integral_of_le zero_le_one,
    integral_Ioc_eq_integral_Ioo, integral_Ioc_eq_integral_Ioo]
  exact setIntegral_congr_fun measurableSet_Ioo h

theorem z3_P_eq (n : ℕ) (x : ℝ) :
    aeval x (shiftedLegendre n) = ∑ k ∈ Finset.range (n + 1),
      (((-1 : ℤ) ^ k * n.choose k * (n + k).choose n : ℤ) : ℝ) * x ^ k := by
  simp [shiftedLegendre, map_sum]

theorem z3_expand (n : ℕ) :
    (∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1,
      -Real.log (x * y) / (1 - x * y) * aeval x (shiftedLegendre n) * aeval y (shiftedLegendre n)) =
    ∑ i ∈ Finset.range (n + 1), ∑ j ∈ Finset.range (n + 1),
      (((-1 : ℤ) ^ i * n.choose i * (n + i).choose n : ℤ) : ℝ) *
      (((-1 : ℤ) ^ j * n.choose j * (n + j).choose n : ℤ) : ℝ) *
      ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) := by
  set c : ℕ → ℝ := fun k => (((-1 : ℤ) ^ k * n.choose k * (n + k).choose n : ℤ) : ℝ) with hc
  set S : ℕ → ℝ → ℝ := fun j x =>
    ∑' k : ℕ, x ^ k * (-Real.log x / ((j : ℝ) + k + 1) + 1 / ((j : ℝ) + k + 1) ^ 2) with hS
  have hP : ∀ x : ℝ, aeval x (shiftedLegendre n) = ∑ k ∈ Finset.range (n + 1), c k * x ^ k :=
    z3_P_eq n
  have step1 : ∀ x ∈ Ioo (0 : ℝ) 1, (∫ y in (0 : ℝ)..1,
      -Real.log (x * y) / (1 - x * y) * aeval x (shiftedLegendre n) * aeval y (shiftedLegendre n)) =
      ∑ i ∈ Finset.range (n + 1), ∑ j ∈ Finset.range (n + 1), c i * c j * (x ^ i * S j x) := by
    intro x hx
    have e : (fun y => -Real.log (x * y) / (1 - x * y) * aeval x (shiftedLegendre n) *
        aeval y (shiftedLegendre n)) = fun y => ∑ j ∈ Finset.range (n + 1),
          (aeval x (shiftedLegendre n) * c j) * (-Real.log (x * y) / (1 - x * y) * y ^ j) := by
      ext y; rw [hP y, Finset.mul_sum]; refine Finset.sum_congr rfl fun j _ => by ring
    rw [e, intervalIntegral.integral_finsetSum (fun j _ => (z3_inner j hx).1.const_mul _)]
    simp only [intervalIntegral.integral_const_mul, (z3_inner _ hx).2]
    rw [hP x]
    simp only [Finset.sum_mul]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    simp only [hS]; ring
  have hii : ∀ i, IntervalIntegrable
      (fun x => ∑ j ∈ Finset.range (n + 1), c i * c j * (x ^ i * S j x)) volume 0 1 := by
    intro i
    have := IntervalIntegrable.sum (Finset.range (n + 1)) (f := fun j x => c i * c j * (x ^ i * S j x))
      (fun j _ => (z3_outer i j).1.const_mul _)
    convert this using 1
    ext x; simp [Finset.sum_apply]
  rw [z3_congr01 step1, intervalIntegral.integral_finsetSum (fun i _ => hii i)]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [intervalIntegral.integral_finsetSum (fun j _ => (z3_outer i j).1.const_mul _)]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [intervalIntegral.integral_const_mul, (z3_outer i j).2]

theorem z3_sigma_diag (i : ℕ) :
    ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((i : ℝ) + k + 1)) +
        1 / (((i : ℝ) + k + 1) * ((i : ℝ) + k + 1) ^ 2)) =
      2 * ((∑' m : ℕ, 1 / (m : ℝ) ^ 3) - ∑ m ∈ Finset.range (i + 1), 1 / (m : ℝ) ^ 3) := by
  have hs : Summable (fun m : ℕ => 1 / (m : ℝ) ^ 3) := Real.summable_one_div_nat_pow.2 (by norm_num)
  have h := hs.sum_add_tsum_nat_add (i + 1)
  have e : ∀ k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((i : ℝ) + k + 1)) +
        1 / (((i : ℝ) + k + 1) * ((i : ℝ) + k + 1) ^ 2)) = 2 * (1 / (((k + (i + 1) : ℕ) : ℝ)) ^ 3) := by
    intro k; push_cast; field_simp; ring
  simp only [e]
  rw [tsum_mul_left, ← h]
  ring

theorem z3_sigma_off (j e : ℕ) :
    ∑' k : ℕ, (1 / ((((j + e : ℕ) : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / ((((j + e : ℕ) : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) * e =
      ∑ m ∈ Finset.range e, 1 / ((j : ℝ) + m + 1) ^ 2 := by
  set f : ℕ → ℝ := fun k => 1 / ((j : ℝ) + k + 1) ^ 2 with hf
  have hs : Summable f := by
    have := (summable_nat_add_iff (j + 1)).2 (Real.summable_one_div_nat_pow.2 (by norm_num : 1 < 2))
    refine this.congr fun k => ?_
    simp only [hf]; push_cast; ring_nf
  have h := hs.sum_add_tsum_nat_add e
  have hs' : Summable (fun k => f (k + e)) := (summable_nat_add_iff e).2 hs
  have term : ∀ k : ℕ, (1 / ((((j + e : ℕ) : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / ((((j + e : ℕ) : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) * e = f k - f (k + e) := by
    intro k; simp only [hf]; push_cast; field_simp; ring
  simp only [term]
  rw [hs.tsum_sub hs', ← h]
  ring

theorem z3_sigma_symm (i j : ℕ) :
    ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) =
    ∑' k : ℕ, (1 / (((j : ℝ) + k + 1) ^ 2 * ((i : ℝ) + k + 1)) +
        1 / (((j : ℝ) + k + 1) * ((i : ℝ) + k + 1) ^ 2)) := by
  congr 1; ext k; rw [add_comm]; ring

theorem z3_cast_div {d m : ℕ} (h : m ∣ d) : ((d / m : ℕ) : ℝ) = (d : ℝ) * (1 / (m : ℝ)) := by
  rcases Nat.eq_zero_or_pos m with rfl | hm
  · simp
  · rw [Nat.cast_div h (by exact_mod_cast hm.ne')]; ring

theorem z3_dvd_lcm {n m : ℕ} (h1 : 1 ≤ m) (h2 : m ≤ n) : m ∣ (Finset.Icc 1 n).lcm id :=
  Finset.dvd_lcm (s := Finset.Icc 1 n) (f := id) (Finset.mem_Icc.2 ⟨h1, h2⟩)

theorem z3_sigma_int (n i j : ℕ) (hi : i ≤ n) (hj : j ≤ n) :
    ∃ a : ℤ, (((Finset.Icc 1 n).lcm id : ℕ) : ℝ) ^ 3 *
      ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) =
      a + (if i = j then 2 * (((Finset.Icc 1 n).lcm id : ℕ) : ℝ) ^ 3 else 0) *
        ∑' m : ℕ, 1 / (m : ℝ) ^ 3 := by
  set d := (Finset.Icc 1 n).lcm id
  -- the off-diagonal case with i = j + e
  have off : ∀ j e : ℕ, 1 ≤ e → j + e ≤ n → ∃ a : ℤ, (d : ℝ) ^ 3 *
      ∑' k : ℕ, (1 / ((((j + e : ℕ) : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / ((((j + e : ℕ) : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) = a := by
    intro j e he hje
    refine ⟨((d / e : ℕ) : ℤ) * ∑ m ∈ Finset.range e, ((d / (j + m + 1) : ℕ) : ℤ) ^ 2, ?_⟩
    have hsig := z3_sigma_off j e
    have hepos : (0 : ℝ) < e := by exact_mod_cast he
    have hσ : ∑' k : ℕ, (1 / ((((j + e : ℕ) : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / ((((j + e : ℕ) : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) =
        (1 / (e : ℝ)) * ∑ m ∈ Finset.range e, 1 / ((j : ℝ) + m + 1) ^ 2 := by
      rw [← hsig, tsum_mul_right]; field_simp
    rw [hσ]
    simp only [Int.cast_mul, Int.cast_sum, Int.cast_pow, Int.cast_natCast]
    rw [z3_cast_div (z3_dvd_lcm (n := n) he (by omega)), Finset.mul_sum, Finset.mul_sum,
      Finset.mul_sum]
    refine Finset.sum_congr rfl fun m hm => ?_
    have hm' := Finset.mem_range.1 hm
    have hdv : (j + m + 1) ∣ d := z3_dvd_lcm (n := n) (by omega) (by omega)
    rw [z3_cast_div hdv]
    simp only [d]
    push_cast
    field_simp
  rcases lt_trichotomy i j with h | rfl | h
  · obtain ⟨a, ha⟩ := off i (j - i) (by omega) (by omega)
    refine ⟨a, ?_⟩
    rw [if_neg h.ne, zero_mul, add_zero, z3_sigma_symm, ← ha]
    congr 3 <;> push_cast [show i + (j - i) = j by omega] <;> rfl
  · refine ⟨-2 * ∑ m ∈ Finset.range (i + 1), ((d / m : ℕ) : ℤ) ^ 3, ?_⟩
    rw [if_pos rfl, z3_sigma_diag]
    simp only [Int.cast_mul, Int.cast_sum, Int.cast_pow, Int.cast_natCast, Int.cast_neg,
      Int.cast_ofNat]
    have : ∀ m ∈ Finset.range (i + 1), ((d / m : ℕ) : ℝ) ^ 3 = (d : ℝ) ^ 3 * (1 / (m : ℝ) ^ 3) := by
      intro m hm
      have hm' := Finset.mem_range.1 hm
      rcases Nat.eq_zero_or_pos m with rfl | hmpos
      · simp
      rw [z3_cast_div (z3_dvd_lcm (n := n) hmpos (by omega))]; ring
    rw [Finset.sum_congr rfl this, ← Finset.mul_sum]
    ring
  · obtain ⟨a, ha⟩ := off j (i - j) (by omega) (by omega)
    refine ⟨a, ?_⟩
    rw [if_neg h.ne', zero_mul, add_zero, ← ha]
    congr 3 <;> push_cast [show j + (i - j) = i by omega] <;> rfl


theorem z3_zeta_re : (riemannZeta 3).re = ∑' m : ℕ, 1 / (m : ℝ) ^ 3 := by
  have h := zeta_nat_eq_tsum_of_gt_one (k := 3) (by norm_num)
  push_cast at h
  rw [h, show (∑' m : ℕ, 1 / (m : ℂ) ^ 3) = ((∑' m : ℕ, 1 / (m : ℝ) ^ 3 : ℝ) : ℂ) by
    rw [Complex.ofReal_tsum]; push_cast; rfl]
  exact Complex.ofReal_re _

theorem z3_thm2 (n : ℕ) :
    ∃ A B : ℤ, B = 2 * (aperyNumber n : ℤ) * (lcmUpTo n : ℤ) ^ 3 ∧
      (lcmUpTo n : ℝ) ^ 3 * beukersIntegral n = A + B * (riemannZeta 3).re := by
  have hI := z3_expand n
  have hint : ∀ i j : ℕ, ∃ a : ℤ, i ≤ n → j ≤ n → (((Finset.Icc 1 n).lcm id : ℕ) : ℝ) ^ 3 *
      ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
        1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2)) =
      a + (if i = j then 2 * (((Finset.Icc 1 n).lcm id : ℕ) : ℝ) ^ 3 else 0) *
        ∑' m : ℕ, 1 / (m : ℝ) ^ 3 := by
    intro i j
    by_cases h : i ≤ n ∧ j ≤ n
    · obtain ⟨a, ha⟩ := z3_sigma_int n i j h.1 h.2
      exact ⟨a, fun _ _ => ha⟩
    · exact ⟨0, fun h1 h2 => absurd ⟨h1, h2⟩ h⟩
  choose a ha using hint
  set cZ : ℕ → ℤ := fun k => (-1 : ℤ) ^ k * n.choose k * (n + k).choose n with hcZ
  refine ⟨∑ i ∈ Finset.range (n + 1), ∑ j ∈ Finset.range (n + 1), cZ i * cZ j * a i j,
    2 * (aperyNumber n : ℤ) * (lcmUpTo n : ℤ) ^ 3, rfl, ?_⟩
  rw [z3_zeta_re]
  unfold beukersIntegral
  rw [hI, Finset.mul_sum]
  simp only [Finset.mul_sum]
  have e1 : ∀ i ∈ Finset.range (n + 1), ∀ j ∈ Finset.range (n + 1),
      (lcmUpTo n : ℝ) ^ 3 * ((cZ i : ℝ) * (cZ j : ℝ) *
        ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
          1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2))) =
      (cZ i : ℝ) * cZ j * a i j + (if i = j then (cZ i : ℝ) * cZ i * (2 * (lcmUpTo n : ℝ) ^ 3) else 0) *
        ∑' m : ℕ, 1 / (m : ℝ) ^ 3 := by
    intro i hi j hj
    have := ha i j (by simpa [Nat.lt_succ_iff] using hi) (by simpa [Nat.lt_succ_iff] using hj)
    unfold lcmUpTo
    rw [show (((Finset.Icc 1 n).lcm id : ℕ) : ℝ) ^ 3 * ((cZ i : ℝ) * (cZ j : ℝ) *
        ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
          1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2))) =
        (cZ i : ℝ) * cZ j * ((((Finset.Icc 1 n).lcm id : ℕ) : ℝ) ^ 3 *
        ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
          1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2))) by ring, this]
    split_ifs with hij
    · subst hij; ring
    · ring
  have e1' : ∀ i ∈ Finset.range (n + 1),
      ∑ j ∈ Finset.range (n + 1), (lcmUpTo n : ℝ) ^ 3 * ((cZ i : ℝ) * (cZ j : ℝ) *
        ∑' k : ℕ, (1 / (((i : ℝ) + k + 1) ^ 2 * ((j : ℝ) + k + 1)) +
          1 / (((i : ℝ) + k + 1) * ((j : ℝ) + k + 1) ^ 2))) =
      ∑ j ∈ Finset.range (n + 1), (cZ i : ℝ) * cZ j * a i j +
        (cZ i : ℝ) * cZ i * (2 * (lcmUpTo n : ℝ) ^ 3) * ∑' m : ℕ, 1 / (m : ℝ) ^ 3 := by
    intro i hi
    rw [Finset.sum_congr rfl (e1 i hi), Finset.sum_add_distrib]
    congr 1
    simp only [ite_mul, zero_mul]
    rw [Finset.sum_ite_eq (Finset.range (n + 1)) i, if_pos hi]
  rw [Finset.sum_congr rfl e1', Finset.sum_add_distrib]
  push_cast
  congr 1
  rw [← Finset.sum_mul, ← Finset.sum_mul]
  congr 1
  unfold aperyNumber
  push_cast
  rw [Finset.mul_sum, Finset.sum_mul, Finset.sum_mul]
  refine Finset.sum_congr rfl fun k _ => ?_
  simp only [hcZ]
  push_cast
  rw [Nat.choose_symm_add]
  have h1 : ((-1 : ℝ) ^ k) * ((-1 : ℝ) ^ k) = 1 := by rw [← mul_pow]; norm_num
  linear_combination (2 * (n.choose k : ℝ) ^ 2 * ((n + k).choose k : ℝ) ^ 2 *
    (lcmUpTo n : ℝ) ^ 3) * h1


theorem z3_step1 {x y : ℝ} (hx : x ∈ Ioo (0 : ℝ) 1) (hy : y ∈ Ioo (0 : ℝ) 1) :
    ∫ z in (0 : ℝ)..1, 1 / (1 - (1 - x * y) * z) = -Real.log (x * y) / (1 - x * y) := by
  set a := 1 - x * y with ha
  have hxy0 : 0 < x * y := mul_pos hx.1 hy.1
  have hxy1 : x * y < 1 := by nlinarith [hx.1, hx.2, hy.1, hy.2]
  have ha0 : 0 < a := by linarith
  have hpos : ∀ z ∈ uIcc (0 : ℝ) 1, 0 < 1 - a * z := by
    intro z hz
    rw [uIcc_of_le zero_le_one] at hz
    nlinarith [hz.1, hz.2]
  have hderiv : ∀ z ∈ uIcc (0 : ℝ) 1,
      HasDerivAt (fun z => -Real.log (1 - a * z) / a) (1 / (1 - a * z)) z := by
    intro z hz
    have h1 : HasDerivAt (fun z => 1 - a * z) (-a) z := by
      simpa using ((hasDerivAt_id z).const_mul a).const_sub 1
    have h2 := ((h1.log (hpos z hz).ne').neg).div_const a
    convert h2 using 1
    field_simp
  have hcont : ContinuousOn (fun z => 1 / (1 - a * z)) (uIcc (0 : ℝ) 1) :=
    continuousOn_const.div (by fun_prop) fun z hz => (hpos z hz).ne'
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hcont.intervalIntegrable]
  simp only [mul_one, mul_zero, sub_zero, Real.log_one, neg_zero, zero_div]
  rw [ha, show 1 - (1 - x * y) = x * y by ring]

theorem z3_subst (n : ℕ) {b : ℝ} (hb0 : 0 < b) (hb1 : b < 1) :
    ∫ z in (0 : ℝ)..1, (b * z) ^ n / (1 - (1 - b) * z) ^ (n + 1) =
      ∫ w in (0 : ℝ)..1, (1 - w) ^ n / (1 - (1 - b) * w) := by
  set a := 1 - b with ha
  have hpos : ∀ w ∈ Icc (0 : ℝ) 1, 0 < 1 - a * w := by
    intro w hw; nlinarith [hw.1, hw.2]
  have hpos' : ∀ w ∈ uIcc (0 : ℝ) 1, 0 < 1 - a * w := by
    rw [uIcc_of_le zero_le_one]; exact hpos
  set f : ℝ → ℝ := fun w => (1 - w) / (1 - a * w) with hf
  set f' : ℝ → ℝ := fun w => -b / (1 - a * w) ^ 2 with hf'
  set g : ℝ → ℝ := fun z => (b * z) ^ n / (1 - a * z) ^ (n + 1) with hg
  have hder : ∀ w ∈ uIcc (0 : ℝ) 1, HasDerivAt f (f' w) w := by
    intro w hw
    have hw0 := (hpos' w hw).ne'
    have h1 : HasDerivAt (fun w => 1 - w) (-1) w := by
      simpa using (hasDerivAt_id w).const_sub 1
    have h2 : HasDerivAt (fun w => 1 - a * w) (-a) w := by
      simpa using ((hasDerivAt_id w).const_mul a).const_sub 1
    convert h1.div h2 hw0 using 1
    simp only [hf', ha]
    field_simp
    ring
  have hf'c : ContinuousOn f' (uIcc (0 : ℝ) 1) :=
    continuousOn_const.div (by fun_prop) fun w hw => pow_ne_zero _ (hpos' w hw).ne'
  have himg : f '' uIcc (0 : ℝ) 1 ⊆ Icc 0 1 := by
    rintro _ ⟨w, hw, rfl⟩
    rw [uIcc_of_le zero_le_one] at hw
    have hp := hpos w hw
    simp only [hf, mem_Icc]
    constructor
    · exact div_nonneg (by linarith [hw.2]) hp.le
    · rw [div_le_one hp]; nlinarith [hw.1, hw.2]
  have hgc : ContinuousOn g (f '' uIcc (0 : ℝ) 1) := by
    refine ContinuousOn.mono ?_ himg
    exact (by fun_prop : Continuous fun z : ℝ => (b * z) ^ n).continuousOn.div (by fun_prop)
      fun z hz => pow_ne_zero _ (hpos z hz).ne'
  have hcov := intervalIntegral.integral_comp_mul_deriv' hder hf'c hgc
  have hf0 : f 0 = 1 := by simp [hf]
  have hf1 : f 1 = 0 := by simp [hf]
  rw [hf0, hf1, intervalIntegral.integral_symm (f := g) 0 1] at hcov
  have hcongr : ∫ w in (0 : ℝ)..1, (g ∘ f) w * f' w =
      ∫ w in (0 : ℝ)..1, -((1 - w) ^ n / (1 - a * w)) := by
    refine intervalIntegral.integral_congr fun w hw => ?_
    have hp := hpos' w hw
    have hp0 := hp.ne'
    have hb' : b = 1 - a := by rw [ha]; ring
    simp only [Function.comp, hf, hg, hf']
    have e1 : 1 - a * ((1 - w) / (1 - a * w)) = b / (1 - a * w) := by
      field_simp; rw [hb']; ring
    rw [e1]
    have hbne : b ≠ 0 := hb0.ne'
    generalize 1 - a * w = D at hp0 ⊢
    have hDn : D ^ n ≠ 0 := pow_ne_zero _ hp0
    have hbn : b ^ n ≠ 0 := pow_ne_zero _ hbne
    simp only [div_pow, mul_pow, pow_succ]
    field_simp
  rw [hcongr, intervalIntegral.integral_neg] at hcov
  linarith

theorem z3_vanish (n m : ℕ) (hm : m < n) :
    aeval (0 : ℝ) (derivative^[m] ((X : ℤ[X]) ^ n * (1 - X) ^ n)) = 0 ∧
    aeval (1 : ℝ) (derivative^[m] ((X : ℤ[X]) ^ n * (1 - X) ^ n)) = 0 := by
  constructor
  · obtain ⟨r, hr⟩ := pow_sub_dvd_iterate_derivative_of_pow_dvd (p := (X : ℤ[X]) ^ n * (1 - X) ^ n)
      (q := X) (n := n) m (dvd_mul_right _ _)
    rw [hr, map_mul, map_pow, aeval_X, zero_pow (by omega), zero_mul]
  · have hd : ((X : ℤ[X]) - 1) ^ n ∣ (X : ℤ[X]) ^ n * (1 - X) ^ n :=
      Dvd.dvd.mul_left (pow_dvd_pow_of_dvd ⟨-1, by ring⟩ n) _
    obtain ⟨r, hr⟩ := pow_sub_dvd_iterate_derivative_of_pow_dvd m hd
    rw [hr, map_mul, map_pow, map_sub, aeval_X, map_one, sub_self, zero_pow (by omega), zero_mul]

theorem z3_gderiv (k : ℕ) {α β t : ℝ} (h : α + β * t ≠ 0) :
    HasDerivAt (fun t => (k ! : ℝ) * β ^ k / (α + β * t) ^ (k + 1))
      (-((((k + 1) ! : ℕ) : ℝ) * β ^ (k + 1) / (α + β * t) ^ (k + 1 + 1))) t := by
  have h1 : HasDerivAt (fun t => α + β * t) β t := by
    simpa using ((hasDerivAt_id t).const_mul β).const_add α
  have h2 := (h1.pow (k + 1)).inv (pow_ne_zero _ h)
  have h3 := h2.const_mul ((k ! : ℝ) * β ^ k)
  convert h3 using 1
  · ext s; simp [div_eq_mul_inv]
  · simp only [Pi.pow_apply, Nat.add_sub_cancel]
    push_cast [Nat.factorial_succ]
    field_simp
    ring

theorem z3_ibp (n : ℕ) {α β : ℝ} (hα : 0 < α) (hβ : 0 ≤ β) :
    ∫ t in (0 : ℝ)..1, aeval t (shiftedLegendre n) * (1 / (α + β * t)) =
      ∫ t in (0 : ℝ)..1, β ^ n * (t ^ n * (1 - t) ^ n) / (α + β * t) ^ (n + 1) := by
  set U : ℤ[X] := (X : ℤ[X]) ^ n * (1 - X) ^ n with hU
  set g : ℕ → ℝ → ℝ := fun k t => (k ! : ℝ) * β ^ k / (α + β * t) ^ (k + 1) with hg
  have hpos : ∀ t ∈ uIcc (0 : ℝ) 1, 0 < α + β * t := by
    intro t ht; rw [uIcc_of_le zero_le_one] at ht
    have := mul_nonneg hβ ht.1; linarith
  have hgc : ∀ k, ContinuousOn (g k) (uIcc (0 : ℝ) 1) := fun k =>
    continuousOn_const.div (by fun_prop) fun t ht => pow_ne_zero _ (hpos t ht).ne'
  have claim : ∀ k ≤ n, ∫ t in (0 : ℝ)..1, aeval t (derivative^[n] U) * g 0 t =
      ∫ t in (0 : ℝ)..1, aeval t (derivative^[n - k] U) * g k t := by
    intro k
    induction k with
    | zero => intro _; rfl
    | succ k ih =>
      intro hk
      rw [ih (by omega)]
      obtain ⟨m, hm⟩ : ∃ m, n - k = m + 1 := ⟨n - k - 1, by omega⟩
      have hm' : n - (k + 1) = m := by omega
      rw [hm, hm', Function.iterate_succ_apply']
      have hv := z3_vanish n m (by omega)
      rw [← hU] at hv
      have ibp := intervalIntegral.integral_mul_deriv_eq_deriv_mul
        (u := fun t => aeval t (derivative^[m] U))
        (u' := fun t => aeval t (derivative (derivative^[m] U)))
        (v := g k) (v' := fun t => -g (k + 1) t)
        (fun t _ => Polynomial.hasDerivAt_aeval _ t)
        (fun t ht => by simpa [hg] using z3_gderiv k (hpos t ht).ne')
        ((Polynomial.continuous_aeval _).intervalIntegrable 0 1)
        ((hgc (k + 1)).neg.intervalIntegrable)
      simp only [hv.1, hv.2, zero_mul, sub_zero, mul_neg, intervalIntegral.integral_neg] at ibp
      linarith
  have hfin := claim n le_rfl
  rw [Nat.sub_self, Function.iterate_zero, id] at hfin
  have hrod : ∀ t : ℝ, aeval t (derivative^[n] U) = (n ! : ℝ) * aeval t (shiftedLegendre n) := by
    intro t
    rw [hU, ← factorial_mul_shiftedLegendre_eq, map_mul]
    simp
  simp only [hrod, hg] at hfin
  have hn : (n ! : ℝ) ≠ 0 := by positivity
  have e1 : ∫ t in (0 : ℝ)..1, aeval t (shiftedLegendre n) * (1 / (α + β * t)) =
      (1 / (n ! : ℝ)) * ∫ t in (0 : ℝ)..1, (n ! : ℝ) * aeval t (shiftedLegendre n) *
        ((0 ! : ℝ) * β ^ 0 / (α + β * t) ^ (0 + 1)) := by
    rw [← intervalIntegral.integral_const_mul]
    refine intervalIntegral.integral_congr fun t _ => ?_
    simp only [Nat.factorial_zero, Nat.cast_one, pow_zero, zero_add, pow_one]
    field_simp
  rw [e1, hfin, ← intervalIntegral.integral_const_mul]
  refine intervalIntegral.integral_congr fun t _ => ?_
  simp only [hU, map_mul, map_pow, map_sub, aeval_X, map_one]
  field_simp

theorem z3_bound {x y w : ℝ} (hx : x ∈ Ioo (0 : ℝ) 1) (hy : y ∈ Ioo (0 : ℝ) 1)
    (hw : w ∈ Ioo (0 : ℝ) 1) :
    x * (1 - x) * (y * (1 - y)) * (w * (1 - w)) ≤ (Real.sqrt 2 - 1) ^ 4 * (1 - (1 - x * y) * w) := by
  obtain ⟨hx0, hx1⟩ := hx
  obtain ⟨hy0, hy1⟩ := hy
  obtain ⟨hw0, hw1⟩ := hw
  set s := Real.sqrt x
  set u := Real.sqrt y
  set r := Real.sqrt 2
  have hs : s ^ 2 = x := Real.sq_sqrt hx0.le
  have hu : u ^ 2 = y := Real.sq_sqrt hy0.le
  have hr : r ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hu0 : 0 ≤ u := Real.sqrt_nonneg _
  set t := s * u
  have ht0 : 0 ≤ t := mul_nonneg hs0 hu0
  have ht2 : t ^ 2 = x * y := by rw [mul_pow, hs, hu]
  have ht1 : t ≤ 1 := by nlinarith [mul_pos hx0 hy0]
  have h1 : (1 - x) * (1 - y) ≤ (1 - t) ^ 2 := by
    rw [← hs, ← hu]; nlinarith [sq_nonneg (s - u)]
  have h2 : (1 + t) ^ 2 * (w * (1 - w)) ≤ 1 - w + t ^ 2 * w := by
    nlinarith [sq_nonneg (1 - (1 + t) * w)]
  have h3 : t * (1 - t) ≤ (3 - 2 * r) * (1 + t) := by
    nlinarith [sq_nonneg (t - (r - 1))]
  have hq : (r - 1) ^ 4 = (3 - 2 * r) ^ 2 := by
    have : (r - 1) ^ 2 = 3 - 2 * r := by nlinarith
    rw [show (r - 1) ^ 4 = ((r - 1) ^ 2) ^ 2 by ring, this]
  have hD : 1 - (1 - x * y) * w = 1 - w + t ^ 2 * w := by rw [ht2]; ring
  have hww : 0 ≤ w * (1 - w) := mul_nonneg hw0.le (by linarith)
  have htt : 0 ≤ t * (1 - t) := mul_nonneg ht0 (by linarith)
  have h3' : (t * (1 - t)) ^ 2 ≤ ((3 - 2 * r) * (1 + t)) ^ 2 := pow_le_pow_left₀ htt h3 2
  have step1 : x * (1 - x) * (y * (1 - y)) * (w * (1 - w)) ≤ t ^ 2 * (1 - t) ^ 2 * (w * (1 - w)) := by
    have : x * (1 - x) * (y * (1 - y)) * (w * (1 - w)) =
        t ^ 2 * ((1 - x) * (1 - y)) * (w * (1 - w)) := by rw [ht2]; ring
    rw [this]
    gcongr
  have step2 : (1 + t) ^ 2 * (t ^ 2 * (1 - t) ^ 2 * (w * (1 - w))) ≤
      (1 + t) ^ 2 * ((3 - 2 * r) ^ 2 * (1 - w + t ^ 2 * w)) := by
    calc (1 + t) ^ 2 * (t ^ 2 * (1 - t) ^ 2 * (w * (1 - w)))
        = (t * (1 - t)) ^ 2 * ((1 + t) ^ 2 * (w * (1 - w))) := by ring
      _ ≤ (t * (1 - t)) ^ 2 * (1 - w + t ^ 2 * w) := by gcongr
      _ ≤ ((3 - 2 * r) * (1 + t)) ^ 2 * (1 - w + t ^ 2 * w) := by
          gcongr
      _ = (1 + t) ^ 2 * ((3 - 2 * r) ^ 2 * (1 - w + t ^ 2 * w)) := by ring
  have step3 := le_of_mul_le_mul_left step2 (by positivity)
  rw [hq, hD]
  linarith


theorem z3_ae_cube :
    ∀ᵐ p ∂((volume.restrict (Ioo (0 : ℝ) 1)).prod
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))),
      p.1 ∈ Ioo (0 : ℝ) 1 ∧ p.2.1 ∈ Ioo (0 : ℝ) 1 ∧ p.2.2 ∈ Ioo (0 : ℝ) 1 := by
  rw [Measure.prod_restrict, Measure.prod_restrict]
  filter_upwards [ae_restrict_mem (measurableSet_Ioo.prod (measurableSet_Ioo.prod measurableSet_Ioo))]
    with p hp
  exact ⟨hp.1, hp.2.1, hp.2.2⟩

theorem z3_K3_le {x y z : ℝ} (hx : x ∈ Ioo (0 : ℝ) 1) (hy : y ∈ Ioo (0 : ℝ) 1)
    (hz : z ∈ Ioo (0 : ℝ) 1) :
    1 / (1 - (1 - x * y) * z) ≤ 2 + (Real.sqrt x)⁻¹ * ((Real.sqrt y)⁻¹ * (Real.sqrt (1 - z))⁻¹) := by
  obtain ⟨hx0, hx1⟩ := hx
  obtain ⟨hy0, hy1⟩ := hy
  obtain ⟨hz0, hz1⟩ := hz
  have hxy : 0 < x * y := mul_pos hx0 hy0
  have hxy1 : x * y < 1 := by nlinarith
  have hD : 0 < 1 - (1 - x * y) * z := by nlinarith
  have hprod : 0 ≤ (Real.sqrt x)⁻¹ * ((Real.sqrt y)⁻¹ * (Real.sqrt (1 - z))⁻¹) := by positivity
  rcases le_or_gt z (1 / 2) with hz2 | hz2
  · have : 1 / (1 - (1 - x * y) * z) ≤ 2 := by
      rw [div_le_iff₀ hD]; nlinarith
    linarith
  · set a := Real.sqrt x * Real.sqrt y
    set b := Real.sqrt (1 - z)
    have ha : a ^ 2 = x * y := by
      rw [mul_pow, Real.sq_sqrt hx0.le, Real.sq_sqrt hy0.le]
    have hb : b ^ 2 = 1 - z := Real.sq_sqrt (by linarith)
    have ha0 : 0 < a := mul_pos (Real.sqrt_pos.2 hx0) (Real.sqrt_pos.2 hy0)
    have hb0 : 0 < b := Real.sqrt_pos.2 (by linarith)
    have hab : a * b ≤ 1 - (1 - x * y) * z := by
      nlinarith [sq_nonneg (b - a / 2), sq_nonneg a]
    have e : (Real.sqrt x)⁻¹ * ((Real.sqrt y)⁻¹ * (Real.sqrt (1 - z))⁻¹) = 1 / (a * b) := by
      simp only [a, b]; field_simp
    rw [e]
    have : 1 / (1 - (1 - x * y) * z) ≤ 1 / (a * b) :=
      one_div_le_one_div_of_le (by positivity) hab
    linarith

theorem z3_int_isqrt :
    Integrable (fun x : ℝ => (Real.sqrt x)⁻¹) (volume.restrict (Ioo (0 : ℝ) 1)) := by
  have h := (intervalIntegral.integrableOn_Ioo_rpow_iff (s := -(1 / 2 : ℝ)) zero_lt_one).2 (by norm_num)
  refine h.congr_fun (fun x hx => ?_) measurableSet_Ioo
  simp only
  rw [Real.sqrt_eq_rpow, Real.rpow_neg hx.1.le]

theorem z3_int_isqrt' :
    Integrable (fun x : ℝ => (Real.sqrt (1 - x))⁻¹) (volume.restrict (Ioo (0 : ℝ) 1)) := by
  have h : IntervalIntegrable (fun x : ℝ => (Real.sqrt x)⁻¹) volume 0 1 :=
    (intervalIntegrable_iff_integrableOn_Ioo_of_le zero_le_one).2 z3_int_isqrt
  have h2 := h.comp_sub_left 1
  simp only [sub_zero, sub_self] at h2
  exact (intervalIntegrable_iff_integrableOn_Ioo_of_le zero_le_one).1 h2.symm

theorem z3_K3_int :
    Integrable (fun p : ℝ × ℝ × ℝ => 1 / (1 - (1 - p.1 * p.2.1) * p.2.2))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
  have hg : Integrable (fun p : ℝ × ℝ × ℝ =>
      2 + (Real.sqrt p.1)⁻¹ * ((Real.sqrt p.2.1)⁻¹ * (Real.sqrt (1 - p.2.2))⁻¹))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) :=
    (integrable_const _).add (z3_int_isqrt.mul_prod (z3_int_isqrt.mul_prod z3_int_isqrt'))
  refine hg.mono' (Measurable.aestronglyMeasurable (by fun_prop)) ?_
  filter_upwards [z3_ae_cube] with p hp
  have hD : 0 < 1 - (1 - p.1 * p.2.1) * p.2.2 := by
    obtain ⟨⟨a0, a1⟩, ⟨b0, b1⟩, ⟨c0, c1⟩⟩ := hp
    have : p.1 * p.2.1 < 1 := by nlinarith
    nlinarith [mul_pos a0 b0]
  rw [Real.norm_of_nonneg (by positivity)]
  exact z3_K3_le hp.1 hp.2.1 hp.2.2

theorem z3_int01 (g : ℝ → ℝ) :
    ∫ x in (0 : ℝ)..1, g x = ∫ x, g x ∂(volume.restrict (Ioo (0 : ℝ) 1)) := by
  rw [intervalIntegral.integral_of_le zero_le_one, integral_Ioc_eq_integral_Ioo]

theorem z3_fub (f : ℝ → ℝ → ℝ → ℝ)
    (hf : Integrable (fun p : ℝ × ℝ × ℝ => f p.1 p.2.1 p.2.2)
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1))))) :
    ∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1, ∫ z in (0 : ℝ)..1, f x y z =
      ∫ p, f p.1 p.2.1 p.2.2 ∂((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
  simp only [z3_int01]
  rw [integral_prod _ hf]
  refine integral_congr_ae ?_
  filter_upwards [hf.prod_right_ae] with x hx
  exact (integral_prod _ hx).symm

theorem z3_mp_swap :
    MeasurePreserving (MeasurableEquiv.prodCongr (MeasurableEquiv.refl ℝ) MeasurableEquiv.prodComm)
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1))))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) :=
  (MeasurePreserving.id _).prod Measure.measurePreserving_swap

theorem z3_mp_rot :
    MeasurePreserving
      ((MeasurableEquiv.prodAssoc (α := ℝ) (β := ℝ) (γ := ℝ)).symm.trans MeasurableEquiv.prodComm)
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1))))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) :=
  Measure.measurePreserving_swap.comp (measurePreserving_prodAssoc _ _ _).symm

/-- swapping the last two variables of an iterated integral -/
theorem z3_swap (f : ℝ → ℝ → ℝ → ℝ)
    (hf : Integrable (fun p : ℝ × ℝ × ℝ => f p.1 p.2.1 p.2.2)
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1))))) :
    ∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1, ∫ z in (0 : ℝ)..1, f x y z =
      ∫ x in (0 : ℝ)..1, ∫ z in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1, f x y z := by
  have hf' := z3_mp_swap.integrable_comp_of_integrable hf
  rw [z3_fub f hf, z3_fub (fun x z y => f x y z) hf', ← z3_mp_swap.integral_comp']
  rfl

/-- moving the first variable of an iterated integral innermost -/
theorem z3_rot (f : ℝ → ℝ → ℝ → ℝ)
    (hf : Integrable (fun p : ℝ × ℝ × ℝ => f p.1 p.2.1 p.2.2)
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1))))) :
    ∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1, ∫ z in (0 : ℝ)..1, f x y z =
      ∫ y in (0 : ℝ)..1, ∫ z in (0 : ℝ)..1, ∫ x in (0 : ℝ)..1, f x y z := by
  have hf' := z3_mp_rot.integrable_comp_of_integrable hf
  rw [z3_fub f hf, z3_fub (fun y z x => f x y z) hf', ← z3_mp_rot.integral_comp']
  rfl

theorem z3_dom {f : ℝ × ℝ × ℝ → ℝ}
    (hf : AEStronglyMeasurable f ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))))
    (C : ℝ) (h : ∀ x y z : ℝ, x ∈ Ioo (0 : ℝ) 1 → y ∈ Ioo (0 : ℝ) 1 → z ∈ Ioo (0 : ℝ) 1 →
      |f (x, (y, z))| ≤ C * (1 / (1 - (1 - x * y) * z))) :
    Integrable f ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
  refine (z3_K3_int.const_mul C).mono' hf ?_
  filter_upwards [z3_ae_cube] with p hp
  rw [Real.norm_eq_abs]
  exact h p.1 p.2.1 p.2.2 hp.1 hp.2.1 hp.2.2

theorem z3_D_pos {x y z : ℝ} (hx : x ∈ Ioo (0 : ℝ) 1) (hy : y ∈ Ioo (0 : ℝ) 1)
    (hz : z ∈ Ioo (0 : ℝ) 1) : x * y * z < 1 - (1 - x * y) * z := by
  nlinarith [hz.2]

theorem z3_pow_ratio_le (n : ℕ) {x y z : ℝ} (hx : x ∈ Ioo (0 : ℝ) 1) (hy : y ∈ Ioo (0 : ℝ) 1)
    (hz : z ∈ Ioo (0 : ℝ) 1) :
    (x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1) ≤ 1 / (1 - (1 - x * y) * z) := by
  have h0 : 0 < x * y * z := mul_pos (mul_pos hx.1 hy.1) hz.1
  have hD := z3_D_pos hx hy hz
  have hD0 : 0 < 1 - (1 - x * y) * z := h0.trans hD
  rw [pow_succ, ← div_div]
  apply div_le_div_of_nonneg_right _ hD0.le
  rw [div_le_one (pow_pos hD0 n)]
  exact pow_le_pow_left₀ h0.le hD.le n

theorem z3_one_sub_pow {y : ℝ} (n : ℕ) (hy : y ∈ Ioo (0 : ℝ) 1) : 0 ≤ (1 - y) ^ n ∧ (1 - y) ^ n ≤ 1 :=
  ⟨pow_nonneg (by linarith [hy.2]) n, pow_le_one₀ (by linarith [hy.2]) (by linarith [hy.1])⟩

theorem z3_F_int (n : ℕ) : Integrable (fun p : ℝ × ℝ × ℝ => (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n *
      (1 - p.2.1) ^ n * (1 - p.2.2) ^ n / (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
  have hKpos : ∀ x y z : ℝ, x ∈ Ioo (0 : ℝ) 1 → y ∈ Ioo (0 : ℝ) 1 → z ∈ Ioo (0 : ℝ) 1 →
      0 < 1 - (1 - x * y) * z := fun x y z hx hy hz =>
    (mul_pos (mul_pos hx.1 hy.1) hz.1).trans (z3_D_pos hx hy hz)
  refine z3_dom (Measurable.aestronglyMeasurable (by fun_prop)) 1 fun x y z hx hy hz => ?_
  have hK := hKpos x y z hx hy hz
  have hR := z3_pow_ratio_le n hx hy hz
  obtain ⟨hx0, hx1⟩ := z3_one_sub_pow n hx
  obtain ⟨hy0, hy1⟩ := z3_one_sub_pow n hy
  obtain ⟨hz0, hz1⟩ := z3_one_sub_pow n hz
  have e : (x * y * z) ^ n * (1 - x) ^ n * (1 - y) ^ n * (1 - z) ^ n /
      (1 - (1 - x * y) * z) ^ (n + 1) = ((x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1)) *
        ((1 - x) ^ n * (1 - y) ^ n * (1 - z) ^ n) := by ring
  have hR0 : 0 ≤ (x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1) :=
    div_nonneg (pow_nonneg (mul_pos (mul_pos hx.1 hy.1) hz.1).le n) (pow_pos hK _).le
  rw [e, abs_of_nonneg (by positivity), one_mul]
  calc (x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1) * ((1 - x) ^ n * (1 - y) ^ n * (1 - z) ^ n)
      ≤ (1 / (1 - (1 - x * y) * z)) * (1 * 1 * 1) := by gcongr
    _ = _ := by ring

open Polynomial in
theorem z3_chain (n : ℕ) :
    (∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1,
      -Real.log (x * y) / (1 - x * y) * aeval x (shiftedLegendre n) * aeval y (shiftedLegendre n)) =
    ∫ p, (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n * (1 - p.2.1) ^ n * (1 - p.2.2) ^ n /
        (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1)
      ∂((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
  set P : ℝ → ℝ := fun t => aeval t (shiftedLegendre n) with hP
  have hPc : Continuous P := Polynomial.continuous_aeval _
  have hPm : Measurable P := hPc.measurable
  obtain ⟨M, hM⟩ := (isCompact_Icc (a := (0 : ℝ)) (b := 1)).exists_bound_of_continuousOn
    hPc.continuousOn
  have hM' : ∀ x ∈ Ioo (0 : ℝ) 1, |P x| ≤ M := fun x hx => by
    simpa [Real.norm_eq_abs] using hM x (Ioo_subset_Icc_self hx)
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM' (1 / 2) ⟨by norm_num, by norm_num⟩)
  -- step 0: replace the log kernel by an integral over z
  have S0 : (∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1,
      -Real.log (x * y) / (1 - x * y) * aeval x (shiftedLegendre n) * aeval y (shiftedLegendre n)) =
      ∫ x in (0 : ℝ)..1, ∫ y in (0 : ℝ)..1, ∫ z in (0 : ℝ)..1,
        P x * P y * (1 / (1 - (1 - x * y) * z)) := by
    refine z3_congr01 fun x hx => z3_congr01 fun y hy => ?_
    rw [intervalIntegral.integral_const_mul, z3_step1 hx hy]
    ring
  have hKpos : ∀ x y z : ℝ, x ∈ Ioo (0 : ℝ) 1 → y ∈ Ioo (0 : ℝ) 1 → z ∈ Ioo (0 : ℝ) 1 →
      0 < 1 - (1 - x * y) * z := fun x y z hx hy hz =>
    (mul_pos (mul_pos hx.1 hy.1) hz.1).trans (z3_D_pos hx hy hz)
  -- integrability of the four integrands
  have hΦ0 : Integrable (fun p : ℝ × ℝ × ℝ => P p.1 * P p.2.1 * (1 / (1 - (1 - p.1 * p.2.1) * p.2.2)))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
    refine z3_dom (Measurable.aestronglyMeasurable (by fun_prop)) (M * M) fun x y z hx hy hz => ?_
    have hK := hKpos x y z hx hy hz
    rw [abs_mul, abs_mul, abs_of_pos (one_div_pos.2 hK)]
    gcongr
    · exact hM' x hx
    · exact hM' y hy
  have hΦ1 : Integrable (fun p : ℝ × ℝ × ℝ => P p.1 * (1 - p.2.1) ^ n *
      ((p.1 * p.2.1 * p.2.2) ^ n / (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1)))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
    refine z3_dom (Measurable.aestronglyMeasurable (by fun_prop)) M fun x y z hx hy hz => ?_
    have hK := hKpos x y z hx hy hz
    have hR := z3_pow_ratio_le n hx hy hz
    have hR0 : 0 ≤ (x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1) :=
      div_nonneg (pow_nonneg (mul_pos (mul_pos hx.1 hy.1) hz.1).le n) (pow_pos hK _).le
    obtain ⟨hy0, hy1⟩ := z3_one_sub_pow n hy
    rw [abs_mul, abs_mul, abs_of_nonneg hy0, abs_of_nonneg hR0]
    calc |P x| * (1 - y) ^ n * ((x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1))
        ≤ M * 1 * (1 / (1 - (1 - x * y) * z)) := by
          gcongr
          exact hM' x hx
      _ = M * (1 / (1 - (1 - x * y) * z)) := by ring
  have hΦ2 : Integrable (fun p : ℝ × ℝ × ℝ => P p.1 * (1 - p.2.1) ^ n *
      ((1 - p.2.2) ^ n / (1 - (1 - p.1 * p.2.1) * p.2.2)))
      ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1)))) := by
    refine z3_dom (Measurable.aestronglyMeasurable (by fun_prop)) M fun x y z hx hy hz => ?_
    have hK := hKpos x y z hx hy hz
    obtain ⟨hy0, hy1⟩ := z3_one_sub_pow n hy
    obtain ⟨hz0, hz1⟩ := z3_one_sub_pow n hz
    rw [abs_mul, abs_mul, abs_of_nonneg hy0, abs_of_nonneg (div_nonneg hz0 hK.le)]
    calc |P x| * (1 - y) ^ n * ((1 - z) ^ n / (1 - (1 - x * y) * z))
        ≤ M * 1 * (1 / (1 - (1 - x * y) * z)) := by
          gcongr
          · exact hM' x hx
      _ = M * (1 / (1 - (1 - x * y) * z)) := by ring
  have hF := z3_F_int n
  -- step 1: swap y and z
  rw [S0, z3_swap (fun x y z => P x * P y * (1 / (1 - (1 - x * y) * z))) hΦ0]
  -- step 2: integrate by parts in y
  have S2 : ∀ x ∈ Ioo (0 : ℝ) 1, ∀ z ∈ Ioo (0 : ℝ) 1,
      ∫ y in (0 : ℝ)..1, P x * P y * (1 / (1 - (1 - x * y) * z)) =
      ∫ y in (0 : ℝ)..1, P x * (1 - y) ^ n * ((x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1)) := by
    intro x hx z hz
    have e1 : ∀ y : ℝ, P x * P y * (1 / (1 - (1 - x * y) * z)) =
        P x * (P y * (1 / ((1 - z) + (x * z) * y))) := by
      intro y; rw [show (1 : ℝ) - (1 - x * y) * z = (1 - z) + (x * z) * y by ring]; ring
    have e2 : ∀ y : ℝ, P x * (1 - y) ^ n * ((x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1)) =
        P x * ((x * z) ^ n * (y ^ n * (1 - y) ^ n) / ((1 - z) + (x * z) * y) ^ (n + 1)) := by
      intro y; rw [show (1 : ℝ) - (1 - x * y) * z = (1 - z) + (x * z) * y by ring, mul_pow, mul_pow,
        mul_pow]; ring
    simp only [e1, e2, intervalIntegral.integral_const_mul]
    rw [z3_ibp n (α := 1 - z) (β := x * z) (by linarith [hz.2])
      (mul_pos hx.1 hz.1).le]
  rw [z3_congr01 fun x hx => z3_congr01 fun z hz => S2 x hx z hz]
  -- step 3: swap back
  rw [← z3_swap (fun x y z => P x * (1 - y) ^ n *
    ((x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1))) hΦ1]
  -- step 4: substitute in z
  have S4 : ∀ x ∈ Ioo (0 : ℝ) 1, ∀ y ∈ Ioo (0 : ℝ) 1,
      ∫ z in (0 : ℝ)..1, P x * (1 - y) ^ n * ((x * y * z) ^ n / (1 - (1 - x * y) * z) ^ (n + 1)) =
      ∫ w in (0 : ℝ)..1, P x * (1 - y) ^ n * ((1 - w) ^ n / (1 - (1 - x * y) * w)) := by
    intro x hx y hy
    rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      z3_subst n (b := x * y) (mul_pos hx.1 hy.1) (by nlinarith [hx.1, hx.2, hy.1, hy.2])]
  rw [z3_congr01 fun x hx => z3_congr01 fun y hy => S4 x hx y hy]
  -- step 5: move x innermost
  rw [z3_rot (fun x y w => P x * (1 - y) ^ n * ((1 - w) ^ n / (1 - (1 - x * y) * w))) hΦ2]
  -- step 6: integrate by parts in x
  have S6 : ∀ y ∈ Ioo (0 : ℝ) 1, ∀ w ∈ Ioo (0 : ℝ) 1,
      ∫ x in (0 : ℝ)..1, P x * (1 - y) ^ n * ((1 - w) ^ n / (1 - (1 - x * y) * w)) =
      ∫ x in (0 : ℝ)..1, (x * y * w) ^ n * (1 - x) ^ n * (1 - y) ^ n * (1 - w) ^ n /
        (1 - (1 - x * y) * w) ^ (n + 1) := by
    intro y hy w hw
    have e1 : ∀ x : ℝ, P x * (1 - y) ^ n * ((1 - w) ^ n / (1 - (1 - x * y) * w)) =
        ((1 - y) ^ n * (1 - w) ^ n) * (P x * (1 / ((1 - w) + (y * w) * x))) := by
      intro x; rw [show (1 : ℝ) - (1 - x * y) * w = (1 - w) + (y * w) * x by ring]; ring
    have e2 : ∀ x : ℝ, (x * y * w) ^ n * (1 - x) ^ n * (1 - y) ^ n * (1 - w) ^ n /
        (1 - (1 - x * y) * w) ^ (n + 1) = ((1 - y) ^ n * (1 - w) ^ n) *
        ((y * w) ^ n * (x ^ n * (1 - x) ^ n) / ((1 - w) + (y * w) * x) ^ (n + 1)) := by
      intro x; rw [show (1 : ℝ) - (1 - x * y) * w = (1 - w) + (y * w) * x by ring, mul_pow, mul_pow,
        mul_pow]; ring
    simp only [e1, e2, intervalIntegral.integral_const_mul]
    rw [z3_ibp n (α := 1 - w) (β := y * w) (by linarith [hw.2]) (mul_pos hy.1 hw.1).le]
  rw [z3_congr01 fun y hy => z3_congr01 fun w hw => S6 y hy w hw]
  -- step 7: back to a single integral over the cube
  rw [← z3_rot (fun x y w => (x * y * w) ^ n * (1 - x) ^ n * (1 - y) ^ n * (1 - w) ^ n /
    (1 - (1 - x * y) * w) ^ (n + 1)) hF]
  exact z3_fub _ hF

theorem z3_beukers_zero : beukersIntegral 0 = 2 * (riemannZeta 3).re := by
  unfold beukersIntegral
  rw [z3_expand 0, z3_zeta_re]
  simp only [zero_add, Finset.range_one, Finset.sum_singleton, pow_zero, Nat.choose_self,
    Nat.cast_one, mul_one, Int.cast_one, one_mul]
  rw [z3_sigma_diag 0]
  simp

theorem z3_thm3 (n : ℕ) :
    0 < beukersIntegral n ∧
      beukersIntegral n ≤ 2 * (riemannZeta 3).re * (Real.sqrt 2 - 1) ^ (4 * n) := by
  have hc := z3_chain n
  have hc0 := z3_chain 0
  have hz := z3_beukers_zero
  unfold beukersIntegral at hz
  rw [hc0] at hz
  simp only [pow_zero, one_mul, zero_add, pow_one] at hz
  -- hz : ∫ K = 2 ζ(3)
  unfold beukersIntegral
  rw [hc]
  set ν := ((volume.restrict (Ioo (0 : ℝ) 1)).prod
        ((volume.restrict (Ioo (0 : ℝ) 1)).prod (volume.restrict (Ioo (0 : ℝ) 1))))
  have hF := z3_F_int n
  have hpos : ∀ p : ℝ × ℝ × ℝ, (p.1 ∈ Ioo (0 : ℝ) 1 ∧ p.2.1 ∈ Ioo (0 : ℝ) 1 ∧ p.2.2 ∈ Ioo (0 : ℝ) 1) →
      0 < (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n * (1 - p.2.1) ^ n * (1 - p.2.2) ^ n /
        (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1) := by
    rintro ⟨x, y, w⟩ ⟨hx, hy, hw⟩
    have hD := (mul_pos (mul_pos hx.1 hy.1) hw.1).trans (z3_D_pos hx hy hw)
    have := hx.2; have := hy.2; have := hw.2
    have : 0 < 1 - x := by linarith
    have : 0 < 1 - y := by linarith
    have : 0 < 1 - w := by linarith
    have := hx.1; have := hy.1; have := hw.1
    positivity
  constructor
  · rw [integral_pos_iff_support_of_nonneg_ae _ hF]
    · have hae : ∀ᵐ p ∂ν, p ∈ Function.support (fun p : ℝ × ℝ × ℝ =>
          (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n * (1 - p.2.1) ^ n * (1 - p.2.2) ^ n /
            (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1)) := by
        filter_upwards [z3_ae_cube] with p hp
        exact (hpos p hp).ne'
      have h0 : ν (Function.support (fun p : ℝ × ℝ × ℝ =>
          (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n * (1 - p.2.1) ^ n * (1 - p.2.2) ^ n /
            (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1)))ᶜ = 0 := by
        exact ae_iff.1 hae
      have huniv : ν univ = 1 := by
        simp only [ν]
        rw [← Set.univ_prod_univ, Measure.prod_prod, ← Set.univ_prod_univ, Measure.prod_prod]
        simp [Real.volume_Ioo]
      have := measure_univ_le_add_compl (μ := ν) (Function.support (fun p : ℝ × ℝ × ℝ =>
          (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n * (1 - p.2.1) ^ n * (1 - p.2.2) ^ n /
            (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1)))
      rw [h0, add_zero, huniv] at this
      exact lt_of_lt_of_le zero_lt_one this
    · filter_upwards [z3_ae_cube] with p hp
      exact (hpos p hp).le
  · have hbd : ∀ᵐ p ∂ν, (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n * (1 - p.2.1) ^ n *
        (1 - p.2.2) ^ n / (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1) ≤
        ((Real.sqrt 2 - 1) ^ 4) ^ n * (1 / (1 - (1 - p.1 * p.2.1) * p.2.2)) := by
      filter_upwards [z3_ae_cube] with p hp
      obtain ⟨x, y, w⟩ := p
      obtain ⟨hx, hy, hw⟩ := hp
      simp only at hx hy hw ⊢
      have hD := (mul_pos (mul_pos hx.1 hy.1) hw.1).trans (z3_D_pos hx hy hw)
      have hb := z3_bound hx hy hw
      set D := 1 - (1 - x * y) * w
      set num := x * (1 - x) * (y * (1 - y)) * (w * (1 - w))
      have hnum0 : 0 ≤ num := by
        have := hx.2; have := hy.2; have := hw.2
        have : 0 ≤ 1 - x := by linarith
        have : 0 ≤ 1 - y := by linarith
        have : 0 ≤ 1 - w := by linarith
        have := hx.1; have := hy.1; have := hw.1
        positivity
      have hr : num / D ≤ (Real.sqrt 2 - 1) ^ 4 := by rw [div_le_iff₀ hD]; linarith
      have e : (x * y * w) ^ n * (1 - x) ^ n * (1 - y) ^ n * (1 - w) ^ n / D ^ (n + 1) =
          (num / D) ^ n * (1 / D) := by
        have hDn : D ^ n ≠ 0 := pow_ne_zero _ hD.ne'
        simp only [num, div_pow, mul_pow, pow_succ]
        field_simp
      rw [e]
      gcongr
    calc ∫ p, (p.1 * p.2.1 * p.2.2) ^ n * (1 - p.1) ^ n * (1 - p.2.1) ^ n * (1 - p.2.2) ^ n /
          (1 - (1 - p.1 * p.2.1) * p.2.2) ^ (n + 1) ∂ν
        ≤ ∫ p, ((Real.sqrt 2 - 1) ^ 4) ^ n * (1 / (1 - (1 - p.1 * p.2.1) * p.2.2)) ∂ν :=
          integral_mono_ae hF (z3_K3_int.const_mul _) hbd
      _ = ((Real.sqrt 2 - 1) ^ 4) ^ n * (2 * (riemannZeta 3).re) := by
          rw [integral_const_mul, hz]
      _ = 2 * (riemannZeta 3).re * (Real.sqrt 2 - 1) ^ (4 * n) := by
          rw [pow_mul]; ring

theorem z3_rho_lt_one : (16 / 5 : ℝ) ^ 3 * (Real.sqrt 2 - 1) ^ 4 < 1 := by
  have hs2 : (1.41413 : ℝ) < Real.sqrt 2 := by
    rw [Real.lt_sqrt (by norm_num)]; norm_num
  have hsq : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have e : (Real.sqrt 2 - 1) ^ 4 = 17 - 12 * Real.sqrt 2 := by
    have : (Real.sqrt 2 - 1) ^ 2 = 3 - 2 * Real.sqrt 2 := by nlinarith
    rw [show (Real.sqrt 2 - 1) ^ 4 = ((Real.sqrt 2 - 1) ^ 2) ^ 2 by ring, this]
    nlinarith
  rw [e]
  nlinarith

theorem z3_thm1 : ∀ q : ℚ, riemannZeta 3 ≠ (q : ℂ) := by
  intro q hq
  have hre : (riemannZeta 3).re = (q : ℝ) := by rw [hq]; simp
  obtain ⟨A, hA, hlcm⟩ := cheb_growth
  have hs1 : 1 < Real.sqrt 2 := by rw [Real.lt_sqrt (by norm_num)]; norm_num
  set ρ : ℝ := (16 / 5 : ℝ) ^ 3 * (Real.sqrt 2 - 1) ^ 4 with hρ
  have hρ0 : 0 < ρ := mul_pos (by norm_num) (pow_pos (by linarith) 4)
  have hρ1 : ρ < 1 := z3_rho_lt_one
  set N : ℝ := (q.den : ℝ) with hN
  have hN0 : 0 < N := by positivity
  set C : ℝ := N * A ^ 3 * (2 * (riemannZeta 3).re) with hC
  have key : ∀ n : ℕ, 1 ≤ C * ρ ^ n := by
    intro n
    obtain ⟨a, b, -, hab⟩ := z3_thm2 n
    obtain ⟨hI0, hI1⟩ := z3_thm3 n
    set d : ℝ := (lcmUpTo n : ℝ)
    set I := beukersIntegral n
    have hd0 : 0 ≤ d := Nat.cast_nonneg _
    have hdA : d ≤ A * (16 / 5) ^ n := hlcm n
    have hz : ((q.den * a + b * q.num : ℤ) : ℝ) = N * (d ^ 3 * I) := by
      rw [hab, hre]
      push_cast
      have hq' : (q : ℝ) = q.num / q.den := by exact_mod_cast (Rat.num_div_den q).symm
      rw [hq', hN]
      field_simp
    have hzpos : (0 : ℝ) < ((q.den * a + b * q.num : ℤ) : ℝ) := by
      rw [hz]
      have : 0 < d := Nat.cast_pos.mpr (show 0 < lcmUpTo n from Nat.lcmUpto_pos n)
      positivity
    have hz1 : (1 : ℝ) ≤ ((q.den * a + b * q.num : ℤ) : ℝ) := by
      have : (0 : ℤ) < q.den * a + b * q.num := by exact_mod_cast hzpos
      exact_mod_cast this
    have hB : 0 < 2 * (riemannZeta 3).re * (Real.sqrt 2 - 1) ^ (4 * n) := hI0.trans_le hI1
    calc (1 : ℝ) ≤ N * (d ^ 3 * I) := hz ▸ hz1
      _ ≤ N * (d ^ 3 * (2 * (riemannZeta 3).re * (Real.sqrt 2 - 1) ^ (4 * n))) := by gcongr
      _ ≤ N * ((A * (16 / 5) ^ n) ^ 3 * (2 * (riemannZeta 3).re * (Real.sqrt 2 - 1) ^ (4 * n))) := by
          gcongr
      _ = C * ρ ^ n := by
          rw [hC, hρ, pow_mul]
          generalize (Real.sqrt 2 - 1) ^ 4 = s
          generalize (16 / 5 : ℝ) = g
          ring
  have hC0 : 0 < C := by
    have := key 0
    simp at this
    linarith
  obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one (one_div_pos.2 hC0) hρ1
  have := key n
  rw [lt_div_iff₀ hC0] at hn
  linarith


#print axioms cheb_g_ineq
#print axioms cheb_div_eq
#print axioms cheb_term
#print axioms cheb_count
#print axioms cheb_dvd
#print axioms cheb_up
#print axioms cheb_down
#print axioms cheb_max
#print axioms cheb_choose_lower
#print axioms cheb_choose_15
#print axioms cheb_step
#print axioms cheb_lcm_mono
#print axioms cheb_step_real
#print axioms cheb_pow
#print axioms cheb_growth
#print axioms z3_series_integral
#print axioms z3_mom_pow
#print axioms z3_mom_log
#print axioms z3_int_powlog
#print axioms z3_summable_inner
#print axioms z3_inner
#print axioms z3_summable_outer
#print axioms z3_outer
#print axioms z3_congr01
#print axioms z3_P_eq
#print axioms z3_expand
#print axioms z3_sigma_diag
#print axioms z3_sigma_off
#print axioms z3_sigma_symm
#print axioms z3_cast_div
#print axioms z3_dvd_lcm
#print axioms z3_sigma_int
#print axioms z3_zeta_re
#print axioms z3_thm2
#print axioms z3_step1
#print axioms z3_subst
#print axioms z3_vanish
#print axioms z3_gderiv
#print axioms z3_ibp
#print axioms z3_bound
#print axioms z3_ae_cube
#print axioms z3_K3_le
#print axioms z3_int_isqrt
#print axioms z3_int_isqrt'
#print axioms z3_K3_int
#print axioms z3_int01
#print axioms z3_fub
#print axioms z3_mp_swap
#print axioms z3_mp_rot
#print axioms z3_swap
#print axioms z3_rot
#print axioms z3_dom
#print axioms z3_D_pos
#print axioms z3_pow_ratio_le
#print axioms z3_one_sub_pow
#print axioms z3_F_int
#print axioms z3_chain
#print axioms z3_beukers_zero
#print axioms z3_thm3
#print axioms z3_rho_lt_one
#print axioms z3_thm1

end Z3Helpers

/-- Apery's theorem: zeta of 3, the sum 1 + 1/8 + 1/27 + ... of one over each whole number
cubed, is irrational: no fraction p/q equals it. -/
theorem zeta_three_irrational : ∀ q : ℚ, riemannZeta 3 ≠ (q : ℂ) := by
  exact z3_thm1

/-- Steps 1 and 2: d_n^3 times Beukers' integral is a whole-number combination A_n + B_n zeta(3),
and the zeta(3) part is B_n = 2 a_n d_n^3, twice Apery's number times the cube of the lcm. -/
theorem lcm_cube_mul_beukers_integral_eq (n : ℕ) :
    ∃ A B : ℤ, B = 2 * (aperyNumber n : ℤ) * (lcmUpTo n : ℤ) ^ 3 ∧
      (lcmUpTo n : ℝ) ^ 3 * beukersIntegral n = A + B * (riemannZeta 3).re := by
  exact z3_thm2 n

/-- Steps 3 and 4: Beukers' integral is positive and at most 2 zeta(3) (sqrt 2 - 1)^(4n). -/
theorem beukers_integral_pos_and_le (n : ℕ) :
    0 < beukersIntegral n ∧
      beukersIntegral n ≤ 2 * (riemannZeta 3).re * (Real.sqrt 2 - 1) ^ (4 * n) := by
  exact z3_thm3 n

-- Apery's numbers 1, 5, 73, 1,445, 33,001.
example : (List.range 5).map aperyNumber = [1, 5, 73, 1445, 33001] := by decide

-- Apery's recurrence n^3 a_n = (34n^3 - 51n^2 + 27n - 5) a_(n-1) - (n-1)^3 a_(n-2) at n = 2, 3, 4.
example : (2 : ℤ) ^ 3 * 73 = (34 * 2 ^ 3 - 51 * 2 ^ 2 + 27 * 2 - 5) * 5 - 1 ^ 3 * 1 := by norm_num
example : (3 : ℤ) ^ 3 * 1445 = (34 * 3 ^ 3 - 51 * 3 ^ 2 + 27 * 3 - 5) * 73 - 2 ^ 3 * 5 := by norm_num
example : (4 : ℤ) ^ 3 * 33001 = (34 * 4 ^ 3 - 51 * 4 ^ 2 + 27 * 4 - 5) * 1445 - 3 ^ 3 * 73 := by
  norm_num

-- d_4 = 12 and d_12 = 27,720; and d_1, ..., d_4 = 1, 2, 6, 12 as in the table.
example : lcmUpTo 4 = 12 := by decide
example : lcmUpTo 12 = 27720 := by decide
example : (List.range' 1 4).map lcmUpTo = [1, 2, 6, 12] := by decide

-- B_n = 2 a_n d_n^3 gives the table's 10, 1,168, 624,240, 114,051,456.
example : (List.range' 1 4).map (fun n => 2 * aperyNumber n * lcmUpTo n ^ 3)
    = [10, 1168, 624240, 114051456] := by decide

-- By hand for n = 1: J(0,0) - 2J(1,0) - 2J(0,1) + 4J(1,1) = 2z - 2 - 2 + 4(2z - 2) = 10z - 12.
example : ∀ z : ℚ, 2 * z - 2 - 2 + 4 * (2 * z - 2) = 10 * z - 12 := by
  intro z; ring

-- Without d_2^3: I_2 = 1,168/8 zeta(3) - 1,404/8 = 146 zeta(3) - 351/2, and 351/2 is not whole.
example : (1168 : ℚ) / 8 = 146 ∧ (1404 : ℚ) / 8 = 351 / 2 ∧ ¬ (8 ∣ 1404) := by norm_num

-- The squeeze: (sqrt 2 - 1)^4 = 17 - 12 sqrt 2, and 27 (17 - 12 sqrt 2) < 1 because 458^2 < 2 * 324^2,
-- while Chebyshev's 4^3 = 64 fails: 64 (17 - 12 sqrt 2) > 1 because 1087^2 > 2 * 768^2.
example : 458 ^ 2 < 2 * 324 ^ 2 ∧ 1087 ^ 2 > 2 * 768 ^ 2 := by norm_num

-- d_n < 3^n for n = 1 to 12.
example : ∀ n ∈ Finset.Icc 1 12, lcmUpTo n < 3 ^ n := by decide

#print axioms zeta_three_irrational
#print axioms lcm_cube_mul_beukers_integral_eq
#print axioms beukers_integral_pos_and_le
