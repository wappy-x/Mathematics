-- First and second moments: a random count reaches 1 with chance at most its mean, falls to 0 with chance at most its variance over its squared mean, and the triangle count of a random graph has mean C(n,3)p³ and variance C(n,3)(p³ − p⁶) + C(n,3)·3(n − 3)(p⁵ − p⁶).
import Mathlib.Probability.Moments.Variance
import Mathlib.Combinatorics.SimpleGraph.Clique

open MeasureTheory ProbabilityTheory
open scoped ENNReal

open Finset in
theorem fsm_mem_pairEdges {α : Type*} [DecidableEq α] (t : Finset α) (x y : α) :
    s(x, y) ∈ t.offDiag.image Sym2.mk.uncurry ↔ x ∈ t ∧ y ∈ t ∧ x ≠ y := by
  constructor
  · intro h
    obtain ⟨⟨a, b⟩, hab, he⟩ := mem_image.1 h
    rw [mem_offDiag] at hab
    change s(a, b) = s(x, y) at he
    rcases Sym2.eq_iff.1 he with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact hab
    · exact ⟨hab.2.1, hab.1, fun h => hab.2.2 h.symm⟩
  · rintro ⟨hx, hy, hxy⟩
    exact mem_image.2 ⟨(x, y), mem_offDiag.2 ⟨hx, hy, hxy⟩, rfl⟩

open Finset in
theorem fsm_pairEdges_inter {α : Type*} [DecidableEq α] (t u : Finset α) :
    t.offDiag.image Sym2.mk.uncurry ∩ u.offDiag.image Sym2.mk.uncurry =
      (t ∩ u).offDiag.image Sym2.mk.uncurry := by
  ext e
  induction e using Sym2.ind with
  | _ x y =>
    rw [mem_inter, fsm_mem_pairEdges, fsm_mem_pairEdges, fsm_mem_pairEdges, mem_inter, mem_inter]
    tauto

open Finset in
theorem fsm_pairEdges_subset_iff {V : Type*} [DecidableEq V] (G : SimpleGraph V)
    [Fintype G.edgeSet] (t : Finset V) :
    t.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset ↔
      ∀ x ∈ t, ∀ y ∈ t, x ≠ y → G.Adj x y := by
  constructor
  · intro h x hx y hy hxy
    have := h ((fsm_mem_pairEdges t x y).2 ⟨hx, hy, hxy⟩)
    simpa using this
  · intro h e he
    induction e using Sym2.ind with
    | _ x y =>
      rw [fsm_mem_pairEdges] at he
      simpa using h x he.1 y he.2.1 he.2.2

open Finset in
theorem fsm_powerset_sum {α : Type*} [DecidableEq α] (U S : Finset α) (hS : S ⊆ U) (p : ℝ) :
    ∑ A ∈ U.powerset, p ^ A.card * (1 - p) ^ (U.card - A.card) *
      (if S ⊆ A then (1 : ℝ) else 0) = p ^ S.card := by
  have key := Finset.prod_add (fun _ => p) (fun e => (1 - p) * if e ∈ S then (0 : ℝ) else 1) U
  have lhs : ∏ i ∈ U, (p + (1 - p) * if i ∈ S then (0 : ℝ) else 1) = p ^ S.card := by
    calc ∏ i ∈ U, (p + (1 - p) * if i ∈ S then (0 : ℝ) else 1)
        = ∏ i ∈ U, (if i ∈ S then p else 1) :=
          prod_congr rfl (fun i _ => by split_ifs <;> ring)
      _ = ∏ i ∈ U ∩ S, p := prod_ite_mem U S _
      _ = p ^ S.card := by rw [inter_eq_right.mpr hS, prod_const]
  rw [lhs] at key
  rw [key]
  refine sum_congr rfl (fun A hA => ?_)
  rw [mem_powerset] at hA
  have hind : ∏ i ∈ U \ A, (if i ∈ S then (0 : ℝ) else 1) = if S ⊆ A then 1 else 0 := by
    by_cases h : S ⊆ A
    · rw [if_pos h]
      refine prod_eq_one (fun i hi => ?_)
      rw [if_neg]
      exact fun hiS => (mem_sdiff.1 hi).2 (h hiS)
    · rw [if_neg h]
      obtain ⟨i, hiS, hiA⟩ := not_subset.1 h
      exact prod_eq_zero (i := i) (mem_sdiff.2 ⟨hS hiS, hiA⟩) (by simp [hiS])
  rw [prod_const, prod_mul_distrib, prod_const, card_sdiff_of_subset hA, hind]
  ring

open Finset in
open scoped Classical in
theorem fsm_graph_sum (n : ℕ) (F : Finset (Sym2 (Fin n)) → ℝ) :
    ∑ G : SimpleGraph (Fin n), F G.edgeFinset =
      ∑ A ∈ ((univ : Finset (Fin n)).offDiag.image Sym2.mk.uncurry).powerset, F A := by
  refine Finset.sum_nbij' (fun G : SimpleGraph (Fin n) => G.edgeFinset)
    (fun A => SimpleGraph.fromEdgeSet (A : Set (Sym2 (Fin n)))) ?_ ?_ ?_ ?_ ?_
  · intro G _
    simp only [mem_powerset]
    intro e he
    induction e using Sym2.ind with
    | _ x y =>
      rw [fsm_mem_pairEdges]
      exact ⟨mem_univ _, mem_univ _, G.ne_of_adj (by simpa using he)⟩
  · intro A _
    simp
  · intro G _
    simp only [SimpleGraph.coe_edgeFinset, SimpleGraph.fromEdgeSet_edgeSet]
  · intro A hA
    simp only [mem_powerset] at hA
    ext e
    simp only [SimpleGraph.mem_edgeFinset, SimpleGraph.edgeSet_fromEdgeSet]
    induction e using Sym2.ind with
    | _ x y =>
      constructor
      · rintro ⟨h, _⟩
        exact h
      · intro h
        refine ⟨h, ?_⟩
        have := (fsm_mem_pairEdges _ x y).1 (hA h)
        simpa using this.2.2
  · intro G _
    rfl

open Finset in
open scoped Classical in
theorem fsm_graph_prob (n : ℕ) (p : ℝ) (S : Finset (Sym2 (Fin n)))
    (hS : S ⊆ (univ : Finset (Fin n)).offDiag.image Sym2.mk.uncurry) :
    ∑ G : SimpleGraph (Fin n), p ^ G.edgeFinset.card * (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
      (if S ⊆ G.edgeFinset then (1 : ℝ) else 0) = p ^ S.card := by
  have h := fsm_graph_sum n
    (fun A => p ^ A.card * (1 - p) ^ (n.choose 2 - A.card) * (if S ⊆ A then (1 : ℝ) else 0))
  rw [h]
  have hU : ((univ : Finset (Fin n)).offDiag.image Sym2.mk.uncurry).card = n.choose 2 := by
    rw [Sym2.card_image_offDiag, card_univ, Fintype.card_fin]
  rw [← hU]
  exact fsm_powerset_sum _ S hS p

open Finset in
open scoped Classical in
theorem fsm_clique_card (n : ℕ) (G : SimpleGraph (Fin n)) :
    ((G.cliqueFinset 3).card : ℝ) =
      ∑ t ∈ (univ : Finset (Fin n)).powersetCard 3,
        (if t.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset then (1 : ℝ) else 0) := by
  have h : G.cliqueFinset 3 = ((univ : Finset (Fin n)).powersetCard 3).filter
      (fun t => t.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset) := by
    ext t
    rw [SimpleGraph.mem_cliqueFinset_iff, mem_filter, mem_powersetCard, fsm_pairEdges_subset_iff,
      SimpleGraph.isNClique_iff, SimpleGraph.IsClique, Set.Pairwise]
    simp only [mem_coe, subset_univ, true_and]
    tauto
  rw [h, card_filter]
  push_cast
  rfl

open Finset in
theorem fsm_count_share_two (n : ℕ) (t : Finset (Fin n)) (ht : t.card = 3) :
    (((univ : Finset (Fin n)).powersetCard 3).filter (fun u => (t ∩ u).card = 2)).card =
      3 * (n - 3) := by
  have hprod : ((t.powersetCard 2) ×ˢ tᶜ).card = 3 * (n - 3) := by
    rw [card_product, card_powersetCard, card_compl, ht, Fintype.card_fin]
    rfl
  rw [← hprod]
  symm
  refine card_bij (fun q _ => insert q.2 q.1) ?_ ?_ ?_
  · rintro ⟨u, x⟩ hq
    rw [mem_product, mem_powersetCard, mem_compl] at hq
    obtain ⟨⟨hut, hu2⟩, hx⟩ := hq
    have hxu : x ∉ u := fun h => hx (hut h)
    have hinter : t ∩ insert x u = u := by
      ext y
      simp only [mem_inter, mem_insert]
      constructor
      · rintro ⟨hyt, rfl | hyu⟩
        · exact absurd hyt hx
        · exact hyu
      · intro hyu
        exact ⟨hut hyu, Or.inr hyu⟩
    rw [mem_filter, mem_powersetCard, card_insert_of_notMem hxu, hu2, hinter, hu2]
    exact ⟨⟨subset_univ _, rfl⟩, rfl⟩
  · rintro ⟨u, x⟩ hq ⟨u', x'⟩ hq' heq
    rw [mem_product, mem_powersetCard, mem_compl] at hq hq'
    simp only at heq
    have key : ∀ (u : Finset (Fin n)) (x : Fin n), u ⊆ t → x ∉ t → t ∩ insert x u = u := by
      intro u x hut hx
      ext y
      simp only [mem_inter, mem_insert]
      constructor
      · rintro ⟨hyt, rfl | hyu⟩
        · exact absurd hyt hx
        · exact hyu
      · intro hyu
        exact ⟨hut hyu, Or.inr hyu⟩
    have hu : u = u' := by
      rw [← key u x hq.1.1 hq.2, ← key u' x' hq'.1.1 hq'.2, heq]
    subst hu
    have hx : x ∈ insert x' u := heq ▸ mem_insert_self x u
    rcases mem_insert.1 hx with h | h
    · rw [h]
    · exact absurd (hq.1.1 h) hq.2
  · intro v hv
    rw [mem_filter, mem_powersetCard] at hv
    obtain ⟨⟨_, hv3⟩, hi2⟩ := hv
    have hsd : (v \ t).card = 1 := by
      have := card_sdiff_add_card_inter v t
      rw [inter_comm] at this
      omega
    obtain ⟨x, hx⟩ := card_eq_one.1 hsd
    have hxv : x ∈ v \ t := by rw [hx]; exact mem_singleton_self x
    refine ⟨(t ∩ v, x), ?_, ?_⟩
    · rw [mem_product, mem_powersetCard, mem_compl]
      exact ⟨⟨inter_subset_left, hi2⟩, (mem_sdiff.1 hxv).2⟩
    · ext y
      simp only [mem_insert, mem_inter]
      constructor
      · rintro (rfl | ⟨_, hy⟩)
        · exact (mem_sdiff.1 hxv).1
        · exact hy
      · intro hy
        by_cases hyt : y ∈ t
        · exact Or.inr ⟨hyt, hy⟩
        · left
          have : y ∈ v \ t := mem_sdiff.2 ⟨hy, hyt⟩
          rw [hx] at this
          exact mem_singleton.1 this

open Finset in
theorem fsm_pair_term (n : ℕ) (p : ℝ) (t u : Finset (Fin n)) (ht : t.card = 3)
    (hu : u.card = 3) :
    p ^ (t.offDiag.image Sym2.mk.uncurry ∪ u.offDiag.image Sym2.mk.uncurry).card =
      p ^ 6 + (if u = t then p ^ 3 - p ^ 6 else 0) +
        (if (t ∩ u).card = 2 then p ^ 5 - p ^ 6 else 0) := by
  have hU := card_union_add_card_inter (t.offDiag.image Sym2.mk.uncurry)
    (u.offDiag.image Sym2.mk.uncurry)
  rw [fsm_pairEdges_inter, Sym2.card_image_offDiag, Sym2.card_image_offDiag,
    Sym2.card_image_offDiag, ht, hu] at hU
  have hk : (t ∩ u).card ≤ 3 := ht ▸ card_le_card inter_subset_left
  have heq : u = t ↔ (t ∩ u).card = 3 := by
    constructor
    · rintro rfl
      rw [inter_self, ht]
    · intro h3
      have h1 : t ∩ u = t := eq_of_subset_of_card_le inter_subset_left (by rw [h3, ht])
      have h2 : t ⊆ u := by rw [← h1]; exact inter_subset_right
      exact (eq_of_subset_of_card_le h2 (by rw [ht, hu])).symm
  generalize (t ∩ u).card = k at hU hk heq ⊢
  interval_cases k
  · rw [if_neg (by rw [heq]; omega), if_neg (by omega)]
    norm_num at hU
    rw [show (t.offDiag.image Sym2.mk.uncurry ∪ u.offDiag.image Sym2.mk.uncurry).card = 6 by
      omega]
    ring
  · rw [if_neg (by rw [heq]; omega), if_neg (by omega)]
    norm_num at hU
    rw [show (t.offDiag.image Sym2.mk.uncurry ∪ u.offDiag.image Sym2.mk.uncurry).card = 6 by
      omega]
    ring
  · rw [if_neg (by rw [heq]; omega), if_pos rfl]
    norm_num at hU
    rw [show (t.offDiag.image Sym2.mk.uncurry ∪ u.offDiag.image Sym2.mk.uncurry).card = 5 by
      omega]
    ring
  · rw [if_pos (heq.2 rfl), if_neg (by omega)]
    norm_num at hU
    rw [show (t.offDiag.image Sym2.mk.uncurry ∪ u.offDiag.image Sym2.mk.uncurry).card = 3 by
      omega]
    ring

/-- **The first and second moment methods.** Let X be a count: a random whole number on a
probability space. First method: the chance that at least one appears is at most the average
number that appear, P(X ≥ 1) ≤ E[X] (an infinite average makes this say nothing, so no finite
mean is assumed). Second method: if X also has a finite variance and its mean is above zero,
the chance that none appear is at most the variance divided by the square of the mean,
P(X = 0) ≤ Var(X) / E[X]². -/
theorem first_and_second_moment_methods {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℕ) (hX : Measurable X) :
    μ {ω | 1 ≤ X ω} ≤ ∫⁻ ω, (X ω : ℝ≥0∞) ∂μ ∧
      (MemLp (fun ω => (X ω : ℝ)) 2 μ → 0 < ∫ ω, (X ω : ℝ) ∂μ →
        μ.real {ω | X ω = 0} ≤
          variance (fun ω => (X ω : ℝ)) μ / (∫ ω, (X ω : ℝ) ∂μ) ^ 2) := by
  constructor
  · have hm : AEMeasurable (fun ω => (X ω : ℝ≥0∞)) μ :=
      ((measurable_from_nat (f := fun k : ℕ => (k : ℝ≥0∞))).comp hX).aemeasurable
    have h := mul_meas_ge_le_lintegral₀ hm 1
    rw [one_mul] at h
    refine le_trans (le_of_eq ?_) h
    congr 1
    ext ω
    simp [Nat.one_le_cast]
  · intro hL hpos
    have h := meas_ge_le_variance_div_sq hL hpos
    rw [measureReal_def]
    refine ENNReal.toReal_le_of_le_ofReal (div_nonneg (variance_nonneg _ _) (sq_nonneg _)) ?_
    refine le_trans (measure_mono ?_) h
    intro ω hω
    simp only [Set.mem_ofPred_eq] at hω ⊢
    rw [hω]
    simp [abs_of_pos hpos]

/-- **The average triangle count.** In a club of n members where each of the C(n,2) pairs are
friends with chance p, independently, a friendship pattern G with k friendships has chance
p^k (1 − p)^(C(n,2) − k). The average number of triangles (trios who are all friends), summed
over every pattern, is the number of trios times the chance a trio is closed:
E[X] = C(n,3) p³. -/
theorem triangle_count_mean (n : ℕ) (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    open scoped Classical in
    ∑ G : SimpleGraph (Fin n),
        p ^ G.edgeFinset.card * (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
          ((G.cliqueFinset 3).card : ℝ) =
      (n.choose 3 : ℝ) * p ^ 3 := by
  classical
  simp_rw [fsm_clique_card, Finset.mul_sum]
  rw [Finset.sum_comm]
  have h : ∀ t ∈ (Finset.univ : Finset (Fin n)).powersetCard 3,
      ∑ G : SimpleGraph (Fin n), p ^ G.edgeFinset.card *
        (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
          (if t.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset then (1 : ℝ) else 0) = p ^ 3 := by
    intro t ht
    rw [fsm_graph_prob]
    · rw [Sym2.card_image_offDiag, (Finset.mem_powersetCard.1 ht).2]
      rfl
    · exact Finset.image_subset_image (Finset.offDiag_mono (Finset.subset_univ t))
  rw [Finset.sum_congr rfl h, Finset.sum_const, Finset.card_powersetCard, Finset.card_univ,
    Fintype.card_fin, nsmul_eq_mul]

/-- **The variance of the triangle count.** In the same random club, the variance of the number
of triangles, E[X²] − E[X]², is each trio's own variance p³ − p⁶ summed over the C(n,3) trios,
plus the covariance p⁵ − p⁶ for each of the 3(n − 3) trios that share a pair with a given trio:
Var(X) = C(n,3)(p³ − p⁶) + C(n,3) · 3(n − 3)(p⁵ − p⁶). -/
theorem triangle_count_variance (n : ℕ) (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    open scoped Classical in
    (∑ G : SimpleGraph (Fin n),
        p ^ G.edgeFinset.card * (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
          ((G.cliqueFinset 3).card : ℝ) ^ 2) -
      (∑ G : SimpleGraph (Fin n),
        p ^ G.edgeFinset.card * (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
          ((G.cliqueFinset 3).card : ℝ)) ^ 2 =
      (n.choose 3 : ℝ) * (p ^ 3 - p ^ 6) +
        (n.choose 3 : ℝ) * (3 * ((n : ℝ) - 3)) * (p ^ 5 - p ^ 6) := by
  classical
  rw [triangle_count_mean n p hp0 hp1]
  set T := (Finset.univ : Finset (Fin n)).powersetCard 3 with hT
  have hTc : (T.card : ℝ) = n.choose 3 := by
    rw [hT, Finset.card_powersetCard, Finset.card_univ, Fintype.card_fin]
  have hsq : ∀ G : SimpleGraph (Fin n),
      p ^ G.edgeFinset.card * (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
        ((G.cliqueFinset 3).card : ℝ) ^ 2 =
      ∑ t ∈ T, ∑ u ∈ T, p ^ G.edgeFinset.card * (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
        (if t.offDiag.image Sym2.mk.uncurry ∪ u.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset
          then (1 : ℝ) else 0) := by
    intro G
    rw [fsm_clique_card, sq, Finset.sum_mul_sum, Finset.mul_sum]
    refine Finset.sum_congr rfl (fun t _ => ?_)
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl (fun u _ => ?_)
    congr 1
    by_cases h1 : t.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset <;>
      by_cases h2 : u.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset <;>
        simp [h1, h2, Finset.union_subset_iff]
  rw [Finset.sum_congr rfl (fun G _ => hsq G), Finset.sum_comm]
  have hsub : ∀ s : Finset (Fin n),
      s.offDiag.image Sym2.mk.uncurry ⊆
        (Finset.univ : Finset (Fin n)).offDiag.image Sym2.mk.uncurry :=
    fun s => Finset.image_subset_image (Finset.offDiag_mono (Finset.subset_univ s))
  have hinner : ∀ t ∈ T,
      ∑ G : SimpleGraph (Fin n), ∑ u ∈ T, p ^ G.edgeFinset.card *
        (1 - p) ^ (n.choose 2 - G.edgeFinset.card) *
        (if t.offDiag.image Sym2.mk.uncurry ∪ u.offDiag.image Sym2.mk.uncurry ⊆ G.edgeFinset
          then (1 : ℝ) else 0) =
      (n.choose 3 : ℝ) * p ^ 6 + (p ^ 3 - p ^ 6) + 3 * ((n : ℝ) - 3) * (p ^ 5 - p ^ 6) := by
    intro t ht
    have ht3 : t.card = 3 := (Finset.mem_powersetCard.1 ht).2
    have hn : 3 ≤ n := by
      have := Finset.card_le_univ t
      rw [Fintype.card_fin] at this
      omega
    rw [Finset.sum_comm]
    rw [Finset.sum_congr rfl (fun u _ => fsm_graph_prob n p _
      (Finset.union_subset (hsub t) (hsub u)))]
    rw [Finset.sum_congr rfl (fun u hu => fsm_pair_term n p t u ht3
      (Finset.mem_powersetCard.1 hu).2)]
    rw [Finset.sum_add_distrib, Finset.sum_add_distrib, Finset.sum_const, nsmul_eq_mul, hTc,
      Finset.sum_ite_eq' T t, if_pos ht, ← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul,
      fsm_count_share_two n t ht3]
    push_cast [hn]
    ring
  rw [Finset.sum_congr rfl hinner, Finset.sum_const, nsmul_eq_mul, hTc]
  ring

-- The 100-member club: 4,950 pairs and 100 × 99 × 98 / 6 = 161,700 trios.
example : Nat.choose 100 2 = 4950 := by decide
example : Nat.choose 100 3 = 161700 := by decide
example : 100 * 99 * 98 / 6 = 161700 := by decide
-- Of the other 161,699 trios, 147,440 share no member with a given trio, 13,968 share one,
-- and 291 = 3(n − 3) share two.
example : Nat.choose 97 3 = 147440 ∧ 3 * Nat.choose 97 2 = 13968 ∧ 3 * (100 - 3) = 291 := by
  decide
example : 147440 + 13968 + 291 = 161700 - 1 := by decide
-- At p = 1/200 a trio is closed with chance 1/8,000,000, and E[X] = 161,700 / 8,000,000
-- = 0.0202125 exactly, which the card rounds to 0.0202: about 2% of clubs at most.
example : ((1 : ℚ) / 200) ^ 3 = 1 / 8000000 := by norm_num
example : (161700 : ℚ) * (1 / 200) ^ 3 = 202125 / 10000000 := by norm_num
-- At p = 1/20 a trio is closed with chance 1/8,000, and E[X] = 161,700 / 8,000 = 20.2125.
example : ((1 : ℚ) / 20) ^ 3 = 1 / 8000 := by norm_num
example : (161700 : ℚ) * (1 / 20) ^ 3 = 202125 / 10000 := by norm_num
-- Its variance and the second method's ratio: no triangle in at most 8.37% of clubs.
example :
    let p : ℚ := 1 / 20
    let v := 161700 * (p ^ 3 - p ^ 6) + 161700 * 291 * (p ^ 5 - p ^ 6)
    let e := 161700 * p ^ 3
    v / e ^ 2 ≤ 837 / 10000 ∧ 836 / 10000 ≤ v / e ^ 2 := by
  norm_num
-- The ratio's simplified form agrees with the raw division at p = 1/20.
example :
    let p : ℚ := 1 / 20
    let t : ℚ := 161700
    (t * (p ^ 3 - p ^ 6) + t * (3 * (100 - 3)) * (p ^ 5 - p ^ 6)) / (t * p ^ 3) ^ 2 =
      (1 - p ^ 3) / (t * p ^ 3) + 3 * (100 - 3) * (1 - p) / (t * p) := by
  norm_num
-- The 6-member club: 15 pairs, 2^15 = 32,768 friendship patterns, and 20 trios, with
-- 20 × 3 × 3 = 180 ordered pairs of trios sharing a pair.
example : Nat.choose 6 2 = 15 ∧ 2 ^ 15 = 32768 ∧ Nat.choose 6 3 = 20 := by decide
example : Nat.choose 6 3 * 3 * 3 = 180 := by decide
-- Its exact moments at p = 1/5: E[X] = 0.16 and Var(X) = 0.2048.
example : (20 : ℚ) * (1 / 5) ^ 3 = 16 / 100 := by norm_num
example : (20 : ℚ) * ((1 / 5) ^ 3 - (1 / 5) ^ 6) + 20 * (3 * 3) * ((1 / 5) ^ 5 - (1 / 5) ^ 6) =
    2048 / 10000 := by norm_num
-- The all-or-nothing club: every pair friends with chance 1/10, none otherwise. The average
-- count is 161,700 / 10 = 16,170, and the second method's ratio is 9, which says nothing.
example : (1 / 10 : ℚ) * 161700 = 16170 := by norm_num
example :
    let t : ℚ := 161700
    ((1 / 10) * t ^ 2 - ((1 / 10) * t) ^ 2) / ((1 / 10) * t) ^ 2 = 9 := by
  norm_num

#print axioms fsm_mem_pairEdges
#print axioms fsm_pairEdges_inter
#print axioms fsm_pairEdges_subset_iff
#print axioms fsm_powerset_sum
#print axioms fsm_graph_sum
#print axioms fsm_graph_prob
#print axioms fsm_clique_card
#print axioms fsm_count_share_two
#print axioms fsm_pair_term
#print axioms first_and_second_moment_methods
#print axioms triangle_count_mean
#print axioms triangle_count_variance
