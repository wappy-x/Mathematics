-- The L-function: Hasse's bound |a_p| ≤ 2√p makes the Euler product of the local factors 1/(1 - a_p p^(-s) + p^(1-2s)) at good primes and 1/(1 - a_p p^(-s)) at bad ones converge to a nonzero number for Re s > 3/2.
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Analysis.SpecialFunctions.Log.Summable
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.AlgebraicGeometry.EllipticCurve.Weierstrass
import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.NumberTheory.SumPrimeReciprocals

open PowerSeries

/-- The local factor of L(E, s) at the prime p: `1/(1 - a_p p^(-s) + p^(1-2s))` at a good prime,
and the shorter `1/(1 - a_p p^(-s))` at a bad prime. -/
noncomputable def localFactor (good : Prop) [Decidable good] (a : ℤ) (p : ℕ) (s : ℂ) : ℂ :=
  (1 - (a : ℂ) * (p : ℂ) ^ (-s) + (if good then (p : ℂ) ^ (1 - 2 * s) else 0))⁻¹

lemma quad_ne_zero_aux (a p : ℝ) (hp : 0 < p) (ha : a ^ 2 ≤ 4 * p) (z : ℂ)
    (hz : p * ‖z‖ ^ 2 < 1) : 1 - (a : ℂ) * z + (p : ℂ) * z ^ 2 ≠ 0 := by
  intro h
  have hre := congrArg Complex.re h
  have him := congrArg Complex.im h
  simp [sq] at hre him
  rw [Complex.sq_norm, Complex.normSq_apply] at hz
  have him' : z.im * (2 * p * z.re - a) = 0 := by linarith
  rcases mul_eq_zero.mp him' with hy | hx
  · rw [hy] at hre hz
    have h1 : (2 * p * z.re - a) ^ 2 + (4 * p - a ^ 2) = 0 := by nlinarith
    have h3 : a ^ 2 = 4 * p := by nlinarith [sq_nonneg (2 * p * z.re - a)]
    have h4 : a = 2 * p * z.re := by nlinarith [sq_nonneg (2 * p * z.re - a)]
    rw [h4] at h3
    nlinarith
  · have h4 : a = 2 * p * z.re := by linarith
    rw [h4] at hre
    nlinarith

#print axioms quad_ne_zero_aux

/-- The card's main claim. Take one local factor per prime: the quadratic one at each good prime,
where Hasse's bound `|a_p| ≤ 2√p` holds, and the linear one at each bad prime, where `a_p` is
`1`, `-1` or `0` (split node, non-split node, cusp). Then for every complex `s` with
`Re s > 3/2` the product of all the local factors converges, and its value L(E, s) is not 0. -/
theorem euler_product_converges_of_hasse_bound
    (bad : Set Nat.Primes) [DecidablePred (· ∈ bad)] (a : Nat.Primes → ℤ)
    (hasse : ∀ p : Nat.Primes, p ∉ bad → |(a p : ℝ)| ≤ 2 * Real.sqrt (p : ℕ))
    (hbad : ∀ p ∈ bad, a p = 1 ∨ a p = -1 ∨ a p = 0)
    {s : ℂ} (hs : 3 / 2 < s.re) :
    ∃ L : ℂ, L ≠ 0 ∧
      HasProd (fun p : Nat.Primes => localFactor (p ∉ bad) (a p) (p : ℕ) s) L := by
  set z : Nat.Primes → ℂ := fun p => ((p : ℕ) : ℂ) ^ (-s) with hz
  set t : Nat.Primes → ℝ := fun p => ((p : ℕ) : ℝ) ^ ((1 : ℝ) / 2 - s.re) with ht
  set u : Nat.Primes → ℂ := fun p =>
    -((a p : ℂ) * z p) + (if p ∉ bad then ((p : ℕ) : ℂ) * z p ^ 2 else 0) with hu
  -- basic facts about one prime
  have hp1 : ∀ p : Nat.Primes, (1 : ℝ) < ((p : ℕ) : ℝ) := fun p => by
    exact_mod_cast p.2.one_lt
  have hnorm : ∀ p : Nat.Primes, ‖z p‖ = ((p : ℕ) : ℝ) ^ (-s.re) := fun p => by
    simp only [hz]
    rw [Complex.norm_natCast_cpow_of_pos p.2.pos]
    simp
  have hsqrt : ∀ p : Nat.Primes, Real.sqrt ((p : ℕ) : ℝ) * ‖z p‖ = t p := fun p => by
    rw [hnorm, Real.sqrt_eq_rpow, ← Real.rpow_add (by linarith [hp1 p])]
    simp only [ht]
    ring_nf
  have ht_nonneg : ∀ p, 0 ≤ t p := fun p => Real.rpow_nonneg (by linarith [hp1 p]) _
  have ht_lt : ∀ p, t p < 1 := fun p => Real.rpow_lt_one_of_one_lt_of_neg (hp1 p) (by linarith)
  have hsq1 : ∀ p : Nat.Primes, 1 ≤ Real.sqrt ((p : ℕ) : ℝ) := fun p => by
    rw [Real.one_le_sqrt]; exact (hp1 p).le
  have hz_le : ∀ p, ‖z p‖ ≤ t p := fun p => by
    rw [← hsqrt]
    have := norm_nonneg (z p)
    nlinarith [hsq1 p]
  have hpz2 : ∀ p : Nat.Primes, ‖((p : ℕ) : ℂ) * z p ^ 2‖ = t p ^ 2 := fun p => by
    rw [norm_mul, norm_pow, ← hsqrt, mul_pow, Real.sq_sqrt (by linarith [hp1 p])]
    simp
  -- the local factor in the form (1 + u)⁻¹
  have hfac : ∀ p : Nat.Primes,
      localFactor (p ∉ bad) (a p) (p : ℕ) s = (1 + u p)⁻¹ := fun p => by
    have hp0 : ((p : ℕ) : ℂ) ≠ 0 := by exact_mod_cast p.2.ne_zero
    have hpow : ((p : ℕ) : ℂ) ^ (1 - 2 * s) = ((p : ℕ) : ℂ) * z p ^ 2 := by
      simp only [hz]
      rw [show (1 : ℂ) - 2 * s = 1 + (-s) + (-s) by ring, Complex.cpow_add _ _ hp0,
        Complex.cpow_add _ _ hp0, Complex.cpow_one]
      ring
    simp only [localFactor, hu, hpow]
    congr 1
    split_ifs <;> ring
  -- bound on u
  have hbound : ∀ p, ‖u p‖ ≤ 3 * t p := fun p => by
    simp only [hu]
    have ht2 : t p ^ 2 ≤ t p := by nlinarith [ht_nonneg p, ht_lt p]
    by_cases hp : p ∈ bad
    · simp only [hp, not_true_eq_false, ite_false, add_zero, norm_neg, norm_mul,
        Complex.norm_intCast]
      have ha : |((a p : ℤ) : ℝ)| ≤ 1 := by
        rcases hbad p hp with h | h | h <;> simp [h]
      have := norm_nonneg (z p)
      nlinarith [hz_le p, ht_nonneg p]
    · simp only [hp, not_false_eq_true, ite_true]
      refine (norm_add_le _ _).trans ?_
      rw [hpz2, norm_neg, norm_mul, Complex.norm_intCast]
      have h1 : |((a p : ℤ) : ℝ)| * ‖z p‖ ≤ 2 * t p := by
        rw [← hsqrt, ← mul_assoc]
        exact mul_le_mul_of_nonneg_right (hasse p hp) (norm_nonneg _)
      linarith
  -- nonvanishing
  have hne : ∀ p, 1 + u p ≠ 0 := fun p => by
    simp only [hu]
    by_cases hp : p ∈ bad
    · simp only [hp, not_true_eq_false, ite_false, add_zero]
      intro h
      have h' : (a p : ℂ) * z p = 1 := by linear_combination -h
      have := congrArg norm h'
      rw [norm_mul, Complex.norm_intCast, norm_one] at this
      have ha : |((a p : ℤ) : ℝ)| ≤ 1 := by
        rcases hbad p hp with h | h | h <;> simp [h]
      have := norm_nonneg (z p)
      nlinarith [hz_le p, ht_lt p, abs_nonneg ((a p : ℤ) : ℝ)]
    · simp only [hp, not_false_eq_true, ite_true]
      have ha2 : ((a p : ℤ) : ℝ) ^ 2 ≤ 4 * ((p : ℕ) : ℝ) := by
        have h := hasse p hp
        have h0 : 0 ≤ 2 * Real.sqrt ((p : ℕ) : ℝ) := by positivity
        have : |((a p : ℤ) : ℝ)| ^ 2 ≤ (2 * Real.sqrt ((p : ℕ) : ℝ)) ^ 2 :=
          pow_le_pow_left₀ (abs_nonneg _) h 2
        rw [sq_abs, mul_pow, Real.sq_sqrt (by linarith [hp1 p])] at this
        linarith
      have hz2 : ((p : ℕ) : ℝ) * ‖z p‖ ^ 2 < 1 := by
        have h := hpz2 p
        rw [norm_mul, norm_pow, Complex.norm_natCast] at h
        rw [h]
        nlinarith [ht_nonneg p, ht_lt p]
      have := quad_ne_zero_aux ((a p : ℤ) : ℝ) ((p : ℕ) : ℝ) (by linarith [hp1 p]) ha2 (z p) hz2
      push_cast at this
      convert this using 1
      ring
  -- summability
  have hsum : Summable fun p => ‖u p‖ := by
    refine Summable.of_nonneg_of_le (fun p => norm_nonneg _) hbound ?_
    exact (Nat.Primes.summable_rpow.mpr (by linarith)).mul_left 3
  have hmul : Multipliable fun p => 1 + u p := multipliable_one_add_of_summable hsum
  have hne0 : ∏' p, (1 + u p) ≠ 0 := tprod_one_add_ne_zero_of_summable hne hsum
  refine ⟨(∏' p, (1 + u p))⁻¹, inv_ne_zero hne0, ?_⟩
  simp only [hfac]
  exact hmul.hasProd.inv₀ hne0

/-- Step 4: one over the good local quadratic, as a power series in T, has coefficients
`a_(p^k)` that start 1, a_p and then obey `a_(p^k) = a_p a_(p^(k-1)) - p a_(p^(k-2))`. -/
theorem inverse_local_factor_series (ap p : ℤ) (c : ℕ → ℤ)
    (h0 : c 0 = 1) (h1 : c 1 = ap) (hrec : ∀ k, c (k + 2) = ap * c (k + 1) - p * c k) :
    (1 - C ap * X + C p * X ^ 2) * PowerSeries.mk c = 1 := by
  ext n
  rcases n with _ | _ | n
  · simp [sub_mul, add_mul, mul_assoc, h0]
  · simp [sub_mul, add_mul, mul_assoc, coeff_X_pow_mul', h0, h1, coeff_one]
  · simp [sub_mul, add_mul, mul_assoc, coeff_X_pow_mul', hrec, coeff_one]

/-- Step 3: a cusp curve is a line in disguise. Over any finite field F the cusp curve
`y^2 = x^3` has exactly |F| points (x, y), one for each v through (v^2, v^3); with O that is
|F| + 1, which is why the local factor at a cusp is 1. -/
theorem cusp_curve_card (F : Type*) [Field F] [Fintype F] [DecidableEq F] :
    Fintype.card {q : F × F // q.2 ^ 2 = q.1 ^ 3} = Fintype.card F := by
  refine (Fintype.card_congr ?_).symm
  refine
    { toFun := fun v => ⟨(v ^ 2, v ^ 3), by ring⟩
      invFun := fun q => if q.1.1 = 0 then 0 else q.1.2 / q.1.1
      left_inv := ?_
      right_inv := ?_ }
  · intro v
    by_cases hv : v = 0
    · simp [hv]
    · simp only [pow_eq_zero_iff, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, hv, ite_false]
      field_simp
  · rintro ⟨⟨x, y⟩, h⟩
    simp only at h
    by_cases hx : x = 0
    · have : y = 0 := by
        rw [hx] at h; simpa using h
      simp [hx, this]
    · simp only [hx, ite_false]
      ext
      · simp only
        rw [div_pow, h]; field_simp
      · simp only
        rw [div_pow, show y ^ 3 = y * y ^ 2 by ring, h]; field_simp

-- The house point (3, 5) lies on y^2 = x^3 - 2.
example : (5 : ℤ) ^ 2 = 3 ^ 3 - 2 := by norm_num

-- Mathlib's discriminant of y^2 = x^3 - 2 is -1728 = -2^6 * 3^3.
example : (⟨0, 0, 0, 0, -2⟩ : WeierstrassCurve ℤ).Δ = -1728 := by
  simp only [WeierstrassCurve.Δ, WeierstrassCurve.b₂, WeierstrassCurve.b₄,
    WeierstrassCurve.b₆, WeierstrassCurve.b₈]
  norm_num
example : (-1728 : ℤ) = -(2 ^ 6 * 3 ^ 3) := by norm_num

-- Point counts with O: 3 over F_2, 4 over F_3, 6 over F_5, 7 over F_7 (affine points plus 1).
example : Fintype.card {q : ZMod 2 × ZMod 2 // q.2 ^ 2 = q.1 ^ 3 - 2} + 1 = 3 := by decide
example : Fintype.card {q : ZMod 3 × ZMod 3 // q.2 ^ 2 = q.1 ^ 3 - 2} + 1 = 4 := by decide
example : Fintype.card {q : ZMod 5 × ZMod 5 // q.2 ^ 2 = q.1 ^ 3 - 2} + 1 = 6 := by decide
example : Fintype.card {q : ZMod 7 × ZMod 7 // q.2 ^ 2 = q.1 ^ 3 - 2} + 1 = 7 := by decide

-- a_5 = 5 + 1 - 6 = 0 and a_7 = 7 + 1 - 7 = 1.
example : (5 + 1 - 6 : ℤ) = 0 := by norm_num
example : (7 + 1 - 7 : ℤ) = 1 := by norm_num

-- Mod 2 the curve is y^2 = x^3 and mod 3 it is y^2 = (x + 1)^3.
example : ∀ x y : ZMod 2, (y ^ 2 = x ^ 3 - 2 ↔ y ^ 2 = x ^ 3) := by decide
example : ∀ x y : ZMod 3, (y ^ 2 = x ^ 3 - 2 ↔ y ^ 2 = (x + 1) ^ 3) := by decide

-- Local factors at s = 2, where T = 1/p^2: 125/126 at p = 5 and 343/337 at p = 7.
example : ((1 : ℚ) - 0 * (1 / 5 ^ 2) + 5 * (1 / 5 ^ 2) ^ 2)⁻¹ = 125 / 126 := by norm_num
example : ((1 : ℚ) - 1 * (1 / 7 ^ 2) + 7 * (1 / 7 ^ 2) ^ 2)⁻¹ = 343 / 337 := by norm_num

-- The first four factors at s = 2: 1 · 1 · 125/126 · 343/337 = 6125/6066.
example : (1 : ℚ) * 1 * (125 / 126) * (343 / 337) = 6125 / 6066 := by norm_num

-- a_25 = a_5 · a_5 - 5 · a_1 = -5.
example : (0 : ℤ) * 0 - 5 * 1 = -5 := by norm_num

#print axioms euler_product_converges_of_hasse_bound
#print axioms inverse_local_factor_series
#print axioms cusp_curve_card
