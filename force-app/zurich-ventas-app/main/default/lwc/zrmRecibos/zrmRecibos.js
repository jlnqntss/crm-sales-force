import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData from "@salesforce/apex/ZrmRecibosController.getData";

// The rest of the relative imports
import labels from "./labels";
import columns from "./columns";

export default class ZrmRecibos extends LightningElement {
  @api antiguedadRecibo;

  labels = labels;
  columns = columns;
  data = [];
  disablePreviousButton = true;
  disableNextButton = true;
  currentPage = 1; // atributo que lleva la cuenta interna del número de página para el servicio web
  pageSize = 50;
  cache = {};
  isLoading = false;

  // Métodos LWC

  // Metodo que se ejecuta cuando se abre el componente
  connectedCallback() {
    this.isLoading = true;
    this.loadData(1); // inicializamos con 1 para facilitar la cuenta del numero de pagina y habilitar y deshabilitar botones, en el controlador al invocar al WS se resta 1 pues empieza en 0
  }

  // control botón previous
  handlePrevious() {
    if (this.currentPage > 1) {
      this.isLoading = true;
      this.loadData(this.currentPage - 1);
    }
  }

  // control botón next
  handleNext() {
    this.isLoading = true;
    this.loadData(this.currentPage + 1);
  }

  // control de caché y obtener datos del servicio web
  loadData(pageNumber) {
    // Verifica si los datos ya están en la caché
    if (this.cache[pageNumber]) {
      this.updateData(this.cache[pageNumber], pageNumber);
    } else {
      // Llama al método Apex solo si los datos no están en la caché
      getData({
        pageNumber: pageNumber,
        pageSize: this.pageSize,
        invocationType: this.antiguedadRecibo
      })
        .then((result) => {
          // Almacena el resultado en la caché
          this.cache[pageNumber] = result;
          this.updateData(result, pageNumber);
        })
        .catch((error) => {
          this.isLoading = false;
          let errorMessage = "An unknown error occurred";

          // Verifica si error y error.body están definidos antes de acceder a error.body.message
          if (error && error.body) {
            if (typeof error.body.message === "string") {
              errorMessage = error.body.message;
            } else {
              errorMessage = "Error message is not a string";
            }
          } else if (error && error.message) {
            errorMessage = error.message;
          }

          // Asumiendo que showToast es un método definido en tu componente
          this.showToast("Error", errorMessage, "error");
        });
    }
  }

  // actualizar variables
  updateData(result, pageNumber) {
    this.isLoading = false;
    this.data = result.records;
    this.disablePreviousButton = result.disablePreviousButton;
    this.disableNextButton = result.disableNextButton;
    this.currentPage = pageNumber;
  }

  // Función para mostrar mensajes toast
  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
}
