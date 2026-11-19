-- Typical numbers have about log log n distinct prime factors: almost every n has close to log log n different prime factors, and the same holds when repeats are counted.
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.Chebyshev
import Mathlib.NumberTheory.Harmonic.Bounds
import Mathlib.Algebra.Order.Field.GeomSum
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Simproc.Factors

open Filter Topology ArithmeticFunction
open scoped ArithmeticFunction.omega ArithmeticFunction.Omega

theorem hr_primeFactors_eq_filter (x n : ℕ) (hn : n ∈ Finset.Icc 1 x) :
    n.primeFactors = ((Finset.Iic x).filter Nat.Prime).filter (· ∣ n) := by
  ext p
  simp only [Finset.mem_Icc] at hn
  simp only [Nat.mem_primeFactors, Finset.mem_filter, Finset.mem_Iic]
  constructor
  · rintro ⟨hp, hpn, hn0⟩
    exact ⟨⟨(Nat.le_of_dvd (by omega) hpn).trans hn.2, hp⟩, hpn⟩
  · rintro ⟨⟨_, hp⟩, hpn⟩
    exact ⟨hp, hpn, by omega⟩
#print axioms hr_primeFactors_eq_filter

theorem hr_omega_eq_sum (x n : ℕ) (hn : n ∈ Finset.Icc 1 x) :
    (ω n : ℝ) = ∑ p ∈ (Finset.Iic x).filter Nat.Prime, if p ∣ n then (1 : ℝ) else 0 := by
  rw [Finset.sum_boole, cardDistinctFactors_apply, ← List.card_toFinset,
    ← hr_primeFactors_eq_filter x n hn]
  rfl
#print axioms hr_omega_eq_sum

theorem hr_card_dvd (x p : ℕ) : ((Finset.Icc 1 x).filter (p ∣ ·)).card = x / p := by
  rw [← Nat.Ioc_filter_dvd_card_eq_div]
  rfl
#print axioms hr_card_dvd

theorem hr_primeCounting_eq (x : ℕ) :
    ((Finset.Iic x).filter Nat.Prime).card = Nat.primeCounting x := by
  rw [Nat.primeCounting, ← Nat.primesBelow_card_eq_primeCounting']
  congr 1
  ext p; simp [Nat.primesBelow]
#print axioms hr_primeCounting_eq

theorem hr_div_ge (x p : ℕ) (hp : 0 < p) : (x : ℝ) / p - 1 ≤ ((x / p : ℕ) : ℝ) := by
  have h1 := Nat.div_add_mod x p
  have h2 := Nat.mod_lt x hp
  have hp' : (0 : ℝ) < p := by exact_mod_cast hp
  rw [div_sub_one hp'.ne', div_le_iff₀ hp']
  have : (x : ℝ) = p * ((x / p : ℕ) : ℝ) + ((x % p : ℕ) : ℝ) := by exact_mod_cast h1.symm
  have h3 : ((x % p : ℕ) : ℝ) < p := by exact_mod_cast h2
  nlinarith
#print axioms hr_div_ge

theorem hr_sum_omega_ge (x : ℕ) :
    (x : ℝ) * (∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p) - Nat.primeCounting x ≤
      ∑ n ∈ Finset.Icc 1 x, (ω n : ℝ) := by
  rw [Finset.sum_congr rfl (fun n hn => hr_omega_eq_sum x n hn), Finset.sum_comm,
    ← hr_primeCounting_eq, Finset.mul_sum]
  have : (((Finset.Iic x).filter Nat.Prime).card : ℝ) =
      ∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) := by simp
  rw [this, ← Finset.sum_sub_distrib]
  apply Finset.sum_le_sum
  intro p hp
  have hp' : p.Prime := (Finset.mem_filter.mp hp).2
  rw [Finset.sum_boole, hr_card_dvd]
  have := hr_div_ge x p hp'.pos
  rw [mul_one_div]
  exact this
#print axioms hr_sum_omega_ge

theorem hr_sum_omega_sq_le (x : ℕ) :
    ∑ n ∈ Finset.Icc 1 x, (ω n : ℝ) ^ 2 ≤
      (x : ℝ) * (∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p) +
      (x : ℝ) * (∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p) ^ 2 := by
  set P := (Finset.Iic x).filter Nat.Prime with hP
  rw [Finset.sum_congr rfl (fun n hn => by rw [hr_omega_eq_sum x n hn])]
  simp_rw [sq, Finset.sum_mul_sum]
  rw [Finset.sum_comm]
  simp_rw [Finset.sum_comm (s := Finset.Icc 1 x)]
  have key : ∀ p ∈ P, ∀ q ∈ P,
      ∑ n ∈ Finset.Icc 1 x, ((if p ∣ n then (1 : ℝ) else 0) * if q ∣ n then (1 : ℝ) else 0) ≤
        (if p = q then (x : ℝ) * (1 / p) else 0) + (x : ℝ) * ((1 / p) * (1 / q)) := by
    intro p hp q hq
    have hp' : p.Prime := (Finset.mem_filter.mp hp).2
    have hq' : q.Prime := (Finset.mem_filter.mp hq).2
    simp_rw [ite_zero_mul_ite_zero, mul_one]
    rw [Finset.sum_boole]
    by_cases hpq : p = q
    · subst hpq
      simp only [and_self, ite_true]
      rw [hr_card_dvd]
      have h1 : ((x / p : ℕ) : ℝ) ≤ (x : ℝ) / p := Nat.cast_div_le
      have h2 : 0 ≤ (x : ℝ) * ((1 / p) * (1 / p)) := by positivity
      rw [mul_one_div]; linarith
    · rw [if_neg hpq, zero_add]
      have hfilt : (Finset.Icc 1 x).filter (fun n => p ∣ n ∧ q ∣ n) =
          (Finset.Icc 1 x).filter (fun n => p * q ∣ n) := by
        apply Finset.filter_congr
        intro n _
        constructor
        · rintro ⟨h1, h2⟩
          exact Nat.Coprime.mul_dvd_of_dvd_of_dvd ((Nat.coprime_primes hp' hq').mpr hpq) h1 h2
        · intro h
          exact ⟨dvd_trans (dvd_mul_right p q) h, dvd_trans (dvd_mul_left q p) h⟩
      rw [hfilt, hr_card_dvd]
      have h1 : ((x / (p * q) : ℕ) : ℝ) ≤ (x : ℝ) / ((p * q : ℕ) : ℝ) := Nat.cast_div_le
      rw [Nat.cast_mul] at h1
      calc ((x / (p * q) : ℕ) : ℝ) ≤ (x : ℝ) / ((p : ℝ) * q) := h1
        _ = (x : ℝ) * ((1 / p) * (1 / q)) := by field_simp
  calc ∑ p ∈ P, ∑ q ∈ P, ∑ n ∈ Finset.Icc 1 x,
        ((if p ∣ n then (1 : ℝ) else 0) * if q ∣ n then (1 : ℝ) else 0)
      ≤ ∑ p ∈ P, ∑ q ∈ P,
        ((if p = q then (x : ℝ) * (1 / p) else 0) + (x : ℝ) * ((1 / p) * (1 / q))) :=
        Finset.sum_le_sum fun p hp => Finset.sum_le_sum fun q hq => key p hp q hq
    _ = _ := by
        rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun p hp => ?_
        rw [Finset.sum_add_distrib, Finset.sum_ite_eq, if_pos hp, Finset.mul_sum]
#print axioms hr_sum_omega_sq_le

theorem hr_turan (x : ℕ) (hL : 0 < Real.log (Real.log x)) :
    (1 / (x : ℝ)) * ∑ n ∈ Finset.Icc 1 x, ((ω n : ℝ) - Real.log (Real.log x)) ^ 2 ≤
      (∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p)
        + ((∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p) - Real.log (Real.log x)) ^ 2
        + 2 * Real.log (Real.log x) * (Nat.primeCounting x : ℝ) / x := by
  set L := Real.log (Real.log x) with hLdef
  set S := ∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p with hS
  have hx : (0 : ℝ) < x := by
    rcases Nat.eq_zero_or_pos x with h | h
    · subst h; simp [hLdef] at hL
    · exact_mod_cast h
  have h1 := hr_sum_omega_ge x
  have h2 := hr_sum_omega_sq_le x
  rw [← hS] at h1 h2
  have hexp : ∑ n ∈ Finset.Icc 1 x, ((ω n : ℝ) - L) ^ 2 =
      ∑ n ∈ Finset.Icc 1 x, (ω n : ℝ) ^ 2 - 2 * L * ∑ n ∈ Finset.Icc 1 x, (ω n : ℝ)
        + x * L ^ 2 := by
    simp only [sub_sq, Finset.sum_add_distrib, Finset.sum_sub_distrib, Finset.sum_const,
      Nat.card_Icc, nsmul_eq_mul]
    rw [Finset.mul_sum, Nat.add_sub_cancel]
    congr 2
    exact Finset.sum_congr rfl fun n _ => by ring
  have h3 : 2 * L * ((x : ℝ) * S - Nat.primeCounting x) ≤
      2 * L * ∑ n ∈ Finset.Icc 1 x, (ω n : ℝ) :=
    mul_le_mul_of_nonneg_left h1 (by positivity)
  rw [hexp, one_div_mul_eq_div, div_le_iff₀ hx]
  have : (S + (S - L) ^ 2 + 2 * L * (Nat.primeCounting x : ℝ) / x) * x =
      x * S + x * S ^ 2 - 2 * L * (x * S - Nat.primeCounting x) + x * L ^ 2 := by
    field_simp
    ring
  rw [this]
  linarith
#print axioms hr_turan

theorem hr_sum_primes_succ (f : ℕ → ℝ) (N : ℕ) :
    ∑ p ∈ (Finset.Iic (N + 1)).filter Nat.Prime, f p =
      ∑ p ∈ (Finset.Iic N).filter Nat.Prime, f p + if (N + 1).Prime then f (N + 1) else 0 := by
  rw [← Nat.range_succ_eq_Iic, ← Nat.range_succ_eq_Iic, Finset.range_add_one, Finset.filter_insert]
  split_ifs with h
  · rw [Finset.sum_insert (by simp), add_comm]
  · simp
#print axioms hr_sum_primes_succ

theorem hr_log_ge (N n : ℕ) (hn : n ∈ Finset.Icc 1 N) :
    ∑ p ∈ (Finset.Iic N).filter Nat.Prime, (if p ∣ n then Real.log p else 0) ≤ Real.log n := by
  rw [← Finset.sum_filter, ← hr_primeFactors_eq_filter N n hn]
  have hn0 : n ≠ 0 := by simp at hn; omega
  rw [← Real.log_prod (fun p hp => by
    have := (Nat.prime_of_mem_primeFactors hp).pos
    positivity)]
  apply Real.log_le_log
  · apply Finset.prod_pos
    intro p hp
    exact_mod_cast (Nat.prime_of_mem_primeFactors hp).pos
  · rw [← Nat.cast_prod]
    exact_mod_cast Nat.le_of_dvd (Nat.pos_of_ne_zero hn0) (Nat.prod_primeFactors_dvd n)
#print axioms hr_log_ge

theorem hr_theta_le (N : ℕ) :
    ∑ p ∈ (Finset.Iic N).filter Nat.Prime, Real.log p ≤ N * Real.log 4 := by
  have := Chebyshev.theta_le_log4_mul_x (x := (N : ℝ)) (Nat.cast_nonneg N)
  rw [Chebyshev.theta, Nat.floor_natCast] at this
  have hs : (Finset.Ioc 0 N).filter Nat.Prime = (Finset.Iic N).filter Nat.Prime := by
    ext p
    simp only [Finset.mem_filter, Finset.mem_Ioc, Finset.mem_Iic]
    constructor
    · rintro ⟨⟨_, h⟩, hp⟩; exact ⟨h, hp⟩
    · rintro ⟨h, hp⟩; exact ⟨⟨hp.pos, h⟩, hp⟩
  rw [hs] at this
  linarith
#print axioms hr_theta_le

/-- Mertens' first theorem, upper half. -/
theorem hr_mertens_one (N : ℕ) (hN : 1 ≤ N) :
    ∑ p ∈ (Finset.Iic N).filter Nat.Prime, Real.log p / p ≤ Real.log N + Real.log 4 := by
  set P := (Finset.Iic N).filter Nat.Prime with hP
  have hNpos : (0 : ℝ) < N := by exact_mod_cast hN
  -- sum of log n over n ≤ N is at most N log N
  have hup : ∑ n ∈ Finset.Icc 1 N, Real.log n ≤ N * Real.log N := by
    calc ∑ n ∈ Finset.Icc 1 N, Real.log n ≤ ∑ n ∈ Finset.Icc 1 N, Real.log N := by
          apply Finset.sum_le_sum
          intro n hn
          simp only [Finset.mem_Icc] at hn
          apply Real.log_le_log (by exact_mod_cast hn.1) (by exact_mod_cast hn.2)
      _ = N * Real.log N := by simp
  have hlow : ∑ p ∈ P, Real.log p * ((N / p : ℕ) : ℝ) ≤ ∑ n ∈ Finset.Icc 1 N, Real.log n := by
    calc ∑ p ∈ P, Real.log p * ((N / p : ℕ) : ℝ)
        = ∑ n ∈ Finset.Icc 1 N, ∑ p ∈ P, (if p ∣ n then Real.log p else 0) := by
          rw [Finset.sum_comm]
          refine Finset.sum_congr rfl fun p _ => ?_
          rw [← Finset.sum_filter, Finset.sum_const, hr_card_dvd, nsmul_eq_mul, mul_comm]
      _ ≤ _ := Finset.sum_le_sum fun n hn => hr_log_ge N n hn
  have hmid : (N : ℝ) * ∑ p ∈ P, Real.log p / p - ∑ p ∈ P, Real.log p ≤
      ∑ p ∈ P, Real.log p * ((N / p : ℕ) : ℝ) := by
    rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
    apply Finset.sum_le_sum
    intro p hp
    have hp' : p.Prime := (Finset.mem_filter.mp hp).2
    have h1 := hr_div_ge N p hp'.pos
    have h2 : 0 ≤ Real.log p := Real.log_natCast_nonneg p
    calc (N : ℝ) * (Real.log p / p) - Real.log p = Real.log p * ((N : ℝ) / p - 1) := by ring
      _ ≤ _ := mul_le_mul_of_nonneg_left h1 h2
  have hth := hr_theta_le N
  rw [← hP] at hth
  have : (N : ℝ) * ∑ p ∈ P, Real.log p / p ≤ N * (Real.log N + Real.log 4) := by
    nlinarith
  exact le_of_mul_le_mul_left this hNpos
#print axioms hr_mertens_one

/-- Mertens' second theorem, upper half: the sum of `1/p` over primes `p ≤ N` is at most
`log log N` plus a constant. -/
theorem hr_mertens_two_upper : ∃ K : ℝ, ∀ N : ℕ, 2 ≤ N →
    ∑ p ∈ (Finset.Iic N).filter Nat.Prime, (1 : ℝ) / p ≤ Real.log (Real.log N) + K := by
  set C := Real.log 4
  let S : ℕ → ℝ := fun N => ∑ p ∈ (Finset.Iic N).filter Nat.Prime, (1 : ℝ) / p
  let M : ℕ → ℝ := fun N => ∑ p ∈ (Finset.Iic N).filter Nat.Prime, Real.log p / p
  let F : ℕ → ℝ := fun N => S N - (M N - C) / Real.log N
  have hF : ∀ N : ℕ, 2 ≤ N → F N ≤ Real.log (Real.log N) + (F 2 - Real.log (Real.log 2)) := by
    intro N hN
    induction N, hN using Nat.le_induction with
    | base => simp
    | succ N hN ih =>
      have hu : 0 < Real.log N := Real.log_pos (by exact_mod_cast (by omega : 1 < N))
      have huv : Real.log N < Real.log (N + 1 : ℕ) :=
        Real.log_lt_log (by positivity) (by push_cast; linarith)
      have hv : 0 < Real.log (N + 1 : ℕ) := hu.trans huv
      have hstep : F (N + 1) - F N =
          (M N - C) * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) := by
        simp only [F, S, M]
        rw [hr_sum_primes_succ, hr_sum_primes_succ]
        split_ifs
        · field_simp
          ring
        · field_simp
          ring
      have hMC : M N - C ≤ Real.log N := by
        have := hr_mertens_one N (by omega)
        simp only [M, C]
        linarith
      have hd : 0 ≤ 1 / Real.log N - 1 / Real.log (N + 1 : ℕ) := by
        rw [sub_nonneg]
        exact one_div_le_one_div_of_le hu huv.le
      have h1 : (M N - C) * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) ≤
          Real.log N * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) :=
        mul_le_mul_of_nonneg_right hMC hd
      have h2 : Real.log N * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ)) ≤
          Real.log (Real.log (N + 1 : ℕ)) - Real.log (Real.log N) := by
        have := Real.one_sub_inv_le_log_of_pos (div_pos hv hu)
        rw [Real.log_div hv.ne' hu.ne', inv_div] at this
        calc Real.log N * (1 / Real.log N - 1 / Real.log (N + 1 : ℕ))
            = 1 - Real.log N / Real.log (N + 1 : ℕ) := by field_simp
          _ ≤ _ := this
      linarith
  refine ⟨F 2 - Real.log (Real.log 2) + 1, fun N hN => ?_⟩
  have h := hF N hN
  have hu : 0 < Real.log N := Real.log_pos (by exact_mod_cast (by omega : 1 < N))
  have hMC : (M N - C) / Real.log N ≤ 1 := by
    rw [div_le_one hu]
    have := hr_mertens_one N (by omega)
    simp only [M, C]
    linarith
  have : S N = F N + (M N - C) / Real.log N := by simp only [F]; ring
  show S N ≤ _
  linarith
#print axioms hr_mertens_two_upper

theorem hr_telescope (N : ℕ) :
    ∑ m ∈ Finset.Ioc 1 N, (1 / ((m : ℝ) - 1) - 1 / m) ≤ 1 := by
  have key : ∀ N : ℕ, 1 ≤ N → ∑ m ∈ Finset.Ioc 1 N, (1 / ((m : ℝ) - 1) - 1 / m) = 1 - 1 / N := by
    intro N hN
    induction N, hN using Nat.le_induction with
    | base => simp
    | succ N hN ih =>
      rw [Finset.sum_Ioc_succ_top hN, ih]
      have : (N : ℝ) ≠ 0 := by positivity
      push_cast
      rw [add_sub_cancel_right]
      ring
  rcases Nat.eq_zero_or_pos N with h | h
  · subst h; simp
  · rw [key N h]
    have : (0 : ℝ) ≤ 1 / N := by positivity
    linarith
#print axioms hr_telescope

theorem hr_sum_inv_sub_one_le (N : ℕ) :
    ∑ p ∈ (Finset.Iic N).filter Nat.Prime, (1 : ℝ) / ((p : ℝ) - 1) ≤
      ∑ p ∈ (Finset.Iic N).filter Nat.Prime, (1 : ℝ) / p + 1 := by
  have hsub : (Finset.Iic N).filter Nat.Prime ⊆ Finset.Ioc 1 N := by
    intro p hp
    simp only [Finset.mem_filter, Finset.mem_Iic] at hp
    simp only [Finset.mem_Ioc]
    exact ⟨hp.2.one_lt, hp.1⟩
  have h1 : ∑ p ∈ (Finset.Iic N).filter Nat.Prime, (1 / ((p : ℝ) - 1) - 1 / p) ≤
      ∑ m ∈ Finset.Ioc 1 N, (1 / ((m : ℝ) - 1) - 1 / m) := by
    apply Finset.sum_le_sum_of_subset_of_nonneg hsub
    intro m hm _
    simp only [Finset.mem_Ioc] at hm
    have h2 : (2 : ℝ) ≤ m := by exact_mod_cast hm.1
    rw [sub_nonneg]
    apply one_div_le_one_div_of_le (by linarith) (by linarith)
  rw [Finset.sum_sub_distrib] at h1
  linarith [hr_telescope N]
#print axioms hr_sum_inv_sub_one_le

theorem hr_harmonic_le_prod (N : ℕ) :
    ∑ n ∈ Finset.Icc 1 N, (1 : ℝ) / n ≤
      ∏ p ∈ (Finset.Iic N).filter Nat.Prime, ∑ k ∈ Finset.range (N + 1), ((1 : ℝ) / p) ^ k := by
  classical
  set P := (Finset.Iic N).filter Nat.Prime with hP
  rw [Finset.prod_sum]
  set φ : ℕ → ((a : ℕ) → a ∈ P → ℕ) := fun n a _ => n.factorization a with hφ
  set g : ((a : ℕ) → a ∈ P → ℕ) → ℝ :=
    fun e => ∏ x ∈ P.attach, ((1 : ℝ) / x.1) ^ (e x.1 x.2) with hg
  have hval : ∀ n ∈ Finset.Icc 1 N, g (φ n) = 1 / n := by
    intro n hn
    have hn0 : n ≠ 0 := by simp at hn; omega
    simp only [hg, hφ]
    rw [Finset.prod_attach P (fun a => ((1 : ℝ) / a) ^ (n.factorization a))]
    simp_rw [div_pow, one_pow]
    rw [Finset.prod_div_distrib, Finset.prod_const_one]
    congr 1
    have h1 : ∏ a ∈ P, ((a : ℝ) ^ (n.factorization a)) =
        ((∏ a ∈ P, a ^ (n.factorization a) : ℕ) : ℝ) := by push_cast; rfl
    rw [h1]
    congr 1
    have h2 : n.primeFactors ⊆ P := by
      rw [hr_primeFactors_eq_filter N n hn]; exact Finset.filter_subset _ _
    rw [← Finset.prod_subset h2 (fun p _ hp => by
      rw [Nat.factorization_eq_zero_of_not_dvd (fun h => hp (by
        rw [Nat.mem_primeFactors]; exact ⟨(Finset.mem_filter.mp ‹p ∈ P›).2, h, hn0⟩)), pow_zero])]
    exact Nat.prod_factorization_pow_eq_self hn0
  have hinj : Set.InjOn φ (Finset.Icc 1 N : Set ℕ) := by
    intro n hn m hm hnm
    have hn0 : n ≠ 0 := by simp at hn; omega
    have hm0 : m ≠ 0 := by simp at hm; omega
    apply Nat.eq_of_factorization_eq hn0 hm0
    intro p
    by_cases hpP : p ∈ P
    · exact congr_fun (congr_fun hnm p) hpP
    · by_cases hp : p.Prime
      · have hpN : N < p := by
          by_contra h
          exact hpP (Finset.mem_filter.mpr ⟨Finset.mem_Iic.mpr (by omega), hp⟩)
        simp only [Finset.coe_Icc, Set.mem_Icc] at hn hm
        rw [Nat.factorization_eq_zero_of_not_dvd (fun h => by
              have := Nat.le_of_dvd (by omega) h; omega),
            Nat.factorization_eq_zero_of_not_dvd (fun h => by
              have := Nat.le_of_dvd (by omega) h; omega)]
      · simp [Nat.factorization_eq_zero_of_not_prime _ hp]
  have hmaps : ∀ n ∈ Finset.Icc 1 N, φ n ∈ P.pi (fun _ => Finset.range (N + 1)) := by
    intro n hn
    have hn0 : n ≠ 0 := by simp at hn; omega
    rw [Finset.mem_pi]
    intro a _
    simp only [Finset.mem_range, hφ]
    have := Nat.factorization_lt a hn0
    simp at hn
    omega
  calc ∑ n ∈ Finset.Icc 1 N, (1 : ℝ) / n = ∑ n ∈ Finset.Icc 1 N, g (φ n) :=
        Finset.sum_congr rfl fun n hn => (hval n hn).symm
    _ = ∑ e ∈ (Finset.Icc 1 N).image φ, g e := (Finset.sum_image hinj).symm
    _ ≤ ∑ e ∈ P.pi (fun _ => Finset.range (N + 1)), g e := by
        apply Finset.sum_le_sum_of_subset_of_nonneg
        · intro e he
          obtain ⟨n, hn, rfl⟩ := Finset.mem_image.mp he
          exact hmaps n hn
        · intro e _ _
          apply Finset.prod_nonneg
          intro x _
          positivity
#print axioms hr_harmonic_le_prod

/-- Mertens' second theorem, lower half: `log log N ≤ (sum of 1/p over p ≤ N) + 1`. -/
theorem hr_mertens_two_lower (N : ℕ) (hN : 2 ≤ N) :
    Real.log (Real.log N) ≤ ∑ p ∈ (Finset.Iic N).filter Nat.Prime, (1 : ℝ) / p + 1 := by
  set P := (Finset.Iic N).filter Nat.Prime with hP
  have hlogN : 0 < Real.log N := Real.log_pos (by exact_mod_cast (by omega : 1 < N))
  have h1 : Real.log (N + 1 : ℕ) ≤ ∑ n ∈ Finset.Icc 1 N, (1 : ℝ) / n := by
    have := log_add_one_le_harmonic N
    rw [harmonic_eq_sum_Icc] at this
    push_cast at this
    simpa [one_div] using this
  have hr : ∀ p ∈ P, ∑ k ∈ Finset.range (N + 1), ((1 : ℝ) / p) ^ k ≤ 1 / (1 - 1 / (p : ℝ)) := by
    intro p hp
    have hp2 : (2 : ℝ) ≤ p := by exact_mod_cast (Finset.mem_filter.mp hp).2.two_le
    have := geom_sum_Ico_le_of_lt_one (x := (1 : ℝ) / p) (m := 0) (n := N + 1) (by positivity)
      (by rw [div_lt_one (by linarith)]; linarith)
    rw [Finset.range_eq_Ico]
    simpa using this
  have hrpos : ∀ p ∈ P, 0 < 1 / (1 - 1 / (p : ℝ)) := by
    intro p hp
    have hp2 : (2 : ℝ) ≤ p := by exact_mod_cast (Finset.mem_filter.mp hp).2.two_le
    have : 1 / (p : ℝ) < 1 := by rw [div_lt_one (by linarith)]; linarith
    apply div_pos one_pos; linarith
  have h2 := hr_harmonic_le_prod N
  rw [← hP] at h2
  have h3 : ∏ p ∈ P, ∑ k ∈ Finset.range (N + 1), ((1 : ℝ) / p) ^ k ≤
      ∏ p ∈ P, 1 / (1 - 1 / (p : ℝ)) :=
    Finset.prod_le_prod₀ (fun p _ => Finset.sum_nonneg fun k _ => by positivity) hr
  have hNpos : (0 : ℝ) < Real.log (N + 1 : ℕ) :=
    Real.log_pos (by exact_mod_cast (by omega : 1 < N + 1))
  have h4 : Real.log (∏ p ∈ P, 1 / (1 - 1 / (p : ℝ))) ≤ ∑ p ∈ P, (1 : ℝ) / ((p : ℝ) - 1) := by
    rw [Real.log_prod (fun p hp => (hrpos p hp).ne')]
    apply Finset.sum_le_sum
    intro p hp
    have hp2 : (2 : ℝ) ≤ p := by exact_mod_cast (Finset.mem_filter.mp hp).2.two_le
    calc Real.log (1 / (1 - 1 / (p : ℝ))) ≤ 1 / (1 - 1 / (p : ℝ)) - 1 :=
          Real.log_le_sub_one_of_pos (hrpos p hp)
      _ = 1 / ((p : ℝ) - 1) := by
          have : (p : ℝ) - 1 ≠ 0 := by linarith
          have : (p : ℝ) ≠ 0 := by linarith
          field_simp
          ring
  have h5 := hr_sum_inv_sub_one_le N
  rw [← hP] at h5
  calc Real.log (Real.log N) ≤ Real.log (Real.log (N + 1 : ℕ)) := by
        apply Real.log_le_log hlogN
        apply Real.log_le_log (by positivity)
        push_cast; linarith
    _ ≤ Real.log (∏ p ∈ P, 1 / (1 - 1 / (p : ℝ))) := by
        apply Real.log_le_log hNpos
        linarith
    _ ≤ _ := by linarith
#print axioms hr_mertens_two_lower

theorem hr_primeCounting_le (x : ℕ) : (Nat.primeCounting x : ℝ) ≤ x := by
  rw [← hr_primeCounting_eq]
  have : (Finset.Iic x).filter Nat.Prime ⊆ Finset.Ioc 0 x := by
    intro p hp
    simp only [Finset.mem_filter, Finset.mem_Iic] at hp
    simp only [Finset.mem_Ioc]
    exact ⟨hp.2.pos, hp.1⟩
  have := Finset.card_le_card this
  rw [Nat.card_Ioc, Nat.sub_zero] at this
  exact_mod_cast this
#print axioms hr_primeCounting_le

/-- For `√x < n ≤ x`, `log log n` lies within `log 2` below `log log x`. -/
theorem hr_loglog_close (x n : ℕ) (hx : 2 ≤ x) (hn : n ≤ x) (hnn : x < n * n) :
    Real.log (Real.log x) - Real.log 2 < Real.log (Real.log n) ∧
      Real.log (Real.log n) ≤ Real.log (Real.log x) := by
  have hn2 : 2 ≤ n := by nlinarith
  have hlx : 0 < Real.log x := Real.log_pos (by exact_mod_cast (by omega : 1 < x))
  have hln : 0 < Real.log n := Real.log_pos (by exact_mod_cast (by omega : 1 < n))
  have h1 : Real.log x < 2 * Real.log n := by
    rw [← Real.log_rpow (by positivity)]
    apply Real.log_lt_log (by positivity)
    have : ((x : ℕ) : ℝ) < ((n * n : ℕ) : ℝ) := by exact_mod_cast hnn
    push_cast at this
    rw [show (n : ℝ) ^ (2 : ℝ) = n * n by norm_num [sq]]
    exact this
  constructor
  · rw [← Real.log_div hlx.ne' (by norm_num)]
    apply Real.log_lt_log (by positivity)
    linarith
  · apply Real.log_le_log hln
    apply Real.log_le_log (by positivity)
    exact_mod_cast hn
#print axioms hr_loglog_close

theorem hr_tendsto_loglog :
    Tendsto (fun x : ℕ => Real.log (Real.log x)) atTop atTop :=
  Real.tendsto_log_atTop.comp (Real.tendsto_log_atTop.comp tendsto_natCast_atTop_atTop)
#print axioms hr_tendsto_loglog

theorem hr_tendsto_inv_sqrt :
    Tendsto (fun x : ℕ => 1 / Real.sqrt x) atTop (𝓝 0) := by
  simp_rw [one_div]
  exact tendsto_inv_atTop_zero.comp (Real.tendsto_sqrt_atTop.comp tendsto_natCast_atTop_atTop)
#print axioms hr_tendsto_inv_sqrt

theorem hr_sqrt_div_le (x : ℕ) (hx : 1 ≤ x) : (Nat.sqrt x : ℝ) / x ≤ 1 / Real.sqrt x := by
  have hxpos : (0 : ℝ) < x := by exact_mod_cast hx
  have hs : 0 < Real.sqrt x := Real.sqrt_pos.mpr hxpos
  calc (Nat.sqrt x : ℝ) / x ≤ Real.sqrt x / x := by
        gcongr; exact Real.nat_sqrt_le_real_sqrt
    _ = 1 / Real.sqrt x := by
        rw [div_eq_div_iff hxpos.ne' hs.ne', one_mul, Real.mul_self_sqrt hxpos.le]
#print axioms hr_sqrt_div_le

theorem hr_card_small (x : ℕ) :
    ((Finset.Icc 1 x).filter (fun n => n * n ≤ x)).card ≤ Nat.sqrt x := by
  have : (Finset.Icc 1 x).filter (fun n => n * n ≤ x) ⊆ Finset.Icc 1 (Nat.sqrt x) := by
    intro n hn
    simp only [Finset.mem_filter, Finset.mem_Icc] at hn
    simp only [Finset.mem_Icc]
    exact ⟨hn.1.1, Nat.le_sqrt.mpr hn.2⟩
  calc _ ≤ (Finset.Icc 1 (Nat.sqrt x)).card := Finset.card_le_card this
    _ = Nat.sqrt x := by simp
#print axioms hr_card_small

/-- Markov's inequality on a finite set: the number of points where `f ≥ c > 0` is at most
the sum of `f` divided by `c`. -/
theorem hr_markov (s : Finset ℕ) (f : ℕ → ℝ) (hf : ∀ n ∈ s, 0 ≤ f n) (c : ℝ) (hc : 0 < c) :
    ((s.filter (fun n => c ≤ f n)).card : ℝ) ≤ (∑ n ∈ s, f n) / c := by
  rw [le_div_iff₀ hc]
  calc ((s.filter (fun n => c ≤ f n)).card : ℝ) * c = ∑ n ∈ s.filter (fun n => c ≤ f n), c := by
        simp
    _ ≤ ∑ n ∈ s.filter (fun n => c ≤ f n), f n :=
        Finset.sum_le_sum fun n hn => (Finset.mem_filter.mp hn).2
    _ ≤ ∑ n ∈ s, f n :=
        Finset.sum_le_sum_of_subset_of_nonneg (Finset.filter_subset _ _)
          fun n hn _ => hf n hn
#print axioms hr_markov

theorem hr_omega_le_Omega (n : ℕ) : ω n ≤ Ω n := by
  rw [cardDistinctFactors_apply, cardFactors_apply]
  exact (List.dedup_sublist _).length_le
#print axioms hr_omega_le_Omega

theorem hr_Omega_le (x n : ℕ) (hn : n ∈ Finset.Icc 1 x) :
    Ω n ≤ ω n + ∑ p ∈ (Finset.Iic x).filter Nat.Prime,
      ((Finset.Icc 2 x).filter (fun k => p ^ k ∣ n)).card := by
  have hn0 : n ≠ 0 := by simp at hn; omega
  have hnx : n ≤ x := (Finset.mem_Icc.mp hn).2
  have hΩ : Ω n = ∑ p ∈ n.primeFactors, n.factorization p := by
    rw [cardFactors_eq_sum_factorization, Finsupp.sum]; rfl
  have hω : ω n = ∑ p ∈ n.primeFactors, 1 := by
    rw [cardDistinctFactors_apply, ← List.card_toFinset, Finset.card_eq_sum_ones]; rfl
  have hsub : n.primeFactors ⊆ (Finset.Iic x).filter Nat.Prime := by
    rw [hr_primeFactors_eq_filter x n hn]; exact Finset.filter_subset _ _
  rw [hΩ, hω]
  calc ∑ p ∈ n.primeFactors, n.factorization p
      ≤ ∑ p ∈ n.primeFactors, (1 + ((Finset.Icc 2 x).filter (fun k => p ^ k ∣ n)).card) := by
        apply Finset.sum_le_sum
        intro p hp
        have h1 : Finset.Icc 2 (n.factorization p) ⊆
            (Finset.Icc 2 x).filter (fun k => p ^ k ∣ n) := by
          intro k hk
          rw [Finset.mem_Icc] at hk
          have := Nat.factorization_lt p hn0
          rw [Finset.mem_filter, Finset.mem_Icc]
          exact ⟨⟨hk.1, by omega⟩,
            (Nat.pow_dvd_pow p hk.2).trans (Nat.ordProj_dvd n p)⟩
        have h2 := Finset.card_le_card h1
        rw [Nat.card_Icc] at h2
        omega
    _ = ∑ p ∈ n.primeFactors, 1 +
          ∑ p ∈ n.primeFactors, ((Finset.Icc 2 x).filter (fun k => p ^ k ∣ n)).card :=
        Finset.sum_add_distrib
    _ ≤ _ := by
        gcongr
#print axioms hr_Omega_le

theorem hr_sum_Omega_sub (x : ℕ) :
    ∑ n ∈ Finset.Icc 1 x, ((Ω n : ℝ) - ω n) ≤ x := by
  set P := (Finset.Iic x).filter Nat.Prime with hP
  have step1 : ∀ n ∈ Finset.Icc 1 x, (Ω n : ℝ) - ω n ≤
      ∑ p ∈ P, ∑ k ∈ Finset.Icc 2 x, (if p ^ k ∣ n then (1 : ℝ) else 0) := by
    intro n hn
    have := hr_Omega_le x n hn
    have h : (Ω n : ℝ) ≤ ω n + ∑ p ∈ P,
        (((Finset.Icc 2 x).filter (fun k => p ^ k ∣ n)).card : ℝ) := by exact_mod_cast this
    simp_rw [Finset.sum_boole]
    linarith
  have step2 : ∀ p ∈ P, ∑ k ∈ Finset.Icc 2 x, ((1 : ℝ) / p) ^ k ≤ 1 / ((p : ℝ) - 1) - 1 / p := by
    intro p hp
    have hp2 : (2 : ℝ) ≤ p := by exact_mod_cast (Finset.mem_filter.mp hp).2.two_le
    have := geom_sum_Ico_le_of_lt_one (x := (1 : ℝ) / p) (m := 2) (n := x + 1) (by positivity)
      (by rw [div_lt_one (by linarith)]; linarith)
    rw [Finset.Ico_add_one_right_eq_Icc] at this
    refine this.trans (le_of_eq ?_)
    have : (p : ℝ) - 1 ≠ 0 := by linarith
    have : (p : ℝ) ≠ 0 := by linarith
    field_simp
    ring
  calc ∑ n ∈ Finset.Icc 1 x, ((Ω n : ℝ) - ω n)
      ≤ ∑ n ∈ Finset.Icc 1 x, ∑ p ∈ P, ∑ k ∈ Finset.Icc 2 x, (if p ^ k ∣ n then (1 : ℝ) else 0) :=
        Finset.sum_le_sum step1
    _ = ∑ p ∈ P, ∑ k ∈ Finset.Icc 2 x, ∑ n ∈ Finset.Icc 1 x, (if p ^ k ∣ n then (1 : ℝ) else 0) := by
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun p _ => ?_
        rw [Finset.sum_comm]
    _ ≤ ∑ p ∈ P, ∑ k ∈ Finset.Icc 2 x, (x : ℝ) * ((1 : ℝ) / p) ^ k := by
        apply Finset.sum_le_sum; intro p hp
        apply Finset.sum_le_sum; intro k _
        rw [Finset.sum_boole, hr_card_dvd]
        have : ((x / p ^ k : ℕ) : ℝ) ≤ (x : ℝ) / ((p ^ k : ℕ) : ℝ) := Nat.cast_div_le
        rw [div_pow, one_pow, mul_one_div]
        push_cast at this
        exact this
    _ = (x : ℝ) * ∑ p ∈ P, ∑ k ∈ Finset.Icc 2 x, ((1 : ℝ) / p) ^ k := by
        rw [Finset.mul_sum]
        refine Finset.sum_congr rfl fun p _ => ?_
        rw [Finset.mul_sum]
    _ ≤ (x : ℝ) * ∑ p ∈ P, (1 / ((p : ℝ) - 1) - 1 / p) := by
        gcongr with p hp
        exact step2 p hp
    _ ≤ (x : ℝ) * 1 := by
        gcongr
        have := hr_sum_inv_sub_one_le x
        rw [← hP] at this
        rw [Finset.sum_sub_distrib]
        linarith
    _ = x := mul_one _
#print axioms hr_sum_Omega_sub

/-- Hardy and Ramanujan (1917): the count `ω n` of different primes dividing `n` has normal
order `log log n`. For every `ε > 0`, the share of the numbers `n` from 1 to `x` whose count
misses `log log n` by more than `ε log log n` tends to 0 as `x` grows. -/
theorem hardy_ramanujan_omega_normal_order (ε : ℝ) (hε : 0 < ε) :
    Tendsto (fun x : ℕ =>
      (((Finset.Icc 1 x).filter (fun n : ℕ =>
          ε * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)).card : ℝ) / x)
      atTop (𝓝 0) := by
  obtain ⟨K, hK⟩ := hr_mertens_two_upper
  set B := |K| + 1 with hB
  have hB1 : 1 ≤ B := by have := abs_nonneg K; linarith
  have hKB : K ≤ B - 1 := by have := le_abs_self K; linarith
  set g : ℕ → ℝ := fun x => 1 / Real.sqrt x + (12 / ε ^ 2) * (Real.log (Real.log x))⁻¹ +
    (4 * (B + B ^ 2) / ε ^ 2) * ((Real.log (Real.log x))⁻¹) ^ 2 with hgdef
  have hg : Tendsto g atTop (𝓝 0) := by
    have hi := tendsto_inv_atTop_zero.comp hr_tendsto_loglog
    have := (hr_tendsto_inv_sqrt.add (hi.const_mul (12 / ε ^ 2))).add
      ((hi.pow 2).const_mul (4 * (B + B ^ 2) / ε ^ 2))
    simpa [hgdef] using this
  apply tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hg
  · exact Eventually.of_forall fun x => by positivity
  have h1 := hr_tendsto_loglog.eventually_ge_atTop (max 1 (2 * (1 + ε) / ε))
  filter_upwards [h1, eventually_ge_atTop 2] with x hL hx
  set L := Real.log (Real.log x) with hLdef
  have hL1 : 1 ≤ L := le_of_max_le_left hL
  have hL2 : 2 * (1 + ε) / ε ≤ L := le_of_max_le_right hL
  have hLe : 2 * (1 + ε) ≤ ε * L := by
    rw [div_le_iff₀ hε] at hL2; linarith
  have hxpos : (0 : ℝ) < x := by exact_mod_cast (by omega : 0 < x)
  set S := ∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p with hS
  have hSu : S ≤ L + K := hK x hx
  have hSl : L ≤ S + 1 := hr_mertens_two_lower x hx
  have hT := hr_turan x (by linarith)
  rw [← hLdef, ← hS] at hT
  set V := 3 * L + B + B ^ 2 with hV
  have hR : S + (S - L) ^ 2 + 2 * L * (Nat.primeCounting x : ℝ) / x ≤ V := by
    have e1 : (S - L) ^ 2 ≤ B ^ 2 := sq_le_sq' (by linarith) (by linarith)
    have e2 : 2 * L * (Nat.primeCounting x : ℝ) / x ≤ 2 * L := by
      rw [div_le_iff₀ hxpos]
      have := hr_primeCounting_le x
      have : 0 ≤ 2 * L := by linarith
      nlinarith
    linarith
  have hsum : ∑ n ∈ Finset.Icc 1 x, ((ω n : ℝ) - L) ^ 2 ≤ x * V := by
    have := hT.trans hR
    rw [one_div_mul_eq_div, div_le_iff₀ hxpos] at this
    linarith
  set δ := ε * L / 2 with hδ
  have hδpos : 0 < δ := by positivity
  have hsub : (Finset.Icc 1 x).filter (fun n : ℕ =>
        ε * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|) ⊆
      (Finset.Icc 1 x).filter (fun n => n * n ≤ x) ∪
      (Finset.Icc 1 x).filter (fun n => δ ^ 2 ≤ ((ω n : ℝ) - L) ^ 2) := by
    intro n hn
    rw [Finset.mem_filter] at hn
    rw [Finset.mem_union, Finset.mem_filter, Finset.mem_filter]
    by_cases hnn : n * n ≤ x
    · exact Or.inl ⟨hn.1, hnn⟩
    · right
      refine ⟨hn.1, ?_⟩
      have hnx : n ≤ x := (Finset.mem_Icc.mp hn.1).2
      obtain ⟨c1, c2⟩ := hr_loglog_close x n hx hnx (by omega)
      rw [← hLdef] at c1 c2
      have hl2 : Real.log 2 < 2 - 1 := Real.log_lt_sub_one_of_pos (by norm_num) (by norm_num)
      have tri : |(ω n : ℝ) - Real.log (Real.log n)| ≤
          |(ω n : ℝ) - L| + |L - Real.log (Real.log n)| := abs_sub_le _ _ _
      have habs : |L - Real.log (Real.log n)| = L - Real.log (Real.log n) :=
        abs_of_nonneg (by linarith)
      have hεl : ε * (L - 1) ≤ ε * Real.log (Real.log n) :=
        mul_le_mul_of_nonneg_left (by linarith) hε.le
      have key : δ ≤ |(ω n : ℝ) - L| := by
        rw [hδ]; nlinarith [hn.2]
      rw [sq_le_sq, abs_of_pos hδpos]
      exact key
  have hcard := Finset.card_le_card hsub
  have hcard2 := hcard.trans (Finset.card_union_le _ _)
  have hA1 := hr_card_small x
  have hA2 := hr_markov (Finset.Icc 1 x) (fun n => ((ω n : ℝ) - L) ^ 2)
    (fun n _ => sq_nonneg _) (δ ^ 2) (by positivity)
  have hfin : ((((Finset.Icc 1 x).filter (fun n : ℕ =>
        ε * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)).card : ℕ) : ℝ) ≤
      Nat.sqrt x + x * V / δ ^ 2 := by
    have : ((((Finset.Icc 1 x).filter (fun n : ℕ =>
        ε * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)).card : ℕ) : ℝ) ≤
        (((Finset.Icc 1 x).filter (fun n => n * n ≤ x)).card : ℝ) +
        (((Finset.Icc 1 x).filter (fun n => δ ^ 2 ≤ ((ω n : ℝ) - L) ^ 2)).card : ℝ) := by
      exact_mod_cast hcard2
    have h3 : (∑ n ∈ Finset.Icc 1 x, ((ω n : ℝ) - L) ^ 2) / δ ^ 2 ≤ x * V / δ ^ 2 :=
      div_le_div_of_nonneg_right hsum (by positivity)
    have h4 : (((Finset.Icc 1 x).filter (fun n => n * n ≤ x)).card : ℝ) ≤ Nat.sqrt x := by
      exact_mod_cast hA1
    linarith
  calc _ ≤ ((Nat.sqrt x : ℝ) + x * V / δ ^ 2) / x := div_le_div_of_nonneg_right hfin hxpos.le
    _ = (Nat.sqrt x : ℝ) / x + V / δ ^ 2 := by field_simp
    _ ≤ 1 / Real.sqrt x + V / δ ^ 2 := by
        have := hr_sqrt_div_le x (by omega)
        linarith
    _ = g x := by
        simp only [hgdef, hV, hδ]
        rw [← hLdef]
        have : L ≠ 0 := by linarith
        field_simp
        ring

/-- Repeats change nothing: the count `Ω n` of prime factors of `n` with repeats also has
normal order `log log n`. For every `ε > 0`, the share of `n` from 1 to `x` with
`|Ω n - log log n| > ε log log n` tends to 0. -/
theorem hardy_ramanujan_bigOmega_normal_order (ε : ℝ) (hε : 0 < ε) :
    Tendsto (fun x : ℕ =>
      (((Finset.Icc 1 x).filter (fun n : ℕ =>
          ε * Real.log (Real.log n) < |(Ω n : ℝ) - Real.log (Real.log n)|)).card : ℝ) / x)
      atTop (𝓝 0) := by
  have hω := hardy_ramanujan_omega_normal_order (ε / 2) (by positivity)
  set fω : ℕ → ℝ := fun x : ℕ =>
      (((Finset.Icc 1 x).filter (fun n : ℕ =>
          ε / 2 * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)).card : ℝ) / x
    with hfω
  set g : ℕ → ℝ := fun x => 1 / Real.sqrt x + fω x + (4 / ε) * (Real.log (Real.log x))⁻¹
    with hgdef
  have hg : Tendsto g atTop (𝓝 0) := by
    have hi := tendsto_inv_atTop_zero.comp hr_tendsto_loglog
    have := (hr_tendsto_inv_sqrt.add hω).add (hi.const_mul (4 / ε))
    simpa [hgdef] using this
  apply tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hg
  · exact Eventually.of_forall fun x => by positivity
  have h1 := hr_tendsto_loglog.eventually_ge_atTop 2
  filter_upwards [h1, eventually_ge_atTop 2] with x hL hx
  set L := Real.log (Real.log x) with hLdef
  have hxpos : (0 : ℝ) < x := by exact_mod_cast (by omega : 0 < x)
  set δ := ε * L / 4 with hδ
  have hδpos : 0 < δ := by positivity
  have hsub : (Finset.Icc 1 x).filter (fun n : ℕ =>
        ε * Real.log (Real.log n) < |(Ω n : ℝ) - Real.log (Real.log n)|) ⊆
      ((Finset.Icc 1 x).filter (fun n => n * n ≤ x) ∪
      (Finset.Icc 1 x).filter (fun n : ℕ =>
          ε / 2 * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)) ∪
      (Finset.Icc 1 x).filter (fun n => δ ≤ (Ω n : ℝ) - ω n) := by
    intro n hn
    rw [Finset.mem_filter] at hn
    simp only [Finset.mem_union, Finset.mem_filter]
    by_cases hnn : n * n ≤ x
    · exact Or.inl (Or.inl ⟨hn.1, hnn⟩)
    by_cases hb : ε / 2 * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|
    · exact Or.inl (Or.inr ⟨hn.1, hb⟩)
    right
    refine ⟨hn.1, ?_⟩
    replace hb := not_lt.mp hb
    have hnx : n ≤ x := (Finset.mem_Icc.mp hn.1).2
    obtain ⟨c1, c2⟩ := hr_loglog_close x n hx hnx (by omega)
    rw [← hLdef] at c1 c2
    have hl2 : Real.log 2 < 2 - 1 := Real.log_lt_sub_one_of_pos (by norm_num) (by norm_num)
    have hle : (ω n : ℝ) ≤ Ω n := by exact_mod_cast hr_omega_le_Omega n
    have tri : |(Ω n : ℝ) - Real.log (Real.log n)| ≤
        |(Ω n : ℝ) - ω n| + |(ω n : ℝ) - Real.log (Real.log n)| := abs_sub_le _ _ _
    rw [abs_of_nonneg (by linarith : (0 : ℝ) ≤ (Ω n : ℝ) - ω n)] at tri
    have hεl : ε * (L / 2) ≤ ε * Real.log (Real.log n) :=
      mul_le_mul_of_nonneg_left (by linarith) hε.le
    rw [hδ]
    nlinarith [hn.2]
  have hcard := (Finset.card_le_card hsub).trans
    ((Finset.card_union_le _ _).trans (Nat.add_le_add_right (Finset.card_union_le _ _) _))
  have hA1 := hr_card_small x
  have hA3 := hr_markov (Finset.Icc 1 x) (fun n => (Ω n : ℝ) - ω n)
    (fun n _ => by
      have : (ω n : ℝ) ≤ Ω n := by exact_mod_cast hr_omega_le_Omega n
      linarith) δ hδpos
  have hS := hr_sum_Omega_sub x
  have hfin : ((((Finset.Icc 1 x).filter (fun n : ℕ =>
        ε * Real.log (Real.log n) < |(Ω n : ℝ) - Real.log (Real.log n)|)).card : ℕ) : ℝ) ≤
      Nat.sqrt x + (((Finset.Icc 1 x).filter (fun n : ℕ =>
          ε / 2 * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)).card : ℝ)
        + x / δ := by
    have h0 : ((((Finset.Icc 1 x).filter (fun n : ℕ =>
        ε * Real.log (Real.log n) < |(Ω n : ℝ) - Real.log (Real.log n)|)).card : ℕ) : ℝ) ≤
        (((Finset.Icc 1 x).filter (fun n => n * n ≤ x)).card : ℝ) +
        (((Finset.Icc 1 x).filter (fun n : ℕ =>
          ε / 2 * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)).card : ℝ) +
        (((Finset.Icc 1 x).filter (fun n => δ ≤ (Ω n : ℝ) - ω n)).card : ℝ) := by
      exact_mod_cast hcard
    have h3 : (∑ n ∈ Finset.Icc 1 x, ((Ω n : ℝ) - ω n)) / δ ≤ x / δ :=
      div_le_div_of_nonneg_right hS hδpos.le
    have h4 : (((Finset.Icc 1 x).filter (fun n => n * n ≤ x)).card : ℝ) ≤ Nat.sqrt x := by
      exact_mod_cast hA1
    linarith
  calc _ ≤ ((Nat.sqrt x : ℝ) + (((Finset.Icc 1 x).filter (fun n : ℕ =>
          ε / 2 * Real.log (Real.log n) < |(ω n : ℝ) - Real.log (Real.log n)|)).card : ℝ)
        + x / δ) / x := div_le_div_of_nonneg_right hfin hxpos.le
    _ = (Nat.sqrt x : ℝ) / x + fω x + 1 / δ := by
        simp only [hfω]
        field_simp
    _ ≤ 1 / Real.sqrt x + fω x + 1 / δ := by
        have := hr_sqrt_div_le x (by omega)
        linarith
    _ = g x := by
        simp only [hgdef, hδ]
        rw [← hLdef]
        have : L ≠ 0 := by linarith
        field_simp

/-- Turán's variance bound: for a whole number `x` with `L = log log x > 0`, and `S` the sum
of `1/p` over the primes `p ≤ x`, the average of `(ω n - L)^2` over `n` from 1 to `x` is at
most `S + (S - L)^2 + 2 L π(x) / x`. -/
theorem turan_variance_bound (x : ℕ) (hL : 0 < Real.log (Real.log x)) :
    (1 / (x : ℝ)) * ∑ n ∈ Finset.Icc 1 x, ((ω n : ℝ) - Real.log (Real.log x)) ^ 2 ≤
      (∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p)
        + ((∑ p ∈ (Finset.Iic x).filter Nat.Prime, (1 : ℝ) / p) - Real.log (Real.log x)) ^ 2
        + 2 * Real.log (Real.log x) * (Nat.primeCounting x : ℝ) / x := by
  exact hr_turan x hL

-- The card's three neighbours of a million.
example : 999999 = 3 ^ 3 * 7 * 11 * 13 * 37 := by norm_num
example : ω 999999 = 5 := by simp [cardDistinctFactors_apply]
example : Ω 999999 = 7 := by simp [cardFactors_apply]
example : ω 1000000 = 2 := by simp [cardDistinctFactors_apply]
example : Ω 1000000 = 12 := by simp [cardFactors_apply]
example : 1000001 = 101 * 9901 ∧ Nat.Prime 101 ∧ Nat.Prime 9901 := by norm_num
example : ω 1000001 = 2 := by simp [cardDistinctFactors_apply]
example : Ω 1000001 = 2 := by simp [cardFactors_apply]
-- 510,510 has 7 different primes.
example : ω 510510 = 7 := by simp [cardDistinctFactors_apply]
-- 1031 and 1033 never divide the same window number: their product is past 1,050,000.
example : Nat.Prime 1031 ∧ Nat.Prime 1033 ∧ 1031 * 1033 = 1065023 ∧ 1050000 < 1031 * 1033 := by
  norm_num
-- The window has 100,001 numbers, and the histogram rows add up to it.
example : 1050000 - 950000 + 1 = 100001 := by norm_num
example : 7237 + 27142 + 37282 + 22595 + 5353 + 390 + 2 = 100001 := by norm_num
example : 27142 + 37282 + 22595 = 87019 := by norm_num

#print axioms hardy_ramanujan_omega_normal_order
#print axioms hardy_ramanujan_bigOmega_normal_order
#print axioms turan_variance_bound
