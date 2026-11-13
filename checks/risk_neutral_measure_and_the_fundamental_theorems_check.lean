-- The fundamental theorems: in a one-period market with a bank account and finitely many futures, no arbitrage holds exactly when a pricing measure with every weight above zero exists, and then every payoff can be copied exactly when that measure is unique.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Analysis.Convex.StdSimplex
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Tactic

open Finset

namespace FundamentalTheorems

variable {Ω ι : Type*} [Fintype Ω] [Fintype ι]

/-- The market: `X i j` is what one unit of traded asset `i` pays in future `j`, `S i` is its
price today, and the bank account pays 1 in every future for `exp (-r * T)` today.
A portfolio holds `θ i` units of asset `i` and `b` units of the bank account.
Its cost today, with no fees and one price to buy and sell: -/
noncomputable def cost (S : ι → ℝ) (r T : ℝ) (θ : ι → ℝ) (b : ℝ) : ℝ :=
  b * Real.exp (-r * T) + ∑ i, θ i * S i

/-- What the portfolio pays in future `j`. -/
def payoff (X : ι → Ω → ℝ) (θ : ι → ℝ) (b : ℝ) (j : Ω) : ℝ :=
  b + ∑ i, θ i * X i j

/-- An arbitrage (free money): put on today for nothing or for a credit, never pays anything
negative, and pays something positive in at least one future. -/
def IsArbitrage (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (θ : ι → ℝ) (b : ℝ) : Prop :=
  cost S r T θ b ≤ 0 ∧ (∀ j, 0 ≤ payoff X θ b j) ∧ ∃ j, 0 < payoff X θ b j

/-- No portfolio is an arbitrage. -/
def NoArbitrage (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) : Prop :=
  ∀ θ b, ¬ IsArbitrage X S r T θ b

/-- A pricing measure: weights on the futures, every one strictly above zero, adding to one,
under which every traded price is its discounted average payoff. -/
def IsPricingMeasure (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (π : Ω → ℝ) : Prop :=
  (∀ j, 0 < π j) ∧ ∑ j, π j = 1 ∧ ∀ i, S i = Real.exp (-r * T) * ∑ j, π j * X i j

/-- A complete market: every payoff can be copied by some portfolio. -/
def IsComplete (X : ι → Ω → ℝ) : Prop :=
  ∀ f : Ω → ℝ, ∃ θ b, ∀ j, payoff X θ b j = f j

theorem copy_cost_aux
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (π : Ω → ℝ)
    (hπ : IsPricingMeasure X S r T π) (f : Ω → ℝ) (θ : ι → ℝ) (b : ℝ)
    (hcopy : ∀ j, payoff X θ b j = f j) :
    cost S r T θ b = Real.exp (-r * T) * ∑ j, π j * f j := by
  obtain ⟨-, hsum, hS⟩ := hπ
  have hf : f = fun j => b + ∑ i, θ i * X i j := funext fun j => (hcopy j).symm
  subst hf
  unfold cost
  simp only [hS, mul_add, sum_add_distrib, mul_sum]
  have h1 : ∑ j, Real.exp (-r * T) * (π j * b) = b * Real.exp (-r * T) := by
    rw [← mul_sum, ← sum_mul, hsum]; ring
  rw [h1, Finset.sum_comm (s := univ) (t := univ)
    (f := fun j i => Real.exp (-r * T) * (π j * (θ i * X i j)))]
  congr 1
  refine sum_congr rfl fun i _ => sum_congr rfl fun j _ => by ring

theorem noArb_of_pricing
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (π : Ω → ℝ)
    (hπ : IsPricingMeasure X S r T π) : NoArbitrage X S r T := by
  rintro θ b ⟨hc, hnn, j0, hj0⟩
  have h := copy_cost_aux X S r T π hπ (payoff X θ b) θ b (fun _ => rfl)
  have hpos : 0 < ∑ j, π j * payoff X θ b j :=
    Finset.sum_pos' (fun j _ => mul_nonneg (hπ.1 j).le (hnn j))
      ⟨j0, mem_univ _, mul_pos (hπ.1 j0) hj0⟩
  have := mul_pos (Real.exp_pos (-r * T)) hpos
  linarith

theorem pricing_of_noArb [Nonempty Ω]
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (hNA : NoArbitrage X S r T) :
    ∃ π : Ω → ℝ, IsPricingMeasure X S r T π := by
  classical
  set d := Real.exp (-r * T) with hd
  have hd0 : 0 < d := Real.exp_pos _
  let g : ι → Ω → ℝ := fun i j => X i j - S i / d
  let W : Submodule ℝ (Ω → ℝ) := Submodule.span ℝ (Set.range g)
  have hdisj : Disjoint (stdSimplex ℝ Ω) (W : Set (Ω → ℝ)) := by
    refine Set.disjoint_left.2 fun x hx hxW => ?_
    obtain ⟨c, hc⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).1 hxW
    have hpay : ∀ j, payoff X c (-(∑ i, c i * S i) / d) j = x j := by
      intro j
      rw [← hc]
      simp only [payoff, Finset.sum_apply, Pi.smul_apply, smul_eq_mul, g, mul_sub,
        sum_sub_distrib, sum_div, ← sum_neg_distrib, neg_div]
      rw [sum_neg_distrib]
      rw [show ∑ x, c x * (S x / d) = ∑ x, c x * S x / d from
        sum_congr rfl fun _ _ => by ring]
      ring
    apply hNA c (-(∑ i, c i * S i) / d)
    refine ⟨?_, ?_, ?_⟩
    · unfold cost
      rw [div_mul_cancel₀ _ hd0.ne']
      simp
    · intro j; rw [hpay]; exact hx.1 j
    · by_contra hcon
      push_neg at hcon
      have h1 : ∑ j, x j ≤ 0 := sum_nonpos fun j _ => by rw [← hpay]; exact hcon j
      have := hx.2
      linarith
  have hcpt : IsCompact (stdSimplex ℝ Ω) :=
    IsCompact.of_isClosed_subset isCompact_Icc (isClosed_stdSimplex ℝ Ω) (stdSimplex_subset_Icc ℝ)
  obtain ⟨f, u, v, hu, huv, hv⟩ := geometric_hahn_banach_compact_closed
    (convex_stdSimplex ℝ Ω) hcpt (Submodule.convex W) W.closed_of_finiteDimensional hdisj
  have hv0 : v < 0 := by have := hv 0 W.zero_mem; simpa using this
  have hfW : ∀ w ∈ W, f w = 0 := by
    intro w hw
    by_contra hne
    have := hv (((v - 1) / f w) • w) (W.smul_mem _ hw)
    rw [map_smul, smul_eq_mul, div_mul_cancel₀ _ hne] at this
    linarith
  let y : Ω → ℝ := fun j => -f (fun k => if j = k then 1 else 0)
  have hy : ∀ j, 0 < y j := by
    intro j
    have hmem : (fun k => if j = k then (1:ℝ) else 0) ∈ stdSimplex ℝ Ω :=
      ⟨fun k => by show 0 ≤ (if j = k then (1:ℝ) else 0); split_ifs <;> norm_num, by simp⟩
    have := hu _ hmem
    simp only [y]; linarith
  have hf : ∀ x : Ω → ℝ, f x = -∑ j, x j * y j := by
    intro x
    have := LinearMap.pi_apply_eq_sum_univ (f : (Ω → ℝ) →ₗ[ℝ] ℝ) x
    simp only [ContinuousLinearMap.coe_coe] at this
    rw [this, ← sum_neg_distrib]
    refine sum_congr rfl fun j _ => ?_
    simp [y, smul_eq_mul]
  have hgi : ∀ i, ∑ j, X i j * y j = S i / d * ∑ j, y j := by
    intro i
    have h0 := hfW (g i) (Submodule.subset_span ⟨i, rfl⟩)
    rw [hf] at h0
    simp only [g, sub_mul, sum_sub_distrib, ← mul_sum] at h0
    linarith
  set Y := ∑ j, y j with hY
  have hY0 : 0 < Y := Finset.sum_pos (fun j _ => hy j) univ_nonempty
  refine ⟨fun j => y j / Y, fun j => div_pos (hy j) hY0, ?_, fun i => ?_⟩
  · rw [← sum_div, div_self hY0.ne']
  · have : ∑ j, y j / Y * X i j = (∑ j, X i j * y j) / Y := by
      rw [sum_div]; exact sum_congr rfl fun j _ => by ring
    rw [this, hgi i]
    field_simp
    rw [hd]; ring_nf

theorem perturb_pricing
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (π : Ω → ℝ)
    (hπ : IsPricingMeasure X S r T π) (z : Ω → ℝ) (hz1 : ∑ j, z j = 0)
    (hzX : ∀ i, ∑ j, z j * X i j = 0) :
    ∃ ε : ℝ, 0 < ε ∧ IsPricingMeasure X S r T (fun j => π j + ε * z j) := by
  obtain ⟨hpos, hsum, hS⟩ := hπ
  set K := ∑ k, |z k| / π k with hK
  have hK0 : 0 ≤ K := sum_nonneg fun k _ => div_nonneg (abs_nonneg _) (hpos k).le
  refine ⟨1 / (K + 1), by positivity, fun j => ?_, ?_, fun i => ?_⟩
  · have hj : |z j| / π j ≤ K :=
      single_le_sum (f := fun k => |z k| / π k)
        (fun k _ => div_nonneg (abs_nonneg _) (hpos k).le) (mem_univ j)
    have hpj := hpos j
    have h1 : |z j| ≤ K * π j := by rwa [div_le_iff₀ hpj] at hj
    have h2 : -|z j| ≤ z j := neg_abs_le _
    have hK1 : 0 < K + 1 := by linarith
    show 0 < π j + 1 / (K + 1) * z j
    rw [show π j + 1 / (K + 1) * z j = (π j * (K + 1) + z j) / (K + 1) by field_simp]
    apply div_pos _ hK1
    nlinarith
  · rw [sum_add_distrib, ← mul_sum, hsum, hz1]; ring
  · rw [hS i]
    congr 1
    simp only [add_mul, sum_add_distrib, mul_assoc, ← mul_sum, hzX i]
    ring

theorem mix_pricing
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (π₁ π₂ : Ω → ℝ)
    (h₁ : IsPricingMeasure X S r T π₁) (h₂ : IsPricingMeasure X S r T π₂)
    (t : ℝ) (ht0 : 0 < t) (ht1 : t ≤ 1) :
    IsPricingMeasure X S r T (fun j => π₁ j + t * (π₂ j - π₁ j)) := by
  obtain ⟨p₁, s₁, e₁⟩ := h₁
  obtain ⟨p₂, s₂, e₂⟩ := h₂
  refine ⟨fun j => ?_, ?_, fun i => ?_⟩
  · show 0 < π₁ j + t * (π₂ j - π₁ j)
    have := p₁ j; have := p₂ j
    nlinarith [mul_nonneg (sub_nonneg.2 ht1) (p₁ j).le, mul_pos ht0 (p₂ j)]
  · rw [sum_add_distrib, ← mul_sum, sum_sub_distrib, s₁, s₂]; ring
  · have : ∑ j, (π₁ j + t * (π₂ j - π₁ j)) * X i j
        = ∑ j, π₁ j * X i j + t * (∑ j, π₂ j * X i j - ∑ j, π₁ j * X i j) := by
      rw [← sum_sub_distrib, mul_sum, ← sum_add_distrib]
      exact sum_congr rfl fun j _ => by ring
    rw [this, mul_add, mul_left_comm, mul_sub, ← e₁, ← e₂]; ring

#print axioms copy_cost_aux
#print axioms noArb_of_pricing
#print axioms pricing_of_noArb
#print axioms perturb_pricing
#print axioms mix_pricing

/-- First fundamental theorem (finitely many futures): there is no free money exactly when
some pricing measure exists, with every weight strictly above zero, adding to one, that prices
every traded asset as its payoff averaged over the weights and discounted at the bank rate. -/
theorem no_arbitrage_iff_exists_pricing_measure [Nonempty Ω]
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) :
    NoArbitrage X S r T ↔ ∃ π : Ω → ℝ, IsPricingMeasure X S r T π := by
  exact ⟨pricing_of_noArb X S r T, fun ⟨π, hπ⟩ => noArb_of_pricing X S r T π hπ⟩

/-- Second fundamental theorem (finitely many futures): once at least one pricing measure
exists, every payoff can be copied by trading exactly when there is exactly one pricing measure. -/
theorem complete_iff_unique_pricing_measure
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ)
    (h : ∃ π : Ω → ℝ, IsPricingMeasure X S r T π) :
    IsComplete X ↔ ∃! π : Ω → ℝ, IsPricingMeasure X S r T π := by
  classical
  constructor
  · intro hc
    obtain ⟨π, hπ⟩ := h
    refine ⟨π, hπ, fun π' hπ' => funext fun j => ?_⟩
    obtain ⟨θ, b, hθ⟩ := hc (fun k => if k = j then 1 else 0)
    have h1 := copy_cost_aux X S r T π hπ _ θ b hθ
    have h2 := copy_cost_aux X S r T π' hπ' _ θ b hθ
    rw [h1] at h2
    simp only [mul_ite, mul_one, mul_zero, sum_ite_eq', mem_univ, if_true] at h2
    exact (mul_left_cancel₀ (Real.exp_pos (-r * T)).ne' h2).symm
  · rintro ⟨π, hπ, huniq⟩
    by_contra hnc
    let W : Submodule ℝ (Ω → ℝ) :=
      Submodule.span ℝ (insert (fun _ => (1:ℝ)) (Set.range X))
    have hW : W ≠ ⊤ := by
      intro hW
      apply hnc
      intro f
      have hf : f ∈ W := hW ▸ Submodule.mem_top
      obtain ⟨a, z, hz, rfl⟩ := Submodule.mem_span_insert.1 hf
      obtain ⟨c, rfl⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).1 hz
      exact ⟨c, a, fun j => by simp [payoff, Finset.sum_apply]⟩
    obtain ⟨φ, hφ0, hle⟩ := W.exists_le_ker_of_lt_top (lt_top_iff_ne_top.2 hW)
    let z : Ω → ℝ := fun j => φ (fun k => if j = k then 1 else 0)
    have hφ : ∀ x, φ x = ∑ j, x j * z j := fun x => by
      rw [LinearMap.pi_apply_eq_sum_univ φ x]
      simp [z, smul_eq_mul]
    have hz1 : ∑ j, z j = 0 := by
      have := hle (Submodule.subset_span (Set.mem_insert _ _))
      rw [LinearMap.mem_ker, hφ] at this
      simpa using this
    have hzX : ∀ i, ∑ j, z j * X i j = 0 := by
      intro i
      have := hle (Submodule.subset_span (Set.mem_insert_of_mem _ ⟨i, rfl⟩))
      rw [LinearMap.mem_ker, hφ] at this
      rw [← this]
      exact sum_congr rfl fun j _ => mul_comm _ _
    have hz0 : ∃ j, z j ≠ 0 := by
      by_contra hcon
      push_neg at hcon
      exact hφ0 (LinearMap.ext fun x => by simp [hφ, hcon])
    obtain ⟨j0, hj0⟩ := hz0
    obtain ⟨ε, hε, hpr⟩ := perturb_pricing X S r T π hπ z hz1 hzX
    have := congrFun (huniq _ hpr) j0
    simp only [add_eq_left, mul_eq_zero] at this
    rcases this with h | h
    · exact hε.ne' h
    · exact hj0 h

/-- The price of a copyable payoff: under any pricing measure, what a portfolio copying the
payoff costs today equals that payoff averaged over the weights and discounted at the bank rate. -/
theorem copy_cost_eq_discounted_average
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ) (π : Ω → ℝ)
    (hπ : IsPricingMeasure X S r T π) (f : Ω → ℝ) (θ : ι → ℝ) (b : ℝ)
    (hcopy : ∀ j, payoff X θ b j = f j) :
    cost S r T θ b = Real.exp (-r * T) * ∑ j, π j * f j := by
  exact copy_cost_aux X S r T π hπ f θ b hcopy

/-- When the pricing measure is not unique, there are infinitely many: the alternative to one
measure is never two. -/
theorem pricing_measures_infinite_of_not_unique
    (X : ι → Ω → ℝ) (S : ι → ℝ) (r T : ℝ)
    (h : ∃ π : Ω → ℝ, IsPricingMeasure X S r T π)
    (hnot : ¬ ∃! π : Ω → ℝ, IsPricingMeasure X S r T π) :
    {π : Ω → ℝ | IsPricingMeasure X S r T π}.Infinite := by
  obtain ⟨π₁, h₁⟩ := h
  obtain ⟨π₂, h₂, hne⟩ : ∃ π₂, IsPricingMeasure X S r T π₂ ∧ π₂ ≠ π₁ := by
    by_contra hcon
    push_neg at hcon
    exact hnot ⟨π₁, h₁, fun π hπ => hcon π hπ⟩
  obtain ⟨j0, hj0⟩ := Function.ne_iff.1 hne
  let F : ℕ → Ω → ℝ := fun n j => π₁ j + (1 / ((n:ℝ) + 1)) * (π₂ j - π₁ j)
  refine Set.infinite_of_injective_forall_mem (f := F) ?_ fun n => ?_
  · intro n m hnm
    have h := congrFun hnm j0
    simp only [F, add_right_inj] at h
    have hd : π₂ j0 - π₁ j0 ≠ 0 := sub_ne_zero.2 hj0
    have h' := mul_right_cancel₀ hd h
    have hn : (0:ℝ) < (n:ℝ) + 1 := by positivity
    have hm : (0:ℝ) < (m:ℝ) + 1 := by positivity
    field_simp at h'
    exact_mod_cast (by linarith : (n:ℝ) = m)
  · exact mix_pricing X S r T π₁ π₂ h₁ h₂ _ (by positivity)
      (by rw [div_le_one (by positivity)]; have := n.cast_nonneg (α := ℝ); linarith)

-- The card's three-ending market: Acme ends at 80, 100 or 125. The nudge (5, -9, 4) leaves
-- the sum of the weights unchanged and the average end price unchanged.
example : (5 : ℤ) + (-9) + 4 = 0 := by decide
example : (5 : ℤ) * 80 + (-9) * 100 + 4 * 125 = 0 := by decide
-- The claim paying 10 only if Acme ends at 100 scores -90 against the nudge, so it is not copyable.
example : (5 : ℤ) * 0 + (-9) * 10 + 4 * 0 = -90 := by decide

-- The two-ending market (80 or 125): 10/45 shares and -(10/45) * 80 in cash copy the claim
-- paying 10 at 125 and nothing at 80.
example : (10 / 45 : ℚ) * 80 + (-(10 / 45) * 80) = 0 := by norm_num
example : (10 / 45 : ℚ) * 125 + (-(10 / 45) * 80) = 10 := by norm_num

#print axioms no_arbitrage_iff_exists_pricing_measure
#print axioms complete_iff_unique_pricing_measure
#print axioms copy_cost_eq_discounted_average
#print axioms pricing_measures_infinite_of_not_unique

end FundamentalTheorems
