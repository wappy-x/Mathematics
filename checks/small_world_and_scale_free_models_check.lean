-- Small worlds and hubs: the ring's clustering is 3(h-1)/(2(2h-1)) at every person, and preferential attachment's degree law is 2m(m+1)/(k(k+1)(k+2)) with tail m(m+1)/(k(k+1)).
import Mathlib.Combinatorics.SimpleGraph.Circulant
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.ZMod.Defs
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open scoped Classical


lemma sw_zmod_cast_eq_zero_iff {n : ℕ} (y : ℤ) (h1 : -(n:ℤ) < y) (h2 : y < n) :
    ((y : ZMod n) = 0 ↔ y = 0) := by
  rw [ZMod.intCast_zmod_eq_zero_iff_dvd]
  constructor
  · rintro ⟨k, rfl⟩
    have hn : (0:ℤ) < n := by omega
    rcases lt_trichotomy k 0 with hk | hk | hk
    · nlinarith
    · simp [hk]
    · nlinarith
  · rintro rfl; simp

lemma sw_mem_jumps_iff {n h : ℕ} (hn : 3 * h < n) (x : ℤ) (hx1 : -(2 * (h:ℤ)) ≤ x)
    (hx2 : x ≤ 2 * h) :
    ((x : ZMod n) ∈ ((fun j : ℕ => (j : ZMod n)) '' Set.Icc 1 h)) ↔ (1 ≤ x ∧ x ≤ h) := by
  constructor
  · rintro ⟨j, ⟨hj1, hj2⟩, hj⟩
    simp only at hj
    have h0 : (((x - j : ℤ)) : ZMod n) = 0 := by push_cast; rw [hj, sub_self]
    rw [sw_zmod_cast_eq_zero_iff _ (by omega) (by omega)] at h0
    omega
  · rintro ⟨h1, h2⟩
    obtain ⟨j, rfl⟩ := Int.eq_ofNat_of_zero_le (by omega : (0:ℤ) ≤ x)
    exact ⟨j, ⟨by omega, by omega⟩, by simp⟩

lemma sw_ring_adj_iff {n h : ℕ} (hn : 3 * h < n) (v : ZMod n) (a b : ℤ)
    (ha1 : -(h:ℤ) ≤ a) (ha2 : a ≤ h) (hb1 : -(h:ℤ) ≤ b) (hb2 : b ≤ h) :
    (SimpleGraph.circulantGraph ((fun j : ℕ => (j : ZMod n)) '' Set.Icc 1 h)).Adj
      (v + (a : ZMod n)) (v + (b : ZMod n)) ↔ (a ≠ b ∧ a - b ≤ h ∧ b - a ≤ h) := by
  rw [SimpleGraph.circulantGraph_adj]
  have e1 : v + (a : ZMod n) - (v + (b : ZMod n)) = ((a - b : ℤ) : ZMod n) := by push_cast; ring
  have e2 : v + (b : ZMod n) - (v + (a : ZMod n)) = ((b - a : ℤ) : ZMod n) := by push_cast; ring
  have hne : ¬ v + (a : ZMod n) = v + (b : ZMod n) ↔ ¬ a = b := by
    rw [← sub_eq_zero, e1, sw_zmod_cast_eq_zero_iff _ (by omega) (by omega),
      sub_eq_zero]
  rw [hne, e1, e2, sw_mem_jumps_iff hn _ (by omega) (by omega),
    sw_mem_jumps_iff hn _ (by omega) (by omega)]
  omega

lemma sw_abs_sum (h : ℕ) : ∑ a ∈ Finset.Icc (-(h:ℤ)) h, |a| = (h:ℤ) * (h + 1) := by
  induction h with
  | zero => simp
  | succ h ih =>
    have hs : Finset.Icc (-((h + 1 : ℕ) : ℤ)) ((h + 1 : ℕ) : ℤ) =
        insert ((h:ℤ) + 1) (insert (-((h:ℤ) + 1)) (Finset.Icc (-(h:ℤ)) h)) := by
      ext x; simp; omega
    rw [hs, Finset.sum_insert (by simp; omega), Finset.sum_insert (by simp), ih,
      abs_of_pos (show (0:ℤ) < (h:ℤ) + 1 by positivity),
      abs_of_neg (show -((h:ℤ) + 1) < 0 by omega)]
    push_cast; ring

lemma sw_inner_card (h : ℕ) (a : ℤ) (ha : a ∈ (Finset.Icc (-(h:ℤ)) h).erase 0) :
    ((((Finset.Icc (-(h:ℤ)) h).erase 0).filter
      (fun b : ℤ => a ≠ b ∧ a - b ≤ h ∧ b - a ≤ h)).card : ℤ) = 2 * h - 1 - |a| := by
  simp only [Finset.mem_erase, Finset.mem_Icc] at ha
  rcases lt_or_gt_of_ne ha.1 with hneg | hpos
  · have hs : ((Finset.Icc (-(h:ℤ)) h).erase 0).filter
        (fun b : ℤ => a ≠ b ∧ a - b ≤ h ∧ b - a ≤ h) =
        ((Finset.Icc (-(h:ℤ)) (a + h)).erase 0).erase a := by
      ext b; simp; omega
    rw [hs, Finset.card_erase_of_mem (by simp; omega), Finset.card_erase_of_mem (by simp; omega),
      Int.card_Icc, abs_of_neg hneg]
    have := Int.toNat_of_nonneg (show (0:ℤ) ≤ a + h + 1 - -(h:ℤ) by omega)
    omega
  · have hs : ((Finset.Icc (-(h:ℤ)) h).erase 0).filter
        (fun b : ℤ => a ≠ b ∧ a - b ≤ h ∧ b - a ≤ h) =
        ((Finset.Icc (a - h) (h:ℤ)).erase 0).erase a := by
      ext b; simp; omega
    rw [hs, Finset.card_erase_of_mem (by simp; omega), Finset.card_erase_of_mem (by simp; omega),
      Int.card_Icc, abs_of_pos hpos]
    have := Int.toNat_of_nonneg (show (0:ℤ) ≤ (h:ℤ) + 1 - (a - h) by omega)
    omega

lemma sw_T_card (h : ℕ) : ((Finset.Icc (-(h:ℤ)) h).erase 0).card = 2 * h := by
  rw [Finset.card_erase_of_mem (by simp), Int.card_Icc]
  omega

lemma sw_pair_count (h : ℕ) :
    (((((Finset.Icc (-(h:ℤ)) h).erase 0) ×ˢ ((Finset.Icc (-(h:ℤ)) h).erase 0)).filter
      (fun p : ℤ × ℤ => p.1 ≠ p.2 ∧ p.1 - p.2 ≤ h ∧ p.2 - p.1 ≤ h)).card : ℤ) =
      3 * h * (h - 1) := by
  have hsplit : ((((Finset.Icc (-(h:ℤ)) h).erase 0) ×ˢ ((Finset.Icc (-(h:ℤ)) h).erase 0)).filter
      (fun p : ℤ × ℤ => p.1 ≠ p.2 ∧ p.1 - p.2 ≤ h ∧ p.2 - p.1 ≤ h)).card =
      ∑ a ∈ (Finset.Icc (-(h:ℤ)) h).erase 0, (((Finset.Icc (-(h:ℤ)) h).erase 0).filter
        (fun b : ℤ => a ≠ b ∧ a - b ≤ h ∧ b - a ≤ h)).card := by
    rw [Finset.card_filter, Finset.sum_product]
    refine Finset.sum_congr rfl (fun a _ => ?_)
    rw [Finset.card_filter]
  rw [hsplit]
  push_cast
  rw [Finset.sum_congr rfl (fun a ha => sw_inner_card h a ha), Finset.sum_sub_distrib,
    Finset.sum_const, sw_T_card, Finset.sum_erase _ (by simp), sw_abs_sum]
  ring

#print axioms sw_zmod_cast_eq_zero_iff
#print axioms sw_mem_jumps_iff
#print axioms sw_ring_adj_iff
#print axioms sw_abs_sum
#print axioms sw_inner_card
#print axioms sw_T_card
#print axioms sw_pair_count

/-- The ring's clustering, by counting. Put `n` people on a ring (`ZMod n`) and link each person to
the `h` nearest on each side: the circulant graph with jumps `1, …, h`. Then every person has
`2h` friends, and the share of pairs of their friends who are themselves friends is
`3(h-1)/(2(2h-1))`, the same for everyone. Pairs are counted in order on both sides of the
fraction, which gives the same share as unordered pairs. The card's counting assumes the ring is
big enough that friends' offsets never wrap round the ring (`3h < n`; at `n = 3h` the friends at
offsets `h` and `-h` would be linked the short way), and at least one neighbour each side. -/
theorem ring_clustering_eq (n h : ℕ) [NeZero n] (hh : 1 ≤ h) (hn : 3 * h < n)
    (G : SimpleGraph (ZMod n))
    (hG : G = SimpleGraph.circulantGraph ((fun j : ℕ => (j : ZMod n)) '' Set.Icc 1 h))
    (v : ZMod n) :
    G.degree v = 2 * h ∧
      ((((G.neighborFinset v ×ˢ G.neighborFinset v).filter (fun p => G.Adj p.1 p.2)).card : ℚ) /
          ((G.degree v : ℚ) * ((G.degree v : ℚ) - 1)) =
        3 * ((h : ℚ) - 1) / (2 * (2 * (h : ℚ) - 1))) := by
  have hadjG : ∀ a b : ℤ, -(h:ℤ) ≤ a → a ≤ h → -(h:ℤ) ≤ b → b ≤ h →
      (G.Adj (v + (a : ZMod n)) (v + (b : ZMod n)) ↔ (a ≠ b ∧ a - b ≤ h ∧ b - a ≤ h)) := by
    intro a b ha1 ha2 hb1 hb2
    rw [hG]
    exact sw_ring_adj_iff hn v a b ha1 ha2 hb1 hb2
  obtain ⟨T, hTdef⟩ : ∃ T : Finset ℤ, T = (Finset.Icc (-(h:ℤ)) h).erase 0 := ⟨_, rfl⟩
  have hT : ∀ a, a ∈ T ↔ (-(h:ℤ) ≤ a ∧ a ≤ h ∧ a ≠ 0) := by
    intro a; rw [hTdef]; simp only [Finset.mem_erase, Finset.mem_Icc]; tauto
  have hinj : ∀ a ∈ T, ∀ b ∈ T, v + (a : ZMod n) = v + (b : ZMod n) → a = b := by
    intro a ha b hb hab
    rw [hT] at ha hb
    have h0 : ((a - b : ℤ) : ZMod n) = 0 := by
      have : (v + (a : ZMod n)) - (v + (b : ZMod n)) = ((a - b : ℤ) : ZMod n) := by
        push_cast; ring
      rw [← this, hab, sub_self]
    rw [sw_zmod_cast_eq_zero_iff _ (by omega) (by omega)] at h0
    omega
  have hN : G.neighborFinset v
      = T.image (fun d : ℤ => v + (d : ZMod n)) := by
    ext w
    rw [SimpleGraph.mem_neighborFinset, Finset.mem_image]
    constructor
    · intro hw
      rw [hG, SimpleGraph.circulantGraph_adj] at hw
      rcases hw.2 with ⟨j, ⟨hj1, hj2⟩, hj⟩ | ⟨j, ⟨hj1, hj2⟩, hj⟩
      · refine ⟨-(j:ℤ), (hT _).2 ⟨by omega, by omega, by omega⟩, ?_⟩
        simp only at hj
        push_cast
        rw [hj]; ring
      · refine ⟨(j:ℤ), (hT _).2 ⟨by omega, by omega, by omega⟩, ?_⟩
        simp only at hj
        push_cast
        rw [hj]; ring
    · rintro ⟨a, ha, rfl⟩
      rw [hT] at ha
      have := (hadjG 0 a (by omega) (by omega) (by omega) (by omega)).2
        ⟨by omega, by omega, by omega⟩
      simpa using this
  have hdeg : G.degree v
      = 2 * h := by
    rw [← SimpleGraph.card_neighborFinset_eq_degree, hN,
      Finset.card_image_of_injOn (fun a ha b hb hab => hinj a ha b hb hab), hTdef, sw_T_card]
  have hpair : ((G.neighborFinset v ×ˢ
      G.neighborFinset v).filter
      (fun p => G.Adj p.1 p.2)).card
      = ((T ×ˢ T).filter (fun p : ℤ × ℤ => p.1 ≠ p.2 ∧ p.1 - p.2 ≤ h ∧ p.2 - p.1 ≤ h)).card := by
    rw [hN]
    symm
    apply Finset.card_bij (fun p _ => (v + (p.1 : ZMod n), v + (p.2 : ZMod n)))
    · rintro ⟨a, b⟩ hab
      simp only [Finset.mem_filter, Finset.mem_product] at hab ⊢
      refine ⟨⟨Finset.mem_image_of_mem _ hab.1.1, Finset.mem_image_of_mem _ hab.1.2⟩, ?_⟩
      have ha := (hT a).1 hab.1.1
      have hb := (hT b).1 hab.1.2
      exact (hadjG a b (by omega) (by omega) (by omega) (by omega)).2 hab.2
    · rintro ⟨a, b⟩ hab ⟨c, d⟩ hcd heq
      simp only [Finset.mem_filter, Finset.mem_product] at hab hcd
      simp only [Prod.mk.injEq] at heq
      rw [hinj a hab.1.1 c hcd.1.1 heq.1, hinj b hab.1.2 d hcd.1.2 heq.2]
    · rintro ⟨x, y⟩ hxy
      simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_image] at hxy
      obtain ⟨⟨⟨a, ha, rfl⟩, ⟨b, hb, rfl⟩⟩, hadj⟩ := hxy
      refine ⟨(a, b), ?_, rfl⟩
      have ha' := (hT a).1 ha
      have hb' := (hT b).1 hb
      simp only [Finset.mem_filter, Finset.mem_product]
      exact ⟨⟨ha, hb⟩,
        (hadjG a b (by omega) (by omega) (by omega) (by omega)).1 hadj⟩
  have hQ := sw_pair_count h
  rw [← hTdef] at hQ
  have hQ' : (((T ×ˢ T).filter
      (fun p : ℤ × ℤ => p.1 ≠ p.2 ∧ p.1 - p.2 ≤ h ∧ p.2 - p.1 ≤ h)).card : ℚ) =
      3 * h * ((h:ℚ) - 1) := by
    have := congrArg (fun z : ℤ => (z : ℚ)) hQ
    push_cast at this
    exact this
  refine ⟨hdeg, ?_⟩
  rw [hpair, hdeg, hQ']
  have hh' : (1:ℚ) ≤ h := by exact_mod_cast hh
  push_cast
  rw [div_eq_div_iff (by nlinarith) (by linarith)]
  ring

/-- Preferential attachment, the balance equation solved. If the long-run degree shares satisfy
the card's balance `p_m = 2/(m+2)` and `p_k = p_{k-1} (k-1)/(k+2)` for `k > m`, then multiplying
the ratios gives `p_k = 2m(m+1)/(k(k+1)(k+2))` for every `k ≥ m`. Each newcomer brings `m ≥ 1`
links. -/
theorem pref_attachment_degree_law (m : ℕ) (hm : 1 ≤ m) (p : ℕ → ℝ)
    (h0 : p m = 2 / ((m : ℝ) + 2))
    (hrec : ∀ k : ℕ, m < k → p k = p (k - 1) * ((k : ℝ) - 1) / ((k : ℝ) + 2)) :
    ∀ k : ℕ, m ≤ k →
      p k = 2 * (m : ℝ) * ((m : ℝ) + 1) / ((k : ℝ) * ((k : ℝ) + 1) * ((k : ℝ) + 2)) := by
  intro k hk
  induction k, hk using Nat.le_induction with
  | base =>
    rw [h0]
    have hm' : (0:ℝ) < m := by exact_mod_cast hm
    rw [div_eq_div_iff (by positivity) (mul_pos (mul_pos hm' (by linarith)) (by linarith)).ne']
    ring
  | succ k hmk ih =>
    rw [hrec (k + 1) (by omega), Nat.add_sub_cancel, ih]
    have hk' : (1:ℝ) ≤ k := by exact_mod_cast (le_trans hm hmk)
    push_cast
    field_simp
    ring

/-- Preferential attachment, the power-law tail. Adding the degree law
`2m(m+1)/(j(j+1)(j+2))` over every `j ≥ k` telescopes to `m(m+1)/(k(k+1))`: the share of people
with `k` or more friends. Here `k ≥ m ≥ 1`, as for the degree law; with `k = m` the shares add to 1. -/
theorem pref_attachment_tail_sum (m k : ℕ) (hm : 1 ≤ m) (hk : m ≤ k) :
    HasSum
      (fun i : ℕ => 2 * (m : ℝ) * ((m : ℝ) + 1) /
        (((k + i : ℕ) : ℝ) * (((k + i : ℕ) : ℝ) + 1) * (((k + i : ℕ) : ℝ) + 2)))
      ((m : ℝ) * ((m : ℝ) + 1) / ((k : ℝ) * ((k : ℝ) + 1))) := by
  have hk1 : (1:ℝ) ≤ k := by exact_mod_cast (le_trans hm hk)
  let g : ℕ → ℝ := fun i => (m : ℝ) * ((m : ℝ) + 1) / (((k + i : ℕ) : ℝ) * (((k + i : ℕ) : ℝ) + 1))
  have hterm : ∀ i : ℕ, 2 * (m : ℝ) * ((m : ℝ) + 1) /
      (((k + i : ℕ) : ℝ) * (((k + i : ℕ) : ℝ) + 1) * (((k + i : ℕ) : ℝ) + 2)) = g i - g (i + 1) := by
    intro i
    simp only [g]
    have hi : (0:ℝ) ≤ i := by positivity
    push_cast
    have hki : (1:ℝ) ≤ k + i := by linarith
    field_simp
    ring
  have hnonneg : ∀ i : ℕ, 0 ≤ 2 * (m : ℝ) * ((m : ℝ) + 1) /
      (((k + i : ℕ) : ℝ) * (((k + i : ℕ) : ℝ) + 1) * (((k + i : ℕ) : ℝ) + 2)) := by
    intro i; positivity
  rw [hasSum_iff_tendsto_nat_of_nonneg hnonneg]
  simp_rw [hterm, Finset.sum_range_sub']
  have hlim : Filter.Tendsto g Filter.atTop (nhds 0) := by
    apply Filter.Tendsto.div_atTop tendsto_const_nhds
    apply Filter.tendsto_atTop_mono _ tendsto_natCast_atTop_atTop
    intro i
    push_cast
    have hi : (0:ℝ) ≤ i := by positivity
    nlinarith
  have h0 : g 0 = (m : ℝ) * ((m : ℝ) + 1) / ((k : ℝ) * ((k : ℝ) + 1)) := by
    simp [g]
  rw [← h0]
  simpa using (tendsto_const_nhds (x := g 0)).sub hlim

-- The card's worked numbers, exactly: 5,000 people, 10 friends each, h = 5, m = 5.

-- links: 5000 × 10 / 2
example : 5000 * 10 / 2 = 25000 := by norm_num
-- chance a pair is linked under pure chance: 2 × 25,000 / (5000 × 4999) = 10/4999
example : (2 * 25000 : ℚ) / (5000 * 4999) = 10 / 4999 := by norm_num
-- ring, h = 5: 3h(h-1)/2 = 30 linked friend pairs out of h(2h-1) = 45
example : 3 * 5 * (5 - 1) / 2 = 30 ∧ 5 * (2 * 5 - 1) = 45 := by norm_num
-- ring clustering: 30/45 = 3(h-1)/(2(2h-1)) = 2/3
example : (30 : ℚ) / 45 = 2 / 3 ∧ (3 * (5 - 1) : ℚ) / (2 * (2 * 5 - 1)) = 2 / 3 := by norm_num
-- ring path length, rough: 5000/(4 × 5) = 250
example : (5000 : ℚ) / (4 * 5) = 250 := by norm_num
-- ring path length, exact sum over every offset: 1,252,000 / 4999 (about 250.4501)
example : (Finset.Ico 1 5000).sum (fun d => (min d (5000 - d) + 5 - 1) / 5) = 1252000 := by
  decide +kernel
-- shortcuts: n h β = 25,000 × 1/100 = 250 and 25,000 × 1/10 = 2,500
example : (5000 * 5 : ℚ) * (1 / 100) = 250 ∧ (5000 * 5 : ℚ) * (1 / 10) = 2500 := by norm_num
-- rewired at β = 1/10: (9/10)^3 = 729/1000, and C₀ (1-β)^3 = 2/3 × 729/1000 = 243/500
example : ((9 : ℚ) / 10) ^ 3 = 729 / 1000 ∧ (2 / 3 : ℚ) * (9 / 10) ^ 3 = 243 / 500 := by norm_num
-- growth, m = 5: p_m = 2/(m+2) = 2/7 agrees with 2m(m+1)/(m(m+1)(m+2))
example : (2 : ℚ) / (5 + 2) = 2 * 5 * 6 / (5 * 6 * 7) := by norm_num
-- growth, share with 20 or more friends: 5 × 6 / (20 × 21) = 30/420 = 1/14
example : (5 * 6 : ℚ) / (20 * 21) = 30 / 420 ∧ (30 : ℚ) / 420 = 1 / 14 := by norm_num
-- growth, expected people with 20 or more: 5000/14 = 2500/7 (about 357.1429)
example : (5000 : ℚ) * (1 / 14) = 2500 / 7 := by norm_num
-- growth, expected people with 50 or more: 5000 × 30 / (50 × 51) = 1000/17 (about 58.8235)
example : (5000 : ℚ) * 30 / (50 * 51) = 1000 / 17 := by norm_num
-- mean degree under growth is 2m, not m
example : 2 * 5 = 10 := by norm_num

#print axioms ring_clustering_eq
#print axioms pref_attachment_degree_law
#print axioms pref_attachment_tail_sum
