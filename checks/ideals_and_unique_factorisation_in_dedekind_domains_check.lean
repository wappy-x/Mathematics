-- Ideals factor uniquely even where numbers do not: every nonzero ideal of a ring of integers (and of any Dedekind domain) is a product of prime ideals in exactly one way, with the norms multiplying along, and in Z[√-5] the ideal (6) is P2² · P3 · P3bar.
import Mathlib.NumberTheory.NumberField.Basic
import Mathlib.RingTheory.DedekindDomain.Ideal.Basic
import Mathlib.RingTheory.DedekindDomain.Ideal.Lemmas
import Mathlib.RingTheory.Ideal.Norm.AbsNorm
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.Data.Int.Interval

open NumberField

/-- In `ℤ[√-5]`, the ideal `(n, 1 + ε√-5)` is prime when `n` is prime, `ε * ε = 1`, and
`ε * ε = -5` modulo `n`: it is the kernel of the map to `ZMod n` sending `√-5` to `-ε`. -/
theorem zsqrtd_neg_five_span_isPrime (n : ℕ) [Fact n.Prime] (ε : ℤ) (hε : ε * ε = 1)
    (h5 : ((-ε : ℤ) : ZMod n) * ((-ε : ℤ) : ZMod n) = ((-5 : ℤ) : ZMod n)) :
    (Ideal.span {((n : ℤ) : ℤ√(-5)), 1 + (ε : ℤ√(-5)) * Zsqrtd.sqrtd}).IsPrime := by
  let f : ℤ√(-5) →+* ZMod n := Zsqrtd.lift ⟨((-ε : ℤ) : ZMod n), h5⟩
  have hker : Ideal.span {((n : ℤ) : ℤ√(-5)), 1 + (ε : ℤ√(-5)) * Zsqrtd.sqrtd} = RingHom.ker f := by
    apply le_antisymm
    · rw [Ideal.span_le, Set.insert_subset_iff, Set.singleton_subset_iff]
      refine ⟨?_, ?_⟩
      · simp [f, RingHom.mem_ker]
      · have : ((ε * ε : ℤ) : ZMod n) = 1 := by rw [hε]; simp
        simp only [SetLike.mem_coe, RingHom.mem_ker, map_add, map_one, map_mul, map_intCast, f]
        simp only [Zsqrtd.lift_apply_apply, Zsqrtd.re_sqrtd, Zsqrtd.im_sqrtd]
        push_cast at this ⊢
        linear_combination (-1 : ZMod n) * this
    · intro x hx
      rw [RingHom.mem_ker] at hx
      simp only [f, Zsqrtd.lift_apply_apply] at hx
      have hd : ((x.re - ε * x.im : ℤ) : ZMod n) = 0 := by
        push_cast at hx ⊢; linear_combination hx
      rw [ZMod.intCast_zmod_eq_zero_iff_dvd] at hd
      obtain ⟨k, hk⟩ := hd
      rw [Ideal.mem_span_pair]
      refine ⟨(k : ℤ√(-5)), ((ε * x.im : ℤ) : ℤ√(-5)), ?_⟩
      ext
      · simp; linear_combination (-1 : ℤ) * hk
      · simp; linear_combination (x.im) * hε
  rw [hker]
  exact RingHom.ker_isPrime f

#print axioms zsqrtd_neg_five_span_isPrime

/-- The Dedekind property in a ring of integers: in the ring of integers `𝓞 K` of a number
field `K`, every nonzero ideal `I` is a product of prime ideals, the list of prime ideals with
their counts (a multiset) is unique, and the norm of `I` (the number of classes in `𝓞 K / I`)
is the product of the norms of its prime factors. -/
theorem ideal_factors_uniquely_into_prime_ideals
    (K : Type*) [Field K] [NumberField K] (I : Ideal (𝓞 K)) (hI : I ≠ ⊥) :
    (∃! s : Multiset (Ideal (𝓞 K)), (∀ p ∈ s, p.IsPrime) ∧ s.prod = I) ∧
      ∀ s : Multiset (Ideal (𝓞 K)), (∀ p ∈ s, p.IsPrime) → s.prod = I →
        Ideal.absNorm I = (s.map Ideal.absNorm).prod := by
  have hexists : ∃! s : Multiset (Ideal (𝓞 K)), (∀ p ∈ s, p.IsPrime) ∧ s.prod = I := by
    refine ⟨UniqueFactorizationMonoid.normalizedFactors I, ⟨fun p hp => ?_, ?_⟩, ?_⟩
    · exact Ideal.isPrime_of_prime (UniqueFactorizationMonoid.prime_of_normalized_factor p hp)
    · exact Ideal.prod_normalizedFactors_eq_self hI
    · rintro t ⟨ht, rfl⟩
      have hp : ∀ p ∈ t, Prime p := by
        intro p hp
        refine Ideal.prime_of_isPrime ?_ (ht p hp)
        rintro rfl
        exact hI (Multiset.prod_eq_zero (by simpa using hp))
      exact (UniqueFactorizationMonoid.normalizedFactors_prod_of_prime hp).symm
  refine ⟨hexists, ?_⟩
  rintro s - rfl
  exact map_multiset_prod Ideal.absNorm s

/-- The Dedekind property in any Dedekind domain (a domain that is Noetherian, integrally
closed, and in which every nonzero prime ideal is maximal): every nonzero ideal is a product
of prime ideals in exactly one way, apart from order. -/
theorem dedekind_domain_ideal_factors_uniquely
    (R : Type*) [CommRing R] [IsDedekindDomain R] (I : Ideal R) (hI : I ≠ ⊥) :
    ∃! s : Multiset (Ideal R), (∀ p ∈ s, p.IsPrime) ∧ s.prod = I := by
  refine ⟨UniqueFactorizationMonoid.normalizedFactors I, ⟨fun p hp => ?_, ?_⟩, ?_⟩
  · exact Ideal.isPrime_of_prime (UniqueFactorizationMonoid.prime_of_normalized_factor p hp)
  · exact Ideal.prod_normalizedFactors_eq_self hI
  · rintro t ⟨ht, rfl⟩
    have hp : ∀ p ∈ t, Prime p := by
      intro p hp
      refine Ideal.prime_of_isPrime ?_ (ht p hp)
      rintro rfl
      exact hI (Multiset.prod_eq_zero (by simpa using hp))
    exact (UniqueFactorizationMonoid.normalizedFactors_prod_of_prime hp).symm

/-- The house example in `ℤ[√-5]`: `P2 = (2, 1 + √-5)`, `P3 = (3, 1 + √-5)` and
`P3bar = (3, 1 - √-5)` are prime ideals; `(2) = P2 · P2`, `(3) = P3 · P3bar`,
`(1 + √-5) = P2 · P3`, `(1 - √-5) = P2 · P3bar`; so both splits of 6 give
`(6) = P2² · P3 · P3bar`. -/
theorem six_factors_as_prime_ideals_in_zsqrtd_neg_five :
    let r : ℤ√(-5) := Zsqrtd.sqrtd
    let P2 : Ideal (ℤ√(-5)) := Ideal.span {2, 1 + r}
    let P3 : Ideal (ℤ√(-5)) := Ideal.span {3, 1 + r}
    let P3bar : Ideal (ℤ√(-5)) := Ideal.span {3, 1 - r}
    P2.IsPrime ∧ P3.IsPrime ∧ P3bar.IsPrime ∧
      Ideal.span {(2 : ℤ√(-5))} = P2 * P2 ∧
      Ideal.span {(3 : ℤ√(-5))} = P3 * P3bar ∧
      Ideal.span {1 + r} = P2 * P3 ∧
      Ideal.span {1 - r} = P2 * P3bar ∧
      Ideal.span {(6 : ℤ√(-5))} = P2 ^ 2 * P3 * P3bar := by
  intro r P2 P3 P3bar
  have hr : r * r = -5 := by
    simp only [r, Zsqrtd.dmuld]; norm_num
  have hP2 : P2.IsPrime := by
    have := zsqrtd_neg_five_span_isPrime 2 1 (by norm_num) (by decide)
    simpa [P2, P3, P3bar, r, sub_eq_add_neg] using this
  have hP3 : P3.IsPrime := by
    have := zsqrtd_neg_five_span_isPrime 3 1 (by norm_num) (by decide)
    simpa [P2, P3, P3bar, r, sub_eq_add_neg] using this
  have hP3bar : P3bar.IsPrime := by
    have := zsqrtd_neg_five_span_isPrime 3 (-1) (by norm_num) (by decide)
    simpa [P2, P3, P3bar, r, sub_eq_add_neg] using this
  -- (2) = P2 * P2
  have e2 : Ideal.span {(2 : ℤ√(-5))} = P2 * P2 := by
    simp only [P2, Ideal.span_pair_mul_span_pair]
    apply le_antisymm
    · rw [Ideal.span_le, Set.singleton_subset_iff, SetLike.mem_coe]
      have g1 : (2 * 2 : ℤ√(-5)) ∈ Ideal.span {2 * 2, 2 * (1 + r), (1 + r) * 2, (1 + r) * (1 + r)} :=
        Ideal.subset_span (by simp)
      have g2 : (2 * (1 + r) : ℤ√(-5)) ∈ Ideal.span {2 * 2, 2 * (1 + r), (1 + r) * 2, (1 + r) * (1 + r)} :=
        Ideal.subset_span (by simp)
      have g4 : ((1 + r) * (1 + r) : ℤ√(-5)) ∈ Ideal.span {2 * 2, 2 * (1 + r), (1 + r) * 2, (1 + r) * (1 + r)} :=
        Ideal.subset_span (by simp)
      have : (2 : ℤ√(-5)) = 2 * (1 + r) - (1 + r) * (1 + r) - 2 * 2 := by
        linear_combination hr
      rw [this]
      exact sub_mem (sub_mem g2 g4) g1
    · rw [Ideal.span_le]
      simp only [Set.insert_subset_iff, Set.singleton_subset_iff, SetLike.mem_coe,
        Ideal.mem_span_singleton]
      exact ⟨⟨2, rfl⟩, ⟨1 + r, rfl⟩, ⟨1 + r, by ring⟩, ⟨-2 + r, by linear_combination hr⟩⟩
  -- (3) = P3 * P3bar
  have e3 : Ideal.span {(3 : ℤ√(-5))} = P3 * P3bar := by
    simp only [P3, P3bar, Ideal.span_pair_mul_span_pair]
    apply le_antisymm
    · rw [Ideal.span_le, Set.singleton_subset_iff, SetLike.mem_coe]
      have g1 : (3 * 3 : ℤ√(-5)) ∈ Ideal.span {3 * 3, 3 * (1 - r), (1 + r) * 3, (1 + r) * (1 - r)} :=
        Ideal.subset_span (by simp)
      have g4 : ((1 + r) * (1 - r) : ℤ√(-5)) ∈ Ideal.span {3 * 3, 3 * (1 - r), (1 + r) * 3, (1 + r) * (1 - r)} :=
        Ideal.subset_span (by simp)
      have : (3 : ℤ√(-5)) = 3 * 3 - (1 + r) * (1 - r) := by
        linear_combination (-1 : ℤ√(-5)) * hr
      rw [this]
      exact sub_mem g1 g4
    · rw [Ideal.span_le]
      simp only [Set.insert_subset_iff, Set.singleton_subset_iff, SetLike.mem_coe,
        Ideal.mem_span_singleton]
      exact ⟨⟨3, rfl⟩, ⟨1 - r, rfl⟩, ⟨1 + r, by ring⟩, ⟨2, by linear_combination (-1 : ℤ√(-5)) * hr⟩⟩
  -- (1 + r) = P2 * P3
  have e1p : Ideal.span {1 + r} = P2 * P3 := by
    simp only [P2, P3, Ideal.span_pair_mul_span_pair]
    apply le_antisymm
    · rw [Ideal.span_le, Set.singleton_subset_iff, SetLike.mem_coe]
      have g2 : (2 * (1 + r) : ℤ√(-5)) ∈ Ideal.span {2 * 3, 2 * (1 + r), (1 + r) * 3, (1 + r) * (1 + r)} :=
        Ideal.subset_span (by simp)
      have g3 : ((1 + r) * 3 : ℤ√(-5)) ∈ Ideal.span {2 * 3, 2 * (1 + r), (1 + r) * 3, (1 + r) * (1 + r)} :=
        Ideal.subset_span (by simp)
      have : (1 + r : ℤ√(-5)) = (1 + r) * 3 - 2 * (1 + r) := by ring
      rw [this]
      exact sub_mem g3 g2
    · rw [Ideal.span_le]
      simp only [Set.insert_subset_iff, Set.singleton_subset_iff, SetLike.mem_coe,
        Ideal.mem_span_singleton]
      exact ⟨⟨1 - r, by linear_combination hr⟩, ⟨2, by ring⟩, ⟨3, rfl⟩,
        ⟨1 + r, rfl⟩⟩
  -- (1 - r) = P2 * P3bar
  have e1m : Ideal.span {1 - r} = P2 * P3bar := by
    simp only [P2, P3bar, Ideal.span_pair_mul_span_pair]
    apply le_antisymm
    · rw [Ideal.span_le, Set.singleton_subset_iff, SetLike.mem_coe]
      have g1 : (2 * 3 : ℤ√(-5)) ∈ Ideal.span {2 * 3, 2 * (1 - r), (1 + r) * 3, (1 + r) * (1 - r)} :=
        Ideal.subset_span (by simp)
      have g2 : (2 * (1 - r) : ℤ√(-5)) ∈ Ideal.span {2 * 3, 2 * (1 - r), (1 + r) * 3, (1 + r) * (1 - r)} :=
        Ideal.subset_span (by simp)
      have g3 : ((1 + r) * 3 : ℤ√(-5)) ∈ Ideal.span {2 * 3, 2 * (1 - r), (1 + r) * 3, (1 + r) * (1 - r)} :=
        Ideal.subset_span (by simp)
      have : (1 - r : ℤ√(-5)) = (-r) * ((1 + r) * 3) - 2 * (2 * 3) - 2 * (1 - r) := by
        linear_combination (3 : ℤ√(-5)) * hr
      rw [this]
      exact sub_mem (sub_mem (Ideal.mul_mem_left _ _ g3) (Ideal.mul_mem_left _ _ g1)) g2
    · rw [Ideal.span_le]
      simp only [Set.insert_subset_iff, Set.singleton_subset_iff, SetLike.mem_coe,
        Ideal.mem_span_singleton]
      exact ⟨⟨1 + r, by linear_combination hr⟩, ⟨2, by ring⟩,
        ⟨-2 + r, by linear_combination hr⟩, ⟨1 + r, by ring⟩⟩
  refine ⟨hP2, hP3, hP3bar, e2, e3, e1p, e1m, ?_⟩
  rw [pow_two, mul_assoc, ← e2, ← e3, Ideal.span_singleton_mul_span_singleton]
  norm_num

-- 6 = 2 × 3 = (1 + √-5)(1 - √-5) in ℤ[√-5].
example : (⟨1, 1⟩ : ℤ√(-5)) * ⟨1, -1⟩ = 6 := by decide
example : (2 : ℤ√(-5)) * 3 = 6 := by decide

-- The norms a² + 5b² of 2, 3, 1 + √-5, 1 - √-5 are 4, 9, 6, 6.
example : Zsqrtd.norm (2 : ℤ√(-5)) = 4 ∧ Zsqrtd.norm (3 : ℤ√(-5)) = 9 ∧
    Zsqrtd.norm (⟨1, 1⟩ : ℤ√(-5)) = 6 ∧ Zsqrtd.norm (⟨1, -1⟩ : ℤ√(-5)) = 6 := by decide

-- No number a + b√-5 has norm 2 or 3 (only |a| ≤ 1, b = 0 could, and those give 0 or 1).
example : ∀ a ∈ Finset.Icc (-2 : ℤ) 2, ∀ b ∈ Finset.Icc (-1 : ℤ) 1,
    a ^ 2 + 5 * b ^ 2 ≠ 2 ∧ a ^ 2 + 5 * b ^ 2 ≠ 3 := by decide

-- Norm check: 2 × 2 × 3 × 3 = 36 = 6² + 5 · 0².
example : 2 * 2 * 3 * 3 = 6 ^ 2 + 5 * 0 ^ 2 := by norm_num

-- 21 = 3 × 7 = (1 + 2√-5)(1 - 2√-5) = (4 + √-5)(4 - √-5).
example : (3 : ℤ√(-5)) * 7 = 21 ∧ (⟨1, 2⟩ : ℤ√(-5)) * ⟨1, -2⟩ = 21 ∧
    (⟨4, 1⟩ : ℤ√(-5)) * ⟨4, -1⟩ = 21 := by decide

#print axioms ideal_factors_uniquely_into_prime_ideals
#print axioms dedekind_domain_ideal_factors_uniquely
#print axioms six_factors_as_prime_ideals_in_zsqrtd_neg_five
