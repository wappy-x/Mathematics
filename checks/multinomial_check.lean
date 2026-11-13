-- Multinomial: for n independent trials that each land in exactly one of r categories with the same chances p, the chance of a whole tally k is n!/(k_1!...k_r!) times p_1^k_1...p_r^k_r (and zero if the counts do not add to n), each count alone is Binomial(n, p_i), and two different counts have covariance -n p_i p_j.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Covariance
import Mathlib.Data.Nat.Choose.Multinomial
import Mathlib.Algebra.MvPolynomial.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- The count of category `i`: how many of the `n` trials landed in category `i`. -/
def tallyCount {Ω : Type*} {n r : ℕ} (X : Fin n → Ω → Fin r) (i : Fin r) (ω : Ω) : ℕ :=
  (Finset.univ.filter (fun t => X t ω = i)).card

section
open Finset

lemma tally_ind_eq_iff {r : ℕ} (a b : Fin r → ℕ) :
    Finsupp.indicator (Finset.univ : Finset (Fin r)) (fun i _ => a i) =
      Finsupp.indicator univ (fun i _ => b i) ↔ a = b := by
  constructor
  · intro h; funext i
    have := DFunLike.congr_fun h i
    simpa [Finsupp.indicator_of_mem (mem_univ i)] using this
  · rintro rfl; rfl

lemma card_tally_eq (n r : ℕ) (k : Fin r → ℕ) :
    (univ.filter (fun x : Fin n → Fin r =>
        ∀ i, (univ.filter (fun t => x t = i)).card = k i)).card =
      if ∑ i, k i = n then Nat.multinomial univ k else 0 := by
  classical
  set d : Fin r →₀ ℕ := Finsupp.indicator univ (fun i _ => k i) with hd
  have hprod : ∀ x : Fin n → Fin r, (∏ t, (MvPolynomial.X (x t) : MvPolynomial (Fin r) ℕ)) =
      ∏ i, MvPolynomial.X i ^ (univ.filter (fun t => x t = i)).card := by
    intro x
    rw [← Finset.prod_fiberwise univ x (fun t => (MvPolynomial.X (x t) : MvPolynomial (Fin r) ℕ))]
    refine Finset.prod_congr rfl fun i _ => ?_
    rw [Finset.prod_congr rfl (g := fun _ => MvPolynomial.X i) (fun t ht => by
      rw [(Finset.mem_filter.1 ht).2]), Finset.prod_const]
  have key : (∑ i, (MvPolynomial.X i : MvPolynomial (Fin r) ℕ)) ^ n =
      ∑ x : Fin n → Fin r, ∏ i, MvPolynomial.X i ^ (univ.filter (fun t => x t = i)).card := by
    rw [← Fin.prod_const, Finset.prod_univ_sum]
    simp only [Fintype.piFinset_univ]
    exact Finset.sum_congr rfl fun x _ => hprod x
  have h1 := congrArg (fun p : MvPolynomial (Fin r) ℕ => p.coeff d) key
  rw [Finset.sum_pow_eq_sum_piAntidiag] at h1
  simp only [MvPolynomial.coeff_sum, MvPolynomial.coeff_C_mul, ← map_natCast (MvPolynomial.C),
    MvPolynomial.coeff_prod_X_pow, hd, tally_ind_eq_iff, mul_ite, mul_one, mul_zero] at h1
  rw [Finset.sum_ite_eq] at h1
  simp only [mem_piAntidiag, mem_univ, implies_true, and_true, Nat.cast_id] at h1
  rw [h1, Finset.sum_boole]
  simp only [Nat.cast_id, funext_iff, eq_comm (a := k _)]

end

lemma tally_setOf_forall_eq {Ω : Type*} {n r : ℕ} (X : Fin n → Ω → Fin r)
    (S : Fin n → Set (Fin r)) :
    {ω | ∀ t, X t ω ∈ S t} = ⋂ t ∈ (Finset.univ : Finset (Fin n)), X t ⁻¹' S t := by
  ext ω; simp

lemma tally_measurableSet_forall {Ω : Type*} [MeasurableSpace Ω] {n r : ℕ}
    (X : Fin n → Ω → Fin r) (hmeas : ∀ t, Measurable (X t)) (S : Fin n → Set (Fin r)) :
    MeasurableSet {ω | ∀ t, X t ω ∈ S t} := by
  rw [tally_setOf_forall_eq]
  exact Finset.measurableSet_biInter _ fun t _ => hmeas t MeasurableSet.of_discrete

lemma tally_prob_forall {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n r : ℕ} (X : Fin n → Ω → Fin r) (hindep : iIndepFun X P)
    (S : Fin n → Set (Fin r)) :
    P.real {ω | ∀ t, X t ω ∈ S t} = ∏ t, P.real (X t ⁻¹' S t) := by
  rw [tally_setOf_forall_eq, measureReal_def,
    hindep.measure_inter_preimage_eq_mul Finset.univ (fun t _ => MeasurableSet.of_discrete),
    ENNReal.toReal_prod]
  rfl

#print axioms tally_ind_eq_iff
#print axioms card_tally_eq
#print axioms tally_setOf_forall_eq
#print axioms tally_measurableSet_forall
#print axioms tally_prob_forall

/-- The joint mass. Take a fixed number `n` of trials `X 0, ..., X (n-1)`. Each trial lands in
exactly one of `r` categories (its value is one of `0, ..., r-1`), every trial has the same
chance `p i` of landing in category `i`, and the trials are independent. Then the chance that
the counts come out as the tally `k` is the multinomial coefficient `n! / (k_1! ... k_r!)` times
`p_1^k_1 ... p_r^k_r` when the `k_i` add to `n`, and zero when they do not. -/
theorem multinomial_joint_mass {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n r : ℕ} (X : Fin n → Ω → Fin r) (p : Fin r → ℝ)
    (hmeas : ∀ t, Measurable (X t)) (hindep : iIndepFun X P)
    (hsame : ∀ t i, P.real (X t ⁻¹' {i}) = p i) (k : Fin r → ℕ) :
    P.real {ω | ∀ i, tallyCount X i ω = k i} =
      if ∑ i, k i = n then (Nat.multinomial Finset.univ k : ℝ) * ∏ i, p i ^ k i else 0 := by
  classical
  set S := Finset.univ.filter (fun x : Fin n → Fin r =>
    ∀ i, (Finset.univ.filter (fun t => x t = i)).card = k i) with hS
  have hev : {ω | ∀ i, tallyCount X i ω = k i} =
      ⋃ x ∈ S, {ω | ∀ t, X t ω ∈ ({x t} : Set (Fin r))} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Set.mem_singleton_iff, hS, Finset.mem_filter,
      Finset.mem_univ, true_and, exists_prop, tallyCount]
    constructor
    · intro h
      exact ⟨_, h, fun t => rfl⟩
    · rintro ⟨x, hx, hω⟩
      have : (fun t => X t ω) = x := funext hω
      subst this
      exact hx
  rw [hev, measureReal_biUnion_finset]
  · rw [Finset.sum_congr rfl (g := fun _ => ∏ i, p i ^ k i)]
    · rw [Finset.sum_const, hS, card_tally_eq, nsmul_eq_mul]
      split_ifs <;> simp
    · intro x hx
      rw [hS, Finset.mem_filter] at hx
      rw [tally_prob_forall P X hindep]
      simp_rw [hsame]
      rw [← Finset.prod_fiberwise Finset.univ x (fun t => p (x t))]
      refine Finset.prod_congr rfl fun i _ => ?_
      rw [Finset.prod_congr rfl (g := fun _ => p i) (fun t ht => by
        rw [(Finset.mem_filter.1 ht).2]), Finset.prod_const, hx.2 i]
  · intro x _ y _ hxy
    refine Set.disjoint_left.2 fun ω h1 h2 => hxy ?_
    funext t
    simp only [Set.mem_ofPred_eq, Set.mem_singleton_iff] at h1 h2
    rw [← h1 t, h2 t]
  · intro x _
    exact tally_measurableSet_forall X hmeas _

/-- Each count alone is binomial: under the same conditions, the count of category `i`
follows Binomial(n, p_i), so it equals `k` with chance `C(n, k) p_i^k (1 - p_i)^(n - k)`. -/
theorem multinomial_count_binomial {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n r : ℕ} (X : Fin n → Ω → Fin r) (p : Fin r → ℝ)
    (hmeas : ∀ t, Measurable (X t)) (hindep : iIndepFun X P)
    (hsame : ∀ t i, P.real (X t ⁻¹' {i}) = p i) (i : Fin r) (k : ℕ) :
    P.real {ω | tallyCount X i ω = k} = (n.choose k : ℝ) * p i ^ k * (1 - p i) ^ (n - k) := by
  classical
  have hev : {ω | tallyCount X i ω = k} =
      ⋃ A ∈ Finset.powersetCard k (Finset.univ : Finset (Fin n)),
        {ω | ∀ t, X t ω ∈ {a | a = i ↔ t ∈ A}} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_powersetCard, exists_prop,
      tallyCount]
    constructor
    · intro h
      exact ⟨_, ⟨Finset.subset_univ _, h⟩, fun t => by simp⟩
    · rintro ⟨A, ⟨-, hA⟩, hω⟩
      have : Finset.univ.filter (fun t => X t ω = i) = A := by
        ext t; simp [hω t]
      rw [this, hA]
  have hpt : ∀ (A : Finset (Fin n)) t,
      P.real (X t ⁻¹' {a | a = i ↔ t ∈ A}) = if t ∈ A then p i else 1 - p i := by
    intro A t
    by_cases ht : t ∈ A
    · have : X t ⁻¹' {a | a = i ↔ t ∈ A} = X t ⁻¹' {i} := by ext; simp [ht]
      rw [this, hsame]; simp [ht]
    · have : X t ⁻¹' {a | a = i ↔ t ∈ A} = (X t ⁻¹' {i})ᶜ := by ext; simp [ht]
      rw [this, probReal_compl_eq_one_sub (hmeas t (measurableSet_singleton _)), hsame]
      simp [ht]
  rw [hev, measureReal_biUnion_finset]
  · rw [Finset.sum_congr rfl (g := fun _ => p i ^ k * (1 - p i) ^ (n - k))]
    · rw [Finset.sum_const, Finset.card_powersetCard, Finset.card_univ, Fintype.card_fin,
        nsmul_eq_mul, mul_assoc]
    · intro A hA
      rw [Finset.mem_powersetCard] at hA
      rw [tally_prob_forall P X hindep]
      simp_rw [hpt A]
      rw [Finset.prod_ite, Finset.prod_const, Finset.prod_const]
      have hc : (Finset.univ.filter (fun t => t ∉ A)) = Aᶜ := by ext; simp
      simp [hc, Finset.card_compl, hA.2]
  · intro A _ B _ hAB
    refine Set.disjoint_left.2 fun ω h1 h2 => hAB ?_
    ext t
    simp only [Set.mem_ofPred_eq] at h1 h2
    rw [← h1 t, h2 t]
  · intro A _
    exact tally_measurableSet_forall X hmeas _

/-- Two different counts pull against each other: under the same conditions, for two different
categories `i ≠ j`, the covariance of their counts is exactly `-n p_i p_j`. -/
theorem multinomial_covariance {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n r : ℕ} (X : Fin n → Ω → Fin r) (p : Fin r → ℝ)
    (hmeas : ∀ t, Measurable (X t)) (hindep : iIndepFun X P)
    (hsame : ∀ t i, P.real (X t ⁻¹' {i}) = p i) {i j : Fin r} (hij : i ≠ j) :
    cov[fun ω => (tallyCount X i ω : ℝ), fun ω => (tallyCount X j ω : ℝ); P] =
      -(n : ℝ) * p i * p j := by
  classical
  have hms : ∀ t c, MeasurableSet (X t ⁻¹' {c}) := fun t c => hmeas t (measurableSet_singleton c)
  have hind : ∀ c, (fun ω => (tallyCount X c ω : ℝ)) =
      fun ω => ∑ t, (X t ⁻¹' {c}).indicator (1 : Ω → ℝ) ω := by
    intro c; funext ω
    simp [tallyCount, Set.indicator_apply, Finset.sum_boole]
  have hmem : ∀ c, MemLp (fun ω => (tallyCount X c ω : ℝ)) 2 P := by
    intro c
    refine MemLp.of_bound ?_ (n : ℝ) (ae_of_all _ fun ω => ?_)
    · rw [hind c]
      exact (Finset.measurable_sum _ fun t _ =>
        (measurable_const.indicator (hms t c))).aestronglyMeasurable
    · rw [Real.norm_natCast]
      exact_mod_cast (Finset.card_filter_le _ _).trans (by simp)
  have hint : ∀ t c, Integrable ((X t ⁻¹' {c}).indicator (1 : Ω → ℝ)) P :=
    fun t c => (integrable_const (1 : ℝ)).indicator (hms t c)
  have hE : ∀ c, ∫ ω, (tallyCount X c ω : ℝ) ∂P = n * p c := by
    intro c
    rw [show (∫ ω, (tallyCount X c ω : ℝ) ∂P) =
      ∫ ω, ∑ t, (X t ⁻¹' {c}).indicator (1 : Ω → ℝ) ω ∂P from by rw [← hind c]]
    rw [integral_finsetSum _ fun t _ => hint t c]
    simp_rw [integral_indicator_one (hms _ c), hsame]
    simp
  have hpair : ∀ t s, P.real (X t ⁻¹' {i} ∩ X s ⁻¹' {j}) =
      p i * p j - if t = s then p i * p j else 0 := by
    intro t s
    by_cases hts : t = s
    · subst hts
      have : X t ⁻¹' {i} ∩ X t ⁻¹' {j} = ∅ := by
        ext ω
        simp only [Set.mem_inter_iff, Set.mem_preimage, Set.mem_singleton_iff,
          Set.mem_empty_iff_false, iff_false, not_and]
        intro h1 h2
        exact hij (h1.symm.trans h2)
      simp [this]
    · rw [measureReal_def, (hindep.indepFun hts).measure_inter_preimage_eq_mul _ _
        (measurableSet_singleton i) (measurableSet_singleton j), ENNReal.toReal_mul,
        ← measureReal_def, ← measureReal_def, hsame, hsame]
      simp [hts]
  have hEprod : ∫ ω, (tallyCount X i ω : ℝ) * (tallyCount X j ω : ℝ) ∂P =
      (n : ℝ) * n * (p i * p j) - n * (p i * p j) := by
    have : (fun ω => (tallyCount X i ω : ℝ) * (tallyCount X j ω : ℝ)) =
        fun ω => ∑ t, ∑ s, (X t ⁻¹' {i} ∩ X s ⁻¹' {j}).indicator (1 : Ω → ℝ) ω := by
      funext ω
      rw [congrFun (hind i) ω, congrFun (hind j) ω, Finset.sum_mul_sum]
      refine Finset.sum_congr rfl fun t _ => Finset.sum_congr rfl fun s _ => ?_
      rw [Set.inter_indicator_one]
      rfl
    have hint2 : ∀ t s, Integrable ((X t ⁻¹' {i} ∩ X s ⁻¹' {j}).indicator (1 : Ω → ℝ)) P :=
      fun t s => (integrable_const (1 : ℝ)).indicator ((hms t i).inter (hms s j))
    rw [this, integral_finsetSum Finset.univ
      (f := fun t ω => ∑ s, (X t ⁻¹' {i} ∩ X s ⁻¹' {j}).indicator (1 : Ω → ℝ) ω)
      fun t _ => integrable_finsetSum Finset.univ fun s _ => hint2 t s]
    have hin : ∀ t, ∫ ω, ∑ s, (X t ⁻¹' {i} ∩ X s ⁻¹' {j}).indicator (1 : Ω → ℝ) ω ∂P =
        ∑ s, P.real (X t ⁻¹' {i} ∩ X s ⁻¹' {j}) := by
      intro t
      rw [integral_finsetSum Finset.univ
        (f := fun s ω => (X t ⁻¹' {i} ∩ X s ⁻¹' {j}).indicator (1 : Ω → ℝ) ω)
        fun s _ => hint2 t s]
      exact Finset.sum_congr rfl fun s _ => integral_indicator_one ((hms t i).inter (hms s j))
    simp_rw [hin, hpair]
    simp [Finset.sum_sub_distrib]
    ring
  rw [covariance_eq_sub (hmem i) (hmem j)]
  simp only [Pi.mul_apply]
  rw [hEprod, hE i, hE j]
  ring

/-! The coffee cart: 20 customers, small 3/10, medium 1/2, large 1/5. -/

-- The chances add to 1.
example : (3 / 10 : ℚ) + 1 / 2 + 1 / 5 = 1 := by norm_num

-- Orders with 6 small, 10 medium, 4 large: 20! / (6! 10! 4!) = 38,798,760.
example : Nat.multinomial Finset.univ ![6, 10, 4] = 38798760 := by decide
example : Nat.factorial 20 / (Nat.factorial 6 * Nat.factorial 10 * Nat.factorial 4) = 38798760 := by
  decide

-- The pieces of one order: 0.3^6 = 0.000729, 0.5^10 = 0.0009765625, 0.2^4 = 0.0016.
example : (3 / 10 : ℚ) ^ 6 = 729 / 1000000 := by norm_num
example : (1 / 2 : ℚ) ^ 10 = 9765625 / 10000000000 := by norm_num
example : (1 / 5 : ℚ) ^ 4 = 16 / 10000 := by norm_num

-- The tally 6, 10, 4 has chance exactly 707107401 / 16000000000 (0.044194...).
example : (38798760 : ℚ) * (3 / 10) ^ 6 * (1 / 2) ^ 10 * (1 / 5) ^ 4 = 707107401 / 16000000000 := by
  norm_num

-- There are 231 possible tallies of 20 cups into 3 sizes.
example : (Finset.Nat.antidiagonalTuple 3 20).card = 231 := by decide +kernel

-- Means 20 × 0.3, 20 × 0.5, 20 × 0.2 = 6, 10, 4.
example : (20 : ℚ) * (3 / 10) = 6 ∧ (20 : ℚ) * (1 / 2) = 10 ∧ (20 : ℚ) * (1 / 5) = 4 := by norm_num

-- Variances 4.2, 5, 3.2.
example : (20 : ℚ) * (3 / 10) * (7 / 10) = 21 / 5 ∧ (20 : ℚ) * (1 / 2) * (1 / 2) = 5 ∧
    (20 : ℚ) * (1 / 5) * (4 / 5) = 16 / 5 := by norm_num

-- Covariances: small with medium −3, small with large −1.2, medium with large −2.
example : -(20 : ℚ) * (3 / 10) * (1 / 2) = -3 ∧ -(20 : ℚ) * (3 / 10) * (1 / 5) = -6 / 5 ∧
    -(20 : ℚ) * (1 / 2) * (1 / 5) = -2 := by norm_num

-- Step 4: Var(S + M) = Var(L): 3.2 = 4.2 + 5 + 2 × (−3).
example : (21 / 5 : ℚ) + 5 + 2 * (-3) = 16 / 5 := by norm_num

-- Each row of the covariance table adds to zero: 4.2 − 3 − 1.2 = 0.
example : (21 / 5 : ℚ) - 3 - 6 / 5 = 0 := by norm_num

-- Step 5: given 4 mediums the smalls average 0.6 × 16 = 9.60; given 16 mediums, 0.6 × 4 = 2.40.
example : (3 / 10 : ℚ) / (3 / 10 + 1 / 5) = 3 / 5 := by norm_num
example : (3 / 5 : ℚ) * (20 - 4) = 48 / 5 ∧ (3 / 5 : ℚ) * (20 - 16) = 12 / 5 := by norm_num

-- Customers in 10 pairs ordering alike: C(10; 3, 5, 2) = 2520, and the tally 6, 10, 4 then has
-- chance 2520 × 0.3^3 × 0.5^5 × 0.2^2 = 0.08505; the medium variance doubles to 4 × 10 × 0.25 = 10.
example : Nat.multinomial Finset.univ ![3, 5, 2] = 2520 := by decide
example : (2520 : ℚ) * (3 / 10) ^ 3 * (1 / 2) ^ 5 * (1 / 5) ^ 2 = 1701 / 20000 := by norm_num
example : (4 : ℚ) * (10 * (1 / 2) * (1 / 2)) = 10 := by norm_num

#print axioms multinomial_joint_mass
#print axioms multinomial_count_binomial
#print axioms multinomial_covariance
