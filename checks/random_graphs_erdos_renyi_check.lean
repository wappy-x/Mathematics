-- Random graphs: in the random graph G(n, p), one person's friend count is binomial with average (n − 1)p, the edge count is binomial with average p times the number of pairs, and the friend-count law is within (n − 1)p(1 − e^(−p)) ≤ (n − 1)p² of the Poisson law.
import Mathlib.Probability.Combinatorics.BinomialRandomGraph.Defs
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Tactic.NormNum
import Mathlib.Probability.Distributions.Binomial
import Mathlib.Data.Sym.NatCard

open MeasureTheory ProbabilityTheory unitInterval
open scoped Classical

lemma rg_bin_conv (p : ℝ) (m k : ℕ) :
    ((m + 1).choose k : ℝ) * p ^ k * (1 - p) ^ (m + 1 - k)
      = ∑ i ∈ Finset.range (k + 1), ((m.choose i : ℝ) * p ^ i * (1 - p) ^ (m - i))
          * ((Nat.choose 1 (k - i) : ℝ) * p ^ (k - i) * (1 - p) ^ (1 - (k - i))) := by
  cases k with
  | zero => simp [pow_succ]
  | succ j =>
    rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_eq_zero]
    · simp only [Nat.add_sub_cancel_left, Nat.sub_self, Nat.choose_self, Nat.choose_zero_right,
        Nat.cast_one, pow_one, pow_zero, Nat.sub_zero, one_mul, mul_one, zero_add,
        Nat.add_sub_add_right, Nat.choose_succ_succ, Nat.cast_add]
      rcases Nat.lt_or_ge m (j + 1) with h | h
      · rw [Nat.choose_eq_zero_of_lt h]
        simp only [Nat.cast_zero, zero_mul, add_zero]
        ring
      · obtain ⟨r, rfl⟩ := Nat.exists_eq_add_of_le h
        have e1 : j + 1 + r - j = r + 1 := by omega
        have e2 : j + 1 + r - (j + 1) = r := by omega
        rw [e1, e2]
        ring
    · intro i hi
      rw [Finset.mem_range] at hi
      rw [Nat.choose_eq_zero_of_lt (n := 1) (k := j + 1 - i) (by omega)]
      simp

lemma rg_poi_conv (a b : ℝ) (k : ℕ) :
    Real.exp (-(a + b)) * (a + b) ^ k / (k.factorial : ℝ)
      = ∑ i ∈ Finset.range (k + 1), (Real.exp (-a) * a ^ i / (i.factorial : ℝ))
          * (Real.exp (-b) * b ^ (k - i) / ((k - i).factorial : ℝ)) := by
  rw [add_pow, Finset.mul_sum, Finset.sum_div]
  refine Finset.sum_congr rfl fun i hi => ?_
  have hik : i ≤ k := Nat.lt_succ_iff.mp (Finset.mem_range.mp hi)
  have h := Nat.choose_mul_factorial_mul_factorial hik
  have h' : (k.factorial : ℝ) = (k.choose i : ℝ) * (i.factorial : ℝ) * ((k - i).factorial : ℝ) := by
    exact_mod_cast h.symm
  have hc : (k.choose i : ℝ) ≠ 0 := by exact_mod_cast (Nat.choose_pos hik).ne'
  rw [h', neg_add, Real.exp_add]
  field_simp

lemma rg_bin_prefix (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (m K : ℕ) :
    ∑ k ∈ Finset.range K, (m.choose k : ℝ) * p ^ k * (1 - p) ^ (m - k) ≤ 1 := by
  have hnn : ∀ k, 0 ≤ (m.choose k : ℝ) * p ^ k * (1 - p) ^ (m - k) := fun k => by
    have : 0 ≤ 1 - p := by linarith
    positivity
  calc ∑ k ∈ Finset.range K, (m.choose k : ℝ) * p ^ k * (1 - p) ^ (m - k)
      ≤ ∑ k ∈ Finset.range (m + 1 + K), (m.choose k : ℝ) * p ^ k * (1 - p) ^ (m - k) :=
        Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_mono (by omega))
          (fun k _ _ => hnn k)
    _ = ∑ k ∈ Finset.range (m + 1), (m.choose k : ℝ) * p ^ k * (1 - p) ^ (m - k) := by
        rw [Finset.sum_range_add, add_eq_left]
        refine Finset.sum_eq_zero fun x _ => ?_
        rw [Nat.choose_eq_zero_of_lt (by omega)]
        simp
    _ = (p + (1 - p)) ^ m := by
        rw [add_pow]
        refine Finset.sum_congr rfl fun k _ => by ring
    _ = 1 := by simp

lemma rg_poi_prefix (a : ℝ) (ha : 0 ≤ a) (K : ℕ) :
    ∑ k ∈ Finset.range K, Real.exp (-a) * a ^ k / (k.factorial : ℝ) ≤ 1 := by
  have h : ∑ k ∈ Finset.range K, Real.exp (-a) * a ^ k / (k.factorial : ℝ)
      = Real.exp (-a) * ∑ k ∈ Finset.range K, a ^ k / (k.factorial : ℝ) := by
    rw [Finset.mul_sum]
    exact Finset.sum_congr rfl fun k _ => by ring
  rw [h]
  calc Real.exp (-a) * ∑ k ∈ Finset.range K, a ^ k / (k.factorial : ℝ)
      ≤ Real.exp (-a) * Real.exp a :=
        mul_le_mul_of_nonneg_left (Real.sum_le_exp_of_nonneg ha K) (Real.exp_pos _).le
    _ = 1 := by rw [← Real.exp_add]; simp

lemma rg_conv_bound (f g : ℕ → ℝ) (hf : ∀ i, 0 ≤ f i) (hg : ∀ j, 0 ≤ g j) (K : ℕ) :
    ∑ k ∈ Finset.range K, ∑ i ∈ Finset.range (k + 1), f i * g (k - i)
      ≤ (∑ i ∈ Finset.range K, f i) * (∑ j ∈ Finset.range K, g j) := by
  rw [Finset.sum_range_diag_flip K (fun i j => f i * g j), Finset.sum_mul]
  refine Finset.sum_le_sum fun i _ => ?_
  rw [Finset.mul_sum]
  exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_mono (Nat.sub_le _ _))
    (fun j _ _ => mul_nonneg (hf i) (hg j))

lemma rg_base (p : ℝ) (hp0 : 0 ≤ p) (_hp1 : p ≤ 1) (K : ℕ) :
    ∑ k ∈ Finset.range K, |(Nat.choose 1 k : ℝ) * p ^ k * (1 - p) ^ (1 - k)
        - Real.exp (-p) * p ^ k / (k.factorial : ℝ)|
      ≤ 2 * (p * (1 - Real.exp (-p))) := by
  set F : ℕ → ℝ := fun k => |(Nat.choose 1 k : ℝ) * p ^ k * (1 - p) ^ (1 - k)
        - Real.exp (-p) * p ^ k / (k.factorial : ℝ)| with hF
  set P : ℕ → ℝ := fun k => Real.exp (-p) * p ^ k / (k.factorial : ℝ) with hP
  have hle : ∑ k ∈ Finset.range K, F k ≤ ∑ k ∈ Finset.range (K + 2), F k :=
    Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_mono (by omega))
      (fun k _ _ => abs_nonneg _)
  refine hle.trans ?_
  have hpre := rg_poi_prefix p hp0 (K + 2)
  rw [Finset.sum_range_succ', Finset.sum_range_succ'] at hpre ⊢
  have hF2 : ∀ k, F (k + 1 + 1) = P (k + 1 + 1) := by
    intro k
    simp only [hF, hP]
    rw [Nat.choose_eq_zero_of_lt (by omega)]
    have : 0 ≤ Real.exp (-p) * p ^ (k + 1 + 1) / ((k + 1 + 1).factorial : ℝ) := by positivity
    simp only [Nat.cast_zero, zero_mul, zero_sub, abs_neg]
    exact abs_of_nonneg this
  simp_rw [hF2]
  have hF1 : F (0 + 1) = p - p * Real.exp (-p) := by
    simp only [hF]
    have h1 : Real.exp (-p) ≤ 1 := Real.exp_le_one_iff.mpr (by linarith)
    rw [abs_of_nonneg] <;> simp <;> nlinarith
  have hF0 : F 0 = Real.exp (-p) - (1 - p) := by
    simp only [hF]
    have h1 : -p + 1 ≤ Real.exp (-p) := Real.add_one_le_exp _
    rw [abs_of_nonpos] <;> simp <;> linarith
  have hP0 : P 0 = Real.exp (-p) := by simp [hP]
  have hP1 : P (0 + 1) = p * Real.exp (-p) := by simp [hP]; ring
  rw [hF1, hF0]
  have e1 : Real.exp (-p) * p ^ (0 + 1) / ((0 + 1).factorial : ℝ) = p * Real.exp (-p) := by
    simp; ring
  have e0 : Real.exp (-p) * p ^ 0 / ((Nat.factorial 0 : ℕ) : ℝ) = Real.exp (-p) := by simp
  rw [e1, e0] at hpre
  change ∑ x ∈ Finset.range K, P (x + 1 + 1) + _ + _ ≤ 1 at hpre
  linarith

lemma rg_setBer_map_inter {ι : Type*} (u w : Set ι) (p : I) :
    (setBernoulli u p).map (fun s => s ∩ w) = setBernoulli (u ∩ w) p := by
  rw [setBernoulli_eq_map, setBernoulli_eq_map, Measure.map_map (by fun_prop) (by fun_prop)]
  have h : ((fun s : Set ι => s ∩ w) ∘ fun P : ι → Prop => {i | P i})
      = (fun P : ι → Prop => {i | P i}) ∘ (fun P i => P i ∧ i ∈ w) := by
    funext P; ext i; simp
  have hm := Measure.infinitePi_map_pi (fun i : ι => Ber(i ∈ u, False, p))
    (f := fun i (q : Prop) => q ∧ i ∈ w) (fun i => Measurable.of_discrete)
  beta_reduce at hm
  rw [h, ← Measure.map_map (by fun_prop) (by fun_prop), hm]
  congr 2
  funext i
  rw [map_bernoulliMeasure' _ _ Measurable.of_discrete]
  simp [Set.mem_inter_iff]

lemma rg_law_inter {V : Type*} [Finite V] (p : I) (w : Set (Sym2 V)) (k : ℕ) :
    (SimpleGraph.binomialRandom V p).real {G | (G.edgeSet ∩ w).ncard = k}
      = ((Sym2.diagSetᶜ ∩ w).ncard.choose k : ℝ) * (p : ℝ) ^ k
        * (1 - (p : ℝ)) ^ ((Sym2.diagSetᶜ ∩ w).ncard - k) := by
  have hfin : (Sym2.diagSetᶜ ∩ w : Set (Sym2 V)).Finite := Set.toFinite _
  rw [← map_ncard_setBernoulli_real_singleton hfin, ← rg_setBer_map_inter,
    Measure.map_map (by fun_prop) (by fun_prop)]
  rw [measureReal_def, measureReal_def, SimpleGraph.binomialRandom,
    SimpleGraph.measurableEmbedding_edgeSet.comap_apply,
    Measure.map_apply (by fun_prop) (MeasurableSet.of_discrete),
    setBernoulli_apply_eq_apply_subsets, setBernoulli_apply_eq_apply_subsets (S := _ ⁻¹' _)]
  congr 2
  ext s
  simp only [Set.mem_image, Set.mem_ofPred_eq, Set.mem_preimage, Function.comp_apply,
    Set.mem_singleton_iff]
  constructor
  · rintro ⟨⟨G, hG, rfl⟩, -⟩
    exact ⟨hG, SimpleGraph.edgeSet_subset_compl_diagSet G⟩
  · rintro ⟨hs, hsu⟩
    refine ⟨⟨SimpleGraph.fromEdgeSet s, ?_, ?_⟩, hsu⟩
    all_goals rw [SimpleGraph.edgeSet_fromEdgeSet,
      sdiff_eq_left.mpr (Set.subset_compl_iff_disjoint_right.mp hsu)]
    exact hs

lemma rg_meas {V : Type*} [Finite V] (w : Set (Sym2 V)) :
    Measurable (fun G : SimpleGraph V => (G.edgeSet ∩ w).ncard) := by
  have : Measurable (fun s : Set (Sym2 V) => s ∩ w) := by fun_prop
  exact measurable_ncard.comp (this.comp SimpleGraph.measurable_edgeSet)

lemma rg_map_eq {V : Type*} [Finite V] (p : I) (w : Set (Sym2 V)) :
    (SimpleGraph.binomialRandom V p).map (fun G => (G.edgeSet ∩ w).ncard)
      = binomial (Sym2.diagSetᶜ ∩ w).ncard p := by
  refine Measure.ext_of_measureReal_singleton fun k => ?_
  rw [map_measureReal_apply (rg_meas w) (.of_discrete), binomial_real_singleton]
  exact rg_law_inter p w k

lemma rg_integral {V : Type*} [Finite V] (p : I) (w : Set (Sym2 V)) :
    ∫ G, ((G.edgeSet ∩ w).ncard : ℝ) ∂(SimpleGraph.binomialRandom V p)
      = ((Sym2.diagSetᶜ ∩ w).ncard : ℝ) * p := by
  have h : HasLaw (fun G : SimpleGraph V => ((G.edgeSet ∩ w).ncard : ℝ))
      ((binomial (Sym2.diagSetᶜ ∩ w).ncard p).map (Nat.cast : ℕ → ℝ))
      (SimpleGraph.binomialRandom V p) :=
    ⟨(measurable_from_nat.comp (rg_meas w)).aemeasurable, by
      rw [← rg_map_eq, Measure.map_map measurable_from_nat (rg_meas w)]; rfl⟩
  rw [integral_of_hasLaw_binomial h, mul_comm]

lemma rg_card_top {n : ℕ} :
    (Sym2.diagSetᶜ ∩ (Set.univ : Set (Sym2 (Fin n)))).ncard = n.choose 2 := by
  rw [Set.inter_univ, Sym2.ncard_diagSet_compl, Nat.card_eq_fintype_card, Fintype.card_fin]

lemma rg_card_star {n : ℕ} (v : Fin n) :
    (Sym2.diagSetᶜ ∩ {e : Sym2 (Fin n) | v ∈ e}).ncard = n - 1 := by
  have : (Sym2.diagSetᶜ ∩ {e : Sym2 (Fin n) | v ∈ e}) = (fun x => s(v, x)) '' {x | x ≠ v} := by
    ext e
    induction e using Sym2.ind with
    | _ a b =>
      simp only [Set.mem_inter_iff, Set.mem_compl_iff, Sym2.mem_diagSet, Sym2.mk_isDiag_iff,
        Set.mem_ofPred_eq, Sym2.mem_iff, Set.mem_image, Sym2.eq_iff]
      constructor
      · rintro ⟨hab, rfl | rfl⟩
        · exact ⟨b, fun h => hab h.symm, Or.inl ⟨rfl, rfl⟩⟩
        · exact ⟨a, hab, Or.inr ⟨rfl, rfl⟩⟩
      · rintro ⟨x, hx, (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩)⟩
        · exact ⟨fun h => hx h.symm, Or.inl rfl⟩
        · exact ⟨hx, Or.inr rfl⟩
  rw [this, Set.ncard_image_of_injective _ (fun x y h => Sym2.congr_right.mp h)]
  have h2 : {x : Fin n | x ≠ v} = {v}ᶜ := rfl
  rw [h2, Set.ncard_eq_toFinset_card']
  simp [Finset.card_compl]

lemma rg_degree_eq {n : ℕ} (G : SimpleGraph (Fin n)) (v : Fin n) :
    G.degree v = (G.edgeSet ∩ {e | v ∈ e}).ncard := by
  rw [← SimpleGraph.card_incidenceSet_eq_degree, ← Nat.card_eq_fintype_card, Nat.card_coe_set_eq]
  rfl

lemma rg_abs_mul_sub (x x' y y' : ℝ) (hy : 0 ≤ y) (hx' : 0 ≤ x') :
    |x * y - x' * y'| ≤ |x - x'| * y + x' * |y - y'| := by
  have h : x * y - x' * y' = (x - x') * y + x' * (y - y') := by ring
  rw [h]
  refine (abs_add_le _ _).trans ?_
  rw [abs_mul, abs_mul, abs_of_nonneg hy, abs_of_nonneg hx']

lemma rg_main (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (m : ℕ) (K : ℕ) :
    ∑ k ∈ Finset.range K, |(m.choose k : ℝ) * p ^ k * (1 - p) ^ (m - k)
        - Real.exp (-((m : ℝ) * p)) * ((m : ℝ) * p) ^ k / (k.factorial : ℝ)|
      ≤ 2 * ((m : ℝ) * (p * (1 - Real.exp (-p)))) := by
  induction m generalizing K with
  | zero =>
    rw [Finset.sum_eq_zero]
    · simp
    · intro k _
      cases k <;> simp
  | succ m ih =>
    set B : ℕ → ℝ := fun k => (m.choose k : ℝ) * p ^ k * (1 - p) ^ (m - k) with hB
    set Q : ℕ → ℝ := fun k => Real.exp (-((m : ℝ) * p)) * ((m : ℝ) * p) ^ k / (k.factorial : ℝ)
      with hQ
    set b : ℕ → ℝ := fun k => (Nat.choose 1 k : ℝ) * p ^ k * (1 - p) ^ (1 - k) with hb
    set q : ℕ → ℝ := fun k => Real.exp (-p) * p ^ k / (k.factorial : ℝ) with hq
    have hBn : ∀ k, 0 ≤ B k := fun k => by
      have : 0 ≤ 1 - p := by linarith
      simp only [hB]; positivity
    have hbn : ∀ k, 0 ≤ b k := fun k => by
      have : 0 ≤ 1 - p := by linarith
      simp only [hb]; positivity
    have hQn : ∀ k, 0 ≤ Q k := fun k => by
      simp only [hQ]; positivity
    have hmp : (0 : ℝ) ≤ (m : ℝ) * p := by positivity
    have hstep : ∀ k, |((m + 1).choose k : ℝ) * p ^ k * (1 - p) ^ (m + 1 - k)
        - Real.exp (-(((m + 1 : ℕ) : ℝ) * p)) * (((m + 1 : ℕ) : ℝ) * p) ^ k / (k.factorial : ℝ)|
        ≤ ∑ i ∈ Finset.range (k + 1), (|B i - Q i| * b (k - i) + Q i * |b (k - i) - q (k - i)|) := by
      intro k
      have e : ((m + 1 : ℕ) : ℝ) * p = (m : ℝ) * p + p := by push_cast; ring
      rw [e, rg_poi_conv, rg_bin_conv, ← Finset.sum_sub_distrib]
      refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun i _ => ?_)
      exact rg_abs_mul_sub _ _ _ _ (hbn _) (hQn _)
    have hS := ih K
    have hT := rg_base p hp0 hp1 K
    have hbsum := rg_bin_prefix p hp0 hp1 1 K
    have hQsum := rg_poi_prefix ((m : ℝ) * p) hmp K
    have c1 := rg_conv_bound (fun i => |B i - Q i|) b (fun _ => abs_nonneg _) hbn K
    have c2 := rg_conv_bound Q (fun j => |b j - q j|) hQn (fun _ => abs_nonneg _) K
    change ∑ k ∈ Finset.range K, |B k - Q k| ≤ _ at hS
    change ∑ k ∈ Finset.range K, |b k - q k| ≤ _ at hT
    change ∑ k ∈ Finset.range K, b k ≤ 1 at hbsum
    change ∑ k ∈ Finset.range K, Q k ≤ 1 at hQsum
    have hS0 : 0 ≤ ∑ k ∈ Finset.range K, |B k - Q k| :=
      Finset.sum_nonneg fun _ _ => abs_nonneg _
    have hT0 : 0 ≤ ∑ k ∈ Finset.range K, |b k - q k| :=
      Finset.sum_nonneg fun _ _ => abs_nonneg _
    calc _ ≤ ∑ k ∈ Finset.range K, ∑ i ∈ Finset.range (k + 1),
            (|B i - Q i| * b (k - i) + Q i * |b (k - i) - q (k - i)|) :=
          Finset.sum_le_sum fun k _ => hstep k
      _ = ∑ k ∈ Finset.range K, ∑ i ∈ Finset.range (k + 1), |B i - Q i| * b (k - i)
          + ∑ k ∈ Finset.range K, ∑ i ∈ Finset.range (k + 1), Q i * |b (k - i) - q (k - i)| := by
          rw [← Finset.sum_add_distrib]
          exact Finset.sum_congr rfl fun k _ => Finset.sum_add_distrib
      _ ≤ (∑ k ∈ Finset.range K, |B k - Q k|) * (∑ k ∈ Finset.range K, b k)
          + (∑ k ∈ Finset.range K, Q k) * (∑ k ∈ Finset.range K, |b k - q k|) :=
          add_le_add c1 c2
      _ ≤ (∑ k ∈ Finset.range K, |B k - Q k|) * 1 + 1 * (∑ k ∈ Finset.range K, |b k - q k|) := by
          gcongr
      _ ≤ 2 * (((m + 1 : ℕ) : ℝ) * (p * (1 - Real.exp (-p)))) := by
          push_cast; linarith

/-- The degree law. In the random graph G(n, p) (n people, every pair of people made friends by
its own coin with the same chance p, all coins independent), pick any one person v. The chance
that v has exactly k friends is C(n − 1, k) p^k (1 − p)^(n − 1 − k): the binomial law with one
trial for each of the other n − 1 people. Its average is λ = (n − 1)p. -/
theorem degree_is_binomial (n : ℕ) (p : I) (v : Fin n) :
    (∀ k : ℕ, (SimpleGraph.binomialRandom (Fin n) p).real {G | G.degree v = k}
        = ((n - 1).choose k : ℝ) * (p : ℝ) ^ k * (1 - (p : ℝ)) ^ (n - 1 - k)) ∧
    ∫ G, (G.degree v : ℝ) ∂(SimpleGraph.binomialRandom (Fin n) p) = ((n - 1 : ℕ) : ℝ) * p := by
  constructor
  · intro k
    simp_rw [rg_degree_eq]
    rw [rg_law_inter, rg_card_star]
  · simp_rw [rg_degree_eq]
    rw [rg_integral, rg_card_star]

/-- The edge-count law. In G(n, p) the number of friendships M is a sum of one yes-or-no per
pair, so it is binomial with C(n, 2) trials: the chance of exactly m friendships is
C(C(n, 2), m) p^m (1 − p)^(C(n, 2) − m), and the average is C(n, 2) p. -/
theorem edge_count_is_binomial (n : ℕ) (p : I) :
    (∀ m : ℕ, (SimpleGraph.binomialRandom (Fin n) p).real {G | G.edgeSet.ncard = m}
        = ((n.choose 2).choose m : ℝ) * (p : ℝ) ^ m * (1 - (p : ℝ)) ^ (n.choose 2 - m)) ∧
    ∫ G, (G.edgeSet.ncard : ℝ) ∂(SimpleGraph.binomialRandom (Fin n) p)
      = (n.choose 2 : ℝ) * p := by
  constructor
  · intro m
    have h := rg_law_inter p (Set.univ : Set (Sym2 (Fin n))) m
    rw [rg_card_top] at h
    simpa only [Set.inter_univ] using h
  · have h := rg_integral p (Set.univ : Set (Sym2 (Fin n)))
    rw [rg_card_top] at h
    simpa only [Set.inter_univ] using h

/-- The Poisson form, with its error. In G(n, p) let λ = (n − 1)p. The gap Δ between one
person's friend-count law and the Poisson law with average λ (half the summed differences of
their chances, P(D = k) against e^(−λ) λ^k / k!) is at most (n − 1) p (1 − e^(−p)), and that is
at most (n − 1) p². The gap is stated for the first K counts, for every K, so it bounds the
full infinite sum. -/
theorem degree_near_poisson (n : ℕ) (p : I) (v : Fin n) (K : ℕ) :
    (1 / 2 : ℝ) * ∑ k ∈ Finset.range K,
        |(SimpleGraph.binomialRandom (Fin n) p).real {G | G.degree v = k}
          - Real.exp (-(((n - 1 : ℕ) : ℝ) * p)) * (((n - 1 : ℕ) : ℝ) * p) ^ k / (k.factorial : ℝ)|
      ≤ ((n - 1 : ℕ) : ℝ) * p * (1 - Real.exp (-(p : ℝ))) ∧
    ((n - 1 : ℕ) : ℝ) * p * (1 - Real.exp (-(p : ℝ))) ≤ ((n - 1 : ℕ) : ℝ) * (p : ℝ) ^ 2 := by
  have hp0 : (0 : ℝ) ≤ p := p.2.1
  have hp1 : (p : ℝ) ≤ 1 := p.2.2
  constructor
  · have h := rg_main p hp0 hp1 (n - 1) K
    rw [Finset.sum_congr rfl fun k _ => by rw [(degree_is_binomial n p v).1 k]]
    linarith
  · have h1 : -(p : ℝ) + 1 ≤ Real.exp (-(p : ℝ)) := Real.add_one_le_exp _
    have hn : (0 : ℝ) ≤ ((n - 1 : ℕ) : ℝ) * p := by positivity
    have : ((n - 1 : ℕ) : ℝ) * p * (1 - Real.exp (-(p : ℝ))) ≤ ((n - 1 : ℕ) : ℝ) * p * p :=
      mul_le_mul_of_nonneg_left (by linarith) hn
    linarith [show ((n - 1 : ℕ) : ℝ) * (p : ℝ) ^ 2 = ((n - 1 : ℕ) : ℝ) * p * p by ring]

-- The town: 1,000 people make C(1000, 2) = 1000 × 999 / 2 = 499,500 pairs, one coin each.
example : Nat.choose 1000 2 = 499500 := by rw [Nat.choose_two_right]
example : 1000 * 999 / 2 = 499500 := by norm_num
-- Groups of three: C(1000, 3) = 166,167,000.
example : Nat.choose 1000 3 = 166167000 := by
  rw [Nat.choose_eq_descFactorial_div_factorial]; norm_num [Nat.descFactorial, Nat.factorial]
-- Expected friendships 499,500 × 3/1000 = 1,498.5; expected friends each 999 × 3/1000 = 2.997.
example : (499500 : ℚ) * (3 / 1000) = 2997 / 2 := by norm_num
example : (999 : ℚ) * (3 / 1000) = 2997 / 1000 := by norm_num
-- Same average by handshakes: 2 × 1,498.5 / 1,000 = 2.997.
example : 2 * ((2997 : ℚ) / 2) / 1000 = 2997 / 1000 := by norm_num
-- Variance of one person's friend count: 999 × 0.003 × 0.997 = 2.988009.
example : (999 : ℚ) * (3 / 1000) * (1 - 3 / 1000) = 2988009 / 1000000 := by norm_num
-- Expected triangles: 166,167,000 × 0.003^3 = 4.486509.
example : (166167000 : ℚ) * (3 / 1000) ^ 3 = 4486509 / 1000000 := by norm_num
-- The cruder Poisson bound: (n − 1)p² = 999 × 0.003² = 0.008991.
example : (999 : ℚ) * (3 / 1000) ^ 2 = 8991 / 1000000 := by norm_num
-- A 4-person town at p = 0.3: 6 pairs, 2^6 = 64 outcomes, 6 × 0.3 = 1.8 expected friendships.
example : Nat.choose 4 2 = 6 ∧ 2 ^ 6 = 64 := by decide
example : (Nat.choose 4 2 : ℚ) * (3 / 10) = 9 / 5 := by norm_num [Nat.choose]
-- Person 1's friend count there is Binomial(3, 0.3): 0.343, 0.441, 0.189, 0.027.
example : (List.range 4).map (fun k => (Nat.choose 3 k : ℚ) * (3 / 10) ^ k * (7 / 10) ^ (3 - k))
    = [343 / 1000, 441 / 1000, 189 / 1000, 27 / 1000] := by
  simp [List.range_succ, Nat.choose]; norm_num
-- Mistakes: n² p = 1,000,000 × 0.003 = 3,000; n times the average degree = 1,000 × 2.997 = 2,997.
example : (1000 : ℚ) ^ 2 * (3 / 1000) = 3000 := by norm_num
example : (1000 : ℚ) * (2997 / 1000) = 2997 := by norm_num
-- One shared coin for the 4-person town: still 0.3 × 6 = 1.8 friendships on average, but person 1
-- is friendless with chance 0.7, not 0.7^3 = 0.343.
example : (3 / 10 : ℚ) * 6 = 9 / 5 ∧ (7 / 10 : ℚ) ^ 3 = 343 / 1000 := by norm_num

#print axioms degree_is_binomial
#print axioms edge_count_is_binomial
#print axioms degree_near_poisson
#print axioms rg_bin_conv
#print axioms rg_poi_conv
#print axioms rg_bin_prefix
#print axioms rg_poi_prefix
#print axioms rg_conv_bound
#print axioms rg_base
#print axioms rg_setBer_map_inter
#print axioms rg_law_inter
#print axioms rg_meas
#print axioms rg_map_eq
#print axioms rg_integral
#print axioms rg_card_top
#print axioms rg_card_star
#print axioms rg_degree_eq
#print axioms rg_abs_mul_sub
#print axioms rg_main
