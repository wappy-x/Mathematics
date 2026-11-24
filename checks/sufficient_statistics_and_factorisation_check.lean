-- Sufficient statistics: for data with countably many possible lists, a statistic is sufficient exactly when the chance of the data factors as g(T(x); θ) h(x), the likelihood-ratio test gives a minimal sufficient statistic, and given its count of yeses each yes-or-no list has chance 1 / C(n, t).
import Mathlib.Probability.ProbabilityMassFunction.Constructions
import Mathlib.Data.Fintype.Pi
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.Powerset

open scoped ENNReal

universe u v w z

namespace SufficientStatistics

variable {Θ : Type u} {Ω : Type v} {τ : Type w}

/-- The data `X` take countably many possible values `Ω`; `P θ` is their chance law when the
unknown is `θ`, so `P θ x = f(x; θ)`. `(P θ).map T` is the chance law of the statistic `T`, and
`P θ x / (P θ).map T (T x)` is the chance of the list `x` given `T = T x`.
`T` is sufficient when this conditional chance is the same for every `θ` (wherever the value
`T x` has positive chance). -/
def IsSufficient (P : Θ → PMF Ω) (T : Ω → τ) : Prop :=
  ∀ θ θ' x, (P θ).map T (T x) ≠ 0 → (P θ').map T (T x) ≠ 0 →
    P θ x / (P θ).map T (T x) = P θ' x / (P θ').map T (T x)

/-- `T` is minimal sufficient when it is sufficient and is a function of every other sufficient
statistic `S`: lists with equal `S` have equal `T`. -/
def IsMinimalSufficient (P : Θ → PMF Ω) (T : Ω → τ) : Prop :=
  IsSufficient P T ∧
    ∀ (σ : Type z) (S : Ω → σ), IsSufficient P S → ∀ x y, S x = S y → T x = T y

/-- Each list has no more chance than the value of the statistic it gives. -/
theorem le_map_self (p : PMF Ω) (T : Ω → τ) (x : Ω) : p x ≤ p.map T (T x) := by
  classical
  rw [PMF.map_apply]
  refine le_trans ?_ (le_tsum _ x)
  simp

#print axioms le_map_self

/-- The Fisher-Neyman factorisation theorem, for data with countably many possible lists:
a statistic `T` is sufficient exactly when the chance of the data splits as
`f(x; θ) = g(T(x); θ) h(x)`, a piece that sees the data only through `T` times a piece that
never sees the unknown. -/
theorem sufficient_iff_factorisation [Countable Ω] (P : Θ → PMF Ω) (T : Ω → τ) :
    IsSufficient P T ↔
      ∃ (g : τ → Θ → ℝ≥0∞) (h : Ω → ℝ≥0∞), ∀ θ x, P θ x = g (T x) θ * h x := by
  classical
  constructor
  · intro hS
    refine ⟨fun t θ => (P θ).map T t, fun x =>
      if hx : ∃ θ, (P θ).map T (T x) ≠ 0 then
        P hx.choose x / (P hx.choose).map T (T x) else 0, ?_⟩
    intro θ x
    by_cases h0 : (P θ).map T (T x) = 0
    · have : P θ x = 0 := le_antisymm (h0 ▸ le_map_self (P θ) T x) bot_le
      simp [this, h0]
    · have hx : ∃ θ, (P θ).map T (T x) ≠ 0 := ⟨θ, h0⟩
      simp only [hx, ↓reduceDIte]
      rw [hS hx.choose θ x hx.choose_spec h0, ENNReal.mul_div_cancel h0 (PMF.apply_ne_top _ _)]
  · rintro ⟨g, h, hgh⟩
    have key : ∀ θ x,
        (P θ).map T (T x) = g (T x) θ * ∑' a, (if T x = T a then h a else 0) := by
      intro θ x
      rw [PMF.map_apply, ← ENNReal.tsum_mul_left]
      refine tsum_congr fun a => ?_
      split_ifs with ha
      · rw [hgh, ha]
      · simp
    have hdiv : ∀ θ x, (P θ).map T (T x) ≠ 0 →
        P θ x / (P θ).map T (T x) = h x / ∑' a, (if T x = T a then h a else 0) := by
      intro θ x hne
      have hk := key θ x
      rw [hk] at hne
      have hg0 : g (T x) θ ≠ 0 := left_ne_zero_of_mul hne
      have hgt : g (T x) θ ≠ ⊤ := by
        intro htop
        have hH : (∑' a, (if T x = T a then h a else 0)) ≠ 0 := right_ne_zero_of_mul hne
        have := PMF.apply_ne_top ((P θ).map T) (T x)
        rw [hk, htop, ENNReal.top_mul hH] at this
        exact this rfl
      rw [hk, hgh θ x, ENNReal.mul_div_mul_left _ _ hg0 hgt]
    intro θ θ' x h1 h2
    rw [hdiv θ x h1, hdiv θ' x h2]

/-- The likelihood-ratio test for minimal sufficiency, working with lists of positive chance:
if two lists share the value of `T` exactly when the ratio `f(x; θ) / f(y; θ)` of their
likelihoods does not depend on `θ`, then `T` is minimal sufficient. -/
theorem minimal_sufficient_of_likelihood_ratio [Countable Ω] (P : Θ → PMF Ω) (T : Ω → τ)
    (hpos : ∀ θ x, P θ x ≠ 0)
    (hT : ∀ x y, T x = T y ↔ ∀ θ θ', P θ x / P θ y = P θ' x / P θ' y) :
    IsMinimalSufficient.{u, v, w, z} P T := by
  classical
  refine ⟨?_, ?_⟩
  · rcases isEmpty_or_nonempty Θ with hΘ | ⟨⟨θ₀⟩⟩
    · intro θ
      exact isEmptyElim θ
    rw [sufficient_iff_factorisation]
    refine ⟨fun t θ => if ht : ∃ x, T x = t then P θ ht.choose else 0,
      fun x => P θ₀ x / P θ₀ (Classical.choose (⟨x, rfl⟩ : ∃ y, T y = T x)), ?_⟩
    intro θ x
    have ht : ∃ y, T y = T x := ⟨x, rfl⟩
    simp only [ht, ↓reduceDIte]
    have hr := (hT x ht.choose).mp ht.choose_spec.symm θ₀ θ
    rw [hr, ENNReal.mul_div_cancel (hpos θ _) (PMF.apply_ne_top _ _)]
  · intro σ S hS x y hxy
    rw [hT]
    obtain ⟨g, h, hgh⟩ := (sufficient_iff_factorisation P S).mp hS
    have hfac : ∀ θ, P θ x / P θ y = h x / h y := by
      intro θ
      have hy := hpos θ y
      rw [hgh θ y] at hy
      have hg0 : g (S y) θ ≠ 0 := left_ne_zero_of_mul hy
      have hgt : g (S y) θ ≠ ⊤ := by
        intro htop
        have hh : h y ≠ 0 := right_ne_zero_of_mul hy
        have := PMF.apply_ne_top (P θ) y
        rw [hgh θ y, htop, ENNReal.top_mul hh] at this
        exact this rfl
      rw [hgh θ x, hgh θ y, hxy, ENNReal.mul_div_mul_left _ _ hg0 hgt]
    intro θ θ'
    rw [hfac θ, hfac θ']

/-- The chance of one yes-or-no list `x` of `n` independent answers, each a yes with chance `p`. -/
noncomputable def listChance {n : ℕ} (p : ℝ) (x : Fin n → Bool) : ℝ :=
  ∏ i, if x i then p else 1 - p

/-- The number of yeses in the list `x`. -/
def yesCount {n : ℕ} (x : Fin n → Bool) : ℕ :=
  (Finset.univ.filter (fun i => x i = true)).card

/-- A list's chance depends only on its count of yeses. -/
theorem listChance_eq_pow {n : ℕ} (p : ℝ) (x : Fin n → Bool) :
    listChance p x = p ^ yesCount x * (1 - p) ^ (n - yesCount x) := by
  unfold listChance yesCount
  rw [Finset.prod_ite, Finset.prod_const, Finset.prod_const]
  congr 2
  have := Finset.card_filter_add_card_filter_not (s := (Finset.univ : Finset (Fin n)))
    (fun i => x i = true)
  rw [Finset.card_univ, Fintype.card_fin] at this
  omega

#print axioms listChance_eq_pow

/-- Exactly `C(n, t)` lists of `n` answers hold `t` yeses. -/
theorem card_yesCount_eq (n t : ℕ) :
    (Finset.univ.filter (fun y : Fin n → Bool => yesCount y = t)).card = n.choose t := by
  have hc : (Finset.powersetCard t (Finset.univ : Finset (Fin n))).card = n.choose t := by
    rw [Finset.card_powersetCard, Finset.card_univ, Fintype.card_fin]
  rw [← hc]
  refine Finset.card_nbij' (fun y => Finset.univ.filter (fun i => y i = true))
    (fun s i => decide (i ∈ s)) ?_ ?_ ?_ ?_
  · intro y hy
    simp only [Finset.coe_filter, Finset.mem_univ, true_and] at hy
    simp only [Finset.mem_coe, Finset.mem_powersetCard]
    exact ⟨Finset.subset_univ _, hy⟩
  · intro s hs
    simp only [Finset.mem_coe, Finset.mem_powersetCard] at hs
    simp only [Finset.coe_filter, Finset.mem_univ, true_and]
    show yesCount _ = t
    simpa [yesCount] using hs.2
  · intro y _
    funext i
    simp
  · intro s _
    ext i
    simp

#print axioms card_yesCount_eq

/-- The poll: given its count of `t` yeses among `n` answers, each list has chance
`1 / C(n, t)`, whatever the true share `p` is, so the count is sufficient. -/
theorem poll_list_given_count {n : ℕ} (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (x : Fin n → Bool) :
    listChance p x /
        ∑ y ∈ Finset.univ.filter (fun y : Fin n → Bool => yesCount y = yesCount x), listChance p y =
      1 / (n.choose (yesCount x) : ℝ) := by
  have hsum : ∑ y ∈ Finset.univ.filter (fun y : Fin n → Bool => yesCount y = yesCount x),
      listChance p y = (n.choose (yesCount x) : ℝ) * listChance p x := by
    rw [Finset.sum_congr rfl (g := fun _ => listChance p x), Finset.sum_const,
      card_yesCount_eq, nsmul_eq_mul]
    intro y hy
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hy
    rw [listChance_eq_pow, listChance_eq_pow, hy]
  have hpos : listChance p x ≠ 0 := by
    rw [listChance_eq_pow]
    have : 0 < 1 - p := by linarith
    positivity
  rw [hsum, div_mul_cancel_right₀ hpos, one_div]

-- The poll in miniature: 7 yeses can fall among 10 answers in C(10, 7) = 120 orders.
example : Nat.choose 10 7 = 120 := by decide

-- There are 2 ^ 10 = 1,024 possible lists of 10 answers.
example : Fintype.card (Fin 10 → Bool) = 1024 := by simp

-- One list given the count 7, at p = 0.52: p^7 (1 - p)^3 / (120 p^7 (1 - p)^3) = 1/120.
example : ((52 / 100 : ℚ) ^ 7 * (48 / 100) ^ 3) / (120 * ((52 / 100) ^ 7 * (48 / 100) ^ 3)) = 1 / 120 := by
  norm_num

-- The same at p = 0.3.
example : ((3 / 10 : ℚ) ^ 7 * (7 / 10) ^ 3) / (120 * ((3 / 10) ^ 7 * (7 / 10) ^ 3)) = 1 / 120 := by
  norm_num

-- Brute force over all 1,024 lists: exactly 120 of them hold 7 yeses.
example : (Finset.univ.filter (fun y : Fin 10 → Bool => yesCount y = 7)).card = 120 := by
  decide +kernel

-- The whole list keeps n / (p (1 - p)) = 10 / (0.7 × 0.3) = 1000/21 units of information.
example : (10 : ℚ) / ((7 / 10) * (3 / 10)) = 1000 / 21 := by norm_num

-- The shuttle at θ = 5: the likelihood θ^-3 is 1/125.
example : ((5 : ℚ) ^ 3)⁻¹ = 1 / 125 := by norm_num

#print axioms sufficient_iff_factorisation
#print axioms minimal_sufficient_of_likelihood_ratio
#print axioms poll_list_given_count

end SufficientStatistics
