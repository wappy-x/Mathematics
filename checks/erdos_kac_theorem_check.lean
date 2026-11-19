-- Erdos-Kac: among the whole numbers up to x, the share whose count of distinct prime factors sits at most z widths above log log n tends to the bell curve's area Phi(z), and two whole-number facts the proof uses hold exactly.
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.Simproc.Factors
import Mathlib

open Filter Finset Real ProbabilityTheory
open scoped Topology ArithmeticFunction.omega

namespace EKHelp

open MeasureTheory
open scoped ENNReal NNReal






lemma log_factorial_eq (N : ℕ) :
    Real.log ((N.factorial : ℕ) : ℝ) =
      ∑ p ∈ Nat.primesLE N, ((N.factorial.factorization p : ℕ) : ℝ) * Real.log p := by
  rw [Real.log_nat_eq_sum_factorization]
  apply Finsupp.sum_of_support_subset
  · intro p hp
    rw [Nat.support_factorization] at hp
    have hpp := Nat.prime_of_mem_primeFactors hp
    have hdvd := Nat.dvd_of_mem_primeFactors hp
    rw [Nat.mem_primesLE]
    exact ⟨(Nat.Prime.dvd_factorial hpp).mp hdvd, hpp⟩
  · intro p _; simp

lemma log_factorial_le (N : ℕ) : Real.log ((N.factorial : ℕ) : ℝ) ≤ N * Real.log N := by
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp
  rw [← Real.log_pow]
  apply Real.log_le_log (by exact_mod_cast Nat.factorial_pos N)
  exact_mod_cast Nat.factorial_le_pow N

lemma log_factorial_ge (N : ℕ) : N * Real.log N - N ≤ Real.log ((N.factorial : ℕ) : ℝ) := by
  have h := Real.pow_div_factorial_le_exp (x := (N : ℝ)) (Nat.cast_nonneg _) N
  have hf : (0 : ℝ) < (N.factorial : ℝ) := by exact_mod_cast Nat.factorial_pos N
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp
  have hpos : (0 : ℝ) < (N : ℝ) ^ N / (N.factorial : ℝ) := by positivity
  have := Real.log_le_log hpos h
  rw [Real.log_exp, Real.log_div (by positivity) hf.ne', Real.log_pow] at this
  linarith

/-- Sum of `log n / (n (n-1))` is at most 4. -/
lemma sum_log_div_le (N : ℕ) (hN : 1 ≤ N) :
    ∑ n ∈ Icc 2 N, Real.log n / (n * (n - 1)) + Real.log N / N ≤ 4 - 2 / N := by
  induction N, hN using Nat.le_induction with
  | base => norm_num
  | succ N hN ih =>
    rw [Finset.sum_Icc_succ_top (by omega)]
    have hN' : (1 : ℝ) ≤ N := by exact_mod_cast hN
    push_cast
    have hlog : Real.log (N + 1) - Real.log N ≤ 2 / (N + 1) := by
      rw [← Real.log_div (by positivity) (by positivity)]
      have := Real.log_le_sub_one_of_pos (x := ((N:ℝ) + 1) / N) (by positivity)
      have h2 : ((N:ℝ) + 1) / N - 1 = 1 / N := by field_simp; ring
      rw [h2] at this
      have h3 : 1 / (N : ℝ) ≤ 2 / (N + 1) := by
        rw [div_le_div_iff₀ (by positivity) (by positivity)]; linarith
      linarith
    have e1 : Real.log (↑N + 1) / ((↑N + 1) * (↑N + 1 - 1)) + Real.log (↑N + 1) / (↑N + 1)
        = Real.log (N + 1) / N := by
      have hN0 : (N:ℝ) ≠ 0 := by positivity
      rw [show (N:ℝ) + 1 - 1 = N by ring]
      field_simp; ring
    have e2 : (2 : ℝ) / N - 2 / (N + 1) = 2 / (N * (N + 1)) := by field_simp; ring
    have key : Real.log (N + 1) / N - Real.log N / N ≤ 2 / N - 2 / (N + 1) := by
      rw [e2, ← sub_div, div_le_div_iff₀ (by positivity) (by positivity)]
      have := mul_le_mul_of_nonneg_right hlog (by positivity : (0:ℝ) ≤ N * (N + 1))
      calc (Real.log (↑N + 1) - Real.log ↑N) * (↑N * (↑N + 1))
          ≤ 2 / (↑N + 1) * (↑N * (↑N + 1)) := this
        _ = 2 * N := by field_simp
    linarith

lemma sum_primes_log_div_le (N : ℕ) :
    ∑ p ∈ Nat.primesLE N, Real.log p / (p * (p - 1)) ≤ 4 := by
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp [Nat.primesLE]
  have h := sum_log_div_le N hN
  have hsub : Nat.primesLE N ⊆ Icc 2 N := by
    intro p hp
    rw [Nat.mem_primesLE] at hp
    exact Finset.mem_Icc.mpr ⟨hp.2.two_le, hp.1⟩
  have hnn : ∀ n ∈ Icc 2 N, 0 ≤ Real.log n / (n * (n - 1)) := by
    intro n hn
    have : (2:ℝ) ≤ n := by exact_mod_cast (Finset.mem_Icc.mp hn).1
    apply div_nonneg (Real.log_nonneg (by linarith))
    nlinarith
  have h1 := Finset.sum_le_sum_of_subset_of_nonneg hsub (fun i hi _ => hnn i hi)
  have h2 : 0 ≤ Real.log N / N := div_nonneg (Real.log_natCast_nonneg _) (Nat.cast_nonneg _)
  have h3 : 0 ≤ (2:ℝ) / N := by positivity
  linarith

/-- Mertens' first theorem, lower bound. -/
lemma mertens1_lower (N : ℕ) (hN : 1 ≤ N) :
    Real.log N - 5 ≤ ∑ p ∈ Nat.primesLE N, Real.log p / p := by
  have hNr : (0:ℝ) < N := by exact_mod_cast hN
  have h1 := log_factorial_ge N
  rw [log_factorial_eq] at h1
  have h2 : ∑ p ∈ Nat.primesLE N, ((N.factorial.factorization p : ℕ) : ℝ) * Real.log p ≤
      ∑ p ∈ Nat.primesLE N, (N : ℝ) * (Real.log p / (p - 1)) := by
    apply Finset.sum_le_sum
    intro p hp
    have hpp := (Nat.mem_primesLE.mp hp).2
    have hp1 : (1:ℝ) < p := by exact_mod_cast hpp.one_lt
    have hv := Nat.factorization_factorial_le_div_pred hpp N
    have hv' : ((N.factorial.factorization p : ℕ) : ℝ) ≤ (N : ℝ) / (p - 1) := by
      calc ((N.factorial.factorization p : ℕ) : ℝ) ≤ ((N / (p - 1) : ℕ) : ℝ) := by exact_mod_cast hv
        _ ≤ (N : ℝ) / ((p - 1 : ℕ) : ℝ) := Nat.cast_div_le
        _ = (N : ℝ) / (p - 1) := by rw [Nat.cast_sub hpp.one_le]; simp
    have hl : 0 ≤ Real.log p := Real.log_nonneg hp1.le
    calc ((N.factorial.factorization p : ℕ) : ℝ) * Real.log p ≤ (N : ℝ) / (p - 1) * Real.log p :=
          mul_le_mul_of_nonneg_right hv' hl
      _ = (N : ℝ) * (Real.log p / (p - 1)) := by ring
  rw [← Finset.mul_sum] at h2
  have h3 : Real.log N - 1 ≤ ∑ p ∈ Nat.primesLE N, Real.log p / (p - 1) := by
    have : (N:ℝ) * (Real.log N - 1) ≤ N * ∑ p ∈ Nat.primesLE N, Real.log p / (p - 1) := by
      nlinarith
    exact le_of_mul_le_mul_left this hNr
  have h4 : ∑ p ∈ Nat.primesLE N, Real.log p / (p - 1) =
      ∑ p ∈ Nat.primesLE N, Real.log p / p + ∑ p ∈ Nat.primesLE N, Real.log p / (p * (p - 1)) := by
    rw [← Finset.sum_add_distrib]
    apply Finset.sum_congr rfl
    intro p hp
    have hpp := (Nat.mem_primesLE.mp hp).2
    have hp1 : (1:ℝ) < p := by exact_mod_cast hpp.one_lt
    have : (p:ℝ) - 1 ≠ 0 := by linarith
    have : (p:ℝ) ≠ 0 := by linarith
    field_simp
    ring
  have h5 := sum_primes_log_div_le N
  linarith

/-- Mertens' first theorem, upper bound. -/
lemma mertens1_upper (N : ℕ) (hN : 1 ≤ N) :
    ∑ p ∈ Nat.primesLE N, Real.log p / p ≤ Real.log N + 2 := by
  have hNr : (0:ℝ) < N := by exact_mod_cast hN
  have h1 := log_factorial_le N
  rw [log_factorial_eq] at h1
  have h2 : ∑ p ∈ Nat.primesLE N, ((N : ℝ) * (Real.log p / p) - Real.log p) ≤
      ∑ p ∈ Nat.primesLE N, ((N.factorial.factorization p : ℕ) : ℝ) * Real.log p := by
    apply Finset.sum_le_sum
    intro p hp
    have hpp := (Nat.mem_primesLE.mp hp).2
    have hp0 : (0:ℝ) < p := by exact_mod_cast hpp.pos
    have hl : 0 ≤ Real.log p := Real.log_nonneg (by exact_mod_cast hpp.one_lt.le)
    have hv : N / p ≤ N.factorial.factorization p := by
      rw [Nat.factorization_factorial hpp (Nat.lt_add_one (Nat.log p N))]
      rcases Nat.lt_or_ge N p with hlt | hge
      · rw [Nat.div_eq_of_lt hlt]; exact Nat.zero_le _
      · have hlog : 1 ≤ Nat.log p N := Nat.le_log_of_pow_le hpp.one_lt (by simpa using hge)
        have : (1:ℕ) ∈ Ico 1 (Nat.log p N + 1) := Finset.mem_Ico.mpr ⟨le_refl _, by omega⟩
        have := Finset.single_le_sum (f := fun i => N / p ^ i) (fun i _ => Nat.zero_le _) this
        simpa using this
    have hv' : (N:ℝ) / p - 1 ≤ ((N.factorial.factorization p : ℕ) : ℝ) := by
      have h := Nat.lt_div_mul_add (a := N) hpp.pos
      have : (N : ℝ) < (N / p : ℕ) * p + p := by exact_mod_cast h
      have : (N:ℝ) / p < (N / p : ℕ) + 1 := by
        rw [div_lt_iff₀ hp0]; linarith
      have : ((N / p : ℕ) : ℝ) ≤ ((N.factorial.factorization p : ℕ) : ℝ) := by exact_mod_cast hv
      linarith
    calc (N : ℝ) * (Real.log p / p) - Real.log p = ((N : ℝ) / p - 1) * Real.log p := by ring
      _ ≤ _ := mul_le_mul_of_nonneg_right hv' hl
  rw [Finset.sum_sub_distrib, ← Finset.mul_sum, ← Chebyshev.theta_eq_sum_primesLE_log] at h2
  have h3 := Chebyshev.theta_le_log4_mul_x (x := (N:ℝ)) hNr.le
  have h4 : Real.log 4 ≤ 2 := by
    have := Real.log_le_sub_one_of_pos (x := 2) (by norm_num)
    rw [show (4:ℝ) = 2^2 by norm_num, Real.log_pow]; push_cast; linarith
  have : (N:ℝ) * ∑ p ∈ Nat.primesLE N, Real.log p / p ≤ N * (Real.log N + 2) := by nlinarith
  exact le_of_mul_le_mul_left this hNr



lemma mertensD_step (N : ℕ) (hN : 2 ≤ N) :
    (∑ p ∈ Nat.primesLE (N + 1), (1:ℝ) / p) -
        (∑ p ∈ Nat.primesLE (N + 1), Real.log p / p) / Real.log (N + 1 : ℕ) =
      (∑ p ∈ Nat.primesLE N, (1:ℝ) / p) - (∑ p ∈ Nat.primesLE N, Real.log p / p) / Real.log N +
        (∑ p ∈ Nat.primesLE N, Real.log p / p) * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) := by
  have hb : 0 < Real.log ((N + 1 : ℕ) : ℝ) := Real.log_pos (by exact_mod_cast (by omega : 1 < N + 1))
  rw [Nat.primesLE_succ]
  split_ifs with hp
  · rw [Finset.sum_insert (Nat.notMem_primesLE N), Finset.sum_insert (Nat.notMem_primesLE N)]
    have : ((N + 1 : ℕ) : ℝ) ≠ 0 := by positivity
    field_simp
    ring
  · ring

lemma loglog_step (N : ℕ) (hN : 2 ≤ N) :
    Real.log N * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) ≤
        Real.log (Real.log (N + 1 : ℕ)) - Real.log (Real.log N) ∧
    Real.log (Real.log (N + 1 : ℕ)) - Real.log (Real.log N) -
        (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) ≤
      Real.log N * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) := by
  set a := Real.log N with ha
  set b := Real.log ((N + 1 : ℕ) : ℝ) with hb
  have ha0 : 0 < a := Real.log_pos (by exact_mod_cast (by omega : 1 < N))
  have hab : a < b := Real.log_lt_log (by positivity) (by exact_mod_cast (by omega : N < N + 1))
  have hb0 : 0 < b := by linarith
  have hba1 : b - a ≤ 1 := by
    rw [ha, hb, ← Real.log_div (by positivity) (by positivity)]
    have := Real.log_le_sub_one_of_pos (x := ((N + 1 : ℕ) : ℝ) / N) (by positivity)
    have hN1 : (1:ℝ) ≤ N := by exact_mod_cast (by omega : 1 ≤ N)
    have : ((N + 1 : ℕ) : ℝ) / N - 1 = 1 / N := by push_cast; field_simp; ring
    have : 1 / (N:ℝ) ≤ 1 := by rw [div_le_one (by positivity)]; exact hN1
    linarith
  have hlog : Real.log b - Real.log a = Real.log (b / a) := (Real.log_div hb0.ne' ha0.ne').symm
  rw [hlog]
  constructor
  · have := Real.log_le_sub_one_of_pos (x := a / b) (by positivity)
    rw [Real.log_div ha0.ne' hb0.ne'] at this
    rw [Real.log_div hb0.ne' ha0.ne']
    have e : a * (1 / a - 1 / b) = 1 - a / b := by field_simp
    rw [e]; linarith
  · have := Real.log_le_sub_one_of_pos (x := b / a) (by positivity)
    have e : a * (1 / a - 1 / b) = 1 - a / b := by field_simp
    rw [e]
    have e2 : b / a - 1 - (1 / a - 1 / b) = 1 - a / b + (b - a - 1) * (1 / a - 1 / b) := by
      field_simp; ring
    have hd : 0 ≤ 1 / a - 1 / b := by
      rw [sub_nonneg]; exact one_div_le_one_div_of_le ha0 hab.le
    have : (b - a - 1) * (1 / a - 1 / b) ≤ 0 := mul_nonpos_of_nonpos_of_nonneg (by linarith) hd
    linarith

lemma mertensD_bounds (N : ℕ) (hN : 2 ≤ N) :
    Real.log (Real.log N) - Real.log (Real.log 2) - 6 / Real.log 2 + 6 / Real.log N ≤
      (∑ p ∈ Nat.primesLE N, (1:ℝ) / p) - (∑ p ∈ Nat.primesLE N, Real.log p / p) / Real.log N ∧
    (∑ p ∈ Nat.primesLE N, (1:ℝ) / p) - (∑ p ∈ Nat.primesLE N, Real.log p / p) / Real.log N ≤
      Real.log (Real.log N) - Real.log (Real.log 2) + 2 / Real.log 2 - 2 / Real.log N := by
  induction N, hN using Nat.le_induction with
  | base =>
    have h2 : Nat.primesLE 2 = {2} := by decide
    rw [h2]
    have : Real.log 2 ≠ 0 := (Real.log_pos (by norm_num)).ne'
    simp only [Finset.sum_singleton, Nat.cast_ofNat]
    constructor
    · field_simp; ring_nf; rfl
    · field_simp; ring_nf; rfl
  | succ N hN ih =>
    have hstep := mertensD_step N hN
    push_cast at hstep ⊢
    rw [hstep]
    have hl := loglog_step N hN
    push_cast at hl
    have ha0 : 0 < Real.log N := Real.log_pos (by exact_mod_cast (by omega : 1 < N))
    have hab : Real.log N < Real.log (N + 1) :=
      Real.log_lt_log (by positivity) (by linarith)
    have hd : 0 ≤ 1 / Real.log N - 1 / Real.log (N + 1) := by
      rw [sub_nonneg]; exact one_div_le_one_div_of_le ha0 hab.le
    have hA1 := mertens1_lower N (by omega)
    have hA2 := mertens1_upper N (by omega)
    set A := ∑ p ∈ Nat.primesLE N, Real.log p / p
    set δ := 1 / Real.log N - 1 / Real.log (N + 1)
    have e1 : 6 / Real.log N = 6 / Real.log (N + 1) + 6 * δ := by simp only [δ]; ring
    have e2 : 2 / Real.log N = 2 / Real.log (N + 1) + 2 * δ := by simp only [δ]; ring
    constructor
    · have : (Real.log N - 5) * δ ≤ A * δ := mul_le_mul_of_nonneg_right hA1 hd
      nlinarith [ih.1]
    · have : A * δ ≤ (Real.log N + 2) * δ := mul_le_mul_of_nonneg_right hA2 hd
      nlinarith [ih.2]

/-- Mertens' second theorem with an explicit constant. -/
lemma mertens2 (N : ℕ) (hN : 2 ≤ N) :
    |(∑ p ∈ Nat.primesLE N, (1:ℝ) / p) - Real.log (Real.log N)| ≤ 12 := by
  obtain ⟨h1, h2⟩ := mertensD_bounds N hN
  have hA1 := mertens1_lower N (by omega)
  have hA2 := mertens1_upper N (by omega)
  have hl2 : 1 / 2 ≤ Real.log 2 := by
    have := Real.one_sub_inv_le_log_of_pos (x := 2) (by norm_num)
    linarith
  have hl2' : Real.log 2 ≤ 1 := by
    have := Real.log_le_sub_one_of_pos (x := 2) (by norm_num); linarith
  have hll2 : Real.log (Real.log 2) ≤ 0 := Real.log_nonpos (by linarith) hl2'
  have hll2' : -1 ≤ Real.log (Real.log 2) := by
    have := Real.one_sub_inv_le_log_of_pos (x := Real.log 2) (by linarith)
    have : (Real.log 2)⁻¹ ≤ 2 := by
      rw [inv_le_comm₀ (by linarith) (by norm_num)]; linarith
    linarith
  have hlN : Real.log 2 ≤ Real.log N := Real.log_le_log (by norm_num) (by exact_mod_cast hN)
  have hlN0 : 0 < Real.log N := by linarith
  have i2 : 1 / Real.log 2 ≤ 2 := by rw [div_le_iff₀ (by linarith)]; linarith
  have e1 : (∑ p ∈ Nat.primesLE N, Real.log p / p) / Real.log N ≤ 1 + 2 / Real.log N := by
    rw [div_le_iff₀ hlN0]; field_simp; linarith
  have e2 : 1 - 5 / Real.log N ≤ (∑ p ∈ Nat.primesLE N, Real.log p / p) / Real.log N := by
    rw [le_div_iff₀ hlN0]; field_simp; linarith
  have i3 : 0 ≤ 1 / Real.log N := by positivity
  rw [abs_le]
  constructor
  · have : 6 / Real.log 2 ≤ 12 := by
      have := mul_le_mul_of_nonneg_left i2 (by norm_num : (0:ℝ) ≤ 6)
      rw [show 6 / Real.log 2 = 6 * (1 / Real.log 2) by ring]; linarith
    have : 6 / Real.log N - 5 / Real.log N ≥ 0 := by
      rw [← sub_div]; positivity
    linarith
  · have : 2 / Real.log 2 ≤ 4 := by
      rw [show 2 / Real.log 2 = 2 * (1 / Real.log 2) by ring]; linarith
    linarith



section Tay
open Complex





/-- remainder of the Taylor polynomial of `exp (u I)` -/
noncomputable def tayRem (k : ℕ) (u : ℝ) : ℂ :=
  Complex.exp (u * I) - ∑ j ∈ range k, ((u : ℂ) * I) ^ j / (j.factorial : ℂ)

lemma hasDerivAt_tayRem (k : ℕ) (u : ℝ) :
    HasDerivAt (tayRem (k + 1)) (I * tayRem k u) u := by
  have h1 : HasDerivAt (fun s : ℝ => Complex.exp ((s : ℂ) * I)) (Complex.exp (u * I) * I) u := by
    have := ((hasDerivAt_id (u : ℂ)).mul_const I).cexp
    simpa using this.comp_ofReal
  have h2 : ∀ j ∈ range (k + 1), HasDerivAt (fun s : ℝ => ((s : ℂ) * I) ^ j / (j.factorial : ℂ))
      ((j : ℂ) * ((u : ℂ) * I) ^ (j - 1) * I / (j.factorial : ℂ)) u := by
    intro j _
    have := (((hasDerivAt_id (u : ℂ)).mul_const I).pow j).div_const (j.factorial : ℂ)
    simpa using this.comp_ofReal
  have h3 := h1.sub (HasDerivAt.fun_sum h2)
  unfold tayRem
  convert h3 using 1
  rw [Finset.sum_range_succ']
  simp only [Nat.factorial_succ, Nat.cast_mul, Nat.cast_succ, add_tsub_cancel_right, CharP.cast_eq_zero,
    zero_mul, zero_div, add_zero, mul_sub, Finset.mul_sum]
  congr 1
  · ring
  · apply Finset.sum_congr rfl
    intro j _
    have : (j.factorial : ℂ) ≠ 0 := by exact_mod_cast Nat.factorial_ne_zero j
    have : ((j : ℂ) + 1) ≠ 0 := by exact_mod_cast Nat.succ_ne_zero j
    field_simp

lemma tayRem_zero_at (k : ℕ) : tayRem (k + 1) 0 = 0 := by
  unfold tayRem
  rw [Finset.sum_range_succ']
  simp

lemma norm_tayRem_le (k : ℕ) (u : ℝ) : ‖tayRem k u‖ ≤ |u| ^ k / (k.factorial : ℝ) := by
  induction k generalizing u with
  | zero =>
    simp [tayRem, Complex.norm_exp_ofReal_mul_I]
  | succ k ih =>
    have key : ∀ σ : ℝ, (σ = 1 ∨ σ = -1) → ∀ s : ℝ, 0 ≤ s →
        ‖tayRem (k + 1) (σ * s)‖ ≤ s ^ (k + 1) / ((k + 1).factorial : ℝ) := by
      intro σ hσ s hs
      have hσabs : |σ| = 1 := by rcases hσ with rfl | rfl <;> simp
      have hd : ∀ t, HasDerivAt (fun t : ℝ => tayRem (k + 1) (σ * t))
          ((σ : ℂ) * (I * tayRem k (σ * t))) t := by
        intro t
        have h := (hasDerivAt_tayRem k (σ * t)).scomp t ((hasDerivAt_id t).const_mul σ)
        convert h using 1
        · rfl
        · rw [mul_one, Complex.real_smul]
      have hB : ∀ t, HasDerivAt (fun t : ℝ => t ^ (k + 1) / ((k + 1).factorial : ℝ))
          (t ^ k / (k.factorial : ℝ)) t := by
        intro t
        have := (hasDerivAt_pow (k + 1) t).div_const ((k + 1).factorial : ℝ)
        convert this using 1
        simp only [Nat.factorial_succ, Nat.cast_mul, Nat.cast_succ, add_tsub_cancel_right]
        have : (k.factorial : ℝ) ≠ 0 := by exact_mod_cast Nat.factorial_ne_zero k
        field_simp
      refine image_norm_le_of_norm_deriv_right_le_deriv_boundary
        (f := fun t : ℝ => tayRem (k + 1) (σ * t)) (a := 0) (b := s)
        (fun t _ => (hd t).continuousAt.continuousWithinAt)
        (fun t _ => (hd t).hasDerivWithinAt) ?_ hB ?_ (Set.mem_Icc.mpr ⟨hs, le_refl s⟩)
      · simp [tayRem_zero_at]
      · intro t ht
        have ht0 : 0 ≤ t := (Set.mem_Ico.mp ht).1
        have := ih (σ * t)
        rw [abs_mul, hσabs, one_mul, abs_of_nonneg ht0] at this
        simpa [hσabs, Complex.norm_real] using this
    rcases le_or_gt 0 u with hu | hu
    · have := key 1 (Or.inl rfl) u hu
      rw [one_mul] at this
      rwa [abs_of_nonneg hu]
    · have := key (-1) (Or.inr rfl) (-u) (by linarith)
      rw [neg_one_mul, neg_neg] at this
      rwa [abs_of_neg hu]



end Tay





lemma pow_sum_sub_expand {α : Type*} (P : Finset ℕ) (R : ℕ → α → Prop) [∀ p a, Decidable (R p a)]
    (c : ℕ → ℝ) (j : ℕ) (a : α) :
    (∑ p ∈ P, ((if R p a then (1:ℝ) else 0) - c p)) ^ j =
      ∑ g ∈ Fintype.piFinset (fun _ : Fin j => P), ∑ J ∈ (univ : Finset (Fin j)).powerset,
        (∏ i ∈ univ \ J, (-c (g i))) * (if ∀ q ∈ J.image g, R q a then (1:ℝ) else 0) := by
  rw [← Fin.prod_const j, ← Finset.sum_prod_piFinset]
  apply sum_congr rfl
  intro g _
  simp_rw [sub_eq_add_neg]
  rw [Finset.prod_add]
  apply sum_congr rfl
  intro J _
  rw [mul_comm, Finset.prod_boole]
  congr 2
  simp

lemma sum_mul_pow_expand {γ : Type*} (P : Finset ℕ) (c : ℕ → ℝ) (j : ℕ) (C : Finset γ)
    (w : γ → ℝ) (R : ℕ → γ → Prop) [∀ p a, Decidable (R p a)] :
    ∑ a ∈ C, w a * (∑ p ∈ P, ((if R p a then (1:ℝ) else 0) - c p)) ^ j =
      ∑ g ∈ Fintype.piFinset (fun _ : Fin j => P), ∑ J ∈ (univ : Finset (Fin j)).powerset,
        (∏ i ∈ univ \ J, (-c (g i))) *
          ∑ a ∈ C, w a * (if ∀ q ∈ J.image g, R q a then (1:ℝ) else 0) := by
  simp_rw [pow_sum_sub_expand, Finset.mul_sum]
  rw [Finset.sum_comm]
  apply sum_congr rfl
  intro g _
  rw [Finset.sum_comm]
  apply sum_congr rfl
  intro J _
  apply sum_congr rfl
  intro a _
  ring

lemma moment_compare {α β : Type*} (P : Finset ℕ) (A : Finset α) (B : Finset β)
    (w1 : α → ℝ) (w2 : β → ℝ) (R1 : ℕ → α → Prop) (R2 : ℕ → β → Prop)
    [∀ p a, Decidable (R1 p a)] [∀ p b, Decidable (R2 p b)] (c : ℕ → ℝ)
    (hc : ∀ p ∈ P, |c p| ≤ 1) (δ : ℝ)
    (hδ : ∀ Q ⊆ P, |∑ a ∈ A, w1 a * (if ∀ q ∈ Q, R1 q a then (1:ℝ) else 0) -
      ∑ b ∈ B, w2 b * (if ∀ q ∈ Q, R2 q b then (1:ℝ) else 0)| ≤ δ) (j : ℕ) :
    |∑ a ∈ A, w1 a * (∑ p ∈ P, ((if R1 p a then (1:ℝ) else 0) - c p)) ^ j -
      ∑ b ∈ B, w2 b * (∑ p ∈ P, ((if R2 p b then (1:ℝ) else 0) - c p)) ^ j| ≤
      (2 * P.card) ^ j * δ := by
  rw [sum_mul_pow_expand, sum_mul_pow_expand, ← Finset.sum_sub_distrib]
  simp_rw [← Finset.sum_sub_distrib, ← mul_sub]
  have hδ0 : 0 ≤ δ := le_trans (abs_nonneg _) (hδ ∅ (Finset.empty_subset _))
  calc _ ≤ ∑ g ∈ Fintype.piFinset (fun _ : Fin j => P), ∑ J ∈ (univ : Finset (Fin j)).powerset,
        |(∏ i ∈ univ \ J, (-c (g i))) *
          (∑ a ∈ A, w1 a * (if ∀ q ∈ J.image g, R1 q a then (1:ℝ) else 0) -
            ∑ b ∈ B, w2 b * (if ∀ q ∈ J.image g, R2 q b then (1:ℝ) else 0))| := by
        refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun g _ => ?_)
        exact Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ g ∈ Fintype.piFinset (fun _ : Fin j => P), ∑ J ∈ (univ : Finset (Fin j)).powerset,
        δ := by
        apply Finset.sum_le_sum
        intro g hg
        apply Finset.sum_le_sum
        intro J _
        rw [Fintype.mem_piFinset] at hg
        rw [abs_mul]
        have h1 : |∏ i ∈ univ \ J, (-c (g i))| ≤ 1 := by
          rw [Finset.abs_prod]
          apply Finset.prod_le_one₀ (fun i _ => abs_nonneg _)
          intro i _
          rw [abs_neg]; exact hc _ (hg i)
        have h2 := hδ (J.image g) (by
          intro q hq
          obtain ⟨i, _, rfl⟩ := Finset.mem_image.mp hq
          exact hg i)
        calc _ ≤ 1 * δ := mul_le_mul h1 h2 (abs_nonneg _) zero_le_one
          _ = δ := one_mul δ
    _ = (2 * P.card) ^ j * δ := by
        simp only [Finset.sum_const, Finset.card_powerset, Finset.card_univ, Fintype.card_fin,
          Fintype.card_piFinset, Finset.prod_const, nsmul_eq_mul]
        push_cast
        ring




/-! ## The independent model -/

/-- weight of the subset `T` of `P` in the model -/
noncomputable def mw (P T : Finset ℕ) : ℝ :=
  (∏ p ∈ T, (1 / (p : ℝ))) * ∏ p ∈ P \ T, (1 - 1 / (p : ℝ))

lemma powerset_prod {R : Type*} [CommRing R] (P : Finset ℕ) (c a b : ℕ → R) :
    ∑ T ∈ P.powerset, ((∏ p ∈ T, c p) * ∏ p ∈ P \ T, (1 - c p)) *
        ∏ p ∈ P, (if p ∈ T then a p else b p) =
      ∏ p ∈ P, (c p * a p + (1 - c p) * b p) := by
  rw [Finset.prod_add (fun p => c p * a p) (fun p => (1 - c p) * b p)]
  apply sum_congr rfl
  intro T hT
  rw [Finset.mem_powerset] at hT
  rw [Finset.prod_ite, Finset.filter_mem_eq_inter, Finset.inter_eq_right.mpr hT,
    Finset.filter_notMem_eq_sdiff, Finset.prod_mul_distrib, Finset.prod_mul_distrib]
  ring

lemma mw_nonneg (P T : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) : 0 ≤ mw P T := by
  unfold mw
  apply mul_nonneg
  · apply Finset.prod_nonneg; intro p _; positivity
  · apply Finset.prod_nonneg
    intro p hp
    have : (2:ℝ) ≤ p := by exact_mod_cast (hP p (Finset.mem_sdiff.mp hp).1).two_le
    rw [sub_nonneg, div_le_one (by linarith)]; linarith

lemma model_indicator (P Q : Finset ℕ) (hQ : Q ⊆ P) :
    ∑ T ∈ P.powerset, mw P T * (if ∀ q ∈ Q, q ∈ T then (1:ℝ) else 0) =
      ∏ q ∈ Q, (1 / (q : ℝ)) := by
  have h := powerset_prod P (fun p => 1 / (p : ℝ)) (fun _ => 1)
    (fun p => if p ∈ Q then 0 else 1)
  have e : ∀ T ∈ P.powerset, (if ∀ q ∈ Q, q ∈ T then (1:ℝ) else 0) =
      ∏ p ∈ P, (if p ∈ T then (fun _ => (1:ℝ)) p else (fun p => if p ∈ Q then (0:ℝ) else 1) p) := by
    intro T hT
    rw [Finset.mem_powerset] at hT
    split_ifs with hQT
    · symm
      apply Finset.prod_eq_one
      intro p _
      by_cases hpT : p ∈ T
      · simp [hpT]
      · have : p ∉ Q := fun h => hpT (hQT p h)
        simp [hpT, this]
    · push Not at hQT
      obtain ⟨q, hqQ, hqT⟩ := hQT
      symm
      apply Finset.prod_eq_zero (hQ hqQ)
      simp [hqT, hqQ]
  rw [Finset.sum_congr rfl (fun T hT => by rw [e T hT])]
  simp only [mw]
  rw [h]
  have e2 : ∀ p ∈ P, (1 / (p:ℝ) * 1 + (1 - 1 / (p:ℝ)) * (if p ∈ Q then 0 else 1)) =
      if p ∈ Q then 1 / (p:ℝ) else 1 := by
    intro p _; split_ifs <;> ring
  rw [Finset.prod_congr rfl e2, Finset.prod_ite_mem, Finset.inter_eq_right.mpr hQ]

lemma emp_indicator (x : ℕ) (hx : 1 ≤ x) (Q : Finset ℕ) (hQ : ∀ q ∈ Q, q.Prime) :
    |∑ n ∈ Icc 1 x, (1 / (x:ℝ)) * (if ∀ q ∈ Q, q ∣ n then (1:ℝ) else 0) -
      ∏ q ∈ Q, (1 / (q:ℝ))| ≤ 1 / x := by
  set d := ∏ q ∈ Q, q with hd
  have hd0 : 0 < d := Finset.prod_pos (fun q hq => (hQ q hq).pos)
  have hfilt : (Icc 1 x).filter (fun n => ∀ q ∈ Q, q ∣ n) = (Icc 1 x).filter (fun n => d ∣ n) := by
    apply Finset.filter_congr
    intro n _
    constructor
    · intro h
      exact Finset.prod_primes_dvd n (fun q hq => (hQ q hq).prime) h
    · intro h q hq
      exact dvd_trans (Finset.dvd_prod_of_mem _ hq) h
  rw [← Finset.mul_sum, Finset.sum_boole, hfilt]
  have hcard : ((Icc 1 x).filter (fun n => d ∣ n)).card = x / d := by
    rw [← Nat.Ioc_filter_dvd_card_eq_div]; rfl
  rw [hcard]
  have hprod : ∏ q ∈ Q, (1 / (q:ℝ)) = 1 / (d:ℝ) := by
    rw [hd, Nat.cast_prod, Finset.prod_div_distrib, Finset.prod_const_one]
  rw [hprod]
  have hxr : (0:ℝ) < x := by exact_mod_cast hx
  have hdr : (0:ℝ) < d := by exact_mod_cast hd0
  set m := x / d with hm
  have h1 : m * d ≤ x := Nat.div_mul_le_self x d
  have h2 : x < m * d + d := Nat.lt_div_mul_add hd0
  have h1r : (m:ℝ) * d ≤ x := by exact_mod_cast h1
  have h2r : (x:ℝ) < m * d + d := by exact_mod_cast h2
  rw [abs_le]
  constructor
  · rw [show 1 / (x:ℝ) * (m:ℝ) - 1 / d = (m * d - x) / (x * d) by field_simp]
    rw [show -(1 / (x:ℝ)) = -d / (x * d) by field_simp]
    apply div_le_div_of_nonneg_right _ (by positivity)
    linarith
  · rw [show 1 / (x:ℝ) * (m:ℝ) - 1 / d = (m * d - x) / (x * d) by field_simp]
    have : ((m:ℝ) * d - x) / (x * d) ≤ 0 :=
      div_nonpos_of_nonpos_of_nonneg (by linarith) (by positivity)
    have : (0:ℝ) ≤ 1 / x := by positivity
    linarith

/-- centred count of the primes of `P` dividing `n` -/
noncomputable def Semp (P : Finset ℕ) (n : ℕ) : ℝ :=
  ∑ p ∈ P, ((if p ∣ n then (1:ℝ) else 0) - 1 / (p:ℝ))

/-- the same in the model -/
noncomputable def Smod (P T : Finset ℕ) : ℝ :=
  ∑ p ∈ P, ((if p ∈ T then (1:ℝ) else 0) - 1 / (p:ℝ))

lemma moment_diff (P : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) (x : ℕ) (hx : 1 ≤ x) (j : ℕ) :
    |∑ n ∈ Icc 1 x, (1 / (x:ℝ)) * Semp P n ^ j - ∑ T ∈ P.powerset, mw P T * Smod P T ^ j| ≤
      (2 * P.card) ^ j * (1 / x) := by
  apply moment_compare P (Icc 1 x) P.powerset (fun _ => 1 / (x:ℝ)) (mw P)
    (fun p n => p ∣ n) (fun p T => p ∈ T) (fun p => 1 / (p:ℝ))
  · intro p hp
    have : (1:ℝ) ≤ p := by exact_mod_cast (hP p hp).one_lt.le
    rw [abs_of_nonneg (by positivity)]
    rw [div_le_one (by linarith)]; exact this
  · intro Q hQ
    rw [model_indicator P Q hQ]
    exact emp_indicator x hx Q (fun q hq => hP q (hQ hq))

lemma model_mgf (P : Finset ℕ) (s : ℝ) :
    ∑ T ∈ P.powerset, mw P T * Real.exp (s * Smod P T) =
      ∏ p ∈ P, (1 / (p:ℝ) * Real.exp (s * (1 - 1 / p)) + (1 - 1 / (p:ℝ)) * Real.exp (s * (0 - 1 / p))) := by
  rw [← powerset_prod P (fun p => 1 / (p:ℝ)) (fun p => Real.exp (s * (1 - 1 / p)))
    (fun p => Real.exp (s * (0 - 1 / p)))]
  apply sum_congr rfl
  intro T _
  rw [mw, Smod, Finset.mul_sum, Real.exp_sum]
  congr 1
  apply prod_congr rfl
  intro p _
  split_ifs <;> rfl

lemma model_mgf_le (P : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) (s : ℝ) (hs : |s| ≤ 1) :
    ∑ T ∈ P.powerset, mw P T * Real.exp (s * Smod P T) ≤
      Real.exp ((∑ p ∈ P, 1 / (p:ℝ)) * s ^ 2) := by
  rw [model_mgf, Finset.sum_mul, Real.exp_sum]
  apply Finset.prod_le_prod₀
  · intro p hp
    have : (1:ℝ) ≤ p := by exact_mod_cast (hP p hp).one_lt.le
    have : 1 / (p:ℝ) ≤ 1 := by rw [div_le_one (by linarith)]; linarith
    have : 0 ≤ 1 - 1 / (p:ℝ) := by linarith
    positivity
  · intro p hp
    have hp1 : (1:ℝ) ≤ p := by exact_mod_cast (hP p hp).one_lt.le
    set c := 1 / (p:ℝ) with hc
    have hc0 : 0 ≤ c := by positivity
    have hc1 : c ≤ 1 := by rw [hc, div_le_one (by linarith)]; linarith
    have e : c * Real.exp (s * (1 - c)) + (1 - c) * Real.exp (s * (0 - c)) =
        Real.exp (-(s * c)) * (c * (Real.exp s - 1) + 1) := by
      rw [show s * (1 - c) = s + -(s * c) by ring, Real.exp_add, show s * (0 - c) = -(s * c) by ring]
      ring
    rw [e]
    have h1 : c * (Real.exp s - 1) + 1 ≤ Real.exp (c * (Real.exp s - 1)) := Real.add_one_le_exp _
    have h2 : Real.exp s - 1 - s ≤ s ^ 2 := by
      have := Real.norm_exp_sub_one_sub_id_le (x := s) (by rw [Real.norm_eq_abs]; exact hs)
      rw [Real.norm_eq_abs, Real.norm_eq_abs, sq_abs] at this
      exact le_trans (le_abs_self _) this
    calc Real.exp (-(s * c)) * (c * (Real.exp s - 1) + 1)
        ≤ Real.exp (-(s * c)) * Real.exp (c * (Real.exp s - 1)) :=
          mul_le_mul_of_nonneg_left h1 (Real.exp_nonneg _)
      _ = Real.exp (c * (Real.exp s - 1 - s)) := by rw [← Real.exp_add]; ring_nf
      _ ≤ Real.exp (c * s ^ 2) := by
          apply Real.exp_le_exp.mpr
          exact mul_le_mul_of_nonneg_left h2 hc0

lemma model_abs_moment (P : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) (k : ℕ) (l : ℝ) (hl : 0 < l)
    (hμ : l ^ 2 ≤ ∑ p ∈ P, 1 / (p:ℝ)) :
    ∑ T ∈ P.powerset, mw P T * |Smod P T / √(∑ p ∈ P, 1 / (p:ℝ))| ^ k ≤
      2 * Real.exp (l ^ 2) * k.factorial / l ^ k := by
  set μ := ∑ p ∈ P, 1 / (p:ℝ) with hμdef
  have hμ0 : 0 < μ := lt_of_lt_of_le (by positivity) hμ
  have hsq : 0 < √μ := Real.sqrt_pos.mpr hμ0
  have hls : l ≤ √μ := Real.le_sqrt_of_sq_le hμ
  set s := l / √μ with hs
  have hs1 : |s| ≤ 1 := by
    rw [abs_of_nonneg (by positivity), hs, div_le_one hsq]; exact hls
  have hs1' : |-s| ≤ 1 := by rw [abs_neg]; exact hs1
  have hkf : (0:ℝ) < k.factorial := by exact_mod_cast Nat.factorial_pos k
  have pt : ∀ T, |Smod P T / √μ| ^ k ≤ k.factorial / l ^ k *
      (Real.exp (s * Smod P T) + Real.exp (-s * Smod P T)) := by
    intro T
    set z := Smod P T / √μ
    have hz : s * Smod P T = l * z := by simp only [z, hs]; field_simp
    have hz' : -s * Smod P T = -(l * z) := by rw [neg_mul, hz]
    rw [hz, hz']
    have h1 := Real.pow_div_factorial_le_exp (x := l * |z|) (by positivity) k
    have h2 : Real.exp (l * |z|) ≤ Real.exp (l * z) + Real.exp (-(l * z)) := by
      rcases le_or_gt 0 z with h | h
      · rw [abs_of_nonneg h]; linarith [Real.exp_pos (-(l * z))]
      · rw [abs_of_neg h]; rw [show l * -z = -(l * z) by ring]; linarith [Real.exp_pos (l * z)]
    rw [mul_pow] at h1
    rw [div_mul_eq_mul_div, le_div_iff₀ (by positivity)]
    rw [div_le_iff₀ hkf] at h1
    nlinarith [pow_pos hl k]
  calc ∑ T ∈ P.powerset, mw P T * |Smod P T / √μ| ^ k
      ≤ ∑ T ∈ P.powerset, mw P T * (k.factorial / l ^ k *
          (Real.exp (s * Smod P T) + Real.exp (-s * Smod P T))) := by
        apply Finset.sum_le_sum
        intro T _
        exact mul_le_mul_of_nonneg_left (pt T) (mw_nonneg P T hP)
    _ = k.factorial / l ^ k * (∑ T ∈ P.powerset, mw P T * Real.exp (s * Smod P T) +
          ∑ T ∈ P.powerset, mw P T * Real.exp (-s * Smod P T)) := by
        rw [mul_add, Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib]
        apply sum_congr rfl; intro T _; ring
    _ ≤ k.factorial / l ^ k * (Real.exp (μ * s ^ 2) + Real.exp (μ * (-s) ^ 2)) := by
        apply mul_le_mul_of_nonneg_left _ (by positivity)
        exact add_le_add (model_mgf_le P hP s hs1) (model_mgf_le P hP (-s) hs1')
    _ = 2 * Real.exp (l ^ 2) * k.factorial / l ^ k := by
        have : μ * s ^ 2 = l ^ 2 := by
          rw [hs, div_pow, Real.sq_sqrt hμ0.le]; field_simp
        rw [neg_sq, this]; ring


section CF
open Complex

lemma norm_prod_sub_prod_le {ι : Type*} [DecidableEq ι] (s : Finset ι) (a b : ι → ℂ)
    (ha : ∀ i ∈ s, ‖a i‖ ≤ 1) (hb : ∀ i ∈ s, ‖b i‖ ≤ 1) :
    ‖∏ i ∈ s, a i - ∏ i ∈ s, b i‖ ≤ ∑ i ∈ s, ‖a i - b i‖ := by
  induction s using Finset.induction_on with
  | empty => simp
  | insert i s hi ih =>
    rw [Finset.prod_insert hi, Finset.prod_insert hi, Finset.sum_insert hi]
    have ha' := fun j hj => ha j (Finset.mem_insert_of_mem hj)
    have hb' := fun j hj => hb j (Finset.mem_insert_of_mem hj)
    have hpb : ‖∏ j ∈ s, b j‖ ≤ 1 := by
      rw [norm_prod]; exact Finset.prod_le_one₀ (fun _ _ => norm_nonneg _) hb'
    have e : a i * ∏ j ∈ s, a j - b i * ∏ j ∈ s, b j =
        a i * (∏ j ∈ s, a j - ∏ j ∈ s, b j) + (a i - b i) * ∏ j ∈ s, b j := by ring
    rw [e]
    calc _ ≤ ‖a i * (∏ j ∈ s, a j - ∏ j ∈ s, b j)‖ + ‖(a i - b i) * ∏ j ∈ s, b j‖ := norm_add_le _ _
      _ ≤ 1 * ∑ j ∈ s, ‖a j - b j‖ + ‖a i - b i‖ * 1 := by
          rw [norm_mul, norm_mul]
          gcongr
          · exact ha i (Finset.mem_insert_self i s)
          · exact ih ha' hb'
      _ = _ := by ring

lemma sum_inv_mul_pred (N : ℕ) (hN : 1 ≤ N) :
    ∑ n ∈ Icc 2 N, 1 / ((n:ℝ) * (n - 1)) = 1 - 1 / N := by
  induction N, hN using Nat.le_induction with
  | base => norm_num
  | succ N hN ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    have : (1:ℝ) ≤ N := by exact_mod_cast hN
    push_cast
    rw [show (N:ℝ) + 1 - 1 = N by ring]
    field_simp
    ring

lemma sum_primes_inv_sq_le (P : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) :
    ∑ p ∈ P, (1 / (p:ℝ)) ^ 2 ≤ 1 := by
  set N := P.sup id + 1
  have hsub : P ⊆ Icc 2 N := by
    intro p hp
    rw [Finset.mem_Icc]
    exact ⟨(hP p hp).two_le, le_trans (Finset.le_sup (f := id) hp) (Nat.le_succ _)⟩
  have h1 : ∑ p ∈ P, (1 / (p:ℝ)) ^ 2 ≤ ∑ n ∈ Icc 2 N, 1 / ((n:ℝ) * (n - 1)) := by
    calc ∑ p ∈ P, (1 / (p:ℝ)) ^ 2 ≤ ∑ p ∈ P, 1 / ((p:ℝ) * (p - 1)) := by
          apply Finset.sum_le_sum
          intro p hp
          have : (2:ℝ) ≤ p := by exact_mod_cast (hP p hp).two_le
          rw [div_pow, one_pow]
          apply one_div_le_one_div_of_le (by nlinarith)
          nlinarith
      _ ≤ _ := by
          apply Finset.sum_le_sum_of_subset_of_nonneg hsub
          intro n hn _
          have : (2:ℝ) ≤ n := by exact_mod_cast (Finset.mem_Icc.mp hn).1
          apply div_nonneg zero_le_one
          nlinarith
  rw [sum_inv_mul_pred N (by omega)] at h1
  have : (0:ℝ) ≤ 1 / N := by positivity
  linarith

lemma cf_expand {γ : Type*} (C : Finset γ) (w : γ → ℝ) (Z : γ → ℝ) (t : ℝ) (k : ℕ) :
    ∑ c ∈ C, (w c : ℂ) * cexp (t * Z c * I) =
      ∑ j ∈ range k, ((t:ℂ) * I) ^ j / (j.factorial : ℂ) * ((∑ c ∈ C, w c * Z c ^ j : ℝ) : ℂ) +
        ∑ c ∈ C, (w c : ℂ) * tayRem k (t * Z c) := by
  have : ∀ c ∈ C, (w c : ℂ) * cexp (t * Z c * I) =
      ∑ j ∈ range k, ((t:ℂ) * I) ^ j / (j.factorial : ℂ) * ((w c * Z c ^ j : ℝ) : ℂ) +
        (w c : ℂ) * tayRem k (t * Z c) := by
    intro c _
    unfold tayRem
    rw [mul_sub, Finset.mul_sum]
    push_cast
    have hs : ∑ j ∈ range k, ((t:ℂ) * I) ^ j / (j.factorial : ℂ) * ((w c : ℂ) * (Z c : ℂ) ^ j) =
        ∑ j ∈ range k, (w c : ℂ) * (((t:ℂ) * (Z c : ℂ) * I) ^ j / (j.factorial : ℂ)) :=
      sum_congr rfl (fun j _ => by ring)
    rw [hs]; ring
  rw [Finset.sum_congr rfl this, Finset.sum_add_distrib, Finset.sum_comm]
  congr 1
  apply sum_congr rfl
  intro j _
  push_cast
  rw [Finset.mul_sum]

lemma norm_sum_tayRem_le {γ : Type*} (C : Finset γ) (w : γ → ℝ) (hw : ∀ c ∈ C, 0 ≤ w c)
    (Z : γ → ℝ) (t : ℝ) (k : ℕ) :
    ‖∑ c ∈ C, (w c : ℂ) * tayRem k (t * Z c)‖ ≤ |t| ^ k / k.factorial * ∑ c ∈ C, w c * |Z c| ^ k := by
  refine (norm_sum_le _ _).trans ?_
  rw [Finset.mul_sum]
  apply Finset.sum_le_sum
  intro c hc
  rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg (hw c hc)]
  have := norm_tayRem_le k (t * Z c)
  rw [abs_mul, mul_pow] at this
  calc w c * ‖tayRem k (t * Z c)‖ ≤ w c * (|t| ^ k * |Z c| ^ k / k.factorial) :=
        mul_le_mul_of_nonneg_left this (hw c hc)
    _ = _ := by ring

/-- Taylor comparison of two finite characteristic functions through their moments. -/
lemma cf_compare {α β : Type*} (A : Finset α) (B : Finset β) (w1 : α → ℝ) (w2 : β → ℝ)
    (hw1 : ∀ a ∈ A, 0 ≤ w1 a) (hw2 : ∀ b ∈ B, 0 ≤ w2 b) (X : α → ℝ) (Y : β → ℝ) (t : ℝ) (k : ℕ) :
    ‖∑ a ∈ A, (w1 a : ℂ) * cexp (t * X a * I) - ∑ b ∈ B, (w2 b : ℂ) * cexp (t * Y b * I)‖ ≤
      ∑ j ∈ range k, |t| ^ j / j.factorial *
          |∑ a ∈ A, w1 a * X a ^ j - ∑ b ∈ B, w2 b * Y b ^ j| +
        |t| ^ k / k.factorial * (∑ a ∈ A, w1 a * |X a| ^ k + ∑ b ∈ B, w2 b * |Y b| ^ k) := by
  rw [cf_expand A w1 X t k, cf_expand B w2 Y t k]
  have e : ∀ (u v r s : ℂ), u + r - (v + s) = (u - v) + (r - s) := fun _ _ _ _ => by ring
  rw [e, ← Finset.sum_sub_distrib]
  have hkf : (0:ℝ) < k.factorial := by exact_mod_cast Nat.factorial_pos k
  calc _ ≤ ‖∑ j ∈ range k, (((t:ℂ) * I) ^ j / (j.factorial : ℂ) * ((∑ a ∈ A, w1 a * X a ^ j : ℝ) : ℂ) -
          ((t:ℂ) * I) ^ j / (j.factorial : ℂ) * ((∑ b ∈ B, w2 b * Y b ^ j : ℝ) : ℂ))‖ +
        (‖∑ a ∈ A, (w1 a : ℂ) * tayRem k (t * X a)‖ + ‖∑ b ∈ B, (w2 b : ℂ) * tayRem k (t * Y b)‖) := by
        refine (norm_add_le _ _).trans ?_
        gcongr
        exact norm_sub_le _ _
    _ ≤ _ := by
        rw [mul_add]
        gcongr
        · refine (norm_sum_le _ _).trans (Finset.sum_le_sum fun j _ => ?_)
          rw [← mul_sub, norm_mul, norm_div, norm_pow, norm_mul, Complex.norm_real, Complex.norm_I,
            mul_one, Complex.norm_natCast, Real.norm_eq_abs, ← Complex.ofReal_sub, Complex.norm_real,
            Real.norm_eq_abs]
        · exact norm_sum_tayRem_le A w1 hw1 X t k
        · exact norm_sum_tayRem_le B w2 hw2 Y t k

lemma model_cf (P : Finset ℕ) (θ : ℝ) :
    ∑ T ∈ P.powerset, (mw P T : ℂ) * cexp (θ * Smod P T * I) =
      cexp (-((θ : ℂ) * ((∑ p ∈ P, 1 / (p:ℝ) : ℝ) : ℂ)) * I) *
        ∏ p ∈ P, (1 + ((1 / (p:ℝ) : ℝ) : ℂ) * (cexp (θ * I) - 1)) := by
  have h := powerset_prod (R := ℂ) P (fun p => ((1 / (p:ℝ) : ℝ) : ℂ))
    (fun p => cexp (θ * (1 - ((1 / (p:ℝ) : ℝ) : ℂ)) * I))
    (fun p => cexp (θ * (0 - ((1 / (p:ℝ) : ℝ) : ℂ)) * I))
  have e1 : ∀ T ∈ P.powerset, (mw P T : ℂ) * cexp (θ * Smod P T * I) =
      ((∏ p ∈ T, ((1 / (p:ℝ) : ℝ) : ℂ)) * ∏ p ∈ P \ T, (1 - ((1 / (p:ℝ) : ℝ) : ℂ))) *
        ∏ p ∈ P, (if p ∈ T then cexp (θ * (1 - ((1 / (p:ℝ) : ℝ) : ℂ)) * I)
          else cexp (θ * (0 - ((1 / (p:ℝ) : ℝ) : ℂ)) * I)) := by
    intro T _
    congr 1
    · simp [mw]
    · rw [Smod, Complex.ofReal_sum, Finset.mul_sum, Finset.sum_mul, Complex.exp_sum]
      apply prod_congr rfl
      intro p _
      split_ifs <;> push_cast <;> rfl
  rw [Finset.sum_congr rfl e1, h, Complex.ofReal_sum, Finset.mul_sum, ← Finset.sum_neg_distrib,
    Finset.sum_mul, Complex.exp_sum, ← Finset.prod_mul_distrib]
  apply prod_congr rfl
  intro p _
  set c : ℂ := ((1 / (p:ℝ) : ℝ) : ℂ)
  rw [show (θ:ℂ) * (1 - c) * I = θ * I + (-(θ * c) * I) by ring, Complex.exp_add,
    show (θ:ℂ) * (0 - c) * I = -(θ * c) * I by ring]
  ring

lemma model_cf_bound (P : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) (t : ℝ)
    (hμ : 0 < ∑ p ∈ P, 1 / (p:ℝ)) (h1 : t ^ 2 ≤ ∑ p ∈ P, 1 / (p:ℝ))
    (h2 : |t| ^ 3 ≤ 6 * √(∑ p ∈ P, 1 / (p:ℝ))) :
    ‖∑ T ∈ P.powerset, (mw P T : ℂ) * cexp (t * (Smod P T / √(∑ p ∈ P, 1 / (p:ℝ)) : ℝ) * I) -
        cexp (-(t:ℂ) ^ 2 / 2)‖ ≤
      t ^ 2 / (∑ p ∈ P, 1 / (p:ℝ)) + |t| ^ 3 / (3 * √(∑ p ∈ P, 1 / (p:ℝ))) := by
  set μ := ∑ p ∈ P, 1 / (p:ℝ) with hμdef
  have hsq : 0 < √μ := Real.sqrt_pos.mpr hμ
  have hsq2 : √μ ^ 2 = μ := Real.sq_sqrt hμ.le
  set θ := t / √μ with hθ
  have hθt : θ ^ 2 * μ = t ^ 2 := by rw [hθ, div_pow, hsq2]; field_simp
  have hθ1 : |θ| ≤ 1 := by
    have : θ ^ 2 ≤ 1 := by
      have : θ ^ 2 * μ ≤ 1 * μ := by rw [hθt, one_mul]; exact h1
      exact le_of_mul_le_mul_right this hμ
    nlinarith [sq_abs θ, abs_nonneg θ]
  have hrw : ∀ T, (t : ℂ) * ((Smod P T / √μ : ℝ) : ℂ) * I = θ * Smod P T * I := by
    intro T; push_cast; rw [hθ]; push_cast; ring
  simp_rw [hrw]
  rw [model_cf P θ]
  set E := cexp (θ * I) - 1 with hE
  have hE1 : ‖E‖ ≤ |θ| := by
    have := norm_tayRem_le 1 θ
    simpa [tayRem] using this
  -- the factors
  set a : ℕ → ℂ := fun p => 1 + ((1 / (p:ℝ) : ℝ) : ℂ) * E with ha
  set b : ℕ → ℂ := fun p => cexp (((1 / (p:ℝ) : ℝ) : ℂ) * E) with hb
  have hc : ∀ p ∈ P, 0 ≤ 1 / (p:ℝ) ∧ 1 / (p:ℝ) ≤ 1 := by
    intro p hp
    have : (1:ℝ) ≤ p := by exact_mod_cast (hP p hp).one_lt.le
    exact ⟨by positivity, by rw [div_le_one (by linarith)]; exact this⟩
  have hna : ∀ p ∈ P, ‖a p‖ ≤ 1 := by
    intro p hp
    obtain ⟨c0, c1⟩ := hc p hp
    simp only [ha, hE]
    rw [show (1:ℂ) + ((1 / (p:ℝ) : ℝ) : ℂ) * (cexp (θ * I) - 1) =
      ((1 - 1 / (p:ℝ) : ℝ) : ℂ) + ((1 / (p:ℝ) : ℝ) : ℂ) * cexp (θ * I) by push_cast; ring]
    refine (norm_add_le _ _).trans ?_
    rw [norm_mul, Complex.norm_real, Complex.norm_real, Complex.norm_exp_ofReal_mul_I,
      Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg c0, abs_of_nonneg (by linarith)]
    linarith
  have hnb : ∀ p ∈ P, ‖b p‖ ≤ 1 := by
    intro p hp
    obtain ⟨c0, c1⟩ := hc p hp
    simp only [hb]
    rw [Complex.norm_exp, Real.exp_le_one_iff]
    rw [Complex.re_ofReal_mul, hE, Complex.sub_re, Complex.one_re]
    apply mul_nonpos_of_nonneg_of_nonpos c0
    have := Complex.re_le_norm (cexp (θ * I))
    rw [Complex.norm_exp_ofReal_mul_I] at this
    linarith
  have hab : ∀ p ∈ P, ‖a p - b p‖ ≤ (1 / (p:ℝ)) ^ 2 * θ ^ 2 := by
    intro p hp
    obtain ⟨c0, c1⟩ := hc p hp
    have hz : ‖((1 / (p:ℝ) : ℝ) : ℂ) * E‖ ≤ 1 / (p:ℝ) * |θ| := by
      rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg c0]
      exact mul_le_mul_of_nonneg_left hE1 c0
    have hz1 : ‖((1 / (p:ℝ) : ℝ) : ℂ) * E‖ ≤ 1 := by
      refine hz.trans ?_
      calc 1 / (p:ℝ) * |θ| ≤ 1 * 1 := mul_le_mul c1 hθ1 (abs_nonneg _) zero_le_one
        _ = 1 := one_mul 1
    have := Complex.norm_exp_sub_one_sub_id_le hz1
    simp only [ha, hb]
    rw [show (1:ℂ) + ((1 / (p:ℝ) : ℝ) : ℂ) * E - cexp (((1 / (p:ℝ) : ℝ) : ℂ) * E) =
      -(cexp (((1 / (p:ℝ) : ℝ) : ℂ) * E) - 1 - ((1 / (p:ℝ) : ℝ) : ℂ) * E) by ring, norm_neg]
    refine this.trans ?_
    calc ‖((1 / (p:ℝ) : ℝ) : ℂ) * E‖ ^ 2 ≤ (1 / (p:ℝ) * |θ|) ^ 2 :=
          pow_le_pow_left₀ (norm_nonneg _) hz 2
      _ = (1 / (p:ℝ)) ^ 2 * θ ^ 2 := by rw [mul_pow, sq_abs]
  have hprod : ‖∏ p ∈ P, a p - ∏ p ∈ P, b p‖ ≤ θ ^ 2 := by
    refine (norm_prod_sub_prod_le P a b hna hnb).trans ?_
    calc ∑ p ∈ P, ‖a p - b p‖ ≤ ∑ p ∈ P, (1 / (p:ℝ)) ^ 2 * θ ^ 2 := Finset.sum_le_sum hab
      _ = (∑ p ∈ P, (1 / (p:ℝ)) ^ 2) * θ ^ 2 := by rw [Finset.sum_mul]
      _ ≤ 1 * θ ^ 2 := mul_le_mul_of_nonneg_right (sum_primes_inv_sq_le P hP) (sq_nonneg _)
      _ = θ ^ 2 := one_mul _
  have hprodb : ∏ p ∈ P, b p = cexp ((μ : ℂ) * E) := by
    simp only [hb]
    rw [← Complex.exp_sum, ← Finset.sum_mul, hμdef, Complex.ofReal_sum]
  -- the exponent
  set D : ℂ := (μ : ℂ) * tayRem 3 θ with hD
  have hDeq : -((θ:ℂ) * μ) * I + μ * E = -(t:ℂ) ^ 2 / 2 + D := by
    simp only [hD, tayRem, hE]
    have : (t:ℂ) ^ 2 = (θ:ℂ) ^ 2 * μ := by exact_mod_cast hθt.symm
    rw [this]
    simp [Finset.sum_range_succ]
    ring_nf
    rw [Complex.I_sq]
    ring
  have hDn : ‖D‖ ≤ |t| ^ 3 / (6 * √μ) := by
    simp only [hD]
    rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hμ]
    have := norm_tayRem_le 3 θ
    calc μ * ‖tayRem 3 θ‖ ≤ μ * (|θ| ^ 3 / (Nat.factorial 3 : ℝ)) :=
          mul_le_mul_of_nonneg_left this hμ.le
      _ = μ * (|t| ^ 3 / √μ ^ 3 / 6) := by
          rw [hθ, abs_div, abs_of_pos hsq, div_pow]; norm_num [Nat.factorial]
      _ = |t| ^ 3 / (6 * √μ) := by
          rw [show √μ ^ 3 = √μ ^ 2 * √μ by ring, hsq2]
          field_simp
  have hD1 : ‖D‖ ≤ 1 := by
    refine hDn.trans ?_
    rw [div_le_one (by positivity)]; exact h2
  have hexp1 : ‖cexp (-(θ:ℂ) * μ * I)‖ = 1 := by
    rw [show -(θ:ℂ) * μ * I = ((-(θ * μ) : ℝ) : ℂ) * I by push_cast; ring]
    exact Complex.norm_exp_ofReal_mul_I _
  have hexpb : ‖cexp (-(t:ℂ) ^ 2 / 2)‖ ≤ 1 := by
    rw [Complex.norm_exp]
    rw [Real.exp_le_one_iff]
    have : (-(t:ℂ) ^ 2 / 2).re = -(t ^ 2) / 2 := by
      rw [show -(t:ℂ) ^ 2 / 2 = ((-(t ^ 2) / 2 : ℝ) : ℂ) by push_cast; ring, Complex.ofReal_re]
    rw [this]; nlinarith [sq_nonneg t]
  have key : cexp (-((θ : ℂ) * (μ : ℂ)) * I) * ∏ p ∈ P, a p - cexp (-(t:ℂ) ^ 2 / 2) =
      cexp (-((θ : ℂ) * (μ : ℂ)) * I) * (∏ p ∈ P, a p - ∏ p ∈ P, b p) +
        cexp (-(t:ℂ) ^ 2 / 2) * (cexp D - 1) := by
    rw [mul_sub, hprodb, ← Complex.exp_add, hDeq, Complex.exp_add]
    ring
  have hfin : ∏ p ∈ P, (1 + ((1 / (p:ℝ) : ℝ) : ℂ) * (cexp (θ * I) - 1)) = ∏ p ∈ P, a p := rfl
  rw [hfin, key]
  refine (norm_add_le _ _).trans ?_
  rw [norm_mul, norm_mul, show -((θ : ℂ) * (μ : ℂ)) * I = -(θ:ℂ) * μ * I by ring, hexp1, one_mul]
  have h3 : ‖cexp D - 1‖ ≤ 2 * ‖D‖ := Complex.norm_exp_sub_one_le hD1
  have hθ2 : θ ^ 2 = t ^ 2 / μ := by rw [← hθt]; field_simp
  calc ‖∏ p ∈ P, a p - ∏ p ∈ P, b p‖ + ‖cexp (-(t:ℂ) ^ 2 / 2)‖ * ‖cexp D - 1‖
      ≤ θ ^ 2 + 1 * (2 * (|t| ^ 3 / (6 * √μ))) := by
        gcongr
        exact h3.trans (by gcongr)
    _ = t ^ 2 / μ + |t| ^ 3 / (3 * √μ) := by
        rw [hθ2]; field_simp; ring

end CF


section EmpCF
open Complex

lemma emp_cf_bound (P : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) (x : ℕ) (hx : 1 ≤ x) (t l : ℝ)
    (hl : 0 < l) (k : ℕ) (hk : Even k)
    (hμ1 : 1 ≤ ∑ p ∈ P, 1 / (p:ℝ)) (hlμ : l ^ 2 ≤ ∑ p ∈ P, 1 / (p:ℝ))
    (ht1 : t ^ 2 ≤ ∑ p ∈ P, 1 / (p:ℝ)) (ht2 : |t| ^ 3 ≤ 6 * √(∑ p ∈ P, 1 / (p:ℝ)))
    (hPk : (P.card : ℝ) ^ k ≤ √(x:ℝ)) :
    ‖∑ n ∈ Icc 1 x, ((1 / (x:ℝ) : ℝ) : ℂ) * cexp (t * (Semp P n / √(∑ p ∈ P, 1 / (p:ℝ)) : ℝ) * I) -
        cexp (-(t:ℂ) ^ 2 / 2)‖ ≤
      Real.exp (2 * |t|) / √(x:ℝ) + 4 * Real.exp (l ^ 2) * (|t| / l) ^ k +
        (t ^ 2 / (∑ p ∈ P, 1 / (p:ℝ)) + |t| ^ 3 / (3 * √(∑ p ∈ P, 1 / (p:ℝ)))) := by
  set μ := ∑ p ∈ P, 1 / (p:ℝ) with hμdef
  have hμ0 : 0 < μ := by linarith
  have hsq : 1 ≤ √μ := by rw [Real.one_le_sqrt]; exact hμ1
  have hxr : (0:ℝ) < x := by exact_mod_cast hx
  have hsx : 0 < √(x:ℝ) := Real.sqrt_pos.mpr hxr
  have hPne : 1 ≤ (P.card : ℝ) := by
    rcases Finset.eq_empty_or_nonempty P with h | h
    · rw [hμdef, h] at hμ1; simp at hμ1; linarith
    · exact_mod_cast Finset.card_pos.mpr h
  have hmod := model_cf_bound P hP t hμ0 ht1 ht2
  rw [← hμdef] at hmod
  have hcmp := cf_compare (Icc 1 x) P.powerset (fun _ => 1 / (x:ℝ)) (mw P)
    (fun _ _ => by positivity) (fun T _ => mw_nonneg P T hP)
    (fun n => Semp P n / √μ) (fun T => Smod P T / √μ) t k
  -- moments
  have hmom : ∀ j, |∑ n ∈ Icc 1 x, 1 / (x:ℝ) * (Semp P n / √μ) ^ j -
      ∑ T ∈ P.powerset, mw P T * (Smod P T / √μ) ^ j| ≤ (2 * P.card) ^ j * (1 / x) := by
    intro j
    have e : ∀ {γ : Type} (C : Finset γ) (w : γ → ℝ) (Z : γ → ℝ),
        ∑ c ∈ C, w c * (Z c / √μ) ^ j = (∑ c ∈ C, w c * Z c ^ j) / √μ ^ j := by
      intro γ C w Z
      rw [Finset.sum_div]
      apply sum_congr rfl; intro c _; rw [div_pow]; ring
    rw [e, e, ← sub_div, abs_div, abs_of_pos (pow_pos (lt_of_lt_of_le one_pos hsq) j)]
    refine (div_le_self (abs_nonneg _) (one_le_pow₀ hsq)).trans ?_
    exact moment_diff P hP x hx j
  have hbig : ∀ j ≤ k, (2 * (P.card:ℝ)) ^ j * (1 / x) ≤ 2 ^ j / √(x:ℝ) := by
    intro j hj
    rw [mul_pow]
    have : (P.card:ℝ) ^ j ≤ √(x:ℝ) := (pow_le_pow_right₀ hPne hj).trans hPk
    have hx2 : √(x:ℝ) * (1 / x) = 1 / √(x:ℝ) := by
      rw [show (x:ℝ) = √(x:ℝ) ^ 2 from (Real.sq_sqrt hxr.le).symm]; field_simp
      rw [Real.sqrt_sq hsx.le]
    calc 2 ^ j * (P.card:ℝ) ^ j * (1 / x) ≤ 2 ^ j * √(x:ℝ) * (1 / x) := by gcongr
      _ = 2 ^ j / √(x:ℝ) := by rw [mul_assoc, hx2]; ring
  -- even absolute moments
  have habs : ∀ {γ : Type} (C : Finset γ) (w : γ → ℝ) (Z : γ → ℝ),
      ∑ c ∈ C, w c * |Z c| ^ k = ∑ c ∈ C, w c * Z c ^ k := by
    intro γ C w Z
    apply sum_congr rfl; intro c _; rw [hk.pow_abs]
  have hE2 := model_abs_moment P hP k l hl hlμ
  rw [← hμdef] at hE2
  have hE1 : ∑ n ∈ Icc 1 x, 1 / (x:ℝ) * |Semp P n / √μ| ^ k ≤
      2 * Real.exp (l ^ 2) * k.factorial / l ^ k + 2 ^ k / √(x:ℝ) := by
    rw [habs]
    have h1 := hmom k
    have h2 := hbig k le_rfl
    rw [habs] at hE2
    have := (abs_le.mp h1).2
    linarith
  rw [habs] at hE2
  have hkf : (0:ℝ) < k.factorial := by exact_mod_cast Nat.factorial_pos k
  -- assemble
  have step1 : ‖∑ n ∈ Icc 1 x, ((1 / (x:ℝ) : ℝ) : ℂ) * cexp (t * (Semp P n / √μ : ℝ) * I) -
      ∑ T ∈ P.powerset, (mw P T : ℂ) * cexp (t * (Smod P T / √μ : ℝ) * I)‖ ≤
      Real.exp (2 * |t|) / √(x:ℝ) + 4 * Real.exp (l ^ 2) * (|t| / l) ^ k := by
    refine hcmp.trans ?_
    rw [habs (Icc 1 x), habs P.powerset]
    have hA : ∑ j ∈ range k, |t| ^ j / j.factorial *
        |∑ n ∈ Icc 1 x, 1 / (x:ℝ) * (Semp P n / √μ) ^ j -
          ∑ T ∈ P.powerset, mw P T * (Smod P T / √μ) ^ j| ≤
        ∑ j ∈ range k, (2 * |t|) ^ j / j.factorial / √(x:ℝ) := by
      apply Finset.sum_le_sum
      intro j hj
      have hjk : j ≤ k := (Finset.mem_range.mp hj).le
      calc |t| ^ j / j.factorial * |∑ n ∈ Icc 1 x, 1 / (x:ℝ) * (Semp P n / √μ) ^ j -
            ∑ T ∈ P.powerset, mw P T * (Smod P T / √μ) ^ j|
          ≤ |t| ^ j / j.factorial * (2 ^ j / √(x:ℝ)) := by
            gcongr; exact (hmom j).trans (hbig j hjk)
        _ = (2 * |t|) ^ j / j.factorial / √(x:ℝ) := by rw [mul_pow]; ring
    have hB : |t| ^ k / k.factorial *
        (∑ n ∈ Icc 1 x, 1 / (x:ℝ) * (Semp P n / √μ) ^ k +
          ∑ T ∈ P.powerset, mw P T * (Smod P T / √μ) ^ k) ≤
        4 * Real.exp (l ^ 2) * (|t| / l) ^ k + (2 * |t|) ^ k / k.factorial / √(x:ℝ) := by
      rw [habs] at hE1
      have hs : ∑ n ∈ Icc 1 x, 1 / (x:ℝ) * (Semp P n / √μ) ^ k +
          ∑ T ∈ P.powerset, mw P T * (Smod P T / √μ) ^ k ≤
          4 * Real.exp (l ^ 2) * k.factorial / l ^ k + 2 ^ k / √(x:ℝ) := by
        have : 4 * Real.exp (l ^ 2) * k.factorial / l ^ k =
          2 * (2 * Real.exp (l ^ 2) * k.factorial / l ^ k) := by ring
        linarith
      calc |t| ^ k / k.factorial * (∑ n ∈ Icc 1 x, 1 / (x:ℝ) * (Semp P n / √μ) ^ k +
            ∑ T ∈ P.powerset, mw P T * (Smod P T / √μ) ^ k)
          ≤ |t| ^ k / k.factorial * (4 * Real.exp (l ^ 2) * k.factorial / l ^ k + 2 ^ k / √(x:ℝ)) := by
            gcongr
        _ = 4 * Real.exp (l ^ 2) * (|t| / l) ^ k + (2 * |t|) ^ k / k.factorial / √(x:ℝ) := by
            rw [div_pow, mul_pow]; field_simp
    have hC : ∑ j ∈ range k, (2 * |t|) ^ j / j.factorial / √(x:ℝ) +
        (2 * |t|) ^ k / k.factorial / √(x:ℝ) ≤ Real.exp (2 * |t|) / √(x:ℝ) := by
      rw [← Finset.sum_div, ← add_div, ← Finset.sum_range_succ]
      gcongr
      exact Real.sum_le_exp_of_nonneg (by positivity) _
    linarith
  calc _ ≤ ‖∑ n ∈ Icc 1 x, ((1 / (x:ℝ) : ℝ) : ℂ) * cexp (t * (Semp P n / √μ : ℝ) * I) -
      ∑ T ∈ P.powerset, (mw P T : ℂ) * cexp (t * (Smod P T / √μ : ℝ) * I)‖ +
      ‖∑ T ∈ P.powerset, (mw P T : ℂ) * cexp (t * (Smod P T / √μ : ℝ) * I) -
        cexp (-(t:ℂ) ^ 2 / 2)‖ := norm_sub_le_norm_sub_add_norm_sub _ _ _
    _ ≤ _ := add_le_add step1 hmod

end EmpCF

/-- uniform measure on the values `Z n`, `n = 1..x` -/
noncomputable def empMeasure (x : ℕ) (Z : ℕ → ℝ) : Measure ℝ :=
  ∑ n ∈ Icc 1 x, ((x : ℝ≥0∞)⁻¹ • Measure.dirac (Z n))

open scoped Classical in
lemma empMeasure_apply (x : ℕ) (Z : ℕ → ℝ) (s : Set ℝ) (hs : MeasurableSet s) :
    empMeasure x Z s = (x : ℝ≥0∞)⁻¹ * (#{n ∈ Icc 1 x | Z n ∈ s} : ℝ≥0∞) := by
  rw [empMeasure, Measure.finsetSum_apply]
  simp only [Measure.smul_apply, smul_eq_mul, Measure.dirac_apply' _ hs]
  rw [← Finset.mul_sum]
  congr 1
  rw [Finset.card_filter]
  push_cast
  apply sum_congr rfl
  intro n _
  by_cases h : Z n ∈ s <;> simp [h]

lemma empMeasure_isProb (x : ℕ) (hx : 1 ≤ x) (Z : ℕ → ℝ) :
    IsProbabilityMeasure (empMeasure x Z) := by
  constructor
  rw [empMeasure_apply x Z _ MeasurableSet.univ]
  simp only [Set.mem_univ, Finset.filter_true_of_mem, implies_true, Nat.card_Icc,
    add_tsub_cancel_right]
  try exact ENNReal.inv_mul_cancel (by exact_mod_cast (by omega : x ≠ 0)) (ENNReal.natCast_ne_top x)

lemma charFun_empMeasure (x : ℕ) (Z : ℕ → ℝ) (t : ℝ) :
    charFun (empMeasure x Z) t =
      ∑ n ∈ Icc 1 x, ((1 / (x:ℝ) : ℝ) : ℂ) * Complex.exp (t * Z n * Complex.I) := by
  rw [charFun_apply_real, empMeasure, integral_finsetSum_measure]
  · apply sum_congr rfl
    intro n hn
    have : x ≠ 0 := by have := (Finset.mem_Icc.mp hn); omega
    rw [integral_smul_measure, integral_dirac]
    simp [Complex.real_smul]
  · intro n hn
    have : x ≠ 0 := by have := (Finset.mem_Icc.mp hn); omega
    apply Integrable.smul_measure _ (by simp [this])
    apply integrable_dirac
    simp

lemma levy_cdf (Z : ℕ → ℕ → ℝ)
    (h : ∀ t : ℝ, Tendsto (fun x : ℕ => ∑ n ∈ Icc 1 x, ((1 / (x:ℝ) : ℝ) : ℂ) *
      Complex.exp (t * Z x n * Complex.I)) atTop (𝓝 (Complex.exp (-(t:ℂ) ^ 2 / 2)))) (w : ℝ) :
    Tendsto (fun x : ℕ => (#{n ∈ Icc 1 x | Z x n ≤ w} : ℝ) / x) atTop
      (𝓝 (cdf (gaussianReal 0 1) w)) := by
  let ν : ℕ → ProbabilityMeasure ℝ := fun m =>
    ⟨empMeasure (m + 1) (Z (m + 1)), empMeasure_isProb (m + 1) (by omega) (Z (m + 1))⟩
  let γ : ProbabilityMeasure ℝ := ⟨gaussianReal 0 1, inferInstance⟩
  have hlim : Tendsto ν atTop (𝓝 γ) := by
    apply ProbabilityMeasure.tendsto_of_tendsto_charFun
    intro t
    have h1 := (h t).comp (tendsto_add_atTop_nat 1)
    have e1 : charFun (γ : Measure ℝ) t = Complex.exp (-(t:ℂ) ^ 2 / 2) := by
      simp only [γ, ProbabilityMeasure.coe_mk, charFun_gaussianReal]
      congr 1; push_cast; ring
    rw [e1]
    convert h1 using 1
    funext m
    simp only [ν, ProbabilityMeasure.coe_mk, Function.comp, charFun_empMeasure]
  have hfr : γ (frontier (Set.Iic w)) = 0 := by
    rw [frontier_Iic]
    have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    simp [γ]
  have h2 := ProbabilityMeasure.tendsto_measure_of_null_frontier_of_tendsto hlim hfr
  have h3 := (NNReal.continuous_coe.tendsto _).comp h2
  rw [← Filter.tendsto_add_atTop_iff_nat 1]
  convert h3 using 1
  · funext m
    simp only [Function.comp, ν, ProbabilityMeasure.mk_apply]
    rw [ENNReal.coe_toNNReal_eq_toReal, empMeasure_apply _ _ _ measurableSet_Iic,
      ENNReal.toReal_mul, ENNReal.toReal_inv]
    simp only [ENNReal.toReal_natCast, Set.mem_Iic]
    push_cast
    rw [div_eq_inv_mul]
  · rw [cdf_eq_real]
    simp [γ, Measure.real]
    rfl

lemma continuous_cdf_gaussian (z : ℝ) : ContinuousAt (cdf (gaussianReal 0 1)) z := by
  set f := cdf (gaussianReal 0 1)
  rw [f.mono.continuousAt_iff_leftLim_eq_rightLim, f.rightLim_eq]
  have h1 : f.measure {z} = 0 := by
    rw [measure_cdf]
    have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    simp
  rw [StieltjesFunction.measure_singleton, ENNReal.ofReal_eq_zero] at h1
  have h2 := f.mono.leftLim_le (le_refl z)
  linarith

/-! ## Parameters -/

/-- `log log x` -/
noncomputable def ekL (x : ℕ) : ℝ := Real.log (Real.log x)
/-- the cut exponent `β = (log log x)^(1/4)` -/
noncomputable def ekB (x : ℕ) : ℝ := √(√(ekL x))
/-- the cut `y = x^(1/β)` -/
noncomputable def ekR (x : ℕ) : ℝ := (x : ℝ) ^ (1 / ekB x)
/-- the primes up to the cut -/
noncomputable def ekP (x : ℕ) : Finset ℕ := Nat.primesLE ⌊ekR x⌋₊
/-- the mean `∑ 1/p` over the primes up to the cut -/
noncomputable def ekMu (x : ℕ) : ℝ := ∑ p ∈ ekP x, 1 / (p:ℝ)

lemma ekP_prime (x : ℕ) : ∀ p ∈ ekP x, p.Prime := fun _ hp => (Nat.mem_primesLE.mp hp).2

lemma one_lt_log_four : 1 < Real.log 4 := by
  rw [Real.lt_log_iff_exp_lt (by norm_num)]
  have := Real.exp_one_lt_d9
  linarith

lemma eventually_log_ge (C : ℝ) : ∀ᶠ x : ℕ in atTop, C ≤ Real.log x := by
  have : Tendsto (fun x : ℕ => Real.log x) atTop atTop :=
    Real.tendsto_log_atTop.comp tendsto_natCast_atTop_atTop
  exact this.eventually_ge_atTop C

/-- basic facts once `log x ≥ 4` -/
lemma good_params (x : ℕ) (hx : 4 ≤ Real.log x) :
    Real.log 4 ≤ ekL x ∧ 1 ≤ ekB x ∧ √(ekL x) = ekB x ^ 2 ∧ ekL x = ekB x ^ 4 ∧
      ekB x ≤ √(Real.log x) ∧ 4 ≤ ekR x ∧ Real.log (ekR x) = Real.log x / ekB x := by
  have hlx : 0 < Real.log x := by linarith
  have hx0 : (0:ℝ) < x := by
    by_contra h
    push Not at h
    have : (x:ℝ) = 0 := le_antisymm h (Nat.cast_nonneg x)
    rw [this, Real.log_zero] at hx; linarith
  have hL : Real.log 4 ≤ ekL x := Real.log_le_log (by norm_num) hx
  have hL1 : 1 ≤ ekL x := le_trans one_lt_log_four.le hL
  have hB1 : 1 ≤ ekB x := by
    unfold ekB
    rw [Real.one_le_sqrt, Real.one_le_sqrt]; exact hL1
  have hsq : √(ekL x) = ekB x ^ 2 := by
    unfold ekB; rw [Real.sq_sqrt (Real.sqrt_nonneg _)]
  have hL4 : ekL x = ekB x ^ 4 := by
    rw [show ekB x ^ 4 = (ekB x ^ 2) ^ 2 by ring, ← hsq, Real.sq_sqrt (by linarith)]
  have hLlog : ekL x ≤ Real.log x := by
    unfold ekL
    have := Real.log_le_sub_one_of_pos hlx
    linarith
  have hBle : ekB x ≤ √(Real.log x) := by
    unfold ekB
    calc √(√(ekL x)) ≤ √(ekL x) := by
          apply Real.sqrt_le_sqrt
          rw [Real.sqrt_le_left (by linarith)]
          nlinarith
      _ ≤ √(Real.log x) := Real.sqrt_le_sqrt hLlog
  have hlogR : Real.log (ekR x) = Real.log x / ekB x := by
    unfold ekR
    rw [Real.log_rpow hx0]; ring
  have hR4 : 4 ≤ ekR x := by
    have hs : 2 ≤ √(Real.log x) := by
      rw [Real.le_sqrt (by norm_num) hlx.le]; linarith
    have h1 : √(Real.log x) ≤ Real.log x / ekB x := by
      rw [le_div_iff₀ (by linarith)]
      calc √(Real.log x) * ekB x ≤ √(Real.log x) * √(Real.log x) := by gcongr
        _ = Real.log x := Real.mul_self_sqrt hlx.le
    have h2 : Real.log 4 ≤ Real.log (ekR x) := by
      rw [hlogR]
      have : Real.log 4 < 2 := by
        have := Real.log_le_sub_one_of_pos (x := 4) (by norm_num)
        have h4 : Real.log 4 = 2 * Real.log 2 := by
          rw [show (4:ℝ) = 2 ^ 2 by norm_num, Real.log_pow]; push_cast; ring
        have := Real.log_two_lt_d9
        linarith
      linarith
    have hRpos : 0 < ekR x := by unfold ekR; positivity
    exact (Real.log_le_log_iff (by norm_num) hRpos).mp h2
  exact ⟨hL, hB1, hsq, hL4, hBle, hR4, hlogR⟩

lemma mu_close (x : ℕ) (hx : 4 ≤ Real.log x) :
    |ekMu x - ekL x| ≤ Real.log (ekB x) + 13 := by
  obtain ⟨hL, hB1, hsq, hL4, hBle, hR4, hlogR⟩ := good_params x hx
  set R := ekR x
  set Y := ⌊R⌋₊
  have hY4 : 4 ≤ Y := Nat.le_floor (by exact_mod_cast hR4)
  have hYR : (Y:ℝ) ≤ R := Nat.floor_le (by linarith)
  have hYR' : R - 1 < (Y:ℝ) := by have := Nat.lt_floor_add_one R; linarith
  have hY0 : (0:ℝ) < Y := by exact_mod_cast (by omega : 0 < Y)
  have hM := mertens2 Y (by omega)
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hl2' : Real.log 2 < 1 := by have := Real.log_two_lt_d9; linarith
  have h4 : Real.log 4 = 2 * Real.log 2 := by
    rw [show (4:ℝ) = 2 ^ 2 by norm_num, Real.log_pow]; push_cast; ring
  have hlR : 2 * Real.log 2 ≤ Real.log R := by
    rw [← h4]; exact Real.log_le_log (by norm_num) hR4
  have hlY1 : Real.log Y ≤ Real.log R := Real.log_le_log hY0 hYR
  have hlY2 : Real.log R - Real.log 2 ≤ Real.log Y := by
    rw [← Real.log_div (by linarith) (by norm_num)]
    apply Real.log_le_log (by linarith)
    linarith
  have hlYpos : 0 < Real.log Y := by linarith
  have hll1 : Real.log (Real.log Y) ≤ Real.log (Real.log R) := Real.log_le_log hlYpos hlY1
  have hll2 : Real.log (Real.log R) - Real.log 2 ≤ Real.log (Real.log Y) := by
    rw [← Real.log_div (by linarith) (by norm_num)]
    apply Real.log_le_log (div_pos (by linarith) (by norm_num))
    linarith
  have hllR : Real.log (Real.log R) = ekL x - Real.log (ekB x) := by
    rw [hlogR, Real.log_div (by linarith) (by linarith)]; rfl
  have hlogB : 0 ≤ Real.log (ekB x) := Real.log_nonneg hB1
  unfold ekMu ekP
  rw [abs_le] at hM ⊢
  constructor <;> linarith [hM.1, hM.2]

lemma tendsto_ekL : Tendsto ekL atTop atTop :=
  Real.tendsto_log_atTop.comp (Real.tendsto_log_atTop.comp tendsto_natCast_atTop_atTop)

lemma tendsto_ekB : Tendsto ekB atTop atTop :=
  Real.tendsto_sqrt_atTop.comp (Real.tendsto_sqrt_atTop.comp tendsto_ekL)

lemma tendsto_ekMu : Tendsto ekMu atTop atTop := by
  have h1 : Tendsto (fun x => ekB x - 13) atTop atTop := tendsto_atTop_add_const_right _ _ tendsto_ekB
  apply tendsto_atTop_mono' _ _ h1
  filter_upwards [eventually_log_ge 4, tendsto_ekB.eventually_ge_atTop 2] with x hx hB
  obtain ⟨hL, hB1, hsq, hL4, hBle, hR4, hlogR⟩ := good_params x hx
  have hm := mu_close x hx
  rw [abs_le] at hm
  have hlogB : Real.log (ekB x) ≤ ekB x - 1 := Real.log_le_sub_one_of_pos (by linarith)
  have : 2 * ekB x ≤ ekB x ^ 4 := by nlinarith [sq_nonneg (ekB x), sq_nonneg (ekB x ^ 2 - 1)]
  linarith [hm.1]

lemma card_ekP_pow_le (x : ℕ) (hx : 4 ≤ Real.log x) (k : ℕ) (hk : 2 * (k:ℝ) ≤ ekB x) :
    ((ekP x).card : ℝ) ^ k ≤ √(x:ℝ) := by
  obtain ⟨hL, hB1, hsq, hL4, hBle, hR4, hlogR⟩ := good_params x hx
  have hx0 : (0:ℝ) < x := by
    by_contra h
    push Not at h
    have : (x:ℝ) = 0 := le_antisymm h (Nat.cast_nonneg x)
    rw [this, Real.log_zero] at hx; linarith
  have hx1 : (1:ℝ) ≤ x := by
    by_contra h
    push Not at h
    have := Real.log_neg hx0 h
    linarith
  have hcard : ((ekP x).card : ℝ) ≤ ekR x := by
    have h1 : (ekP x).card ≤ ⌊ekR x⌋₊ := by
      unfold ekP
      calc (Nat.primesLE ⌊ekR x⌋₊).card ≤ (Icc 1 ⌊ekR x⌋₊).card := by
            apply Finset.card_le_card
            intro p hp
            rw [Nat.mem_primesLE] at hp
            exact Finset.mem_Icc.mpr ⟨hp.2.one_lt.le, hp.1⟩
        _ = ⌊ekR x⌋₊ := by simp
    calc ((ekP x).card : ℝ) ≤ (⌊ekR x⌋₊ : ℝ) := by exact_mod_cast h1
      _ ≤ ekR x := Nat.floor_le (by linarith)
  calc ((ekP x).card : ℝ) ^ k ≤ ekR x ^ k := by gcongr
    _ = (x:ℝ) ^ ((k:ℝ) / ekB x) := by
        unfold ekR
        rw [← Real.rpow_natCast, ← Real.rpow_mul hx0.le]; congr 1; ring
    _ ≤ (x:ℝ) ^ ((1:ℝ) / 2) := by
        apply Real.rpow_le_rpow_of_exponent_le hx1
        rw [div_le_div_iff₀ (by linarith) (by norm_num)]; linarith
    _ = √(x:ℝ) := (Real.sqrt_eq_rpow _).symm

open Complex in
lemma core_cf (t : ℝ) :
    Tendsto (fun x : ℕ => ∑ n ∈ Icc 1 x, ((1 / (x:ℝ) : ℝ) : ℂ) *
      cexp (t * (Semp (ekP x) n / √(ekMu x) : ℝ) * I)) atTop (𝓝 (cexp (-(t:ℂ) ^ 2 / 2))) := by
  rw [Metric.tendsto_nhds]
  intro ε hε
  set l := 2 * |t| + 1 with hl
  have hl0 : 0 < l := by positivity
  obtain ⟨m, hm⟩ := exists_pow_lt_of_lt_one (show 0 < ε / (16 * Real.exp (l ^ 2)) by positivity)
    (show (1/2:ℝ) < 1 by norm_num)
  set k := 2 * m with hk
  have hkev : Even k := even_two_mul m
  have hk1 : 4 * Real.exp (l ^ 2) * (|t| / l) ^ k < ε / 4 := by
    have h1 : (|t| / l) ^ k ≤ (1/2) ^ m := by
      calc (|t| / l) ^ k ≤ (1/2) ^ k := by
            apply pow_le_pow_left₀ (by positivity)
            rw [div_le_iff₀ hl0]; linarith
        _ ≤ (1/2) ^ m := pow_le_pow_of_le_one (by norm_num) (by norm_num) (by omega)
    have h2 : (1/2:ℝ) ^ m * (16 * Real.exp (l ^ 2)) < ε := by
      rwa [lt_div_iff₀ (by positivity)] at hm
    have := Real.exp_pos (l ^ 2)
    nlinarith
  -- model error tends to zero
  have hsqmu : Tendsto (fun x => √(ekMu x)) atTop atTop := Real.tendsto_sqrt_atTop.comp tendsto_ekMu
  have hg : Tendsto (fun x => t ^ 2 / ekMu x + |t| ^ 3 / (3 * √(ekMu x))) atTop (𝓝 0) := by
    have a1 := tendsto_ekMu.const_div_atTop (t ^ 2)
    have a2 := (hsqmu.const_mul_atTop (by norm_num : (0:ℝ) < 3)).const_div_atTop (|t| ^ 3)
    simpa using a1.add a2
  have hsx : Tendsto (fun x : ℕ => Real.exp (2 * |t|) / √(x:ℝ)) atTop (𝓝 0) :=
    (Real.tendsto_sqrt_atTop.comp tendsto_natCast_atTop_atTop).const_div_atTop _
  filter_upwards [eventually_log_ge 4, tendsto_ekB.eventually_ge_atTop (2 * (k:ℝ)),
    tendsto_ekMu.eventually_ge_atTop (1 + l ^ 2 + t ^ 2 + |t| ^ 6),
    hg.eventually (gt_mem_nhds (show (0:ℝ) < ε / 4 by positivity)),
    hsx.eventually (gt_mem_nhds (show (0:ℝ) < ε / 4 by positivity))] with x hx hB hmu hgx hsxx
  have hx0 : (0:ℝ) < x := by
    by_contra h
    push Not at h
    have : (x:ℝ) = 0 := le_antisymm h (Nat.cast_nonneg x)
    rw [this, Real.log_zero] at hx; linarith
  have hx1 : 1 ≤ x := by exact_mod_cast hx0
  have ht2 : |t| ^ 3 ≤ 6 * √(ekMu x) := by
    have : |t| ^ 3 ≤ √(ekMu x) := by
      rw [Real.le_sqrt (by positivity) (by linarith [sq_nonneg t, sq_nonneg l, pow_two_nonneg (|t| ^ 3)])]
      have : (|t| ^ 3) ^ 2 = |t| ^ 6 := by ring
      nlinarith [sq_nonneg t, sq_nonneg l]
    nlinarith [Real.sqrt_nonneg (ekMu x)]
  have hb := emp_cf_bound (ekP x) (ekP_prime x) x hx1 t l hl0 k hkev
    (by unfold ekMu at hmu; nlinarith [sq_nonneg t, sq_nonneg l, pow_two_nonneg (|t| ^ 3)])
    (by unfold ekMu at hmu; nlinarith [sq_nonneg t, sq_nonneg l, pow_two_nonneg (|t| ^ 3)])
    (by unfold ekMu at hmu; nlinarith [sq_nonneg t, sq_nonneg l, pow_two_nonneg (|t| ^ 3)])
    (by unfold ekMu at ht2; exact ht2)
    (card_ekP_pow_le x hx k hB)
  rw [dist_eq_norm]
  unfold ekMu at hgx
  unfold ekMu
  linarith


lemma card_cut_lt (x β : ℝ) (n : ℕ) (hβ : 0 < β) (hn : (n : ℝ) ≤ x) :
    ((n.primeFactors.filter (fun p : ℕ ↦ x ^ (1 / β) < (p : ℝ))).card : ℝ) < β := by
  set s := n.primeFactors.filter (fun p : ℕ ↦ x ^ (1 / β) < (p : ℝ)) with hs
  by_contra hcon
  push Not at hcon
  have hn0 : n ≠ 0 := by
    rintro rfl
    simp [hs] at hcon
    linarith
  have hx1 : 1 ≤ x := le_trans (by exact_mod_cast Nat.one_le_iff_ne_zero.mpr hn0) hn
  have hdvd : (∏ p ∈ s, p) ∣ n := by
    refine dvd_trans (Finset.prod_dvd_prod_of_subset _ _ id (Finset.filter_subset _ _)) ?_
    exact Nat.prod_primeFactors_dvd n
  have hle : ((∏ p ∈ s, p : ℕ) : ℝ) ≤ x :=
    le_trans (by exact_mod_cast Nat.le_of_dvd (Nat.pos_of_ne_zero hn0) hdvd) hn
  have hy0 : 0 < x ^ (1 / β) := Real.rpow_pos_of_pos (by linarith) _
  have hne : s.Nonempty := by
    rw [Finset.nonempty_iff_ne_empty]
    rintro h
    rw [h] at hcon
    simp at hcon
    linarith
  have hlt : (x ^ (1 / β)) ^ s.card < ((∏ p ∈ s, p : ℕ) : ℝ) := by
    push_cast
    rw [← Finset.prod_const]
    obtain ⟨i0, hi0⟩ := hne
    apply Finset.prod_lt_prod₀
    · intro i _; exact hy0
    · intro i hi
      exact ((Finset.mem_filter.mp hi).2).le
    · exact ⟨i0, hi0, (Finset.mem_filter.mp hi0).2⟩
  have hge : x ≤ (x ^ (1 / β)) ^ s.card := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul (by linarith)]
    calc x = x ^ (1:ℝ) := (Real.rpow_one x).symm
      _ ≤ x ^ (1 / β * s.card) := by
        apply Real.rpow_le_rpow_of_exponent_le hx1
        rw [div_mul_eq_mul_div, one_mul, le_div_iff₀ hβ]
        linarith
  linarith

lemma sandwich_point (A B r s z ε δ : ℝ) (hr : 0 < r) (hδ : δ ≤ 1 / 2) (hr1 : |r - 1| ≤ δ)
    (hs : |s| ≤ δ) (hε : 2 * δ * (|z| + 1) ≤ ε) (hA : A = B * r + s) :
    (A ≤ z → B ≤ z + ε) ∧ (B ≤ z - ε → A ≤ z) := by
  have key : A ≤ z ↔ B ≤ (z - s) / r := by
    rw [hA, le_div_iff₀ hr]; constructor <;> intro h <;> linarith
  have hr2 : 1 / 2 ≤ r := by have := (abs_le.mp hr1).1; linarith
  have hδ0 : 0 ≤ δ := le_trans (abs_nonneg _) hs
  have hclose : |(z - s) / r - z| ≤ ε := by
    rw [show (z - s) / r - z = (z * (1 - r) - s) / r by field_simp; ring, abs_div, abs_of_pos hr,
      div_le_iff₀ hr]
    have h1 : |z * (1 - r) - s| ≤ |z| * δ + δ := by
      calc |z * (1 - r) - s| ≤ |z * (1 - r)| + |s| := abs_sub _ _
        _ = |z| * |r - 1| + |s| := by rw [abs_mul, abs_sub_comm]
        _ ≤ |z| * δ + δ := by gcongr
    have h2 : (|z| * δ + δ) ≤ ε * r := by
      have : (|z| * δ + δ) = δ * (|z| + 1) := by ring
      rw [this]
      have hz : 0 ≤ |z| + 1 := by positivity
      have hε0 : 0 ≤ ε := le_trans (by positivity) hε
      nlinarith [mul_le_mul_of_nonneg_left hr2 hε0]
    linarith
  rw [abs_le] at hclose
  constructor
  · intro h; have := key.mp h; linarith [hclose.2]
  · intro h; apply key.mpr; linarith [hclose.1]

lemma Semp_eq (P : Finset ℕ) (n : ℕ) :
    Semp P n = ((P.filter (· ∣ n)).card : ℝ) - ∑ p ∈ P, 1 / (p:ℝ) := by
  unfold Semp
  rw [Finset.sum_sub_distrib, Finset.sum_boole]

lemma omega_split (x : ℕ) (hx : 4 ≤ Real.log x) (n : ℕ) (hn1 : 1 ≤ n) (hnx : n ≤ x) :
    ((ekP x).filter (· ∣ n)).card ≤ ω n ∧
      ((ω n : ℝ) - ((ekP x).filter (· ∣ n)).card) < ekB x := by
  obtain ⟨hL, hB1, hsq, hL4, hBle, hR4, hlogR⟩ := good_params x hx
  have hωn : ω n = n.primeFactors.card := by
    rw [ArithmeticFunction.cardDistinctFactors_apply, Nat.primeFactors, List.card_toFinset]
  have hfilt : (ekP x).filter (· ∣ n) = n.primeFactors.filter (· ≤ ⌊ekR x⌋₊) := by
    ext p
    simp only [ekP, Finset.mem_filter, Nat.mem_primesLE, Nat.mem_primeFactors]
    constructor
    · rintro ⟨⟨h1, h2⟩, h3⟩; exact ⟨⟨h2, h3, by omega⟩, h1⟩
    · rintro ⟨⟨h2, h3, _⟩, h1⟩; exact ⟨⟨h1, h2⟩, h3⟩
  have hcut := card_cut_lt (x : ℝ) (ekB x) n (by linarith) (by exact_mod_cast hnx)
  have hfilt2 : n.primeFactors.filter (fun p : ℕ => (x:ℝ) ^ (1 / ekB x) < (p:ℝ)) =
      n.primeFactors.filter (fun p => ¬ p ≤ ⌊ekR x⌋₊) := by
    apply Finset.filter_congr
    intro p _
    rw [not_le, Nat.floor_lt (by unfold ekR; positivity)]
    rfl
  rw [hfilt2] at hcut
  have hsplit := Finset.card_filter_add_card_filter_not
    (s := n.primeFactors) (fun p => p ≤ ⌊ekR x⌋₊)
  rw [hfilt, hωn]
  constructor
  · omega
  · have : (n.primeFactors.card : ℝ) = (n.primeFactors.filter (· ≤ ⌊ekR x⌋₊)).card +
        (n.primeFactors.filter (fun p => ¬ p ≤ ⌊ekR x⌋₊)).card := by exact_mod_cast hsplit.symm
    linarith

lemma beta_aux (β : ℝ) (h : 64 ≤ β) : 2 * β + 13 < β ^ 4 ∧ β ^ 2 ≤ β ^ 4 := by
  have b2 : 64 * β ≤ β ^ 2 := by nlinarith
  have b4 : β ^ 2 * β ^ 2 = β ^ 4 := by ring
  have b3 : 64 * β ^ 2 ≤ β ^ 4 := by nlinarith
  constructor <;> nlinarith

lemma point_decomp (x : ℕ) (hx : 4 ≤ Real.log x) (hB64 : 64 ≤ ekB x) (n : ℕ) (hn3 : 3 ≤ n)
    (hnx : n ≤ x) (hns : Nat.sqrt x < n) :
    ∃ r s : ℝ, 0 < r ∧ |r - 1| ≤ 32 / ekB x ∧ |s| ≤ 32 / ekB x ∧
      ((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) =
        (Semp (ekP x) n / √(ekMu x)) * r + s := by
  obtain ⟨hL, hB1, hsq, hL4, hBle, hR4, hlogR⟩ := good_params x hx
  set β := ekB x with hβ
  set L := ekL x with hLdef
  set μ := ekMu x with hμdef
  set ℓ := Real.log (Real.log n) with hℓdef
  have hn0 : (1:ℝ) < n := by exact_mod_cast (by omega : 1 < n)
  have hlogn : 0 < Real.log n := Real.log_pos hn0
  have hxn : (n:ℝ) ≤ x := by exact_mod_cast hnx
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have h4 : Real.log 4 = 2 * Real.log 2 := by
    rw [show (4:ℝ) = 2 ^ 2 by norm_num, Real.log_pow]; push_cast; ring
  -- bounds on ℓ
  have hℓ1 : ℓ ≤ L := Real.log_le_log hlogn (Real.log_le_log (by linarith) hxn)
  have hsq2 : (x:ℝ) ≤ (n:ℝ) ^ 2 := by
    have := Nat.lt_succ_sqrt' x
    have : x ≤ n ^ 2 := le_trans this.le (Nat.pow_le_pow_left hns 2)
    exact_mod_cast this
  have hlx : Real.log x ≤ 2 * Real.log n := by
    have hx0 : (0:ℝ) < x := by
      by_contra h; push Not at h
      have : (x:ℝ) = 0 := le_antisymm h (Nat.cast_nonneg x)
      rw [this, Real.log_zero] at hx; linarith
    calc Real.log x ≤ Real.log ((n:ℝ) ^ 2) := Real.log_le_log hx0 hsq2
      _ = 2 * Real.log n := by rw [Real.log_pow]; push_cast; ring
  have hℓ2 : L - Real.log 2 ≤ ℓ := by
    have : Real.log (Real.log x / 2) ≤ ℓ := Real.log_le_log (by linarith) (by linarith)
    rw [Real.log_div (by linarith) (by norm_num)] at this
    exact this
  have hℓ3 : L / 2 ≤ ℓ := by linarith
  have hL0 : 0 < L := by linarith
  have hℓ0 : 0 < ℓ := by linarith
  -- bounds on μ
  have hμL := mu_close x hx
  rw [← hμdef, ← hLdef, ← hβ] at hμL
  have hlogβ : Real.log β ≤ β := by
    have := Real.log_le_sub_one_of_pos (show 0 < β by linarith); linarith
  have hbaux := beta_aux β hB64
  have hD : |μ - ℓ| ≤ 15 * β := by
    rw [abs_le] at hμL ⊢
    have : Real.log 2 < 1 := by have := Real.log_two_lt_d9; linarith
    constructor <;> linarith [hμL.1, hμL.2]
  have hμ0 : 0 < μ := by
    rw [abs_le] at hμL
    linarith [hμL.1, hbaux.1]
  -- omega
  obtain ⟨hω1, hω2⟩ := omega_split x hx n (by omega) hnx
  set ωP := ((ekP x).filter (· ∣ n)).card with hωP
  have hω1' : (ωP : ℝ) ≤ ω n := by exact_mod_cast hω1
  have hSemp : Semp (ekP x) n = ωP - μ := by rw [Semp_eq]; rfl
  -- the decomposition
  have hsμ : 0 < √μ := Real.sqrt_pos.mpr hμ0
  have hsℓ : 0 < √ℓ := Real.sqrt_pos.mpr hℓ0
  refine ⟨√μ / √ℓ, ((ω n : ℝ) - ωP + μ - ℓ) / √ℓ, by positivity, ?_, ?_, ?_⟩
  · -- |r - 1|
    set r := √μ / √ℓ
    have hr0 : 0 ≤ r := by positivity
    have hr2 : r ^ 2 = μ / ℓ := by
      simp only [r]; rw [div_pow, Real.sq_sqrt hμ0.le, Real.sq_sqrt hℓ0.le]
    have h1 : |r - 1| ≤ |r ^ 2 - 1| := by
      rw [show r ^ 2 - 1 = (r - 1) * (r + 1) by ring, abs_mul]
      have : 1 ≤ |r + 1| := by rw [abs_of_nonneg (by linarith)]; linarith
      calc |r - 1| = |r - 1| * 1 := (mul_one _).symm
        _ ≤ |r - 1| * |r + 1| := mul_le_mul_of_nonneg_left this (abs_nonneg _)
    have h2 : |r ^ 2 - 1| = |μ - ℓ| / ℓ := by
      rw [hr2, show μ / ℓ - 1 = (μ - ℓ) / ℓ by field_simp, abs_div, abs_of_pos hℓ0]
    have h3 : |μ - ℓ| / ℓ ≤ 32 / β := by
      rw [div_le_div_iff₀ hℓ0 (by linarith)]
      have : β ^ 4 / 2 ≤ ℓ := by rw [← hL4]; exact hℓ3
      have a : |μ - ℓ| * β ≤ 15 * β * β := mul_le_mul_of_nonneg_right hD (by linarith)
      have b : β * β = β ^ 2 := by ring
      linarith [hbaux.2]
    linarith
  · -- |s|
    rw [abs_div, abs_of_pos hsℓ, div_le_div_iff₀ hsℓ (by linarith)]
    have h1 : |(ω n : ℝ) - ωP + μ - ℓ| ≤ 16 * β := by
      calc |(ω n : ℝ) - ωP + μ - ℓ| = |((ω n : ℝ) - ωP) + (μ - ℓ)| := by ring_nf
        _ ≤ |(ω n : ℝ) - ωP| + |μ - ℓ| := abs_add_le _ _
        _ ≤ β + 15 * β := by
            gcongr
            rw [abs_of_nonneg (by linarith)]; exact hω2.le
        _ = 16 * β := by ring
    have h2 : β ^ 2 / 2 ≤ √ℓ := by
      rw [Real.le_sqrt (by positivity) hℓ0.le]
      have : β ^ 4 / 2 ≤ ℓ := by rw [← hL4]; exact hℓ3
      have e : (β ^ 2 / 2) ^ 2 = β ^ 4 / 4 := by ring
      have : 0 ≤ β ^ 4 := by positivity
      linarith
    have : |(ω n : ℝ) - ωP + μ - ℓ| * β ≤ 16 * β * β := by
      apply mul_le_mul_of_nonneg_right h1 (by linarith)
    have b : β * β = β ^ 2 := by ring
    linarith
  · -- identity
    rw [hSemp]
    field_simp
    ring


lemma card_bad_le (x : ℕ) :
    (((Icc 1 x).filter (· ≤ Nat.sqrt x + 2)).card : ℝ) ≤ √(x:ℝ) + 2 := by
  have h1 : ((Icc 1 x).filter (· ≤ Nat.sqrt x + 2)).card ≤ Nat.sqrt x + 2 := by
    calc ((Icc 1 x).filter (· ≤ Nat.sqrt x + 2)).card ≤ (Icc 1 (Nat.sqrt x + 2)).card := by
          apply Finset.card_le_card
          intro n hn
          rw [Finset.mem_filter, Finset.mem_Icc] at hn
          exact Finset.mem_Icc.mpr ⟨hn.1.1, hn.2⟩
      _ = Nat.sqrt x + 2 := by simp
  have h2 : (Nat.sqrt x : ℝ) ≤ √(x:ℝ) := Real.nat_sqrt_le_real_sqrt
  have h3 : (((Icc 1 x).filter (· ≤ Nat.sqrt x + 2)).card : ℝ) ≤ (Nat.sqrt x : ℝ) + 2 := by
    exact_mod_cast h1
  linarith

lemma count_bounds (z ε : ℝ) (hε : 0 < ε) : ∀ᶠ x : ℕ in atTop,
    (#{n ∈ Icc 3 x | ((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) ≤ z} : ℝ) ≤
        #{n ∈ Icc 1 x | Semp (ekP x) n / √(ekMu x) ≤ z + ε} + (√(x:ℝ) + 2) ∧
    (#{n ∈ Icc 1 x | Semp (ekP x) n / √(ekMu x) ≤ z - ε} : ℝ) ≤
        #{n ∈ Icc 3 x | ((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) ≤ z} +
          (√(x:ℝ) + 2) := by
  set δ0 := min (1 / 2) (ε / (2 * (|z| + 1))) with hδ0
  have hδ0pos : 0 < δ0 := lt_min (by norm_num) (by positivity)
  filter_upwards [eventually_log_ge 4, tendsto_ekB.eventually_ge_atTop 64,
    tendsto_ekB.eventually_ge_atTop (32 / δ0)] with x hx hB64 hBδ
  have hδ : 32 / ekB x ≤ δ0 := by
    rw [div_le_iff₀ (by linarith)]
    rw [div_le_iff₀ hδ0pos] at hBδ
    linarith
  have hδ1 : 32 / ekB x ≤ 1 / 2 := hδ.trans (min_le_left _ _)
  have hδ2 : 2 * (32 / ekB x) * (|z| + 1) ≤ ε := by
    have : 32 / ekB x ≤ ε / (2 * (|z| + 1)) := hδ.trans (min_le_right _ _)
    rw [le_div_iff₀ (by positivity)] at this
    linarith
  have key : ∀ n, 3 ≤ n → n ≤ x → Nat.sqrt x < n →
      ((((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) ≤ z →
        Semp (ekP x) n / √(ekMu x) ≤ z + ε) ∧
      (Semp (ekP x) n / √(ekMu x) ≤ z - ε →
        ((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) ≤ z)) := by
    intro n hn3 hnx hns
    obtain ⟨r, s, hr, hr1, hs, hA⟩ := point_decomp x hx hB64 n hn3 hnx hns
    exact sandwich_point _ _ r s z ε (32 / ekB x) hr hδ1 hr1 hs hδ2 hA
  have hbad := card_bad_le x
  constructor
  · have hsub : (Icc 3 x).filter (fun n => ((ω n : ℝ) - Real.log (Real.log n)) /
        √(Real.log (Real.log n)) ≤ z) ⊆
        (Icc 1 x).filter (fun n => Semp (ekP x) n / √(ekMu x) ≤ z + ε) ∪
          (Icc 1 x).filter (· ≤ Nat.sqrt x + 2) := by
      intro n hn
      rw [Finset.mem_filter, Finset.mem_Icc] at hn
      rw [Finset.mem_union, Finset.mem_filter, Finset.mem_filter, Finset.mem_Icc]
      by_cases hns : n ≤ Nat.sqrt x + 2
      · right; exact ⟨⟨by omega, hn.1.2⟩, hns⟩
      · left
        exact ⟨⟨by omega, hn.1.2⟩, (key n hn.1.1 hn.1.2 (by omega)).1 hn.2⟩
    have := (Finset.card_le_card hsub).trans (Finset.card_union_le _ _)
    have : ((#{n ∈ Icc 3 x | ((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) ≤ z}
        : ℕ) : ℝ) ≤ (#{n ∈ Icc 1 x | Semp (ekP x) n / √(ekMu x) ≤ z + ε} : ℕ) +
          (((Icc 1 x).filter (· ≤ Nat.sqrt x + 2)).card : ℕ) := by exact_mod_cast this
    linarith
  · have hsub : (Icc 1 x).filter (fun n => Semp (ekP x) n / √(ekMu x) ≤ z - ε) ⊆
        (Icc 3 x).filter (fun n => ((ω n : ℝ) - Real.log (Real.log n)) /
          √(Real.log (Real.log n)) ≤ z) ∪ (Icc 1 x).filter (· ≤ Nat.sqrt x + 2) := by
      intro n hn
      rw [Finset.mem_filter, Finset.mem_Icc] at hn
      rw [Finset.mem_union, Finset.mem_filter, Finset.mem_filter, Finset.mem_Icc, Finset.mem_Icc]
      by_cases hns : n ≤ Nat.sqrt x + 2
      · right; exact ⟨hn.1, hns⟩
      · left
        exact ⟨⟨by omega, hn.1.2⟩, (key n (by omega) hn.1.2 (by omega)).2 hn.2⟩
    have := (Finset.card_le_card hsub).trans (Finset.card_union_le _ _)
    have : ((#{n ∈ Icc 1 x | Semp (ekP x) n / √(ekMu x) ≤ z - ε} : ℕ) : ℝ) ≤
        (#{n ∈ Icc 3 x | ((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) ≤ z}
          : ℕ) + (((Icc 1 x).filter (· ≤ Nat.sqrt x + 2)).card : ℕ) := by exact_mod_cast this
    linarith

lemma core_cdf (w : ℝ) :
    Tendsto (fun x : ℕ => (#{n ∈ Icc 1 x | Semp (ekP x) n / √(ekMu x) ≤ w} : ℝ) / x) atTop
      (𝓝 (cdf (gaussianReal 0 1) w)) :=
  levy_cdf (fun x n => Semp (ekP x) n / √(ekMu x)) core_cf w

lemma tendsto_bad : Tendsto (fun x : ℕ => (√(x:ℝ) + 2) / x) atTop (𝓝 0) := by
  have h1 : Tendsto (fun x : ℕ => 1 / √(x:ℝ) + 2 / (x:ℝ)) atTop (𝓝 0) := by
    have a := (Real.tendsto_sqrt_atTop.comp tendsto_natCast_atTop_atTop).const_div_atTop 1
    have b := (tendsto_natCast_atTop_atTop (R := ℝ)).const_div_atTop 2
    simpa using a.add b
  apply h1.congr'
  filter_upwards [eventually_ge_atTop 1] with x hx
  have hx0 : (0:ℝ) < x := by exact_mod_cast hx
  have hs : 0 < √(x:ℝ) := Real.sqrt_pos.mpr hx0
  have : (x:ℝ) = √(x:ℝ) * √(x:ℝ) := (Real.mul_self_sqrt hx0.le).symm
  rw [add_div]
  congr 1
  rw [div_eq_div_iff hs.ne' hx0.ne', one_mul]
  exact this

lemma erdos_kac_main (z : ℝ) :
    Tendsto
      (fun x : ℕ ↦
        (#{n ∈ Icc 3 x | ((ω n : ℝ) - Real.log (Real.log n)) / √(Real.log (Real.log n)) ≤ z} : ℝ) / x)
      atTop (𝓝 (cdf (gaussianReal 0 1) z)) := by
  have hc := continuous_cdf_gaussian z
  rw [Metric.continuousAt_iff] at hc
  rw [tendsto_order]
  constructor
  · intro a ha
    obtain ⟨d, hd, hcd⟩ := hc (cdf (gaussianReal 0 1) z - a) (by linarith)
    have hε : 0 < d / 2 := by positivity
    have h1 := hcd (x := z - d / 2) (by rw [Real.dist_eq]; rw [abs_lt]; constructor <;> linarith)
    rw [Real.dist_eq, abs_lt] at h1
    have hlim := (core_cdf (z - d / 2)).sub tendsto_bad
    rw [sub_zero] at hlim
    have hev := hlim.eventually (lt_mem_nhds (show a < cdf (gaussianReal 0 1) (z - d / 2) by linarith))
    filter_upwards [hev, count_bounds z (d / 2) hε, eventually_ge_atTop 1] with x hx hcb hx1
    have hx0 : (0:ℝ) < x := by exact_mod_cast hx1
    have := hcb.2
    rw [← sub_div] at hx
    calc a < ((#{n ∈ Icc 1 x | Semp (ekP x) n / √(ekMu x) ≤ z - d / 2} : ℝ) - (√(x:ℝ) + 2)) / x := hx
      _ ≤ _ := by gcongr; linarith
  · intro b hb
    obtain ⟨d, hd, hcd⟩ := hc (b - cdf (gaussianReal 0 1) z) (by linarith)
    have hε : 0 < d / 2 := by positivity
    have h1 := hcd (x := z + d / 2) (by rw [Real.dist_eq]; rw [abs_lt]; constructor <;> linarith)
    rw [Real.dist_eq, abs_lt] at h1
    have hlim := (core_cdf (z + d / 2)).add tendsto_bad
    rw [add_zero] at hlim
    have hev := hlim.eventually (gt_mem_nhds (show cdf (gaussianReal 0 1) (z + d / 2) < b by linarith))
    filter_upwards [hev, count_bounds z (d / 2) hε, eventually_ge_atTop 1] with x hx hcb hx1
    have hx0 : (0:ℝ) < x := by exact_mod_cast hx1
    have := hcb.1
    rw [← add_div] at hx
    calc _ ≤ ((#{n ∈ Icc 1 x | Semp (ekP x) n / √(ekMu x) ≤ z + d / 2} : ℝ) + (√(x:ℝ) + 2)) / x := by
          gcongr
      _ < b := hx


#print axioms log_factorial_eq
#print axioms log_factorial_le
#print axioms log_factorial_ge
#print axioms sum_log_div_le
#print axioms sum_primes_log_div_le
#print axioms mertens1_lower
#print axioms mertens1_upper
#print axioms mertensD_step
#print axioms loglog_step
#print axioms mertensD_bounds
#print axioms mertens2
#print axioms hasDerivAt_tayRem
#print axioms tayRem_zero_at
#print axioms norm_tayRem_le
#print axioms pow_sum_sub_expand
#print axioms sum_mul_pow_expand
#print axioms moment_compare
#print axioms powerset_prod
#print axioms mw_nonneg
#print axioms model_indicator
#print axioms emp_indicator
#print axioms moment_diff
#print axioms model_mgf
#print axioms model_mgf_le
#print axioms model_abs_moment
#print axioms norm_prod_sub_prod_le
#print axioms sum_inv_mul_pred
#print axioms sum_primes_inv_sq_le
#print axioms cf_expand
#print axioms norm_sum_tayRem_le
#print axioms cf_compare
#print axioms model_cf
#print axioms model_cf_bound
#print axioms emp_cf_bound
#print axioms empMeasure_apply
#print axioms empMeasure_isProb
#print axioms charFun_empMeasure
#print axioms levy_cdf
#print axioms continuous_cdf_gaussian
#print axioms ekP_prime
#print axioms one_lt_log_four
#print axioms eventually_log_ge
#print axioms good_params
#print axioms mu_close
#print axioms tendsto_ekL
#print axioms tendsto_ekB
#print axioms tendsto_ekMu
#print axioms card_ekP_pow_le
#print axioms core_cf
#print axioms card_cut_lt
#print axioms sandwich_point
#print axioms Semp_eq
#print axioms omega_split
#print axioms beta_aux
#print axioms point_decomp
#print axioms card_bad_le
#print axioms count_bounds
#print axioms core_cdf
#print axioms tendsto_bad
#print axioms erdos_kac_main

end EKHelp

/-- **The Erdos-Kac theorem (1940).** Write `ω n` for the number of different primes dividing
`n`. For every real threshold `z`, among the whole numbers `n` from 3 to `x` (so that
`log log n > 0`), the share whose score `(ω n - log log n) / √(log log n)` is at most `z`
tends, as `x → ∞`, to `Φ(z)`, the standard bell curve's area left of `z`. Logarithms are
natural logarithms. -/
theorem erdos_kac (z : ℝ) :
    Tendsto
      (fun x : ℕ ↦
        (#{n ∈ Icc 3 x | ((ω n : ℝ) - log (log n)) / √(log (log n)) ≤ z} : ℝ) / x)
      atTop (𝓝 (cdf (gaussianReal 0 1) z)) := by
  exact EKHelp.erdos_kac_main z

/-- **The cut costs fewer than `β` primes (Step 3).** If `n ≤ x` and `β > 0`, then fewer than
`β` of the different primes dividing `n` lie above `y = x ^ (1/β)`: `β` of them would multiply
to more than `y ^ β = x`. So counting only the primes up to `y` lowers `ω n` by less than `β`. -/
theorem card_primeFactors_above_cut_lt (x β : ℝ) (n : ℕ) (hβ : 0 < β) (hn : (n : ℝ) ≤ x) :
    ((n.primeFactors.filter (fun p : ℕ ↦ x ^ (1 / β) < (p : ℝ))).card : ℝ) < β := by
  set s := n.primeFactors.filter (fun p : ℕ ↦ x ^ (1 / β) < (p : ℝ)) with hs
  by_contra hcon
  push Not at hcon
  have hn0 : n ≠ 0 := by
    rintro rfl
    simp [hs] at hcon
    linarith
  have hx1 : 1 ≤ x := le_trans (by exact_mod_cast Nat.one_le_iff_ne_zero.mpr hn0) hn
  have hdvd : (∏ p ∈ s, p) ∣ n := by
    refine dvd_trans (Finset.prod_dvd_prod_of_subset _ _ id (Finset.filter_subset _ _)) ?_
    exact Nat.prod_primeFactors_dvd n
  have hle : ((∏ p ∈ s, p : ℕ) : ℝ) ≤ x :=
    le_trans (by exact_mod_cast Nat.le_of_dvd (Nat.pos_of_ne_zero hn0) hdvd) hn
  have hy0 : 0 < x ^ (1 / β) := Real.rpow_pos_of_pos (by linarith) _
  have hne : s.Nonempty := by
    rw [Finset.nonempty_iff_ne_empty]
    rintro h
    rw [h] at hcon
    simp at hcon
    linarith
  have hlt : (x ^ (1 / β)) ^ s.card < ((∏ p ∈ s, p : ℕ) : ℝ) := by
    push_cast
    rw [← Finset.prod_const]
    obtain ⟨i0, hi0⟩ := hne
    apply Finset.prod_lt_prod₀
    · intro i _; exact hy0
    · intro i hi
      exact ((Finset.mem_filter.mp hi).2).le
    · exact ⟨i0, hi0, (Finset.mem_filter.mp hi0).2⟩
  have hge : x ≤ (x ^ (1 / β)) ^ s.card := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul (by linarith)]
    calc x = x ^ (1:ℝ) := (Real.rpow_one x).symm
      _ ≤ x ^ (1 / β * s.card) := by
        apply Real.rpow_le_rpow_of_exponent_le hx1
        rw [div_mul_eq_mul_div, one_mul, le_div_iff₀ hβ]
        linarith
  linarith

/-- **Exactly `⌊x/d⌋` numbers up to `x` are divisible by `d` (Step 2).** Among the whole numbers
`1, 2, ..., x`, the number of multiples of `d` is `x / d` rounded down. -/
theorem card_multiples_le (x d : ℕ) :
    #{n ∈ Icc 1 x | d ∣ n} = x / d := by
  rw [← Nat.Ioc_filter_dvd_card_eq_div]
  rfl

/-! The card's worked whole-number examples. -/

-- 999,999 = 3^3 × 7 × 11 × 13 × 37 has 5 different primes.
example : ω 999999 = 5 := by
  simp [ArithmeticFunction.cardDistinctFactors_apply, Nat.primeFactorsList_ofNat]

-- 1,000,000 = 2^6 × 5^6 has only 2.
example : ω 1000000 = 2 := by
  simp [ArithmeticFunction.cardDistinctFactors_apply, Nat.primeFactorsList_ofNat]

-- 510,510 = 2 × 3 × 5 × 7 × 11 × 13 × 17 has 7.
example : ω 510510 = 7 := by
  simp [ArithmeticFunction.cardDistinctFactors_apply, Nat.primeFactorsList_ofNat]

-- The number 1 has no prime factor: the true count at omega = 0 is 1.
example : ω 1 = 0 := by simp

-- No n up to a million has three primes above 100: 101^3 = 1,030,301 > 1,000,000.
example : (101 : ℕ) ^ 3 = 1030301 ∧ 1000000 < 101 ^ 3 := by norm_num

-- There are 25 primes up to 100.
example : #{p ∈ range 101 | p.Prime} = 25 := by decide

#print axioms erdos_kac
#print axioms card_primeFactors_above_cut_lt
#print axioms card_multiples_le
