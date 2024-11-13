import StatMech.Hamiltonian

noncomputable section
namespace MicroHamiltonian

variable {D : Type} (H : MicroHamiltonian D) (d : D)

/-- The partition function corresponding to a given MicroHamiltonian. This is a function taking a thermodynamic β, not a temperature.
It also depends on the data D defining the system extrinsincs.

 * Ideally this would be an NNReal, but ∫ (NNReal) doesn't work right now, so it would just be a separate proof anyway
-/
def PartitionZ (β : ℝ) : ℝ :=
  ∫ (config : H.dim d → ℝ),
    let E := H.H config
    if h : E = ⊤ then 0 else Real.exp (-β * (E.untop h))

/-- The partition function as a function of temperature T instead of β. -/
def PartitionZT (T : ℝ) : ℝ :=
  PartitionZ H d (1/T)

/-- The Internal Energy, U or E, defined as -∂(ln Z)/∂β. Parameterized here with β. -/
def InternalU (β : ℝ) : ℝ :=
  -deriv (fun β' ↦ (PartitionZ H d β').log) β

/-- The Helmholtz Free Energy, -T * ln Z. Also denoted F. Parameterized here with temperature T, not β. -/
def HelmholtzA (T : ℝ) : ℝ :=
  -T * (PartitionZT H d T).log

/-- The entropy, defined as the -∂A/∂T. Function of T. -/
def EntropyS (T : ℝ) : ℝ :=
  -deriv (HelmholtzA H d) T

/-- The entropy, defined as ln Z + β*U. Function of β. -/
def EntropySβ (β : ℝ) : ℝ :=
  (PartitionZ H d β).log + β * InternalU H d β

/-- To be able to compute or define anything from a Hamiltonian, we need its partition function to be
a computable integral. A Hamiltonian is ZIntegrable at β if PartitionZ is Lesbegue integrable and nonzero.
-/
def ZIntegrable (β : ℝ) : Prop :=
  MeasureTheory.Integrable (fun (config : H.dim d → ℝ) ↦
    let E := H.H config;
    if h : E = ⊤ then 0 else Real.exp (-β * (E.untop h))
  ) ∧ (H.PartitionZ d β ≠ 0)

/--
This Prop defines the most common case of ZIntegrable, that it is integrable at all finite temperatures
(aka all positive β).
-/
def PositiveβIntegrable : Prop :=
  ∀ β > 0, H.ZIntegrable d β

/-
Need the fact that the partition function Z is differentiable. Assume it's integrable.
Letting μ⁻(H,E) be the measure of {x | H(x) ≤ E}, then for nonzero β,
∫_0..∞ exp(-βE) (dμ⁻/dE) dE =
∫ exp(-βH) dμ =
∫ (1/β * ∫_H..∞ exp(-βE) dE) dμ =
∫ (1/β * ∫_-∞..∞ exp(-βE) χ(E ≤ H) dE) dμ =
1/β * ∫ (∫ exp(-βE) χ(E ≤ H) dμ) dE =
1/β * ∫ exp(-βE) * μ⁻(H,E) dE

so this will be differentiable if
∫ exp(-βE) * μ⁻(H,E) dE
is, aka if the Laplace transform is differentiable.
See e.g. https://math.stackexchange.com/q/84382/127777
For this we really want the fact that the Laplace transform is analytic wherever it's absolutely convergent,
which is (as Wikipedia informs) an easy consequence of Fubini's theorem + Morera's theorem. However, Morera's
theorem isn't in mathlib yet. So this is a sorry for now
-/
variable {H d} in
theorem DifferentiableAt_Z_if_ZIntegrable {β : ℝ} (h : H.ZIntegrable d β) : ContDiffAt ℝ ⊤ (H.PartitionZ d) β :=
  sorry

/-- The two definitions of entropy, in terms of T or β, are equivalent. -/
theorem entropy_A_eq_entropy_Z (T β : ℝ) (hβT : T * β = 1) (hi : H.ZIntegrable d β)
    : EntropyS H d T = EntropySβ H d β := by
  have hTnz : T ≠ 0 := left_ne_zero_of_mul_eq_one hβT
  have hβnz : β ≠ 0 := right_ne_zero_of_mul_eq_one hβT
  have hβT' := eq_one_div_of_mul_eq_one_right hβT
  dsimp [EntropyS, EntropySβ, InternalU, PartitionZT]
  unfold HelmholtzA
  rw [deriv_mul, deriv_neg'', neg_mul, one_mul, neg_add_rev, neg_neg, mul_neg, add_comm]
  congr 1
  · rw [PartitionZT, hβT']
  simp_rw [PartitionZT]
  have hdc := deriv.comp (h := fun T ↦ T⁻¹) (h₂ := fun β => Real.log (H.PartitionZ d β)) T ?_ ?_
  unfold Function.comp at hdc
  simp only [hdc, one_div, deriv_inv', mul_neg, neg_inj, hβT']
  field_simp
  ring_nf
  --Show the differentiability side-goals
  · eta_reduce
    rw [← one_div, ← hβT']
    have := hi.2
    have := DifferentiableAt_Z_if_ZIntegrable hi
    have := OrderTop.le_top (1 : ℕ∞)
    fun_prop (disch := assumption)
  · fun_prop (disch := assumption)
  · fun_prop
  · simp_rw [PartitionZT]
    rw [hβT'] at hi
    have := hi.2
    have := DifferentiableAt_Z_if_ZIntegrable hi
    have := OrderTop.le_top (1 : ℕ∞)
    fun_prop (disch := assumption)

/--
The "definition of temperature from entropy":
1/T = (∂S/∂U), when the derivative is at constant extrinsic d (typically N/V).
Here we use β instead of 1/T on the left, and express the right actually as (∂S/∂β)/(∂U/∂β),
as all our things are ultimately parameterized by β.
-/
theorem β_eq_deriv_S_U {β : ℝ} (hi : H.ZIntegrable d β) : β = (deriv (H.EntropySβ d) β) / deriv (H.InternalU d) β := by
  unfold EntropySβ
  unfold InternalU
  simp only [mul_neg, deriv.neg']
  rw [deriv_add]
  simp only [deriv.neg', differentiableAt_id']
  rw [deriv_mul]
  simp only [deriv_id'', one_mul, neg_add_rev, add_neg_cancel_comm_assoc, neg_div_neg_eq]
  have : deriv (deriv fun β => Real.log (H.PartitionZ d β)) β ≠ 0 := ?_
  exact (mul_div_cancel_right₀ β this).symm
  · sorry
  · fun_prop
  · have := DifferentiableAt_Z_if_ZIntegrable hi
    replace this := ContDiffAt.log this hi.2
    replace this :=
      (this.fderiv_right (m := ⊤) (OrderTop.le_top _)).differentiableAt (OrderTop.le_top _)
    unfold deriv
    convert this
    sorry
  · have := hi.2
    have := DifferentiableAt_Z_if_ZIntegrable hi
    have := OrderTop.le_top (1 : ℕ∞)
    fun_prop (disch := assumption)
  · sorry

end MicroHamiltonian

--! Specializing to a system of particles in space

namespace NVEHamiltonian
open MicroHamiltonian

variable (H : NVEHamiltonian) (d : ℕ × ℝ)

/-- Pressure, as a function of T. Defined as the conjugate variable to volume. -/
def Pressure (T : ℝ) : ℝ :=
  let (n, V) := d;
  -deriv (fun V' ↦ HelmholtzA H (n, V') T) V

end NVEHamiltonian