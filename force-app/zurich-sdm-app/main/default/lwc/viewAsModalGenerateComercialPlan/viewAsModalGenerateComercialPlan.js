import { wire } from "lwc";
import LightningModal from "lightning/modal";
import userId from "@salesforce/user/Id";
import getSDMUsersList from "@salesforce/apex/ViewAsModalGeneratePlanController.getSDMUsersList";

// custom label
import SDM_PlanAnual_ButtonCancel from "@salesforce/label/c.SDM_PlanAnual_ButtonCancel";
import SDM_PlanAnual_ViewAsModalSubmit from "@salesforce/label/c.SDM_PlanAnual_ViewAsModalSubmit";
import SDM_PlanAnual_ViewAsModalFilterUsers from "@salesforce/label/c.SDM_PlanAnual_ViewAsModalFilterUsers";
import SDM_PlanAnual_ViewAsModalChangeUser from "@salesforce/label/c.SDM_PlanAnual_ViewAsModalChangeUser";

export default class ViewAsModalGenerateComercialPlan extends LightningModal {
  labels = {
    SDM_PlanAnual_ViewAsModalSubmit,
    SDM_PlanAnual_ViewAsModalFilterUsers,
    SDM_PlanAnual_ViewAsModalChangeUser,
    SDM_PlanAnual_ButtonCancel
  };

  selectedUserId = userId;
  selectedUserName;
  userOptions;
  filteredUserOptions = [];
  disableSubmitButton = false;

  // cargar las opciones en el combobox
  @wire(getSDMUsersList)
  wiredUsers({ error, data }) {
    if (data) {
      this.userOptions = data.map((user) => ({
        label: user.Name,
        value: user.Id
      }));
      this.filteredUserOptions = [...this.userOptions];
    } else if (error) {
      console.error(JSON.stringify(error));
    }
  }
  // obtener el id del registro seleccionado en el combobox
  handleChange(event) {
    this.selectedUserId = event.detail.value;
  }

  // metodos filtro input
  handleFilter(event) {
    const filter = event.target.value.toLowerCase();
    if (filter !== "" && filter !== null) {
      this.filteredUserOptions = this.userOptions.filter((option) =>
        option.label.toLowerCase().includes(filter)
      );
      if (this.filteredUserOptions.length > 0) {
        this.selectedUserId = this.filteredUserOptions[0].value;
      }
    } else {
      this.filteredUserOptions = [...this.userOptions];
      this.selectedUserId = userId;
    }
    this.handleDisableSubmitButton();
  }

  // habilitar/deshabilitar boton Submit
  handleDisableSubmitButton() {
    this.disableSubmitButton = this.filteredUserOptions.length === 0;
  }

  // enviar a la pantalla la información necesaria
  handleOkay() {
    // busco el label de la opción seleccionada para mostrar en el componente
    this.selectedUserName = this.userOptions.filter((option) =>
      option.value.includes(this.selectedUserId)
    )[0].label;
    let closeData = {
      selectedUserId: this.selectedUserId,
      selectedUserName: this.selectedUserName
    };
    this.close(closeData);
  }

  // botón cancelar
  handleCancel() {
    this.close(undefined);
  }
}
