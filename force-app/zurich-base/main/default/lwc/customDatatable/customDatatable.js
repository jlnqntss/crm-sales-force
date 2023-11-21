import LightningDatatable from "lightning/datatable";
import richTextColumnType from "./richTextColumnType.html";
import hyperlinkedString from "./hyperlinkedString.html";

/**
 * Custom component that extends LightningDatatable
 * and adds a new column type
 */
export default class CustomDatatable extends LightningDatatable {
  static customTypes = {
    // custom type definition
    richText: {
      template: richTextColumnType,
      standardCellLayout: true
    },
    hyperlinkedString: {
      template: hyperlinkedString,
      standardCellLayout: true,
      typeAttributes: ['recordId', 'sObject']
    }
  };
}
