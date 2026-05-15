import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modalBackdrop", "modalTitle", "modalContent", "specialistSelect", "confirmButton"]

  openBulkModal(event) {
    event.preventDefault()
    this.showModal("Bulk Reassign")
  }

  openReassignModal(event) {
    event.preventDefault()
    const accountName = event.currentTarget.dataset.accountName
    const accountId = event.currentTarget.dataset.accountId
    const title = accountName ? `Assign Specialist to ${accountName}` : "Reassign Specialist"
    this.showModal(title, accountId)
  }

  showModal(title, accountId = null) {
    this.modalBackdropTarget.style.display = "flex"
    if (this.modalTitleTarget) {
      this.modalTitleTarget.innerHTML = `<i class="ri-git-branch-line"></i> ${title}`
    }
    if (accountId) {
      this.modalBackdropTarget.dataset.accountId = accountId
    } else {
      delete this.modalBackdropTarget.dataset.accountId
    }
    document.body.style.overflow = "hidden"
  }

  closeModal(event) {
    if (event) event.preventDefault()
    this.hideModal()
  }

  confirmReassign(event) {
    event.preventDefault()
    console.log("confirmReassign called")

    const selectedSpecialist = this.specialistSelectTarget?.value
    if (!selectedSpecialist) {
      alert("Please select a specialist.")
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const accountId = this.modalBackdropTarget?.dataset?.accountId

    if (accountId) {
      const form = document.createElement("form")
      form.method = "POST"
      form.action = "/admin/assignments"

      if (csrfToken) {
        const tokenInput = document.createElement("input")
        tokenInput.type = "hidden"
        tokenInput.name = "authenticity_token"
        tokenInput.value = csrfToken
        form.appendChild(tokenInput)
      }

      const specialistInput = document.createElement("input")
      specialistInput.type = "hidden"
      specialistInput.name = "specialist_id"
      specialistInput.value = selectedSpecialist
      form.appendChild(specialistInput)

      const accountInput = document.createElement("input")
      accountInput.type = "hidden"
      accountInput.name = "account_id"
      accountInput.value = accountId
      form.appendChild(accountInput)

      document.body.appendChild(form)
      console.log("Submitting single assignment...")
      form.submit()
      return
    }

    const assignmentIds = Array.from(document.querySelectorAll(".assignment-checkbox:checked")).map(cb => cb.value)
    console.log("Selected specialist:", selectedSpecialist, "Assignment IDs:", assignmentIds)

    if (assignmentIds.length === 0) {
      alert("Please select at least one patient to reassign.")
      return
    }

    const form = document.createElement("form")
    form.method = "POST"
    form.action = "/admin/assignments/bulk_reassign"

    if (csrfToken) {
      const tokenInput = document.createElement("input")
      tokenInput.type = "hidden"
      tokenInput.name = "authenticity_token"
      tokenInput.value = csrfToken
      form.appendChild(tokenInput)
    }

    const methodInput = document.createElement("input")
    methodInput.type = "hidden"
    methodInput.name = "_method"
    methodInput.value = "patch"
    form.appendChild(methodInput)

    const specialistInput = document.createElement("input")
    specialistInput.type = "hidden"
    specialistInput.name = "specialist_id"
    specialistInput.value = selectedSpecialist
    form.appendChild(specialistInput)

    assignmentIds.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "assignment_ids[]"
      input.value = id
      form.appendChild(input)
    })

    document.body.appendChild(form)
    console.log("Submitting form...")
    form.submit()
  }

  toggleAll(event) {
    const checked = event.target.checked
    document.querySelectorAll(".assignment-checkbox").forEach(cb => {
      cb.checked = checked
    })
    this.updateBulkCount()
  }

  updateBulkCount(event) {
    if (event) event.preventDefault()
    const checked = document.querySelectorAll(".assignment-checkbox:checked").length
    const countEl = document.getElementById("selected-count")
    if (countEl) {
      countEl.textContent = checked > 0 ? `${checked} selected` : ""
    }
  }

  hideModal() {
    this.modalBackdropTarget.style.display = "none"
    document.body.style.overflow = ""
  }
}