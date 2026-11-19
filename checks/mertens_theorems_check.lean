-- Mertens' theorems: the sum of log p / p over the primes up to x is log x plus a bounded error, the sum of 1/p is log log x plus a fixed constant M plus an error of size 1/log x, and the product of 1 − 1/p times log x tends to e^−γ.
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.Harmonic.EulerMascheroni
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.NumberTheory.Chebyshev
import Mathlib.NumberTheory.AbelSummation
import Mathlib.NumberTheory.Harmonic.ZetaAsymp
import Mathlib.NumberTheory.Harmonic.GammaDeriv
import Mathlib.NumberTheory.EulerProduct.DirichletLSeries
import Mathlib.Analysis.SpecialFunctions.Log.Sum
import Mathlib.NumberTheory.SumPrimeReciprocals
import Mathlib.Data.Nat.Choose.Factorization
import Mathlib.Analysis.Normed.Group.Tannery

open Filter Topology Nat Real
theorem mertens_log_factorial_eq (N : ℕ) :
    Real.log ((N ! : ℕ) : ℝ) = ∑ p ∈ primesLE N, ((N !).factorization p : ℝ) * Real.log p := by
  rw [Real.log_nat_eq_sum_factorization]
  apply Finsupp.sum_of_support_subset
  · intro p hp
    rw [Nat.support_factorization] at hp
    have hpp := Nat.prime_of_mem_primeFactors hp
    have hd := Nat.dvd_of_mem_primeFactors hp
    exact mem_primesLE.mpr ⟨(Nat.Prime.dvd_factorial hpp).mp hd, hpp⟩
  · intro p _; simp

theorem mertens_sum_le (N : ℕ) (hN : 1 ≤ N) :
    ∑ p ∈ primesLE N, Real.log p / p ≤ Real.log N + Real.log 4 := by
  have hNpos : (0:ℝ) < N := by exact_mod_cast hN
  have key : ∀ p ∈ primesLE N, (N:ℝ) * (Real.log p / p) ≤
      ((N !).factorization p : ℝ) * Real.log p + Real.log p := by
    intro p hp
    have hpp := prime_of_mem_primesLE hp
    have hp0 : (0:ℝ) < p := by exact_mod_cast hpp.pos
    have hlog : 0 ≤ Real.log p := Real.log_natCast_nonneg p
    have h1 : (N:ℝ)/p - 1 ≤ ((N / p : ℕ) : ℝ) := by
      rw [← Nat.floor_div_eq_div (K := ℝ)]; exact (Nat.sub_one_lt_floor _).le
    have h2 : N / p ≤ (N !).factorization p := by
      rw [Nat.factorization_factorial hpp (Nat.lt_add_one (Nat.log p N))]
      have : 1 ∈ Finset.Ico 1 (Nat.log p N + 1) := by
        simp only [Finset.mem_Ico, le_refl, true_and, lt_add_iff_pos_left]
        exact Nat.log_pos hpp.one_lt (le_of_mem_primesLE hp)
      calc N / p = N / p ^ 1 := by rw [pow_one]
        _ ≤ _ := Finset.single_le_sum (f := fun i => N / p ^ i) (fun _ _ => Nat.zero_le _) this
    have h3 : ((N / p : ℕ) : ℝ) ≤ ((N !).factorization p : ℝ) := by exact_mod_cast h2
    calc (N:ℝ) * (Real.log p / p) = ((N:ℝ)/p - 1) * Real.log p + Real.log p := by
          field_simp; ring
      _ ≤ ((N !).factorization p : ℝ) * Real.log p + Real.log p := by gcongr; linarith
  have hsum := Finset.sum_le_sum key
  rw [← Finset.mul_sum, Finset.sum_add_distrib, ← mertens_log_factorial_eq,
    ← Chebyshev.theta_eq_sum_primesLE_log] at hsum
  have hfact : Real.log ((N ! : ℕ) : ℝ) ≤ N * Real.log N := by
    have := Real.sum_log_le' (x := (N:ℝ)) (by exact_mod_cast hN)
    rwa [Nat.floor_natCast, Real.sum_log_eq_log_factorial] at this
  have htheta := Chebyshev.theta_le_log4_mul_x (x := (N:ℝ)) hNpos.le
  have : (N:ℝ) * ∑ p ∈ primesLE N, Real.log p / p ≤ N * (Real.log N + Real.log 4) := by
    nlinarith
  exact le_of_mul_le_mul_left this hNpos

theorem mertens_log_div_bound (n : ℕ) (hn : 2 ≤ n) :
    Real.log n / (n * (n - 1)) ≤ 4 * ((n:ℝ) ^ (3/2:ℝ))⁻¹ := by
  have hn' : (2:ℝ) ≤ n := by exact_mod_cast hn
  have hn0 : (0:ℝ) < n := by linarith
  have hsq : (n:ℝ) ^ (3/2:ℝ) = n * √n := by
    rw [show (3/2:ℝ) = 1 + 1/2 by norm_num, Real.rpow_add hn0, Real.rpow_one, Real.sqrt_eq_rpow]
  rw [hsq]
  have hs0 : 0 < √(n:ℝ) := Real.sqrt_pos.mpr hn0
  have hss : √(n:ℝ) * √n = n := Real.mul_self_sqrt hn0.le
  have hlog : Real.log n ≤ 2 * √n := by
    have h := Real.log_le_sub_one_of_pos hs0
    rw [Real.log_sqrt hn0.le] at h
    linarith
  rw [div_le_iff₀ (by nlinarith), ← div_eq_mul_inv, mul_comm, ← mul_div_assoc, le_div_iff₀ (by positivity)]
  have h1 := mul_le_mul_of_nonneg_right hlog (by positivity : (0:ℝ) ≤ n * √n)
  have h2 : 2 * √(n:ℝ) * (n * √n) = 2 * n * n := by rw [mul_comm (n:ℝ), ← mul_assoc, mul_assoc 2, hss]
  nlinarith

theorem mertens_tail_bound : ∃ C : ℝ, 0 ≤ C ∧ ∀ N : ℕ,
    ∑ p ∈ primesLE N, Real.log p / (p * (p - 1)) ≤ C := by
  set G : ℕ → ℝ := fun n => 4 * ((n:ℝ) ^ (3/2:ℝ))⁻¹ with hGdef
  have hG : Summable G := (Real.summable_nat_rpow_inv.mpr (by norm_num)).mul_left 4
  refine ⟨∑' n, G n, tsum_nonneg (fun n => by positivity), fun N => ?_⟩
  calc ∑ p ∈ primesLE N, Real.log p / (p * (p - 1)) ≤ ∑ p ∈ primesLE N, G p := by
        apply Finset.sum_le_sum; intro p hp
        exact mertens_log_div_bound p (two_le_of_mem_primesLE hp)
    _ ≤ ∑' n, G n := hG.sum_le_tsum _ (fun n _ => by positivity)

theorem mertens_sum_ge (C : ℝ) (hC : ∀ N : ℕ, ∑ p ∈ primesLE N, Real.log p / (p * (p - 1)) ≤ C)
    (N : ℕ) (hN : 1 ≤ N) :
    Real.log N - 1 - C ≤ ∑ p ∈ primesLE N, Real.log p / p := by
  have hNpos : (0:ℝ) < N := by exact_mod_cast hN
  have key : ∀ p ∈ primesLE N, ((N !).factorization p : ℝ) * Real.log p ≤
      N * (Real.log p / p + Real.log p / (p * (p - 1))) := by
    intro p hp
    have hpp := prime_of_mem_primesLE hp
    have hp2 : (2:ℝ) ≤ p := by exact_mod_cast hpp.two_le
    have hlog : 0 ≤ Real.log p := Real.log_natCast_nonneg p
    have h1 : ((N !).factorization p : ℝ) ≤ (N:ℝ) / (p - 1) := by
      have h := Nat.factorization_factorial_le_div_pred hpp N
      have h' : ((N !).factorization p : ℝ) ≤ ((N / (p - 1) : ℕ) : ℝ) := by exact_mod_cast h
      refine h'.trans ((Nat.cast_div_le).trans ?_)
      rw [Nat.cast_sub hpp.one_le, Nat.cast_one]
    calc ((N !).factorization p : ℝ) * Real.log p ≤ (N:ℝ) / (p - 1) * Real.log p := by gcongr
      _ = N * (Real.log p / p + Real.log p / (p * (p - 1))) := by
          have : (p:ℝ) - 1 ≠ 0 := by linarith
          have : (p:ℝ) ≠ 0 := by linarith
          field_simp; ring
  have hsum := Finset.sum_le_sum key
  rw [← mertens_log_factorial_eq, ← Finset.mul_sum, Finset.sum_add_distrib] at hsum
  have hfact : (N:ℝ) * Real.log N - N ≤ Real.log ((N ! : ℕ) : ℝ) := by
    have := Real.le_sum_log_nat N
    rwa [Real.sum_log_eq_log_factorial] at this
  have hc := hC N
  have : (N:ℝ) * (Real.log N - 1 - C) ≤ N * ∑ p ∈ primesLE N, Real.log p / p := by nlinarith
  exact le_of_mul_le_mul_left this hNpos

theorem mertens_first_nat : ∃ K : ℝ, 0 ≤ K ∧ ∀ N : ℕ, 1 ≤ N →
    |(∑ p ∈ primesLE N, Real.log p / p) - Real.log N| ≤ K := by
  obtain ⟨C, hC0, hC⟩ := mertens_tail_bound
  refine ⟨max (Real.log 4) (1 + C), by positivity, fun N hN => ?_⟩
  rw [abs_le]
  constructor
  · have := mertens_sum_ge C hC N hN
    have : 1 + C ≤ max (Real.log 4) (1 + C) := le_max_right _ _
    linarith
  · have := mertens_sum_le N hN
    have : Real.log 4 ≤ max (Real.log 4) (1 + C) := le_max_left _ _
    linarith

theorem mertens_first_real : ∃ K : ℝ, 0 ≤ K ∧ ∀ x : ℝ, 2 ≤ x →
    |(∑ p ∈ primesLE ⌊x⌋₊, Real.log p / p) - Real.log x| ≤ K := by
  obtain ⟨K, hK0, hK⟩ := mertens_first_nat
  refine ⟨K + Real.log 2, by positivity, fun x hx => ?_⟩
  have hN1 : 1 ≤ ⌊x⌋₊ := Nat.le_floor (by norm_num; linarith)
  have hN := hK _ hN1
  have hNpos : (0:ℝ) < ⌊x⌋₊ := by exact_mod_cast hN1
  have hfl : (⌊x⌋₊ : ℝ) ≤ x := Nat.floor_le (by linarith)
  have hlt : x < ⌊x⌋₊ + 1 := Nat.lt_floor_add_one x
  have h1 : Real.log ⌊x⌋₊ ≤ Real.log x := Real.log_le_log hNpos hfl
  have h2 : Real.log x ≤ Real.log ⌊x⌋₊ + Real.log 2 := by
    rw [← Real.log_mul hNpos.ne' (by norm_num)]
    apply Real.log_le_log (by linarith)
    have : (1:ℝ) ≤ ⌊x⌋₊ := by exact_mod_cast hN1
    linarith
  rw [abs_le] at hN ⊢
  constructor <;> linarith [hN.1, hN.2]

/-- Discrete summation by parts. -/
theorem mertens_abel_discrete (a f : ℕ → ℝ) (N : ℕ) :
    ∑ n ∈ Finset.range (N + 1), a n * f n =
      (∑ n ∈ Finset.range (N + 1), a n) * f N +
      ∑ n ∈ Finset.range N, (∑ m ∈ Finset.range (n + 1), a m) * (f n - f (n + 1)) := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [Finset.sum_range_succ (fun n => a n * f n), ih,
      Finset.sum_range_succ (fun n => (∑ m ∈ Finset.range (n + 1), a m) * (f n - f (n + 1))),
      Finset.sum_range_succ a (N + 1)]
    ring

theorem mertens_inv_log_tendsto :
    Tendsto (fun n : ℕ => 1 / Real.log n) atTop (𝓝 0) := by
  have := (tendsto_log_atTop.comp tendsto_natCast_atTop_atTop).inv_tendsto_atTop
  refine this.congr (fun n => ?_)
  simp [one_div]

theorem mertens_inv_log_hasSum (N : ℕ) (hN : 2 ≤ N) :
    HasSum (fun k : ℕ => 1 / Real.log ((k + N : ℕ) : ℝ) - 1 / Real.log ((k + N + 1 : ℕ) : ℝ))
      (1 / Real.log N) := by
  have hnn : ∀ k : ℕ, 0 ≤ 1 / Real.log ((k + N : ℕ) : ℝ) - 1 / Real.log ((k + N + 1 : ℕ) : ℝ) := by
    intro k
    have h2 : (2:ℝ) ≤ ((k + N : ℕ) : ℝ) := by exact_mod_cast (by omega : 2 ≤ k + N)
    have hl : 0 < Real.log ((k + N : ℕ) : ℝ) := Real.log_pos (by linarith)
    have hle : Real.log ((k + N : ℕ) : ℝ) ≤ Real.log ((k + N + 1 : ℕ) : ℝ) :=
      Real.log_le_log (by linarith) (by push_cast; linarith)
    rw [sub_nonneg]
    exact one_div_le_one_div_of_le hl hle
  rw [hasSum_iff_tendsto_nat_of_nonneg hnn]
  have hsum : ∀ m : ℕ, ∑ k ∈ Finset.range m,
      (1 / Real.log ((k + N : ℕ) : ℝ) - 1 / Real.log ((k + N + 1 : ℕ) : ℝ)) =
      1 / Real.log N - 1 / Real.log ((m + N : ℕ) : ℝ) := by
    intro m
    have := Finset.sum_range_sub' (fun k => 1 / Real.log ((k + N : ℕ) : ℝ)) m
    simp only [zero_add] at this
    rw [← this]
    apply Finset.sum_congr rfl
    intro k _
    congr 3
    push_cast; ring
  simp_rw [hsum]
  have := mertens_inv_log_tendsto.comp (tendsto_add_atTop_nat N)
  simpa using (tendsto_const_nhds (x := 1 / Real.log N)).sub this

theorem mertens_loglog_step (n : ℕ) (hn : 2 ≤ n) :
    |Real.log n * (1 / Real.log n - 1 / Real.log ((n + 1 : ℕ) : ℝ)) -
      (Real.log (Real.log ((n + 1 : ℕ) : ℝ)) - Real.log (Real.log n))| ≤
      1 / Real.log n - 1 / Real.log ((n + 1 : ℕ) : ℝ) := by
  have h2 : (2:ℝ) ≤ n := by exact_mod_cast hn
  set L0 := Real.log n with hL0
  set L1 := Real.log ((n + 1 : ℕ) : ℝ) with hL1
  have hL0p : 0 < L0 := Real.log_pos (by linarith)
  have hlt : L0 < L1 := Real.log_lt_log (by linarith) (by push_cast; linarith)
  have hL1p : 0 < L1 := hL0p.trans hlt
  have hd : L1 - L0 ≤ 1 := by
    rw [hL0, hL1, ← Real.log_div (by push_cast; linarith) (by linarith)]
    have := Real.log_le_sub_one_of_pos (x := ((n + 1 : ℕ) : ℝ) / n) (by positivity)
    have h3 : ((n + 1 : ℕ) : ℝ) / n - 1 ≤ 1 := by
      rw [div_sub_one (by linarith), div_le_one (by linarith)]; push_cast; linarith
    linarith
  have hr : 0 < L1 / L0 := div_pos hL1p hL0p
  have hlo := Real.one_sub_inv_le_log_of_pos hr
  have hhi := Real.log_le_sub_one_of_pos hr
  rw [Real.log_div hL1p.ne' hL0p.ne'] at hlo hhi
  have e1 : L0 * (1 / L0 - 1 / L1) = 1 - (L1 / L0)⁻¹ := by field_simp
  have e2 : L1 / L0 - 1 - (1 - (L1 / L0)⁻¹) = (L1 - L0) ^ 2 / (L0 * L1) := by field_simp
  have e3 : 1 / L0 - 1 / L1 = (L1 - L0) / (L0 * L1) := by field_simp
  have hsq : (L1 - L0) ^ 2 / (L0 * L1) ≤ (L1 - L0) / (L0 * L1) := by
    apply div_le_div_of_nonneg_right _ (by positivity)
    nlinarith
  rw [e1, abs_le]
  constructor <;> nlinarith

theorem mertens_second_nat : ∃ M K : ℝ, 0 ≤ K ∧ ∀ N : ℕ, 2 ≤ N →
    |(∑ p ∈ primesLE N, (1 : ℝ) / p) - Real.log (Real.log N) - M| ≤ K / Real.log N := by
  obtain ⟨K, hK0, hK⟩ := mertens_first_nat
  set a : ℕ → ℝ := fun n => if n.Prime then Real.log n / n else 0 with ha
  set f : ℕ → ℝ := fun n => 1 / Real.log n with hf
  set A : ℕ → ℝ := fun n => ∑ m ∈ Finset.range (n + 1), a m with hA
  set L : ℕ → ℝ := fun n => Real.log (Real.log n) with hL
  set c : ℕ → ℝ := fun n => A n * (f n - f (n + 1)) - (L (n + 1) - L n) with hc
  have hAeq : ∀ n, A n = ∑ p ∈ primesLE n, Real.log p / p := by
    intro n
    simp only [hA, ha, primesLE_eq_filter_range, Finset.sum_filter]
  have hSeq : ∀ N, ∑ p ∈ primesLE N, (1 : ℝ) / p = ∑ n ∈ Finset.range (N + 1), a n * f n := by
    intro N
    rw [primesLE_eq_filter_range, Finset.sum_filter]
    apply Finset.sum_congr rfl
    intro n _
    simp only [ha, hf]
    split_ifs with hp
    · have : (1:ℝ) < n := by exact_mod_cast hp.one_lt
      have hl : Real.log n ≠ 0 := (Real.log_pos this).ne'
      field_simp
    · simp
  -- bound on c
  have hcb : ∀ n, 2 ≤ n → |c n| ≤ (K + 1) * (f n - f (n + 1)) := by
    intro n hn
    have hR := hK n (by omega)
    rw [← hAeq] at hR
    have hstep := mertens_loglog_step n hn
    have hg : 0 ≤ f n - f (n + 1) := by
      have := hstep; exact (abs_nonneg _).trans this
    have : c n = (A n - Real.log n) * (f n - f (n + 1)) +
        (Real.log n * (f n - f (n + 1)) - (L (n + 1) - L n)) := by simp only [hc]; ring
    rw [this]
    calc _ ≤ |(A n - Real.log n) * (f n - f (n + 1))| +
          |Real.log n * (f n - f (n + 1)) - (L (n + 1) - L n)| := abs_add_le _ _
      _ ≤ K * (f n - f (n + 1)) + (f n - f (n + 1)) := by
          refine add_le_add ?_ ?_
          · rw [abs_mul, abs_of_nonneg hg]; exact mul_le_mul_of_nonneg_right hR hg
          · simpa [hf, hL] using hstep
      _ = _ := by ring
  have hgsum : ∀ N, 2 ≤ N → HasSum (fun k => f (k + N) - f (k + N + 1)) (f N) := by
    intro N hN
    have := mertens_inv_log_hasSum N hN
    simpa [hf] using this
  have hcsum : Summable c := by
    rw [← summable_nat_add_iff 2]
    refine Summable.of_norm_bounded ((hgsum 2 le_rfl).summable.mul_left (K + 1)) ?_
    intro k
    simpa [Real.norm_eq_abs, add_assoc] using hcb (k + 2) (by omega)
  refine ⟨1 + ∑' n, c n, 2 * K + 1, by positivity, fun N hN => ?_⟩
  have h2 : (2:ℝ) ≤ N := by exact_mod_cast hN
  have hlogN : 0 < Real.log N := Real.log_pos (by linarith)
  have hS : ∑ p ∈ primesLE N, (1 : ℝ) / p = A N * f N + ∑ n ∈ Finset.range N, c n + L N := by
    rw [hSeq, mertens_abel_discrete]
    have htel : ∑ n ∈ Finset.range N, (L (n + 1) - L n) = L N - L 0 := Finset.sum_range_sub L N
    have hL0 : L 0 = 0 := by simp [hL]
    simp only [hc, Finset.sum_sub_distrib] at htel ⊢
    rw [htel, hL0]; ring
  have htail := (hcsum.sum_add_tsum_nat_add N).symm
  have htb : |∑' k, c (k + N)| ≤ (K + 1) * f N := by
    have := tsum_of_norm_bounded (f := fun k => c (k + N)) ((hgsum N hN).mul_left (K + 1))
      (fun k => by simpa [Real.norm_eq_abs] using hcb (k + N) (by omega))
    simpa [Real.norm_eq_abs] using this
  have hR := hK N (by omega)
  rw [← hAeq] at hR
  have hfN : f N = 1 / Real.log N := rfl
  have hAf : A N * f N - 1 = (A N - Real.log N) * f N := by
    rw [hfN]; field_simp
  have hfpos : 0 < f N := by rw [hfN]; positivity
  rw [hS]
  have : A N * f N + ∑ n ∈ Finset.range N, c n + L N - Real.log (Real.log N) -
      (1 + ∑' n, c n) = (A N - Real.log N) * f N - ∑' k, c (k + N) := by
    rw [htail, ← hAf]; simp only [hL]; ring
  rw [this]
  calc _ ≤ |(A N - Real.log N) * f N| + |∑' k, c (k + N)| := abs_sub _ _
    _ ≤ K * f N + (K + 1) * f N := by
        refine add_le_add ?_ htb
        rw [abs_mul, abs_of_pos hfpos]; exact mul_le_mul_of_nonneg_right hR hfpos.le
    _ = (2 * K + 1) / Real.log N := by rw [hfN]; ring

theorem mertens_second_real : ∃ M K : ℝ, 0 ≤ K ∧ ∀ x : ℝ, 2 ≤ x →
    |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x := by
  obtain ⟨M, K, hK0, hK⟩ := mertens_second_nat
  refine ⟨M, 2 * (K + 1), by positivity, fun x hx => ?_⟩
  have hN2 : 2 ≤ ⌊x⌋₊ := Nat.le_floor (by norm_num; linarith)
  have hN := hK _ hN2
  have h2 : (2:ℝ) ≤ ⌊x⌋₊ := by exact_mod_cast hN2
  have hNpos : (0:ℝ) < ⌊x⌋₊ := by linarith
  have hfl : (⌊x⌋₊ : ℝ) ≤ x := Nat.floor_le (by linarith)
  have hlt : x < ⌊x⌋₊ + 1 := Nat.lt_floor_add_one x
  have hlN : 0 < Real.log ⌊x⌋₊ := Real.log_pos (by linarith)
  have h1 : Real.log ⌊x⌋₊ ≤ Real.log x := Real.log_le_log hNpos hfl
  have hlx : 0 < Real.log x := hlN.trans_le h1
  have hl2 : Real.log 2 ≤ Real.log ⌊x⌋₊ := Real.log_le_log (by norm_num) h2
  have hl2' : Real.log 2 ≤ 1 := by
    have := Real.log_two_lt_d9; linarith
  have hup : Real.log x ≤ Real.log ⌊x⌋₊ + Real.log 2 := by
    rw [← Real.log_mul hNpos.ne' (by norm_num)]
    apply Real.log_le_log (by linarith)
    linarith
  have hll1 : Real.log (Real.log ⌊x⌋₊) ≤ Real.log (Real.log x) := Real.log_le_log hlN h1
  have hll2 : Real.log (Real.log x) - Real.log (Real.log ⌊x⌋₊) ≤ 1 / Real.log ⌊x⌋₊ := by
    rw [← Real.log_div hlx.ne' hlN.ne']
    refine (Real.log_le_sub_one_of_pos (div_pos hlx hlN)).trans ?_
    rw [div_sub_one hlN.ne']
    exact div_le_div_of_nonneg_right (by linarith) hlN.le
  have hcmp : 1 / Real.log ⌊x⌋₊ ≤ 2 / Real.log x := by
    rw [div_le_div_iff₀ hlN hlx]; linarith
  have hK1 : K / Real.log ⌊x⌋₊ ≤ 2 * K / Real.log x := by
    rw [div_le_div_iff₀ hlN hlx]; nlinarith
  rw [abs_le] at hN ⊢
  have e : 2 * (K + 1) / Real.log x = 2 * K / Real.log x + 2 / Real.log x := by ring
  rw [e]
  constructor <;> linarith [hN.1, hN.2]

theorem mertens_neg_log_bound (u : ℝ) (_h0 : 0 ≤ u) (h1 : u ≤ 1 / 2) :
    0 ≤ -Real.log (1 - u) - u ∧ -Real.log (1 - u) - u ≤ 2 * u ^ 2 := by
  have hp : 0 < 1 - u := by linarith
  have a := Real.log_le_sub_one_of_pos hp
  have b := Real.one_sub_inv_le_log_of_pos hp
  have e : (1 - u)⁻¹ = 1 + u + u ^ 2 / (1 - u) := by field_simp; ring
  have c : u ^ 2 / (1 - u) ≤ 2 * u ^ 2 := by
    rw [div_le_iff₀ hp]; nlinarith
  constructor <;> linarith

theorem mertens_log_zeta (s : ℝ) (hs : 1 < s) :
    Real.log (riemannZeta (s : ℂ)).re =
      ∑' n : ℕ, if n.Prime then -Real.log (1 - (n : ℝ) ^ (-s)) else 0 := by
  have h := riemannZeta_eulerProduct_exp_log (s := (s : ℂ)) (by simpa using hs)
  have hterm : ∀ p : Nat.Primes, -Complex.log (1 - ((p : ℕ) : ℂ) ^ (-(s : ℂ))) =
      ((-Real.log (1 - ((p : ℕ) : ℝ) ^ (-s)) : ℝ) : ℂ) := by
    intro p
    have hp : (0 : ℝ) < (p : ℕ) := by exact_mod_cast p.prop.pos
    have hu : ((p : ℕ) : ℝ) ^ (-s) < 1 :=
      Real.rpow_lt_one_of_one_lt_of_neg (by exact_mod_cast p.prop.one_lt) (by linarith)
    rw [Complex.ofReal_neg, Complex.ofReal_log (by linarith), Complex.ofReal_sub,
      Complex.ofReal_one, Complex.ofReal_cpow hp.le, Complex.ofReal_neg, Complex.ofReal_natCast]
  simp_rw [hterm] at h
  rw [← Complex.ofReal_tsum, ← Complex.ofReal_exp] at h
  rw [← h, Complex.ofReal_re, Real.log_exp,
    Nat.Primes.tsum_eq_tsum_ite (fun n : ℕ => -Real.log (1 - (n : ℝ) ^ (-s)))]

theorem mertens_rpow_le_inv (n : ℕ) (hn : n.Prime) (s : ℝ) (hs : 1 ≤ s) :
    0 ≤ (n : ℝ) ^ (-s) ∧ (n : ℝ) ^ (-s) ≤ (n : ℝ)⁻¹ ∧ (n : ℝ)⁻¹ ≤ 1 / 2 := by
  have h2 : (2 : ℝ) ≤ n := by exact_mod_cast hn.two_le
  refine ⟨by positivity, ?_, ?_⟩
  · rw [← Real.rpow_neg_one]
    exact Real.rpow_le_rpow_of_exponent_le (by linarith) (by linarith)
  · rw [inv_eq_one_div]; exact one_div_le_one_div_of_le (by norm_num) h2

theorem mertens_ppow_tendsto :
    Tendsto (fun s : ℝ => ∑' n : ℕ,
        if n.Prime then -Real.log (1 - (n : ℝ) ^ (-s)) - (n : ℝ) ^ (-s) else 0)
      (𝓝[>] 1)
      (𝓝 (∑' n : ℕ, if n.Prime then -Real.log (1 - (n : ℝ) ^ (-(1:ℝ))) - (n : ℝ) ^ (-(1:ℝ))
        else 0)) := by
  refine tendsto_tsum_of_dominated_convergence (bound := fun n : ℕ => 2 * ((n : ℝ) ^ 2)⁻¹)
    ((Real.summable_nat_pow_inv.mpr one_lt_two).mul_left 2) ?_ ?_
  · intro n
    by_cases hn : n.Prime
    · simp only [hn, ite_true]
      have hn0 : (0 : ℝ) < n := by exact_mod_cast hn.pos
      have h1 : ContinuousAt (fun s : ℝ => (n : ℝ) ^ (-s)) 1 :=
        ContinuousAt.rpow continuousAt_const continuousAt_id.neg (Or.inl hn0.ne')
      have hne : (1 : ℝ) - (n : ℝ) ^ (-(1:ℝ)) ≠ 0 := by
        have := (mertens_rpow_le_inv n hn 1 le_rfl)
        linarith [this.2.1, this.2.2]
      have h2 : ContinuousAt (fun s : ℝ => -Real.log (1 - (n : ℝ) ^ (-s)) - (n : ℝ) ^ (-s)) 1 :=
        ((continuousAt_const.sub h1).log hne).neg.sub h1
      exact h2.tendsto.mono_left nhdsWithin_le_nhds
    · simp only [hn, ite_false]; exact tendsto_const_nhds
  · filter_upwards [self_mem_nhdsWithin] with s hs n
    have hs : (1 : ℝ) ≤ s := le_of_lt hs
    by_cases hn : n.Prime
    · simp only [hn, ite_true]
      obtain ⟨h0, h1, h2⟩ := mertens_rpow_le_inv n hn s hs
      obtain ⟨b0, b1⟩ := mertens_neg_log_bound _ h0 (h1.trans h2)
      rw [Real.norm_eq_abs, abs_of_nonneg b0]
      refine b1.trans ?_
      rw [← inv_pow]
      gcongr
    · simp [hn]

theorem mertens_measurable_S :
    Measurable (fun t : ℝ => ∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) :=
  (measurable_from_nat (f := fun n : ℕ => ∑ p ∈ primesLE n, (1 : ℝ) / p)).comp
    Nat.measurable_floor

theorem mertens_S_eq_zero (t : ℝ) (ht : t < 2) :
    ∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p = 0 := by
  apply Finset.sum_eq_zero
  intro p hp
  have h1 := le_of_mem_primesLE hp
  have h2 := two_le_of_mem_primesLE hp
  have : ⌊t⌋₊ < 2 := (Nat.floor_lt' (by norm_num)).mpr (by simpa using ht)
  omega

theorem mertens_D_integrable (M K : ℝ) (hK0 : 0 ≤ K)
    (hMK : ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x)
    (σ : ℝ) (hσ : 1 < σ) :
    MeasureTheory.IntegrableOn (fun t : ℝ =>
      ((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-σ))
      (Set.Ioi 1) := by
  have hmeas : Measurable (fun t : ℝ =>
      ((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-σ)) := by
    have := mertens_measurable_S
    fun_prop
  have hpow : MeasureTheory.IntegrableOn (fun t : ℝ => t ^ (-σ)) (Set.Ioi 1) :=
    integrableOn_Ioi_rpow_of_lt (by linarith) one_pos
  rw [← Set.Ioo_union_Ici_eq_Ioi (show (1:ℝ) < 2 by norm_num)]
  refine MeasureTheory.IntegrableOn.union ?_ ?_
  · have h1 : MeasureTheory.IntegrableOn
        (fun t : ℝ => -(Real.log (Real.log t) * t ^ (-σ)) - M * t ^ (-σ)) (Set.Ioo 1 2) :=
      (((Real.integrableOn_log_log_mul_rpow hσ).mono_set Set.Ioo_subset_Ioi_self).neg.sub
        ((hpow.mono_set Set.Ioo_subset_Ioi_self).const_mul M))
    refine h1.congr_fun (fun t ht => ?_) measurableSet_Ioo
    simp only
    rw [mertens_S_eq_zero t ht.2]
    ring
  · have hg : MeasureTheory.IntegrableOn (fun t : ℝ => K / Real.log 2 * t ^ (-σ)) (Set.Ici 2) :=
      (hpow.mono_set (Set.Ici_subset_Ioi.mpr (by norm_num))).const_mul _
    refine MeasureTheory.Integrable.mono' hg hmeas.aestronglyMeasurable ?_
    refine (MeasureTheory.ae_restrict_iff' measurableSet_Ici).mpr (Filter.Eventually.of_forall ?_)
    intro t ht
    have ht2 : (2:ℝ) ≤ t := ht
    have hb := hMK t ht2
    have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
    have hlt : Real.log 2 ≤ Real.log t := Real.log_le_log (by norm_num) ht2
    have hKl : K / Real.log t ≤ K / Real.log 2 := div_le_div_of_nonneg_left hK0 hl2 hlt
    rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg (by positivity : (0:ℝ) ≤ t ^ (-σ))]
    exact mul_le_mul_of_nonneg_right (hb.trans hKl) (by positivity)

theorem mertens_S_icc (n : ℕ) :
    ∑ k ∈ Finset.Icc 0 n, (if k.Prime then (1 : ℝ) / k else 0) = ∑ p ∈ primesLE n, (1 : ℝ) / p := by
  rw [primesLE_eq_filter_Icc_zero, Finset.sum_filter]

theorem mertens_prime_sum_hasSum (M K : ℝ) (hK0 : 0 ≤ K)
    (hMK : ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x)
    (s : ℝ) (hs : 1 < s) :
    HasSum (fun n : ℕ => if n.Prime then (n : ℝ) ^ (-s) else 0)
      ((s - 1) * ∫ t in Set.Ioi 1, (∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) * t ^ (-s)) := by
  set c : ℕ → ℝ := fun k => if k.Prime then (1 : ℝ) / k else 0 with hcdef
  set Sx : ℝ → ℝ := fun t => ∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p with hSx
  have hSc : ∀ t : ℝ, ∑ k ∈ Finset.Icc 0 ⌊t⌋₊, c k = Sx t := fun t => mertens_S_icc _
  have hderiv : ∀ t : ℝ, deriv (fun t : ℝ => t ^ (1 - s)) t = (1 - s) * t ^ (-s) := by
    intro t
    rw [Real.deriv_rpow_const]; congr 2; ring
  -- integrability of Sx t * t^(-s) on Ioi 1
  have hD := mertens_D_integrable M K hK0 hMK s hs
  have hLL := Real.integrableOn_log_log_mul_rpow hs
  have hpow : MeasureTheory.IntegrableOn (fun t : ℝ => t ^ (-s)) (Set.Ioi 1) :=
    integrableOn_Ioi_rpow_of_lt (by linarith) one_pos
  have hSint : MeasureTheory.IntegrableOn (fun t : ℝ => Sx t * t ^ (-s)) (Set.Ioi 1) := by
    refine ((hD.add hLL).add (hpow.const_mul M)).congr_fun (fun t _ => ?_) measurableSet_Ioi
    simp only [Pi.add_apply, hSx]; ring
  -- summability of the prime sum
  have hsum : Summable (fun n : ℕ => if n.Prime then (n : ℝ) ^ (-s) else 0) := by
    refine Summable.of_nonneg_of_le (fun n => ?_) (fun n => ?_)
      (Real.summable_nat_rpow_inv.mpr hs)
    · split_ifs <;> positivity
    · split_ifs
      · rw [Real.rpow_neg (Nat.cast_nonneg _)]
      · positivity
  -- Abel summation
  have habel := tendsto_sum_mul_atTop_nhds_one_sub_integral₀ (f := fun t : ℝ => t ^ (1 - s)) c
    (by simp [hcdef, Nat.not_prime_zero])
    (fun t ht => by
      have : (0:ℝ) < t := lt_of_lt_of_le one_pos ht
      exact (differentiableAt_id.rpow_const (Or.inl this.ne')))
    (by
      rw [show deriv (fun t : ℝ => t ^ (1 - s)) = fun t => (1 - s) * t ^ (-s) from funext hderiv]
      refine ContinuousOn.locallyIntegrableOn ?_ measurableSet_Ici
      refine ContinuousOn.mul continuousOn_const ?_
      exact ContinuousOn.rpow_const continuousOn_id
        (fun t ht => Or.inl (lt_of_lt_of_le one_pos ht).ne'))
    (l := 0) ?_ (g := fun t => deriv (fun t : ℝ => t ^ (1 - s)) t * ∑ k ∈ Finset.Icc 0 ⌊t⌋₊, c k)
    (Asymptotics.isBigO_refl _ _) ?_
  rotate_left
  · -- h_lim
    show Tendsto (fun n : ℕ => (n:ℝ) ^ (1 - s) * ∑ k ∈ Finset.Icc 0 n, c k) atTop (𝓝 0)
    have hε : 0 < s - 1 := by linarith
    have hC : ∀ n : ℕ, 2 ≤ n → 0 ≤ ∑ k ∈ Finset.Icc 0 n, c k ∧
        ∑ k ∈ Finset.Icc 0 n, c k ≤ Real.log n + (|M| + K / Real.log 2) := by
      intro n hn
      rw [mertens_S_icc n]
      have h2 : (2:ℝ) ≤ n := by exact_mod_cast hn
      have hb := hMK n h2
      rw [Nat.floor_natCast] at hb
      have hl : 0 < Real.log n := Real.log_pos (by linarith)
      have hll : Real.log (Real.log n) ≤ Real.log n :=
        (Real.log_le_sub_one_of_pos hl).trans (by linarith)
      have hl2 : Real.log 2 ≤ Real.log n := Real.log_le_log (by norm_num) h2
      have hKl : K / Real.log n ≤ K / Real.log 2 :=
        div_le_div_of_nonneg_left hK0 (Real.log_pos (by norm_num)) hl2
      refine ⟨Finset.sum_nonneg (fun p _ => by positivity), ?_⟩
      have := (abs_le.mp hb).2
      have := le_abs_self M
      linarith
    have hup : Tendsto (fun x : ℝ => x ^ (1 - s) * (Real.log x + (|M| + K / Real.log 2)))
        atTop (𝓝 0) := by
      have h1 : Tendsto (fun x : ℝ => Real.log x / x ^ (s - 1)) atTop (𝓝 0) :=
        (isLittleO_log_rpow_atTop hε).tendsto_div_nhds_zero
      have h2 : Tendsto (fun x : ℝ => x ^ (1 - s)) atTop (𝓝 0) := by
        have := tendsto_rpow_neg_atTop hε
        simpa [neg_sub] using this
      have h3 := h1.add (h2.mul_const (|M| + K / Real.log 2))
      rw [zero_add, zero_mul] at h3
      refine h3.congr' ?_
      filter_upwards [eventually_gt_atTop 0] with x hx
      rw [show (1 - s) = -(s - 1) by ring, Real.rpow_neg hx.le]
      field_simp
    have hup' := hup.comp tendsto_natCast_atTop_atTop
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hup' ?_ ?_
    · filter_upwards [eventually_ge_atTop 2] with n hn
      exact mul_nonneg (by positivity) (hC n hn).1
    · filter_upwards [eventually_ge_atTop 2] with n hn
      exact mul_le_mul_of_nonneg_left (hC n hn).2 (by positivity)
  · -- integrable at filter
    refine ⟨Set.Ioi 1, Ioi_mem_atTop 1, ?_⟩
    have : MeasureTheory.IntegrableOn (fun t => (1 - s) * (Sx t * t ^ (-s))) (Set.Ioi 1) :=
      hSint.const_mul (1 - s)
    refine this.congr_fun (fun t _ => ?_) measurableSet_Ioi
    simp only [hderiv, hSc]; ring
  have hlim2 := hsum.hasSum.tendsto_sum_nat.comp (tendsto_add_atTop_nat 1)
  have heq : ∀ n : ℕ, ∑ k ∈ Finset.Icc 0 n, (fun t : ℝ => t ^ (1 - s)) k * c k =
      (fun N => ∑ i ∈ Finset.range N, if i.Prime then (i : ℝ) ^ (-s) else 0) (n + 1) := by
    intro n
    simp only
    rw [show Finset.range (n + 1) = Finset.Icc 0 n by ext; simp only [Finset.mem_range, Finset.mem_Icc]; omega]
    apply Finset.sum_congr rfl
    intro k _
    simp only [hcdef]
    split_ifs with hk
    · have hk0 : (0:ℝ) < k := by exact_mod_cast hk.pos
      rw [Real.rpow_sub hk0, Real.rpow_one, Real.rpow_neg hk0.le]
      field_simp
    · simp
  simp_rw [heq] at habel
  have huniq := tendsto_nhds_unique habel hlim2
  suffices hX : (s - 1) * ∫ t in Set.Ioi 1, (∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) * t ^ (-s) =
      ∑' n : ℕ, (if n.Prime then (n : ℝ) ^ (-s) else 0) by
    rw [hX]; exact hsum.hasSum
  rw [← huniq]
  simp_rw [hderiv, hSc]
  rw [show (fun t : ℝ => (1 - s) * t ^ (-s) * Sx t) = fun t => (1 - s) * (Sx t * t ^ (-s)) by
    funext t; ring]
  rw [MeasureTheory.integral_const_mul]
  ring

theorem mertens_decay_bound (M K : ℝ) (hK0 : 0 ≤ K)
    (hMK : ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x)
    (T : ℝ) (hT : 2 ≤ T) (s : ℝ) (hs : 1 < s) :
    |(s - 1) * ∫ t in Set.Ioi 1,
        ((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-s)| ≤
      (s - 1) * (T ^ 2 * ∫ t in Set.Ioi 1,
        |((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-(2:ℝ))|) +
      K / Real.log T := by
  set D : ℝ → ℝ := fun t => (∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M
    with hD
  have hDs := mertens_D_integrable M K hK0 hMK s hs
  have hD2 := mertens_D_integrable M K hK0 hMK 2 one_lt_two
  set C2 := ∫ t in Set.Ioi 1, |D t * t ^ (-(2:ℝ))| with hC2
  have hT0 : (0:ℝ) < T := by linarith
  have hlT : 0 < Real.log T := Real.log_pos (by linarith)
  rw [← Set.Ioc_union_Ioi_eq_Ioi (show (1:ℝ) ≤ T by linarith)]
  rw [MeasureTheory.setIntegral_union Set.Ioc_disjoint_Ioi_same measurableSet_Ioi
    (hDs.mono_set Set.Ioc_subset_Ioi_self)
    (hDs.mono_set (Set.Ioi_subset_Ioi (by linarith)))]
  -- first piece
  have hP1 : |∫ t in Set.Ioc 1 T, D t * t ^ (-s)| ≤ T ^ 2 * C2 := by
    have hg' : MeasureTheory.IntegrableOn (fun t => T ^ 2 * |D t * t ^ (-(2:ℝ))|) (Set.Ioi 1) :=
      hD2.norm.const_mul (T ^ 2)
    have hg : MeasureTheory.IntegrableOn (fun t => T ^ 2 * |D t * t ^ (-(2:ℝ))|) (Set.Ioc 1 T) :=
      hg'.mono_set Set.Ioc_subset_Ioi_self
    have h1 := MeasureTheory.norm_integral_le_of_norm_le hg
      (f := fun t => D t * t ^ (-s)) ?_
    · refine (Real.norm_eq_abs _ ▸ h1).trans ?_
      rw [MeasureTheory.integral_const_mul]
      refine mul_le_mul_of_nonneg_left ?_ (by positivity)
      exact MeasureTheory.setIntegral_mono_set hD2.norm
        (Filter.Eventually.of_forall (fun t => abs_nonneg _))
        Set.Ioc_subset_Ioi_self.eventuallyLE
    · refine (MeasureTheory.ae_restrict_iff' measurableSet_Ioc).mpr
        (Filter.Eventually.of_forall ?_)
      intro t ht
      have ht1 : 1 < t := ht.1
      have htT : t ≤ T := ht.2
      have ht0 : 0 < t := by linarith
      have hts : t ^ (-s) ≤ 1 := Real.rpow_le_one_of_one_le_of_nonpos ht1.le (by linarith)
      have ht2 : 1 ≤ T ^ 2 * t ^ (-(2:ℝ)) := by
        rw [Real.rpow_neg ht0.le, Real.rpow_two, ← div_eq_mul_inv, le_div_iff₀ (by positivity)]
        nlinarith
      rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_of_pos (Real.rpow_pos_of_pos ht0 _),
        abs_of_pos (Real.rpow_pos_of_pos ht0 _)]
      have hDa := abs_nonneg (D t)
      calc |D t| * t ^ (-s) ≤ |D t| * 1 := mul_le_mul_of_nonneg_left hts hDa
        _ ≤ |D t| * (T ^ 2 * t ^ (-(2:ℝ))) := mul_le_mul_of_nonneg_left ht2 hDa
        _ = T ^ 2 * (|D t| * t ^ (-(2:ℝ))) := by ring
  -- second piece
  have hP2 : |∫ t in Set.Ioi T, D t * t ^ (-s)| ≤ K / Real.log T * (T ^ (1 - s) / (s - 1)) := by
    have hpow : MeasureTheory.IntegrableOn (fun t : ℝ => t ^ (-s)) (Set.Ioi T) :=
      integrableOn_Ioi_rpow_of_lt (by linarith) hT0
    have h1 := MeasureTheory.norm_integral_le_of_norm_le (hpow.const_mul (K / Real.log T))
      (f := fun t => D t * t ^ (-s)) ?_
    · refine (Real.norm_eq_abs _ ▸ h1).trans (le_of_eq ?_)
      rw [MeasureTheory.integral_const_mul, integral_Ioi_rpow_of_lt (by linarith) hT0]
      congr 1
      rw [show -s + 1 = 1 - s by ring, neg_div, ← div_neg, neg_sub]
    · refine (MeasureTheory.ae_restrict_iff' measurableSet_Ioi).mpr
        (Filter.Eventually.of_forall ?_)
      intro t ht
      have htT : T < t := ht
      have ht0 : 0 < t := by linarith
      have hb := hMK t (by linarith)
      have hlt : Real.log T ≤ Real.log t := Real.log_le_log hT0 htT.le
      have hKl : K / Real.log t ≤ K / Real.log T := div_le_div_of_nonneg_left hK0 hlT hlt
      rw [Real.norm_eq_abs, abs_mul, abs_of_pos (Real.rpow_pos_of_pos ht0 _)]
      exact mul_le_mul_of_nonneg_right (hb.trans hKl) (Real.rpow_pos_of_pos ht0 _).le
  have hs1 : 0 < s - 1 := by linarith
  have hTs : T ^ (1 - s) ≤ 1 := Real.rpow_le_one_of_one_le_of_nonpos (by linarith) (by linarith)
  have hKT : 0 ≤ K / Real.log T := by positivity
  rw [abs_mul, abs_of_pos hs1]
  calc (s - 1) * |(∫ t in Set.Ioc 1 T, D t * t ^ (-s)) + ∫ t in Set.Ioi T, D t * t ^ (-s)|
      ≤ (s - 1) * (T ^ 2 * C2 + K / Real.log T * (T ^ (1 - s) / (s - 1))) := by
        refine mul_le_mul_of_nonneg_left ((abs_add_le _ _).trans (add_le_add hP1 hP2)) hs1.le
    _ = (s - 1) * (T ^ 2 * C2) + K / Real.log T * T ^ (1 - s) := by
        field_simp
    _ ≤ (s - 1) * (T ^ 2 * C2) + K / Real.log T := by
        gcongr
        calc K / Real.log T * T ^ (1 - s) ≤ K / Real.log T * 1 :=
              mul_le_mul_of_nonneg_left hTs hKT
          _ = K / Real.log T := mul_one _

theorem mertens_decay (M K : ℝ) (hK0 : 0 ≤ K)
    (hMK : ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x) :
    Tendsto (fun s : ℝ => (s - 1) * ∫ t in Set.Ioi 1,
        ((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-s))
      (𝓝[>] 1) (𝓝 0) := by
  rw [Metric.tendsto_nhds]
  intro ε hε
  set C2 := ∫ t in Set.Ioi 1,
    |((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-(2:ℝ))| with hC2
  have hC20 : 0 ≤ C2 := MeasureTheory.integral_nonneg (fun t => abs_nonneg _)
  set T := Real.exp (2 * K / ε + 1) with hTdef
  have hT2 : 2 ≤ T := by
    have h1 : Real.exp 1 ≤ T := Real.exp_le_exp.mpr (by have : 0 ≤ 2 * K / ε := by positivity
                                                        linarith)
    have := Real.exp_one_gt_d9
    linarith
  have hlogT : Real.log T = 2 * K / ε + 1 := Real.log_exp _
  have hKT : K / Real.log T < ε / 2 := by
    rw [hlogT, div_lt_iff₀ (by positivity)]
    have : ε / 2 * (2 * K / ε + 1) = K + ε / 2 := by field_simp
    rw [this]; linarith
  set B := T ^ 2 * C2 with hB
  have hB0 : 0 ≤ B := by positivity
  set δ := min 1 (ε / (2 * (B + 1))) with hδ
  have hδ0 : 0 < δ := lt_min one_pos (by positivity)
  filter_upwards [Ioo_mem_nhdsGT (show (1:ℝ) < 1 + δ by linarith)] with s hs
  have hs1 : 1 < s := hs.1
  have hbound := mertens_decay_bound M K hK0 hMK T hT2 s hs1
  rw [Real.dist_eq, sub_zero]
  have hsδ : s - 1 < ε / (2 * (B + 1)) := by
    have := min_le_right 1 (ε / (2 * (B + 1))); linarith [hs.2]
  have : (s - 1) * B < ε / 2 := by
    calc (s - 1) * B ≤ (s - 1) * (B + 1) := by nlinarith
      _ < ε / (2 * (B + 1)) * (B + 1) := by
          exact mul_lt_mul_of_pos_right hsδ (by linarith)
      _ = ε / 2 := by field_simp
  linarith

theorem mertens_h_bound (s : ℝ) (hs : 1 ≤ s) (n : ℕ) :
    ‖(if n.Prime then -Real.log (1 - (n : ℝ) ^ (-s)) - (n : ℝ) ^ (-s) else 0)‖ ≤
      2 * ((n : ℝ) ^ 2)⁻¹ := by
  by_cases hn : n.Prime
  · simp only [hn, ite_true]
    obtain ⟨h0, h1, h2⟩ := mertens_rpow_le_inv n hn s hs
    obtain ⟨b0, b1⟩ := mertens_neg_log_bound _ h0 (h1.trans h2)
    rw [Real.norm_eq_abs, abs_of_nonneg b0]
    refine b1.trans ?_
    rw [← inv_pow]
    gcongr
  · simp [hn]

theorem mertens_h_summable (s : ℝ) (hs : 1 ≤ s) :
    Summable (fun n : ℕ => if n.Prime then -Real.log (1 - (n : ℝ) ^ (-s)) - (n : ℝ) ^ (-s)
      else 0) :=
  Summable.of_norm_bounded ((Real.summable_nat_pow_inv.mpr one_lt_two).mul_left 2)
    (mertens_h_bound s hs)

theorem mertens_M_add_H (M K : ℝ) (hK0 : 0 ≤ K)
    (hMK : ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x) :
    M + (∑' n : ℕ, if n.Prime then -Real.log (1 - (n : ℝ) ^ (-(1:ℝ))) - (n : ℝ) ^ (-(1:ℝ))
      else 0) = eulerMascheroniConstant := by
  set H := ∑' n : ℕ, if n.Prime then -Real.log (1 - (n : ℝ) ^ (-(1:ℝ))) - (n : ℝ) ^ (-(1:ℝ))
      else 0 with hH
  set E : ℝ → ℝ := fun s => (s - 1) * ∫ t in Set.Ioi 1,
        ((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-s) with hE
  set Hs : ℝ → ℝ := fun s => ∑' n : ℕ,
        if n.Prime then -Real.log (1 - (n : ℝ) ^ (-s)) - (n : ℝ) ^ (-s) else 0 with hHs
  -- the key identity for s > 1
  have hid : ∀ s : ℝ, 1 < s → Real.log (riemannZeta (s : ℂ)).re + Real.log (s - 1) =
      E s - eulerMascheroniConstant + M + Hs s := by
    intro s hs
    have hP := mertens_prime_sum_hasSum M K hK0 hMK s hs
    have hHsum := mertens_h_summable s hs.le
    rw [mertens_log_zeta s hs]
    have hsplit : (fun n : ℕ => if n.Prime then -Real.log (1 - (n : ℝ) ^ (-s)) else 0) =
        fun n => (if n.Prime then (n : ℝ) ^ (-s) else 0) +
          (if n.Prime then -Real.log (1 - (n : ℝ) ^ (-s)) - (n : ℝ) ^ (-s) else 0) := by
      funext n; split_ifs <;> ring
    rw [hsplit, hP.summable.tsum_add hHsum, hP.tsum_eq]
    -- integral identities
    have hD := mertens_D_integrable M K hK0 hMK s hs
    have hLL := Real.integrableOn_log_log_mul_rpow hs
    have hpow : MeasureTheory.IntegrableOn (fun t : ℝ => t ^ (-s)) (Set.Ioi 1) :=
      integrableOn_Ioi_rpow_of_lt (by linarith) one_pos
    have hint : ∫ t in Set.Ioi 1, (∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) * t ^ (-s) =
        (∫ t in Set.Ioi 1,
          ((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-s)) +
        (∫ t in Set.Ioi 1, Real.log (Real.log t) * t ^ (-s)) +
        M * ∫ t in Set.Ioi 1, t ^ (-s) := by
      have hDL : MeasureTheory.IntegrableOn (fun t : ℝ =>
          ((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-s) +
          Real.log (Real.log t) * t ^ (-s)) (Set.Ioi 1) := hD.add hLL
      have hMp : MeasureTheory.IntegrableOn (fun t : ℝ => M * t ^ (-s)) (Set.Ioi 1) :=
        hpow.const_mul M
      have e : ∫ t in Set.Ioi 1, (∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) * t ^ (-s) =
          ∫ t in Set.Ioi 1,
            ((((∑ p ∈ primesLE ⌊t⌋₊, (1 : ℝ) / p) - Real.log (Real.log t) - M) * t ^ (-s) +
            Real.log (Real.log t) * t ^ (-s)) + M * t ^ (-s)) :=
        MeasureTheory.setIntegral_congr_fun measurableSet_Ioi (fun t _ => by ring)
      rw [e, MeasureTheory.integral_add hDL hMp, MeasureTheory.integral_add hD hLL,
        MeasureTheory.integral_const_mul]
    have hpowI : ∫ t in Set.Ioi (1:ℝ), t ^ (-s) = 1 / (s - 1) := by
      rw [integral_Ioi_rpow_of_lt (by linarith) one_pos, Real.one_rpow]
      have : -s + 1 = -(s - 1) := by ring
      rw [this, neg_div_neg_eq]
    have hγ := Real.eulerMascheroniConstant_eq_neg_integral_log_log hs
    have hs1 : s - 1 ≠ 0 := by linarith
    rw [hint, hpowI, hγ]
    simp only [hE, hHs]
    field_simp
    ring
  -- limits
  have hL : Tendsto (fun s : ℝ => Real.log (riemannZeta (s : ℂ)).re + Real.log (s - 1))
      (𝓝[>] 1) (𝓝 0) :=
    (Asymptotics.isLittleO_one_iff ℝ).mp log_riemannZeta_add_log_sub_isLittleO_ofReal
  have hR : Tendsto (fun s : ℝ => E s - eulerMascheroniConstant + M + Hs s)
      (𝓝[>] 1) (𝓝 (0 - eulerMascheroniConstant + M + H)) :=
    (((mertens_decay M K hK0 hMK).sub tendsto_const_nhds).add tendsto_const_nhds).add
      mertens_ppow_tendsto
  have hR' : Tendsto (fun s : ℝ => Real.log (riemannZeta (s : ℂ)).re + Real.log (s - 1))
      (𝓝[>] 1) (𝓝 (0 - eulerMascheroniConstant + M + H)) := by
    refine hR.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with s hs
    exact (hid s hs).symm
  have := tendsto_nhds_unique hL hR'
  linarith

theorem mertens_third (M K : ℝ) (hK0 : 0 ≤ K)
    (hMK : ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x) :
    Tendsto (fun x : ℝ => (∏ p ∈ primesLE ⌊x⌋₊, (1 - (1 : ℝ) / p)) * Real.log x) atTop
      (𝓝 (Real.exp (-eulerMascheroniConstant))) := by
  set h : ℕ → ℝ := fun n => if n.Prime then -Real.log (1 - (n : ℝ) ^ (-(1:ℝ))) -
      (n : ℝ) ^ (-(1:ℝ)) else 0 with hh
  have hMH := mertens_M_add_H M K hK0 hMK
  have hsum : Summable h := mertens_h_summable 1 le_rfl
  set F : ℝ → ℝ := fun x => -((∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M)
      - M - ∑ n ∈ Finset.range (⌊x⌋₊ + 1), h n with hF
  have hF1 : Tendsto (fun x : ℝ =>
      (∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M) atTop (𝓝 0) := by
    have hK : Tendsto (fun x : ℝ => K / Real.log x) atTop (𝓝 0) := by
      have := (tendsto_log_atTop.inv_tendsto_atTop).const_mul K
      simpa [div_eq_mul_inv] using this
    rw [tendsto_zero_iff_abs_tendsto_zero]
    refine squeeze_zero' (Filter.Eventually.of_forall (fun x => abs_nonneg _)) ?_ hK
    filter_upwards [eventually_ge_atTop 2] with x hx using hMK x hx
  have hF2 : Tendsto (fun x : ℝ => ∑ n ∈ Finset.range (⌊x⌋₊ + 1), h n) atTop
      (𝓝 (∑' n, h n)) :=
    hsum.hasSum.tendsto_sum_nat.comp ((tendsto_add_atTop_nat 1).comp tendsto_nat_floor_atTop)
  have hFlim : Tendsto F atTop (𝓝 (-eulerMascheroniConstant)) := by
    have := ((hF1.neg).sub_const M).sub hF2
    rw [show -eulerMascheroniConstant = -0 - M - ∑' n, h n by rw [← hMH]; ring]
    exact this
  refine (Real.continuous_exp.tendsto _ |>.comp hFlim).congr' ?_
  filter_upwards [eventually_ge_atTop 2] with x hx
  have hx1 : 1 < x := by linarith
  have hlx : 0 < Real.log x := Real.log_pos hx1
  have hfac : ∀ p ∈ primesLE ⌊x⌋₊, 0 < 1 - (1 : ℝ) / p := by
    intro p hp
    have : (2:ℝ) ≤ p := by exact_mod_cast two_le_of_mem_primesLE hp
    rw [sub_pos, div_lt_one (by linarith)]; linarith
  have hQ : 0 < ∏ p ∈ primesLE ⌊x⌋₊, (1 - (1 : ℝ) / p) := Finset.prod_pos hfac
  have hsumh : ∑ n ∈ Finset.range (⌊x⌋₊ + 1), h n = ∑ p ∈ primesLE ⌊x⌋₊,
      (-Real.log (1 - (p : ℝ) ^ (-(1:ℝ))) - (p : ℝ) ^ (-(1:ℝ))) := by
    rw [primesLE_eq_filter_range, Finset.sum_filter]
  have hlogs : ∑ p ∈ primesLE ⌊x⌋₊, Real.log (1 - (1 : ℝ) / p) =
      -(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - ∑ p ∈ primesLE ⌊x⌋₊,
        (-Real.log (1 - (p : ℝ) ^ (-(1:ℝ))) - (p : ℝ) ^ (-(1:ℝ))) := by
    rw [← Finset.sum_neg_distrib, ← Finset.sum_sub_distrib]
    apply Finset.sum_congr rfl
    intro p _
    rw [Real.rpow_neg_one, inv_eq_one_div]; ring
  simp only [Function.comp_apply]
  rw [← Real.exp_log (mul_pos hQ hlx)]
  congr 1
  rw [Real.log_mul hQ.ne' hlx.ne', Real.log_prod (fun p hp => (hfac p hp).ne'), hlogs]
  simp only [hF]
  rw [hsumh]
  ring


/-- Mertens' second theorem. There is a fixed number M (Mertens' constant) and a fixed bound K
such that for every cut-off x ≥ 2 the reciprocals of the primes up to x add up to
log log x + M, with an error at most K / log x:
|∑_{p ≤ x} 1/p − log log x − M| ≤ K / log x. -/
theorem sum_inv_prime_eq_loglog_add_const :
    ∃ M K : ℝ, ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, (1 : ℝ) / p) - Real.log (Real.log x) - M| ≤ K / Real.log x := by
  obtain ⟨M, K, _, h⟩ := mertens_second_real
  exact ⟨M, K, h⟩

/-- Mertens' first theorem. The primes up to x, each weighted by log p / p, add up to log x
give or take a fixed amount: there is a fixed bound K with
|∑_{p ≤ x} log p / p − log x| ≤ K for every x ≥ 2. -/
theorem sum_log_prime_div_prime_eq_log_add_bounded :
    ∃ K : ℝ, ∀ x : ℝ, 2 ≤ x →
      |(∑ p ∈ primesLE ⌊x⌋₊, Real.log p / p) - Real.log x| ≤ K := by
  obtain ⟨K, _, h⟩ := mertens_first_real
  exact ⟨K, h⟩

/-- Mertens' third theorem. The product of (1 − 1/p) over the primes up to x is about
e^−γ / log x, with γ Euler's constant: the product times log x tends to e^−γ as x grows. -/
theorem prod_one_sub_inv_prime_mul_log_tendsto :
    Tendsto (fun x : ℝ => (∏ p ∈ primesLE ⌊x⌋₊, (1 - (1 : ℝ) / p)) * Real.log x) atTop
      (𝓝 (Real.exp (-eulerMascheroniConstant))) := by
  obtain ⟨M, K, hK0, hMK⟩ := mertens_second_real
  exact mertens_third M K hK0 hMK

-- Legendre's formula for p = 2, n = 10: 5 + 2 + 1 = 8, and 2^8 is the exact power of 2 in 10!.
example : 10 / 2 + 10 / 4 + 10 / 8 = 8 ∧ 2 ^ 8 ∣ 10 ! ∧ ¬ 2 ^ 9 ∣ 10 ! := by decide

-- 10! = 2^8 · 3^4 · 5^2 · 7 = 3,628,800.
example : 10 ! = 2 ^ 8 * 3 ^ 4 * 5 ^ 2 * 7 ∧ 10 ! = 3628800 := by decide

-- The prime counts in the card's table: π(10) = 4 and π(100) = 25.
example : (primesLE 10).card = 4 := by decide
example : (primesLE 100).card = 25 := by decide

#print axioms mertens_log_factorial_eq
#print axioms mertens_sum_le
#print axioms mertens_log_div_bound
#print axioms mertens_tail_bound
#print axioms mertens_sum_ge
#print axioms mertens_first_nat
#print axioms mertens_first_real
#print axioms mertens_abel_discrete
#print axioms mertens_inv_log_tendsto
#print axioms mertens_inv_log_hasSum
#print axioms mertens_loglog_step
#print axioms mertens_second_nat
#print axioms mertens_second_real
#print axioms mertens_neg_log_bound
#print axioms mertens_log_zeta
#print axioms mertens_rpow_le_inv
#print axioms mertens_ppow_tendsto
#print axioms mertens_measurable_S
#print axioms mertens_S_eq_zero
#print axioms mertens_D_integrable
#print axioms mertens_S_icc
#print axioms mertens_prime_sum_hasSum
#print axioms mertens_decay_bound
#print axioms mertens_decay
#print axioms mertens_h_bound
#print axioms mertens_h_summable
#print axioms mertens_M_add_H
#print axioms mertens_third
#print axioms sum_inv_prime_eq_loglog_add_const
#print axioms sum_log_prime_div_prime_eq_log_add_bounded
#print axioms prod_one_sub_inv_prime_mul_log_tendsto
