    import { createElement } from 'lwc';
import CallMeBackList from 'c/callMeBackList';

describe('c-call-me-back-list', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // Test para comprobar que se muestran las CMB
    it('Comprobar que la tabla es correcta', () => {
        const element = createElement('c-call-me-back-list', {
            is: CallMeBackList
        });
        document.body.appendChild(element);
        const datatable = element.shadowRoot.querySelector("lightning-datatable");
        expect(datatable.columns.length).toBe(3);
    });

    // TODO: Test para comprobar que se muestra el modal al darle a mostrar más

    // TODO: Test para comprobar que se cancelan CMB
    it('Comprobar que se cancelan los CMB', () => {

        const rowActionEvent = new CustomEvent("rowaction", {
            detail: {
                action: { name: "Cancel" },
                row: {    GenesysInteractionId__c: "9b6eef74-0015-420c-b74a-cc105f309d53",
                        Id : "0Tz7a000000KynICAS" 
                }            
            }
          });

        const element = createElement('c-call-me-back-list', {
            is: CallMeBackList
        });
        document.body.appendChild(element);
        const datatable = element.shadowRoot.querySelector("lightning-datatable");
        datatable.dispatchEvent(rowActionEvent);
    });
});