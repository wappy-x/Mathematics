-- Finite fields: for every prime p and n ≥ 1 there is exactly one field with p^n elements up to renaming, its symmetries are the n powers of Frobenius, and its subfields are the fixed sets of Frobenius^d, one of size p^d for each d dividing n.
import Mathlib.FieldTheory.Finite.GaloisField
import Mathlib.NumberTheory.Divisors

theorem ff_charP_of_card (p : ℕ) [hp : Fact p.Prime] (n : ℕ) (hn : 0 < n)
    (K : Type) [Field K] [Fintype K] (hK : Fintype.card K = p ^ n) : CharP K p := by
  obtain ⟨q, hq⟩ := CharP.exists K
  obtain ⟨m, hqp, hm⟩ := FiniteField.card K q
  have hdvd : p ∣ q ^ (m : ℕ) := by
    rw [← hm, hK]; exact dvd_pow_self p hn.ne'
  have := (Nat.prime_dvd_prime_iff_eq hp.out hqp).mp (hp.out.dvd_of_dvd_pow hdvd)
  subst this
  exact hq

#print axioms ff_charP_of_card

theorem ff_ncard_fixed_le (p : ℕ) [hp : Fact p.Prime] (K : Type) [Field K] [Fintype K]
    (d : ℕ) (hd : 0 < d) : Set.ncard {a : K | a ^ p ^ d = a} ≤ p ^ d := by
  classical
  have h1 : 1 < p ^ d := Nat.one_lt_pow hd.ne' hp.out.one_lt
  set f : Polynomial K := Polynomial.X ^ p ^ d - Polynomial.X with hf
  have hf0 : f ≠ 0 := Polynomial.X_pow_sub_X_ne_zero h1
  let Z : Finset K := Finset.univ.filter (fun a => a ^ p ^ d = a)
  have hZ : {a : K | a ^ p ^ d = a} = (Z : Set K) := by
    ext a; simp [Z]
  rw [hZ, Set.ncard_coe_finset]
  have hdeg : f.natDegree ≤ p ^ d := by
    refine (Polynomial.natDegree_sub_le _ _).trans ?_
    simp
    omega
  refine le_trans (Polynomial.card_le_degree_of_subset_roots ?_) hdeg
  intro a ha
  have ha' : a ^ p ^ d = a := by simpa [Z] using ha
  rw [Polynomial.mem_roots hf0, Polynomial.IsRoot, hf]
  simp [ha']

#print axioms ff_ncard_fixed_le

theorem ff_finrank_eq (p : ℕ) [hp : Fact p.Prime] (n : ℕ)
    (K : Type) [Field K] [Fintype K] [Algebra (ZMod p) K] (hK : Fintype.card K = p ^ n) :
    Module.finrank (ZMod p) K = n := by
  have h := FiniteField.pow_finrank_eq_card p K
  rw [hK] at h
  exact Nat.pow_right_injective hp.out.two_le h

#print axioms ff_finrank_eq

/-- For every prime `p` and whole number `n ≥ 1` there is a field with `p ^ n` elements,
and any two fields with `p ^ n` elements are the same field after renaming
(there is a bijection between them that keeps every sum and every product). -/
theorem exists_unique_field_of_prime_power_card (p : ℕ) [Fact p.Prime] (n : ℕ) (hn : 0 < n) :
    (∃ (K : Type) (_ : Field K) (_ : Fintype K), Fintype.card K = p ^ n) ∧
    ∀ (K L : Type) [Field K] [Fintype K] [Field L] [Fintype L],
      Fintype.card K = p ^ n → Fintype.card L = p ^ n → Nonempty (K ≃+* L) := by
  constructor
  · refine ⟨GaloisField p n, inferInstance, Fintype.ofFinite _, ?_⟩
    rw [Fintype.card_eq_nat_card]
    exact GaloisField.card p n hn.ne'
  · intro K L _ _ _ _ hK hL
    exact ⟨FiniteField.ringEquivOfCardEq (hK.trans hL.symm)⟩

/-- In a field with `p ^ n` elements, raising to the `p`-th power (Frobenius) is a symmetry,
and every symmetry of the field is Frobenius repeated `k` times, `a ↦ a ^ (p ^ k)`, for exactly
one `k` from `0` to `n - 1`: the symmetries are exactly `id, Frob, …, Frob^(n-1)`. -/
theorem symmetries_are_powers_of_frobenius (p : ℕ) [Fact p.Prime] (n : ℕ) (hn : 0 < n)
    (K : Type) [Field K] [Fintype K] (hK : Fintype.card K = p ^ n) :
    (∃ σ : K ≃+* K, ∀ a : K, σ a = a ^ p) ∧
    ∀ σ : K ≃+* K, ∃! k : ℕ, k < n ∧ ∀ a : K, σ a = a ^ p ^ k := by
  have := ff_charP_of_card p n hn K hK
  constructor
  · exact ⟨frobeniusEquiv K p, fun a => by simp [frobenius_def]⟩
  · intro σ
    let : Algebra (ZMod p) K := ZMod.algebra K p
    have hfin := ff_finrank_eq p n K hK
    let τ : K ≃ₐ[ZMod p] K := AlgEquiv.ofRingEquiv (f := σ) (fun x => by
      have h : (σ : K →+* K).comp (algebraMap (ZMod p) K) = algebraMap (ZMod p) K :=
        Subsingleton.elim _ _
      exact RingHom.congr_fun h x)
    have hτ : ∀ a, τ a = σ a := fun a => rfl
    have hfr : ∀ k : ℕ, ∀ a : K,
        (FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) K ^ k) a = a ^ p ^ k := by
      intro k a
      rw [AlgEquiv.coe_pow, FiniteField.coe_frobeniusAlgEquivOfAlgebraic_iterate, ZMod.card]
    have hbij := FiniteField.bijective_frobeniusAlgEquivOfAlgebraic_pow (ZMod p) K
    obtain ⟨⟨k, hk⟩, hk'⟩ := hbij.2 τ
    have hka : ∀ a, σ a = a ^ p ^ k := by
      intro a
      rw [← hτ, ← hfr]
      exact (congrArg (fun g : K ≃ₐ[ZMod p] K => g a) hk').symm
    refine ⟨k, ⟨hfin ▸ hk, hka⟩, ?_⟩
    rintro j ⟨hj, hja⟩
    have heq : FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) K ^ j =
        FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) K ^ k := by
      ext a
      rw [hfr, hfr, ← hja a, hka a]
    have := hbij.1 (a₁ := ⟨j, hfin ▸ hj⟩) (a₂ := ⟨k, hk⟩) heq
    exact congrArg Fin.val this

/-- In a field with `p ^ n` elements, for each divisor `d` of `n` the elements fixed by
Frobenius repeated `d` times, `{a | a ^ (p ^ d) = a}`, form a subfield with `p ^ d` elements;
and every subfield is one of these. -/
theorem subfields_are_frobenius_fixed_sets (p : ℕ) [Fact p.Prime] (n : ℕ) (hn : 0 < n)
    (K : Type) [Field K] [Fintype K] (hK : Fintype.card K = p ^ n) :
    (∀ d : ℕ, d ∣ n →
      ∃ L : Subfield K, (L : Set K) = {a | a ^ p ^ d = a} ∧ Nat.card L = p ^ d) ∧
    ∀ L : Subfield K, ∃ d : ℕ, d ∣ n ∧ (L : Set K) = {a | a ^ p ^ d = a} := by
  have := ff_charP_of_card p n hn K hK
  constructor
  · intro d hd
    have hd0 : 0 < d := Nat.pos_of_dvd_of_pos hd hn
    let L : Subfield K := (iterateFrobenius K p d).eqLocusField (RingHom.id K)
    have hS : (L : Set K) = {a | a ^ p ^ d = a} := by
      ext a
      simp [L, iterateFrobenius_def]
    refine ⟨L, hS, ?_⟩
    rw [← SetLike.coe_sort_coe, Nat.card_coe_set_eq, hS]
    refine le_antisymm (ff_ncard_fixed_le p K d hd0) ?_
    let : Algebra (ZMod p) K := ZMod.algebra K p
    have hfin := ff_finrank_eq p n K hK
    obtain ⟨φ⟩ := FiniteField.nonempty_algHom_of_finrank_dvd (F := ZMod p)
      (K := GaloisField p d) (L := K) (by rw [GaloisField.finrank p hd0.ne', hfin]; exact hd)
    let := Fintype.ofFinite (GaloisField p d)
    have hG : Fintype.card (GaloisField p d) = p ^ d := by
      rw [Fintype.card_eq_nat_card]; exact GaloisField.card p d hd0.ne'
    let f : GaloisField p d → {a : K | a ^ p ^ d = a} := fun x =>
      ⟨φ x, by
        show φ x ^ p ^ d = φ x
        rw [← map_pow, ← hG, FiniteField.pow_card]⟩
    have hf : Function.Injective f := by
      intro x y hxy
      exact φ.toRingHom.injective (congrArg Subtype.val hxy)
    have := Nat.card_le_card_of_injective f hf
    rw [Nat.card_coe_set_eq, Nat.card_eq_fintype_card, hG] at this
    exact this
  · intro L
    let := Fintype.ofFinite L
    have : CharP L p := ⟨fun x => by
      rw [← CharP.cast_eq_zero_iff K p x]
      constructor
      · intro h; simpa using congrArg Subtype.val h
      · intro h; exact Subtype.ext (by simpa using h)⟩
    obtain ⟨m, _, hm⟩ := FiniteField.card L p
    have hcardK : Fintype.card K = Fintype.card L ^ Module.finrank L K :=
      Module.card_eq_pow_finrank
    rw [hK, hm, ← pow_mul] at hcardK
    have hn' : n = (m : ℕ) * Module.finrank L K :=
      Nat.pow_right_injective (Fact.out : p.Prime).two_le hcardK
    refine ⟨m, ⟨_, hn'⟩, ?_⟩
    have hsub : (L : Set K) ⊆ {a | a ^ p ^ (m : ℕ) = a} := by
      intro a ha
      have h := FiniteField.pow_card (⟨a, ha⟩ : L)
      rw [hm] at h
      exact congrArg Subtype.val h
    refine Set.eq_of_subset_of_ncard_le hsub ?_
    have hL : (L : Set K).ncard = p ^ (m : ℕ) := by
      rw [← Nat.card_coe_set_eq, SetLike.coe_sort_coe, Nat.card_eq_fintype_card, hm]
    rw [hL]
    exact ff_ncard_fixed_le p K m m.pos

-- The 256-element field: the divisors of 8 are 1, 2, 4, 8, giving four subfields.
example : Nat.divisors 8 = {1, 2, 4, 8} := by decide
example : (Nat.divisors 8).card = 4 := by decide
-- Their sizes 2, 4, 16, 256.
example : [1, 2, 4, 8].map (fun d => 2 ^ d) = [2, 4, 16, 256] := by decide
-- 3 does not divide 8, so there is no 8-element subfield.
example : ¬ (3 ∣ 8) := by decide
-- Counting elements by Frobenius orbits: 1·2 + 2·1 + 4·3 + 8·30 = 256.
example : 1 * 2 + 2 * 1 + 4 * 3 + 8 * 30 = 2 ^ 8 := by norm_num
-- The 30 irreducible polynomials of degree 8: (256 - 2 - 2 - 12) / 8 = 30.
example : (256 - 2 - 2 - 12) / 8 = 30 := by norm_num
-- GF(4)'s two new bytes add (bit by bit) to 01: bc + bd = 01.
example : (0xbc : ℕ) ^^^ 0xbd = 0x01 := by decide
-- 255 = 256 - 1, the order of the generator 03.
example : 2 ^ 8 - 1 = 255 := by norm_num

#print axioms exists_unique_field_of_prime_power_card
#print axioms symmetries_are_powers_of_frobenius
#print axioms subfields_are_frobenius_fixed_sets
