-- The Sylow theorems: in a finite group of size p^a * m with p prime and p not dividing m, subgroups of size p^a exist, any two are conjugate, and their number leaves remainder 1 on dividing by p, equals the index of one such subgroup's normaliser, and divides m; as uses, the subset count C(p^a m, p^a) leaves the same remainder as m, and every group of order 15 is cyclic.
import Mathlib.GroupTheory.Sylow
import Mathlib.GroupTheory.SpecificGroups.Cyclic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Choose.Lucas
import Mathlib.NumberTheory.Divisors

theorem factorization_prime_pow_mul_self {p a m : ℕ} (hp : p.Prime) (hm : ¬ p ∣ m) :
    (p ^ a * m).factorization p = a := by
  have hm0 : m ≠ 0 := by rintro rfl; exact hm (dvd_zero p)
  rw [Nat.factorization_mul (pow_ne_zero _ hp.ne_zero) hm0, Finsupp.add_apply,
    Nat.factorization_pow, Finsupp.smul_apply, hp.factorization_self,
    Nat.factorization_eq_zero_of_not_dvd hm]
  simp

#print axioms factorization_prime_pow_mul_self

theorem conj_mem_zpowers_of_card_eq_one {G : Type*} [Group G] {p : ℕ}
    (h1 : Nat.card {P : Subgroup G // Nat.card P = p} = 1) (x : G) (hx : orderOf x = p)
    (g : G) : g * x * g⁻¹ ∈ Subgroup.zpowers x := by
  have hsub : Subsingleton {P : Subgroup G // Nat.card P = p} := by
    have := Nat.card_eq_one_iff_unique.mp h1
    exact this.1
  have hH : Nat.card (Subgroup.zpowers x) = p := by rw [Nat.card_zpowers, hx]
  have hH' : Nat.card ((Subgroup.zpowers x).map (MulAut.conj g).toMonoidHom) = p := by
    rw [Subgroup.card_map_of_injective (MulAut.conj g).injective, hH]
  have heq := congrArg Subtype.val
    (Subsingleton.elim (⟨_, hH'⟩ : {P : Subgroup G // Nat.card P = p}) ⟨_, hH⟩)
  simp only at heq
  rw [← heq]
  exact ⟨x, Subgroup.mem_zpowers x, by simp⟩

#print axioms conj_mem_zpowers_of_card_eq_one

/-- The three Sylow theorems, as the card states them: let G be a finite group, p a prime, and
split the size as p^a * m with p not dividing m. Then (existence) G has a subgroup of size p^a;
(conjugacy) any two subgroups of size p^a are conjugate, Q = g * P * g⁻¹ for some g; and
(counting) the number n_p of subgroups of size p^a leaves remainder 1 on dividing by p, equals
the index [G : N(P)] of the normaliser of any one of them, and divides m. -/
theorem sylow_exist_conjugate_count {G : Type*} [Group G] [Finite G] {p a m : ℕ}
    (hp : p.Prime) (hG : Nat.card G = p ^ a * m) (hm : ¬ p ∣ m) :
    (∃ P : Subgroup G, Nat.card P = p ^ a) ∧
      (∀ P Q : Subgroup G, Nat.card P = p ^ a → Nat.card Q = p ^ a →
        ∃ g : G, Q = P.map (MulAut.conj g).toMonoidHom) ∧
      (Nat.card {P : Subgroup G // Nat.card P = p ^ a} ≡ 1 [MOD p] ∧
        (∀ P : Subgroup G, Nat.card P = p ^ a →
          Nat.card {P : Subgroup G // Nat.card P = p ^ a} =
            (Subgroup.normalizer (P : Set G)).index) ∧
        Nat.card {P : Subgroup G // Nat.card P = p ^ a} ∣ m) := by
  have : Fact p.Prime := ⟨hp⟩
  have hfac : (Nat.card G).factorization p = a := by
    rw [hG]; exact factorization_prime_pow_mul_self hp hm
  let e : {P : Subgroup G // Nat.card P = p ^ a} ≃ Sylow p G :=
    { toFun := fun P => Sylow.ofCard P.1 (by rw [P.2, hfac])
      invFun := fun Q => ⟨Q, by rw [Q.card_eq_multiplicity, hfac]⟩
      left_inv := fun P => rfl
      right_inv := fun Q => Sylow.ext rfl }
  have hcard : Nat.card {P : Subgroup G // Nat.card P = p ^ a} = Nat.card (Sylow p G) :=
    Nat.card_congr e
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · obtain ⟨Q⟩ := (inferInstance : Nonempty (Sylow p G))
    exact ⟨Q, (e.symm Q).2⟩
  · intro P Q hP hQ
    obtain ⟨g, hg⟩ := MulAction.exists_smul_eq G (e ⟨P, hP⟩) (e ⟨Q, hQ⟩)
    refine ⟨g, ?_⟩
    have := congrArg (fun R : Sylow p G => (R : Subgroup G)) hg
    simp only [Sylow.coe_subgroup_smul] at this
    exact this.symm
  · rw [hcard]; exact card_sylow_modEq_one p G
  · intro P hP
    rw [hcard]
    exact (e ⟨P, hP⟩).card_eq_index_normalizer
  · rw [hcard]
    obtain ⟨Q⟩ := (inferInstance : Nonempty (Sylow p G))
    have h1 := Q.card_dvd_index
    have h2 := (Q : Subgroup G).card_mul_index
    rw [Q.card_eq_multiplicity, hfac, hG] at h2
    have : (Q : Subgroup G).index = m :=
      Nat.eq_of_mul_eq_mul_left (pow_pos hp.pos a) h2
    rwa [this] at h1

/-- The fold in Step 1: the number of subsets of size p^a in a set of p^a * m things leaves the
same remainder as m on dividing by the prime p. -/
theorem choose_prime_pow_mul_modEq {p a m : ℕ} (hp : p.Prime) :
    (p ^ a * m).choose (p ^ a) ≡ m [MOD p] := by
  have : Fact p.Prime := ⟨hp⟩
  have := Choose.choose_pow_mul_pow_mul_modEq_choose_nat (p := p) (k := a) (a := m) (b := 1)
  simpa using this

/-- Step 4: every group with 15 members is cyclic, the 15-position dial. -/
theorem card_fifteen_isCyclic {G : Type*} [Group G] (hG : Nat.card G = 15) : IsCyclic G := by
  have hfin : Finite G := Nat.finite_of_card_ne_zero (by rw [hG]; norm_num)
  have h3 : Nat.card {P : Subgroup G // Nat.card P = 3} = 1 := by
    obtain ⟨-, -, hmod, -, hdvd⟩ :=
      sylow_exist_conjugate_count (G := G) (p := 3) (a := 1) (m := 5) Nat.prime_three
        (by rw [hG]; norm_num) (by norm_num)
    rw [pow_one] at hmod hdvd
    have hle := Nat.le_of_dvd (by norm_num) hdvd
    unfold Nat.ModEq at hmod
    interval_cases h : Nat.card {P : Subgroup G // Nat.card P = 3} <;> simp_all
  have h5 : Nat.card {P : Subgroup G // Nat.card P = 5} = 1 := by
    obtain ⟨-, -, hmod, -, hdvd⟩ :=
      sylow_exist_conjugate_count (G := G) (p := 5) (a := 1) (m := 3) Nat.prime_five
        (by rw [hG]; norm_num) (by norm_num)
    rw [pow_one] at hmod hdvd
    have hle := Nat.le_of_dvd (by norm_num) hdvd
    unfold Nat.ModEq at hmod
    interval_cases h : Nat.card {P : Subgroup G // Nat.card P = 5} <;> simp_all
  have : Fact (Nat.Prime 3) := ⟨Nat.prime_three⟩
  have : Fact (Nat.Prime 5) := ⟨Nat.prime_five⟩
  obtain ⟨x, hx⟩ := exists_prime_orderOf_dvd_card' (G := G) 3 (by rw [hG]; norm_num)
  obtain ⟨y, hy⟩ := exists_prime_orderOf_dvd_card' (G := G) 5 (by rw [hG]; norm_num)
  obtain ⟨c, hc⟩ : ∃ c : G, c = x * y * x⁻¹ * y⁻¹ := ⟨_, rfl⟩
  have hcy : c ∈ Subgroup.zpowers y := by
    rw [hc]
    exact Subgroup.mul_mem _ (conj_mem_zpowers_of_card_eq_one h5 y hy x) (Subgroup.inv_mem _
      (Subgroup.mem_zpowers y))
  have hcx : c ∈ Subgroup.zpowers x := by
    have h := Subgroup.inv_mem _ (conj_mem_zpowers_of_card_eq_one h3 x hx y)
    have : x * y * x⁻¹ * y⁻¹ = x * (y * x * y⁻¹)⁻¹ := by group
    rw [hc]
    rw [this]
    exact Subgroup.mul_mem _ (Subgroup.mem_zpowers x) h
  have d3 : orderOf c ∣ 3 := by
    have := (Subgroup.zpowers x).orderOf_dvd_natCard hcx
    rwa [Nat.card_zpowers, hx] at this
  have d5 : orderOf c ∣ 5 := by
    have := (Subgroup.zpowers y).orderOf_dvd_natCard hcy
    rwa [Nat.card_zpowers, hy] at this
  have hc1 : orderOf c = 1 := by
    have := Nat.dvd_gcd d3 d5
    simpa using this
  rw [orderOf_eq_one_iff] at hc1
  have hcomm : Commute x y := by
    have : x * y = c * (y * x) := by rw [hc]; group
    rw [hc1, one_mul] at this
    exact this
  apply isCyclic_of_orderOf_eq_card (x * y)
  rw [hcomm.orderOf_mul_eq_mul_orderOf_of_coprime (by rw [hx, hy]; norm_num), hx, hy, hG]

-- Order 15 = 3 x 5: the divisors of 5 leaving 1 on dividing by 3, and of 3 leaving 1 on 5.
example : 15 = 3 ^ 1 * 5 ∧ 15 = 5 ^ 1 * 3 := by norm_num
example : (Nat.divisors 5).filter (fun d => d % 3 = 1) = {1} := by decide
example : (Nat.divisors 3).filter (fun d => d % 5 = 1) = {1} := by decide
-- "Divides m" alone leaves n_3 at 1 or 5.
example : Nat.divisors 5 = {1, 5} := by decide
-- 1 identity + 2 of order 3 + 4 of order 5 = 7; 8 left over, and the 15-dial has 8 of order 15.
example : 1 + (3 - 1) * 1 + (5 - 1) * 1 = 7 ∧ 15 - 7 = 8 := by norm_num
example : ((Finset.range 15).filter (fun k => Nat.Coprime k 15)).card = 8 := by decide
-- Order 24 = 2^3 x 3: n_2 may be 1 or 3, n_3 may be 1 or 4.
example : 24 = 2 ^ 3 * 3 ∧ 24 = 3 ^ 1 * 8 := by norm_num
example : (Nat.divisors 3).filter (fun d => d % 2 = 1) = {1, 3} := by decide
example : (Nat.divisors 8).filter (fun d => d % 3 = 1) = {1, 4} := by decide
-- Normalisers of sizes 8 and 6 in S4: 24 / 8 = 3 and 24 / 6 = 4.
example : 24 / 8 = 3 ∧ 24 / 6 = 4 := by norm_num
-- The subset counts and their remainders.
example : Nat.choose 24 8 = 735471 ∧ 735471 % 2 = 1 ∧ 3 % 2 = 1 := by decide
example : Nat.choose 15 3 = 455 ∧ 455 % 3 = 2 ∧ 5 % 3 = 2 := by decide
example : Nat.choose 15 5 = 3003 ∧ 3003 % 5 = 3 ∧ 3 % 5 = 3 := by decide
-- Order 21 = 3 x 7: n_3 may be 1 or 7.
example : (Nat.divisors 7).filter (fun d => d % 3 = 1) = {1, 7} := by decide
-- Order 56: n_7 may be 1 or 8, n_2 may be 1 or 7; 8 subgroups of size 7 hold 48 members of order 7.
example : (Nat.divisors 8).filter (fun d => d % 7 = 1) = {1, 8} := by decide
example : (Nat.divisors 7).filter (fun d => d % 2 = 1) = {1, 7} := by decide
example : 8 * (7 - 1) = 48 ∧ 56 - 48 = 8 := by norm_num
example : Nat.choose 56 7 = 231917400 ∧ 231917400 % 7 = 1 ∧ 8 % 7 = 1 := by decide

#print axioms sylow_exist_conjugate_count
#print axioms choose_prime_pow_mul_modEq
#print axioms card_fifteen_isCyclic
