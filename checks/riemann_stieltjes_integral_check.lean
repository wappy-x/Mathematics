-- Stieltjes integrals: a continuous value has a Stieltjes integral against every nondecreasing integrator, a steady rise plus jumps gives an ordinary integral plus one term per jump, and the card's 1,000 contracts average $35.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Topology.UniformSpace.HeineCantor

open Set

/-- A partition of `[a, b]` into `n` slices: the cuts `a = x 0 < x 1 < ... < x n = b`. -/
def IsPartition (a b : ℝ) (n : ℕ) (x : Fin (n + 1) → ℝ) : Prop :=
  StrictMono x ∧ x 0 = a ∧ x (Fin.last n) = b

/-- A Stieltjes sum: value at the tag `ξ k` times the weight `G(x_k) - G(x_{k-1})` of slice `k`. -/
def stieltjesSum (f G : ℝ → ℝ) (n : ℕ) (x : Fin (n + 1) → ℝ) (ξ : Fin n → ℝ) : ℝ :=
  ∑ k : Fin n, f (ξ k) * (G (x k.succ) - G (x k.castSucc))

/-- `I` is the Stieltjes integral of `f` against `G` from `a` to `b`: the Stieltjes sums settle
on `I` as the widest slice shrinks, whatever the tags. For every `ε > 0` there is a width `δ > 0`
such that every partition whose slices are all narrower than `δ`, with any tag in each slice,
gives a sum within `ε` of `I`. -/
def HasStieltjesIntegral (f G : ℝ → ℝ) (a b I : ℝ) : Prop :=
  ∀ ε > 0, ∃ δ > 0, ∀ (n : ℕ) (x : Fin (n + 1) → ℝ) (ξ : Fin n → ℝ),
    IsPartition a b n x →
    (∀ k : Fin n, x k.succ - x k.castSucc < δ) →
    (∀ k : Fin n, ξ k ∈ Icc (x k.castSucc) (x k.succ)) →
    |stieltjesSum f G n x ξ - I| < ε

/-- The `n` equal slices of `[a, b]`: cut `k` sits at `a + (b - a) k / n`. -/
noncomputable def evenCuts (a b : ℝ) (n : ℕ) (k : Fin (n + 1)) : ℝ :=
  a + (b - a) * (k : ℕ) / n

/-- The card's integrator: the share of the 1,000 contracts paying at most `x` dollars.
A lump of 2/5 at $0, a steady rise of 1/200 per dollar, and a lump of 1/10 at the $100 cap. -/
noncomputable def bookShare (x : ℝ) : ℝ :=
  if x < 0 then 0 else if x < 100 then 2 / 5 + x / 200 else 1

lemma rs_fin_tele (n : ℕ) (y : Fin (n + 1) → ℝ) :
    ∑ k : Fin n, (y k.succ - y k.castSucc) = y (Fin.last n) - y 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Fin.sum_univ_castSucc]
    have := ih (fun i => y i.castSucc)
    simp only [Fin.succ_castSucc] at this ⊢
    rw [this]
    simp only [Fin.castSucc_zero, Fin.succ_last]
    ring

#print axioms rs_fin_tele

lemma rs_part_mem {a b : ℝ} {n : ℕ} {x : Fin (n + 1) → ℝ} (h : IsPartition a b n x)
    (i : Fin (n + 1)) : x i ∈ Icc a b := by
  obtain ⟨hm, h0, hl⟩ := h
  constructor
  · rw [← h0]; exact hm.monotone (Fin.zero_le i)
  · rw [← hl]; exact hm.monotone (Fin.le_last i)

#print axioms rs_part_mem

lemma rs_part_lt {a b : ℝ} {n : ℕ} {x : Fin (n + 1) → ℝ} (h : IsPartition a b n x)
    (k : Fin n) : x k.castSucc < x k.succ := h.1 (Fin.castSucc_lt_succ (i := k))

#print axioms rs_part_lt

lemma rs_crit (f G Φ Ψ : ℝ → ℝ) (a b : ℝ)
    (h : ∀ ε > 0, ∃ δ > 0, ∀ u ξ v, a ≤ u → u ≤ ξ → ξ ≤ v → v ≤ b → v - u < δ →
      |Φ v - Φ u - f ξ * (G v - G u)| ≤ ε * (Ψ v - Ψ u)) :
    HasStieltjesIntegral f G a b (Φ b - Φ a) := by
  intro ε hε
  set C := |Ψ b - Ψ a| + 1 with hC
  have hCpos : 0 < C := by positivity
  obtain ⟨δ, hδ, hδ'⟩ := h (ε / (2 * C)) (by positivity)
  refine ⟨δ, hδ, fun n x ξ hP hmesh htag => ?_⟩
  have hsum : Φ b - Φ a - stieltjesSum f G n x ξ = ∑ k : Fin n, (Φ (x k.succ) - Φ (x k.castSucc)
      - f (ξ k) * (G (x k.succ) - G (x k.castSucc))) := by
    rw [Finset.sum_sub_distrib, rs_fin_tele n (fun i => Φ (x i)), hP.2.1, hP.2.2]; rfl
  have hb : |Φ b - Φ a - stieltjesSum f G n x ξ| ≤ ε / (2 * C) * (Ψ b - Ψ a) := by
    rw [hsum]
    calc _ ≤ ∑ k : Fin n, |Φ (x k.succ) - Φ (x k.castSucc)
            - f (ξ k) * (G (x k.succ) - G (x k.castSucc))| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ k : Fin n, ε / (2 * C) * (Ψ (x k.succ) - Ψ (x k.castSucc)) :=
          Finset.sum_le_sum fun k _ => hδ' _ _ _ (rs_part_mem hP _).1 (htag k).1 (htag k).2
            (rs_part_mem hP _).2 (hmesh k)
      _ = _ := by rw [← Finset.mul_sum, rs_fin_tele n (fun i => Ψ (x i)), hP.2.1, hP.2.2]
  have h2 : ε / (2 * C) * C = ε / 2 := by field_simp
  rw [abs_sub_comm]
  calc _ ≤ ε / (2 * C) * (Ψ b - Ψ a) := hb
    _ ≤ ε / (2 * C) * C :=
        mul_le_mul_of_nonneg_left (by rw [hC]; linarith [le_abs_self (Ψ b - Ψ a)]) (by positivity)
    _ < ε := by rw [h2]; linarith

#print axioms rs_crit

lemma rs_clamp_swap (G : ℝ → ℝ) (p q r s : ℝ) (hpq : p ≤ q) (hrs : r ≤ s) :
    G (max p (min q s)) - G (max p (min q r))
      = G (max r (min s q)) - G (max r (min s p)) := by
  rcases le_total q r with h1 | h1
  · rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith,
      show max r (min s q) = max r (min s p) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring
  rcases le_total s p with h2 | h2
  · rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith,
      show max r (min s q) = max r (min s p) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring
  rw [show max p (min q s) = max r (min s q) by
        simp only [max_def, min_def]; split_ifs <;> linarith,
      show max p (min q r) = max r (min s p) by
        simp only [max_def, min_def]; split_ifs <;> linarith]

#print axioms rs_clamp_swap

lemma rs_clamp_overlap (G : ℝ → ℝ) (p q r s : ℝ) (_hpq : p ≤ q) (hrs : r ≤ s)
    (h : G (max p (min q s)) - G (max p (min q r)) ≠ 0) : r < q ∧ p < s := by
  constructor
  · by_contra hcon
    push Not at hcon
    apply h
    rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring
  · by_contra hcon
    push Not at hcon
    apply h
    rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring

#print axioms rs_clamp_overlap

lemma rs_clamp_nonneg (G : ℝ → ℝ) (a b p q r s : ℝ) (hG : MonotoneOn G (Icc a b))
    (hp : p ∈ Icc a b) (hq : q ∈ Icc a b) (_hpq : p ≤ q) (hrs : r ≤ s) :
    0 ≤ G (max p (min q s)) - G (max p (min q r)) := by
  have m1 : max p (min q s) ∈ Icc a b :=
    ⟨hp.1.trans (le_max_left _ _), max_le hp.2 ((min_le_left _ _).trans hq.2)⟩
  have m2 : max p (min q r) ∈ Icc a b :=
    ⟨hp.1.trans (le_max_left _ _), max_le hp.2 ((min_le_left _ _).trans hq.2)⟩
  exact sub_nonneg.2 (hG m2 m1 (max_le_max le_rfl (min_le_min le_rfl hrs)))

#print axioms rs_clamp_nonneg

lemma rs_cauchy (f G : ℝ → ℝ) (a b : ℝ) (hf : ContinuousOn f (Icc a b))
    (hG : MonotoneOn G (Icc a b)) :
    ∀ ε > 0, ∃ δ > 0, ∀ (n : ℕ) (x : Fin (n + 1) → ℝ) (ξ : Fin n → ℝ)
      (m : ℕ) (y : Fin (m + 1) → ℝ) (η : Fin m → ℝ),
      IsPartition a b n x → (∀ k : Fin n, x k.succ - x k.castSucc < δ) →
      (∀ k : Fin n, ξ k ∈ Icc (x k.castSucc) (x k.succ)) →
      IsPartition a b m y → (∀ k : Fin m, y k.succ - y k.castSucc < δ) →
      (∀ k : Fin m, η k ∈ Icc (y k.castSucc) (y k.succ)) →
      |stieltjesSum f G n x ξ - stieltjesSum f G m y η| ≤ ε * (G b - G a) := by
  intro ε hε
  obtain ⟨δ, hδ, hδ'⟩ := Metric.uniformContinuousOn_iff.1
    (isCompact_Icc.uniformContinuousOn_of_continuous hf) ε hε
  refine ⟨δ / 2, by positivity, ?_⟩
  intro n x ξ m y η hP hPm hPt hQ hQm hQt
  set W : Fin n → Fin m → ℝ := fun k j =>
    G (max (x k.castSucc) (min (x k.succ) (y j.succ)))
      - G (max (x k.castSucc) (min (x k.succ) (y j.castSucc))) with hW
  have hrow : ∀ k, ∑ j, W k j = G (x k.succ) - G (x k.castSucc) := by
    intro k
    rw [hW]
    rw [rs_fin_tele m (fun i => G (max (x k.castSucc) (min (x k.succ) (y i)))), hQ.2.1, hQ.2.2]
    have h1 := rs_part_mem hP k.castSucc
    have h2 := rs_part_mem hP k.succ
    have h3 := rs_part_lt hP k
    rw [min_eq_left h2.2, max_eq_right h3.le, min_eq_right (h1.1.trans h3.le),
      max_eq_left h1.1]
  have hcol : ∀ j, ∑ k, W k j = G (y j.succ) - G (y j.castSucc) := by
    intro j
    have hsw : ∀ k, W k j = G (max (y j.castSucc) (min (y j.succ) (x k.succ)))
        - G (max (y j.castSucc) (min (y j.succ) (x k.castSucc))) := fun k =>
      rs_clamp_swap G _ _ _ _ (rs_part_lt hP k).le (rs_part_lt hQ j).le
    rw [Finset.sum_congr rfl fun k _ => hsw k]
    rw [rs_fin_tele n (fun i => G (max (y j.castSucc) (min (y j.succ) (x i)))), hP.2.1, hP.2.2]
    have h1 := rs_part_mem hQ j.castSucc
    have h2 := rs_part_mem hQ j.succ
    have h3 := rs_part_lt hQ j
    rw [min_eq_left h2.2, max_eq_right h3.le, min_eq_right (h1.1.trans h3.le),
      max_eq_left h1.1]
  have hdiff : stieltjesSum f G n x ξ - stieltjesSum f G m y η
      = ∑ k, ∑ j, (f (ξ k) - f (η j)) * W k j := by
    unfold stieltjesSum
    rw [Finset.sum_congr rfl fun k _ => congrArg (f (ξ k) * ·) (hrow k).symm,
      Finset.sum_congr rfl fun j _ => congrArg (f (η j) * ·) (hcol j).symm]
    simp only [Finset.mul_sum]
    rw [Finset.sum_comm (s := Finset.univ) (t := Finset.univ)
      (f := fun j k => f (η j) * W k j), ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl fun j _ => by ring
  rw [hdiff]
  calc |∑ k, ∑ j, (f (ξ k) - f (η j)) * W k j| ≤ ∑ k, ∑ j, ε * W k j := by
        refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun k _ => ?_)
        refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun j _ => ?_)
        have hW0 : 0 ≤ W k j := rs_clamp_nonneg G a b _ _ _ _ hG (rs_part_mem hP _)
          (rs_part_mem hP _) (rs_part_lt hP k).le (rs_part_lt hQ j).le
        rw [abs_mul, abs_of_nonneg hW0]
        by_cases hz : W k j = 0
        · rw [hz]; simp
        · apply mul_le_mul_of_nonneg_right _ hW0
          obtain ⟨o1, o2⟩ := rs_clamp_overlap G _ _ _ _ (rs_part_lt hP k).le
            (rs_part_lt hQ j).le hz
          have hξ : ξ k ∈ Icc a b :=
            ⟨(rs_part_mem hP _).1.trans (hPt k).1, (hPt k).2.trans (rs_part_mem hP _).2⟩
          have hη : η j ∈ Icc a b :=
            ⟨(rs_part_mem hQ _).1.trans (hQt j).1, (hQt j).2.trans (rs_part_mem hQ _).2⟩
          have hd := hδ' _ hξ _ hη (by
            rw [Real.dist_eq, abs_lt]
            constructor <;> linarith [(hPt k).1, (hPt k).2, (hQt j).1, (hQt j).2, hPm k, hQm j])
          rw [Real.dist_eq] at hd
          exact hd.le
    _ = ε * (G b - G a) := by
        simp only [← Finset.mul_sum, hrow]
        rw [rs_fin_tele n (fun i => G (x i)), hP.2.1, hP.2.2]

#print axioms rs_cauchy

lemma rs_half (ε D : ℝ) (hε : 0 < ε) (hD : 0 ≤ D) : ε / (2 * (D + 1)) * D ≤ ε / 2 := by
  rw [div_mul_eq_mul_div, div_le_div_iff₀ (by positivity) (by norm_num)]
  nlinarith

#print axioms rs_half

lemma rs_even_part (a b : ℝ) (hab : a < b) (n : ℕ) :
    IsPartition a b (n + 1) (evenCuts a b (n + 1)) := by
  have hn : (0 : ℝ) < ((n + 1 : ℕ) : ℝ) := by positivity
  refine ⟨fun i j hij => ?_, ?_, ?_⟩
  · simp only [evenCuts]
    have : ((i : ℕ) : ℝ) < ((j : ℕ) : ℝ) := by exact_mod_cast hij
    have h2 : (b - a) * (i : ℕ) / ((n + 1 : ℕ) : ℝ) < (b - a) * (j : ℕ) / ((n + 1 : ℕ) : ℝ) :=
      div_lt_div_of_pos_right (mul_lt_mul_of_pos_left this (sub_pos.2 hab)) hn
    linarith
  · simp [evenCuts]
  · simp only [evenCuts, Fin.val_last]
    field_simp
    ring

#print axioms rs_even_part

lemma rs_even_mesh (a b : ℝ) (n : ℕ) (k : Fin (n + 1)) :
    evenCuts a b (n + 1) k.succ - evenCuts a b (n + 1) k.castSucc = (b - a) / ((n : ℝ) + 1) := by
  simp only [evenCuts, Fin.val_succ, Fin.val_castSucc]
  push_cast
  field_simp
  ring

#print axioms rs_even_mesh

/-- The Stieltjes integral exists: if the value `f` is continuous on `[a, b]` and the
integrator `G` never falls there, then the Stieltjes sums of `f` against `G` settle on one
number as the widest slice shrinks, whatever the tags. -/
theorem continuous_has_stieltjes_integral_against_nondecreasing (f G : ℝ → ℝ) (a b : ℝ)
    (hf : ContinuousOn f (Icc a b)) (hG : MonotoneOn G (Icc a b)) :
    ∃ I, HasStieltjesIntegral f G a b I := by
  by_cases hab : a < b
  · have hD : 0 ≤ G b - G a :=
      sub_nonneg.2 (hG (left_mem_Icc.2 hab.le) (right_mem_Icc.2 hab.le) hab.le)
    set D := G b - G a with hDdef
    have hC := rs_cauchy f G a b hf hG
    set s : ℕ → ℝ := fun N => stieltjesSum f G (N + 1) (evenCuts a b (N + 1))
      (fun k => evenCuts a b (N + 1) k.castSucc) with hs
    have htag : ∀ N (k : Fin (N + 1)), evenCuts a b (N + 1) k.castSucc ∈
        Icc (evenCuts a b (N + 1) k.castSucc) (evenCuts a b (N + 1) k.succ) :=
      fun N k => ⟨le_rfl, (rs_part_lt (rs_even_part a b hab N) k).le⟩
    have hmesh : ∀ δ > 0, ∃ N₀ : ℕ, ∀ N ≥ N₀, ∀ k : Fin (N + 1),
        evenCuts a b (N + 1) k.succ - evenCuts a b (N + 1) k.castSucc < δ := by
      intro δ hδ
      obtain ⟨N₀, hN₀⟩ := exists_nat_gt ((b - a) / δ)
      refine ⟨N₀, fun N hN k => ?_⟩
      rw [rs_even_mesh, div_lt_iff₀ (by positivity)]
      rw [div_lt_iff₀ hδ] at hN₀
      have : (N₀ : ℝ) ≤ N := by exact_mod_cast hN
      nlinarith
    -- the key estimate: two fine sums are close
    have hclose : ∀ ε > 0, ∃ δ > 0, ∃ N₀ : ℕ, ∀ N ≥ N₀, ∀ (n : ℕ) (x : Fin (n + 1) → ℝ)
        (ξ : Fin n → ℝ), IsPartition a b n x → (∀ k : Fin n, x k.succ - x k.castSucc < δ) →
        (∀ k : Fin n, ξ k ∈ Icc (x k.castSucc) (x k.succ)) →
        |stieltjesSum f G n x ξ - s N| ≤ ε / 2 := by
      intro ε hε
      obtain ⟨δ, hδ, hδ'⟩ := hC (ε / (2 * (D + 1))) (by positivity)
      obtain ⟨N₀, hN₀⟩ := hmesh δ hδ
      refine ⟨δ, hδ, N₀, fun N hN n x ξ hP hPm hPt => ?_⟩
      exact (hδ' n x ξ (N + 1) _ _ hP hPm hPt (rs_even_part a b hab N) (hN₀ N hN)
        (htag N)).trans (rs_half ε D hε hD)
    have hcs : CauchySeq s := by
      rw [Metric.cauchySeq_iff]
      intro ε hε
      obtain ⟨δ, hδ, N₀, hN₀⟩ := hclose ε hε
      obtain ⟨N₁, hN₁⟩ := hmesh δ hδ
      refine ⟨max N₀ N₁, fun p hp q hq => ?_⟩
      rw [Real.dist_eq]
      have := hN₀ q (le_of_max_le_left hq) (p + 1) _ _ (rs_even_part a b hab p)
        (hN₁ p (le_of_max_le_right hp)) (htag p)
      linarith
    obtain ⟨I, hI⟩ := cauchySeq_tendsto_of_complete hcs
    refine ⟨I, fun ε hε => ?_⟩
    obtain ⟨δ, hδ, N₀, hN₀⟩ := hclose ε hε
    obtain ⟨N₁, hN₁⟩ := Metric.tendsto_atTop.1 hI (ε / 2) (by positivity)
    refine ⟨δ, hδ, fun n x ξ hP hPm hPt => ?_⟩
    have h1 := hN₀ (max N₀ N₁) (le_max_left _ _) n x ξ hP hPm hPt
    have h2 := hN₁ (max N₀ N₁) (le_max_right _ _)
    rw [Real.dist_eq] at h2
    calc |stieltjesSum f G n x ξ - I|
        ≤ |stieltjesSum f G n x ξ - s (max N₀ N₁)| + |s (max N₀ N₁) - I| := abs_sub_le _ _ _
      _ < ε := by linarith
  · refine ⟨0, fun ε hε => ⟨1, one_pos, fun n x ξ hP _ _ => ?_⟩⟩
    obtain rfl : n = 0 := by
      by_contra hn
      apply hab
      rw [← hP.2.1, ← hP.2.2]
      apply hP.1
      rw [Fin.lt_def]
      simp only [Fin.val_zero, Fin.val_last]
      omega
    simp [stieltjesSum, hε]

/-- The working formula: if the nondecreasing integrator `G` is a part `G₀` climbing at a
continuous rate `g` plus finitely many jumps, of size `w j` at the point `c j` inside the
interval (`a < c j ≤ b`), then for a continuous value `f` the Stieltjes integral is the ordinary
integral of `f` times the rate, plus each jump's size times the value there. -/
theorem stieltjes_integral_rate_plus_jumps (f G G₀ g : ℝ → ℝ) (a b : ℝ) (m : ℕ)
    (w c : Fin m → ℝ)
    (hf : ContinuousOn f (Icc a b)) (hG : MonotoneOn G (Icc a b))
    (hG₀ : ∀ x ∈ Icc a b, HasDerivWithinAt G₀ (g x) (Icc a b) x)
    (hg : ContinuousOn g (Icc a b))
    (hc : ∀ j, c j ∈ Ioc a b)
    (hsplit : ∀ x ∈ Icc a b, G x = G₀ x + ∑ j, w j * (if c j ≤ x then 1 else 0)) :
    HasStieltjesIntegral f G a b ((∫ x in a..b, f x * g x) + ∑ j, w j * f (c j)) := by
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hg
  have hfg : ContinuousOn (fun x => f x * g x) (Icc a b) := hf.mul hg
  have hint : ∀ p ∈ Icc a b, ∀ q ∈ Icc a b,
      IntervalIntegrable (fun x => f x * g x) MeasureTheory.volume p q :=
    fun p hp q hq => (hfg.mono (uIcc_subset_Icc hp hq)).intervalIntegrable
  have hintg : ∀ p ∈ Icc a b, ∀ q ∈ Icc a b, IntervalIntegrable g MeasureTheory.volume p q :=
    fun p hp q hq => (hg.mono (uIcc_subset_Icc hp hq)).intervalIntegrable
  set s : Fin m → ℝ → ℝ := fun j x => if c j ≤ x then 1 else 0 with hs
  set Φ : ℝ → ℝ := fun x => (∫ t in a..x, f t * g t) + ∑ j, w j * f (c j) * s j x with hΦ
  set Ψ : ℝ → ℝ := fun x => M * x + ∑ j, |w j| * s j x with hΨ
  have key := rs_crit f G Φ Ψ a b ?_
  · convert key using 1
    have h1 : ∀ j, s j b = 1 := fun j => by simp [hs, (hc j).2]
    have h0 : ∀ j, s j a = 0 := fun j => by simp [hs, not_le.2 (hc j).1]
    simp only [hΦ, h1, h0, mul_one, mul_zero, Finset.sum_const_zero,
      intervalIntegral.integral_same, add_zero, sub_zero]
  · intro ε hε
    obtain ⟨δ, hδ, hδ'⟩ := Metric.uniformContinuousOn_iff.1
      (isCompact_Icc.uniformContinuousOn_of_continuous hf) ε hε
    refine ⟨δ, hδ, fun u ξ v hau huξ hξv hvb hvu => ?_⟩
    have huv : u ≤ v := huξ.trans hξv
    have hu : u ∈ Icc a b := ⟨hau, huv.trans hvb⟩
    have hv : v ∈ Icc a b := ⟨hau.trans huv, hvb⟩
    have hξ : ξ ∈ Icc a b := ⟨hau.trans huξ, hξv.trans hvb⟩
    have ha : a ∈ Icc a b := ⟨le_rfl, hau.trans (huv.trans hvb)⟩
    have hGs : G v - G u = (G₀ v - G₀ u) + ∑ j, w j * (s j v - s j u) := by
      rw [hsplit v hv, hsplit u hu]
      simp only [hs, mul_sub, Finset.sum_sub_distrib]
      ring
    have hG₀' : G₀ v - G₀ u = ∫ t in u..v, g t := by
      symm
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le huv
      · exact fun x hx => (hG₀ x ⟨hau.trans hx.1, hx.2.trans hvb⟩).continuousWithinAt.mono
          (Icc_subset_Icc hau hvb)
      · exact fun x hx => (hG₀ x ⟨hau.trans hx.1.le, hx.2.le.trans hvb⟩).hasDerivAt
          (Icc_mem_nhds (hau.trans_lt hx.1) (hx.2.trans_le hvb))
      · exact hintg u hu v hv
    have hΦ' : Φ v - Φ u = (∫ t in u..v, f t * g t) + ∑ j, w j * f (c j) * (s j v - s j u) := by
      simp only [hΦ]
      rw [← intervalIntegral.integral_interval_sub_left (hint a ha v hv) (hint a ha u hu)]
      simp only [mul_sub, Finset.sum_sub_distrib]
      ring
    have hA : (∫ t in u..v, (f t - f ξ) * g t)
        = (∫ t in u..v, f t * g t) - f ξ * ∫ t in u..v, g t := by
      simp only [sub_mul]
      rw [intervalIntegral.integral_sub (hint u hu v hv) ((hintg u hu v hv).const_mul (f ξ)),
        intervalIntegral.integral_const_mul]
    have hB : ∑ j, w j * (f (c j) - f ξ) * (s j v - s j u)
        = ∑ j, w j * f (c j) * (s j v - s j u) - f ξ * ∑ j, w j * (s j v - s j u) := by
      rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
      exact Finset.sum_congr rfl fun j _ => by ring
    have hE : Φ v - Φ u - f ξ * (G v - G u) = (∫ t in u..v, (f t - f ξ) * g t)
        + ∑ j, w j * (f (c j) - f ξ) * (s j v - s j u) := by
      rw [hΦ', hGs, hG₀', hA, hB]; ring
    have hAb : |∫ t in u..v, (f t - f ξ) * g t| ≤ ε * M * (v - u) := by
      have := intervalIntegral.norm_integral_le_of_norm_le_const (a := u) (b := v)
        (C := ε * M) (f := fun t => (f t - f ξ) * g t) ?_
      · rw [Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 huv)] at this
        exact this
      · intro t ht
        rw [uIoc_of_le huv] at ht
        have htm : t ∈ Icc a b := ⟨hau.trans ht.1.le, ht.2.trans hvb⟩
        have hd : dist (f t) (f ξ) < ε := hδ' t htm ξ hξ (by
          rw [Real.dist_eq, abs_lt]; constructor <;> linarith [ht.1, ht.2])
        rw [Real.dist_eq] at hd
        rw [norm_mul, Real.norm_eq_abs]
        exact mul_le_mul hd.le (hM t htm) (norm_nonneg _) hε.le
    have hBb : |∑ j, w j * (f (c j) - f ξ) * (s j v - s j u)|
        ≤ ε * ∑ j, |w j| * (s j v - s j u) := by
      rw [Finset.mul_sum]
      refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun j _ => ?_)
      simp only [hs]
      by_cases h1 : c j ≤ u
      · have h2 : c j ≤ v := h1.trans huv
        simp [h1, h2]
      · by_cases h2 : c j ≤ v
        · simp only [h1, h2, ↓reduceIte, sub_zero, mul_one, abs_mul]
          have hcm : c j ∈ Icc a b := ⟨(hc j).1.le, (hc j).2⟩
          have hd : dist (f (c j)) (f ξ) < ε := hδ' _ hcm ξ hξ (by
            rw [Real.dist_eq, abs_lt]; constructor <;> linarith [not_le.1 h1])
          rw [Real.dist_eq] at hd
          nlinarith [abs_nonneg (w j)]
        · have h1' : ¬ c j ≤ u := h1
          simp [h1', h2]
    have hΨ' : Ψ v - Ψ u = M * (v - u) + ∑ j, |w j| * (s j v - s j u) := by
      simp only [hΨ, mul_sub, Finset.sum_sub_distrib]; ring
    rw [hE, hΨ']
    calc _ ≤ |∫ t in u..v, (f t - f ξ) * g t| + |∑ j, w j * (f (c j) - f ξ) * (s j v - s j u)| :=
          abs_add_le _ _
      _ ≤ ε * M * (v - u) + ε * ∑ j, |w j| * (s j v - s j u) := add_le_add hAb hBb
      _ = _ := by ring

/-- The card's answer: the average payout, the Stieltjes integral of the payout `x` against the
share of contracts paying at most `x`, taken from -20 to 100, is $35 per contract. -/
theorem book_average_payout_is_35 :
    HasStieltjesIntegral (fun x => x) bookShare (-20) 100 35 := by
  have key := rs_crit (fun x => x) bookShare
    (fun x => if x < 0 then 0 else if x < 100 then x ^ 2 / 400 else 35)
    (fun x => 2 * bookShare x) (-20) 100 ?_
  · convert key using 1; norm_num
  · intro ε hε
    refine ⟨ε, hε, fun u ξ v hu huξ hξv hv hvu => ?_⟩
    simp only [bookShare]
    rw [abs_le]
    split_ifs <;> constructor <;>
      nlinarith [mul_nonneg (sub_nonneg.2 huξ) (sub_nonneg.2 hξv),
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) hε.le,
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) (sub_nonneg.2 huξ),
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) (sub_nonneg.2 hξv),
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) (sub_pos.2 hvu).le]

-- Counting: 400 + 500 + 100 = 1,000 contracts; 500 × $50 + 100 × $100 = $35,000, $35 each.
example : 400 + 500 + 100 = 1000 ∧ 500 * 50 + 100 * 100 = 35000 ∧ 35000 / 1000 = 35 := by
  decide
-- The integrator's chart: G at -20, 0, 20, 40, 60, 80, 100 is 0, 2/5, 1/2, 3/5, 7/10, 4/5, 1.
example : [-20, 0, 20, 40, 60, 80, 100].map bookShare = [0, 2 / 5, 1 / 2, 3 / 5, 7 / 10, 4 / 5, 1] := by
  norm_num [bookShare]
-- Total weight G(b) - G(a) = 1, the whole book.
example : bookShare 100 - bookShare (-20) = 1 := by norm_num [bookShare]
-- Worked numbers: smooth part 1/200 × 100 × 100 / 2 = 25; jumps 2/5 × 0 + 1/10 × 100 = 10;
-- average 25 + 0 + 10 = 35.
example : (1 / 200 : ℚ) * 100 * 100 / 2 = 25 ∧ (2 / 5 : ℚ) * 0 + 1 / 10 * 100 = 10 ∧
    (25 : ℚ) + 0 + 10 = 35 := by norm_num
-- 12 slices of $10, left tags: the lower sum is 55/2 (27.50).
example : stieltjesSum (fun x => x) bookShare 12 (evenCuts (-20) 100 12)
    (fun k => evenCuts (-20) 100 12 k.castSucc) = 55 / 2 := by
  norm_num [stieltjesSum, evenCuts, bookShare, Fin.sum_univ_succ]
-- 12 slices of $10, right tags: the upper sum is 75/2 (37.50).
example : stieltjesSum (fun x => x) bookShare 12 (evenCuts (-20) 100 12)
    (fun k => evenCuts (-20) 100 12 k.succ) = 75 / 2 := by
  norm_num [stieltjesSum, evenCuts, bookShare, Fin.sum_univ_succ]
-- The mistakes: lumps dropped gives 25; divided by the smooth weight 1/2 gives 50;
-- width instead of weight, 100 × 100 / 2, gives 5000.
example : (25 : ℚ) / (1 / 2) = 50 ∧ (100 : ℚ) * 100 / 2 = 5000 := by norm_num
-- The fee by counting: 600 of the 1,000 contracts pay something, 3/5 of a dollar each.
example : 400 + 500 + 100 - 400 = 600 ∧ (600 : ℚ) / 1000 = 3 / 5 := by norm_num

#print axioms continuous_has_stieltjes_integral_against_nondecreasing
#print axioms stieltjes_integral_rate_plus_jumps
#print axioms book_average_payout_is_35
