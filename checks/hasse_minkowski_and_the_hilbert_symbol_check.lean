-- Legendre's theorem, the three-unknown case of Hasse-Minkowski: for positive, squarefree, pairwise coprime a, b, c, the equation a x^2 + b y^2 = c z^2 has a whole-number solution other than (0, 0, 0) exactly when bc is a square mod a, ac is a square mod b, and -ab is a square mod c.
import Mathlib.LinearAlgebra.QuadraticForm.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.NumberTheory.Padics.PadicNumbers
import Mathlib.Basic.Real.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Squarefree.Basic
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Nat.Squarefree
import Mathlib.NumberTheory.SumTwoSquares
import Mathlib.RingTheory.PrincipalIdealDomain
import Mathlib.RingTheory.Coprime.Lemmas

/-! A quadratic form in `n` unknowns with rational coefficients is given by its symmetric
matrix `A`; Mathlib's `A.toQuadraticForm'` is the form `x ↦ xᵀ A x`, and `A.det` is the
form's determinant. Over the reals or over `ℚ_[p]` the same form has the matrix `A.map Rat.cast`. -/

/-- If a prime `p` divides `A` exactly once, does not divide `B`, and divides `Z`, then any
solution of `A X² + B Y² + C Z² = 0` has `p ∣ X` and `p ∣ Y`. -/
theorem legendre_aux_dvd (p : ℕ) (hp : p.Prime) (A B C X Y Z : ℤ)
    (h : A * X ^ 2 + B * Y ^ 2 + C * Z ^ 2 = 0) (hA : (p : ℤ) ∣ A) (hA2 : ¬ (p : ℤ) * p ∣ A)
    (hB : ¬ (p : ℤ) ∣ B) (hZ : (p : ℤ) ∣ Z) : (p : ℤ) ∣ X ∧ (p : ℤ) ∣ Y := by
  have hpp : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
  have hY2 : (p : ℤ) ∣ B * Y ^ 2 := by
    have : B * Y ^ 2 = -(A * X ^ 2 + C * Z ^ 2) := by linear_combination h
    rw [this]
    exact (dvd_add (dvd_mul_of_dvd_left hA _) (dvd_mul_of_dvd_right (dvd_pow hZ two_ne_zero) _)).neg_right
  have hY : (p : ℤ) ∣ Y := by
    rcases hpp.dvd_or_dvd hY2 with h1 | h1
    · exact absurd h1 hB
    · exact hpp.dvd_of_dvd_pow h1
  refine ⟨?_, hY⟩
  by_contra hX
  obtain ⟨y, rfl⟩ := hY
  obtain ⟨z, rfl⟩ := hZ
  have h2 : (p : ℤ) * p ∣ A * X ^ 2 := ⟨-(B * y ^ 2 + C * z ^ 2), by linear_combination h⟩
  have hcop : IsCoprime ((p : ℤ) * p) (X ^ 2) := by
    have : IsCoprime (p : ℤ) X := (Irreducible.coprime_iff_not_dvd hpp.irreducible).mpr hX
    exact (this.mul_left this).pow_right
  exact hA2 (hcop.dvd_of_dvd_mul_right h2)

/-- An integer with no prime factor in common with `a` is a unit mod `a`. -/
theorem legendre_aux_unit (a : ℕ) (z : ℤ) (h : ∀ p : ℕ, p.Prime → (p : ℤ) ∣ z → ¬ (p : ℤ) ∣ a) :
    IsUnit (z : ZMod a) := by
  have hc : Nat.Coprime z.natAbs a := Nat.coprime_of_dvd fun k hk h1 h2 =>
    h k hk (Int.natCast_dvd.mpr h1) (Int.natCast_dvd_natCast.mpr h2)
  have hc' : IsCoprime z (a : ℤ) := Int.isCoprime_iff_gcd_eq_one.mpr (by simpa [Int.gcd] using hc)
  obtain ⟨u, v, huv⟩ := hc'
  refine IsUnit.of_mul_eq_one (u : ZMod a) ?_
  have := congrArg (Int.cast : ℤ → ZMod a) huv
  push_cast at this
  rw [ZMod.natCast_self] at this
  linear_combination this

/-- A squarefree number that is a perfect square is `1`. -/
theorem legendre_aux_sq (m : ℕ) (hm : Squarefree m) (x : ℤ) (h : (m : ℤ) = x ^ 2) : m = 1 := by
  have : m = x.natAbs * x.natAbs := by
    have := congrArg Int.natAbs h
    simpa [Int.natAbs_pow, sq, Int.natAbs_mul] using this
  have hu := hm x.natAbs (by rw [this])
  rw [Nat.isUnit_iff] at hu
  rw [this, hu]

/-- A nonzero solution can be taken with no prime dividing all three coordinates. -/
theorem legendre_aux_primitive (a b c : ℤ)
    (h : ∃ x y z : ℤ, (x, y, z) ≠ (0, 0, 0) ∧ a * x ^ 2 + b * y ^ 2 = c * z ^ 2) :
    ∃ x y z : ℤ, (x, y, z) ≠ (0, 0, 0) ∧ a * x ^ 2 + b * y ^ 2 = c * z ^ 2 ∧
      ∀ p : ℕ, p.Prime → ¬ ((p : ℤ) ∣ x ∧ (p : ℤ) ∣ y ∧ (p : ℤ) ∣ z) := by
  classical
  have hex : ∃ n : ℕ, ∃ x y z : ℤ, (x, y, z) ≠ (0, 0, 0) ∧ a * x ^ 2 + b * y ^ 2 = c * z ^ 2 ∧
      x.natAbs + y.natAbs + z.natAbs = n := by
    obtain ⟨x, y, z, h1, h2⟩ := h
    exact ⟨_, x, y, z, h1, h2, rfl⟩
  obtain ⟨x, y, z, h1, h2, h3⟩ := Nat.find_spec hex
  refine ⟨x, y, z, h1, h2, ?_⟩
  rintro p hp ⟨⟨x', rfl⟩, ⟨y', rfl⟩, ⟨z', rfl⟩⟩
  have hp0 : (p : ℤ) ≠ 0 := by exact_mod_cast hp.ne_zero
  have hne : (x', y', z') ≠ (0, 0, 0) := by
    intro h0
    simp only [Prod.mk.injEq] at h0
    obtain ⟨rfl, rfl, rfl⟩ := h0
    exact h1 (by simp)
  have heq : a * x' ^ 2 + b * y' ^ 2 = c * z' ^ 2 := by
    have : ((p : ℤ) * p) * (a * x' ^ 2 + b * y' ^ 2 - c * z' ^ 2) = 0 := by linear_combination h2
    rcases mul_eq_zero.mp this with h4 | h4
    · exact absurd h4 (mul_ne_zero hp0 hp0)
    · linear_combination h4
  have hmin := Nat.find_min' hex ⟨x', y', z', hne, heq, rfl⟩
  have hpos : 0 < x'.natAbs + y'.natAbs + z'.natAbs := by
    by_contra h0
    have hx : x' = 0 := by omega
    have hy : y' = 0 := by omega
    have hz : z' = 0 := by omega
    exact hne (by simp [hx, hy, hz])
  rw [← h3] at hmin
  simp only [Int.natAbs_mul, Int.natAbs_natCast] at hmin
  have := hp.two_le
  nlinarith

#print axioms legendre_aux_dvd
#print axioms legendre_aux_unit
#print axioms legendre_aux_sq
#print axioms legendre_aux_primitive

/-- Legendre's theorem, the case of three unknowns proved on the card. Let `a, b, c` be
positive, squarefree and pairwise coprime. Then `a x² + b y² = c z²` has a whole-number
solution other than `(0, 0, 0)` exactly when `bc` is a square mod `a`, `ac` is a square
mod `b`, and `-ab` is a square mod `c`. -/
theorem legendre_ternary_solvable_iff (a b c : ℕ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c)
    (hsa : Squarefree a) (hsb : Squarefree b) (hsc : Squarefree c)
    (hab : Nat.Coprime a b) (hbc : Nat.Coprime b c) (hca : Nat.Coprime c a) :
    (∃ x y z : ℤ, (x, y, z) ≠ (0, 0, 0) ∧ (a : ℤ) * x ^ 2 + b * y ^ 2 = c * z ^ 2) ↔
      (IsSquare ((b * c : ℕ) : ZMod a) ∧ IsSquare ((a * c : ℕ) : ZMod b) ∧
        IsSquare (-((a * b : ℕ) : ZMod c))) := by
  -- facts about primes dividing one coefficient
  have nsq : ∀ (m : ℕ), Squarefree m → ∀ p : ℕ, p.Prime → ¬ (p : ℤ) * p ∣ (m : ℤ) := by
    intro m hm p hp hd
    have : p * p ∣ m := by exact_mod_cast hd
    exact (Nat.squarefree_iff_prime_squarefree.mp hm) p hp this
  have ndv : ∀ (m n : ℕ), Nat.Coprime m n → ∀ p : ℕ, p.Prime → (p : ℤ) ∣ (m : ℤ) →
      ¬ (p : ℤ) ∣ (n : ℤ) := by
    intro m n hmn p hp h1 h2
    have h1' : p ∣ m := by exact_mod_cast h1
    have h2' : p ∣ n := by exact_mod_cast h2
    have := Nat.dvd_gcd h1' h2'
    rw [hmn] at this
    exact hp.one_lt.ne' (Nat.dvd_one.mp this)
  constructor
  · intro hsol
    obtain ⟨x, y, z, -, heq, hprim⟩ := legendre_aux_primitive _ _ _ hsol
    refine ⟨?_, ?_, ?_⟩
    · -- mod a
      have hz : IsUnit (z : ZMod a) := by
        refine legendre_aux_unit a z fun p hp hpz hpa => ?_
        have := legendre_aux_dvd p hp a b (-c) x y z (by linear_combination heq) hpa
          (nsq a hsa p hp) (ndv a b hab p hp hpa) hpz
        exact hprim p hp ⟨this.1, this.2, hpz⟩
      obtain ⟨u, hu⟩ := hz
      have key : ((a * x ^ 2 + b * y ^ 2 : ℤ) : ZMod a) = ((c * z ^ 2 : ℤ) : ZMod a) := by
        rw [heq]
      push_cast at key
      rw [ZMod.natCast_self] at key
      have hinv : (z : ZMod a) * ((u⁻¹ : (ZMod a)ˣ) : ZMod a) = 1 := by
        rw [← hu]; exact Units.mul_inv u
      refine ⟨(b : ZMod a) * y * ((u⁻¹ : (ZMod a)ˣ) : ZMod a), ?_⟩
      push_cast
      linear_combination (-((b : ZMod a) * ((u⁻¹ : (ZMod a)ˣ) : ZMod a) ^ 2)) * key +
        (-((b : ZMod a) * c * ((z : ZMod a) * ((u⁻¹ : (ZMod a)ˣ) : ZMod a) + 1))) * hinv
    · -- mod b
      have hz : IsUnit (z : ZMod b) := by
        refine legendre_aux_unit b z fun p hp hpz hpb => ?_
        have := legendre_aux_dvd p hp b a (-c) y x z (by linear_combination heq) hpb
          (nsq b hsb p hp) (ndv b a hab.symm p hp hpb) hpz
        exact hprim p hp ⟨this.2, this.1, hpz⟩
      obtain ⟨u, hu⟩ := hz
      have key : ((a * x ^ 2 + b * y ^ 2 : ℤ) : ZMod b) = ((c * z ^ 2 : ℤ) : ZMod b) := by
        rw [heq]
      push_cast at key
      rw [ZMod.natCast_self] at key
      have hinv : (z : ZMod b) * ((u⁻¹ : (ZMod b)ˣ) : ZMod b) = 1 := by
        rw [← hu]; exact Units.mul_inv u
      refine ⟨(a : ZMod b) * x * ((u⁻¹ : (ZMod b)ˣ) : ZMod b), ?_⟩
      push_cast
      linear_combination (-((a : ZMod b) * ((u⁻¹ : (ZMod b)ˣ) : ZMod b) ^ 2)) * key +
        (-((a : ZMod b) * c * ((z : ZMod b) * ((u⁻¹ : (ZMod b)ˣ) : ZMod b) + 1))) * hinv
    · -- mod c
      have hx : IsUnit (x : ZMod c) := by
        refine legendre_aux_unit c x fun p hp hpx hpc => ?_
        have hpc' : (p : ℤ) ∣ -(c : ℤ) := hpc.neg_right
        have hnsq : ¬ (p : ℤ) * p ∣ -(c : ℤ) := fun h => nsq c hsc p hp (dvd_neg.mp h)
        have := legendre_aux_dvd p hp (-c) b a z y x (by linear_combination heq) hpc'
          hnsq (ndv c b hbc.symm p hp hpc) hpx
        exact hprim p hp ⟨hpx, this.2, this.1⟩
      obtain ⟨u, hu⟩ := hx
      have key : ((a * x ^ 2 + b * y ^ 2 : ℤ) : ZMod c) = ((c * z ^ 2 : ℤ) : ZMod c) := by
        rw [heq]
      push_cast at key
      rw [ZMod.natCast_self] at key
      have hinv : (x : ZMod c) * ((u⁻¹ : (ZMod c)ˣ) : ZMod c) = 1 := by
        rw [← hu]; exact Units.mul_inv u
      refine ⟨(b : ZMod c) * y * ((u⁻¹ : (ZMod c)ˣ) : ZMod c), ?_⟩
      push_cast
      linear_combination (-((b : ZMod c) * ((u⁻¹ : (ZMod c)ˣ) : ZMod c) ^ 2)) * key +
        ((a : ZMod c) * b * ((x : ZMod c) * ((u⁻¹ : (ZMod c)ˣ) : ZMod c) + 1)) * hinv
  · rintro ⟨⟨r, hr⟩, ⟨s, hs⟩, ⟨t, ht⟩⟩
    have : NeZero a := ⟨ha.ne'⟩
    have : NeZero b := ⟨hb.ne'⟩
    have : NeZero c := ⟨hc.ne'⟩
    push_cast at hr hs ht
    set X := Nat.sqrt (b * c) with hX
    set Y := Nat.sqrt (a * c) with hY
    set Z := Nat.sqrt (a * b) with hZ
    let S : Finset (ℕ × ℕ × ℕ) :=
      Finset.range (X + 1) ×ˢ Finset.range (Y + 1) ×ˢ Finset.range (Z + 1)
    let f : ℕ × ℕ × ℕ → ZMod a × ZMod b × ZMod c := fun q =>
      ((b : ZMod a) * q.2.1 - r * q.2.2, (a : ZMod b) * q.1 - s * q.2.2,
        (a : ZMod c) * q.1 - t * q.2.1)
    have hcard : (Finset.univ : Finset (ZMod a × ZMod b × ZMod c)).card < S.card := by
      simp only [S, Finset.card_univ, Fintype.card_prod, ZMod.card, Finset.card_product,
        Finset.card_range]
      have h1 : b * c < (X + 1) ^ 2 := Nat.lt_succ_sqrt' _
      have h2 : a * c < (Y + 1) ^ 2 := Nat.lt_succ_sqrt' _
      have h3 : a * b < (Z + 1) ^ 2 := Nat.lt_succ_sqrt' _
      have h4 : (a * (b * c)) ^ 2 < ((X + 1) * ((Y + 1) * (Z + 1))) ^ 2 := by
        have e1 : (a * (b * c)) ^ 2 = (b * c) * ((a * c) * (a * b)) := by ring
        have e2 : ((X + 1) * ((Y + 1) * (Z + 1))) ^ 2 =
            (X + 1) ^ 2 * ((Y + 1) ^ 2 * (Z + 1) ^ 2) := by ring
        rw [e1, e2]
        exact Nat.mul_lt_mul'' h1 (Nat.mul_lt_mul'' h2 h3)
      exact lt_of_pow_lt_pow_left₀ 2 (Nat.zero_le _) h4
    obtain ⟨q1, hq1, q2, hq2, hne, hfeq⟩ := Finset.exists_ne_map_eq_of_card_lt_of_maps_to hcard
      (f := f) (fun _ _ => Finset.mem_coe.2 (Finset.mem_univ _))
    simp only [S, Finset.mem_product, Finset.mem_range] at hq1 hq2
    simp only [f, Prod.mk.injEq] at hfeq
    obtain ⟨e1, e2, e3⟩ := hfeq
    set x : ℤ := (q1.1 : ℤ) - q2.1 with hxdef
    set y : ℤ := (q1.2.1 : ℤ) - q2.2.1 with hydef
    set z : ℤ := (q1.2.2 : ℤ) - q2.2.2 with hzdef
    have hnz : (x, y, z) ≠ (0, 0, 0) := by
      intro h0
      simp only [Prod.mk.injEq] at h0
      obtain ⟨h01, h02, h03⟩ := h0
      apply hne
      ext <;> omega
    set Q : ℤ := a * x ^ 2 + b * y ^ 2 - c * z ^ 2 with hQ
    -- Q vanishes mod a, b and c
    have hQa : (a : ℤ) ∣ Q := by
      rw [← ZMod.intCast_zmod_eq_zero_iff_dvd]
      have hlin : (b : ZMod a) * (y : ZMod a) = r * (z : ZMod a) := by
        simp only [hydef, hzdef]; push_cast; linear_combination e1
      have hu : IsUnit (b : ZMod a) := (ZMod.isUnit_iff_coprime b a).mpr hab.symm
      have h0 : (b : ZMod a) * ((b : ZMod a) * (y : ZMod a) ^ 2 - c * (z : ZMod a) ^ 2) = 0 := by
        linear_combination ((b : ZMod a) * y + r * z) * hlin - (z : ZMod a) ^ 2 * hr
      have h00 := (hu.mul_right_eq_zero).mp h0
      simp only [hQ]; push_cast
      rw [ZMod.natCast_self]
      linear_combination h00
    have hQb : (b : ℤ) ∣ Q := by
      rw [← ZMod.intCast_zmod_eq_zero_iff_dvd]
      have hlin : (a : ZMod b) * (x : ZMod b) = s * (z : ZMod b) := by
        simp only [hxdef, hzdef]; push_cast; linear_combination e2
      have hu : IsUnit (a : ZMod b) := (ZMod.isUnit_iff_coprime a b).mpr hab
      have h0 : (a : ZMod b) * ((a : ZMod b) * (x : ZMod b) ^ 2 - c * (z : ZMod b) ^ 2) = 0 := by
        linear_combination ((a : ZMod b) * x + s * z) * hlin - (z : ZMod b) ^ 2 * hs
      have h00 := (hu.mul_right_eq_zero).mp h0
      simp only [hQ]; push_cast
      rw [ZMod.natCast_self]
      linear_combination h00
    have hQc : (c : ℤ) ∣ Q := by
      rw [← ZMod.intCast_zmod_eq_zero_iff_dvd]
      have hlin : (a : ZMod c) * (x : ZMod c) = t * (y : ZMod c) := by
        simp only [hxdef, hydef]; push_cast; linear_combination e3
      have hu : IsUnit (a : ZMod c) := (ZMod.isUnit_iff_coprime a c).mpr hca.symm
      have h0 : (a : ZMod c) * ((a : ZMod c) * (x : ZMod c) ^ 2 + b * (y : ZMod c) ^ 2) = 0 := by
        linear_combination ((a : ZMod c) * x + t * y) * hlin - (y : ZMod c) ^ 2 * ht
      have h00 := (hu.mul_right_eq_zero).mp h0
      simp only [hQ]; push_cast
      rw [ZMod.natCast_self]
      linear_combination h00
    have hN : ((a * b * c : ℕ) : ℤ) ∣ Q := by
      have c1 : IsCoprime (a : ℤ) (b : ℤ) := Nat.isCoprime_iff_coprime.mpr hab
      have c2 : IsCoprime (a : ℤ) (c : ℤ) := Nat.isCoprime_iff_coprime.mpr hca.symm
      have c3 : IsCoprime (b : ℤ) (c : ℤ) := Nat.isCoprime_iff_coprime.mpr hbc
      push_cast
      exact (c2.mul_left c3).mul_dvd (c1.mul_dvd hQa hQb) hQc
    obtain ⟨k, hk⟩ := hN
    push_cast at hk
    -- size bounds
    have hXb : ((X : ℤ)) ^ 2 ≤ (b : ℤ) * c := by exact_mod_cast Nat.sqrt_le' (b * c)
    have hYb : ((Y : ℤ)) ^ 2 ≤ (a : ℤ) * c := by exact_mod_cast Nat.sqrt_le' (a * c)
    have hZb : ((Z : ℤ)) ^ 2 ≤ (a : ℤ) * b := by exact_mod_cast Nat.sqrt_le' (a * b)
    have hx2 : x ^ 2 ≤ (X : ℤ) ^ 2 := sq_le_sq' (by omega) (by omega)
    have hy2 : y ^ 2 ≤ (Y : ℤ) ^ 2 := sq_le_sq' (by omega) (by omega)
    have hz2 : z ^ 2 ≤ (Z : ℤ) ^ 2 := sq_le_sq' (by omega) (by omega)
    have ha' : (0 : ℤ) < a := by exact_mod_cast ha
    have hb' : (0 : ℤ) < b := by exact_mod_cast hb
    have hc' : (0 : ℤ) < c := by exact_mod_cast hc
    have Ax : (a : ℤ) * x ^ 2 ≤ a * b * c := by
      calc (a : ℤ) * x ^ 2 ≤ a * X ^ 2 := mul_le_mul_of_nonneg_left hx2 ha'.le
        _ ≤ a * (b * c) := mul_le_mul_of_nonneg_left hXb ha'.le
        _ = a * b * c := by ring
    have By : (b : ℤ) * y ^ 2 ≤ a * b * c := by
      calc (b : ℤ) * y ^ 2 ≤ b * Y ^ 2 := mul_le_mul_of_nonneg_left hy2 hb'.le
        _ ≤ b * (a * c) := mul_le_mul_of_nonneg_left hYb hb'.le
        _ = a * b * c := by ring
    have Cz : (c : ℤ) * z ^ 2 ≤ a * b * c := by
      calc (c : ℤ) * z ^ 2 ≤ c * Z ^ 2 := mul_le_mul_of_nonneg_left hz2 hc'.le
        _ ≤ c * (a * b) := mul_le_mul_of_nonneg_left hZb hc'.le
        _ = a * b * c := by ring
    have Ax0 : 0 ≤ (a : ℤ) * x ^ 2 := by positivity
    have By0 : 0 ≤ (b : ℤ) * y ^ 2 := by positivity
    have Cz0 : 0 ≤ (c : ℤ) * z ^ 2 := by positivity
    have hNpos : (0 : ℤ) < a * b * c := by positivity
    have hk1 : -1 ≤ k := by
      by_contra hlt
      have : k ≤ -2 := by omega
      have := mul_le_mul_of_nonneg_left this hNpos.le
      linarith
    have hk2 : k ≤ 2 := by
      by_contra hlt
      have : 3 ≤ k := by omega
      have := mul_le_mul_of_nonneg_left this hNpos.le
      linarith
    interval_cases k
    · -- Q = -abc: then x = y = 0 and z² = ab, so a = b = 1 and c is a sum of two squares
      have hax : (a : ℤ) * x ^ 2 = 0 := by linarith
      have hby : (b : ℤ) * y ^ 2 = 0 := by linarith
      have hcz : (c : ℤ) * z ^ 2 = a * b * c := by linarith
      have hab1 : a * b = 1 := by
        refine legendre_aux_sq (a * b) ((Nat.squarefree_mul hab).mpr ⟨hsa, hsb⟩) z ?_
        have : (c : ℤ) * (z ^ 2 - a * b) = 0 := by linear_combination hcz
        rcases mul_eq_zero.mp this with h | h
        · omega
        · push_cast; linear_combination -h
      have ha1 : a = 1 := Nat.eq_one_of_mul_eq_one_right hab1
      have hb1 : b = 1 := Nat.eq_one_of_mul_eq_one_left hab1
      subst ha1 hb1
      have hm1 : IsSquare (-1 : ZMod c) := ⟨t, by simpa using ht⟩
      obtain ⟨u, v, huv⟩ := Nat.eq_sq_add_sq_of_isSquare_mod_neg_one hm1
      refine ⟨u, v, 1, by simp, ?_⟩
      push_cast
      rw [huv]; push_cast; ring
    · -- Q = 0
      exact ⟨x, y, z, hnz, by linear_combination hk⟩
    · -- Q = abc: Legendre's identity gives a solution
      refine ⟨x * z + b * y, y * z - a * x, z ^ 2 + a * b, ?_, ?_⟩
      · intro h0
        simp only [Prod.mk.injEq] at h0
        have : (0 : ℤ) < z ^ 2 + a * b := by positivity
        omega
      · linear_combination (z ^ 2 + (a : ℤ) * b) * hk
    · -- Q = 2abc: then x² = bc and y² = ac, forcing a = b = c = 1
      have hax : (a : ℤ) * x ^ 2 = a * b * c := by linarith
      have hby : (b : ℤ) * y ^ 2 = a * b * c := by linarith
      have hbc1 : b * c = 1 := by
        refine legendre_aux_sq (b * c) ((Nat.squarefree_mul hbc).mpr ⟨hsb, hsc⟩) x ?_
        have : (a : ℤ) * (x ^ 2 - b * c) = 0 := by linear_combination hax
        rcases mul_eq_zero.mp this with h | h
        · omega
        · push_cast; linear_combination -h
      have hac1 : a * c = 1 := by
        refine legendre_aux_sq (a * c) ((Nat.squarefree_mul hca.symm).mpr ⟨hsa, hsc⟩) y ?_
        have : (b : ℤ) * (y ^ 2 - a * c) = 0 := by linear_combination hby
        rcases mul_eq_zero.mp this with h | h
        · omega
        · push_cast; linear_combination -h
      have hb1 : b = 1 := Nat.eq_one_of_mul_eq_one_right hbc1
      have ha1 : a = 1 := Nat.eq_one_of_mul_eq_one_right hac1
      have hc1 : c = 1 := Nat.eq_one_of_mul_eq_one_left hbc1
      subst ha1 hb1 hc1
      exact ⟨1, 0, 1, by simp, by norm_num⟩

/-! The card's whole-number worked examples. -/

-- x² + y² = 5z² has the solution (1, 2, 1): 1 + 4 = 5.
example : (1 : ℤ) ^ 2 + 2 ^ 2 = 5 * 1 ^ 2 := by norm_num
-- (3, -1)_3 = -1 because -1 is not a square mod 3.
example : ∀ r : ZMod 3, r * r ≠ -1 := by decide
-- (-1/5) = +1 because 2² = 4 ≡ -1 mod 5.
example : (2 : ZMod 5) * 2 = -1 := by decide
-- x² + y² = 3z²: 2 primitive solutions mod 3, namely (0, 0, 1) and (0, 0, 2) ...
example : ((Finset.univ : Finset (ZMod 3 × ZMod 3 × ZMod 3)).filter
    (fun t => t.1 ^ 2 + t.2.1 ^ 2 = 3 * t.2.2 ^ 2 ∧ t ≠ (0, 0, 0))).card = 2 := by decide
-- ... but none mod 9: every solution mod 9 has x, y, z all multiples of 3.
example : ∀ x y z : ZMod 9, x ^ 2 + y ^ 2 = 3 * z ^ 2 → 3 * x = 0 ∧ 3 * y = 0 ∧ 3 * z = 0 := by
  decide
-- Legendre's box for 11x² + 13y² = 2z²: (-5, 1, 1) gives Q = 286 = 11 · 13 · 2,
-- and the identity turns it into (1, 7, 18): 11 + 637 = 648.
example : 11 * (-5 : ℤ) ^ 2 + 13 * 1 ^ 2 - 2 * 1 ^ 2 = 11 * 13 * 2 := by norm_num
example : (-5 : ℤ) * 1 + 13 * 1 = 8 ∧ (1 : ℤ) * 1 - 11 * (-5) = 56 ∧ (1 : ℤ) ^ 2 + 11 * 13 = 144 ∧
    (8, 56, 144) = (8 * 1, 8 * 7, 8 * 18) := by norm_num
example : 11 * 1 ^ 2 + 13 * 7 ^ 2 = 2 * 18 ^ 2 ∧ 13 * 7 ^ 2 = 637 ∧ 2 * 18 ^ 2 = 648 := by norm_num
-- For x² + y² = 5z² the box finds (-2, -1, 0) with Q = 5, and the identity gives (1, 2, 1).
example : (-2 : ℤ) ^ 2 + (-1) ^ 2 - 5 * 0 ^ 2 = 5 ∧
    ((-2 : ℤ) * 0 + 1 * (-1), (-1 : ℤ) * 0 - 1 * (-2), (0 : ℤ) ^ 2 + 1 * 1) = (-1, 2, 1) := by
  norm_num
-- The identity behind Legendre's last step.
example (a b c x y z : ℤ) :
    a * (x * z + b * y) ^ 2 + b * (y * z - a * x) ^ 2 - c * (z ^ 2 + a * b) ^ 2 =
      (z ^ 2 + a * b) * (a * x ^ 2 + b * y ^ 2 - c * z ^ 2 - a * b * c) := by ring
-- Selmer's cubic 3x³ + 4y³ + 5z³: local points (1, 0, 1) at 2, (0, 1, 4) at 3, (1, 2, 0) at 5.
example : 3 * 1 ^ 3 + 4 * 0 ^ 3 + 5 * 1 ^ 3 = 8 ∧ 3 * 0 ^ 3 + 4 * 1 ^ 3 + 5 * 4 ^ 3 = 324 ∧
    324 = 3 ^ 3 * 12 ∧ 3 * 1 ^ 3 + 4 * 2 ^ 3 + 5 * 0 ^ 3 = 35 ∧ 35 = 5 * 7 := by norm_num
-- The house example: 29 = 3² + 5 · 2², 41 = 6² + 5 · 1², 61 = 4² + 5 · 3², 89 = 3² + 5 · 4².
example : 29 = 3 ^ 2 + 5 * 2 ^ 2 ∧ 41 = 6 ^ 2 + 5 * 1 ^ 2 ∧ 61 = 4 ^ 2 + 5 * 3 ^ 2 ∧
    89 = 3 ^ 2 + 5 * 4 ^ 2 := by norm_num

#print axioms legendre_ternary_solvable_iff
