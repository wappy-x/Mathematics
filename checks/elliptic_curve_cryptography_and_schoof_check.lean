-- Curves for keys: the point count of y² = x³ + ax + b over the field mod an odd prime is even exactly when the cubic has a root there, the shared key needs only the secrets' product mod the order, and a smooth order lets the key be found one prime factor at a time.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Algebra.Field.ZMod
import Mathlib.Tactic.NormNum.Prime
import Mathlib.GroupTheory.Perm.Cycle.Type

open WeierstrassCurve

/-- The curve y² = x³ + a x + b, as a Mathlib Weierstrass curve with a₁ = a₂ = a₃ = 0. -/
def shortCurve {F : Type*} [Field F] (a b : F) : WeierstrassCurve F :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := a, a₆ := b }


/-- If n • g = 0, then k • g depends only on k mod n. -/
theorem nsmul_eq_mod_nsmul_of_nsmul_eq_zero {A : Type*} [AddMonoid A] (g : A) (n k : ℕ)
    (h : n • g = 0) : k • g = (k % n) • g := by
  conv_lhs => rw [← Nat.mod_add_div k n]
  have h0 : (n * (k / n)) • g = 0 := by rw [mul_comm n, mul_nsmul', h, nsmul_zero]
  rw [add_nsmul, h0, add_zero]

/-- A finite field gives finitely many points. -/
theorem finite_point_of_finite {F : Type*} [Field F] [Finite F] (W : WeierstrassCurve F) :
    Finite W.toAffine.Point :=
  haveI : Finite (Option {xy : F × F // W.toAffine.Nonsingular xy.1 xy.2}) := inferInstance
  @Finite.of_equiv _ _ this (W.toAffine.nonsingularPointEquiv).symm

/-- In ZMod p with p an odd prime, 2 ≠ 0. -/
theorem two_ne_zero_zmod_of_odd (p : ℕ) [Fact p.Prime] (hp : Odd p) : (2 : ZMod p) ≠ 0 := by
  intro h
  have h2 : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
  rw [ZMod.natCast_eq_zero_iff] at h2
  have hp2 : p = 2 := ((Nat.prime_dvd_prime_iff_eq Fact.out Nat.prime_two).mp h2)
  subst hp2
  exact absurd hp (by decide)

/-- Schoof's step for ℓ = 2. Take an odd prime p and the curve y² = x³ + a x + b over 𝔽_p, with
4a³ + 27b² ≠ 0 so that the curve is smooth. Its number of points, O included, is even exactly
when the cubic x³ + a x + b has a root in 𝔽_p (that is, exactly when a_p is even). -/
theorem card_points_even_iff_cubic_has_root (p : ℕ) [Fact p.Prime] (hp : Odd p)
    (a b : ZMod p) (hΔ : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0) :
    Even (Nat.card (shortCurve a b).toAffine.Point) ↔ ∃ x : ZMod p, x ^ 3 + a * x + b = 0 := by
  have := finite_point_of_finite (shortCurve a b)
  have h2 := two_ne_zero_zmod_of_odd p hp
  constructor
  · intro he
    have : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩
    obtain ⟨g, hg⟩ := exists_prime_addOrderOf_dvd_card' 2 (even_iff_two_dvd.mp he)
    rcases g with _ | ⟨x, y, h⟩
    · have h0 : addOrderOf (0 : (shortCurve a b).toAffine.Point) = 2 := hg
      simp at h0
    · refine ⟨x, ?_⟩
      have hgg : (2 : ℕ) • (WeierstrassCurve.Affine.Point.some x y h) = 0 := by
        rw [← hg]; exact addOrderOf_nsmul_eq_zero _
      rw [two_nsmul] at hgg
      have hy : y = (shortCurve a b).toAffine.negY x y := by
        by_contra hne
        rw [WeierstrassCurve.Affine.Point.add_self_of_Y_ne hne] at hgg
        exact WeierstrassCurve.Affine.Point.some_ne_zero _ hgg
      simp only [WeierstrassCurve.Affine.negY, shortCurve] at hy
      have hy0 : y = 0 := by
        have : 2 * y = 0 := by linear_combination hy
        rcases mul_eq_zero.mp this with h' | h'
        · exact absurd h' h2
        · exact h'
      have heq := h.1
      rw [WeierstrassCurve.Affine.equation_iff] at heq
      simp only [shortCurve, hy0] at heq
      linear_combination -heq
  · rintro ⟨x, hx⟩
    have hns : (shortCurve a b).toAffine.Nonsingular x 0 := by
      rw [WeierstrassCurve.Affine.nonsingular_iff']
      refine ⟨?_, Or.inl ?_⟩
      · rw [WeierstrassCurve.Affine.equation_iff]
        simp only [shortCurve]
        linear_combination -hx
      · simp only [shortCurve]
        intro h3
        apply hΔ
        have ha : a = -3 * x ^ 2 := by linear_combination -h3
        have hb : b = 2 * x ^ 3 := by linear_combination hx + x * h3
        rw [ha, hb]; ring
    have hP : WeierstrassCurve.Affine.Point.some x 0 hns + WeierstrassCurve.Affine.Point.some x 0 hns = 0 :=
      WeierstrassCurve.Affine.Point.add_self_of_Y_eq (by simp [shortCurve])
    have : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩
    have hord : addOrderOf (WeierstrassCurve.Affine.Point.some x 0 hns) = 2 :=
      addOrderOf_eq_prime (by rw [two_nsmul]; exact hP)
        (WeierstrassCurve.Affine.Point.some_ne_zero _)
    rw [even_iff_two_dvd, ← hord]
    exact addOrderOf_dvd_natCard _

/-- Elliptic-curve Diffie-Hellman. If n G = O, the phone's d_P (d_L G) and the lock's
d_L (d_P G) are the same point, and it equals ((d_P d_L) mod n) G: only the product of the two
secrets mod n matters. -/
theorem ecdh_shared_point_eq {F : Type*} [Field F] [DecidableEq F] (W : WeierstrassCurve F)
    (G : W.toAffine.Point) (n dP dL : ℕ) (hn : n • G = 0) :
    dP • (dL • G) = dL • (dP • G) ∧ dP • (dL • G) = ((dP * dL) % n) • G := by
  refine ⟨?_, ?_⟩
  · rw [smul_smul, smul_smul, mul_comm]
  · rw [smul_smul, mul_comm]
    exact nsmul_eq_mod_nsmul_of_nsmul_eq_zero G n _ hn

/-- The Pohlig–Hellman step. If n G = O, q divides n and Q = d G, then multiplying by n / q
sends G to a point of the subgroup of q points, and sends Q to (d mod q) times that point. So the
key d mod q is found inside a group of only q points. -/
theorem pohlig_hellman_step {F : Type*} [Field F] [DecidableEq F] (W : WeierstrassCurve F)
    (G : W.toAffine.Point) (n q d : ℕ) (hn : n • G = 0) (hq : q ∣ n) :
    q • ((n / q) • G) = 0 ∧ (n / q) • (d • G) = (d % q) • ((n / q) • G) := by
  have hq0 : q • ((n / q) • G) = 0 := by
    rw [smul_smul, Nat.mul_div_cancel' hq, hn]
  refine ⟨hq0, ?_⟩
  rw [smul_comm]
  exact nsmul_eq_mod_nsmul_of_nsmul_eq_zero _ q d hq0

/-! ### The card's worked numbers -/

-- The toy curve y² = x³ + 2x + 4 over 𝔽_13 is smooth and has 16 affine points, 17 with O.
example : (4 * 2 ^ 3 + 27 * 4 ^ 2 : ZMod 13) ≠ 0 := by decide
example : (Finset.univ.filter
    (fun P : ZMod 13 × ZMod 13 => P.2 ^ 2 = P.1 ^ 3 + 2 * P.1 + 4)).card = 16 := by decide
-- The count 17 lies in Hasse's window 14 ± 2√13, and a_p = 14 − 17 = −3.
example : ((17 : ℤ) - 14) ^ 2 ≤ 4 * 13 ∧ (13 : ℤ) + 1 - 17 = -3 := by norm_num
-- The ℓ = 2 step on the toy: the cubic has no root mod 13, and indeed a_p = −3 is odd.
example : ∀ x : ZMod 13, x ^ 3 + 2 * x + 4 ≠ 0 := by decide
-- Schoof's primes for p = 13: 2 · 3 · 5 = 30 > 4√13, since 30² > 16 · 13.
example : (2 * 3 * 5) ^ 2 > 16 * 13 := by norm_num
-- For a 256-bit p, 4√p < 2^130: the 27 primes up to 103 give a product above 2^130,
-- and the 26 primes up to 101 do not.
example : (List.range 104).filter Nat.Prime = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41,
    43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103] := by decide
example : 2 ^ 130 < 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 * 31 * 37 * 41 * 43 * 47 * 53 *
    59 * 61 * 67 * 71 * 73 * 79 * 83 * 89 * 97 * 101 * 103 := by norm_num
example : 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 * 31 * 37 * 41 * 43 * 47 * 53 *
    59 * 61 * 67 * 71 * 73 * 79 * 83 * 89 * 97 * 101 < 2 ^ 130 := by norm_num
-- ECDH: secrets 6 and 9 on a group of 17 points; 6 × 9 = 54 and 54 mod 17 = 3.
example : 6 * 9 % 17 = 3 := by norm_num
-- ECDSA mod n = 17: the toy hash 7299 gives z = 6; 1/8 = 15; s = 15 (6 + 8 · 5) = 10;
-- 1/10 = 12; u₁ = 6 · 12 = 4, u₂ = 8 · 12 = 11; and u₁ + u₂ d_S = 4 + 11 · 5 = 8 = k.
example : 7299 % 17 = 6 := by norm_num
example : (8 : ZMod 17) * 15 = 1 ∧ (15 : ZMod 17) * (6 + 8 * 5) = 10 := by decide
example : (10 : ZMod 17) * 12 = 1 ∧ (6 : ZMod 17) * 12 = 4 ∧ (8 : ZMod 17) * 12 = 11 := by decide
example : (4 : ZMod 17) + 11 * 5 = 8 := by decide
-- The mistake: s worked mod 13 instead of mod 17 gives 1/8 = 5 and s = 9.
example : (8 : ZMod 13) * 5 = 1 ∧ (5 : ZMod 13) * (6 + 8 * 5) = 9 := by decide
-- The house curve y² = x³ − 2: 6 affine points mod 7 (7 with O, equal to p: anomalous),
-- 18 mod 13 (19 with O, a prime), 41 mod 41 (42 = 2 · 3 · 7 with O).
example : (Finset.univ.filter
    (fun P : ZMod 7 × ZMod 7 => P.2 ^ 2 = P.1 ^ 3 - 2)).card = 6 := by decide
example : (Finset.univ.filter
    (fun P : ZMod 13 × ZMod 13 => P.2 ^ 2 = P.1 ^ 3 - 2)).card = 18 := by decide
example : (Finset.univ.filter
    (fun P : ZMod 41 × ZMod 41 => P.2 ^ 2 = P.1 ^ 3 - 2)).card = 41 := by decide
-- Cubic roots: none mod 7 or mod 13 (odd counts 7 and 19), exactly one mod 41 (even count 42).
example : (∀ x : ZMod 7, x ^ 3 - 2 ≠ 0) ∧ (∀ x : ZMod 13, x ^ 3 - 2 ≠ 0) := by decide
example : (Finset.univ.filter (fun x : ZMod 41 => x ^ 3 - 2 = 0)).card = 1 := by decide
-- Embedding degrees: 4 for q = 17, p = 13; 18 for q = 19, p = 13; 2 for q = 7, p = 41.
example : (13 : ZMod 17) ^ 4 = 1 ∧ ∀ k ∈ [1, 2, 3], (13 : ZMod 17) ^ k ≠ 1 := by decide
example : (13 : ZMod 19) ^ 18 = 1 ∧ ∀ k ∈ List.range' 1 17, (13 : ZMod 19) ^ k ≠ 1 := by decide
example : (41 : ZMod 7) ^ 2 = 1 ∧ (41 : ZMod 7) ≠ 1 := by decide
-- Pohlig–Hellman mod 41: 42 = 2 · 3 · 7, and the key mod 2, 3, 7 = 1, 2, 1 joins to 29 alone
-- below 42, in (1 + 1) + (2 + 1) + (1 + 1) = 7 trials.
example : 42 = 2 * 3 * 7 ∧ (29 % 2, 29 % 3, 29 % 7) = (1, 2, 1) := by norm_num
example : ∀ x < 42, (x % 2 = 1 ∧ x % 3 = 2 ∧ x % 7 = 1) ↔ x = 29 := by decide
example : (1 + 1) + (2 + 1) + (1 + 1) = 7 := by norm_num
-- P-256 (SEC 2): its prime p = 2^256 − 2^224 + 2^192 + 2^96 − 1 has 256 bits.
example : 2 ^ 255 ≤ 2 ^ 256 - 2 ^ 224 + 2 ^ 192 + 2 ^ 96 - 1 ∧
    2 ^ 256 - 2 ^ 224 + 2 ^ 192 + 2 ^ 96 - 1 < 2 ^ 256 := by norm_num

#print axioms nsmul_eq_mod_nsmul_of_nsmul_eq_zero
#print axioms finite_point_of_finite
#print axioms two_ne_zero_zmod_of_odd
#print axioms card_points_even_iff_cubic_has_root
#print axioms ecdh_shared_point_eq
#print axioms pohlig_hellman_step
