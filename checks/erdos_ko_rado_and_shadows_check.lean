-- Erdos-Ko-Rado: an intersecting family of k-sets on n ≥ 2k points has at most C(n-1, k-1) members, the star reaches it, and initial colex segments have the smallest shadow.
import Mathlib.Combinatorics.SetFamily.KruskalKatona

open Finset
open scoped FinsetFamily

/-- **Erdős–Ko–Rado.** Take `n` points (here `Fin n`) and a family `𝒜` of sets that all have
`k` members. If every two members of the family share a point, and `n ≥ 2k`, then the family has
at most `C(n - 1, k - 1)` members: no more than the star of all `k`-sets through one point. -/
theorem erdos_ko_rado_intersecting_family_le_star {n k : ℕ} {𝒜 : Finset (Finset (Fin n))}
    (hinter : (𝒜 : Set (Finset (Fin n))).Intersecting)
    (hsize : (𝒜 : Set (Finset (Fin n))).Sized k)
    (hn : 2 * k ≤ n) :
    #𝒜 ≤ (n - 1).choose (k - 1) := by
  exact erdos_ko_rado hinter hsize (by omega)

/-- **The bound is reached by a star.** For `k ≥ 1` and any point `a` among `n` points, the star
of all `k`-sets containing `a` is an intersecting family of `k`-sets with exactly
`C(n - 1, k - 1)` members. -/
theorem star_intersecting_and_card_eq {n k : ℕ} (hk : 1 ≤ k) (a : Fin n) :
    (((univ.powersetCard k).filter (fun s => a ∈ s) : Finset (Finset (Fin n))) :
        Set (Finset (Fin n))).Intersecting ∧
      (((univ.powersetCard k).filter (fun s => a ∈ s) : Finset (Finset (Fin n))) :
        Set (Finset (Fin n))).Sized k ∧
      #((univ.powersetCard k).filter (fun s => a ∈ s) : Finset (Finset (Fin n))) =
        (n - 1).choose (k - 1) := by
  refine ⟨?_, ?_, ?_⟩
  · intro s hs t ht hst
    simp only [coe_filter, Set.mem_ofPred_eq] at hs ht
    exact Finset.disjoint_left.1 hst hs.2 ht.2
  · intro s hs
    simp only [coe_filter, Set.mem_ofPred_eq, mem_powersetCard_univ] at hs
    exact hs.1
  · have h := card_filter_powersetCard_subset ({a} : Finset (Fin n)) univ k (subset_univ _)
      (by simpa using hk)
    simp only [singleton_subset_iff, card_univ, Fintype.card_fin, card_singleton] at h
    exact h

/-- **Kruskal–Katona.** Among all families of `k`-sets on `n` points with the same number of
members, the first ones in colex order (an initial segment of colex) have the smallest shadow:
the fewest `(k - 1)`-sets lying inside some member. -/
theorem kruskal_katona_colex_smallest_shadow {n k : ℕ} {𝒜 𝒞 : Finset (Finset (Fin n))}
    (hsize : (𝒜 : Set (Finset (Fin n))).Sized k)
    (hcolex : Colex.IsInitSeg 𝒞 k)
    (hcard : #𝒞 = #𝒜) :
    #(∂ 𝒞) ≤ #(∂ 𝒜) := by
  exact kruskal_katona hsize hcard.le hcolex

/-! The card's worked numbers. Points are numbered `0, …, n - 1` here, so the card's server 1
is point `0`. -/

-- Six servers, groups of three: 20 groups, and the star through one server holds C(5, 2) = 10.
example : Nat.choose 6 3 = 20 := by decide
example : Nat.choose 5 2 = 10 := by decide
example : #((univ.powersetCard 3).filter (fun s => (0 : Fin 6) ∈ s)) = 10 := by decide

-- Katona's count: 5! = 120 seatings, 3! × 3! = 36 seatings per arc, 3 × 120 = 360 hits, 360 / 36 = 10.
example : Nat.factorial 5 = 120 := by decide
example : Nat.factorial 3 * Nat.factorial 3 = 36 := by decide
example : 3 * Nat.factorial 5 = 360 ∧ 360 / 36 = 10 := by decide
example : 3 * Nat.factorial 5 / (Nat.factorial 3 * Nat.factorial 3) = Nat.choose 5 2 := by decide

-- Five servers, groups of three: all C(5, 3) = 10 groups meet pairwise, more than C(4, 2) = 6.
example : ∀ A ∈ (univ : Finset (Fin 5)).powersetCard 3,
    ∀ B ∈ (univ : Finset (Fin 5)).powersetCard 3, ¬ Disjoint A B := by decide
example : #((univ : Finset (Fin 5)).powersetCard 3) = 10 ∧ Nat.choose 4 2 = 6 := by decide

-- The groups holding at least two of servers 1, 2, 3: 10 groups, every two meet, no common server.
example :
    #((univ.powersetCard 3).filter
      (fun s : Finset (Fin 6) => 2 ≤ #(s ∩ {0, 1, 2}))) = 10 := by decide
example : ∀ A ∈ (univ.powersetCard 3).filter
      (fun s : Finset (Fin 6) => 2 ≤ #(s ∩ {0, 1, 2})),
    ∀ B ∈ (univ.powersetCard 3).filter
      (fun s : Finset (Fin 6) => 2 ≤ #(s ∩ {0, 1, 2})), ¬ Disjoint A B := by decide
example : ¬ ∃ p : Fin 6, ∀ A ∈ (univ.powersetCard 3).filter
      (fun s : Finset (Fin 6) => 2 ≤ #(s ∩ {0, 1, 2})), p ∈ A := by decide

-- At n = 2k = 6: 10 opposite pairs, so 2 ^ 10 = 1024 ways to take one group from each.
example : Nat.choose 6 3 / 2 = 10 ∧ 2 ^ 10 = 1024 := by decide

-- Small case n = 4, k = 2: 6 pairs, at most C(3, 1) = 3 pairwise meeting.
example : Nat.choose 4 2 = 6 ∧ Nat.choose 3 1 = 3 := by decide

-- Shadows: the star through server 1 has 15 pairs in its shadow; all 3-sets of the first five
-- servers (the first 10 in colex order) have 10.
example : #(∂ ((univ.powersetCard 3).filter (fun s => (0 : Fin 6) ∈ s))) = 15 := by decide
example : #(∂ ((univ.filter (fun i : Fin 6 => i < 5)).powersetCard 3)) = 10 := by decide

-- Kruskal-Katona's greedy split: 7 = C(4, 3) + C(3, 2), so the shadow has at least C(4, 2) + C(3, 1) = 9.
example : 7 = Nat.choose 4 3 + Nat.choose 3 2 ∧ Nat.choose 4 2 + Nat.choose 3 1 = 9 := by decide

#print axioms erdos_ko_rado_intersecting_family_le_star
#print axioms star_intersecting_and_card_eq
#print axioms kruskal_katona_colex_smallest_shadow
