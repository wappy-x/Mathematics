-- The zeta function: for complex s with real part above 1 the sum of 1/n^s converges to a holomorphic function equal to the product over the primes of 1/(1 - 1/p^s), at s = 2 it is π^2/6, its reciprocal 6/π^2 is the limiting share of coprime pairs, and the sum of 1/p over the primes diverges.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Rat.Defs
import Mathlib

open Filter Topology

lemma telescope_bound (P : ℕ) :
    ∑ n ∈ (Finset.range (P + 1)).filter (fun n => 2 ≤ n),
      ((1 : ℝ) / ((n : ℝ) - 1) - 1 / n) ≤ 1 - 1 / (P : ℝ) := by
  induction P with
  | zero => simp [Finset.sum_filter]
  | succ P ih =>
    rw [Finset.range_add_one, Finset.filter_insert]
    rcases Nat.eq_zero_or_pos P with rfl | hP
    · simp [Finset.sum_filter]
    · have h2 : 2 ≤ P + 1 := by omega
      simp only [h2, ↓reduceIte]
      rw [Finset.sum_insert (by simp)]
      have : ((P + 1 : ℕ) : ℝ) - 1 = P := by push_cast; ring
      rw [this]
      push_cast
      linarith

#print axioms telescope_bound

lemma harmonic_le_euler (P : ℕ) :
    ∑ n ∈ Finset.Icc 1 P, ((n : ℝ))⁻¹ ≤
      ∏ p ∈ (P + 1).primesBelow, (1 - ((p : ℝ))⁻¹)⁻¹ := by
  let f : ℕ →* ℝ :=
    { toFun := fun n => ((n : ℝ))⁻¹
      map_one' := by simp
      map_mul' := by intro a b; push_cast; rw [mul_inv] }
  have hf : ∀ {p : ℕ}, p.Prime → ‖f p‖ < 1 := by
    intro p hp
    have : (1 : ℝ) < p := by exact_mod_cast hp.one_lt
    simp only [f, MonoidHom.coe_mk, OneHom.coe_mk, norm_inv, Real.norm_natCast]
    exact inv_lt_one_of_one_lt₀ this
  have H := (EulerProduct.summable_and_hasSum_smoothNumbers_prod_primesBelow_geometric hf
    (P + 1)).2
  simp only [f, MonoidHom.coe_mk, OneHom.coe_mk] at H
  have key := sum_le_hasSum ((Finset.Icc 1 P).subtype (· ∈ (P + 1).smoothNumbers))
    (fun i _ => by positivity) H
  refine le_trans (le_of_eq ?_) key
  rw [Finset.sum_subtype_eq_sum_filter (f := fun n : ℕ => ((n : ℝ))⁻¹),
    Finset.filter_true_of_mem]
  · intro n hn
    rw [Finset.mem_Icc] at hn
    exact Nat.mem_smoothNumbers_of_lt (by omega) (by omega)

#print axioms harmonic_le_euler

lemma moebius_sum_gcd (a b M : ℕ) (ha : 1 ≤ a) (haM : a ≤ M) :
    (if Nat.Coprime a b then (1 : ℤ) else 0) =
      ∑ d ∈ Finset.range (M + 1),
        if d ∣ a ∧ d ∣ b then (ArithmeticFunction.moebius d : ℤ) else 0 := by
  have h1 : (if Nat.Coprime a b then (1 : ℤ) else 0) =
      ∑ d ∈ (Nat.gcd a b).divisors, (ArithmeticFunction.moebius d : ℤ) := by
    have := congrArg (fun f => f (Nat.gcd a b))
      (ArithmeticFunction.moebius_mul_coe_zeta)
    simp only [ArithmeticFunction.coe_mul_zeta_apply, ArithmeticFunction.one_apply] at this
    rw [this]
  rw [h1, ← Finset.sum_filter]
  apply Finset.sum_congr _ (fun _ _ => rfl)
  have hg : Nat.gcd a b ≠ 0 := by
    intro h; rw [Nat.gcd_eq_zero_iff] at h; omega
  ext d
  simp only [Nat.mem_divisors, Finset.mem_filter, Finset.mem_range, ← Nat.dvd_gcd_iff]
  constructor
  · rintro ⟨hd, -⟩
    refine ⟨?_, hd⟩
    have := Nat.le_of_dvd (Nat.pos_of_ne_zero hg) hd
    have := Nat.gcd_le_left b (show 0 < a by omega)
    omega
  · rintro ⟨-, hd⟩
    exact ⟨hd, hg⟩

#print axioms moebius_sum_gcd

lemma card_dvd_Icc (d M : ℕ) :
    ((Finset.Icc 1 M).filter (fun a => d ∣ a)).card = M / d := by
  have : Finset.Icc 1 M = Finset.Ioc 0 M := by
    ext x; simp only [Finset.mem_Icc, Finset.mem_Ioc]; omega
  rw [this]
  exact Nat.Ioc_filter_dvd_card_eq_div M d

#print axioms card_dvd_Icc

lemma coprime_count (M : ℕ) :
    ((((Finset.Icc 1 M ×ˢ Finset.Icc 1 M).filter
        (fun q : ℕ × ℕ => Nat.Coprime q.1 q.2)).card : ℤ)) =
      ∑ d ∈ Finset.range (M + 1),
        (ArithmeticFunction.moebius d : ℤ) * ((M / d : ℕ) : ℤ) ^ 2 := by
  rw [Finset.natCast_card_filter]
  have hq : ∀ q ∈ Finset.Icc 1 M ×ˢ Finset.Icc 1 M,
      (if Nat.Coprime q.1 q.2 then (1 : ℤ) else 0) =
      ∑ d ∈ Finset.range (M + 1),
        if d ∣ q.1 ∧ d ∣ q.2 then (ArithmeticFunction.moebius d : ℤ) else 0 := by
    intro q hq
    rw [Finset.mem_product, Finset.mem_Icc] at hq
    exact moebius_sum_gcd q.1 q.2 M hq.1.1 hq.1.2
  rw [Finset.sum_congr rfl hq]
  rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro d _
  rw [← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul, mul_comm]
  congr 1
  rw [Finset.filter_product (p := fun a => d ∣ a) (q := fun b => d ∣ b), Finset.card_product,
    card_dvd_Icc]
  push_cast; ring

#print axioms coprime_count

lemma moebius_series_two :
    ∑' d : ℕ, (ArithmeticFunction.moebius d : ℝ) / (d : ℝ) ^ 2 = 6 / Real.pi ^ 2 := by
  have h := ArithmeticFunction.LSeries_zeta_mul_Lseries_moebius (s := 2) (by norm_num)
  rw [ArithmeticFunction.LSeries_zeta_eq_riemannZeta (by norm_num), riemannZeta_two] at h
  have hL : LSeries (fun n => (ArithmeticFunction.moebius n : ℂ)) 2 =
      ((∑' d : ℕ, (ArithmeticFunction.moebius d : ℝ) / (d : ℝ) ^ 2 : ℝ) : ℂ) := by
    rw [LSeries, Complex.ofReal_tsum]
    apply tsum_congr
    intro n
    rw [LSeries.term_def]
    rcases eq_or_ne n 0 with rfl | hn
    · simp
    · simp only [hn, ↓reduceIte]
      have : ((n : ℂ) ^ (2 : ℂ)) = (n : ℂ) ^ (2 : ℕ) := by
        exact_mod_cast Complex.cpow_natCast (n : ℂ) 2
      rw [this]
      push_cast
      rfl
  have hpi : (Real.pi : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr Real.pi_ne_zero
  have h2 : LSeries (fun n => (ArithmeticFunction.moebius n : ℂ)) 2 = 6 / (Real.pi : ℂ) ^ 2 := by
    field_simp
    field_simp at h
    linear_combination h
  rw [hL] at h2
  exact_mod_cast h2

#print axioms moebius_series_two

/-- For every complex s with real part above 1, the sum of 1/n^s over n = 1, 2, 3, ... converges;
the function zeta(s) it defines is holomorphic on the half-plane Re s > 1; zeta(s) equals the
product over all primes p of 1/(1 - 1/p^s); and zeta(2) = π^2/6. -/
theorem zeta_sum_holomorphic_and_euler_product :
    (∀ s : ℂ, 1 < s.re → Summable (fun n : ℕ => 1 / ((n : ℂ) + 1) ^ s)) ∧
    DifferentiableOn ℂ (fun s : ℂ => ∑' n : ℕ, 1 / ((n : ℂ) + 1) ^ s) {s : ℂ | 1 < s.re} ∧
    (∀ s : ℂ, 1 < s.re →
      HasProd (fun p : Nat.Primes => 1 / (1 - 1 / ((p : ℕ) : ℂ) ^ s))
        (∑' n : ℕ, 1 / ((n : ℂ) + 1) ^ s)) ∧
    ∑' n : ℕ, 1 / ((n : ℂ) + 1) ^ (2 : ℂ) = (Real.pi : ℂ) ^ 2 / 6 := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro s hs
    have h := (Complex.summable_one_div_nat_cpow (p := s)).mpr hs
    have h2 := (summable_nat_add_iff 1).mpr h
    simpa [Nat.cast_add, Nat.cast_one] using h2
  · refine DifferentiableOn.congr (f := riemannZeta) ?_ ?_
    · intro s hs
      have hs' : s ≠ 1 := by
        rintro rfl; simp at hs
      exact (differentiableAt_riemannZeta hs').differentiableWithinAt
    · intro s hs
      exact (zeta_eq_tsum_one_div_nat_add_one_cpow hs).symm
  · intro s hs
    rw [← zeta_eq_tsum_one_div_nat_add_one_cpow hs]
    have := riemannZeta_eulerProduct_hasProd hs
    convert this using 2 with p
    rw [Complex.cpow_neg, one_div, one_div]
  · rw [← zeta_eq_tsum_one_div_nat_add_one_cpow (by norm_num), riemannZeta_two]

/-- The share of coprime ordered pairs (a, b) with 1 ≤ a, b ≤ M tends to 6/π^2 = 1/zeta(2)
as M grows. -/
theorem coprime_pair_share_tendsto_six_div_pi_sq :
    Tendsto (fun M : ℕ =>
      ((((Finset.Icc 1 M ×ˢ Finset.Icc 1 M).filter (fun q : ℕ × ℕ => Nat.Coprime q.1 q.2)).card : ℝ)
        / (M : ℝ) ^ 2))
      atTop (𝓝 (6 / Real.pi ^ 2)) := by
  set F : ℕ → ℕ → ℝ := fun M d =>
    (ArithmeticFunction.moebius d : ℝ) * (((M / d : ℕ) : ℝ) / M) ^ 2 with hF
  have hEq : ∀ M : ℕ,
      ((((Finset.Icc 1 M ×ˢ Finset.Icc 1 M).filter
        (fun q : ℕ × ℕ => Nat.Coprime q.1 q.2)).card : ℝ) / (M : ℝ) ^ 2) = ∑' d, F M d := by
    intro M
    have hc := coprime_count M
    have hc' : ((((Finset.Icc 1 M ×ˢ Finset.Icc 1 M).filter
        (fun q : ℕ × ℕ => Nat.Coprime q.1 q.2)).card : ℝ)) =
        ∑ d ∈ Finset.range (M + 1),
          (ArithmeticFunction.moebius d : ℝ) * ((M / d : ℕ) : ℝ) ^ 2 := by
      have := congrArg (Int.cast : ℤ → ℝ) hc
      push_cast at this
      exact this
    rw [hc', tsum_eq_sum (s := Finset.range (M + 1)), Finset.sum_div]
    · apply Finset.sum_congr rfl
      intro d _
      simp only [hF]
      ring
    · intro d hd
      rw [Finset.mem_range] at hd
      have : M / d = 0 := Nat.div_eq_of_lt (by omega)
      simp [hF, this]
  simp_rw [hEq]
  rw [← moebius_series_two]
  apply tendsto_tsum_of_dominated_convergence (bound := fun d : ℕ => 1 / (d : ℝ) ^ 2)
  · exact Real.summable_one_div_nat_pow.mpr (by norm_num)
  · intro d
    rcases Nat.eq_zero_or_pos d with rfl | hd
    · simp [hF]
    · have hdR : (0 : ℝ) < d := by exact_mod_cast hd
      have hlim : Tendsto (fun M : ℕ => ((M / d : ℕ) : ℝ) / M) atTop (𝓝 (1 / (d : ℝ))) := by
        have hlow : Tendsto (fun M : ℕ => 1 / (d : ℝ) - 1 / (M : ℝ)) atTop
            (𝓝 (1 / (d : ℝ))) := by
          have := (tendsto_one_div_atTop_nhds_zero_nat (𝕜 := ℝ)).const_sub (1 / (d : ℝ))
          simpa using this
        apply tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow tendsto_const_nhds
        · filter_upwards [eventually_ge_atTop 1] with M hM
          have hMR : (0 : ℝ) < M := by exact_mod_cast hM
          have h1 : M < M / d * d + d := Nat.lt_div_mul_add hd
          have h1R : (M : ℝ) ≤ ((M / d : ℕ) : ℝ) * d + d := by exact_mod_cast h1.le
          rw [sub_le_iff_le_add, ← add_div, div_le_div_iff₀ hdR hMR]
          linarith
        · filter_upwards [eventually_ge_atTop 1] with M hM
          have hMR : (0 : ℝ) < M := by exact_mod_cast hM
          have h2 : ((M / d : ℕ) : ℝ) ≤ (M : ℝ) / d := Nat.cast_div_le
          rw [div_le_div_iff₀ hMR hdR]
          rw [le_div_iff₀ hdR] at h2
          linarith
      have := (hlim.pow 2).const_mul (ArithmeticFunction.moebius d : ℝ)
      convert this using 2
      field_simp
  · filter_upwards [eventually_ge_atTop 1] with M hM d
    have hMR : (0 : ℝ) < M := by exact_mod_cast hM
    rcases Nat.eq_zero_or_pos d with rfl | hd
    · simp [hF]
    · have hdR : (0 : ℝ) < d := by exact_mod_cast hd
      simp only [hF, norm_mul, norm_pow, Real.norm_eq_abs]
      have hmu : |(ArithmeticFunction.moebius d : ℝ)| ≤ 1 := by
        exact_mod_cast ArithmeticFunction.abs_moebius_le_one
      have h2 : ((M / d : ℕ) : ℝ) ≤ (M : ℝ) / d := Nat.cast_div_le
      have h3 : |((M / d : ℕ) : ℝ) / M| ≤ 1 / d := by
        rw [abs_of_nonneg (by positivity), div_le_iff₀ hMR]
        calc ((M / d : ℕ) : ℝ) ≤ (M : ℝ) / d := h2
          _ = 1 / d * M := by ring
      have h4 : |((M / d : ℕ) : ℝ) / M| ^ 2 ≤ (1 / d) ^ 2 :=
        pow_le_pow_left₀ (abs_nonneg _) h3 2
      calc |(ArithmeticFunction.moebius d : ℝ)| * |((M / d : ℕ) : ℝ) / M| ^ 2
          ≤ 1 * (1 / d) ^ 2 := mul_le_mul hmu h4 (by positivity) (by norm_num)
        _ = 1 / (d : ℝ) ^ 2 := by ring

/-- The sum of 1/p over the primes up to P is at least ln ln(P + 1) - 1, for every P,
so the sum of 1/p over all primes diverges. -/
theorem sum_one_div_primes_diverges :
    (∀ P : ℕ, Real.log (Real.log ((P : ℝ) + 1)) - 1 ≤
      ∑ p ∈ (Finset.range (P + 1)).filter Nat.Prime, (1 : ℝ) / p) ∧
    ¬ Summable (fun p : Nat.Primes => (1 : ℝ) / (p : ℕ)) := by
  refine ⟨?_, Nat.Primes.not_summable_one_div⟩
  intro P
  have hPB : (P + 1).primesBelow = (Finset.range (P + 1)).filter Nat.Prime := rfl
  set S := ∑ p ∈ (Finset.range (P + 1)).filter Nat.Prime, (1 : ℝ) / p with hS
  have hS0 : 0 ≤ S := Finset.sum_nonneg (fun _ _ => by positivity)
  -- product bound
  have hE : ∏ p ∈ (P + 1).primesBelow, (1 - ((p : ℝ))⁻¹)⁻¹ ≤ Real.exp (S + 1) := by
    have h1 : ∏ p ∈ (P + 1).primesBelow, (1 - ((p : ℝ))⁻¹)⁻¹ ≤
        ∏ p ∈ (P + 1).primesBelow, Real.exp ((1 : ℝ) / ((p : ℝ) - 1)) := by
      apply Finset.prod_le_prod₀
      · intro p hp
        have hp' := (Nat.prime_of_mem_primesBelow hp).one_lt
        have : (1 : ℝ) < p := by exact_mod_cast hp'
        have : (p : ℝ)⁻¹ < 1 := inv_lt_one_of_one_lt₀ this
        have : 0 < 1 - (p : ℝ)⁻¹ := by linarith
        positivity
      · intro p hp
        have hp' := (Nat.prime_of_mem_primesBelow hp).one_lt
        have hp1 : (1 : ℝ) < p := by exact_mod_cast hp'
        have heq : (1 - ((p : ℝ))⁻¹)⁻¹ = 1 / ((p : ℝ) - 1) + 1 := by
          field_simp
          ring
        rw [heq]
        exact Real.add_one_le_exp _
    rw [← Real.exp_sum] at h1
    refine h1.trans (Real.exp_le_exp.mpr ?_)
    have hsplit : ∑ p ∈ (P + 1).primesBelow, (1 : ℝ) / ((p : ℝ) - 1) =
        S + ∑ p ∈ (P + 1).primesBelow, ((1 : ℝ) / ((p : ℝ) - 1) - 1 / p) := by
      rw [hS, hPB, ← Finset.sum_add_distrib]
      apply Finset.sum_congr rfl
      intro p _; ring
    rw [hsplit]
    have hsub : ∑ p ∈ (P + 1).primesBelow, ((1 : ℝ) / ((p : ℝ) - 1) - 1 / p) ≤
        ∑ n ∈ (Finset.range (P + 1)).filter (fun n => 2 ≤ n),
          ((1 : ℝ) / ((n : ℝ) - 1) - 1 / n) := by
      apply Finset.sum_le_sum_of_subset_of_nonneg
      · intro p hp
        rw [Nat.primesBelow, Finset.mem_filter] at hp
        rw [Finset.mem_filter]
        exact ⟨hp.1, hp.2.two_le⟩
      · intro n hn _
        rw [Finset.mem_filter] at hn
        have : (2 : ℝ) ≤ n := by exact_mod_cast hn.2
        rw [sub_nonneg]
        apply one_div_le_one_div_of_le <;> linarith
    have ht := telescope_bound P
    have : 0 ≤ 1 / (P : ℝ) := by positivity
    linarith
  have hH := harmonic_le_euler P
  have hlog : Real.log ((P : ℝ) + 1) ≤ ∑ n ∈ Finset.Icc 1 P, ((n : ℝ))⁻¹ := by
    have := log_add_one_le_harmonic P
    rw [harmonic_eq_sum_Icc] at this
    push_cast at this
    exact this
  have hchain : Real.log ((P : ℝ) + 1) ≤ Real.exp (S + 1) := hlog.trans (hH.trans hE)
  rcases Nat.eq_zero_or_pos P with rfl | hP
  · simp; linarith
  · have hpos : 0 < Real.log ((P : ℝ) + 1) := by
      apply Real.log_pos
      have : (1 : ℝ) ≤ P := by exact_mod_cast hP
      linarith
    have := Real.log_le_log hpos hchain
    rw [Real.log_exp] at this
    linarith

-- Tickets 6 and 15 share the factor 3; tickets 8 and 15 are coprime.
example : Nat.gcd 6 15 = 3 := by decide
example : Nat.Coprime 8 15 := by decide

-- Tickets 1 to 6: 23 of the 36 ordered pairs are coprime.
example : ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun q : ℕ × ℕ => Nat.Coprime q.1 q.2)).card = 23 := by
  decide

-- Splitting every pair by its gcd g: the sum over g of C(6 / g) is 6^2 = 36.
example : ∑ g ∈ Finset.Icc 1 6,
    ((Finset.Icc 1 (6 / g) ×ˢ Finset.Icc 1 (6 / g)).filter (fun q : ℕ × ℕ => Nat.Coprime q.1 q.2)).card = 36 := by
  decide

-- Four terms: 1 + 1/4 + 1/9 + 1/16 = 205/144
example : (1 : ℚ) + 1/4 + 1/9 + 1/16 = 205/144 := by norm_num

-- Tail bracket after four terms: adding 1/5 or 1/4.
example : (205 : ℚ)/144 + 1/5 = 1169/720 ∧ (205 : ℚ)/144 + 1/4 = 241/144 := by norm_num

-- Primes 2, 3, 5: (4/3)(9/8)(25/24) = 25/16.
example : (1 / (1 - 1/2^2 : ℚ)) * (1 / (1 - 1/3^2)) * (1 / (1 - 1/5^2)) = 25/16 := by norm_num

#print axioms zeta_sum_holomorphic_and_euler_product
#print axioms coprime_pair_share_tendsto_six_div_pi_sq
#print axioms sum_one_div_primes_diverges
