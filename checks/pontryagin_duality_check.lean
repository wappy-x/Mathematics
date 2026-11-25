-- Pontryagin duality: for every finite abelian group, such as the 12-hour clock, evaluation is an isomorphism onto the dual of the dual, Plancherel holds with weight 1/|G| on the characters, and summing over a subgroup equals |H|/|G| times the transform summed over its annihilator.
import Mathlib.Analysis.Fourier.FiniteAbelian.PontryaginDuality

open Finset ComplexConjugate

/-- **The double-dual theorem, for a finite abelian group.** For a finite abelian group `G`
(with the discrete topology, so it is locally compact), the map `α` that sends `x` to
"evaluate at `x`", `α x χ = χ x`, is an isomorphism of groups from `G` onto the dual of its
dual group: every character of the dual group is "read the character at some point of `G`",
for exactly one point. For a finite group every character `G → ℂ` lands on the unit circle,
so these are the card's characters to `𝕋`. -/
theorem double_dual_evaluation_isomorphism (G : Type*) [AddCommGroup G] [Finite G] :
    ∃ α : G ≃+ AddChar (AddChar G ℂ) ℂ, ∀ (x : G) (χ : AddChar G ℂ), α x χ = χ x := by
  exact ⟨AddChar.doubleDualEquiv, fun x χ => rfl⟩

/-- **Plancherel with paired measures, for a finite abelian group.** Put counting measure on
`G` and weight `1/|G|` at each character. Then the signal's energy on the group equals the
energy of its transform `f̂(χ) = ∑ₓ f(x) · conj (χ x)` on the dual group. -/
theorem plancherel_finite_abelian (G : Type*) [AddCommGroup G] [Fintype G] (f : G → ℂ) :
    ∑ x, ‖f x‖ ^ 2 =
      (Fintype.card G : ℝ)⁻¹ * ∑ χ : AddChar G ℂ, ‖∑ x, f x * conj (χ x)‖ ^ 2 := by
  classical
  have hG : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  apply Complex.ofReal_injective
  push_cast
  simp_rw [← Complex.mul_conj', map_sum, map_mul, Complex.conj_conj, sum_mul, mul_sum]
  have key : ∀ x y : G, ∑ χ : AddChar G ℂ, f x * conj (χ x) * (conj (f y) * χ y)
      = f x * conj (f y) * (if y - x = 0 then (Fintype.card G : ℂ) else 0) := by
    intro x y
    rw [← AddChar.sum_apply_eq_ite, mul_sum]
    refine sum_congr rfl fun χ _ => ?_
    rw [sub_eq_add_neg, AddChar.map_add_eq_mul, AddChar.map_neg_eq_conj]
    ring
  rw [sum_comm]
  apply Finset.sum_congr rfl
  intro y _
  rw [sum_comm]
  simp_rw [← Finset.mul_sum (univ : Finset (AddChar G ℂ)), key, sub_eq_zero, mul_ite, mul_zero, sum_ite_eq', mem_univ, ite_true]
  field_simp

open scoped Classical in
/-- **Poisson summation on a finite abelian group.** For a subgroup `H` of `G`, its annihilator
is the set of characters that read 1 on every point of `H`. With counting measure on `H` and
weight `|H|/|G|` on each character of the annihilator, the signal summed over the subgroup
equals its transform `f̂(χ) = ∑ₓ f(x) · conj (χ x)` summed over the annihilator. -/
theorem poisson_summation_subgroup_annihilator (G : Type*) [AddCommGroup G] [Fintype G]
    (H : AddSubgroup G) (f : G → ℂ) :
    ∑ h : H, f h =
      ((Nat.card H : ℂ) / Fintype.card G) *
        ∑ χ ∈ (univ.filter fun χ : AddChar G ℂ => ∀ h ∈ H, χ h = 1),
          ∑ x, f x * conj (χ x) := by
  set A := (univ.filter fun χ : AddChar G ℂ => ∀ h ∈ H, χ h = 1) with hA
  -- a character outside the subgroup
  have hsep : ∀ x : G, x ∉ H → ∃ χ ∈ A, χ x ≠ 1 := by
    intro x hx
    have hne : (QuotientAddGroup.mk x : G ⧸ H) ≠ 0 := by
      rwa [Ne, QuotientAddGroup.eq_zero_iff]
    obtain ⟨ψ, hψ⟩ := AddChar.exists_apply_ne_zero.2 hne
    refine ⟨ψ.compAddMonoidHom (QuotientAddGroup.mk' H), ?_, hψ⟩
    simp only [hA, mem_filter, mem_univ, true_and, AddChar.compAddMonoidHom_apply,
      QuotientAddGroup.mk'_apply]
    intro h hh
    rw [(QuotientAddGroup.eq_zero_iff h).2 hh, AddChar.map_zero_eq_one]
  have hS : ∀ x : G, ∑ χ ∈ A, χ x = if x ∈ H then (A.card : ℂ) else 0 := by
    intro x
    split_ifs with hx
    · rw [← nsmul_one, ← sum_const]
      refine sum_congr rfl fun χ hχ => ?_
      exact (mem_filter.1 hχ).2 x hx
    · obtain ⟨χ₀, hχ₀, hne⟩ := hsep x hx
      have : ∑ χ ∈ A, χ x = χ₀ x * ∑ χ ∈ A, χ x := by
        rw [mul_sum]
        refine sum_nbij' (fun χ => -χ₀ + χ) (fun χ => χ₀ + χ) ?_ ?_ ?_ ?_ ?_
        · intro χ hχ
          simp only [hA, mem_filter, mem_univ, true_and] at hχ ⊢
          intro h hh
          rw [AddChar.add_apply, AddChar.neg_apply, (mem_filter.1 hχ₀).2 (-h) (neg_mem hh),
            hχ h hh, one_mul]
        · intro χ hχ
          simp only [hA, mem_filter, mem_univ, true_and] at hχ ⊢
          intro h hh
          rw [AddChar.add_apply, (mem_filter.1 hχ₀).2 h hh, hχ h hh, one_mul]
        · intro χ _; simp
        · intro χ _; simp
        · intro χ _
          rw [AddChar.add_apply, AddChar.neg_apply, ← mul_assoc, ← AddChar.map_add_eq_mul,
            add_neg_cancel, AddChar.map_zero_eq_one, one_mul]
      have h1 : (1 - χ₀ x) * ∑ χ ∈ A, χ x = 0 := by rw [sub_mul, one_mul, ← this, sub_self]
      exact (mul_eq_zero.1 h1).resolve_left (sub_ne_zero.2 (Ne.symm hne))
  -- the size of the annihilator
  have hcard : (A.card : ℂ) * Nat.card H = Fintype.card G := by
    have e1 : ∑ x : G, ∑ χ ∈ A, χ x = (A.card : ℂ) * Nat.card H := by
      simp_rw [hS, sum_ite, sum_const_zero, add_zero, sum_const, nsmul_eq_mul]
      rw [mul_comm]
      congr 2
      rw [Nat.card_eq_fintype_card, ← Fintype.card_subtype]
    have e2 : ∑ x : G, ∑ χ ∈ A, χ x = Fintype.card G := by
      rw [sum_comm]
      simp_rw [AddChar.sum_eq_ite]
      rw [sum_ite, sum_const_zero, add_zero, sum_const, nsmul_eq_mul]
      have : filter (fun χ => χ = 0) A = {0} := by
        ext χ
        simp only [hA, mem_filter, mem_univ, true_and, mem_singleton]
        constructor
        · exact fun h => h.2
        · rintro rfl; exact ⟨fun h _ => AddChar.zero_apply h, rfl⟩
      rw [this, card_singleton, Nat.cast_one, one_mul]
    rw [← e1, e2]
  have hG : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  have hRHS : ∑ χ ∈ A, ∑ x, f x * conj (χ x) = (A.card : ℂ) * ∑ h : H, f h := by
    rw [sum_comm]
    simp_rw [← mul_sum, ← AddChar.map_neg_eq_conj, hS, neg_mem_iff, mul_ite, mul_zero]
    rw [← sum_filter, mul_comm, sum_mul]
    exact sum_subtype _ (by simp) _
  rw [hRHS, ← mul_assoc, div_mul_eq_mul_div, mul_comm (Nat.card H : ℂ), hcard, div_self hG,
    one_mul]

/-! ### The card's whole-number worked examples on the clock `ℤ/12` -/

-- Energy of `f(x) = x` on the clock: 0² + 1² + ⋯ + 11² = 506.
example : ∑ x ∈ range 12, x ^ 2 = 506 := by decide

-- The transform at `k = 0`: 0 + 1 + ⋯ + 11 = 66, and its share of the dual energy, 66²/12 = 363.
example : ∑ x ∈ range 12, x = 66 := by decide
example : (66 ^ 2 : ℚ) / 12 = 363 := by norm_num

-- The annihilator of `H = {0, 3, 6, 9}`: the `k` with `3k` a multiple of 12 are 0, 4, 8.
example : (univ.filter fun k : ZMod 12 => ∀ h ∈ ({0, 3, 6, 9} : Finset (ZMod 12)), k * h = 0)
    = {0, 4, 8} := by decide

-- Poisson on the clock: the sum of `f` over `H` is 18, and `(66 + (−12)) / 3 = 18`.
example : 0 + 3 + 6 + 9 = 18 := by norm_num
example : ((66 : ℚ) + (-12)) / 3 = 18 := by norm_num

-- The double dual by search: for each 12th root `w = e^(2πij/12)`, exactly one hour `x` has
-- `χ_k(x) = w^k` for every `k`, that is `k x ≡ k j (mod 12)`.
example : ∀ j : ZMod 12, (univ.filter fun x : ZMod 12 => ∀ k : ZMod 12, k * x = k * j) = {j} := by
  decide

-- The clock's annihilator in `ℤ`, for `|n| ≤ 30`: −24, −12, 0, 12, 24.
example : ((Icc (-30 : ℤ) 30).filter fun n => (12 : ℤ) ∣ n) = {-24, -12, 0, 12, 24} := by decide

-- What breaks: counting measure on both sides gives 12 × 506 = 6072, and all of `k = 0..23`
-- gives 2 × 506 = 1012.
example : 12 * 506 = 6072 := by norm_num
example : 2 * 506 = 1012 := by norm_num

-- What breaks: `S₃` is not abelian. A character sends the 3-cycle `r` and the swap `s` to
-- sixth roots `e^(2πiu/6)`, `e^(2πiv/6)` with `r³ = s² = 1` and `s r s = r⁻¹`; only 2 exist.
example : (univ.filter fun p : ZMod 6 × ZMod 6 =>
    3 * p.1 = 0 ∧ 2 * p.2 = 0 ∧ p.2 + p.1 + p.2 = -p.1).card = 2 := by decide

#print axioms double_dual_evaluation_isomorphism
#print axioms plancherel_finite_abelian
#print axioms poisson_summation_subgroup_annihilator
