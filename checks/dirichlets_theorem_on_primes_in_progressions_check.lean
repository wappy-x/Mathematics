-- Dirichlet's theorem: every progression whose start shares no factor with its step holds infinitely many primes, and each such class gets the share 1/φ(q) of the sum of 1/p^s as s comes down to 1.
import Mathlib.NumberTheory.LSeries.PrimesInAP
import Mathlib.NumberTheory.LegendreSymbol.ZModChar
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.PSeries

open Filter Topology Asymptotics

section DirichletHelpers

open Complex LSeries DirichletCharacter ArithmeticFunction ArithmeticFunction.vonMangoldt
open scoped LSeries.notation

/-- On real `x > 1`, the real L-series of `residueClass a` is the real part of the auxiliary
function plus the pole term `(q.totient)⁻¹/(x-1)`. -/
lemma dirichletHelper_residueClass_tsum_eq {q : ℕ} [NeZero q] {a : ZMod q} (ha : IsUnit a)
    {x : ℝ} (hx : 1 < x) :
    ∑' n, residueClass a n / (n : ℝ) ^ x =
      (LFunctionResidueClassAux a x).re + (q.totient : ℝ)⁻¹ / (x - 1) := by
  refine ofReal_injective ?_
  simp only [ofReal_tsum, ofReal_div, ofReal_cpow (Nat.cast_nonneg _), ofReal_natCast,
    ofReal_add, ofReal_inv, ofReal_sub, ofReal_one]
  simp_rw [← LFunctionResidueClassAux_real ha hx,
    eqOn_LFunctionResidueClassAux ha <| Set.mem_ofPred.mpr (ofReal_re x ▸ hx), sub_add_cancel,
    LSeries, term]
  refine tsum_congr fun n ↦ ?_
  split_ifs with hn
  · simp only [hn, residueClass_apply_zero, ofReal_zero, zero_div]
  · rfl

/-- The real part of the auxiliary function is bounded on `[1, 2]`. -/
lemma dirichletHelper_aux_bounded {q : ℕ} [NeZero q] (a : ZMod q) :
    ∃ M : ℝ, ∀ x ∈ Set.Icc (1 : ℝ) 2, |(LFunctionResidueClassAux a x).re| ≤ M := by
  have : ContinuousOn (fun x : ℝ ↦ (LFunctionResidueClassAux a x).re) (Set.Icc 1 2) :=
    continuous_re.continuousOn.comp (t := Set.univ) (continuousOn_LFunctionResidueClassAux a)
      (fun ⦃x⦄ a ↦ trivial) |>.comp continuous_ofReal.continuousOn fun x hx ↦ by
        simpa only [Set.mem_ofPred_eq, ofReal_re] using hx.1
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn this
  exact ⟨M, fun x hx ↦ by simpa [Real.norm_eq_abs] using hM x hx⟩

/-- For a prime-class indicator, the term `log p * p^(-s)` is the prime part of the
von Mangoldt residue-class series. -/
lemma dirichletHelper_indicator_eq {q a : ℕ} (s : ℝ) (n : ℕ) :
    {p : ℕ | p.Prime ∧ p ≡ a [MOD q]}.indicator (fun p : ℕ ↦ Real.log p * (p : ℝ) ^ (-s)) n =
      (if n.Prime then residueClass (a : ZMod q) n else 0) / (n : ℝ) ^ s := by
  by_cases hp : n.Prime
  · by_cases hm : n ≡ a [MOD q]
    · have hm' : (n : ZMod q) = a := (ZMod.natCast_eq_natCast_iff _ _ _).mpr hm
      simp [Set.indicator, hp, hm, hm', vonMangoldt_apply_prime hp, Real.rpow_neg,
        div_eq_mul_inv]
    · have hm' : ¬ (n : ZMod q) = a := fun e ↦ hm ((ZMod.natCast_eq_natCast_iff _ _ _).mp e)
      simp [Set.indicator, hp, hm, hm']
  · simp [Set.indicator, hp]

lemma dirichletHelper_summable {q : ℕ} (a : ZMod q) {s : ℝ} (hs : 1 < s) :
    Summable fun n : ℕ ↦ residueClass a n / (n : ℝ) ^ s :=
  LSeries.summable_real_of_abscissaOfAbsConv_lt <|
    (abscissaOfAbsConv_residueClass_le_one a).trans_lt <| mod_cast hs

lemma dirichletHelper_summable_prime {q : ℕ} (a : ZMod q) {s : ℝ} (hs : 1 < s) :
    Summable fun n : ℕ ↦ (if n.Prime then residueClass a n else 0) / (n : ℝ) ^ s := by
  refine (dirichletHelper_summable a hs).of_nonneg_of_le (fun n ↦ ?_) (fun n ↦ ?_)
  · have := residueClass_nonneg a n
    split_ifs <;> positivity
  · refine div_le_div_of_nonneg_right ?_ (by positivity)
    split_ifs
    exacts [le_rfl, residueClass_nonneg a n]

lemma dirichletHelper_summable_nonprime {q : ℕ} (a : ZMod q) {s : ℝ} (hs : 1 < s) :
    Summable fun n : ℕ ↦ (if n.Prime then 0 else residueClass a n) / (n : ℝ) ^ s := by
  refine (dirichletHelper_summable a hs).of_nonneg_of_le (fun n ↦ ?_) (fun n ↦ ?_)
  · have := residueClass_nonneg a n
    split_ifs <;> positivity
  · refine div_le_div_of_nonneg_right ?_ (by positivity)
    split_ifs
    exacts [residueClass_nonneg a n, le_rfl]

/-- Split the residue-class series into its prime part and its prime-power part. -/
lemma dirichletHelper_split {q a : ℕ} {s : ℝ} (hs : 1 < s) :
    ∑' n, residueClass (a : ZMod q) n / (n : ℝ) ^ s =
      ∑' p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}, Real.log p * ((p : ℕ) : ℝ) ^ (-s) +
        ∑' n : ℕ, (if n.Prime then 0 else residueClass (a : ZMod q) n) / (n : ℝ) ^ s := by
  have h1 := tsum_subtype {p : ℕ | p.Prime ∧ p ≡ a [MOD q]}
    (fun p : ℕ ↦ Real.log p * (p : ℝ) ^ (-s))
  have h1' : ∑' p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}, Real.log p * ((p : ℕ) : ℝ) ^ (-s) =
      ∑' n : ℕ, (if n.Prime then residueClass (a : ZMod q) n else 0) / (n : ℝ) ^ s := by
    rw [show (∑' p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}, Real.log p * ((p : ℕ) : ℝ) ^ (-s)) =
      ∑' p : ({p : ℕ | p.Prime ∧ p ≡ a [MOD q]} : Set ℕ), Real.log p * ((p : ℕ) : ℝ) ^ (-s)
      from rfl, h1]
    exact tsum_congr (dirichletHelper_indicator_eq s)
  rw [h1', ← (dirichletHelper_summable_prime _ hs).tsum_add
    (dirichletHelper_summable_nonprime _ hs)]
  refine tsum_congr fun n ↦ ?_
  split_ifs <;> simp

/-- The prime-power part is bounded by its value at `s = 1`. -/
lemma dirichletHelper_nonprime_le {q : ℕ} (a : ZMod q) {s : ℝ} (hs : 1 < s) :
    0 ≤ ∑' n : ℕ, (if n.Prime then 0 else residueClass a n) / (n : ℝ) ^ s ∧
    ∑' n : ℕ, (if n.Prime then 0 else residueClass a n) / (n : ℝ) ^ s ≤
      ∑' n : ℕ, (if n.Prime then 0 else residueClass a n) / n := by
  have hnn (n : ℕ) : 0 ≤ (if n.Prime then 0 else residueClass a n) := by
    have := residueClass_nonneg a n
    split_ifs <;> positivity
  refine ⟨tsum_nonneg fun n ↦ div_nonneg (hnn n) (by positivity), ?_⟩
  refine Summable.tsum_le_tsum (fun n ↦ ?_) (dirichletHelper_summable_nonprime a hs)
    (summable_residueClass_non_primes_div a)
  rcases n.eq_zero_or_pos with rfl | hn
  · simp
  · refine div_le_div_of_nonneg_left (hnn n) (mod_cast hn) ?_
    conv_lhs => rw [← Real.rpow_one n]
    exact Real.rpow_le_rpow_of_exponent_le (by exact_mod_cast hn) hs.le

/-- Termwise derivative of the prime sum. -/
lemma dirichletHelper_hasDerivAt {q a : ℕ} {s : ℝ} (hs : 1 < s) :
    HasDerivAt (fun t : ℝ ↦ ∑' p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}, ((p : ℕ) : ℝ) ^ (-t))
      (∑' p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}, -(Real.log p * ((p : ℕ) : ℝ) ^ (-s))) s := by
  set s₀ : ℝ := (1 + s) / 2 with hs₀
  have h1s₀ : 1 < s₀ := by rw [hs₀]; linarith
  have hss₀ : s₀ < s := by rw [hs₀]; linarith
  have hu : Summable fun p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]} ↦
      Real.log p * ((p : ℕ) : ℝ) ^ (-s₀) := by
    have := (summable_subtype_iff_indicator (s := {p : ℕ | p.Prime ∧ p ≡ a [MOD q]})
      (f := fun p : ℕ ↦ Real.log p * (p : ℝ) ^ (-s₀))).mpr
      ((dirichletHelper_summable_prime (a : ZMod q) h1s₀).congr
        fun n ↦ (dirichletHelper_indicator_eq s₀ n).symm)
    exact this
  refine hasDerivAt_tsum_of_isPreconnected hu isOpen_Ioi isPreconnected_Ioi
    (g := fun (p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}) (t : ℝ) ↦ ((p : ℕ) : ℝ) ^ (-t))
    (g' := fun (p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}) (t : ℝ) ↦
      -(Real.log p * ((p : ℕ) : ℝ) ^ (-t)))
    (fun p y _ ↦ ?_) (fun p y hy ↦ ?_) (y₀ := s) hss₀ ?_ hss₀
  · have hp : (0 : ℝ) < (p : ℕ) := by exact_mod_cast p.2.1.pos
    have := (Real.hasStrictDerivAt_const_rpow hp (-y)).hasDerivAt.comp y (hasDerivAt_neg y)
    exact this.congr_deriv (by ring)
  · have hp : (1 : ℝ) ≤ (p : ℕ) := by exact_mod_cast p.2.1.one_lt.le
    have hy' : s₀ < y := hy
    rw [norm_neg, Real.norm_eq_abs, abs_of_nonneg (by positivity [Real.log_nonneg hp])]
    gcongr
  · exact (Real.summable_nat_rpow.mpr (by linarith : -s < -1)).subtype
      (fun p : ℕ ↦ p.Prime ∧ p ≡ a [MOD q])

end DirichletHelpers

/-- Dirichlet's theorem: if the step q is positive and the start a shares no factor with q,
then infinitely many primes p satisfy p ≡ a (mod q). -/
theorem infinitely_many_primes_in_progression {q a : ℕ} (hq : 0 < q) (h : Nat.Coprime a q) :
    {p : ℕ | p.Prime ∧ p ≡ a [MOD q]}.Infinite := by
  exact Nat.infinite_setOfPred_prime_and_modEq hq.ne' h

/-- The weighted equal share (Dirichlet density): if the step q is positive and a shares no
factor with q, then as s comes down to 1 from above, the sum of 1/p^s over the primes
p ≡ a (mod q) equals (1/φ(q)) · log(1/(s − 1)) plus an amount that stays bounded. -/
theorem sum_inv_rpow_primes_in_class_eq_log_div_totient_add_bounded {q a : ℕ} (hq : 0 < q)
    (h : Nat.Coprime a q) :
    (fun s : ℝ => (∑' p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}, ((p : ℕ) : ℝ) ^ (-s))
        - ((q.totient : ℝ))⁻¹ * Real.log (1 / (s - 1)))
      =O[𝓝[>] 1] (fun _ => (1 : ℝ)) := by
  have : NeZero q := ⟨hq.ne'⟩
  have hA : IsUnit (a : ZMod q) := (ZMod.isUnit_iff_coprime a q).mpr h
  obtain ⟨M, hM⟩ := dirichletHelper_aux_bounded (a : ZMod q)
  set E₁ : ℝ := ∑' n : ℕ, (if n.Prime then 0 else
    ArithmeticFunction.vonMangoldt.residueClass (a : ZMod q) n) / n with hE₁
  set P : ℝ → ℝ := fun s ↦ ∑' p : {p : ℕ // p.Prime ∧ p ≡ a [MOD q]}, ((p : ℕ) : ℝ) ^ (-s)
    with hP
  set H : ℝ → ℝ := fun s ↦ P s + (q.totient : ℝ)⁻¹ * Real.log (s - 1) with hH
  set H' : ℝ → ℝ := fun s ↦
    -(ArithmeticFunction.vonMangoldt.LFunctionResidueClassAux (a : ZMod q) s).re +
      ∑' n : ℕ, (if n.Prime then 0 else
        ArithmeticFunction.vonMangoldt.residueClass (a : ZMod q) n) / (n : ℝ) ^ s with hH'
  have hderiv : ∀ s ∈ Set.Ioc (1 : ℝ) 2, HasDerivWithinAt H (H' s) (Set.Ioc 1 2) s := by
    intro s hs
    refine HasDerivAt.hasDerivWithinAt ?_
    have h1 := dirichletHelper_hasDerivAt (q := q) (a := a) hs.1
    have h2 := ((hasDerivAt_id s).sub_const 1).log (sub_ne_zero.mpr hs.1.ne')
    have h3 := h1.add (h2.const_mul (q.totient : ℝ)⁻¹)
    refine h3.congr_deriv ?_
    have e1 := dirichletHelper_residueClass_tsum_eq hA hs.1
    have e2 := dirichletHelper_split (q := q) (a := a) hs.1
    rw [tsum_neg]
    have e3 : (q.totient : ℝ)⁻¹ * (1 / (s - 1)) = (q.totient : ℝ)⁻¹ / (s - 1) := by ring
    simp only [hH', id_eq, e3]
    linarith
  have hbound : ∀ s ∈ Set.Ioc (1 : ℝ) 2, ‖H' s‖ ≤ M + E₁ := by
    intro s hs
    have hg := hM s (Set.mem_Icc_of_Ioc hs)
    have hE := dirichletHelper_nonprime_le (a : ZMod q) hs.1
    rw [Real.norm_eq_abs]
    simp only [hH']
    rw [abs_le]
    constructor
    · have := neg_abs_le (ArithmeticFunction.vonMangoldt.LFunctionResidueClassAux
        (a : ZMod q) s).re
      have := le_abs_self (ArithmeticFunction.vonMangoldt.LFunctionResidueClassAux
        (a : ZMod q) s).re
      linarith [hE.1, hE.2]
    · have := neg_abs_le (ArithmeticFunction.vonMangoldt.LFunctionResidueClassAux
        (a : ZMod q) s).re
      linarith [hE.1, hE.2]
  have h2mem : (2 : ℝ) ∈ Set.Ioc (1 : ℝ) 2 := Set.right_mem_Ioc.mpr one_lt_two
  refine IsBigO.of_bound (M + E₁ + ‖H 2‖) ?_
  filter_upwards [Ioc_mem_nhdsGT one_lt_two] with s hs
  have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le hderiv hbound (convex_Ioc 1 2) h2mem hs
  have heq : P s - (q.totient : ℝ)⁻¹ * Real.log (1 / (s - 1)) = H s := by
    simp only [hH, one_div, Real.log_inv]
    ring
  have hMpos : 0 ≤ M + E₁ := by
    have hg := hM 2 (Set.mem_Icc_of_Ioc h2mem)
    have hE := dirichletHelper_nonprime_le (a : ZMod q) (s := 2) one_lt_two
    linarith [abs_nonneg (ArithmeticFunction.vonMangoldt.LFunctionResidueClassAux
      (a : ZMod q) (2 : ℝ)).re]
  have hdist : ‖s - 2‖ ≤ 1 := by
    rw [Real.norm_eq_abs, abs_le]
    constructor <;> linarith [hs.1, hs.2]
  show ‖P s - (q.totient : ℝ)⁻¹ * Real.log (1 / (s - 1))‖ ≤ (M + E₁ + ‖H 2‖) * ‖(1 : ℝ)‖
  rw [heq, norm_one, mul_one]
  calc ‖H s‖ = ‖(H s - H 2) + H 2‖ := by ring_nf
    _ ≤ ‖H s - H 2‖ + ‖H 2‖ := norm_add_le _ _
    _ ≤ (M + E₁) * ‖s - 2‖ + ‖H 2‖ := by gcongr
    _ ≤ (M + E₁) * 1 + ‖H 2‖ := by gcongr
    _ = M + E₁ + ‖H 2‖ := by ring

/-- The class filter mod 4: for odd n, (χ₀(n) − χ₄(n))/2 is 1 when n ≡ 3 (mod 4) and 0 when
n ≡ 1 (mod 4); here χ₀(n) = 1 because n is odd. -/
theorem chi_four_filter_picks_three_mod_four (n : ℕ) (hn : n % 2 = 1) :
    (1 - ZMod.χ₄ (n : ZMod 4)) / 2 = if n % 4 = 3 then 1 else 0 := by
  rcases (show n % 4 = 1 ∨ n % 4 = 3 by omega) with h4 | h4
  · rw [ZMod.χ₄_nat_one_mod_four h4, if_neg (by omega)]
    rfl
  · rw [ZMod.χ₄_nat_three_mod_four h4, if_pos h4]
    rfl

-- The first primes 3 mod 4 are 3, 7, 11, 19, 23; the skipped member 15 is 3 × 5.
example : [3, 7, 11, 19, 23].all (fun p => p.Prime ∧ p % 4 = 3) := by decide
example : ¬ Nat.Prime 15 ∧ 15 = 3 * 5 := by decide

-- Mod 4 only the classes 1 and 3 share no factor with the step: φ(4) = 2.
example : Nat.totient 4 = 2 := by decide

-- The class filter at n = 7 gives 1, and at n = 5 gives 0.
example : (1 - ZMod.χ₄ (7 : ZMod 4)) / 2 = 1 := by decide
example : (1 - ZMod.χ₄ (5 : ZMod 4)) / 2 = 0 := by decide

-- Euclid's trick for 3 mod 4: 4 × 3 × 7 × 11 − 1 = 923 = 13 × 71, and 71 ≡ 3 (mod 4).
example : 4 * 3 * 7 * 11 - 1 = 923 ∧ 923 = 13 * 71 ∧ Nat.Prime 71 ∧ 71 % 4 = 3 := by
  norm_num

-- The same trick fails for 1 mod 4: 4 × 5 × 13 × 17 − 1 = 4419 = 3 × 3 × 491, each factor 3 mod 4.
example : 4 * 5 * 13 * 17 - 1 = 4419 ∧ 4419 = 3 * 3 * 491 ∧ Nat.Prime 491 ∧ 491 % 4 = 3 := by
  norm_num

-- The class 2 mod 4 holds just one prime below 100, namely 2; the class 0 mod 4 holds none.
example : ((Finset.range 100).filter (fun p => p.Prime ∧ p % 4 = 2)) = {2} := by decide
example : ((Finset.range 100).filter (fun p => p.Prime ∧ p % 4 = 0)) = ∅ := by decide

-- Below 100 the classes 1 and 3 mod 4 hold 11 and 13 primes.
example : ((Finset.range 100).filter (fun p => p.Prime ∧ p % 4 = 1)).card = 11 := by decide
example : ((Finset.range 100).filter (fun p => p.Prime ∧ p % 4 = 3)).card = 13 := by decide

#print axioms dirichletHelper_residueClass_tsum_eq
#print axioms dirichletHelper_aux_bounded
#print axioms dirichletHelper_indicator_eq
#print axioms dirichletHelper_summable
#print axioms dirichletHelper_summable_prime
#print axioms dirichletHelper_summable_nonprime
#print axioms dirichletHelper_split
#print axioms dirichletHelper_nonprime_le
#print axioms dirichletHelper_hasDerivAt
#print axioms infinitely_many_primes_in_progression
#print axioms sum_inv_rpow_primes_in_class_eq_log_div_totient_add_bounded
#print axioms chi_four_filter_picks_three_mod_four
